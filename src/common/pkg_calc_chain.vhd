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
--!   @file                   pkg_calc_chain.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Calculus chain parameters
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

package pkg_calc_chain is

   -- ------------------------------------------------------------------------------------------------------
   --!   Calculus chain parameters: bus size
   -- ------------------------------------------------------------------------------------------------------
constant c_A_P_S              : integer := c_EP_SPI_WD_S                                                    ; --! a(p) bus size
constant c_ELP_P_S            : integer := c_EP_SPI_WD_S                                                    ; --! Elp(p) bus size
constant c_GN_S               : integer := c_EP_SPI_WD_S                                                    ; --! Input gain bus size
constant c_KI_KNORM_P_S       : integer := c_EP_SPI_WD_S                                                    ; --! ki(p)*knorm(p) bus size
constant c_KNORM_P_S          : integer := c_EP_SPI_WD_S                                                    ; --! knorm(p) bus size

constant c_A_P_FRC_S          : integer := c_A_P_S                                                          ; --! a(p) fractional part bus size
constant c_ELP_P_FRC_S        : integer := c_ELP_P_S - c_SQM_ADC_DATA_S                                     ; --! Elp(p) fractional part bus size
constant c_GN_FRC_S           : integer := 12                                                               ; --! Input gain fractional part bus size
constant c_KI_KNORM_P_FRC_S   : integer := c_KI_KNORM_P_S                                                   ; --! ki(p)*knorm(p) fractional part bus size
constant c_KNORM_P_FRC_S      : integer := 18                                                               ; --! knorm(p) fractional part bus size

constant c_FGN_P_TOT_S        : integer := (c_KI_KNORM_P_S + 1) + c_GN_S - 1                                ; --! Feedback gain(p): DSP Result total size
constant c_FGN_P_TOT_FRC_S    : integer := c_KI_KNORM_P_FRC_S + c_GN_FRC_S                                  ; --! Feedback gain(p): DSP Result total fractional part bus size
constant c_FGN_P_S            : integer := c_MULT_ALU_PORTA_S                                               ; --! Feedback gain(p): bus size
constant c_FGN_P_INT_S        : integer := c_FGN_P_TOT_S -  c_FGN_P_TOT_FRC_S                               ; --! Feedback gain(p): integer part bus size

constant c_SGN_P_TOT_S        : integer := (c_KNORM_P_S + 1) + c_GN_S - 1                                   ; --! Science gain(p): DSP Result total size
constant c_SGN_P_TOT_FRC_S    : integer := c_KNORM_P_FRC_S   + c_GN_FRC_S                                   ; --! Science gain(p): DSP Result total fractional part bus size
constant c_SGN_P_S            : integer := c_MULT_ALU_PORTA_S                                               ; --! Science gain(p): bus size
constant c_SGN_P_INT_S        : integer := c_SGN_P_TOT_S -  c_SGN_P_TOT_FRC_S                               ; --! Science gain(p): integer part bus size

constant c_ADC_SMP_AVE_SAT    : integer := c_SQM_ADC_DATA_S + c_ASP_CF_S - 1                                ; --! ADC sample average: saturation (no linear result)
constant c_ADC_SMP_AVE_S      : integer := c_MULT_ALU_PORTB_S                                               ; --! ADC sample average: bus size

constant c_M_PN_SAT           : integer := (c_FGN_P_S + c_ADC_SMP_AVE_S - 1) - (c_FGN_P_INT_S - 1)          ; --! M(p,n): saturation (no linear result)
constant c_M_PN_S             : integer := c_MULT_ALU_PORTC_S                                               ; --! M(p,n): bus size

constant c_DFB_PN_S           : integer := c_MULT_ALU_PORTA_S                                               ; --! dFB(p,n): bus size
constant c_DFB_PN_DACC_S      : integer := c_M_PN_S - c_A_P_FRC_S                                           ; --! dFB(p,n): data to accumulate bus size

constant c_PC1_PN_SAT         : integer := c_M_PN_S                                                         ; --! PC1(p,n): saturation (no linear result)
constant c_PC1_PN_S           : integer := 32                                                               ; --! PC1(p,n): bus size

constant c_FB_PN_S            : integer := c_PC1_PN_S                                                       ; --! FB(p,n): bus size

constant c_NRM_PN_SAT         : integer := (c_SGN_P_S + c_ADC_SMP_AVE_S - 1) - (c_SGN_P_INT_S - 1)          ; --! NRM(p,n): saturation (no linear result)
constant c_NRM_PN_S           : integer := c_FB_PN_S                                                        ; --! NRM(p,n): bus size

   -- ------------------------------------------------------------------------------------------------------
   --!   Calculus chain parameters: synchronization
   -- ------------------------------------------------------------------------------------------------------
constant c_MEM_ELN_RD_NPER    : integer := c_MEM_RD_DATA_NPER + 1                                           ; --! Clock period number for reading data in add/acc memory from data element n ready
constant c_MEM_PAR_NPER       : integer := c_MEM_RD_DATA_NPER + 1                                           ; --! Clock period number for getting parameter in memory from memory address update

constant c_ADC_SMP_AVE_NPER   : integer := c_DSP_NPER + 1                                                   ; --! Clock period number for ADC sample average       from SQUID MUX Data error ready
constant c_ADC_SMP_DEL_NPER   : integer := c_ADC_SMP_AVE_NPER + c_SQA_FIR_DTA_NPER                          ; --! Clock period number for ADC sample average delay from SQUID MUX Data error ready
constant c_ADC_SMP_MUX_NPER   : integer := c_ADC_SMP_DEL_NPER + 1                                           ; --! Clock period number for ADC sample multiplexer   from SQUID MUX Data error ready
constant c_ERR_SIG_NPER       : integer := c_ADC_SMP_MUX_NPER + 1                                           ; --! Clock period number for Error signal             from SQUID MUX Data error ready

constant c_DIF_E_PN_NPER      : integer := c_ADC_SMP_MUX_NPER + 1                                           ; --! Clock period number for E(p,n) - Elp(p)          from SQUID MUX Data error ready
constant c_NRM_PN_NPER        : integer := c_DIF_E_PN_NPER    + c_DSP_NPER + 1                              ; --! Clock period number for NRM(p,n)                 from SQUID MUX Data error ready
constant c_SC_PN_NPER         : integer := c_NRM_PN_NPER      + 2                                           ; --! Clock period number for SC(p,n)                  from SQUID MUX Data error ready
constant c_SC_O_PN_NPER       : integer := c_SC_PN_NPER       + 1                                           ; --! Clock period number for SC(p,n) out              from SQUID MUX Data error ready
constant c_AQMDE_SYNC_NPER    : integer := c_SC_PN_NPER       - 1                                           ; --! Clock period number for aqdme sync               from SQUID MUX Data error ready

constant c_M_PN_NPER          : integer := c_DIF_E_PN_NPER + c_DSP_NPER + 1                                 ; --! Clock period number for M(p,n)                   from SQUID MUX Data error ready
constant c_PC1_PN_NPER        : integer := c_M_PN_NPER     + c_DSP_NPER + 1                                 ; --! Clock period number for PC1(p,n)                 from SQUID MUX Data error ready
constant c_RL_ENA_NPER        : integer := c_PC1_PN_NPER   + 2                                              ; --! Clock period number for Relock enable            from SQUID MUX Data error ready
constant c_FB_PNP1_NPER       : integer := c_RL_ENA_NPER   + 2                                              ; --! Clock period number for FB(p,n+1)                from SQUID MUX Data error ready
constant c_TST_PAT_SC_NPER    : integer := 4                                                                ; --! Clock period number for test pattern on science before FB(p,n+1) elaboration

constant c_SGN_P_NPER         : integer := c_DIF_E_PN_NPER                                                  ; --! Clock period number for SGN(p)                   from SQUID MUX Data error ready
constant c_KNORM_P_NPER       : integer := c_SGN_P_NPER    - (c_DSP_NPER + 1)                               ; --! Clock period number for knorm(p)                 from SQUID MUX Data error ready
constant c_KNORM_P_SRT        : integer := c_KNORM_P_NPER  - (c_MEM_PAR_NPER + 1)                           ; --! Start memory reading: parameters knorm(p)

constant c_FGN_P_NPER         : integer := c_DIF_E_PN_NPER                                                  ; --! Clock period number for FGN(p)                   from SQUID MUX Data error ready
constant c_KIKNM_P_NPER       : integer := c_FGN_P_NPER    - (c_DSP_NPER + 1)                               ; --! Clock period number for ki(p)*knorm(p)           from SQUID MUX Data error ready
constant c_KIKNM_P_SRT        : integer := c_KIKNM_P_NPER  - (c_MEM_PAR_NPER + 1)                           ; --! Start memory reading: parameters ki(p)*knorm(p)

constant c_A_P_SRT            : integer := c_M_PN_NPER     - c_MEM_PAR_NPER                                 ; --! Start memory reading: parameters a(p)
constant c_ELP_P_SRT          : integer := c_DIF_E_PN_NPER - c_MEM_PAR_NPER - 3                             ; --! Start memory reading: parameters Elp(p)
constant c_DFB_PN_SRT         : integer := c_M_PN_NPER     - c_MEM_ELN_RD_NPER                              ; --! Start memory reading: parameters dFB(p,n)
constant c_FB_PN_SRT          : integer := c_NRM_PN_NPER   - c_MEM_ELN_RD_NPER                              ; --! Start memory reading: parameters FB(p,n)
constant c_SMFB0_P_SRT        : integer := c_RL_ENA_NPER   - c_MEM_PAR_NPER - 1                             ; --! Start memory reading: parameters smfb0
constant c_MEM_RL_RD_ADD_SRT  : integer := c_RL_ENA_NPER   - c_MEM_PAR_NPER - 3                             ; --! Start memory reading: Relock memories read address
constant c_INI_DFB_PN_SRT     : integer := c_DFB_PN_SRT    - c_MEM_PAR_NPER + 1                             ; --! Start memory reading: Initialization dFB(p,n)

constant c_DATA_ERR_RDY_R_NB  : integer := c_FB_PNP1_NPER + 1                                               ; --! Data science ready register number
constant c_ERR_SIG_R_NB       : integer := c_SC_PN_NPER    - c_ERR_SIG_NPER                                 ; --! Error signal register number

end pkg_calc_chain;
