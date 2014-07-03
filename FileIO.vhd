library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;


package FileIO is
	
	--Irritatingly we can't have an unconstrained array of an unconstrained array until VHDL-2008 which of course Xilinx doesn't support
	--So for now fix waveform length here
	constant WF_LENGTH : natural := 1024;
	type WF_t is array(0 to WF_LENGTH-1) of std_logic_vector(11 downto 0) ;
	type WFArray_t is array(natural range <>) of WF_t;

	impure function read_wf_file(fileName : string) return WFArray_t;
	impure function num_lines(fileName : string) return natural;
	-- impure function wf_length(fileName : string) return natural;

end FileIO;

package body FileIO is

impure function read_wf_file(fileName : string) return WFArray_t is
	--Read a set of test waveform from a file
	--Expects a list of signed integers on each line (space separated)
	variable wfs : WFArray_t(0 to num_lines(fileName)-1);
	file FID : text;
    variable ln : line;
    variable eol : boolean;
    variable dummy : integer;
    variable linect, wordct : natural := 0;

	begin 
		file_open(FID, fileName, read_mode);
		lineReading: while not endfile(FID) loop
			readline(FID, ln);
			read(ln, dummy, eol);
			wordct := 0;
			wfs(linect)(wordct) := std_logic_vector(to_unsigned(dummy, 12));
			wordCounting : while not eol loop
				read(ln, dummy, eol);
				wordct := wordct + 1;
				report "Read wordct = " & integer'image(wordct);
				wfs(linect)(wordct) := std_logic_vector(to_unsigned(dummy, 12));
			end loop wordCounting;
			linect := linect + 1;
		end loop lineReading;
		file_close(FID);
	return wfs;
end read_wf_file;


impure function num_lines(fileName : string) return natural is
	--Helper function to count the number of lines in a file
	variable linect : natural := 0;
	file FID : text;
    variable ln : line;

	begin
		file_open(FID, fileName, read_mode);
		lineReading : while not endfile(FID) loop
		    readline(FID, ln);
			linect := linect + 1;
		end loop lineReading;
		file_close(FID);
	return linect;
end num_lines;

-- impure function wf_length(fileName : string) return natural is
-- 	--Helper function to count the number of entries on the first line in a file
-- 	variable entryct : natural := 0;
-- 	file FID : text;
-- 	variable dummy : integer;
-- 	variable eol : boolean := false;
--     variable ln : line;

-- 	begin
-- 		file_open(FID, fileName, read_mode);
-- 		readline(FID, ln);
-- 		read(ln, dummy, eol);
-- 		wordCounting : while not eol loop
-- 			entryct := entryct + 1;
-- 			read(ln, dummy, eol);
-- 		end loop wordCounting;
-- 		report "Found number of words on first line as " & integer'image(entryct);
-- 		file_close(FID);
-- 	return entryct;
-- end wf_length;

end package body;