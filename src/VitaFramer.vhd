-- Vita framer for packetized AXI streams
-- Exhibits back presssure while applying header
-- Currently works at VITA word width (4 bytes) with adapters as necessary
-- This could be a performance bottleneck for continuous wide input streams
-- However because of the 7 word VITA header it makes life much easier

--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.VitaFramer_pkg.all;

entity VitaFramer is
  generic (
    INPUT_BYTE_WIDTH : natural := 4
  );
  port (
  clk : in std_logic;
  rst : in std_logic;

  stream_id : in std_logic_vector(15 downto 0);
  frame_size : in std_logic_vector(15 downto 0);
  pad_bytes : in std_logic_vector(3 downto 0);

  in_data : in std_logic_vector(INPUT_BYTE_WIDTH*8 - 1 downto 0);
  in_vld : in std_logic;
  in_last : in std_logic;
  in_rdy : out std_logic;

  out_data : out std_logic_vector(31 downto 0);
  out_vld : out std_logic;
  out_last : out std_logic;
  out_rdy : in std_logic
  );
end entity;

architecture arch of VitaFramer is

type VITA_HEADER_ARRAY_t is array(0 to 6) of std_logic_vector(31 downto 0);
signal vita_header_array : VITA_HEADER_ARRAY_t;

signal vita_tail : std_logic_vector(31 downto 0) := (others => '0');

--vww = Vita Word Wide
signal in_vww_data : std_logic_vector(31 downto 0) := (others => '0');
signal in_vww_vld, in_vww_last, in_vww_rdy : std_logic := '0';

signal pkt_data, meta_data : std_logic_vector(31 downto 0) := (others => '0');
signal pkt_vld, pkt_last, pkt_rdy, meta_vld : std_logic := '0';

type STATE_t is (IDLE, WRITE_HEADER, RUN, HOLDOFF, PAD_FRAME, WRITE_TAIL);
signal state : STATE_t;

begin

--See page 314-315 of X6-1000M FrameWork Logic Guide or Vita Packet Format (page 100) of X6-1000M User's Manual
vita_header_array(0) <= "0001" & "1100" --set by II
                        & "11" --timestamping integer seconds format = other
                        & "11" --timestamping fractional seconds format = other
                        & "0000" -- packet count
                        & frame_size;

vita_header_array(1) <= x"0001" & stream_id;
vita_header_array(2) <= (others => '0'); --Class OUI apparently not used
vita_header_array(3) <= x"00030000"; --Class Info word -- II puts some partial packet info in here; here we put eof and sof high; see ii_vita_framer.vhd
vita_header_array(4) <= (others => '0'); -- timestamp integer seconds TODO
vita_header_array(5) <= (others => '0'); -- timestamp fraction seconds high TODO
vita_header_array(6) <= (others => '0'); -- timestamp fraction seconds low TODO

vita_tail <= x"00f00" & pad_bytes & X"00";

--Bring the width to 32 bits using an adaptor
--TODO: if-block if already at 32bit
input_width_adapter : axis_adapter
generic map (
  INPUT_DATA_WIDTH => 8*INPUT_BYTE_WIDTH,
  INPUT_KEEP_WIDTH => INPUT_BYTE_WIDTH,
  OUTPUT_DATA_WIDTH => 32,
  OUTPUT_KEEP_WIDTH => 4
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
  output_axis_tdata  => in_vww_data,
  output_axis_tkeep  => open,
  output_axis_tvalid => in_vww_vld,
  output_axis_tready => in_vww_rdy,
  output_axis_tlast  => in_vww_last,
  output_axis_tuser  => open
);

main : process(clk)
variable headerct : natural range 0 to 7 := 0;
variable wordct : unsigned(16 downto 0) := (others => '0');
begin
  if rising_edge(clk) then
    if rst = '1' then
      state <= IDLE;
      meta_vld <= '0';
      pkt_last <= '0';
      headerct := 0;
    else
      case( state ) is

        when IDLE =>
          meta_vld <= '0';
          pkt_last <= '0';
          headerct := 0;
          wordct := resize(unsigned(frame_size),17) - 1 - 8;
          --Wait until in_vld is asserted
          if in_vld = '1' then
            state <= WRITE_HEADER;
          end if;

        when WRITE_HEADER =>
          meta_data <= vita_header_array(headerct);
          meta_vld <= '1';
          if headerct = 6 then
            state <= HOLDOFF;
          end if;
          headerct := headerct + 1;

        --Hold off 1 clock to finish writing header before combination mux below kicks in
        when HOLDOFF =>
          meta_vld <= '0';
          state <= RUN;

        when RUN =>
          if in_vww_vld = '1' and in_vww_rdy = '1' then
            wordct := wordct - 1;
          end if;
          if in_vww_last = '1' and in_vww_rdy = '1' then
            state <= PAD_FRAME;
          end if;

        when PAD_FRAME =>
          meta_data <= (others => '0');
          if wordct(wordct'high) = '1' then
            state <= WRITE_TAIL;
            meta_vld <= '0';
          else
            meta_vld <= '1';
            if pkt_rdy = '1' then
              wordct := wordct - 1;
            end if;
          end if;

        when WRITE_TAIL =>
          meta_vld <= '1';
          meta_data <= vita_tail;
          pkt_last <= '1';
          state <= IDLE;

      end case;
    end if;
  end if;
end process;

--Mux the packet data between header/tail and data
pkt_data <= in_vww_data when state = RUN else meta_data;
pkt_vld <= in_vww_vld when state = RUN else meta_vld;
in_vww_rdy <= pkt_rdy when state = RUN else '0';

--Output register
pktFIFO : axis_srl_register
generic map (
  DATA_WIDTH => 32
)
port map (
  clk => clk,
  rst => rst,

  input_axis_tdata => pkt_data,
  input_axis_tvalid => pkt_vld,
  input_axis_tready => pkt_rdy,
  input_axis_tlast => pkt_last,
  input_axis_tuser => '0',

  output_axis_tdata => out_data,
  output_axis_tvalid => out_vld,
  output_axis_tready => out_rdy,
  output_axis_tlast => out_last,
  output_axis_tuser => open
);

end architecture;
