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
--!   @file                   sts_err_out_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command: Status, error data out of range management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sts_err_out_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_out_rdy  : in     std_logic                                                            ; --! EP command receipted: error data out of range ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd_sts_err_out : out    std_logic                                                              --! EP command: Status, error data out of range
   );
end entity sts_err_out_mgt;

architecture RTL of sts_err_out_mgt is
constant c_DFLD_SMFMD_TOT_S   : integer   :=  c_EP_SPI_WD_S/c_NB_COL                                        ; --! EP command: Data field, MUX_SQ_FB_ON_OFF total bus size
constant c_DFLD_SAOFM_TOT_S   : integer   :=  c_EP_SPI_WD_S/c_NB_COL                                        ; --! EP command: Data field, AMP_SQ_OFFSET_MODE total bus size

signal   cond_aqmde           : std_logic                                                                   ; --! Error data out of range condition: DATA_ACQ_MODE
signal   cond_smfmd           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Error data out of range condition: MUX_SQ_FB_ON_OFF
signal   cond_smfmd_or        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Error data out of range condition: MUX_SQ_FB_ON_OFF "or-ed"
signal   cond_saofm           : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Error data out of range condition: AMP_SQ_OFFSET_MODE
signal   cond_saofm_or        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Error data out of range condition: AMP_SQ_OFFSET_MODE "or-ed"
signal   cond_tsten           : std_logic                                                                   ; --! Error data out of range condition: TEST_PATTERN_ENABLE
signal   cond_smfbm           : std_logic                                                                   ; --! Error data out of range condition: CY_MUX_SQ_FB_MODE
signal   cond_saoff           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_FINE
signal   cond_saolp           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_LSB_PTR
signal   cond_saofl           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_LSB
signal   cond_saofc           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_COARSE
signal   cond_smfbd           : std_logic                                                                   ; --! Error data out of range condition: CY_MUX_SQ_FB_DELAY
signal   cond_saodd           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_DAC_DELAY
signal   cond_saomd           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_MUX_DELAY
signal   cond_smpdl           : std_logic                                                                   ; --! Error data out of range condition: CY_SAMPLING_DELAY
signal   cond_plsss           : std_logic                                                                   ; --! Error data out of range condition: CY_PULSE_SHAPING_SELECTION

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Error data out of range conditions
   -- ------------------------------------------------------------------------------------------------------
   cond_aqmde     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_AQMDE_S)     /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_AQMDE_S) else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_IDLE else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_SCIE else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_ERRS else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_DUMP else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_AQMDE_S-1 downto 0) = c_DST_AQMDE_TEST else
                     c_HGH_LEV;

   cond_smfmd_or(0) <= cond_smfmd(0);
   cond_saofm_or(0) <= cond_saofm(0);

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      cond_smfmd(k)  <= c_HGH_LEV when i_ep_cmd_rx_wd_data((k+1)*c_DFLD_SMFMD_TOT_S-1 downto k*c_DFLD_SMFMD_TOT_S+c_DFLD_SMFMD_COL_S) /= c_ZERO(c_DFLD_SMFMD_TOT_S-1 downto c_DFLD_SMFMD_COL_S) else
                        c_LOW_LEV;

      cond_saofm(k)  <= c_HGH_LEV when i_ep_cmd_rx_wd_data((k+1)*c_DFLD_SAOFM_TOT_S-1 downto k*c_DFLD_SAOFM_TOT_S+c_DFLD_SAOFM_COL_S) /= c_ZERO(c_DFLD_SAOFM_TOT_S-1 downto c_DFLD_SAOFM_COL_S) else
                        c_LOW_LEV;

      G_k_not0: if k /= c_ZERO_INT generate

         cond_smfmd_or(k) <= cond_smfmd(k) or cond_smfmd_or(k-1);
         cond_saofm_or(k) <= cond_saofm(k) or cond_saofm_or(k-1);

      end generate G_k_not0;

   end generate G_column_mgt;

   cond_tsten     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_TSTEN_S)     /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_TSTEN_S) else
                     c_LOW_LEV;

   cond_smfbm     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMFBM_PIX_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMFBM_PIX_S) else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_SMFBM_PIX_S-1 downto 0) = c_DST_SMFBM_OPEN  else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_SMFBM_PIX_S-1 downto 0) = c_DST_SMFBM_CLOSE else
                     c_LOW_LEV when i_ep_cmd_rx_wd_data(c_DFLD_SMFBM_PIX_S-1 downto 0) = c_DST_SMFBM_TEST  else
                     c_HGH_LEV;

   cond_saoff     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFF_PIX_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFF_PIX_S) else
                     c_LOW_LEV;

   cond_saolp     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOLP_COL_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOLP_COL_S) else
                     c_LOW_LEV;

   cond_saofl     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFL_COL_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFL_COL_S) else
                     c_LOW_LEV;

   cond_saofc     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFC_COL_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOFC_COL_S) else
                     c_LOW_LEV;

   cond_smfbd     <= c_LOW_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMFBD_COL_S-1) = c_MINUSONE(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMFBD_COL_S-1) else
                     c_LOW_LEV when unsigned(i_ep_cmd_rx_wd_data) <= to_unsigned(  c_DFLD_SMFBD_MAX, i_ep_cmd_rx_wd_data'length) else
                     c_HGH_LEV;

   cond_saodd     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAODD_COL_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAODD_COL_S) else
                     c_LOW_LEV;

   cond_saomd     <= c_LOW_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOMD_COL_S-1) = c_MINUSONE(i_ep_cmd_rx_wd_data'high downto c_DFLD_SAOMD_COL_S-1) else
                     c_LOW_LEV when unsigned(i_ep_cmd_rx_wd_data) <= to_unsigned(  c_DFLD_SAOMD_MAX, i_ep_cmd_rx_wd_data'length) else
                     c_HGH_LEV;

   cond_smpdl     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMPDL_COL_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_SMPDL_COL_S) else
                     c_HGH_LEV when unsigned(i_ep_cmd_rx_wd_data(c_DFLD_SMPDL_COL_S-1 downto 0)) > to_unsigned(c_DFLD_SMPDL_MAX, c_DFLD_SMPDL_COL_S) else
                     c_LOW_LEV;

   cond_plsss     <= c_HGH_LEV when i_ep_cmd_rx_wd_data(i_ep_cmd_rx_wd_data'high downto c_DFLD_PLSSS_PLS_S) /= c_ZERO(i_ep_cmd_rx_wd_data'high downto c_DFLD_PLSSS_PLS_S) else
                     c_LOW_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error data out of range
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_out : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if i_ep_cmd_rx_out_rdy = c_HGH_LEV then
            if i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_R then
               o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

            else

               if    i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_AQMDE  then
                  o_ep_cmd_sts_err_out <= cond_aqmde xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SMFMD  then
                  o_ep_cmd_sts_err_out <= cond_smfmd_or(cond_smfmd_or'high) xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SAOFM  then
                  o_ep_cmd_sts_err_out <= cond_saofm_or(cond_saofm_or'high) xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_TSTEN  then
                  o_ep_cmd_sts_err_out <= cond_tsten xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBM(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      = c_EP_CMD_ADD_SMFBM(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SMFBM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S))                    then
                  o_ep_cmd_sts_err_out <= cond_smfbm xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFF(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      = c_EP_CMD_ADD_SAOFF(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SAOFF_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S))                    then
                  o_ep_cmd_sts_err_out <= cond_saoff xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOLP(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOLP(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saolp xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFL(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saofl xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFC(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFC(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saofc xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBD(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMFBD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_smfbd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAODD(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAODD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saodd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOMD(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOMD(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saomd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMPDL(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMPDL(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_smpdl xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSS(c_COL0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_PLSSS(c_COL0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_plsss xor c_EP_CMD_ERR_CLR;

               else
                  o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

               end if;

            end if;

         end if;

      end if;

   end process P_ep_cmd_sts_err_out;

end architecture RTL;
