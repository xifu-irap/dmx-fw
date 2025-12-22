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
--!   @file                   sqa_fbk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP Feedback management
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

entity sqa_fbk_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         i_saofm              : in     std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                      ; --! SQUID AMP offset mode
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset

         i_saomd              : in     std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                      ; --! SQUID AMP offset MUX delay
         i_test_pattern       : in     std_logic_vector(  c_SQA_DAC_DATA_S-1 downto 0)                      ; --! Test pattern
         i_sqm_dta_err_frst   : in     std_logic                                                            ; --! SQUID MUX Data error corrected first pixel
         i_sqa_fb_close       : in     std_logic_vector(  c_SQA_DAC_DATA_S+1 downto 0)                      ; --! SQUID AMP feedback close mode
         i_sqm_dta_err_cor_cs : in     std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_saoff          : in     t_mem(
                                       add(              c_MEM_SAOFF_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SAOFF_PIX_S-1 downto 0))                     ; --! SQUID AMP lockpoint fine offset: memory inputs
         o_saoff_data         : out    std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                      ; --! SQUID AMP lockpoint fine offset: data read

         o_sqa_fbk_mux        : out    std_logic_vector(   c_SQA_DAC_MUX_S-1 downto 0)                      ; --! SQUID AMP Feedback Multiplexer
         o_sqa_fbk_off        : out    std_logic_vector(  c_SQA_DAC_DATA_S-1 downto 0)                      ; --! SQUID AMP coarse offset
         o_sqa_pls_cnt_init   : out    std_logic_vector(   c_SQA_PLS_CNT_S-1 downto 0)                        --! SQUID AMP Pulse counter initialization

   );
end entity sqa_fbk_mgt;

architecture RTL of sqa_fbk_mgt is
constant c_MINUSTWO           : std_logic_vector(c_SQA_PLS_CNT_S-1 downto 0):=
                                std_logic_vector(to_signed(-2, c_SQA_PLS_CNT_S))                            ; --! Minus two value

constant c_PLS_RW_CNT_NB_VAL  : integer:= c_PIXEL_DAC_NB_CYC * c_MUX_FACT/2                                 ; --! Pulse by row counter: number of value
constant c_PLS_RW_CNT_MAX_VAL : integer:= c_PLS_RW_CNT_NB_VAL - 2                                           ; --! Pulse by row counter: maximal value
constant c_PLS_RW_CNT_INIT    : integer:= c_PLS_RW_CNT_MAX_VAL - c_SAD_SYNC_DATA_NPER/2 - 4                 ; --! Pulse by row counter: initialization value
constant c_PLS_RW_CNT_S       : integer:= log2_ceil(c_PLS_RW_CNT_MAX_VAL + 1) + 1                           ; --! Pulse by row counter: size bus (signed)

constant c_FRAME_NB_CYC       : integer := c_MUX_FACT * c_PIXEL_DAC_NB_CYC                                  ; --! Frame period number
constant c_FRAME_NB_CYC_S     : integer := log2_ceil(c_FRAME_NB_CYC)                                        ; --! Frame period number bus size
constant c_SAOMD_POSITIVE_S   : integer := c_FRAME_NB_CYC_S + 1                                             ; --! SQUID AMP offset MUX delay in positive bus size
constant c_SAOMD_CMP_R_S      : integer := 2 * c_DSP_NPER + 2                                               ; --! SQUID AMP offset MUX delay compare register bus size

constant c_PLS_CNT_INIT_SHT   : integer := 2                                                                ; --! Pulse counter initialization number cycle shift
constant c_PLS_CNT_INIT_SHT_V : std_logic_vector(c_SAOMD_POSITIVE_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_PLS_CNT_INIT_SHT , c_SAOMD_POSITIVE_S))      ; --! Pulse counter initialization number cycle shift vector

constant c_FBK_PLS_CNT_NB_VAL : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Feedback Pulse counter: number of value
constant c_FBK_PLS_CNT_MX_VAL : integer:= c_FBK_PLS_CNT_NB_VAL - 2                                          ; --! Feedback Pulse counter: maximal value

constant c_PXL_DAC_NCYC_INV   : integer := div_round(2**(c_MULT_ALU_PORTA_S), c_PIXEL_DAC_NB_CYC)           ; --! DAC clock period number allocated to one pixel acquisition inverted
constant c_PXL_DAC_NCYC_INV_S : integer := log2_ceil(c_PXL_DAC_NCYC_INV) + 1                                ; --! DAC clock period number allocated to one pixel acquisition inverted bus size
constant c_PXL_DAC_NCYC_INV_V : std_logic_vector(c_PXL_DAC_NCYC_INV_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_PXL_DAC_NCYC_INV , c_PXL_DAC_NCYC_INV_S))    ; --! DAC clock period number allocated to one pixel acquisition inverted vector
constant c_PXL_DAC_NCYC_NEG_V : std_logic_vector(c_MULT_ALU_PORTA_S-1 downto 0) :=
                                std_logic_vector(to_signed(-c_PIXEL_DAC_NB_CYC , c_MULT_ALU_PORTA_S))       ; --! DAC clock period number allocated to one pixel acquisition negative vector

constant c_FBK_PXL_POS_INIT   : integer:= c_SQA_PXL_POS_MX_VAL - 1                                          ; --! Feedback Pixel position: initialization value
constant c_FBK_PXL_POS_SHIFT  : integer:= 2                                                                 ; --! Feedback Pixel position: shift

signal   saomd_r              : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                             ; --! SQUID AMP offset MUX delay register
signal   saomd_cmp            : std_logic                                                                   ; --! SQUID AMP offset MUX delay compare
signal   saomd_cmp_r          : std_logic_vector(   c_SAOMD_CMP_R_S-1 downto 0)                             ; --! SQUID AMP offset MUX delay compare register
signal   saomd_positive       : std_logic_vector(c_SAOMD_POSITIVE_S-1 downto 0)                             ; --! SQUID AMP offset MUX delay in positive

signal   pls_rw_cnt           : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter

signal   pixel_pos_div        : std_logic_vector(c_SQA_PXL_POS_S-1 downto 0)                                ; --! Pixel position division result
signal   sqa_pixel_pos_init   : std_logic_vector(c_SQA_PXL_POS_S-1 downto 0)                                ; --! SQUID AMP Pixel position initialization
signal   fbk_pixel_pos_init   : std_logic_vector(c_SQA_PXL_POS_S-1 downto 0)                                ; --! Feedback Pixel position initialization
signal   pixel_pos            : std_logic_vector(c_SQA_PXL_POS_S-1 downto 0)                                ; --! Pixel position
signal   pixel_pos_init       : std_logic_vector(c_SQA_PXL_POS_S-1 downto 0)                                ; --! Pixel position initialization
signal   pixel_pos_inc        : std_logic_vector(c_SQA_PXL_POS_S-2 downto 0)                                ; --! Pixel position increasing

signal   sqa_pls_cnt_init     : std_logic_vector(c_SQA_PLS_CNT_S-1 downto 0)                                ; --! SQUID AMP Pulse shaping counter initialization
signal   pls_cnt_div_rem      : std_logic_vector(c_SQA_PLS_CNT_S-1 downto 0)                                ; --! Pulse counter division remainder
signal   pls_cnt              : std_logic_vector(c_SQA_PLS_CNT_S-2 downto 0)                                ; --! Feedback Pulse counter

signal   mem_saoff_pp         : std_logic                                                                   ; --! SQUID AMP lockpoint fine offset, TC/HK side: ping-pong buffer bit
signal   mem_saoff_prm        : t_mem(
                                add(           c_MEM_SAOFF_ADD_S-1 downto 0),
                                data_w(       c_DFLD_SAOFF_PIX_S-1 downto 0))                               ; --! SQUID AMP lockpoint fine offset, getting parameter side: memory inputs

signal   saofm_sync           : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                             ; --! SQUID AMP offset mode synchronized on first Pixel sequence
signal   saofm_close          : std_logic                                                                   ; --! SQUID AMP offset mode in close mode
signal   saofm_close_sync     : std_logic                                                                   ; --! SQUID AMP offset mode in close mode synchronized
signal   sqa_fb_close_fst_frm : std_logic                                                                   ; --! SQUID AMP feedback close mode first frame
signal   sqa_fb_close_rnd_sat : std_logic_vector(  c_SQA_DAC_DATA_S   downto 0)                             ; --! SQUID AMP feedback close mode round with saturation
signal   sqa_fb_close_ptve    : std_logic_vector(  c_SQA_DAC_DATA_S-1 downto 0)                             ; --! SQUID AMP feedback close mode positive
signal   saoff                : std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                             ; --! SQUID AMP lockpoint fine offset
signal   saoff_off_mode       : std_logic_vector(   c_SQA_DAC_MUX_S-1 downto 0)                             ; --! SQUID AMP lockpoint fine offset, SQUID AMP in offset mode
signal   saoff_ptr            : std_logic_vector(   c_SQA_DAC_MUX_S-1 downto 0)                             ; --! SQUID AMP lockpoint fine offset, SQUID AMP in test pattern mode

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_rw_cnt : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = c_HGH_LEV then
            pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_INIT, pls_rw_cnt'length));

         elsif pls_rw_cnt(pls_rw_cnt'high) = c_HGH_LEV then
            pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

         else
            pls_rw_cnt <= std_logic_vector(signed(pls_rw_cnt) - 1);

         end if;

      end if;

   end process P_pls_rw_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP offset MUX delay
   -- ------------------------------------------------------------------------------------------------------
   P_saomd_cmp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         saomd_r     <= c_EP_CMD_DEF_SAOMD;
         saomd_cmp   <= c_LOW_LEV;
         saomd_cmp_r <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         saomd_r  <= i_saomd;

         if saomd_r /= i_saomd then
            saomd_cmp <= c_HGH_LEV;

         else
            saomd_cmp <= c_LOW_LEV;

         end if;
         saomd_cmp_r <= saomd_cmp_r(saomd_cmp_r'high-1 downto 0) & saomd_cmp;

      end if;

   end process P_saomd_cmp;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP offset MUX delay in positive
   -- ------------------------------------------------------------------------------------------------------
   P_saomd_positive : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         saomd_positive  <= c_ZERO(saomd_positive'range);

      elsif rising_edge(i_clk) then
         if i_saomd(i_saomd'high) = c_HGH_LEV then
            saomd_positive <= std_logic_vector(signed(to_unsigned(c_FRAME_NB_CYC-c_SAM_SYNC_DATA_NPER-c_PLS_CNT_INIT_SHT, saomd_positive'length))
                                      + resize(signed(i_saomd), saomd_positive'length));

         else
            saomd_positive <= std_logic_vector(resize(signed(i_saomd), saomd_positive'length) - signed(to_unsigned(c_SAM_SYNC_DATA_NPER + c_PLS_CNT_INIT_SHT, saomd_positive'length)));

         end if;

      end if;

   end process P_saomd_positive;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position division result
   -- ------------------------------------------------------------------------------------------------------
   I_pixel_pos_div: entity work.dsp generic map (
         g_PORTA_S            => c_PXL_DAC_NCYC_INV_S , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SAOMD_POSITIVE_S   , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_MULT_ALU_PORTC_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_SQA_PXL_POS_S      , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_ENA  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_MULT_ALU_SAT_NU    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => c_PXL_DAC_NCYC_INV_V , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => saomd_positive       , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_MULT_ALU_PORTC_S-1 downto 0),  -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_PLS_CNT_INIT_SHT_V , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => pixel_pos_div        , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter division remainder
   -- ------------------------------------------------------------------------------------------------------
   I_pls_cnt_div_rem: entity work.dsp generic map (
         g_PORTA_S            => c_MULT_ALU_PORTA_S   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SQA_PXL_POS_S      , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SAOMD_POSITIVE_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_SQA_PLS_CNT_S      , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_DIS  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_SQA_PLS_CNT_S      , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => c_PXL_DAC_NCYC_NEG_V , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => pixel_pos_div        , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => saomd_positive       , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_SQA_PXL_POS_S-1 downto 0),     -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => pls_cnt_div_rem      , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP Pixel position initialization
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_pixel_pos_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqa_pixel_pos_init <= c_MINUSONE(sqa_pixel_pos_init'range);

      elsif rising_edge(i_clk) then
         if pls_cnt_div_rem = c_MINUSTWO then
            sqa_pixel_pos_init <= std_logic_vector(signed(pixel_pos_div) - 1);

         else
            sqa_pixel_pos_init <= pixel_pos_div;

         end if;

      end if;

   end process P_sqa_pixel_pos_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Internal pixel position initialization
   -- ------------------------------------------------------------------------------------------------------
   P_fbk_pixel_pos_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_FBK_PXL_POS_INIT, fbk_pixel_pos_init'length));

      elsif rising_edge(i_clk) then
         if    sqa_pixel_pos_init = c_ZERO(sqa_pixel_pos_init'range) then
            fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_SQA_PXL_POS_MX_VAL, fbk_pixel_pos_init'length));

         elsif sqa_pixel_pos_init = c_MINUSONE(sqa_pixel_pos_init'range) then
            fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_SQA_PXL_POS_MX_VAL-1, fbk_pixel_pos_init'length));

         else
            fbk_pixel_pos_init <= std_logic_vector(signed(sqa_pixel_pos_init) - c_FBK_PXL_POS_SHIFT);

         end if;

      end if;

   end process P_fbk_pixel_pos_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP Pulse counter initialization
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_pls_cnt_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqa_pls_cnt_init  <= c_MINUSONE(sqa_pls_cnt_init'range);

      elsif rising_edge(i_clk) then
         if pls_cnt_div_rem = c_MINUSTWO then
            sqa_pls_cnt_init <= std_logic_vector(to_unsigned(c_SQA_PLS_CNT_MX_VAL, sqa_pls_cnt_init'length));

         else
            sqa_pls_cnt_init <= pls_cnt_div_rem;

         end if;

      end if;

   end process P_sqa_pls_cnt_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP initialization outputs
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pixel_pos_init       <= std_logic_vector(to_signed(c_FBK_PXL_POS_INIT, pixel_pos_init'length));
         o_sqa_pls_cnt_init   <= std_logic_vector(to_signed(c_SQA_PLS_CNT_INIT, o_sqa_pls_cnt_init'length));

      elsif rising_edge(i_clk) then
         if saomd_cmp_r(saomd_cmp_r'high) = c_HGH_LEV then
            pixel_pos_init       <= fbk_pixel_pos_init;
            o_sqa_pls_cnt_init   <= sqa_pls_cnt_init;

         end if;

      end if;

   end process P_sqa_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   --    @Req : DRE-DMX-FW-REQ-0375
   --    @Req : DRE-DMX-FW-REQ-0385
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pls_cnt  <= std_logic_vector(to_unsigned(c_FBK_PLS_CNT_MX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = c_HGH_LEV then
            pls_cnt <= o_sqa_pls_cnt_init(o_sqa_pls_cnt_init'high downto 1);

         elsif pls_cnt(pls_cnt'high) = c_HGH_LEV then
            pls_cnt <= std_logic_vector(to_unsigned(c_FBK_PLS_CNT_MX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   --    @Req : DRE-DMX-FW-REQ-0385
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pixel_pos   <= c_MINUSONE(pixel_pos'range);

      elsif rising_edge(i_clk) then
         if i_sync_re = c_HGH_LEV then
            pixel_pos <= pixel_pos_init;

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(to_unsigned(c_SQA_PXL_POS_MX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   pixel_pos_inc <= std_logic_vector(resize(unsigned(to_signed(c_SQA_PXL_POS_MX_VAL, pixel_pos'length) - signed(pixel_pos)), pixel_pos_inc'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals synchronized on first Pixel sequence
   --    @Req : DRE-DMX-FW-REQ-0385
   -- ------------------------------------------------------------------------------------------------------
   P_sig_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         saofm_sync           <= c_DST_SAOFM_OFF;
         mem_saoff_prm.pp     <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = c_HGH_LEV then
            saofm_sync        <= i_saofm;
            mem_saoff_prm.pp  <= mem_saoff_pp;

         end if;

      end if;

   end process P_sig_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID AMP lockpoint fine offset
   --    @Req : REG_CY_AMP_SQ_OFFSET_FINE
   --    @Req : DRE-DMX-FW-REQ-0300
   --    @Req : DRE-DMX-FW-REQ-0305
   -- ------------------------------------------------------------------------------------------------------
   I_mem_sqa_pxl_lkp: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SAOFF_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SAOFF_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SAOFF     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_saoff          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_saoff_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_saoff_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_saoff_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => saoff                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   saoff_off_mode <= saoff(c_SQA_DAC_MUX_S-1 downto 0);
   saoff_ptr      <= saoff(saoff'high        downto c_SQA_DAC_MUX_S);

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory SQUID AMP lockpoint fine offset signals: memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_saoff_prm.add     <= pixel_pos_inc;
   mem_saoff_prm.we      <= c_LOW_LEV;
   mem_saoff_prm.cs      <= c_HGH_LEV;
   mem_saoff_prm.data_w  <= c_ZERO(mem_saoff_prm.data_w'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP feedback Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0305
   --    @Req : DRE-DMX-FW-REQ-0330
   --    @Req : DRE-DMX-FW-REQ-0360
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fbk_mux : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqa_fbk_mux <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         if saofm_sync = c_DST_SAOFM_OFFSET then
            o_sqa_fbk_mux <= saoff_off_mode;

         elsif saofm_sync = c_DST_SAOFM_TEST then
            o_sqa_fbk_mux <= saoff_ptr;

         else
            o_sqa_fbk_mux <= (others => c_LOW_LEV);

         end if;

      end if;

   end process P_sqa_fbk_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP close loop mode
   -- ------------------------------------------------------------------------------------------------------
   I_sqa_fb_clse: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_SQA_DAC_DATA_S+2     -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => i_sqa_fb_close       , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => sqa_fb_close_rnd_sat   -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

    --! SQUID AMP close loop mode: Saturation in case of negative data value
   P_sqa_fb_close_ptve : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqa_fb_close_ptve <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk) then
         if (i_sqm_dta_err_cor_cs and i_sqm_dta_err_frst) = c_HGH_LEV then
            if sqa_fb_close_rnd_sat(sqa_fb_close_rnd_sat'high) = c_HGH_LEV then
               sqa_fb_close_ptve <= c_ZERO(sqa_fb_close_ptve'range);

            else
               sqa_fb_close_ptve <= sqa_fb_close_rnd_sat(sqa_fb_close_ptve'range);

            end if;

         end if;

      end if;

   end process P_sqa_fb_close_ptve;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP feedback close mode first frame
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fb_cls_fst_frm : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         saofm_close_sync     <= c_LOW_LEV;
         sqa_fb_close_fst_frm <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if pls_rw_cnt = c_ZERO(pls_rw_cnt'range) then

            if i_saofm = c_DST_SAOFM_CLOSE then
               saofm_close_sync     <= c_HGH_LEV;

            else
               saofm_close_sync     <= c_LOW_LEV;

            end if;

            sqa_fb_close_fst_frm <= saofm_close and not(saofm_close_sync);

         end if;

      end if;

   end process P_sqa_fb_cls_fst_frm;

   saofm_close <= c_HGH_LEV when i_saofm = c_DST_SAOFM_CLOSE else c_LOW_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP coarse offset
   --    @Req : DRE-DMX-FW-REQ-0290
   --    @Req : DRE-DMX-FW-REQ-0330
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fbk_off : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqa_fbk_off  <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk) then
         if pls_rw_cnt(pls_rw_cnt'high) = c_HGH_LEV then

            if (i_saofm = c_DST_SAOFM_OFFSET) or ((i_saofm = c_DST_SAOFM_CLOSE) and  sqa_fb_close_fst_frm = c_HGH_LEV) then
               o_sqa_fbk_off <= i_saofc;

            elsif i_saofm = c_DST_SAOFM_CLOSE then
               o_sqa_fbk_off <= sqa_fb_close_ptve;

            elsif i_saofm = c_DST_SAOFM_TEST then
               o_sqa_fbk_off <= std_logic_vector(signed(i_test_pattern) + to_signed(c_SQA_DAC_MDL_POINT, o_sqa_fbk_off'length));

            else
               o_sqa_fbk_off <= c_EP_CMD_DEF_SAOFC;

            end if;

         end if;

      end if;

   end process P_sqa_fbk_off;

end architecture RTL;
