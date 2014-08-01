library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PulseGenerator is
	generic (wb_offset : std_logic_vector(15 downto 0));
	port (
	sys_clk : in std_logic;
	reset : in std_logic;
	trigger : in std_logic;

	--
	dac_data_clk : in std_logic;
	dac_data     : out std_logic_vector(63 downto 0) ;

	--wishbone interface
	wb_rst_i       : in  std_logic;
	wb_clk_i       : in  std_logic;
	wb_adr_i       : in  std_logic_vector(15 downto 0);
	wb_dat_i       : in  std_logic_vector(31 downto 0);
	wb_we_i        : in  std_logic;
	wb_stb_i       : in  std_logic;
	wb_ack_o       : out std_logic;
	wb_dat_o       : out std_logic_vector(31 downto 0)

	) ;
end entity ; -- PulseGenerator

architecture arch of PulseGenerator is

signal control, status : std_logic_vector(31 downto 0) := (others => '0');
signal wf_length : std_logic_vector(15 downto 0) := (others => '0');

signal clk_reset, io_reset : std_logic := '0';
signal ddr_clk : std_logic;

signal dac_data : std_logic_vector(63 downto 0) ;

signal wf_wr_addr, wf_wr_data : std_logic_vector(31 downto 0) ;
signal wf_wr_we : std_logic;
signal wf_rd_addr : unsigned(11 downto 0) ;



begin

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
    clkb => dac_data_clk,
    addrb => std_logic_vector(wf_rd_addr),
    doutb => dac_data
  );

--Playback logic SM
playback : process( dac_data_clk )
type state_t is (IDLE, PLAYING);
variable state : state_t;
begin
	if rising_edge(dac_data_clk) then
		case( state ) is
				
					when IDLE =>
						--wait for trigger
						wf_rd_addr <= (others => '0');
						if trigger = '1' then
							state := PLAYING;
						end if;

					when PLAYING =>
						wf_rd_addr <= wf_rd_addr + 1;
						if wf_rd_addr = unsigned(wf_length(12 downto 0)) then
							state := IDLE;
						end if;

					when others =>
						null;
				
				end case ;		
	end if ;
end process ; -- playback

end architecture ; -- arch