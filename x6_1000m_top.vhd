-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--* *************************************************************************
--* Design Name: X6 1000M
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.4
--*
--*     @short X6 1000M top level
--*
--* Description:
--*
--*   This is the top entity for the XMC X6_1000M interface logic.
--*   The basic architecture of this logic is a hardware interface layer (HIL),
--*   composed of hardware interface components, is wrapped around the system logic.
--*   System logic all runs at the same clock rate in this example, and the HIL
--*   provides clock domain transitions where necessary.
--*
--*   @port pex_rst_n           : input, Master reset into the FPGA controlled by the PCIe interface. Active low
--*   @port pci_rst_n           : input, Master reset into the FPGA controlled by the PCI interface bridge. Active low
--*   @port sys_clk_p           : input, System clock differential pair (side-P), 200 MHz
--*   @port sys_clk_n           : input, System clock differential pair (side-N), 200 MHz
--*   @port pex_tx_p            :output, PCI Express transmit ports differential pair (side-P)
--*   @port pex_tx_n            :output, PCI Express transmit ports differential pair (side-N)
--*   @port pex_rx_p            : input, PCI Express receive ports differential pair (side-P)
--*   @port pex_rx_n            : input, PCI Express receive ports differential pair (side-N)
--*   @port pex_ref_clk_p       : input, PCI Express reference clock differential pair (side-P)
--*   @port pex_ref_clk_n       : input, PCI Express reference clock differential pair (side-N)
--*   @port pex_mbist_n         :output, xmc built-in self-test (bist not used)
--*   @port lpddr2_c0_ck_p      :output, LPDDR2 differential output clock (side-P)
--*   @port lpddr2_c0_ck_n      :output, LPDDR2 differential output clock (side-N)
--*   @port lpddr2_c0_cke       :output, LPDDR2 Clock enable
--*   @port lpddr2_c0_cs_n      :output, LPDDR2 chip select
--*   @port lpddr2_c0_ca        :output, LPDDR2 bank address
--*   @port lpddr2_c0_dm        :output, LPDDR2 data mask for lower byte
--*   @port lpddr2_c0_dqs_p     : inout, LPDDR2 data data read/write strobe (side-P)
--*   @port lpddr2_c0_dqs_n     : inout, LPDDR2 data data read/write strobe (side-N)
--*   @port lpddr2_c0_dq        : inout, LPDDR2 data bus
--*   @port lpddr2_c1_ck_p      :output, LPDDR2 differential output clock (side-P)
--*   @port lpddr2_c1_ck_n      :output, LPDDR2 differential output clock (side-N)
--*   @port lpddr2_c1_cke       :output, LPDDR2 Clock enable
--*   @port lpddr2_c1_cs_n      :output, LPDDR2 chip select
--*   @port lpddr2_c1_ca        :output, LPDDR2 bank address
--*   @port lpddr2_c1_dm        :output, LPDDR2 data mask for lower byte
--*   @port lpddr2_c1_dqs_p     : inout, LPDDR2 data data read/write strobe (side-P)
--*   @port lpddr2_c1_dqs_n     : inout, LPDDR2 data data read/write strobe (side-N)
--*   @port lpddr2_c1_dq        : inout, LPDDR2 data bus
--*   @port lpddr2_c2_ck_p      :output, LPDDR2 differential output clock (side-P)
--*   @port lpddr2_c2_ck_n      :output, LPDDR2 differential output clock (side-N)
--*   @port lpddr2_c2_cke       :output, LPDDR2 Clock enable
--*   @port lpddr2_c2_cs_n      :output, LPDDR2 chip select
--*   @port lpddr2_c2_ca        :output, LPDDR2 bank address
--*   @port lpddr2_c2_dm        :output, LPDDR2 data mask for lower byte
--*   @port lpddr2_c2_dqs_p     : inout, LPDDR2 data data read/write strobe (side-P)
--*   @port lpddr2_c2_dqs_n     : inout, LPDDR2 data data read/write strobe (side-N)
--*   @port lpddr2_c2_dq        : inout, LPDDR2 data bus
--*   @port lpddr2_c3_ck_p      :output, LPDDR2 differential output clock (side-P)
--*   @port lpddr2_c3_ck_n      :output, LPDDR2 differential output clock (side-N)
--*   @port lpddr2_c3_cke       :output, LPDDR2 Clock enable
--*   @port lpddr2_c3_cs_n      :output, LPDDR2 chip select
--*   @port lpddr2_c3_ca        :output, LPDDR2 bank address
--*   @port lpddr2_c3_dm        :output, LPDDR2 data mask for lower byte
--*   @port lpddr2_c3_dqs_p     : inout, LPDDR2 data data read/write strobe (side-P)
--*   @port lpddr2_c3_dqs_n     : inout, LPDDR2 data data read/write strobe (side-N)
--*   @port lpddr2_c3_dq        : inout, LPDDR2 data bus
--*   @port pll_vcxo_en         :output, PLL VCXO output enable
--*   @port pll_vcxo_scl        :output, I2C clock to PLL VCXO
--*   @port pll_vcxo_sda        : inout, I2C data to/from PLL VCXO
--*   @port pll_pwr_down_n      :output, PLL power down (active low)
--*   @port pll_reset_n         :output, PLL reset (active low)
--*   @port pll_spi_sclk        :output, PLL SPI clock
--*   @port pll_spi_le          :output, PLL SPI load enable, active low
--*   @port pll_spi_mosi        :output, PLL SPI master out slave in
--*   @port pll_spi_miso        : input, PLL SPI master in slave out
--*   @port pll_ext_clk_sel     :output, PLL external clock select 0=J6,1=P16
--*   @port pll_lock            : input, PLL lock indicator
--*   @port ref_adc_clk_p       : input, ADC reference clock differential pair (side-P)
--*   @port ref_adc_clk_n       : input, ADC reference clock differential pair (side-N)
--*   @port ref_dac_clk_p       : input, DAC reference clock differential pair (side-P)
--*   @port ref_dac_clk_n       : input, DAC reference clock differential pair (side-N)
--*   @port ext_sync_sel        :output, External sync select (0=J5, 1=P16)
--*   @port adc0_ext_sync_p     : input, ADC0 external sync (trigger) differential pair (side-P)
--*   @port adc0_ext_sync_n     : input, ADC0 external sync (trigger) differential pair (side-N)
--*   @port adc1_ext_sync_p     : input, ADC1 external sync (trigger) differential pair (side-P)
--*   @port adc1_ext_sync_n     : input, ADC1 external sync (trigger) differential pair (side-N)
--*   @port dac0_ext_sync_p     : input, DAC0 external sync (trigger) differential pair (side-P)
--*   @port dac0_ext_sync_n     : input, DAC0 external sync (trigger) differential pair (side-N)
--*   @port dac1_ext_sync_p     : input, DAC1 external sync (trigger) differential pair (side-P)
--*   @port dac1_ext_sync_n     : input, DAC1 external sync (trigger) differential pair (side-N)
--*   @port adc0_spi_sclk       :output, ADC0 SPI clock
--*   @port adc0_spi_sdenb      :output, ADC0 SPI enable
--*   @port adc0_spi_sdio       : inout, ADC0 SPI input/output data
--*   @port adc0_reset_p        :output, ADC0 ADC reset differential pair (side-P)
--*   @port adc0_reset_n        :output, ADC0 ADC reset differential pair (side-N)
--*   @port adc0_da_dclk_p      : input, ADC0 adc forwarded clock differential pair (side-P)
--*   @port adc0_da_dclk_n      : input, ADC0 adc forwarded clock differential pair (side-N)
--*   @port adc0_da_p           : input, ADC0 DA serial data in differential pair (side-P) (8 bits)
--*   @port adc0_da_n           : input, ADC0 DA serial data in differential pair (side-N) (8 bits)
--*   @port adc0_ovra_p         : input, ADC0 OVR serial data in differential pair (side-P)
--*   @port adc0_ovra_n         : input, ADC0 OVR serial data in differential pair (side-N)
--*   @port adc1_spi_sclk       :output, ADC1 SPI clock
--*   @port adc1_spi_sdenb      :output, ADC1 SPI enable
--*   @port adc1_spi_sdio       : inout, ADC1 SPI input/output data
--*   @port adc1_reset_p        :output, ADC1 ADC reset differential pair (side-P)
--*   @port adc1_reset_n        :output, ADC1 ADC reset differential pair (side-N)
--*   @port adc1_da_dclk_p      : input, ADC1 adc forwarded clock differential pair (side-P)
--*   @port adc1_da_dclk_n      : input, ADC1 adc forwarded clock differential pair (side-N)
--*   @port adc1_da_p           : input, ADC1 DA serial data in differential pair (side-P) (8 bits)
--*   @port adc1_da_n           : input, ADC1 DA serial data in differential pair (side-N) (8 bits)
--*   @port adc1_ovra_p         : input, ADC1 OVR serial data in differential pair (side-P)
--*   @port adc1_ovra_n         : input, ADC1 OVR serial data in differential pair (side-N)
--*   @port dac0_resetb         :output, DAC0 reset, active low
--*   @port dac0_spi_sclk       :output, DAC0 SPI clock
--*   @port dac0_spi_sdenb      :output, DAC0 SPI enable
--*   @port dac0_spi_sdio       : inout, DAC0 SPI input/output data
--*   @port dac0_spi_sdo        : input, DAC0 status
--*   @port dac0_clk_in_p       : input, DAC0 clock differential pair (side-P)
--*   @port dac0_clk_in_n       : input, DAC0 clock differential pair (side-N)
--*   @port dac0_dclk_p         :output, forwarded DAC0 clock differential pair (side-P)
--*   @port dac0_dclk_n         :output, forwarded DAC0 clock differential pair (side-N)
--*   @port dac0_sync_p         :output, DAC0 SYNC differential pair (side-P)
--*   @port dac0_sync_n         :output, DAC0 SYNC differential pair (side-N)
--*   @port dac0_sync2_p        :output, a copy of DAC0 SYNC differential pair (side-P)
--*   @port dac0_sync2_n        :output, a copy of DAC0 SYNC differential pair (side-N)
--*   @port dac0_data_p         :output, DAC0 data differential pair (side-P) (16 bits)
--*   @port dac0_data_n         :output, DAC0 data differential pair (side-N) (16 bits)
--*   @port dac1_resetb         :output, DAC1 reset, active low
--*   @port dac1_spi_sclk       :output, DAC1 SPI clock
--*   @port dac1_spi_sdenb      :output, DAC1 SPI enable
--*   @port dac1_spi_sdio       : inout, DAC1 SPI input/output data
--*   @port dac1_spi_sdo        : input, DAC1 status
--*   @port dac1_clk_in_p       : input, DAC1 clock differential pair (side-P)
--*   @port dac1_clk_in_n       : input, DAC1 clock differential pair (side-N)
--*   @port dac1_dclk_p         :output, forwarded DAC1 clock differential pair (side-P)
--*   @port dac1_dclk_n         :output, forwarded DAC1 clock differential pair (side-N)
--*   @port dac1_sync_p         :output, DAC1 SYNC differential pair (side-P)
--*   @port dac1_sync_n         :output, DAC1 SYNC differential pair (side-N)
--*   @port dac1_sync2_p        :output, a copy of DAC1 SYNC differential pair (side-P)
--*   @port dac1_sync2_n        :output, a copy of DAC1 SYNC differential pair (side-N)
--*   @port dac1_data_p         :output, DAC1 data differential pair (side-P) (16 bits)
--*   @port dac1_data_n         :output, DAC1 data differential pair (side-N) (16 bits)
--*   @port dac_dig_en          :output, enable DAC digitizer
--*   @port dac0_dig_p          : input, DAC0 digitized output differential pair (side-P)
--*   @port dac0_dig_n          : input, DAC0 digitized output differential pair (side-N)
--*   @port dac1_dig_p          : input, DAC1 digitized output differential pair (side-P)
--*   @port dac1_dig_n          : input, DAC1 digitized output differential pair (side-N)
--*   @port sio_xo_scl          :output, MGT XO I2C clock
--*   @port sio_xo_sda          : inout, MGT XO I2C data in/out
--*   @port sio_xo_intr         : input, MGT XO interrupt
--*   @port gtx0_refclk_p       : input, RIO0 GTX reference clock differential pair (side-P)
--*   @port gtx0_refclk_n       : input, RIO0 GTX reference clock differential pair (side-N)
--*   @port gtx0_rxp            : input, RIO0 GTX receive ports differential pair (side-P)
--*   @port gtx0_rxn            : input, RIO0 GTX receive ports differential pair (side-N)
--*   @port gtx0_txp            :output, RIO0 GTX transmit ports differential pair (side-P)
--*   @port gtx0_txn            :output, RIO0 GTX transmit ports differential pair (side-N)
--*   @port gtx1_refclk_p       : input, RIO1 GTX reference clock differential pair (side-P)
--*   @port gtx1_refclk_n       : input, RIO1 GTX reference clock differential pair (side-N)
--*   @port gtx1_rxp            : input, RIO1 GTX receive ports differential pair (side-P)
--*   @port gtx1_rxn            : input, RIO1 GTX receive ports differential pair (side-N)
--*   @port gtx1_txp            :output, RIO1 GTX transmit ports differential pair (side-P)
--*   @port gtx1_txn            :output, RIO1 GTX transmit ports differential pair (side-N)
--*   @port hw_rev              : input, Hardware revision code from the PCB
--*   @port cfg                 : input, Configuration image selection
--*   @port dio_p               : inout, digital input/output port differential pair (side-P)
--*   @port dio_n               : inout, digital input/output port differential pair (side-N)
--*   @port h_pps               : input, pulse per second
--*   @port loader_clk          :output, Configuration serial clock
--*   @port loader_cs           :output, Configuration chip select
--*   @port loader_dio          : inout, Configuration serial data in/out
--*   @port loader_bus          : inout, Configuration bus data in/out
--*   @port rom_sck             :output, serial flash clock
--*   @port rom_cs_n            :output, serial flash chip select
--*   @port rom_sdi             :output, serial flash input
--*   @port rom_sdo             : input, serial flash output
--*   @port rom_wp_n            :output, serial flash write protect (active low)
--*   @port rom_hold_n          :output, serial flash hold (active low)
--*   @port temp_smbclk         :output, LM96163 (temperate sensor) interface SMB clock
--*   @port temp_smbdat         : inout, LM96163 (temperate sensor) interface SMB data
--*   @port led1                :output, Active low red LED signals PCIe link is up
--*   @port led2                :output, Active low green LED signals all clocks are locked
--*   @port led3                :output, Active low application LED output signals PCIe link is up
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 8/12/08
--*
--*
-- **************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;

library unisim;
use unisim.vcomponents.all;

library work;
use work.x6_pkg.all;

entity x6_1000m_top is
  generic (
    SYS_CLK_FREQ         : integer := 200;  -- system clk freq in MHz
    MEM_CLK_FREQ         : integer := 400;  -- memory clk freq in MHz
    PCIE_LANES           : integer := 8;    -- number of PCIE lanes
    ADD_AURORA           : boolean := FALSE;-- instantiate Aurora cores
    USE_XMC_RST          : boolean := TRUE; -- PCIE reset (XMC vs PMC)
    DEVICE               : string  := "lx240t"
  );
  port (
    -- clocks & resets
    pex_rst_n            : in    std_logic;
    pci_rst_n            : in    std_logic;
    sys_clk_p            : in    std_logic;
    sys_clk_n            : in    std_logic;

    -- PCI Express Interface
    pex_tx_p             : out   std_logic_vector(PCIE_LANES-1 downto 0);
    pex_tx_n             : out   std_logic_vector(PCIE_LANES-1 downto 0);
    pex_rx_p             : in    std_logic_vector(PCIE_LANES-1 downto 0);
    pex_rx_n             : in    std_logic_vector(PCIE_LANES-1 downto 0);
    pex_ref_clk_p        : in    std_logic;
    pex_ref_clk_n        : in    std_logic;
    pex_mbist_n          : out   std_logic;

    -- LPDDR2 Interface
    lpddr2_c0_ck_p       : out   std_logic_vector(0 downto 0);
    lpddr2_c0_ck_n       : out   std_logic_vector(0 downto 0);
    lpddr2_c0_cke        : out   std_logic_vector(1 downto 0);
    lpddr2_c0_cs_n       : out   std_logic_vector(1 downto 0);
    lpddr2_c0_ca         : out   std_logic_vector(9 downto 0);
    lpddr2_c0_dm         : out   std_logic_vector(3 downto 0);
    lpddr2_c0_dqs_p      : inout std_logic_vector(3 downto 0);
    lpddr2_c0_dqs_n      : inout std_logic_vector(3 downto 0);
    lpddr2_c0_dq         : inout std_logic_vector(31 downto 0);

    lpddr2_c1_ck_p       : out   std_logic_vector(0 downto 0);
    lpddr2_c1_ck_n       : out   std_logic_vector(0 downto 0);
    lpddr2_c1_cke        : out   std_logic_vector(1 downto 0);
    lpddr2_c1_cs_n       : out   std_logic_vector(1 downto 0);
    lpddr2_c1_ca         : out   std_logic_vector(9 downto 0);
    lpddr2_c1_dm         : out   std_logic_vector(3 downto 0);
    lpddr2_c1_dqs_p      : inout std_logic_vector(3 downto 0);
    lpddr2_c1_dqs_n      : inout std_logic_vector(3 downto 0);
    lpddr2_c1_dq         : inout std_logic_vector(31 downto 0);

    lpddr2_c2_ck_p       : out   std_logic_vector(0 downto 0);
    lpddr2_c2_ck_n       : out   std_logic_vector(0 downto 0);
    lpddr2_c2_cke        : out   std_logic_vector(1 downto 0);
    lpddr2_c2_cs_n       : out   std_logic_vector(1 downto 0);
    lpddr2_c2_ca         : out   std_logic_vector(9 downto 0);
    lpddr2_c2_dm         : out   std_logic_vector(3 downto 0);
    lpddr2_c2_dqs_p      : inout std_logic_vector(3 downto 0);
    lpddr2_c2_dqs_n      : inout std_logic_vector(3 downto 0);
    lpddr2_c2_dq         : inout std_logic_vector(31 downto 0);

    lpddr2_c3_ck_p       : out   std_logic_vector(0 downto 0);
    lpddr2_c3_ck_n       : out   std_logic_vector(0 downto 0);
    lpddr2_c3_cke        : out   std_logic_vector(1 downto 0);
    lpddr2_c3_cs_n       : out   std_logic_vector(1 downto 0);
    lpddr2_c3_ca         : out   std_logic_vector(9 downto 0);
    lpddr2_c3_dm         : out   std_logic_vector(3 downto 0);
    lpddr2_c3_dqs_p      : inout std_logic_vector(3 downto 0);
    lpddr2_c3_dqs_n      : inout std_logic_vector(3 downto 0);
    lpddr2_c3_dq         : inout std_logic_vector(31 downto 0);

    -- PLL Interface
    pll_vcxo_en          : out   std_logic;
    pll_vcxo_scl         : out   std_logic;
    pll_vcxo_sda         : inout std_logic;
    pll_pwr_down_n       : out   std_logic;
    pll_reset_n          : out   std_logic;
    pll_spi_sclk         : out   std_logic;
    pll_spi_le           : out   std_logic;
    pll_spi_mosi         : out   std_logic;
    pll_spi_miso         : in    std_logic;
    pll_ext_clk_sel      : out   std_logic;
    pll_lock             : in    std_logic;
    ref_adc_clk_p        : in    std_logic;
    ref_adc_clk_n        : in    std_logic;
    ref_dac_clk_p        : in    std_logic;
    ref_dac_clk_n        : in    std_logic;


    -- External sync
    ext_sync_sel         : out   std_logic;
    adc0_ext_sync_p      : in    std_logic;
    adc0_ext_sync_n      : in    std_logic;
    adc1_ext_sync_p      : in    std_logic;
    adc1_ext_sync_n      : in    std_logic;
    dac0_ext_sync_p      : in    std_logic;
    dac0_ext_sync_n      : in    std_logic;
    dac1_ext_sync_p      : in    std_logic;
    dac1_ext_sync_n      : in    std_logic;

    -- ADC0 and ADC1 interface
    adc0_spi_sclk        : out   std_logic;
    adc0_spi_sdenb       : out   std_logic;
    adc0_spi_sdio        : inout std_logic;
    adc0_reset_p         : out   std_logic;
    adc0_reset_n         : out   std_logic;
    adc0_da_dclk_p       : in    std_logic;
    adc0_da_dclk_n       : in    std_logic;
    adc0_da_p            : in    std_logic_vector(11 downto 0);
    adc0_da_n            : in    std_logic_vector(11 downto 0);
    adc0_ovra_p          : in    std_logic;
    adc0_ovra_n          : in    std_logic;
    adc1_spi_sclk        : out   std_logic;
    adc1_spi_sdenb       : out   std_logic;
    adc1_spi_sdio        : inout std_logic;
    adc1_reset_p         : out   std_logic;
    adc1_reset_n         : out   std_logic;
    adc1_da_dclk_p       : in    std_logic;
    adc1_da_dclk_n       : in    std_logic;
    adc1_da_p            : in    std_logic_vector(11 downto 0);
    adc1_da_n            : in    std_logic_vector(11 downto 0);
    adc1_ovra_p          : in    std_logic;
    adc1_ovra_n          : in    std_logic;

    -- DAC0 and DAC1 interface signals
    dac0_resetb          : out   std_logic;
    dac0_spi_sclk        : out   std_logic;
    dac0_spi_sdenb       : out   std_logic;
    dac0_spi_sdio        : inout std_logic;
    dac0_spi_sdo         : in    std_logic;
    dac0_clk_in_p        : in    std_logic;
    dac0_clk_in_n        : in    std_logic;
    dac0_dclk_p          : out   std_logic;
    dac0_dclk_n          : out   std_logic;
    dac0_sync_p          : out   std_logic;
    dac0_sync_n          : out   std_logic;
    dac0_sync2_p         : out   std_logic;
    dac0_sync2_n         : out   std_logic;
    dac0_data_p          : out   std_logic_vector(15 downto 0);
    dac0_data_n          : out   std_logic_vector(15 downto 0);
    dac1_resetb          : out   std_logic;
    dac1_spi_sclk        : out   std_logic;
    dac1_spi_sdenb       : out   std_logic;
    dac1_spi_sdio        : inout std_logic;
    dac1_spi_sdo         : in    std_logic;
    dac1_clk_in_p        : in    std_logic;
    dac1_clk_in_n        : in    std_logic;
    dac1_dclk_p          : out   std_logic;
    dac1_dclk_n          : out   std_logic;
    dac1_sync_p          : out   std_logic;
    dac1_sync_n          : out   std_logic;
    dac1_sync2_p         : out   std_logic;
    dac1_sync2_n         : out   std_logic;
    dac1_data_p          : out   std_logic_vector(15 downto 0);
    dac1_data_n          : out   std_logic_vector(15 downto 0);

    -- DAC output digitizer interface
    dac_dig_en           : out   std_logic;
    dac0_dig_p           : in    std_logic;
    dac0_dig_n           : in    std_logic;
    dac1_dig_p           : in    std_logic;
    dac1_dig_n           : in    std_logic;

    -- Serial RapidIO clock control
    sio_xo_scl           : out   std_logic;
    sio_xo_sda           : inout std_logic;
    sio_xo_intr          : in    std_logic;

    -- GTX Serial I/O ports
    gtx0_refclk_p        : in    std_logic;
    gtx0_refclk_n        : in    std_logic;
    gtx0_rxp             : in    std_logic_vector(3 downto 0);
    gtx0_rxn             : in    std_logic_vector(3 downto 0);
    gtx0_txp             : out   std_logic_vector(3 downto 0);
    gtx0_txn             : out   std_logic_vector(3 downto 0);
    gtx1_refclk_p        : in    std_logic;
    gtx1_refclk_n        : in    std_logic;
    gtx1_rxp             : in    std_logic_vector(3 downto 0);
    gtx1_rxn             : in    std_logic_vector(3 downto 0);
    gtx1_txp             : out   std_logic_vector(3 downto 0);
    gtx1_txn             : out   std_logic_vector(3 downto 0);

    -- Board revision info
    hw_rev               : in    std_logic_vector(3 downto 0);
    cfg                  : in    std_logic_vector(3 downto 0);

    -- Digital I/O
    dio_p                : out std_logic_vector(31 downto 0);
    dio_n                : out std_logic_vector(31 downto 0);
    h_pps                : in    std_logic;

    -- CPLD interface
    loader_clk           : out   std_logic;
    loader_cs            : out   std_logic;
    loader_dio           : out   std_logic;
    loader_bus           : inout std_logic_vector(15 downto 0);

    -- Calibration serial flash
    rom_sck              : out   std_logic;
    rom_cs_n             : out   std_logic;
    rom_sdi              : out   std_logic;
    rom_sdo              : in    std_logic;
    rom_wp_n             : out   std_logic;
    rom_hold_n           : out   std_logic;

    -- Temperature monitoring
    temp_smbclk          : out   std_logic;
    temp_smbdat          : inout std_logic;

    -- LED
    led1                 : out   std_logic;
    led2                 : out   std_logic;
    led3                 : out   std_logic
  );
end x6_1000m_top;


architecture arch of x6_1000m_top is

-----------------------------------------------------------------------------
-- Function declarations
-----------------------------------------------------------------------------
  function dev_encode (s : in string) return std_logic_vector is
  begin
    if (s = "lx240t") then
      return "01";
    elsif (s = "sx315t") then
      return "10";
    elsif (s = "sx475t") then
      return "11";
    else
      return "00";
    end if;
  end function dev_encode;

-----------------------------------------------------------------------------
-- Logic version/revision
-----------------------------------------------------------------------------
  constant rev_maj            : std_logic_vector(7 downto 0) := X"01";
  constant rev_min            : std_logic_vector(7 downto 0) := X"06";
  signal sub_rev              : std_logic_vector(7 downto 0) := X"b1";
  signal revision             : std_logic_vector(15 downto 0) := rev_maj & rev_min;
  constant hw_type            : std_logic_vector(3 downto 0) := X"5"; -- X6-1000M
  constant fpga_type          : std_logic_vector(1 downto 0) := dev_encode(DEVICE);
-----------------------------------------------------------------------------
-- Clocks
-----------------------------------------------------------------------------
  signal ref_clk200           : std_logic;
  signal sys_clk              : std_logic;
  signal mem_clk_div2         : std_logic;
  signal pex_clk              : std_logic;
  signal clks_locked          : std_logic;
  signal ref_adc_clk          : std_logic;
  signal ref_dac_clk          : std_logic;
  signal crm_run              : std_logic;
-----------------------------------------------------------------------------
-- Reset
-----------------------------------------------------------------------------
  signal prst_n               : std_logic;
  signal por_arst             : std_logic;
  signal brd_rst              : std_logic;
  signal app_rst              : std_logic;
  signal mem_rst              : std_logic;
  signal wb_rst               : std_logic;
  signal frontend_rst         : std_logic;
  signal backend_rst          : std_logic;
-----------------------------------------------------------------------------
-- PCIe interface
-----------------------------------------------------------------------------
  signal pcie_rx_rden         : std_logic;
  signal pcie_rx_empty        : std_logic;
  signal pcie_rx_aempty       : std_logic;
  signal pcie_rx_data_vld     : std_logic;
  signal pcie_rx_dout         : std_logic_vector(127 downto 0);
  signal pcie_tx_din          : std_logic_vector(127 downto 0);
  signal pcie_tx_rdy          : std_logic;
  signal pex_linkup_n         : std_logic;
  signal ctrl_addr            : std_logic_vector(31 downto 0);
  signal ctrl_din             : std_logic_vector(31 downto 0);
  signal ctrl_rd              : std_logic;
  signal ctrl_wr              : std_logic;
  signal ctrl_vld             : std_logic;
  signal ctrl_dout            : std_logic_vector(31 downto 0);
-----------------------------------------------------------------------------
-- Wishbone interface
-----------------------------------------------------------------------------
  signal wb_adr_o             : std_logic_vector(15 downto 0);
  signal wb_dat_o             : std_logic_vector(31 downto 0);
  signal wb_we_o              : std_logic;
  signal wb_stb_o             : std_logic;
  signal wb_cyc_o             : std_logic;
  signal wb_ack_i             : std_logic_vector(15 downto 0):=(others=>'0');
  signal wb_ack_i_d           : std_logic_vector(15 downto 0):=(others=>'0');
  signal wb_ack_int           : std_logic := '0';
  signal wb_dat_i             : std_logic_vector(31 downto 0);
  signal wb_dat_i_d           : std_logic_vector(31 downto 0);
  signal wb_dat_i_dd          : std_logic_vector(31 downto 0);
-----------------------------------------------------------------------------
-- Temperature controller
-----------------------------------------------------------------------------
  signal temp_alert           : std_logic;
-----------------------------------------------------------------------------
-- Alert
-----------------------------------------------------------------------------
  signal mem_alert_din        : std_logic_vector(15 downto 0);
  signal mem_alert_strb       : std_logic;
  signal mem_alert_dout       : std_logic_vector(15 downto 0);
  signal alert_sw_stb         : std_logic;
  signal alert_sw_data        : std_logic_vector(31 downto 0);
  signal alert_clr            : std_logic_vector(31 downto 0);
  signal alert_data           : width_32_alrt_array;
  signal alert, alert_enable  : std_logic_vector(31 downto 0);
  signal alert_timestamp_run  : std_logic;
  signal timestamp_rollover   : std_logic;
  signal alert_fifo_wrd_cnt   : std_logic_vector(8 downto 0);
  signal alert_fifo_aempty    : std_logic;
  signal alert_fifo_empty     : std_logic;
  signal alert_fifo_rd        : std_logic;
  signal alert_dout_vld       : std_logic;
  signal alert_dout           : std_logic_vector(127 downto 0);
  signal afe_trigger          : std_logic;
  signal alert_ref_clk        : std_logic;
-----------------------------------------------------------------------------
-- Packetizer
-----------------------------------------------------------------------------
  signal ch_pkt_size          : width_24_ch_array;
  signal force_pkt_size       : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_src_data_cnt     : width_22_ch_array;
  signal pkt_src_aempty       : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_src_empty        : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_rden             : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_din_vld          : std_logic_vector(num_pkt_ch-1 downto 0);
  signal pkt_din              : width_128_ch_array;
  signal pkt_valid            : std_logic;
-----------------------------------------------------------------------------
-- Deframer
-----------------------------------------------------------------------------
  signal pd_addr_df           : width_8_pd_df_array;
  signal def_dest_rdy         : std_logic_vector(num_pd_df-1 downto 0);
  signal def_valid            : std_logic_vector(num_pd_df-1 downto 0);
  signal def_data_out         : std_logic_vector(127 downto 0);
  signal def_pid_addr0        : std_logic_vector(7 downto 0);
  signal def_pid_addr1        : std_logic_vector(7 downto 0);
-----------------------------------------------------------------------------
-- Loopback fifo signals
-----------------------------------------------------------------------------
  signal lpbk_fifo_rden       : std_logic;
  signal lpbk_fifo_dout       : std_logic_vector(127 downto 0);
  signal lpbk_fifo_empty      : std_logic;
  signal lpbk_fifo_vld        : std_logic;
  signal lpbk_fifo_afull      : std_logic;
  signal lpbk_fifo_aempty     : std_logic;
------------------------------------------------------------------------------
-- RIO
------------------------------------------------------------------------------
  signal rio0_src_rdy         : std_logic;
  signal rio0_src_valid       : std_logic;
  signal rio0_src_din         : std_logic_vector(127 downto 0);
  signal rio1_src_rdy         : std_logic;
  signal rio1_src_valid       : std_logic;
  signal rio1_src_din         : std_logic_vector(127 downto 0);
-----------------------------------------------------------------------------
-- Misc.
-----------------------------------------------------------------------------
  signal led                  : std_logic_vector(1 downto 0);
  signal ds_data_oe           : std_logic;
  signal ds_data_o            : std_logic;
  signal sio_xo_sdo           : std_logic;
  signal h_pps_xdom           : std_logic;
  signal h_pps_demet          : std_logic;
  signal h_pps_demet_d        : std_logic;
  signal h_pps_demet_re       : std_logic;
------------------------------------------------------------------------------
-- ADC interface
------------------------------------------------------------------------------
  signal adc_trigger_o        : std_logic;
  signal adc0_overrange       : std_logic;
  signal adc1_overrange       : std_logic;
  signal adc0_overflow        : std_logic;
  signal adc1_overflow        : std_logic;
  signal adc_run_o            : std_logic;
  signal adc0_fifo_rd         : std_logic;
  signal adc0_fifo_empty      : std_logic;
  signal adc0_fifo_aempty     : std_logic;
  signal adc0_fifo_valid      : std_logic;
  signal adc0_fifo_dout       : std_logic_vector(127 downto 0);
  signal adc1_fifo_rd         : std_logic;
  signal adc1_fifo_empty      : std_logic;
  signal adc1_fifo_aempty     : std_logic;
  signal adc1_fifo_valid      : std_logic;
  signal adc1_fifo_dout       : std_logic_vector(127 downto 0);
------------------------------------------------------------------------------
-- DAC interface
------------------------------------------------------------------------------
  signal dac_trigger_o        : std_logic;
  signal dac0_underflow       : std_logic;
  signal dac1_underflow       : std_logic;
  signal dac_run_o            : std_logic;
  signal dac0_stream_id       : std_logic_vector(15 downto 0);
  signal dac1_stream_id       : std_logic_vector(15 downto 0);
------------------------------------------------------------------------------
-- VITA router
------------------------------------------------------------------------------
  signal rtr_src_aempty       : std_logic_vector(2 downto 0);
  signal rtr_src_empty        : std_logic_vector(2 downto 0);
  signal rtr_src_rden         : std_logic_vector(2 downto 0);
  signal rtr_src_vld          : std_logic_vector(2 downto 0);
  signal rtr_src_data         : std_logic_vector(128*3-1 downto 0);
  signal rtr_dst_rdy          : std_logic;
  signal rtr_dst_wren         : std_logic;
  signal rtr_dst_data         : std_logic_vector(127 downto 0);
------------------------------------------------------------------------------
-- LPDDR2
------------------------------------------------------------------------------
  signal lpddr2_dpd_req       : std_logic_vector(3 downto 0);
  signal lpddr2_phy_init_done : std_logic_vector(3 downto 0);
  signal playback_en          : std_logic_vector(1 downto 0);
  signal mem_test_en          : std_logic_vector(3 downto 0);
  signal mem_test_error       : std_logic_vector(3 downto 0);
  signal vf0_pbcmd_fifo_wren  : std_logic;
  signal vf0_pbcmd_fifo_data  : std_logic_vector(127 downto 0);
  signal vf0_pbcmd_fifo_rdy   : std_logic;
  signal vf0_tag_load_done    : std_logic;
  signal vf0_tag_load_value   : std_logic_vector(7 downto 0);
  signal vf0_tag_rep_done     : std_logic;
  signal vf0_tag_rep_value    : std_logic_vector(7 downto 0);
  signal vfifo0_i_wren        : std_logic;
  signal vfifo0_i_data        : std_logic_vector(127 downto 0);
  signal vfifo0_i_rdy         : std_logic;
  signal vfifo0_o_rden        : std_logic;
  signal vfifo0_o_aempty      : std_logic;
  signal vfifo0_o_empty       : std_logic;
  signal vfifo0_o_vld         : std_logic;
  signal vfifo0_o_data        : std_logic_vector(127 downto 0);
  signal vfifo0_overflow      : std_logic;
  signal vfifo0_underflow     : std_logic;
  signal vfifo0_wrd_cnt       : std_logic_vector(29 downto 0);
  signal vfifo0_aempty        : std_logic;
  signal vfifo0_afull         : std_logic;
  signal vf1_pbcmd_fifo_wren  : std_logic;
  signal vf1_pbcmd_fifo_data  : std_logic_vector(127 downto 0);
  signal vf1_pbcmd_fifo_rdy   : std_logic;
  signal vf1_tag_load_done    : std_logic;
  signal vf1_tag_load_value   : std_logic_vector(7 downto 0);
  signal vf1_tag_rep_done     : std_logic;
  signal vf1_tag_rep_value    : std_logic_vector(7 downto 0);
  signal vfifo1_i_wren        : std_logic;
  signal vfifo1_i_data        : std_logic_vector(127 downto 0);
  signal vfifo1_i_rdy         : std_logic;
  signal vfifo1_o_rden        : std_logic;
  signal vfifo1_o_aempty      : std_logic;
  signal vfifo1_o_empty       : std_logic;
  signal vfifo1_o_vld         : std_logic;
  signal vfifo1_o_data        : std_logic_vector(127 downto 0);
  signal vfifo1_overflow      : std_logic;
  signal vfifo1_underflow     : std_logic;
  signal vfifo1_wrd_cnt       : std_logic_vector(29 downto 0);
  signal vfifo1_aempty        : std_logic;
  signal vfifo1_afull         : std_logic;
  signal vfifo2_i_wren        : std_logic;
  signal vfifo2_i_data        : std_logic_vector(127 downto 0);
  signal vfifo2_i_rdy         : std_logic;
  signal vfifo2_o_rden        : std_logic;
  signal vfifo2_o_aempty      : std_logic;
  signal vfifo2_o_empty       : std_logic;
  signal vfifo2_o_vld         : std_logic;
  signal vfifo2_o_data        : std_logic_vector(127 downto 0);
  signal vfifo2_overflow      : std_logic;
  signal vfifo2_underflow     : std_logic;
  signal vfifo2_wrd_cnt       : std_logic_vector(29 downto 0);
  signal vfifo2_aempty        : std_logic;
  signal vfifo2_afull         : std_logic;
  signal vfifo3_i_wren        : std_logic;
  signal vfifo3_i_data        : std_logic_vector(127 downto 0);
  signal vfifo3_i_rdy         : std_logic;
  signal vfifo3_o_rden        : std_logic;
  signal vfifo3_o_aempty      : std_logic;
  signal vfifo3_o_empty       : std_logic;
  signal vfifo3_o_vld         : std_logic;
  signal vfifo3_o_data        : std_logic_vector(127 downto 0);
  signal vfifo3_overflow      : std_logic;
  signal vfifo3_underflow     : std_logic;
  signal vfifo3_wrd_cnt       : std_logic_vector(29 downto 0);
  signal vfifo3_aempty        : std_logic;
  signal vfifo3_afull         : std_logic;
------------------------------------------------------------------------------
-- VITA mover (2x1)
------------------------------------------------------------------------------
  signal vmvr_src_aempty      : std_logic_vector(1 downto 0);
  signal vmvr_src_empty       : std_logic_vector(1 downto 0);
  signal vmvr_src_rden        : std_logic_vector(1 downto 0);
  signal vmvr_src_vld         : std_logic_vector(1 downto 0);
  signal vmvr_src_data        : std_logic_vector(128*2-1 downto 0);
  signal vmvr_dst_wrd_cnt     : std_logic_vector(8 downto 0);
  signal vmvr_dst_aempty      : std_logic;
  signal vmvr_dst_empty       : std_logic;
  signal vmvr_dst_rden        : std_logic;
  signal vmvr_dst_vld         : std_logic;
  signal vmvr_dst_dout        : std_logic_vector(127 downto 0);
  signal pkt_din_wrd_cnt      : std_logic_vector(29 downto 0);
  signal pkt_din_wrd_cnt_sat  : std_logic_vector(21 downto 0);
------------------------------------------------------------------------------
-- VITA-Velocia padder
------------------------------------------------------------------------------
  signal pad_dst_wrd_cnt      : std_logic_vector(21 downto 0);
  signal pad_dst_aempty       : std_logic;
  signal pad_dst_empty        : std_logic;
  signal pad_dst_rden         : std_logic;
  signal pad_dst_vld          : std_logic;
  signal pad_dst_dout         : std_logic_vector(127 downto 0);
  signal pad_bypass           : std_logic;
------------------------------------------------------------------------------
-- VITA-Checker
------------------------------------------------------------------------------
  signal hdr_error            : std_logic;
  signal trlr_error           : std_logic;
------------------------------------------------------------------------------
-- Custom DSP stuff
------------------------------------------------------------------------------
  signal state0               : std_logic_vector(1 downto 0);
  signal state1               : std_logic_vector(1 downto 0);
  signal state0_vld           : std_logic_vector(1 downto 0);
  signal state1_vld           : std_logic_vector(1 downto 0);
  signal state_vld            : std_logic;

------------------------------------------------------------------------------
-- Chipscope debug
------------------------------------------------------------------------------
  signal control0, control1, control2, control3 : std_logic_vector(35 downto 0) ;

-----------------------------------------------------------------------------
signal dac0_ext_sync, dac1_ext_sync, adc0_ext_sync, adc1_ext_sync : std_logic;
signal dac0_data, dac1_data : std_logic_vector(63 downto 0) ;
signal dac0_data_wr_en, dac1_data_wr_en : std_logic;
signal dac0_data_rdy, dac1_data_rdy : std_logic;
 
signal adc0_data_clk, adc1_data_clk : std_logic;
signal adc0_raw_data, adc1_raw_data : std_logic_vector(47 downto 0) ;

-- AFE register connections

  signal adc_phy_init_d       : std_logic;
  signal adc_phy_init_re      : std_logic;

    signal clk200_locked_d      : std_logic;
    signal clk200_locked_dd     : std_logic;
    signal clk200_locked_re     : std_logic;
    signal idelayctrl_rst_sreg  : std_logic_vector(9 downto 0);
    signal idelayctrl_rst       : std_logic;


    signal adc_phy_init         : std_logic;
    signal skip_adc_phy_cal     : std_logic;
    signal adc0_delay_ce, adc1_delay_ce        : std_logic_vector(11 downto 0) ;
    signal adc0_eye_aligned, adc1_eye_aligned     : std_logic_vector(11 downto 0);
    signal adc1_prbs_locked     : std_logic;
    signal adc1_prbs_aligned    : std_logic;
    signal adc1_phy_rdy         : std_logic;

  signal pll_spi_rdy          : std_logic;
  signal pll_spi_rdata_valid  : std_logic;
  signal pll_spi_wr_strb      : std_logic;
  signal pll_spi_addr         : std_logic_vector(3 downto 0);
  signal pll_spi_wdata        : std_logic_vector(27 downto 0);
  signal pll_spi_rdata        : std_logic_vector(31 downto 0);
  signal pll_vcxo_sdo         : std_logic;
  signal adc0_spi_access_strb : std_logic;
  signal adc0_spi_wdata       : std_logic_vector(7 downto 0);
  signal adc0_spi_addr        : std_logic_vector(4 downto 0);
  signal adc0_spi_rd_wrn      : std_logic;
  signal adc0_spi_rdy         : std_logic;
  signal adc0_spi_rdata_valid : std_logic;
  signal adc0_spi_rdata       : std_logic_vector(7 downto 0);
  signal adc1_spi_access_strb : std_logic;
  signal adc1_spi_wdata       : std_logic_vector(7 downto 0);
  signal adc1_spi_addr        : std_logic_vector(4 downto 0);
  signal adc1_spi_rd_wrn      : std_logic;
  signal adc1_spi_rdy         : std_logic;
  signal adc1_spi_rdata_valid : std_logic;
  signal adc1_spi_rdata       : std_logic_vector(7 downto 0);
  signal dac0_spi_access_strb : std_logic;
  signal dac0_spi_wdata       : std_logic_vector(7 downto 0);
  signal dac0_spi_addr        : std_logic_vector(4 downto 0);
  signal dac0_spi_rd_wrn      : std_logic;
  signal dac0_spi_rdy         : std_logic;
  signal dac0_spi_rdata_valid : std_logic;
  signal dac0_spi_rdata       : std_logic_vector(7 downto 0);
  signal dac1_spi_access_strb : std_logic;
  signal dac1_spi_wdata       : std_logic_vector(7 downto 0);
  signal dac1_spi_addr        : std_logic_vector(4 downto 0);
  signal dac1_spi_rd_wrn      : std_logic;
  signal dac1_spi_rdy         : std_logic;
  signal dac1_spi_rdata_valid : std_logic;
  signal dac1_spi_rdata       : std_logic_vector(7 downto 0);
  signal dac0_spi_sdo_sysclk, dac1_spi_sdo_sysclk : std_logic;

  signal wf_rd_addr_copy_dac0, wf_rd_addr_copy_dac1 : std_logic_vector(15 downto 0) ;
  signal dac_ch_en : std_logic_vector(3 downto 0) ;
  signal dac0_trigger, dac0_trigger_en, dac1_trigger, dac1_trigger_en : std_logic;

begin

-----------------------------------------------------------------------------
-- Clocks and Resets
-----------------------------------------------------------------------------
  -- Choose XMC (pex) vs PMC (pci) reset
  xmc_rst : if (USE_XMC_RST) generate
    prst_n <= pex_rst_n;
  end generate;

  pmc_rst : if (not USE_XMC_RST) generate
    prst_n <= pci_rst_n;
  end generate;

  por_arst <= not prst_n;

  -- Register to ease timing closure
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      crm_run <= adc_run_o or dac_run_o;
    end if;
  end process;

  -- clocks & reset management module
  inst_crm : ii_crm
  generic map (
    SYS_CLK_FREQ         => SYS_CLK_FREQ,
    MEM_CLK_FREQ         => MEM_CLK_FREQ
  )
  port map (
    por_arst             => por_arst,
    brd_arst             => brd_rst,
    clk200_p             => sys_clk_p,
    clk200_n             => sys_clk_n,
    ref_clk200           => ref_clk200,
    sys_clk              => sys_clk,
    mem_clk_div2         => mem_clk_div2,
    clks_locked          => clks_locked,
    app_rst              => app_rst,
    run                  => crm_run,
    mem_rst              => mem_rst,
    wb_rst               => wb_rst,
    frontend_rst         => frontend_rst,
    backend_rst          => backend_rst
  );

-----------------------------------------------------------------------------
-- PCIe interface
-----------------------------------------------------------------------------
  inst_pcie : ii_pcie_intf
  generic map (
    PCIE_LANES           => PCIE_LANES
  )
  port map (
    -- clock and reset related inputs
    pex_ref_clk_p        => pex_ref_clk_p, -- pcie clock in (from connector)
    pex_ref_clk_n        => pex_ref_clk_n, -- pcie clock in (from connector)
    pex_rst_n            => prst_n,        -- asynch reset, active low
    sys_clk              => sys_clk,       -- system clock (from xtal)
    pex_clk              => pex_clk,
    brd_rst              => brd_rst,       -- on pex_clk domain
    linkup_n             => pex_linkup_n,
    pex_mbist_n          => pex_mbist_n,

    -- rx fifo i/o
    rx_fifo_rden         => pcie_rx_rden,
    rx_fifo_empty        => pcie_rx_empty,
    rx_fifo_aempty       => pcie_rx_aempty,
    rx_fifo_valid        => pcie_rx_data_vld,
    rx_fifo_dout         => pcie_rx_dout,

    -- tx fifo i/o
    tx_fifo_wren         => pkt_valid,
    tx_fifo_din          => pcie_tx_din,
    tx_fifo_rdy          => pcie_tx_rdy,

    -- PCIe serial Rocket i/o
    txp                  => pex_tx_p(PCIE_LANES-1 downto 0),
    txn                  => pex_tx_n(PCIE_LANES-1 downto 0),
    rxp                  => pex_rx_p(PCIE_LANES-1 downto 0),
    rxn                  => pex_rx_n(PCIE_LANES-1 downto 0),

    -- Control Bus
    ctrl_addr            => ctrl_addr,
    ctrl_dout            => ctrl_dout,
    ctrl_rd              => ctrl_rd,
    ctrl_wr              => ctrl_wr,
    ctrl_vld             => ctrl_vld,
    ctrl_din             => ctrl_din
  );

-----------------------------------------------------------------------------
-- Wishbone master interface
-----------------------------------------------------------------------------
  wb_master : ii_regs_master
  port map (
    rst                  => wb_rst,
    pcie_clk             => pex_clk,

    ctrl_addr            => ctrl_addr,
    ctrl_din             => ctrl_dout,
    ctrl_rd              => ctrl_rd,
    ctrl_wr              => ctrl_wr,
    ctrl_vld             => ctrl_vld,
    ctrl_dout            => ctrl_din,

    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_o             => wb_adr_o,
    wb_dat_o             => wb_dat_o,
    wb_we_o              => wb_we_o,
    wb_stb_o             => wb_stb_o,
    wb_cyc_o             => wb_cyc_o,
    wb_ack_i             => wb_ack_int,
    wb_dat_i             => wb_dat_i_dd
  );

  -- OR reduction of wb_ack from slaves
  -- Also double register wb_dat_i to match the wb_ack latency
  process (sys_clk)
    variable ack_or : std_logic;
  begin
    if (rising_edge(sys_clk)) then
      wb_ack_i_d  <= wb_ack_i;
      wb_dat_i_d  <= wb_dat_i;
      wb_dat_i_dd <= wb_dat_i_d;
      ack_or := '0';
      for i in wb_ack_i_d'range loop
        ack_or := wb_ack_i_d(i) or ack_or;
      end loop;
      wb_ack_int <= ack_or;
    end if;
  end process;

-----------------------------------------------------------------------------
-- Wishbone slave interface
-----------------------------------------------------------------------------
  sys_ctrl : ii_regs_periph
  generic map (
    offset               => MR_PRF
  )
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(0),
    wb_dat_o             => wb_dat_i,

    -- User registers
    revision             => revision,
    cfg                  => cfg,
    hw_rev               => hw_rev(2 downto 0),
    hw_type              => hw_type,
    fpga_type            => fpga_type,
    app_rst              => app_rst,
    led                  => led,
    ds_data_oe           => ds_data_oe,
    ds_data_o            => ds_data_o,
    ds_data_i            => ds_data_o,
    sub_rev              => sub_rev,
    bypass_vita_pad      => pad_bypass,
    vita_hdr_err         => hdr_error,
    vita_trlr_err        => trlr_error,
    h_pps                => h_pps,
    sio_xo_sdo           => sio_xo_sdo,
    sio_xo_scl           => sio_xo_scl,
    sio_xo_sdi           => sio_xo_sda,
    sio_xo_intr          => sio_xo_intr,
    lpddr2_dpd_req       => lpddr2_dpd_req,
    lpddr2_phy_init_done => lpddr2_phy_init_done,
    playback_en          => playback_en,
    mem_test_en          => mem_test_en,
    mem_test_error       => mem_test_error,
    def_pid_addr0        => def_pid_addr0,
    def_pid_addr1        => def_pid_addr1
  );

  sio_xo_sda <= '0' when (sio_xo_sdo = '0') else 'Z';

------------------------------------------------------------------------------
-- CPLD interface - Flash programming
------------------------------------------------------------------------------
  flash_loader : ii_loader_top
  generic map (
    addr_bits            => 2,
    offset               => MR_LDR
  )
  port map (
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(1),
    wb_dat_o             => wb_dat_i,

    srst                 => frontend_rst,
    sys_clk              => sys_clk,

    loader_clk           => loader_clk,
    loader_dio           => loader_dio,
    loader_cs            => loader_cs,
    loader_bus           => loader_bus
  );

------------------------------------------------------------------------------
-- Digital I/O
------------------------------------------------------------------------------
  -- inst_dio_top : ii_dio_top
  -- generic map (
  --   width                => 32,
  --   diff_en              => FALSE,
  --   addr_bits            => 2,
  --   offset               => MR_DIO
  -- )
  -- port map (
  --   -- Wishbone interface signals
  --   wb_rst_i             => wb_rst,
  --   wb_clk_i             => sys_clk,
  --   wb_adr_i             => wb_adr_o,
  --   wb_dat_i             => wb_dat_o,
  --   wb_we_i              => wb_we_o,
  --   wb_stb_i             => wb_stb_o,
  --   wb_ack_o             => wb_ack_i(5),
  --   wb_dat_o             => wb_dat_i,
  --   -- user registers
  --   clk                  => sys_clk,
  --   dio_p                => dio_p,
  --   dio_n                => dio_n
  -- );
  wb_ack_i(5) <= '0';
  dio_p(26 downto 17) <= (others => frontend_rst);

  
  dio_p(16) <= or_reduce(state1_vld & state0_vld);
  dio_p(15 downto 12) <= state1 & state0;
  dio_p(11 downto 0) <= (others => '0');
  dio_n(31 downto 0) <= (others => '0');

-----------------------------------------------------------------------------
-- Temperature controllers
-----------------------------------------------------------------------------
  inst_temp_control_top : ii_temp_control_top
  generic map (
    offset               => MR_TMP
  )
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(2),
    wb_dat_o             => wb_dat_i,

    -- system interface
    srst                 => wb_rst,
    clk                  => sys_clk,

    -- temp_control signals
    crit_temp_sel        => hw_rev(3),
    temp_warning         => temp_alert,
    fan_en               => open,

    -- LM96163 interface
    smb_clk              => temp_smbclk,
    smb_data             => temp_smbdat
  );

-----------------------------------------------------------------------------
-- Data Flash Interface
-----------------------------------------------------------------------------
  inst_flash_intf_top : ii_flash_intf_top
  generic map (
    addr_bits            => 2,
    offset               => MR_ROM
  )
  port map (
    srst                 => frontend_rst,
    sys_clk              => sys_clk,
    -- Slave Wishbone interface
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(6),
    wb_dat_o             => wb_dat_i,
    -- Flash SPI interface
    rom_sck              => rom_sck,
    rom_cs_n             => rom_cs_n,
    rom_sdi              => rom_sdi,
    rom_sdo              => rom_sdo,
    rom_wp_n             => rom_wp_n,
    rom_hold_n           => rom_hold_n
  );

-----------------------------------------------------------------------------
-- Alerts
-----------------------------------------------------------------------------
  mem_alert_din <= (vfifo3_afull & vfifo3_aempty & vfifo3_underflow &
                    vfifo3_overflow & vfifo2_afull & vfifo2_aempty &
                    vfifo2_underflow & vfifo2_overflow & vfifo1_afull &
                    vfifo1_aempty & vfifo1_underflow & vfifo1_overflow &
                    vfifo0_afull & vfifo0_aempty & vfifo0_underflow &
                    vfifo0_overflow);

  inst_mem_alert_gen : ii_alert_gen
  generic map (
    width                => 16
  )
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Input alerts
    alert_din            => mem_alert_din,

    -- Output alert
    alert_strb           => mem_alert_strb,
    alert_dout           => mem_alert_dout
  );

  afe_trigger <= adc_trigger_o or dac_trigger_o;

  inst_alert_ref_clk : BUFGMUX
  generic map (
    CLK_SEL_TYPE         => "ASYNC"
  )
  port map (
    O                    => alert_ref_clk,
    I0                   => ref_adc_clk,
    I1                   => ref_dac_clk,
    S                    => dac_run_o
  );

  inst_alerts_top : ii_alerts_top
  generic map (
    offset               => MR_ALR
  )
  port map (
    -- wishbone interface signals
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(4),
    wb_dat_o             => wb_dat_i,

    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- alerts interface
    ref_clk              => alert_ref_clk,
    alert_data           => alert_data,
    alert                => alert,
    trigger              => afe_trigger,
    alert_sw_data        => alert_sw_data,
    alert_sw_stb         => alert_sw_stb,
    alert_clr            => alert_clr,
    timestamp_rollover   => timestamp_rollover,
    alert_fifo_wrd_cnt   => alert_fifo_wrd_cnt,
    alert_fifo_aempty    => alert_fifo_aempty,
    alert_fifo_empty     => alert_fifo_empty,
    alert_fifo_rd        => alert_fifo_rd,
    alert_dout_vld       => alert_dout_vld,
    alert_dout           => alert_dout
  );

  ----------------------------------------------------------------
  -- alert packet: (-2,-1 generated in ii_alerts; -4, -3 headers generated in packetizer)
  -- payload starts at dword#4, please refere to hardware manual.
  -- alert_data(-4) header0 (0xff000024)
  -- alert_data(-3) header1 (zeros)
  -- alert_data(-2) triggered "alert", 32 bits signal
  -- alert_data(-1) timestamp
  -- alert_data(0) => aligned with alert(0)
  -- alert_data(1)
  -- ....
  alert_data(0)       <= (x"1303000" & "000" & timestamp_rollover);
  alert_data(1)       <= alert_sw_data;
  alert_data(2)       <= (others => '0');
  alert_data(3)       <= (x"1303000" & "000" & temp_alert);
  alert_data(4)       <= (others => '0');
  alert_data(5)       <= (others => '0');
  alert_data(6)       <= (others => '0');
  alert_data(7)       <= (others => '0');
  alert_data(8)       <= (others => '0');
  alert_data(9)       <= (others => '0');
  alert_data(10)      <= (others => '0');
  alert_data(11)      <= (others => '0');
  alert_data(12)      <= (others => '0');
  alert_data(13)      <= (others => '0');
  alert_data(14)      <= (others => '0');
  alert_data(15)      <= (others => '0');
  alert_data(16)      <= (others => '0');
  alert_data(17)      <= (others => '0');
  alert_data(18)      <= (others => '0');
  alert_data(19)      <= (vf1_tag_rep_value & vf1_tag_load_value & vf0_tag_rep_value & vf0_tag_load_value);
  alert_data(20)      <= (x"1303000" & "00" & adc1_overrange & adc0_overrange);
  alert_data(21)      <= (x"1303000" & "00" & adc1_overflow & adc0_overflow);
  alert_data(22)      <= (others => '0');
  alert_data(23)      <= (others => '0');
  alert_data(24)      <= (x"1303000" & "00" & dac_trigger_o & adc_trigger_o);
  alert_data(25)      <= (others => '0');
  alert_data(26)      <= (x"1303000" & "00" & dac1_underflow & dac0_underflow);
  alert_data(27)      <= (x"1303" & mem_alert_dout);
  alert_data(28)      <= (others => '0');
  alert_data(29)      <= (others => '0');
  alert_data(30)      <= (others => '0');
  alert_data(31)      <= (others => '0');

  -- triggers for alert flag in ii_alert.vhd
  alert(0)            <= timestamp_rollover;
  alert(1)            <= alert_sw_stb;
  alert(2)            <= '0';
  alert(3)            <= temp_alert;
  alert(18 downto 4)  <= (others => '0');
  alert(19)           <= vf1_tag_rep_done or vf1_tag_load_done or vf0_tag_rep_done or vf0_tag_load_done;
  alert(20)           <= adc1_overrange or adc0_overrange;
  alert(21)           <= adc1_overflow or adc0_overflow;
  alert(23 downto 22) <= (others => '0');
  alert(24)           <= afe_trigger;
  alert(25)           <= '0';
  alert(26)           <= dac1_underflow or dac0_underflow;
  alert(27)           <= mem_alert_strb;
  alert(31 downto 28) <= (others => '0');

-----------------------------------------------------------------------------
-- Packetizer (channel 0 always connects to alerts)
-----------------------------------------------------------------------------
  pkt_src_data_cnt(0) <= (x"000" & '0' & alert_fifo_wrd_cnt);
  pkt_src_data_cnt(1) <= pad_dst_wrd_cnt;

  pkt_src_aempty(0)   <= alert_fifo_aempty;
  pkt_src_aempty(1)   <= pad_dst_aempty;

  pkt_src_empty(0)    <= alert_fifo_empty;
  pkt_src_empty(1)    <= pad_dst_empty;

  pkt_din_vld(0)      <= alert_dout_vld;
  pkt_din_vld(1)      <= pad_dst_vld;

  pkt_din(0)          <= alert_dout;
  pkt_din(1)          <= pad_dst_dout;

  inst_packetizer_top : ii_packetizer_top
  generic map (
    offset               => MR_PKT
  )
  port map (
    -- Wishbone interface signals
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(3),
    wb_dat_o             => wb_dat_i,

    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Exported settings
    ch_pkt_size          => ch_pkt_size,
    force_pkt_size       => force_pkt_size,

    -- Source channels interface
    src_data_cnt         => pkt_src_data_cnt,
    src_aempty           => pkt_src_aempty,
    src_empty            => pkt_src_empty,
    src_rden             => pkt_rden,
    src_data_vld         => pkt_din_vld,
    data_in              => pkt_din,

    -- Destination channel interface
    dest_rdy             => pcie_tx_rdy,
    dest_wren            => pkt_valid,
    data_out             => pcie_tx_din
  );

  alert_fifo_rd <= pkt_rden(0);
  pad_dst_rden  <= pkt_rden(1);

-----------------------------------------------------------------------------
-- Deframer  (Receives packet data from PCIe interface and routes it to DDR)
-----------------------------------------------------------------------------
  pd_addr_df(0)   <= def_pid_addr0;
  pd_addr_df(1)   <= def_pid_addr1;

  def_dest_rdy(0) <= not lpbk_fifo_afull;

  inst_deframer : ii_deframer
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Configuration
    pd_addr              => pd_addr_df,

    -- Status
    new_packet           => open,
    bad_pdn              => open,
    end_of_packet        => open,

    -- Source channel interface
    src_aempty           => pcie_rx_aempty,
    src_empty            => pcie_rx_empty,
    src_rden             => pcie_rx_rden,
    src_data_vld         => pcie_rx_data_vld,
    data_in              => pcie_rx_dout,

    -- Destination channels interface
    dest_rdy             => def_dest_rdy,
    dest_wren            => def_valid,
    data_out             => def_data_out
  );

-----------------------------------------------------------------------------
-- Deframer output fifo
-----------------------------------------------------------------------------
  lpbk_fifo : sfifo_512x128_bltin
  port map (
    clk                  => sys_clk,
    rst                  => backend_rst,
    din                  => def_data_out,
    wr_en                => def_valid(0),
    rd_en                => lpbk_fifo_rden,
    dout                 => lpbk_fifo_dout,
    full                 => open,
    empty                => lpbk_fifo_empty,
    valid                => lpbk_fifo_vld,
    prog_full            => lpbk_fifo_afull,
    prog_empty           => lpbk_fifo_aempty
  );

-----------------------------------------------------------------------------
-- DAC router
-----------------------------------------------------------------------------
  inst_dac_rtr : ii_dac_router
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Routing configuration
    dac0_stream_id       => dac0_stream_id,
    dac1_stream_id       => dac1_stream_id,

    -- Data source interface
    dac_rtr_rdy          => def_dest_rdy(1),
    dac_rtr_wren         => def_valid(1),
    dac_rtr_data         => def_data_out,

    -- Destination channels interface
    dac0_pbcmd_rdy       => vf0_pbcmd_fifo_rdy,
    dac0_pbcmd_wren      => vf0_pbcmd_fifo_wren,
    dac0_pbcmd_data      => vf0_pbcmd_fifo_data,
    dac0_vfifo_rdy       => vfifo0_i_rdy,
    dac0_vfifo_wren      => vfifo0_i_wren,
    dac0_vfifo_data      => vfifo0_i_data,
    dac1_pbcmd_rdy       => vf1_pbcmd_fifo_rdy,
    dac1_pbcmd_wren      => vf1_pbcmd_fifo_wren,
    dac1_pbcmd_data      => vf1_pbcmd_fifo_data,
    dac1_vfifo_rdy       => vfifo1_i_rdy,
    dac1_vfifo_wren      => vfifo1_i_wren,
    dac1_vfifo_data      => vfifo1_i_data
  );

-----------------------------------------------------------------------------
-- VFIFO interface
-----------------------------------------------------------------------------
  lpddr2_c0 : ii_vfifo_pb
  port map (
    -- Reset and Clock inputs
    mem_rst              => mem_rst,
    mem_clk_div2         => mem_clk_div2,
    ref_clk200           => ref_clk200,
    sys_clk              => sys_clk,

    -- Control and status
    dpd_req              => lpddr2_dpd_req(0),
    run                  => dac_run_o,
    playback_en          => playback_en(0),
    test_en              => mem_test_en(0),
    test_error           => mem_test_error(0),

    -- Playback command FIFO interface
    pbcmd_fifo_wren      => vf0_pbcmd_fifo_wren,
    pbcmd_fifo_data      => vf0_pbcmd_fifo_data,
    pbcmd_fifo_rdy       => vf0_pbcmd_fifo_rdy,

    -- Alert output
    tag_load_done        => vf0_tag_load_done,
    tag_load_value       => vf0_tag_load_value,
    tag_rep_done         => vf0_tag_rep_done,
    tag_rep_value        => vf0_tag_rep_value,

    -- Input fifo interface (data write port)
    vfifo_i_wren         => vfifo0_i_wren,
    vfifo_i_data         => vfifo0_i_data,
    vfifo_i_rdy          => vfifo0_i_rdy,

    -- Output fifo interface (data read port)
    vfifo_o_rden         => vfifo0_o_rden,
    vfifo_o_aethresh     => ("00" & x"08"),
    vfifo_o_aempty       => vfifo0_o_aempty,
    vfifo_o_empty        => vfifo0_o_empty,
    vfifo_o_vld          => vfifo0_o_vld,
    vfifo_o_data         => vfifo0_o_data,

    -- LPDDR2 status
    lpddr2_init_done     => lpddr2_phy_init_done(0),
    lpddr2_overflow      => vfifo0_overflow,
    lpddr2_underflow     => vfifo0_underflow,
    lpddr2_wrd_cnt       => vfifo0_wrd_cnt,
    lpddr2_aempty        => vfifo0_aempty,
    lpddr2_afull         => vfifo0_afull,

    -- LPDDR2 Output Interface
    lpddr2_ck_p          => lpddr2_c0_ck_p,
    lpddr2_ck_n          => lpddr2_c0_ck_n,
    lpddr2_cke           => lpddr2_c0_cke,
    lpddr2_cs_n          => lpddr2_c0_cs_n,
    lpddr2_ca            => lpddr2_c0_ca,
    lpddr2_dm            => lpddr2_c0_dm,
    lpddr2_dqs_p         => lpddr2_c0_dqs_p,
    lpddr2_dqs_n         => lpddr2_c0_dqs_n,
    lpddr2_dq            => lpddr2_c0_dq
  );

  lpddr2_c1 : ii_vfifo_pb
  port map (
    -- Reset and Clock inputs
    mem_rst              => mem_rst,
    mem_clk_div2         => mem_clk_div2,
    ref_clk200           => ref_clk200,
    sys_clk              => sys_clk,

    -- Control and status
    dpd_req              => lpddr2_dpd_req(1),
    run                  => dac_run_o,
    playback_en          => playback_en(1),
    test_en              => mem_test_en(1),
    test_error           => mem_test_error(1),

    -- Playback command FIFO interface
    pbcmd_fifo_wren      => vf1_pbcmd_fifo_wren,
    pbcmd_fifo_data      => vf1_pbcmd_fifo_data,
    pbcmd_fifo_rdy       => vf1_pbcmd_fifo_rdy,

    -- Alert output
    tag_load_done        => vf1_tag_load_done,
    tag_load_value       => vf1_tag_load_value,
    tag_rep_done         => vf1_tag_rep_done,
    tag_rep_value        => vf1_tag_rep_value,

    -- Input fifo interface (data write port)
    vfifo_i_wren         => vfifo1_i_wren,
    vfifo_i_data         => vfifo1_i_data,
    vfifo_i_rdy          => vfifo1_i_rdy,

    -- Output fifo interface (data read port)
    vfifo_o_rden         => vfifo1_o_rden,
    vfifo_o_aethresh     => ("00" & x"08"),
    vfifo_o_aempty       => vfifo1_o_aempty,
    vfifo_o_empty        => vfifo1_o_empty,
    vfifo_o_vld          => vfifo1_o_vld,
    vfifo_o_data         => vfifo1_o_data,

    -- LPDDR2 status
    lpddr2_init_done     => lpddr2_phy_init_done(1),
    lpddr2_overflow      => vfifo1_overflow,
    lpddr2_underflow     => vfifo1_underflow,
    lpddr2_wrd_cnt       => vfifo1_wrd_cnt,
    lpddr2_aempty        => vfifo1_aempty,
    lpddr2_afull         => vfifo1_afull,

    -- LPDDR2 Output Interface
    lpddr2_ck_p          => lpddr2_c1_ck_p,
    lpddr2_ck_n          => lpddr2_c1_ck_n,
    lpddr2_cke           => lpddr2_c1_cke,
    lpddr2_cs_n          => lpddr2_c1_cs_n,
    lpddr2_ca            => lpddr2_c1_ca,
    lpddr2_dm            => lpddr2_c1_dm,
    lpddr2_dqs_p         => lpddr2_c1_dqs_p,
    lpddr2_dqs_n         => lpddr2_c1_dqs_n,
    lpddr2_dq            => lpddr2_c1_dq
  );

  lpddr2_c2 : ii_vfifo
  port map (
    -- Reset and Clock inputs
    mem_rst              => mem_rst,
    mem_clk_div2         => mem_clk_div2,
    ref_clk200           => ref_clk200,
    sys_clk              => sys_clk,

    -- Control and status
    dpd_req              => lpddr2_dpd_req(2),
    run                  => adc_run_o,
    test_en              => mem_test_en(2),
    test_error           => mem_test_error(2),

    -- Input fifo interface (data write port)
    vfifo_i_wren         => vfifo2_i_wren,
    vfifo_i_data         => vfifo2_i_data,
    vfifo_i_rdy          => vfifo2_i_rdy,

    -- Output fifo interface (data read port)
    vfifo_o_rden         => vfifo2_o_rden,
    vfifo_o_aethresh     => ("00" & x"08"),
    vfifo_o_aempty       => vfifo2_o_aempty,
    vfifo_o_empty        => vfifo2_o_empty,
    vfifo_o_vld          => vfifo2_o_vld,
    vfifo_o_data         => vfifo2_o_data,

    -- LPDDR2 status
    lpddr2_init_done     => lpddr2_phy_init_done(2),
    lpddr2_overflow      => vfifo2_overflow,
    lpddr2_underflow     => vfifo2_underflow,
    lpddr2_wrd_cnt       => vfifo2_wrd_cnt,
    lpddr2_aempty        => vfifo2_aempty,
    lpddr2_afull         => vfifo2_afull,

    -- LPDDR2 Output Interface
    lpddr2_ck_p          => lpddr2_c2_ck_p,
    lpddr2_ck_n          => lpddr2_c2_ck_n,
    lpddr2_cke           => lpddr2_c2_cke,
    lpddr2_cs_n          => lpddr2_c2_cs_n,
    lpddr2_ca            => lpddr2_c2_ca,
    lpddr2_dm            => lpddr2_c2_dm,
    lpddr2_dqs_p         => lpddr2_c2_dqs_p,
    lpddr2_dqs_n         => lpddr2_c2_dqs_n,
    lpddr2_dq            => lpddr2_c2_dq
  );

  lpddr2_c3 : ii_vfifo
  port map (
    -- Reset and Clock inputs
    mem_rst              => mem_rst,
    mem_clk_div2         => mem_clk_div2,
    ref_clk200           => ref_clk200,
    sys_clk              => sys_clk,

    -- Control and status
    dpd_req              => lpddr2_dpd_req(3),
    run                  => adc_run_o,
    test_en              => mem_test_en(3),
    test_error           => mem_test_error(3),

    -- Input fifo interface (data write port)
    vfifo_i_wren         => vfifo3_i_wren,
    vfifo_i_data         => vfifo3_i_data,
    vfifo_i_rdy          => vfifo3_i_rdy,

    -- Output fifo interface (data read port)
    vfifo_o_rden         => vfifo3_o_rden,
    vfifo_o_aethresh     => ("00" & x"08"),
    vfifo_o_aempty       => vfifo3_o_aempty,
    vfifo_o_empty        => vfifo3_o_empty,
    vfifo_o_vld          => vfifo3_o_vld,
    vfifo_o_data         => vfifo3_o_data,

    -- LPDDR2 status
    lpddr2_init_done     => lpddr2_phy_init_done(3),
    lpddr2_wrd_cnt       => vfifo3_wrd_cnt,
    lpddr2_overflow      => vfifo3_overflow,
    lpddr2_underflow     => vfifo3_underflow,
    lpddr2_aempty        => vfifo3_aempty,
    lpddr2_afull         => vfifo3_afull,

    -- LPDDR2 Output Interface
    lpddr2_ck_p          => lpddr2_c3_ck_p,
    lpddr2_ck_n          => lpddr2_c3_ck_n,
    lpddr2_cke           => lpddr2_c3_cke,
    lpddr2_cs_n          => lpddr2_c3_cs_n,
    lpddr2_ca            => lpddr2_c3_ca,
    lpddr2_dm            => lpddr2_c3_dm,
    lpddr2_dqs_p         => lpddr2_c3_dqs_p,
    lpddr2_dqs_n         => lpddr2_c3_dqs_n,
    lpddr2_dq            => lpddr2_c3_dq
  );

------------------------------------------------------------------------------
-- VITA mover (2x1)
------------------------------------------------------------------------------
  vmvr_src_aempty <= vfifo3_o_aempty & vfifo2_o_aempty;

  vmvr_src_empty  <= vfifo3_o_empty & vfifo2_o_empty;
  
  vmvr_src_vld    <= vfifo3_o_vld & vfifo2_o_vld;

  vmvr_src_data   <= vfifo3_o_data & vfifo2_o_data;

  inst_vmvr : ii_vita_mvr_nx1
  generic map (
    num_src_ch           => 2
  )
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Source channels interface
    src_aempty           => vmvr_src_aempty,
    src_empty            => vmvr_src_empty,
    src_rden             => vmvr_src_rden,
    src_vld              => vmvr_src_vld,
    src_data             => vmvr_src_data,

    -- Destination channels interface
    dst_wrd_cnt          => vmvr_dst_wrd_cnt,
    dst_aempty           => vmvr_dst_aempty,
    dst_empty            => vmvr_dst_empty,
    dst_rden             => vmvr_dst_rden,
    dst_vld              => vmvr_dst_vld,
    dst_dout             => vmvr_dst_dout
  );

  vfifo2_o_rden <= vmvr_src_rden(0);
  vfifo3_o_rden <= vmvr_src_rden(1);

  data_cnt_adder : block
    signal tmp0                 : unsigned(29 downto 0);
  begin

    process (sys_clk)
    begin
      if (rising_edge(sys_clk)) then
        tmp0 <= (resize(unsigned(vmvr_dst_wrd_cnt),30)) + unsigned(vfifo2_wrd_cnt);
        pkt_din_wrd_cnt <= std_logic_vector(tmp0 + unsigned(vfifo3_wrd_cnt));
      end if;
    end process;

  end block data_cnt_adder;

  inst_pkt_din_wrd_cnt_sat : ii_unsign_sat
  generic map (
    ibw                  => 30,
    obw                  => 22
  )
  port map (
    i                    => pkt_din_wrd_cnt,
    o                    => pkt_din_wrd_cnt_sat
  );

-----------------------------------------------------------------------------
-- VITA-Velocia packet padder
-----------------------------------------------------------------------------
  inst_velo_pad : ii_vita_velo_pad
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,
    ch_pkt_size          => ch_pkt_size(1),
    force_pkt_size       => force_pkt_size(1),
    bypass               => pad_bypass,

    -- Source channel interface
    src_wrd_cnt          => pkt_din_wrd_cnt_sat,
    src_aempty           => vmvr_dst_aempty,
    src_empty            => vmvr_dst_empty,
    src_rden             => vmvr_dst_rden,
    src_vld              => vmvr_dst_vld,
    src_data             => vmvr_dst_dout,

    -- Destination channel interface
    dst_wrd_cnt          => pad_dst_wrd_cnt,
    dst_aempty           => pad_dst_aempty,
    dst_empty            => pad_dst_empty,
    dst_rden             => pad_dst_rden,
    dst_vld              => pad_dst_vld,
    dst_dout             => pad_dst_dout
  );

-----------------------------------------------------------------------------
-- VITA-Checker
-----------------------------------------------------------------------------
  inst_vita_chkr : ii_vita_checker
  port map (
    -- Reset and clock
    srst                 => backend_rst,
    sys_clk              => sys_clk,

    -- Source data input
    src_vld              => pad_dst_vld,
    src_data             => pad_dst_dout,

    -- Status outputs
    hdr_error            => hdr_error,
    trlr_error           => trlr_error
  );

-----------------------------------------------------------------------------
-- LED
-----------------------------------------------------------------------------
  led1 <= pex_linkup_n;                   -- red LED, active low
  led2 <= not (led(0) and clks_locked);   -- green LED, active low
  led3 <= not led(1);                     -- front panel LED, active low

------------------------------------------------------------------------------
-- Aurora
------------------------------------------------------------------------------
  -- gen_aurora : if (ADD_AURORA) generate
  --   rio0 : ii_aurora_4l_intf_top
  --   generic map (
  --     USE_CHIPSCOPE        => 0,
  --     SIM_GTXRESET_SPEEDUP => 0,
  --     addr_bits            => 2,
  --     offset               => MR_AU0
  --   )
  --   port map (
  --     -- System reset and clocks
  --     srst                 => frontend_rst,
  --     sys_clk              => sys_clk,
  --     run_o                => open,

  --     -- Data source i/f
  --     src_rdy              => rio0_src_rdy,
  --     src_valid            => rio0_src_valid,
  --     src_din              => rio0_src_din,

  --     -- Destination FIFO i/f
  --     dest_rdy             => '1',
  --     dest_valid           => open,
  --     dest_dout            => open,

  --     -- slave wishbone interface
  --     wb_rst_i             => wb_rst,
  --     wb_clk_i             => sys_clk,
  --     wb_adr_i             => wb_adr_o,
  --     wb_dat_i             => wb_dat_o,
  --     wb_we_i              => wb_we_o,
  --     wb_stb_i             => wb_stb_o,
  --     wb_ack_o             => wb_ack_i(10),
  --     wb_dat_o             => wb_dat_i,

  --     -- GTX Serial I/O ports
  --     gtx_refclk_p         => gtx0_refclk_p,
  --     gtx_refclk_n         => gtx0_refclk_n,
  --     gtx_rxp              => gtx0_rxp,
  --     gtx_rxn              => gtx0_rxn,
  --     gtx_txp              => gtx0_txp,
  --     gtx_txn              => gtx0_txn
  --   );

  --   rio1 : ii_aurora_4l_intf_top
  --   generic map (
  --     USE_CHIPSCOPE        => 0,
  --     SIM_GTXRESET_SPEEDUP => 0,
  --     addr_bits            => 2,
  --     offset               => MR_AU1
  --   )
  --   port map (
  --     -- System reset and clocks
  --     srst                 => frontend_rst,
  --     sys_clk              => sys_clk,
  --     run_o                => open,

  --     -- Data source i/f
  --     src_rdy              => rio1_src_rdy,
  --     src_valid            => rio1_src_valid,
  --     src_din              => rio1_src_din,

  --     -- Destination FIFO i/f
  --     dest_rdy             => '1',
  --     dest_valid           => open,
  --     dest_dout            => open,

  --     -- slave wishbone interface
  --     wb_rst_i             => wb_rst,
  --     wb_clk_i             => sys_clk,
  --     wb_adr_i             => wb_adr_o,
  --     wb_dat_i             => wb_dat_o,
  --     wb_we_i              => wb_we_o,
  --     wb_stb_i             => wb_stb_o,
  --     wb_ack_o             => wb_ack_i(11),
  --     wb_dat_o             => wb_dat_i,

  --     -- GTX Serial I/O ports
  --     gtx_refclk_p         => gtx1_refclk_p,
  --     gtx_refclk_n         => gtx1_refclk_n,
  --     gtx_rxp              => gtx1_rxp,
  --     gtx_rxn              => gtx1_rxn,
  --     gtx_txp              => gtx1_txp,
  --     gtx_txn              => gtx1_txn
  --   );
  -- end generate;

  gen_no_aurora : if (not ADD_AURORA) generate
    rio0_src_rdy <= '1';
    rio1_src_rdy <= '1';
    wb_ack_i(10) <= '0';
    wb_ack_i(11) <= '0';
  end generate;

------------------------------------------------------------------------------
-- Analog Frontend Interface
------------------------------------------------------------------------------
  inst_afe_top : entity work.ii_afe_intf_top
  generic map (
    G_SIM                => false,
    SYS_CLK_FREQ         => SYS_CLK_FREQ,
    offset               => MR_AFE
  )
  port map (
    srst                 => frontend_rst,
    sys_clk              => sys_clk,

    -- reference clock
    ref_clk200           => ref_clk200,
    clk200_locked        => clks_locked,

    -- Slave Wishbone interface
    wb_rst_i             => wb_rst,
    wb_clk_i             => sys_clk,
    wb_adr_i             => wb_adr_o,
    wb_dat_i             => wb_dat_o,
    wb_we_i              => wb_we_o,
    wb_stb_i             => wb_stb_o,
    wb_ack_o             => wb_ack_i(8),
    wb_dat_o             => wb_dat_i,

    -- Alerts
    adc_trigger_o        => adc_trigger_o,
    dac_trigger_o        => dac_trigger_o,
    adc0_overrange       => adc0_overrange,
    adc1_overrange       => adc1_overrange,
    adc0_overflow        => adc0_overflow,
    adc1_overflow        => adc1_overflow,
    dac0_underflow       => dac0_underflow,
    dac1_underflow       => dac1_underflow,
    ovr_alrt_clr         => alert_clr(20),
    ovf_alrt_clr         => alert_clr(21),
    trig_alrt_clr        => alert_clr(24),
    udf_alrt_clr         => alert_clr(26),

    -- System interface
    ref_adc_clk          => ref_adc_clk,
    ref_dac_clk          => ref_dac_clk,
    adc_run_o            => adc_run_o,
    dac_run_o            => dac_run_o,

    -- DAC stream ID
    dac0_stream_id       => dac0_stream_id,
    dac1_stream_id       => dac1_stream_id,

    -- ADC0 fifo interface
    adc0_fifo_empty      => adc0_fifo_empty,
    adc0_fifo_aempty     => adc0_fifo_aempty,
    adc0_fifo_rd         => adc0_fifo_rd,
    adc0_fifo_vld        => adc0_fifo_valid,
    adc0_fifo_dout       => adc0_fifo_dout,

    -- ADC1 fifo interface
    adc1_fifo_empty      => adc1_fifo_empty,
    adc1_fifo_aempty     => adc1_fifo_aempty,
    adc1_fifo_rd         => adc1_fifo_rd,
    adc1_fifo_vld        => adc1_fifo_valid,
    adc1_fifo_dout       => adc1_fifo_dout,

    -- ADC0 raw interface
    adc0_raw_data        => adc0_raw_data,
    adc0_data_clk        => adc0_data_clk,

    -- ADC1 raw interface
    adc1_raw_data        => adc1_raw_data,
    adc1_data_clk        => adc1_data_clk,

    -- DAC0 data source fifo interface
    dac0_src_aempty      => vfifo0_o_aempty,
    dac0_src_empty       => vfifo0_o_empty,
    dac0_src_rden        => vfifo0_o_rden,
    dac0_src_vld         => vfifo0_o_vld,
    dac0_src_din         => vfifo0_o_data,

    -- DAC0 raw sample interface
    dac0_data            => dac0_data,
    dac0_data_wr_en      => dac0_data_wr_en,
    dac0_data_rdy        => dac0_data_rdy,

    -- DAC1 data source fifo interface
    dac1_src_aempty      => vfifo1_o_aempty,
    dac1_src_empty       => vfifo1_o_empty,
    dac1_src_rden        => vfifo1_o_rden,
    dac1_src_vld         => vfifo1_o_vld,
    dac1_src_din         => vfifo1_o_data,

    -- DAC1 raw sample interface
    dac1_data            => dac1_data,
    dac1_data_wr_en      => dac1_data_wr_en,
    dac1_data_rdy        => dac1_data_rdy,

    -- PLL interface
    pll_vcxo_en          => pll_vcxo_en,
    pll_vcxo_scl         => pll_vcxo_scl,
    pll_vcxo_sda         => pll_vcxo_sda,
    pll_pwr_down_n       => pll_pwr_down_n,
    pll_reset_n          => pll_reset_n,
    pll_spi_sclk         => pll_spi_sclk,
    pll_spi_le           => pll_spi_le,
    pll_spi_mosi         => pll_spi_mosi,
    pll_spi_miso         => pll_spi_miso,
    pll_ext_clk_sel      => pll_ext_clk_sel,
    pll_lock             => pll_lock,
    ref_adc_clk_p        => ref_adc_clk_p,
    ref_adc_clk_n        => ref_adc_clk_n,
    ref_dac_clk_p        => ref_dac_clk_p,
    ref_dac_clk_n        => ref_dac_clk_n,

    -- ADC external sync
    ext_sync_sel         => ext_sync_sel,
    adc0_ext_sync_p      => adc0_ext_sync_p,
    adc0_ext_sync_n      => adc0_ext_sync_n,
    adc0_ext_sync        => adc0_ext_sync,
    adc1_ext_sync_p      => adc1_ext_sync_p,
    adc1_ext_sync_n      => adc1_ext_sync_n,
    adc1_ext_sync        => adc1_ext_sync,
    dac0_ext_sync_p      => dac0_ext_sync_p,
    dac0_ext_sync_n      => dac0_ext_sync_n,
    dac1_ext_sync_p      => dac1_ext_sync_p,
    dac1_ext_sync_n      => dac1_ext_sync_n,

    -- ADC0 and ADC1 interface
    adc0_spi_sclk        => adc0_spi_sclk,
    adc0_spi_sdenb       => adc0_spi_sdenb,
    adc0_spi_sdio        => adc0_spi_sdio,
    adc0_reset_p         => adc0_reset_p,
    adc0_reset_n         => adc0_reset_n,
    adc0_da_dclk_p       => adc0_da_dclk_p,
    adc0_da_dclk_n       => adc0_da_dclk_n,
    adc0_da_p            => adc0_da_p,
    adc0_da_n            => adc0_da_n,
    adc0_ovra_p          => adc0_ovra_p,
    adc0_ovra_n          => adc0_ovra_n,
    adc1_spi_sclk        => adc1_spi_sclk,
    adc1_spi_sdenb       => adc1_spi_sdenb,
    adc1_spi_sdio        => adc1_spi_sdio,
    adc1_reset_p         => adc1_reset_p,
    adc1_reset_n         => adc1_reset_n,
    adc1_da_dclk_p       => adc1_da_dclk_p,
    adc1_da_dclk_n       => adc1_da_dclk_n,
    adc1_da_p            => adc1_da_p,
    adc1_da_n            => adc1_da_n,
    adc1_ovra_p          => adc1_ovra_p,
    adc1_ovra_n          => adc1_ovra_n,

    -- DAC0 and DAC1 interface signals
    dac0_resetb          => dac0_resetb,
    dac0_spi_sclk        => dac0_spi_sclk,
    dac0_spi_sdenb       => dac0_spi_sdenb,
    dac0_spi_sdio        => dac0_spi_sdio,
    dac0_spi_sdo         => dac0_spi_sdo,
    dac0_clk_in_p        => dac0_clk_in_p,
    dac0_clk_in_n        => dac0_clk_in_n,
    dac0_dclk_p          => dac0_dclk_p,
    dac0_dclk_n          => dac0_dclk_n,
    dac0_sync_p          => dac0_sync_p,
    dac0_sync_n          => dac0_sync_n,
    dac0_sync2_p         => dac0_sync2_p,
    dac0_sync2_n         => dac0_sync2_n,
    dac0_data_p          => dac0_data_p,
    dac0_data_n          => dac0_data_n,
    dac1_resetb          => dac1_resetb,
    dac1_spi_sclk        => dac1_spi_sclk,
    dac1_spi_sdenb       => dac1_spi_sdenb,
    dac1_spi_sdio        => dac1_spi_sdio,
    dac1_spi_sdo         => dac1_spi_sdo,
    dac1_clk_in_p        => dac1_clk_in_p,
    dac1_clk_in_n        => dac1_clk_in_n,
    dac1_dclk_p          => dac1_dclk_p,
    dac1_dclk_n          => dac1_dclk_n,
    dac1_sync_p          => dac1_sync_p,
    dac1_sync_n          => dac1_sync_n,
    dac1_sync2_p         => dac1_sync2_p,
    dac1_sync2_n         => dac1_sync2_n,
    dac1_data_p          => dac1_data_p,
    dac1_data_n          => dac1_data_n,

    dac_ch_en            => dac_ch_en,
    dac0_trigger         => dac0_trigger,
    dac0_trigger_en      => dac0_trigger_en,
    dac1_trigger         => dac1_trigger,
    dac1_trigger_en      => dac1_trigger_en,

    -- DAC output digitizer interface
    dac_dig_en           => dac_dig_en,
    dac0_dig_p           => dac0_dig_p,
    dac0_dig_n           => dac0_dig_n,
    dac1_dig_p           => dac1_dig_p,
    dac1_dig_n           => dac1_dig_n,

    -- PPS pulse input (ie. GPS)
    ts_pps_pls           => h_pps_demet_re
  );

  adc0_fifo_rd <= '1';
  adc1_fifo_rd <= '1';

  dac0_ext_sync <= adc0_ext_sync;
  dac1_ext_sync <= adc1_ext_sync;
  
--Pulse generators

pg0 : entity work.PulseGenerator
  generic map (
        wb_offset => MR_PG0
    )
  port map (
    sys_clk => sys_clk,
    reset => backend_rst,
    trigger => dac0_ext_sync,

    --DAC data interface
    dac_data => dac0_data,
    dac_data_wr_en => dac0_data_wr_en,
    dac_data_rdy   => dac0_data_rdy,

    --wishbone interface
    wb_rst_i => wb_rst,
    wb_clk_i => sys_clk,
    wb_adr_i => wb_adr_o,
    wb_dat_i => wb_dat_o,
    wb_we_i  => wb_we_o,
    wb_stb_i => wb_stb_o,
    wb_ack_o => wb_ack_i(14),
    wb_dat_o => wb_dat_i,

    wf_rd_addr_copy => wf_rd_addr_copy_dac0
  ) ;

pg1 : entity work.PulseGenerator
    generic map (
        wb_offset => MR_PG1
    )
    port map (
    sys_clk => sys_clk,
    reset => backend_rst,
    trigger => dac1_ext_sync,

    --DAC data interface
    dac_data => dac1_data,
    dac_data_wr_en => dac1_data_wr_en,
    dac_data_rdy   => dac1_data_rdy,

    --wishbone interface
    wb_rst_i => wb_rst,
    wb_clk_i => sys_clk,
    wb_adr_i => wb_adr_o,
    wb_dat_i => wb_dat_o,
    wb_we_i  => wb_we_o,
    wb_stb_i => wb_stb_o,
    wb_ack_o => wb_ack_i(15),
    wb_dat_o => wb_dat_i,

    wf_rd_addr_copy => wf_rd_addr_copy_dac1
    ) ;


inst_dsp0 : entity work.ii_dsp_top
  generic map (
    dsp_app_offset => MR_DSP0_APP
  )
  port map (
    srst => backend_rst,
    sys_clk => sys_clk,
    trigger => adc0_ext_sync,

    -- Slave Wishbone Interface
    wb_rst_i => wb_rst,
    wb_clk_i => sys_clk,
    wb_adr_i => wb_adr_o,
    wb_dat_i => wb_dat_o,
    wb_we_i  => wb_we_o,
    wb_stb_i => wb_stb_o,
    wb_ack_o => wb_ack_i(12),
    wb_dat_o => wb_dat_i,

    -- Input raw data interface
    raw_data_clk => adc0_data_clk,
    raw_data => adc0_raw_data,

    -- VITA-49 Output FIFO Interface
    muxed_vita_rden  => vfifo2_i_rdy,
    muxed_vita_vld   => vfifo2_i_wren,
    muxed_vita_data  => vfifo2_i_data,

    -- Decision Engine outputs
    state     => state0,
    state_vld => state0_vld 
  );

  inst_dsp1 : entity work.ii_dsp_top
  generic map (
    dsp_app_offset => MR_DSP1_APP
  )
  port map (
    srst => backend_rst,
    sys_clk => sys_clk,
    trigger => adc1_ext_sync,

    -- Slave Wishbone Interface
    wb_rst_i => wb_rst,
    wb_clk_i => sys_clk,
    wb_adr_i => wb_adr_o,
    wb_dat_i => wb_dat_o,
    wb_we_i  => wb_we_o,
    wb_stb_i => wb_stb_o,
    wb_ack_o => wb_ack_i(13),
    wb_dat_o => wb_dat_i,

    -- Input raw data interface
    raw_data_clk => adc1_data_clk,
    raw_data => adc1_raw_data,

    -- VITA-49 Output FIFO Interface
    muxed_vita_rden  => vfifo3_i_rdy,
    muxed_vita_vld   => vfifo3_i_wren,
    muxed_vita_data  => vfifo3_i_data,

    -- Decision Engine outputs
    state => state1,
    state_vld => state1_vld 
  );

  inst_chipscope_icon : entity work.chipscope_icon
  port map (
    CONTROL0 => control0,
    CONTROL1 => control1,
    CONTROL2 => control2,
    CONTROL3 => control3);

  inst_chipscope_dac0 : entity work.chipscope_ila_dac
  port map (
    CONTROL => control0,
    CLK => sys_clk,
    DATA(111 downto 87) => (others => '0'),
    DATA(86) => dac0_trigger_en,
    DATA(85) => dac0_trigger,
    DATA(84 downto 83) => dac_ch_en(1 downto 0),
    DATA(82) => dac_run_o,
    DATA(81) => dac0_data_rdy,
    DATA(80) => dac0_data_wr_en,
    DATA(79 downto 16) => dac0_data,
    DATA(15 downto 0) => wf_rd_addr_copy_dac0,
    TRIG0(0) => dac0_ext_sync);

  inst_chipscope_dac1 : entity work.chipscope_ila_dac
  port map (
    CONTROL => control1,
    CLK => sys_clk,
    DATA(111 downto 87) => (others => '0'),
    DATA(86) => dac1_trigger_en,
    DATA(85) => dac1_trigger,
    DATA(84 downto 83) => dac_ch_en(3 downto 2),
    DATA(82) => dac_run_o,
    DATA(81) => dac1_data_rdy,
    DATA(80) => dac1_data_wr_en,
    DATA(79 downto 16) => dac1_data,
    DATA(15 downto 0) => wf_rd_addr_copy_dac1,
    TRIG0(0) => dac1_ext_sync);

  inst_chipscope_adc0 : entity work.chipscope_ila_adc
  port map (
    CONTROL => control2,
    CLK => adc0_data_clk,
    DATA(48) => adc0_ext_sync,
    DATA(47 downto 0) => adc0_raw_data,
    TRIG0(0) => adc0_ext_sync);

  inst_chipscope_adc1 : entity work.chipscope_ila_adc
  port map (
    CONTROL => control3,
    CLK => adc1_data_clk,
    DATA(48) => adc1_ext_sync,
    DATA(47 downto 0) => adc1_raw_data,
    TRIG0(0) => adc1_ext_sync);

------------------------------------------------------------------------------
-- DSP VITA mover
------------------------------------------------------------------------------
  -- rtr_src_aempty <= adc1_fifo_aempty & adc0_fifo_aempty & lpbk_fifo_aempty;
  -- rtr_src_empty  <= adc1_fifo_empty & adc0_fifo_empty & lpbk_fifo_empty;
  -- rtr_src_vld    <= adc1_fifo_valid & adc0_fifo_valid & lpbk_fifo_vld;

  lpbk_fifo_rden <= '1';


------------------------------------------------------------------------------
-- Misc.
------------------------------------------------------------------------------
  -- Detect a rising edge on the h_pps input
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      h_pps_xdom     <= h_pps;
      h_pps_demet    <= h_pps_xdom;
      h_pps_demet_d  <= h_pps_demet;
      h_pps_demet_re <= not h_pps_demet_d and h_pps_demet;
    end if;
  end process;

end arch;
