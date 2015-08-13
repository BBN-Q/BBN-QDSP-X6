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

use ieee.std_logic_misc.and_reduce; --just use and in VHDL-2008

use work.BBN_QDSP_pkg.all;

entity BBN_QDSP_top is
  generic (
    WB_OFFSET        : std_logic_vector(15 downto 0) := x"0000";
    STREAM_ID_OFFSET : std_logic_vector(3 downto 0) := x"0";
    SYS_CLK_FREQ     : natural := 200 -- system clock frequency in MHz
  );
  port (
    -- Reset and Clock
    sys_clk        : in  std_logic;
    rst            : in  std_logic; --reset synchronous to sys_clk
    trig_ext       : in  std_logic; --trigger synchronous to adc_clk

    -- Slave Wishbone Interface
    wb_rst_i       : in  std_logic;
    wb_clk_i       : in  std_logic;
    wb_adr_i       : in  std_logic_vector(15 downto 0);
    wb_dat_i       : in  std_logic_vector(31 downto 0);
    wb_we_i        : in  std_logic;
    wb_stb_i       : in  std_logic;
    wb_ack_o       : out std_logic;
    wb_dat_o       : out std_logic_vector(31 downto 0);

    --ADC data interface
    adc_clk        : in std_logic;
    adc_data       : in std_logic_vector(47 downto 0) ;

    -- VITA-49 Output FIFO Interfaces
    vita_muxed_data   : out std_logic_vector(31 downto 0);
    vita_muxed_vld    : out std_logic;
    vita_muxed_rdy    : in std_logic;
    vita_muxed_last   : out std_logic;

    -- Decision Engine outputs
    state        : out std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');
    state_vld    : out std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0')
  );
end entity;

architecture arch of BBN_QDSP_top is

--Data streams
signal in_data : std_logic_vector(47 downto 0) := (others => '0');
signal in_vld, in_last : std_logic := '0';

signal decimated_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_vld, decimated_last : std_logic := '0';

signal decimated_sysclk_data : std_logic_vector(13 downto 0) := (others => '0');
signal decimated_sysclk_vld, decimated_sysclk_last, decimated_sysclk_rdy : std_logic := '0';

signal channelized_data_re, channelized_data_im : width_16_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal channelized_vld, channelized_last : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal result_raw_re, result_raw_im : width_32_array_t(NUM_RAW_KI_CH-1 downto 0) := (others => (others => '0'));
signal result_raw_vld, result_raw_last : std_logic_vector(NUM_RAW_KI_CH-1 downto 0) := (others => '0');

signal result_demod_re, result_demod_im : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal result_demod_vld, result_demod_last : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

--WB registers
signal test_settings      : std_logic_vector(31 downto 0) := (others => '0');
alias  test_enable        : std_logic is test_settings(16);
alias  test_trig_interval : std_logic_vector(15 downto 0) is test_settings(15 downto 0);
signal record_length      : std_logic_vector(15 downto 0) := (others => '0');
signal stream_enable      : std_logic_vector(31 downto 0) := (others => '0');
signal phase_inc          : width_24_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));

--Kernel memory
signal kernel_len        : kernel_addr_array_t(NUM_KI_CH-1 downto 0) := (others => (others => '0'));
signal kernel_rdwr_addr  : kernel_addr_array_t(NUM_KI_CH-1 downto 0) := (others => (others => '0'));
signal kernel_rd_data, kernel_wr_data  : width_32_array_t(NUM_KI_CH-1 downto 0) := (others => (others => '0'));
signal kernel_we         : std_logic_vector(NUM_KI_CH-1 downto 0) := (others => '0');

--Decision Engine thresholds
signal threshold        : width_32_array_t(NUM_RAW_KI_CH-1 downto 0) := (others => (others => '0'));

--Vita streams
signal ts_seconds, ts_frac_seconds : std_logic_vector(31 downto 0);

signal vita_raw_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_raw_vld, vita_raw_last, vita_raw_rdy : std_logic := '0';

signal vita_result_raw_data : width_32_array_t(NUM_RAW_KI_CH-1 downto 0) := (others => (others => '0'));
signal vita_result_raw_vld, vita_result_raw_last, vita_result_raw_rdy : std_logic_vector(NUM_RAW_KI_CH-1 downto 0) := (others => '0');

signal vita_demod_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_demod_vld, vita_demod_last, vita_demod_rdy : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal vita_result_demod_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_result_demod_vld, vita_result_demod_last, vita_result_demod_rdy : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

--Misc.
signal srst, rst_adc_clk, rst_chan, rst_rawKI : std_logic := '1';

signal channelizer_dds_vld : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');
signal raw_framer_vld, raw_framer_rdy : std_logic := '0';

signal result_raw_vld_sys  : std_logic_vector(NUM_RAW_KI_CH-1 downto 0) := (others => '0');
signal result_raw_vld_re   : std_logic_vector(NUM_RAW_KI_CH-1 downto 0) := (others => '0');
signal result_demod_vld_re : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal trigger, trig_test, trig_sysclk : std_logic := '0';

signal test_pattern_re, test_pattern_im : std_logic_vector(47 downto 0) := (others => '0');

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
    test_settings        => test_settings,
    record_length        => record_length,
    stream_enable        => stream_enable,

    phase_inc            => phase_inc,
    kernel_len           => kernel_len,
    threshold            => threshold,
    kernel_addr          => kernel_rdwr_addr,
    kernel_wr_data       => kernel_wr_data,
    kernel_rd_data       => kernel_rd_data,
    kernel_we            => kernel_we
  );

  --Register synchronous reset; doesn't matter if we come of of reset one clock cycle later and helps timing closure getting the reset signal everywhere
  rstReg : process( sys_clk )
   begin
    if rising_edge(sys_clk) then
      srst <= rst;
    end if ;
   end process ; -- rstReg

  timeStamper : entity work.VitaTimeStamp
    generic map (CLK_FREQ => SYS_CLK_FREQ)
    port map (
      clk => sys_clk,
      rst => srst,

      ts_seconds => ts_seconds,
      ts_frac_seconds => ts_frac_seconds
    );

  --Synchronize the reset from the system clock to the adc_clk
  --See https://github.com/noasic/noasic/blob/master/components/reset_synchronizer.vhd
  rst_sync_adc : entity work.synchronizer
  generic map(G_INIT_VALUE => '1', G_NUM_GUARD_FFS => 1)
  port map(reset => srst, clk => adc_clk, i_data => '0', o_data => rst_adc_clk);

  --Generate channelizer reset pulse on system clock
  --DDS and FIR in channlizer need two clock high reset
  sync_trig_sys : entity work.synchronizer
  port map(reset => srst, clk => sys_clk, i_data => trigger, o_data => trig_sysclk);

  channelizerResetPulse : process(sys_clk)
  variable trig_d : std_logic;
  variable reset_line : std_logic_vector(1 downto 0);
  begin
    if rising_edge(sys_clk) then
      if srst = '1' then
        trig_d := '0';
        reset_line := (others => '1');
      else
        --Check for rising_edge of trigger
        if trig_sysclk = '1' and trig_d = '0' then
          reset_line := (others => '1');
        else
          reset_line := reset_line(reset_line'high-1 downto 0) & '0';
        end if;
        trig_d := trig_sysclk;
      end if;
      rst_chan <= reset_line(reset_line'high);
    end if;
  end process;

  --Hold valid high for the record length amount of time
  --TODO: add a trigger delay state
  recordCounter_proc : process( adc_clk )
  type state_t is (IDLE, RECORDING);
  variable state : state_t;
  variable counter : unsigned(15 downto 0);
  begin
    if rising_edge(adc_clk) then
      if rst_adc_clk = '1' then
        state := IDLE;
        in_vld <= '0';
        in_last <= '0';
      else
        case( state ) is
          when IDLE =>
            -- -1 because we catch underflow below
            -- Drop bottom two bits because we have 4 sample wide bus
            counter := resize(unsigned(record_length(15 downto 2))-1, counter'length);
            in_vld <= '0';
            in_last <= '0';
            if trigger = '1' then
              state := RECORDING;
            end if;

          when RECORDING =>
            counter := counter - 1;
            in_vld <= '1';
            --catch roll-over
            if counter(counter'high) = '1' then
              state := IDLE;
              in_last <= '1';
            end if ;

        end case ;
      end if; --reset if
    end if ; -- rising_edge if
  end process ; -- recordCounter_proc

  --Initial decimation of 1GSPS stream to a manageable 250MSPS
  ADCDecimator_inst : entity work.ADCDecimator
  generic map (ADC_DATA_WIDTH => 12)
  port map (
    clk => adc_clk,
    rst => srst,

    in_data => in_data,
    in_vld => in_vld,
    in_last => in_last,

    out_data => decimated_data,
    out_vld => decimated_vld,
    out_last => decimated_last);

  --Raw kernel integrators and framers

  --Reset integrator on rising edge of trigger
  rawIntegratorReset : process( adc_clk )
  variable trig_d : std_logic := '0';
  begin
    if rising_edge(adc_clk) then
      if rst_adc_clk = '1' then
        trig_d := '0';
        rst_rawKI <= '1';
      else
        rst_rawKI <= trigger and not trig_d;
        trig_d := trigger;
      end if;
    end if;
  end process;

  rawKIgen : for ct in 0 to NUM_RAW_KI_CH-1 generate
    rawIntegrator : entity work.KernelIntegrator
    generic map ( KERNEL_ADDR_WIDTH => RAW_KERNEL_ADDR_WIDTH)
    port map (
      clk => adc_clk,
      rst => rst_rawKI,

      --TODO make KernelIntegrator data width generic
      data_re   => std_logic_vector(resize(signed(decimated_data),16)),
      data_im   => (others => '0'),
      data_vld  => decimated_vld,
      data_last => decimated_last,

      kernel_len       => kernel_len(ct),
      kernel_rdwr_addr => kernel_rdwr_addr(ct),
      kernel_wr_data   => kernel_wr_data(ct),
      kernel_rd_data   => kernel_rd_data(ct),
      kernel_we        => kernel_we(ct),
      kernel_wr_clk    => sys_clk,

      result_re      =>  result_raw_re(ct),
      result_im      =>  result_raw_im(ct),
      result_vld     =>  result_raw_vld(ct)
    );

    --Drive state decision lines
    thresholding : process(adc_clk)
    begin
      if rising_edge(adc_clk) then
        if rst_adc_clk = '1' then
          state(ct) <= '0';
          state_vld(ct) <= '0';
        else
          if signed(result_raw_re(ct)) > signed(threshold(ct)) then
            state(ct) <= '1';
          else
            state(ct) <= '0';
          end if;
          state_vld(ct) <= result_raw_vld(ct);
        end if;
      end if;
    end process;

    --Package the result data into a vita frame
    --We want a single clock cycle valid high so use rising edge as valid
    --First get back onto the system clock
    sync_result_raw_vld_sys : entity work.synchronizer
    port map(reset => srst, clk => sys_clk, i_data => result_raw_vld(ct), o_data => result_raw_vld_sys(ct));

    result_raw_vld_re_detector : process( sys_clk )
    variable result_raw_vld_d : std_logic := '0';
    begin
      if rising_edge(sys_clk) then
        if srst = '1' then
          result_raw_vld_d := '0';
          result_raw_vld_re(ct) <= '0';
        else
          result_raw_vld_re(ct) <= result_raw_vld_sys(ct) and not result_raw_vld_d;
          result_raw_vld_d := result_raw_vld_sys(ct);
        end if;
      end if;
    end process;

    rawResultFramer : entity work.VitaFramer
    generic map (INPUT_BYTE_WIDTH => 8)
    port map (
      clk => sys_clk,
      rst => srst,

      stream_id => x"0" & STREAM_ID_OFFSET & x"0" & std_logic_vector(to_unsigned(ct+1,4)),
      payload_size => x"0004", --minimum size
      pad_bytes => x"8", -- two words padding = 8 bytes
      ts_seconds => ts_seconds,
      ts_frac_seconds => ts_frac_seconds,

      in_data => result_raw_im(ct) & result_raw_re(ct),
      in_vld  => result_raw_vld_re(ct) and stream_enable(ct+1),
      in_last => result_raw_vld_re(ct),
      in_rdy  => open,

      out_data => vita_result_raw_data(ct),
      out_vld  => vita_result_raw_vld(ct),
      out_rdy  => vita_result_raw_rdy(ct),
      out_last => vita_result_raw_last(ct)
    );
  end generate;

  --Get the data onto the system clock for framing and further demodulation
  adc2sys_CDC : axis_async_fifo
  generic map (
    ADDR_WIDTH => 12,
    DATA_WIDTH => 14
  )
  port map (
    input_clk => adc_clk,
    input_rst => rst_adc_clk,
    input_axis_tdata => decimated_data,
    input_axis_tvalid => decimated_vld,
    input_axis_tready => open,
    input_axis_tlast => decimated_last,
    input_axis_tuser => '0',

    output_clk => sys_clk,
    output_rst => srst,
    output_axis_tdata => decimated_sysclk_data,
    output_axis_tvalid => decimated_sysclk_vld,
    output_axis_tready => decimated_sysclk_rdy,
    output_axis_tlast => decimated_sysclk_last,
    output_axis_tuser => open
  );

  --Package the decimated raw data into a vita frame
  rawFramer : entity work.VitaFramer
  generic map (INPUT_BYTE_WIDTH => 2)
  port map (
    clk => sys_clk,
    rst => srst,

    stream_id => x"0" & STREAM_ID_OFFSET & x"00",
    payload_size => "000" & record_length(15 downto 3),  --divide by four for decimation and two samples per word
    pad_bytes => (others => '0'),
    ts_seconds => ts_seconds,
    ts_frac_seconds => ts_frac_seconds,

    in_data => std_logic_vector(resize(signed(decimated_sysclk_data),16)),
    in_vld  => raw_framer_vld and stream_enable(0),
    in_last => decimated_sysclk_last,
    in_rdy  => raw_framer_rdy,

    out_data => vita_raw_data,
    out_vld  => vita_raw_vld,
    out_rdy  => vita_raw_rdy,
    out_last => vita_raw_last
  );

  --Wait until channelizer comes out of reset before letting framer control flow
  --We still let framer control to get the right size vita packets but of course the channlizer
  --needs continuous data because it does not apply back pressure to DDS
  raw_framer_vld <= decimated_sysclk_vld when and_reduce(channelizer_dds_vld) = '1' else '0';
  decimated_sysclk_rdy <= raw_framer_rdy when and_reduce(channelizer_dds_vld) = '1' else '0';

  -- For each demod channel demodulate, integrate and frame both
  demodGenLoop : for ct in 0 to NUM_DEMOD_CH-1 generate
    genChannelizer: entity work.Channelizer
      generic map (
        DATA_IN_WIDTH  => 14,
        DATA_OUT_WIDTH => 16
      )
      port map (
        clk               => sys_clk,
        rst               => rst_chan,
        dds_phase_inc     => phase_inc(ct),
        dds_phase_inc_vld => '1',
        dds_vld           => channelizer_dds_vld(ct),
        data_in_re        => decimated_sysclk_data,
        data_in_im        => (others => '0'),
        data_in_vld       => decimated_sysclk_vld and decimated_sysclk_rdy,
        data_in_last      => decimated_sysclk_last,
        data_out_re       => channelized_data_re(ct),
        data_out_im       => channelized_data_im(ct),
        data_out_vld      => channelized_vld(ct),
        data_out_last     => channelized_last(ct)
      );

      --Package the channelized data into the vita frame
      demodFramer : entity work.VitaFramer
      generic map (INPUT_BYTE_WIDTH => 4)
      port map (
        clk => sys_clk,
        rst => srst,

        stream_id => x"0" & STREAM_ID_OFFSET & std_logic_vector(to_unsigned(ct+1,4)) & x"0",
        payload_size => "00000" & record_length(15 downto 5), --total decimation factor of 32
        pad_bytes => (others => '0'),
        ts_seconds => ts_seconds,
        ts_frac_seconds => ts_frac_seconds,

        in_data => channelized_data_im(ct) & channelized_data_re(ct),
        in_vld  => channelized_vld(ct) and stream_enable(16+ct),
        in_last => channelized_last(ct),
        in_rdy  => open,

        out_data => vita_demod_data(ct),
        out_vld  => vita_demod_vld(ct),
        out_rdy  => vita_demod_rdy(ct),
        out_last => vita_demod_last(ct)
      );

      demodIntegrator : entity work.KernelIntegrator
      generic map ( KERNEL_ADDR_WIDTH => RAW_KERNEL_ADDR_WIDTH-3) -- demod length is / 8
      port map (
        clk => sys_clk,
        rst => rst_chan,

        data_re   => channelized_data_re(ct),
        data_im   => channelized_data_im(ct),
        data_vld  => channelized_vld(ct),
        data_last => channelized_last(ct),

        kernel_len       => kernel_len(NUM_RAW_KI_CH+ct)(RAW_KERNEL_ADDR_WIDTH-4 downto 0),
        kernel_rdwr_addr => kernel_rdwr_addr(NUM_RAW_KI_CH+ct)(RAW_KERNEL_ADDR_WIDTH-4 downto 0),
        kernel_wr_data   => kernel_wr_data(NUM_RAW_KI_CH+ct),
        kernel_rd_data   => kernel_rd_data(NUM_RAW_KI_CH+ct),
        kernel_we        => kernel_we(NUM_RAW_KI_CH+ct),
        kernel_wr_clk    => sys_clk,

        result_re      =>  result_demod_re(ct),
        result_im      =>  result_demod_im(ct),
        result_vld     =>  result_demod_vld(ct)
      );

      --Package the result data into a vita frame
      --We want a single clock cycle valid high to use rising edge as valid
      result_demod_vld_re_detector : process( sys_clk )
      variable result_demod_vld_d : std_logic := '0';
      begin
        if rising_edge(sys_clk) then
          if srst = '1' then
            result_demod_vld_d := '0';
            result_demod_vld_re(ct) <= '0';
          else
            result_demod_vld_re(ct) <= result_demod_vld(ct) and not result_demod_vld_d;
            result_demod_vld_d := result_demod_vld(ct);
          end if;
        end if;
      end process;

      demodResultFramer : entity work.VitaFramer
      generic map (INPUT_BYTE_WIDTH => 8)
      port map (
        clk => sys_clk,
        rst => srst,

        stream_id => x"0" & STREAM_ID_OFFSET & std_logic_vector(to_unsigned(ct+1,4)) & x"1",
        payload_size => x"0004", --minimum size
        pad_bytes => x"8", -- two words padding = 8 bytes
        ts_seconds => ts_seconds,
        ts_frac_seconds => ts_frac_seconds,

        in_data => result_demod_im(ct) & result_demod_re(ct),
        in_vld  => result_demod_vld_re(ct) and stream_enable(20+ct),
        in_last => result_demod_vld_re(ct),
        in_rdy  => open,

        out_data => vita_result_demod_data(ct),
        out_vld  => vita_result_demod_vld(ct),
        out_rdy  => vita_result_demod_rdy(ct),
        out_last => vita_result_demod_last(ct)
      );

  end generate;

  --Mux together all the vita channels
  vitaMuxer : entity work.BBN_QDSP_VitaMuxer
  port map (
    clk => sys_clk,
    rst => srst,

    vita_raw_data  => vita_raw_data,
    vita_raw_vld   => vita_raw_vld,
    vita_raw_rdy   => vita_raw_rdy,
    vita_raw_last  => vita_raw_last,

    vita_result_raw_data  => vita_result_raw_data,
    vita_result_raw_vld   => vita_result_raw_vld,
    vita_result_raw_rdy   => vita_result_raw_rdy,
    vita_result_raw_last  => vita_result_raw_last,

    vita_demod_data  => vita_demod_data,
    vita_demod_vld   => vita_demod_vld,
    vita_demod_rdy   => vita_demod_rdy,
    vita_demod_last  => vita_demod_last,

    vita_result_demod_data  => vita_result_demod_data,
    vita_result_demod_vld   => vita_result_demod_vld,
    vita_result_demod_rdy   => vita_result_demod_rdy,
    vita_result_demod_last  => vita_result_demod_last,

    vita_muxed_data  => vita_muxed_data,
    vita_muxed_vld   => vita_muxed_vld,
    vita_muxed_rdy   => vita_muxed_rdy,
    vita_muxed_last  => vita_muxed_last
  );

  --Test pattern generator
  myTestPattern : entity work.TestPattern
  generic map (
    SAMPLE_WIDTH => 12,
    TRIGGER_WIDTH => 2
  )
  port map (
    clk => adc_clk,
    rst => (not test_enable) or srst,

    trig_interval => test_trig_interval,
    trigger       => trig_test,

    pattern_data_re => test_pattern_re,
    pattern_data_im => test_pattern_im
  );

  --Mux data and trigger source depending on mode
  in_data <= test_pattern_re when test_enable = '1' else adc_data;
  trigger <= trig_test when test_enable = '1' else trig_ext;

end architecture;
