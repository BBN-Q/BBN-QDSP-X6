-- Wishbone registers for the qubit DSP module
--
-- Original authors Colm Ryan and Blake Johnson
-- Copyright 2015, Raytheon BBN Technologies

-- Based of a design Copyright 2012 by Innovative Integration Inc., All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BBN_QDSP_pkg.all;

entity BBN_QDSP_regs is
  generic (
    addr_bits            : integer := 6;
    offset               : std_logic_vector(15 downto 0)
  );
  port (
    -- Wishbone interface signals
    wb_rst_i             : in  std_logic;
    wb_clk_i             : in  std_logic;
    wb_adr_i             : in  std_logic_vector(15 downto 0);
    wb_dat_i             : in  std_logic_vector(31 downto 0);
    wb_we_i              : in  std_logic;
    wb_stb_i             : in  std_logic;
    wb_ack_o             : out std_logic;
    wb_dat_o             : out std_logic_vector(31 downto 0);

    -- User registers
    test_settings        : out std_logic_vector(31 downto 0);
    record_length        : out std_logic_vector(15 downto 0);
    stream_enable        : out std_logic_vector(31 downto 0);

    phase_inc            : out width_24_array_t(NUM_DEMOD_CH-1 downto 0);

    kernel_len           : out kernel_addr_array(NUM_DEMOD_CH-1 downto 0);
    threshold            : out width_32_array_t(NUM_DEMOD_CH-1 downto 0);
    kernel_addr          : out kernel_addr_array(NUM_DEMOD_CH-1 downto 0);
    kernel_wr_data       : out width_32_array_t(NUM_DEMOD_CH-1 downto 0);
    kernel_rd_data       : in width_32_array_t(NUM_DEMOD_CH-1 downto 0);
    kernel_we            : out std_logic_vector(NUM_DEMOD_CH-1 downto 0)
  );
end BBN_QDSP_regs;

architecture arch of BBN_QDSP_regs is

  component ii_regs_core
    generic (
      addr_bits            : integer;
      offset               : std_logic_vector(15 downto 0)
    );
    port (
      -- Wishbone slave interface
      wb_rst_i             : in  std_logic;
      wb_clk_i             : in  std_logic;
      wb_adr_i             : in  std_logic_vector(15 downto 0);
      wb_dat_i             : in  std_logic_vector(31 downto 0);
      wb_we_i              : in  std_logic;
      wb_stb_i             : in  std_logic;
      wb_ack_o             : out std_logic;
      wb_dat_o             : out std_logic_vector(31 downto 0);
      -- Core to slave register interface signals
      wr_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
      rd_stb               : out std_logic_vector(2**addr_bits-1 downto 0);
      wb_reg_init_core     : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
      wb_reg_i_core        : in  std_logic_vector((2**addr_bits*32)-1 downto 0);
      wb_reg_o_core        : out std_logic_vector((2**addr_bits*32)-1 downto 0)
    );
  end component;

  constant addr_range         : integer := 2**addr_bits;

  subtype wb_reg_width is std_logic_vector(31 downto 0);
  type wb_reg_t is array (addr_range-1 downto 0) of wb_reg_width;
  constant WB_REG_ZEROS       : wb_reg_width := (others => '0');

  signal wr_stb               : std_logic_vector(addr_range-1 downto 0);
  signal rd_stb               : std_logic_vector(addr_range-1 downto 0);
  signal wb_reg_init          : wb_reg_t := (others => WB_REG_ZEROS);
  signal wb_reg_i             : wb_reg_t;
  signal wb_reg_o             : wb_reg_t;
  signal wb_reg_i_slv         : std_logic_vector((addr_range*32)-1 downto 0);
  signal wb_reg_o_slv         : std_logic_vector((addr_range*32)-1 downto 0);
  signal wb_reg_init_slv      : std_logic_vector((addr_range*32)-1 downto 0);

  begin

  -- Form incoming and outgoing data array
  process (wb_reg_i, wb_reg_i_slv, wb_reg_init)
  begin
    for i in 1 to addr_range loop
      wb_reg_o_slv((i*32)-1 downto (i-1)*32) <= wb_reg_i(i-1);
      wb_reg_init_slv((i*32)-1 downto (i-1)*32) <= wb_reg_init(i-1);
      wb_reg_o(i-1) <= wb_reg_i_slv((i*32)-1 downto (i-1)*32);
    end loop;
  end process;

  inst_core: ii_regs_core
    generic map (
      addr_bits            => addr_bits,
      offset               => offset
    )
    port map(
      wb_rst_i             => wb_rst_i,
      wb_clk_i             => wb_clk_i,
      wb_adr_i             => wb_adr_i,
      wb_dat_i             => wb_dat_i,
      wb_we_i              => wb_we_i,
      wb_stb_i             => wb_stb_i,
      wb_ack_o             => wb_ack_o,
      wb_dat_o             => wb_dat_o,
      wr_stb               => wr_stb,
      rd_stb               => rd_stb,
      wb_reg_init_core     => wb_reg_init_slv,
      wb_reg_i_core        => wb_reg_o_slv,
      wb_reg_o_core        => wb_reg_i_slv
    );

  -- ************************************************************************
  -- All the assignments below this line can be modified according to the
  -- required register map.

  -- register map:
  -- 1        : test settings (interval/enable)
  -- 15       : stream_enable
  -- 16 to 23 : phase_inc
  -- 24 to 31 : kernel_len
  -- 48 to 55 (even) : kernel_addr
  -- 48 to 55 (odd) : kernel write/read data
  -- 56 to 62 : threshold
  -- 63 record length in samples

  test_settings  <= wb_reg_o(1);
  wb_reg_i(63)   <= wb_reg_o(63);
  wb_reg_init(0) <= (others => '0');

  -- mapping of streams to stream_enable reg:
  -- 0     : raw
  -- 1-15  : demod
  -- 16-31 : results
  stream_enable   <= wb_reg_o(15);
  wb_reg_init(15) <= X"ffffffff";
  wb_reg_i(15)    <= wb_reg_o(15);

  gen_out_params : for i in 0 to num_vita_streams-1 generate
    --------------------------------------------------------------------------
    wb_reg_i(32+i)           <= wb_reg_o(32+i);
    --------------------------------------------------------------------------
  end generate;

  record_length             <= wb_reg_o(63)(15 downto 0);
  wb_reg_i(63)(15 downto 0) <= wb_reg_o(63)(15 downto 0);

  gen_demod_regs : for i in 0 to NUM_DEMOD_CH-1 generate
    phase_inc(i)                <= wb_reg_o(16+i)(23 downto 0);
    wb_reg_i(16+i)(23 downto 0) <= wb_reg_o(16+i)(23 downto 0);
    wb_reg_init(16+i)           <= x"00000000";

    kernel_len(i)               <= wb_reg_o(24+i)(KERNEL_ADDR_WIDTH-1 downto 0);
    wb_reg_i(24+i)(15 downto 0) <= wb_reg_o(24+i)(15 downto 0);

    kernel_addr(i) <= wb_reg_o(48+2*i)(KERNEL_ADDR_WIDTH-1 downto 0);
    wb_reg_i(48+2*i) <= wb_reg_o(48+2*i);
    kernel_wr_data(i) <= wb_reg_o(48+2*i+1);
    wb_reg_i(48+2*i+1) <= kernel_rd_data(i);

    -- Use write strobe from data to write to kernel memory
    kernel_we(i) <= wr_stb(48+2*i+1);

    threshold(i)    <= wb_reg_o(56+i);
    wb_reg_i(56+i)  <= wb_reg_o(56+i);

  end generate;

end arch;
