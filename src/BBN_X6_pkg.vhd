-- Constants and declarations for BBN X6 firmware
--
-- Copyright Raytheon BBN Technologies 2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BBN_X6_pkg is

	--Version numbers
	-- last two bytes are x.x firmware version
	-- next three nibbles indicate how many commit since that tag
	-- top nibble `d` indicates dirty working tree
	-- use `git describe` and/or `git diff --exit-code` and/or `git rev-parse --short=8 HEAD` to extract
	-- TODO: automate
	constant BBN_X6_VERSION : std_logic_vector(31 downto 0) := x"d006_0009";
	constant BBN_X6_GIT_SHA1 : std_logic_vector(31 downto 0) := x"55b14231";

end BBN_X6_pkg;
