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
--!   @file                   pkg_func_math.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Mathematical function package
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;

package pkg_func_math is

function log2_ceil              (X: in integer) return integer                                              ; --! return logarithm base 2 of X  (ceil integer)
function div_ceil               (X: in integer; Y : in integer) return integer                              ; --! return X/Y (ceil integer)
function div_floor              (X: in integer; Y : in integer) return integer                              ; --! return X/Y (floor integer)
function div_round              (X: in integer; Y : in integer) return integer                              ; --! return X/Y (round integer)

   -- ------------------------------------------------------------------------------------------------------
   --!   Convert real array to std_logic_vector array
   -- ------------------------------------------------------------------------------------------------------
   function real_arr_to_slv_arr (
         i_tab_real           : in     real_vector                                                          ; --  Table in real format
         i_tab_coef_s         : in     integer                                                              ; --  Table coefficient bus size output
         i_tab_coef_frc_s     : in     integer                                                                --  Table coefficient fractional part bus size output
   ) return t_slv_arr;

end pkg_func_math;

package body pkg_func_math is

   -- ------------------------------------------------------------------------------------------------------
   --! return logarithm base 2 of X  (ceil integer)
   -- ------------------------------------------------------------------------------------------------------
   function log2_ceil           (X: in integer) return integer is
   begin
      return integer(ceil(log2(real(X))));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (ceil integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_ceil            (X: in integer; Y : in integer) return integer is
   begin
      return integer(ceil(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (floor integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_floor           (X: in integer; Y : in integer) return integer is
   begin
      return integer(floor(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (round integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_round           (X: in integer; Y : in integer) return integer is
   begin
      return integer(round(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --!   Convert real array to std_logic_vector array
   -- ------------------------------------------------------------------------------------------------------
   function real_arr_to_slv_arr (
         i_tab_real           : in     real_vector                                                          ; --  Table in real format
         i_tab_coef_s         : in     integer                                                              ; --  Table coefficient bus size output
         i_tab_coef_frc_s     : in     integer                                                                --  Table coefficient fractional part bus size output
   ) return t_slv_arr is
   constant c_TAB_COEF_EXP    : real := 2**real(i_tab_coef_frc_s)                                           ; --! Table coefficient exponent

   variable v_tab_slv_arr     : t_slv_arr(i_tab_real'range)(i_tab_coef_s-1 downto 0)                        ; --! Table in std_logic_vector array format
   begin

      for k in 0 to i_tab_real'high loop
         v_tab_slv_arr(k) := std_logic_vector(to_signed(integer(round(i_tab_real(k) * c_TAB_COEF_EXP)), i_tab_coef_s));

      end loop;

      return v_tab_slv_arr;

   end real_arr_to_slv_arr;

end pkg_func_math;
