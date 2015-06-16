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

    -- VITA-49 Output FIFO Interfaces
    vita_muxed_data      : out std_logic_vector(31 downto 0);
    vita_muxed_vld       : out std_logic;
    vita_muxed_rdy       : in std_logic;
    vita_muxed_last      : out std_logic;

    -- Decision Engine outputs
    state                : out std_logic_vector(NUM_DEMOD_CH-1 downto 0);
    state_vld            : out std_logic_vector(NUM_DEMOD_CH-1 downto 0)
  );
end entity;

architecture arch of BBN_QDSP_top is

signal adc_data_vld, adc_data_last : std_logic := '0';
signal decimated_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_vld, decimated_last : std_logic := '0';

signal decimated_sysclk_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_sysclk_vld, decimated_sysclk_last, decimated_sysclk_rdy : std_logic := '0';

signal channelized_data_re, channelized_data_im : width_16_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal channelized_vld, channelized_last : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal rst_adc_clk : std_logic := '1';

--WB registers
signal record_length      : std_logic_vector(15 downto 0) := (others => '0');
signal stream_enable      : std_logic_vector(31 downto 0) := (others => '0');
signal stream_id          : width_32_array_t(num_vita_streams-1 downto 0) := (others => (others => '0'));
signal phase_inc          : width_24_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));

--Kernel memory
signal kernel_addr, kernel_wr_addr  : kernel_addr_array(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal kernel_data, kernel_wr_data  : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal kernel_len                   : kernel_addr_array(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal threshold        : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal kernel_we        : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal vita_raw_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_raw_vld, vita_raw_last, vita_raw_rdy : std_logic := '0';

signal vita_demod_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_demod_vld, vita_demod_last, vita_demod_rdy : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');


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

  --Package the decimated data into a vita frame
  raw_stream_framer : entity work.VitaFramer
  generic map (INPUT_BYTE_WIDTH => 2)
  port map (
    clk => sys_clk,
    rst => rst,

    stream_id => stream_id(0)(15 downto 0),
    payload_size => "00" & record_length(15 downto 2),
    pad_bytes => (others => '0'),

    in_data => std_logic_vector(resize(signed(decimated_sysclk_data),16)),
    in_vld  => decimated_sysclk_vld,
    in_last => decimated_sysclk_last,
    in_rdy  => decimated_sysclk_rdy,

    out_data => vita_raw_data,
    out_vld  => vita_raw_vld,
    out_rdy  => vita_raw_rdy,
    out_last => vita_raw_last
  );

  -- For each demod channel demodulate and frame
  demodGenLoop : for ct in 0 to NUM_DEMOD_CH-1 generate
    genChannelizer: entity work.Channelizer
      generic map (
        DATA_IN_WIDTH  => 14,
        DATA_OUT_WIDTH => 16
      )
      port map (
        clk               => sys_clk,
        rst               => rst,
        dds_phase_inc     => phase_inc(ct),
        dds_phase_inc_vld => '1',
        data_in_re        => decimated_sysclk_data,
        data_in_im        => (others => '0'),
        data_in_vld       => decimated_sysclk_vld,
        data_in_last      => decimated_sysclk_last,
        data_out_re       => channelized_data_re(ct),
        data_out_im       => channelized_data_im(ct),
        data_out_vld      => channelized_vld(ct),
        data_out_last     => channelized_last(ct)
      );

      --Package the decimated data into a vita frame
      demodFramer : entity work.VitaFramer
      generic map (INPUT_BYTE_WIDTH => 4)
      port map (
        clk => sys_clk,
        rst => rst,

        stream_id => stream_id(0)(15 downto 0),
        payload_size => "00000" & record_length(15 downto 5),
        pad_bytes => (others => '0'),

        in_data => channelized_data_re(ct) & channelized_data_im(ct),
        in_vld  => channelized_vld(ct),
        in_last => channelized_last(ct),
        in_rdy  => open,

        out_data => vita_demod_data(ct),
        out_vld  => vita_demod_vld(ct),
        out_rdy  => vita_demod_rdy(ct),
        out_last => vita_demod_last(ct)
      );

  end generate;

  --Mux together all the vita channels
  vitaMuxer : entity work.BBN_QDSP_VitaMuxer
  port map (
    clk => sys_clk,
    rst => rst,

    vita_raw_data  => vita_raw_data,
    vita_raw_vld   => vita_raw_vld,
    vita_raw_rdy   => vita_raw_rdy,
    vita_raw_last  => vita_raw_last,

    vita_demod_data  => vita_demod_data,
    vita_demod_vld   => vita_demod_vld,
    vita_demod_rdy   => vita_demod_rdy,
    vita_demod_last  => vita_demod_last,

    vita_muxed_data  => vita_muxed_data,
    vita_muxed_vld   => vita_muxed_vld,
    vita_muxed_rdy   => vita_muxed_rdy,
    vita_muxed_last  => vita_muxed_last
  );


end architecture;
