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
--!   @file                   fir_deci.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Filter Infinite Impulse Response
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

entity iir_deci is generic (
         g_IIR_TAB_NW         : integer                                                                     ; --! Filter IIR table number word
         g_IIR_START_NB_CYC   : integer                                                                     ; --! Filter IIR number of system clock before calculation
         g_IIR_IN_COEF_S      : integer                                                                     ; --! Filter IIR input part coefficients bus size
         g_IIR_IN_COEF_FRC_S  : integer                                                                     ; --! Filter IIR input part coefficients fractionnal part bus size
         g_IIR_IN_COEF        : t_slv_arr(0 to g_IIR_TAB_NW-1)(g_IIR_IN_COEF_S-1 downto 0)                  ; --! Filter IIR input part coefficients
         g_IIR_IN_COEF_SUM_S  : integer                                                                     ; --! Filter IIR input part coefficient sum bus size
         g_IIR_IN_DATA_S      : integer                                                                     ; --! Filter IIR input part data bus size
         g_IIR_IN_DATA_SHF    : integer                                                                     ; --! Filter IIR input part data shift used by the product
         g_IIR_REC_COEF_S     : integer                                                                     ; --! Filter IIR minus recursive part coefficient bus size
         g_IIR_REC_COEF       : t_slv_arr(0 to g_IIR_TAB_NW-1)(g_IIR_REC_COEF_S-1 downto 0)                 ; --! Filter IIR minus recursive part coefficients
         g_IIR_REC_COEF_SUM_S : integer                                                                     ; --! Filter IIR minus recursive part coefficient sum bus size
         g_IIR_REC_DATA_S     : integer                                                                     ; --! Filter IIR minus recursive part data bus size
         g_IIR_REC_DATA_SHF   : integer                                                                     ; --! Filter IIR minus recursive part data shift used by the product
         g_IIR_RES_S          : integer                                                                       --! Filter IIR result bus size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_iir_init_val       : in     std_logic_vector(g_IIR_IN_DATA_S-1 downto 0)                         ; --! Filter IIR data initialization value
         i_iir_init_ena       : in     std_logic                                                            ; --! Filter IIR data initialization enable ('0' = No, '1' = Yes)
         i_iir_init_ena_fe    : in     std_logic                                                            ; --! Filter IIR data initialization enable falling edge
         i_iir_start_cond     : in     std_logic                                                            ; --! Filter IIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               : in     std_logic_vector(g_IIR_IN_DATA_S-1 downto 0)                         ; --! Data (signed)
         i_data_rdy           : in     std_logic                                                            ; --! Data ready ('0' = Inactive, '1' = Active)
         o_iir_res            : out    std_logic_vector(    g_IIR_RES_S-1 downto 0)                         ; --! Filter IIR result no decimation (signed)
         o_iir_rdy            : out    std_logic                                                              --! Filter IIR result ready ('0' = Inactive, '1' = Active)
   );
end entity iir_deci;

architecture RTL of iir_deci is
constant c_IIR_PART_DCI_VAL   : integer := 1                                                                ; --! Filter IIR: decimation value for each calculation part
constant c_IIR_TAB_POS_INIT   : integer := 0                                                                ; --! Filter IIR: table position initialization

constant c_IIR_IN_RES_INT_S   : integer := g_IIR_IN_DATA_S    + g_IIR_IN_COEF_SUM_S - g_IIR_IN_COEF_FRC_S   ; --! Filter IIR input part result, integer part bus size
constant c_IIR_REC_RES_FRC_S  : integer := g_IIR_REC_DATA_S   - g_IIR_IN_DATA_S                             ; --! Filter IIR minus recursive part result fractionnal part bus size
constant c_IIR_IN_RES_S       : integer := c_IIR_IN_RES_INT_S + c_IIR_REC_RES_FRC_S                         ; --! Filter IIR input part result bus size

signal   iir_rec_init_val     : std_logic_vector(g_IIR_REC_DATA_S-1 downto 0)                               ; --! Filter IIR: data initialization minus recursive part

signal   iir_res_in           : std_logic_vector(  c_IIR_IN_RES_S-1 downto 0)                               ; --! Filter IIR: input part result (signed)
signal   iir_res_in_rsz       : std_logic_vector(g_IIR_REC_DATA_S-1 downto 0)                               ; --! Filter IIR: input part result resized
signal   iir_res_minus_rec    : std_logic_vector(g_IIR_REC_DATA_S   downto 0)                               ; --! Filter IIR: result minus recursive part (signed)
signal   iir_res_minus_rc_rsz : std_logic_vector(g_IIR_REC_DATA_S-1 downto 0)                               ; --! Filter IIR: result minus recursive part resized
signal   iir_res_no_deci      : std_logic_vector(g_IIR_REC_DATA_S-1 downto 0)                               ; --! Filter IIR: result no decimation (signed)
signal   iir_res              : std_logic_vector(     g_IIR_RES_S   downto 0)                               ; --! Filter IIR: result no decimation
signal   iir_res_in_rdy       : std_logic                                                                   ; --! Filter IIR: input part result ready ('0' = Inactive, '1' = Active)
signal   iir_res_in_rdy_r     : std_logic                                                                   ; --! Filter IIR: input part result ready register
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         iir_res_in_rdy_r <= c_LOW_LEV;
         o_iir_rdy        <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         iir_res_in_rdy_r <= iir_res_in_rdy;
         o_iir_rdy        <= iir_res_in_rdy_r;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter Infinite Impulse Response: Input part
   -- ------------------------------------------------------------------------------------------------------
   I_iir_in: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_IIR_PART_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => g_IIR_TAB_NW         , -- integer                                          ; --! Filter FIR table number word
         g_FIR_TAB_POS_INIT   => c_IIR_TAB_POS_INIT   , -- integer                                          ; --! Filter FIR table position initialization
         g_FIR_START_NB_CYC   => g_IIR_START_NB_CYC   , -- integer                                          ; --! Filter FIR number of system clock before calculation
         g_FIR_COEF_S         => g_IIR_IN_COEF_S      , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => g_IIR_IN_COEF        , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => g_IIR_IN_COEF_SUM_S  , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => g_IIR_IN_DATA_S      , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_DATA_SHF       => g_IIR_IN_DATA_SHF    , -- integer                                          ; --! Filter FIR data shift used by the product
         g_FIR_RES_S          => c_IIR_IN_RES_S         -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => i_iir_init_val       , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => i_iir_init_ena       , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)
         i_fir_init_ena_fe    => i_iir_init_ena_fe    , -- in     std_logic                                 ; --! Filter FIR data initialization enable falling edge
         i_fir_start_cond     => i_iir_start_cond     , -- in     std_logic                                 ; --! Filter FIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => i_data               , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => i_data_rdy           , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => iir_res_in           , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => iir_res_in_rdy         -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR: data initialization minus recursive part
   -- ------------------------------------------------------------------------------------------------------
   I_iir_init_val_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => g_IIR_IN_DATA_S      , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => g_IIR_REC_DATA_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => i_iir_init_val       , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => iir_rec_init_val     , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter Infinite Impulse Response: Minus Recursive part
   -- ------------------------------------------------------------------------------------------------------
   I_iir_rec: entity work.fir_deci generic map (
         g_FIR_DCI_VAL        => c_IIR_PART_DCI_VAL   , -- integer                                          ; --! Filter FIR decimation value
         g_FIR_TAB_NW         => g_IIR_TAB_NW         , -- integer                                          ; --! Filter FIR table number word
         g_FIR_TAB_POS_INIT   => c_IIR_TAB_POS_INIT   , -- integer                                          ; --! Filter FIR table position initialization
         g_FIR_START_NB_CYC   => g_IIR_START_NB_CYC   , -- integer                                          ; --! Filter FIR number of system clock before calculation
         g_FIR_COEF_S         => g_IIR_REC_COEF_S     , -- integer                                          ; --! Filter FIR coefficient bus size
         g_FIR_COEF           => g_IIR_REC_COEF       , -- t_slv_arr g_FIR_TAB_NW g_FIR_COEF_S              ; --! Filter FIR coefficients
         g_FIR_COEF_SUM_S     => g_IIR_REC_COEF_SUM_S , -- integer                                          ; --! Filter FIR coefficient sum bus size
         g_FIR_DATA_S         => g_IIR_REC_DATA_S     , -- integer                                          ; --! Filter FIR data bus size
         g_FIR_DATA_SHF       => g_IIR_REC_DATA_SHF   , -- integer                                          ; --! Filter FIR data shift used by the product
         g_FIR_RES_S          => g_IIR_REC_DATA_S + 1   -- integer                                            --! Filter FIR result bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_fir_init_val       => iir_rec_init_val     , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Filter FIR data initialization value
         i_fir_init_ena       => i_iir_init_ena       , -- in     std_logic                                 ; --! Filter FIR data initialization enable ('0' = No, '1' = Yes)
         i_fir_init_ena_fe    => i_iir_init_ena_fe    , -- in     std_logic                                 ; --! Filter FIR data initialization enable falling edge
         i_fir_start_cond     => i_iir_start_cond     , -- in     std_logic                                 ; --! Filter FIR start calculation condition ('0' = Inactive, '1' one clk cyc. = Active)

         i_data               => iir_res_no_deci      , -- in     std_logic_vector(g_FIR_DATA_S-1 downto 0) ; --! Data (signed)
         i_data_rdy           => iir_res_in_rdy_r     , -- in     std_logic                                 ; --! Data ready ('0' = Inactive, '1' = Active)

         o_fir_res            => iir_res_minus_rec    , -- out    std_logic_vector( g_FIR_RES_S-1 downto 0) ; --! Filter FIR result (signed)
         o_fir_res_rdy        => open                   -- out    std_logic                                   --! Filter FIR result ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR: result no decimation
   -- ------------------------------------------------------------------------------------------------------
   iir_res_in_rsz       <= std_logic_vector(resize(signed(iir_res_in), iir_res_in_rsz'length));
   iir_res_minus_rc_rsz <= iir_res_minus_rec(iir_res_minus_rc_rsz'range);

   I_in_minus_rec: entity work.adder_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_S             => g_IIR_REC_DATA_S       -- integer                                            --! Data bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_fst           => iir_res_in_rsz       , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data first (signed)
         i_data_sec           => iir_res_minus_rc_rsz , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data second (signed)
         o_data_add_sat       => iir_res_no_deci        -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Data added with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR: result no decimation stall MSB
   -- ------------------------------------------------------------------------------------------------------
   I_iir_res_stall : entity work.resize_stall_msb generic map (
         g_DATA_S             => g_IIR_REC_DATA_S     , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => g_IIR_RES_S + 1        -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => iir_res_no_deci      , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => iir_res              , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Filter IIR: result no decimation
   -- ------------------------------------------------------------------------------------------------------
   I_iir_res: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => g_IIR_RES_S + 1        -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => iir_res              , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_iir_res              -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

end architecture RTL;
