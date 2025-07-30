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
--!   @file                   pkg_mod.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Parameters specific to the model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;

package pkg_mod is

constant c_COL                : integer   := 4                                                              ; --! DEMUX: column number

   -- ------------------------------------------------------------------------------------------------------
   --!   Parameters specific to the model
   -- ------------------------------------------------------------------------------------------------------
constant c_FPGA_POS_ADC       : integer_vector(0 to c_COL-1) := ( 2, 3, 0, 1)                               ; --! FPGA position ADC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)
constant c_FPGA_POS_SQM_DAC   : integer_vector(0 to c_COL-1) := ( 3, 2, 1, 0)                               ; --! FPGA position MUX DAC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)
constant c_FPGA_POS_SQA_DAC   : integer_vector(0 to c_COL-1) := ( 3, 3, 0, 0)                               ; --! FPGA position AMP DAC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)

constant c_SQM_DATA_COMP      : std_logic_vector(c_COL-1 downto 0):= "1001"                                 ; --! SQUID MUX data by column complemented ('0' = No, '1' = Yes)

constant c_CLK_ADC_DEL_STEP   : integer   := 36                                                             ; --! ADC Clock propagation delay step number

end pkg_mod;
