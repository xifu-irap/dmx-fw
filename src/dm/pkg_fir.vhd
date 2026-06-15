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
--!   @file                   pkg_fir.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP under-sampling filters parameters
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;

package pkg_fir is
constant c_FIR_DATA_SHF_NU    : integer := 0                                                                ; --! Filter FIR data shift used by the product: not used value

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID AMP parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_SQA_FIR1_DCI_VAL   : integer := 2                                                                ; --! SQUID AMP: Filter FIR1 decimation value
constant c_SQA_FIR1_TAB_NW    : integer := 26                                                               ; --! SQUID AMP: Filter FIR1 table number word
constant c_SQA_FIR1_DATA_S    : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter FIR1 data input bus size
constant c_SQA_FIR1_S         : integer := c_MULT_ALU_PORTA_S                                               ; --! SQUID AMP: Filter FIR1 coefficient bus size
constant c_SQA_FIR1_FRC_S     : integer := integer(ceil(real(c_SQA_FIR1_S-2) - log2(0.256344821000)))       ; --! SQUID AMP: Filter FIR1 coefficient fractional part
constant c_SQA_FIR1_COEF_SM_S : integer := c_SQA_FIR1_FRC_S                                                 ; --! SQUID AMP: Filter FIR1 coefficient sum bus size (sum slightly higher than 1.0)
constant c_SQA_FIR1_DATA_SHF  : integer := c_FIR_DATA_SHF_NU                                                ; --! SQUID AMP: Filter FIR1 data shift used by the product
constant c_SQA_FIR1_TAB_REAL  : real_vector(0 to 2**log2_ceil(c_SQA_FIR1_TAB_NW)-1) :=
                               ( 0.000000000000,-0.000029024474, 0.000481973816, 0.002098162730,
                                 0.003295826560,-0.000213914191,-0.011663688200,-0.025542737500,
                                -0.023894513700, 0.014492290200, 0.094316714200, 0.190224151000,
                                 0.256344821000, 0.256344821000, 0.190224151000, 0.094316714200,
                                 0.014492290200,-0.023894513700,-0.025542737500,-0.011663688200,
                                -0.000213914191, 0.003295826560, 0.002098162730, 0.000481973816,
                                -0.000029024474, 0.000000000000, 0.000000000000, 0.000000000000,
                                 0.000000000000, 0.000000000000, 0.000000000000, 0.000000000000)            ; --! SQUID AMP: Filter FIR1 coefficients (symetrical FIR, Fs = 6.25 MHz) real vector

constant c_SQA_FIR1_TAB       :  t_slv_arr(0 to 2**log2_ceil(c_SQA_FIR1_TAB_NW)-1)(c_SQA_FIR1_S-1 downto 0) :=
                                 real_arr_to_slv_arr(c_SQA_FIR1_TAB_REAL, c_SQA_FIR1_S, c_SQA_FIR1_FRC_S)   ; --! SQUID AMP: Filter FIR1 coefficients (symetrical FIR, Fs = 6.25 MHz)

constant c_IIR2_DCI_VAL       : integer := 51                                                               ; --! SQUID AMP: Filter IIR2 decimation value
constant c_IIR2_TAB_NW        : integer := 4                                                                ; --! SQUID AMP: Filter IIR2 table number word

constant c_IIR2_IN_TAB_S      : integer := c_MULT_ALU_PORTA_S                                               ; --! SQUID AMP: Filter IIR2 input part coefficient bus size
constant c_IIR2_IN_FRC_S      : integer := integer(ceil(real(c_IIR2_IN_TAB_S-2) - log2(0.00058087)))        ; --! SQUID AMP: Filter IIR2 input part coefficient fractional part
constant c_IIR2_IN_COEF_SM_S  : integer := integer(ceil(real(c_IIR2_IN_FRC_S)   + log2(0.00022638))) + 1    ; --! SQUID AMP: Filter IIR2 input part coefficient sum bus size
constant c_IIR2_IN_DATA_S     : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter IIR2 input part data bus size
constant c_IIR2_IN_DATA_SHF   : integer := c_FIR_DATA_SHF_NU                                                ; --! SQUID AMP: Filter IIR2 input part data shift used by the product
constant c_IIR2_IN_TAB_RL     : real_vector(0 to c_IIR2_TAB_NW-1) :=
                               ( 0.000580870000,-0.000467680000,-0.000467680000, 0.000580870000)            ; --! SQUID AMP: Filter IIR2 input part coefficients real vector
constant c_IIR2_IN_TAB        :  t_slv_arr(0 to c_IIR2_TAB_NW-1)(c_IIR2_IN_TAB_S-1 downto 0) :=
                                 real_arr_to_slv_arr(c_IIR2_IN_TAB_RL, c_IIR2_IN_TAB_S, c_IIR2_IN_FRC_S)    ; --! SQUID AMP: Filter IIR2 input part coefficients coefficients

constant c_IIR2_REC_TAB_S     : integer := 30                                                               ; --! SQUID AMP: Filter IIR2 minus recursive part coefficient bus size
constant c_IIR2_REC_FRC_S     : integer := integer(ceil(real(c_IIR2_REC_TAB_S-2) - log2(2.87600971)))       ; --! SQUID AMP: Filter IIR2 minus recursive part coefficient fractional part
constant c_IIR2_REC_COEF_SM_S : integer := integer(ceil(real(c_IIR2_REC_FRC_S)   + log2(0.99977363))) + 1   ; --! SQUID AMP: Filter IIR2 minus recursive part coefficient sum bus size
constant c_IIR2_REC_DATA_S    : integer := 32                                                               ; --! SQUID AMP: Filter IIR2 minus recursive part data shift bus size
constant c_IIR2_REC_DATA_SHF  : integer := 6                                                                ; --! SQUID AMP: Filter IIR2 minus recursive part data shift used by the product
constant c_IIR2_REC_TAB_RL    : real_vector(0 to c_IIR2_TAB_NW-1) :=
                               ( 0.883353660000,-2.759589740000, 2.876009710000, 0.000000000000)            ; --! SQUID AMP: Filter IIR2 minus recursive part coefficients real vector
constant c_IIR2_REC_TAB       :  t_slv_arr(0 to c_IIR2_TAB_NW-1)(c_IIR2_REC_TAB_S-1 downto 0) :=
                                 real_arr_to_slv_arr(c_IIR2_REC_TAB_RL, c_IIR2_REC_TAB_S, c_IIR2_REC_FRC_S) ; --! SQUID AMP: Filter IIR2 minus recursive part coefficients

end pkg_fir;
