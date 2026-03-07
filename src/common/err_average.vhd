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
--!   @file                   err_average.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Error average
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_calc_chain.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity err_average is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_adc_ena            : in     std_logic                                                            ; --! ADC enable ('0' = Inactive, '1' = Active)
         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging
         i_sqm_adc_pwdn       : in     std_logic                                                            ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_sqm_data_err       : in     std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error
         i_sqm_data_err_frst  : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_aqmde_sync         : out    std_logic_vector(c_DFLD_AQMDE_S-1  downto 0)                         ; --! Telemetry mode, sync. on first pixel
         o_adc_smp_ave        : out    std_logic_vector(c_ADC_SMP_AVE_S-1 downto 0)                           --! ADC sample average (signed) (bus size result +1 bit for rounding)
   );
end entity err_average;

architecture RTL of err_average is
signal   sqm_data_err_frst_r  : std_logic_vector(c_AQMDE_SYNC_NPER downto 0)                                ; --! SQUID MUX Data science first pixel register
signal   sqm_data_err_rdy_r   : std_logic_vector(c_AQMDE_SYNC_NPER downto 0)                                ; --! SQUID MUX Data science ready register

signal   sqm_adc_ena          : std_logic                                                                   ; --! ADC enable ('0'= No, '1'= Yes)
signal   bxlgt_sync           : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                             ; --! ADC sample number for averaging, sync. on first pixel

signal   sqm_data_err         : std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                               ; --! SQUID MUX Data error

signal   adc_smp_ave_coef     : std_logic_vector(c_ASP_CF_S       downto 0)                                 ; --! ADC sample number for averaging coefficient (signed)
signal   adc_smp_ave          : std_logic_vector(c_ADC_SMP_AVE_S  downto 0)                                 ; --! ADC sample average (signed) (bus size result +1 bit for rounding)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_data_err_frst_r  <= (others => c_LOW_LEV);
         sqm_data_err_rdy_r   <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         sqm_data_err_frst_r  <= sqm_data_err_frst_r(sqm_data_err_frst_r'high-1 downto 0) & i_sqm_data_err_frst;
         sqm_data_err_rdy_r   <= sqm_data_err_rdy_r( sqm_data_err_rdy_r'high-1  downto 0) & i_sqm_data_err_rdy;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers sync. on first pixel
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_adc_ena  <= c_LOW_LEV;
         o_aqmde_sync <= c_EP_CMD_DEF_AQMDE;
         bxlgt_sync   <= c_EP_CMD_DEF_BXLGT;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_frst_r(c_AQMDE_SYNC_NPER) and sqm_data_err_rdy_r(c_AQMDE_SYNC_NPER)) = c_HGH_LEV then
            o_aqmde_sync <= i_aqmde;

         end if;

         if (i_sqm_data_err_frst and i_sqm_data_err_rdy) = c_HGH_LEV then
            sqm_adc_ena <= i_adc_ena and not(i_sqm_adc_pwdn);

         end if;

         if sqm_adc_ena = c_LOW_LEV then
            bxlgt_sync <= c_EP_CMD_DEF_BXLGT;

         elsif (i_sqm_data_err_frst and i_sqm_data_err_rdy) = c_HGH_LEV then
            bxlgt_sync <= i_bxlgt;

         end if;

      end if;

   end process P_reg_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data error
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_err : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_data_err <= std_logic_vector(resize(signed(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

      elsif rising_edge(i_clk) then
         if sqm_adc_ena = c_HGH_LEV then
            sqm_data_err <= std_logic_vector(resize(signed(i_sqm_data_err), sqm_data_err'length));

         else
            sqm_data_err <= std_logic_vector(resize(signed(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

         end if;

      end if;

   end process P_sqm_data_err;

   -- ------------------------------------------------------------------------------------------------------
   --!   Get ADC sample number for averaging coefficient from table
   --    @Req : DRE-DMX-FW-REQ-0145
   -- ------------------------------------------------------------------------------------------------------
   P_adc_smp_ave_coef : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         adc_smp_ave_coef <= std_logic_vector(resize(unsigned(c_ADC_SMP_AVE_TAB(to_integer(unsigned(c_EP_CMD_DEF_BXLGT)))), adc_smp_ave_coef'length));

      elsif rising_edge(i_clk) then
         adc_smp_ave_coef <= std_logic_vector(resize(unsigned(c_ADC_SMP_AVE_TAB(to_integer(unsigned(bxlgt_sync)))), adc_smp_ave_coef'length));

      end if;

   end process P_adc_smp_ave_coef;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average, E(p,n) (bus size result +1 bit for rounding)
   --    @Req : DRE-DMX-FW-REQ-0140
   -- ------------------------------------------------------------------------------------------------------
   I_adc_smp_ave: entity work.dsp generic map (
         g_PORTA_S            => c_ASP_CF_S+1         , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_ADC_SMP_AVE_S + 1  , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_DIS  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_ADC_SMP_AVE_SAT    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => adc_smp_ave_coef     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => sqm_data_err         , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_SQM_DATA_ERR_S-1 downto 0),    -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_SQM_DATA_ERR_S-1 downto 0),    -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => adc_smp_ave          , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_adc_smp_ave_rd_sat: entity work.round_sat generic map (
         g_RST_LEV_ACT        => c_RST_LEV_ACT        , -- std_logic                                        ; --! Reset level activation value
         g_DATA_CARRY_S       => c_ADC_SMP_AVE_S+1      -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => adc_smp_ave          , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_adc_smp_ave          -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

end architecture RTL;
