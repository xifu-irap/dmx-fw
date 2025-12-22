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
--!   @file                   hk_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                HouseKeeping model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity hk_model is generic (
         g_HK_MUX_TPS         : time   := c_HK_MUX_TPS_DEF                                                    --! HouseKeeping: Multiplexer, time Data Propagation switch in to out
   ); port (
         i_hk_mux             : in     std_logic_vector(c_HK_MUX_S-1 downto 0)                              ; --! HouseKeeping: Multiplexer
         i_hk_mux_ena_n       : in     std_logic                                                            ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_hk_spi_mosi        : in     std_logic                                                            ; --! HouseKeeping: SPI Master Output Slave Input
         i_hk_spi_sclk        : in     std_logic                                                            ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         i_hk_spi_cs_n        : in     std_logic                                                            ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk_spi_miso        : out    std_logic                                                              --! HouseKeeping: SPI Master Input Slave Output

   );
end entity hk_model;

architecture Behavioral of hk_model is
constant c_HK_ADC_RES         : real := c_HK_ADC_VREF_DEF / real(2**(c_HK_SPI_DATA_S))                      ; --! Housekeeping, ADC resolution (V)
constant c_HK_P1V8_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P1V8_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P1V8_ANA default value real format
constant c_HK_P2V5_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P2V5_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P2V5_ANA default value real format
constant c_HK_M2V5_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_M2V5_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_M2V5_ANA default value real format
constant c_HK_P3V3_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P3V3_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P3V3_ANA default value real format
constant c_HK_M5V0_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_M5V0_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_M5V0_ANA default value real format
constant c_HK_P1V2_DIG_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P1V2_DIG_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P1V2_DIG default value real format
constant c_HK_P2V5_DIG_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P2V5_DIG_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P2V5_DIG default value real format
constant c_HK_P2V5_AUX_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P2V5_AUX_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P2V5_AUX default value real format
constant c_HK_P3V3_DIG_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P3V3_DIG_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P3V3_DIG default value real format
constant c_HK_VREF_TMP_DEF_R  : real :=  real(to_integer(unsigned(c_HK_VREF_TMP_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_VREF_TMP default value real format
constant c_HK_VREF_R2R_DEF_R  : real :=  real(to_integer(unsigned(c_HK_VREF_R2R_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_VREF_R2R default value real format
constant c_HK_SPARE_DEF_R     : real :=  real(to_integer(unsigned(c_HK_SPARE_DEF)))    * c_HK_ADC_RES       ; --! Housekeeping, HK_SPARE    default value real format
constant c_HK_P5V0_ANA_DEF_R  : real :=  real(to_integer(unsigned(c_HK_P5V0_ANA_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_P5V0_ANA default value real format
constant c_HK_TEMP_AVE_DEF_R  : real :=  real(to_integer(unsigned(c_HK_TEMP_AVE_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_TEMP_AVE default value real format
constant c_HK_TEMP_MAX_DEF_R  : real :=  real(to_integer(unsigned(c_HK_TEMP_MAX_DEF))) * c_HK_ADC_RES       ; --! Housekeeping, HK_TEMP_MAX default value real format

signal   hk_mux               : real                                                                        ; --! Housekeeping multiplexer
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   HK Multiplexer
   -- ------------------------------------------------------------------------------------------------------
   I_hk_mux_model: entity work.cd74hc4051_model generic map (
         g_TIME_TPS           => g_HK_MUX_TPS           -- time                                               --! Time: Data Propagation switch in to out
   ) port map (
         i_s                  => i_hk_mux             , -- in     std_logic_vector(2 downto 0)              ; --! Address select
         i_e_n                => i_hk_mux_ena_n       , -- in     std_logic                                 ; --! Enable ('0' = Active, '1' = Inactive)

         i_a0                 => c_HK_M5V0_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 0
         i_a1                 => c_HK_P1V2_DIG_DEF_R  , -- in     real                                      ; --! Analog input channel 1
         i_a2                 => c_HK_P2V5_DIG_DEF_R  , -- in     real                                      ; --! Analog input channel 2
         i_a3                 => c_HK_P2V5_AUX_DEF_R  , -- in     real                                      ; --! Analog input channel 3
         i_a4                 => c_HK_P3V3_DIG_DEF_R  , -- in     real                                      ; --! Analog input channel 4
         i_a5                 => c_HK_VREF_TMP_DEF_R  , -- in     real                                      ; --! Analog input channel 5
         i_a6                 => c_HK_VREF_R2R_DEF_R  , -- in     real                                      ; --! Analog input channel 6
         i_a7                 => c_HK_SPARE_DEF_R     , -- in     real                                      ; --! Analog input channel 7

         o_com                => hk_mux                 -- out    real                                        --! Analog output
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   HK ADC
   -- ------------------------------------------------------------------------------------------------------
   I_hk_adc_model: entity work.adc128s102_model generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_VA                 => c_HK_ADC_VREF_DEF      -- real                                               --! Voltage reference (V)
   ) port map (
         i_in0                => c_HK_P1V8_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 0 ( 0.0 <= i_in0 < g_VA)
         i_in1                => c_HK_P2V5_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 1 ( 0.0 <= i_in1 < g_VA)
         i_in2                => c_HK_M2V5_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 2 ( 0.0 <= i_in2 < g_VA)
         i_in3                => c_HK_P3V3_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 3 ( 0.0 <= i_in3 < g_VA)
         i_in4                => hk_mux               , -- in     real                                      ; --! Analog input channel 4 ( 0.0 <= i_in4 < g_VA)
         i_in5                => c_HK_P5V0_ANA_DEF_R  , -- in     real                                      ; --! Analog input channel 5 ( 0.0 <= i_in5 < g_VA)
         i_in6                => c_HK_TEMP_AVE_DEF_R  , -- in     real                                      ; --! Analog input channel 6 ( 0.0 <= i_in6 < g_VA)
         i_in7                => c_HK_TEMP_MAX_DEF_R  , -- in     real                                      ; --! Analog input channel 7 ( 0.0 <= i_in7 < g_VA)

         i_din                => i_hk_spi_mosi        , -- in     std_logic                                 ; --! Serial Data in
         i_sclk               => i_hk_spi_sclk        , -- in     std_logic                                 ; --! Serial Clock
         i_cs_n               => i_hk_spi_cs_n        , -- in     std_logic                                 ; --! Chip Select ('0' = Active, '1' = Inactive)
         o_dout               => o_hk_spi_miso          -- out    std_logic                                   --! Serial Data out
   );

end architecture Behavioral;
