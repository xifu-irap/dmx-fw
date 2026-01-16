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
--!   @file                   pkg_science_data.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package science data
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;

library std;
use std.textio.all;

package pkg_science_data is

   -- ------------------------------------------------------------------------------------------------------
   --! Science first data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_first_pkt (
         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science Data: Control word
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
signal   b_packet_end         : inout  std_logic                                                            ; --  Science packet end ('0' = No, '1' = Yes)
         o_sc_ctrl_fst_w      : out    std_logic                                                            ; --  Science data, first control word detected ('0' = No, '1' = Yes)
         o_packet_tx_time     : out    time                                                                 ; --  Science packet first word transmit time
         o_packet_type        : out    line                                                                 ; --  Science packet type
         o_packet_dump        : out    std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
         o_packet_size        : out    integer                                                              ; --  Science packet size
         o_packet_size_exp    : out    integer                                                              ; --  Science packet size expected
         o_packet_content     : out    t_line_arr(0 to c_NB_COL-1)                                          ; --  Science packet content
         o_err_sc_ctrl_ukn    : out    std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         o_err_sc_pkt_eod     : out    std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)          --  Science packet type
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Science second data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_sec_pkt (
         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science Data: Control word
         b_packet_type        : inout  line                                                                 ; --  Science packet type
         o_err_sc_ctrl_ukn    : out    std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)          --  Science packet type
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Science end of data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_end_pkt (
         i_packet_size_exp    : in     integer                                                              ; --  Science packet size expected
         b_packet_content     : inout  t_line_arr(0 to c_NB_COL-1)                                          ; --  Science packet content
         b_sc_ctrl_fst_w      : inout  std_logic                                                            ; --  Science data, first control word detected ('0' = No, '1' = Yes)
         b_packet_tx_time     : inout  time                                                                 ; --  Science packet first word transmit time
         b_packet_type        : inout  line                                                                 ; --  Science packet type
         b_packet_size        : inout  integer                                                              ; --  Science packet size
         o_packet_dump        : out    std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
signal   o_packet_end         : out    std_logic                                                            ; --  Science packet end ('0' = No, '1' = Yes)
         o_err_sc_pkt_start   : out    std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         o_err_sc_pkt_size    : out    std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)        ; --  Science packet type
         file scd_file        : text                                                                          --  Science Data Result file
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Science data error display
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_err_display (
         i_packet_dump        : in     std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
         i_err_sc_dta_ena     : in     std_logic                                                            ; --  Error science data enable ('0' = No, '1' = Yes)
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
         i_science_data_err   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Science data error ('0' = No error, '1' = Error)
         i_mem_dmp_sc_dta_out : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --  Memory Dump, science side: data out
         i_err_sc_ctrl_dif    : in     std_logic                                                            ; --  Error science data control similar ('0' = No error, '1' = Error)
         i_err_sc_ctrl_ukn    : in     std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         i_err_sc_pkt_start   : in     std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_eod     : in     std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_size    : in     std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
signal   o_sc_pkt_err         : out    std_logic                                                            ; --  Science packet error ('0' = No error, '1' = Error)
         file scd_file        : text                                                                          --  Science Data Result file
   );

end pkg_science_data;

package body pkg_science_data is

   -- ------------------------------------------------------------------------------------------------------
   --! Science first data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_first_pkt (
         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science Data: Control word
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
signal   b_packet_end         : inout  std_logic                                                            ; --  Science packet end ('0' = No, '1' = Yes)
         o_sc_ctrl_fst_w      : out    std_logic                                                            ; --  Science data, first control word detected ('0' = No, '1' = Yes)
         o_packet_tx_time     : out    time                                                                 ; --  Science packet first word transmit time
         o_packet_type        : out    line                                                                 ; --  Science packet type
         o_packet_dump        : out    std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
         o_packet_size        : out    integer                                                              ; --  Science packet size
         o_packet_size_exp    : out    integer                                                              ; --  Science packet size expected
         o_packet_content     : out    t_line_arr(0 to c_NB_COL-1)                                          ; --  Science packet content
         o_err_sc_ctrl_ukn    : out    std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         o_err_sc_pkt_eod     : out    std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)          --  Science packet type
   ) is
   begin

      o_sc_ctrl_fst_w   := c_HGH_LEV;
      o_packet_tx_time  := now - (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S+1)*c_CLK_SC_HPER;
      o_packet_size     := c_ONE_INT;

      if i_science_data_ctrl = c_SC_CTRL_FWD then
         o_packet_dump     := c_HGH_LEV;
         o_packet_size_exp := c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC;
      else
         o_packet_dump     := c_LOW_LEV;
         o_packet_size_exp := c_MUX_FACT;
      end if;

      o_sc_pkt_type(o_sc_pkt_type'low) <= i_science_data_ctrl;

      o_packet_type     := null;
      hwrite(o_packet_type, i_science_data_ctrl);

      -- Reinitialize and get packet content
      o_packet_content := (others => null);

      for k in 0 to c_NB_COL-1 loop
         hwrite(o_packet_content(k), i_science_data(k));
         write(o_packet_content(k), ',');

      end loop;

      -- Check science data control on first position
      if i_science_data_ctrl = c_SC_CTRL_FWD or i_science_data_ctrl = c_SC_CTRL_FWS or i_science_data_ctrl = c_SC_CTRL_FWA or i_science_data_ctrl = c_SC_CTRL_TPT then
         o_err_sc_ctrl_ukn := c_LOW_LEV;

      else
         o_err_sc_ctrl_ukn := c_HGH_LEV;

      end if;

      -- Check end of data control word was sent before acquiring a new packet
      o_err_sc_pkt_eod  := not(b_packet_end);

      -- Reinitialize packet end
      b_packet_end <= c_LOW_LEV;

   end sc_data_first_pkt;

   -- ------------------------------------------------------------------------------------------------------
   --! Science second data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_sec_pkt (
         i_science_data_ctrl  : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science Data: Control word
         b_packet_type        : inout  line                                                                 ; --  Science packet type
         o_err_sc_ctrl_ukn    : out    std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)          --  Science packet type
   ) is
   begin

      -- Check science data control on second position
      if i_science_data_ctrl = c_SC_CTRL_TPT or i_science_data_ctrl = c_SC_CTRL_RDV or i_science_data_ctrl = c_SC_CTRL_DDV then
         o_err_sc_ctrl_ukn := c_LOW_LEV;

      else
         o_err_sc_ctrl_ukn := c_HGH_LEV;

      end if;

      o_sc_pkt_type(o_sc_pkt_type'high) <= i_science_data_ctrl;

      write(b_packet_type, '/');
      hwrite(b_packet_type, i_science_data_ctrl);

   end sc_data_sec_pkt;

   -- ------------------------------------------------------------------------------------------------------
   --! Science end of data packet
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_end_pkt (
         i_packet_size_exp    : in     integer                                                              ; --  Science packet size expected
         b_packet_content     : inout  t_line_arr(0 to c_NB_COL-1)                                          ; --  Science packet content
         b_sc_ctrl_fst_w      : inout  std_logic                                                            ; --  Science data, first control word detected ('0' = No, '1' = Yes)
         b_packet_tx_time     : inout  time                                                                 ; --  Science packet first word transmit time
         b_packet_type        : inout  line                                                                 ; --  Science packet type
         b_packet_size        : inout  integer                                                              ; --  Science packet size
         o_packet_dump        : out    std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
signal   o_packet_end         : out    std_logic                                                            ; --  Science packet end ('0' = No, '1' = Yes)
         o_err_sc_pkt_start   : out    std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         o_err_sc_pkt_size    : out    std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
signal   o_sc_pkt_type        : out    t_slv_arr(0 to c_SC_PKT_W_NB-1)(c_SC_DATA_SER_W_S-1 downto 0)        ; --  Science packet type
         file scd_file        : text                                                                          --  Science Data Result file
   ) is
   begin

      -- Check start packet was sent before acquiring an another word
      o_err_sc_pkt_start := not(b_sc_ctrl_fst_w);

      -- Check science packet size
      if b_packet_size /= i_packet_size_exp then
         o_err_sc_pkt_size := c_HGH_LEV;
      end if;

      -- Science Data Result file writing
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);
      fprintf(none, "Packet header transmit time   : " & time'image(b_packet_tx_time)  , scd_file);
      fprintf(none, "Packet header                 : " & b_packet_type.all             , scd_file);

      fprintf(none, "Packet size                   : " & integer'image(b_packet_size), scd_file);

      for k in 0 to c_NB_COL-1 loop
      fprintf(none, "Packet content column " & integer'image(k) & "       : " & b_packet_content(k).all, scd_file);

      end loop;

      -- Packet variables reinitialization
      b_sc_ctrl_fst_w  := c_LOW_LEV;
      b_packet_tx_time :=  c_ZERO_TIME;
      write(b_packet_type, c_ZERO_INT);
      o_packet_dump    := c_LOW_LEV;
      b_packet_size    := c_ZERO_INT;
      o_packet_end     <= c_HGH_LEV;
      o_sc_pkt_type    <= (others => c_SC_CTRL_DTW);

   end sc_data_end_pkt;

   -- ------------------------------------------------------------------------------------------------------
   --! Science data error display
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_err_display (
         i_packet_dump        : in     std_logic                                                            ; --  Science packet dump ('0' = No, '1' = Yes)
         i_err_sc_dta_ena     : in     std_logic                                                            ; --  Error science data enable ('0' = No, '1' = Yes)
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
         i_science_data_err   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Science data error ('0' = No error, '1' = Error)
         i_mem_dmp_sc_dta_out : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --  Memory Dump, science side: data out
         i_err_sc_ctrl_dif    : in     std_logic                                                            ; --  Error science data control similar ('0' = No error, '1' = Error)
         i_err_sc_ctrl_ukn    : in     std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         i_err_sc_pkt_start   : in     std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_eod     : in     std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_size    : in     std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
signal   o_sc_pkt_err         : out    std_logic                                                            ; --  Science packet error ('0' = No error, '1' = Error)
         file scd_file        : text                                                                          --  Science Data Result file
   ) is
   variable v_err_sc_data     : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --  Error science data ('0' = No error, '1' = Error)
   begin

      -- Check science data
      for k in 0 to c_NB_COL-1 loop
         v_err_sc_data(k) := c_LOW_LEV;
         if (i_packet_dump = c_HGH_LEV) and (i_science_data(k) /= std_logic_vector(resize(unsigned(i_mem_dmp_sc_dta_out(k)), i_science_data(k)'length))) then
            v_err_sc_data(k) := c_HGH_LEV;

         end if;
      end loop;

      -- Errors display
      if i_err_sc_ctrl_dif = c_HGH_LEV then
         o_sc_pkt_err <= c_HGH_LEV;
         fprintf(error, "Science Data Control different on the two lines", scd_file);
      end if;

      if i_err_sc_ctrl_ukn = c_HGH_LEV then
         o_sc_pkt_err <= c_HGH_LEV;
         fprintf(error, "Science Data Control unknown", scd_file);
      end if;

      if i_err_sc_pkt_start = c_HGH_LEV then
         o_sc_pkt_err <= c_HGH_LEV;
         fprintf(error, "Science Data packet header missing", scd_file);
      end if;

      if i_err_sc_pkt_eod = c_HGH_LEV then
         o_sc_pkt_err <= c_HGH_LEV;
         fprintf(error, "Science Data packet end of data missing", scd_file);
      end if;

      if i_err_sc_pkt_size = c_HGH_LEV then
         o_sc_pkt_err <= c_HGH_LEV;
         fprintf(error, "Science Data packet size not expected", scd_file);
      end if;

      G_science_data_err : for k in 0 to c_NB_COL-1 loop

         if (v_err_sc_data(k) and i_err_sc_dta_ena) = c_HGH_LEV then
            o_sc_pkt_err <= c_HGH_LEV;
            fprintf(error, "Science Data packet content, column " & integer'image(k) &
                           ", does not correspond to ADC input (Read: " & hfield_format(i_science_data(k)).all & ", Expected: " & hfield_format(i_mem_dmp_sc_dta_out(k)).all & ")", scd_file);
         end if;

         if (i_science_data_err(k) and i_err_sc_dta_ena) = c_HGH_LEV then
            o_sc_pkt_err <= c_HGH_LEV;
            fprintf(error, "Science Data packet content, column " & integer'image(k) & ", not expected", scd_file);
         end if;

      end loop G_science_data_err;

   end sc_data_err_display;

end package body pkg_science_data;
