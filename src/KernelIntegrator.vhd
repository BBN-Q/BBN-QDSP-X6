library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bbn_qdsp_pkg.KERNEL_ADDR_WIDTH;

entity KernelIntegrator is
  port (
	rst : in std_logic;
	clk : in std_logic;

  --Complex input data stream
	data_re : in std_logic_vector(15 downto 0);
	data_im : in std_logic_vector(15 downto 0);
	data_vld : in std_logic;
  data_last : in std_logic;

  --Wishbone kernel memory writes
	kernel_len : in std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0);
  kernel_wr_addr : in std_logic_vector(KERNEL_ADDR_WIDTH-1 downto 0);
  kernel_wr_data : in std_logic_vector(31 downto 0);
  kernel_we : in std_logic;
  kernel_wr_clk : in std_logic;

  --Output integrated results
	result_re : out std_logic_vector(31 downto 0);
	result_im : out std_logic_vector(31 downto 0);
  result_vld : out std_logic
  ) ;

end entity ; -- KernelIntegrator

architecture arch of KernelIntegrator is

signal kernel_addr : unsigned(KERNEL_ADDR_WIDTH-1 downto 0);

signal data_re_d, data_im_d : std_logic_vector(15 downto 0) := (others => '0');

signal prod_re, prod_im : signed(31 downto 0);
signal tmp1, tmp2, tmp3, tmp4 : signed(31 downto 0);
signal s_data_re, s_data_im, s_kernel_re, s_kernel_im : signed(15 downto 0) := (others => '0');

signal accum_re, accum_im : signed(31 downto 0);

signal kernel_data : std_logic_vector(31 downto 0);
signal kernel_re, kernel_im : std_logic_vector(15 downto 0);

signal kernel_last : std_logic;
signal mult_last   : std_logic;
signal accum_last  : std_logic;

--instantiate kernel BRAM storage
--easy enough to instantiate our own
constant KERNEL_RAM_SIZE : natural := 2**KERNEL_ADDR_WIDTH;
type RAM_ARRAY_t is array(KERNEL_RAM_SIZE-1 downto 0) of std_logic_vector(31 downto 0);
signal kernel_RAM : RAM_ARRAY_t := (others => (others => '0'));
signal kernel_addr_d : unsigned(KERNEL_ADDR_WIDTH-1 downto 0);

begin

  --Kernel memory write/read processes
  kernel_mem_wr : process(kernel_wr_clk)
  begin
    if rising_edge(kernel_wr_clk) then
      if kernel_we = '1' then
        kernel_RAM(to_integer(unsigned(kernel_wr_addr))) <= kernel_wr_data;
      end if;
    end if;
  end process;

  kernel_mem_read : process(clk)
  begin
    if rising_edge(clk) then
      kernel_addr_d <= kernel_addr;
      kernel_data <= kernel_RAM(to_integer(kernel_addr_d));
    end if;
  end process;

  --Simple counter to increment through kernel addresses
  addrCounter : process( clk )
  begin
  	if rising_edge(clk) then
  		if rst = '1' then
  			kernel_addr <= (others => '0');
  		elsif data_vld = '1' then
  				kernel_addr <= kernel_addr + 1;
			end if;
  	end if ;
  end process ; -- addrCounter

  lastCalc : process(clk)
  variable addrct : unsigned(KERNEL_ADDR_WIDTH-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      if rst = '1' then
        kernel_last <= '0';
        addrct := unsigned(kernel_len) - 2;
      elsif data_vld = '1' then
        addrct := addrct - 1;
        --Catch underflow
        if addrct(addrct'high) = '1' then
          kernel_last <= '1';
        else
          kernel_last <= '0';
        end if;
      end if;
    end if;
  end process;

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
  kernel_re <= kernel_data(31 downto 16);
  kernel_im <= kernel_data(15 downto 0);

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

  result_vld <= accum_last;

end architecture ; -- arch
