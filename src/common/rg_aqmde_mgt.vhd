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
--!   @file                   rg_aqmde_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Register AQMDE Telemetry mode management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity rg_aqmde_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ep_cmd_rx_wd_dta_r : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     : in     std_logic                                                            ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r : in     std_logic                                                            ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
         i_cs_rg_aqdme        : in     std_logic                                                            ; --! Chip selects register AQMDE

         i_tst_pat_end_re     : in     std_logic                                                            ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         i_aqmde_dmp_tx_end   : in     std_logic                                                            ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)

         o_aqmde              : out    std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         o_rg_aqmde_dmp_cmp   : out    std_logic                                                            ; --! EP register: DATA_ACQ_MODE, status "Dump" compared ('0' = Inactive, '1' = Active)
         o_rg_aqmde_tst_cmp   : out    std_logic                                                              --! EP register: DATA_ACQ_MODE, status "Test Pattern" compared ('0'=Inactive, '1'=Active)
   );
end entity rg_aqmde_mgt;

architecture RTL of rg_aqmde_mgt is
signal   rg_aqmde_sav         : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! EP register: DATA_ACQ_MODE save previous mode

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Telemetry mode
   -- ------------------------------------------------------------------------------------------------------
   P_aqmde : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_aqmde      <= c_DST_AQMDE_IDLE;
         rg_aqmde_sav <= c_DST_AQMDE_IDLE;

      elsif rising_edge(i_clk) then

         if i_ep_cmd_rx_ner_ry_r = c_HGH_LEV and i_ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and i_cs_rg_aqdme = c_HGH_LEV then
            o_aqmde <= i_ep_cmd_rx_wd_dta_r;

         elsif (o_aqmde = c_DST_AQMDE_TEST and i_tst_pat_end_re = c_HGH_LEV) or (o_aqmde = c_DST_AQMDE_DUMP and i_aqmde_dmp_tx_end = c_HGH_LEV) then
            o_aqmde <= rg_aqmde_sav;

         end if;

         if i_ep_cmd_rx_ner_ry_r = c_HGH_LEV and i_ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W then

            if i_cs_rg_aqdme = c_HGH_LEV then
               if i_ep_cmd_rx_wd_dta_r = c_DST_AQMDE_TEST or
                 (i_ep_cmd_rx_wd_dta_r = c_DST_AQMDE_DUMP and o_aqmde = c_DST_AQMDE_TEST) then
                  rg_aqmde_sav <= c_DST_AQMDE_IDLE;

               else
                  rg_aqmde_sav <= o_aqmde;

               end if;

            end if;

         end if;

      end if;

   end process P_aqmde;

   o_rg_aqmde_dmp_cmp <= c_HGH_LEV when o_aqmde = c_DST_AQMDE_DUMP else c_LOW_LEV;
   o_rg_aqmde_tst_cmp <= c_HGH_LEV when o_aqmde = c_DST_AQMDE_TEST else c_LOW_LEV;

end architecture RTL;
