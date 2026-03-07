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
--!   @file                   sqa_dac_sys.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP DAC signals synchronized on system clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sqa_dac_sys is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization (System Clock)
         i_sqa_off_lsb        : in     std_logic_vector(  c_SQA_DAC_DATA_S-1 downto 0)                      ; --! SQUID AMP offset LSB
         i_saodd              : in     std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                      ; --! SQUID AMP offset DAC delay (System Clock)

         o_sync_rs_rsys       : out    std_logic                                                            ; --! Pixel sequence synchronization register (System Clock)
         o_sqa_off_lsb_rsys   : out    std_logic_vector(  c_SQA_DAC_DATA_S-1 downto 0)                      ; --! SQUID AMP offset LSB register (System Clock)
         o_saodd_rsys         : out    std_logic_vector(c_DFLD_SAODD_COL_S-1 downto 0)                        --! SQUID AMP offset DAC delay register (System Clock)
   );
end entity sqa_dac_sys;

architecture RTL of sqa_dac_sys is
attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_sync_rs_rsys        : signal is true                                   ; --! Disabling signal optimization: o_sync_rs_rsys

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs registered on system clock
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sys: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sync_rs_rsys       <= c_I_SYNC_DEF;
         o_sqa_off_lsb_rsys   <= c_EP_CMD_DEF_SAOFL;
         o_saodd_rsys         <= c_EP_CMD_DEF_SAODD;

      elsif rising_edge(i_clk) then
         o_sync_rs_rsys       <= i_sync_rs;
         o_sqa_off_lsb_rsys   <= i_sqa_off_lsb;
         o_saodd_rsys         <= i_saodd;

      end if;

   end process P_reg_sys;

end architecture RTL;
