-- Constants and declarations for qubit DSP
--
-- Copyright Raytheon BBN Technologies 2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BBN_QDSP_pkg is

--------------------------------------------------------------------------------
-- Constants declarations
--------------------------------------------------------------------------------
  constant NUM_DEMOD_CH      : natural := 2;   -- number of demodulated channels
  constant num_vita_streams  : natural := num_demod_ch + 2; -- results + demod + the raw data stream
  constant adc_data_width  : natural := 12;  -- number of bits in ADC data

  constant KERNEL_ADDR_WIDTH : natural := 12; --width of the kernel memory

--------------------------------------------------------------------------------
-- Data type declarations
--------------------------------------------------------------------------------
  type width_16_array_t is array (natural range <>) of std_logic_vector(15 downto 0);
  type width_24_array_t is array (natural range <>) of std_logic_vector(23 downto 0);
  type width_32_array_t is array (natural range <>) of std_logic_vector(31 downto 0);

  type kernel_addr_array is array (natural range <>) of std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0) ;

  component axis_async_fifo
    generic (
      ADDR_WIDTH : natural := 12;
      DATA_WIDTH : natural := 8
    );
    port (
      input_clk         : in std_logic;
      input_rst         : in std_logic;

      input_axis_tdata  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_axis_tvalid : in std_logic;
      input_axis_tready : out std_logic;
      input_axis_tlast  : in std_logic;
      input_axis_tuser  : in std_logic;

      output_clk         : in std_logic;
      output_rst         : in std_logic;
      output_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      output_axis_tvalid : out std_logic;
      output_axis_tready : in std_logic;
      output_axis_tlast  : out std_logic;
      output_axis_tuser  : out std_logic
    );
  end component;

  component axis_fifo
    generic (
      ADDR_WIDTH : natural := 12;
      DATA_WIDTH : natural := 8
    );
    port (
      clk         : in std_logic;
      rst         : in std_logic;

      input_axis_tdata  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_axis_tvalid : in std_logic;
      input_axis_tready : out std_logic;
      input_axis_tlast  : in std_logic;
      input_axis_tuser  : in std_logic;

      output_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      output_axis_tvalid : out std_logic;
      output_axis_tready : in std_logic;
      output_axis_tlast  : out std_logic;
      output_axis_tuser  : out std_logic
    );
  end component;

  component axis_arb_mux_2
    generic (
      DATA_WIDTH : natural := 8;
      ARB_TYPE : string := "PRIORITY"; --"PRIORITY" or "ROUND_ROBIN"
      LSB_PRIORITY : string := "HIGH" --"LOW" or "HIGH"
    );
    port (
      clk         : in std_logic;
      rst         : in std_logic;

      input_0_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_0_axis_tvalid  : in std_logic;
      input_0_axis_tready  : out std_logic;
      input_0_axis_tlast   : in std_logic;
      input_0_axis_tuser   : in std_logic;

      input_1_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_1_axis_tvalid  : in std_logic;
      input_1_axis_tready  : out std_logic;
      input_1_axis_tlast   : in std_logic;
      input_1_axis_tuser   : in std_logic;

      output_axis_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      output_axis_tvalid  : out std_logic;
      output_axis_tready  : in std_logic;
      output_axis_tlast   : out std_logic;
      output_axis_tuser   : out std_logic
    );
  end component;

  component axis_arb_mux_4
    generic (
      DATA_WIDTH : natural := 8;
      ARB_TYPE : string := "PRIORITY"; --"PRIORITY" or "ROUND_ROBIN"
      LSB_PRIORITY : string := "HIGH" --"LOW" or "HIGH"
    );
    port (
      clk         : in std_logic;
      rst         : in std_logic;

      input_0_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_0_axis_tvalid  : in std_logic;
      input_0_axis_tready  : out std_logic;
      input_0_axis_tlast   : in std_logic;
      input_0_axis_tuser   : in std_logic;

      input_1_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_1_axis_tvalid  : in std_logic;
      input_1_axis_tready  : out std_logic;
      input_1_axis_tlast   : in std_logic;
      input_1_axis_tuser   : in std_logic;

      input_2_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_2_axis_tvalid  : in std_logic;
      input_2_axis_tready  : out std_logic;
      input_2_axis_tlast   : in std_logic;
      input_2_axis_tuser   : in std_logic;

      input_3_axis_tdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_3_axis_tvalid  : in std_logic;
      input_3_axis_tready  : out std_logic;
      input_3_axis_tlast   : in std_logic;
      input_3_axis_tuser   : in std_logic;

      output_axis_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      output_axis_tvalid  : out std_logic;
      output_axis_tready  : in std_logic;
      output_axis_tlast   : out std_logic;
      output_axis_tuser   : out std_logic
    );
  end component;


end BBN_QDSP_pkg;
