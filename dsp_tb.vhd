-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- use work.x6_pkg.all;

entity dsp_testbench is
end dsp_testbench;

architecture behavior of dsp_testbench is

-- Clock period definitions
constant clk_period : time := 10 ns;
constant fs_period : time := 12 ns;

signal clk : std_logic := '0';
signal fs_clk : std_logic := '0';
signal rst : std_logic := '1';

-- wishbone signals
signal wb_adr_i : std_logic_vector(15 downto 0) := (others => '0');
signal wb_dat_i : std_logic_vector(31 downto 0) := (others => '0');
signal wb_we_i  : std_logic := '0';
signal wb_stb_i : std_logic := '0';
signal wb_ack_o : std_logic := '0';

-- ADC raw interface
signal adc0_raw_rden : std_logic := '0';
signal adc0_raw_dvld  : std_logic := '0';
signal adc0_raw_vld  : std_logic := '0';
signal adc0_raw_data : std_logic_vector(47 downto 0) := (others => '0');
signal adc0_raw_dout : std_logic_vector(11 downto 0) := (others => '0');

signal adc1_raw_rden : std_logic := '0';
signal adc1_raw_dvld  : std_logic := '0';
signal adc1_raw_vld  : std_logic := '0';
signal adc1_raw_data : std_logic_vector(47 downto 0) := (others => '0');
signal adc1_raw_dout : std_logic_vector(11 downto 0) := (others => '0');

-- DSP VITA interface
signal ofifo_empty  : std_logic_vector(1 downto 0) := "00";
signal ofifo_aempty : std_logic_vector(1 downto 0) := "00";
signal ofifo_rden   : std_logic_vector(1 downto 0) := "00";
signal ofifo_vld    : std_logic_vector(1 downto 0) := "00";
signal dsp0_dout    : std_logic_vector(127 downto 0) := (others => '0');
signal dsp1_dout    : std_logic_vector(127 downto 0) := (others => '0');

type testbench_states is (RESETTING, WB_WRITE, RUNNING, STOPPING);
signal testbench_state : testbench_states := RESETTING;

component afifo_1k48x12
  port (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
end component;

begin

-- Clock process definitions
clk_process :process
begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
end process;

fs_clk_process :process
begin
	fs_clk <= '0';
	wait for fs_period/2;
	fs_clk <= '1';
	wait for fs_period/2;
end process;

-- data processes
adc01_data : process( fs_clk )
	variable cnt : natural := 0;
	variable cnt_slv0 : std_logic_vector(11 downto 0) := (others => '0');
	variable cnt_slv1 : std_logic_vector(11 downto 0) := (others => '0');
	variable cnt_slv2 : std_logic_vector(11 downto 0) := (others => '0');
	variable cnt_slv3 : std_logic_vector(11 downto 0) := (others => '0');
begin
	if rising_edge(fs_clk) then
		if (rst = '1') or (testbench_state /= RUNNING) then
			adc0_raw_data <= (others => '0');
			adc0_raw_dvld <= '0';
			adc1_raw_data <= (others => '0');
			adc1_raw_dvld <= '0';
		else -- RUNNING
			cnt_slv0 := std_logic_vector(to_signed(cnt+0, 12));
			cnt_slv1 := std_logic_vector(to_signed(cnt+1, 12));
			cnt_slv2 := std_logic_vector(to_signed(cnt+2, 12));
			cnt_slv3 := std_logic_vector(to_signed(cnt+3, 12));
			adc0_raw_data <= cnt_slv0 & cnt_slv1 & cnt_slv2 & cnt_slv3;
			adc0_raw_dvld <= '1';
			adc1_raw_data <= cnt_slv0 & cnt_slv1 & cnt_slv2 & cnt_slv3;
			adc1_raw_dvld <= '1';
			if cnt <= 1024 then
				cnt := cnt + 4;
			else
				cnt := 0;
			end if;
		end if;
	end if;
end process ; -- adc01_data

adc0_serializer : afifo_1k48x12
port map (
	rst => rst,
	wr_clk => fs_clk,
	rd_clk => clk,
	din => adc0_raw_data,
	wr_en => adc0_raw_dvld,
	rd_en => adc0_raw_rden,
	dout => adc0_raw_dout,
	valid => adc0_raw_vld
);

adc1_serializer : afifo_1k48x12
port map (
	rst => rst,
	wr_clk => fs_clk,
	rd_clk => clk,
	din => adc1_raw_data,
	wr_en => adc1_raw_dvld,
	rd_en => adc1_raw_rden,
	dout => adc1_raw_dout,
	valid => adc1_raw_vld
);

inst_dsp : entity work.ii_dsp_top
generic map (
	dsp_frmr_offset => x"0700",
	dsp_app_offset => x"0000"
)
port map (
	srst => rst,
	sys_clk => clk,

	-- Slave Wishbone Interface
	wb_rst_i => rst,
	wb_clk_i => clk,
	wb_adr_i => wb_adr_i,
	wb_dat_i => wb_dat_i,
	wb_we_i  => wb_we_i,
	wb_stb_i => wb_stb_i,
	wb_ack_o => wb_ack_o,

	-- Input serialized raw data interface
	rden(0)    => adc0_raw_rden,
	rden(1)    => adc1_raw_rden,
	din_vld(0) => adc0_raw_vld,
	din_vld(1) => adc1_raw_vld,
	din(0)     => adc0_raw_dout,
	din(1)     => adc1_raw_dout,

	-- VITA-49 Output FIFO Interface
	ofifo_empty   => ofifo_empty,
	ofifo_aempty  => ofifo_aempty,
	ofifo_rden    => ofifo_rden,
	ofifo_vld     => ofifo_vld,
	ofifo_dout(0) => dsp0_dout,
	ofifo_dout(1) => dsp1_dout
);

ofifo_rden <= not ofifo_aempty;

--  Test Bench Statements
stim_proc : process
begin
	testbench_state <= RESETTING;
	wait for 100 ns;
	
	RST <= '0';
	wait for 100 ns;

	testbench_state <= WB_WRITE;
	wb_adr_i <= X"0710";
	wb_dat_i <= x"00001000";
	wb_we_i <= '1';
	wb_stb_i <= '1';

	wait until wb_ack_o = '1';

	wb_stb_i <= '0';

	testbench_state <= RUNNING;
	wait for 2 us;

	testbench_state <= STOPPING;

	wait; -- will wait forever
end process;
--  End Test Bench 

end;
