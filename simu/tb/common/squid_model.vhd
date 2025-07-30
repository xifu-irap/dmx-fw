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
--!   @file                   squid_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX/SQUID AMP model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity squid_model is generic (
         g_SQM_ADC_VREF       : real      := c_SQM_ADC_VREF_DEF                                             ; --! SQUID MUX ADC: Voltage reference (Volt)
         g_SQM_DAC_VREF       : real      := c_SQM_DAC_VREF_DEF                                             ; --! SQUID MUX DAC: Voltage reference (Volt)
         g_SQA_DAC_VREF       : real      := c_SQA_DAC_VREF_DEF                                             ; --! SQUID AMP DAC: Voltage reference (Volt)
         g_SQA_DAC_TS         : time      := c_SQA_DAC_TS_DEF                                               ; --! SQUID AMP DAC: Output Voltage Settling time
         g_SQA_MUX_TPLH       : time      := c_SQA_MUX_TPLH_DEF                                             ; --! SQUID AMP MUX: Propagation delay switch in to out
         g_CLK_ADC_PER        : time      := c_CLK_ADC_PER_DEF                                              ; --! SQUID MUX ADC: Clock period
         g_TIM_ADC_TPD        : time      := c_TIM_ADC_TPD_DEF                                              ; --! SQUID MUX ADC: Time, Data Propagation Delay
         g_SQM_VOLT_DEL       : time      := c_SQM_VOLT_DEL_DEF                                             ; --! SQUID MUX voltage delay
         g_SQA_VOLT_DEL       : time      := c_SQA_VOLT_DEL_DEF                                             ; --! SQUID AMP voltage delay
         g_SQERR_VOLT_DEL     : time      := c_SQERR_VOLT_DEL_DEF                                             --! SQUID Error voltage delay
   ); port (
         i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_clk_sqm_adc        : in     std_logic                                                            ; --! SQUID MUX ADC: Clock
         i_sqm_adc_pwdn       : in     std_logic                                                            ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_adc_spi_sdio   : out    std_logic                                                            ; --! SQUID MUX ADC: SPI Serial Data In Out
         i_sqm_adc_spi_sclk   : in     std_logic                                                            ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')

         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input
         o_sqm_adc_ana        : out    real                                                                 ; --! SQUID MUX ADC: Analog
         o_sqm_adc_data       : out    std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data
         o_sqm_adc_oor        : out    std_logic                                                            ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

         i_sqm_data_comp      : in     std_logic                                                            ; --! SQUID MUX data complemented ('0' = No, '1' = Yes)
         i_clk_sqm_dac        : in     std_logic                                                            ; --! SQUID MUX DAC: Clock
         i_sqm_dac_data       : in     std_logic_vector(c_SQM_DAC_DATA_S-1 downto 0)                        ; --! SQUID MUX DAC: Data
         i_sqm_dac_sleep      : in     std_logic                                                            ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         i_pls_shp_fc         : in     integer                                                              ; --! Pulse shaping cut frequency (Hz)
         o_err_num_pls_shp    : out    integer                                                              ; --! Pulse shaping error number

         i_sqa_dac_data       : in     std_logic                                                            ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       : in     std_logic                                                            ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sqa_dac_mux        : in     std_logic_vector( c_SQA_DAC_MUX_S-1 downto 0)                        ; --! SQUID AMP DAC: Multiplexer
         i_sqa_dac_mx_en_n    : in     std_logic                                                            ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_squid_err_volt     : in     real                                                                 ; --! SQUID Error voltage (Volt)
         o_sqm_dac_delta_volt : out    real                                                                 ; --! SQUID MUX voltage (Vin+ - Vin-) (Volt)
         o_sqa_volt           : out    real                                                                   --! SQUID AMP voltage (Volt)
   );
end entity squid_model;

architecture Behavioral of squid_model is
signal   squid_err_volt       : real                                                                        ; --! SQUID Error voltage (Volt)
signal   sqm_dac_out          : real                                                                        ; --! SQUID MUX DAC output
signal   sqm_dac_delta_volt   : real                                                                        ; --! SQUID MUX voltage (Vin+ - Vin-) (Volt)
signal   sqa_volt             : real                                                                        ; --! SQUID AMP voltage (Volt)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX DAC model management
   -- ------------------------------------------------------------------------------------------------------
   I_sqm_dac_model: entity work.dac5675a_model generic map (
         g_VREF               => g_SQM_DAC_VREF         -- real                                               --! Voltage reference (Volt)
   ) port map (
         i_clk                => i_clk_sqm_dac        , -- in     std_logic                                 ; --! Clock
         i_sleep              => i_sqm_dac_sleep      , -- in     std_logic                                 ; --! Sleep ('0' = Inactive, '1' = Active)
         i_d                  => i_sqm_dac_data       , -- in     std_logic_vector(13 downto 0)             ; --! Data
         o_delta_vout         => sqm_dac_out            -- out    real                                        --! Analog voltage (-g_VREF <= Vout1 - Vout2 < g_VREF)
   );

   sqm_dac_delta_volt   <= sqm_dac_out when i_sqm_data_comp = c_LOW_LEV else -sqm_dac_out;
   o_sqm_dac_delta_volt <= transport sqm_dac_delta_volt after g_SQM_VOLT_DEL when now > g_SQM_VOLT_DEL else c_ZERO_REAL;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse shaping check
   -- ------------------------------------------------------------------------------------------------------
   I_pulse_shaping_check: entity work.pulse_shaping_check port map (
         i_arst               => i_arst               , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sqm_dac        => i_clk_sqm_dac        , -- in     std_logic                                 ; --! SQUID MUX DAC: Clock
         i_sync               => i_sync               , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_sqm_dac_ana        => sqm_dac_delta_volt   , -- in     real                                      ; --! SQUID MUX DAC: Analog
         i_pls_shp_fc         => i_pls_shp_fc         , -- in     integer                                   ; --! Pulse shaping cut frequency (Hz)

         o_err_num_pls_shp    => o_err_num_pls_shp      -- out    integer                                     --! Pulse shaping error number
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP DAC model management
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_dac_model: entity work.sqa_dac_model generic map (
         g_SQA_DAC_VREF       => g_SQA_DAC_VREF       , -- real                                             ; --! SQUID AMP DAC: Voltage reference (Volt)
         g_SQA_DAC_TS         => g_SQA_DAC_TS         , -- time                                             ; --! SQUID AMP DAC: Output Voltage Settling time
         g_SQA_MUX_TPLH       => g_SQA_MUX_TPLH         -- time                                               --! SQUID AMP MUX: Propagation delay switch in to out
   ) port map (
         i_sqa_dac_data       => i_sqa_dac_data       , -- in     std_logic                                 ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       => i_sqa_dac_sclk       , -- in     std_logic                                 ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    => i_sqa_dac_snc_l_n    , -- in     std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    => i_sqa_dac_snc_o_n    , -- in     std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sqa_dac_mux        => i_sqa_dac_mux        , -- in     slv(c_SQA_DAC_MUX_S-1 downto 0)           ; --! SQUID AMP DAC: Multiplexer
         i_sqa_dac_mx_en_n    => i_sqa_dac_mx_en_n    , -- in     std_logic                                 ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_sqa_vout           => sqa_volt               -- out    real                                        --! Analog voltage (0.0 <= o_sqa_vout < c_SQA_COEF * g_SQA_DAC_VREF,
                                                                                                              --!  with c_SQA_COEF = (2^(c_SQA_DAC_MUX_S+1)-1)/(c_SQA_DAC_COEF_DIV*2^c_SQA_DAC_MUX_S))
   );

   o_sqa_volt <= transport sqa_volt after g_SQA_VOLT_DEL when now > g_SQA_VOLT_DEL else c_ZERO_REAL;

   -- ------------------------------------------------------------------------------------------------------
   --!   Switch ADC Voltage input
   -- ------------------------------------------------------------------------------------------------------
   squid_err_volt <= transport i_squid_err_volt after g_SQERR_VOLT_DEL when now > g_SQERR_VOLT_DEL else c_ZERO_REAL;

   o_sqm_adc_ana <= sqa_volt            when i_sw_adc_vin = c_SW_ADC_VIN_ST_SQA else
                    sqm_dac_delta_volt  when i_sw_adc_vin = c_SW_ADC_VIN_ST_SQM else
                    squid_err_volt;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC model management
   -- ------------------------------------------------------------------------------------------------------
   I_adc_model: entity work.adc_ad9254_model generic map (
         g_VREF               => g_SQM_ADC_VREF       , -- real                                             ; --! Voltage reference (Volt)
         g_CLK_PER            => g_CLK_ADC_PER        , -- time                                             ; --! Clock period (>= 6700 ps)
         g_TIME_TPD           => g_TIM_ADC_TPD          -- time                                               --! Time: Data Propagation Delay
   ) port map (
         i_clk                => i_clk_sqm_adc        , -- in     std_logic                                 ; --! Clock
         i_pwdn               => i_sqm_adc_pwdn       , -- in     std_logic                                 ; --! Power down ('0' = Inactive, '1' = Active)
         i_oeb_n              => c_LOW_LEV            , -- in     std_logic                                 ; --! Output enable ('0' = Active, '1' = Inactive)
         o_sdio_dcs           => o_sqm_adc_spi_sdio   , -- out    std_logic                                 ; --! SPI Data in/out, Duty Cycle stabilizer select ('0' = Disable, '1' = Enable)
         i_sclk_dfs           => i_sqm_adc_spi_sclk   , -- in     std_logic                                 ; --! SPI Serial clock, Data Format select ('0' = Binary, '1' = Twos complement)

         i_delta_vin          => o_sqm_adc_ana        , -- in     real                                      ; --! Analog voltage (-g_VREF <= Vin+ - Vin- < g_VREF)
         o_dco                => open                 , -- out    std_logic                                 ; --! Data clock
         o_d                  => o_sqm_adc_data       , -- out    std_logic_vector(13 downto 0)             ; --! Data
         o_or                 => o_sqm_adc_oor          -- out    std_logic                                   --! Out of range indicator ('0' = Range, '1' = Out of range)
   );

end architecture Behavioral;
