-- Integer and fractional timestamps for vita packets
--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VitaTimeStamp is
  generic (CLK_FREQ : natural); --clock frequency in MHz
  port (
  clk : in std_logic;
  rst : in std_logic;

  ts_seconds      : out std_logic_vector(31 downto 0);
  ts_frac_seconds : out std_logic_vector(31 downto 0)

  );
end entity;

architecture arch of VitaTimeStamp is

signal seconds_cnt : unsigned(31 downto 0) := (others => '0');
signal ts_seconds_int : unsigned(31 downto 0) := (others => '0');
signal ts_frac_seconds_int : unsigned(31 downto 0) := (others => '0');

--Scale from MHZ to Hz or back again in simulation
constant CLKS_PER_SEC : natural := CLK_FREQ * 1000000
--pragma synthesis_off
                                      / 1000000
--pragma synthesis_on
;

begin

mainCounter : process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      seconds_cnt <= to_unsigned(CLKS_PER_SEC-2, 32);
      ts_seconds_int <= (others => '0');
      ts_frac_seconds_int <= (others => '0');
    else
      --Count down seconds counter
      seconds_cnt <= seconds_cnt - 1;

      --Increment fractional seconds count
      ts_frac_seconds_int <= ts_frac_seconds_int + 1;

      --catch roll-over on second counter and increment ts_seconds and reset ts_frac_seconds
      if seconds_cnt(seconds_cnt'high) = '1' then
        seconds_cnt <= to_unsigned(CLKS_PER_SEC-2, 32);
        ts_seconds_int <= ts_seconds_int + 1;
        ts_frac_seconds_int <= (others => '0');
      end if;

    end if;
  end if;
end process;

outputReg : process(clk)
begin
  if rising_edge(clk) then
    ts_seconds <= std_logic_vector(ts_seconds_int);
    ts_frac_seconds <= std_logic_vector(ts_frac_seconds_int);
  end if;
end process;

end architecture;
