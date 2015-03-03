library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ii_dsp_pkg.KERNEL_ADDR_WIDTH;

entity DecisionEngine is
  port (
	rst : in std_logic;
	clk : in std_logic;
	ce  : in std_logic;

	data_re : in std_logic_vector(15 downto 0);
	data_im : in std_logic_vector(15 downto 0);

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

begin

kernel_addr <= std_logic_vector(addrct);

addrCounter : process( clk )
begin
	if rising_edge(clk) and ce = '1' then
		if rst = '1' then
			addrct <= (others => '0');
			state_vld <= '0';
		else
			addrct <= addrct + 1;
			if addrct = unsigned(kernel_len) - 1 then
				state_vld <= '1';
			else
				state_vld <= '0';
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
		elsif ce = '1' then
			data_re_delayline := data_re_delayline(data_re_delayline'high-1 downto 0) & data_re;
			data_re_d <= data_re_delayline(data_re_delayline'high);
			data_im_delayline := data_im_delayline(data_im_delayline'high-1 downto 0) & data_im;
			data_im_d <= data_im_delayline(data_im_delayline'high);
		end if ;
	end if ;
end process ; -- delayLines

--Complex multiplier and pipelining
mult : process( clk )
begin
	if rising_edge(clk) then
		s_data_re <= signed(data_re_d);
		s_data_im <= signed(data_im_d);
		s_kernel_re <= signed(kernel_re);
		s_kernel_im <= signed(kernel_im);

		tmp1 <= s_data_re * s_kernel_re;
		tmp2 <= s_data_im * s_kernel_im;
		tmp3 <= s_data_re * s_kernel_im;
		tmp4 <= s_data_im * s_kernel_re;

		if rst = '1' then
			prod_re <= (others => '0');
			prod_im <= (others => '0');
		else
			prod_re <= tmp1 - tmp2;
			prod_im <= tmp3 + tmp4;
		end if;
	end if ;
end process ; -- mult

--Acumulator
accum : process( clk )
begin
	if rising_edge(clk) then
		if rst = '1' then
			accum_re <= (others => '0');
			accum_im <= (others => '0');
		else
			if ce = '1' then
				accum_re <= accum_re + prod_re(31 downto 16);
				accum_im <= accum_im + prod_im(31 downto 16);
			end if;

			result_re <= std_logic_vector(accum_re);
			result_im <= std_logic_vector(accum_im);
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
	end if ;
end process ; -- thresholding

end architecture ; -- arch