-- Vita framer for packetized AXI streams
-- Exhibits back presssure while applying header
--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.VitaFramer_pkg.all;

entity VitaFramer is
  generic (
    INPUT_BYTE_WIDTH : natural := 16
  );
  port (
  clk : in std_logic;
  rst : in std_logic;

  frame_size : in std_logic_vector(15 downto 0);

  in_data : in std_logic_vector(INPUT_BYTE_WIDTH*8 - 1 downto 0);
  in_vld : in std_logic;
  in_last : in std_logic;
  in_rdy : out std_logic;

  out_data : in std_logic_vector(127 downto 0);
  out_vld : in std_logic;
  out_last : in std_logic
  );
end entity;

architecture arch of VitaFramer is

type VITA_HEADER_ARRAY_t is array(0 to 6) of std_logic_vector(31 downto 0);
signal vita_header_array : VITA_HEADER_ARRAY_t;

signal in_wide_data : std_logic_vector(127 downto 0) := (others => '0');
signal in_wide_vld, in_wide_last, in_wide_rdy : std_logic := '0';

begin

--See page 314-315 of X6-1000M FrameWork Logic Guide or Vita Packet Format (page 100) of X6-1000M User's Manual
vita_header_array(0)(31 downto 24) <= "0001" & "1100"; --set by II
vita_header_array(0)(23 downto 22) <= "11"; --timestamping integer seconds format = other
vita_header_array(0)(21 downto 20) <= "11"; --timestamping fractional seconds format = other
vita_header_array(0)(19 downto 16) <= "0000"; -- packet count
vita_header_array(0)(15 downto 0) <= frame_size;

--Bring the input width up to 128 bits using an adaptor
input_width_adapter : axis_adapter
generic map (
  INPUT_DATA_WIDTH => 8*INPUT_BYTE_WIDTH,
  INPUT_KEEP_WIDTH => INPUT_BYTE_WIDTH,
  OUTPUT_DATA_WIDTH => 128,
  OUTPUT_KEEP_WIDTH => 16
)
port map (
  clk => clk,
  rst => rst,

  --AXI input
  input_axis_tdata  => in_data,
  input_axis_tkeep  => (others => '1'),
  input_axis_tvalid => in_vld,
  input_axis_tready => in_rdy,
  input_axis_tlast  => in_last,
  input_axis_tuser  => '0',

  --AXI input
  output_axis_tdata  => in_wide_data,
  output_axis_tkeep  => open,
  output_axis_tvalid => in_wide_vld,
  output_axis_tready => in_wide_rdy,
  output_axis_tlast  => in_wide_last,
  output_axis_tuser  => open
);

main : process(clk)
type STATE_t is (IDLE, WRITING_HEADER, RUNNING, WRITING_TAIL);
variable state : STATE_t;
variable headerct : natural range 0 to 1 := 0;
begin
  if rising_edge(clk) then
    if rst = '1' then
      state := IDLE;
      in_wide_rdy <= '0';
    else
      case( state ) is

        when IDLE =>
          headerct := 0;
          --Wait until in_vld is asserted
          in_wide_rdy <= '0';
          if in_vld = '1' then
            state := WRITING_HEADER;
          end if;

        when WRITING_HEADER =>
          in_wide_rdy <= '0';
          state := RUNNING;

        when RUNNING =>
          in_wide_rdy <= '1';

        when WRITING_TAIL =>
          null;

      end case;
    end if;
  end if;

end process;

end architecture;
