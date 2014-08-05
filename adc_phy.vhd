library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- Interface to the PHY layer of the ADC
-- Takes clock and data lines and returns serialized data with a divided clock
-- Also handles SPI comms from wishbone registers

entity adc_phy is
  port (
  	reset : in std_logic;
  	sys_clk : in std_logic;

    adc_reset_p : out std_logic;
    adc_reset_n : out std_logic;

  	--clock and data lines from ADC chip
  	clk_in_p : in std_logic;
  	clk_in_n : in std_logic;
  	data_in_p : in std_logic_vector(11 downto 0) ;
  	data_in_n : in std_logic_vector(11 downto 0) ;

  	--Data out to other modules
  	data_clk : buffer std_logic;
  	data_out : out std_logic_vector(47 downto 0);

    DELAY_DATA_CE        : in    std_logic_vector(11 downto 0);            -- Enable signal for delay for bit 
    REF_CLOCK            : in    std_logic;                    -- Reference Clock for IDELAYCTRL. Has to come from BUFG.

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
end entity ; -- adc_phy

architecture arch of adc_phy is

signal delay_data_ce_sync, delay_data_ce_sync_d, delay_ce_pulse : std_logic_vector(11 downto 0) ;

begin

--Differential buffer for reset
reset_buf : OBUFDS
generic map (
  IOSTANDARD    => "LVDS_25"
)
port map (
  O       => adc_reset_p,
  OB      => adc_reset_n,
  I       => reset
);


--edge detector for delay_ce on div_clk
sync_delay_ce : entity work.reg_synchronizer
generic map(REG_WIDTH => 12)
port map ( reset => reset, clk => data_clk, i_data => DELAY_DATA_CE, o_data => delay_data_ce_sync);

edge_detector : process( data_clk )
begin
  if rising_edge(data_clk) then
    delay_data_ce_sync_d <= delay_data_ce_sync;
    delay_ce_pulse <= delay_data_ce_sync and not delay_data_ce_sync_d;
  end if ;
end process ; -- edge_detector


--Deserialize the ADC data
adc_gear_in : entity work.ADC_DESIN
  port map
   (
  -- From the system into the device
  DATA_IN_FROM_PINS_P =>   data_in_p, --Input pins
  DATA_IN_FROM_PINS_N =>   data_in_n, --Input pins
  DATA_IN_TO_DEVICE =>   data_out, --Output pins

  DELAY_RESET => reset,
  DELAY_DATA_CE => delay_ce_pulse,
  DELAY_DATA_INC => (others => '1'),
  DELAY_LOCKED => open,
  REF_CLOCK => REF_CLOCK,
  BITSLIP =>   '0',    --product guide says hold to zero if unused
 
  -- Clock and reset signals
  CLK_IN_P =>  clk_in_p,     -- Differential clock from IOB
  CLK_IN_N =>  clk_in_n,     -- Differential clock from IOB
  CLK_DIV_OUT => data_clk,     -- Slow clock output
  CLK_RESET => reset,         --clocking logic reset
  IO_RESET =>  reset);          --system reset

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