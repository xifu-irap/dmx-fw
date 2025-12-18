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
--!   @file                   pkg_str_add_assoc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package string address association
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
use     work.pkg_str_fld_assoc.all;

library std;
use std.textio.all;

package pkg_str_add_assoc is

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command address) included in line and the associated address value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_add (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_add            : out    line                                                                 ; --  Field address
         o_fld_add_val        : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field address value
   );

end pkg_str_add_assoc;

package body pkg_str_add_assoc is
constant c_PAD                : character := ' '                                                            ; --  Padding character

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command address) included in line and the associated address value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_add (
         b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_add            : out    line                                                                 ; --  Field address
         o_fld_add_val        : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field address value
   ) is
   variable v_fld_add_pad     : line                                                                        ; --  Field address with padding
   begin

      -- Get the address name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_add_pad);

      -- Return address value
      case v_fld_add_pad(c_ONE_INT to c_CMD_NAME_STR_MAX_S) is
         when "DATA_ACQ_MODE                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_AQMDE;

         when "MUX_SQ_FB_ON_OFF              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFMD;

         when "AMP_SQ_OFFSET_MODE            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFM;

         when "TEST_PATTERN                  "  =>
            o_fld_add_val:= c_EP_CMD_ADD_TSTPT;

         when "TEST_PATTERN_ENABLE           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_TSTEN;

         when "BOXCAR_LENGTH                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_BXLGT;

         when "HK_P1V8_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P1V8_ANA;

         when "HK_P2V5_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P2V5_ANA;

         when "HK_M2V5_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_M2V5_ANA;

         when "HK_P3V3_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P3V3_ANA;

         when "HK_M5V0_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_M5V0_ANA;

         when "HK_P1V2_DIG                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P1V2_DIG;

         when "HK_P2V5_DIG                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P2V5_DIG;

         when "HK_P2V5_AUX                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P2V5_AUX;

         when "HK_P3V3_DIG                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P3V3_DIG;

         when "HK_VREF_TMP                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_VREF_TMP;

         when "HK_VREF_R2R                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_VREF_R2R;

         when "HK_VGND                       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_SPARE;

         when "HK_P5V0_ANA                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_P5V0_ANA;

         when "HK_TEMP_AVE                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_TEMP_AVE;

         when "HK_TEMP_MAX                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HKEEP(o_fld_add_val'high downto c_MEM_HKEEP_ADD_S) & c_HK_ADD_TEMP_MAX;

         when "DELOCK_FLAG                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLFLG;

         when "Status                        "  =>
            o_fld_add_val:= c_EP_CMD_ADD_STATUS;

         when "Fw_Version                    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_FW_VER;

         when "Hw_Version                    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HW_VER;

         when "C0_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(c_COL0);

         when "C0_MUX_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMIGN(c_COL0);

         when "C0_AMP_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAIGN(c_COL0);

         when "C0_MUX_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(c_COL0);

         when "C0_AMP_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKKM(c_COL0);

         when "C0_MUX_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(c_COL0);

         when "C0_AMP_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKRM(c_COL0);

         when "C0_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(c_COL0);

         when "C0_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(c_COL0);

         when "C0_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(c_COL0);

         when "C0_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(c_COL0);

         when "C0_AMP_SQ_OFFSET_LSB_PTR      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOLP(c_COL0);

         when "C0_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(c_COL0);

         when "C0_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(c_COL0);

         when "C0_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(c_COL0);

         when "C0_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(c_COL0);

         when "C0_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(c_COL0);

         when "C0_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(c_COL0);

         when "C0_PULSE_SHAPING              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(c_COL0);

         when "C0_PULSE_SHAPING_SELECTION    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(c_COL0);

         when "C0_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(c_COL0);

         when "C0_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(c_COL0);

         when "C0_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(c_COL0);

         when "C1_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(c_COL1);

         when "C1_MUX_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMIGN(c_COL1);

         when "C1_AMP_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAIGN(c_COL1);

         when "C1_MUX_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(c_COL1);

         when "C1_AMP_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKKM(c_COL1);

         when "C1_MUX_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(c_COL1);

         when "C1_AMP_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKRM(c_COL1);

         when "C1_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(c_COL1);

         when "C1_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(c_COL1);

         when "C1_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(c_COL1);

         when "C1_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(c_COL1);

         when "C1_AMP_SQ_OFFSET_LSB_PTR      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOLP(c_COL1);

         when "C1_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(c_COL1);

         when "C1_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(c_COL1);

         when "C1_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(c_COL1);

         when "C1_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(c_COL1);

         when "C1_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(c_COL1);

         when "C1_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(c_COL1);

         when "C1_PULSE_SHAPING              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(c_COL1);

         when "C1_PULSE_SHAPING_SELECTION    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(c_COL1);

         when "C1_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(c_COL1);

         when "C1_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(c_COL1);

         when "C1_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(c_COL1);

         when "C2_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(c_COL2);

         when "C2_MUX_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMIGN(c_COL2);

         when "C2_AMP_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAIGN(c_COL2);

         when "C2_MUX_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(c_COL2);

         when "C2_AMP_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKKM(c_COL2);

         when "C2_MUX_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(c_COL2);

         when "C2_AMP_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKRM(c_COL2);

         when "C2_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(c_COL2);

         when "C2_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(c_COL2);

         when "C2_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(c_COL2);

         when "C2_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(c_COL2);

         when "C2_AMP_SQ_OFFSET_LSB_PTR      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOLP(c_COL2);

         when "C2_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(c_COL2);

         when "C2_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(c_COL2);

         when "C2_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(c_COL2);

         when "C2_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(c_COL2);

         when "C2_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(c_COL2);

         when "C2_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(c_COL2);

         when "C2_PULSE_SHAPING              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(c_COL2);

         when "C2_PULSE_SHAPING_SELECTION    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(c_COL2);

         when "C2_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(c_COL2);

         when "C2_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(c_COL2);

         when "C2_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(c_COL2);

         when "C3_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(c_COL3);

         when "C3_MUX_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMIGN(c_COL3);

         when "C3_AMP_SQ_INPUT_GAIN          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAIGN(c_COL3);

         when "C3_MUX_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(c_COL3);

         when "C3_AMP_SQ_KI_KNORM            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKKM(c_COL3);

         when "C3_MUX_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(c_COL3);

         when "C3_AMP_SQ_KNORM               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAKRM(c_COL3);

         when "C3_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(c_COL3);

         when "C3_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(c_COL3);

         when "C3_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(c_COL3);

         when "C3_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(c_COL3);

         when "C3_AMP_SQ_OFFSET_LSB_PTR      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOLP(c_COL3);

         when "C3_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(c_COL3);

         when "C3_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(c_COL3);

         when "C3_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(c_COL3);

         when "C3_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(c_COL3);

         when "C3_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(c_COL3);

         when "C3_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(c_COL3);

         when "C3_PULSE_SHAPING              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(c_COL3);

         when "C3_PULSE_SHAPING_SELECTION    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(c_COL3);

         when "C3_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(c_COL3);

         when "C3_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(c_COL3);

         when "C3_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(c_COL3);

         when others                            =>
            o_fld_add_val:= c_RET_UKWN;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_add_pad, c_PAD, o_fld_add);

   end get_cmd_add;

end package body pkg_str_add_assoc;
