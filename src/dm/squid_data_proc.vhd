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
--!   @file                   squid_data_proc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_calc_chain.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity squid_data_proc is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_adc_ena            : in     std_logic                                                            ; --! ADC enable ('0' = Inactive, '1' = Active)
         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset
         i_sakkm              : in     std_logic_vector(c_DFLD_SAKKM_COL_S-1 downto 0)                      ; --! SQUID AMP ki*knorm
         i_sakrm              : in     std_logic_vector(c_DFLD_SAKRM_COL_S-1 downto 0)                      ; --! SQUID AMP knorm
         i_rldel              : in     std_logic_vector(c_DFLD_RLDEL_COL_S-1 downto 0)                      ; --! Relock delay
         i_rlthr              : in     std_logic_vector(c_DFLD_RLTHR_COL_S-1 downto 0)                      ; --! Relock threshold
         i_squid_gain         : in     std_logic_vector(c_DFLD_SMIGN_COL_S-1 downto 0)                      ; --! SQUID gain
         i_sqm_adc_pwdn       : in     std_logic                                                            ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_mem_prc            : in     t_mem_prc                                                            ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       : out    t_mem_prc_dta                                                        ; --! Memory for data squid proc.: data read

         o_smfbm_add          : out    std_logic_vector(c_MEM_SMFBM_ADD_S-1 downto 0)                       ; --! SQUID MUX feedback mode: address, memory output
         o_smfbm_cs           : out    std_logic                                                            ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         i_squid_amp_close    : in     std_logic                                                            ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         i_squid_close_mode_n : in     std_logic                                                            ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   : in     std_logic                                                            ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)

         i_sqm_data_err       : in     std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error
         i_sqm_data_err_frst  : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  : in     std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_err_sig            : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! Error signal (signed)
         o_sqm_data_sc        : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! SQUID MUX Data science
         o_sqm_data_sc_first  : out    std_logic                                                            ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   : out    std_logic                                                            ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    : out    std_logic                                                            ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_aqmde_sync         : out    std_logic_vector(  c_DFLD_AQMDE_S-1 downto 0)                        ; --! Telemetry mode, sync. on first pixel
         o_sqm_dta_pixel_pos  : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_frst   : out    std_logic                                                            ; --! SQUID MUX Data error corrected first pixel
         o_sqm_dta_err_cor    : out    std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         o_sqa_fb_close       : out    std_logic_vector(c_SQA_DAC_DATA_S+1 downto 0)                        ; --! SQUID AMP feedback close mode
         o_sqm_dta_err_cor_cs : out    std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_dlcnt          : in     t_mem(
                                       add(    c_MEM_DLCNT_ADD_S-1 downto 0),
                                       data_w(c_DFLD_DLCNT_PIX_S-1 downto 0))                               ; --! Delock counter: memory inputs
         o_dlcnt_data         : out    std_logic_vector(c_DFLD_DLCNT_PIX_S-1 downto 0)                      ; --! Delock counter: data read
         o_dlflg              : out    std_logic_vector(c_DFLD_DLFLG_COL_S-1 downto 0)                        --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)
   );
end entity squid_data_proc;

architecture RTL of squid_data_proc is
signal   mem_parma_prm_add    : std_logic_vector(c_MEM_PARMA_ADD_S-1  downto 0)                             ; --! Parameter a(p): memory parameter side address
signal   mem_kiknm_prm_add    : std_logic_vector(c_MEM_KIKNM_ADD_S-1  downto 0)                             ; --! Parameter ki(p)*knorm(p): memory parameter side address
signal   mem_knorm_prm_add    : std_logic_vector(c_MEM_KNORM_ADD_S-1  downto 0)                             ; --! Parameter knorm(p): memory parameter side address
signal   mem_smfb0_prm_add    : std_logic_vector(c_MEM_SMFB0_ADD_S-1  downto 0)                             ; --! Parameter smfb0(p): memory parameter side address
signal   mem_smlkv_prm_add    : std_logic_vector(c_MEM_SMLKV_ADD_S-1  downto 0)                             ; --! Parameter Elp(p): memory parameter side address

signal   mem_parma_pp_rdy     : std_logic                                                                   ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
signal   mem_kiknm_pp_rdy     : std_logic                                                                   ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
signal   mem_knorm_pp_rdy     : std_logic                                                                   ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
signal   mem_smfb0_pp_rdy     : std_logic                                                                   ; --! Parameter smfb0(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
signal   mem_smlkv_pp_rdy     : std_logic                                                                   ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

signal   sqm_dta_err_cor_cs_r : std_logic_vector(c_TST_PAT_SC_NPER-1 downto 0)                              ; --! SQUID MUX Data error corrected chip select register
signal   squid_amp_close_sync : std_logic                                                                   ; --! SQUID AMP Close mode synchronized on first pixel
signal   mem_rl_rd_add        : std_logic_vector(c_MUX_FACT_S-1 downto 0)                                   ; --! Relock memories read address
signal   rl_ena               : std_logic                                                                   ; --! Relock enable ('0' = No, '1' = Yes)

signal   a_p_aln              : std_logic_vector(c_DFLD_PARMA_PIX_S   downto 0)                             ; --! Parameters a(p)
signal   fgn_p                : std_logic_vector(c_FGN_P_S-1          downto 0)                             ; --! Parameters gain*ki(p)*knorm(p)
signal   sgn_p                : std_logic_vector(c_SGN_P_S-1          downto 0)                             ; --! Parameters gain*knorm(p)
signal   minus_elp_p_aln      : std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                             ; --! Parameters -Elp(p) aligned on E(p,n) bus size
signal   fb0_fb_aln           : std_logic_vector(c_FB_PN_S-1 downto 0)                                      ; --! Feedback value in open loop for FB(p,n) alignment
signal   fb0_rl_aln           : std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                               ; --! Feedback value in open loop for relock alignment

signal   adc_smp_ave          : std_logic_vector(c_ADC_SMP_AVE_S-1  downto 0)                               ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
signal   adc_smp_ave_frst     : std_logic                                                                   ; --! ADC sample average first pixel
signal   adc_smp_ave_cs       : std_logic                                                                   ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)

signal   sqa_under_samp       : std_logic_vector(c_ADC_SMP_AVE_S-1  downto 0)                               ; --! SQUID AMP under-sampling
signal   adc_smp_ave_mux      : std_logic_vector(c_ADC_SMP_AVE_S-1  downto 0)                               ; --! ADC sample average multiplexer

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP Close mode synchronized on first pixel
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_close_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_dta_err_cor_cs_r <= (others => c_LOW_LEV);
         squid_amp_close_sync <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         sqm_dta_err_cor_cs_r <= sqm_dta_err_cor_cs_r(sqm_dta_err_cor_cs_r'high-1 downto 0) & o_sqm_dta_err_cor_cs;

         if (i_sqm_data_err_frst and i_sqm_data_err_rdy) = c_HGH_LEV then
            squid_amp_close_sync <= i_squid_amp_close;

         end if;

      end if;

   end process P_sqa_close_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid Data process parameter memories
   -- ------------------------------------------------------------------------------------------------------
   I_squid_data_prc_mem: entity work.squid_data_proc_mem port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => i_clk_90             , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sakkm              => i_sakkm              , -- in     slv(c_DFLD_SAKKM_COL_S-1 downto 0)        ; --! SQUID AMP ki*knorm
         i_sakrm              => i_sakrm              , -- in     slv(c_DFLD_SAKRM_COL_S-1 downto 0)        ; --! SQUID AMP knorm
         i_saofc              => i_saofc              , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP lockpoint coarse offset
         i_squid_gain         => i_squid_gain         , -- in     slv(c_DFLD_SMIGN_COL_S-1 downto 0)        ; --! SQUID gain
         i_squid_amp_close    => squid_amp_close_sync , -- in     std_logic                                 ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)

         i_mem_prc            => i_mem_prc            , -- in     t_mem_prc                                 ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       => o_mem_prc_data       , -- out    t_mem_prc_dta                             ; --! Memory for data squid proc.: data read

         i_mem_parma_prm_add  => mem_parma_prm_add    , -- in     slv(c_MEM_PARMA_ADD_S-1  downto 0)        ; --! Parameter a(p): memory parameter side address
         i_mem_kiknm_prm_add  => mem_kiknm_prm_add    , -- in     slv(c_MEM_KIKNM_ADD_S-1  downto 0)        ; --! Parameter ki(p)*knorm(p): memory parameter side address
         i_mem_knorm_prm_add  => mem_knorm_prm_add    , -- in     slv(c_MEM_KNORM_ADD_S-1  downto 0)        ; --! Parameter knorm(p): memory parameter side address
         i_mem_smfb0_prm_add  => mem_smfb0_prm_add    , -- in     slv(c_MEM_SMFB0_ADD_S-1  downto 0)        ; --! Parameter smfb0(p): memory parameter side address
         i_mem_smlkv_prm_add  => mem_smlkv_prm_add    , -- in     slv(c_MEM_SMLKV_ADD_S-1  downto 0)        ; --! Parameter Elp(p): memory parameter side address

         i_mem_parma_pp_rdy   => mem_parma_pp_rdy     , -- in     std_logic                                 ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_kiknm_pp_rdy   => mem_kiknm_pp_rdy     , -- in     std_logic                                 ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_knorm_pp_rdy   => mem_knorm_pp_rdy     , -- in     std_logic                                 ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_smfb0_pp_rdy   => mem_smfb0_pp_rdy     , -- in     std_logic                                 ; --! Parameter smfb0(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_smlkv_pp_rdy   => mem_smlkv_pp_rdy     , -- in     std_logic                                 ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

         o_a_p_aln            => a_p_aln              , -- out    slv(c_DFLD_PARMA_PIX_S   downto 0)        ; --! Parameters a(p)
         o_fb0_fb_aln         => fb0_fb_aln           , -- out    slv(c_FB_PN_S-1          downto 0)        ; --! Feedback value in open loop for FB(p,n) alignment
         o_fb0_rl_aln         => fb0_rl_aln           , -- out    slv(c_SQM_DATA_FBK_S-1   downto 0)        ; --! Feedback value in open loop for relock alignment
         o_fgn_p              => fgn_p                , -- out    slv(c_FGN_P_S-1          downto 0)        ; --! Parameters gain*ki(p)*knorm(p)
         o_sgn_p              => sgn_p                , -- out    slv(c_SGN_P_S-1          downto 0)        ; --! Parameters gain*knorm(p)
         o_minus_elp_p_aln    => minus_elp_p_aln        -- out    slv(c_ADC_SMP_AVE_S-1    downto 0)          --! Parameters -Elp(p) aligned on E(p,n) bus size
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Error Average
   -- ------------------------------------------------------------------------------------------------------
   I_err_average: entity work.err_average port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_adc_ena            => i_adc_ena            , -- in     std_logic                                 ; --! ADC enable ('0' = Inactive, '1' = Active)
         i_aqmde              => i_aqmde              , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         i_bxlgt              => i_bxlgt              , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging
         i_sqm_adc_pwdn       => i_sqm_adc_pwdn       , -- in     std_logic                                 ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_sqm_data_err       => i_sqm_data_err       , -- in     slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error
         i_sqm_data_err_frst  => i_sqm_data_err_frst  , -- in     std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   => i_sqm_data_err_rdy   , -- in     std_logic                                 ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_aqmde_sync         => o_aqmde_sync         , -- out    slv(c_DFLD_AQMDE_S-1  downto 0)           ; --! Telemetry mode, sync. on first pixel
         o_adc_smp_ave        => adc_smp_ave          , -- out    slv(c_ADC_SMP_AVE_S-1 downto 0)           ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         o_err_sig            => o_err_sig              -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S      --! Error signal (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP close loop mode
   --    @Req : DRE-DMX-FW-REQ-0325
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_under_samp: entity work.sqa_under_samp port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_squid_amp_close    => squid_amp_close_sync , -- in     std_logic                                 ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         i_saofc              => i_saofc              , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP lockpoint coarse offset

         i_adc_smp_ave        => adc_smp_ave          , -- in     slv(c_ADC_SMP_AVE_S-1 downto 0)           ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         i_adc_smp_ave_frst   => adc_smp_ave_frst     , -- in     std_logic                                 ; --! ADC sample average first pixel
         i_adc_smp_ave_cs     => adc_smp_ave_cs       , -- in     std_logic                                 ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)

         o_sqa_under_samp     => sqa_under_samp         -- out    slv(c_ADC_SMP_AVE_S-1 downto 0)             --! SQUID AMP under-sampling
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average multiplexer
   --    @Req : DRE-DMX-FW-REQ-0325
   -- ------------------------------------------------------------------------------------------------------
   P_adc_smp_ave_mux : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         adc_smp_ave_mux   <= std_logic_vector(resize(signed(c_I_SQM_ADC_DATA_DEF), adc_smp_ave_mux'length));

      elsif rising_edge(i_clk) then
         if squid_amp_close_sync = c_HGH_LEV then
            if adc_smp_ave_cs = c_HGH_LEV then
               adc_smp_ave_mux <= sqa_under_samp;

            end if;

         else
            adc_smp_ave_mux <= adc_smp_ave;

         end if;

      end if;

   end process P_adc_smp_ave_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   Error process
   -- ------------------------------------------------------------------------------------------------------
   I_err_proc: entity work.err_proc port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         o_mem_parma_prm_add  => mem_parma_prm_add    , -- out    slv(c_MEM_PARMA_ADD_S-1  downto 0)        ; --! Parameter a(p): memory parameter side address
         o_mem_kiknm_prm_add  => mem_kiknm_prm_add    , -- out    slv(c_MEM_KIKNM_ADD_S-1  downto 0)        ; --! Parameter ki(p)*knorm(p): memory parameter side address
         o_mem_knorm_prm_add  => mem_knorm_prm_add    , -- out    slv(c_MEM_KNORM_ADD_S-1  downto 0)        ; --! Parameter knorm(p): memory parameter side address
         o_mem_smfb0_prm_add  => mem_smfb0_prm_add    , -- out    slv(c_MEM_SMFB0_ADD_S-1  downto 0)        ; --! Parameter smfb0(p): memory parameter side address
         o_mem_smlkv_prm_add  => mem_smlkv_prm_add    , -- out    slv(c_MEM_SMLKV_ADD_S-1  downto 0)        ; --! Parameter Elp(p): memory parameter side address

         o_mem_parma_pp_rdy   => mem_parma_pp_rdy     , -- out    std_logic                                 ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_kiknm_pp_rdy   => mem_kiknm_pp_rdy     , -- out    std_logic                                 ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_knorm_pp_rdy   => mem_knorm_pp_rdy     , -- out    std_logic                                 ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_smfb0_pp_rdy   => mem_smfb0_pp_rdy     , -- out    std_logic                                 ; --! Parameter smfb0(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_smlkv_pp_rdy   => mem_smlkv_pp_rdy     , -- out    std_logic                                 ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

         i_a_p_aln            => a_p_aln              , -- in     slv(c_DFLD_PARMA_PIX_S   downto 0)        ; --! Parameters a(p)
         i_fb0_fb_aln         => fb0_fb_aln           , -- in     slv(c_FB_PN_S-1          downto 0)        ; --! Feedback value in open loop for FB(p,n) alignment
         i_fgn_p              => fgn_p                , -- in     slv(c_FGN_P_S-1          downto 0)        ; --! Parameters gain*ki(p)*knorm(p)
         i_sgn_p              => sgn_p                , -- in     slv(c_SGN_P_S-1          downto 0)        ; --! Parameters gain*knorm(p)
         i_minus_elp_p_aln    => minus_elp_p_aln      , -- in     slv(c_ADC_SMP_AVE_S-1    downto 0)        ; --! Parameters -Elp(p) aligned on E(p,n) bus size

         i_squid_close_mode_n => i_squid_close_mode_n , -- in     std_logic                                 ; --! SQUID MUX/AMP Close mode by pixel ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   => i_amp_frst_lst_frm   , -- in     std_logic                                 ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
         i_rl_ena             => rl_ena               , -- in     std_logic                                 ; --! Relock enable ('0' = No, '1' = Yes)

         o_adc_smp_ave_frst   => adc_smp_ave_frst     , -- out    std_logic                                 ; --! ADC sample average first pixel
         o_adc_smp_ave_cs     => adc_smp_ave_cs       , -- out    std_logic                                 ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)
         o_smfbm_add          => o_smfbm_add          , -- out    slv(c_MEM_SMFBM_ADD_S-1 downto 0)         ; --! SQUID MUX feedback mode: address, memory output
         o_smfbm_cs           => o_smfbm_cs           , -- out    std_logic                                 ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         o_mem_rl_rd_add      => mem_rl_rd_add        , -- out    slv(c_MUX_FACT_S-1 downto 0)              ; --! Relock memories read address

         i_adc_smp_ave        => adc_smp_ave_mux      , -- in     slv(c_ADC_SMP_AVE_S-1   downto 0)         ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         i_sqm_data_err_frst  => i_sqm_data_err_frst  , -- in     std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  => i_sqm_data_err_last  , -- in     std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   => i_sqm_data_err_rdy   , -- in     std_logic                                 ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_sqm_data_sc        => o_sqm_data_sc        , -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! SQUID MUX Data science
         o_sqm_data_sc_first  => o_sqm_data_sc_first  , -- out    std_logic                                 ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   => o_sqm_data_sc_last   , -- out    std_logic                                 ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    => o_sqm_data_sc_rdy    , -- out    std_logic                                 ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_sqm_dta_pixel_pos  => o_sqm_dta_pixel_pos  , -- out    slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_frst   => o_sqm_dta_err_frst   , -- out    std_logic                                 ; --! SQUID MUX Data error corrected first pixel
         o_sqm_dta_err_cor    => o_sqm_dta_err_cor    , -- out    slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         o_sqm_dta_err_cor_cs => o_sqm_dta_err_cor_cs   -- out    std_logic                                   --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
   );

   o_sqa_fb_close <= o_sqm_dta_err_cor(o_sqm_dta_err_cor'high downto o_sqm_dta_err_cor'length-o_sqa_fb_close'length);

   -- ------------------------------------------------------------------------------------------------------
   --!   Relock
   -- ------------------------------------------------------------------------------------------------------
   I_relock: entity work.relock port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_sqm_dta_err_cor    => o_sqm_dta_err_cor    , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         i_fb0_rl_aln         => fb0_rl_aln           , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! Feedback value in open loop for relock alignment
         i_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs_r(sqm_dta_err_cor_cs_r'high),-- in     std_logic        ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_rl_rd_add      => mem_rl_rd_add        , -- in     slv(c_MUX_FACT_S-1 downto 0)              ; --! Relock memories read address
         i_smfmd              => i_smfmd              , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_squid_close_mode_n => i_squid_close_mode_n , -- in     std_logic                                 ; --! SQUID MUX/AMP Close mode by pixel ('0' = Yes, '1' = No)
         i_rldel              => i_rldel              , -- in     slv(c_DFLD_RLDEL_COL_S-1 downto 0)        ; --! Relock delay
         i_rlthr              => i_rlthr              , -- in     slv(c_DFLD_RLTHR_COL_S-1 downto 0)        ; --! Relock threshold

         i_mem_dlcnt          => i_mem_dlcnt          , -- in     t_mem                                     ; --! Delock counter: memory inputs
         o_dlcnt_data         => o_dlcnt_data         , -- out    slv(c_DFLD_DLCNT_PIX_S-1 downto 0)        ; --! Delock counter: data read
         o_dlflg              => o_dlflg              , -- out    slv(c_DFLD_DLFLG_COL_S-1 downto 0)        ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)

         o_rl_ena             => rl_ena                 -- out    std_logic                                   --! Relock enable ('0' = No, '1' = Yes)
   );

end architecture RTL;
