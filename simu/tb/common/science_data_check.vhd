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
--!   @file                   science_data_check.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_ep_cmd.all;

entity science_data_check is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_smfbd              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)            ; --! SQUID MUX feedback delay
         i_saomd              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)            ; --! SQUID AMP offset MUX delay
         i_sqm_fbm_cls_lp_n   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)
         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         i_frm_cnt_sc_rst     : in     std_logic                                                            ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         i_adc_dmp_mem_add    : in     std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   : in     std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         i_science_mem_data   : in     std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! Science  memory for data compare: data
         i_adc_dmp_mem_cs     : in     std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science Data: Control word
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! Science Data: Data
         i_science_data_rdy   : in     std_logic                                                            ; --! Science Data Ready ('0' = Inactive, '1' = Active)

         o_science_data_err   : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! Science data error ('0' = No error, '1' = Error)
   );
end entity science_data_check;

architecture Behavioral of science_data_check is
constant c_FRAME_NB_CYC       : integer := c_MUX_FACT * c_PIXEL_DAC_NB_CYC                                  ; --! Frame period number
constant c_SC_DATA_R_PIP_NB   : integer:= 3                                                                 ; --! Science Data register: pipeline number

constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_ADC_NB_CYC                                                ; --! Pulse counter (Dump case): number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter (Dump case): maximal value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter (Dump case): size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 1                                                    ; --! Pixel position (Dump case): maximal value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)                                  ; --! Pixel position (Dump case): size bus

constant c_SEQ_CNT_MAX_VAL    : integer:= c_DMP_SEQ_ACQ_NB - 1                                              ; --! Sequence counter (Dump case): maximal value
constant c_SEQ_CNT_S          : integer:= log2_ceil(c_SEQ_CNT_MAX_VAL + 1)                                  ; --! Sequence counter (Dump case): size bus

constant c_PLS_CNT_SC_NB_VAL  : integer:= c_MUX_FACT                                                        ; --! Pulse counter (Science case): number of value
constant c_PLS_CNT_SC_MAX_VAL : integer:= c_PLS_CNT_SC_NB_VAL - 1                                           ; --! Pulse counter (Science case): maximal value
constant c_PLS_CNT_SC_S       : integer:= log2_ceil(c_PLS_CNT_SC_MAX_VAL + 1)                               ; --! Pulse counter (Science case): size bus

constant c_FRM_CNT_SC_NB_VAL  : integer:= c_MEM_SC_FRM_NB                                                   ; --! Frame counter (Science case): number of value
constant c_FRM_CNT_SC_MAX_VAL : integer:= c_FRM_CNT_SC_NB_VAL - 1                                           ; --! Frame counter (Science case): maximal value
constant c_FRM_CNT_SC_S       : integer:= log2_ceil(c_FRM_CNT_SC_MAX_VAL + 1)                               ; --! Frame counter (Science case): size bus

type     t_tm_mode_sel          is  (idle, science, error_sig, dump, test_pattern)                          ; --! Mode selection type

signal   squid_amp_mux_del    : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)                   ; --! SQUID MUX/AMP Feedback delay
signal   squid_del            : t_slv_arr(0 to c_NB_COL-1)(c_FRAME_NB_CYC-1 downto 0)                       ; --! SQUID Feedback delay

signal   pls_cnt              : std_logic_vector(            c_PLS_CNT_S-1 downto 0)                        ; --! Pulse counter (Dump case)
signal   pls_cnt_pos_init     : t_slv_arr(0 to c_NB_COL-1)(c_FRAME_NB_CYC-1 downto 0)                       ; --! Pulse counter (Dump case) position initialization
signal   pls_cnt_pos_del      : t_slv_arr(0 to c_NB_COL-1)(  c_PLS_CNT_S-1 downto 0)                        ; --! Pulse counter (Dump case) position with delay
signal   pixel_pos            : std_logic_vector(          c_PIXEL_POS_S-1 downto 0)                        ; --! Pixel position (Dump case)
signal   pixel_pos_init       : t_slv_arr(0 to c_NB_COL-1)(c_PIXEL_POS_S-1 downto 0)                        ; --! Pixel position (Dump case) initialization
signal   pixel_pos_del        : t_slv_arr(0 to c_NB_COL-1)(c_PIXEL_POS_S-1 downto 0)                        ; --! Pixel position (Dump case) with delay
signal   seq_cnt              : std_logic_vector(            c_SEQ_CNT_S-1 downto 0)                        ; --! Sequence counter (Dump case)

signal   frm_cnt_sc_rst_lt    : std_logic                                                                   ; --! Frame counter science reset latch
signal   pls_cnt_sc           : std_logic_vector(         c_PLS_CNT_SC_S-1 downto 0)                        ; --! Pulse counter (Science case)
signal   frm_cnt_sc           : std_logic_vector(         c_FRM_CNT_SC_S-1 downto 0)                        ; --! Frame counter (Science case)

signal   science_dta_ctrl_lst : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Science Data: Control word last

signal   sm_mode_sel          : t_tm_mode_sel                                                               ; --! Mode selection FSM

signal   science_data_rdy_r   : std_logic_vector(1 downto 0)                                                ; --! Science Data Ready register ('0' = Inactive, '1' = Active)
signal   science_data_r       : t_slv_arr_tab(0 to c_NB_COL-1)(0 to c_SC_DATA_R_PIP_NB-1)
                                             (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)                ; --! Science Data register


signal   mem_adc_dump_dta2cmp : t_slv_arr_tab(0 to c_NB_COL-1)(0 to c_MEM_SC_FRM_NB * c_MUX_FACT-1)
                                             (c_SQM_ADC_DATA_S+1 downto 0):=
                                             (others => (others => c_ZERO(c_SQM_ADC_DATA_S+1 downto 0)))    ; --! Dual port memory for adc dump data to compare
signal   mem_science_dta2cmp  : t_slv_arr_tab(0 to c_NB_COL-1)(0 to c_MEM_SC_FRM_NB * c_MUX_FACT-1)
                                             (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0):= (others =>
                                         (others => c_ZERO(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0))) ; --! Dual port memory for science data to compare

signal   adc_dump_dta2cmp     : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! adc dump data to compare
signal   adc_dump_dta2cmp_lst : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! adc dump data to compare last value
signal   science_dta2cmp      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)   ; --! science data to compare

signal   science_data_err     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Science data error ('0' = No error, '1' = Error)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter (Dump case)
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         pls_cnt  <= c_MINUSONE(pls_cnt'range);

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = c_HGH_LEV then

            if    i_science_data_ctrl /= c_SC_CTRL_DTW then
               pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));

            elsif pls_cnt(pls_cnt'high) = c_HGH_LEV and (
                  pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) or (
                  pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) and
                  seq_cnt   < std_logic_vector(to_unsigned(c_SEQ_CNT_MAX_VAL   , seq_cnt'length))  )) then
               pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));

            elsif pls_cnt(pls_cnt'high) = c_LOW_LEV then
               pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

            end if;

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position (Dump case)
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         pixel_pos   <= std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length));

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = c_HGH_LEV then

            if    i_science_data_ctrl /= c_SC_CTRL_DTW then
               pixel_pos <= c_ZERO(pixel_pos'range);

            elsif pls_cnt(pls_cnt'high) = c_HGH_LEV and
                  pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) and
                  seq_cnt   < std_logic_vector(to_unsigned(c_SEQ_CNT_MAX_VAL   , seq_cnt'length))   then
               pixel_pos <= c_ZERO(pixel_pos'range);

            elsif pls_cnt(pls_cnt'high) = c_HGH_LEV and pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) then
               pixel_pos <= std_logic_vector(unsigned(pixel_pos) + 1);

            end if;

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Sequence counter (Dump case)
   -- ------------------------------------------------------------------------------------------------------
   P_seq_cnt : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         seq_cnt   <= c_ZERO(seq_cnt'range);

      elsif rising_edge(i_clk_science) then
         if i_science_data_rdy = c_HGH_LEV then

            if i_science_data_ctrl /= c_SC_CTRL_DTW then
               seq_cnt <= c_ZERO(seq_cnt'range);

            elsif pls_cnt(pls_cnt'high) = c_HGH_LEV and pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) then
               seq_cnt <= std_logic_vector(unsigned(seq_cnt) + 1);

            end if;

         end if;

      end if;

   end process P_seq_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter (Science case)
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt_sc : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         pls_cnt_sc  <= std_logic_vector(to_unsigned(c_PLS_CNT_SC_MAX_VAL, pls_cnt_sc'length));

      elsif rising_edge(i_clk_science) then
         if science_data_rdy_r(science_data_rdy_r'low) = c_HGH_LEV then

            if    i_science_data_ctrl = c_SC_CTRL_FWA or i_science_data_ctrl = c_SC_CTRL_FWS or
                 (i_science_data_ctrl = c_SC_CTRL_TPT and science_dta_ctrl_lst = c_SC_CTRL_DTW) then
               pls_cnt_sc <= c_ZERO(pls_cnt_sc'range);

            elsif pls_cnt_sc < std_logic_vector(to_unsigned(c_PLS_CNT_SC_MAX_VAL, pls_cnt_sc'length)) then
               pls_cnt_sc <= std_logic_vector(unsigned(pls_cnt_sc) + 1);

            end if;

         end if;

      end if;

   end process P_pls_cnt_sc;

   -- ------------------------------------------------------------------------------------------------------
   --!   Frame counter science reset latch
   -- ------------------------------------------------------------------------------------------------------
   P_frm_cnt_sc_rst_lt : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         frm_cnt_sc_rst_lt  <= c_LOW_LEV;

      elsif rising_edge(i_clk_science) then
         if i_frm_cnt_sc_rst = c_HGH_LEV then
            frm_cnt_sc_rst_lt <= c_HGH_LEV;

         elsif science_data_rdy_r(science_data_rdy_r'low) = c_HGH_LEV and pls_cnt_sc = std_logic_vector(to_unsigned(c_PLS_CNT_SC_MAX_VAL, pls_cnt_sc'length)) then
            frm_cnt_sc_rst_lt  <= c_LOW_LEV;

         end if;

      end if;

   end process P_frm_cnt_sc_rst_lt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Frame counter (Science case)
   -- ------------------------------------------------------------------------------------------------------
   P_frm_cnt_sc : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         frm_cnt_sc  <= c_ZERO(frm_cnt_sc'range);

      elsif rising_edge(i_clk_science) then
         if science_data_rdy_r(science_data_rdy_r'low) = c_HGH_LEV and pls_cnt_sc = std_logic_vector(to_unsigned(c_PLS_CNT_SC_MAX_VAL, pls_cnt_sc'length)) then

            if frm_cnt_sc_rst_lt = c_HGH_LEV then
               frm_cnt_sc <= c_ZERO(frm_cnt_sc'range);

            else
               frm_cnt_sc <= std_logic_vector(unsigned(frm_cnt_sc) + 1);

            end if;

         end if;

      end if;

   end process P_frm_cnt_sc;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data: Control word last
   -- ------------------------------------------------------------------------------------------------------
   P_sc_dta_ctrl_lst : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         science_dta_ctrl_lst <= c_SC_CTRL_DTW;

      elsif rising_edge(i_clk_science) then
         if science_data_rdy_r(science_data_rdy_r'low) = c_HGH_LEV then
            science_dta_ctrl_lst   <= i_science_data_ctrl;

         end if;

      end if;

   end process P_sc_dta_ctrl_lst;

   -- ------------------------------------------------------------------------------------------------------
   --!   Mode selection
   -- ------------------------------------------------------------------------------------------------------
   P_mode_sel : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         sm_mode_sel <= idle;

      elsif rising_edge(i_clk_science) then
         if    i_science_data_ctrl = c_SC_CTRL_FWA then
            sm_mode_sel   <= error_sig;

         elsif i_science_data_ctrl = c_SC_CTRL_FWS then
            sm_mode_sel   <= science;

         elsif i_science_data_ctrl = c_SC_CTRL_FWD then
            sm_mode_sel   <= dump;

         elsif i_science_data_ctrl = c_SC_CTRL_TPT and science_dta_ctrl_lst = c_SC_CTRL_DTW then
            sm_mode_sel   <= test_pattern;

         end if;
      end if;

   end process P_mode_sel;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Ready register
   -- ------------------------------------------------------------------------------------------------------
   P_science_data_rdy : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         science_data_rdy_r   <= c_ZERO(science_data_rdy_r'range);

      elsif rising_edge(i_clk_science) then
         science_data_rdy_r   <= science_data_rdy_r(science_data_rdy_r'high-1 downto 0) & i_science_data_rdy;

      end if;

   end process P_science_data_rdy;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data register
   -- ------------------------------------------------------------------------------------------------------
   G_mem_adc_dmp_dta : for k in 0 to c_NB_COL-1 generate
   begin

      --! Science Data register
      P_science_data_r : process (i_rst, i_clk_science)
      begin

         if i_rst = c_RST_LEV_ACT then
            science_data_r(k) <= (others => c_ZERO(science_data_r(science_data_r'low)(science_data_r'low)'range));

         elsif rising_edge(i_clk_science) then
            science_data_r(k) <= i_science_data(k) & science_data_r(k)(0 to science_data_r(k)'high-1);

         end if;

      end process P_science_data_r;

      -- ------------------------------------------------------------------------------------------------------
      --!   Dual port memory for adc dump data compare
      -- ------------------------------------------------------------------------------------------------------
      P_mem_adc_dmp_dta_w : process(i_clk_science)
      begin
         if rising_edge(i_clk_science) then
            if i_adc_dmp_mem_cs(k) = c_HGH_LEV then
               mem_adc_dump_dta2cmp(k)(to_integer(unsigned(i_adc_dmp_mem_add))) <=  i_adc_dmp_mem_data;
               mem_science_dta2cmp(k)( to_integer(unsigned(i_adc_dmp_mem_add))) <=  i_science_mem_data;

           end if;
         end if;
      end process P_mem_adc_dmp_dta_w;

      --! Adc dump data compare: memory read
      P_mem_adc_dmp_dta_r : process(i_rst, i_clk_science)
      begin
         if i_rst = c_RST_LEV_ACT then
            adc_dump_dta2cmp(k) <= c_ZERO(adc_dump_dta2cmp(adc_dump_dta2cmp'low)'range);
            science_dta2cmp(k)  <= c_ZERO(science_dta2cmp(science_dta2cmp'low)'range);

         elsif rising_edge(i_clk_science) then
            adc_dump_dta2cmp(k) <= mem_adc_dump_dta2cmp(k)(to_integer(unsigned(pixel_pos_del(k))));
            science_dta2cmp(k)  <= mem_science_dta2cmp(k)(c_MUX_FACT * to_integer(unsigned(frm_cnt_sc)) + to_integer(unsigned(pls_cnt_sc)));

         end if;
      end process P_mem_adc_dmp_dta_r;

      -- ------------------------------------------------------------------------------------------------------
      --!   adc dump data to compare last value
      -- ------------------------------------------------------------------------------------------------------
      P_dump_dta2cmp_lst : process (i_rst, i_clk_science)
      begin

         if i_rst = c_RST_LEV_ACT then
            adc_dump_dta2cmp_lst(k) <= c_ZERO(adc_dump_dta2cmp_lst(adc_dump_dta2cmp_lst'low)'range);

         elsif rising_edge(i_clk_science) then
            if i_science_data_rdy = c_HGH_LEV then
               adc_dump_dta2cmp_lst(k) <= adc_dump_dta2cmp(k);

            end if;

         end if;

      end process P_dump_dta2cmp_lst;

      -- ------------------------------------------------------------------------------------------------------
      --!   Squid delay
      -- ------------------------------------------------------------------------------------------------------
      squid_amp_mux_del(k) <= i_smfbd(k) when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQM) else i_saomd(k);
      squid_del(k) <= std_logic_vector(resize(signed(squid_amp_mux_del(k)), squid_del(k)'length)) when squid_amp_mux_del(k)(c_DFLD_SMFBD_COL_S-1) = c_LOW_LEV else
                      std_logic_vector(resize(signed(squid_amp_mux_del(k)), squid_del(k)'length) + to_signed(c_FRAME_NB_CYC, squid_del(k)'length));

      pixel_pos_init(k)    <= std_logic_vector(to_unsigned(div_floor(to_integer(unsigned(squid_del(k))), c_PIXEL_DAC_NB_CYC), pixel_pos_init(k)'length));
      pls_cnt_pos_init(k)  <= std_logic_vector(signed(unsigned(squid_del(k))) - to_signed(to_integer(unsigned(pixel_pos_init(k))) * c_PIXEL_DAC_NB_CYC, pls_cnt_pos_init(k)'length));

      -- ------------------------------------------------------------------------------------------------------
      --!   Pulse counter position with delay
      -- ------------------------------------------------------------------------------------------------------
      P_pls_cnt_pos_del : process (i_rst, i_clk_science)
      begin

         if i_rst = c_RST_LEV_ACT then
            pls_cnt_pos_del(k) <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt_pos_del(k)'length));

         elsif rising_edge(i_clk_science) then
            pls_cnt_pos_del(k) <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt_pos_del(k)'length) - resize(unsigned(pls_cnt_pos_init(k)), pls_cnt_pos_del(k)'length));

         end if;

      end process P_pls_cnt_pos_del;

      -- ------------------------------------------------------------------------------------------------------
      --!   Pixel position with delay
      -- ------------------------------------------------------------------------------------------------------
      P_pixel_pos_del : process (i_rst, i_clk_science)
      begin

         if i_rst = c_RST_LEV_ACT then
            pixel_pos_del(k)   <= std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos_del(k)'length));

         elsif rising_edge(i_clk_science) then
            if pls_cnt = pls_cnt_pos_del(k) or (pls_cnt(pls_cnt'high) = c_HGH_LEV and pixel_pos = std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL , pixel_pos'length))) then

               if unsigned(pixel_pos) < unsigned(pixel_pos_init(k)) then
                  pixel_pos_del(k) <= std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL+1, pixel_pos_del(k)'length) + unsigned(pixel_pos) - unsigned(pixel_pos_init(k)));

               else
                  pixel_pos_del(k) <= std_logic_vector(unsigned(pixel_pos) - unsigned(pixel_pos_init(k)));

               end if;

            end if;

         end if;

      end process P_pixel_pos_del;

      -- ------------------------------------------------------------------------------------------------------
      --!   Science data error
      -- ------------------------------------------------------------------------------------------------------
      science_data_err(k) <=  c_LOW_LEV when (pls_cnt   = std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length)) and
                                        pixel_pos = c_ZERO(pixel_pos'range) and
                                        seq_cnt   = c_ZERO(seq_cnt'range))  else
                              c_HGH_LEV when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQA and (sm_mode_sel = dump) and
                                        i_science_data(k) /= adc_dump_dta2cmp_lst(k)) else
                              c_HGH_LEV when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQM) and (pls_cnt = pls_cnt_pos_del(k)) and (sm_mode_sel = dump) and (
                                        signed(i_science_data(k)) /= signed(adc_dump_dta2cmp_lst(k))) else
                              c_HGH_LEV when (sm_mode_sel = error_sig) and (
                                        signed(science_data_r(k)(c_SC_DATA_R_PIP_NB-1)) /= signed(science_dta2cmp(k))) else
                              c_HGH_LEV when (i_sw_adc_vin = c_SW_ADC_VIN_ST_SQM) and (sm_mode_sel = science) and (i_sqm_fbm_cls_lp_n(k) = c_HGH_LEV) and (
                                        signed(science_data_r(k)(c_SC_DATA_R_PIP_NB-1)) /= signed(science_dta2cmp(k))) else
                              c_HGH_LEV when (sm_mode_sel = test_pattern) and (
                                        signed(science_data_r(k)(c_SC_DATA_R_PIP_NB-1)) /= signed(science_dta2cmp(k))) else
                              c_LOW_LEV;

   end generate G_mem_adc_dmp_dta;

   -- ------------------------------------------------------------------------------------------------------
   --!   Output management
   -- ------------------------------------------------------------------------------------------------------
   P_science_data_err : process (i_rst, i_clk_science)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_science_data_err <= c_ZERO(o_science_data_err'range);

      elsif rising_edge(i_clk_science) then
         if science_data_rdy_r(science_data_rdy_r'high) = c_HGH_LEV then
            o_science_data_err <= science_data_err;

         end if;

      end if;

   end process P_science_data_err;

end architecture Behavioral;
