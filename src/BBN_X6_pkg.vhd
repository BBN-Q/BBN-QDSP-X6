-- Constants and declarations for BBN X6 firmware
--
-- Copyright Raytheon BBN Technologies 2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BBN_X6_pkg is

	--Version numbers
	constant BBN_X6_FIRMWARE_VERSION : std_logic_vector(15 downto 0) := x"0008";
	constant QDSP_VERSION : std_logic_vector(15 downto 0) := x"0100";
	constant PG_VERSION : std_logic_vector(15 downto 0) := x"0001";

end BBN_X6_pkg;
