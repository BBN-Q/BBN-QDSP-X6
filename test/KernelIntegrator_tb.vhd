library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use work.bbn_qdsp_pkg.RAW_KERNEL_ADDR_WIDTH;

entity KernelIntegrator_tb is
end;

architecture bench of KernelIntegrator_tb is

  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal data_re, data_im : std_logic_vector(15 downto 0) := (others => '0');
  signal data_vld, data_last : std_logic := '0';
  signal kernel_len: std_logic_vector(RAW_KERNEL_ADDR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(128, RAW_KERNEL_ADDR_WIDTH));
  signal kernel_rdwr_addr: std_logic_vector(RAW_KERNEL_ADDR_WIDTH-1 downto 0);
  signal kernel_wr_data : std_logic_vector(31 downto 0);
  signal kernel_rd_data : std_logic_vector(31 downto 0);
  signal kernel_we: std_logic := '0';
  signal kernel_wr_clk: std_logic := '0';
  signal result_re, result_im : std_logic_vector(31 downto 0) := (others => '0');
  signal result_vld: std_logic;

  constant CLK_PERIOD: time := 10 ns;
  constant WB_CLK_PERIOD : time := 20 ns;
  signal stop_the_clocks : boolean := false;

  type TestBenchState_t is (RESET, MEMORY_WRITE, MEMORY_READ, RUNNING, FINISHED);
  signal testBench_state : TestBenchState_t;

begin

  --Clocking
  clk <= not clk after CLK_PERIOD/2 when not stop_the_clocks;
  kernel_wr_clk <= not kernel_wr_clk after WB_CLK_PERIOD/2 when not stop_the_clocks;

  uut: entity work.KernelIntegrator
    generic map ( KERNEL_ADDR_WIDTH => RAW_KERNEL_ADDR_WIDTH)
    port map (
      rst => rst,
      clk              => clk,
      data_re          => data_re,
      data_im          => data_im,
      data_vld         => data_vld,
      data_last        => data_last,
      kernel_len       => kernel_len,
      kernel_rdwr_addr => kernel_rdwr_addr,
      kernel_wr_data   => kernel_wr_data,
      kernel_rd_data   => kernel_rd_data,
      kernel_we        => kernel_we,
      kernel_wr_clk    => kernel_wr_clk,
      result_re        => result_re,
      result_im        => result_im,
      result_vld       => result_vld );

  stimulus: process
  begin

    -- Reset
    testBench_state <= RESET;
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait for 5 ns;

    -- Load the kernel memory
    wait until rising_edge(kernel_wr_clk);
    testBench_state <= MEMORY_WRITE;
    memoryWriter : for ct in 1 to to_integer(unsigned(kernel_len)) loop
      kernel_rdwr_addr <= std_logic_vector(to_unsigned(ct-1, RAW_KERNEL_ADDR_WIDTH));
      wait until rising_edge(kernel_wr_clk);
      --For now load ramp
      kernel_wr_data <= std_logic_vector(to_signed(ct, 16)) & std_logic_vector(to_signed(256*ct-1, 16));
      kernel_we <= '1';
      wait until rising_edge(kernel_wr_clk);
      kernel_we <= '0';
      wait until rising_edge(kernel_wr_clk);
    end loop;

    --Read back a memory address
    wait until rising_edge(kernel_wr_clk);
    testBench_state <= MEMORY_READ;
    kernel_rdwr_addr <= std_logic_vector(to_unsigned(27, RAW_KERNEL_ADDR_WIDTH));
    --Address and output register delay
    for ct in 1 to 3 loop
      wait until rising_edge(kernel_wr_clk);
    end loop;
    assert kernel_rd_data = std_logic_vector(to_signed(28, 16)) & std_logic_vector(to_signed(256*28-1, 16))
      report "Failed to read kernel memory";

    --Clock in the data
    wait until rising_edge(clk);
    testBench_state <= RUNNING;
    data_vld <= '1';
    dataWriter : for ct in 1 to 128 loop
      data_re <= std_logic_vector(to_signed(-256*ct, 16));
      data_im <= std_logic_vector(to_signed(256*ct-1, 16));
      if ct = 128 then
        data_last <= '1';
      else
        data_last <= '0';
      end if;
      wait until rising_edge(clk);
    end loop;

    data_vld <= '0';
    data_last <= '0';

    wait for 100ns;
    testBench_state <= FINISHED;
    stop_the_clocks <= true;
    wait;
  end process;

  check : process
  begin
    --Check the output result
    --Value calculated in Julia with
    -- kernel = 256*(1:128)-1 + 1im*(1:128)
    -- data = -256*(1:128) + 1im*(256(1:128)-1)
    -- floor(sum(kernel .* data) / 2^13) % assuming RAW_KERNEL_ADDR_WIDTH = 12 and extra bit from ComplexMultiplier
    -- = -5679955 + 5635494im
    --
    wait until rising_edge(result_vld);
    assert to_integer(signed(result_re)) = -5679955 report "KernelIntegrator real output incorrect!";
    assert to_integer(signed(result_im)) = 5635494 report "KernelIntegrator real output incorrect!";

    wait;

  end process;

end;
