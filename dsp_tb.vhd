-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

use work.FileIO.all;

library work;
-- use work.x6_pkg.all;

entity dsp_testbench is
end dsp_testbench;

architecture behavior of dsp_testbench is

-- Clock period definitions
constant clk_period : time := 5 ns;
constant fs_period : time := 4 ns;

constant frame_size : integer := 256;
constant decimation_factor : integer := 4;

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
signal adc0_raw_dvld : std_logic := '0';
signal adc0_raw_vld  : std_logic := '0';
signal adc0_raw_vld_d: std_logic := '0';
signal adc0_raw_data : std_logic_vector(47 downto 0) := (others => '0');
signal adc0_raw_dout : std_logic_vector(11 downto 0) := (others => '0');
signal adc0_frame    : std_logic := '0'; 

signal adc1_raw_rden : std_logic := '0';
signal adc1_raw_dvld : std_logic := '0';
signal adc1_raw_vld  : std_logic := '0';
signal adc1_raw_vld_d: std_logic := '0';
signal adc1_raw_data : std_logic_vector(47 downto 0) := (others => '0');
signal adc1_raw_dout : std_logic_vector(11 downto 0) := (others => '0');
signal adc1_frame    : std_logic := '0';

-- DSP VITA interface
signal vita_rden   : std_logic := '0';
signal vita_vld    : std_logic := '0';
signal vita_dout     : std_logic_vector(127 downto 0) := (others => '0');

--Trigger the input
signal trigger : std_logic := '0';

--Decision Engine interface
signal state : std_logic_vector(1 downto 0) := "00";

type testbench_states is (RESETTING, WB_WRITE, RUNNING, STOPPING);
signal testbench_state : testbench_states := RESETTING;

type KernelArray_t is array(natural range <>) of std_logic_vector(31 downto 0);
constant allOnes : KernelArray_t(0 to 2*frame_size/decimation_factor - 1) := (others => (31 => '0', 15 => '0', others => '1'));

signal testData0 : WFArray_t(0 to num_lines("testWFs.in")-1);

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
	variable wfct : natural := 0;
	type PLAYSTATE_t is (WAITING, PLAYING);
	variable playState : PLAYSTATE_t;
begin
	if rising_edge(fs_clk) then
		if (rst = '1') or (testbench_state /= RUNNING) then
			adc0_raw_data <= (others => '0');
			adc0_raw_dvld <= '0';
			adc1_raw_data <= (others => '0');
			adc1_raw_dvld <= '0';
			playState := WAITING;
			wfct := 0;
			cnt := 0;
		else -- RUNNING

			case( playState ) is
			
				when WAITING =>
					cnt := 0;
					adc0_raw_data <= (others => '0');
					adc0_raw_dvld <= '0';
					if trigger = '1' then
						playState := PLAYING;
					end if;

				when PLAYING =>
					adc0_raw_data <= testData0(wfct)(cnt) & testData0(wfct)(cnt+1) & testData0(wfct)(cnt+2) & testData0(wfct)(cnt+3);
					adc0_raw_dvld <= '1';
					cnt := cnt + 4;

	
				when others =>
					playState := WAITING;
			end case ;
		end if;
	end if;
end process ; -- adc01_data

--output to file process
vita2stream : process( clk )
file FID : text open write_mode is "vitastream.out";
variable ln : line;
begin
	if rising_edge(clk) then
		--Write vita stream to file
		if vita_vld = '1' then
			write(ln, vita_dout);
			writeline(FID, ln);
		end if;
	end if ;
end process ; -- vita2stream

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

--Deserialized frame creator
adc0_frame <= adc0_raw_vld and adc0_raw_vld_d;
adc1_frame <= adc1_raw_vld and adc1_raw_vld_d;
frameDeser : process( clk )
begin
if rising_edge(clk) then
  adc0_raw_vld_d <= adc0_raw_vld;
  adc1_raw_vld_d <= adc1_raw_vld;
end if ;
end process ; -- frameDeser

inst_dsp : entity work.ii_dsp_top
generic map (
	dsp_app_offset => x"2000"
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
	rden    => adc0_raw_rden,
	din_vld => adc0_raw_vld,
	din     => adc0_raw_dout,
	frame_in   => adc0_frame,

	-- VITA-49 Output FIFO Interface
	muxed_vita_rden => vita_rden,
	muxed_vita_vld  => vita_vld,
	muxed_vita_data => vita_dout,

    -- Decision Engine outputs
    state => state
);

vita_rden <= '1';

--  Test Bench Statements
stim_proc : process

	procedure wb_write(
		addr : in std_logic_vector(15 downto 0);
		data : in std_logic_vector(31 downto 0) ) is 
	begin
		wb_adr_i <= addr;
		wb_dat_i <= data;
		wb_we_i <= '1';
		wb_stb_i <= '1';

		wait until wb_ack_o = '1';
		wb_stb_i <= '0';
		wait until rising_edge(clk);

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

	procedure write_kernel(
		phys : in natural;
		demod : in natural;
		dataArray : in KernelArray_t) is

	variable wbOffset : natural := 8192 + phys*256 + 48 + 2*demod;
	begin
		wb_write(8192 + phys*256 + 24 + demod, dataArray'length);
		for ct in dataArray'range loop
			wb_write(wbOffset, ct);
			wb_write(wbOffset+1, dataArray(ct));
		end loop;
	end procedure;


begin
	--For some reason if I initialize this signal at definition the funciton is not called.
	testData0 <= read_wf_file("../II-Readout-Filter/testWFs.in");


	testbench_state <= RESETTING;
	wait for 100 ns;
	
	rst <= '0';
	wait for 100 ns;

	testbench_state <= WB_WRITE;
	for phys in 0 to 0 loop
		-- write the phase increments
		for demod in 0 to 1 loop
			wb_write(8192 + phys*256 + 16 + demod, (2*phys+demod+1)* 10486);
		end loop;

		-- write frame sizes and stream IDs
		wb_write(8192 + phys*256, frame_size);
		wb_write(8192 + phys*256 + 32, 256*(phys+1));
		for demod in 1 to 2 loop
			wb_write(8192 + phys*256 + demod, 2*frame_size/decimation_factor);
			wb_write(8192 + phys*256 + 32 + demod, 256*(phys+1) + 16*demod);
		end loop;

		--write integration kernels
		for demod in 0 to 1 loop
			write_kernel(phys, demod, allOnes);
		end loop;
	end loop;

	testbench_state <= RUNNING;

	--pump the trigger every 20us
	for ct in 0 to 1 loop
		trigger <= '1';
		wait until rising_edge(clk);
		trigger <= '0';
		wait for 20 us;
	end loop;

	testbench_state <= STOPPING;

	wait; -- will wait forever
end process;
--  End Test Bench 

end;
