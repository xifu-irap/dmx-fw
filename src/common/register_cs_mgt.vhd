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
--!   @file                   register_cs_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Chip selects register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity register_cs_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ep_cmd_rx_wd_add_r : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared, registered
         o_cs_rg              : out    std_logic_vector(c_EP_CMD_REG_MX_STIN(1)-1 downto 0)                   --! Chip selects register ('0' = Inactive, '1' = Active)
   );
end entity register_cs_mgt;

architecture RTL of register_cs_mgt is
signal   cs_rg                : std_logic_vector(c_EP_CMD_POS_LAST-1 downto 0)                              ; --! Chip selects register ('0' = Inactive, '1' = Active)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Chip selects register
   -- ------------------------------------------------------------------------------------------------------
   cs_rg(c_EP_CMD_POS_AQMDE)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_AQMDE  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_SMFMD)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SMFMD  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_SAOFM)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOFM  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_TSTEN)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_TSTEN  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_BXLGT)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_BXLGT  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_DLFLG)  <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_DLFLG  else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_STATUS) <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_STATUS else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_FW_VER) <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_FW_VER else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_HW_VER) <= c_HGH_LEV when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_HW_VER else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_TSTPT)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)        = c_EP_CMD_ADD_TSTPT(i_ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)                and
       i_ep_cmd_rx_wd_add_r(   c_MEM_TSTPT_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_TSTPT_NW, c_MEM_TSTPT_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_HKEEP)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)        = c_EP_CMD_ADD_HKEEP(i_ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)                and
       i_ep_cmd_rx_wd_add_r(   c_MEM_HKEEP_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_HKEEP_NW, c_MEM_HKEEP_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_PARMA)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_PARMA(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)          = c_EP_CMD_ADD_PARMA(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_PARMA_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_PARMA_NW, c_MEM_PARMA_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMIGN)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMIGN(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SMIGN(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAIGN)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAIGN(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAIGN(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_KIKNM)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_KIKNM(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                         >= c_EP_CMD_ADD_KIKNM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                        and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          < std_logic_vector(unsigned(c_EP_CMD_ADD_KIKNM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                                     + to_unsigned(c_TAB_KIKNM_NW, c_EP_CMD_ADD_COLPOSL)))              else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_SAKKM)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAKKM(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAKKM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_KNORM)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_KNORM(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)          = c_EP_CMD_ADD_KNORM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_KNORM_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_KNORM_NW, c_MEM_KNORM_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAKRM)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAKRM(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAKRM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMFB0)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMFB0(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)          = c_EP_CMD_ADD_SMFB0(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SMFB0_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_SMFB0_NW, c_MEM_SMFB0_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMLKV)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMLKV(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                         >= c_EP_CMD_ADD_SMLKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                        and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          < std_logic_vector(unsigned(c_EP_CMD_ADD_SMLKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                                     + to_unsigned(c_TAB_SMLKV_NW, c_EP_CMD_ADD_COLPOSL)))              else c_LOW_LEV;
   cs_rg(c_EP_CMD_POS_SALKV)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SALKV(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SALKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMFBM)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMFBM(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)          = c_EP_CMD_ADD_SMFBM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SMFBM_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAOLP)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAOLP(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAOLP(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAOFF)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAOFF(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)          = c_EP_CMD_ADD_SAOFF(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SAOFF_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S)))              else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAOFC)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAOFC(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAOFC(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAOFL)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAOFL(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAOFL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMFBD)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMFBD(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SMFBD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAODD)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAODD(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAODD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SAOMD)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SAOMD(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SAOMD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_SMPDL)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_SMPDL(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_SMPDL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_PLSSH)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_PLSSH(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)          = c_EP_CMD_ADD_PLSSH(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(     c_TAB_PLSSH_S-1    downto 0)                          < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_TAB_PLSSH_S)))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_PLSSS)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_PLSSS(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_PLSSS(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_RLDEL)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_RLDEL(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_RLDEL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_RLTHR)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_RLTHR(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                          = c_EP_CMD_ADD_RLTHR(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                  else c_LOW_LEV;

   cs_rg(c_EP_CMD_POS_DLCNT)  <= c_HGH_LEV when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1)   = c_EP_CMD_ADD_DLCNT(c_COL0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)          = c_EP_CMD_ADD_DLCNT(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)        and
       i_ep_cmd_rx_wd_add_r(   c_MEM_DLCNT_ADD_S-1  downto 0)                          < std_logic_vector(to_unsigned(c_TAB_DLCNT_NW, c_MEM_DLCNT_ADD_S)))              else c_LOW_LEV;

   --! Chip selects register
   P_cs_rg : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_cs_rg(c_EP_CMD_POS_LAST-1 downto 0) <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         o_cs_rg(c_EP_CMD_POS_LAST-1 downto 0) <= cs_rg;

      end if;

   end process P_cs_rg;

   o_cs_rg(c_EP_CMD_REG_MX_STIN(1)-1 downto c_EP_CMD_POS_LAST) <= (others => c_LOW_LEV);

end architecture RTL;
