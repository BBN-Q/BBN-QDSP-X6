library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package VitaFramer_pkg is

  component axis_adapter
    generic (
      INPUT_DATA_WIDTH : natural := 8;
      INPUT_KEEP_WIDTH : natural := 1;
      OUTPUT_DATA_WIDTH : natural := 8;
      OUTPUT_KEEP_WIDTH : natural := 1
    );
    port (
      clk : in std_logic;
      rst : in std_logic;

      --AXIS input
      input_axis_tdata  : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
      input_axis_tkeep  : in std_logic_vector(INPUT_KEEP_WIDTH-1 downto 0);
      input_axis_tvalid : in std_logic;
      input_axis_tready : out std_logic;
      input_axis_tlast  : in std_logic;
      input_axis_tuser  : in std_logic;

      --AXIS input
      output_axis_tdata  : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
      output_axis_tkeep  : out std_logic_vector(OUTPUT_KEEP_WIDTH-1 downto 0);
      output_axis_tvalid : out std_logic;
      output_axis_tready : in std_logic;
      output_axis_tlast  : out std_logic;
      output_axis_tuser  : out std_logic
    );
  end component;

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



end VitaFramer_pkg;
