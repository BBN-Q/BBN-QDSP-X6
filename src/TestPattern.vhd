-- Create test autodyne pulses for transmit or receive
-- Samples are created 4 wide as per the usual 4:1 analog-to-FPGA clock ratio
--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestPattern is
  generic (
    SAMPLE_WIDTH : natural := 16;
    TRIGGER_WIDTH : natural := 2
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    trig_interval : in std_logic_vector(15 downto 0); --trigger interval in clocks
    trigger : buffer std_logic;

    pattern_data_re : out std_logic_vector(4*SAMPLE_WIDTH-1 downto 0);
    pattern_data_im : out std_logic_vector(4*SAMPLE_WIDTH-1 downto 0)
  );
end entity;

architecture arch of TestPattern is

signal rst_SSB : std_logic := '0';

--1MHz on 250MHz clock rate and 24 bits phase precision is 2^24 * (1/250) = 67108.864
constant BASE_PHASE_INC : unsigned(17 downto 0) := to_unsigned(67109, 18);
constant MAX_VAL_SLV : std_logic_vector(SAMPLE_WIDTH-1 downto 0) := std_logic_vector(to_signed( 2**(SAMPLE_WIDTH-1)-1, SAMPLE_WIDTH));

signal phinc : unsigned(23 downto 0) := (others => '0');

signal recordct : unsigned(5 downto 0) := (others => '0');
signal samplect : unsigned(10 downto 0) := (others => '0');

signal samp_base_re, samp_base_im : signed(7 downto 0);
signal out_ssb_re, out_ssb_im : std_logic_vector(4*SAMPLE_WIDTH-1 downto 0);
signal ssb_vld : std_logic := '0';

begin

triggerPro : process(clk)
variable ct : unsigned(16 downto 0);
variable triggerLine : std_logic_vector(TRIGGER_WIDTH-1 downto 0);
begin
  if rising_edge(clk) then
    if rst = '1' then
      ct := unsigned('0' & trig_interval)-2;
      triggerLine := (others => '0');
      trigger <= '0';
    else
      if ct(ct'high) = '1' then
        triggerLine := (others => '1');
        ct := unsigned('0' & trig_interval)-2;
      else
        ct := ct - 1;
        triggerLine := triggerLine(triggerLine'high-1 downto 0) & '0';
      end if;
      trigger <= triggerLine(triggerLine'high);
    end if;
  end if;
end process;



main : process(clk)
type STATE_t is (IDLE, RESETTING, ALIGN_MARKER, WAIT_FOR_VALID, PLAYING);
variable state : STATE_t := IDLE;
variable resetct : natural range 0 to 3 := 0;
variable alignct :natural range 0 to 3 := 0;
begin
  if rising_edge(clk) then
    phinc <= recordct * BASE_PHASE_INC;
    if rst = '1' then
      state := IDLE;
      rst_SSB <= '1';
      resetct := 0;
      alignct := 0;
      recordct <= (others => '0');
      pattern_data_re <= (others => '0');
      pattern_data_im <= (others => '0');
    else
      case( state ) is

        when IDLE =>
          pattern_data_re <= (others => '0');
          pattern_data_im <= (others => '0');
          --wait for trigger
          resetct := 0;
          if trigger = '1' then
            state := RESETTING;
          end if;

        when RESETTING =>
          --Hold reset for at least two clock cycles
          rst_SSB <= '1';
          samplect <= to_unsigned(1023, samplect'length);
          alignct := 0;
          if resetct = 2 then
            state := ALIGN_MARKER;
          end if;
          resetct := resetct + 1;

        when ALIGN_MARKER =>
          if recordct = 0 then
            pattern_data_re <= MAX_VAL_SLV & MAX_VAL_SLV & MAX_VAL_SLV & MAX_VAL_SLV;
            pattern_data_im <= (others => '0');
          end if;

          if alignct = 3 then
            state := WAIT_FOR_VALID;
          end if;
          alignct := alignct + 1;

        when WAIT_FOR_VALID =>
          rst_SSB <= '0';
          pattern_data_re <= (others => '0');
          pattern_data_im <= (others => '0');
          if ssb_vld = '1' then
            state := PLAYING;
          end if;

        when PLAYING =>
          pattern_data_re <= out_ssb_re;
          pattern_data_im <= out_ssb_im;

          if samplect(samplect'high) = '1' then
            recordct <= recordct + 1;
            state := IDLE;
          end if;
          samplect <= samplect - 1;
      end case;
    end if;
  end if;

end process;


samp_base_re <= to_signed(127, 8);
samp_base_im <= to_signed(0, 8);

--Polyphase SSB module to generate waveforms
polyphaseSSB : entity work.PolyphaseSSB
  generic map (
    IN_DATA_WIDTH => 8,
    OUT_DATA_WIDTH => SAMPLE_WIDTH
  )
  port map (
    clock => clk,
    reset => rst_SSB,

    phinc => std_logic_vector(phinc),
    phoff => (others => '0'),

    waveform_in_re => std_logic_vector(samp_base_re) & std_logic_vector(samp_base_re) & std_logic_vector(samp_base_re) & std_logic_vector(samp_base_re),
    waveform_in_im => std_logic_vector(samp_base_im) & std_logic_vector(samp_base_im) & std_logic_vector(samp_base_im) & std_logic_vector(samp_base_im),

    waveform_out_re => out_ssb_re,
    waveform_out_im => out_ssb_im,
    out_vld         => ssb_vld
  );

end architecture;
