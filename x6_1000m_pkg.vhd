-- Copyright 2010 by Innovative Integration Inc., All Rights Reserved.
--******************************************************************************
--* Design Name: x6_pkg
--*
--* @li Target Device: Virtex-6
--* @li Tool versions: ISE 13.2
--*
--*     @short generic X6 project package
--*
--* Description:
--*
--*   This file defines the packages for the X6 family framework logic.
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date created 4/29/2011
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package x6_pkg is

------------------------------------------------------------------------------
-- Constants declarations
------------------------------------------------------------------------------
  constant num_pkt_ch      : positive := 2;  -- number of packetizer channels (including alerts)
  constant num_pd_df       : integer  := 2;  -- number of deframer channels
  constant num_alerts      : integer  := 32; -- number of alerts (must be multiple of 4)

------------------------------------------------------------------------------
-- Wishbone slave address offset and register map constant declarations
------------------------------------------------------------------------------
  -- Peripheral Registers
  constant MR_PRF              : std_logic_vector(15 downto 0) := X"0000";
  constant MR_PRF_INFO         : unsigned(15 downto 0) := unsigned(MR_PRF) + 0;
  constant MR_PRF_RST          : unsigned(15 downto 0) := unsigned(MR_PRF) + 1;
  constant MR_PRF_SEC_ROM      : unsigned(15 downto 0) := unsigned(MR_PRF) + 2;
  constant MR_PRF_SUB_REV      : unsigned(15 downto 0) := unsigned(MR_PRF) + 3;
  constant MR_PRF_VPAD_CFG     : unsigned(15 downto 0) := unsigned(MR_PRF) + 4;
  constant MR_PRF_H_TRIG       : unsigned(15 downto 0) := unsigned(MR_PRF) + 5;
  constant MR_PRF_SIO_XO       : unsigned(15 downto 0) := unsigned(MR_PRF) + 6;
  constant MR_PRF_LPDDR        : unsigned(15 downto 0) := unsigned(MR_PRF) + 7;
  constant MR_PRF_DEF_PID0     : unsigned(15 downto 0) := unsigned(MR_PRF) + 8;
  constant MR_PRF_DEF_PID1     : unsigned(15 downto 0) := unsigned(MR_PRF) + 9;

  -- Loader Interface Registers
  constant MR_LDR              : std_logic_vector(15 downto 0) := X"0100";
  constant MR_LDR_ADDR         : unsigned(15 downto 0) := unsigned(MR_LDR) + 0;
  constant MR_LDR_DATA         : unsigned(15 downto 0) := unsigned(MR_LDR) + 1;
  constant MR_LDR_CMD          : unsigned(15 downto 0) := unsigned(MR_LDR) + 2;

  -- Temperature Control Registers
  constant MR_TMP              : std_logic_vector(15 downto 0) := X"0200";
  constant MR_TMP_TEMP         : unsigned(15 downto 0) := unsigned(MR_TMP) + 0;
  constant MR_TMP_FAN_THRSH    : unsigned(15 downto 0) := unsigned(MR_TMP) + 1;
  constant MR_TMP_WARN_THRSH   : unsigned(15 downto 0) := unsigned(MR_TMP) + 2;
  constant MR_TMP_CMD_CH       : unsigned(15 downto 0) := unsigned(MR_TMP) + 3;

  -- Packetizer Registers
  constant MR_PKT              : std_logic_vector(15 downto 0) := X"0300";
  constant MR_PKT_DATA_CH_EN   : unsigned(15 downto 0) := unsigned(MR_PKT) + 0;
  constant MR_PKT_AUX_HDR      : unsigned(15 downto 0) := unsigned(MR_PKT) + 1;
  constant MR_PKT_ALRT_HDR     : unsigned(15 downto 0) := unsigned(MR_PKT) + 2;
  constant MR_PKT_DATA_HDR0    : unsigned(15 downto 0) := unsigned(MR_PKT) + 3;
  constant MR_PKT_FRC_CH_SIZE  : unsigned(15 downto 0) := unsigned(MR_PKT) + 34;
  constant MR_PKT_TIMER        : unsigned(15 downto 0) := unsigned(MR_PKT) + 35;

  -- Alert Registers
  constant MR_ALR              : std_logic_vector(15 downto 0) := X"0400";
  constant MR_ALR_ENAB         : unsigned(15 downto 0) := unsigned(MR_ALR) + 0;
  constant MR_ALR_CTRL         : unsigned(15 downto 0) := unsigned(MR_ALR) + 1;
  constant MR_ALR_SW           : unsigned(15 downto 0) := unsigned(MR_ALR) + 2;
  constant MR_ALR_CLR          : unsigned(15 downto 0) := unsigned(MR_ALR) + 3;

  -- DIO Registers
  constant MR_DIO              : std_logic_vector(15 downto 0) := X"0500";
  constant MR_DIO_DOUT_L       : unsigned(15 downto 0) := unsigned(MR_DIO) + 0;
  constant MR_DIO_DOUT_H       : unsigned(15 downto 0) := unsigned(MR_DIO) + 1;
  constant MR_DIO_OE_L         : unsigned(15 downto 0) := unsigned(MR_DIO) + 2;
  constant MR_DIO_OE_H         : unsigned(15 downto 0) := unsigned(MR_DIO) + 3;

  -- Flash Registers
  constant MR_ROM              : std_logic_vector(15 downto 0) := X"0600";
  constant MR_ROM_ADDR_CTRL    : unsigned(15 downto 0) := unsigned(MR_ROM) + 0;
  constant MR_ROM_DATA         : unsigned(15 downto 0) := unsigned(MR_ROM) + 1;
  constant MR_ROM_OPCODE       : unsigned(15 downto 0) := unsigned(MR_ROM) + 2;
  constant MR_ROM_RD_VALID     : integer := 30;
  constant MR_ROM_SPI_RDY      : integer := 31;

  -- MatLab BSP Registers
  constant MR_BSP              : std_logic_vector(15 downto 0) := X"0700";

  -- AFE Interface Registers
  constant MR_AFE              : std_logic_vector(15 downto 0) := X"0800";
  constant MR_AFE_PLL_CTRL     : unsigned(15 downto 0) := unsigned(MR_AFE) + 0;
  constant MR_AFE_PLL_SPI      : unsigned(15 downto 0) := unsigned(MR_AFE) + 1;
  constant MR_AFE_VCXO         : unsigned(15 downto 0) := unsigned(MR_AFE) + 2;
  constant MR_AFE_CLK_CTRL     : unsigned(15 downto 0) := unsigned(MR_AFE) + 3;
  constant MR_AFE_TEST_CTRL    : unsigned(15 downto 0) := unsigned(MR_AFE) + 4;
  constant MR_AFE_FLOW_CTRL    : unsigned(15 downto 0) := unsigned(MR_AFE) + 5;
  constant MR_AFE_SW_TRIG      : unsigned(15 downto 0) := unsigned(MR_AFE) + 6;
  constant MR_AFE_EXT_SYNC_CFG : unsigned(15 downto 0) := unsigned(MR_AFE) + 7;
  constant MR_AFE_ADC_EN       : unsigned(15 downto 0) := unsigned(MR_AFE) + 8;
  constant MR_AFE_ADC_TRGR     : unsigned(15 downto 0) := unsigned(MR_AFE) + 9;
  constant MR_AFE_ADC_DECI     : unsigned(15 downto 0) := unsigned(MR_AFE) + 10;
  constant MR_AFE_ADC_PRI_TRGR : unsigned(15 downto 0) := unsigned(MR_AFE) + 11;
  constant MR_AFE_ADC_PRI      : unsigned(15 downto 0) := unsigned(MR_AFE) + 12;
  constant MR_AFE_ADC_PRI_PARAM: unsigned(15 downto 0) := unsigned(MR_AFE) + 13;
  constant MR_AFE_ADC_PRI_WIDTH: unsigned(15 downto 0) := unsigned(MR_AFE) + 14;
  constant MR_AFE_ADC0_SPI_CTRL: unsigned(15 downto 0) := unsigned(MR_AFE) + 16;
  constant MR_AFE_ADC0_SPI_STAT: unsigned(15 downto 0) := unsigned(MR_AFE) + 17;
  constant MR_AFE_ADC1_SPI_CTRL: unsigned(15 downto 0) := unsigned(MR_AFE) + 18;
  constant MR_AFE_ADC1_SPI_STAT: unsigned(15 downto 0) := unsigned(MR_AFE) + 19;
  constant MR_AFE_ADC_PHY_CAL  : unsigned(15 downto 0) := unsigned(MR_AFE) + 20;
  constant MR_AFE_ADC0_CAL_STS : unsigned(15 downto 0) := unsigned(MR_AFE) + 25;
  constant MR_AFE_ADC1_CAL_STS : unsigned(15 downto 0) := unsigned(MR_AFE) + 26;
  constant MR_AFE_ADC_AMP_CFG  : unsigned(15 downto 0) := unsigned(MR_AFE) + 27;
  constant MR_AFE_ADC_TS_LD    : unsigned(15 downto 0) := unsigned(MR_AFE) + 32;
  constant MR_AFE_ADC_TS_CTRL  : unsigned(15 downto 0) := unsigned(MR_AFE) + 33;
  constant MR_AFE_ADC0_VFRAME  : unsigned(15 downto 0) := unsigned(MR_AFE) + 48;
  constant MR_AFE_ADC1_VFRAME  : unsigned(15 downto 0) := unsigned(MR_AFE) + 49;
  constant MR_AFE_ADC0_SID     : unsigned(15 downto 0) := unsigned(MR_AFE) + 64;
  constant MR_AFE_ADC1_SID     : unsigned(15 downto 0) := unsigned(MR_AFE) + 65;
  constant MR_AFE_ADC0_GAIN    : unsigned(15 downto 0) := unsigned(MR_AFE) + 80;
  constant MR_AFE_ADC1_GAIN    : unsigned(15 downto 0) := unsigned(MR_AFE) + 81;
  constant MR_AFE_ADC0_OFST    : unsigned(15 downto 0) := unsigned(MR_AFE) + 96;
  constant MR_AFE_ADC1_OFST    : unsigned(15 downto 0) := unsigned(MR_AFE) + 97;
  constant MR_AFE_DAC_EN       : unsigned(15 downto 0) := unsigned(MR_AFE) + 128;
  constant MR_AFE_DAC_TRGR     : unsigned(15 downto 0) := unsigned(MR_AFE) + 129;
  constant MR_AFE_DAC_RST      : unsigned(15 downto 0) := unsigned(MR_AFE) + 131;
  constant MR_AFE_DAC_PINC     : unsigned(15 downto 0) := unsigned(MR_AFE) + 132;
  constant MR_AFE_DAC_PRI_TRGR : unsigned(15 downto 0) := unsigned(MR_AFE) + 133;
  constant MR_AFE_DAC_PRI      : unsigned(15 downto 0) := unsigned(MR_AFE) + 134;
  constant MR_AFE_DAC_PRI_PARAM: unsigned(15 downto 0) := unsigned(MR_AFE) + 135;
  constant MR_AFE_DAC_PRI_WIDTH: unsigned(15 downto 0) := unsigned(MR_AFE) + 136;
  constant MR_AFE_DAC0_SPI_CTRL: unsigned(15 downto 0) := unsigned(MR_AFE) + 144;
  constant MR_AFE_DAC0_SPI_STAT: unsigned(15 downto 0) := unsigned(MR_AFE) + 145;
  constant MR_AFE_DAC1_SPI_CTRL: unsigned(15 downto 0) := unsigned(MR_AFE) + 146;
  constant MR_AFE_DAC1_SPI_STAT: unsigned(15 downto 0) := unsigned(MR_AFE) + 147;
  constant MR_AFE_DAC_CAL      : unsigned(15 downto 0) := unsigned(MR_AFE) + 152;
  constant MR_AFE_DAC0_SID     : unsigned(15 downto 0) := unsigned(MR_AFE) + 192;
  constant MR_AFE_DAC1_SID     : unsigned(15 downto 0) := unsigned(MR_AFE) + 193;
  constant MR_AFE_DAC0A_GAIN   : unsigned(15 downto 0) := unsigned(MR_AFE) + 208;
  constant MR_AFE_DAC0B_GAIN   : unsigned(15 downto 0) := unsigned(MR_AFE) + 209;
  constant MR_AFE_DAC1A_GAIN   : unsigned(15 downto 0) := unsigned(MR_AFE) + 210;
  constant MR_AFE_DAC1B_GAIN   : unsigned(15 downto 0) := unsigned(MR_AFE) + 211;
  constant MR_AFE_DAC0A_OFST   : unsigned(15 downto 0) := unsigned(MR_AFE) + 224;
  constant MR_AFE_DAC0B_OFST   : unsigned(15 downto 0) := unsigned(MR_AFE) + 225;
  constant MR_AFE_DAC1A_OFST   : unsigned(15 downto 0) := unsigned(MR_AFE) + 226;
  constant MR_AFE_DAC1B_OFST   : unsigned(15 downto 0) := unsigned(MR_AFE) + 227;

  -- DDC Registers
  constant MR_DDC              : std_logic_vector(15 downto 0) := X"0900";

  -- Aurora 0 Registers
  constant MR_AU0              : std_logic_vector(15 downto 0) := X"0A00";
  constant MR_AU0_TEST_CTRL    : unsigned(15 downto 0) := unsigned(MR_AU0) + 0;
  constant MR_AU0_CTRL_STAT    : unsigned(15 downto 0) := unsigned(MR_AU0) + 1;
  constant MR_AU0_CMD_WR       : unsigned(15 downto 0) := unsigned(MR_AU0) + 2;
  constant MR_AU0_CMD_RD       : unsigned(15 downto 0) := unsigned(MR_AU0) + 3;

  -- Aurora 1 Registers
  constant MR_AU1              : std_logic_vector(15 downto 0) := X"0B00";
  constant MR_AU1_TEST_CTRL    : unsigned(15 downto 0) := unsigned(MR_AU1) + 0;
  constant MR_AU1_CTRL_STAT    : unsigned(15 downto 0) := unsigned(MR_AU1) + 1;
  constant MR_AU1_CMD_WR       : unsigned(15 downto 0) := unsigned(MR_AU1) + 2;
  constant MR_AU1_CMD_RD       : unsigned(15 downto 0) := unsigned(MR_AU1) + 3;

-----------------------------------------------------------------------------
-- Data type declarations
-----------------------------------------------------------------------------
  subtype width_8 is std_logic_vector(7 downto 0);
  subtype width_16 is std_logic_vector(15 downto 0);
  subtype width_22 is std_logic_vector(21 downto 0);
  subtype width_23 is std_logic_vector(22 downto 0);
  subtype width_24 is std_logic_vector(23 downto 0);
  subtype width_32 is std_logic_vector(31 downto 0);
  subtype width_64 is std_logic_vector(63 downto 0);
  subtype width_128 is std_logic_vector(127 downto 0);

  -- array for data bus to packetizer
  type width_8_ch_array is array (num_pkt_ch-1 downto 0) of width_8;
  type width_22_ch_array is array (num_pkt_ch-1 downto 0) of width_22;
  type width_23_ch_array is array (num_pkt_ch-1 downto 0) of width_23;
  type width_24_ch_array is array (num_pkt_ch-1 downto 0) of width_24;
  type width_64_ch_array is array (num_pkt_ch-1 downto 0) of width_64;
  type width_128_ch_array is array (num_pkt_ch-1 downto 0) of width_128;

  -- address array for peripherals
  type width_8_pd_df_array is array (num_pd_df - 1 downto 0) of width_8;
  type width_32_alrt_array is array (num_alerts - 1 downto 0) of width_32;

-----------------------------------------------------------------------------
-- Component declarations
-----------------------------------------------------------------------------
  component ii_crm
    generic (
      SYS_CLK_FREQ         : integer := 250; -- system clk freq in MHz
      MEM_CLK_FREQ         : integer := 333  -- memory clk freq in MHz
    );
    port (
      por_arst             : in  std_logic;
      brd_arst             : in  std_logic;
      clk200_p             : in  std_logic;
      clk200_n             : in  std_logic;
      ref_clk200           : out std_logic;
      sys_clk              : out std_logic;
      mem_clk_div2         : out std_logic;
      clks_locked          : out std_logic;
      app_rst              : in  std_logic;
      run                  : in  std_logic;
      mem_rst              : out std_logic;
      wb_rst               : out std_logic;
      frontend_rst         : out std_logic;
      backend_rst          : out std_logic
    );
  end component;

  component ii_pcie_intf
    generic (
      PCIE_LANES           : integer
    );
    port (
      pex_ref_clk_p        : in  std_logic;  -- pcie clock in (from connector)
      pex_ref_clk_n        : in  std_logic;  -- pcie clock in (from connector)
      pex_rst_n            : in  std_logic;  -- asynch reset, active low
      sys_clk              : in  std_logic;  -- system clock (from xtal)
      pex_clk              : out std_logic;
      brd_rst              : out std_logic;
      linkup_n             : out std_logic;
      pex_mbist_n          : out std_logic;

      -- rx fifo i/o
      rx_fifo_rden         : in  std_logic;
      rx_fifo_empty        : out std_logic;
      rx_fifo_aempty       : out std_logic;
      rx_fifo_valid        : out std_logic;
      rx_fifo_dout         : out std_logic_vector(127 downto 0);

      -- tx fifo i/o
      tx_fifo_wren         : in  std_logic;
      tx_fifo_din          : in  std_logic_vector(127 downto 0);
      tx_fifo_rdy          : out std_logic;

      -- PCIe serial Rocket i/o
      txp                  : out std_logic_vector(PCIE_LANES-1 downto 0);
      txn                  : out std_logic_vector(PCIE_LANES-1 downto 0);
      rxp                  : in  std_logic_vector(PCIE_LANES-1 downto 0);
      rxn                  : in  std_logic_vector(PCIE_LANES-1 downto 0);

      ctrl_addr            : out std_logic_vector(31 downto 0);
      ctrl_dout            : out std_logic_vector(31 downto 0);
      ctrl_rd              : out std_logic;
      ctrl_wr              : out std_logic;
      ctrl_vld             : in  std_logic;
      ctrl_din             : in  std_logic_vector(31 downto 0)
    );
  end component;

  component ii_regs_master
    port (
      rst                  : in  std_logic;
      pcie_clk             : in  std_logic;

      ctrl_addr            : in  std_logic_vector(31 downto 0);
      ctrl_din             : in  std_logic_vector(31 downto 0);
      ctrl_rd              : in  std_logic;
      ctrl_wr              : in  std_logic;
      ctrl_vld             : out std_logic;
      ctrl_dout            : out std_logic_vector(31 downto 0);

      -- master wishbone interface
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_o             : out std_logic_vector(15 downto 0);
      wb_dat_o             : out std_logic_vector(31 downto 0);
      wb_we_o              : out std_logic;
      wb_stb_o             : out std_logic;
      wb_cyc_o             : out std_logic;
      wb_ack_i             : in  std_logic;
      wb_dat_i             : in  std_logic_vector(31 downto 0)
    );
  end component;

  component ii_regs_periph
    generic (
      addr_bits            : integer := 4;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- User registers
      revision             : in  std_logic_vector(15 downto 0);
      cfg                  : in  std_logic_vector(3 downto 0);
      hw_rev               : in  std_logic_vector(2 downto 0);
      hw_type              : in  std_logic_vector(3 downto 0);
      fpga_type            : in  std_logic_vector(1 downto 0);
      app_rst              : out std_logic;
      led                  : out std_logic_vector(1 downto 0);
      ds_data_oe           : out std_logic;
      ds_data_o            : out std_logic;
      ds_data_i            : in  std_logic;
      sub_rev              : in  std_logic_vector(7 downto 0);
      bypass_vita_pad      : out std_logic;
      vita_hdr_err         : in  std_logic;
      vita_trlr_err        : in  std_logic;
      h_pps                : in  std_logic;
      sio_xo_sdo           : out std_logic;
      sio_xo_scl           : out std_logic;
      sio_xo_sdi           : in  std_logic;
      sio_xo_intr          : in  std_logic;
      lpddr2_dpd_req       : out std_logic_vector(3 downto 0);
      lpddr2_phy_init_done : in  std_logic_vector(3 downto 0);
      playback_en          : out std_logic_vector(1 downto 0);
      mem_test_en          : out std_logic_vector(3 downto 0);
      mem_test_error       : in  std_logic_vector(3 downto 0);
      def_pid_addr0        : out std_logic_vector(31 downto 24);
      def_pid_addr1        : out std_logic_vector(31 downto 24)
    );
  end component;

  component ii_temp_control_top
    generic (
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- system interface
      srst                 : in  std_logic;
      clk                  : in  std_logic;

      -- temp_control signals
      crit_temp_sel        : in  std_logic;
      temp_warning         : out std_logic;
      fan_en               : out std_logic;

      -- LM96163 interface
      smb_clk              : out std_logic;
      smb_data             : inout std_logic
    );
  end component;

  component ii_alert_gen
    generic (
      width                : integer := 16
    );
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Input alerts
      alert_din            : in  std_logic_vector(width-1 downto 0);

      -- Output alert
      alert_strb           : out std_logic;
      alert_dout           : out std_logic_vector(width-1 downto 0)
    );
  end component;

  component ii_alerts_top
    generic (
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- alerts interface
      ref_clk              : in  std_logic;
      alert_data           : in  width_32_alrt_array;
      alert                : in  std_logic_vector(num_alerts-1 downto 0);
      trigger              : in  std_logic;
      alert_sw_data        : out std_logic_vector(31 downto 0);
      alert_sw_stb         : out std_logic;
      alert_clr            : out std_logic_vector(num_alerts-1 downto 0);
      timestamp_rollover   : out std_logic;
      alert_fifo_wrd_cnt   : out std_logic_vector(8 downto 0);
      alert_fifo_aempty    : out std_logic;
      alert_fifo_empty     : out std_logic;
      alert_fifo_rd        : in  std_logic;
      alert_dout_vld       : out std_logic;
      alert_dout           : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_vita_mvr_nx1
    generic (
      num_src_ch           : integer := 4
    );
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Source channels interface
      src_aempty           : in  std_logic_vector(num_src_ch-1 downto 0);
      src_empty            : in  std_logic_vector(num_src_ch-1 downto 0);
      src_rden             : out std_logic_vector(num_src_ch-1 downto 0);
      src_vld              : in  std_logic_vector(num_src_ch-1 downto 0);
      src_data             : in  std_logic_vector(128*num_src_ch-1 downto 0);

      -- Destination channels interface
      dst_wrd_cnt          : out std_logic_vector(8 downto 0);
      dst_aempty           : out std_logic;
      dst_empty            : out std_logic;
      dst_rden             : in  std_logic;
      dst_vld              : out std_logic;
      dst_dout             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_vita_router
    generic (
      num_src_ch           : integer := 4;
      num_dst_ch           : integer := 3
    );
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Source channels interface
      src_aempty           : in  std_logic_vector(num_src_ch-1 downto 0);
      src_empty            : in  std_logic_vector(num_src_ch-1 downto 0);
      src_rden             : out std_logic_vector(num_src_ch-1 downto 0);
      src_vld              : in  std_logic_vector(num_src_ch-1 downto 0);
      src_data             : in  std_logic_vector(128*num_src_ch-1 downto 0);

      -- Destination channels interface
      dst_rdy              : in  std_logic_vector(num_dst_ch-1 downto 0);
      dst_wren             : out std_logic_vector(num_dst_ch-1 downto 0);
      dst_data             : out std_logic_vector(128*num_dst_ch-1 downto 0)
    );
  end component;

  component ii_vita_velo_pad
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      ch_pkt_size          : in  std_logic_vector(23 downto 0);
      force_pkt_size       : in  std_logic;
      bypass               : in  std_logic;

      -- Source channels interface
      src_wrd_cnt          : in  std_logic_vector(21 downto 0);
      src_aempty           : in  std_logic;
      src_empty            : in  std_logic;
      src_rden             : out std_logic;
      src_vld              : in  std_logic;
      src_data             : in  std_logic_vector(127 downto 0);

      -- Destination channels interface
      dst_wrd_cnt          : out std_logic_vector(21 downto 0);
      dst_aempty           : out std_logic;
      dst_empty            : out std_logic;
      dst_rden             : in  std_logic;
      dst_vld              : out std_logic;
      dst_dout             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_vita_checker
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Source data input
      src_vld              : in  std_logic;
      src_data             : in  std_logic_vector(127 downto 0);

      -- Status outputs
      hdr_error            : out std_logic;
      trlr_error           : out std_logic
    );
  end component;

  component ii_packetizer_top
    generic (
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Exported settings
      ch_pkt_size          : out width_24_ch_array;
      force_pkt_size       : out std_logic_vector(num_pkt_ch-1 downto 0);

      -- Source channels interface
      src_data_cnt         : in  width_22_ch_array;
      src_aempty           : in  std_logic_vector(num_pkt_ch-1 downto 0);
      src_empty            : in  std_logic_vector(num_pkt_ch-1 downto 0);
      src_rden             : out std_logic_vector(num_pkt_ch-1 downto 0);
      src_data_vld         : in  std_logic_vector(num_pkt_ch-1 downto 0);
      data_in              : in  width_128_ch_array;

      -- Destination channel interface
      dest_rdy             : in  std_logic;
      dest_wren            : out std_logic;
      data_out             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_deframer
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Configuration
      pd_addr              : in  width_8_pd_df_array;

      -- Status
      new_packet           : out std_logic;
      bad_pdn              : out std_logic;
      end_of_packet        : out std_logic;

      -- Source channel interface
      src_aempty           : in  std_logic;
      src_empty            : in  std_logic;
      src_rden             : out std_logic;
      src_data_vld         : in  std_logic;
      data_in              : in  std_logic_vector(127 downto 0);

      -- Destination channels interface
      dest_rdy             : in  std_logic_vector(num_pd_df-1 downto 0);
      dest_wren            : out std_logic_vector(num_pd_df-1 downto 0);
      data_out             : out std_logic_vector(127 downto 0)
    );
  end component;

  component ii_loader_top
    generic (
      addr_bits            : integer := 2;
      offset               : std_logic_vector(15 downto 0) := x"0100"
    );
    port (
      -- Wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- FPA interface pins (Flash Programming & Authentication)
      loader_clk           : out std_logic;
      loader_cs            : out std_logic;
      loader_dio           : out std_logic;
      loader_bus           : inout std_logic_vector(15 downto 0)
    );
  end component;

  component ii_dio_top
    generic (
      width                : integer := 8;
      diff_en              : boolean := FALSE;
      addr_bits            : integer := 2;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone interface signals
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);
      -- DIO signals
      clk                  : in  std_logic;
      dio_p                : inout std_logic_vector(width-1 downto 0);
      dio_n                : inout std_logic_vector(width-1 downto 0)
    );
  end component;

  component ii_flash_intf_top
    generic (
      addr_bits            : integer := 2;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      -- Slave Wishbone interface
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);
      -- Flash SPI interface
      rom_sck              : out std_logic;
      rom_cs_n             : out std_logic;
      rom_sdi              : out std_logic;
      rom_sdo              : in  std_logic;
      rom_wp_n             : out std_logic;
      rom_hold_n           : out std_logic
    );
  end component;

  component ii_vfifo
    port (
      -- Reset and Clock inputs
      mem_rst              : in  std_logic;-- Synchronous active high memory reset
      mem_clk_div2         : in  std_logic;-- Memory clock divided by 2
      ref_clk200           : in  std_logic;-- 200MHz reference clock
      sys_clk              : in  std_logic;-- System clock

      -- Control and status
      dpd_req              : in  std_logic;-- Request to enter deep power down state
      run                  : in  std_logic;-- enable data flow
      test_en              : in  std_logic;-- enable test mode
      test_error           : out std_logic;-- error detected in test mode

      -- Input fifo interface (data write port)
      vfifo_i_wren         : in  std_logic;-- write data strobe
      vfifo_i_data         : in  std_logic_vector(127 downto 0);
      vfifo_i_rdy          : out std_logic;-- ready for data

      -- Output fifo interface (data read port)
      vfifo_o_rden         : in  std_logic;-- read data strobe
      vfifo_o_aethresh     : in  std_logic_vector(9 downto 0);
      vfifo_o_aempty       : out std_logic;
      vfifo_o_empty        : out std_logic;
      vfifo_o_vld          : out std_logic;-- read data valid indicator
      vfifo_o_data         : out std_logic_vector(127 downto 0);

      -- LPDDR2 status
      lpddr2_init_done     : out std_logic;-- lpddr2 memory initialization done
      lpddr2_overflow      : out std_logic;-- lpddr2 memory overflowed
      lpddr2_underflow     : out std_logic;-- lpddr2 memory underflowed
      lpddr2_wrd_cnt       : out std_logic_vector(29 downto 0);
      lpddr2_aempty        : out std_logic;-- mem_word_cnt < 1/512th the memory size
      lpddr2_afull         : out std_logic;-- mem_word_cnt > 511/512th the memory size

      -- LPDDR2 Output Interface
      lpddr2_ck_p          : out std_logic_vector(0 downto 0);
      lpddr2_ck_n          : out std_logic_vector(0 downto 0);
      lpddr2_cke           : out std_logic_vector(1 downto 0);
      lpddr2_cs_n          : out std_logic_vector(1 downto 0);
      lpddr2_ca            : out std_logic_vector(9 downto 0);
      lpddr2_dm            : out std_logic_vector(3 downto 0);
      lpddr2_dqs_p         : inout std_logic_vector(3 downto 0);
      lpddr2_dqs_n         : inout std_logic_vector(3 downto 0);
      lpddr2_dq            : inout std_logic_vector(31 downto 0)
    );
  end component;

  component ii_vfifo_pb
    port (
      -- Reset and Clock inputs
      mem_rst              : in  std_logic;-- Synchronous active high memory reset
      mem_clk_div2         : in  std_logic;-- Memory clock divided by 2
      ref_clk200           : in  std_logic;-- 200MHz reference clock
      sys_clk              : in  std_logic;-- System clock

      -- Control and status
      dpd_req              : in  std_logic;-- Request to enter deep power down state
      run                  : in  std_logic;-- enable data flow
      playback_en          : in  std_logic;-- enable playback mode
      test_en              : in  std_logic;-- enable test mode
      test_error           : out std_logic;-- error detected in test mode

      -- Playback command FIFO interface
      pbcmd_fifo_wren      : in  std_logic;-- write command strobe
      pbcmd_fifo_data      : in  std_logic_vector(127 downto 0);
      pbcmd_fifo_rdy       : out std_logic;-- ready for data

      -- Alert output
      tag_load_done        : out std_logic;
      tag_load_value       : out std_logic_vector(7 downto 0);
      tag_rep_done         : out std_logic;
      tag_rep_value        : out std_logic_vector(7 downto 0);

      -- Input fifo interface (data write port)
      vfifo_i_wren         : in  std_logic;-- write data strobe
      vfifo_i_data         : in  std_logic_vector(127 downto 0);
      vfifo_i_rdy          : out std_logic;-- ready for data

      -- Output fifo interface (data read port)
      vfifo_o_rden         : in  std_logic;-- read data strobe
      vfifo_o_aethresh     : in  std_logic_vector(9 downto 0);
      vfifo_o_aempty       : out std_logic;
      vfifo_o_empty        : out std_logic;
      vfifo_o_vld          : out std_logic;-- read data valid indicator
      vfifo_o_data         : out std_logic_vector(127 downto 0);

      -- LPDDR2 status
      lpddr2_init_done     : out std_logic;-- lpddr2 memory initialization done
      lpddr2_overflow      : out std_logic;-- lpddr2 memory overflowed
      lpddr2_underflow     : out std_logic;-- lpddr2 memory underflowed
      lpddr2_wrd_cnt       : out std_logic_vector(29 downto 0);
      lpddr2_aempty        : out std_logic;-- mem_word_cnt < 1/512th the memory size
      lpddr2_afull         : out std_logic;-- mem_word_cnt > 511/512th the memory size

      -- LPDDR2 Output Interface
      lpddr2_ck_p          : out std_logic_vector(0 downto 0);
      lpddr2_ck_n          : out std_logic_vector(0 downto 0);
      lpddr2_cke           : out std_logic_vector(1 downto 0);
      lpddr2_cs_n          : out std_logic_vector(1 downto 0);
      lpddr2_ca            : out std_logic_vector(9 downto 0);
      lpddr2_dm            : out std_logic_vector(3 downto 0);
      lpddr2_dqs_p         : inout std_logic_vector(3 downto 0);
      lpddr2_dqs_n         : inout std_logic_vector(3 downto 0);
      lpddr2_dq            : inout std_logic_vector(31 downto 0)
    );
  end component;

  component ii_aurora_4l_intf_top
    generic (
      USE_CHIPSCOPE        : integer := 0;
      SIM_GTXRESET_SPEEDUP : integer := 0;  -- Set to 1 to speed up sim reset
      addr_bits            : integer := 5;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- System reset and clocks
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;
      run_o                : out std_logic;

      -- Data source i/f
      src_rdy              : out std_logic;
      src_valid            : in  std_logic;
      src_din              : in  std_logic_vector(127 downto 0);

      -- Destination FIFO i/f
      dest_rdy             : in  std_logic;
      dest_valid           : out std_logic;
      dest_dout            : out std_logic_vector(127 downto 0);

      -- slave wishbone interface
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);

      -- GTX Serial I/O ports
      gtx_refclk_p         : in  std_logic;
      gtx_refclk_n         : in  std_logic;
      gtx_rxp              : in  std_logic_vector(3 downto 0);
      gtx_rxn              : in  std_logic_vector(3 downto 0);
      gtx_txp              : out std_logic_vector(3 downto 0);
      gtx_txn              : out std_logic_vector(3 downto 0)
    );
  end component;

  component ii_unsign_sat
    generic (
      ibw                  : integer;
      obw                  : integer
    );
    port (
      i                    : in  std_logic_vector(ibw-1 downto 0);
      o                    : out std_logic_vector(obw-1 downto 0)
    );
  end component;

  component ii_afe_intf_top
    generic (
      G_SIM                : boolean;
      SYS_CLK_FREQ         : integer := 250;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Reset and Clock
      srst                 : in    std_logic;
      sys_clk              : in    std_logic;

      -- reference clock
      ref_clk200           : in    std_logic;
      clk200_locked        : in    std_logic;

      -- Slave Wishbone interface
      wb_rst_i             : in    std_logic;
      wb_clk_i             : in    std_logic;
      wb_adr_i             : in    std_logic_vector(15 downto 0);
      wb_dat_i             : in    std_logic_vector(31 downto 0);
      wb_we_i              : in    std_logic;
      wb_stb_i             : in    std_logic;
      wb_ack_o             : out   std_logic;
      wb_dat_o             : out   std_logic_vector(31 downto 0);

      -- Alerts
      adc_trigger_o        : out   std_logic;
      dac_trigger_o        : out   std_logic;
      adc0_overrange       : out   std_logic;
      adc1_overrange       : out   std_logic;
      adc0_overflow        : out   std_logic;
      adc1_overflow        : out   std_logic;
      dac0_underflow       : out   std_logic;
      dac1_underflow       : out   std_logic;
      ovr_alrt_clr         : in    std_logic;
      ovf_alrt_clr         : in    std_logic;
      trig_alrt_clr        : in    std_logic;
      udf_alrt_clr         : in    std_logic;

      -- System interface
      ref_adc_clk          : out   std_logic;
      ref_dac_clk          : out   std_logic;
      adc_run_o            : out   std_logic;
      dac_run_o            : out   std_logic;

      -- DAC stream ID
      dac0_stream_id       : out std_logic_vector(15 downto 0);
      dac1_stream_id       : out std_logic_vector(15 downto 0);

      -- ADC0 fifo interface
      adc0_fifo_empty      : out   std_logic;
      adc0_fifo_aempty     : out   std_logic;
      adc0_fifo_rd         : in    std_logic;
      adc0_fifo_vld        : out   std_logic;
      adc0_fifo_dout       : out   std_logic_vector(127 downto 0);

      -- ADC1 fifo interface
      adc1_fifo_empty      : out   std_logic;
      adc1_fifo_aempty     : out   std_logic;
      adc1_fifo_rd         : in    std_logic;
      adc1_fifo_vld        : out   std_logic;
      adc1_fifo_dout       : out   std_logic_vector(127 downto 0);

      -- ADC0 raw data interface
      adc0_raw_rden        : in    std_logic;
      adc0_raw_vld         : out   std_logic;
      adc0_raw_dout        : out   std_logic_vector(11 downto 0);
      adc0_frame_out       : out   std_logic;

      -- ADC1 raw data interface
      adc1_raw_rden        : in    std_logic;
      adc1_raw_vld         : out   std_logic;
      adc1_raw_dout        : out   std_logic_vector(11 downto 0);
      adc1_frame_out       : out   std_logic;

      -- DAC0 data source fifo interface
      dac0_src_aempty      : in    std_logic;
      dac0_src_empty       : in    std_logic;
      dac0_src_rden        : out   std_logic;
      dac0_src_vld         : in    std_logic;
      dac0_src_din         : in    std_logic_vector(127 downto 0);

      -- DAC1 data source fifo interface
      dac1_src_aempty      : in    std_logic;
      dac1_src_empty       : in    std_logic;
      dac1_src_rden        : out   std_logic;
      dac1_src_vld         : in    std_logic;
      dac1_src_din         : in    std_logic_vector(127 downto 0);

      -- PLL interface
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

      -- PPS pulse input (ie. GPS)
      ts_pps_pls           : in    std_logic
    );
  end component;

  component sfifo_512x128_bltin
    port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      din                  : in  std_logic_vector(127 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(127 downto 0);
      full                 : out std_logic;
      empty                : out std_logic;
      valid                : out std_logic;
      prog_full            : out std_logic;
      prog_empty           : out std_logic
    );
  end component;

  component ii_dac_router
    port (
      -- Reset and clock
      srst                 : in  std_logic;
      sys_clk              : in  std_logic;

      -- Routing configuration
      dac0_stream_id       : in  std_logic_vector(15 downto 0);
      dac1_stream_id       : in  std_logic_vector(15 downto 0);

      -- Data source interface
      dac_rtr_rdy          : out std_logic;
      dac_rtr_wren         : in  std_logic;
      dac_rtr_data         : in  std_logic_vector(127 downto 0);

      -- Destination channels interface
      dac0_pbcmd_rdy       : in  std_logic;
      dac0_pbcmd_wren      : out std_logic;
      dac0_pbcmd_data      : out std_logic_vector(127 downto 0);
      dac0_vfifo_rdy       : in  std_logic;
      dac0_vfifo_wren      : out std_logic;
      dac0_vfifo_data      : out std_logic_vector(127 downto 0);
      dac1_pbcmd_rdy       : in  std_logic;
      dac1_pbcmd_wren      : out std_logic;
      dac1_pbcmd_data      : out std_logic_vector(127 downto 0);
      dac1_vfifo_rdy       : in  std_logic;
      dac1_vfifo_wren      : out std_logic;
      dac1_vfifo_data      : out std_logic_vector(127 downto 0)
    );
  end component;

end x6_pkg;

