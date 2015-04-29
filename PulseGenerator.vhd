library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PulseGenerator is
	generic (wb_offset : std_logic_vector(15 downto 0));
	port (
	sys_clk : in std_logic;
	reset : in std_logic;
	trigger : in std_logic;

	-- DAC sample interface
	dac_data       : out std_logic_vector(63 downto 0) ;
	dac_data_wr_en : out std_logic;
	dac_data_rdy   : in std_logic;

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
my_wf_bram : entity work.WF_BRAM
  PORT MAP (
    clka => sys_clk,
    wea(0) => wf_we,
    addra => wf_addr_wr(12 downto 0),
    dina => wf_data_wr,
    douta => wf_data_rd,
    clkb => sys_clk,
    web(0)  => '0',
    addrb => std_logic_vector(wf_addr_rd),
    dinb => (others => '0'),
    doutb => dac_data
  );

--Playback logic
-- since the data is FIFO'd in the DAC_PHY just push it on when possible
playback : process( sys_clk )
begin
	if rising_edge(sys_clk) then
		if reset = '1' then
			wf_addr_rd <= (others => '0');
			dac_data_wr_en <= '0';
		else
			if dac_data_rdy = '1' then
				wf_addr_rd <= wf_addr_rd + 1;
				dac_data_wr_en <= '1';
				
				if wf_addr_rd = unsigned(wf_length(12 downto 0)) then
					wf_addr_rd <= (others => '0');
				end if;
			else
				dac_data_wr_en <= '0';
			end if;
		end if;
	end if ;
end process ; -- playback

end architecture ; -- arch