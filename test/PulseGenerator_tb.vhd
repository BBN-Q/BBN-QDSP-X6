library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity PulseGenerator_tb is
end;

architecture bench of PulseGenerator_tb is

  constant WB_OFFSET : std_logic_vector(15 downto 0) := x"2200";

  signal rst : std_logic := '0';
  signal dac_clk : std_logic := '0';
  signal trigger : std_logic := '0';

  signal wb_rst_i : std_logic := '0';
  signal wb_clk : std_logic := '0';
  signal wb_adr_i : std_logic_vector(15 downto 0) := (others => '0');
  signal wb_dat_i : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_we_i : std_logic := '0';
  signal wb_stb_i : std_logic := '0';
  signal wb_ack_o : std_logic := '0';
  signal wb_dat_o : std_logic_vector(31 downto 0) := (others => '0');

  constant DAC_CLK_PERIOD: time := 4 ns;
  constant WB_CLK_PERIOD : time := 10 ns;
  signal stop_the_clocks : boolean := false;

  constant WF_LENGTH : natural := 256;

  signal dac_data : std_logic_vector(63 downto 0);

  type TestBenchState_t is (RESET, MEMORY_WRITE, MEMORY_READ, RUNNING, FINISHED);
  signal testBench_state : TestBenchState_t;

begin

  --Clocking
  dac_clk <= not dac_clk after DAC_CLK_PERIOD/2 when not stop_the_clocks;
  wb_clk <= not wb_clk after WB_CLK_PERIOD/2 when not stop_the_clocks;

  uut: entity work.PulseGenerator
    generic map (
      WB_OFFSET => x"2200"
    )
    port map (
      --DAC data interface
      dac_clk => dac_clk,
      rst => rst,
      trigger => trigger,

      dac_data => dac_data,

      --wishbone interface
      wb_rst_i => wb_rst_i,
      wb_clk_i => wb_clk,
      wb_adr_i => wb_adr_i,
      wb_dat_i => wb_dat_i,
      wb_we_i  => wb_we_i,
      wb_stb_i => wb_stb_i,
      wb_ack_o => wb_ack_o,
      wb_dat_o => wb_dat_o,

      wf_rd_addr_copy => open
    ) ;

  trigPro : process
  begin
  	--pump the trigger every 20us
  	while true loop
  		if testBench_state = RUNNING then
        wait until rising_edge(dac_clk);
  			trigger <= '1';
  			wait for 10ns;
  			trigger <= '0';
  			wait for 19.99 us;
  		else
        trigger <= '0';
  			wait for 1 us;
  		end if;
  	end loop;
  end process ; -- trigPro

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

    wait until rising_edge(wb_clk) and wb_ack_o = '1';
    wb_stb_i <= '0';
    wb_we_i <= '0';
    wait until rising_edge(wb_clk);

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
    rst <= '1';
    wb_rst_i <= '1';
    wait for 100ns;
    wb_rst_i <= '0';
    wait for 20ns;

    -- Load the waveform memory
    wait until rising_edge(wb_clk);
    testBench_state <= MEMORY_WRITE;
    wb_write(8704+8, WF_LENGTH);
    wfWriter : for ct in 1 to WF_LENGTH loop
      wb_write(8704+9, ct-1);
      wb_write(8704+10, std_logic_vector(to_signed(ct, 16)) & std_logic_vector(to_signed(-ct, 16)));
    end loop;

    --Read back a memory address
    wait until rising_edge(wb_clk);
    testBench_state <= MEMORY_READ;
    wb_write(8704+9, 27);
    --Address and output register delay
    for ct in 1 to 3 loop
      wait until rising_edge(wb_clk);
    end loop;
    -- Need to issue WB read somehow
    -- assert wb_dat_o = std_logic_vector(to_signed(27, 16)) & std_logic_vector(to_signed(-27, 16))
    --   report "Failed to read waveform data";

    rst <= '0';
    wait for 20ns;
    testBench_state <= RUNNING;
    wait for 100us;

    testBench_state <= FINISHED;
    stop_the_clocks <= true;
    wait;
  end process;

  check : process
  begin
    --Check the output result
    wait until rising_edge(dac_clk) and trigger = '1';
    --output delay
    for ct in 1 to 4 loop
      wait until rising_edge(dac_clk);
    end loop;

    for ct in 1 to 64 loop
      wait until rising_edge(dac_clk);
      assert dac_data = std_logic_vector(to_signed(2*ct,16)) &
                        std_logic_vector(to_signed(-2*ct,16)) &
                        std_logic_vector(to_signed(2*ct-1,16)) &
                        std_logic_vector(to_signed(-2*ct+1,16))
        report "PulseGenerator output incorrect!";
    end loop;

    wait;

  end process;

end;
