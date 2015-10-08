library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use IEEE.math_real.all;

use work.TestVectors.all;

entity Channelizer_tb is
end;

architecture bench of Channelizer_tb is

  constant DATA_IN_WIDTH : natural := 14;
  constant DATA_IN_SCALE : real := real(2 ** (DATA_IN_WIDTH-1)) - 1.0;
  constant DATA_OUT_WIDTH : natural := 16;

  signal clk: std_logic := '0';
  signal rst: std_logic := '0';
  signal dds_phase_inc: std_logic_vector(23 downto 0) := (others => '0');
  signal dds_phase_inc_vld: std_logic := '0';
  signal dds_vld : std_logic;
  signal data_in_re, data_in_im : std_logic_vector(DATA_IN_WIDTH-1 downto 0) := (others => '0');
  signal data_in_vld: std_logic := '0';
  signal data_in_last: std_logic := '0';
  signal data_out_re, data_out_im : std_logic_vector(DATA_OUT_WIDTH-1 downto 0) := (others => '0');
  shared variable data_out_re_expected, data_out_im_expected : signed(DATA_OUT_WIDTH-1 downto 0) := (others => '0');
  signal data_out_vld : std_logic := '0';
  signal data_out_last: std_logic := '0';

  constant CLK_PERIOD: time := 4 ns;
  signal finished : boolean := false;

  type TestBenchState_t is (RESET, LOAD_PHASE_INC, PUMP_RESET, WRITE_WFM, ALL_DONE);
  signal testBenchState : TestBenchState_t;
begin

  uut: entity work.Channelizer
    generic map ( DATA_IN_WIDTH  => DATA_IN_WIDTH )
    port map (
      clk               => clk,
      rst               => rst,
      dds_phase_inc     => dds_phase_inc,
      dds_phase_inc_vld => dds_phase_inc_vld,
      dds_vld           => dds_vld,
      data_in_re        => data_in_re,
      data_in_im        => data_in_im,
      data_in_vld       => data_in_vld,
      data_in_last      => data_in_last,
      data_out_re       => data_out_re,
      data_out_im       => data_out_im,
      data_out_vld      => data_out_vld,
      data_out_last     => data_out_last );

  --Clocking
  clk <= not clk after CLK_PERIOD/2 when not finished;

  stimulus: process
  variable phase : real;
  begin

    testBenchState <= RESET;
    rst <= '1';
    wait for 100ns;
    rst <= '0';
    wait for 10ns;

    testBenchState <= LOAD_PHASE_INC;
    wait until rising_edge(clk);
    --Set to 13MHz on 250MHz round(Int, 13/250 * 2^24)
    dds_phase_inc <= std_logic_vector(to_unsigned(872415, 24));
    dds_phase_inc_vld <= '1';
    wait until rising_edge(clk);
    dds_phase_inc_vld <= '0';

    wait until rising_edge(clk);
    testBenchState <= PUMP_RESET;
    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';

    --DDS latency
    for ct in 0 to 7 loop
      wait until rising_edge(clk);
    end loop;

    testBenchState <= WRITE_WFM;
    --Test waveform is square pulse at +13MHz
    --Now pulse at +13MHz
    for ct in 0 to 767 loop
      wait until rising_edge(clk);
      phase := 2.0*MATH_PI * 13.0e6 * (real(ct) * real(CLK_PERIOD / 1ns) * 1.0e-9);
      data_in_re <= std_logic_vector(to_signed(integer(trunc(DATA_IN_SCALE * cos(phase))), DATA_IN_WIDTH));
      data_in_im <= std_logic_vector(to_signed(integer(trunc(DATA_IN_SCALE * sin(phase))), DATA_IN_WIDTH));
      data_in_vld <= '1';
    end loop;

    --Final 256 zeros of padding
    data_in_re <= (others => '0');
    data_in_im <= (others => '0');
    for ct in 1 to 256 loop
      wait until rising_edge(clk);
      data_in_vld <= '1';
    end loop;
    data_in_last <= '1';

    wait until rising_edge(clk);
    data_in_vld <= '0';
    data_in_last <= '0';

    wait for 1us;

    testBenchState <= ALL_DONE;
    finished <= true;
    wait;
  end process;

  --Output checking
  check : process(clk)
  variable ct : natural := 0;
  begin
    if rising_edge(clk) then
      if data_out_vld = '1' then
        data_out_re_expected := to_signed(channel_filter_expected_re(ct), DATA_OUT_WIDTH);
        data_out_im_expected := to_signed(channel_filter_expected_im(ct), DATA_OUT_WIDTH);
        assert abs(to_integer(signed(data_out_re)) - channel_filter_expected_re(ct)) < 16
          report "Channel filter real part incorrect: expected " &
          integer'image(channel_filter_expected_re(ct)) & " but got " &
          integer'image(to_integer(signed(data_out_re)));
        assert abs(to_integer(signed(data_out_im)) - channel_filter_expected_im(ct)) < 16
          report "Channel filter imaginary part incorrect: expected " &
          integer'image(channel_filter_expected_im(ct)) & " but got " &
          integer'image(to_integer(signed(data_out_im)));
        ct := ct + 1;
      end if;
      if data_out_last = '1' then
        assert ct = 128 report "Wrong output length!";
      end if;
    end if;

  end process;


end;
