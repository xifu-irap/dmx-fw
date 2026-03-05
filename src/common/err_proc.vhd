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
--!   @file                   err_proc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Error process
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

entity err_proc is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         o_mem_parma_prm_add  : out    std_logic_vector(c_MEM_PARMA_ADD_S-1  downto 0)                      ; --! Parameter a(p): memory parameter side address
         o_mem_kiknm_prm_add  : out    std_logic_vector(c_MEM_KIKNM_ADD_S-1  downto 0)                      ; --! Parameter ki(p)*knorm(p): memory parameter side address
         o_mem_knorm_prm_add  : out    std_logic_vector(c_MEM_KNORM_ADD_S-1  downto 0)                      ; --! Parameter knorm(p): memory parameter side address
         o_mem_smfb0_prm_add  : out    std_logic_vector(c_MEM_SMFB0_ADD_S-1  downto 0)                      ; --! Parameter smfb0(p): memory parameter side address
         o_mem_smlkv_prm_add  : out    std_logic_vector(c_MEM_SMLKV_ADD_S-1  downto 0)                      ; --! Parameter Elp(p): memory parameter side address

         o_mem_parma_pp_rdy   : out    std_logic                                                            ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_kiknm_pp_rdy   : out    std_logic                                                            ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_knorm_pp_rdy   : out    std_logic                                                            ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_smfb0_pp_rdy   : out    std_logic                                                            ; --! Parameter smfb0(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         o_mem_smlkv_pp_rdy   : out    std_logic                                                            ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

         i_a_p_aln            : in     std_logic_vector(c_DFLD_PARMA_PIX_S   downto 0)                      ; --! Parameters a(p)
         i_fb0_fb_aln         : in     std_logic_vector(c_FB_PN_S-1          downto 0)                      ; --! Feedback value in open loop for FB(p,n) alignment
         i_fgn_p              : in     std_logic_vector(c_FGN_P_S-1          downto 0)                      ; --! Parameters gain*ki(p)*knorm(p)
         i_sgn_p              : in     std_logic_vector(c_SGN_P_S-1          downto 0)                      ; --! Parameters gain*knorm(p)
         i_minus_elp_p_aln    : in     std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                      ; --! Parameters -Elp(p) aligned on E(p,n) bus size

         i_squid_close_mode_n : in     std_logic                                                            ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   : in     std_logic                                                            ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
         i_rl_ena             : in     std_logic                                                            ; --! Relock enable ('0' = No, '1' = Yes)

         o_adc_smp_ave_frst   : out    std_logic                                                            ; --! ADC sample average first pixel
         o_adc_smp_ave_cs     : out    std_logic                                                            ; --! ADC sample average chip select ('0' = Inactive, '1' = Active)
         o_sqa_close_sync_ena : out    std_logic                                                            ; --! SQUID AMP Close mode synchronized on first pixel enable ('0' = No, '1' = Yes)
         o_smfbm_add          : out    std_logic_vector( c_MEM_SMFBM_ADD_S-1 downto 0)                      ; --! SQUID MUX feedback mode: address, memory output
         o_smfbm_cs           : out    std_logic                                                            ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         o_mem_rl_rd_add      : out    std_logic_vector(   c_MUX_FACT_S-1 downto 0)                         ; --! Relock memories read address

         i_adc_smp_ave        : in     std_logic_vector(c_ADC_SMP_AVE_S-1 downto 0)                         ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
         i_sqm_data_err_frst  : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  : in     std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_sqm_data_sc        : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! SQUID MUX Data science
         o_sqm_data_sc_first  : out    std_logic                                                            ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   : out    std_logic                                                            ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    : out    std_logic                                                            ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_sqm_dta_pixel_pos  : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_frst   : out    std_logic                                                            ; --! SQUID MUX Data error corrected first pixel
         o_sqm_dta_err_cor    : out    std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         o_sqm_dta_err_cor_cs : out    std_logic                                                              --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
   );
end entity err_proc;

architecture RTL of err_proc is
constant c_PIXEL_POS_MAX_VAL  : integer := c_MUX_FACT - 1                                                   ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer := log2_ceil(c_PIXEL_POS_MAX_VAL+1)                                 ; --! Pixel position: size bus

signal   sqm_data_err_frst_r  : std_logic_vector(c_DATA_ERR_RDY_R_NB-1 downto 0)                            ; --! SQUID MUX Data science first pixel register
signal   sqm_data_err_last_r  : std_logic_vector(c_DATA_ERR_RDY_R_NB-1 downto 0)                            ; --! SQUID MUX Data science last pixel register
signal   sqm_data_err_rdy_r   : std_logic_vector(c_DATA_ERR_RDY_R_NB-1 downto 0)                            ; --! SQUID MUX Data science ready register

signal   pixel_pos            : std_logic_vector(            c_PIXEL_POS_S-1 downto 0)                      ; --! Pixel position
signal   pixel_pos_r          : t_slv_arr(0 to c_DATA_ERR_RDY_R_NB-1)(c_PIXEL_POS_S-1 downto 0)             ; --! Pixel position register

signal   rl_ena_rdy           : std_logic                                                                   ; --! Relock enable ready

signal   dfb_mem_acc_add      : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! dFB(p,n): Memory accumulator address Data to accumulate
signal   dfb_mem_eln_add      : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! dFB(p,n): Memory accumulator address Data element n
signal   dfb_data_acc_rdy     : std_logic                                                                   ; --! dFB(p,n): Data to accumulate ready ('0' = Not ready, '1' = Ready)
signal   dfb_data_eln_rdy     : std_logic                                                                   ; --! dFB(p,n): Data element n ready     ('0' = Not ready, '1' = Ready)

signal   fb_mem_acc_add       : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! FB(p,n): Memory accumulator address Data to accumulate
signal   fb_mem_eln_add       : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! FB(p,n): Memory accumulator address Data element n
signal   fb_data_acc_rdy      : std_logic                                                                   ; --! FB(p,n): Data to accumulate ready ('0' = Not ready, '1' = Ready)
signal   fb_data_eln_rdy      : std_logic                                                                   ; --! FB(p,n): Data element n ready     ('0' = Not ready, '1' = Ready)

signal   e_pn_minus_elp_p     : std_logic_vector(c_ADC_SMP_AVE_S-1 downto 0)                                ; --! Result: E(p,n) - Elp(p)
signal   m_pn                 : std_logic_vector(c_M_PN_S          downto 0)                                ; --! Result: M(p,n) = ki(p)*knorm(p)*(E(p,n)-Elp(p)) (bus size result +1 bit for rounding)
signal   m_pn_car_dfb_pn      : std_logic_vector(c_DFB_PN_DACC_S   downto 0)                                ; --! M(p,n) with carry for dFB(p,n+1) calculation
signal   m_pn_rnd_sat_dfb_pn  : std_logic_vector(c_DFB_PN_DACC_S-1 downto 0)                                ; --! M(p,n) round with saturation for dFB(p,n+1) calculation
signal   m_pn_rnd_sat_pc1_pn  : std_logic_vector(c_M_PN_S-1        downto 0)                                ; --! M(p,n) round with saturation for PC1(p,n) calculation
signal   dfb_pn               : std_logic_vector(c_DFB_PN_S-1      downto 0)                                ; --! Result: dFB(p,n) = M(p,n-1) + dFB(p,n-1)
signal   pc1_pn               : std_logic_vector(c_PC1_PN_S        downto 0)                                ; --! Result: PC1(p,n) = M(p,n) + a(p) * dFB(p,n) (bus size result +1 bit for rounding)
signal   pc1_pn_rnd_sat_fb_pn : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! PC1(p,n) round with saturation for FB(p,n+1) calculation
signal   fb_pn                : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! Result: FB(p,n)
signal   fb_pnp1              : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! Result: FB(p,n+1) = FB(p,n) + M(p,n) + a(p) * dFB(p,n)
signal   fb_pnp1_car          : std_logic_vector(c_SQM_DATA_FBK_S  downto 0)                                ; --! FB(p,n+1) with carry
signal   nrm_pn               : std_logic_vector(c_NRM_PN_S        downto 0)                                ; --! Result: NRM(p,n) = knorm(p)*(E(p,n) - Elp(p)) (bus size result +1 bit for rounding)
signal   nrm_pn_rnd_sat       : std_logic_vector(c_NRM_PN_S-1      downto 0)                                ; --! NRM(p,n) round with saturation
signal   sc_pn                : std_logic_vector(c_NRM_PN_S-1      downto 0)                                ; --! Result: SC(p,n) = knorm(p)*(E(p,n) - Elp(p)) + FB(p,n)
signal   sc_pn_car            : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S   downto 0)             ; --! SC(p,n) with carry

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_sqm_data_sc_first : signal is true                                     ; --! Disabling signal optimization: o_sqm_data_sc_first
attribute syn_preserve          of o_sqm_data_sc_rdy   : signal is true                                     ; --! Disabling signal optimization: o_sqm_data_sc_rdy
attribute syn_preserve          of o_sqm_dta_err_frst  : signal is true                                     ; --! Disabling signal optimization: o_sqm_dta_err_frst
attribute syn_preserve          of o_sqm_dta_err_cor_cs: signal is true                                     ; --! Disabling signal optimization: o_sqm_dta_err_cor_cs

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_data_err_frst_r  <= (others => c_LOW_LEV);
         sqm_data_err_last_r  <= (others => c_LOW_LEV);
         sqm_data_err_rdy_r   <= (others => c_LOW_LEV);
         pixel_pos_r          <= (others => c_MINUSONE(pixel_pos_r(pixel_pos_r'low)'range));

      elsif rising_edge(i_clk) then
         sqm_data_err_frst_r  <= sqm_data_err_frst_r(sqm_data_err_frst_r'high-1 downto 0) & i_sqm_data_err_frst;
         sqm_data_err_last_r  <= sqm_data_err_last_r(sqm_data_err_last_r'high-1 downto 0) & i_sqm_data_err_last;
         sqm_data_err_rdy_r   <= sqm_data_err_rdy_r( sqm_data_err_rdy_r'high-1  downto 0) & i_sqm_data_err_rdy;
         pixel_pos_r          <= pixel_pos & pixel_pos_r(0 to pixel_pos_r'high-1);

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pixel_pos   <= c_ZERO(pixel_pos'range);

      elsif rising_edge(i_clk) then
         if i_sqm_data_err_rdy = c_HGH_LEV then
            if i_sqm_data_err_frst = c_HGH_LEV then
               pixel_pos <= c_ZERO(pixel_pos'range);

            elsif pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) then
               pixel_pos <= std_logic_vector(unsigned(pixel_pos) + 1);

            end if;

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories parameter side address
   -- ------------------------------------------------------------------------------------------------------
   o_mem_parma_prm_add <= pixel_pos_r(c_A_P_SRT);
   o_mem_kiknm_prm_add <= pixel_pos_r(c_KIKNM_P_SRT);
   o_mem_knorm_prm_add <= pixel_pos_r(c_KNORM_P_SRT);
   o_mem_smfb0_prm_add <= pixel_pos_r(c_SMFB0_P_SRT);
   o_mem_smlkv_prm_add <= pixel_pos_r(c_ELP_P_SRT);

   -- ------------------------------------------------------------------------------------------------------
   --!   Ping-pong buffer bit ready
   -- ------------------------------------------------------------------------------------------------------
   o_mem_parma_pp_rdy  <= sqm_data_err_rdy_r(c_A_P_SRT) and sqm_data_err_frst_r(c_A_P_SRT);
   o_mem_kiknm_pp_rdy  <= sqm_data_err_rdy_r(c_KIKNM_P_SRT) and sqm_data_err_frst_r(c_KIKNM_P_SRT);
   o_mem_knorm_pp_rdy  <= sqm_data_err_rdy_r(c_KNORM_P_SRT) and sqm_data_err_frst_r(c_KNORM_P_SRT);
   o_mem_smfb0_pp_rdy  <= sqm_data_err_rdy_r(c_SMFB0_P_SRT) and sqm_data_err_frst_r(c_SMFB0_P_SRT);
   o_mem_smlkv_pp_rdy  <= sqm_data_err_rdy_r(c_ELP_P_SRT) and sqm_data_err_frst_r(c_ELP_P_SRT);

   -- ------------------------------------------------------------------------------------------------------
   --!   External element synchronization
   -- ------------------------------------------------------------------------------------------------------
   o_adc_smp_ave_frst   <= sqm_data_err_frst_r(c_ADC_SMP_AVE_NPER);
   o_adc_smp_ave_cs     <= sqm_data_err_rdy_r( c_ADC_SMP_AVE_NPER);
   o_sqa_close_sync_ena <= sqm_data_err_frst_r(c_KNORM_P_SRT) and sqm_data_err_rdy_r(c_KNORM_P_SRT);
   o_smfbm_add          <= pixel_pos_r(        c_INI_DFB_PN_SRT);
   o_smfbm_cs           <= sqm_data_err_rdy_r( c_INI_DFB_PN_SRT);
   o_mem_rl_rd_add      <= pixel_pos_r(c_MEM_RL_RD_ADD_SRT);

   rl_ena_rdy           <= sqm_data_err_rdy_r(c_RL_ENA_NPER);

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: E(p,n) - Elp(p)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   I_e_pn_minus_elp_p: entity work.adder_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_S             => c_ADC_SMP_AVE_S        -- integer                                            --! Data bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_fst           => i_adc_smp_ave        , -- in     slv g_DATA_S                              ; --! Data first (signed)
         i_data_sec           => i_minus_elp_p_aln    , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data second (signed)
         o_data_add_sat       => e_pn_minus_elp_p       -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Data added with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: M(p,n) = gain*ki(p)*knorm(p)*(E(p,n) - Elp(p)) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   I_m_pn: entity work.dsp generic map (
         g_PORTA_S            => c_FGN_P_S            , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_ADC_SMP_AVE_S      , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_FGN_P_S            , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_M_PN_S + 1         , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_DIS  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_M_PN_SAT           , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => i_fgn_p              , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => e_pn_minus_elp_p     , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_FGN_P_S-1           downto 0), -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_ADC_SMP_AVE_S-1     downto 0), -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => m_pn                 , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   m_pn_car_dfb_pn <= m_pn(m_pn'high downto m_pn'length-m_pn_car_dfb_pn'length);

   I_m_pn_rd_sat_dfb_pn: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_DFB_PN_DACC_S+1      -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => m_pn_car_dfb_pn      , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => m_pn_rnd_sat_dfb_pn    -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   I_m_pn_rd_sat_pc1_pn: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_M_PN_S + 1           -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => m_pn                 , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => m_pn_rnd_sat_pc1_pn    -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Adder with accumulator: dFB(p,n+1) = M(p,n) + dFB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   dfb_mem_eln_add   <= pixel_pos_r(       c_DFB_PN_SRT);
   dfb_data_eln_rdy  <= sqm_data_err_rdy_r(c_DFB_PN_SRT);
   dfb_mem_acc_add   <= pixel_pos_r(     c_RL_ENA_NPER);
   dfb_data_acc_rdy  <= sqm_data_err_rdy_r(c_M_PN_NPER);

   I_dfb_pn: entity work.adder_acc generic map (
         g_DATA_ACC_S         => c_DFB_PN_DACC_S      , -- integer                                          ; --! Data to accumulate bus size
         g_DATA_ELN_S         => c_DFB_PN_S           , -- integer                                          ; --! Data element n bus size (>= g_DATA_ACC_S)
         g_MEM_ACC_NW         => c_MUX_FACT             -- integer                                          ; --! Memory accumulator number word
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_mem_eln_rd_add     => dfb_mem_eln_add      , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address element n read
         i_mem_acc_wr_add     => dfb_mem_acc_add      , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address data to accumulate write
         i_squid_close_mode_n => i_squid_close_mode_n , -- in     std_logic                                 ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   => i_amp_frst_lst_frm   , -- in     std_logic                                 ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
         i_mem_acc_init_val   => c_ZERO(c_DFB_PN_S-1 downto 0), -- in slv(g_DATA_ELN_S-1 downto 0)          ; --! Memory accumulator initialization value (signed)
         i_rl_ena             => i_rl_ena             , -- in     std_logic                                 ; --! Relock enable ('0' = No, '1' = Yes)
         i_rl_ena_rdy         => rl_ena_rdy           , -- in     std_logic                                 ; --! Relock enable ready
         i_data_acc           => m_pn_rnd_sat_dfb_pn  , -- in     std_logic_vector(g_DATA_ACC_S-1 downto 0) ; --! Data to accumulate (signed)
         i_data_acc_rdy       => dfb_data_acc_rdy     , -- in     std_logic                                 ; --! Data to accumulate ready ('0' = Not ready, '1' = Ready)
         i_data_eln_rdy       => dfb_data_eln_rdy     , -- in     std_logic                                 ; --! Data element n ready     ('0' = Not ready, '1' = Ready)
         o_data_elnp1         => open                 , -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Data element n+1 (signed)
         o_data_eln           => dfb_pn                 -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0)   --! Data element n   (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: PC1(p,n) = M(p,n) + a(p) * dFB(p,n) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   I_pc1_pn: entity work.dsp generic map (
         g_PORTA_S            => c_DFB_PN_S           , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_PARMA_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_M_PN_S             , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_PC1_PN_S + 1       , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_DIS  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_PC1_PN_SAT         , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => dfb_pn               , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => i_a_p_aln            , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => m_pn_rnd_sat_pc1_pn  , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_DFLD_PARMA_PIX_S downto 0),    -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => pc1_pn               , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_pc1_pn_rd_st_fb_pn: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_PC1_PN_S + 1         -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => pc1_pn               , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => pc1_pn_rnd_sat_fb_pn   -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Adder with accumulator: FB(p,n+1) = FB(p,n) + M(p,n) + a(p) * dFB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0160
   --    @Req : DRE-DMX-FW-REQ-0396
   --    @Req : DRE-DMX-FW-REQ-0400
   -- ------------------------------------------------------------------------------------------------------
   fb_mem_eln_add    <= pixel_pos_r(       c_FB_PN_SRT);
   fb_data_eln_rdy   <= sqm_data_err_rdy_r(c_FB_PN_SRT);
   fb_mem_acc_add    <= pixel_pos_r(       c_RL_ENA_NPER);
   fb_data_acc_rdy   <= sqm_data_err_rdy_r(c_PC1_PN_NPER);

   I_fb_pn: entity work.adder_acc generic map (
         g_DATA_ACC_S         => c_FB_PN_S            , -- integer                                          ; --! Data to accumulate bus size
         g_DATA_ELN_S         => c_FB_PN_S            , -- integer                                          ; --! Data element n bus size (>= g_DATA_ACC_S)
         g_MEM_ACC_NW         => c_MUX_FACT             -- integer                                          ; --! Memory accumulator number word
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_mem_eln_rd_add     => fb_mem_eln_add       , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address element n read
         i_mem_acc_wr_add     => fb_mem_acc_add       , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address data to accumulate write
         i_squid_close_mode_n => i_squid_close_mode_n , -- in     std_logic                                 ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   => i_amp_frst_lst_frm   , -- in     std_logic                                 ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
         i_mem_acc_init_val   => i_fb0_fb_aln         , -- in     std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Memory accumulator initialization value (signed)
         i_rl_ena             => i_rl_ena             , -- in     std_logic                                 ; --! Relock enable ('0' = No, '1' = Yes)
         i_rl_ena_rdy         => rl_ena_rdy           , -- in     std_logic                                 ; --! Relock enable ready
         i_data_acc           => pc1_pn_rnd_sat_fb_pn , -- in     std_logic_vector(g_DATA_ACC_S-1 downto 0) ; --! Data to accumulate (signed)
         i_data_acc_rdy       => fb_data_acc_rdy      , -- in     std_logic                                 ; --! Data to accumulate ready ('0' = Not ready, '1' = Ready)
         i_data_eln_rdy       => fb_data_eln_rdy      , -- in     std_logic                                 ; --! Data element n ready     ('0' = Not ready, '1' = Ready)
         o_data_elnp1         => fb_pnp1              , -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Data element n+1 (signed)
         o_data_eln           => fb_pn                  -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0)   --! Data element n   (signed)
   );

   fb_pnp1_car    <= fb_pnp1(fb_pnp1'high downto fb_pnp1'length-fb_pnp1_car'length);

   I_sqm_dta_err_cor: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_SQM_DATA_FBK_S+1     -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => fb_pnp1_car          , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_sqm_dta_err_cor      -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   o_sqm_dta_pixel_pos  <= pixel_pos_r(c_FB_PNP1_NPER-c_TST_PAT_SC_NPER-1);
   o_sqm_dta_err_cor_cs <= sqm_data_err_rdy_r(c_FB_PNP1_NPER-c_TST_PAT_SC_NPER);
   o_sqm_dta_err_frst   <= sqm_data_err_frst_r(c_FB_PNP1_NPER-c_TST_PAT_SC_NPER);

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: NRM(p,n) = gain*knorm(p)*(E(p,n) - Elp(p)) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0390
   --    @Req : DRE-DMX-FW-REQ-0391
   --    @Req : DRE-DMX-FW-REQ-0396
   -- ------------------------------------------------------------------------------------------------------
   I_nrm_pn: entity work.dsp generic map (
         g_PORTA_S            => c_SGN_P_S            , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_ADC_SMP_AVE_S      , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SGN_P_S            , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_NRM_PN_S + 1       , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_DIS  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_NRM_PN_SAT         , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => i_sgn_p              , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => e_pn_minus_elp_p     , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_SGN_P_S-1           downto 0), -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_ADC_SMP_AVE_S-1     downto 0), -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => nrm_pn               , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_nrm_pn_rnd_sat: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_NRM_PN_S + 1         -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => nrm_pn               , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => nrm_pn_rnd_sat         -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: SC(p,n) = knorm(p)*(E(p,n) - Elp(p)) + FB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0390
   --    @Req : DRE-DMX-FW-REQ-0391
   --    @Req : DRE-DMX-FW-REQ-0396
   -- ------------------------------------------------------------------------------------------------------
   I_sc_pn: entity work.adder_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_S             => c_NRM_PN_S             -- integer                                            --! Data bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_fst           => nrm_pn_rnd_sat       , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data first (signed)
         i_data_sec           => fb_pn                , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data second (signed)
         o_data_add_sat       => sc_pn                  -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Data added with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science telemetry (rounded with saturation operation)
   -- ------------------------------------------------------------------------------------------------------
   sc_pn_car <= sc_pn(sc_pn'high downto sc_pn'length-sc_pn_car'length);

   I_sqm_data_sc: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S+1 -- integer                              --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => sc_pn_car            , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_sqm_data_sc          -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   --!   Science telemetry control
   P_sqm_data_sc_ctrl : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqm_data_sc_first  <= c_LOW_LEV;
         o_sqm_data_sc_rdy    <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         o_sqm_data_sc_first  <= sqm_data_err_frst_r(c_SC_PN_NPER);
         o_sqm_data_sc_rdy    <= sqm_data_err_rdy_r( c_SC_PN_NPER);

      end if;

   end process P_sqm_data_sc_ctrl;

   o_sqm_data_sc_last   <= sqm_data_err_last_r(c_SC_O_PN_NPER);

end architecture RTL;
