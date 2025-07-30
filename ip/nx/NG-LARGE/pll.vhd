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
--!   @file                   pll.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Clocks generation from a Phase Locked Loop (NX_PLL_L IpCore, NG-LARGE), external feedback configuration for synchronization with Reference Clock,
--!                           and distributed through Wave Form Generators (NX_WFG_L IpCore, NG-LARGE). SQUID MUX ADC Clocks and SQUID MUX DAC Clocks FPGA outputs can be switched by
--!                           command thanks to some clock switches (NX_CKS IpCore, NG-LARGE).
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_type.all;
use     work.pkg_mod.all;
use     work.pkg_project.all;

library nx;
use     nx.nxpackage.all;

entity pll is port (
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         o_clk                : out    std_logic                                                            ; --! System Clock
         o_clk_sqm_adc_dac    : out    std_logic                                                            ; --! SQUID MUX ADC/DAC internal Clock
         o_clk_adc_out        : out    std_logic                                                            ; --! Clock for SQUID ADC output Image Clock
         o_clk_dac_out        : out    std_logic                                                            ; --! Clock for SQUID DAC output Image Clock

         o_clk_90             : out    std_logic                                                            ; --! System Clock 90 degrees shift
         o_clk_sqm_adc_dac_90 : out    std_logic                                                              --! SQUID MUX ADC/DAC internal 90 degrees shift
   );
end entity pll;

architecture RTL of pll is
constant c_PRM_NU             : integer := c_ZERO_INT                                                       ; --! Parameter not used

constant c_CLK_REF_DIV        : integer := div_floor(c_CLK_REF_FREQ, 100000000)                             ; --! Pll main ref. clock freq. divided as 20MHz<= CLK_REF_FREQ /(REF_INTDIV + 1) <= 100MHz

constant c_CLK_SYNC_REF_N_PAT : integer := c_PLL_MAIN_VCO_MULT*(c_CLK_REF_DIV+1)/c_CLK_REF_MULT - 1         ; --! Clock synchronous Ref. clock: Number of vco cycles for pattern
constant c_CLK_SYNC_REF_PAT   : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ(c_CLK_SYNC_REF_N_PAT)   ; --! Clock synchronous Ref. clock: Pattern, use only the number of vco cycles+1 MSB bits

constant c_CLK_N_PAT          : integer := c_PLL_MAIN_VCO_MULT/c_CLK_MULT - 1                               ; --! System clock: Number of vco cycles for pattern
constant c_CLK_PAT            : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ(c_CLK_N_PAT)            ; --! System clock: Pattern, use only the number of vco cycles+1 MSB bits
constant c_CLK_90_PAT         : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ_90(c_CLK_N_PAT)         ; --! System clock 90 degrees shift: Pattern, use only the number of vco cycles+1 MSB bits

constant c_CLK_ADC_DAC_N_PAT  : integer := c_PLL_MAIN_VCO_MULT/c_CLK_ADC_DAC_MULT - 1                       ; --! SQUID MUX ADC/DAC Clock: Number of vco cycles for pattern
constant c_CLK_ADC_DAC_PAT    : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ(c_CLK_ADC_DAC_N_PAT)    ; --! SQUID MUX ADC/DAC Clock: Pattern, use only the number of vco cycles+1 MSB bits
constant c_CLK_ADC_DAC_90_PAT : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ_90(c_CLK_ADC_DAC_N_PAT) ; --! SQUID MUX ADC/DAC Clock 90 degrees shift: Pattern

constant c_CLK_DAC_OUT_N_PAT  : integer := c_PLL_MAIN_VCO_MULT/c_CLK_DAC_OUT_MULT - 1                       ; --! SQUID MUX DAC output Clock: Number of vco cycles for pattern
constant c_CLK_DAC_OUT_PAT    : bit_vector(0 to c_WFG_PAT_S-1) := c_WFG_PAT_ONE_SEQ(c_CLK_DAC_OUT_N_PAT)    ; --! SQUID MUX DAC output Clock: Pattern, use only the number of vco cycles+1 MSB bits

signal   pll_main_vco         : std_logic                                                                   ; --! Pll main VCO
signal   pll_main_lock        : std_logic                                                                   ; --! Pll main Status ('0' = Pll not locked, '1' = Pll locked)

signal   clk_sync_ref         : std_logic                                                                   ; --! Clock synchronous Ref. clock
signal   clk_sqm_adc_dac      : std_logic                                                                   ; --! SQUID MUX ADC/DAC internal Clock

signal   clk_sync_ref_end_seq : std_logic                                                                   ; --! Clock synchronous Ref. clock: End pattern sequence ('0': No, '1': Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!  Main pll
   -- ------------------------------------------------------------------------------------------------------
   I_pll_main: entity nx.nx_pll_l generic map (
         REF_INTDIV           => c_CLK_REF_DIV        , -- integer range 0 to 31                            ; --! Reference clock frequency divisor as 20MHz <= REF_FREQ /(REF_INTDIV + 1) <= 100MHz
         REF_OSC_ON           => c_PLL_SEL_REF        , -- bit                                              ; --! Select reference clock input ('0' = ref input , '1' = osc input)
         EXT_FBK_ON           => c_PLL_FBK_EXT        , -- bit                                              ; --! Feedback select ('0' = Internal feedback, '1' = External feedback)
         FBK_INTDIV           => c_PRM_NU             , -- integer range 0 to 31                            ; --! Internal feedback frequency multiplier, 2 * (FBK_INTDIV+2)
         FBK_DELAY_ON         => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Feedback delay ('0' = No, '1' = Yes)
         FBK_DELAY            => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on the feedback path (steps of 160 ps)
         CLK_OUTDIVP1         => c_PRM_NU             , -- integer range 0 to  7                            ; --! divp1 output divider value divp1_freq = Fvco/(2**CLK_OUTDIVP1)
         CLK_OUTDIVP2         => c_PRM_NU             , -- integer range 0 to  7                            ; --! divp2 output divider value, divp2_freq = Fvco/(2**(CLK_OUTDIVP2+1))
         CLK_OUTDIVO1         => c_PRM_NU             , -- integer range 0 to  7                            ; --! divo1 output divider value, divo1_freq = Fvco/(2**CLK_OUTDIVO1+3)
         CLK_OUTDIVP3O2       => c_PRM_NU               -- integer range 0 to  7                              --! divp3/divo2 output divider value,divp3_freq = Fvco/(2**(CLK_OUTDIVP3O2+2))
                                                                                                              --                                   divo2_freq = Fvco/(2**CLK_OUTDIVP3O2+5)
   )     port map (
         ref                  => i_clk_ref            , -- in     std_logic                                 ; --! Reference clock
         fbk                  => clk_sync_ref         , -- in     std_logic                                 ; --! External feedback
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         vco                  => pll_main_vco         , -- out    std_logic                                 ; --! VCO
         refo                 => open                 , -- out    std_logic                                 ; --! Output REF_INTDIV divider, refo_frequency = CLK_REF_FREQ /(REF_INTDIV + 1)
         ldfo                 => open                 , -- out    std_logic                                 ; --! Output FBK_INTDIV divider, ldfo_frequency = 2 * (FBK_INTDIV+2) * refo_frequency
         divo1                => open                 , -- out    std_logic                                 ; --! divo1 output generated by frequency division of the VCO output
         divo2                => open                 , -- out    std_logic                                 ; --! divo2 output generated by frequency division of the VCO output
         divp1                => open                 , -- out    std_logic                                 ; --! divp1 output generated by frequency division of the VCO output
         divp2                => open                 , -- out    std_logic                                 ; --! divp2 output generated by frequency division of the VCO output
         divp3                => open                 , -- out    std_logic                                 ; --! divp3 output generated by frequency division of the VCO output
         osc                  => open                 , -- out    std_logic                                 ; --! Internal 200MHz oscillator
         pll_locked           => pll_main_lock        , -- out    std_logic                                 ; --! Pll Status ('0' = Pll not locked, '1' = Pll locked)
         cal_locked           => open                   -- out    std_logic                                   --! Automatic calibration complete ('0' = not complete , '1' = complete)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  Clock synchronous to Reference Clock input generation
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_sync_ref: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_SYNC_REF_N_PAT , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_SYNC_REF_PAT     -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => c_HGH_LEV            , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => clk_sync_ref_end_seq , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => clk_sync_ref           -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  System clock generation
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_N_PAT          , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_PAT              -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => o_clk                  -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  SQUID MUX ADC/DAC internal Clock generation
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_adc_dac: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_ADC_DAC_N_PAT  , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_ADC_DAC_PAT      -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => clk_sqm_adc_dac        -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   o_clk_sqm_adc_dac <= clk_sqm_adc_dac;

   -- ------------------------------------------------------------------------------------------------------
   --!  Clock for SQUID ADC Image clock generation
   --    @Req : DRE-DMX-FW-REQ-0120
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_adc_out: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_ON     , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_CLK_ADC_DEL_STEP   , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_DAC_OUT_N_PAT  , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_DAC_OUT_PAT      -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => o_clk_adc_out          -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  Clock for SQUID DAC Image clock generation
   --    @Req : DRE-DMX-FW-REQ-0270
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_dac_out: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_DAC_OUT_N_PAT  , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_DAC_OUT_PAT      -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => o_clk_dac_out          -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  System clock 90 degrees shift generation
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_90: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_N_PAT          , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_90_PAT           -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => o_clk_90               -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  ADC/DAC internal Clock 90 degrees shift generation
   -- ------------------------------------------------------------------------------------------------------
   I_wfg_clk_adc_dac_90: entity nx.nx_wfg_l generic map (
         WFG_EDGE             => c_WFG_EDGE_INV_N     , -- bit                                              ; --! Input clock inverted ('0' = No, '1' = Yes)
         DELAY_ON             => c_PLL_WFG_DEL_OFF    , -- bit                                              ; --! Delay on generated clock ('0' = No, '1' = Yes)
         DELAY                => c_PRM_NU             , -- integer range 0 to 63                            ; --! Number of delay taps on generated clock (steps of 160 ps)
         MODE                 => c_WFG_PATTERN_ON     , -- bit                                              ; --! WFG pattern used ('0' = No, '1' = Yes)
         PATTERN_END          => c_CLK_ADC_DAC_N_PAT  , -- integer range 0 to 15                            ; --! Number of pattern to apply to generated clock
         PATTERN              => c_CLK_ADC_DAC_90_PAT   -- bit_vector(0 to 15)                                --! Pattern applied to generated clock: use only PATTERN_END+1 MSB bits
   )     port map (
         r                    => c_LOW_LEV            , -- in     std_logic                                 ; --! Reset ('0' = Inactive, '1' = Active)
         si                   => clk_sync_ref_end_seq , -- in     std_logic                                 ; --! Reset pattern sequence  ('0' = Inactive, '1' = Active)
         zi                   => pll_main_vco         , -- in     std_logic                                 ; --! Input clock (connected to PLL VCO or D1, D2 or D3 output)
         rdy                  => pll_main_lock        , -- in     std_logic                                 ; --! '1' for the WFG generating PLL clock on external feedback, pll_locked pin otherwise
         so                   => open                 , -- out    std_logic                                 ; --! End pattern sequence ('0': No, '1': Yes)
         zo                   => o_clk_sqm_adc_dac_90   -- out    std_logic                                   --! Generated clock, connected to clock tree
   );

end architecture RTL;
