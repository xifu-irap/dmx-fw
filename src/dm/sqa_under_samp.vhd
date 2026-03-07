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
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset

         i_adc_smp_ave        : in     std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                      ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         i_adc_smp_ave_frst   : in     std_logic                                                            ; --! ADC sample average first pixel
         i_adc_smp_ave_cs     : in     std_logic                                                            ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)

         o_sqa_under_samp     : out    std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                        --! SQUID AMP under-sampling
   );
end entity sqa_under_samp;

architecture RTL of sqa_under_samp is
constant c_FIR1_DATA_S        : integer:= c_RAM_ECC_DATA_S                                                  ; --! Filter FIR1: Data input bus size
constant c_FIR2_DATA_S        : integer:= c_RAM_ECC_DATA_S                                                  ; --! Filter FIR2: Data input bus size
constant c_FIR2_RES_S         : integer:= c_ADC_SMP_AVE_S                                                   ; --! Filter FIR2: Result bus size

constant c_FIR1_START_NB_CYC  : integer:=  (c_MUX_FACT-1) * (c_PIXEL_ADC_NB_CYC/2) + c_MEM_RD_DATA_NPER - 1
                                          - c_SQA_FIR1_TAB_NW + c_SQA_FIR_ADD_DIFF                          ; --! Filter FIR1 number of system clock before calculation
constant c_FIR2_START_NB_CYC  : integer:=   c_MUX_FACT    * (c_PIXEL_ADC_NB_CYC/2)
                                          - c_SQA_FIR2_TAB_NW + c_SQA_FIR_ADD_DIFF                          ; --! Filter FIR2 number of system clock before calculation

constant c_FIR2_CNT_SP_MX_VAL : integer:= c_SQA_FIR2_DCI_VAL - 2                                            ; --! Filter FIR2 sample counter: maximal value
constant c_FIR2_CNT_SP_S      : integer:= log2_ceil(c_FIR2_CNT_SP_MX_VAL + 1) + 1                           ; --! Filter FIR2 sample counter: size bus (signed)

signal   adc_smp_ave_rdy      : std_logic                                                                   ; --! ADC sample average ready

signal   fir_init_ena         : std_logic                                                                   ; --! Filter FIR: initialization enable
signal   fir_init_ena_fe      : std_logic                                                                   ; --! Filter FIR: initialization enable falling edge
signal   fir_init_ena_r       : std_logic_vector(c_SQA_FIR1_DTA_NPER-1 downto 0)                            ; --! Filter FIR: initialization enable register
signal   fir_init_ena_fe_r    : std_logic_vector(c_SQA_FIR1_DTA_NPER-1 downto 0)                            ; --! Filter FIR: initialization enable falling edge register

signal   fir1_saofc_stall_msb : std_logic_vector(c_FIR1_DATA_S-2 downto 0)                                  ; --! Filter FIR1: SQUID AMP lockpoint coarse offset stall on msb
signal   fir1_init_val        : std_logic_vector(c_FIR1_DATA_S-1 downto 0)                                  ; --! Filter FIR1: initialization value
signal   fir1_start_cond      : std_logic                                                                   ; --! Filter FIR1: start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)
signal   fir1_res             : std_logic_vector(c_FIR2_DATA_S   downto 0)                                  ; --! Filter FIR1: result
signal   fir1_res_sat         : std_logic_vector(c_FIR2_DATA_S-1 downto 0)                                  ; --! Filter FIR1: result with saturation
signal   fir1_res_rdy         : std_logic                                                                   ; --! Filter FIR1: result ready ('0' = Inactive, '1' = Active)
signal   fir1_res_rdy_r       : std_logic                                                                   ; --! Filter FIR1: result ready register

signal   fir2_cnt_sp          : std_logic_vector(c_FIR2_CNT_SP_S-1 downto 0)                                ; --! Filter FIR2: sample counter
signal   fir2_saofc_stall_msb : std_logic_vector(c_FIR2_DATA_S-2 downto 0)                                  ; --! Filter FIR2: SQUID AMP lockpoint coarse offset stall on msb
signal   fir2_init_val        : std_logic_vector(c_FIR2_DATA_S-1 downto 0)                                  ; --! Filter FIR2: initialization value
signal   fir2_start_cond      : std_logic                                                                   ; --! Filter FIR2: start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)
signal   fir2_res             : std_logic_vector( c_FIR2_RES_S-1 downto 0)                                  ; --! Filter FIR2: result
signal   fir2_res_rdy         : std_logic                                                                   ; --! Filter FIR2: result ready ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         adc_smp_ave_rdy   <= c_LOW_LEV;
         fir1_res_rdy_r    <= c_LOW_LEV;
         fir_init_ena_r    <= (others => c_HGH_LEV);
         fir_init_ena_fe_r <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         adc_smp_ave_rdy   <= i_adc_smp_ave_cs;
         fir1_res_rdy_r    <= fir1_res_rdy;
         fir_init_ena_r    <= fir_init_ena_r(      fir_init_ena_r'high-1 downto 0) & fir_init_ena;
         fir_init_ena_fe_r <= fir_init_ena_fe_r(fir_init_ena_fe_r'high-1 downto 0) & fir_init_ena_fe;

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
   I_fir1_saofc_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FIR1_DATA_S - 1      -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_saofc              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir1_saofc_stall_msb , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   fir1_init_val <= std_logic_vector(resize(unsigned(fir1_saofc_stall_msb), fir1_init_val'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1: start calculation condition
   -- ------------------------------------------------------------------------------------------------------
   P_fir1_start_cond : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir1_start_cond <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         fir1_start_cond <= i_adc_smp_ave_cs and i_adc_smp_ave_frst;

      end if;

   end process P_fir1_start_cond;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1
   -- ------------------------------------------------------------------------------------------------------
   I_fir_deci1: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_SQA_FIR1_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => c_SQA_FIR1_TAB_NW    , -- integer                                          ; --! Filter FIR table number word
         g_FIR_START_NB_CYC   => c_FIR1_START_NB_CYC  , -- integer                                          ; --! Filter FIR number of system clock before calculation
         g_FIR_COEF_S         => c_SQA_FIR1_S         , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => c_SQA_FIR1_TAB       , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => c_SQA_FIR1_COEF_SM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => c_FIR1_DATA_S        , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_RES_S          => c_FIR2_DATA_S + 1      -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => fir1_init_val        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => fir_init_ena         , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)
         i_fir_init_ena_fe    => fir_init_ena_fe      , -- in     std_logic                                 ; --! Filter FIR data initialization enable falling edge
         i_fir_start_cond     => fir1_start_cond      , -- in     std_logic                                 ; --! Filter FIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => i_adc_smp_ave        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => adc_smp_ave_rdy      , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => fir1_res             , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => fir1_res_rdy           -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR1 result with saturation
   -- ------------------------------------------------------------------------------------------------------
   P_fir1_res_sat : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir1_res_sat <= c_ZERO(fir1_res_sat'range);

      elsif rising_edge(i_clk) then

         -- Saturation on minimum value
         if    (fir1_res(fir1_res'high) and not(fir1_res(fir1_res'high-1))) = c_HGH_LEV then
            fir1_res_sat(fir1_res_sat'high)           <= c_HGH_LEV;
            fir1_res_sat(fir1_res_sat'high-1 downto 0)<= (others => c_LOW_LEV);

         -- Saturation on maximum value
         elsif (not(fir1_res(fir1_res'high)) and fir1_res(fir1_res'high-1)) = c_HGH_LEV then
            fir1_res_sat(fir1_res_sat'high)           <= c_LOW_LEV;
            fir1_res_sat(fir1_res_sat'high-1 downto 0)<= (others => c_HGH_LEV);

         else
            fir1_res_sat <= fir1_res(fir1_res_sat'range);

         end if;

      end if;

   end process P_fir1_res_sat;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2: initialization value
   -- ------------------------------------------------------------------------------------------------------
   I_fir2_saofc_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FIR2_DATA_S - 1      -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_saofc              , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => fir2_saofc_stall_msb , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   fir2_init_val <= std_logic_vector(resize(unsigned(fir2_saofc_stall_msb), fir2_init_val'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2: sample counter
   -- ------------------------------------------------------------------------------------------------------
   P_fir2_cnt_sp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir2_cnt_sp <= std_logic_vector(to_unsigned(c_FIR2_CNT_SP_MX_VAL, fir2_cnt_sp'length));

      elsif rising_edge(i_clk) then
         if fir_init_ena_r(fir_init_ena_r'high) = c_HGH_LEV then
            fir2_cnt_sp <= std_logic_vector(to_unsigned(c_FIR2_CNT_SP_MX_VAL, fir2_cnt_sp'length));

         elsif fir1_res_rdy = c_HGH_LEV then
            if fir2_cnt_sp(fir2_cnt_sp'high) = c_HGH_LEV then
               fir2_cnt_sp <= std_logic_vector(to_unsigned(c_FIR2_CNT_SP_MX_VAL, fir2_cnt_sp'length));

            else
               fir2_cnt_sp <= std_logic_vector(signed(fir2_cnt_sp) - 1);

            end if;

         end if;

      end if;

   end process P_fir2_cnt_sp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2: start calculation condition
   -- ------------------------------------------------------------------------------------------------------
   P_fir2_start_cond : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fir2_start_cond <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
            fir2_start_cond <= fir1_res_rdy_r and fir2_cnt_sp(fir2_cnt_sp'high);

      end if;

   end process P_fir2_start_cond;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter FIR2
   -- ------------------------------------------------------------------------------------------------------
   I_fir_deci2: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_SQA_FIR2_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => c_SQA_FIR2_TAB_NW    , -- integer                                          ; --! Filter FIR table number word
         g_FIR_START_NB_CYC   => c_FIR2_START_NB_CYC  , -- integer                                          ; --! Filter FIR number of system clock before calculation
         g_FIR_COEF_S         => c_SQA_FIR2_S         , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => c_SQA_FIR2_TAB       , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => c_SQA_FIR2_COEF_SM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => c_FIR2_DATA_S        , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_RES_S          => c_FIR2_RES_S           -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => fir2_init_val        , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => fir_init_ena_r(   fir_init_ena_r'high)   , -- in std_logic                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)
         i_fir_init_ena_fe    => fir_init_ena_fe_r(fir_init_ena_fe_r'high), -- in std_logic                 ; --! Filter FIR data initialization enable falling edge
         i_fir_start_cond     => fir2_start_cond      , -- in     std_logic                                 ; --! Filter FIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => fir1_res_sat         , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => fir1_res_rdy_r       , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => fir2_res             , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => fir2_res_rdy           -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP under-sampling
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_under_samp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqa_under_samp <= std_logic_vector(resize(unsigned(c_EP_CMD_DEF_SAOFC), o_sqa_under_samp'length));

      elsif rising_edge(i_clk) then
         if fir_init_ena_r(fir_init_ena_r'high) = c_HGH_LEV then
            o_sqa_under_samp <= fir2_init_val;

         elsif fir2_res_rdy = c_HGH_LEV then
            o_sqa_under_samp <= fir2_res;

         end if;

      end if;

   end process P_sqa_under_samp;

end architecture RTL;
