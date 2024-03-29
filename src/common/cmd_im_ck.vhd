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
--!   @file                   cmd_im_ck.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Image clock command
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;

entity cmd_im_ck is generic (
         g_CK_CMD_DEF         : std_logic                                                                     --! Clock switch command default value at reset
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_cmd_ck_ena         : in     std_logic                                                            ; --! Clock switch command enable  ('0' = Inactive, '1' = Active)
         i_cmd_ck_dis         : in     std_logic                                                            ; --! Clock switch command disable ('0' = Inactive, '1' = Active)

         o_cmd_ck             : out    std_logic                                                            ; --! Clock switch command
         o_cmd_ck_sleep       : out    std_logic                                                              --! Clock switch command sleep ('0' = Inactive, '1' = Active)
   );
end entity cmd_im_ck;

architecture RTL of cmd_im_ck is
signal   cmd_ck_dis_r         : std_logic                                                                   ; --! Clock switch command disable register
signal   cmd_ck_sleep         : std_logic                                                                   ; --! Clock switch command sleep ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Clock switch command
   -- ------------------------------------------------------------------------------------------------------
   P_cmd_ck : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cmd_ck_dis_r   <= c_LOW_LEV;
         o_cmd_ck       <= g_CK_CMD_DEF;
         cmd_ck_sleep   <= not(g_CK_CMD_DEF);
         o_cmd_ck_sleep <= not(g_CK_CMD_DEF);

      elsif rising_edge(i_clk) then
         cmd_ck_dis_r <= i_cmd_ck_dis;

         if    i_cmd_ck_ena = c_HGH_LEV then
            o_cmd_ck <= c_HGH_LEV;

         elsif i_cmd_ck_dis = c_HGH_LEV then
            o_cmd_ck <= c_LOW_LEV;

         end if;

         if    i_cmd_ck_ena = c_HGH_LEV then
            cmd_ck_sleep <= c_LOW_LEV;

         elsif cmd_ck_dis_r = c_HGH_LEV then
            cmd_ck_sleep <= c_HGH_LEV;

         end if;

         o_cmd_ck_sleep <= cmd_ck_sleep;

      end if;

   end process P_cmd_ck;

end architecture RTL;
