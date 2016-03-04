library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_vita_velo_pad_tb is
end;

architecture bench of ii_vita_velo_pad_tb is

	signal srst           : std_logic := '0';
	signal sys_clk        : std_logic := '0';
	signal ch_pkt_size    : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned(8192, 24));
	signal force_pkt_size : std_logic := '0';
	signal bypass         : std_logic := '0';
	signal src_wrd_cnt    : std_logic_vector(21 downto 0) := (others => '0');
	signal src_aempty     : std_logic := '1';
	signal src_empty      : std_logic := '1';
	signal src_rden       : std_logic := '0';
	signal src_vld        : std_logic := '0';
	signal src_data       : std_logic_vector(127 downto 0) := (others => '0');
	signal dst_wrd_cnt    : std_logic_vector(21 downto 0) := (others => '0');
	signal dst_aempty     : std_logic := '0';
	signal dst_empty      : std_logic := '0';
	signal dst_rden       : std_logic := '0';
	signal dst_vld        : std_logic := '0';
	signal dst_dout       : std_logic_vector(127 downto 0) := (others => '0');

	constant SYS_CLK_PERIOD : time := 5 ns;
	signal stop_the_clock : boolean;

begin

	uut: entity work.ii_vita_velo_pad
		port map (
			srst           => srst,
			sys_clk        => sys_clk,
			ch_pkt_size    => ch_pkt_size,
			force_pkt_size => force_pkt_size,
			bypass         => bypass,
			src_wrd_cnt    => src_wrd_cnt,
			src_aempty     => src_aempty,
			src_empty      => src_empty,
			src_rden       => src_rden,
			src_vld        => src_vld,
			src_data       => src_data,
			dst_wrd_cnt    => dst_wrd_cnt,
			dst_aempty     => dst_aempty,
			dst_empty      => dst_empty,
			dst_rden       => dst_rden,
			dst_vld        => dst_vld,
			dst_dout       => dst_dout
		);

	--clocking
	sys_clk <= not sys_clk after SYS_CLK_PERIOD/2 when not stop_the_clock;

	data_writer : process
		type data_array_t is array(0 to 2) of std_logic_vector(127 downto 0);
		constant data_array : data_array_t := (
		  x"00030000_00000000_00010101_1cf0000c",
			x"abcdef00_00000000_00000000_00000001",
			x"00f00800_00000000_00000000_00abcdef"
		);
		variable ct : natural := 0;
	begin
		wait until rising_edge(sys_clk) and src_rden = '1';
		wait until rising_edge(sys_clk);
		src_vld <= '1';
		src_data <= data_array(ct);
		if ct = 2 then
			ct := 0;
		else
			ct := ct + 1;
		end if;
		wait until rising_edge(sys_clk);
		src_vld <= '0';
	end process;

	stimulus: process
	begin
		wait until rising_edge(sys_clk);
		srst <= '1';
		wait for 100ns;
		wait until rising_edge(sys_clk);
		srst <= '0';

		wait for 100 ns;

		--clock in first dqw
		wait until rising_edge(sys_clk);
		src_empty <= '0';
		src_wrd_cnt <= std_logic_vector(to_unsigned(1, src_wrd_cnt'length));

		wait until rising_edge(sys_clk) and src_rden = '1';
		wait until rising_edge(sys_clk);
		src_empty <= '1';
		src_wrd_cnt <= std_logic_vector(to_unsigned(0, src_wrd_cnt'length));

		wait until rising_edge(sys_clk);
		wait until rising_edge(sys_clk);
		wait until rising_edge(sys_clk);
		wait until rising_edge(sys_clk);

		src_empty <= '0';
		src_wrd_cnt <= std_logic_vector(to_unsigned(1, src_wrd_cnt'length));

		wait until rising_edge(sys_clk) and src_rden = '1';
		wait until rising_edge(sys_clk);
		src_empty <= '1';
		src_wrd_cnt <= std_logic_vector(to_unsigned(0, src_wrd_cnt'length));

		wait for 500 ns;

		src_empty <= '0';
		src_wrd_cnt <= std_logic_vector(to_unsigned(1, src_wrd_cnt'length));

		wait until rising_edge(sys_clk) and src_rden = '1';
		wait until rising_edge(sys_clk);
		src_empty <= '1';
		src_wrd_cnt <= std_logic_vector(to_unsigned(0, src_wrd_cnt'length));

		wait for 100 ns;
		src_empty <= '0';
		src_wrd_cnt <= std_logic_vector(to_unsigned(1, src_wrd_cnt'length));

		for ct in 2 to 5 loop
			wait for 50ns;
			wait until rising_edge(sys_clk);
			src_wrd_cnt <= std_logic_vector(to_unsigned(ct, src_wrd_cnt'length));
		end loop;

		wait until rising_edge(sys_clk);

		stop_the_clock <= true;
		wait;
	end process;


end;
