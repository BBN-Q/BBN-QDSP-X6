-- Scales and then adds offset to 16 bit DAC data
-- Assumes 16 bit DAC data representing -0.5 to 0.5
-- Assumes gain has extra bit to represent gain between -2 and +2
-- Assumes offset is 16 bits

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dac_offgain is
  port (
	rst : in std_logic;
	clk : in std_logic;

	data_in : in signed(15 downto 0); --Q1.16 -0.5 to 0.5
	gain : in signed(17 downto 0); --Q2.16 -2 to 2
	offset : in signed(15 downto 0); --Q1.16 -0.5 to 0.5

	data_out : out signed(15 downto 0) 
  ) ;
end entity ; -- dac_offgain

architecture arch of dac_offgain is

signal tmp_out : signed(data_in'length + gain'length - 1 downto 0);

begin

-- See http://www.xilinx.com/txpatches/pub/documentation/misc/dsp48_inference.pdf
-- for why a DSP48 should be inferred from this 
-- For now just register output


tmp_out <= data_in*gain + resize(offset, data_in'length + gain'length);

registers : process( clk )
begin
	if rising_edge(clk) then
		if rst = '1' then
			data_out <= (others => '0');
		else
			--Since full scale multiplication would overflow we can throw away the msb
			--we'll then truncate the least significant bits so that we have 16 bits going out again
			data_out <= resize(tmp_out, tmp_out'length-1)(tmp_out'length - 2 downto tmp_out'length - 17);
		end if ;
	end if ;
end process ; -- registers

end architecture ; -- arch