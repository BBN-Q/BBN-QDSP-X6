library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PulseGenerator is
	generic (WB_OFFSET : std_logic_vector(15 downto 0));
	port (
	-- DAC sample interface
	dac_clk : in std_logic;
	rst : in std_logic;
	trigger : in std_logic;

	dac_data       : out std_logic_vector(63 downto 0) ;

	--wishbone interface
	wb_rst_i       : in  std_logic;
	wb_clk_i       : in  std_logic;
	wb_adr_i       : in  std_logic_vector(15 downto 0);
	wb_dat_i       : in  std_logic_vector(31 downto 0);
	wb_we_i        : in  std_logic;
	wb_stb_i       : in  std_logic;
	wb_ack_o       : out std_logic;
	wb_dat_o       : out std_logic_vector(31 downto 0);

	wf_rd_addr_copy    : out std_logic_vector(15 downto 0)
	) ;
end entity ; -- PulseGenerator

architecture arch of PulseGenerator is

signal control, status : std_logic_vector(31 downto 0) := (others => '0');
signal wf_length : std_logic_vector(15 downto 0) := (others => '0');

signal wf_addr_wr, wf_data_wr, wf_data_rd : std_logic_vector(31 downto 0) ;
signal wf_we : std_logic;
signal wf_addr_rd : unsigned(11 downto 0) ;
signal wf_data : std_logic_vector(63 downto 0);

signal wf_vld, wf_vld_d : std_logic := '0';

type state_t is (IDLE, PLAYING);
signal state : state_t := IDLE;

begin

--send waveform read address out as a debug signal
wf_rd_addr_copy(15 downto 12) <= (others => '0');
wf_rd_addr_copy(11 downto 0) <= std_logic_vector(wf_addr_rd);

--Wishbone registers

	inst_pg_regs : entity work.pg_wb_regs
	generic map (
		offset      => wb_offset
	)
	port map (
		-- Wishbone interface signals
		wb_rst_i    => wb_rst_i,
		wb_clk_i    => wb_clk_i,
		wb_adr_i    => wb_adr_i,
		wb_dat_i    => wb_dat_i,
		wb_we_i     => wb_we_i,
		wb_stb_i    => wb_stb_i,
		wb_ack_o    => wb_ack_o,
		wb_dat_o    => wb_dat_o,

		-- User registers
		control     => control,
		status      => status,
		wf_length   => wf_length,
		wf_addr     => wf_addr_wr,
		wf_data_out => wf_data_wr,
		wf_we       => wf_we,
		wf_data_in  => wf_data_rd
	);

--WF BRAM
--Irritatingly XST cannot infer a large asymmetrical block RAM so have to use an IP core
--INFO:Xst:3229 - The RAM description <Mram_wf_RAM> will not be implemented on the device block RAM because actual implementation does not support asymetric block RAM larger than one block.
my_wf_bram : entity work.WF_BRAM
  PORT MAP (
    clka => wb_clk_i,
    wea(0) => wf_we,
    addra => wf_addr_wr(12 downto 0),
    dina => wf_data_wr,
    douta => wf_data_rd,
    clkb => dac_clk,
    web(0)  => '0',
    addrb => std_logic_vector(wf_addr_rd),
    dinb => (others => '0'),
    doutb => wf_data
  );

--Playback state machine
playback : process( dac_clk )
variable ct : unsigned(16 downto 0);
begin
	if rising_edge(dac_clk) then
		if rst = '1' then
			wf_addr_rd <= (others => '1');
			ct := resize(unsigned(wf_length(wf_length'high downto 1)) - 2, 17); --divide by two because take 4 samples per clock
			state <= IDLE;
			wf_vld <= '0';
		else
			wf_vld <= '0'; --default
			case( state ) is

				when IDLE =>
					wf_addr_rd <= (others => '1');
					ct := resize(unsigned(wf_length(wf_length'high downto 1)) - 2, 17); --divide by two because take 4 samples per clock

					if trigger = '1' then
						state <= PLAYING;
					end if;

				when PLAYING =>
					wf_vld <= '1';
					wf_addr_rd <= wf_addr_rd + 1;
					if ct(ct'high) = '1' then
						state <= IDLE;
					end if;
					ct := ct - 1;

			end case;
		end if;
	end if ;
end process ; -- playback

--Mux between zero and wf data
--We need a delay line for the valid for address update the output registers in BRAM
delayLine_wf_vld : entity work.DelayLine
generic map(DELAY_TAPS => 2)
port map(clk => dac_clk, rst => rst, data_in(0) => wf_vld, data_out(0) => wf_vld_d);

zeroMux : process(dac_clk)
begin
	if rising_edge(dac_clk) then
		if rst = '1' then
			dac_data <= (others => '0');
		else
			if wf_vld_d = '1' then
				dac_data <= wf_data;
			else
				dac_data <= (others => '0');
			end if;
		end if;
	end if;
end process;

end architecture ; -- arch
