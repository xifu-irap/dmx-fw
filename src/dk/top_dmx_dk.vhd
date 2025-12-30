-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   slaurent@nanoxplore.com
--!   @file                   top_dmx_dk.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level Devkit Model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_mod.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity top_dmx_dk is port (
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         o_clk_science_01     : out    std_logic                                                            ; --! Science Data: Clock channel 0/1
         o_clk_science_23     : out    std_logic                                                            ; --! Science Data: Clock channel 2/3

         i_ras_data_valid_n   : in     std_logic                                                            ; --! RAS Data valid ('0' = Yes, '1' = No)

         o_science_ctrl_01    : out    std_logic                                                            ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    : out    std_logic                                                            ; --! Science Data: Control channel 2/3
         o_science_data       : out    t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB-1 downto 0)              ; --! Science Data: Serial Data
         o_science_data_c2_0  : out    std_logic                                                            ; --! Science Data: Serial Data column 2 bit 0 redundancy

         i_ep_spi_sel         : in     std_logic                                                            ; --! EP: SPI select ('0' = Channel 0, '1' = Channel 1)
         i_ep_spi_mosi        : in     std_logic_vector(1 downto 0)                                         ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        : out    std_logic_vector(1 downto 0)                                         ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        : in     std_logic_vector(1 downto 0)                                         ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        : in     std_logic_vector(1 downto 0)                                           --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

    );
end entity top_dmx_dk;

architecture RTL of top_dmx_dk is
constant c_BRD_REF            : std_logic_vector(  c_BRD_REF_S-1 downto 0) := (others => c_LOW_LEV)         ; --! Board reference
constant c_BRD_MODEL          : std_logic_vector(c_BRD_MODEL_S-1 downto 0) := (others => c_HGH_LEV)         ; --! Board model

constant c_SYNC_CNT_NB_VAL    : integer:= c_MUX_FACT * c_PIXEL_ADC_NB_CYC / 2                               ; --! Sync counter: number of value
constant c_SYNC_CNT_MAX_VAL   : integer:= c_SYNC_CNT_NB_VAL-2                                               ; --! Sync counter: maximal value
constant c_SYNC_CNT_S         : integer:= log2_ceil(c_SYNC_CNT_MAX_VAL + 1) + 1                             ; --! Sync counter: size bus (signed)

constant c_DAC_MDL_POINT_V    : std_logic_vector(c_SQM_DAC_DATA_S-1 downto 0) :=
                                std_logic_vector(to_signed(2**(c_SQM_DAC_DATA_S-1), c_SQM_DAC_DATA_S))      ; --! DAC middle point

constant c_HK_SPI_DTA_WD_NB_S : integer :=  1                                                               ; --! HouseKeeping: SPI Data word number size

constant c_ADD0               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(0, c_HK_SPI_ADD_S))                            ; --! Address 0
constant c_ADD1               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(1, c_HK_SPI_ADD_S))                            ; --! Address 1
constant c_ADD2               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(2, c_HK_SPI_ADD_S))                            ; --! Address 2
constant c_ADD3               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(3, c_HK_SPI_ADD_S))                            ; --! Address 3
constant c_ADD4               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(4, c_HK_SPI_ADD_S))                            ; --! Address 4
constant c_ADD5               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(5, c_HK_SPI_ADD_S))                            ; --! Address 5
constant c_ADD6               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(6, c_HK_SPI_ADD_S))                            ; --! Address 6
constant c_ADD7               : std_logic_vector(c_HK_SPI_ADD_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(7, c_HK_SPI_ADD_S))                            ; --! Address 7

constant c_HK_P1V8_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1170, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P1V8_ANA value
constant c_HK_P2V5_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned(  878, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P2V5_ANA value
constant c_HK_M2V5_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1463, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_M2V5_ANA value
constant c_HK_P3V3_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned(  585, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P3V3_ANA value
constant c_HK_M5V0_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1755, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_M5V0_ANA value
constant c_HK_P1V2_DIG        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2633, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P1V2_DIG value
constant c_HK_P2V5_DIG        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2340, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P2V5_DIG value
constant c_HK_P2V5_AUX        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3510, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P2V5_AUX value
constant c_HK_P3V3_DIG        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2048, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P3V3_DIG value
constant c_HK_VREF_TMP        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3803, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_VREF_TMP value
constant c_HK_VREF_R2R        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4000, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_VREF_R2R value
constant c_HK_SPARE           : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1261, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_SPARE    value
constant c_HK_P5V0_ANA        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned(  293, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_P5V0_ANA value
constant c_HK_TEMP_AVE        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2925, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_TEMP_AVE value
constant c_HK_TEMP_MAX        : std_logic_vector(c_HK_SPI_DATA_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3218, c_HK_SPI_DATA_S))                       ; --! Housekeeping, HK_TEMP_MAX value

signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   rst_sqm_adc_dac      : std_logic                                                                   ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
signal   clk                  : std_logic                                                                   ; --! System Clock
signal   clk_sqm_adc_dac      : std_logic                                                                   ; --! SQUID ADC/DAC internal Clock

signal   ep_spi_sel_r         : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! EP: SPI select ('0' = Channel 0, '1' = Channel 1)
signal   ep_spi_mosi_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(1 downto 0)                                 ; --! EP: SPI Master Input Slave Output (MSB first)
signal   ep_spi_sclk_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(1 downto 0)                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
signal   ep_spi_cs_n_r        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(1 downto 0)                                 ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sync_cnt             : std_logic_vector(c_SYNC_CNT_S-1 downto 0)                                   ; --! Pixel sequence synchronization counter
signal   sync                 : std_logic                                                                   ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

signal   sqm_dac_data         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DAC_DATA_S-1 downto 0)                     ; --! SQUID MUX DAC: Data buses
signal   sqm_adc_data         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S-1 downto 0)                     ; --! SQUID MUX ADC: Data buses

signal   hk_spi_data_tx_wd    : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HouseKeeping: SPI Transmit  data word
signal   hk_spi_data_rx_wd    : std_logic_vector(c_HK_SPI_SER_WD_S-1 downto 0)                              ; --! HouseKeeping: SPI Receipted data word
signal   hk_spi_add           : std_logic_vector(   c_HK_SPI_ADD_S-1 downto 0)                              ; --! HouseKeeping: SPI Address

signal   hk_mux               : std_logic_vector(      c_HK_MUX_S-1 downto 0)                               ; --! HouseKeeping: Multiplexer
signal   hk_mux_ena_n         : std_logic                                                                   ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)
signal   hk_mux_data          : std_logic_vector( c_HK_SPI_DATA_S-1 downto 0)                               ; --! HouseKeeping: Data Multiplexer out
signal   hk_data              : std_logic_vector( c_HK_SPI_DATA_S-1 downto 0)                               ; --! HouseKeeping: Data

signal   hk_spi_miso          : std_logic                                                                   ; --! HouseKeeping: SPI Master Input Slave Output
signal   hk_spi_mosi          : std_logic                                                                   ; --! HouseKeeping: SPI Master Output Slave Input
signal   hk_spi_sclk          : std_logic                                                                   ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
signal   hk_spi_cs_n          : std_logic                                                                   ; --! HouseKeeping: SPI Chip Select ('1' = Active, '1' = Inactive)

signal   ep_spi_mosi          : std_logic                                                                   ; --! EP: SPI Master Input Slave Output (MSB first)
signal   ep_spi_miso          : std_logic                                                                   ; --! EP: SPI Master Output Slave Input (MSB first)
signal   ep_spi_sclk          : std_logic                                                                   ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
signal   ep_spi_cs_n          : std_logic                                                                   ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   science_data         : t_slv_arr(0 to c_NB_COL  )(c_SC_DATA_SER_NB-1 downto 0)                     ; --! Science Data: Serial Data

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         ep_spi_sel_r   <= (others => c_LOW_LEV);
         ep_spi_mosi_r  <= (others => (others => c_LOW_LEV));
         ep_spi_sclk_r  <= (others => (others => c_LOW_LEV));
         ep_spi_cs_n_r  <= (others => (others => c_I_SPI_CS_N_DEF));

      elsif rising_edge(clk) then
         ep_spi_sel_r   <= ep_spi_sel_r(ep_spi_sel_r'high-1 downto 0) & i_ep_spi_sel;
         ep_spi_mosi_r  <= i_ep_spi_mosi & ep_spi_mosi_r(0 to ep_spi_mosi_r'high-1);
         ep_spi_sclk_r  <= i_ep_spi_sclk & ep_spi_sclk_r(0 to ep_spi_sclk_r'high-1);
         ep_spi_cs_n_r  <= i_ep_spi_cs_n & ep_spi_cs_n_r(0 to ep_spi_cs_n_r'high-1);

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   -- ------------------------------------------------------------------------------------------------------
   P_sync_cnt : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         sync_cnt   <= c_MINUSONE(sync_cnt'range);

      elsif rising_edge(clk) then
         if sync_cnt(sync_cnt'high) = c_HGH_LEV then
            sync_cnt <= std_logic_vector(to_unsigned(c_SYNC_CNT_MAX_VAL, sync_cnt'length));

         else
            sync_cnt <= std_logic_vector(signed(sync_cnt) - 1);

         end if;
      end if;

   end process P_sync_cnt;

   sync     <= sync_cnt(sync_cnt'high-1);

   -- ------------------------------------------------------------------------------------------------------
   --!   Loop SQUID MUX DAC on ADC
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      -- Case SQUID MUX data not complemented
      G_sqm_dta_comp_n: if c_SQM_DATA_COMP(k) = c_LOW_LEV generate
      begin
         sqm_adc_data(k) <= not(sqm_dac_data(k)(sqm_dac_data(k)'high)) & sqm_dac_data(k)(sqm_dac_data(k)'high-1 downto 0);

      end generate G_sqm_dta_comp_n;

      -- Case SQUID MUX data complemented
      G_sqm_dta_comp: if c_SQM_DATA_COMP(k) = c_HGH_LEV generate
      begin
         sqm_adc_data(k) <= std_logic_vector(signed(c_DAC_MDL_POINT_V) - signed(sqm_dac_data(k)));

      end generate G_sqm_dta_comp;

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   HK Multiplexer
   -- ------------------------------------------------------------------------------------------------------
   P_hk_mux_data : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         hk_mux_data <= c_ZERO(hk_mux_data'range);

      elsif rising_edge(clk) then
         if hk_mux_ena_n = c_HGH_LEV then
            hk_mux_data <= c_ZERO(hk_mux_data'range);

         else
            case hk_mux is
               when c_ADD0 =>
                  hk_mux_data <= c_HK_M5V0_ANA;

               when c_ADD1 =>
                  hk_mux_data <= c_HK_P1V2_DIG;

               when c_ADD2 =>
                  hk_mux_data <= c_HK_P2V5_DIG;

               when c_ADD3 =>
                  hk_mux_data <= c_HK_P2V5_AUX;

               when c_ADD4 =>
                  hk_mux_data <= c_HK_P3V3_DIG;

               when c_ADD5 =>
                  hk_mux_data <= c_HK_VREF_TMP;

               when c_ADD6 =>
                  hk_mux_data <= c_HK_VREF_R2R;

               when c_ADD7 =>
                  hk_mux_data <= c_HK_SPARE;

               when others =>
                  hk_mux_data <= c_ZERO(hk_mux_data'range);

            end case;

         end if;

      end if;

   end process P_hk_mux_data;

   -- ------------------------------------------------------------------------------------------------------
   --!   HK SPI
   -- ------------------------------------------------------------------------------------------------------
   hk_spi_add  <= hk_spi_data_rx_wd(c_HK_SPI_ADD_S+c_HK_SPI_ADD_POS_LSB-1 downto c_HK_SPI_ADD_POS_LSB);

   --! HK Data
   P_hk_data : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         hk_data <= c_ZERO(hk_data'range);

      elsif rising_edge(clk) then
         case hk_spi_add is
            when c_ADD0 =>
               hk_data <= c_HK_P1V8_ANA;

            when c_ADD1 =>
               hk_data <= c_HK_P2V5_ANA;

            when c_ADD2 =>
               hk_data <= c_HK_M2V5_ANA;

            when c_ADD3 =>
               hk_data <= c_HK_P3V3_ANA;

            when c_ADD4 =>
               hk_data <= hk_mux_data;

            when c_ADD5 =>
               hk_data <= c_HK_P5V0_ANA;

            when c_ADD6 =>
               hk_data <= c_HK_TEMP_AVE;

            when others =>
               hk_data <= c_HK_TEMP_MAX;

         end case;

      end if;

   end process P_hk_data;

   hk_spi_data_tx_wd <= std_logic_vector(resize(unsigned(hk_data), hk_spi_data_tx_wd'length));

   I_hk_spi_slave: entity work.spi_slave generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_CPOL               => c_HK_SPI_CPOL        , -- std_logic                                        ; --! Clock polarity
         g_CPHA               => c_HK_SPI_CPHA        , -- std_logic                                        ; --! Clock phase
         g_DTA_TX_WD_S        => c_HK_SPI_SER_WD_S    , -- integer                                          ; --! Data word to transmit bus size
         g_DTA_TX_WD_NB_S     => c_HK_SPI_DTA_WD_NB_S , -- integer                                          ; --! Data word to transmit number size
         g_DTA_RX_WD_S        => c_HK_SPI_SER_WD_S    , -- integer                                          ; --! Receipted data word bus size
         g_DTA_RX_WD_NB_S     => c_HK_SPI_DTA_WD_NB_S   -- integer                                            --! Receipted data word number size
   ) port map (
         i_rst                => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! Clock

         i_data_tx_wd         => hk_spi_data_tx_wd    , -- in     slv(g_DTA_TX_WD_S   -1 downto 0)          ; --! Data word to transmit (stall on MSB)
         o_data_tx_wd_nb      => open                 , -- out    slv(g_DTA_TX_WD_NB_S-1 downto 0)          ; --! Data word to transmit number

         o_data_rx_wd         => hk_spi_data_rx_wd    , -- out    slv(g_DTA_RX_WD_S   -1 downto 0)          ; --! Receipted data word (stall on LSB)
         o_data_rx_wd_nb      => open                 , -- out    slv(g_DTA_RX_WD_NB_S-1 downto 0)          ; --! Receipted data word number
         o_data_rx_wd_lg      => open                 , -- out    slv(log2_ceil(g_DTA_RX_WD_S)-1 downto 0)  ; --! Receipted data word length minus 1
         o_data_rx_wd_rdy     => open                 , -- out    std_logic                                 ; --! Receipted data word ready ('0' = Not ready, '1' = Ready)

         o_spi_wd_end         => open                 , -- out    std_logic                                 ; --! SPI word end ('0' = Not end, '1' = End)

         o_miso               => hk_spi_miso          , -- out    std_logic                                 ; --! SPI Master Input Slave Output
         i_mosi               => hk_spi_mosi          , -- in     std_logic                                 ; --! SPI Master Output Slave Input
         i_sclk               => hk_spi_sclk          , -- in     std_logic                                 ; --! SPI Serial Clock
         i_cs_n               => hk_spi_cs_n            -- in     std_logic                                   --! SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP SPI
   -- ------------------------------------------------------------------------------------------------------
   P_ep_spi : process (rst, clk)
   begin

      if rst = c_RST_LEV_ACT then
         ep_spi_mosi    <= c_I_SPI_DATA_DEF;
         ep_spi_sclk    <= c_I_SPI_SCLK_DEF;
         ep_spi_cs_n    <= c_I_SPI_CS_N_DEF;

         o_ep_spi_miso  <= (others => c_LOW_LEV);

      elsif rising_edge(clk) then
         if ep_spi_sel_r(ep_spi_sel_r'high) = c_HGH_LEV then
            ep_spi_mosi <= ep_spi_mosi_r(ep_spi_mosi_r'high)(ep_spi_mosi_r'high);
            ep_spi_sclk <= ep_spi_sclk_r(ep_spi_sclk_r'high)(ep_spi_sclk_r'high);
            ep_spi_cs_n <= ep_spi_cs_n_r(ep_spi_cs_n_r'high)(ep_spi_cs_n_r'high);

         else
            ep_spi_mosi <= ep_spi_mosi_r(ep_spi_mosi_r'high)(ep_spi_mosi_r'low);
            ep_spi_sclk <= ep_spi_sclk_r(ep_spi_sclk_r'high)(ep_spi_sclk_r'low);
            ep_spi_cs_n <= ep_spi_cs_n_r(ep_spi_cs_n_r'high)(ep_spi_cs_n_r'low);

         end if;

         o_ep_spi_miso <= (others => ep_spi_miso);

      end if;

   end process P_ep_spi;

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX: Top level
   -- ------------------------------------------------------------------------------------------------------
   I_top_dmx_dm_clk: entity work.top_dmx_dm_clk port map (
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock

         o_rst                => rst                  , -- out    std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- out    std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- out    std_logic                                 ; --! SQUID ADC/DAC internal Clock

         o_clk_sqm_adc        => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Clock
         o_clk_sqm_dac        => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Clock
         o_clk_science_01     => o_clk_science_01     , -- out    std_logic                                 ; --! Science Data: Clock channel 0/1
         o_clk_science_23     => o_clk_science_23     , -- out    std_logic                                 ; --! Science Data: Clock channel 2/3

         i_brd_ref            => c_BRD_REF            , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => c_BRD_MODEL          , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => sync                 , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_ras_data_valid     => not(i_ras_data_valid_n), -- in   std_logic                                 ; --! RAS Data valid ('0' = No, '1' = Yes)

         i_sqm_adc_data       => sqm_adc_data         , -- in     t_slv_arr c_NB_COL c_SQM_ADC_DATA_S       ; --! SQUID MUX ADC: Data
         i_sqm_adc_oor        => (others => c_LOW_LEV), -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)
         o_sqm_dac_data       => sqm_dac_data         , -- out    t_slv_arr c_NB_COL c_SQM_DAC_DATA_S       ; --! SQUID MUX DAC: Data

         o_science_ctrl_01    => o_science_ctrl_01    , -- out    std_logic                                 ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    => o_science_ctrl_23    , -- out    std_logic                                 ; --! Science Data: Control channel 2/3
         o_science_data       => science_data         , -- out    t_slv_arr c_NB_COL c_SC_DATA_SER_NB       ; --! Science Data: Serial Data

         i_hk_spi_miso        => hk_spi_miso          , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Input Slave Output
         o_hk_spi_mosi        => hk_spi_mosi          , -- out    std_logic                                 ; --! HouseKeeping: SPI Master Output Slave Input
         o_hk_spi_sclk        => hk_spi_sclk          , -- out    std_logic                                 ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         o_hk_spi_cs_n        => hk_spi_cs_n          , -- out    std_logic                                 ; --! HouseKeeping: SPI Chip Select ('1' = Active, '1' = Inactive)
         o_hk_mux             => hk_mux               , -- out    std_logic_vector(c_HK_MUX_S-1 downto 0)   ; --! HouseKeeping: Multiplexer
         o_hk_mux_ena_n       => hk_mux_ena_n         , -- out    std_logic                                 ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        => ep_spi_mosi          , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        => ep_spi_miso          , -- out    std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        => ep_spi_sclk          , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        => ep_spi_cs_n          , -- in     std_logic                                 ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_spi_sdio   => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_pwdn       => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         o_sqa_dac_data       => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    => open                 , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sqa_dac_mux        => open                 , -- out    t_slv_arr c_NB_COL c_SQA_DAC_MUX_S        ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_mx_en_n    => open                   -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

   );

   o_science_data      <= science_data(o_science_data'range);
   o_science_data_c2_0 <= science_data(c_COL2)(c_ZERO_INT);

end architecture RTL;
