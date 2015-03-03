library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ii_dsp_pkg.KERNEL_ADDR_WIDTH;

entity DecisionEngine is
  port (
	rst : in std_logic;
	clk : in std_logic;

	data_re : in std_logic_vector(15 downto 0);
	data_im : in std_logic_vector(15 downto 0);
	data_vld : in std_logic;

	kernel_re : in std_logic_vector(15 downto 0);
	kernel_im : in std_logic_vector(15 downto 0);

	kernel_len : in std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0) ;
	kernel_addr : out std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0) ;

	result_re : out std_logic_vector(31 downto 0) ;
	result_im : out std_logic_vector(31 downto 0) ;

	threshold : in std_logic_vector(31 downto 0) ;
	state : out std_logic;
	state_vld : out std_logic

  ) ;
end entity ; -- DecisionEngine

architecture arch of DecisionEngine is

signal addrct : unsigned(KERNEL_ADDR_WIDTH-1 downto 0);

signal data_re_d : std_logic_vector(15 downto 0);
signal data_im_d : std_logic_vector(15 downto 0);

signal prod_re, prod_im : signed(31 downto 0);
signal tmp1, tmp2, tmp3, tmp4 : signed(31 downto 0);
signal s_data_re, s_data_im, s_kernel_re, s_kernel_im : signed(15 downto 0);

signal accum_re, accum_im : signed(31 downto 0);

signal kernel_last : std_logic;
signal mult_last   : std_logic;
signal accum_last  : std_logic;

begin

kernel_addr <= std_logic_vector(addrct);

addrCounter : process( clk )
begin
	if rising_edge(clk) then
		if rst = '1' then
			addrct <= (others => '0');
			kernel_last <= '0';
		else
			if data_vld = '1' then
				addrct <= addrct + 1;
			end if;
			if addrct = unsigned(kernel_len) - 1 then
				kernel_last <= '1';
			end if ;
		end if;
	end if ;
end process ; -- addrCounter

--Delay lines to align input data and kernel
--It takes two clock cycles for data to come out of the kernel BRAM
delaylines : process( clk )
type data_delayline_t is array(1 downto 0) of std_logic_vector(15 downto 0);
variable data_re_delayline : data_delayline_t;
variable data_im_delayline : data_delayline_t;
begin
	if rising_edge(clk) then
		if rst = '1' then
			data_re_delayline := (others => (others => '0'));
			data_im_delayline := (others => (others => '0'));
		else
			data_re_delayline := data_re_delayline(data_re_delayline'high-1 downto 0) & data_re;
			data_re_d <= data_re_delayline(data_re_delayline'high);
			data_im_delayline := data_im_delayline(data_im_delayline'high-1 downto 0) & data_im;
			data_im_d <= data_im_delayline(data_im_delayline'high);
		end if ;
	end if ;
end process ; -- delayLines

--Complex multiplier and pipelining
mult : process( clk )
variable last_delay : std_logic_vector(2 downto 0);
begin
	if rising_edge(clk) then
		if rst = '1' then
			last_delay := (others => '0');
			mult_last <= '0';
		else
			mult_last <= last_delay(last_delay'high);
			last_delay := last_delay(last_delay'high-1 downto 0) & kernel_last;
		end if;
		s_data_re <= signed(data_re_d);
		s_data_im <= signed(data_im_d);
		s_kernel_re <= signed(kernel_re);
		s_kernel_im <= signed(kernel_im);

		tmp1 <= s_data_re * s_kernel_re;
		tmp2 <= s_data_im * s_kernel_im;
		tmp3 <= s_data_re * s_kernel_im;
		tmp4 <= s_data_im * s_kernel_re;

		prod_re <= tmp1 - tmp2;
		prod_im <= tmp3 + tmp4;
	end if ;
end process ; -- mult

--Acumulator
accum : process( clk )
begin
	if rising_edge(clk) then
		if rst = '1' then
			accum_re <= (others => '0');
			accum_im <= (others => '0');
			result_re <= (others => '0');
			result_im <= (others => '0');
			accum_last <= '0';
		else
			accum_re <= accum_re + prod_re(31 downto 16);
			accum_im <= accum_im + prod_im(31 downto 16);

			if mult_last = '1' and accum_last = '0' then -- rising edge of mult_last
				result_re <= std_logic_vector(accum_re);
				result_im <= std_logic_vector(accum_im);
			end if;
			accum_last <= mult_last;
		end if ;
	end if ;
end process ; -- accum

--Thresholding
Thresholding : process( clk )
begin
	if rising_edge(clk) then
		if accum_re > signed(threshold) then
			state <= '1';
		else
			state <= '0';
		end if;

		state_vld <= accum_last;
	end if ;
end process ; -- thresholding

end architecture ; -- arch