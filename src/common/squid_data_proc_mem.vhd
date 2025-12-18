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
--!   @file                   squid_data_proc_mem.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process parameter memories management
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
use     work.pkg_ep_cmd_type.all;
use     work.pkg_calc_chain.all;

entity squid_data_proc_mem is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sakkm              : in     std_logic_vector(c_DFLD_SAKKM_COL_S-1 downto 0)                      ; --! SQUID AMP ki*knorm
         i_sakrm              : in     std_logic_vector(c_DFLD_SAKRM_COL_S-1 downto 0)                      ; --! SQUID AMP knorm
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset
         i_squid_gain         : in     std_logic_vector(c_DFLD_SMIGN_COL_S-1 downto 0)                      ; --! SQUID gain
         i_squid_amp_close    : in     std_logic                                                            ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)

         i_mem_prc            : in     t_mem_prc                                                            ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       : out    t_mem_prc_dta                                                        ; --! Memory for data squid proc.: data read

         i_mem_parma_prm_add  : in     std_logic_vector(c_MEM_PARMA_ADD_S-1  downto 0)                      ; --! Parameter a(p): memory parameter side address
         i_mem_kiknm_prm_add  : in     std_logic_vector(c_MEM_KIKNM_ADD_S-1  downto 0)                      ; --! Parameter ki(p)*knorm(p): memory parameter side address
         i_mem_knorm_prm_add  : in     std_logic_vector(c_MEM_KNORM_ADD_S-1  downto 0)                      ; --! Parameter knorm(p): memory parameter side address
         i_mem_smfb0_prm_add  : in     std_logic_vector(c_MEM_SMFB0_ADD_S-1  downto 0)                      ; --! Parameter smfb0(p): memory parameter side address
         i_mem_smlkv_prm_add  : in     std_logic_vector(c_MEM_SMLKV_ADD_S-1  downto 0)                      ; --! Parameter Elp(p): memory parameter side address

         i_mem_parma_pp_rdy   : in     std_logic                                                            ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_kiknm_pp_rdy   : in     std_logic                                                            ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_knorm_pp_rdy   : in     std_logic                                                            ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_smfb0_pp_rdy   : in     std_logic                                                            ; --! Parameter smfb0(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_smlkv_pp_rdy   : in     std_logic                                                            ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

         o_a_p_aln            : out    std_logic_vector(c_DFLD_PARMA_PIX_S   downto 0)                      ; --! Parameters a(p)
         o_fb0_fb_aln         : out    std_logic_vector(c_FB_PN_S-1          downto 0)                      ; --! Feedback value in open loop for FB(p,n) alignment
         o_fb0_rl_aln         : out    std_logic_vector(c_SQM_DATA_FBK_S-1   downto 0)                      ; --! Feedback value in open loop for relock alignment
         o_fgn_p              : out    std_logic_vector(c_FGN_P_S-1          downto 0)                      ; --! Parameters gain*ki(p)*knorm(p)
         o_sgn_p              : out    std_logic_vector(c_SGN_P_S-1          downto 0)                      ; --! Parameters gain*knorm(p)
         o_minus_elp_p_aln    : out    std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                        --! Parameters -Elp(p) aligned on E(p,n) bus size
   );
end entity squid_data_proc_mem;

architecture RTL of squid_data_proc_mem is
signal   mem_parma_pp         : std_logic                                                                   ; --! Parameter a(p), TC/HK side: ping-pong buffer bit
signal   mem_parma_prm        : t_mem(
                                add(              c_MEM_PARMA_ADD_S-1 downto 0),
                                data_w(          c_DFLD_PARMA_PIX_S-1 downto 0))                            ; --! Parameter a(p), getting parameter side: memory inputs

signal   mem_kiknm_pp         : std_logic                                                                   ; --! Parameter ki(p)*knorm(p), TC/HK side: ping-pong buffer bit
signal   mem_kiknm_prm        : t_mem(
                                add(              c_MEM_KIKNM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KIKNM_PIX_S-1 downto 0))                            ; --! Parameter ki(p)*knorm(p), getting parameter side: memory inputs

signal   mem_knorm_pp         : std_logic                                                                   ; --! Parameter knorm(p), TC/HK side: ping-pong buffer bit
signal   mem_knorm_prm        : t_mem(
                                add(              c_MEM_KNORM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KNORM_PIX_S-1 downto 0))                            ; --! Parameter knorm(p), getting parameter side: memory inputs

signal   mem_smfb0_pp         : std_logic                                                                   ; --! SQUID MUX feedback value in open loop, TC/HK side: ping-pong buffer bit
signal   mem_smfb0_prm        : t_mem(
                                add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback value in open loop, getting parameter side: memory inputs

signal   mem_smlkv_pp         : std_logic                                                                   ; --! Parameter elp(p), TC/HK side: ping-pong buffer bit
signal   mem_smlkv_prm        : t_mem(
                                add(              c_MEM_SMLKV_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMLKV_PIX_S-1 downto 0))                            ; --! Parameter elp(p), getting parameter side: memory inputs

signal   mem_kiknm_pp_rdy_r   : std_logic_vector(c_MEM_RD_DATA_NPER-1 downto 0)                             ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready register
signal   mem_knorm_pp_rdy_r   : std_logic_vector(c_MEM_RD_DATA_NPER-1 downto 0)                             ; --! Parameter knorm(p): ping-pong buffer bit ready register
signal   mem_smfb0_pp_rdy_r   : std_logic_vector(c_MEM_RD_DATA_NPER-1 downto 0)                             ; --! Parameter smfb0(p): ping-pong buffer bit ready register

signal   mux_ki_knorm_p       : std_logic_vector(c_DFLD_KIKNM_PIX_S-1 downto 0)                             ; --! Parameters MUX ki(p)*knorm(p)
signal   amp_ki_knorm         : std_logic_vector(c_DFLD_SAKKM_COL_S-1 downto 0)                             ; --! Parameters AMP ki*knorm
signal   ki_knorm_p           : std_logic_vector(c_DFLD_KIKNM_PIX_S-1 downto 0)                             ; --! Parameters ki(p)*knorm(p)
signal   ki_knorm_p_aln       : std_logic_vector(c_DFLD_KIKNM_PIX_S   downto 0)                             ; --! Parameters ki(p)*knorm(p) aligned
signal   fgn_p                : std_logic_vector(c_FGN_P_S            downto 0)                             ; --! Parameters gain*ki(p)*knorm(p) (bus size result +1 bit for rounding)

signal   mux_knorm_p          : std_logic_vector(c_DFLD_KNORM_PIX_S-1 downto 0)                             ; --! Parameters MUX knorm(p)
signal   amp_knorm            : std_logic_vector(c_DFLD_SAKRM_COL_S-1 downto 0)                             ; --! Parameters AMP knorm
signal   knorm_p              : std_logic_vector(c_DFLD_KNORM_PIX_S-1 downto 0)                             ; --! Parameters knorm(p)
signal   knorm_p_aln          : std_logic_vector(c_DFLD_KNORM_PIX_S   downto 0)                             ; --! Parameters knorm(p) aligned
signal   sgn_p                : std_logic_vector(c_SGN_P_S            downto 0)                             ; --! Parameters gain*knorm(p) (bus size result +1 bit for rounding)

signal   a_p                  : std_logic_vector(c_DFLD_PARMA_PIX_S-1 downto 0)                             ; --! Parameters a(p)
signal   smfb0_p              : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! Parameters MUX fb0(p)
signal   safb0                : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! Parameters AMP fb0 (unsigned)
signal   safb0_aln            : std_logic_vector(c_DFLD_SMFB0_PIX_S-2 downto 0)                             ; --! Parameters AMP fb0 (unsigned)
signal   fb0_p_aln            : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! Parameters fb0(p) (signed)

signal   elp_p                : std_logic_vector(c_DFLD_SMLKV_PIX_S-1 downto 0)                             ; --! Parameters Elp(p)
signal   elp_p_aln            : std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                             ; --! Parameters Elp(p) aligned on E(p,n) bus size

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_kiknm_pp_rdy_r   <= (others => c_LOW_LEV);
         mem_knorm_pp_rdy_r   <= (others => c_LOW_LEV);
         mem_smfb0_pp_rdy_r   <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         mem_kiknm_pp_rdy_r   <= mem_kiknm_pp_rdy_r(mem_kiknm_pp_rdy_r'high-1 downto 0) & i_mem_kiknm_pp_rdy;
         mem_knorm_pp_rdy_r   <= mem_knorm_pp_rdy_r(mem_knorm_pp_rdy_r'high-1 downto 0) & i_mem_knorm_pp_rdy;
         mem_smfb0_pp_rdy_r   <= mem_smfb0_pp_rdy_r(mem_smfb0_pp_rdy_r'high-1 downto 0) & i_mem_smfb0_pp_rdy;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters a(p)
   --    @Req : DRE-DMX-FW-REQ-0180
   --    @Req : REG_CY_A
   -- ------------------------------------------------------------------------------------------------------
   I_mem_parma_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_PARMA_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_PARMA_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_PARMA     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.parma      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.parma , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_parma_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_parma_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => a_p                  , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_a_p_aln <= std_logic_vector(resize(unsigned(a_p), o_a_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory a(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_parma_prm.add     <= i_mem_parma_prm_add;
   mem_parma_prm.we      <= c_LOW_LEV;
   mem_parma_prm.cs      <= c_HGH_LEV;
   mem_parma_prm.data_w  <= c_ZERO(mem_parma_prm.data_w'range);

   --! Memory a(p), ping-pong buffer bit
   P_mem_parma_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_parma_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_parma_pp_rdy = c_HGH_LEV then
            mem_parma_prm.pp   <= mem_parma_pp;

         end if;

      end if;

   end process P_mem_parma_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters MUX ki(p)*knorm(p)
   --    @Req : DRE-DMX-FW-REQ-0170
   --    @Req : REG_CY_MUX_SQ_KI_KNORM
   -- ------------------------------------------------------------------------------------------------------
   I_mem_kiknm_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_KIKNM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_KIKNM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_KIKNM     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.kiknm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.kiknm , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_kiknm_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_kiknm_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => mux_ki_knorm_p       , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory MUX ki(p)*knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_kiknm_prm.add     <= i_mem_kiknm_prm_add;
   mem_kiknm_prm.we      <= c_LOW_LEV;
   mem_kiknm_prm.cs      <= c_HGH_LEV;
   mem_kiknm_prm.data_w  <= c_ZERO(mem_kiknm_prm.data_w'range);

   --! Memory ki(p)*knorm(p), ping-pong buffer bit
   P_mem_kiknm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_kiknm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_kiknm_pp_rdy = c_HGH_LEV then
            mem_kiknm_prm.pp   <= mem_kiknm_pp;

         end if;

      end if;

   end process P_mem_kiknm_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameters AMP ki*knorm
   -- ------------------------------------------------------------------------------------------------------
   P_amp_ki_knorm : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         amp_ki_knorm   <= c_EP_CMD_DEF_SAKKM;

      elsif rising_edge(i_clk) then
         if mem_kiknm_pp_rdy_r(mem_kiknm_pp_rdy_r'high) = c_HGH_LEV then
            amp_ki_knorm   <= i_sakkm;

         end if;

      end if;

   end process P_amp_ki_knorm;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameter ki*knorm select
   --    @Req : DRE-DMX-FW-REQ-0392
   -- ------------------------------------------------------------------------------------------------------
   P_ki_knorm_p : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         ki_knorm_p <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_KIKNM(0), ki_knorm_p'length));

      elsif rising_edge(i_clk) then
         if i_squid_amp_close = c_HGH_LEV then
            ki_knorm_p <= amp_ki_knorm;

         else
            ki_knorm_p <= mux_ki_knorm_p;

         end if;

      end if;

   end process P_ki_knorm_p;

   ki_knorm_p_aln <= std_logic_vector(resize(unsigned(ki_knorm_p), ki_knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: fgn(p) = gain*ki(p)*knorm(p) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0147
   --    @Req : DRE-DMX-FW-REQ-0148
   -- ------------------------------------------------------------------------------------------------------
   I_fgn_p: entity work.dsp generic map (
         g_PORTA_S            => c_DFLD_SMIGN_COL_S   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_KIKNM_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_DFLD_SMIGN_COL_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_FGN_P_S + 1        , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_ENA  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_MULT_ALU_SAT_NU    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => i_squid_gain         , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => ki_knorm_p_aln       , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_DFLD_SMIGN_COL_S-1  downto 0), -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_DFLD_KIKNM_PIX_S    downto 0), -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => fgn_p                , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_fgn_p_rnd_sat: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_FGN_P_S + 1          -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => fgn_p                , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_fgn_p                -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters MUX knorm(p)
   --    @Req : REG_CY_MUX_SQ_KNORM
   -- ------------------------------------------------------------------------------------------------------
   I_mem_knorm_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_KNORM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_KNORM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_KNORM     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.knorm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.knorm , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_knorm_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_knorm_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => mux_knorm_p          , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory MUX knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_knorm_prm.add     <= i_mem_knorm_prm_add;
   mem_knorm_prm.we      <= c_LOW_LEV;
   mem_knorm_prm.cs      <= c_HGH_LEV;
   mem_knorm_prm.data_w  <= c_ZERO(mem_knorm_prm.data_w'range);

   --! Memory knorm(p), ping-pong buffer bit
   P_mem_knorm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_knorm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_knorm_pp_rdy = c_HGH_LEV then
            mem_knorm_prm.pp   <= mem_knorm_pp;

         end if;

      end if;

   end process P_mem_knorm_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameters AMP knorm
   --    @Req : REG_CY_AMP_SQ_KNORM
   -- ------------------------------------------------------------------------------------------------------
   P_amp_knorm : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         amp_knorm      <= c_EP_CMD_DEF_SAKRM;

      elsif rising_edge(i_clk) then
         if mem_knorm_pp_rdy_r(mem_knorm_pp_rdy_r'high) = c_HGH_LEV then
            amp_knorm   <= i_sakrm;

         end if;

      end if;

   end process P_amp_knorm;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameter knorm select
   --    @Req : DRE-DMX-FW-REQ-0392
   --    @Req : DRE-DMX-FW-REQ-0393
   -- ------------------------------------------------------------------------------------------------------
   P_knorm_p : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         knorm_p <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_KNORM(0), knorm_p'length));

      elsif rising_edge(i_clk) then
         if i_squid_amp_close = c_HGH_LEV then
            knorm_p <= amp_knorm;

         else
            knorm_p <= mux_knorm_p;

         end if;

      end if;

   end process P_knorm_p;

   knorm_p_aln <= std_logic_vector(resize(unsigned(knorm_p), knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: sgn(p) = gain*knorm(p) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0147
   --    @Req : DRE-DMX-FW-REQ-0148
   -- ------------------------------------------------------------------------------------------------------
   I_sgn_p: entity work.dsp generic map (
         g_PORTA_S            => c_DFLD_SMIGN_COL_S   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_KNORM_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_DFLD_SMIGN_COL_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_SGN_P_S + 1        , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_ENA  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_MULT_ALU_SAT_NU    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => i_squid_gain         , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => knorm_p_aln          , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_DFLD_SMIGN_COL_S-1  downto 0), -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_DFLD_KNORM_PIX_S    downto 0), -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => sgn_p                , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_sgn_p_rnd_sat: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_SGN_P_S + 1          -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => sgn_p                , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_sgn_p                -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for smfb0(p)
   --    @Req : DRE-DMX-FW-REQ-0200
   --    @Req : REG_CY_MUX_SQ_FB0
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smfb0_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMFB0_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMFB0     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.smfb0      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.smfb0 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smfb0_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smfb0_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => smfb0_p              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory smfb0(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smfb0_prm.add     <= i_mem_smfb0_prm_add;
   mem_smfb0_prm.we      <= c_LOW_LEV;
   mem_smfb0_prm.cs      <= c_HGH_LEV;
   mem_smfb0_prm.data_w  <= c_ZERO(mem_smfb0_prm.data_w'range);

   --! Memory smfb0(p), ping-pong buffer bit
   P_mem_smfb0_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_smfb0_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_smfb0_pp_rdy = c_HGH_LEV then
            mem_smfb0_prm.pp   <= mem_smfb0_pp;

         end if;

      end if;

   end process P_mem_smfb0_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameters AMP fb0
   -- ------------------------------------------------------------------------------------------------------
   P_safb0 : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         safb0    <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk) then
         if mem_smfb0_pp_rdy_r(mem_smfb0_pp_rdy_r'high) = c_HGH_LEV then
            safb0 <= i_saofc;

         end if;

      end if;

   end process P_safb0;

   I_safb0_aln : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SAOFC_COL_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_DFLD_SMFB0_PIX_S-1   -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => safb0                , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => safb0_aln            , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameter FB0 select
   -- ------------------------------------------------------------------------------------------------------
   P_fb0_p_aln : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fb0_p_aln <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_SMFB0(0), fb0_p_aln'length));

      elsif rising_edge(i_clk) then
         if i_squid_amp_close = c_HGH_LEV then
            fb0_p_aln <= std_logic_vector(resize(unsigned(safb0_aln), fb0_p_aln'length));

         else
            fb0_p_aln <= smfb0_p;

         end if;

      end if;

   end process P_fb0_p_aln;

   I_fb0_fb_aln : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FB_PN_S              -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => fb0_p_aln            , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => o_fb0_fb_aln         , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   I_fb0_rl_aln : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SQM_DATA_FBK_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => fb0_p_aln            , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => o_fb0_rl_aln         , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters Elp(p)
   --    @Req : DRE-DMX-FW-REQ-0190
   --    @Req : REG_CY_MUX_SQ_LOCKPOINT_V
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smlkv_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMLKV_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMLKV_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMLKV     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.smlkv      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.smlkv , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smlkv_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smlkv_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => elp_p                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- Parameter Elp(p) aligned on E(p,n)
   I_elp_p_aln : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SMLKV_PIX_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_ADC_SMP_AVE_S        -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => elp_p                , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => elp_p_aln            , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- Parameter -Elp(p) aligned on E(p,n) with saturation on the most low value
   P_minus_elp_p_aln : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_minus_elp_p_aln <= c_ZERO(o_minus_elp_p_aln'range);

      elsif rising_edge(i_clk) then
         if (elp_p(elp_p'high) = c_HGH_LEV and elp_p(elp_p'high-1 downto 0) = c_ZERO(elp_p'high-1 downto 0)) then
            o_minus_elp_p_aln(o_minus_elp_p_aln'high)             <= c_LOW_LEV;
            o_minus_elp_p_aln(o_minus_elp_p_aln'high-1 downto 0)  <= (others => c_HGH_LEV);

         else
            o_minus_elp_p_aln <= std_logic_vector(signed(c_ZERO(o_minus_elp_p_aln'range)) - signed(elp_p_aln));

         end if;

      end if;

   end process P_minus_elp_p_aln;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Elp(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smlkv_prm.add     <= i_mem_smlkv_prm_add;
   mem_smlkv_prm.we      <= c_LOW_LEV;
   mem_smlkv_prm.cs      <= c_HGH_LEV;
   mem_smlkv_prm.data_w  <= c_ZERO(mem_smlkv_prm.data_w'range);

   --! Memory Elp(p), ping-pong buffer bit
   P_mem_smlkv_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_smlkv_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_smlkv_pp_rdy = c_HGH_LEV then
            mem_smlkv_prm.pp   <= mem_smlkv_pp;

         end if;

      end if;

   end process P_mem_smlkv_prm_pp;

end architecture RTL;
