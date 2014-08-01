library ieee;

use ieee.std_logic_1164.all;

entity reg_synchronizer is
	generic ( REG_WIDTH : natural := 32);
	port (
		reset  : in std_logic; -- active high
		clk    : in std_logic;
		i_data : in std_logic_vector( REG_WIDTH - 1 downto 0);
		o_data : out std_logic_vector( REG_WIDTH - 1 downto 0)
	);
end reg_synchronizer;

architecture behavior of reg_synchronizer is


component synchronizer is
  generic(
    G_INIT_VALUE : std_logic := '0'; -- initial value of all flip-flops in the module
    G_NUM_GUARD_FFS : positive := 1); -- number of guard flip-flops after the synchronizing flip-flop
  port(
    i_reset : in std_logic; -- asynchronous, high-active
    i_clk : in std_logic; -- destination clock
    i_data : in std_logic;
    o_data : out std_logic);
end component; 

begin

	GEN_REG: 
	for I in 0 to REG_WIDTH - 1 generate
      synchx : synchronizer
		generic map (
			 G_INIT_VALUE => '0', 
			 G_NUM_GUARD_FFS => 1
		)
		port map (
			i_reset => reset,
			i_clk => clk,
			i_data => i_data(I),
			o_data => o_data(I)
		);
	end generate GEN_REG;

end behavior;