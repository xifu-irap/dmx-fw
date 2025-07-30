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
--!   @file                   science_data_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_mess.all;
use     work.pkg_science_data.all;

library std;
use std.textio.all;

entity science_data_model is generic (
         g_SIM_TIME           : time      := c_SIM_TIME_DEF                                                 ; --! Simulation time
         g_SIM_TYPE           : std_logic := c_SIM_TYPE_DEF                                                 ; --! Simulation type ('0': No regression, '1': Coupled simulation)
         g_BRD_MDL            : string    := c_BRD_MDL_DEF                                                  ; --! Board model
         g_ERR_SC_DTA_ENA     : std_logic := c_ERR_SC_DTA_ENA_DEF                                           ; --! Error science data enable ('0' = No, '1' = Yes)
         g_FRM_CNT_SC_ENA     : std_logic := c_FRM_CNT_SC_ENA_DEF                                           ; --! Frame counter science enable ('0' = No, '1' = Yes)
         g_TST_NUM            : string    := c_TST_NUM_DEF                                                    --! Test number
   ); port (
         i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_acq    : in     std_logic                                                            ; --! SQUID MUX ADC acquisition Clock
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_science_ctrl_01    : in     std_logic                                                            ; --! Science Data: Control channel 0/1
         i_science_ctrl_23    : in     std_logic                                                            ; --! Science Data: Control channel 2/3
         i_science_data       : in     t_slv_arr(0 to c_NB_COL  )(c_SC_DATA_SER_NB-1 downto 0)              ; --! Science Data: Serial Data

         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_smfbd              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFBD_COL_S-1 downto 0)            ; --! SQUID MUX feedback delay
         i_saomd              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOMD_COL_S-1 downto 0)            ; --! SQUID AMP offset MUX delay
         i_sqm_fbm_cls_lp_n   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)
         i_sw_adc_vin         : in     std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         i_sqm_adc_data       : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S-1 downto 0)              ; --! SQUID MUX ADC: Data buses
         i_sqm_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Out of range ('0' = No, '1' = under/over range)

         i_frm_cnt_sc_rst     : in     std_logic                                                            ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         i_adc_dmp_mem_add    : in     std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   : in     std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         i_science_mem_data   : in     std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! Science  memory for data compare: data
         i_adc_dmp_mem_cs     : in     std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)        ; --! Science packet type
         o_sc_pkt_err         : out    std_logic                                                              --! Science packet error ('0' = No error, '1' = Error)
   );
end entity science_data_model;

architecture Behavioral of science_data_model is
constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Memory Dump, ADC acquisition counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Memory Dump, ADC acquisition counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_MAX_VAL + 1) + 1                              ; --! Memory Dump, ADC acquisition counter: size bus (signed)

signal   mem_dump             : t_slv_arr_tab(0 to c_NB_COL-1)
                                (0 to 2**(c_DMP_CNT_S)-1)(c_SQM_ADC_DATA_S+1 downto 0)                      ; --! Multi Dual port memory dump

signal   sync_r               : std_logic_vector(c_ADC_DATA_NPER-2 downto 0)                                ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   sync_re_adc_data     : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge, synchronized on ADC data first pixel

signal   frm_cnt_sc_rst_r     : std_logic                                                                   ; --! Frame counter science reset register ('0' = Inactive, '1' = Active)

signal   mem_dump_adc_cnt_w   : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: counter words
signal   mem_dump_adc_add     : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: address
signal   mem_dump_adc_data_in : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! Memory Dump, ADC acquisition side: data in

signal   mem_dump_sc_add      : std_logic_vector(     c_DMP_CNT_S-2 downto 0)                               ; --! Memory Dump, science side: address
signal   mem_dump_sc_data_out : t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)                     ; --! Memory Dump, science side: data out

signal   science_data_ser     : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB+1 downto 0)                      ; --! Science Data: Serial Data
signal   science_data_ctrl    : t_slv_arr(0 to 1)(c_SC_DATA_SER_W_S-1 downto 0)                             ; --! Science Data: Control word
signal   science_data         : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)   ; --! Science Data: Data
signal   science_data_r       : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)   ; --! Science Data: Data register
signal   science_data_rdy     : std_logic                                                                   ; --! Science Data Ready ('0' = Inactive, '1' = Active)
signal   science_data_rdy_r   : std_logic                                                                   ; --! Science Data Ready register

signal   science_data_err     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Science data error ('0' = No error, '1' = Error)
signal   packet_end           : std_logic                                                                   ; --! Science packet end ('0' = No, '1' = Yes)

begin


   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (i_arst, i_clk_sqm_adc_acq)
   begin

      if i_arst = c_RST_LEV_ACT then
         sync_r               <= (others => c_I_SYNC_DEF);
         sync_re_adc_data     <= c_LOW_LEV;
         frm_cnt_sc_rst_r     <= c_HGH_LEV;

      elsif rising_edge(i_clk_sqm_adc_acq) then
         sync_r               <= sync_r(sync_r'high-1 downto 0) & i_sync;
         sync_re_adc_data     <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);
         frm_cnt_sc_rst_r     <= not(g_FRM_CNT_SC_ENA) or i_frm_cnt_sc_rst;

      end if;

   end process P_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC acquisition counter words
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_adc_cnt_w : process (i_arst, i_clk_sqm_adc_acq)
   begin

      if i_arst = c_RST_LEV_ACT then
         mem_dump_adc_cnt_w   <= c_MINUSONE(mem_dump_adc_cnt_w'range);

      elsif rising_edge(i_clk_sqm_adc_acq) then
         if (mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) and sync_re_adc_data) = c_HGH_LEV and i_aqmde = c_DST_AQMDE_DUMP then
            mem_dump_adc_cnt_w <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, mem_dump_adc_cnt_w'length));

         elsif mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = c_LOW_LEV then
            mem_dump_adc_cnt_w <= std_logic_vector(signed(mem_dump_adc_cnt_w) - 1);

         end if;

      end if;

   end process P_mem_dump_adc_cnt_w;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memories for Dump
   -- ------------------------------------------------------------------------------------------------------
   mem_dump_adc_add <= std_logic_vector(to_signed(c_DMP_CNT_MAX_VAL, mem_dump_adc_add'length) - signed(mem_dump_adc_cnt_w));

   G_mem_dump : for k in 0 to c_NB_COL-1 generate
   begin

      mem_dump_adc_data_in(k)(c_SQM_ADC_DATA_S-1 downto 0) <= i_sqm_adc_data(k);
      mem_dump_adc_data_in(k)(c_SQM_ADC_DATA_S)            <= i_sqm_adc_oor(k);
      mem_dump_adc_data_in(k)(c_SQM_ADC_DATA_S+1)          <= c_LOW_LEV;

      --! Memory Dump write
      P_mem_dump_w : process(i_clk_sqm_adc_acq)
      begin
         if rising_edge(i_clk_sqm_adc_acq) then
            if mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = c_LOW_LEV then
               mem_dump(k)(to_integer(unsigned(mem_dump_adc_add))) <=  mem_dump_adc_data_in(k);

           end if;
         end if;
      end process P_mem_dump_w;

      --! Memory Dump read
      P_mem_dump_r : process(i_arst, i_clk_science)
      begin
         if i_arst = c_RST_LEV_ACT then
            science_data_r(k)          <= c_ZERO(science_data_r(science_data_r'low)'range);
            mem_dump_sc_data_out(k)    <= c_ZERO(mem_dump_sc_data_out(mem_dump_sc_data_out'low)'range);

         elsif rising_edge(i_clk_science) then
            if (science_data_rdy = c_HGH_LEV) then
               science_data_r(k)       <= science_data(k);
               mem_dump_sc_data_out(k) <= mem_dump(k)(to_integer(unsigned(mem_dump_sc_add)));

            end if;
         end if;
      end process P_mem_dump_r;

   end generate G_mem_dump;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory Dump, science side: address
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_sc_add : process (i_arst, i_clk_science)
   begin

      if i_arst = c_RST_LEV_ACT then
         science_data_rdy_r   <= c_LOW_LEV;
         mem_dump_sc_add      <= c_ZERO(mem_dump_sc_add'range);

      elsif rising_edge(i_clk_science) then
         science_data_rdy_r   <= science_data_rdy;

         if packet_end = c_HGH_LEV then
            mem_dump_sc_add <= c_ZERO(mem_dump_sc_add'range);

         elsif science_data_rdy_r = c_HGH_LEV then
            mem_dump_sc_add <= std_logic_vector(unsigned(mem_dump_sc_add) + 1);

         end if;

      end if;

   end process P_mem_dump_sc_add;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data: Serial Data
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      science_data_ser((k+1)*c_SC_DATA_SER_NB-1 downto k*c_SC_DATA_SER_NB)  <= i_science_data(k);

   end generate G_column_mgt;

   science_data_ser(c_NB_COL*c_SC_DATA_SER_NB)  <= i_science_ctrl_01;
   science_data_ser(c_NB_COL*c_SC_DATA_SER_NB+1)<= i_science_ctrl_23;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data receipt
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_rx: entity work.science_data_rx port map (
         i_rst                => i_arst               , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        => i_clk_science        , -- in     std_logic                                 ; --! Science Clock

         i_science_data_ser   => science_data_ser     , -- in     slv(c_NB_COL*c_SC_DATA_SER_NB+1 downto 0) ; --! Science Data: Serial Data
         o_science_data_ctrl  => science_data_ctrl    , -- out    t_sc_data(0 to 1)                         ; --! Science Data: Control word
         o_science_data       => science_data         , -- out    t_sc_data(0 to c_NB_COL-1)                ; --! Science Data: Data
         o_science_data_rdy   => science_data_rdy       -- out    std_logic                                   --! Science Data Ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data check
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_check: entity work.science_data_check port map (
         i_rst                => i_arst               , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        => i_clk_science        , -- in     std_logic                                 ; --! Science Clock

         i_smfbd              => i_smfbd              , -- in     t_slv_arr c_NB_COL c_DFLD_SMFBD_COL_S     ; --! SQUID MUX feedback delay
         i_saomd              => i_saomd              , -- in     t_slv_arr c_NB_COL c_DFLD_SAOMD_COL_S     ; --! SQUID AMP offset MUX delay
         i_sqm_fbm_cls_lp_n   => i_sqm_fbm_cls_lp_n   , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! SQUID MUX feedback mode Closed loop ('0': Yes; '1': No)
         i_sw_adc_vin         => i_sw_adc_vin         , -- in     slv(c_SW_ADC_VIN_S-1 downto 0)            ; --! Switch ADC Voltage input

         i_frm_cnt_sc_rst     => frm_cnt_sc_rst_r     , -- in     std_logic                                 ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         i_adc_dmp_mem_add    => i_adc_dmp_mem_add    , -- in     slv(  c_MEM_SC_ADD_S-1 downto 0)          ; --! ADC Dump memory for data compare: address
         i_adc_dmp_mem_data   => i_adc_dmp_mem_data   , -- in     slv(c_SQM_ADC_DATA_S+1 downto 0)          ; --! ADC Dump memory for data compare: data
         i_science_mem_data   => i_science_mem_data   , -- in     slv c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S    ; --! Science  memory for data compare: data
         i_adc_dmp_mem_cs     => i_adc_dmp_mem_cs     , -- in     std_logic_vector(c_NB_COL-1 downto 0)     ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         i_science_data_ctrl  => science_data_ctrl(science_data_ctrl'low), -- in slv c_SC_DATA_SER_W_S      ; --! Science Data: Control word
         i_science_data       => science_data         , -- in     t_sc_data(0 to c_NB_COL-1)                ; --! Science Data: Data
         i_science_data_rdy   => science_data_rdy     , -- in     std_logic                                 ; --! Science Data Ready ('0' = Inactive, '1' = Active)

         o_science_data_err   => science_data_err       -- out    std_logic_vector(c_NB_COL-1 downto 0)       --! Science data error ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science packet check
   -- ------------------------------------------------------------------------------------------------------
   P_sc_packet_chk : process
   constant c_SIM_NAME        : string    := c_CMD_FILE_ROOT & g_TST_NUM                                    ; --! Simulation name

   variable v_err_sc_ctrl_dif : std_logic                                                                   ; --! Error science data control similar ('0' = No error, '1' = Error)
   variable v_err_sc_ctrl_ukn : std_logic                                                                   ; --! Error science data control unknown ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_start: std_logic                                                                   ; --! Error science packet start missing ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_eod  : std_logic                                                                   ; --! Error science packet end of data missing ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_size : std_logic                                                                   ; --! Error science packet size ('0' = No error, '1' = Error)
   variable v_err_sc_data     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Error science data ('0' = No error, '1' = Error)

   variable v_sc_ctrl_fst_w   : std_logic := c_LOW_LEV                                                      ; --! Science data, first control word detected ('0' = No, '1' = Yes)
   variable v_packet_tx_time  : time := c_ZERO_TIME                                                         ; --! Science packet first word transmit time
   variable v_packet_type     : line := null                                                                ; --! Science packet type
   variable v_packet_dump     : std_logic := c_LOW_LEV                                                      ; --! Science packet dump ('0' = No, '1' = Yes)
   variable v_packet_size     : integer := c_ZERO_INT                                                       ; --! Science packet size
   variable v_packet_size_exp : integer := c_MUX_FACT                                                       ; --! Science packet size expected
   variable v_packet_content  : t_line_arr(0 to c_NB_COL-1) := (others => null)                             ; --! Science packet content
   file     scd_file          : text                                                                        ; --! Science Data Result file
   begin

      -- Variable initialization
      write(v_packet_type, c_ZERO_INT);
      packet_end     <= c_HGH_LEV;
      o_sc_pkt_type  <= (others => c_SC_CTRL_DTW);
      o_sc_pkt_err   <= c_LOW_LEV;

      -- Check if science data analysis is required for unitary test
      if g_TST_NUM /= c_TST_NUM_DEF then

         -- Open Science Data Result file
         if g_SIM_TYPE = c_LOW_LEV then
            file_open(scd_file, c_DIR_ROOT_SIMU & c_DIR_RES_FILE & g_BRD_MDL & "/" & c_SIM_NAME & c_SCD_FILE_SFX, WRITE_MODE);

         else
            file_open(scd_file, c_DIR_ROOT_COSIM & c_DIR_RES_FILE & c_SIM_NAME & c_SCD_FILE_SFX, WRITE_MODE);

         end if;

         -- Check simulation time end
         while(now <= g_SIM_TIME) loop

            -- Wait a new science data
            wait until rising_edge(science_data_rdy_r) for g_SIM_TIME-now;

            -- Exit the loop in case of simulation end
            if now = g_SIM_TIME then
               exit;
            end if;

            -- Errors initialization
            v_err_sc_ctrl_dif := c_LOW_LEV;
            v_err_sc_ctrl_ukn := c_LOW_LEV;
            v_err_sc_pkt_start:= c_LOW_LEV;
            v_err_sc_pkt_eod  := c_LOW_LEV;
            v_err_sc_pkt_size := c_LOW_LEV;
            v_err_sc_data     := c_ZERO(v_err_sc_data'range);

            -- Increase science packet size
            v_packet_size := v_packet_size + 1;

            -- Check the science data controls are similar
            if science_data_ctrl(science_data_ctrl'low) /= science_data_ctrl(science_data_ctrl'high) then
               v_err_sc_ctrl_dif := c_HGH_LEV;
            end if;

            -- Get packet content
            for k in 0 to c_NB_COL-1 loop
               hwrite(v_packet_content(k), science_data(k));
               write(v_packet_content(k), ',');

            end loop;

            case science_data_ctrl(science_data_ctrl'low) is

               -- ------------------------------------------------------------------------------------------------------
               --    Case Science first data packet
               -- ------------------------------------------------------------------------------------------------------
               when c_SC_CTRL_FWS | c_SC_CTRL_TPT | c_SC_CTRL_FWD | c_SC_CTRL_FWA | c_SC_CTRL_RDV | c_SC_CTRL_DDV =>
                  if v_packet_size = c_ONE_INT then
                     sc_data_first_pkt(science_data_ctrl(science_data_ctrl'low), science_data,     packet_end,        v_sc_ctrl_fst_w,
                                       v_packet_tx_time                        , v_packet_type,    v_packet_dump,     v_packet_size,
                                       v_packet_size_exp,                        v_packet_content, v_err_sc_ctrl_ukn, v_err_sc_pkt_eod,
                                       o_sc_pkt_type);

                  else
                     sc_data_sec_pkt(science_data_ctrl(science_data_ctrl'low), v_packet_type, v_err_sc_ctrl_ukn, o_sc_pkt_type);

                  end if;

               -- ------------------------------------------------------------------------------------------------------
               --    Case Science data word
               -- ------------------------------------------------------------------------------------------------------
               when c_SC_CTRL_DTW       =>

                  -- Case End of packet
                  if v_packet_size >= v_packet_size_exp then
                     sc_data_end_pkt(v_packet_size_exp,  v_packet_content,  v_sc_ctrl_fst_w,  v_packet_tx_time,
                                     v_packet_type,      v_packet_size,     v_packet_dump,    packet_end,
                                     v_err_sc_pkt_start, v_err_sc_pkt_size, o_sc_pkt_type,    scd_file);

                  -- Case Data packet
                  else
                     -- Check start packet was sent before acquiring an another word
                     v_err_sc_pkt_start := not(v_sc_ctrl_fst_w);

                  end if;

               -- ------------------------------------------------------------------------------------------------------
               --    Case control word unknown
               -- ------------------------------------------------------------------------------------------------------
               when others                =>
                  v_err_sc_ctrl_ukn := c_HGH_LEV;

            end case;

            -- Check science data
            for k in 0 to c_NB_COL-1 loop
               if (v_packet_dump = c_HGH_LEV) and (science_data_r(k) /= std_logic_vector(resize(unsigned(mem_dump_sc_data_out(k)), science_data_r(k)'length))) then
                  v_err_sc_data(k) := c_HGH_LEV;

               end if;
            end loop;

            -- Science data error display
            sc_data_err_display( g_ERR_SC_DTA_ENA,    science_data_r,   science_data_err, mem_dump_sc_data_out,
                                v_err_sc_ctrl_dif, v_err_sc_ctrl_ukn, v_err_sc_pkt_start, v_err_sc_pkt_eod,
                                v_err_sc_pkt_size,     v_err_sc_data,       o_sc_pkt_err, scd_file);

            wait until falling_edge(science_data_rdy_r) for g_SIM_TIME-now;

         end loop;

         -- Final test status
         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);
         if o_sc_pkt_err = c_LOW_LEV then
            fprintf(none, "Simulation status             : PASS", scd_file);

         else
            fprintf(none, "Simulation status             : FAIL", scd_file);

         end if;

         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);

         -- Close file
         file_close(scd_file);

      end if;

      -- Wait simulation end
      wait;

   end process P_sc_packet_chk;

end architecture Behavioral;
