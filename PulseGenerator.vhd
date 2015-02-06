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

signal wf_wr_addr, wf_wr_data : std_logic_vector(31 downto 0) ;
signal wf_wr_we : std_logic;
signal wf_rd_addr : unsigned(11 downto 0) ;

begin

wf_rd_addr_copy(15 downto 12) <= (others => '0');
wf_rd_addr_copy(11 downto 0) <= std_logic_vector(wf_rd_addr);

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
		wf_wr_addr  => wf_wr_addr,
		wf_wr_data  => wf_wr_data,
		wf_wr_we    => wf_wr_we
	);


--WF BRAM
my_wf_bram : entity work.WF_BRAM
  PORT MAP (
    clka => sys_clk,
    wea(0) => wf_wr_we,
    addra => wf_wr_addr(12 downto 0),
    dina => wf_wr_data,
    clkb => sys_clk,
    addrb => std_logic_vector(wf_rd_addr),
    doutb => dac_data
  );

--Playback logic
-- since the data is FIFO'd in the DAC_PHY just push it on when possible
playback : process( sys_clk )
begin
	if rising_edge(sys_clk) then
		if reset = '1' then
			wf_rd_addr <= (others => '0');
			dac_data_wr_en <= '0';
		else
			if dac_data_rdy = '1' then
				wf_rd_addr <= wf_rd_addr + 1;
				dac_data_wr_en <= '1';
				
				if wf_rd_addr = unsigned(wf_length(12 downto 0)) then
					wf_rd_addr <= (others => '0');
				end if;
			end if;
		end if;
	end if ;
end process ; -- playback

end architecture ; -- arch