library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use work.bbn_qdsp_pkg.KERNEL_ADDR_WIDTH;

entity KernelIntegrator_tb is
end;

architecture bench of KernelIntegrator_tb is

  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal data_re, data_im : std_logic_vector(15 downto 0) := (others => '0');
  signal data_vld, data_last : std_logic := '0';
  signal kernel_len: std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(128, KERNEL_ADDR_WIDTH));
  signal kernel_wr_addr: std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0);
  signal kernel_wr_data: std_logic_vector(31 downto 0);
  signal kernel_we: std_logic := '0';
  signal kernel_wr_clk: std_logic := '0';
  signal result_re, result_im : std_logic_vector(31 downto 0) := (others => '0');
  signal result_vld: std_logic;

  constant CLK_PERIOD: time := 10 ns;
  constant WB_CLK_PERIOD : time := 20 ns;
  signal finished : boolean := false;

begin

  --Clocking
  clk <= not clk after CLK_PERIOD/2 when not finished;
  kernel_wr_clk <= not kernel_wr_clk after WB_CLK_PERIOD when not finished;

  uut: entity work.KernelIntegrator
    port map (
      rst => rst,
      clk            => clk,
      data_re        => data_re,
      data_im        => data_im,
      data_vld       => data_vld,
      data_last      => data_last,
      kernel_len     => kernel_len,
      kernel_wr_addr => kernel_wr_addr,
      kernel_wr_data => kernel_wr_data,
      kernel_we      => kernel_we,
      kernel_wr_clk  => kernel_wr_clk,
      result_re      => result_re,
      result_im      => result_im,
      result_vld     => result_vld );

  stimulus: process
  begin

    -- Reset
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait for 5 ns;

    -- Load the kernel memory
    wait until rising_edge(kernel_wr_clk);
    memoryWriter : for ct in 0 to to_integer(unsigned(kernel_len))-1 loop
      kernel_wr_addr <= std_logic_vector(to_unsigned(ct, KERNEL_ADDR_WIDTH));
      --For now load ramp
      kernel_wr_data <= std_logic_vector(to_signed(256*ct, 16)) & std_logic_vector(to_signed(ct, 16));
      kernel_we <= '1';
      wait until rising_edge(kernel_wr_clk);
      kernel_we <= '0';
      wait for 10ns;
    end loop;

    --Clock in the data
    wait until rising_edge(clk);
    data_vld <= '1';
    dataWriter : for ct in 0 to 127 loop
      data_re <= std_logic_vector(to_signed(-256*ct, 16));
      data_im <= std_logic_vector(to_signed(256*ct, 16));
      if ct = 127 then
        data_last <= '1';
      else
        data_last <= '0';
      end if;
      wait until rising_edge(clk);
    end loop;

    data_vld <= '0';
    data_last <= '0';

    wait for 100ns;
    finished <= true;
    wait;
  end process;

  check : process
  begin
    --Check the output result
    --Value calculated in Julia with
    -- kernel = 256*(0:127) + 1im*(0:127)
    -- data = -256*(0:127) + 1im*256(0:127)
    -- prodData = (kernel .* data)
    -- sum(floor(real(prodData/2^16)) + 1im*floor(imag(prodData/2^16)))
    -- = -693646.0 + 688114.0im
    --
    -- Note this has significant rounding errors
    --  sum((prodData/2^16))
    -- = -693578.75 + 688181.25im

    wait until rising_edge(result_vld);
    assert to_integer(signed(result_re)) = -693646 report "KernelIntegrator real output incorrect!";
    assert to_integer(signed(result_im)) = 688114 report "KernelIntegrator real output incorrect!";

    wait;


  end process;


end;
