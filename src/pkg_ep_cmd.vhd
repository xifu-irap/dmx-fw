-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-ngl-fw is free software: you can redistribute it and/or modify
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
--!   @file                   pkg_ep_cmd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command constants
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

package pkg_ep_cmd is

   -- ------------------------------------------------------------------------------------------------------
   --    EP command
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_RW_R    : std_logic := '0'                                                            ; --! EP command: Address, Read/Write field Read value
constant c_EP_CMD_ADD_RW_W    : std_logic := not(c_EP_CMD_ADD_RW_R)                                         ; --! EP command: Address, Read/Write field Write value

constant c_EP_CMD_WD_ADD_POS  : integer   := 0                                                              ; --! EP command: Address word position
constant c_EP_CMD_WD_DATA_POS : integer   := 1                                                              ; --! EP command: Data word position
constant c_EP_CMD_ADD_RW_POS  : integer   := 0                                                              ; --! EP command: Address, Read/Write field position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Status error
   --    @Req : REG_Status
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ERR_SET     : std_logic := '0'                                                            ; --! EP command: Status, error set value
constant c_EP_CMD_ERR_CLR     : std_logic := not(c_EP_CMD_ERR_SET)                                          ; --! EP command: Status, error clear value

constant c_EP_CMD_ERR_ADD_POS : integer   := 15                                                             ; --! EP command: Status, error position invalid address
constant c_EP_CMD_ERR_LGT_POS : integer   := 14                                                             ; --! EP command: Status, error position SPI command length not complete
constant c_EP_CMD_ERR_WRT_POS : integer   := 13                                                             ; --! EP command: Status, error position try to write in a read only register
constant c_EP_CMD_ERR_OUT_POS : integer   := 12                                                             ; --! EP command: Status, error position SPI data out of range
constant c_EP_CMD_ERR_NIN_POS : integer   := 11                                                             ; --! EP command: Status, error position parameter to read not initialized yet
constant c_EP_CMD_ERR_DIS_POS : integer   := 10                                                             ; --! EP command: Status, error position last SPI command discarded

constant c_EP_CMD_ERR_FST_POS : integer   := 10                                                             ; --! EP command: Status, error first position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: register reading position
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_POS_AQMDE   : integer   := 0                                                              ; --! EP command: Position, DATA_ACQ_MODE
constant c_EP_CMD_POS_SMFMD   : integer   := c_EP_CMD_POS_AQMDE   + 1                                       ; --! EP command: Position, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_POS_SAOFM   : integer   := c_EP_CMD_POS_SMFMD   + 1                                       ; --! EP command: Position, SQ_AMP_OFFSET_MODE
constant c_EP_CMD_POS_TSTPT   : integer   := c_EP_CMD_POS_SAOFM   + 1                                       ; --! EP command: Position, TEST_PATTERN
constant c_EP_CMD_POS_TSTEN   : integer   := c_EP_CMD_POS_TSTPT   + 1                                       ; --! EP command: Position, TEST_PATTERN_ENABLE
constant c_EP_CMD_POS_BXLGT   : integer   := c_EP_CMD_POS_TSTEN   + 1                                       ; --! EP command: Position, BOXCAR_LENGTH
constant c_EP_CMD_POS_HKEEP   : integer   := c_EP_CMD_POS_BXLGT   + 1                                       ; --! EP command: Position, Housekeeping
constant c_EP_CMD_POS_DLFLG   : integer   := c_EP_CMD_POS_HKEEP   + 1                                       ; --! EP command: Position, DELOCK_FLAG
constant c_EP_CMD_POS_STATUS  : integer   := c_EP_CMD_POS_DLFLG   + 1                                       ; --! EP command: Position, Status
constant c_EP_CMD_POS_FW_VER  : integer   := c_EP_CMD_POS_STATUS  + 1                                       ; --! EP command: Position, Firmware Version
constant c_EP_CMD_POS_HW_VER  : integer   := c_EP_CMD_POS_FW_VER  + 1                                       ; --! EP command: Position, Hardware Version
constant c_EP_CMD_POS_PARMA   : integer   := c_EP_CMD_POS_HW_VER  + 1                                       ; --! EP command: Position, CY_A
constant c_EP_CMD_POS_KIKNM   : integer   := c_EP_CMD_POS_PARMA   + 1                                       ; --! EP command: Position, CY_KI_KNORM
constant c_EP_CMD_POS_KNORM   : integer   := c_EP_CMD_POS_KIKNM   + 1                                       ; --! EP command: Position, CY_KNORM
constant c_EP_CMD_POS_SMFB0   : integer   := c_EP_CMD_POS_KNORM   + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB0
constant c_EP_CMD_POS_SMLKV   : integer   := c_EP_CMD_POS_SMFB0   + 1                                       ; --! EP command: Position, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_CMD_POS_SMFBM   : integer   := c_EP_CMD_POS_SMLKV   + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_POS_SAOFF   : integer   := c_EP_CMD_POS_SMFBM   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_POS_SAOFC   : integer   := c_EP_CMD_POS_SAOFF   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_POS_SAOFL   : integer   := c_EP_CMD_POS_SAOFC   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_POS_SMFBD   : integer   := c_EP_CMD_POS_SAOFL   + 1                                       ; --! EP command: Position, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_POS_SAODD   : integer   := c_EP_CMD_POS_SMFBD   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_POS_SAOMD   : integer   := c_EP_CMD_POS_SAODD   + 1                                       ; --! EP command: Position, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_POS_SMPDL   : integer   := c_EP_CMD_POS_SAOMD   + 1                                       ; --! EP command: Position, CY_SAMPLING_DELAY
constant c_EP_CMD_POS_PLSSH   : integer   := c_EP_CMD_POS_SMPDL   + 1                                       ; --! EP command: Position, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_POS_PLSSS   : integer   := c_EP_CMD_POS_PLSSH   + 1                                       ; --! EP command: Position, CY_FB1_PULSE_SHAPING_SELECTION
constant c_EP_CMD_POS_RLDEL   : integer   := c_EP_CMD_POS_PLSSS   + 1                                       ; --! EP command: Position, CY_RELOCK_DELAY
constant c_EP_CMD_POS_RLTHR   : integer   := c_EP_CMD_POS_RLDEL   + 1                                       ; --! EP command: Position, CY_RELOCK_THRESHOLD
constant c_EP_CMD_POS_DLCNT   : integer   := c_EP_CMD_POS_RLTHR   + 1                                       ; --! EP command: Position, CY_DELOCK_COUNTERS

constant c_EP_CMD_POS_LAST    : integer   := c_EP_CMD_POS_DLCNT   + 1                                       ; --! EP command: last position
constant c_EP_CMD_REG_MX_STNB : integer   := 3                                                              ; --! EP command: Register multiplexer stage number
constant c_EP_CMD_REG_MX_STIN : t_int_arr(0 to c_EP_CMD_REG_MX_STNB)   := (32, 40, 42, 43)                  ; --! EP command: Register inputs by multiplexer stage (accumulated)
constant c_EP_CMD_REG_MX_INNB : t_int_arr(0 to c_EP_CMD_REG_MX_STNB-1) := ( 4,  4,  2)                      ; --! EP command: Register inputs by multiplexer

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Address
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_ADD_COLPOSL : integer   := 12                                                             ; --! EP command: Address column position low
constant c_EP_CMD_ADD_COLPOSH : integer   := c_EP_CMD_ADD_COLPOSL + log2_ceil(c_NB_COL) - 1                 ; --! EP command: Address column position high

constant c_EP_CMD_ADD_AQMDE   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4000"                        ; --! EP command: Address, DATA_ACQ_MODE
constant c_EP_CMD_ADD_SMFMD   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4001"                        ; --! EP command: Address, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_ADD_SAOFM   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4002"                        ; --! EP command: Address, SQ_AMP_OFFSET_MODE
constant c_EP_CMD_ADD_TSTPT   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4100"                        ; --! EP command: Address, TEST_PATTERN
constant c_EP_CMD_ADD_TSTEN   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4150"                        ; --! EP command: Address, TEST_PATTERN_ENABLE
constant c_EP_CMD_ADD_BXLGT   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4200"                        ; --! EP command: Address, BOXCAR_LENGTH

constant c_EP_CMD_ADD_HKEEP   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4600"                        ; --! EP command: Address, Housekeeping
constant c_EP_CMD_ADD_DLFLG   : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"4610"                        ; --! EP command: Address, DELOCK_FLAG
constant c_EP_CMD_ADD_STATUS  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6000"                        ; --! EP command: Address, Status
constant c_EP_CMD_ADD_FW_VER  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6001"                        ; --! EP command: Address, Firmware Version
constant c_EP_CMD_ADD_HW_VER  : std_logic_vector(c_EP_SPI_WD_S-1 downto 0):= x"6002"                        ; --! EP command: Address, Hardware Version

constant c_EP_CMD_ADD_PARMA   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0000", x"1000", x"2000", x"3000")                                       ; --! EP command: Address basis, CY_A
constant c_EP_CMD_ADD_KIKNM   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0022", x"1022", x"2022", x"3022")                                       ; --! EP command: Address basis, CY_KI_KNORM
constant c_EP_CMD_ADD_KNORM   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0100", x"1100", x"2100", x"3100")                                       ; --! EP command: Address basis, CY_KNORM
constant c_EP_CMD_ADD_SMFB0   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0200", x"1200", x"2200", x"3200")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB0
constant c_EP_CMD_ADD_SMLKV   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0222", x"1222", x"2222", x"3222")                                       ; --! EP command: Address basis, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_CMD_ADD_SMFBM   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0300", x"1300", x"2300", x"3300")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_ADD_SAOFF   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0400", x"1400", x"2400", x"3400")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_ADD_SAOFC   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0422", x"1422", x"2422", x"3422")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_ADD_SAOFL   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0423", x"1423", x"2423", x"3423")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_ADD_SMFBD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0500", x"1500", x"2500", x"3500")                                       ; --! EP command: Address basis, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_ADD_SAODD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0501", x"1501", x"2501", x"3501")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_ADD_SAOMD   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0502", x"1502", x"2502", x"3502")                                       ; --! EP command: Address basis, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_ADD_SMPDL   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0504", x"1504", x"2504", x"3504")                                       ; --! EP command: Address basis, CY_SAMPLING_DELAY
constant c_EP_CMD_ADD_PLSSH   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0800", x"1800", x"2800", x"3800")                                       ; --! EP command: Address basis, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_ADD_PLSSS   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0880", x"1880", x"2880", x"3880")                                       ; --! EP command: Address basis, CY_FB1_PULSE_SHAPING_SELECTION
constant c_EP_CMD_ADD_RLDEL   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0900", x"1900", x"2900", x"3900")                                       ; --! EP command: Address basis, CY_RELOCK_DELAY
constant c_EP_CMD_ADD_RLTHR   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0901", x"1901", x"2901", x"3901")                                       ; --! EP command: Address basis, CY_RELOCK_THRESHOLD
constant c_EP_CMD_ADD_DLCNT   : t_slv_arr(0 to c_NB_COL-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                 (x"0A00", x"1A00", x"2A00", x"3A00")                                       ; --! EP command: Address basis, CY_DELOCK_COUNTERS

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Table and Memory Address size
   -- ------------------------------------------------------------------------------------------------------
constant c_TAB_TSTPT_NW       : integer   := c_TST_PAT_COEF_NB * c_TST_PAT_RGN_NB                           ; --! Table number word, TEST_PATTERN
constant c_MEM_TSTPT_ADD_S    : integer   := log2_ceil(c_TAB_TSTPT_NW)                                      ; --! Address size memory without ping-pong buffer bit, TEST_PATTERN

constant c_TAB_HKEEP_NW       : integer   := c_HK_NW                                                        ; --! Table number word, Housekeeping
constant c_MEM_HKEEP_ADD_S    : integer   := log2_ceil(c_TAB_HKEEP_NW)                                      ; --! Address size memory, Housekeeping

constant c_TAB_PARMA_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_A
constant c_MEM_PARMA_ADD_S    : integer   := log2_ceil(c_TAB_PARMA_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_A

constant c_TAB_KIKNM_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_KI_KNORM
constant c_MEM_KIKNM_ADD_S    : integer   := log2_ceil(c_TAB_KIKNM_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_KI_KNORM

constant c_TAB_KNORM_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_KNORM
constant c_MEM_KNORM_ADD_S    : integer   := log2_ceil(c_TAB_KNORM_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_KNORM

constant c_TAB_SMFB0_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_MUX_SQ_FB0
constant c_MEM_SMFB0_ADD_S    : integer   := log2_ceil(c_TAB_SMFB0_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_MUX_SQ_FB0

constant c_TAB_SMLKV_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_MUX_SQ_LOCKPOINT_V
constant c_MEM_SMLKV_ADD_S    : integer   := log2_ceil(c_TAB_SMLKV_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_MUX_SQ_LOCKPOINT_V

constant c_TAB_SMFBM_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_MUX_SQ_FB_MODE
constant c_MEM_SMFBM_ADD_S    : integer   := log2_ceil(c_TAB_SMFBM_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_MUX_SQ_FB_MODE

constant c_TAB_SAOFF_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_AMP_SQ_OFFSET_FINE
constant c_MEM_SAOFF_ADD_S    : integer   := log2_ceil(c_TAB_SAOFF_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_AMP_SQ_OFFSET_FINE

constant c_TAB_PLSSH_NW       : integer   := c_PIXEL_DAC_NB_CYC                                             ; --! Table number word, CY_FB1_PULSE_SHAPING
constant c_TAB_PLSSH_S        : integer   := log2_ceil(c_TAB_PLSSH_NW)                                      ; --! Table size bus,    CY_FB1_PULSE_SHAPING
constant c_MEM_PLSSH_ADD_S    : integer   := log2_ceil(c_DAC_PLS_SHP_SET_NB) + c_TAB_PLSSH_S                ; --! Address size memory without ping-pong buffer bit, CY_FB1_PULSE_SHAPING
constant c_MEM_PLSSH_ADD_END  : integer   := (c_DAC_PLS_SHP_SET_NB-1) * 2**c_TAB_PLSSH_S + c_TAB_PLSSH_NW-1 ; --! Address end, CY_FB1_PULSE_SHAPING

constant c_TAB_DLCNT_NW       : integer   := c_MUX_FACT                                                     ; --! Table number word, CY_DELOCK_COUNTERS
constant c_MEM_DLCNT_ADD_S    : integer   := log2_ceil(c_TAB_DLCNT_NW)                                      ; --! Address size memory without ping-pong buffer bit, CY_DELOCK_COUNTERS

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Housekeeping address
   -- ------------------------------------------------------------------------------------------------------
constant c_HK_ADD_P1V8_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 3, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P1V8_ANA
constant c_HK_ADD_P2V5_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 2, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P2V5_ANA
constant c_HK_ADD_M2V5_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 4, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, M2V5_ANA
constant c_HK_ADD_P3V3_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 1, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P3V3_ANA
constant c_HK_ADD_M5V0_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 5, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, M5V0_ANA
constant c_HK_ADD_P1V2_DIG    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 8, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P1V2_DIG
constant c_HK_ADD_P2V5_DIG    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 7, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P2V5_DIG
constant c_HK_ADD_P2V5_AUX    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned(11, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P2V5_AUX
constant c_HK_ADD_P3V3_DIG    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 6, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P3V3_DIG
constant c_HK_ADD_VREF_TMP    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned(12, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, VREF_TMP
constant c_HK_ADD_VREF_R2R    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned(13, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, VREF_R2R
constant c_HK_ADD_P5V0_ANA    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 0, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, P5V0_ANA
constant c_HK_ADD_TEMP_AVE    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned( 9, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, TEMP_AVE
constant c_HK_ADD_TEMP_MAX    : std_logic_vector(c_MEM_HKEEP_ADD_S-1 downto 0):=
                                std_logic_vector(to_unsigned(10, c_MEM_HKEEP_ADD_S))                        ; --! EP command: Housekeeping memory position, TEMP_MAX

constant c_HK_ADD_SEQ         : t_slv_arr(0 to c_HK_NW-1)(c_MEM_HKEEP_ADD_S-1 downto 0) :=
                                (c_HK_ADD_TEMP_AVE, c_HK_ADD_TEMP_MAX, c_HK_ADD_P1V8_ANA, c_HK_ADD_P2V5_ANA,
                                 c_HK_ADD_M2V5_ANA, c_HK_ADD_P3V3_ANA, c_HK_ADD_M5V0_ANA, c_HK_ADD_P1V2_DIG,
                                 c_HK_ADD_P2V5_DIG, c_HK_ADD_P2V5_AUX, c_HK_ADD_P3V3_DIG, c_HK_ADD_VREF_TMP,
                                 c_HK_ADD_VREF_R2R, c_HK_ADD_P5V0_ANA)                                      ; --! Housekeeping memory position sequence

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Write register authorization
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_AUTH_AQMDE  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, DATA_ACQ_MODE
constant c_EP_CMD_AUTH_SMFMD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_AUTH_SAOFM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, SQ_AMP_OFFSET_MODE
constant c_EP_CMD_AUTH_TSTPT  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, TEST_PATTERN
constant c_EP_CMD_AUTH_TSTEN  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, TEST_PATTERN_ENABLE
constant c_EP_CMD_AUTH_BXLGT  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, BOXCAR_LENGTH

constant c_EP_CMD_AUTH_HKEEP  : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Housekeeping
constant c_EP_CMD_AUTH_DLFLG  : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, DELOCK_FLAG
constant c_EP_CMD_AUTH_STATUS : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Status
constant c_EP_CMD_AUTH_FW_VER : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Firmware Version
constant c_EP_CMD_AUTH_HW_VER : std_logic := c_EP_CMD_ERR_SET                                               ; --! EP command: Authorization, Hardware Version

constant c_EP_CMD_AUTH_PARMA  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_A
constant c_EP_CMD_AUTH_KIKNM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_KI_KNORM
constant c_EP_CMD_AUTH_KNORM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_KNORM
constant c_EP_CMD_AUTH_SMFB0  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB0
constant c_EP_CMD_AUTH_SMLKV  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_CMD_AUTH_SMFBM  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB_MODE
constant c_EP_CMD_AUTH_SAOFF  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_FINE
constant c_EP_CMD_AUTH_SAOFC  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_AUTH_SAOFL  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_LSB
constant c_EP_CMD_AUTH_SMFBD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_MUX_SQ_FB_DELAY
constant c_EP_CMD_AUTH_SAODD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_CMD_AUTH_SAOMD  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_CMD_AUTH_SMPDL  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_SAMPLING_DELAY
constant c_EP_CMD_AUTH_PLSSH  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB1_PULSE_SHAPING
constant c_EP_CMD_AUTH_PLSSS  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_FB1_PULSE_SHAPING_SELECTION
constant c_EP_CMD_AUTH_RLDEL  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_RELOCK_DELAY
constant c_EP_CMD_AUTH_RLTHR  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_RELOCK_THRESHOLD
constant c_EP_CMD_AUTH_DLCNT  : std_logic := c_EP_CMD_ERR_CLR                                               ; --! EP command: Authorization, CY_DELOCK_COUNTERS

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data field bus size
   -- ------------------------------------------------------------------------------------------------------
constant c_DFLD_AQMDE_S       : integer   :=  3                                                             ; --! EP command: Data field, DATA_ACQ_MODE bus size
constant c_DFLD_SMFMD_COL_S   : integer   :=  1                                                             ; --! EP command: Data field, SQ_MUX_FB_ON_OFF mode bus size
constant c_DFLD_SAOFM_COL_S   : integer   :=  2                                                             ; --! EP command: Data field, SQ_AMP_OFFSET_MODE bus size
constant c_DFLD_TSTPT_S       : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, TEST_PATTERN bus size
constant c_DFLD_TSTEN_LOP_S   : integer   :=  4                                                             ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Loop number bus size
constant c_DFLD_TSTEN_INF_S   : integer   :=  1                                                             ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Infinity loop bus size
constant c_DFLD_TSTEN_ENA_S   : integer   :=  1                                                             ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Enable bus size
constant c_DFLD_TSTEN_S       : integer   :=  c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_INF_S + c_DFLD_TSTEN_ENA_S  ; --! EP command: Data field, TEST_PATTERN_ENABLE bus size
constant c_DFLD_BXLGT_COL_S   : integer   :=  c_ADC_SMP_AVE_ADD_S                                           ; --! EP command: Data field, BOXCAR_LENGTH bus size
constant c_DFLD_HKEEP_S       : integer   :=  c_HK_SPI_DATA_S                                               ; --! EP command: Data field, Housekeeping bus size
constant c_DFLD_DLFLG_COL_S   : integer   :=  1                                                             ; --! EP command: Data field, DELOCK_FLAG bus size
constant c_DFLD_PARMA_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_A bus size
constant c_DFLD_KIKNM_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_KI_KNORM bus size
constant c_DFLD_KNORM_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_KNORM bus size
constant c_DFLD_SMFB0_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_MUX_SQ_FB0 bus size
constant c_DFLD_SMLKV_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_MUX_SQ_LOCKPOINT_V bus size
constant c_DFLD_SMFBM_PIX_S   : integer   :=  2                                                             ; --! EP command: Data field, CY_MUX_SQ_FB_MODE bus size
constant c_DFLD_SAOFF_PIX_S   : integer   :=  c_SQA_DAC_MUX_S                                               ; --! EP command: Data field, CY_AMP_SQ_OFFSET_FINE bus size
constant c_DFLD_SAOFC_COL_S   : integer   :=  c_SQA_DAC_DATA_S                                              ; --! EP command: Data field, CY_AMP_SQ_OFFSET_COARSE bus size
constant c_DFLD_SAOFL_COL_S   : integer   :=  c_SQA_DAC_DATA_S                                              ; --! EP command: Data field, CY_AMP_SQ_OFFSET_LSB bus size
constant c_DFLD_SMFBD_COL_S   : integer   :=  10                                                            ; --! EP command: Data field, CY_MUX_SQ_FB_DELAY bus size
constant c_DFLD_SAODD_COL_S   : integer   :=  10                                                            ; --! EP command: Data field, CY_AMP_SQ_OFFSET_DAC_DELAY bus size
constant c_DFLD_SAOMD_COL_S   : integer   :=  10                                                            ; --! EP command: Data field, CY_AMP_SQ_OFFSET_MUX_DELAY bus size
constant c_DFLD_SMPDL_COL_S   : integer   :=  5                                                             ; --! EP command: Data field, CY_SAMPLING_DELAY bus size
constant c_DFLD_PLSSH_PLS_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_FB1_PULSE_SHAPING bus size
constant c_DFLD_PLSSS_PLS_S   : integer   :=  log2_ceil(c_DAC_PLS_SHP_SET_NB)                               ; --! EP command: Data field, CY_FB1_PULSE_SHAPING_SELECTION bus size
constant c_DFLD_RLDEL_COL_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_RELOCK_DELAY bus size
constant c_DFLD_RLTHR_COL_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_RELOCK_THRESHOLD bus size
constant c_DFLD_DLCNT_PIX_S   : integer   :=  c_EP_SPI_WD_S                                                 ; --! EP command: Data field, CY_DELOCK_COUNTERS bus size

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data field LSB position
   -- ------------------------------------------------------------------------------------------------------
constant c_DFLD_TSTEN_LOP_POS : integer   :=  0                                                             ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Loop number LSB position
constant c_DFLD_TSTEN_INF_POS : integer   :=  c_DFLD_TSTEN_LOP_S                                            ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Infinity loop LSB position
constant c_DFLD_TSTEN_ENA_POS : integer   :=  c_DFLD_TSTEN_INF_POS + c_DFLD_TSTEN_INF_S                     ; --! EP command: Data field, TEST_PATTERN_ENABLE, field Enable LSB position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Data state
   -- ------------------------------------------------------------------------------------------------------
constant c_DST_AQMDE_IDLE     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "000"                         ; --! EP command: Data state, DATA_ACQ_MODE "Idle"
constant c_DST_AQMDE_SCIE     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "001"                         ; --! EP command: Data state, DATA_ACQ_MODE "Science"
constant c_DST_AQMDE_ERRS     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "010"                         ; --! EP command: Data state, DATA_ACQ_MODE "Error Signal"
constant c_DST_AQMDE_DUMP     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "100"                         ; --! EP command: Data state, DATA_ACQ_MODE "Dump"
constant c_DST_AQMDE_TEST     : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0):= "111"                         ; --! EP command: Data state, DATA_ACQ_MODE "Test Pattern"

constant c_DST_SMFMD_OFF      : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0):= "0"                       ; --! EP command: Data state, SQ_MUX_FB_ON_OFF "Off"
constant c_DST_SMFMD_ON       : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0):= "1"                       ; --! EP command: Data state, SQ_MUX_FB_ON_OFF "On"

constant c_DST_SAOFM_OFF      : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "00"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Off"
constant c_DST_SAOFM_OFFSET   : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "01"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Offset"
constant c_DST_SAOFM_CLOSE    : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "10"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Closed Loop"
constant c_DST_SAOFM_TEST     : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0):= "11"                      ; --! EP command: Data state, SQ_AMP_OFFSET_MODE "Test Pattern"

constant c_DST_SMFBM_OPEN     : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "00"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Open Loop"
constant c_DST_SMFBM_CLOSE    : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "01"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Closed Loop"
constant c_DST_SMFBM_TEST     : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0):= "10"                      ; --! EP command: Data state, CY_MUX_SQ_FB_MODE "Test Pattern"

constant c_DST_PLSSS_PLS_0    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "00"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 0
constant c_DST_PLSSS_PLS_1    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "01"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 1
constant c_DST_PLSSS_PLS_2    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "10"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 2
constant c_DST_PLSSS_PLS_3    : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= "11"                      ; --! EP command: Data state, CY_FB1_PULSE_SHAPING_SELECTION set 3

constant c_DST_SQADAC_NORM    : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "00"                        ; --! EP command: Data state, SQUID AMP DACs mode "Normal"
constant c_DST_SQADAC_PD1K    : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "01"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down 1k to GND"
constant c_DST_SQADAC_PD100K  : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "10"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down 100k to GND"
constant c_DST_SQADAC_PDZ     : std_logic_vector(c_SQA_DAC_MODE_S-1 downto 0):= "11"                        ; --! EP command: Data state, SQUID AMP DACs mode "Power down High Z"

   -- ------------------------------------------------------------------------------------------------------
   --!   Calculus chain parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_A_P_FRC_S          : integer := c_DFLD_PARMA_PIX_S                                               ; --! a(p) fractional part bus size
constant c_ELP_P_FRC_S        : integer := c_DFLD_SMLKV_PIX_S - c_SQM_ADC_DATA_S + 1                        ; --! Elp(p) fractional part bus size
constant c_KI_KNORM_P_FRC_S   : integer := c_DFLD_KIKNM_PIX_S                                               ; --! ki(p)*knorm(p) fractional part bus size
constant c_KNORM_P_FRC_S      : integer := 18                                                               ; --! knorm(p) fractional part bus size

constant c_ADC_SMP_AVE_TOT_S  : integer := c_SQM_ADC_DATA_S + c_ASP_CF_S - 1                                ; --! ADC sample average: DSP Result total size
constant c_ADC_SMP_AVE_SAT    : integer := c_ADC_SMP_AVE_TOT_S - 1                                          ; --! ADC sample average: saturation (unsigned)
constant c_ADC_SMP_AVE_S      : integer := c_MULT_ALU_PORTA_S - 1                                           ; --! ADC sample average: bus size
constant c_ADC_SMP_AVE_C_S    : integer := c_ADC_SMP_AVE_S + 1                                              ; --! ADC sample average: with carry bus size
constant c_ADC_SMP_AVE_FRC_S  : integer := c_ADC_SMP_AVE_S - c_SQM_ADC_DATA_S                               ; --! ADC sample average: fractional part bus size
constant c_ADC_SMP_AVE_LSB    : integer := c_ADC_SMP_AVE_SAT + 1 - c_ADC_SMP_AVE_C_S                        ; --! ADC sample average: DSP Result LSB position

constant c_DFB_PN_PRM_CTRL    : integer := 4                                                                ; --! dFB(p,n) Adder and accumulator input, control parameter

constant c_DFB_PN_INIT_VAL    : integer := 0                                                                ; --! dFB(p,n): initialization value
constant c_DFB_PN_S           : integer := c_MULT_ALU_PORTA_S                                               ; --! dFB(p,n): bus size
constant c_DFB_PN_DACC_S      : integer := c_DFB_PN_S - c_DFB_PN_PRM_CTRL                                   ; --! dFB(p,n): data to accumulate bus size
constant c_DFB_PN_DACC_FRC_S  : integer := c_DFB_PN_DACC_S - c_SQM_ADC_DATA_S - 1                           ; --! dFB(p,n): data to accumulate fractional part bus size
constant c_DFB_PN_FRC_S       : integer := c_DFB_PN_DACC_FRC_S                                              ; --! dFB(p,n): fractional part bus size

constant c_PC1_PN_TOT_S       : integer := c_DFLD_PARMA_PIX_S + c_DFB_PN_S                                  ; --! PC1(p,n): DSP Result total bus size
constant c_PC1_PN_TOT_FRC_S   : integer := c_A_P_FRC_S + c_DFB_PN_FRC_S                                     ; --! PC1(p,n): DSP Result total fractional part bus size
constant c_PC1_PN_TOT_INT_S   : integer := minimum(c_SQM_ADC_DATA_S, c_PC1_PN_TOT_S - c_PC1_PN_TOT_FRC_S)   ; --! PC1(p,n): DSP Result total integer part bus size
constant c_PC1_PN_SAT         : integer := c_PC1_PN_TOT_INT_S + c_PC1_PN_TOT_FRC_S - 1                      ; --! PC1(p,n): saturation
constant c_PC1_PN_S           : integer := 2 * c_RFB_DATA_S                                                 ; --! PC1(p,n): bus size
constant c_PC1_PN_C_S         : integer := c_PC1_PN_S + 1                                                   ; --! PC1(p,n): with carry bus size
constant c_PC1_PN_FRC_S       : integer := c_PC1_PN_S - c_PC1_PN_TOT_INT_S                                  ; --! PC1(p,n): fractional part bus size
constant c_PC1_PN_LSB         : integer := c_PC1_PN_SAT + 1 - c_PC1_PN_C_S                                  ; --! PC1(p,n): DSP Result LSB position

constant c_M_PN_TOT_S         : integer := c_DFLD_KIKNM_PIX_S + c_ADC_SMP_AVE_S + 1                         ; --! M(p,n): DSP Result total bus size
constant c_M_PN_TOT_FRC_S     : integer := c_KI_KNORM_P_FRC_S + c_ADC_SMP_AVE_FRC_S                         ; --! M(p,n): DSP Result total fractional part bus size
constant c_M_PN_SAT           : integer := c_M_PN_TOT_S - 1                                                 ; --! M(p,n): saturation
constant c_M_PN_S             : integer := c_PC1_PN_TOT_FRC_S + c_SQM_ADC_DATA_S + 1                        ; --! M(p,n): bus size
constant c_M_PN_C_S           : integer := c_M_PN_S + 1                                                     ; --! M(p,n): with carry bus size
constant c_M_PN_FRC_S         : integer := c_PC1_PN_TOT_FRC_S                                               ; --! M(p,n): fractional part bus size
constant c_M_PN_LSB           : integer := c_M_PN_SAT + 1 - c_M_PN_C_S                                      ; --! M(p,n): DSP Result LSB position

constant c_FB_PN_INIT_VAL     : integer := 0                                                                ; --! FB(p,n): initialization value
constant c_FB_PN_S            : integer := c_PC1_PN_S                                                       ; --! FB(p,n): bus size
constant c_FB_PN_FRC_S        : integer := c_FB_PN_S - c_SQM_ADC_DATA_S                                     ; --! FB(p,n): fractional part bus size

constant c_NRM_PN_TOT_S       : integer := c_DFLD_KNORM_PIX_S + c_ADC_SMP_AVE_S + 1                         ; --! NRM(p,n): DSP Result total bus size
constant c_NRM_PN_TOT_FRC_S   : integer := c_KNORM_P_FRC_S    + c_ADC_SMP_AVE_FRC_S                         ; --! NRM(p,n): DSP Result total fractional part bus size
constant c_NRM_PN_TOT_INT_S   : integer := minimum(c_SQM_ADC_DATA_S, c_NRM_PN_TOT_S - c_NRM_PN_TOT_FRC_S)   ; --! NRM(p,n): DSP Result total integer part bus size
constant c_NRM_PN_SAT         : integer := c_NRM_PN_TOT_INT_S + c_NRM_PN_TOT_FRC_S - 1                      ; --! NRM(p,n): saturation
constant c_NRM_PN_S           : integer := c_FB_PN_S                                                        ; --! NRM(p,n): bus size
constant c_NRM_PN_C_S         : integer := c_NRM_PN_S + 1                                                   ; --! NRM(p,n): with carry bus size
constant c_NRM_PN_FRC_S       : integer := c_FB_PN_FRC_S                                                    ; --! NRM(p,n): fractional part bus size
constant c_NRM_PN_LSB         : integer := c_SQM_ADC_DATA_S + c_NRM_PN_TOT_FRC_S - c_NRM_PN_C_S             ; --! NRM(p,n): DSP Result LSB position

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Default value
   -- ------------------------------------------------------------------------------------------------------
constant c_EP_CMD_DEF_AQMDE   : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)      := c_DST_AQMDE_IDLE        ; --! EP command: Default value, DATA_ACQ_MODE

constant c_EP_CMD_DEF_SMFMD   : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)  := c_DST_SMFMD_OFF         ; --! EP command: Default value, SQ_MUX_FB_ON_OFF
constant c_EP_CMD_DEF_SAOFM   : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)  := c_DST_SAOFM_OFF         ; --! EP command: Default value, SQ_AMP_OFFSET_MODE
constant c_EP_CMD_DEF_TSTPT   : t_int_arr(0 to 2*c_TAB_TSTPT_NW-1)               := (others => 0)           ; --! EP command: Default value, TEST_PATTERN
constant c_EP_CMD_DEF_TSTEN   : std_logic_vector(c_DFLD_TSTEN_S-1 downto 0)      :=
                                std_logic_vector(to_unsigned(0, c_DFLD_TSTEN_S))                            ; --! EP command: Default value, TEST_PATTERN_ENABLE
constant c_EP_CMD_DEF_BXLGT   : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)  :=
                                std_logic_vector(to_unsigned(0, c_DFLD_BXLGT_COL_S))                        ; --! EP command: Default value, BOXCAR_LENGTH
constant c_EP_CMD_DEF_DLFLG   : std_logic_vector(c_DFLD_DLFLG_COL_S-1 downto 0)  :=
                                std_logic_vector(to_unsigned(0, c_DFLD_DLFLG_COL_S))                        ; --! EP command: Default value, DELOCK_FLAG

constant c_DEF_PARMA_RL       : real := 0.2                                                                 ; --! Default value in real, CY_A
constant c_DEF_KI_RL          : real := 2.2                                                                 ; --! Default value in real, KI parameter
constant c_DEF_KNORM_RL       : real := 0.1076438                                                           ; --! Default value in real, CY_KNORM
constant c_DEF_KIKNM_RL       : real := c_DEF_KI_RL * c_DEF_KNORM_RL                                        ; --! Default value in real, CY_KI_KNORM

constant c_EP_CMD_DEF_PARMA   : t_int_arr(0 to 2*c_TAB_PARMA_NW-1) :=
                                (others => integer(round(c_DEF_PARMA_RL * real(2**c_A_P_FRC_S))))           ; --! EP command: Default value, CY_A memory with ping-pong buffer bit

constant c_EP_CMD_DEF_KIKNM   : t_int_arr(0 to 2*c_TAB_KIKNM_NW-1) :=
                                (others => integer(round(c_DEF_KIKNM_RL * real(2**c_KI_KNORM_P_FRC_S))))    ; --! EP command: Default value, CY_KI_KNORM memory with ping-pong buffer bit

constant c_EP_CMD_DEF_KNORM   : t_int_arr(0 to 2*c_TAB_KNORM_NW-1) :=
                                (others => integer(round(c_DEF_KNORM_RL * real(2**c_KNORM_P_FRC_S))))       ; --! EP command: Default value, CY_KNORM memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SMFB0   : t_int_arr(0 to 2*c_TAB_SMFB0_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_MUX_SQ_FB0 memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SMLKV   : t_int_arr(0 to 2*c_TAB_SMLKV_NW-1) :=
                                (others => to_integer(unsigned(c_I_SQM_ADC_DATA_DEF) * 2**c_ELP_P_FRC_S))   ; --! EP command: Default value, CY_MUX_SQ_LOCKPOINT_V memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SMFBM   : t_int_arr(0 to 2*c_TAB_SMFBM_NW-1) :=
                                (others => to_integer(unsigned(c_DST_SMFBM_OPEN)))                          ; --! EP command: Default value, CY_MUX_SQ_FB_MODE memory with ping-pong buffer bit

constant c_EP_CMD_DEF_SAOFF   : t_int_arr(0 to 2*c_TAB_SAOFF_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_AMP_SQ_OFFSET_FINE memory with ping-pong buffer bit
constant c_EP_CMD_DEF_SAOFC   : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0 ,c_DFLD_SAOFC_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_CMD_DEF_SAOFL   : std_logic_vector(c_DFLD_SAOFL_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAOFL_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_LSB

constant c_EP_CMD_DEF_SMFBD   : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SMFBD_COL_S))                        ; --! EP command: Default value, CY_MUX_SQ_FB_DELAY

constant c_EP_CMD_DEF_SAODD   : std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAODD_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_DAC_DELAY

constant c_EP_CMD_DEF_SAOMD   : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SAOMD_COL_S))                        ; --! EP command: Default value, CY_AMP_SQ_OFFSET_MUX_DELAY

constant c_EP_CMD_DEF_SMPDL   : std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0):=
                                std_logic_vector(to_unsigned(0, c_DFLD_SMPDL_COL_S))                        ; --! EP command: Default value, CY_SAMPLING_DELAY

constant c_EP_CMD_DEF_PLSSH   : t_int_arr(0 to 2**(c_MEM_PLSSH_ADD_S+1)-1) :=
                                (    0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 32681, 16297,  8127,  4053,  2021,  1008,   503,   251,
                                   125,    62,    31,    15,     8,     4,     2,     1,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 29041, 12869,  5703,  2527,  1120,   496,   220,    97,
                                    43,    19,     8,     4,     2,     1,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 26131, 10419,  4154,  1657,   661,   263,   105,    42,
                                    17,     7,     3,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 32681, 16297,  8127,  4053,  2021,  1008,   503,   251,
                                   125,    62,    31,    15,     8,     4,     2,     1,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 29041, 12869,  5703,  2527,  1120,   496,   220,    97,
                                    43,    19,     8,     4,     2,     1,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,

                                 26131, 10419,  4154,  1657,   661,   263,   105,    42,
                                    17,     7,     3,     1,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0,
                                     0,     0,     0,     0,     0,     0,     0,     0)                    ; --! EP command: Default value, CY_FB1_PULSE_SHAPING mem. (fc=No filter/20/25/30 MHz)

constant c_EP_CMD_DEF_PLSSS   : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0):= c_DST_PLSSS_PLS_1         ; --! EP command: Default value, CY_FB1_PULSE_SHAPING_SELECTION
constant c_EP_CMD_DEF_RLDEL   : std_logic_vector(c_DFLD_RLDEL_COL_S-1 downto 0):= (others => '1')           ; --! EP command: Default value, CY_RELOCK_DELAY
constant c_EP_CMD_DEF_RLTHR   : std_logic_vector(c_DFLD_RLTHR_COL_S-1 downto 0):= (others => '1')           ; --! EP command: Default value, CY_RELOCK_THRESHOLD
constant c_EP_CMD_DEF_DLCNT   : t_int_arr(0 to 2*c_TAB_DLCNT_NW-1) := (others => 0)                         ; --! EP command: Default value, CY_DELOCK_COUNTERS


end pkg_ep_cmd;
