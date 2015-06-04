library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use work.BBN_QDSP_pkg.NUM_DEMOD_CH;

entity BBN_QDSP_tb is
end;

architecture bench of BBN_QDSP_tb is

  signal sys_clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal trigger : std_logic := '0';
  signal wb_rst_i : std_logic := '0';
  signal wb_clk_i : std_logic := '0';
  signal wb_adr_i : std_logic_vector(15 downto 0) := (others => '0');
  signal wb_dat_i : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_we_i : std_logic := '0';
  signal wb_stb_i : std_logic := '0';
  signal wb_ack_o : std_logic := '0';
  signal wb_dat_o : std_logic_vector(31 downto 0) := (others => '0');
  signal adc_data_clk : std_logic := '0';
  signal adc_data : std_logic_vector(47 downto 0) := (others => '0');
  signal muxed_vita_wrd_cnt : std_logic_vector(8 downto 0) := (others => '0');
  signal muxed_vita_aempty : std_logic := '0';
  signal muxed_vita_empty : std_logic := '0';
  signal muxed_vita_rden : std_logic := '0';
  signal muxed_vita_vld : std_logic := '0';
  signal muxed_vita_data : std_logic_vector(127 downto 0) := (others => '0');
  signal state : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');
  signal state_vld : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

  constant SYS_CLK_PERIOD : time := 5 ns;
  constant ADC_CLK_PERIOD : time := 4 ns;
  signal stop_the_clocks: boolean := false;

  type TestBenchState_t is (RESET, WB_WRITES, FINISHED);
  signal testBench_state : TestBenchState_t;

begin

  wb_clk_i <= sys_clk;
  wb_rst_i <= rst;

  uut: entity work.BBN_QDSP_top
  generic map ( WB_OFFSET => x"2000" )
  port map (
    sys_clk            => sys_clk,
    rst                => rst,
    trigger            => trigger,
    wb_rst_i           => wb_rst_i,
    wb_clk_i           => wb_clk_i,
    wb_adr_i           => wb_adr_i,
    wb_dat_i           => wb_dat_i,
    wb_we_i            => wb_we_i,
    wb_stb_i           => wb_stb_i,
    wb_ack_o           => wb_ack_o,
    wb_dat_o           => wb_dat_o,
    adc_data_clk       => adc_data_clk,
    adc_data           => adc_data,
    muxed_vita_wrd_cnt => muxed_vita_wrd_cnt,
    muxed_vita_aempty  => muxed_vita_aempty,
    muxed_vita_empty   => muxed_vita_empty,
    muxed_vita_rden    => muxed_vita_rden,
    muxed_vita_vld     => muxed_vita_vld,
    muxed_vita_data    => muxed_vita_data,
    state              => state,
    state_vld          => state_vld );

  stimulus: process
  --Scoped procedures for WB writes
  procedure wb_write(
    addr : in std_logic_vector(15 downto 0);
    data : in std_logic_vector(31 downto 0) ) is
  begin
    wb_adr_i <= addr;
    wb_dat_i <= data;
    wb_we_i <= '1';
    wb_stb_i <= '1';

    wait until rising_edge(wb_clk_i) and wb_ack_o = '1';
    wb_stb_i <= '0';
    wb_we_i <= '0';
    wait until rising_edge(wb_clk_i);

  end procedure wb_write;

  procedure wb_write(
    addr : in natural;
    data : in natural ) is
  begin
    wb_write(std_logic_vector(to_unsigned(addr, 16)), std_logic_vector(to_unsigned(data, 32)) );
  end procedure;

  procedure wb_write(
    addr : in natural;
    data : in std_logic_vector(31 downto 0) ) is
  begin
    wb_write(std_logic_vector(to_unsigned(addr, 16)), data);
  end procedure;

  begin

    --Initial reset
    testBench_state <= RESET;
    rst <= '1';
    wait for 100ns;
    rst <= '0';
    wait for 20ns;

    testbench_state <= WB_WRITES;
  	for phys in 0 to 0 loop
  		-- write the phase increments for the NCO's
  		for demod in 0 to 1 loop
  			wb_write(8192 + phys*256 + 16 + demod, (2*phys+demod+1)* 10486);
  		end loop;

  		-- -- write frame sizes and stream IDs
  		-- wb_write(8192 + phys*256, FRAME_SIZE+8);
  		-- wb_write(8192 + phys*256 + 32, 65536 + 256*(phys+1));
  		-- for demod in 1 to 2 loop
  		-- 	wb_write(8192 + phys*256 + demod, 2*FRAME_SIZE/DECIMATION_FACTOR+8); --factor of 2 for complex demod stream
  		-- 	wb_write(8192 + phys*256 + 32 + demod, 65536 + 256*(phys+1) + 16*demod);
  		-- end loop;
      --
  		-- wb_write(8192 + phys*256 + 63, RECORD_LENGTH); -- recordLength
      --
  		-- --write integration kernels
  		-- for demod in 0 to 1 loop
  		-- 	write_kernel(phys, demod, allOnes);
  		-- end loop;
  	end loop;

    testBench_state <= FINISHED;
    stop_the_clocks <= true;
    wait;
  end process;

  --clocking
  adc_data_clk <= not adc_data_clk after ADC_CLK_PERIOD / 2 when not stop_the_clocks;
  sys_clk <= not sys_clk after SYS_CLK_PERIOD /2 when not stop_the_clocks;
end;
