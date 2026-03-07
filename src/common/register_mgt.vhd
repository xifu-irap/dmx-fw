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
--!   @file                   register_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity register_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock
         i_hk_err_nin         : in     std_logic                                                            ; --! Housekeeping Error parameter to read not initialized yet
         i_dlflg              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_DLFLG_COL_S-1 downto 0)            ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_sts_err_nin : out    std_logic                                                            ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis : out    std_logic                                                            ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register

         i_ep_cmd_rx_wd_add   : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy : in     std_logic                                                            ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command to transmit: read register word

         i_aqmde_dmp_tx_end   : in     std_logic                                                            ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_aqmde              : out    std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         o_aqmde_dmp_cmp      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_aqmde_tst_cmp      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Telemetry mode, status "Test Pattern" compared ('0' = Inactive, '1' = Active)

         i_tst_pat_end_pat    : in     std_logic                                                            ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_end_re     : in     std_logic                                                            ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         i_tst_pat_empty      : in     std_logic                                                            ; --! Test pattern empty ('0' = No, '1' = Yes)
         o_tsten_lop          : out    std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                      ; --! Test pattern enable, field Loop number
         o_tsten_inf          : out    std_logic                                                            ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
         o_tsten_ena          : out    std_logic                                                            ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

         o_adc_ena            : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! ADC enable ('0' = Inactive, '1' = Active)
         o_smfmd              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)            ; --! SQUID MUX feedback mode
         o_saofm              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)            ; --! SQUID AMP offset mode
         o_bxlgt              : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)            ; --! ADC sample number for averaging
         o_rg_col             : out    t_rgc_arr(0 to c_NB_COL-1)                                           ; --! EP register by column
         o_squid_gain         : out    t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMIGN_COL_S-1 downto 0)            ; --! SQUID gain
         o_sqa_off_lsb        : out    t_slv_arr(0 to c_NB_COL-1)(  c_SQA_DAC_DATA_S-1 downto 0)            ; --! SQUID AMP offset LSB

         o_mem_prc            : out    t_mem_prc_arr(0 to c_NB_COL-1)                                       ; --! Memory for data squid proc.: memory interface
         i_mem_prc_data       : in     t_mem_prc_dta_arr(0 to c_NB_COL-1)                                   ; --! Memory for data squid proc.: data read

         o_ep_mem             : out    t_ep_mem_arr(0 to c_NB_COL-1)                                        ; --! Memory: memory interface
         i_ep_mem_data        : in     t_ep_mem_dta_arr(0 to c_NB_COL-1)                                    ; --! Memory: data read

         o_mem_hkeep_add      : out    std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                       ; --! Housekeeping: memory address
         i_hkeep_data         : in     std_logic_vector(c_DFLD_HKEEP_S-1 downto 0)                          ; --! Housekeeping: data read

         i_smfbm_add          : in     t_slv_arr(0 to c_NB_COL-1)( c_MEM_SMFBM_ADD_S-1 downto 0)            ; --! SQUID MUX feedback mode: address, memory output
         i_smfbm_cs           : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         o_squid_amp_close    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         o_squid_close_mode_n : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         o_amp_frst_lst_frm   : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
   );
end entity register_mgt;

architecture RTL of register_mgt is
signal   col_nb               : std_logic_vector(log2_ceil(c_NB_COL)-1 downto 0)                            ; --! Column number
signal   ep_cmd_rx_wd_add_r   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared, registered
signal   ep_cmd_rx_wd_data_r  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word, registered
signal   ep_cmd_rx_rw_r       : std_logic                                                                   ; --! EP command receipted: read/write bit, registered
signal   ep_cmd_rx_nerr_rdy_r : std_logic                                                                   ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
signal   ep_cmd_sts_rg_r      : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: Status register, registered

signal   rg_aqmde_dmp_cmp     : std_logic                                                                   ; --! EP register: DATA_ACQ_MODE, status "Dump" compared ('0' = Inactive, '1' = Active)
signal   rg_aqmde_tst_cmp     : std_logic                                                                   ; --! EP register: DATA_ACQ_MODE, status "Test Pattern" compared ('0'=Inactive, '1'=Active)
signal   rg_tsten             : std_logic_vector(    c_DFLD_TSTEN_S-1 downto 0)                             ; --! Test pattern enable

signal   rg_smfmd             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)                   ; --! EP register: MUX_SQ_FB_ON_OFF
signal   rg_saofm             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)                   ; --! EP register: AMP_SQ_OFFSET_MODE
signal   rg_bxlgt             : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)                   ; --! EP register: BOXCAR_LENGTH

signal   rg_col               : t_rgc_arr(0 to c_NB_COL-1)                                                  ; --! EP register by column
signal   rg_col_data          : t_slv_arr(0 to c_NB_COL-1)(c_EP_RGC_ACC(c_EP_RGC_ACC'high)-1 downto 0)      ; --! EP register by column data
signal   rg_col_cs            : t_slv_arr(0 to c_EP_RGC_NUM_LAST-1)(c_NB_COL-1 downto 0)                    ; --! EP register by column chip select ('0'=Inactive, '1'=Active)

signal   mem_in_add           : std_logic_vector(c_EP_MEM_ADDAC_S(c_EP_MEM_ADDAC_S'high)-1 downto 0)        ; --! Memory inputs: Address
signal   mem_in_we            : std_logic_vector(c_EP_MEM_NUM_LAST-1 downto 0)                              ; --! Memory inputs: Write enable ('0' = Inactive, '1' = Active)
signal   mem_in_cs            : t_slv_arr(0 to c_EP_MEM_NUM_LAST-1)(c_NB_COL-1 downto 0)                    ; --! Memory inputs: Chip select  ('0' = Inactive, '1' = Active)
signal   mem_in_pp            : t_slv_arr(0 to c_EP_MEM_NUM_LAST-1)(c_NB_COL-1 downto 0)                    ; --! Memory inputs: Ping-pong buffer bit
signal   ep_mem_cs            : t_slv_arr(0 to c_EP_MEM_NUM_LAST-1)(c_NB_COL-1 downto 0)                    ; --! Memory chip select ('0'=Inactive, '1'=Active)

signal   cs_rg_r              : std_logic_vector(c_EP_CMD_REG_MX_STIN(1)-1 downto 0)                        ; --! Chip selects register registered

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_aqmde_dmp_cmp   : signal is true                                       ; --! Disabling signal optimization: o_aqmde_dmp_cmp
attribute syn_preserve          of o_aqmde_tst_cmp   : signal is true                                       ; --! Disabling signal optimization: o_aqmde_tst_cmp

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command register
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         ep_cmd_rx_wd_add_r   <= c_ZERO(ep_cmd_rx_wd_add_r'range);
         ep_cmd_rx_wd_data_r  <= c_ZERO(ep_cmd_rx_wd_data_r'range);
         ep_cmd_rx_rw_r       <= c_LOW_LEV;
         ep_cmd_rx_nerr_rdy_r <= c_LOW_LEV;
         ep_cmd_sts_rg_r      <= (others => c_EP_CMD_ERR_CLR);

      elsif rising_edge(i_clk) then
         ep_cmd_rx_wd_add_r   <= i_ep_cmd_rx_wd_add;
         ep_cmd_rx_wd_data_r  <= i_ep_cmd_rx_wd_data;
         ep_cmd_rx_rw_r       <= i_ep_cmd_rx_rw;
         ep_cmd_rx_nerr_rdy_r <= i_ep_cmd_rx_nerr_rdy;
         ep_cmd_sts_rg_r      <= i_ep_cmd_sts_rg;

      end if;

   end process P_ep_cmd_r;

   col_nb <= ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSH downto c_EP_CMD_ADD_COLPOSL);

   -- ------------------------------------------------------------------------------------------------------
   --!   Chip selects register
   -- ------------------------------------------------------------------------------------------------------
   I_register_cs_mgt : entity work.register_cs_mgt port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r   , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP command receipted: address word, read/write bit cleared, registered
         o_cs_rg              => cs_rg_r                -- out    slv(c_EP_CMD_REG_MX_STIN(1)-1 downto 0)     --! Chip selects register ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register writing management
   --    @Req : REG_DATA_ACQ_MODE
   --    @Req : DRE-DMX-FW-REQ-0580
   -- ------------------------------------------------------------------------------------------------------
   I_rg_aqmde_mgt : entity work.rg_aqmde_mgt port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_AQMDE_S-1 downto 0), -- in slv c_DFLD_AQMDE_S   ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
         i_cs_rg_aqdme        => cs_rg_r(c_EP_CMD_POS_AQMDE),                    -- in std_logic            ; --! Chip selects register AQMDE

         i_tst_pat_end_re     => i_tst_pat_end_re     , -- in     std_logic                                 ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         i_aqmde_dmp_tx_end   => i_aqmde_dmp_tx_end   , -- in     std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)

         o_aqmde              => o_aqmde              , -- out    slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         o_rg_aqmde_dmp_cmp   => rg_aqmde_dmp_cmp     , -- out    std_logic                                 ; --! EP register: DATA_ACQ_MODE, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_rg_aqmde_tst_cmp   => rg_aqmde_tst_cmp       -- out    std_logic                                   --! EP register: DATA_ACQ_MODE, status "Test Pattern" compared ('0'=Inactive, '1'=Active)
   );

   -- @Req : REG_TEST_PATTERN_ENABLE
   I_rg_tsten_mgt : entity work.rg_tsten_mgt port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_rx_wd_dta_r => ep_cmd_rx_wd_data_r(c_DFLD_TSTEN_S-1 downto 0), -- in slv c_DFLD_TSTEN_S   ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
         i_cs_rg_tsten        => cs_rg_r(c_EP_CMD_POS_TSTEN),                    -- in std_logic            ; --! Chip selects register TSTEN

         i_tst_pat_end_pat    => i_tst_pat_end_pat    , -- in     std_logic                                 ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_empty      => i_tst_pat_empty      , -- in     std_logic                                 ; --! Test pattern empty ('0' = No, '1' = Yes)

         o_rg_tsten           => rg_tsten               -- out    slv(    c_DFLD_TSTEN_S-1 downto 0)          --! Test pattern enable
   );

   G_column_mgt : for k in 0 to c_NB_COL-1 generate
   begin

      -- ------------------------------------------------------------------------------------------------------
      --!   EP command: register commun for all column
      -- ------------------------------------------------------------------------------------------------------
      P_rg_com_for_all : process (i_rst, i_clk)
      begin

         if i_rst = c_RST_LEV_ACT then
            rg_saofm(k)       <= c_EP_CMD_DEF_SAOFM;
            rg_smfmd(k)       <= c_EP_CMD_DEF_SMFMD;
            rg_bxlgt(k)       <= c_EP_CMD_DEF_BXLGT;

            o_adc_ena(k)      <= c_LOW_LEV;
            o_squid_gain(k)   <= c_EP_CMD_DEF_SMIGN;
            o_sqa_off_lsb(k)  <= c_EP_CMD_DEF_SAOFL;

         elsif rising_edge(i_clk) then

            -- @Req : REG_AMP_SQ_OFFSET_MODE
            -- @Req : DRE-DMX-FW-REQ-0330
            if ep_cmd_rx_nerr_rdy_r = c_HGH_LEV and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and cs_rg_r(c_EP_CMD_POS_SAOFM) = c_HGH_LEV then
               rg_saofm(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_SAOFM_COL_S-1 downto c_NB_COL*k);

            elsif rg_saofm(k) = c_DST_SAOFM_TEST and i_tst_pat_end_re = c_HGH_LEV then
               rg_saofm(k) <= c_DST_SAOFM_OFFSET;

            end if;

            if ep_cmd_rx_nerr_rdy_r = c_HGH_LEV and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

               -- @Req : REG_MUX_SQ_FB_ON_OFF
               if cs_rg_r(c_EP_CMD_POS_SMFMD) = c_HGH_LEV then
                  rg_smfmd(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_SMFMD_COL_S-1 downto c_NB_COL*k);

               end if;

               -- @Req : REG_BOXCAR_LENGTH
               -- @Req : DRE-DMX-FW-REQ-0145
               if cs_rg_r(c_EP_CMD_POS_BXLGT) = c_HGH_LEV then
                  rg_bxlgt(k) <= ep_cmd_rx_wd_data_r(c_NB_COL*k+c_DFLD_BXLGT_COL_S-1 downto c_NB_COL*k);

               end if;

            end if;

            if (o_aqmde = c_DST_AQMDE_DUMP or o_aqmde = c_DST_AQMDE_SCIE or o_aqmde = c_DST_AQMDE_ERRS or rg_smfmd(k) = c_DST_SMFMD_ON or rg_saofm(k) = c_DST_SAOFM_CLOSE) then
               o_adc_ena(k) <= c_HGH_LEV;

            else
               o_adc_ena(k) <= c_LOW_LEV;

            end if;

            --    @Req : DRE-DMX-FW-REQ-0147
            --    @Req : DRE-DMX-FW-REQ-0148
            if o_squid_amp_close(k) = c_HGH_LEV then
               o_squid_gain(k) <= rg_col(k).saign;

            else
               o_squid_gain(k) <= rg_col(k).smign;

            end if;

            --    @Req : DRE-DMX-FW-REQ-0297
            --    @Req : DRE-DMX-FW-REQ-0298
            if rg_saofm(k) = c_DST_SAOFM_TEST then
               o_sqa_off_lsb(k) <= rg_col(k).saolp;

            else
               o_sqa_off_lsb(k) <= rg_col(k).saofl;

            end if;

         end if;

      end process P_rg_com_for_all;

      -- ------------------------------------------------------------------------------------------------------
      --!   EP command: one register by column
      --    @Req : REG_CY_MUX_SQ_INPUT_GAIN
      --    @Req : REG_CY_AMP_SQ_INPUT_GAIN
      --    @Req : REG_CY_AMP_SQ_KI_KNORM
      --    @Req : REG_CY_AMP_SQ_KNORM
      --    @Req : REG_CY_AMP_SQ_LOCKPOINT_V
      --    @Req : REG_CY_AMP_SQ_OFFSET_LSB_PTR
      --    @Req : REG_CY_AMP_SQ_OFFSET_COARSE
      --    @Req : REG_CY_AMP_SQ_OFFSET_LSB
      --    @Req : REG_CY_MUX_SQ_FB_DELAY
      --    @Req : REG_CY_AMP_SQ_OFFSET_DAC_DELAY
      --    @Req : REG_CY_AMP_SQ_OFFSET_MUX_DELAY
      --    @Req : REG_CY_SAMPLING_DELAY
      --    @Req : REG_CY_PULSE_SHAPING_SEL
      --    @Req : REG_CY_RELOCK_DELAY
      --    @Req : REG_CY_RELOCK_THRESHOLD
      --    @Req : DRE-DMX-FW-REQ-0147
      --    @Req : DRE-DMX-FW-REQ-0148
      --    @Req : DRE-DMX-FW-REQ-0150
      --    @Req : DRE-DMX-FW-REQ-0155
      --    @Req : DRE-DMX-FW-REQ-0235
      --    @Req : DRE-DMX-FW-REQ-0280
      --    @Req : DRE-DMX-FW-REQ-0290
      --    @Req : DRE-DMX-FW-REQ-0292
      --    @Req : DRE-DMX-FW-REQ-0295
      --    @Req : DRE-DMX-FW-REQ-0297
      --    @Req : DRE-DMX-FW-REQ-0298
      --    @Req : DRE-DMX-FW-REQ-0305
      --    @Req : DRE-DMX-FW-REQ-0326
      --    @Req : DRE-DMX-FW-REQ-0328
      --    @Req : DRE-DMX-FW-REQ-0380
      --    @Req : DRE-DMX-FW-REQ-0387
      --    @Req : DRE-DMX-FW-REQ-0392
      --    @Req : DRE-DMX-FW-REQ-0393
      --    @Req : DRE-DMX-FW-REQ-0410
      --    @Req : DRE-DMX-FW-REQ-0420
      -- ------------------------------------------------------------------------------------------------------
      G_rg_col : for l in 0 to c_EP_RGC_NUM_LAST-1 generate
      begin

         --! EP command: one register by column
         P_rg_col : process (i_rst, i_clk)
         begin

            if i_rst = c_RST_LEV_ACT then
               rg_col_data(k)(c_EP_RGC_ACC(l+1)-1 downto c_EP_RGC_ACC(l)) <= std_logic_vector(to_unsigned(c_EP_RGC_DEF(l), c_EP_RGC_ACC(l+1)-c_EP_RGC_ACC(l)));

            elsif rising_edge(i_clk) then

               if ep_cmd_rx_nerr_rdy_r = c_HGH_LEV and ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and
                  ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSH downto c_EP_CMD_ADD_COLPOSL) = std_logic_vector(to_unsigned(k, log2_ceil(c_NB_COL))) then

                  if cs_rg_r(c_EP_RGC_POS(l)) = c_HGH_LEV then
                     rg_col_data(k)(c_EP_RGC_ACC(l+1)-1 downto c_EP_RGC_ACC(l)) <= ep_cmd_rx_wd_data_r(c_EP_RGC_ACC(l+1)-c_EP_RGC_ACC(l)-1 downto 0);

                  end if;

               end if;

            end if;

         end process P_rg_col;

         rg_col_cs(l)(k) <= ep_cmd_rx_nerr_rdy_r and (ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W) when ep_cmd_rx_wd_add_r = c_EP_RGC_ADD(l)(k) else '0';

      end generate G_rg_col;

      rg_col(k).smign <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN));
      rg_col(k).saign <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN));
      rg_col(k).sakkm <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM));
      rg_col(k).sakrm <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM));
      rg_col(k).salkv <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SALKV+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SALKV));
      rg_col(k).saolp <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP));
      rg_col(k).saofc <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC));
      rg_col(k).saofl <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL));
      rg_col(k).smfbd <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD));
      rg_col(k).saodd <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD));
      rg_col(k).saomd <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD));
      rg_col(k).smpdl <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL));
      rg_col(k).plsss <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS));
      rg_col(k).rldel <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL));
      rg_col(k).rlthr <= rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR));

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memories inputs generation
   --    @Req : REG_TEST_PATTERN
   --    @Req : REG_CY_A
   --    @Req : REG_CY_MUX_SQ_KI_KNORM
   --    @Req : REG_CY_MUX_SQ_KNORM
   --    @Req : REG_CY_MUX_SQ_FB0
   --    @Req : REG_CY_MUX_SQ_LOCKPOINT_V
   --    @Req : REG_CY_MUX_SQ_FB_MODE
   --    @Req : REG_CY_AMP_SQ_OFFSET_FINE
   --    @Req : REG_CY_PULSE_SHAPING
   --    @Req : REG_CY_DELOCK_COUNTERS
   --    @Req : DRE-DMX-FW-REQ-0170
   --    @Req : DRE-DMX-FW-REQ-0180
   --    @Req : DRE-DMX-FW-REQ-0190
   --    @Req : DRE-DMX-FW-REQ-0200
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : DRE-DMX-FW-REQ-0230
   --    @Req : DRE-DMX-FW-REQ-0300
   --    @Req : DRE-DMX-FW-REQ-0435
   --    @Req : DRE-DMX-FW-REQ-0440
   -- ------------------------------------------------------------------------------------------------------
   G_ep_mem : for l in 0 to c_EP_MEM_NUM_LAST-1 generate
   begin

      I_ep_mem: entity work.mem_in_gen generic map (
         g_MEM_ADD_S          => c_EP_MEM_ADDAC_S(l+1)-c_EP_MEM_ADDAC_S(l), -- integer                      ; --! Memory address size
         g_MEM_ADD_OFF        => c_EP_MEM_ADD_OFF(l)  , -- std_logic_vector(c_EP_SPI_WD_S-1 downto 0)       ; --! Memory address offset
         g_MEM_ADD_END        => c_EP_MEM_ADD_END(l)    -- integer                                            --! Memory address end
      ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_col_nb             => col_nb               , -- in     slv(log2_ceil(c_NB_COL)-1 downto 0)       ; --! Column number
         i_ep_cmd_rx_wd_add_r => ep_cmd_rx_wd_add_r(c_EP_MEM_ADDAC_S(l+1)-c_EP_MEM_ADDAC_S(l)-1 downto 0)   , --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_rw_r     => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r => ep_cmd_rx_nerr_rdy_r , -- in     std_logic                                 ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              => cs_rg_r(c_EP_MEM_POS(l)), -- in  std_logic                                 ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in_add         => mem_in_add(c_EP_MEM_ADDAC_S(l+1)-1 downto c_EP_MEM_ADDAC_S(l))             , --! Memory inputs: Address
         o_mem_in_we          => mem_in_we(l)         , -- out    std_logic                                 ; --! Memory inputs: Write enable ('0' = Inactive, '1' = Active)
         o_mem_in_cs          => mem_in_cs(l)         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Memory inputs: Chip select  ('0' = Inactive, '1' = Active)
         o_mem_in_pp          => mem_in_pp(l)         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Memory inputs: Ping-pong buffer bit
         o_cs_data_rd         => ep_mem_cs(l)           -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Chip select data read ('0' = Inactive, '1' = Active)
      );

   end generate G_ep_mem;

   G_ep_mem_col : for k in 0 to c_NB_COL-1 generate
   begin

      o_ep_mem(k).tstpt.add     <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_TSTPT+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_TSTPT));
      o_ep_mem(k).tstpt.we      <= mem_in_we(c_EP_MEM_NUM_TSTPT);
      o_ep_mem(k).tstpt.cs      <= mem_in_cs(c_EP_MEM_NUM_TSTPT)(k);
      o_ep_mem(k).tstpt.pp      <= mem_in_pp(c_EP_MEM_NUM_TSTPT)(k);
      o_ep_mem(k).tstpt.data_w  <= ep_cmd_rx_wd_data_r(o_ep_mem(k).tstpt.data_w'range);

      o_mem_prc(k).parma.add    <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_PARMA+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_PARMA));
      o_mem_prc(k).parma.we     <= mem_in_we(c_EP_MEM_NUM_PARMA);
      o_mem_prc(k).parma.cs     <= mem_in_cs(c_EP_MEM_NUM_PARMA)(k);
      o_mem_prc(k).parma.pp     <= mem_in_pp(c_EP_MEM_NUM_PARMA)(k);
      o_mem_prc(k).parma.data_w <= ep_cmd_rx_wd_data_r(o_mem_prc(k).parma.data_w'range);

      o_mem_prc(k).kiknm.add    <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_KIKNM+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_KIKNM));
      o_mem_prc(k).kiknm.we     <= mem_in_we(c_EP_MEM_NUM_KIKNM);
      o_mem_prc(k).kiknm.cs     <= mem_in_cs(c_EP_MEM_NUM_KIKNM)(k);
      o_mem_prc(k).kiknm.pp     <= mem_in_pp(c_EP_MEM_NUM_KIKNM)(k);
      o_mem_prc(k).kiknm.data_w <= ep_cmd_rx_wd_data_r(o_mem_prc(k).kiknm.data_w'range);

      o_mem_prc(k).knorm.add    <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_KNORM+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_KNORM));
      o_mem_prc(k).knorm.we     <= mem_in_we(c_EP_MEM_NUM_KNORM);
      o_mem_prc(k).knorm.cs     <= mem_in_cs(c_EP_MEM_NUM_KNORM)(k);
      o_mem_prc(k).knorm.pp     <= mem_in_pp(c_EP_MEM_NUM_KNORM)(k);
      o_mem_prc(k).knorm.data_w <= ep_cmd_rx_wd_data_r(o_mem_prc(k).knorm.data_w'range);

      o_mem_prc(k).smfb0.add    <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMFB0+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMFB0));
      o_mem_prc(k).smfb0.we     <= mem_in_we(c_EP_MEM_NUM_SMFB0);
      o_mem_prc(k).smfb0.cs     <= mem_in_cs(c_EP_MEM_NUM_SMFB0)(k);
      o_mem_prc(k).smfb0.pp     <= mem_in_pp(c_EP_MEM_NUM_SMFB0)(k);
      o_mem_prc(k).smfb0.data_w <= ep_cmd_rx_wd_data_r(o_mem_prc(k).smfb0.data_w'range);

      o_mem_prc(k).smlkv.add    <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMLKV+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMLKV));
      o_mem_prc(k).smlkv.we     <= mem_in_we(c_EP_MEM_NUM_SMLKV);
      o_mem_prc(k).smlkv.cs     <= mem_in_cs(c_EP_MEM_NUM_SMLKV)(k);
      o_mem_prc(k).smlkv.pp     <= mem_in_pp(c_EP_MEM_NUM_SMLKV)(k);
      o_mem_prc(k).smlkv.data_w <= ep_cmd_rx_wd_data_r(o_mem_prc(k).smlkv.data_w'range);

      o_ep_mem(k).smfbm.add     <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMFBM+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SMFBM));
      o_ep_mem(k).smfbm.we      <= mem_in_we(c_EP_MEM_NUM_SMFBM);
      o_ep_mem(k).smfbm.cs      <= mem_in_cs(c_EP_MEM_NUM_SMFBM)(k);
      o_ep_mem(k).smfbm.pp      <= mem_in_pp(c_EP_MEM_NUM_SMFBM)(k);
      o_ep_mem(k).smfbm.data_w  <= ep_cmd_rx_wd_data_r(o_ep_mem(k).smfbm.data_w'range);

      o_ep_mem(k).saoff.add     <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SAOFF+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_SAOFF));
      o_ep_mem(k).saoff.we      <= mem_in_we(c_EP_MEM_NUM_SAOFF);
      o_ep_mem(k).saoff.cs      <= mem_in_cs(c_EP_MEM_NUM_SAOFF)(k);
      o_ep_mem(k).saoff.pp      <= mem_in_pp(c_EP_MEM_NUM_SAOFF)(k);
      o_ep_mem(k).saoff.data_w  <= ep_cmd_rx_wd_data_r(o_ep_mem(k).saoff.data_w'range);

      o_ep_mem(k).plssh.add     <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_PLSSH+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_PLSSH));
      o_ep_mem(k).plssh.we      <= mem_in_we(c_EP_MEM_NUM_PLSSH);
      o_ep_mem(k).plssh.cs      <= mem_in_cs(c_EP_MEM_NUM_PLSSH)(k);
      o_ep_mem(k).plssh.pp      <= mem_in_pp(c_EP_MEM_NUM_PLSSH)(k);
      o_ep_mem(k).plssh.data_w  <= ep_cmd_rx_wd_data_r(o_ep_mem(k).plssh.data_w'range);

      o_ep_mem(k).dlcnt.add     <= mem_in_add(c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_DLCNT+1)-1 downto c_EP_MEM_ADDAC_S(c_EP_MEM_NUM_DLCNT));
      o_ep_mem(k).dlcnt.we      <= mem_in_we(c_EP_MEM_NUM_DLCNT);
      o_ep_mem(k).dlcnt.cs      <= mem_in_cs(c_EP_MEM_NUM_DLCNT)(k);
      o_ep_mem(k).dlcnt.pp      <= c_MEM_STR_ADD_PP_DEF;
      o_ep_mem(k).dlcnt.data_w  <= c_ZERO(o_ep_mem(o_ep_mem'low).dlcnt.data_w'range);

      I_squid_close_mode: entity work.squid_close_mode port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => i_clk_90             , -- in     std_logic                                 ; --! System Clock 90 degrees shift
         i_saofm              => rg_saofm(k)          , -- in     slv(c_DFLD_SAOFM_COL_S-1 downto 0)        ; --! SQUID AMP offset mode
         i_smfmd              => rg_smfmd(k)          , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_mem_smfbm          => o_ep_mem(k).smfbm    , -- in     t_mem                                     ; --! SQUID MUX feedback mode: memory inputs
         i_smfbm_add          => i_smfbm_add(k)       , -- in     slv( c_MEM_SMFBM_ADD_S-1 downto 0)        ; --! SQUID MUX feedback mode: address, memory output
         i_smfbm_cs           => i_smfbm_cs(k)        , -- in     std_logic                                 ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         o_squid_amp_close    => o_squid_amp_close(k) , -- out    std_logic                                 ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         o_squid_close_mode_n => o_squid_close_mode_n(k),--out    std_logic                                 ; --! SQUID MUX/AMP Close mode by pixel ('0' = Yes, '1' = No)
         o_amp_frst_lst_frm   => o_amp_frst_lst_frm(k)  -- in     std_logic                                   --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
      );

   end generate G_ep_mem_col;

   -- @Req : REG_HKEEP
   o_mem_hkeep_add   <= ep_cmd_rx_wd_add_r(  c_MEM_HKEEP_ADD_S-1 downto 0);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Register to transmit management
   --    @Req : DRE-DMX-FW-REQ-0510
   -- ------------------------------------------------------------------------------------------------------
   I_ep_cmd_tx_wd: entity work.ep_cmd_tx_wd port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_cs_rg              => cs_rg_r              , -- in     slv(c_EP_CMD_POS_NB-1 downto 0)           ; --! Chip selects register ('0' = Inactive, '1' = Active)

         i_brd_ref_rs         => i_brd_ref_rs         , -- in     slv(  c_BRD_REF_S-1 downto 0)             ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       => i_brd_model_rs       , -- in     slv(c_BRD_MODEL_S-1 downto 0)             ; --! Board model, synchronized on System Clock
         i_dlflg              => i_dlflg              , -- in     t_slv_arr c_NB_COL c_DFLD_DLFLG_COL_S     ; --! Delock flag

         i_rg_aqmde           => o_aqmde              , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! EP register: DATA_ACQ_MODE

         i_rg_smfmd           => rg_smfmd             , -- in     t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! EP register: MUX_SQ_FB_ON_OFF
         i_rg_saofm           => rg_saofm             , -- in     t_slv_arr c_NB_COL c_DFLD_SAOFM_COL_S     ; --! EP register: AMP_SQ_OFFSET_MODE
         i_rg_tsten           => rg_tsten             , -- in     slv(c_DFLD_TSTEN_S-1 downto 0)            ; --! EP register: TEST_PATTERN_ENABLE
         i_rg_bxlgt           => rg_bxlgt             , -- in     t_slv_arr c_NB_COL c_DFLD_BXLGT_COL_S     ; --! EP register: BOXCAR_LENGTH
         i_ep_cmd_sts_rg_r    => ep_cmd_sts_rg_r      , -- in     slv(c_EP_SPI_WD_S-1 downto 0)             ; --! EP command: Status register, registered

         i_rg_col             => rg_col               , -- in     t_rgc_arr(0 to c_NB_COL-1)                ; --! EP register by column
         i_rg_col_cs          => rg_col_cs            , -- in     t_slv_arr c_EP_RGC_NUM_LAST c_NB_COL      ; --! EP register by column chip select ('0'=Inactive, '1'=Active)

         i_mem_prc_data       => i_mem_prc_data       , -- in     t_mem_prc_dta_arr(0 to c_NB_COL-1)        ; --! Memory for data squid proc.: data read
         i_ep_mem_data        => i_ep_mem_data        , -- in     t_ep_mem_dta_arr(0 to c_NB_COL-1)         ; --! Memory: data read
         i_ep_mem_data_cs     => ep_mem_cs            , -- in     t_slv_arr c_EP_MEM_NUM_LAST c_NB_COL      ; --! Memory: chip select ('0'=Inactive, '1'=Active)

         i_hkeep_data         => i_hkeep_data         , -- in     slv(c_DFLD_HKEEP_S-1 downto 0)            ; --! Data read: Housekeeping

         o_ep_cmd_sts_err_add => o_ep_cmd_sts_err_add , -- out    std_logic                                 ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg => o_ep_cmd_tx_wd_rd_rg   -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)  --! EP command to transmit: read register word
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error last SPI command discarded
   --    @Req : REG_EP_CMD_ERR_DIS
   -- ------------------------------------------------------------------------------------------------------
   I_sts_err_dis_mgt: entity work.sts_err_dis_mgt port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_aqmde_dmp_cmp      => rg_aqmde_dmp_cmp     , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_ep_cmd_rx_add_norw => ep_cmd_rx_wd_add_r   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw_r       , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_dis => o_ep_cmd_sts_err_dis   -- out    std_logic                                   --! EP command: Status, error last SPI command discarded
   );

   -- ------------------------------------------------------------------------------------------------------
   --!  EP command: Status, error parameter to read not initialized yet
   --    @Req : REG_EP_CMD_ERR_IN
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_nin : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if cs_rg_r(c_EP_CMD_POS_HKEEP) = c_HGH_LEV and i_hk_err_nin = c_EP_CMD_ERR_SET then
            o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_SET;

         else
            o_ep_cmd_sts_err_nin <= c_EP_CMD_ERR_CLR;

         end if;

      end if;

   end process P_ep_cmd_sts_err_nin;

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs association
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : DRE-DMX-FW-REQ-0330
   -- ------------------------------------------------------------------------------------------------------
   P_out: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_aqmde_dmp_cmp <= (others => c_LOW_LEV);
         o_aqmde_tst_cmp <= (others => c_LOW_LEV);
         o_tsten_lop     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);
         o_tsten_inf     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_INF_POS);
         o_tsten_ena     <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_ENA_POS);

         o_smfmd         <= (others => c_EP_CMD_DEF_SMFMD);
         o_saofm         <= (others => c_EP_CMD_DEF_SAOFM);
         o_bxlgt         <= (others => c_EP_CMD_DEF_BXLGT);
         o_rg_col        <= (others => c_EP_RGC_REC_DEF);

      elsif rising_edge(i_clk) then
         o_aqmde_dmp_cmp <= (others => rg_aqmde_dmp_cmp);
         o_aqmde_tst_cmp <= (others => rg_aqmde_tst_cmp);
         o_tsten_lop     <= rg_tsten(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);
         o_tsten_inf     <= rg_tsten(c_DFLD_TSTEN_INF_POS);
         o_tsten_ena     <= rg_tsten(c_DFLD_TSTEN_ENA_POS);

         o_smfmd         <= rg_smfmd;
         o_saofm         <= rg_saofm;
         o_bxlgt         <= rg_bxlgt;
         o_rg_col        <= rg_col;

      end if;

   end process P_out;

end architecture RTL;
