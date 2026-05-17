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
--!   @file                   sqa_under_samp.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP under-sampling filters
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_calc_chain.all;
use     work.pkg_fir.all;

entity sqa_under_samp is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_squid_amp_close    : in     std_logic                                                            ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         i_salkv              : in     std_logic_vector(c_DFLD_SALKV_COL_S-1 downto 0)                      ; --! SQUID AMP elp

         i_adc_smp_ave        : in     std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                      ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         i_adc_smp_ave_frst   : in     std_logic                                                            ; --! ADC sample average first pixel
         i_adc_smp_ave_cs     : in     std_logic                                                            ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)

         o_sqa_under_samp     : out    std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                        --! SQUID AMP under-sampling
   );
end entity sqa_under_samp;

architecture RTL of sqa_under_samp is
constant c_FIR1_NB            : integer:= 2                                                                 ; --! Filter FIR1: Filter FIR1 chain number
constant c_FIR1_0             : integer:= 0                                                                 ; --! Filter FIR1: First  value
constant c_FIR1_1             : integer:= 1                                                                 ; --! Filter FIR1: Second value
constant c_SQA_FIR1_TAB_INIT  : integer_vector(0 to c_FIR1_NB-1) := (0, c_SQA_FIR1_DCI_VAL)                 ; --! Filter FIR1: Table position initialization
constant c_FIR1_DCI_CHN_VAL   : integer:= c_FIR1_NB * c_SQA_FIR1_DCI_VAL                                    ; --! Filter FIR1: Decimation value applied to each chain
constant c_IIR2_RES_S         : integer:= c_ADC_SMP_AVE_S                                                   ; --! Filter IIR2: Result bus size
constant c_INIT_ENA_R_SEL     : integer:= 1                                                                 ; --! Initialization enable register selected for dropped first pulse IIR start condition

constant c_FIR1_START_NB_CYC  : integer:= (c_FIR1_DCI_CHN_VAL - 1) * (c_PIXEL_ADC_NB_CYC/2)
                                         - c_SQA_FIR1_TAB_NW       +  c_SQA_FIR_ADD_DIFF - 1                ; --! Filter FIR1 number of system clock before calculation
constant c_IIR2_START_NB_CYC  : integer:= (c_PIXEL_ADC_NB_CYC/2)
                                         - c_IIR2_TAB_NW           +  c_SQA_IIR_ADD_DIFF + 1                ; --! Filter IIR2 number of system clock before calculation

constant c_FIR1_CNT_SP_MX_VAL : integer:= c_FIR1_DCI_CHN_VAL - 2                                            ; --! Filter FIR1 sample counter: maximal value
constant c_FIR1_CNT_SP_S      : integer:= log2_ceil(c_FIR1_CNT_SP_MX_VAL + 1) + 1                           ; --! Filter FIR1 sample counter: size bus (signed)

constant c_IIR2_CNT_SP_MX_VAL : integer:= c_IIR2_DCI_VAL - 2                                                ; --! Filter IIR2 sample counter: maximal value
constant c_IIR2_CNT_SP_S      : integer:= log2_ceil(c_IIR2_CNT_SP_MX_VAL + 1) + 1                           ; --! Filter IIR2 sample counter: size bus (signed)

signal   adc_smp_ave_rdy      : std_logic                                                                   ; --! ADC sample average ready
signal   adc_smp_ave_rdy_r    : std_logic                                                                   ; --! ADC sample average ready register

signal   fir_init_ena         : std_logic                                                                   ; --! Filter FIR: initialization enable
signal   fir_init_ena_fe      : std_logic                                                                   ; --! Filter FIR: initialization enable falling edge
signal   fir_init_ena_r       : std_logic_vector(c_SQA_FIR1_DTA_NPER-1 downto 0)                            ; --! Filter FIR: initialization enable register
signal   fir_init_ena_fe_r    : std_logic_vector(c_SQA_FIR1_DTA_NPER-1 downto 0)                            ; --! Filter FIR: initialization enable falling edge register

signal   fir1_cnt_sp          : std_logic_vector(  c_FIR1_CNT_SP_S-1 downto 0)                              ; --! Filter FIR1: sample counter
signal   fir1_init_val        : std_logic_vector(c_SQA_FIR1_DATA_S-1 downto 0)                              ; --! Filter FIR1: initialization value
signal   fir1_start_cond      : std_logic_vector(        c_FIR1_NB-1 downto 0)                              ; --! Filter FIR1: starts calculation condition ('0' = Inactive, '1' one clk cyc. = Active)
signal   fir1_res             : t_slv_arr(       0 to    c_FIR1_NB-1)(c_IIR2_IN_DATA_S-1 downto 0)          ; --! Filter FIR1: results
signal   fir1_res_rdy         : std_logic_vector(        c_FIR1_NB-1 downto 0)                              ; --! Filter FIR1: results ready ('0' = Inactive, '1' = Active)
signal   fir1_res_mux         : std_logic_vector( c_IIR2_IN_DATA_S-1 downto 0)                              ; --! Filter FIR1: results multiplexer
signal   fir1_res_rdy_or      : std_logic                                                                   ; --! Filter FIR1: results ready 'Or-ed'

signal   iir2_cnt_sp          : std_logic_vector(  c_IIR2_CNT_SP_S-1 downto 0)                              ; --! Filter IIR2: sample counter
signal   iir2_init_val        : std_logic_vector( c_IIR2_IN_DATA_S-1 downto 0)                              ; --! Filter IIR2: initialization value
signal   iir2_start_cond      : std_logic_vector(c_SQA_FIR1_DTA_NPER-2 downto 0)                            ; --! Filter IIR2: start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)
signal   iir2_res             : std_logic_vector(     c_IIR2_RES_S-1 downto 0)                              ; --! Filter IIR2: result
signal   iir2_res_rdy         : std_logic                                                                   ; --! Filter IIR2: results ready ('0' = Inactive, '1' = Active)
signal   iir2_res_rdy_r       : std_logic                                                                   ; --! Filter IIR2: results ready register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         adc_smp_ave_rdy   <= c_LOW_LEV;
         adc_smp_ave_rdy_r <= c_LOW_LEV;
         fir_init_ena_r    <= (others => c_HGH_LEV);
         fir_init_ena_fe_r <= (others => c_LOW_LEV);
         iir2_res_rdy_r    <= c_LOW_LEV;
         iir2_start_cond   <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         adc_smp_ave_rdy   <= i_adc_smp_ave_cs;
         adc_smp_ave_rdy_r <= adc_smp_ave_rdy;
         fir_init_ena_r    <= fir_init_ena_r(      fir_init_ena_r'high-1 downto 0) & fir_init_ena;
         fir_init_ena_fe_r <= fir_init_ena_fe_r(fir_init_ena_fe_r'high-1 downto 0) & fir_init_ena_fe;
         iir2_res_rdy_r    <= iir2_res_rdy;
         iir2_start_cond   <= iir2_start_cond(    iir2_start_cond'high-1 downto 0) & (adc_smp_ave_rdy_r and fir1_cnt_sp(fir1_cnt_sp'low) and not(fir_init_ena_r(c_INIT_ENA_R_SEL)));

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR: initialization enable
   -- ------------------------------------------------------------------------------------------------------
   P_fir_init_ena : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir_init_ena    <= c_HGH_LEV;
         fir_init_ena_fe <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if (i_adc_smp_ave_cs and i_adc_smp_ave_frst) = c_HGH_LEV then
            fir_init_ena   <= not(i_squid_amp_close);

         end if;

         if (i_adc_smp_ave_cs and i_adc_smp_ave_frst) = c_HGH_LEV then
            fir_init_ena_fe <= fir_init_ena and i_squid_amp_close;

         else
            fir_init_ena_fe <= c_LOW_LEV;

         end if;

      end if;

   end process P_fir_init_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1: initialization value
   -- ------------------------------------------------------------------------------------------------------
   I_fir1_salkv_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SALKV_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SQA_FIR1_DATA_S      -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_salkv              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir1_init_val        , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1: sample counter
   -- ------------------------------------------------------------------------------------------------------
   P_fir1_cnt_sp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir1_cnt_sp <= std_logic_vector(to_unsigned(c_FIR1_CNT_SP_MX_VAL, fir1_cnt_sp'length));

      elsif rising_edge(i_clk) then
         if fir_init_ena = c_HGH_LEV then
            fir1_cnt_sp <= std_logic_vector(to_unsigned(c_FIR1_CNT_SP_MX_VAL, fir1_cnt_sp'length));

         elsif adc_smp_ave_rdy = c_HGH_LEV then
            if fir1_cnt_sp(fir1_cnt_sp'high) = c_HGH_LEV then
               fir1_cnt_sp <= std_logic_vector(to_unsigned(c_FIR1_CNT_SP_MX_VAL, fir1_cnt_sp'length));

            else
               fir1_cnt_sp <= std_logic_vector(signed(fir1_cnt_sp) - 1);

            end if;

         end if;

      end if;

   end process P_fir1_cnt_sp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1 management
   -- ------------------------------------------------------------------------------------------------------
   G_fir1_mgt: for k in 0 to c_FIR1_NB-1 generate
   constant c_K_V             : std_logic_vector(log2_ceil(c_FIR1_NB)-1 downto 0) :=
                                std_logic_vector(to_unsigned(k, log2_ceil(c_FIR1_NB)))                      ; --! Vectorized k value
   begin

      --!   Filter FIR1: start calculation condition
      P_fir1_start_cond : process (i_rst, i_clk)
      begin

         if i_rst = c_RST_LEV_ACT then
            fir1_start_cond(k) <= c_LOW_LEV;

         elsif rising_edge(i_clk) then
            if fir1_cnt_sp(fir1_cnt_sp'high-1) = c_K_V(c_K_V'low) then
               fir1_start_cond(k) <= adc_smp_ave_rdy_r and fir1_cnt_sp(fir1_cnt_sp'low);

            else
               fir1_start_cond(k) <= c_LOW_LEV;

            end if;

         end if;

      end process P_fir1_start_cond;

      --!   Filter FIR1
      I_fir_deci1: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_FIR1_DCI_CHN_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => c_SQA_FIR1_TAB_NW    , -- integer                                          ; --! Filter FIR table number word
         g_FIR_TAB_POS_INIT   => c_SQA_FIR1_TAB_INIT(k),-- integer                                          ; --! Filter FIR table position initialization
         g_FIR_START_NB_CYC   => c_FIR1_START_NB_CYC  , -- integer                                          ; --! Filter FIR number of system clock before calculation
         g_FIR_COEF_S         => c_SQA_FIR1_S         , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => c_SQA_FIR1_TAB       , -- t_slv_arr 2**log2_ceil(g_FIR_TAB_NW) g_FIR_COEF_S; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => c_SQA_FIR1_COEF_SM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => c_SQA_FIR1_DATA_S    , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_DATA_SHF       => c_SQA_FIR1_DATA_SHF  , -- integer                                          ; --! Filter FIR data shift used by the product
         g_FIR_RES_S          => c_IIR2_IN_DATA_S       -- integer                                            --! Filter FIR result bus size
      )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => fir1_init_val        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => fir_init_ena         , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)
         i_fir_init_ena_fe    => fir_init_ena_fe      , -- in     std_logic                                 ; --! Filter FIR data initialization enable falling edge
         i_fir_start_cond     => fir1_start_cond(k)   , -- in     std_logic                                 ; --! Filter FIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => i_adc_smp_ave        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => adc_smp_ave_rdy      , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => fir1_res(k)          , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => fir1_res_rdy(k)        -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
      );

   end generate G_fir1_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1: results multiplexer
   -- ------------------------------------------------------------------------------------------------------
   P_fir1_res_mux : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir1_res_rdy_or <= c_LOW_LEV;
         fir1_res_mux    <= c_ZERO(fir1_res_mux'range);

      elsif rising_edge(i_clk) then
         fir1_res_rdy_or <= fir1_res_rdy(c_FIR1_1) or fir1_res_rdy(c_FIR1_0);

         if fir1_res_rdy(c_FIR1_0) = c_HGH_LEV then
            fir1_res_mux <= fir1_res(c_FIR1_0);

         elsif fir1_res_rdy(c_FIR1_1) = c_HGH_LEV then
            fir1_res_mux <= fir1_res(c_FIR1_1);

         end if;

      end if;

   end process P_fir1_res_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR2: initialization value
   -- ------------------------------------------------------------------------------------------------------
   I_iir2_salkv_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SALKV_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_IIR2_IN_DATA_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_salkv              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => iir2_init_val        , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR2
   -- ------------------------------------------------------------------------------------------------------
   I_iir_deci2: entity work.iir_deci generic map (
         g_IIR_TAB_NW         => c_IIR2_TAB_NW        , -- integer                                          ; --! Filter IIR table number word
         g_IIR_START_NB_CYC   => c_IIR2_START_NB_CYC  , -- integer                                          ; --! Filter IIR number of system clock before calculation
         g_IIR_IN_COEF_S      => c_IIR2_IN_TAB_S      , -- integer                                          ; --! Filter IIR input part coefficients bus size
         g_IIR_IN_COEF        => c_IIR2_IN_TAB        , -- t_slv_arr g_IIR_TAB_NW g_IIR_COEF_IN_S           ; --! Filter IIR input part coefficients
         g_IIR_IN_COEF_FRC_S  => c_IIR2_IN_FRC_S      , -- integer                                          ; --! Filter IIR input part coefficients fractionnal part bus size
         g_IIR_IN_COEF_SUM_S  => c_IIR2_IN_COEF_SM_S  , -- integer                                          ; --! Filter IIR input part coefficient sum bus size
         g_IIR_IN_DATA_S      => c_IIR2_IN_DATA_S     , -- integer                                          ; --! Filter IIR input part data bus size
         g_IIR_IN_DATA_SHF    => c_IIR2_IN_DATA_SHF   , -- integer                                          ; --! Filter IIR input part data shift used by the product
         g_IIR_REC_COEF_S     => c_IIR2_REC_TAB_S     , -- integer                                          ; --! Filter IIR minus recursive part coefficient bus size
         g_IIR_REC_COEF       => c_IIR2_REC_TAB       , -- t_slv_arr g_IIR_TAB_NWg_IIR_COEF_REC_S           ; --! Filter IIR minus recursive part coefficients
         g_IIR_REC_COEF_SUM_S => c_IIR2_REC_COEF_SM_S , -- integer                                          ; --! Filter IIR minus recursive part coefficient sum bus size
         g_IIR_REC_DATA_S     => c_IIR2_REC_DATA_S    , -- integer                                          ; --! Filter IIR minus recursive part data bus size
         g_IIR_REC_DATA_SHF   => c_IIR2_REC_DATA_SHF  , -- integer                                          ; --! Filter IIR minus recursive part data shift used by the product
         g_IIR_RES_S          => c_IIR2_RES_S           -- integer                                            --! Filter IIR result bus size
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_iir_init_val       => iir2_init_val        , -- in     std_logic_vector(g_IIR_DATA_S-1 downto 0) ; --! Filter IIR data initialization value
         i_iir_init_ena       => fir_init_ena_r(   fir_init_ena_r'high)   , -- in     std_logic             ; --! Filter IIR data initialization enable ('0' = No, '1' = Yes)
         i_iir_init_ena_fe    => fir_init_ena_fe_r(fir_init_ena_fe_r'high), -- in     std_logic             ; --! Filter IIR data initialization enable falling edge
         i_iir_start_cond     => iir2_start_cond(  iir2_start_cond'high)  , -- in     std_logic             ; --! Filter IIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => fir1_res_mux         , -- in     std_logic_vector(g_IIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => fir1_res_rdy_or      , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)
         o_iir_res            => iir2_res             , -- out    std_logic_vector( g_IIR_RES_S-1 downto 0) ; --! Filter IIR result no decimation (signed)
         o_iir_rdy            => iir2_res_rdy           -- out    std_logic                                   --! Filter IIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR2: sample counter
   -- ------------------------------------------------------------------------------------------------------
   P_iir2_cnt_sp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         iir2_cnt_sp <= std_logic_vector(to_unsigned(c_IIR2_CNT_SP_MX_VAL, iir2_cnt_sp'length));

      elsif rising_edge(i_clk) then
         if fir_init_ena = c_HGH_LEV then
            iir2_cnt_sp <= std_logic_vector(to_unsigned(c_IIR2_CNT_SP_MX_VAL, iir2_cnt_sp'length));

         elsif iir2_res_rdy = c_HGH_LEV then
            if iir2_cnt_sp(iir2_cnt_sp'high) = c_HGH_LEV then
               iir2_cnt_sp <= std_logic_vector(to_unsigned(c_IIR2_CNT_SP_MX_VAL, iir2_cnt_sp'length));

            else
               iir2_cnt_sp <= std_logic_vector(signed(iir2_cnt_sp) - 1);

            end if;

         end if;

      end if;

   end process P_iir2_cnt_sp;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP under-sampling
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_under_samp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqa_under_samp <= c_ZERO(o_sqa_under_samp'range);

      elsif rising_edge(i_clk) then
         if fir_init_ena = c_HGH_LEV then
            o_sqa_under_samp <= iir2_init_val;

         elsif (iir2_cnt_sp(iir2_cnt_sp'high) and iir2_res_rdy_r) = c_HGH_LEV then
            o_sqa_under_samp <= iir2_res;

         end if;

      end if;

   end process P_sqa_under_samp;

end architecture RTL;
