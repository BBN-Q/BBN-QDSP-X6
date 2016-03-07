-- Constants and declarations for BBN X6 firmware
--
-- Copyright Raytheon BBN Technologies 2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BBN_X6_pkg is

	--Version numbers
	-- last two nibbles are x.x firmware version and first six are git hash of commit if unstable
	-- 0x00000d indicates dirty
	-- use `git describe` to extract
	constant BBN_X6_VERSION : std_logic_vector(31 downto 0) := x"0000_0d0a";

end BBN_X6_pkg;
