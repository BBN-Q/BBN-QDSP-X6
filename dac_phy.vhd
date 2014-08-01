library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Interface to the PHY layer of the DAC
-- Takes clock from DAC and returns data with clock
-- Provides divided clock to input wide data on too
-- Also handles SPI comms from wishbone registers

entity dac_phy is
  port (
  	reset : in std_logic;
  	sys_clk : in std_logic;

	--clock lines from DAC chip
	clk_in_p : in std_logic;
	clk_in_n : in std_logic;

	--data and clock out to DAC
	data_out_p : in std_logic_vector(15 downto 0) ;
	data_out_n : in std_logic_vector(15 downto 0) ;
	clk_out_p : std_logic;
	clk_out_n : std_logic;

	--Data in to be serialized
	data_clk : out std_logic;
	data : in std_logic_vector(63 downto 0);

	--SPI wishbone
    spi_access_strb      : in  std_logic;
    spi_wdata            : in  std_logic_vector(7 downto 0);
    spi_addr             : in  std_logic_vector(4 downto 0);
    spi_rd_wrn           : in  std_logic;
    spi_rdy              : out std_logic;
    spi_rdata_valid      : out std_logic;
    spi_rdata            : out std_logic_vector(7 downto 0);

    -- spi serial interface
    spi_sclk         : out std_logic;
    spi_sdenb        : out std_logic;
    spi_sdio         : inout std_logic
  ) ;
end entity ; -- dac_phy

architecture arch of dac_phy is

begin

--Serialization
dac_gear_out : entity work.DAC_SEROUT
  port map	(
  -- From the device out to the system
  DATA_OUT_FROM_DEVICE => data, --Input pins
  DATA_OUT_TO_PINS_P => data_out_p, --Output pins
  DATA_OUT_TO_PINS_N => data_out_n, --Output pins
  CLK_TO_PINS_P      => clk_out_p, --Output pins
  CLK_TO_PINS_N      => clk_out_n, --Output pins

	-- Clock and reset signals
  CLK_IN_P => clk_in_p,     -- Differential clock from IOB
  CLK_IN_N => clk_in_n,     -- Differential clock from IOB
  CLK_DIV_OUT => data_clk,     -- Slow clock output
  CLK_RESET => reset,         --clocking logic reset
  IO_RESET =>  reset         --system reset
);

--Connect the wishbone to spi interface
wb2spi : entity work.wishbone2spi
port map(
    srst => reset,
    sys_clk => sys_clk,

    -- User interface
    spi_access_strb => spi_access_strb,
    spi_wdata => spi_wdata,
    spi_addr => spi_addr,
    spi_rd_wrn => spi_rd_wrn,
    spi_rdy => spi_rdy,
    spi_rdata_valid => spi_rdata_valid,
    spi_rdata => spi_rdata,

    -- dac spi interface
    spi_sclk => spi_sclk,
    spi_sdenb => spi_sdenb,
    spi_sdio => spi_sdio
);

end architecture ; -- arch