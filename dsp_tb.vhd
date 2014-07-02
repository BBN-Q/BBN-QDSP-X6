-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
-- use work.x6_pkg.all;

entity dsp_testbench is
end dsp_testbench;

architecture behavior of dsp_testbench is

-- Clock period definitions
constant clk_period : time := 10 ns;
constant fs_period : time := 12 ns;

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
signal ofifo_rden   : std_logic := '0';
signal ofifo_vld    : std_logic := '0';
signal dsp_dout     : std_logic_vector(127 downto 0) := (others => '0');

--Decision Engine interface
signal state : std_logic_vector(1 downto 0) := "00";

type testbench_states is (RESETTING, WB_WRITE, RUNNING, STOPPING);
signal testbench_state : testbench_states := RESETTING;

type DataArray_t is array(natural range <>) of std_logic_vector(31 downto 0);
constant allOnes : DataArray_t(0 to frame_size/decimation_factor - 1) := (others => (31 => '0', 15 => '0', others => '1'));

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
			if cnt <= 4*frame_size then
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
	muxed_vita_rden => ofifo_rden,
	muxed_vita_vld  => ofifo_vld,
	muxed_vita_data => dsp_dout,

    -- Decision Engine outputs
    state => state
);

ofifo_rden <= ofifo_vld;

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
		physChan : in natural;
		demodChan : in natural;
		dataArray : in DataArray_t) is

	variable wbOffset : natural := 8192 + physChan*256 + 48 + 2*demodChan;
	begin
		for ct in dataArray'range loop
			wb_write(wbOffset, ct);
			wb_write(wbOffset+1, dataArray(ct));
		end loop;
	end procedure;


begin
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
			wb_write(8192 + phys*256 + demod, frame_size/decimation_factor);
			wb_write(8192 + phys*256 + 32 + demod, 256*(phys+1) + 16*demod);
		end loop;

		--write integration kernels
		for demod in 0 to 1 loop
			wb_write(8192 + phys*256 + 24 + demod, frame_size/decimation_factor);
			write_kernel(phys, demod, allOnes);
		end loop;
	end loop;

	testbench_state <= RUNNING;
	wait for fs_period*frame_size/2;

	testbench_state <= STOPPING;

	wait; -- will wait forever
end process;
--  End Test Bench 

end;
