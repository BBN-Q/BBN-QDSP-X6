-- Fully pipelined complex AXI stream multiplier with generic widths
--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ComplexMultiplier is
  generic (
  A_WIDTH : natural := 16;
  B_WIDTH : natural := 16;
  PROD_WIDTH : natural := 16
  );
  port (
  clk : in std_logic;
  rst : in std_logic;

  a_data_re : in std_logic_vector(A_WIDTH-1 downto 0);
  a_data_im : in std_logic_vector(A_WIDTH-1 downto 0);
  a_vld : in std_logic;
  a_last : in std_logic;

  b_data_re : in std_logic_vector(B_WIDTH-1 downto 0);
  b_data_im : in std_logic_vector(B_WIDTH-1 downto 0);
  b_vld : in std_logic;
  b_last : in std_logic;

  prod_data_re : out std_logic_vector(PROD_WIDTH-1 downto 0);
  prod_data_im : out std_logic_vector(PROD_WIDTH-1 downto 0);
  prod_vld : out std_logic;
  prod_last : out std_logic
  );
end entity;

architecture arch of ComplexMultiplier is

signal a_reg_re, a_reg_im : signed(A_WIDTH-1 downto 0);
signal b_reg_re, b_reg_im : signed(A_WIDTH-1 downto 0);

constant SUM_WIDTH : natural := A_WIDTH+B_WIDTH;
signal prod1, prod2, prod3, prod4 : signed(SUM_WIDTH-1 downto 0);
signal sum_re, sum_im : signed(SUM_WIDTH downto 0);

begin

  main : process( clk )
  begin
  	if rising_edge(clk) then
  		if rst = '1' then
        a_reg_re <= (others => '0');
        a_reg_im <= (others => '0');
        b_reg_re <= (others => '0');
        b_reg_im <= (others => '0');

        prod1 <= (others => '0');
        prod2 <= (others => '0');
        prod3 <= (others => '0');
        prod4 <= (others => '0');

        sum_re <= (others => '0');
        sum_im <= (others => '0');
        prod_data_re <= (others => '0');
        prod_data_im <= (others => '0');

  		else
        --Register inputs
        a_reg_re <= signed(a_data_re);
        a_reg_im <= signed(a_data_im);
        b_reg_re <= signed(b_data_re);
        b_reg_im <= signed(b_data_im);

        --Pipeline intermediate products
        prod1 <= a_reg_re * b_reg_re;
        prod2 <= a_reg_re * b_reg_im;
        prod3 <= a_reg_im * b_reg_re;
        prod4 <= a_reg_im * b_reg_im;

        sum_re <= resize(prod1, SUM_WIDTH+1) - resize(prod4, SUM_WIDTH+1);
        sum_im <= resize(prod2, SUM_WIDTH+1) + resize(prod3, SUM_WIDTH+1);

        --Slice output to truncate
        prod_data_re <= std_logic_vector( sum_re(sum_re'high downto sum_re'high-PROD_WIDTH+1) );
        prod_data_im <= std_logic_vector( sum_im(sum_im'high downto sum_im'high-PROD_WIDTH+1) );

  		end if;
  	end if;
  end process; -- main

  pipelineDelay : process(clk)
  variable delayLineVld : std_logic_vector(3 downto 0);
  variable delayLineLast : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        delayLineVld := (others => '0');
        delayLineLast := (others => '0');
      else
        --Both inputs have to be valid
        delayLineVld := delayLineVld(delayLineVld'high-1 downto 0) & (a_vld and b_vld);
        --Either last
        delayLineLast := delayLineLast(delayLineLast'high-1 downto 0) & (a_last or b_last);
      end if;
      prod_vld <= delayLineVld(delayLineVld'high);
      prod_last <= delayLineLast(delayLineLast'high);
    end if;
  end process;

end architecture;
