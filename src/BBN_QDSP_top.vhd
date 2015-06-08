-- A full DSP module for a superconducting qubit measurement records
-- Creates vita packets streams for an optionally complex analog input stream
--
-- Muxed into a single vita stream:
--  *one raw data stream
--  *n demodulated streams
--  *n integrated demodulated streams
--  *m integrated raw streams
--
-- Sends fast digital qubit state decisions out from threshold decisions on the m raw stream integrators

-- Original authors Colm Ryan and Blake Johnson
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BBN_QDSP_pkg.all;

entity BBN_QDSP_top is
  generic (
    WB_OFFSET       : std_logic_vector(15 downto 0)
  );
  port (
    -- Reset and Clock
    sys_clk              : in  std_logic;
    rst                  : in  std_logic; --reset synchronous to sys_clk
    trigger              : in  std_logic; --trigger synchronous to sys_clk

    -- Slave Wishbone Interface
    wb_rst_i             : in  std_logic;
    wb_clk_i             : in  std_logic;
    wb_adr_i             : in  std_logic_vector(15 downto 0);
    wb_dat_i             : in  std_logic_vector(31 downto 0);
    wb_we_i              : in  std_logic;
    wb_stb_i             : in  std_logic;
    wb_ack_o             : out std_logic;
    wb_dat_o             : out std_logic_vector(31 downto 0);

    --ADC data interface
    adc_data_clk         : in std_logic;
    adc_data             : in std_logic_vector(47 downto 0) ;

    -- VITA-49 Output FIFO Interface
    muxed_vita_wrd_cnt   : out std_logic_vector(8 downto 0);
    muxed_vita_aempty    : out std_logic;
    muxed_vita_empty     : out std_logic;
    muxed_vita_rden      : in std_logic;
    muxed_vita_vld       : out std_logic;
    muxed_vita_data      : out std_logic_vector(127 downto 0);

    -- Decision Engine outputs
    state                : out std_logic_vector(num_demod_ch-1 downto 0);
    state_vld            : out std_logic_vector(num_demod_ch-1 downto 0)
  );
end entity;

architecture arch of BBN_QDSP_top is

signal adc_data_vld, adc_data_last : std_logic := '0';
signal decimated_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_vld, decimated_last : std_logic := '0';

signal decimated_sysclk_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_sysclk_vld, decimated_sysclk_last, decimated_sysclk_rdy : std_logic := '0';


signal rst_adc_clk : std_logic := '1';

--WB registers
signal record_length      : std_logic_vector(15 downto 0) := (others => '0');
signal stream_enable      : std_logic_vector(31 downto 0) := (others => '0');
signal frame_size         : width_16_array(num_vita_streams-1 downto 0) := (others => (others => '0'));
signal stream_id          : width_32_array(num_vita_streams-1 downto 0) := (others => (others => '0'));
signal phase_inc          : width_18_array(num_demod_ch-1 downto 0) := (others => (others => '0'));

--Kernel memory
signal kernel_addr, kernel_wr_addr  : kernel_addr_array(num_demod_ch-1 downto 0) := (others => (others => '0'));
signal kernel_data, kernel_wr_data  : width_32_array(num_demod_ch-1 downto 0) := (others => (others => '0'));
signal kernel_len                   : kernel_addr_array(num_demod_ch-1 downto 0) := (others => (others => '0'));
signal threshold        : width_32_array(num_demod_ch-1 downto 0) := (others => (others => '0'));
signal kernel_we        : std_logic_vector(num_demod_ch-1 downto 0) := (others => '0');

signal vita_raw_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_raw_vld, vita_raw_last : std_logic := '0';

begin

  inst_BBN_QDSP_regs : entity work.BBN_QDSP_regs
  generic map ( offset  => WB_OFFSET)
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst_i,
    wb_clk_i             => wb_clk_i,
    wb_adr_i             => wb_adr_i,
    wb_dat_i             => wb_dat_i,
    wb_we_i              => wb_we_i,
    wb_stb_i             => wb_stb_i,
    wb_ack_o             => wb_ack_o,
    wb_dat_o             => wb_dat_o,

    -- User registers
    record_length        => record_length,
    stream_enable        => stream_enable,

    frame_size           => frame_size,
    stream_id            => stream_id,
    phase_inc            => phase_inc,
    kernel_len           => kernel_len,
    threshold            => threshold,
    kernel_addr          => kernel_wr_addr,
    kernel_data          => kernel_wr_data,
    kernel_we            => kernel_we
  );

  --Synchronize the reset from the system clock to the adc_clk
  --See https://github.com/noasic/noasic/blob/master/components/reset_synchronizer.vhd
  rst_sync_adc : entity work.synchronizer
  generic map(G_INIT_VALUE => '1', G_NUM_GUARD_FFS => 1)
  port map(reset => rst, clk => adc_data_clk, i_data => '0', o_data => rst_adc_clk);

  --Hold valid high for the record length amount of time
  --TODO: add a trigger delay state
  recordCounter_proc : process( adc_data_clk )
  type state_t is (IDLE, RECORDING);
  variable state : state_t;
  variable counter : unsigned(15 downto 0);
  begin
    if rising_edge(adc_data_clk) then
      if rst_adc_clk = '1' then
        state := IDLE;
        adc_data_vld <= '0';
        adc_data_last <= '0';
      else
        case( state ) is
          when IDLE =>
            -- -1 because we catch underflow below
            -- Drop bottom two bits because we have 4 sample wide bus
            counter := resize(unsigned(record_length(15 downto 2))-1, counter'length);
            adc_data_vld <= '0';
            adc_data_last <= '0';
            if trigger = '1' then
              state := RECORDING;
            end if;

          when RECORDING =>
            counter := counter - 1;
            adc_data_vld <= '1';
            --catch roll-over
            if counter(counter'high) = '1' then
              state := IDLE;
              adc_data_last <= '1';
            end if ;

            when others =>
            null;
        end case ;
      end if; --reset if
    end if ; -- rising_edge if
  end process ; -- recordCounter_proc

  --Initial decimation of 1GSPS stream to a manageable 250MSPS
  ADCDecimator_inst : entity work.ADCDecimator
  generic map (ADC_DATA_WIDTH => 12)
  port map (
    clk => adc_data_clk,
    rst => rst,

    in_data => adc_data,
    in_vld => adc_data_vld,
    in_last => adc_data_last,

    out_data => decimated_data,
    out_vld => decimated_vld,
    out_last => decimated_last);

  --Get the data onto the system clock for raw stream and further demodulation
  adc2sys_CDC : axis_async_fifo
  generic map (
    ADDR_WIDTH => 12,
    DATA_WIDTH => 14
  )
  port map (
    input_clk => adc_data_clk,
    input_rst => rst_adc_clk,
    input_axis_tdata => decimated_data,
    input_axis_tvalid => decimated_vld,
    input_axis_tready => open,
    input_axis_tlast => decimated_last,
    input_axis_tuser => '0',

    output_clk => sys_clk,
    output_rst => rst,
    output_axis_tdata => decimated_sysclk_data,
    output_axis_tvalid => decimated_sysclk_vld,
    output_axis_tready => decimated_sysclk_rdy,
    output_axis_tlast => decimated_sysclk_last,
    output_axis_tuser => open
  );

  --Package the raw data into a vita frame
  raw_stream_framer : entity work.VitaFramer
  generic map (INPUT_BYTE_WIDTH => 2)
  port map (
    clk => sys_clk,
    rst => rst,

    frame_size => frame_size(0),
    stream_id => x"baad",

    in_data => std_logic_vector(resize(signed(decimated_sysclk_data),16)),
    in_vld  => decimated_sysclk_vld,
    in_last => decimated_sysclk_last,
    in_rdy  => decimated_sysclk_rdy,

    out_data => vita_raw_data,
    out_vld  => vita_raw_vld,
    out_rdy => '1',
    out_last => vita_raw_last
  );

end architecture;
