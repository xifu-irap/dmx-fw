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
--!   @file                   pkg_ep_cmd_type.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Specific types and functions linked to EP command
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

package pkg_ep_cmd_type is

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Register by column management
   -- ------------------------------------------------------------------------------------------------------
type     t_rgc                 is record
         smign                : std_logic_vector(c_DFLD_SMIGN_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_MUX_SQ_INPUT_GAIN
         saign                : std_logic_vector(c_DFLD_SAIGN_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_INPUT_GAIN
         sakkm                : std_logic_vector(c_DFLD_SAKKM_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_KI_KNORM
         sakrm                : std_logic_vector(c_DFLD_SAKRM_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_KNORM
         salkv                : std_logic_vector(c_DFLD_SALKV_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_LOCKPOINT_V
         saolp                : std_logic_vector(c_DFLD_SAOLP_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_LSB_PTR
         saofc                : std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_COARSE
         saofl                : std_logic_vector(c_DFLD_SAOFL_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_LSB
         smfbd                : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_MUX_SQ_FB_DELAY
         saodd                : std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_DAC_DELAY
         saomd                : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_MUX_DELAY
         smpdl                : std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_SAMPLING_DELAY
         plsss                : std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                             ; --! EP command: Register linked to CY_PULSE_SHAPING_SELECTION
         rldel                : std_logic_vector(c_DFLD_RLDEL_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_RELOCK_DELAY
         rlthr                : std_logic_vector(c_DFLD_RLTHR_COL_S-1 downto 0)                             ; --! EP command: Register linked to CY_RELOCK_THRESHOLD
end record t_rgc                                                                                            ; --! EP command: Register by column

type     t_rgc_arr             is array (natural range <>) of t_rgc                                         ; --! EP command: Register by column array

   --! EP command: Register by column number
constant c_EP_RGC_NUM_SMIGN   : integer   := 0                                                              ; --! EP command: Register by column number, CY_MUX_SQ_INPUT_GAIN
constant c_EP_RGC_NUM_SAIGN   : integer   := c_EP_RGC_NUM_SMIGN + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_INPUT_GAIN
constant c_EP_RGC_NUM_SAKKM   : integer   := c_EP_RGC_NUM_SAIGN + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_KI_KNORM
constant c_EP_RGC_NUM_SAKRM   : integer   := c_EP_RGC_NUM_SAKKM + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_KNORM
constant c_EP_RGC_NUM_SALKV   : integer   := c_EP_RGC_NUM_SAKRM + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_LOCKPOINT_V
constant c_EP_RGC_NUM_SAOLP   : integer   := c_EP_RGC_NUM_SALKV + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_OFFSET_LSB_PTR
constant c_EP_RGC_NUM_SAOFC   : integer   := c_EP_RGC_NUM_SAOLP + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_RGC_NUM_SAOFL   : integer   := c_EP_RGC_NUM_SAOFC + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_OFFSET_LSB
constant c_EP_RGC_NUM_SMFBD   : integer   := c_EP_RGC_NUM_SAOFL + 1                                         ; --! EP command: Register by column number, CY_MUX_SQ_FB_DELAY
constant c_EP_RGC_NUM_SAODD   : integer   := c_EP_RGC_NUM_SMFBD + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_RGC_NUM_SAOMD   : integer   := c_EP_RGC_NUM_SAODD + 1                                         ; --! EP command: Register by column number, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_RGC_NUM_SMPDL   : integer   := c_EP_RGC_NUM_SAOMD + 1                                         ; --! EP command: Register by column number, CY_SAMPLING_DELAY
constant c_EP_RGC_NUM_PLSSS   : integer   := c_EP_RGC_NUM_SMPDL + 1                                         ; --! EP command: Register by column number, CY_PULSE_SHAPING_SELECTION
constant c_EP_RGC_NUM_RLDEL   : integer   := c_EP_RGC_NUM_PLSSS + 1                                         ; --! EP command: Register by column number, CY_RELOCK_DELAY
constant c_EP_RGC_NUM_RLTHR   : integer   := c_EP_RGC_NUM_RLDEL + 1                                         ; --! EP command: Register by column number, CY_RELOCK_THRESHOLD

constant c_EP_RGC_NUM_LAST    : integer   := c_EP_RGC_NUM_RLTHR + 1                                         ; --! EP command: Register by column number, last position

   --! EP command: Register by column accumulated bus size
constant c_EP_RGC_ACC_SMIGN   : integer   := c_DFLD_SMIGN_COL_S                                             ; --! EP command: Register by column accumulated bus size, CY_MUX_SQ_INPUT_GAIN
constant c_EP_RGC_ACC_SAIGN   : integer   := c_DFLD_SAIGN_COL_S + c_EP_RGC_ACC_SMIGN                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_INPUT_GAIN
constant c_EP_RGC_ACC_SAKKM   : integer   := c_DFLD_SAKKM_COL_S + c_EP_RGC_ACC_SAIGN                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_KI_KNORM
constant c_EP_RGC_ACC_SAKRM   : integer   := c_DFLD_SAKRM_COL_S + c_EP_RGC_ACC_SAKKM                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_KNORM
constant c_EP_RGC_ACC_SALKV   : integer   := c_DFLD_SALKV_COL_S + c_EP_RGC_ACC_SAKRM                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_LOCKPOINT_V
constant c_EP_RGC_ACC_SAOLP   : integer   := c_DFLD_SAOLP_COL_S + c_EP_RGC_ACC_SALKV                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_OFFSET_LSB_PTR
constant c_EP_RGC_ACC_SAOFC   : integer   := c_DFLD_SAOFC_COL_S + c_EP_RGC_ACC_SAOLP                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_OFFSET_COARSE
constant c_EP_RGC_ACC_SAOFL   : integer   := c_DFLD_SAOFL_COL_S + c_EP_RGC_ACC_SAOFC                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_OFFSET_LSB
constant c_EP_RGC_ACC_SMFBD   : integer   := c_DFLD_SMFBD_COL_S + c_EP_RGC_ACC_SAOFL                        ; --! EP command: Register by column accumulated bus size, CY_MUX_SQ_FB_DELAY
constant c_EP_RGC_ACC_SAODD   : integer   := c_DFLD_SAODD_COL_S + c_EP_RGC_ACC_SMFBD                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_OFFSET_DAC_DELAY
constant c_EP_RGC_ACC_SAOMD   : integer   := c_DFLD_SAOMD_COL_S + c_EP_RGC_ACC_SAODD                        ; --! EP command: Register by column accumulated bus size, CY_AMP_SQ_OFFSET_MUX_DELAY
constant c_EP_RGC_ACC_SMPDL   : integer   := c_DFLD_SMPDL_COL_S + c_EP_RGC_ACC_SAOMD                        ; --! EP command: Register by column accumulated bus size, CY_SAMPLING_DELAY
constant c_EP_RGC_ACC_PLSSS   : integer   := c_DFLD_PLSSS_PLS_S + c_EP_RGC_ACC_SMPDL                        ; --! EP command: Register by column accumulated bus size, CY_PULSE_SHAPING_SELECTION
constant c_EP_RGC_ACC_RLDEL   : integer   := c_DFLD_RLDEL_COL_S + c_EP_RGC_ACC_PLSSS                        ; --! EP command: Register by column accumulated bus size, CY_RELOCK_DELAY
constant c_EP_RGC_ACC_RLTHR   : integer   := c_DFLD_RLTHR_COL_S + c_EP_RGC_ACC_RLDEL                        ; --! EP command: Register by column accumulated bus size, CY_RELOCK_THRESHOLD

constant c_EP_RGC_ACC         : integer_vector(0 to c_EP_RGC_NUM_LAST) := (0,
                                 c_EP_RGC_ACC_SMIGN, c_EP_RGC_ACC_SAIGN, c_EP_RGC_ACC_SAKKM,
                                 c_EP_RGC_ACC_SAKRM, c_EP_RGC_ACC_SALKV, c_EP_RGC_ACC_SAOLP,
                                 c_EP_RGC_ACC_SAOFC, c_EP_RGC_ACC_SAOFL, c_EP_RGC_ACC_SMFBD,
                                 c_EP_RGC_ACC_SAODD, c_EP_RGC_ACC_SAOMD, c_EP_RGC_ACC_SMPDL,
                                 c_EP_RGC_ACC_PLSSS, c_EP_RGC_ACC_RLDEL, c_EP_RGC_ACC_RLTHR)                ; --! EP command: Register by column accumulated bus size

constant c_EP_RGC_REC_DEF     : t_rgc := (
         smign                => c_EP_CMD_DEF_SMIGN   , --        slv(c_DFLD_SMIGN_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_MUX_SQ_INPUT_GAIN
         saign                => c_EP_CMD_DEF_SAIGN   , --        slv(c_DFLD_SAIGN_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_INPUT_GAIN
         sakkm                => c_EP_CMD_DEF_SAKKM   , --        slv(c_DFLD_SAKKM_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_KI_KNORM
         sakrm                => c_EP_CMD_DEF_SAKRM   , --        slv(c_DFLD_SAKRM_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_KNORM
         salkv                => c_EP_CMD_DEF_SALKV   , --        slv(c_DFLD_SALKV_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_LOCKPOINT_V
         saolp                => c_EP_CMD_DEF_SAOLP   , --        slv(c_DFLD_SAOLP_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_LSB_PTR
         saofc                => c_EP_CMD_DEF_SAOFC   , --        slv(c_DFLD_SAOFC_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_COARSE
         saofl                => c_EP_CMD_DEF_SAOFL   , --        slv(c_DFLD_SAOFL_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_LSB
         smfbd                => c_EP_CMD_DEF_SMFBD   , --        slv(c_DFLD_SMFBD_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_MUX_SQ_FB_DELAY
         saodd                => c_EP_CMD_DEF_SAODD   , --        slv(c_DFLD_SAODD_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_DAC_DELAY
         saomd                => c_EP_CMD_DEF_SAOMD   , --        slv(c_DFLD_SAOMD_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_AMP_SQ_OFFSET_MUX_DELAY
         smpdl                => c_EP_CMD_DEF_SMPDL   , --        slv(c_DFLD_SMPDL_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_SAMPLING_DELAY
         plsss                => c_EP_CMD_DEF_PLSSS   , --        slv(c_DFLD_PLSSS_PLS_S-1 downto 0)        ; --! EP command: Register linked to CY_PULSE_SHAPING_SELECTION
         rldel                => c_EP_CMD_DEF_RLDEL   , --        slv(c_DFLD_RLDEL_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_RELOCK_DELAY
         rlthr                => c_EP_CMD_DEF_RLTHR     --        slv(c_DFLD_RLTHR_COL_S-1 downto 0)        ; --! EP command: Register linked to CY_RELOCK_THRESHOLD
      );                                                                                                      --! EP command: Register by column record default value

constant c_EP_RGC_DEF         : integer_vector(0 to c_EP_RGC_NUM_LAST-1) :=
                                (c_EP_CMD_DEF_SMIGN_I, c_EP_CMD_DEF_SAIGN_I, c_EP_CMD_DEF_SAKKM_I,
                                 c_EP_CMD_DEF_SAKRM_I, c_EP_CMD_DEF_SALKV_I, c_EP_CMD_DEF_SAOLP_I,
                                 c_EP_CMD_DEF_SAOFC_I, c_EP_CMD_DEF_SAOFL_I, c_EP_CMD_DEF_SMFBD_I,
                                 c_EP_CMD_DEF_SAODD_I, c_EP_CMD_DEF_SAOMD_I, c_EP_CMD_DEF_SMPDL_I,
                                 c_EP_CMD_DEF_PLSSS_I, c_EP_CMD_DEF_RLDEL_I, c_EP_CMD_DEF_RLTHR_I)          ; --! EP command: Register by column default value

constant c_EP_RGC_POS         : integer_vector(0 to c_EP_RGC_NUM_LAST-1) :=
                                (c_EP_CMD_POS_SMIGN, c_EP_CMD_POS_SAIGN, c_EP_CMD_POS_SAKKM,
                                 c_EP_CMD_POS_SAKRM, c_EP_CMD_POS_SALKV, c_EP_CMD_POS_SAOLP,
                                 c_EP_CMD_POS_SAOFC, c_EP_CMD_POS_SAOFL, c_EP_CMD_POS_SMFBD,
                                 c_EP_CMD_POS_SAODD, c_EP_CMD_POS_SAOMD, c_EP_CMD_POS_SMPDL,
                                 c_EP_CMD_POS_PLSSS, c_EP_CMD_POS_RLDEL, c_EP_CMD_POS_RLTHR)                ; --! EP command: Register by column position

constant c_EP_RGC_ADD         : t_slv_arr_tab(0 to c_EP_RGC_NUM_LAST-1)(0 to c_NB_COL-1)
                                (c_EP_SPI_WD_S-1 downto 0) :=
                                (c_EP_CMD_ADD_SMIGN, c_EP_CMD_ADD_SAIGN, c_EP_CMD_ADD_SAKKM,
                                 c_EP_CMD_ADD_SAKRM, c_EP_CMD_ADD_SALKV, c_EP_CMD_ADD_SAOLP,
                                 c_EP_CMD_ADD_SAOFC, c_EP_CMD_ADD_SAOFL, c_EP_CMD_ADD_SMFBD,
                                 c_EP_CMD_ADD_SAODD, c_EP_CMD_ADD_SAOMD, c_EP_CMD_ADD_SMPDL,
                                 c_EP_CMD_ADD_PLSSS, c_EP_CMD_ADD_RLDEL, c_EP_CMD_ADD_RLTHR)                ; --! EP command: Register by column address

   -- ------------------------------------------------------------------------------------------------------
   --    EP command: Memory management
   -- ------------------------------------------------------------------------------------------------------
type     t_mem_prc             is record
         parma                : t_mem(
                                add(              c_MEM_PARMA_ADD_S-1 downto 0),
                                data_w(          c_DFLD_PARMA_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_A
         kiknm                : t_mem(
                                add(              c_MEM_KIKNM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KIKNM_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_MUX_SQ_KI_KNORM
         knorm                : t_mem(
                                add(              c_MEM_KNORM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KNORM_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_MUX_SQ_KNORM
         smfb0                : t_mem(
                                add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_MUX_SQ_FB0
         smlkv                : t_mem(
                                add(              c_MEM_SMLKV_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMLKV_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_MUX_SQ_LOCKPOINT_V
end record t_mem_prc                                                                                        ; --! EP command: Memory interface for data squid proc.

type     t_mem_prc_dta         is record
         parma                : std_logic_vector(c_DFLD_PARMA_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_A
         kiknm                : std_logic_vector(c_DFLD_KIKNM_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_MUX_SQ_KI_KNORM
         knorm                : std_logic_vector(c_DFLD_KNORM_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_MUX_SQ_KNORM
         smfb0                : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_MUX_SQ_FB0
         smlkv                : std_logic_vector(c_DFLD_SMLKV_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_MUX_SQ_LOCKPOINT_V
end record t_mem_prc_dta                                                                                    ; --! EP command: Memory data read for data squid proc.

type     t_ep_mem             is record
         tstpt                : t_mem(
                                add(              c_MEM_TSTPT_ADD_S-1 downto 0),
                                data_w(              c_DFLD_TSTPT_S-1 downto 0))                            ; --! EP command: Memory interface linked to TEST_PATTERN
         smfbm                : t_mem(
                                add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_MUX_SQ_FB_MODE
         saoff                : t_mem(
                                add(              c_MEM_SAOFF_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SAOFF_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_AMP_SQ_OFFSET_FINE
         plssh                : t_mem(
                                add(              c_MEM_PLSSH_ADD_S-1 downto 0),
                                data_w(          c_DFLD_PLSSH_PLS_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_PULSE_SHAPING
         dlcnt                : t_mem(
                                add(              c_MEM_DLCNT_ADD_S-1 downto 0),
                                data_w(          c_DFLD_DLCNT_PIX_S-1 downto 0))                            ; --! EP command: Memory interface linked to CY_DELOCK_COUNTERS
end record t_ep_mem                                                                                         ; --! EP command: Memory interface

type     t_ep_mem_dta         is record
         tstpt                : std_logic_vector(c_DFLD_TSTPT_S-1     downto 0)                             ; --! EP command: Memory data read linked to TEST_PATTERN
         smfbm                : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_MUX_SQ_FB_MODE
         saoff                : std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_AMP_SQ_OFFSET_FINE
         plssh                : std_logic_vector(c_DFLD_PLSSH_PLS_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_PULSE_SHAPING
         dlcnt                : std_logic_vector(c_DFLD_DLCNT_PIX_S-1 downto 0)                             ; --! EP command: Memory data read linked to CY_DELOCK_COUNTERS
end record t_ep_mem_dta                                                                                     ; --! EP command: Memory data read

type     t_mem_prc_arr         is array (natural range <>) of t_mem_prc                                     ; --! EP command: Memory interface for data squid proc. array
type     t_mem_prc_dta_arr     is array (natural range <>) of t_mem_prc_dta                                 ; --! EP command: Memory data read for data squid proc. array

type     t_ep_mem_arr          is array (natural range <>) of t_ep_mem                                      ; --! EP command: Memory interface array
type     t_ep_mem_dta_arr      is array (natural range <>) of t_ep_mem_dta                                  ; --! EP command: Memory data read array

   --! EP command: Memory number
constant c_EP_MEM_NUM_TSTPT   : integer   := 0                                                              ; --! EP command: Memory number, TEST_PATTERN
constant c_EP_MEM_NUM_PARMA   : integer   := c_EP_MEM_NUM_TSTPT + 1                                         ; --! EP command: Memory for data squid proc. number, CY_A
constant c_EP_MEM_NUM_KIKNM   : integer   := c_EP_MEM_NUM_PARMA + 1                                         ; --! EP command: Memory for data squid proc. number, CY_MUX_SQ_KI_KNORM
constant c_EP_MEM_NUM_KNORM   : integer   := c_EP_MEM_NUM_KIKNM + 1                                         ; --! EP command: Memory for data squid proc. number, CY_MUX_SQ_KNORM
constant c_EP_MEM_NUM_SMFB0   : integer   := c_EP_MEM_NUM_KNORM + 1                                         ; --! EP command: Memory number, CY_MUX_SQ_FB0
constant c_EP_MEM_NUM_SMLKV   : integer   := c_EP_MEM_NUM_SMFB0 + 1                                         ; --! EP command: Memory for data squid proc. number, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_MEM_NUM_SMFBM   : integer   := c_EP_MEM_NUM_SMLKV + 1                                         ; --! EP command: Memory number, CY_MUX_SQ_FB_MODE
constant c_EP_MEM_NUM_SAOFF   : integer   := c_EP_MEM_NUM_SMFBM + 1                                         ; --! EP command: Memory number, CY_AMP_SQ_OFFSET_FINE
constant c_EP_MEM_NUM_PLSSH   : integer   := c_EP_MEM_NUM_SAOFF + 1                                         ; --! EP command: Memory number, CY_PULSE_SHAPING
constant c_EP_MEM_NUM_DLCNT   : integer   := c_EP_MEM_NUM_PLSSH + 1                                         ; --! EP command: Memory number, CY_DELOCK_COUNTERS

constant c_EP_MEM_NUM_LAST    : integer   := c_EP_MEM_NUM_DLCNT + 1                                         ; --! EP command: Memory number, last position

   --! EP command: Memory data accumulated bus size
constant c_EP_MEM_ACC_TSTPT   : integer   := c_DFLD_TSTPT_S                                                 ; --! EP command: Memory accumulated bus size, TEST_PATTERN
constant c_EP_MEM_ACC_PARMA   : integer   := c_DFLD_PARMA_PIX_S + c_EP_MEM_ACC_TSTPT                        ; --! EP command: Memory for data squid proc. accumulated bus size, CY_A
constant c_EP_MEM_ACC_KIKNM   : integer   := c_DFLD_KIKNM_PIX_S + c_EP_MEM_ACC_PARMA                        ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_KI_KNORM
constant c_EP_MEM_ACC_KNORM   : integer   := c_DFLD_KNORM_PIX_S + c_EP_MEM_ACC_KIKNM                        ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_KNORM
constant c_EP_MEM_ACC_SMFB0   : integer   := c_DFLD_SMFB0_PIX_S + c_EP_MEM_ACC_KNORM                        ; --! EP command: Memory accumulated bus size, CY_MUX_SQ_FB0
constant c_EP_MEM_ACC_SMLKV   : integer   := c_DFLD_SMLKV_PIX_S + c_EP_MEM_ACC_SMFB0                        ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_MEM_ACC_SMFBM   : integer   := c_DFLD_SMFBM_PIX_S + c_EP_MEM_ACC_SMLKV                        ; --! EP command: Memory accumulated bus size, CY_MUX_SQ_FB_MODE
constant c_EP_MEM_ACC_SAOFF   : integer   := c_DFLD_SAOFF_PIX_S + c_EP_MEM_ACC_SMFBM                        ; --! EP command: Memory accumulated bus size, CY_AMP_SQ_OFFSET_FINE
constant c_EP_MEM_ACC_PLSSH   : integer   := c_DFLD_PLSSH_PLS_S + c_EP_MEM_ACC_SAOFF                        ; --! EP command: Memory accumulated bus size, CY_PULSE_SHAPING
constant c_EP_MEM_ACC_DLCNT   : integer   := c_DFLD_DLCNT_PIX_S + c_EP_MEM_ACC_PLSSH                        ; --! EP command: Memory accumulated bus size, CY_DELOCK_COUNTERS

   --! EP command: Memory address accumulated bus size
constant c_EP_MEM_ADDAC_TSTPT : integer   := c_MEM_TSTPT_ADD_S                                              ; --! EP command: Memory accumulated bus size, TEST_PATTERN
constant c_EP_MEM_ADDAC_PARMA : integer   := c_MEM_PARMA_ADD_S + c_EP_MEM_ADDAC_TSTPT                       ; --! EP command: Memory for data squid proc. accumulated bus size, CY_A
constant c_EP_MEM_ADDAC_KIKNM : integer   := c_MEM_KIKNM_ADD_S + c_EP_MEM_ADDAC_PARMA                       ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_KI_KNORM
constant c_EP_MEM_ADDAC_KNORM : integer   := c_MEM_KNORM_ADD_S + c_EP_MEM_ADDAC_KIKNM                       ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_KNORM
constant c_EP_MEM_ADDAC_SMFB0 : integer   := c_MEM_SMFB0_ADD_S + c_EP_MEM_ADDAC_KNORM                       ; --! EP command: Memory accumulated bus size, CY_MUX_SQ_FB0
constant c_EP_MEM_ADDAC_SMLKV : integer   := c_MEM_SMLKV_ADD_S + c_EP_MEM_ADDAC_SMFB0                       ; --! EP command: Memory for data squid proc. accumulated bus size, CY_MUX_SQ_LOCKPOINT_V
constant c_EP_MEM_ADDAC_SMFBM : integer   := c_MEM_SMFBM_ADD_S + c_EP_MEM_ADDAC_SMLKV                       ; --! EP command: Memory accumulated bus size, CY_MUX_SQ_FB_MODE
constant c_EP_MEM_ADDAC_SAOFF : integer   := c_MEM_SAOFF_ADD_S + c_EP_MEM_ADDAC_SMFBM                       ; --! EP command: Memory accumulated bus size, CY_AMP_SQ_OFFSET_FINE
constant c_EP_MEM_ADDAC_PLSSH : integer   := c_MEM_PLSSH_ADD_S + c_EP_MEM_ADDAC_SAOFF                       ; --! EP command: Memory accumulated bus size, CY_PULSE_SHAPING
constant c_EP_MEM_ADDAC_DLCNT : integer   := c_MEM_DLCNT_ADD_S + c_EP_MEM_ADDAC_PLSSH                       ; --! EP command: Memory accumulated bus size, CY_DELOCK_COUNTERS

constant c_EP_MEM_ACC         : integer_vector(0 to c_EP_MEM_NUM_LAST) := (0,
                                 c_EP_MEM_ACC_TSTPT, c_EP_MEM_ACC_PARMA, c_EP_MEM_ACC_KIKNM,
                                 c_EP_MEM_ACC_KNORM, c_EP_MEM_ACC_SMFB0, c_EP_MEM_ACC_SMLKV,
                                 c_EP_MEM_ACC_SMFBM, c_EP_MEM_ACC_SAOFF, c_EP_MEM_ACC_PLSSH,
                                 c_EP_MEM_ACC_DLCNT)                                                        ; --! EP command: Memory data accumulated bus size

constant c_EP_MEM_POS         : integer_vector(0 to c_EP_MEM_NUM_LAST-1) :=
                                (c_EP_CMD_POS_TSTPT, c_EP_CMD_POS_PARMA, c_EP_CMD_POS_KIKNM,
                                 c_EP_CMD_POS_KNORM, c_EP_CMD_POS_SMFB0, c_EP_CMD_POS_SMLKV,
                                 c_EP_CMD_POS_SMFBM, c_EP_CMD_POS_SAOFF, c_EP_CMD_POS_PLSSH,
                                 c_EP_CMD_POS_DLCNT)                                                        ; --! EP command: Memory position

constant c_EP_MEM_ADDAC_S     : integer_vector(0 to c_EP_MEM_NUM_LAST) := (0,
                                 c_EP_MEM_ADDAC_TSTPT, c_EP_MEM_ADDAC_PARMA, c_EP_MEM_ADDAC_KIKNM,
                                 c_EP_MEM_ADDAC_KNORM, c_EP_MEM_ADDAC_SMFB0, c_EP_MEM_ADDAC_SMLKV,
                                 c_EP_MEM_ADDAC_SMFBM, c_EP_MEM_ADDAC_SAOFF, c_EP_MEM_ADDAC_PLSSH,
                                 c_EP_MEM_ADDAC_DLCNT)                                                      ; --! EP command: Memory adress accumulated bus size

constant c_EP_MEM_ADD_OFF     : t_slv_arr(0 to c_EP_MEM_NUM_LAST-1)(c_EP_SPI_WD_S-1 downto 0) :=
                                (c_EP_CMD_ADD_TSTPT        , c_EP_CMD_ADD_PARMA(c_COL0), c_EP_CMD_ADD_KIKNM(c_COL0),
                                 c_EP_CMD_ADD_KNORM(c_COL0), c_EP_CMD_ADD_SMFB0(c_COL0), c_EP_CMD_ADD_SMLKV(c_COL0),
                                 c_EP_CMD_ADD_SMFBM(c_COL0), c_EP_CMD_ADD_SAOFF(c_COL0), c_EP_CMD_ADD_PLSSH(c_COL0),
                                 c_EP_CMD_ADD_DLCNT(c_COL0))                                                ; --! EP command: Memory adress offset

constant c_EP_MEM_ADD_END     : integer_vector(0 to c_EP_MEM_NUM_LAST-1) :=
                                (c_TAB_TSTPT_NW-1, c_TAB_PARMA_NW-1, c_TAB_KIKNM_NW-1,
                                 c_TAB_KNORM_NW-1, c_TAB_SMFB0_NW-1, c_TAB_SMLKV_NW-1,
                                 c_TAB_SMFBM_NW-1, c_TAB_SAOFF_NW-1, c_MEM_PLSSH_ADD_END,
                                 c_TAB_DLCNT_NW-1)                                                          ; --! EP command: Memory adress end

end pkg_ep_cmd_type;
