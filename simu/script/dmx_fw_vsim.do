# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
#
#                            dmx-fw is free software: you can redistribute it and/or modify
#                            it under the terms of the GNU General Public License as published by
#                            the Free Software Foundation, either version 3 of the License, or
#                            (at your option) any later version.
#
#                            This program is distributed in the hope that it will be useful,
#                            but WITHOUT ANY WARRANTY; without even the implied warranty of
#                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                            GNU General Public License for more details.
#
#                            You should have received a copy of the GNU General Public License
#                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    email                   slaurent@nanoxplore.com
#    @file                   dmx_fw_vsim.do
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Modelsim script for dmx_fw_vsim compilation files:
#                                *  Command line argument 1: Model Board
#                                *  Command line argument 2: IP directory
#                                *  Command line argument 3: Source directory
#                                *  Command line argument 4: Testbench directory
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###################### Parameters ##########################
quietly set MODEL_BOARD $1
quietly set IP_DIR $2
quietly set SRC_DIR $3
quietly set TB_DIR $4

###################### Files compilation ###################
   vlib work

   if {${MODEL_BOARD} == "dm" || ${MODEL_BOARD} == "dk"} {
      vcom +cover=bcs -work work -2008           \
         ${SRC_DIR}/common/pkg_type.vhd          \
         ${SRC_DIR}/common/pkg_func_math.vhd     \
         ${SRC_DIR}/dm/pkg_mod.vhd               \
         ${IP_DIR}/pkg_fpga_tech.vhd             \
         ${SRC_DIR}/dm/pkg_fir.vhd
   }

   vcom +cover=bcs -work work -2008              \
      ${SRC_DIR}/common/pkg_project.vhd          \
      ${SRC_DIR}/common/pkg_calc_chain.vhd       \
      ${SRC_DIR}/common/pkg_ep_cmd.vhd           \
      ${SRC_DIR}/common/pkg_ep_cmd_type.vhd      \
      ${SRC_DIR}/common/multiplexer.vhd          \
      ${SRC_DIR}/common/resize_stall_msb.vhd     \
      ${SRC_DIR}/common/cmd_im_ck.vhd            \
      ${SRC_DIR}/common/mem_scrubbing.vhd        \
      ${IP_DIR}/dsp.vhd                          \
      ${IP_DIR}/pll.vhd                          \
      ${IP_DIR}/dmem_ecc.vhd                     \
      ${IP_DIR}/mult_add_ext.vhd                 \
      ${SRC_DIR}/common/im_ck.vhd                \
      ${SRC_DIR}/common/rst_gen.vhd              \
      ${SRC_DIR}/common/rst_clk_mgt.vhd          \
      ${SRC_DIR}/common/in_rs_clk.vhd            \
      ${SRC_DIR}/common/round_sat.vhd            \
      ${SRC_DIR}/common/adder_sat.vhd            \
      ${SRC_DIR}/common/spi_slave.vhd            \
      ${SRC_DIR}/common/sts_err_wrt_mgt.vhd      \
      ${SRC_DIR}/common/sts_err_out_mgt.vhd      \
      ${SRC_DIR}/common/sts_err_dis_mgt.vhd      \
      ${SRC_DIR}/common/ep_cmd.vhd               \
      ${SRC_DIR}/common/mem_data_rd_mux.vhd      \
      ${SRC_DIR}/common/ep_cmd_tx_wd.vhd         \
      ${SRC_DIR}/common/mem_in_gen.vhd           \
      ${SRC_DIR}/common/squid_close_mode.vhd     \
      ${SRC_DIR}/common/register_cs_mgt.vhd      \
      ${SRC_DIR}/common/rg_aqmde_mgt.vhd         \
      ${SRC_DIR}/common/rg_tsten_mgt.vhd         \
      ${SRC_DIR}/common/register_mgt.vhd         \
      ${SRC_DIR}/common/dmx_cmd.vhd              \
      ${SRC_DIR}/common/spi_master.vhd           \
      ${SRC_DIR}/common/science_data_tx.vhd      \
      ${SRC_DIR}/common/science_data_mgt.vhd     \
      ${SRC_DIR}/common/adder_acc.vhd            \
      ${SRC_DIR}/common/squid_adc_sys.vhd        \
      ${SRC_DIR}/common/squid_adc_mgt.vhd        \
      ${SRC_DIR}/common/squid_data_proc_mem.vhd  \
      ${SRC_DIR}/common/err_average.vhd          \
      ${SRC_DIR}/common/err_proc.vhd             \
      ${SRC_DIR}/common/sqm_fbk_mgt.vhd          \
      ${SRC_DIR}/common/pulse_shaping.vhd        \
      ${SRC_DIR}/common/sqm_dac_sys.vhd          \
      ${SRC_DIR}/common/sqm_dac_mgt.vhd          \
      ${SRC_DIR}/common/sqm_spi_mgt.vhd          \
      ${SRC_DIR}/common/test_pattern_gen.vhd     \
      ${SRC_DIR}/common/relock.vhd               \
      ${SRC_DIR}/common/fir_deci.vhd             \
      ${SRC_DIR}/common/iir_deci.vhd             \
      ${SRC_DIR}/common/sqa_fbk_mgt.vhd          \
      ${SRC_DIR}/common/sqa_dac_sys.vhd


   if {${MODEL_BOARD} == "dm" || ${MODEL_BOARD} == "dk"} {
      vcom +cover=bcs -work work -2008           \
         ${SRC_DIR}/dm/sqa_under_samp.vhd        \
         ${SRC_DIR}/common/squid_data_proc.vhd   \
         ${SRC_DIR}/dm/hk_mgt.vhd                \
         ${SRC_DIR}/dm/sqa_dac_mgt.vhd           \
         ${SRC_DIR}/dm/top_dmx_dm.vhd
   }

   if {${MODEL_BOARD} == "dk"} {
      vcom +cover=bcs -work work -2008           \
         ${SRC_DIR}/dk/top_dmx_dm_clk.vhd        \
         ${SRC_DIR}/dk/top_dmx_dk.vhd
   }

   vcom -work work -2008                         \
      ${TB_DIR}/common/pkg_model.vhd             \
      ${TB_DIR}/common/pkg_mess.vhd              \
      ${TB_DIR}/common/pkg_str_fld_assoc.vhd     \
      ${TB_DIR}/common/pkg_str_add_assoc.vhd     \
      ${TB_DIR}/common/pkg_func_cmd_spi.vhd      \
      ${TB_DIR}/common/pkg_func_cmd_script.vhd   \
      ${TB_DIR}/common/pkg_func_parser.vhd       \
      ${TB_DIR}/common/pkg_mess_parser.vhd       \
      ${TB_DIR}/common/pkg_science_data.vhd      \
      ${TB_DIR}/common/adc_ad9254_model.vhd      \
      ${TB_DIR}/common/dac5675a_model.vhd        \
      ${TB_DIR}/common/dac121s101_model.vhd      \
      ${TB_DIR}/common/adc128s102_model.vhd      \
      ${TB_DIR}/common/cd74hc4051_model.vhd      \
      ${TB_DIR}/common/clock_check.vhd           \
      ${TB_DIR}/common/clock_check_model.vhd     \
      ${TB_DIR}/common/clock_model.vhd           \
      ${TB_DIR}/common/spi_check.vhd             \
      ${TB_DIR}/common/spi_check_model.vhd       \
      ${TB_DIR}/common/ep_spi_model.vhd          \
      ${TB_DIR}/common/pulse_shaping_check.vhd   \
      ${TB_DIR}/common/sqa_dac_model.vhd         \
      ${TB_DIR}/common/squid_model.vhd           \
      ${TB_DIR}/common/science_data_rx.vhd       \
      ${TB_DIR}/common/science_data_check.vhd    \
      ${TB_DIR}/common/science_data_model.vhd    \
      ${TB_DIR}/common/hk_model.vhd              \
      ${TB_DIR}/common/parser.vhd                \
      ${TB_DIR}/common/fpga_system_fpasim_top.vhd\
      ${TB_DIR}/${MODEL_BOARD}/top_dmx_tb.vhd