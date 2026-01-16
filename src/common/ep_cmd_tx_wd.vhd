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
--!   @file                   ep_cmd_tx_wd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command transmit word management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity ep_cmd_tx_wd is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_cs_rg              : in     std_logic_vector(c_EP_CMD_REG_MX_STIN(1)-1 downto 0)                 ; --! Chip selects register ('0' = Inactive, '1' = Active)

         i_brd_ref_rs         : in     std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference, synchronized on System Clock
         i_brd_model_rs       : in     std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model, synchronized on System Clock
         i_dlflg              : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_DLFLG_COL_S-1 downto 0)            ; --! Delock flag

         i_rg_aqmde           : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! EP register: DATA_ACQ_MODE

         i_rg_smfmd           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SMFMD_COL_S-1 downto 0)            ; --! EP register: MUX_SQ_FB_ON_OFF
         i_rg_saofm           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SAOFM_COL_S-1 downto 0)            ; --! EP register: AMP_SQ_OFFSET_MODE
         i_rg_tsten           : in     std_logic_vector(c_DFLD_TSTEN_S-1 downto 0)                          ; --! EP register: TEST_PATTERN_ENABLE
         i_rg_bxlgt           : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_BXLGT_COL_S-1 downto 0)            ; --! EP register: BOXCAR_LENGTH
         i_ep_cmd_sts_rg_r    : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command: Status register, registered

         i_rg_col             : in     t_rgc_arr(0 to c_NB_COL-1)                                           ; --! EP register by column
         i_rg_col_cs          : in     t_slv_arr(0 to c_EP_RGC_NUM_LAST-1)(c_NB_COL-1 downto 0)             ; --! EP register by column chip select ('0'=Inactive, '1'=Active)

         i_mem_prc_data       : in     t_mem_prc_dta_arr(0 to c_NB_COL-1)                                   ; --! Memory for data squid proc.: data read
         i_ep_mem_data        : in     t_ep_mem_dta_arr(0 to c_NB_COL-1)                                    ; --! Memory: data read
         i_ep_mem_data_cs     : in     t_slv_arr(0 to c_EP_MEM_NUM_LAST-1)(c_NB_COL-1 downto 0)             ; --! Memory: chip select ('0'=Inactive, '1'=Active)

         i_hkeep_data         : in     std_logic_vector(c_DFLD_HKEEP_S-1 downto 0)                          ; --! Data read: Housekeeping

         o_ep_cmd_sts_err_add : out    std_logic                                                            ; --! EP command: Status, error invalid address
         o_ep_cmd_tx_wd_rd_rg : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --! EP command to transmit: read register word

   );
end entity ep_cmd_tx_wd;

architecture RTL of ep_cmd_tx_wd is
constant c_HW_VER_FLD_S       : integer   := c_EP_SPI_WD_S/2                                                ; --! Hardware version field size

signal   rg_col_data          : t_slv_arr(0 to c_NB_COL-1)(c_EP_RGC_ACC(c_EP_RGC_ACC'high)-1 downto 0)      ; --! EP register by column: Data read
signal   rg_col_data_mux      : std_logic_vector(          c_EP_RGC_ACC(c_EP_RGC_ACC'high)-1 downto 0)      ; --! EP register by column: Data read multiplexer

signal   ep_mem_data          : t_slv_arr(0 to c_NB_COL-1)(c_EP_MEM_ACC(c_EP_MEM_ACC'high)-1 downto 0)      ; --! Memory: Data read
signal   ep_mem_data_mux      : std_logic_vector(          c_EP_MEM_ACC(c_EP_MEM_ACC'high)-1 downto 0)      ; --! Memory: Data read multiplexer

signal   data_rg_rd           : t_slv_arr(0 to c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1)
                                         (c_EP_SPI_WD_S-1 downto 0)                                         ; --! Data register read
signal   cs_rg                : std_logic_vector(c_EP_CMD_REG_MX_STIN(c_EP_CMD_REG_MX_STIN'high)-1 downto 0); --! Chip select register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Register by Column Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   G_rg_col_in_trans : for k in 0 to c_NB_COL-1 generate
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN)) <= i_rg_col(k).smign;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN)) <= i_rg_col(k).saign;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM)) <= i_rg_col(k).sakkm;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM)) <= i_rg_col(k).sakrm;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP)) <= i_rg_col(k).saolp;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC)) <= i_rg_col(k).saofc;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL)) <= i_rg_col(k).saofl;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD)) <= i_rg_col(k).smfbd;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD)) <= i_rg_col(k).saodd;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD)) <= i_rg_col(k).saomd;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL)) <= i_rg_col(k).smpdl;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS)) <= i_rg_col(k).plsss;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL)) <= i_rg_col(k).rldel;
      rg_col_data(k)(c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR)) <= i_rg_col(k).rlthr;

   end generate G_rg_col_in_trans;

   G_rg_col : for l in 0 to c_EP_RGC_NUM_LAST-1 generate
   signal   data              : t_slv_arr(0 to c_NB_COL-1)(c_EP_RGC_ACC(l+1)-c_EP_RGC_ACC(l)-1 downto 0)    ; --! Data multiplexer inputs
   begin

      G_column_mgt : for k in 0 to c_NB_COL-1 generate
         data(k)  <= rg_col_data(k)(c_EP_RGC_ACC(l+1)-1 downto c_EP_RGC_ACC(l));

      end generate G_column_mgt;

      I_rg_col : entity work.mem_data_rd_mux generic map (
         g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_EP_RGC_ACC(l+1)-c_EP_RGC_ACC(l), -- integer                              ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
      ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => data                 , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_rg_col_cs(l)       , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => rg_col_data_mux(c_EP_RGC_ACC(l+1)-1 downto c_EP_RGC_ACC(l))                  --! Multiplexed data
      );

   end generate G_rg_col;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   G_ep_mem_in_trans : for k in 0 to c_NB_COL-1 generate
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_TSTPT+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_TSTPT)) <= i_ep_mem_data(k).tstpt;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_PARMA+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_PARMA)) <= i_mem_prc_data(k).parma;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_KIKNM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_KIKNM)) <= i_mem_prc_data(k).kiknm;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_KNORM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_KNORM)) <= i_mem_prc_data(k).knorm;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_SMFB0+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMFB0)) <= i_mem_prc_data(k).smfb0;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_SMLKV+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMLKV)) <= i_mem_prc_data(k).smlkv;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_SMFBM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMFBM)) <= i_ep_mem_data(k).smfbm;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_SAOFF+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SAOFF)) <= i_ep_mem_data(k).saoff;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_PLSSH+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_PLSSH)) <= i_ep_mem_data(k).plssh;
      ep_mem_data(k)(c_EP_MEM_ACC(c_EP_MEM_NUM_DLCNT+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_DLCNT)) <= i_ep_mem_data(k).dlcnt;

   end generate G_ep_mem_in_trans;

   G_ep_mem : for l in 0 to c_EP_MEM_NUM_LAST-1 generate
   signal   data              : t_slv_arr(0 to c_NB_COL-1)(c_EP_MEM_ACC(l+1)-c_EP_MEM_ACC(l)-1 downto 0)    ; --! Data multiplexer inputs
   begin

      G_column_mgt : for k in 0 to c_NB_COL-1 generate
         data(k)  <= ep_mem_data(k)(c_EP_MEM_ACC(l+1)-1 downto c_EP_MEM_ACC(l));

      end generate G_column_mgt;

      I_ep_mem : entity work.mem_data_rd_mux generic map (
         g_MEM_RD_DATA_NPER   => c_MEM_RD_DATA_NPER   , -- integer                                          ; --! Clock period number for accessing memory data output
         g_DATA_S             => c_EP_MEM_ACC(l+1)-c_EP_MEM_ACC(l), -- integer                              ; --! Data bus size
         g_NB                 => c_NB_COL               -- integer                                            --! Data bus number
      ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock
         i_data               => data                 , -- in     t_slv_arr g_NB g_DATA_S                   ; --! Data buses
         i_cs                 => i_ep_mem_data_cs(l)  , -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
         o_data_mux           => ep_mem_data_mux(c_EP_MEM_ACC(l+1)-1 downto c_EP_MEM_ACC(l))                 --! Multiplexed data
      );

   end generate G_ep_mem;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data register read
   -- ------------------------------------------------------------------------------------------------------
   -- @Req : REG_DATA_ACQ_MODE
   -- @Req : DRE-DMX-FW-REQ-0580
   data_rg_rd(c_EP_CMD_POS_AQMDE) <= std_logic_vector(resize(unsigned(i_rg_aqmde),  c_EP_SPI_WD_S));

   -- @Req : REG_MUX_SQ_FB_ON_OFF
   data_rg_rd(c_EP_CMD_POS_SMFMD) <= std_logic_vector(resize(unsigned(i_rg_smfmd(c_COL3)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_smfmd(c_COL2)), c_EP_SPI_WD_S/c_NB_COL) &
                                                      resize(unsigned(i_rg_smfmd(c_COL1)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_smfmd(c_COL0)), c_EP_SPI_WD_S/c_NB_COL));
   -- @Req : REG_AMP_SQ_OFFSET_MODE
   -- @Req : DRE-DMX-FW-REQ-0330
   data_rg_rd(c_EP_CMD_POS_SAOFM) <= std_logic_vector(resize(unsigned(i_rg_saofm(c_COL3)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_saofm(c_COL2)), c_EP_SPI_WD_S/c_NB_COL) &
                                                      resize(unsigned(i_rg_saofm(c_COL1)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_saofm(c_COL0)), c_EP_SPI_WD_S/c_NB_COL));
   -- @Req : REG_TEST_PATTERN
   -- @Req : DRE-DMX-FW-REQ-0440
   data_rg_rd(c_EP_CMD_POS_TSTPT) <= std_logic_vector(resize(unsigned(ep_mem_data_mux( c_EP_MEM_ACC(c_EP_MEM_NUM_TSTPT+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_TSTPT))), c_EP_SPI_WD_S));

   -- @Req : REG_TEST_PATTERN_ENABLE
   data_rg_rd(c_EP_CMD_POS_TSTEN) <= std_logic_vector(resize(unsigned(i_rg_tsten), c_EP_SPI_WD_S));

   -- @Req : REG_BOXCAR_LENGTH
   -- @Req : DRE-DMX-FW-REQ-0145
   data_rg_rd(c_EP_CMD_POS_BXLGT) <= std_logic_vector(resize(unsigned(i_rg_bxlgt(c_COL3)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_bxlgt(c_COL2)), c_EP_SPI_WD_S/c_NB_COL) &
                                                      resize(unsigned(i_rg_bxlgt(c_COL1)), c_EP_SPI_WD_S/c_NB_COL) & resize(unsigned(i_rg_bxlgt(c_COL0)), c_EP_SPI_WD_S/c_NB_COL));
   -- @Req : REG_HKEEP
   -- @Req : DRE-DMX-FW-REQ-0540
   data_rg_rd(c_EP_CMD_POS_HKEEP) <= std_logic_vector(resize(unsigned(i_hkeep_data), c_EP_SPI_WD_S));

   -- @Req : REG_DELOCK_FLAG
   -- @Req : DRE-DMX-FW-REQ-0430
   data_rg_rd(c_EP_CMD_POS_DLFLG) <= std_logic_vector(resize(unsigned(i_dlflg(c_COL3)) & unsigned(i_dlflg(c_COL2)) &
                                                             unsigned(i_dlflg(c_COL1)) & unsigned(i_dlflg(c_COL0)), c_EP_SPI_WD_S));
   -- @Req : REG_Status
   data_rg_rd(c_EP_CMD_POS_STATUS)<= i_ep_cmd_sts_rg_r;

   -- @Req : REG_FW_Version
   -- @Req : DRE-DMX-FW-REQ-0520
   data_rg_rd(c_EP_CMD_POS_FW_VER)<= std_logic_vector(to_unsigned(c_FW_VERSION, c_EP_SPI_WD_S));

   -- @Req : REG_HW_Version
   -- @Req : DRE-DMX-FW-REQ-0530
   data_rg_rd(c_EP_CMD_POS_HW_VER)<= std_logic_vector(resize(unsigned(i_brd_model_rs), c_HW_VER_FLD_S)) & std_logic_vector(resize(unsigned(i_brd_ref_rs), c_HW_VER_FLD_S));

   -- @Req : REG_CY_A
   -- @Req : DRE-DMX-FW-REQ-0180
   data_rg_rd(c_EP_CMD_POS_PARMA) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_PARMA+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_PARMA))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_INPUT_GAIN
   -- @Req : DRE-DMX-FW-REQ-0147
   data_rg_rd(c_EP_CMD_POS_SMIGN) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMIGN))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_INPUT_GAIN
   -- @Req : DRE-DMX-FW-REQ-0148
   data_rg_rd(c_EP_CMD_POS_SAIGN) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAIGN))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_KI_KNORM
   -- @Req : DRE-DMX-FW-REQ-0170
   data_rg_rd(c_EP_CMD_POS_KIKNM) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_KIKNM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_KIKNM))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_KI_KNORM
   -- @Req : DRE-DMX-FW-REQ-0326
   data_rg_rd(c_EP_CMD_POS_SAKKM) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKKM))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_KNORM
   -- @Req : DRE-DMX-FW-REQ-0392
   data_rg_rd(c_EP_CMD_POS_KNORM) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_KNORM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_KNORM))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_KNORM
   -- @Req : DRE-DMX-FW-REQ-0393
   data_rg_rd(c_EP_CMD_POS_SAKRM) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAKRM))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_FB0
   -- @Req : DRE-DMX-FW-REQ-0200
   data_rg_rd(c_EP_CMD_POS_SMFB0) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_SMFB0+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMFB0))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_LOCKPOINT_V
   -- @Req : DRE-DMX-FW-REQ-0190
   data_rg_rd(c_EP_CMD_POS_SMLKV) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_SMLKV+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMLKV))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_FB_MODE
   -- @Req : DRE-DMX-FW-REQ-0210
   data_rg_rd(c_EP_CMD_POS_SMFBM) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_SMFBM+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SMFBM))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_FINE
   -- @Req : DRE-DMX-FW-REQ-0300
   -- @Req : DRE-DMX-FW-REQ-0305
   data_rg_rd(c_EP_CMD_POS_SAOFF) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_SAOFF+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_SAOFF))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_LSB_PTR
   -- @Req : DRE-DMX-FW-REQ-0298
   data_rg_rd(c_EP_CMD_POS_SAOLP) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOLP))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_COARSE
   -- @Req : DRE-DMX-FW-REQ-0290
   -- @Req : DRE-DMX-FW-REQ-0292
   data_rg_rd(c_EP_CMD_POS_SAOFC) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFC))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_LSB
   -- @Req : DRE-DMX-FW-REQ-0295
   -- @Req : DRE-DMX-FW-REQ-0297
   data_rg_rd(c_EP_CMD_POS_SAOFL) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOFL))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_MUX_SQ_FB_DELAY
   -- @Req : DRE-DMX-FW-REQ-0280
   data_rg_rd(c_EP_CMD_POS_SMFBD) <= std_logic_vector(resize(  signed(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMFBD))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_DAC_DELAY
   -- @Req : DRE-DMX-FW-REQ-0387
   data_rg_rd(c_EP_CMD_POS_SAODD) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAODD))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_AMP_SQ_OFFSET_MUX_DELAY
   -- @Req : DRE-DMX-FW-REQ-0380
   data_rg_rd(c_EP_CMD_POS_SAOMD) <= std_logic_vector(resize(  signed(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SAOMD))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_SAMPLING_DELAY
   -- @Req : DRE-DMX-FW-REQ-0150
   -- @Req : DRE-DMX-FW-REQ-0155
   data_rg_rd(c_EP_CMD_POS_SMPDL) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_SMPDL))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_PULSE_SHAPING
   -- @Req : DRE-DMX-FW-REQ-0230
   data_rg_rd(c_EP_CMD_POS_PLSSH) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_PLSSH+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_PLSSH))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_PULSE_SHAPING_SEL
   -- @Req : DRE-DMX-FW-REQ-0235
   data_rg_rd(c_EP_CMD_POS_PLSSS) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_PLSSS))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_RELOCK_DELAY
   -- @Req : DRE-DMX-FW-REQ-0410
   data_rg_rd(c_EP_CMD_POS_RLDEL) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLDEL))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_RELOCK_THRESHOLD
   -- @Req : DRE-DMX-FW-REQ-0420
   data_rg_rd(c_EP_CMD_POS_RLTHR) <= std_logic_vector(resize(unsigned(rg_col_data_mux(c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR+1)-1 downto c_EP_RGC_ACC(c_EP_RGC_NUM_RLTHR))), c_EP_SPI_WD_S));

   -- @Req : REG_CY_DELOCK_COUNTERS
   -- @Req : DRE-DMX-FW-REQ-0435
   data_rg_rd(c_EP_CMD_POS_DLCNT) <= std_logic_vector(resize(unsigned(ep_mem_data_mux(c_EP_MEM_ACC(c_EP_MEM_NUM_DLCNT+1)-1 downto c_EP_MEM_ACC(c_EP_MEM_NUM_DLCNT))), c_EP_SPI_WD_S));

   data_rg_rd(c_EP_CMD_POS_LAST to c_EP_CMD_REG_MX_STIN(1)-1) <= (others => c_ZERO(data_rg_rd(data_rg_rd'low)'range));

   cs_rg(c_EP_CMD_REG_MX_STIN(1)-1 downto 0) <= i_cs_rg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Data read multiplexer
   -- ------------------------------------------------------------------------------------------------------
   G_mux_stage: for k in 0 to c_EP_CMD_REG_MX_STNB-1 generate
   constant c_MUX_NB          : integer   := c_EP_CMD_REG_MX_STIN(k+2) - c_EP_CMD_REG_MX_STIN(k+1)          ; --! Multiplexer number by stage
   begin

      G_mux_nb: for l in 0 to c_MUX_NB - 1 generate
      begin

         I_multiplexer: entity work.multiplexer generic map (
            g_DATA_S          => c_EP_SPI_WD_S        , -- integer                                          ; --! Data bus size
            g_NB              => c_EP_CMD_REG_MX_INNB(k)-- integer                                            --! Data bus number
         ) port map (
            i_rst             => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
            i_clk             => i_clk                , -- in     std_logic                                 ; --! System Clock
            i_data            => data_rg_rd(
                                 l   *c_EP_CMD_REG_MX_INNB(k) + c_EP_CMD_REG_MX_STIN(k) to
                                (l+1)*c_EP_CMD_REG_MX_INNB(k) + c_EP_CMD_REG_MX_STIN(k)-1)                  , --! Data buses
            i_cs              => cs_rg(
                                (l+1)*c_EP_CMD_REG_MX_INNB(k) + c_EP_CMD_REG_MX_STIN(k)-1 downto
                                 l   *c_EP_CMD_REG_MX_INNB(k) + c_EP_CMD_REG_MX_STIN(k))                    , --! Chip selects ('0' = Inactive, '1' = Active)
            o_data_mux        => data_rg_rd(c_EP_CMD_REG_MX_STIN(k+1)+l), -- out    slv(g_DATA_S-1 downto 0); --! Multiplexed data
            o_cs_or           => cs_rg(     c_EP_CMD_REG_MX_STIN(k+1)+l)  -- out    std_logic                 --! Chip selects "or-ed"
         );

      end generate G_mux_nb;

   end generate G_mux_stage;

   o_ep_cmd_tx_wd_rd_rg <= data_rg_rd(data_rg_rd'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error invalid address
   --    @Req : REG_EP_CMD_ERR_ADD
   -- ------------------------------------------------------------------------------------------------------
   o_ep_cmd_sts_err_add <= cs_rg(cs_rg'high) xor c_EP_CMD_ERR_SET;

end architecture RTL;
