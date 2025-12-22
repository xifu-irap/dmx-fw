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
--!   @file                   pkg_str_fld_assoc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package string field association
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;

library std;
use std.textio.all;

package pkg_str_fld_assoc is
constant c_RET_UKWN           : std_logic_vector(c_EP_SPI_WD_S-1 downto 0) :=
                                c_MINUSONE(c_EP_SPI_WD_S-1 downto 0)                                        ; --! Return unknown value

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete output name) included in line and the associated discrete output index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dw_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                              --  Field discrete output index (equal to c_DW_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete input name) included in line and the associated discrete input index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dr_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                              --  Field discrete input index (equal to c_DR_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (check parameters enable name) included in line and the associated check parameters enable index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_ce_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_ce             : out    line                                                                 ; --  Field check parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S+1                                            --  Field check parameters enable index (equal to c_CE_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command data) included in line and the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_data (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_data           : out    line                                                                 ; --  Field data
         o_fld_data_val       : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field data value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (science packet type) included in line and the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_sc_pkt_type (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                         --  Field science packet type value
   );

end pkg_str_fld_assoc;

package body pkg_str_fld_assoc is
constant c_PAD                : character := ' '                                                            ; --  Padding character

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete output name) included in line and the associated discrete output index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dw_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                              --  Field discrete output index (equal to c_DW_S if field not recognized)
   ) is
   variable v_fld_dw_pad      : line                                                                        ; --  Field discrete output with padding
   begin

      -- Get the discrete output name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_dw_pad);

      -- Return field discrete output index
      case v_fld_dw_pad(c_ONE_INT to c_SIG_NAME_STR_MAX_S) is
         when "arst_n              "   =>
            o_fld_dw_ind := c_DW_ARST_N;

         when "brd_model(0)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_0;

         when "brd_model(1)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_1;

         when "brd_model(2)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_2;

         when "sw_adc_vin(0)       "   =>
            o_fld_dw_ind := c_DW_SW_ADC_VIN_0;

         when "sw_adc_vin(1)       "   =>
            o_fld_dw_ind := c_DW_SW_ADC_VIN_1;

         when "frm_cnt_sc_rst      "   =>
            o_fld_dw_ind := c_DW_FRM_CNT_SC_RST;

         when "ras_data_valid      "   =>
            o_fld_dw_ind := c_DW_RAS_DATA_VALID;

         when others                   =>
            o_fld_dw_ind := c_DW_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_dw_pad, c_PAD, o_fld_dw);

   end get_dw_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete input name) included in line and the associated discrete input index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dr_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                              --  Field discrete input index (equal to c_DR_S if field not recognized)
   ) is
   variable v_fld_dr_pad      : line                                                                        ; --  Field discrete input with padding
   begin

      -- Get the discrete input name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_dr_pad);

      -- Return field discrete output index
      case v_fld_dr_pad(c_ONE_INT to c_SIG_NAME_STR_MAX_S) is
         when "rst                 "   =>
            o_fld_dr_ind := c_DR_D_RST;

         when "clk_ref             "   =>
            o_fld_dr_ind := c_DR_CLK_REF;

         when "clk                 "   =>
            o_fld_dr_ind := c_DR_D_CLK;

         when "clk_sqm_adc_acq     "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQM_ADC;

         when "clk_sqm_pls_shape   "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQM_PLS_SH;

         when "ep_cmd_busy_n       "   =>
            o_fld_dr_ind := c_DR_EP_CMD_BUSY_N;

         when "ep_data_rx_rdy      "   =>
            o_fld_dr_ind := c_DR_EP_DATA_RX_RDY;

         when "rst_sqm_adc(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_0;

         when "rst_sqm_adc(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_1;

         when "rst_sqm_adc(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_2;

         when "rst_sqm_adc(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_3;

         when "rst_sqm_dac(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_0;

         when "rst_sqm_dac(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_1;

         when "rst_sqm_dac(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_2;

         when "rst_sqm_dac(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_3;

         when "rst_sqa_mux(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_0;

         when "rst_sqa_mux(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_1;

         when "rst_sqa_mux(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_2;

         when "rst_sqa_mux(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_3;

         when "sync                "   =>
            o_fld_dr_ind := c_DR_SYNC;

         when "sqm_adc_pwdn(0)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_0;

         when "sqm_adc_pwdn(1)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_1;

         when "sqm_adc_pwdn(2)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_2;

         when "sqm_adc_pwdn(3)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_3;

         when "sqm_dac_sleep(0)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_0;

         when "sqm_dac_sleep(1)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_1;

         when "sqm_dac_sleep(2)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_2;

         when "sqm_dac_sleep(3)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_3;

         when "clk_sqm_adc(0)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_0;

         when "clk_sqm_adc(1)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_1;

         when "clk_sqm_adc(2)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_2;

         when "clk_sqm_adc(3)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_3;

         when "clk_sqm_dac(0)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_0;

         when "clk_sqm_dac(1)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_1;

         when "clk_sqm_dac(2)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_2;

         when "clk_sqm_dac(3)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_3;

         when "fpa_conf_busy(0)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_0;

         when "fpa_conf_busy(1)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_1;

         when "fpa_conf_busy(2)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_2;

         when "fpa_conf_busy(3)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_3;

         when "clk_science_01      "   =>
            o_fld_dr_ind := c_DR_CLK_SCIENCE_01;

         when "clk_science_23      "   =>
            o_fld_dr_ind := c_DR_CLK_SCIENCE_23;

         when others                   =>
            o_fld_dr_ind := c_DR_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_dr_pad, c_PAD, o_fld_dr);

   end get_dr_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (check parameters enable name) included in line and the associated check parameters enable index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_ce_index (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_ce             : out    line                                                                 ; --  Field check parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S+1                                            --  Field check parameters enable index (equal to c_CE_S if field not recognized)
   ) is
   variable v_fld_ce_pad      : line                                                                        ; --  Field check parameters enable with padding
   begin

      -- Get the check parameters enable name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_ce_pad);

      -- Return field discrete output index
      case v_fld_ce_pad(c_ONE_INT to c_SIG_NAME_STR_MAX_S) is
         when "clk                 "   =>
            o_fld_ce_ind := c_CE_CLK;

         when "clk_sqm_adc         "   =>
            o_fld_ce_ind := c_CE_CK1_ADC;

         when "clk_sqm_pls_shape   "   =>
            o_fld_ce_ind := c_CE_CK1_PLS;

         when "clk_sqm_adc(0)      "   =>
            o_fld_ce_ind := c_CE_C0_CK1_ADC;

         when "clk_sqm_adc(1)      "   =>
            o_fld_ce_ind := c_CE_C1_CK1_ADC;

         when "clk_sqm_adc(2)      "   =>
            o_fld_ce_ind := c_CE_C2_CK1_ADC;

         when "clk_sqm_adc(3)      "   =>
            o_fld_ce_ind := c_CE_C3_CK1_ADC;

         when "clk_sqm_dac(0)      "   =>
            o_fld_ce_ind := c_CE_C0_CK1_DAC;

         when "clk_sqm_dac(1)      "   =>
            o_fld_ce_ind := c_CE_C1_CK1_DAC;

         when "clk_sqm_dac(2)      "   =>
            o_fld_ce_ind := c_CE_C2_CK1_DAC;

         when "clk_sqm_dac(3)      "   =>
            o_fld_ce_ind := c_CE_C3_CK1_DAC;

         when "clk_science_01      "   =>
            o_fld_ce_ind := c_CE_CLK_SC_01;

         when "clk_science_23      "   =>
            o_fld_ce_ind := c_CE_CLK_SC_23;

         when "spi_hk              "   =>
            o_fld_ce_ind := c_SPIE_HK;

         when "spi_sqa_lsb(0)      "   =>
            o_fld_ce_ind := c_SPIE_C0_SQA_LSB;

         when "spi_sqa_off(0)      "   =>
            o_fld_ce_ind := c_SPIE_C0_SQA_OFF;

         when "spi_sqa_lsb(1)      "   =>
            o_fld_ce_ind := c_SPIE_C1_SQA_LSB;

         when "spi_sqa_off(1)      "   =>
            o_fld_ce_ind := c_SPIE_C1_SQA_OFF;

         when "spi_sqa_lsb(2)      "   =>
            o_fld_ce_ind := c_SPIE_C2_SQA_LSB;

         when "spi_sqa_off(2)      "   =>
            o_fld_ce_ind := c_SPIE_C2_SQA_OFF;

         when "spi_sqa_lsb(3)      "   =>
            o_fld_ce_ind := c_SPIE_C3_SQA_LSB;

         when "spi_sqa_off(3)      "   =>
            o_fld_ce_ind := c_SPIE_C3_SQA_OFF;

         when "pulse_shaping       "   =>
            o_fld_ce_ind := c_E_PLS_SHP;

         when others                   =>
            o_fld_ce_ind := c_CE_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_ce_pad, c_PAD, o_fld_ce);

   end get_ce_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command data) included in line and the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_data (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_data           : out    line                                                                 ; --  Field data
         o_fld_data_val       : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field data value
   ) is
   variable v_fld_data_pad    : line                                                                        ; --  Field data with padding
   begin

      -- Get the data name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_data_pad);

      -- Return data value
      case v_fld_data_pad(c_ONE_INT to c_CMD_NAME_STR_MAX_S) is
         when "FW_VERSION                    "  =>
            o_fld_data_val:= std_logic_vector(to_unsigned(c_FW_VERSION, o_fld_data_val'length));

         when "HK_P1V8_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P1V8_ANA_DEF), o_fld_data_val'length));

         when "HK_P2V5_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P2V5_ANA_DEF), o_fld_data_val'length));

         when "HK_M2V5_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_M2V5_ANA_DEF), o_fld_data_val'length));

         when "HK_P3V3_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P3V3_ANA_DEF), o_fld_data_val'length));

         when "HK_M5V0_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_M5V0_ANA_DEF), o_fld_data_val'length));

         when "HK_P1V2_DIG_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P1V2_DIG_DEF), o_fld_data_val'length));

         when "HK_P2V5_DIG_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P2V5_DIG_DEF), o_fld_data_val'length));

         when "HK_P2V5_AUX_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P2V5_AUX_DEF), o_fld_data_val'length));

         when "HK_P3V3_DIG_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P3V3_DIG_DEF), o_fld_data_val'length));

         when "HK_VREF_TMP_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_VREF_TMP_DEF), o_fld_data_val'length));

         when "HK_VREF_R2R_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_VREF_R2R_DEF), o_fld_data_val'length));

         when "HK_SPARE_VAL                  "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_SPARE_DEF),    o_fld_data_val'length));

         when "HK_P5V0_ANA_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_P5V0_ANA_DEF), o_fld_data_val'length));

         when "HK_TEMP_AVE_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_TEMP_AVE_DEF), o_fld_data_val'length));

         when "HK_TEMP_MAX_VAL               "  =>
            o_fld_data_val:= std_logic_vector(resize(unsigned(c_HK_TEMP_MAX_DEF), o_fld_data_val'length));

         when others                            =>
            o_fld_data_val:= c_RET_UKWN;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_data_pad, c_PAD, o_fld_data);

   end get_cmd_data;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (science packet type) included in line and the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_sc_pkt_type (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                         --  Field science packet type value
   ) is
   variable v_fld_sc_pkt_pad  : line                                                                        ; --  Field science packet type with padding
   begin

      -- Drop padding character(s)
      drop_line_char(b_line, c_PAD, b_line);

      -- Get the science packet type name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_sc_pkt_pad);

      -- Return the science packet type value
      case v_fld_sc_pkt_pad(c_ONE_INT to c_CMD_NAME_STR_MAX_S) is
         when "data_word                     "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_DTW;

         when "science                       "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_FWS;

         when "test_pattern                  "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_TPT;

         when "adc_dump                      "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_FWD;

         when "adc_data                      "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_FWA;

         when "demux_data_valid              "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_DDV;

         when "ras_data_valid                "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_RDV;

         when others                            =>
            o_fld_sc_pkt_val:= c_RET_UKWN(o_fld_sc_pkt_val'range);

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_sc_pkt_pad, c_PAD, o_fld_sc_pkt);

   end get_sc_pkt_type;

end package body pkg_str_fld_assoc;
