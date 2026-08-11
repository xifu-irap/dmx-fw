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
--!   @file                   top_dmx_dm.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level Demonstrator Model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_mod.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity top_dmx_dm is port (
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock

         o_clk_sqm_adc        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Clock
         o_clk_sqm_dac        : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Clock
         o_clk_science_01     : out    std_logic                                                            ; --! Science Data: Clock channel 0/1
         o_clk_science_23     : out    std_logic                                                            ; --! Science Data: Clock channel 2/3

         i_brd_ref            : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         i_brd_model          : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_ras_data_valid     : in     std_logic                                                            ; --! RAS Data valid ('0' = No, '1' = Yes)

         i_sqm_adc_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S-1 downto 0)              ; --! SQUID MUX ADC: Data
         i_sqm_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)
         o_sqm_dac_data       : out    t_slv_arr(0 to c_NB_COL-1)(c_SQM_DAC_DATA_S-1 downto 0)              ; --! SQUID MUX DAC: Data

         o_science_ctrl_01    : out    std_logic                                                            ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    : out    std_logic                                                            ; --! Science Data: Control channel 2/3
         o_science_data       : out    t_slv_arr(0 to c_NB_COL)(c_SC_DATA_SER_NB-1 downto 0)                ; --! Science Data: Serial Data

         i_hk_spi_miso        : in     std_logic                                                            ; --! HouseKeeping: SPI Master Input Slave Output
         o_hk_spi_mosi        : out    std_logic                                                            ; --! HouseKeeping: SPI Master Output Slave Input
         o_hk_spi_sclk        : out    std_logic                                                            ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         o_hk_spi_cs_n        : out    std_logic                                                            ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk_mux             : out    std_logic_vector(c_HK_MUX_S-1 downto 0)                              ; --! HouseKeeping: Multiplexer
         o_hk_mux_ena_n       : out    std_logic                                                            ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        : in     std_logic                                                            ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        : out    std_logic                                                            ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        : in     std_logic                                                            ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        : in     std_logic                                                            ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_spi_sdio   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_pwdn       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         o_sqa_dac_data       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sqa_dac_mux        : out    t_slv_arr(0 to c_NB_COL-1)(c_SQA_DAC_MUX_S downto 1)                 ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_mx_en_n    : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

         o_spare              : out    std_logic                                                            ; --! Spare
         o_debug              : out    std_logic_vector(c_DEBUG_S  downto 1)                                  --! Debug
    );
end entity top_dmx_dm;

architecture RTL of top_dmx_dm is
signal   rst                  : std_logic                                                                   ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
signal   rst_sqm_adc_dac      : std_logic                                                                   ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)

signal   clk                  : std_logic                                                                   ; --! System Clock
signal   clk_sqm_adc_dac      : std_logic                                                                   ; --! SQUID ADC/DAC internal Clock
signal   clk_90               : std_logic                                                                   ; --! System Clock 90 degrees shift
signal   clk_sqm_adc_dac_90   : std_logic                                                                   ; --! SQUID ADC/DAC internal 90 degrees shift

signal   brd_ref_rs           : std_logic_vector(  c_BRD_REF_S-1 downto 0)                                  ; --! Board reference, synchronized on System Clock
signal   brd_model_rs         : std_logic_vector(c_BRD_MODEL_S-1 downto 0)                                  ; --! Board model, synchronized on System Clock
signal   sync_rs              : std_logic_vector(     c_NB_COL   downto 0)                                  ; --! Pixel sequence synchronization, synchronized on System Clock
signal   ras_data_valid_rs    : std_logic                                                                   ; --! RAS Data valid, synchronized on System Clock ('0' = No, '1' = Yes)

signal   hk_spi_miso_rs       : std_logic                                                                   ; --! HouseKeeping: SPI Master Input Slave Output, synchronized on System Clock
signal   ep_spi_mosi_rs       : std_logic                                                                   ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
signal   ep_spi_sclk_rs       : std_logic                                                                   ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
signal   ep_spi_cs_n_rs       : std_logic                                                                   ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock

signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge

signal   cmd_ck_adc_ena       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_adc_dis       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
signal   cmd_ck_sqm_dac_ena   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
signal   cmd_ck_sqm_dac_dis   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

signal   sqm_mem_dump_add     : std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                              ; --! SQUID MUX Memory Dump: address
signal   sqm_mem_dump_data    : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! SQUID MUX Memory Dump: data
signal   sqm_mem_dump_bsy     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

signal   sqm_data_err         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_ERR_S-1 downto 0)                     ; --! SQUID MUX Data error (signed)
signal   sqm_data_err_frst    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
signal   sqm_data_err_last    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
signal   sqm_data_err_rdy     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

signal   sqm_dta_pixel_pos    : t_slv_arr(0 to c_NB_COL-1)(c_MUX_FACT_S-1     downto 0)                     ; --! SQUID MUX Data error corrected pixel position
signal   sqm_dta_err_cor      : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_FBK_S-1 downto 0)                     ; --! SQUID MUX Data error corrected (signed)
signal   sqa_fb_close         : t_slv_arr(0 to c_NB_COL-1)(c_SQA_DAC_DATA_S+1 downto 0)                     ; --! SQUID AMP feedback close mode
signal   sqm_dta_err_cor_cs   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
signal   sqm_dta_err_frst     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data error corrected first pixel

signal   err_sig              : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)   ; --! Error signal (signed)
signal   sqm_data_sc          : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)   ; --! SQUID MUX Data science
signal   sqm_data_sc_first    : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_last     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
signal   sqm_data_sc_rdy      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

signal   sqm_data_fbk         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DATA_FBK_S-1 downto 0)                     ; --! SQUID MUX Data feedback (signed)
signal   sqm_pixel_pos_init   : t_slv_arr(0 to c_NB_COL-1)( c_SQM_PXL_POS_S-1 downto 0)                     ; --! SQUID MUX Pixel position initialization
signal   sqm_pls_cnt_init     : t_slv_arr(0 to c_NB_COL-1)( c_SQM_PLS_CNT_S-1 downto 0)                     ; --! SQUID MUX Pulse shaping counter initialization
signal   sqa_off_lsb          : t_slv_arr(0 to c_NB_COL-1)(c_SQA_DAC_DATA_S-1 downto 0)                     ; --! SQUID AMP offset LSB
signal   sqa_fbk_mux          : t_slv_arr(0 to c_NB_COL-1)( c_SQA_DAC_MUX_S-1 downto 0)                     ; --! SQUID AMP Feedback Multiplexer
signal   sqa_fbk_off          : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFC_COL_S-1 downto 0)                   ; --! SQUID AMP coarse offset
signal   sqa_pls_cnt_init     : t_slv_arr(0 to c_NB_COL-1)(   c_SQA_PLS_CNT_S-1 downto 0)                   ; --! SQUID AMP Pulse counter initialization

signal   test_pattern_sqm     : std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                               ; --! Test pattern: MUX SQUID
signal   test_pattern_sqa     : std_logic_vector(c_SQA_DAC_DATA_S-1 downto 0)                               ; --! Test pattern: AMP SQUID
signal   test_pattern_sc      : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0)   ; --! Test pattern: Science Telemetry
signal   tst_pat_new_step     : std_logic                                                                   ; --! Test pattern new step ('0' = Inactive, '1' = Active)
signal   tst_pat_end_pat      : std_logic                                                                   ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
signal   tst_pat_end          : std_logic                                                                   ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)
signal   tst_pat_end_re       : std_logic                                                                   ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
signal   tst_pat_empty        : std_logic                                                                   ; --! Test pattern empty ('0' = No, '1' = Yes)

signal   ck_science           : std_logic                                                                   ; --! Science Data: Image Clock channel
signal   science_data_ena     : std_logic                                                                   ; --! Science Data Enable
signal   science_data_ser     : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                        ; --! Science Data: Serial Data
signal   sc_data_sync_ck      : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                        ; --! Science Data: Serial Data synchronized on falling edge external generated clock

signal   hk_err_nin           : std_logic                                                                   ; --! Housekeeping: Error parameter to read not initialized yet
signal   ep_cmd_sts_err_add   : std_logic                                                                   ; --! EP command: Status, error invalid address
signal   ep_cmd_sts_err_nin   : std_logic                                                                   ; --! EP command: Status, error parameter to read not initialized yet
signal   ep_cmd_sts_err_dis   : std_logic                                                                   ; --! EP command: Status, error last SPI command discarded
signal   ep_cmd_sts_rg        : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command: status register

signal   ep_cmd_rx_wd_add     : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: address word, read/write bit cleared
signal   ep_cmd_rx_wd_data    : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command receipted: data word
signal   ep_cmd_rx_rw         : std_logic                                                                   ; --! EP command receipted: read/write bit
signal   ep_cmd_rx_nerr_rdy   : std_logic                                                                   ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

signal   ep_cmd_tx_wd_rd_rg   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --! EP command to transmit: read register word

signal   aqmde_dmp_tx_end     : std_logic                                                                   ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
signal   aqmde                : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode
signal   aqmde_dmp_cmp        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
signal   aqmde_tst_cmp        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Test Pattern" compared ('0' = Inactive, '1' = Active)
signal   aqmde_sync           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_AQMDE_S-1 downto 0)                       ; --! Telemetry mode, sync. on first pixel

signal   tsten_lop            : std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                             ; --! Test pattern enable, field Loop number
signal   tsten_inf            : std_logic                                                                   ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
signal   tsten_ena            : std_logic                                                                   ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

signal   adc_ena              : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! ADC enable ('0' = Inactive, '1' = Active)
signal   smfmd                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)                   ; --! SQUID MUX feedback mode
signal   saofm                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)                   ; --! SQUID AMP offset mode
signal   bxlgt                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)                   ; --! ADC sample number for averaging
signal   dlflg                : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_DLFLG_COL_S-1 downto 0)                   ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)
signal   rg_col               : t_rgc_arr(0 to c_NB_COL-1)                                                  ; --! EP register by column
signal   squid_gain           : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMIGN_COL_S-1 downto 0)                   ; --! SQUID gain

signal   mem_prc              : t_mem_prc_arr(0 to c_NB_COL-1)                                              ; --! Memory for data squid proc.: memory interface
signal   mem_data_prc         : t_mem_prc_dta_arr(0 to c_NB_COL-1)                                          ; --! Memory for data squid proc.: data read

signal   ep_mem               : t_ep_mem_arr(0 to c_NB_COL-1)                                               ; --! Memory: memory interface
signal   ep_mem_data          : t_ep_mem_dta_arr(0 to c_NB_COL-1)                                           ; --! Memory: data read

signal   mem_hkeep_add        : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0)                              ; --! Housekeeping: memory address
signal   hkeep_data           : std_logic_vector(c_DFLD_HKEEP_S-1 downto 0)                                 ; --! Housekeeping: data read

signal   smfbm_add            : t_slv_arr(0 to c_NB_COL-1)( c_MEM_SMFBM_ADD_S-1 downto 0)                   ; --! SQUID MUX feedback mode: address, memory output
signal   smfbm_cs             : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
signal   squid_amp_close      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
signal   squid_close_mode_n   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
signal   amp_frst_lst_frm     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Manage the internal reset and generate the clocks
   -- ------------------------------------------------------------------------------------------------------
   I_rst_clk_mgt: entity work.rst_clk_mgt port map (
         i_clk_ref            => i_clk_ref            , -- in     std_logic                                 ; --! Reference Clock

         i_cmd_ck_adc_ena     => cmd_ck_adc_ena       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_adc_dis     => cmd_ck_adc_dis       , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         i_cmd_ck_sqm_dac_ena => cmd_ck_sqm_dac_ena   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_sqm_dac_dis => cmd_ck_sqm_dac_dis   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)

         o_rst                => rst                  , -- out    std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         o_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- out    std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)

         o_clk                => clk                  , -- out    std_logic                                 ; --! System Clock
         o_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- out    std_logic                                 ; --! SQUID ADC/DAC internal Clock

         o_ck_sqm_adc         => o_clk_sqm_adc        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Image Clocks
         o_ck_sqm_dac         => o_clk_sqm_dac        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Image Clocks
         o_ck_science         => ck_science           , -- out    std_logic                                 ; --! Science Data Image Clock
         o_science_data_ena   => science_data_ena     , -- out    std_logic                                 ; --! Science Data Enable

         o_clk_90             => clk_90               , -- out    std_logic                                 ; --! System Clock 90 degrees shift
         o_clk_sqm_adc_dac_90 => clk_sqm_adc_dac_90   , -- out    std_logic                                 ; --! SQUID ADC/DAC internal 90 degrees shift

         o_sqm_adc_pwdn       => o_sqm_adc_pwdn       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      => o_sqm_dac_sleep        -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Data resynchronization on System Clock
   -- ------------------------------------------------------------------------------------------------------
   I_in_rs_clk: entity work.in_rs_clk port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_brd_ref            => i_brd_ref            , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => i_brd_model          , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => i_sync               , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_ras_data_valid     => i_ras_data_valid     , -- in     std_logic                                 ; --! RAS Data valid ('0' = No, '1' = Yes)

         i_hk_spi_miso        => i_hk_spi_miso        , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Input Slave Output

         i_ep_spi_mosi        => i_ep_spi_mosi        , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_sclk        => i_ep_spi_sclk        , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        => i_ep_spi_cs_n        , -- in     std_logic                                 ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_brd_ref_rs         => brd_ref_rs           , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         o_brd_model_rs       => brd_model_rs         , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock
         o_sync_rs            => sync_rs              , -- out    std_logic_vector(     c_NB_COL   downto 0); --! Pixel sequence synchronization, synchronized on System Clock
         o_ras_data_valid_rs  => ras_data_valid_rs    , -- out    std_logic                                 ; --! RAS Data valid, synchronized on System Clock ('0' = No, '1' = Yes)

         o_hk_spi_miso_rs     => hk_spi_miso_rs       , -- out    std_logic                                 ; --! HouseKeeping: SPI Master Input Slave Output, synchronized on System Clock

         o_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- out    std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         o_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- out    std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         o_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- out    std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Management
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_mgt: entity work.science_data_mgt port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_ras_data_valid_rs  => ras_data_valid_rs    , -- in     std_logic                                 ; --! RAS Data valid, synchronized on System Clock ('0' = No, '1' = Yes)
         i_aqmde_sync         => aqmde_sync           , -- in     t_slv_arr c_NB_COL c_DFLD_AQMDE_S         ; --! Telemetry mode, sync. on first pixel
         i_tsten_ena          => tsten_ena            , -- in     std_logic                                 ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)
         i_tst_pat_end        => tst_pat_end          , -- in     std_logic                                 ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)
         i_tst_pat_end_pat    => tst_pat_end_pat      , -- in     std_logic                                 ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_new_step   => tst_pat_new_step     , -- in     std_logic                                 ; --! Test pattern new step ('0' = Inactive, '1' = Active)

         i_test_pattern_sc    => test_pattern_sc      , -- in     t_slv_arr c_NB_COL                        ; --! Test pattern: Science Telemetry
         i_err_sig            => err_sig              , -- in     t_slv_arr c_NB_COL                        ; --! Error signal (signed)
         i_sqm_data_sc        => sqm_data_sc          , -- in     t_slv_arr c_NB_COL                        ; --! SQUID MUX Data science
         i_sqm_data_sc_first  => sqm_data_sc_first    , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_last   => sqm_data_sc_last     , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_rdy    => sqm_data_sc_rdy      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         i_sqm_mem_dump_bsy   => sqm_mem_dump_bsy(c_COL0), -- in  std_logic                                 ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sqm_mem_dump_add   => sqm_mem_dump_add     , -- out    slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID MUX Memory Dump: address
         i_sqm_mem_dump_data  => sqm_mem_dump_data    , -- in     t_slv_arr c_NB_COL c_SQM_ADC_DATA_S+1     ; --! SQUID MUX Memory Dump: data

         o_aqmde_dmp_tx_end   => aqmde_dmp_tx_end     , -- out    std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)

         o_science_data_ser   => science_data_ser       -- out    slv       c_NB_COL*c_SC_DATA_SER_NB         --! Science Data: Serial Data
   );

   I_sc_data_sync_ck: entity work.science_data_sync_ck port map (
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock

         i_science_data_ser   => science_data_ser     , -- in     slv(c_NB_COL*c_SC_DATA_SER_NB downto 0)   ; --! Science Data: Serial Data
         i_science_data_ena   => science_data_ena     , -- in     std_logic                                 ; --! Science Data: Enable
         o_sc_data_sync_ck    => sc_data_sync_ck        -- out    slv(c_NB_COL*c_SC_DATA_SER_NB downto 0)     --! Science Data: Serial Data synchronized on falling edge external generated clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers management
   -- ------------------------------------------------------------------------------------------------------
   I_register_mgt: entity work.register_mgt port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_brd_ref_rs         => brd_ref_rs           , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference, synchronized on System Clock
         i_brd_model_rs       => brd_model_rs         , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model, synchronized on System Clock
         i_hk_err_nin         => hk_err_nin           , -- in     std_logic                                 ; --! Housekeeping Error parameter to read not initialized yet
         i_dlflg              => dlflg                , -- in     t_slv_arr c_NB_COL c_DFLD_DLFLG_COL_S     ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)

         o_ep_cmd_sts_err_add => ep_cmd_sts_err_add   , -- out    std_logic                                 ; --! EP command: Status, error invalid address
         o_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- out    std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         o_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- out    std_logic                                 ; --! EP command: Status, error last SPI command discarded
         i_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         i_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         i_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- in     std_logic                                 ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- in     std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         o_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         i_aqmde_dmp_tx_end   => aqmde_dmp_tx_end     , -- in     std_logic                                 ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_aqmde              => aqmde                , -- out    slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         o_aqmde_dmp_cmp      => aqmde_dmp_cmp        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_aqmde_tst_cmp      => aqmde_tst_cmp        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! Telemetry mode, status "Test pattern" compared ('0' = Inactive, '1' = Active)

         i_tst_pat_end_pat    => tst_pat_end_pat      , -- in     std_logic                                 ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_end_re     => tst_pat_end_re       , -- in     std_logic                                 ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         i_tst_pat_empty      => tst_pat_empty        , -- in     std_logic                                 ; --! Test pattern empty ('0' = No, '1' = Yes)
         o_tsten_lop          => tsten_lop            , -- out    slv(c_DFLD_TSTEN_LOP_S-1 downto 0)        ; --! Test pattern enable, field Loop number
         o_tsten_inf          => tsten_inf            , -- out    std_logic                                 ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
         o_tsten_ena          => tsten_ena            , -- out    std_logic                                 ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

         o_adc_ena            => adc_ena              , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! ADC enable ('0' = Inactive, '1' = Active)
         o_smfmd              => smfmd                , -- out    t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! SQUID MUX feedback mode
         o_saofm              => saofm                , -- out    t_slv_arr c_NB_COL c_DFLD_SAOFM_COL_S     ; --! SQUID AMP offset mode
         o_bxlgt              => bxlgt                , -- out    t_slv_arr c_NB_COL c_DFLD_BXLGT_COL_S     ; --! ADC sample number for averaging
         o_rg_col             => rg_col               , -- out    t_rgc                                     ; --! EP register by column
         o_squid_gain         => squid_gain           , -- out    t_slv_arr c_NB_COL c_DFLD_SMIGN_COL_S     ; --! SQUID gain
         o_sqa_off_lsb        => sqa_off_lsb          , -- out    t_slv_arr c_NB_COL c_SQA_DAC_DATA_S       ; --! SQUID AMP offset LSB

         o_mem_prc            => mem_prc              , -- out    t_mem_prc_arr(0 to c_NB_COL-1)            ; --! Memory for data squid proc.: memory interface
         i_mem_prc_data       => mem_data_prc         , -- in     t_mem_prc_dta_arr(0 to c_NB_COL-1)        ; --! Memory for data squid proc.: data read

         o_ep_mem             => ep_mem               , -- out    t_ep_mem_arr(0 to c_NB_COL-1)             ; --! Memory: memory interface
         i_ep_mem_data        => ep_mem_data          , -- in     t_ep_mem_dta_arr(0 to c_NB_COL-1)         ; --! Memory: data read

         o_mem_hkeep_add      => mem_hkeep_add        , -- out    slv(c_MEM_HKEEP_ADD_S-1 downto 0)         ; --! Housekeeping: memory address
         i_hkeep_data         => hkeep_data           , -- in     slv(c_DFLD_HKEEP_S-1 downto 0)            ; --! Housekeeping: data read

         i_smfbm_add          => smfbm_add            , -- in     t_slv_arr c_NB_COL c_MEM_SMFBM_ADD_S      ; --! SQUID MUX feedback mode: address, memory output
         i_smfbm_cs           => smfbm_cs             , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         o_squid_amp_close    => squid_amp_close      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         o_squid_close_mode_n => squid_close_mode_n   , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX/AMP Close mode by pixel ('0' = Yes, '1' = No)
         o_amp_frst_lst_frm   => amp_frst_lst_frm       -- in     std_logic                                   --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
      );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command
   -- ------------------------------------------------------------------------------------------------------
   I_ep_cmd: entity work.ep_cmd port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_ep_cmd_sts_err_add => ep_cmd_sts_err_add   , -- in     std_logic                                 ; --! EP command: Status, error invalid address
         i_ep_cmd_sts_err_nin => ep_cmd_sts_err_nin   , -- in     std_logic                                 ; --! EP command: Status, error parameter to read not initialized yet
         i_ep_cmd_sts_err_dis => ep_cmd_sts_err_dis   , -- in     std_logic                                 ; --! EP command: Status, error last SPI command discarded
         o_ep_cmd_sts_rg      => ep_cmd_sts_rg        , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command: Status register

         o_ep_cmd_rx_wd_add   => ep_cmd_rx_wd_add     , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: address word, read/write bit cleared
         o_ep_cmd_rx_wd_data  => ep_cmd_rx_wd_data    , -- out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command receipted: data word
         o_ep_cmd_rx_rw       => ep_cmd_rx_rw         , -- out    std_logic                                 ; --! EP command receipted: read/write bit
         o_ep_cmd_rx_nerr_rdy => ep_cmd_rx_nerr_rdy   , -- out    std_logic                                 ; --! EP command receipted with no error ready ('0'= Not ready, '1'= Ready)

         i_ep_cmd_tx_wd_rd_rg => ep_cmd_tx_wd_rd_rg   , -- in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0); --! EP command to transmit: read register word

         o_ep_spi_miso        => o_ep_spi_miso        , -- out    std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_mosi_rs     => ep_spi_mosi_rs       , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first), synchronized on System Clock
         i_ep_spi_sclk_rs     => ep_spi_sclk_rs       , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0'), synchronized on System Clock
         i_ep_spi_cs_n_rs     => ep_spi_cs_n_rs         -- in     std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive), synchronized on System Clock
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX commands
   -- ------------------------------------------------------------------------------------------------------
   I_dmx_cmd: entity work.dmx_cmd port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_sync_rs            => sync_rs(sync_rs'high), -- in     std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_adc_ena            => adc_ena              , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! ADC enable ('0' = Inactive, '1' = Active)
         i_smfmd              => smfmd                , -- in     t_slv_arr c_NB_COL c_DFLD_SMFMD_COL_S     ; --! SQUID MUX feedback mode
         o_sync_re            => sync_re              , -- out    std_logic                                 ; --! Pixel sequence synchronization, rising edge
         o_cmd_ck_adc_ena     => cmd_ck_adc_ena       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_adc_dis     => cmd_ck_adc_dis       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
         o_cmd_ck_sqm_dac_ena => cmd_ck_sqm_dac_ena   , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_sqm_dac_dis => cmd_ck_sqm_dac_dis     -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Housekeeping management
   -- ------------------------------------------------------------------------------------------------------
   I_hk_mgt: entity work.hk_mgt port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_mem_hkeep_add      => mem_hkeep_add        , -- in     slv(c_MEM_HKEEP_ADD_S-1 downto 0)         ; --! Housekeeping: memory address
         o_hkeep_data         => hkeep_data           , -- out    slv(c_DFLD_HKEEP_S-1 downto 0)            ; --! Housekeeping: data read
         o_hk_err_nin         => hk_err_nin           , -- out    std_logic                                 ; --! Housekeeping: Error parameter to read not initialized yet

         i_hk_spi_miso_rs     => hk_spi_miso_rs       , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Input Slave Output
         o_hk_spi_mosi        => o_hk_spi_mosi        , -- out    std_logic                                 ; --! HouseKeeping: SPI Master Output Slave Input
         o_hk_spi_sclk        => o_hk_spi_sclk        , -- out    std_logic                                 ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         o_hk_spi_cs_n        => o_hk_spi_cs_n        , -- out    std_logic                                 ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk_mux             => o_hk_mux             , -- out    std_logic_vector( cc_HK_MUX_S-1 downto 0) ; --! HouseKeeping: Multiplexer
         o_hk_mux_ena_n       => o_hk_mux_ena_n         -- out    std_logic                                   --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern generation
   -- ------------------------------------------------------------------------------------------------------
   I_test_pattern_gen: entity work.test_pattern_gen port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge
         i_tsten_lop          => tsten_lop            , -- in     slv(c_DFLD_TSTEN_LOP_S-1 downto 0)        ; --! Test pattern enable, field Loop number
         i_tsten_inf          => tsten_inf            , -- in     std_logic                                 ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
         i_tsten_ena          => tsten_ena            , -- in     std_logic                                 ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

         i_mem_tstpt          => ep_mem(c_COL0).tstpt , -- in     t_mem                                     ; --! Test pattern: memory inputs
         o_tstpt_data         => ep_mem_data(c_COL0).tstpt , -- out    slv(c_DFLD_TSTPT_S-1 downto 0)       ; --! Test pattern: data read

         o_test_pattern_sqm   => test_pattern_sqm     , -- out    slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! Test pattern: MUX SQUID
         o_test_pattern_sqa   => test_pattern_sqa     , -- out    slv(c_SQA_DAC_DATA_S-1 downto 0)          ; --! Test pattern: AMP SQUID
         o_tst_pat_new_step   => tst_pat_new_step     , -- out    std_logic                                 ; --! Test pattern new step ('0' = Inactive, '1' = Active)
         o_tst_pat_end_pat    => tst_pat_end_pat      , -- out    std_logic                                 ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         o_tst_pat_end        => tst_pat_end          , -- out    std_logic                                 ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)
         o_tst_pat_end_re     => tst_pat_end_re       , -- out    std_logic                                 ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         o_tst_pat_empty      => tst_pat_empty          -- out    std_logic                                   --! Test pattern empty ('0' = No, '1' = Yes)
   );

   G_tstpt_col_mgt: for k in c_ONE_INT to c_NB_COL-1 generate
   begin
      ep_mem_data(k).tstpt <= c_ZERO(ep_mem_data(k).tstpt'range);

   end generate G_tstpt_col_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Columns management
   --    @Req : DRE-DMX-FW-REQ-0070
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      I_squid_adc_mgt: entity work.squid_adc_mgt port map (
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_rs(c_FPGA_POS_ADC(k)), --in std_logic                                 ; --! Pixel sequence synchronization, synchronized on System Clock
         i_aqmde_dmp_cmp      => aqmde_dmp_cmp(k)     , -- in     std_logic                                 ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
         i_bxlgt              => bxlgt(k)             , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging
         i_smpdl              => rg_col(k).smpdl      , -- in     slv(c_DFLD_SMPDL_COL_S-1 downto 0)        ; --! ADC sample delay
         i_sqm_adc_data       => i_sqm_adc_data(k)    , -- in     slv(c_SQM_ADC_DATA_S-1 downto 0)          ; --! SQUID MUX ADC: Data, no rsync
         i_sqm_adc_oor        => i_sqm_adc_oor(k)     , -- in     std_logic                                 ; --! SQUID MUX ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         i_sqm_mem_dump_add   => sqm_mem_dump_add     , -- in     slv(c_MEM_DUMP_ADD_S-1 downto 0)          ; --! SQUID MUX Memory Dump: address
         o_sqm_mem_dump_data  => sqm_mem_dump_data(k) , -- out    slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! SQUID MUX Memory Dump: data
         o_sqm_mem_dump_bsy   => sqm_mem_dump_bsy(k)  , -- out    std_logic                                 ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)

         o_sqm_data_err       => sqm_data_err(k)      , -- out    slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error
         o_sqm_data_err_frst  => sqm_data_err_frst(k) , -- out    std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_last  => sqm_data_err_last(k) , -- out    std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         o_sqm_data_err_rdy   => sqm_data_err_rdy(k)    -- out    std_logic                                   --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)
      );

      I_squid_data_proc: entity work.squid_data_proc port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_adc_ena            => adc_ena(k)           , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! ADC enable ('0' = Inactive, '1' = Active)
         i_aqmde              => aqmde                , -- in     slv(c_DFLD_AQMDE_S-1 downto 0)            ; --! Telemetry mode
         i_bxlgt              => bxlgt(k)             , -- in     slv(c_DFLD_BXLGT_COL_S-1 downto 0)        ; --! ADC sample number for averaging
         i_smfmd              => smfmd(k)             , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_saofc              => rg_col(k).saofc      , -- in     slv(  c_SQA_DAC_DATA_S-1 downto 0)        ; --! SQUID AMP lockpoint coarse offset
         i_sakkm              => rg_col(k).sakkm      , -- in     slv(c_DFLD_SAKKM_COL_S-1 downto 0)        ; --! SQUID AMP ki*knorm
         i_sakrm              => rg_col(k).sakrm      , -- in     slv(c_DFLD_SAKRM_COL_S-1 downto 0)        ; --! SQUID AMP knorm
         i_salkv              => rg_col(k).salkv      , -- in     slv(c_DFLD_SALKV_COL_S-1 downto 0)        ; --! SQUID AMP elp
         i_rldel              => rg_col(k).rldel      , -- in     slv(c_DFLD_RLDEL_COL_S-1 downto 0)        ; --! Relock delay
         i_rlthr              => rg_col(k).rlthr      , -- in     slv(c_DFLD_RLTHR_COL_S-1 downto 0)        ; --! Relock threshold
         i_squid_gain         => squid_gain(k)        , -- in     slv(c_DFLD_SMIGN_COL_S-1 downto 0)        ; --! SQUID gain
         i_sqm_adc_pwdn       => o_sqm_adc_pwdn(k)    , -- in     std_logic                                 ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_mem_prc            => mem_prc(k)           , -- in     t_mem_prc                                 ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       => mem_data_prc(k)      , -- out    t_mem_prc_dta                             ; --! Memory for data squid proc.: data read

         o_smfbm_add          => smfbm_add(k)         , -- out    slv(c_MEM_SMFBM_ADD_S-1 downto 0)         ; --! SQUID MUX feedback mode: address, memory output
         o_smfbm_cs           => smfbm_cs(k)          , -- out    std_logic                                 ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)
         i_squid_amp_close    => squid_amp_close(k)   , -- in     std_logic                                 ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         i_squid_close_mode_n => squid_close_mode_n(k), -- in     std_logic                                 ; --! SQUID MUX/AMP Close mode by pixel ('0' = Yes, '1' = No)
         i_amp_frst_lst_frm   => amp_frst_lst_frm(k)  , -- in     std_logic                                 ; --! SQUID AMP First and Last frame('0' = No, '1' = Yes)

         i_sqm_data_err       => sqm_data_err(k)      , -- in     slv(c_SQM_DATA_ERR_S-1 downto 0)          ; --! SQUID MUX Data error
         i_sqm_data_err_frst  => sqm_data_err_frst(k) , -- in     std_logic                                 ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  => sqm_data_err_last(k) , -- in     std_logic                                 ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   => sqm_data_err_rdy(k)  , -- in     std_logic                                 ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_err_sig            => err_sig(k)           , -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Error signal (signed)
         o_sqm_data_sc        => sqm_data_sc(k)       , -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! SQUID MUX Data science
         o_sqm_data_sc_first  => sqm_data_sc_first(k) , -- out    std_logic                                 ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   => sqm_data_sc_last(k)  , -- out    std_logic                                 ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    => sqm_data_sc_rdy(k)   , -- out    std_logic                                 ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_aqmde_sync         => aqmde_sync(k)        , -- out    slv(  c_DFLD_AQMDE_S-1 downto 0)          ; --! Telemetry mode, sync. on first pixel
         o_sqm_dta_pixel_pos  => sqm_dta_pixel_pos(k) , -- out    slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_frst   => sqm_dta_err_frst(k)  , -- out    std_logic                                 ; --! SQUID MUX Data error corrected first pixel
         o_sqm_dta_err_cor    => sqm_dta_err_cor(k)   , -- out    slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         o_sqa_fb_close       => sqa_fb_close(k)      , -- out    slv(c_SQA_DAC_DATA_S+1 downto 0)          ; --! SQUID AMP feedback close mode
         o_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs(k), -- out    std_logic                                 ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_dlcnt          => ep_mem(k).dlcnt      , -- in     t_mem                                     ; --! Delock counter: memory inputs
         o_dlcnt_data         => ep_mem_data(k).dlcnt , -- out    slv(c_DFLD_DLCNT_PIX_S-1 downto 0)        ; --! Delock counter: data read
         o_dlflg              => dlflg(k)               -- out    slv(c_DFLD_DLFLG_COL_S-1 downto 0)          --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)
      );

      I_sqm_fbk_mgt: entity work.sqm_fbk_mgt port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge
         i_tst_pat_end        => tst_pat_end          , -- in     std_logic                                 ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)

         i_test_pattern       => test_pattern_sqm     , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! Test pattern
         i_sqm_dta_pixel_pos  => sqm_dta_pixel_pos(k) , -- in     slv(    c_MUX_FACT_S-1 downto 0)          ; --! SQUID MUX Data error corrected pixel position
         i_sqm_dta_err_cor    => sqm_dta_err_cor(k)   , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data error corrected (signed)
         i_sqm_dta_err_frst   => sqm_dta_err_frst(k)  , -- in     std_logic                                 ; --! SQUID MUX Data error corrected first pixel
         i_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs(k), -- in     std_logic                                 ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_aqmde_tst_cmp      => aqmde_tst_cmp(k)     , -- in     std_logic                                 ; --! Telemetry mode, status "Test pattern" compared ('0' = Inactive, '1' = Active)
         i_mem_smfb0          => mem_prc(k).smfb0     , -- in     t_mem                                     ; --! SQUID MUX feedback value in open loop: memory inputs
         i_smfmd              => smfmd(k)             , -- in     slv(c_DFLD_SMFMD_COL_S-1 downto 0)        ; --! SQUID MUX feedback mode
         i_smfbd              => rg_col(k).smfbd      , -- in     slv(c_DFLD_SMFBD_COL_S-1 downto 0)        ; --! SQUID MUX feedback delay
         i_mem_smfbm          => ep_mem(k).smfbm      , -- in     t_mem                                     ; --! SQUID MUX feedback mode: memory inputs
         o_smfbm_data         => ep_mem_data(k).smfbm , -- out    slv(c_DFLD_SMFBM_PIX_S-1 downto 0)        ; --! SQUID MUX feedback mode: data read

         o_test_pattern_sc    => test_pattern_sc(k)   , -- out    slv c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB    ; --! Test pattern: Science Telemetry
         o_sqm_data_fbk       => sqm_data_fbk(k)      , -- out    slv( c_SQM_DATA_FBK_S-1 downto 0)         ; --! SQUID MUX Data feedback (signed)
         o_sqm_pixel_pos_init => sqm_pixel_pos_init(k), -- out    slv( c_SQM_PXL_POS_S-1 downto 0)          ; --! SQUID MUX Pixel position initialization
         o_sqm_pls_cnt_init   => sqm_pls_cnt_init(k)    -- out    slv( c_SQM_PLS_CNT_S-1 downto 0)          ; --! SQUID MUX Pulse shaping counter initialization
      );

      I_sqm_dac_mgt: entity work.sqm_dac_mgt generic map (
         g_SQM_DATA_COMP      => c_SQM_DATA_COMP(k)     -- std_logic                                          --! SQUID MUX data complemented ('0' = No, '1' = Yes)
      ) port map (
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID MUX DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock
         i_clk_sqm_adc_dac_90 => clk_sqm_adc_dac_90   , -- in     std_logic                                 ; --! SQUID ADC/DAC internal 90 degrees shift

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_rs            => sync_rs(c_FPGA_POS_SQM_DAC(k)), -- in     std_logic                        ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sqm_data_fbk       => sqm_data_fbk(k)      , -- in     slv(c_SQM_DATA_FBK_S-1 downto 0)          ; --! SQUID MUX Data feedback
         i_sqm_pixel_pos_init => sqm_pixel_pos_init(k), -- in     slv( c_SQM_PXL_POS_S-1 downto 0)          ; --! SQUID MUX Pixel position initialization
         i_sqm_pls_cnt_init   => sqm_pls_cnt_init(k)  , -- in     slv( c_SQM_PLS_CNT_S-1 downto 0)          ; --! SQUID MUX Pulse shaping counter initialization
         i_plsss              => rg_col(k).plsss      , -- in     slv(c_DFLD_PLSSS_PLS_S  -1 downto 0)      ; --! SQUID MUX feedback pulse shaping set

         i_mem_plssh          => ep_mem(k).plssh      , -- in     t_mem                                     ; --! SQUID MUX feedback pulse shaping coefficient: memory inputs
         o_plssh_data         => ep_mem_data(k).plssh , -- out    slv(c_DFLD_PLSSH_PLS_S-1 downto 0)        ; --! SQUID MUX feedback pulse shaping coefficient: data read

         o_sqm_dac_data       => o_sqm_dac_data(k)      -- out    slv(c_SQM_DAC_DATA_S-1 downto 0)            --! SQUID MUX DAC: Data
      );

      I_sqa_fbk_mgt: entity work.sqa_fbk_mgt port map (
         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock
         i_clk_90             => clk_90               , -- in     std_logic                                 ; --! System Clock 90 degrees shift

         i_sync_re            => sync_re              , -- in     std_logic                                 ; --! Pixel sequence synchronization, rising edge

         i_saofm              => saofm(k)             , -- in     slv(c_DFLD_SAOFM_COL_S-1 downto 0)        ; --! SQUID AMP offset mode
         i_saofc              => rg_col(k).saofc      , -- in     slv(  c_SQA_DAC_DATA_S-1 downto 0)        ; --! SQUID AMP lockpoint coarse offset
         i_saomd              => rg_col(k).saomd      , -- in     slv(c_DFLD_SAOMD_COL_S-1 downto 0)        ; --! SQUID AMP offset MUX delay
         i_test_pattern       => test_pattern_sqa     , -- in     slv(  c_SQA_DAC_DATA_S-1 downto 0)        ; --! Test pattern
         i_sqm_dta_err_frst   => sqm_dta_err_frst(k)  , -- in     std_logic                                 ; --! SQUID MUX Data error corrected first pixel
         i_sqa_fb_close       => sqa_fb_close(k)      , -- in     slv(c_SQA_DAC_DATA_S+1 downto 0)          ; --! SQUID AMP feedback close mode
         i_sqm_dta_err_cor_cs => sqm_dta_err_cor_cs(k), -- in     std_logic                                 ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_saoff          => ep_mem(k).saoff      , -- in     t_mem                                     ; --! SQUID AMP lockpoint fine offset: memory inputs
         o_saoff_data         => ep_mem_data(k).saoff , -- out    slv(c_DFLD_SAOFF_PIX_S  -1 downto 0)      ; --! SQUID AMP lockpoint fine offset: data read

         o_sqa_fbk_mux        => sqa_fbk_mux(k)       , -- out    slv(   c_SQA_DAC_MUX_S-1 downto 0)        ; --! SQUID AMP Feedback Multiplexer
         o_sqa_fbk_off        => sqa_fbk_off(k)       , -- out    slv(  c_SQA_DAC_DATA_S-1 downto 0)        ; --! SQUID AMP coarse offset
         o_sqa_pls_cnt_init   => sqa_pls_cnt_init(k)    -- out    slv(   c_SQA_PLS_CNT_S-1 downto 0)          --! SQUID AMP Pulse counter initialization
      );

      I_sqa_dac_mgt: entity work.sqa_dac_mgt port map (
         i_rst_sqm_adc_dac    => rst_sqm_adc_dac      , -- in     std_logic                                 ; --! Reset for SQUID AMP DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    => clk_sqm_adc_dac      , -- in     std_logic                                 ; --! SQUID ADC/DAC internal Clock

         i_rst                => rst                  , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => clk                  , -- in     std_logic                                 ; --! System Clock

         i_sync_rs            => sync_rs(c_FPGA_POS_SQA_DAC(k)), -- in     std_logic                        ; --! Pixel sequence synchronization, synchronized on System Clock
         i_sqa_off_lsb        => sqa_off_lsb(k)       , -- in     slv(   c_SQA_DAC_MUX_S-1 downto 0)        ; --! SQUID AMP offset LSB
         i_sqa_fbk_mux        => sqa_fbk_mux(k)       , -- in     slv(   c_SQA_DAC_MUX_S-1 downto 0)        ; --! SQUID AMP Feedback Multiplexer
         i_sqa_fbk_off        => sqa_fbk_off(k)       , -- in     slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! SQUID AMP coarse offset
         i_saodd              => rg_col(k).saodd      , -- in     slv(c_DFLD_SAODD_COL_S-1 downto 0)        ; --! SQUID AMP offset DAC delay
         i_sqa_pls_cnt_init   => sqa_pls_cnt_init(k)  , -- in     slv(   c_SQA_PLS_CNT_S-1 downto 0)        ; --! SQUID AMP Pulse counter initialization

         o_sqa_dac_mux        => o_sqa_dac_mux(k)     , -- out    slv(c_SQA_DAC_MUX_S -1 downto 0)          ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_data       => o_sqa_dac_data(k)    , -- out    std_logic                                 ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       => o_sqa_dac_sclk(k)    , -- out    std_logic                                 ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    => o_sqa_dac_snc_l_n(k) , -- out    std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    => o_sqa_dac_snc_o_n(k)   -- out    std_logic                                   --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
      );

      I_sqm_spi_mgt: entity work.sqm_spi_mgt port map (
         o_sqm_adc_spi_mosi   => o_sqm_adc_spi_sdio(k), -- out    std_logic                                 ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   => o_sqm_adc_spi_sclk(k), -- out    std_logic                                 ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   => o_sqm_adc_spi_cs_n(k)  -- out    std_logic                                   --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)
      );

      o_science_data(k) <= sc_data_sync_ck((k+1)*c_SC_DATA_SER_NB-1 downto k*c_SC_DATA_SER_NB);

   end generate G_column_mgt;

   o_sqa_dac_mx_en_n <= (others => c_LOW_LEV);

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs association
   -- ------------------------------------------------------------------------------------------------------
   o_clk_science_01     <= ck_science;
   o_clk_science_23     <= ck_science;

   o_science_ctrl_01    <= sc_data_sync_ck(sc_data_sync_ck'high);
   o_science_ctrl_23    <= sc_data_sync_ck(sc_data_sync_ck'high);

   o_science_data(o_science_data'high) <= (others => c_LOW_LEV);
   o_spare                             <= c_LOW_LEV;
   o_debug                             <= (others => c_LOW_LEV);

end architecture RTL;
