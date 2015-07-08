library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity VitaFramer_tb is
end;

architecture bench of VitaFramer_tb is

  constant INPUT_BYTE_WIDTH : natural := 2;
  constant INPUT_FIFO_DEPTH : natural := 8;
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal payload_size : std_logic_vector(15 downto 0) := (others => '0');
  signal pad_bytes : std_logic_vector(3 downto 0) := (others => '0');
  signal stream_id : std_logic_vector(15 downto 0) := (others => '0');
  signal in_data : std_logic_vector(INPUT_BYTE_WIDTH*8 - 1 downto 0) := (others => '0');
  signal in_vld : std_logic := '0';
  signal in_last : std_logic := '0';
  signal in_rdy : std_logic := '0';
  signal out_data : std_logic_vector(31 downto 0) := (others => '0');
  signal out_vld : std_logic := '0';
  signal out_last : std_logic := '0';
  signal out_rdy : std_logic := '0';
  signal ts_seconds : std_logic_vector(31 downto 0) := (others => '0');
  signal ts_frac_seconds : std_logic_vector(31 downto 0) := (others => '0');

  signal test_data : std_logic_vector(15 downto 0) := (others => '0');
  signal test_vld, test_last : std_logic := '0';

  constant CLK_PERIOD : time := 10 ns;
  signal stop_the_clock : boolean := false;

  type TestBenchState_t is (RESET, MEDIUM_FRAME, SHORT_FRAME, LONG_FRAME, FINISHED);
  signal testBench_state : TestBenchState_t;

  shared variable ct : natural;

  component axis_fifo
    generic (
      ADDR_WIDTH : natural := 12;
      DATA_WIDTH : natural := 8
    );
    port (
      clk         : in std_logic;
      rst         : in std_logic;

      input_axis_tdata  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      input_axis_tvalid : in std_logic;
      input_axis_tready : out std_logic;
      input_axis_tlast  : in std_logic;
      input_axis_tuser  : in std_logic;

      output_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      output_axis_tvalid : out std_logic;
      output_axis_tready : in std_logic;
      output_axis_tlast  : out std_logic;
      output_axis_tuser  : out std_logic
    );
  end component;

begin

  timeStamper : entity work.VitaTimeStamp
    generic map (CLK_FREQ => 200)
    port map (
      clk => clk,
      rst => rst,

      ts_seconds => ts_seconds,
      ts_frac_seconds => ts_frac_seconds
    );

  uut: entity work.VitaFramer
    generic map (
      INPUT_BYTE_WIDTH => INPUT_BYTE_WIDTH,
      INPUT_FIFO_DEPTH => INPUT_FIFO_DEPTH
    )
    port map (
      clk             => clk,
      rst             => rst,
      stream_id       => stream_id,
      payload_size    => payload_size,
      pad_bytes       => pad_bytes,
      ts_seconds      => ts_seconds,
      ts_frac_seconds => ts_frac_seconds,
      in_data         => in_data,
      in_vld          => in_vld,
      in_last         => in_last,
      in_rdy          => in_rdy,
      out_data        => out_data,
      out_vld         => out_vld,
      out_last        => out_last,
      out_rdy         => out_rdy
    );

  --Little FIFO so we don't have to worry about stream rdy handshaking
  input : axis_fifo
  generic map (
    DATA_WIDTH => 16,
    ADDR_WIDTH => 4
  )
  port map (
    clk => clk,
    rst => rst,

    input_axis_tdata => test_data,
    input_axis_tvalid => test_vld,
    input_axis_tready => open,
    input_axis_tlast => test_last,
    input_axis_tuser => '0',

    output_axis_tdata => in_data,
    output_axis_tvalid => in_vld,
    output_axis_tready => in_rdy,
    output_axis_tlast => in_last,
    output_axis_tuser => open
  );


  stimulus: process
  begin

    --Initial reset
    testBench_state <= RESET;
    rst <= '1';
    wait for 100ns;
    rst <= '0';
    wait for 20ns;

    --Clock in a medium size frame
    testBench_state <= MEDIUM_FRAME;
    payload_size <= std_logic_vector(to_unsigned(64, 16));
    stream_id <= x"baad";
    out_rdy <= '1';
    wait until rising_edge(clk);

    for ct in 1 to 128 loop
      test_vld <= '1';
      test_data <= std_logic_vector(to_signed(ct, 16));
      if ct = 128 then
        test_last <= '1';
      end if;
      wait until rising_edge(clk);
    end loop;
    test_vld <= '0';
    test_last <= '0';
    test_data <= (others => '0');

    --Wait for packet to come out so we don't clobber payload_size, pad_bytes etc
    wait until out_last = '1';
    wait for 50ns;
    wait until rising_edge(clk);

    --Clock in a short frame with padding
    testBench_state <= SHORT_FRAME;
    payload_size <= std_logic_vector(to_unsigned(4, 16));
    pad_bytes <= x"e";
    stream_id <= x"1234";
    out_rdy <= '1';
    wait until rising_edge(clk);

    test_vld <= '1';
    test_data <= x"abcd";
    test_last <= '1';
    wait until rising_edge(clk);
    test_vld <= '0';
    test_last <= '0';
    test_data <= (others => '0');

    wait for 50ns;

    testBench_state <= FINISHED;
    wait for 200ns;

    stop_the_clock <= true;
    wait;
  end process;

  dataCheck : process
  begin

    ----------------------------------------------------------------------------
    wait until testBench_state = MEDIUM_FRAME;

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"1cf0" & std_logic_vector(unsigned(payload_size)+8) report "Vita header IF word incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"0001" & stream_id report "Vita header SID word incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00000000" report "Vita header class OUI incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00030000" report "Vita header class info. incorrect";

    for ct in 1 to 2 loop
      wait until rising_edge(clk) and out_vld = '1';
      assert out_data = x"00000000" report "Vita timestamp incorrect";
    end loop;
    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00000005" report "Vita timestamp incorrect";

    --16 bit samples are packed in sample1sample0
    for ct in 1 to 64 loop
      wait until rising_edge(clk) and out_vld = '1';
      assert out_data = std_logic_vector(to_signed(2*ct, 16)) & std_logic_vector(to_signed(2*ct-1, 16)) report "Vita packet data incorrect";
    end loop;

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00f00000" report "Vita tail incorrect";
    assert out_last = '1' report "Last flag not set high at tail";

    -------------------------------------------------------------------------------
    wait until testBench_state = SHORT_FRAME;

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"1cf1" & std_logic_vector(unsigned(payload_size)+8) report "Vita header IF word incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"0001" & stream_id report "Vita header SID word incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00000000" report "Vita header class OUI incorrect";

    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00030000" report "Vita header class info. incorrect";

    for ct in 1 to 2 loop
      wait until rising_edge(clk) and out_vld = '1';
      assert out_data = x"00000000" report "Vita timestamp incorrect";
    end loop;
    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"00000098" report "Vita timestamp incorrect";

    --16 bit samples are packed in sample1sample0
    wait until rising_edge(clk) and out_vld = '1';
    assert out_data = x"0000abcd" report "Vita packet data incorrect";

    --padding words
    for ct in 1 to 3 loop
      wait until rising_edge(clk) and out_vld = '1';
      assert out_data = x"00000000" and out_last = '0' report "Padding incorrect";
    end loop;

    wait until rising_edge(clk) and out_vld = '1' and out_last = '1';
    assert out_data = x"00f00" & pad_bytes & x"00" report "Vita tail incorrect";

    wait;
  end process;

  --Clocking
  clk <= not clk after CLK_PERIOD /2 when not stop_the_clock;



end;
