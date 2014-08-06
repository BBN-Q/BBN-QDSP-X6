-- Wishbone to SPI layer.  

-- Generalized port names on a ii_dac5682z_spi module
-- Since both the DAC and ADC are similar TI parts we can reuse the module 

--*   This component is an SPI port interface to TI DAC5682z chip.
--*   The DAC5682z chip is configured and monitored over this SPI port.
--*   Prior to opertion, the DAC5682z chip is initialized over this SPI port.
--*   The maximum clock rate to this serial port is 10 MHz and it is
--*   configured as a 3 pin interface.
--*   Each read/write operation is composed of 2 bytes: Instruction cycle
--*   and data transfer cycle. Data is transferred MSB first.
--*
--*
--*   @port srst            : input, synchronous active high reset
--*   @port sys_clk         : input, system clock
--*   @port spi_access_strb : input, trigger an SPI transaction
--*   @port spi_wdata       : input, DAC SPI write data
--*   @port spi_addr        : input, DAC register address
--*   @port spi_rd_wrn      : input, DAC SPI 1=read/0=write access
--*   @port spi_rdy         :output, SPI port is ready
--*   @port spi_rdata_valid :output, SPI read data is valid
--*   @port spi_rdata       :output, last SPI read data
--*   @port spi_sclk    :output, SPI clock
--*   @port spi_sdenb   :output, SPI enable
--*   @port spi_sdio    : inout, SPI input/output data
--*
--*      @author Innovative Integration
--*      @version 1.0
--*      @date Created 11/23/10
--*
--******************************************************************************
--/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity wishbone2spi is
  port (
    srst                 : in  std_logic;
    sys_clk              : in  std_logic;

    -- User interface
    spi_access_strb      : in  std_logic;
    spi_wdata            : in  std_logic_vector(7 downto 0);
    spi_addr             : in  std_logic_vector(4 downto 0);
    spi_rd_wrn           : in  std_logic;
    spi_rdy              : out std_logic;
    spi_rdata_valid      : out std_logic;
    spi_rdata            : out std_logic_vector(7 downto 0);

    -- spi PHY interface
    spi_sclk         : out std_logic;
    spi_sdenb        : out std_logic;
    spi_sdio         : inout std_logic
  );
end wishbone2spi;

architecture arch of wishbone2spi is

  type   spi_sm_type is (idle, load, command, write, read, extra_clk);
  signal spi_state            : spi_sm_type;
  signal spi_rd_wrn_latched   : std_logic;
  signal sdio_oe              : std_logic;
  signal sdenb                : std_logic;
  signal clk_div_cnt          : unsigned(4 downto 0);
  signal shift_cnt            : unsigned(4 downto 0);
  signal sclk                 : std_logic;
  signal spi_do_sreg          : std_logic_vector(15 downto 0);
  signal sdo                  : std_logic;
  signal spi_sdio_i_d         : std_logic;
  signal spi_di_sreg          : std_logic_vector(7 downto 0);
  signal spi_sdio_i           : std_logic;
  signal spi_sdio_o           : std_logic;
  signal sdio_oe_n            : std_logic;

begin

--------------------------------------------------------------------------------
-- SPI interface logic
--------------------------------------------------------------------------------
  -- SPI state machine
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_rdy            <= '0';
        spi_rdata_valid    <= '0';
        spi_rdata          <= (others => '0');
        spi_rd_wrn_latched <= '0';
        sdio_oe            <= '0';
        sdenb              <= '1';
        spi_state          <= idle;
      else
        spi_rdy <= '0';
        sdio_oe <= '0';
        sdenb   <= '1';
        case spi_state is
          ----------------------------------------------------------------------
          when idle =>
            if (spi_access_strb = '1') then
              spi_rd_wrn_latched  <= spi_rd_wrn;
              if (spi_rd_wrn = '1') then
                spi_rdata_valid <= '0';
              end if;
              spi_state <= load;
            else
              spi_rdy   <= '1';
              spi_state <= idle;
            end if;
          ----------------------------------------------------------------------
          when load =>
            sdio_oe   <= '1';
            sdenb     <= '0';
            spi_state <= command;
          ----------------------------------------------------------------------
          when command =>
            sdio_oe   <= '1';
            sdenb     <= '0';
            if (shift_cnt = "01000") then  -- command byte has been shifted out
              if (spi_rd_wrn_latched = '0') then
                spi_state <= write;
              else
                spi_state <= read;
              end if;
            else
              spi_state <= command;
            end if;
          ----------------------------------------------------------------------
          when write =>
            -- assert sdenb after sending the last bit
            if (shift_cnt = "10000" and clk_div_cnt = "01010") then
              spi_state <= extra_clk;
            else
              sdio_oe   <= '1';
              sdenb     <= '0';
              spi_state <= write;
            end if;
          ----------------------------------------------------------------------
          when read =>
            -- assert sdenb after receiving the last bit
            if (shift_cnt = "10000" and clk_div_cnt = "01010") then
              spi_rdata_valid <= '1';
              spi_rdata       <= spi_di_sreg;
              spi_state       <= extra_clk;
            else
              sdenb           <= '0';
              spi_state       <= read;
            end if;
          ----------------------------------------------------------------------
          when extra_clk =>  -- additional SPI clock cycle needed by the part
            if (shift_cnt = "10001" and clk_div_cnt = "01010") then
              spi_state <= idle;
            else
              spi_state <= extra_clk;
            end if;
          ----------------------------------------------------------------------
          when others =>
            spi_rdata_valid <= '0';
            spi_rdata       <= (others => '0');
            spi_state       <= idle;
          ----------------------------------------------------------------------
        end case;
      end if;
    end if;
  end process;

  -- Counters to generate the serial clock
  -- and count the number of shift operations
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or spi_state = idle) then
        clk_div_cnt <= (others => '0');
        shift_cnt   <= (others => '0');
      elsif (spi_state = load) then
        clk_div_cnt <= "01000";           -- make sure to satisfy ts(SDENB)
      else
        clk_div_cnt <= clk_div_cnt + 1;
        if (clk_div_cnt = "01111") then
          shift_cnt <= shift_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  sclk <= clk_div_cnt(4);

  -- data out shift register
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1') then
        spi_do_sreg <= (others => '0');
      elsif (spi_state = idle) then                  -- load data out
        spi_do_sreg <= (spi_rd_wrn & "00" & spi_addr & spi_wdata);
      elsif (clk_div_cnt = "00111") then             -- shift out
        spi_do_sreg <= (spi_do_sreg(spi_do_sreg'high-1 downto 0) & '0');
      end if;
    end if;
  end process;

  sdo <= spi_do_sreg(spi_do_sreg'high);

  -- Register the input to ease timing closure and shift data in
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      spi_sdio_i_d <= spi_sdio_i;
      if (spi_state = read and clk_div_cnt = "01111") then
        spi_di_sreg <= spi_di_sreg(spi_di_sreg'high-1 downto 0) & spi_sdio_i_d;
      end if;
    end if;
  end process;
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Instantiate an IOBUF to handle tristating the bidirectional spi_sdio port
-----------------------------------------------------------------------------
  sdio_IOBUF_inst : IOBUF
    generic map (
      DRIVE                => 12,
      IBUF_DELAY_VALUE     => "0",
      IFD_DELAY_VALUE      => "AUTO",
      IOSTANDARD           => "DEFAULT",
      SLEW                 => "SLOW"
    )
    port map (
      O                    => spi_sdio_i,
      IO                   => spi_sdio,
      I                    => spi_sdio_o,
      T                    => sdio_oe_n
    );
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Interface with the selected DAC
-----------------------------------------------------------------------------
  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      if (srst = '1' or (spi_state = idle)) then
        spi_sdio_o    <= '0';
        sdio_oe_n     <= '1';
        spi_sclk  <= '0';
        spi_sdenb <= '1';
      else
        spi_sdio_o    <= sdo;
        sdio_oe_n     <= not sdio_oe;
        spi_sclk  <= sclk;
        spi_sdenb <= sdenb;
      end if;
    end if;
  end process;
-----------------------------------------------------------------------------

end arch;
