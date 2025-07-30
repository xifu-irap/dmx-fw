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
--!   @file                   DRE_DMX_UT_0290_cfg.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DRE DEMUX Unitary Test configuration file
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
configuration DRE_DMX_UT_0290_cfg of top_dmx_tb is

   for Simulation

      -- ------------------------------------------------------------------------------------------------------
      --!   Parser configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_parser : parser
         use entity work.parser generic map (
            g_SIM_TIME           => 1156000 ns            , -- time    := c_SIM_TIME_DEF                     ; --! Simulation time
            g_BRD_MDL            => "dm"                 , -- string  := c_BRD_MDL_DEF                      ; --! Board model
            g_TST_NUM            => "0290"                 -- string  := c_TST_NUM_DEF                        --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   Science data model configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_science_data_model: science_data_model
         use entity work.science_data_model generic map (
            g_SIM_TIME           => 1156000 ns            , -- time     := c_SIM_TIME_DEF                   ; --! Simulation time
            g_BRD_MDL            => "dm"                 , -- string  := c_BRD_MDL_DEF                      ; --! Board model
            g_ERR_SC_DTA_ENA     => c_ERR_SC_DTA_ENA_DEF , -- std_logic := c_ERR_SC_DTA_ENA_DEF             ; --! Error science data enable ('0' = No, '1' = Yes)
            g_FRM_CNT_SC_ENA     => c_FRM_CNT_SC_ENA_DEF , -- std_logic := c_FRM_CNT_SC_ENA_DEF             ; --! Frame counter science enable ('0' = No, '1' = Yes)
            g_TST_NUM            => "0290"                 -- string    := c_TST_NUM_DEF                      --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   EP SPI Model configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_ep_spi_model : ep_spi_model
         use entity work.ep_spi_model generic map (
            g_EP_CLK_PER         => c_EP_CLK_PER_DEF     , -- time    := c_EP_CLK_PER_DEF                   ; --! EP: System clock period (ps)
            g_EP_CLK_PER_SHIFT   => c_EP_CLK_PER_SHFT_DEF, -- time    := c_EP_CLK_PER_SHFT_DEF              ; --! EP: Clock period shift
            g_EP_N_CLK_PER_SCLK_L=> 3                    , -- integer := c_EP_SCLK_L_DEF                    ; --! EP: Number of clock period for elaborating SPI Serial Clock low  level
            g_EP_N_CLK_PER_SCLK_H=> 1                    , -- integer := c_EP_SCLK_H_DEF                    ; --! EP: Number of clock period for elaborating SPI Serial Clock high level
            g_EP_BUF_DEL         => 0 ns                   -- time    := c_EP_BUF_DEL_DEF                     --! EP: Delay introduced by buffer
         );
      end for;

   end for;

end configuration DRE_DMX_UT_0290_cfg;
