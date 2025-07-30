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
--!   @file                   squid_adc_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid ADC management
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

entity squid_adc_mgt is port (
         i_rst_sqm_adc_dac    : in     std_logic                                                            ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID ADC/DAC internal Clock

         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock
         i_aqmde_dmp_cmp      : in     std_logic                                                            ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging
         i_smpdl              : in     std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                      ; --! ADC sample delay
         i_sqm_adc_data       : in     std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data, no rsync
         i_sqm_adc_oor        : in     std_logic                                                            ; --! SQUID MUX ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         i_sqm_mem_dump_add   : in     std_logic_vector(c_MEM_DUMP_ADD_S-1 downto 0)                        ; --! SQUID MUX Memory Dump: address
         o_sqm_mem_dump_data  : out    std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --! SQUID MUX Memory Dump: data
         o_sqm_mem_dump_bsy   : out    std_logic                                                            ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

         o_sqm_data_err       : out    std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error
         o_sqm_data_err_frst  : out    std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_last  : out    std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_rdy   : out    std_logic                                                              --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)
   );
end entity squid_adc_mgt;

architecture RTL of squid_adc_mgt is
constant c_ADC_DATA_SYNC_NPER : integer:= c_ADC_DATA_RDY_NPER - c_ADC_SYNC_RDY_NPER - 1                     ; --! ADC clock periods number between ADC data ready and Pixel sequence sync. ready

constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_ADC_NB_CYC                                                ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_ADC_DATA_SYNC_NPER - 3                                          ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= -1                                                                ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1) + 1                              ; --! Pixel position: size bus (signed)
constant c_PIXEL_POS_MSB_R_S  : integer:= 4                                                                 ; --! Pixel position MSB register: size bus (signed)

constant c_SAMPLE_CNT_S       : integer:= c_DFLD_BXLGT_COL_S + 2                                            ; --! Sample counter: size bus (signed)

constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Dump counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Dump counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_MAX_VAL + 1) + 1                              ; --! Dump counter: size bus (signed)

constant c_MEM_DUMP_DATA_S    : integer := c_SQM_ADC_DATA_S + 1                                             ; --! Memory Dump: data bus size (<= c_RAM_DATA_S)

signal   sync_rs_rsys         : std_logic                                                                   ; --! Pixel sequence synchronization register (System Clock)
signal   aqmde_dmp_cmp_rsys   : std_logic                                                                   ; --! Telemetry mode, status "Dump" compared register (System Clock)
signal   bxlgt_rsys           : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                             ; --! ADC sample number for averaging register (System Clock)
signal   smpdl_rsys           : std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                             ; --! ADC sample delay register (System Clock)

signal   rst_sqm_adc_dac_lc   : std_logic                                                                   ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock

signal   sync_r               : std_logic_vector(c_ADC_DATA_SYNC_NPER+c_FF_RSYNC_NB downto 0)               ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   aqmde_dmp_cmp_r      : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Telemetry mode, status "Dump" compared register ('0' = Inactive, '1' = Active)
signal   bxlgt_r              : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_BXLGT_COL_S-1 downto 0)              ; --! ADC sample number for averaging register
signal   smpdl_r              : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_DFLD_SMPDL_COL_S-1 downto 0)              ; --! ADC sample delay register
signal   sqm_adc_data_r       : t_slv_arr(0 to 2*c_FF_RSYNC_NB-1)(c_SQM_ADC_DATA_S-1 downto 0)              ; --! SQUID MUX ADC: Data register
signal   sqm_adc_oor_r        : std_logic_vector(2*c_FF_RSYNC_NB-1 downto 0)                                ; --! SQUID MUX ADC: Out of range register ('0' = No, '1' = under/over range)

signal   sync_re              : std_logic                                                                   ; --! Pixel sequence sync. rising edge
signal   sync_re_adc_data     : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge, synchronized on ADC data first pixel
signal   aqmde_dmp_cmp_sync   : std_logic                                                                   ; --! Telemetry mode, status "Dump" compared sync. on first pixel
signal   bxlgt_sync           : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                             ; --! ADC sample number for averaging sync. on first pixel

signal   pls_cnt              : std_logic_vector(  c_PLS_CNT_S-1 downto 0)                                  ; --! Pulse counter
signal   pls_cnt_init         : std_logic_vector(  c_PLS_CNT_S-1 downto 0)                                  ; --! Pulse shaping counter initialization
signal   pixel_pos            : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! Pixel position
signal   pixel_pos_msb_r      : std_logic_vector(c_PIXEL_POS_MSB_R_S-1 downto 0)                            ; --! Pixel position MSB register
signal   pixel_pos_init       : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! Pixel position initialization

signal   sample_cnt           : std_logic_vector(  c_SAMPLE_CNT_S-1 downto 0)                               ; --! Sample counter
signal   sample_cnt_msb_r     : std_logic_vector(                 1 downto 0)                               ; --! Sample counter MSB register
signal   sum_adc_data         : std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                               ; --! Sum of ADC Data
signal   sqm_data_err         : std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                               ; --! SQUID MUX Data error
signal   sqm_data_err_rdy     : std_logic                                                                   ; --! SQUID MUX Data error ready
signal   sqm_data_err_frst    : std_logic                                                                   ; --! SQUID MUX Data error first pixel
signal   sqm_data_err_last    : std_logic                                                                   ; --! SQUID MUX Data error last pixel

signal   mem_dump_adc_cnt_w   : std_logic_vector(  c_DMP_CNT_S-1 downto 0)                                  ; --! Memory Dump, ADC acquisition side: counter words
signal   mem_dump_adc         : t_mem(add(c_MEM_DUMP_ADD_S-1 downto 0),data_w(c_MEM_DUMP_DATA_S-1 downto 0)); --! Memory Dump, ADC acquisition side inputs

signal   mem_dump_sc          : t_mem(add(c_MEM_DUMP_ADD_S-1 downto 0),data_w(c_MEM_DUMP_DATA_S-1 downto 0)); --! Memory Dump, Science Acquisition side inputs
signal   mem_dump_data_out    : std_logic_vector(c_MEM_DUMP_DATA_S-1 downto 0)                              ; --! Memory Dump, Science Acquisition side: data out
signal   mem_dump_flg_err     : std_logic                                                                   ; --! Memory Dump, Science Acquisition side: flag error uncor. detected ('0'=No,'1'= Yes)

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of rst_sqm_adc_dac_lc    : signal is true                                   ; --! Disabling signal optimization: rst_sqm_adc_dac_lc
attribute syn_preserve          of sync_rs_rsys          : signal is true                                   ; --! Disabling signal optimization: sync_rs_rsys
attribute syn_preserve          of sync_r                : signal is true                                   ; --! Disabling signal optimization: sync_r
attribute syn_preserve          of sync_re               : signal is true                                   ; --! Disabling signal optimization: sync_re

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs entity register on System Clock / Outputs entity resynchronization on System Clock
   -- ------------------------------------------------------------------------------------------------------
   I_squid_adc_sys: entity work.squid_adc_sys port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => i_sync_rs            , -- in     std_logic                                 ; --! Pixel sequence synchronization (System Clock)
         i_aqmde_dmp_cmp      => i_aqmde_dmp_cmp      , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active) (System Clock)
         i_bxlgt              => i_bxlgt              , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging (System Clock)
         i_smpdl              => i_smpdl              , -- in     slv(c_DFLD_SMPDL_COL_S-1 downto 0)        ; --! ADC sample delay (System Clock)

         o_sync_rs_rsys       => sync_rs_rsys         , -- out    std_logic                                 ; --! Pixel sequence synchronization register (System Clock)
         o_aqmde_dmp_cmp_rsys => aqmde_dmp_cmp_rsys   , -- out    std_logic                                 ; --! Telemetry mode, status "Dump" compared register (System Clock)
         o_bxlgt_rsys         => bxlgt_rsys           , -- out    slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging register (System Clock)
         o_smpdl_rsys         => smpdl_rsys           , -- out    slv(c_DFLD_SMPDL_COL_S-1 downto 0)        ; --! ADC sample delay register (System Clock)

         i_mem_dump_bsy       => mem_dump_adc.cs      , -- in     std_logic                                 ; --! SQUID MUX Memory Dump: data busy (ADC/DAC Clock)
         i_data_err           => sqm_data_err         , -- in     slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error (ADC/DAC Clock)
         i_data_err_frst      => sqm_data_err_frst    , -- in     std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes) (ADC/DAC Clock)
         i_data_err_last      => sqm_data_err_last    , -- in     std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)  (ADC/DAC Clock)
         i_data_err_rdy       => sqm_data_err_rdy     , -- in     std_logic                                 ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready) (ADC/DAC Clock)

         o_mem_dump_bsy_rsys  => o_sqm_mem_dump_bsy   , -- out    std_logic                                 ; --! SQUID MUX Memory Dump: data busy (System Clock)
         o_data_err_rsys      => o_sqm_data_err       , -- out    slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error (System Clock)
         o_data_err_frst_rsys => o_sqm_data_err_frst  , -- out    std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes) (System Clock)
         o_data_err_last_rsys => o_sqm_data_err_last  , -- out    std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)  (System Clock)
         o_data_err_rdy_rsys  => o_sqm_data_err_rdy     -- out    std_logic                                   --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready) (System Clock)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Local reset on SQUID MUX ADC acquisition Clock
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_rst_sqm_adc_dac_lc: process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = c_RST_LEV_ACT then
         rst_sqm_adc_dac_lc  <= c_RST_LEV_ACT;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         rst_sqm_adc_dac_lc  <= not(c_RST_LEV_ACT);

      end if;

   end process P_rst_sqm_adc_dac_lc;

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization on SQUID ADC/DAC internal Clock
   --    @Req : DRE-DMX-FW-REQ-0100
   -- ------------------------------------------------------------------------------------------------------
   P_in_pad_rsync : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sqm_adc_data_r    <= (others => c_ZERO(sqm_adc_data_r(sqm_adc_data_r'high)'range));
         sqm_adc_oor_r     <= (others => c_LOW_LEV);
         pixel_pos_msb_r   <= (others => c_HGH_LEV);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sqm_adc_data_r    <= i_sqm_adc_data & sqm_adc_data_r(0 to sqm_adc_data_r'high-1);
         sqm_adc_oor_r     <= sqm_adc_oor_r(sqm_adc_oor_r'high-1 downto 0) & i_sqm_adc_oor;
         pixel_pos_msb_r   <= pixel_pos_msb_r(pixel_pos_msb_r'high-1 downto 0) & pixel_pos(pixel_pos'high);

      end if;

   end process P_in_pad_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization on SQUID MUX ADC acquisition Clock
   -- ------------------------------------------------------------------------------------------------------
   P_in_rsync : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sync_r            <= (others => c_I_SYNC_DEF);
         aqmde_dmp_cmp_r   <= (others => c_LOW_LEV);
         bxlgt_r           <= (others => c_EP_CMD_DEF_BXLGT);
         smpdl_r           <= (others => c_EP_CMD_DEF_SMPDL);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_r            <= sync_r(sync_r'high-1 downto 0) & sync_rs_rsys;
         aqmde_dmp_cmp_r   <= aqmde_dmp_cmp_r(aqmde_dmp_cmp_r'high-1  downto 0) & aqmde_dmp_cmp_rsys;
         bxlgt_r           <= bxlgt_rsys & bxlgt_r(0 to bxlgt_r'high-1);
         smpdl_r           <= smpdl_rsys & smpdl_r(0 to smpdl_r'high-1);

      end if;

   end process P_in_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sync_re              <= c_LOW_LEV;
         sync_re_adc_data     <= c_LOW_LEV;
         aqmde_dmp_cmp_sync   <= c_LOW_LEV;
         bxlgt_sync           <= c_EP_CMD_DEF_BXLGT;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         sync_re              <= not(sync_r(c_FF_RSYNC_NB+1)) and sync_r(c_FF_RSYNC_NB);
         sync_re_adc_data     <= not(sync_r(sync_r'high))   and sync_r(sync_r'high-1);

         if sync_re_adc_data = c_HGH_LEV then
            aqmde_dmp_cmp_sync <= aqmde_dmp_cmp_r(aqmde_dmp_cmp_r'high);

         end if;

         if pixel_pos(pixel_pos'high) = c_HGH_LEV and pls_cnt = c_ZERO(pls_cnt'range) then
            bxlgt_sync <= bxlgt_r(bxlgt_r'high);

         end if;

      end if;

   end process P_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter/Pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0150
   --    @Req : DRE-DMX-FW-REQ-0155
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt_del : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)));
         pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if    unsigned(smpdl_r(smpdl_r'high)) <= to_unsigned(c_PLS_CNT_MAX_VAL - c_PLS_CNT_INIT, c_DFLD_SMPDL_COL_S) then
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)) + unsigned(smpdl_r(smpdl_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         else
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT - c_PLS_CNT_NB_VAL, pls_cnt_init'length)) + unsigned(smpdl_r(smpdl_r'high)));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT + 1 , pixel_pos'length));

         end if;

      end if;

   end process P_pls_cnt_del;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   --    @Req : DRE-DMX-FW-REQ-0130
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         pls_cnt    <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = c_HGH_LEV then
            pls_cnt <= pls_cnt_init;

         elsif pls_cnt(pls_cnt'high) = c_HGH_LEV then
            pls_cnt <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         pixel_pos    <= std_logic_vector(to_signed(c_PIXEL_POS_INIT, pixel_pos'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if sync_re = c_HGH_LEV then
            pixel_pos <= pixel_pos_init;

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Sample counter
   --    @Req : DRE-DMX-FW-REQ-0145
   -- ------------------------------------------------------------------------------------------------------
   P_sample_cnt : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sample_cnt        <= c_MINUSONE(sample_cnt'range);
         sample_cnt_msb_r  <= (others => c_MINUSONE(c_MINUSONE'high));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if pls_cnt(pls_cnt'high) = c_HGH_LEV then
            sample_cnt <= std_logic_vector(resize(unsigned(bxlgt_sync), sample_cnt'length));

         elsif sample_cnt(sample_cnt'high) = c_LOW_LEV then
            sample_cnt <= std_logic_vector(signed(sample_cnt) - 1);

         end if;

         sample_cnt_msb_r  <= sample_cnt_msb_r(sample_cnt_msb_r'high-1 downto 0) & sample_cnt(sample_cnt'high);

      end if;

   end process P_sample_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data error
   --    @Req : DRE-DMX-FW-REQ-0140
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_err : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sum_adc_data      <= c_ZERO(sum_adc_data'range);
         sqm_data_err      <= c_ZERO(sqm_data_err'range);
         sqm_data_err_rdy  <= c_LOW_LEV;
         sqm_data_err_frst <= c_LOW_LEV;
         sqm_data_err_last <= c_LOW_LEV;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if pls_cnt(pls_cnt'high) = c_HGH_LEV then
            sum_adc_data <= c_ZERO(sum_adc_data'range);

         elsif sample_cnt(sample_cnt'high) = c_LOW_LEV then
            sum_adc_data <= std_logic_vector(signed(sum_adc_data) + resize(signed(sqm_adc_data_r(sqm_adc_data_r'high)), sum_adc_data'length));

         end if;

         if (not(sample_cnt_msb_r(sample_cnt_msb_r'low)) and sample_cnt(sample_cnt'high)) = c_HGH_LEV then
            sqm_data_err <= sum_adc_data;

            if pixel_pos = std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) then
               sqm_data_err_frst <= c_HGH_LEV;

            else
               sqm_data_err_frst <= c_LOW_LEV;

            end if;

         end if;

         if pixel_pos(pixel_pos'high) = c_HGH_LEV then
            sqm_data_err_last <= c_HGH_LEV;

         elsif (pixel_pos_msb_r(pixel_pos_msb_r'high) and not(pixel_pos_msb_r(pixel_pos_msb_r'high-1))) = c_HGH_LEV then
            sqm_data_err_last <= c_LOW_LEV;

         end if;

         sqm_data_err_rdy <= (not(sample_cnt_msb_r(sample_cnt_msb_r'high)) and sample_cnt_msb_r(sample_cnt_msb_r'high-1)) or
                             (not(sample_cnt_msb_r(sample_cnt_msb_r'low )) and sample_cnt(sample_cnt'high));

      end if;

   end process P_sqm_data_err;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: memory signals management
   --!      (SQUID MUX ADC acquisition Clock side)
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_adc_cnt_w : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         mem_dump_adc_cnt_w   <= c_MINUSONE(mem_dump_adc_cnt_w'range);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if (mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) and aqmde_dmp_cmp_r(aqmde_dmp_cmp_r'high) and not(aqmde_dmp_cmp_sync) and sync_re_adc_data) = c_HGH_LEV then
            mem_dump_adc_cnt_w <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, mem_dump_adc_cnt_w'length));

         elsif mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = c_LOW_LEV then
            mem_dump_adc_cnt_w <= std_logic_vector(signed(mem_dump_adc_cnt_w) - 1);

         end if;
      end if;

   end process P_mem_dump_adc_cnt_w;

   mem_dump_adc.pp   <= c_LOW_LEV;
   mem_dump_adc.add  <= std_logic_vector(resize(unsigned(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high-1 downto 0)), mem_dump_adc.add'length));
   mem_dump_adc.we   <= c_HGH_LEV;
   mem_dump_adc.cs   <= not(mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high));

   mem_dump_adc.data_w(c_SQM_ADC_DATA_S-1 downto 0) <= sqm_adc_data_r(sqm_adc_data_r'high);
   mem_dump_adc.data_w(c_SQM_ADC_DATA_S)            <= sqm_adc_oor_r(sqm_adc_oor_r'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode
   -- ------------------------------------------------------------------------------------------------------
   I_mem_dump: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_DATA_TX   , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_DUMP_ADD_S     , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_MEM_DUMP_DATA_S    , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_RAM_INIT_EMPTY       -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => mem_dump_adc         , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => open                 , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_dump_sc          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => mem_dump_data_out    , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => mem_dump_flg_err       -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: memory signals management
   --!      (System Clock side)
   -- ------------------------------------------------------------------------------------------------------
   mem_dump_sc.pp       <= c_LOW_LEV;
   mem_dump_sc.add      <= i_sqm_mem_dump_add;
   mem_dump_sc.we       <= c_LOW_LEV;
   mem_dump_sc.cs       <= c_HGH_LEV;
   mem_dump_sc.data_w   <= c_ZERO(mem_dump_sc.data_w'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for data transfer in Dump mode: reading data signals
   --!      (System Clock side)
   -- ------------------------------------------------------------------------------------------------------
   o_sqm_mem_dump_data(c_MEM_DUMP_DATA_S-1 downto 0)  <= mem_dump_data_out;
   o_sqm_mem_dump_data(c_MEM_DUMP_DATA_S)             <= mem_dump_flg_err;

end architecture RTL;
