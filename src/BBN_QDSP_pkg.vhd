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
  constant NUM_DEMOD_CH      : natural := 4;   -- number of demodulated channels 
  constant num_vita_streams  : natural := num_demod_ch + 2; -- results + demod + the raw data stream
  constant adc_data_width  : natural := 12;  -- number of bits in ADC data

  constant KERNEL_ADDR_WIDTH : natural := 12; --width of the kernel memory

--------------------------------------------------------------------------------
-- Data type declarations
--------------------------------------------------------------------------------
  type width_2_array is array (natural range <>) of std_logic_vector(1 downto 0);
  type width_16_array is array (natural range <>) of std_logic_vector(15 downto 0);
  type width_18_array is array (natural range <>) of std_logic_vector(17 downto 0);
  type width_32_array is array (natural range <>) of std_logic_vector(31 downto 0);
  type width_64_array is array (natural range <>) of std_logic_vector(63 downto 0);
  type width_128_array is array (natural range <>) of std_logic_vector(127 downto 0);

  type kernel_addr_array is array (natural range <>) of std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0) ;

end BBN_QDSP_pkg;
