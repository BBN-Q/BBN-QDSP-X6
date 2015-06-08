library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity ADCDecimator_tb is
end;

architecture bench of ADCDecimator_tb is

  constant ADC_DATA_WIDTH : natural := 12;
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal in_data : std_logic_vector(4*ADC_DATA_WIDTH-1 downto 0) := (others => '0');
  signal in_vld, in_last : std_logic := '0';
  signal out_data : std_logic_vector(ADC_DATA_WIDTH+1 downto 0);
  signal out_vld, out_last : std_logic := '0';

  signal data_check : signed(ADC_DATA_WIDTH+1 downto 0) := (others => '0');

  constant CLK_PERIOD: time := 10 ns;
  signal finished: boolean := false;

begin

  uut: entity work.ADCDecimator
    generic map ( ADC_DATA_WIDTH => ADC_DATA_WIDTH)
    port map (
      clk       => clk,
      rst       => rst,
      in_data   => in_data,
      in_vld    => in_vld,
      in_last   => in_last,
      out_data  => out_data,
      out_vld   => out_vld,
      out_last  => out_last);

  stimulus: process
  begin

    rst <= '1';
    wait for 100ns;
    rst <= '0';
    wait for 10ns;
    wait until rising_edge(clk);

    --Clock in a ramp
    for ct in -512 to 511 loop
      in_data <= std_logic_vector(to_signed(ct*4, ADC_DATA_WIDTH)) &
                  std_logic_vector(to_signed(ct*4+1, ADC_DATA_WIDTH)) &
                  std_logic_vector(to_signed(ct*4+2, ADC_DATA_WIDTH)) &
                  std_logic_vector(to_signed(ct*4+3, ADC_DATA_WIDTH));
      in_vld <= '1';
      if ct = 511 then
        in_last <= '1';
      else
        in_last <= '0';
      end if;
      wait until rising_edge(clk);
    end loop;

    in_data <= (others => '0');
    in_vld <= '0';
    in_last <= '0';

    wait for 100ns;

    finished <= true;
    wait;
  end process;

  --Checking
  checking : process
  begin
    wait until out_vld = '1';
    for ct in -512 to 511 loop
      data_check <= to_signed(16*ct + 6, ADC_DATA_WIDTH+2);
      assert data_check = signed(out_data) report "Output incorrect!";
      wait until rising_edge(clk);
    end loop;

  end process;

  --Clocking
  clk <= not clk after CLK_PERIOD/2 when not finished;

end;
