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
--!   @file                   sts_err_wrt_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command: Status, error try to write in a read only register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sts_err_wrt_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_wrt : out    std_logic                                                              --! EP command: Status, error try to write in a read only register
   );
end entity sts_err_wrt_mgt;

architecture RTL of sts_err_wrt_mgt is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error try to write in a read only register
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_wrt : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_ep_cmd_sts_err_wrt <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_R then
            o_ep_cmd_sts_err_wrt <= c_EP_CMD_ERR_CLR;

         else
            if    i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_AQMDE  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_AQMDE;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SMFMD  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMFMD;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SAOFM  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOFM;

            elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_MEM_TSTPT_ADD_S)      = c_EP_CMD_ADD_TSTPT(i_ep_cmd_rx_add_norw'high downto c_MEM_TSTPT_ADD_S)         and
                  i_ep_cmd_rx_add_norw(  c_MEM_TSTPT_ADD_S-1     downto 0)                      < std_logic_vector(to_unsigned(c_TAB_TSTPT_NW, c_MEM_TSTPT_ADD_S))               then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_TSTPT;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_TSTEN  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_TSTEN;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_BXLGT  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_BXLGT;

            elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_MEM_HKEEP_ADD_S)      = c_EP_CMD_ADD_HKEEP(i_ep_cmd_rx_add_norw'high downto c_MEM_HKEEP_ADD_S)         and
                  i_ep_cmd_rx_add_norw(  c_MEM_HKEEP_ADD_S-1     downto 0)                      < std_logic_vector(to_unsigned(c_TAB_HKEEP_NW, c_MEM_HKEEP_ADD_S))               then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_HKEEP;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_DLFLG  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_DLFLG;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_STATUS   then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_STATUS;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_FW_VER  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_FW_VER;

            elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_HW_VER  then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_HW_VER;

            elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) /= c_ZERO(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) then
               o_ep_cmd_sts_err_wrt <= c_EP_CMD_ERR_CLR;

            else
               if    i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PARMA_ADD_S)      = c_EP_CMD_ADD_PARMA(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PARMA_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_PARMA_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PARMA_NW, c_MEM_PARMA_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_PARMA;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMIGN(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMIGN;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAIGN(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAIGN;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                     >= c_EP_CMD_ADD_KIKNM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                        and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_KIKNM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                                                 + to_unsigned(c_TAB_KIKNM_NW, c_EP_CMD_ADD_COLPOSL))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_KIKNM;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAKKM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAKKM;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_KNORM_ADD_S)      = c_EP_CMD_ADD_KNORM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_KNORM_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_KNORM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_KNORM_NW, c_MEM_KNORM_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_KNORM;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAKRM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAKRM;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFB0_ADD_S)      = c_EP_CMD_ADD_SMFB0(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFB0_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SMFB0_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFB0_NW, c_MEM_SMFB0_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMFB0;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                     >= c_EP_CMD_ADD_SMLKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                        and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_SMLKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                                                 + to_unsigned(c_TAB_SMLKV_NW, c_EP_CMD_ADD_COLPOSL))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMLKV;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SALKV(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SALKV;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      = c_EP_CMD_ADD_SMFBM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SMFBM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMFBM;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      = c_EP_CMD_ADD_SAOFF(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SAOFF_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOFF;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOLP(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOLP;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOFL;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFC(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOFC;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMFBD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMFBD;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAODD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAODD;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOMD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SAOMD;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMPDL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_SMPDL;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PLSSH_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_PLSSH_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_MEM_PLSSH_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_PLSSH;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_PLSSS(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_PLSSS;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_RLDEL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_RLDEL;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_RLTHR(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_RLTHR;

               elsif i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_DLCNT_ADD_S)      = c_EP_CMD_ADD_DLCNT(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_DLCNT_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_DLCNT_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_DLCNT_NW, c_MEM_DLCNT_ADD_S))                    then
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_AUTH_DLCNT;

               else
                  o_ep_cmd_sts_err_wrt <= c_EP_CMD_ERR_CLR;

               end if;

            end if;

         end if;

      end if;

   end process P_ep_cmd_sts_err_wrt;

end architecture RTL;
