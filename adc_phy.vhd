library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_phy is
  port (
  	reset : in std_logic;

	--clock and data lines from ADC chip
	clk_in_p : in std_logic;
	clk_in_n : in std_logic;
	data_in_p : in std_logic_vector(11 downto 0) ;
	data_in_n : in std_logic_vector(11 downto 0) ;

	--Data out to other modules
	data_clk : out std_logic;
	data_out : out std_logic_vector(47 downto 0) 

  ) ;
end entity ; -- adc_phy

architecture arch of adc_phy is


begin

--Deserialize the ADC data
adc_gear_in : entity work.ADC_DESIN
  port map
   (
  -- From the system into the device
  DATA_IN_FROM_PINS_P =>   data_in_p, --Input pins
  DATA_IN_FROM_PINS_N =>   data_in_n, --Input pins
  DATA_IN_TO_DEVICE =>   data_out, --Output pins

  BITSLIP =>   '0',    --Input pin
 
-- Clock and reset signals
  CLK_IN_P =>  clk_in_p,     -- Differential clock from IOB
  CLK_IN_N =>  clk_in_n,     -- Differential clock from IOB
  CLK_DIV_OUT => data_clk,     -- Slow clock output
  CLK_RESET => reset,         --clocking logic reset
  IO_RESET =>  reset);          --system reset

end architecture ; -- arch