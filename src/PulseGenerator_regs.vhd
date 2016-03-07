library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BBN_X6_pkg.all;

entity PulseGenerator_regs is
	generic (
		addr_bits						: integer := 4;
		offset							 : std_logic_vector(15 downto 0)
	);
	port (
		-- Wishbone interface signals
		wb_rst_i					: in	std_logic;
		wb_clk_i					: in	std_logic;
		wb_adr_i					: in	std_logic_vector(15 downto 0);
		wb_dat_i					: in	std_logic_vector(31 downto 0);
		wb_we_i					 : in	std_logic;
		wb_stb_i					: in	std_logic;
		wb_ack_o					: out std_logic;
		wb_dat_o					: out std_logic_vector(31 downto 0);

		-- User registers
		control					 : out std_logic_vector(31 downto 0);
		status						: in std_logic_vector(31 downto 0);
		wf_length				 : out std_logic_vector(15 downto 0);

		wf_addr					 : out std_logic_vector(31 downto 0) ;
		wf_data_out			 : out std_logic_vector(31 downto 0) ;
		wf_we						 : out std_logic;
		wf_data_in				: in std_logic_vector(31 downto 0)
	);
end PulseGenerator_regs;

architecture arch of PulseGenerator_regs is

	component ii_regs_core
		generic (
			addr_bits						: integer;
			offset							 : std_logic_vector(15 downto 0)
		);
		port (
			-- Wishbone slave interface
			wb_rst_i						 : in	std_logic;
			wb_clk_i						 : in	std_logic;
			wb_adr_i						 : in	std_logic_vector(15 downto 0);
			wb_dat_i						 : in	std_logic_vector(31 downto 0);
			wb_we_i							: in	std_logic;
			wb_stb_i						 : in	std_logic;
			wb_ack_o						 : out std_logic;
			wb_dat_o						 : out std_logic_vector(31 downto 0);
			-- Core to slave register interface signals
			wr_stb							 : out std_logic_vector(2**addr_bits-1 downto 0);
			rd_stb							 : out std_logic_vector(2**addr_bits-1 downto 0);
			wb_reg_init_core		 : in	std_logic_vector((2**addr_bits*32)-1 downto 0);
			wb_reg_i_core				: in	std_logic_vector((2**addr_bits*32)-1 downto 0);
			wb_reg_o_core				: out std_logic_vector((2**addr_bits*32)-1 downto 0)
		);
	end component;

	constant addr_range				 : integer := 2**addr_bits;

	subtype wb_reg_width is std_logic_vector(31 downto 0);
	type wb_reg_t is array (addr_range-1 downto 0) of wb_reg_width;
	constant WB_REG_ZEROS			 : wb_reg_width := (others => '0');

	signal wr_stb							 : std_logic_vector(addr_range-1 downto 0);
	signal rd_stb							 : std_logic_vector(addr_range-1 downto 0);
	signal wb_reg_init					: wb_reg_t := (others => WB_REG_ZEROS);
	signal wb_reg_i						 : wb_reg_t;
	signal wb_reg_o						 : wb_reg_t;
	signal wb_reg_i_slv				 : std_logic_vector((addr_range*32)-1 downto 0);
	signal wb_reg_o_slv				 : std_logic_vector((addr_range*32)-1 downto 0);
	signal wb_reg_init_slv			: std_logic_vector((addr_range*32)-1 downto 0);

	begin

	-- Form incoming and outgoing data array
	process (wb_reg_i, wb_reg_i_slv, wb_reg_init)
	begin
		for i in 1 to addr_range loop
			wb_reg_o_slv((i*32)-1 downto (i-1)*32) <= wb_reg_i(i-1);
			wb_reg_init_slv((i*32)-1 downto (i-1)*32) <= wb_reg_init(i-1);
			wb_reg_o(i-1) <= wb_reg_i_slv((i*32)-1 downto (i-1)*32);
		end loop;
	end process;

	inst_core: ii_regs_core
		generic map (
			addr_bits						=> addr_bits,
			offset							 => offset
		)
		port map(
			wb_rst_i						 => wb_rst_i,
			wb_clk_i						 => wb_clk_i,
			wb_adr_i						 => wb_adr_i,
			wb_dat_i						 => wb_dat_i,
			wb_we_i							=> wb_we_i,
			wb_stb_i						 => wb_stb_i,
			wb_ack_o						 => wb_ack_o,
			wb_dat_o						 => wb_dat_o,
			wr_stb							 => wr_stb,
			rd_stb							 => rd_stb,
			wb_reg_init_core		 => wb_reg_init_slv,
			wb_reg_i_core				=> wb_reg_o_slv,
			wb_reg_o_core				=> wb_reg_i_slv
		);

	-- ************************************************************************
	-- All the assignments below this line can be modified according to the
	-- required register map.

	control <= wb_reg_o(0);
	wb_reg_i(0) <= wb_reg_o(0);

	wb_reg_i(1) <= status;

	wb_reg_i(2) <= BBN_X6_VERSION;

	wf_length <= wb_reg_o(8)(15 downto 0);
	wb_reg_i(8) <= wb_reg_o(8);

	--Use addr 9/10 for the addr/data of the pulse block RAM
	wf_addr <= wb_reg_o(9);
	wb_reg_i(9) <= wb_reg_o(9); --copy address back for reads
	wf_data_out <= wb_reg_o(10);
	wb_reg_i(10) <= wf_data_in;

	--use the write strobe of the data as write enable for BRAM
	wf_we <= wr_stb(10);

end arch;
