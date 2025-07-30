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
--!   @file                   spi_check_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SPI check model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity spi_check_model is port (
         i_rst                : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_hk_spi_mosi        : in     std_logic                                                            ; --! HouseKeeping: SPI Master Output Slave Input
         i_hk_spi_sclk        : in     std_logic                                                            ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         i_hk_spi_cs_n        : in     std_logic                                                            ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)

         i_sqa_dac_data       : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)

         o_err_n_spi_chk      : out    t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)        --! SPI check error number:
   );
end entity spi_check_model;

architecture Behavioral of spi_check_model is
signal   spi_mosi             : std_logic_vector(c_CHK_ENA_SPI_NB-1 downto 0)                               ; --! SPI: Master Output Slave Input data
signal   spi_sclk             : std_logic_vector(c_CHK_ENA_SPI_NB-1 downto 0)                               ; --! SPI: Serial Clock
signal   spi_cs_n             : std_logic_vector(c_CHK_ENA_SPI_NB-1 downto 0)                               ; --! SPI: Chip Select
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   MOSI signals
   -- ------------------------------------------------------------------------------------------------------
   spi_mosi(c_SPIE_HK         - c_CHK_ENA_CLK_NB) <= i_hk_spi_mosi;
   spi_mosi(c_SPIE_C0_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL0);
   spi_mosi(c_SPIE_C1_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL1);
   spi_mosi(c_SPIE_C2_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL2);
   spi_mosi(c_SPIE_C3_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL3);
   spi_mosi(c_SPIE_C0_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL0);
   spi_mosi(c_SPIE_C1_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL1);
   spi_mosi(c_SPIE_C2_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL2);
   spi_mosi(c_SPIE_C3_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_data(c_COL3);

   -- ------------------------------------------------------------------------------------------------------
   --!   SCLK signals
   -- ------------------------------------------------------------------------------------------------------
   spi_sclk(c_SPIE_HK         - c_CHK_ENA_CLK_NB) <= i_hk_spi_sclk;
   spi_sclk(c_SPIE_C0_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL0);
   spi_sclk(c_SPIE_C1_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL1);
   spi_sclk(c_SPIE_C2_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL2);
   spi_sclk(c_SPIE_C3_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL3);
   spi_sclk(c_SPIE_C0_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL0);
   spi_sclk(c_SPIE_C1_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL1);
   spi_sclk(c_SPIE_C2_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL2);
   spi_sclk(c_SPIE_C3_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_sclk(c_COL3);

   -- ------------------------------------------------------------------------------------------------------
   --!   CS signals
   -- ------------------------------------------------------------------------------------------------------
   spi_cs_n(c_SPIE_HK         - c_CHK_ENA_CLK_NB) <= i_hk_spi_cs_n or i_rst;
   spi_cs_n(c_SPIE_C0_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_l_n(c_COL0);
   spi_cs_n(c_SPIE_C1_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_l_n(c_COL1);
   spi_cs_n(c_SPIE_C2_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_l_n(c_COL2);
   spi_cs_n(c_SPIE_C3_SQA_LSB - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_l_n(c_COL3);
   spi_cs_n(c_SPIE_C0_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_o_n(c_COL0);
   spi_cs_n(c_SPIE_C1_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_o_n(c_COL1);
   spi_cs_n(c_SPIE_C2_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_o_n(c_COL2);
   spi_cs_n(c_SPIE_C3_SQA_OFF - c_CHK_ENA_CLK_NB) <= i_sqa_dac_snc_o_n(c_COL3);

   -- ------------------------------------------------------------------------------------------------------
   --!   SPI check
   -- ------------------------------------------------------------------------------------------------------
   G_spi_check: for k in 0 to c_CHK_ENA_SPI_NB-1 generate
   begin

      I_spi_check: entity work.spi_check generic map (
         g_SPI_TIME_CHK       => c_SCHK(k).spi_time   , -- time_vector(0 to c_SPI_ERR_CHK_NB-3)             ; --! SPI timings to check
         g_CPOL               => c_SCHK(k).spi_cpol   , -- std_logic                                        ; --! Clock polarity
         g_STSCA              => c_SCHK(k).spi_stsca  , -- std_logic                                        ; --! SPI SCLK state when CS goes to active
         g_STSCI              => c_SCHK(k).spi_stsci    -- std_logic                                          --! SPI SCLK state when CS goes to inactive
      ) port map (
         i_spi_mosi           => spi_mosi(k)          , -- in     std_logic                                 ; --! SPI: Master Output Slave Input data
         i_spi_sclk           => spi_sclk(k)          , -- in     std_logic                                 ; --! SPI: Serial Clock
         i_spi_cs_n           => spi_cs_n(k)          , -- in     std_logic                                 ; --! SPI: Chip Select

         o_err_n_spi_chk      => o_err_n_spi_chk(k)     -- out    integer_vector(0 to c_SPI_ERR_CHK_NB-1)     --! SPI check error number:
      );

   end generate G_spi_check;

end architecture Behavioral;
