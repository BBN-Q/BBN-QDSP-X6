library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity TestPattern_tb is
end;

architecture bench of TestPattern_tb is

  constant SAMPLE_WIDTH : natural := 12;
  constant CLK_PERIOD : time := 4 ns;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal trigger : std_logic := '0';
  signal trig_interval : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(2500, 16));
  signal pattern_data_re : std_logic_vector(4*SAMPLE_WIDTH-1 downto 0) := (others => '0');
  signal pattern_data_im : std_logic_vector(4*SAMPLE_WIDTH-1 downto 0) := (others => '0');
  signal fast_pattern_re : std_logic_vector(SAMPLE_WIDTH-1 downto 0);

  type TestBenchState_t is (RESET, RUNNING, FINISHED);
  signal testBench_state : TestBenchState_t;

  signal stop_the_clocks : boolean := false;

begin

  uut: entity work.TestPattern
    generic map ( SAMPLE_WIDTH => SAMPLE_WIDTH )
    port map (
      clk             => clk,
      rst             => rst,
      trig_interval   => trig_interval,
      trigger         => trigger,
      pattern_data_re => pattern_data_re,
      pattern_data_im => pattern_data_im
    );

  oserdes: entity work.FakeOSERDES
    generic map (
      SAMPLE_WIDTH => SAMPLE_WIDTH,
      FPGA_CLK_PERIOD => CLK_PERIOD
    )
    port map (
      clk_in => clk,
      reset => rst,
      data_in => pattern_data_re,
      data_out => fast_pattern_re
    );

  stimulus: process
  begin

    --Initial reset
    testBench_state <= RESET;
    rst <= '1';
    wait for 100ns;
    rst <= '0';
    wait for 20ns;

    testBench_state <= RUNNING;
    wait;
  end process;

  --clocking
  clk <= not clk after CLK_PERIOD /2 when not stop_the_clocks;

end;
