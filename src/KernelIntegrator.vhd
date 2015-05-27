-- Integrate a complex AXI stream of data with a kernel stored in BRAM
--
-- Original authors Colm Ryan and Blake Johnson
-- Copyright 2015, Raytheon BBN Technologies

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

--complex multiplication gains an extra bit
signal prod_re, prod_im : signed(32 downto 0);

--The maximum bit width growth we need in the accumulator is the KERNEL_ADDR_WIDTH
--The DSP48 supports 48 bit accumulator so as long as KERNEL_ADDR_WIDTH is <= 15 we are fine to use full product width
signal accum_re, accum_im : signed(33+KERNEL_ADDR_WIDTH-1 downto 0);
--Xilinx does not infer DSP for accumulator by default so force DSP48 for performance
attribute use_dsp48 : string;
attribute use_dsp48 of accum_re : signal is "yes";
attribute use_dsp48 of accum_im : signal is "yes";

signal kernel_data : std_logic_vector(31 downto 0);
signal kernel_re, kernel_im : std_logic_vector(15 downto 0);

signal data_vld_d : std_logic := '0';
signal kernel_last, kernel_last_d : std_logic := '0';
signal mult_vld, mult_last   : std_logic := '0';
signal accum_last, accum_last_d  : std_logic := '0';

--instantiate kernel BRAM storage
--easy enough to instantiate our own
constant KERNEL_RAM_SIZE : natural := 2**KERNEL_ADDR_WIDTH;
type RAM_ARRAY_t is array(KERNEL_RAM_SIZE-1 downto 0) of std_logic_vector(31 downto 0);
signal kernel_RAM : RAM_ARRAY_t := (others => (others => '0'));
signal kernel_addr_d : unsigned(KERNEL_ADDR_WIDTH-1 downto 0);

begin

  --Make sure we fit in a DSP48
  assert KERNEL_ADDR_WIDTH <= 15 report "KERNEL_ADDR_WIDTH too wide. Must be <= 16 to prevent accumulator overflow.";

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
  type data_delayline_t is array(0 downto 0) of std_logic_vector(15 downto 0);
  variable data_re_delayline : data_delayline_t;
  variable data_im_delayline : data_delayline_t;
  variable last_delayline : std_logic_vector(0 downto 0);
  variable vld_delayline : std_logic_vector(0 downto 0);
  begin
  	if rising_edge(clk) then
  		if rst = '1' then
  			data_re_delayline := (others => (others => '0'));
  			data_im_delayline := (others => (others => '0'));
        last_delayline := (others => '0');
  		else
  			data_re_d <= data_re_delayline(data_re_delayline'high);
  			data_re_delayline := data_re_delayline(data_re_delayline'high-1 downto 0) & data_re;
  			data_im_d <= data_im_delayline(data_im_delayline'high);
  			data_im_delayline := data_im_delayline(data_im_delayline'high-1 downto 0) & data_im;
        kernel_last_d <= last_delayline(last_delayline'high);
        last_delayline := last_delayline(last_delayline'high-1 downto 0) & kernel_last;
        data_vld_d <= vld_delayline(vld_delayline'high);
        vld_delayline := vld_delayline(vld_delayline'high-1 downto 0) & data_vld;
  		end if ;
  	end if ;
  end process ; -- delayLines

  --Complex multiplier and pipelining
  kernel_re <= kernel_data(31 downto 16);
  kernel_im <= kernel_data(15 downto 0);

  multiplier : entity work.ComplexMultiplier
  generic map(
  A_WIDTH => 16,
  B_WIDTH => 16,
  PROD_WIDTH => 33
  )
  port map(
    clk => clk,
    rst => rst,

    a_data_re => data_re_d,
    a_data_im => data_im_d,
    a_vld => data_vld_d,
    a_last => kernel_last_d,

    b_data_re => kernel_re,
    b_data_im => kernel_im,
    b_vld => data_vld_d,
    b_last => kernel_last_d,

    signed(prod_data_re) => prod_re,
    signed(prod_data_im) => prod_im,
    prod_vld => mult_vld,
    prod_last => mult_last
  );

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
        accum_last_d <= '0';
  		else
  			accum_re <= accum_re + prod_re;
  			accum_im <= accum_im + prod_im;

        accum_last <= mult_last;
        accum_last_d <= accum_last;

        -- latch out result on rising edge of accum_last
        -- slice out the top 32bits and truncate the rest
  			if accum_last = '1' and accum_last_d = '0' then
  				result_re <= std_logic_vector(accum_re(accum_re'high downto accum_re'high-31));
  				result_im <= std_logic_vector(accum_im(accum_re'high downto accum_re'high-31));
  			end if;

  		end if ;
  	end if ;
  end process ; -- accum

  result_vld <= accum_last_d;

end architecture ; -- arch
