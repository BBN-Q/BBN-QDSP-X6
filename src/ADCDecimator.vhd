-- Decimate the 4-sample-wide ADC data stream to a single-sample-wide stream
-- For now is a simple averager
--
-- Original authors Colm Ryan and Blake Johnson
-- Copyright 2015, Raytheon BBN Technologies

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity ADCDecimator is
	generic (ADC_DATA_WIDTH : natural := 12);
	port (
	clk : in std_logic;
	rst : in std_logic;

	in_data : in std_logic_vector(4*ADC_DATA_WIDTH-1 downto 0);
	in_vld : in std_logic;
	in_last : in std_logic;

	out_data : out std_logic_vector(ADC_DATA_WIDTH+1 downto 0);
	out_vld : out std_logic;
	out_last : out std_logic
	);
end entity;

architecture arch of ADCDecimator is

signal samp0, samp1, samp2, samp3 : signed(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
signal tmp_sum1, tmp_sum2 : signed(ADC_DATA_WIDTH downto 0) := (others => '0');

begin

--Break-out the 4 samples
samp0 <= signed(in_data(ADC_DATA_WIDTH-1 downto 0));
samp1 <= signed(in_data(2*ADC_DATA_WIDTH-1 downto ADC_DATA_WIDTH));
samp2 <= signed(in_data(3*ADC_DATA_WIDTH-1 downto 2*ADC_DATA_WIDTH));
samp3 <= signed(in_data(4*ADC_DATA_WIDTH-1 downto 3*ADC_DATA_WIDTH));

main : process(clk)
begin
	if rising_edge(clk) then
		tmp_sum1 <= resize(samp0, ADC_DATA_WIDTH+1) + resize(samp1, ADC_DATA_WIDTH+1);
		tmp_sum2 <= resize(samp2, ADC_DATA_WIDTH+1) + resize(samp3, ADC_DATA_WIDTH+1);
		out_data <= std_logic_vector(resize(tmp_sum1, ADC_DATA_WIDTH+2) + resize(tmp_sum2, ADC_DATA_WIDTH+2));
	end if;
end process;

--Pipeline delays
vldDelay : entity work.DelayLine
generic map(DELAY_TAPS => 2)
port map(clk => clk, rst => rst, data_in(0) => in_vld, data_out(0) => out_vld);

lastDelay : entity work.DelayLine
generic map(DELAY_TAPS => 2)
port map(clk => clk, rst => rst, data_in(0) => in_last, data_out(0) => out_last);


end architecture;
