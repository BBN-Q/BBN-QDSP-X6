-- Treed-muxing of all the vita streams produced by the QDSP module
--
--
-- Original author Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BBN_QDSP_pkg.all;

entity BBN_QDSP_VitaMuxer is
  port (
  clk : in std_logic;
  rst : in std_logic;

  vita_raw_data  : in std_logic_vector(31 downto 0);
  vita_raw_vld   : in std_logic;
  vita_raw_rdy   : out std_logic;
  vita_raw_last  : in std_logic;

  vita_result_raw_data  : in width_32_array_t(NUM_DEMOD_CH-1 downto 0);
  vita_result_raw_vld   : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_result_raw_rdy   : out std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_result_raw_last  : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);

  vita_demod_data  : in width_32_array_t(NUM_DEMOD_CH-1 downto 0);
  vita_demod_vld   : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_demod_rdy   : out std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_demod_last  : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);

  vita_result_demod_data  : in width_32_array_t(NUM_DEMOD_CH-1 downto 0);
  vita_result_demod_vld   : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_result_demod_rdy   : out std_logic_vector(NUM_DEMOD_CH-1 downto 0);
  vita_result_demod_last  : in std_logic_vector(NUM_DEMOD_CH-1 downto 0);

  vita_muxed_data  : out std_logic_vector(31 downto 0);
  vita_muxed_vld   : out std_logic;
  vita_muxed_rdy   : in std_logic;
  vita_muxed_last  : out std_logic
  );
end entity;

architecture arch of BBN_QDSP_VitaMuxer is

--Post FIFO signals
signal vita_raw_pf_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_raw_pf_vld, vita_raw_pf_rdy, vita_raw_pf_last : std_logic := '0';

signal vita_result_raw_pf_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_result_raw_pf_vld, vita_result_raw_pf_last, vita_result_raw_pf_rdy : std_logic_vector(NUM_RAW_KI_CH-1 downto 0) := (others => '0');

signal vita_demod_pf_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_demod_pf_vld, vita_demod_pf_last, vita_demod_pf_rdy : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

signal vita_result_demod_pf_data : width_32_array_t(NUM_DEMOD_CH-1 downto 0) := (others => (others => '0'));
signal vita_result_demod_pf_vld, vita_result_demod_pf_last, vita_result_demod_pf_rdy : std_logic_vector(NUM_DEMOD_CH-1 downto 0) := (others => '0');

--Post intermediate muxers
signal vita_muxed_result_raw_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_muxed_result_raw_vld, vita_muxed_result_raw_rdy, vita_muxed_result_raw_last : std_logic := '0';

signal vita_muxed_demod_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_muxed_demod_vld, vita_muxed_demod_rdy, vita_muxed_demod_last : std_logic := '0';

signal vita_muxed_result_demod_data : std_logic_vector(31 downto 0) := (others => '0');
signal vita_muxed_result_demod_vld, vita_muxed_result_demod_rdy, vita_muxed_result_demod_last : std_logic := '0';

begin

  --FIFO's to buffer data while arbitrating
  rawFIFO: axis_fifo
  generic map (
    ADDR_WIDTH => 12, --4096-8 VITA words = 8184 samples (2 samples per word)
    DATA_WIDTH => 32
  )
  port map (
    clk => clk,
    rst => rst,

    input_axis_tdata  => vita_raw_data,
    input_axis_tvalid => vita_raw_vld,
    input_axis_tready => vita_raw_rdy,
    input_axis_tlast  => vita_raw_last,
    input_axis_tuser  => '0',

    output_axis_tdata  => vita_raw_pf_data,
    output_axis_tvalid => vita_raw_pf_vld,
    output_axis_tready => vita_raw_pf_rdy,
    output_axis_tlast  => vita_raw_pf_last,
    output_axis_tuser  => open
  );

  resultRawloop : for ct in 0 to NUM_RAW_KI_CH-1 generate
    resultRawFIFO: axis_fifo
    generic map (
      ADDR_WIDTH => 4, --16-8 VITA words =  4 samples (2 words per sample - Complex{Int32})
      DATA_WIDTH => 32
    )
    port map (
      clk => clk,
      rst => rst,

      input_axis_tdata  => vita_result_raw_data(ct),
      input_axis_tvalid => vita_result_raw_vld(ct),
      input_axis_tready => vita_result_raw_rdy(ct),
      input_axis_tlast  => vita_result_raw_last(ct),
      input_axis_tuser  => '0',

      output_axis_tdata  => vita_result_raw_pf_data(ct),
      output_axis_tvalid => vita_result_raw_pf_vld(ct),
      output_axis_tready => vita_result_raw_pf_rdy(ct),
      output_axis_tlast  => vita_result_raw_pf_last(ct),
      output_axis_tuser  => open
    );

  end generate;

  demodFIFOloop : for ct in 0 to NUM_DEMOD_CH-1 generate
    demodFIFO: axis_fifo
    generic map (
      ADDR_WIDTH => 10, --1024-8 VITA words = 1016 samples (1 sample per word - Complex{Int16})
      DATA_WIDTH => 32
    )
    port map (
      clk => clk,
      rst => rst,

      input_axis_tdata  => vita_demod_data(ct),
      input_axis_tvalid => vita_demod_vld(ct),
      input_axis_tready => vita_demod_rdy(ct),
      input_axis_tlast  => vita_demod_last(ct),
      input_axis_tuser  => '0',

      output_axis_tdata  => vita_demod_pf_data(ct),
      output_axis_tvalid => vita_demod_pf_vld(ct),
      output_axis_tready => vita_demod_pf_rdy(ct),
      output_axis_tlast  => vita_demod_pf_last(ct),
      output_axis_tuser  => open
    );

    resultDemodFIFO: axis_fifo
    generic map (
      ADDR_WIDTH => 4, --16-8 VITA words =  4 samples (2 words per sample - Complex{Int32})
      DATA_WIDTH => 32
    )
    port map (
      clk => clk,
      rst => rst,

      input_axis_tdata  => vita_result_demod_data(ct),
      input_axis_tvalid => vita_result_demod_vld(ct),
      input_axis_tready => vita_result_demod_rdy(ct),
      input_axis_tlast  => vita_result_demod_last(ct),
      input_axis_tuser  => '0',

      output_axis_tdata  => vita_result_demod_pf_data(ct),
      output_axis_tvalid => vita_result_demod_pf_vld(ct),
      output_axis_tready => vita_result_demod_pf_rdy(ct),
      output_axis_tlast  => vita_result_demod_pf_last(ct),
      output_axis_tuser  => open
    );

  end generate;

  --Mux together the raw result streams
  rawResultMux : axis_arb_mux_2
    generic map (
      DATA_WIDTH => 32,
      ARB_TYPE   => "ROUND_ROBIN",
      LSB_PRIORITY => "HIGH"
    )
    port map (
      clk => clk,
      rst => rst,

      input_0_axis_tdata   => vita_result_raw_pf_data(0),
      input_0_axis_tvalid  => vita_result_raw_pf_vld(0),
      input_0_axis_tready  => vita_result_raw_pf_rdy(0),
      input_0_axis_tlast   => vita_result_raw_pf_last(0),
      input_0_axis_tuser   => '0',

      input_1_axis_tdata   => vita_result_raw_pf_data(1),
      input_1_axis_tvalid  => vita_result_raw_pf_vld(1),
      input_1_axis_tready  => vita_result_raw_pf_rdy(1),
      input_1_axis_tlast   => vita_result_raw_pf_last(1),
      input_1_axis_tuser   => '0',

      output_axis_tdata    => vita_muxed_result_raw_data,
      output_axis_tvalid   => vita_muxed_result_raw_vld,
      output_axis_tready   => vita_muxed_result_raw_rdy,
      output_axis_tlast    => vita_muxed_result_raw_last,
      output_axis_tuser    => open
    );

  --Mux together the demod streams
  demodMux : axis_arb_mux_2
    generic map (
      DATA_WIDTH => 32,
      ARB_TYPE   => "ROUND_ROBIN",
      LSB_PRIORITY => "HIGH"
    )
    port map (
      clk => clk,
      rst => rst,

      input_0_axis_tdata   => vita_demod_pf_data(0),
      input_0_axis_tvalid  => vita_demod_pf_vld(0),
      input_0_axis_tready  => vita_demod_pf_rdy(0),
      input_0_axis_tlast   => vita_demod_pf_last(0),
      input_0_axis_tuser   => '0',

      input_1_axis_tdata   => vita_demod_pf_data(1),
      input_1_axis_tvalid  => vita_demod_pf_vld(1),
      input_1_axis_tready  => vita_demod_pf_rdy(1),
      input_1_axis_tlast   => vita_demod_pf_last(1),
      input_1_axis_tuser   => '0',

      output_axis_tdata    => vita_muxed_demod_data,
      output_axis_tvalid   => vita_muxed_demod_vld,
      output_axis_tready   => vita_muxed_demod_rdy,
      output_axis_tlast    => vita_muxed_demod_last,
      output_axis_tuser    => open
    );

  --Mux together the demod result streams
  demodResultMux : axis_arb_mux_2
    generic map (
      DATA_WIDTH => 32,
      ARB_TYPE   => "ROUND_ROBIN",
      LSB_PRIORITY => "HIGH"
    )
    port map (
      clk => clk,
      rst => rst,

      input_0_axis_tdata   => vita_result_demod_pf_data(0),
      input_0_axis_tvalid  => vita_result_demod_pf_vld(0),
      input_0_axis_tready  => vita_result_demod_pf_rdy(0),
      input_0_axis_tlast   => vita_result_demod_pf_last(0),
      input_0_axis_tuser   => '0',

      input_1_axis_tdata   => vita_result_demod_pf_data(1),
      input_1_axis_tvalid  => vita_result_demod_pf_vld(1),
      input_1_axis_tready  => vita_result_demod_pf_rdy(1),
      input_1_axis_tlast   => vita_result_demod_pf_last(1),
      input_1_axis_tuser   => '0',

      output_axis_tdata    => vita_muxed_result_demod_data,
      output_axis_tvalid   => vita_muxed_result_demod_vld,
      output_axis_tready   => vita_muxed_result_demod_rdy,
      output_axis_tlast    => vita_muxed_result_demod_last,
      output_axis_tuser    => open
    );

  --Mux together all the streams
  finalMux : axis_arb_mux_4
    generic map (
      DATA_WIDTH => 32,
      ARB_TYPE   => "ROUND_ROBIN",
      LSB_PRIORITY => "HIGH"
    )
    port map (
      clk => clk,
      rst => rst,

      input_0_axis_tdata   => vita_raw_pf_data,
      input_0_axis_tvalid  => vita_raw_pf_vld,
      input_0_axis_tready  => vita_raw_pf_rdy,
      input_0_axis_tlast   => vita_raw_pf_last,
      input_0_axis_tuser   => '0',

      input_1_axis_tdata   => vita_muxed_result_raw_data,
      input_1_axis_tvalid  => vita_muxed_result_raw_vld,
      input_1_axis_tready  => vita_muxed_result_raw_rdy,
      input_1_axis_tlast   => vita_muxed_result_raw_last,
      input_1_axis_tuser   => '0',

      input_2_axis_tdata   => vita_muxed_demod_data,
      input_2_axis_tvalid  => vita_muxed_demod_vld,
      input_2_axis_tready  => vita_muxed_demod_rdy,
      input_2_axis_tlast   => vita_muxed_demod_last,
      input_2_axis_tuser   => '0',

      input_3_axis_tdata   => vita_muxed_result_demod_data,
      input_3_axis_tvalid  => vita_muxed_result_demod_vld,
      input_3_axis_tready  => vita_muxed_result_demod_rdy,
      input_3_axis_tlast   => vita_muxed_result_demod_last,
      input_3_axis_tuser   => '0',

      output_axis_tdata    => vita_muxed_data,
      output_axis_tvalid   => vita_muxed_vld,
      output_axis_tready   => vita_muxed_rdy,
      output_axis_tlast    => vita_muxed_last,
      output_axis_tuser    => open
    );

end architecture;
