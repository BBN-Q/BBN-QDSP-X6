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

  data_in : in std_logic_vector(4*ADC_DATA_WIDTH-1 downto 0);
  data_in_vld : in std_logic;

  data_out : out std_logic_vector(ADC_DATA_WIDTH+1 downto 0);
  data_out_vld : out std_logic
  );
end entity;

architecture arch of ADCDecimator is

signal samp0, samp1, samp2, samp3 : signed(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
signal tmp_sum1, tmp_sum2 : signed(ADC_DATA_WIDTH downto 0) := (others => '0');

begin

--Break-out the 4 samples
samp0 <= signed(data_in(ADC_DATA_WIDTH-1 downto 0));
samp1 <= signed(data_in(2*ADC_DATA_WIDTH-1 downto ADC_DATA_WIDTH));
samp2 <= signed(data_in(3*ADC_DATA_WIDTH-1 downto 2*ADC_DATA_WIDTH));
samp3 <= signed(data_in(4*ADC_DATA_WIDTH-1 downto 3*ADC_DATA_WIDTH));

main : process(clk)
begin
  if rising_edge(clk) then
    tmp_sum1 <= resize(samp0, ADC_DATA_WIDTH+1) + resize(samp1, ADC_DATA_WIDTH+1);
    tmp_sum2 <= resize(samp2, ADC_DATA_WIDTH+1) + resize(samp3, ADC_DATA_WIDTH+1);
    data_out <= std_logic_vector(resize(tmp_sum1, ADC_DATA_WIDTH+2) + resize(tmp_sum2, ADC_DATA_WIDTH+2));
  end if;
end process;

vldDelay : process(clk)
variable delayLine : std_logic_vector(1 downto 0);
begin
  if rising_edge(clk) then
    if rst = '1' then
      delayLine := (others => '0');
    else
      delayLine := delayLine(delayLine'high-1 downto 0) & data_in_vld;
    end if;
    data_out_vld <= delayLine(delayLine'high);
  end if;
end process;

end architecture;
