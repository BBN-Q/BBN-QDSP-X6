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

signal adc_data_vld : std_logic := '0';
signal adc_decimated_data : std_logic_vector(13 downto 0) := (others => '0');
signal adc_decimated_vld : std_logic := '0';

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
signal kernel_we        : std_logic_vector(num_demod_ch-1 downto 0) := (others => (others => '0'));


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
      else
        case( state ) is
          when IDLE =>
            -- -1 because we catch underflow below
            -- Drop bottom two bits because we have 4 sample wide bus
            counter := resize(unsigned(record_length(15 downto 2))-1, counter'length);
            adc_data_vld <= '0';
            if trigger = '1' then
              state := RECORDING;
            end if;

          when RECORDING =>
            counter := counter - 1;
            adc_data_vld <= '1';
            --catch roll-over
            if counter(counter'high) = '1' then
              state := IDLE;
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

    data_in => adc_data,
    data_in_vld => '0', --TODO

    data_out => adc_decimated_data,
    data_out_vld => adc_decimated_vld);

  --Package the raw data into a vita frame

end architecture;
