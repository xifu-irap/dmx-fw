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
--!   @file                   science_data_sync_ck.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data synchronized on falling edge external generated clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;

entity science_data_sync_ck is port (
         i_rst_sqm_adc_dac    : in     std_logic                                                            ; --! Reset for SQUID ADC/DAC, de-assertion on system clock ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID ADC/DAC internal Clock

         i_science_data_ser   : in     std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                 ; --! Science Data: Serial Data
         i_science_data_ena   : in     std_logic                                                            ; --! Science Data: Enable
         o_sc_data_sync_ck    : out    std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                   --! Science Data: Serial Data synchronized on falling edge external generated clock
   );
end entity science_data_sync_ck;

architecture RTL of science_data_sync_ck is
signal   rst_sqm_adc_dac_lc   : std_logic                                                                   ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock

signal   science_data_ser_r   : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_NB_COL*c_SC_DATA_SER_NB downto 0)         ; --! Science Data: Serial Data register
signal   sc_data_sync_ck      : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                        ; --! Science Data: Serial Data synchronized on falling edge external generated clock

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of rst_sqm_adc_dac_lc    : signal is true                                   ; --! Disabling signal optimization: rst_sqm_adc_dac_lc

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Local reset on SQUID MUX ADC acquisition Clock
   --    @Req : DRE-DMX-FW-REQ-0050
   -- ------------------------------------------------------------------------------------------------------
   P_rst_sqm_adc_dac_lc: process (i_rst_sqm_adc_dac, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac = c_RST_LEV_ACT then
         rst_sqm_adc_dac_lc  <= c_RST_LEV_ACT;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         rst_sqm_adc_dac_lc  <= not(c_RST_LEV_ACT);

      end if;

   end process P_rst_sqm_adc_dac_lc;

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         science_data_ser_r   <= (others => c_ZERO(science_data_ser_r(science_data_ser_r'high)'range));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         science_data_ser_r   <= i_science_data_ser & science_data_ser_r(0 to science_data_ser_r'high-1);

      end if;

   end process P_rsync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data serial
   -- ------------------------------------------------------------------------------------------------------
   P_sc_data_sync_ck : process (rst_sqm_adc_dac_lc , i_clk_sqm_adc_dac)
   begin

      if rst_sqm_adc_dac_lc  = c_RST_LEV_ACT then
         sc_data_sync_ck   <= c_ZERO(  sc_data_sync_ck'range);
         o_sc_data_sync_ck <= c_ZERO(o_sc_data_sync_ck'range);

      elsif rising_edge(i_clk_sqm_adc_dac) then
         if i_science_data_ena = c_HGH_LEV then
            sc_data_sync_ck <= science_data_ser_r(science_data_ser_r'high);

         end if;

      o_sc_data_sync_ck <= sc_data_sync_ck;

      end if;

   end process P_sc_data_sync_ck;

end architecture RTL;
