-- AXI stream digital down-conversion and channel selection via 2 stage FIR filter
-- Selected channel is returned decimated by a factor of 8.
-- For AXI packet framing to work initial packet must be multiple of 8.
-- Does not apply back pressure and needs a continuous valid data flow to keep up with DDS
--
-- Fixed point scaling details:
-- Complex Multiplier : Output should be DATA_IN_WIDTH + 16 + 1
--                      Truncated to 24 bits
--                      Truncated by DATA_IN_WIDTH + 16 + 1 - 24 bits = DATA_IN_WIDTH - 7 bits
--                      Shifts decimal point by 2 bits to avoid overflow
--                      Since we know we have an two exp(i\theta) inputs it is safe to undo one shift
--
-- FIR Stage 1 : Shifts by 1 bit to avoid overflow
--               max gain of filter is only slightly greater than one and inputs are much less than max
--               => safe to undo
-- FIR Stage 2 : Shifts by 1 bit to avoid overflow
--               => again safe to undo
-- Final output width : Truncated by 24 - DATA_OUT_WIDTH
-- e.g. Total truncation for 14 bit inputs and 16 bit outputs  is 14 - 7 + 8  = 15 bits or divide by 131072
--
-- Original authors Colm Ryan and Blake Johnson
-- Copyright 2015, Raytheon BBN Technologies

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity Channelizer is
  generic (
    DATA_IN_WIDTH : natural := 14;
    DATA_OUT_WIDTH : natural := 16);
  port (
  clk : in std_logic;
  rst : in std_logic;

  dds_phase_inc     : in std_logic_vector(23 downto 0);
  dds_phase_inc_vld : in std_logic;
  dds_vld           : out std_logic;

  data_in_re : in std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  data_in_im : in std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  data_in_vld : in std_logic;
  data_in_last : in std_logic;

  data_out_re : out std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
  data_out_im : out std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
  data_out_vld : out std_logic;
  data_out_last : out std_logic

  );
end entity;

architecture arch of Channelizer is

signal dds_vld_int : std_logic := '0';
signal dds_cos, dds_sin : std_logic_vector(15 downto 0) := (others => '0');

signal mult_re, mult_im : std_logic_vector(23 downto 0) := (others => '0');
signal mult_vld, mult_last : std_logic := '0';

signal stage1_re, stage1_im : std_logic_vector(23 downto 0) := (others => '0');
signal stage1_re_vld, stage1_re_last, stage1_im_vld, stage1_im_last : std_logic := '0';

signal stage2_re, stage2_im : std_logic_vector(23 downto 0) := (others => '0');
signal stage2_re_vld, stage2_re_last, stage2_im_vld, stage2_im_last : std_logic := '0';

begin

  dds_vld <= dds_vld_int;

  DDS : entity work.DDS_Channelizer
    port map (
      aclk => clk,
      aresetn => not rst,
      s_axis_config_tvalid => dds_phase_inc_vld,
      s_axis_config_tdata => dds_phase_inc,
      m_axis_data_tvalid => dds_vld_int,
      m_axis_data_tdata(31 downto 16) => dds_sin,
      m_axis_data_tdata(15 downto 0) => dds_cos
    );

  multiplier : entity work.ComplexMultiplier
  generic map(
  A_WIDTH => DATA_IN_WIDTH,
  B_WIDTH => 16,
  PROD_WIDTH => 24,
  BIT_SHIFT => 1
  )
  port map(
    clk => clk,
    rst => rst,

    a_data_re => data_in_re,
    a_data_im => data_in_im,
    a_vld => data_in_vld,
    a_last => data_in_last,

    b_data_re => dds_cos,
    b_data_im => dds_sin,
    b_vld => dds_vld_int,
    b_last => '0',

    prod_data_re => mult_re,
    prod_data_im => mult_im,
    prod_vld => mult_vld,
    prod_last => mult_last
  );

  --FIR filtering to select channel

  --Initial stage with 1/4 rate decimation
  FIR_Stage1_re : entity work.FIR_ChannelSelect_Stage1
  port map (
    aresetn => not rst,
    aclk => clk,
    s_axis_data_tvalid => mult_vld,
    s_axis_data_tready => open,
    s_axis_data_tlast => mult_last,
    s_axis_data_tdata => mult_re,
    m_axis_data_tvalid => stage1_re_vld,
    m_axis_data_tlast => stage1_re_last,
    m_axis_data_tdata => stage1_re
  );

  FIR_Stage1_im : entity work.FIR_ChannelSelect_Stage1
  port map (
    aresetn => not rst,
    aclk => clk,
    s_axis_data_tvalid => mult_vld,
    s_axis_data_tready => open,
    s_axis_data_tlast => mult_last,
    s_axis_data_tdata => mult_im,
    m_axis_data_tvalid => stage1_im_vld,
    m_axis_data_tlast => stage1_im_last,
    m_axis_data_tdata => stage1_im
  );

  --Second stage with 1/2 rate decimation
  --TODO: add reloadable coefficients at this stage
  FIR_Stage2_re : entity work.FIR_ChannelSelect_Stage2
  port map (
    aresetn => not rst,
    aclk => clk,
    s_axis_data_tvalid => stage1_re_vld,
    s_axis_data_tready => open,
    s_axis_data_tlast => stage1_re_last,
    s_axis_data_tdata => std_logic_vector(resize(signed(stage1_re), 24)),
    m_axis_data_tvalid => stage2_re_vld,
    m_axis_data_tlast => stage2_re_last,
    m_axis_data_tdata => stage2_re
  );

  FIR_Stage2_im : entity work.FIR_ChannelSelect_Stage2
  port map (
    aresetn => not rst,
    aclk => clk,
    s_axis_data_tvalid => stage1_im_vld,
    s_axis_data_tready => open,
    s_axis_data_tlast => stage1_im_last,
    s_axis_data_tdata => std_logic_vector(resize(signed(stage1_im), 24)),
    m_axis_data_tvalid => stage2_im_vld,
    m_axis_data_tlast => stage2_im_last,
    m_axis_data_tdata => stage2_im
  );

  --Slice out the MSB for the data_out
  --Undo the bit shift from the filters
  data_out_re <= stage2_re(stage2_re'high-2 downto stage2_re'high-DATA_OUT_WIDTH-1);
  data_out_im <= stage2_im(stage2_im'high-2 downto stage2_im'high-DATA_OUT_WIDTH-1);
  data_out_vld <= stage2_re_vld;
  data_out_last <= stage2_re_last;

end architecture;
