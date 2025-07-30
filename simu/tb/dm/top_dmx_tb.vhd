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
--!   @file                   top_dmx_tb.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Top level testbench (Demonstrator Model)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_mod.all;
use     work.pkg_model.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_ep_cmd.all;

entity top_dmx_tb is
end entity top_dmx_tb;

architecture Simulation of top_dmx_tb is
signal   clk_ref              : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Reference Clock
signal   clk_fpasim           : std_logic                                                                   ; --! FPASIM Clock
signal   clk_fpasim_shift     : std_logic                                                                   ; --! FPASIM Clock, 90 degrees shifted

signal   clk_sqm_adc_io       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: Clocks FPGA output
signal   clk_sqm_adc          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: Clocks
signal   clk_sqm_dac          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC: Clocks
signal   clk_science_01       : std_logic                                                                   ; --! Science Data: Clock channel 0/1
signal   clk_science_23       : std_logic                                                                   ; --! Science Data: Clock channel 2/3

signal   err_chk_rpt          : t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)            ; --! Clock check error reports
signal   err_n_spi_chk        : t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)             ; --! SPI check error number:
signal   err_num_pls_shp      : integer_vector(0 to c_NB_COL-1)                                             ; --! Pulse shaping error number

signal   brd_ref              : std_logic_vector(     c_BRD_REF_S-1 downto 0)                               ; --! Board reference
signal   brd_model            : std_logic_vector(   c_BRD_MODEL_S-1 downto 0)                               ; --! Board model
signal   sync                 : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
signal   ras_data_valid       : std_logic                                                                   ; --! RAS Data valid ('0' = No, '1' = Yes)

signal   sqm_adc_ana          : real_vector(0 to c_NB_COL-1)                                                ; --! SQUID MUX ADC: Analog
signal   sqm_adc_data         : t_slv_arr(  0 to c_NB_COL-1)(c_SQM_ADC_DATA_S-1 downto 0)                   ; --! SQUID MUX ADC: Data buses
signal   sqm_adc_oor          : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

signal   sqm_dac_data         : t_slv_arr(0 to c_NB_COL-1)(c_SQM_DAC_DATA_S-1 downto 0)                     ; --! SQUID MUX DAC: Data buses

signal   science_ctrl_01      : std_logic                                                                   ; --! Science Data: Control channel 0/1
signal   science_ctrl_23      : std_logic                                                                   ; --! Science Data: Control channel 2/3
signal   science_data         : t_slv_arr(0 to c_NB_COL  )(c_SC_DATA_SER_NB-1 downto 0)                     ; --! Science Data: Serial Data

signal   hk_spi_miso          : std_logic                                                                   ; --! HouseKeeping: SPI Master Input Slave Output
signal   hk_spi_mosi          : std_logic                                                                   ; --! HouseKeeping: SPI Master Output Slave Input
signal   hk_spi_sclk          : std_logic                                                                   ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
signal   hk_spi_cs_n          : std_logic                                                                   ; --! HouseKeeping: SPI Chip Select ('1' = Active, '1' = Inactive)
signal   hk_mux               : std_logic_vector(      c_HK_MUX_S-1 downto 0)                               ; --! HouseKeeping: Multiplexer
signal   hk_mux_ena_n         : std_logic                                                                   ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   ep_spi_mosi          : std_logic                                                                   ; --! EP: SPI Master Input Slave Output (MSB first)
signal   ep_spi_miso          : std_logic                                                                   ; --! EP: SPI Master Output Slave Input (MSB first)
signal   ep_spi_sclk          : std_logic                                                                   ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
signal   ep_spi_cs_n          : std_logic                                                                   ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sqm_adc_spi_sdio     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: SPI Serial Data In Out
signal   sqm_adc_spi_sclk     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
signal   sqm_adc_spi_cs_n     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

signal   sqm_adc_pwdn         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
signal   sqm_dac_sleep        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

signal   sqa_dac_data         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP DAC: Serial Data
signal   sqa_dac_sclk         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP DAC: Serial Clock
signal   sqa_dac_snc_l_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
signal   sqa_dac_snc_o_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
signal   sqa_dac_mux          : t_slv_arr(0 to c_NB_COL-1)(c_SQA_DAC_MUX_S-1 downto 0)                      ; --! SQUID AMP DAC: Multiplexer
signal   sqa_dac_mx_en_n      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

signal   d_rst                : std_logic                                                                   ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sqm_adc        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sqm_dac        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
signal   d_rst_sqa_mux        : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

signal   d_clk                : std_logic                                                                   ; --! Internal design: System Clock
signal   d_clk_sqm_adc_acq    : std_logic                                                                   ; --! Internal design: SQUID MUX ADC acquisition Clock
signal   d_clk_sqm_pls_shape  : std_logic                                                                   ; --! Internal design: SQUID MUX pulse shaping Clock

signal   d_aqmde              : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Internal design: Telemetry mode
signal   d_smfbd              : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)                   ; --! Internal design: SQUID MUX feedback delay
signal   d_saomd              : t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)                   ; --! Internal design: SQUID AMP offset MUX delay
signal   d_sqm_fbm_cls_lp_n   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Internal design: SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)

signal   sc_pkt_type          : t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)               ; --! Science packet type
signal   sc_pkt_err           : std_logic                                                                   ; --! Science packet error ('0' = No error, '1' = Error)

signal   ep_cmd               : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP: Command to send
signal   ep_cmd_start         : std_logic                                                                   ; --! EP: Start command transmit (one system clock pulse)
signal   ep_cmd_busy_n        : std_logic                                                                   ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)
signal   ep_cmd_ser_wd_s      : std_logic_vector(log2_ceil(c_SER_WD_MAX_S+1)-1 downto 0)                    ; --! EP: Serial word size

signal   ep_data_rx           : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! EP: Receipted data
signal   ep_data_rx_rdy       : std_logic                                                                   ; --! EP: Receipted data ready ('0' = Inactive, '1' = Active)

signal   pls_shp_fc           : integer_vector(0 to c_NB_COL-1)                                             ; --! Pulse shaping cut frequency (Hz)
signal   sw_adc_vin           : std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                                 ; --! Switch ADC Voltage input

signal   frm_cnt_sc_rst       : std_logic                                                                   ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
signal   adc_dmp_mem_add      : std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                               ; --! ADC Dump memory for data compare: address
signal   adc_dmp_mem_data     : std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                               ; --! ADC Dump memory for data compare: data
signal   science_mem_data     : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! Science  memory for data compare: data
signal   adc_dmp_mem_cs       : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

signal   squid_err_volt       : real_vector(0 to c_NB_COL-1)                                                ; --! SQUID Error voltage (Volt)
signal   sqm_dac_delta_volt   : real_vector(0 to c_NB_COL-1)                                                ; --! SQUID MUX voltage (Vin+ - Vin-) (Volt)
signal   sqa_volt             : real_vector(0 to c_NB_COL-1)                                                ; --! SQUID AMP voltage (Volt)

signal   fpa_conf_busy        : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
signal   fpa_cmd_rdy          : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM command ready ('0' = No, '1' = Yes)
signal   fpa_cmd              : t_slv_arr(0 to c_NB_COL-1)(c_FPA_CMD_S-1 downto 0)                          ; --! FPASIM command
signal   fpa_cmd_valid        : std_logic_vector(        c_NB_COL-1 downto 0)                               ; --! FPASIM command valid ('0' = No, '1' = Yes)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   DEMUX: Top level
   -- ------------------------------------------------------------------------------------------------------
   I_top_dmx_dm: entity work.top_dmx_dm port map (
         i_clk_ref            => clk_ref(c_COL0)      , -- in     std_logic                                 ; --! Reference Clock

         o_clk_sqm_adc        => clk_sqm_adc_io       , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Clock
         o_clk_sqm_dac        => clk_sqm_dac          , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Clock
         o_clk_science_01     => clk_science_01       , -- out    std_logic                                 ; --! Science Data: Clock channel 0/1
         o_clk_science_23     => clk_science_23       , -- out    std_logic                                 ; --! Science Data: Clock channel 2/3

         i_brd_ref            => brd_ref              , -- in     std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         i_brd_model          => brd_model            , -- in     std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_ras_data_valid     => ras_data_valid       , -- in     std_logic                                 ; --! RAS Data valid ('0' = No, '1' = Yes)

         i_sqm_adc_data       => sqm_adc_data         , -- in     t_slv_arr c_NB_COL c_SQM_ADC_DATA_S       ; --! SQUID MUX ADC: Data
         i_sqm_adc_oor        => sqm_adc_oor          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)
         o_sqm_dac_data       => sqm_dac_data         , -- out    t_slv_arr c_NB_COL c_SQM_DAC_DATA_S       ; --! SQUID MUX DAC: Data

         o_science_ctrl_01    => science_ctrl_01      , -- out    std_logic                                 ; --! Science Data: Control channel 0/1
         o_science_ctrl_23    => science_ctrl_23      , -- out    std_logic                                 ; --! Science Data: Control channel 2/3
         o_science_data       => science_data         , -- out    t_slv_arr c_NB_COL c_SC_DATA_SER_NB       ; --! Science Data: Serial Data

         i_hk_spi_miso        => hk_spi_miso          , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Input Slave Output
         o_hk_spi_mosi        => hk_spi_mosi          , -- out    std_logic                                 ; --! HouseKeeping: SPI Master Output Slave Input
         o_hk_spi_sclk        => hk_spi_sclk          , -- out    std_logic                                 ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         o_hk_spi_cs_n        => hk_spi_cs_n          , -- out    std_logic                                 ; --! HouseKeeping: SPI Chip Select ('1' = Active, '1' = Inactive)
         o_hk_mux             => hk_mux               , -- out    std_logic_vector(c_HK_MUX_S-1 downto 0)   ; --! HouseKeeping: Multiplexer
         o_hk_mux_ena_n       => hk_mux_ena_n         , -- out    std_logic                                 ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_ep_spi_mosi        => ep_spi_mosi          , -- in     std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         o_ep_spi_miso        => ep_spi_miso          , -- out    std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         i_ep_spi_sclk        => ep_spi_sclk          , -- in     std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         i_ep_spi_cs_n        => ep_spi_cs_n          , -- in     std_logic                                 ; --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_spi_sdio   => sqm_adc_spi_sdio     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   => sqm_adc_spi_sclk     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   => sqm_adc_spi_cs_n     , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sqm_adc_pwdn       => sqm_adc_pwdn         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_dac_sleep      => sqm_dac_sleep        , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         o_sqa_dac_data       => sqa_dac_data         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Data
         o_sqa_dac_sclk       => sqa_dac_sclk         , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Clock
         o_sqa_dac_snc_l_n    => sqa_dac_snc_l_n      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         o_sqa_dac_snc_o_n    => sqa_dac_snc_o_n      , -- out    std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_sqa_dac_mux        => sqa_dac_mux          , -- out    t_slv_arr c_NB_COL c_SQA_DAC_MUX_S        ; --! SQUID AMP DAC: Multiplexer
         o_sqa_dac_mx_en_n    => sqa_dac_mx_en_n        -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Get top level internal signals
   -- ------------------------------------------------------------------------------------------------------
   G_get_top_level_sig: if true generate
   alias td_rst               : std_logic is <<signal .top_dmx_tb.I_top_dmx_dm.rst           : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_adc_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL0).I_squid_adc_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_adc_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL1).I_squid_adc_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_adc_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL2).I_squid_adc_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_adc_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL3).I_squid_adc_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_dac_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL0).I_sqm_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_dac_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL1).I_sqm_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_dac_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL2).I_sqm_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqm_dac_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL3).I_sqm_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqa_mux_0     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL0).I_sqa_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqa_mux_1     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL1).I_sqa_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqa_mux_2     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL2).I_sqa_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_rst_sqa_mux_3     : std_logic is <<signal
                                .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL3).I_sqa_dac_mgt.rst_sqm_adc_dac_lc
                                                                                             : std_logic>>  ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
   alias td_clk               : std_logic is <<signal .top_dmx_tb.I_top_dmx_dm.clk           : std_logic>>  ; --! Internal design: System Clock
   alias td_clk_sqm_adc_acq   : std_logic is <<signal .top_dmx_tb.I_top_dmx_dm.clk_sqm_adc_dac: std_logic>> ; --! Internal design: SQUID MUX ADC acquisition Clock
   alias td_clk_sqm_pls_shape : std_logic is <<signal .top_dmx_tb.I_top_dmx_dm.clk_sqm_adc_dac: std_logic>> ; --! Internal design: SQUID MUX pulse shaping Clock
   alias td_aqmde             : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.aqmde:
                                   std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)>>                            ; --! Internal design: Telemetry mode

   alias td_smfbd_0           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL0).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_1           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL1).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_2           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL2).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay
   alias td_smfbd_3           : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL3).I_sqm_fbk_mgt.i_smfbd:
                                   std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID MUX feedback delay

   alias td_saomd_0           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL0).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_1           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL1).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_2           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL2).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay
   alias td_saomd_3           : std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.G_column_mgt(c_COL3).I_sqa_fbk_mgt.i_saomd:
                                   std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)>>                        ; --! Internal design: SQUID AMP offset MUX delay

   alias td_sqm_fbm_clslp_n   : std_logic_vector(c_NB_COL-1 downto 0) is
                                 <<signal .top_dmx_tb.I_top_dmx_dm.squid_close_mode_n:
                                   std_logic_vector(c_NB_COL-1 downto 0)>>                                  ; --! Internal design: SQUID MUX feedback mode Closed loop
   begin

      d_rst                      <= td_rst;
      d_rst_sqm_adc(c_COL0)      <= td_rst_sqm_adc_0;
      d_rst_sqm_adc(c_COL1)      <= td_rst_sqm_adc_1;
      d_rst_sqm_adc(c_COL2)      <= td_rst_sqm_adc_2;
      d_rst_sqm_adc(c_COL3)      <= td_rst_sqm_adc_3;
      d_rst_sqm_dac(c_COL0)      <= td_rst_sqm_dac_0;
      d_rst_sqm_dac(c_COL1)      <= td_rst_sqm_dac_1;
      d_rst_sqm_dac(c_COL2)      <= td_rst_sqm_dac_2;
      d_rst_sqm_dac(c_COL3)      <= td_rst_sqm_dac_3;
      d_rst_sqa_mux(c_COL0)      <= td_rst_sqa_mux_0;
      d_rst_sqa_mux(c_COL1)      <= td_rst_sqa_mux_1;
      d_rst_sqa_mux(c_COL2)      <= td_rst_sqa_mux_2;
      d_rst_sqa_mux(c_COL3)      <= td_rst_sqa_mux_3;
      d_clk                      <= td_clk;
      d_clk_sqm_adc_acq          <= td_clk_sqm_adc_acq;
      d_clk_sqm_pls_shape        <= td_clk_sqm_pls_shape;
      d_aqmde                    <= td_aqmde;
      d_smfbd(c_COL0)            <= td_smfbd_0;
      d_smfbd(c_COL1)            <= td_smfbd_1;
      d_smfbd(c_COL2)            <= td_smfbd_2;
      d_smfbd(c_COL3)            <= td_smfbd_3;
      d_saomd(c_COL0)            <= td_saomd_0;
      d_saomd(c_COL1)            <= td_saomd_1;
      d_saomd(c_COL2)            <= td_saomd_2;
      d_saomd(c_COL3)            <= td_saomd_3;
      d_sqm_fbm_cls_lp_n         <= td_sqm_fbm_clslp_n;

   end generate G_get_top_level_sig;

   -- ------------------------------------------------------------------------------------------------------
   --!   Check all clocks
   -- ------------------------------------------------------------------------------------------------------
   I_clock_check_model: entity work.clock_check_model port map (
         i_clk                => d_clk                , -- in     std_logic                                 ; --! Internal design: System Clock
         i_clk_sqm_adc_acq    => d_clk_sqm_adc_acq    , -- in     std_logic                                 ; --! Internal design: SQUID MUX ADC acquisition Clock
         i_clk_sqm_pls_shape  => d_clk_sqm_pls_shape  , -- in     std_logic                                 ; --! Internal design: SQUID MUX pulse shaping Clock
         i_c0_clk_sqm_adc     => clk_sqm_adc(c_COL0)  , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 0: Clock
         i_c1_clk_sqm_adc     => clk_sqm_adc(c_COL1)  , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 1: Clock
         i_c2_clk_sqm_adc     => clk_sqm_adc(c_COL2)  , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 2: Clock
         i_c3_clk_sqm_adc     => clk_sqm_adc(c_COL3)  , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 3: Clock
         i_c0_clk_sqm_dac     => clk_sqm_dac(c_COL0)  , -- in     std_logic                                 ; --! SQUID MUX DAC, col. 0: Clock
         i_c1_clk_sqm_dac     => clk_sqm_dac(c_COL1)  , -- in     std_logic                                 ; --! SQUID MUX DAC, col. 1: Clock
         i_c2_clk_sqm_dac     => clk_sqm_dac(c_COL2)  , -- in     std_logic                                 ; --! SQUID MUX DAC, col. 2: Clock
         i_c3_clk_sqm_dac     => clk_sqm_dac(c_COL3)  , -- in     std_logic                                 ; --! SQUID MUX DAC, col. 3: Clock
         i_clk_science_01     => clk_science_01       , -- in     std_logic                                 ; --! Science Data: Clock channel 0/1
         i_clk_science_23     => clk_science_23       , -- in     std_logic                                 ; --! Science Data: Clock channel 2/3

         i_rst                => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_c0_sqm_adc_pwdn    => sqm_adc_pwdn(c_COL0) , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 0: Power Down ('0' = Inactive, '1' = Active)
         i_c1_sqm_adc_pwdn    => sqm_adc_pwdn(c_COL1) , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 1: Power Down ('0' = Inactive, '1' = Active)
         i_c2_sqm_adc_pwdn    => sqm_adc_pwdn(c_COL2) , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 2: Power Down ('0' = Inactive, '1' = Active)
         i_c3_sqm_adc_pwdn    => sqm_adc_pwdn(c_COL3) , -- in     std_logic                                 ; --! SQUID MUX ADC, col. 3: Power Down ('0' = Inactive, '1' = Active)
         i_c0_sqm_dac_sleep   => sqm_dac_sleep(c_COL0), -- in     std_logic                                 ; --! SQUID MUX DAC, col. 0: Sleep ('0' = Inactive, '1' = Active)
         i_c1_sqm_dac_sleep   => sqm_dac_sleep(c_COL1), -- in     std_logic                                 ; --! SQUID MUX DAC, col. 1: Sleep ('0' = Inactive, '1' = Active)
         i_c2_sqm_dac_sleep   => sqm_dac_sleep(c_COL2), -- in     std_logic                                 ; --! SQUID MUX DAC, col. 2: Sleep ('0' = Inactive, '1' = Active)
         i_c3_sqm_dac_sleep   => sqm_dac_sleep(c_COL3), -- in     std_logic                                 ; --! SQUID MUX DAC, col. 3: Sleep ('0' = Inactive, '1' = Active)

         o_err_chk_rpt        => err_chk_rpt            -- out    t_int_arr_tab c_CHK_ENA_CLK_NB              --! Clock check error reports
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Check SPI bus
   -- ------------------------------------------------------------------------------------------------------
   I_spi_check_model: entity work.spi_check_model port map (
         i_rst                => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_hk_spi_mosi        => hk_spi_mosi          , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Output Slave Input
         i_hk_spi_sclk        => hk_spi_sclk          , -- in     std_logic                                 ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         i_hk_spi_cs_n        => hk_spi_cs_n          , -- in     std_logic                                 ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         i_sqa_dac_data       => sqa_dac_data         , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       => sqa_dac_sclk         , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    => sqa_dac_snc_l_n      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    => sqa_dac_snc_o_n      , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID AMP DAC, col. 0: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         o_err_n_spi_chk      => err_n_spi_chk          -- out    t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)      --! SPI check error number:
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   FPASIM clock reference generation
   -- ------------------------------------------------------------------------------------------------------
   I_clock_model: entity work.clock_model generic map (
         g_CLK_REF_PER        => c_CLK_FPA_PER_DEF    , -- time    := c_CLK_REF_PER_DEF                     ; --! Reference Clock period
         g_SYNC_PER           => c_SYNC_PER_DEF       , -- time    := c_SYNC_PER_DEF                        ; --! Pixel sequence synchronization period
         g_SYNC_SHIFT         => c_SYNC_SHIFT_DEF       -- time    := c_SYNC_SHIFT_DEF                        --! Pixel sequence synchronization shift
   ) port map (
         o_clk_ref            => clk_fpasim           , -- out    std_logic                                 ; --! Reference Clock
         o_sync               => open                   -- out    std_logic                                   --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );

   clk_fpasim_shift <= transport clk_fpasim after c_CLK_FPA_SHIFT when now > c_CLK_FPA_SHIFT else c_LOW_LEV;

   -- ------------------------------------------------------------------------------------------------------
   --!   Housekeeping model
   -- ------------------------------------------------------------------------------------------------------
   I_hk_model: hk_model port map (
         i_hk_mux             => hk_mux               , -- in     std_logic_vector(c_HK_MUX_S-1 downto 0)   ; --! HouseKeeping: Multiplexer
         i_hk_mux_ena_n       => hk_mux_ena_n         , -- in     std_logic                                 ; --! HouseKeeping: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_hk_spi_mosi        => hk_spi_mosi          , -- in     std_logic                                 ; --! HouseKeeping: SPI Master Output Slave Input
         i_hk_spi_sclk        => hk_spi_sclk          , -- in     std_logic                                 ; --! HouseKeeping: SPI Serial Clock (CPOL = '1', CPHA = '1')
         i_hk_spi_cs_n        => hk_spi_cs_n          , -- in     std_logic                                 ; --! HouseKeeping: SPI Chip Select ('0' = Active, '1' = Inactive)
         o_hk_spi_miso        => hk_spi_miso            -- out    std_logic                                   --! HouseKeeping: SPI Master Input Slave Output
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   EP SPI model
   -- ------------------------------------------------------------------------------------------------------
   I_ep_spi_model: ep_spi_model port map (
         i_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- in     slv log2_ceil(c_SER_WD_MAX_S+1)           ; --! EP: Serial word size
         i_ep_cmd_start       => ep_cmd_start         , -- in     std_logic                                 ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd             => ep_cmd               , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Command to send
         o_ep_cmd_busy_n      => ep_cmd_busy_n        , -- out    std_logic                                 ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)

         o_ep_data_rx         => ep_data_rx           , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Receipted data
         o_ep_data_rx_rdy     => ep_data_rx_rdy       , -- out    std_logic                                 ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)

         o_ep_spi_mosi        => ep_spi_mosi          , -- out    std_logic                                 ; --! EP: SPI Master Input Slave Output (MSB first)
         i_ep_spi_miso        => ep_spi_miso          , -- in     std_logic                                 ; --! EP: SPI Master Output Slave Input (MSB first)
         o_ep_spi_sclk        => ep_spi_sclk          , -- out    std_logic                                 ; --! EP: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_ep_spi_cs_n        => ep_spi_cs_n            -- out    std_logic                                   --! EP: SPI Chip Select ('0' = Active, '1' = Inactive)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX/SQUID AMP model
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      clk_sqm_adc(k) <= transport clk_sqm_adc_io(k) after c_CLK_ADC_IO_DEL when now > c_CLK_ADC_IO_DEL else c_LOW_LEV;

      I_squid_model: squid_model port map (
         i_arst               => d_rst                , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_clk_sqm_adc        => clk_sqm_adc(k)       , -- in     std_logic                                 ; --! SQUID MUX ADC: Clock
         i_sqm_adc_pwdn       => sqm_adc_pwdn(k)      , -- in     std_logic                                 ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         o_sqm_adc_spi_sdio   => sqm_adc_spi_sdio(k)  , -- out    std_logic                                 ; --! SQUID MUX ADC: SPI Serial Data In Out
         i_sqm_adc_spi_sclk   => sqm_adc_spi_sclk(k)  , -- in     std_logic                                 ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')

         i_sw_adc_vin         => sw_adc_vin           , -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input
         o_sqm_adc_ana        => sqm_adc_ana(k)       , -- out    real                                      ; --! SQUID MUX ADC: Analog
         o_sqm_adc_data       => sqm_adc_data(k)      , -- out    slv(c_SQM_ADC_DATA_S-1 downto 0)          ; --! SQUID MUX ADC: Data
         o_sqm_adc_oor        => sqm_adc_oor(k)       , -- out    std_logic                                 ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

         i_pls_shp_fc         => pls_shp_fc(k)        , -- in     integer                                   ; --! Pulse shaping cut frequency (Hz)
         o_err_num_pls_shp    => err_num_pls_shp(k)   , -- out    integer                                   ; --! Pulse shaping error number

         i_sqm_data_comp      => c_SQM_DATA_COMP(k)   , -- in     std_logic                                 ; --! SQUID MUX data complemented ('0' = No, '1' = Yes)
         i_clk_sqm_dac        => clk_sqm_dac(k)       , -- in     std_logic                                 ; --! SQUID MUX DAC: Clock
         i_sqm_dac_data       => sqm_dac_data(k)      , -- in     slv(c_SQM_DAC_DATA_S-1 downto 0)          ; --! SQUID MUX DAC: Data
         i_sqm_dac_sleep      => sqm_dac_sleep(k)     , -- in     std_logic                                 ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         i_sqa_dac_data       => sqa_dac_data(k)      , -- in     std_logic                                 ; --! SQUID AMP DAC: Serial Data
         i_sqa_dac_sclk       => sqa_dac_sclk(k)      , -- in     std_logic                                 ; --! SQUID AMP DAC: Serial Clock
         i_sqa_dac_snc_l_n    => sqa_dac_snc_l_n(k)   , -- in     std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC LSB ('0' = Active, '1' = Inactive)
         i_sqa_dac_snc_o_n    => sqa_dac_snc_o_n(k)   , -- in     std_logic                                 ; --! SQUID AMP DAC: Frame Synchronization DAC Offset ('0' = Active, '1' = Inactive)
         i_sqa_dac_mux        => sqa_dac_mux(k)       , -- in     slv( c_SQA_DAC_MUX_S-1 downto 0)          ; --! SQUID AMP DAC: Multiplexer
         i_sqa_dac_mx_en_n    => sqa_dac_mx_en_n(k)   , -- in     std_logic                                 ; --! SQUID AMP DAC: Multiplexer Enable ('0' = Active, '1' = Inactive)

         i_squid_err_volt     => squid_err_volt(k)    , -- in     real                                      ; --! SQUID Error voltage (Volt)
         o_sqm_dac_delta_volt => sqm_dac_delta_volt(k), -- out    real                                      ; --! SQUID MUX voltage (Vin+ - Vin-) (Volt)
         o_sqa_volt           => sqa_volt(k)            -- out    real                                        --! SQUID AMP voltage (Volt)
      );

   -- ------------------------------------------------------------------------------------------------------
   --!   FPASIM model management
   -- ------------------------------------------------------------------------------------------------------
      I_fpasim_model: fpga_system_fpasim_top port map (
         i_make_pulse_valid   => fpa_cmd_valid(k)     , -- in     std_logic                                 ; --! FPASIM command valid ('0' = No, '1' = Yes)
         i_make_pulse         => fpa_cmd(k)           , -- in     std_logic_vector(c_FPA_CMD_S-1 downto 0)  ; --! FPASIM command
         o_auto_conf_busy     => fpa_conf_busy(k)     , -- out    std_logic                                 ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         o_ready              => fpa_cmd_rdy(k)       , -- out    std_logic                                 ; --! FPASIM command ready ('0' = No, '1' = Yes)

         i_adc_clk_phase      => clk_fpasim_shift     , -- in     std_logic                                 ; --! FPASIM ADC 90 degrees shifted clock
         i_adc_clk            => clk_fpasim           , -- in     std_logic                                 ; --! FPASIM ADC clock
         i_adc0_real          => sqm_dac_delta_volt(k), -- in     real                                      ; --! FPASIM ADC Analog Squid MUX
         i_adc1_real          => sqa_volt(k)          , -- in     real                                      ; --! FPASIM ADC Analog Squid AMP

         o_clk_ref_p          => clk_ref(k)           , -- out    std_logic                                 ; --! Diff. Reference Clock
         o_clk_ref_n          => open                 , -- out    std_logic                                 ; --! Diff. Reference Clock
         o_clk_frame_p        => sync(k)              , -- out    std_logic                                 ; --! Diff. pixel sequence sync. (R.E. detected = position sequence to the first pixel)
         o_clk_frame_n        => open                 , -- out    std_logic                                 ; --! Diff. pixel sequence sync. (R.E. detected = position sequence to the first pixel)

         o_dac_real_valid     => open                 , -- out    std_logic                                 ; --! FPASIM DAC Error valid ('0' = No, '1' = Yes)
         o_dac_real           => squid_err_volt(k)      -- out    real                                        --! FPASIM DAC Analog Error
      );

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Model
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_model: science_data_model port map (
         i_arst               => d_rst                , -- in     std_logic                                 ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_acq    => d_clk_sqm_adc_acq    , -- in     std_logic                                 ; --! SQUID MUX ADC acquisition Clock
         i_clk_science        => clk_science_01       , -- in     std_logic                                 ; --! Science Clock

         i_science_ctrl_01    => science_ctrl_01      , -- in     std_logic                                 ; --! Science Data: Control channel 0/1
         i_science_ctrl_23    => science_ctrl_23      , -- in     std_logic                                 ; --! Science Data: Control channel 2/3
         i_science_data       => science_data         , -- in     t_slv_arr c_NB_COL+1 c_SC_DATA_SER_NB     ; --! Science Data: Serial Data

         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_aqmde              => d_aqmde              , -- in     t_slv_arr c_NB_COL c_DFLD_AQMDE_S         ; --! Telemetry mode
         i_smfbd              => d_smfbd              , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBD_COL_S     ; --! SQUID MUX feedback delay
         i_saomd              => d_saomd              , -- in     t_slv_arr c_NB_COL c_DFLD_SAOMD_COL_S     ; --! SQUID AMP offset MUX delay
         i_sqm_fbm_cls_lp_n   => d_sqm_fbm_cls_lp_n   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)
         i_sw_adc_vin         => sw_adc_vin           , -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_sqm_adc_data       => sqm_adc_data         , -- in     t_slv_arr c_NB_COL c_SQM_ADC_DATA_S       ; --! SQUID MUX ADC: Data buses
         i_sqm_adc_oor        => sqm_adc_oor          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

         i_frm_cnt_sc_rst     => frm_cnt_sc_rst       , -- in     std_logic                                 ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         i_adc_dmp_mem_add    => adc_dmp_mem_add      , -- in     slv(  c_MEM_SC_ADD_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   => adc_dmp_mem_data     , -- in     slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         i_science_mem_data   => science_mem_data     , -- in     slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Science  memory for data compare: data
         i_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- in     std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_sc_pkt_type        => sc_pkt_type          , -- out    t_slv_arr c_SC_PKT_W_NB c_SC_DATA_SER_W_S ; --! Science packet type
         o_sc_pkt_err         => sc_pkt_err             -- out    std_logic                                   --! Science packet error ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser
   -- ------------------------------------------------------------------------------------------------------
   I_parser: parser port map (
         o_arst_n             => open                 , -- out    std_logic                                 ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            => clk_ref(c_COL0)      , -- in     std_logic                                 ; --! Reference Clock
         i_sync               => sync(c_COL0)         , -- in     std_logic                                 ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        => err_chk_rpt          , -- in     t_int_arr_tab c_CHK_ENA_CLK_NB            ; --! Clock check error reports
         i_err_n_spi_chk      => err_n_spi_chk        , -- in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)    ; --! SPI check error number:
         i_err_num_pls_shp    => err_num_pls_shp      , -- in     integer_vector(0 to c_NB_COL-1)           ; --! Pulse shaping error number

         i_sqm_adc_pwdn       => sqm_adc_pwdn         , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         i_sqm_adc_ana        => sqm_adc_ana          , -- in     real_vector(0 to c_NB_COL-1)              ; --! SQUID MUX ADC: Analog
         i_sqm_dac_sleep      => sqm_dac_sleep        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              => d_rst                , -- in     std_logic                                 ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_adc      => d_rst_sqm_adc        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_dac      => d_rst_sqm_dac        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqa_mux      => d_rst_sqa_mux        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              => d_clk                , -- in     std_logic                                 ; --! Internal design: System Clock
         i_d_clk_sqm_adc_acq  => d_clk_sqm_adc_acq    , -- in     std_logic                                 ; --! Internal design: SQUID MUX ADC acquisition Clock
         i_d_clk_sqm_pls_shap => d_clk_sqm_pls_shape  , -- in     std_logic                                 ; --! Internal design: SQUID MUX pulse shaping Clock

         i_clk_sqm_adc        => clk_sqm_adc          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX ADC: Clock
         i_clk_sqm_dac        => clk_sqm_dac          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX DAC: Clock
         i_clk_science_01     => clk_science_01       , -- in     std_logic                                 ; --! Science Data: Clock channel 0/1
         i_clk_science_23     => clk_science_23       , -- in     std_logic                                 ; --! Science Data: Clock channel 2/3

         i_sc_pkt_type        => sc_pkt_type          , -- in     t_slv_arr c_SC_PKT_W_NB c_SC_DATA_SER_W_S ; --! Science packet type
         i_sc_pkt_err         => sc_pkt_err           , -- out    std_logic                                 ; --! Science packet error ('0' = No error, '1' = Error)

         i_ep_data_rx         => ep_data_rx           , -- in     std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Receipted data
         i_ep_data_rx_rdy     => ep_data_rx_rdy       , -- in     std_logic                                 ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             => ep_cmd               , -- out    std_logic_vector(c_EP_CMD_S-1 downto 0)   ; --! EP: Command to send
         o_ep_cmd_start       => ep_cmd_start         , -- out    std_logic                                 ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      => ep_cmd_busy_n        , -- in     std_logic                                 ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    => ep_cmd_ser_wd_s      , -- out    slv log2_ceil(c_SER_WD_MAX_S+1)           ; --! EP: Serial word size

         o_brd_ref            => brd_ref              , -- out    std_logic_vector(  c_BRD_REF_S-1 downto 0); --! Board reference
         o_brd_model          => brd_model            , -- out    std_logic_vector(c_BRD_MODEL_S-1 downto 0); --! Board model
         o_ras_data_valid     => ras_data_valid       , -- out    std_logic                                 ; --! RAS Data valid ('0' = No, '1' = Yes)

         o_frm_cnt_sc_rst     => frm_cnt_sc_rst       , -- out    std_logic                                 ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         o_adc_dmp_mem_add    => adc_dmp_mem_add      , -- out    slv(  c_MEM_SC_ADD_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         o_adc_dmp_mem_data   => adc_dmp_mem_data     , -- out    slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         o_science_mem_data   => science_mem_data     , -- out    slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Science  memory for data compare: data
         o_adc_dmp_mem_cs     => adc_dmp_mem_cs       , -- out    std_logic                                 ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_pls_shp_fc         => pls_shp_fc           , -- out    integer_vector(0 to c_NB_COL-1)           ; --! Pulse shaping cut frequency (Hz)
         o_sw_adc_vin         => sw_adc_vin           , -- out    slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_fpa_conf_busy      => fpa_conf_busy        , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         i_fpa_cmd_rdy        => fpa_cmd_rdy          , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! FPASIM command ready ('0' = No, '1' = Yes)
         o_fpa_cmd            => fpa_cmd              , -- out    t_slv_arr(0 to c_NB_COL-1)                ; --! FPASIM command
         o_fpa_cmd_valid      => fpa_cmd_valid          -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! FPASIM command valid ('0' = No, '1' = Yes)
   );

end Simulation;
