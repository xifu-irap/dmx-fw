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
#    @file                   project_constraints.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nx project constraints
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
from nxpython import *

class Region:
    def __init__(self, name, col, row, width, height):
        self.n  = name
        self.c  = col
        self.r  = row
        self.w  = width
        self.h  = height
        self.c2 = col + width   # Col2
        self.r2 = row + height  # Row2

def synthesis_constraints(p,modelboard):
    if   modelboard == 'dk':

        # ------------------------------------------------------------------------------------------------------
        #   Region creation
        # ------------------------------------------------------------------------------------------------------
        RESET           = Region('RESET'        , 25, 14,  1,  1)

        SQM_ADC_0       = Region('SQM_ADC_0'    , 17, 18,  1,  3)
        SQM_ADC_1       = Region('SQM_ADC_1'    , 21, 18,  1,  3)
        SQM_ADC_2       = Region('SQM_ADC_2'    , 25, 18,  1,  3)
        SQM_ADC_3       = Region('SQM_ADC_3'    , 29, 18,  1,  3)

        SQM_DAC_0       = Region('SQM_DAC_0'    , 16, 18,  1,  3)
        SQM_DAC_1       = Region('SQM_DAC_1'    , 20, 18,  1,  3)
        SQM_DAC_2       = Region('SQM_DAC_2'    , 24, 18,  1,  3)
        SQM_DAC_3       = Region('SQM_DAC_3'    , 28, 18,  1,  3)

        EP_CMD          = Region('EP_CMD'       , 37,  6,  1,  1)
        REGISTER_MGT    = Region('REGISTER_MGT' , 19,  8, 10, 10)
        HK_MGT          = Region('HK_MGT'       , 18, 12,  1,  1)

        SCIENCE_MGT     = Region('SCIENCE_MGT'  , 27,  2,  2,  2)

        # ------------------------------------------------------------------------------------------------------
        #   Reset
        # ------------------------------------------------------------------------------------------------------
        p.addModule('rst_gen(XFC92C2C2)', 'I_top_dmx_dm_clk|I_rst_clk_mgt.I_rst', 'rst', 'Soft')
        p.addModule('rst_gen(X0FAADB23)', 'I_top_dmx_dm_clk|I_rst_clk_mgt.I_rst_adc_dac', 'rst_sqm_adc_dac', 'Soft')

        p.addRegion(RESET.n, RESET.c, RESET.r, RESET.w, RESET.h, False)
        p.confineModule('rst', RESET.n)
        p.confineModule('rst_sqm_adc_dac', RESET.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('squid_adc_mgt', 'I_top_dmx_dm_clk|G_column_mgt[0].I_squid_adc_mgt', 'squid_adc_mgt_0', 'Soft')
        p.addModule('squid_adc_mgt', 'I_top_dmx_dm_clk|G_column_mgt[1].I_squid_adc_mgt', 'squid_adc_mgt_1', 'Soft')
        p.addModule('squid_adc_mgt', 'I_top_dmx_dm_clk|G_column_mgt[2].I_squid_adc_mgt', 'squid_adc_mgt_2', 'Soft')
        p.addModule('squid_adc_mgt', 'I_top_dmx_dm_clk|G_column_mgt[3].I_squid_adc_mgt', 'squid_adc_mgt_3', 'Soft')

        p.addRegion(SQM_ADC_0.n, SQM_ADC_0.c, SQM_ADC_0.r, SQM_ADC_0.w, SQM_ADC_0.h, False)
        p.addRegion(SQM_ADC_1.n, SQM_ADC_1.c, SQM_ADC_1.r, SQM_ADC_1.w, SQM_ADC_1.h, False)
        p.addRegion(SQM_ADC_2.n, SQM_ADC_2.c, SQM_ADC_2.r, SQM_ADC_2.w, SQM_ADC_2.h, False)
        p.addRegion(SQM_ADC_3.n, SQM_ADC_3.c, SQM_ADC_3.r, SQM_ADC_3.w, SQM_ADC_3.h, False)

        p.confineModule('squid_adc_mgt_0', SQM_ADC_0.n)
        p.confineModule('squid_adc_mgt_1', SQM_ADC_1.n)
        p.confineModule('squid_adc_mgt_2', SQM_ADC_2.n)
        p.confineModule('squid_adc_mgt_3', SQM_ADC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('sqm_dac_mgt(X0097C298)', 'I_top_dmx_dm_clk|G_column_mgt[0].I_sqm_dac_mgt', 'sqm_dac_mgt_0', 'Soft')
        p.addModule('sqm_dac_mgt(XECC18118)', 'I_top_dmx_dm_clk|G_column_mgt[1].I_sqm_dac_mgt', 'sqm_dac_mgt_1', 'Soft')
        p.addModule('sqm_dac_mgt(XECC18118)', 'I_top_dmx_dm_clk|G_column_mgt[2].I_sqm_dac_mgt', 'sqm_dac_mgt_2', 'Soft')
        p.addModule('sqm_dac_mgt(X0097C298)', 'I_top_dmx_dm_clk|G_column_mgt[3].I_sqm_dac_mgt', 'sqm_dac_mgt_3', 'Soft')

        p.addRegion(SQM_DAC_0.n, SQM_DAC_0.c, SQM_DAC_0.r, SQM_DAC_0.w, SQM_DAC_0.h, False)
        p.addRegion(SQM_DAC_1.n, SQM_DAC_1.c, SQM_DAC_1.r, SQM_DAC_1.w, SQM_DAC_1.h, False)
        p.addRegion(SQM_DAC_2.n, SQM_DAC_2.c, SQM_DAC_2.r, SQM_DAC_2.w, SQM_DAC_2.h, False)
        p.addRegion(SQM_DAC_3.n, SQM_DAC_3.c, SQM_DAC_3.r, SQM_DAC_3.w, SQM_DAC_3.h, False)

        p.confineModule('sqm_dac_mgt_0', SQM_DAC_0.n)
        p.confineModule('sqm_dac_mgt_1', SQM_DAC_1.n)
        p.confineModule('sqm_dac_mgt_2', SQM_DAC_2.n)
        p.confineModule('sqm_dac_mgt_3', SQM_DAC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   EP SPI constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('spi_slave(XCA4B7C09)', 'I_top_dmx_dm_clk|I_ep_cmd|I_spi_slave', 'ep_cmd_spi_slave', 'Soft')
        p.addRegion(EP_CMD.n, EP_CMD.c, EP_CMD.r, EP_CMD.w, EP_CMD.h, False)
        p.confineModule('ep_cmd_spi_slave', EP_CMD.n)

        p.addModule('ep_cmd', 'I_top_dmx_dm_clk|I_ep_cmd', 'ep_cmd', 'Soft')
        p.addRegion(REGISTER_MGT.n, REGISTER_MGT.c, REGISTER_MGT.r, REGISTER_MGT.w, REGISTER_MGT.h, False)
        p.confineModule('ep_cmd', REGISTER_MGT.n)

        # ------------------------------------------------------------------------------------------------------
        #   Science constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('science_data_mgt', 'I_top_dmx_dm_clk|I_science_data_mgt', 'science_data_mgt', 'Soft')
        p.addRegion(SCIENCE_MGT.n, SCIENCE_MGT.c, SCIENCE_MGT.r, SCIENCE_MGT.w, SCIENCE_MGT.h, False)
        p.confineModule('science_data_mgt', SCIENCE_MGT.n)

        # ------------------------------------------------------------------------------------------------------
        #   Internal constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('register_mgt', 'I_top_dmx_dm_clk|I_register_mgt', 'register_mgt', 'Soft')
        p.confineModule('register_mgt', REGISTER_MGT.n)

        p.addModule('spi_slave(XE62E9FBB)', 'I_hk_spi_slave', 'hk_spi_slave', 'Soft')
        p.addRegion(HK_MGT.n, HK_MGT.c, HK_MGT.r, HK_MGT.w, HK_MGT.h, False)
        p.confineModule('hk_spi_slave', HK_MGT.n)

        p.addModule('hk_mgt', 'I_top_dmx_dm_clk|I_hk_mgt', 'hk_mgt', 'Soft')
        p.confineModule('hk_mgt', HK_MGT.n)

    elif modelboard == 'dm':

        # ------------------------------------------------------------------------------------------------------
        #   Mapping directive
        # ------------------------------------------------------------------------------------------------------
        p.addMappingDirective(getModels('*fir_deci*'), 'ROM', 'LUT')

        # ------------------------------------------------------------------------------------------------------
        #   Region creation
        # ------------------------------------------------------------------------------------------------------
        RESET           = Region('RESET'        , 25, 10,  1,  1)

        CLK_SQM_ADC_0   = Region('CLK_SQM_ADC_0', 30, 22,  1,  1)
        CLK_SQM_ADC_1   = Region('CLK_SQM_ADC_1', 41,  2,  1,  1)
        CLK_SQM_ADC_2   = Region('CLK_SQM_ADC_2', 13,  2,  1,  1)
        CLK_SQM_ADC_3   = Region('CLK_SQM_ADC_3',  8, 22,  1,  1)

        SQM_ADC_0       = Region('SQM_ADC_0'    , 30, 16,  2,  3)
        SQM_ADC_1       = Region('SQM_ADC_1'    , 35,  6,  2,  3)
        SQM_ADC_2       = Region('SQM_ADC_2'    , 13,  6,  2,  3)
        SQM_ADC_3       = Region('SQM_ADC_3'    , 13, 16,  2,  3)

        SQM_ADC_PWDN_0  = Region('SQM_ADC_PWD_0', 24,  2,  1,  1)
        SQM_ADC_PWDN_1  = Region('SQM_ADC_PWD_1', 24,  2,  1,  1)
        SQM_ADC_PWDN_2  = Region('SQM_ADC_PWD_2', 24,  2,  1,  1)
        SQM_ADC_PWDN_3  = Region('SQM_ADC_PWD_3', 24,  2,  1,  1)

        CLK_SQM_DAC_0   = Region('CLK_SQM_DAC_0', 35,  2,  1,  1)
        CLK_SQM_DAC_1   = Region('CLK_SQM_DAC_1', 22, 22,  1,  1)
        CLK_SQM_DAC_2   = Region('CLK_SQM_DAC_2', 14, 22,  1,  1)
        CLK_SQM_DAC_3   = Region('CLK_SQM_DAC_3', 19,  2,  1,  1)

        SQM_DAC_0       = Region('SQM_DAC_0'    , 33,  4,  1,  3)
        SQM_DAC_1       = Region('SQM_DAC_1'    , 25, 18,  1,  3)
        SQM_DAC_2       = Region('SQM_DAC_2'    , 17, 18,  1,  3)
        SQM_DAC_3       = Region('SQM_DAC_3'    , 15,  4,  1,  3)

        SQM_DAC_PLS_0   = Region('SQM_DAC_PLS_0', 33,  2,  1,  3)
        SQM_DAC_PLS_1   = Region('SQM_DAC_PLS_1', 25, 20,  1,  3)
        SQM_DAC_PLS_2   = Region('SQM_DAC_PLS_2', 17, 20,  1,  3)
        SQM_DAC_PLS_3   = Region('SQM_DAC_PLS_3', 15,  2,  1,  3)

        SQM_DAC_SLEEP_0 = Region('SQM_DAC_SLP_0', 48,  6,  1,  1)
        SQM_DAC_SLEEP_1 = Region('SQM_DAC_SLP_1', 48,  2,  1,  1)
        SQM_DAC_SLEEP_2 = Region('SQM_DAC_SLP_2',  1,  2,  1,  1)
        SQM_DAC_SLEEP_3 = Region('SQM_DAC_SLP_3',  1,  2,  1,  1)

        SQA_DAC_0       = Region('SQA_DAC_0'    , 47,  6,  2,  1)
        SQA_DAC_1       = Region('SQA_DAC_1'    , 47,  2,  2,  1)
        SQA_DAC_2       = Region('SQA_DAC_2'    ,  1,  6,  2,  1)
        SQA_DAC_3       = Region('SQA_DAC_3'    ,  1,  2,  2,  1)

        SQA_FBK_0       = Region('SQA_FBK_0'    , 41,  6,  7,  5)
        SQA_FBK_1       = Region('SQA_FBK_1'    , 41,  2,  7,  5)
        SQA_FBK_2       = Region('SQA_FBK_2'    ,  1,  6,  7,  5)
        SQA_FBK_3       = Region('SQA_FBK_3'    ,  1,  2,  7,  5)

        EP_CMD          = Region('EP_CMD'       , 38, 12,  1,  1)
        REGISTER_MGT    = Region('REGISTER_MGT' , 19,  8, 10, 10)

        SCIENCE_MGT     = Region('SCIENCE_MGT'  , 36, 18,  2,  2)

        # ------------------------------------------------------------------------------------------------------
        #   Reset
        # ------------------------------------------------------------------------------------------------------
        p.addModule('rst_gen(XFC92C2C2)', 'I_rst_clk_mgt|I_rst', 'rst', 'Soft')
        p.addModule('rst_gen(X0FAADB23)', 'I_rst_clk_mgt|I_rst_adc_dac', 'rst_sqm_adc_dac', 'Soft')

        p.addRegion(RESET.n, RESET.c, RESET.r, RESET.w, RESET.h, False)
        p.confineModule('rst', RESET.n)
        p.confineModule('rst_sqm_adc_dac', RESET.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_0', 'Soft', CLK_SQM_ADC_0.c, CLK_SQM_ADC_0.r, CLK_SQM_ADC_0.w, CLK_SQM_ADC_0.h, 'CLK_SQM_ADC_0_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_1', 'Soft', CLK_SQM_ADC_1.c, CLK_SQM_ADC_1.r, CLK_SQM_ADC_1.w, CLK_SQM_ADC_1.h, 'CLK_SQM_ADC_1_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_2', 'Soft', CLK_SQM_ADC_2.c, CLK_SQM_ADC_2.r, CLK_SQM_ADC_2.w, CLK_SQM_ADC_2.h, 'CLK_SQM_ADC_2_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_3', 'Soft', CLK_SQM_ADC_3.c, CLK_SQM_ADC_3.r, CLK_SQM_ADC_3.w, CLK_SQM_ADC_3.h, 'CLK_SQM_ADC_3_bis', False)

        p.addModule('im_ck(X369A4EF0)', 'I_rst_clk_mgt|G_column_mgt[0].I_sqm_adc', 'ck_adc_0', 'Soft')
        p.addModule('im_ck(X369A4EF0)', 'I_rst_clk_mgt|G_column_mgt[1].I_sqm_adc', 'ck_adc_1', 'Soft')
        p.addModule('im_ck(X369A4EF0)', 'I_rst_clk_mgt|G_column_mgt[2].I_sqm_adc', 'ck_adc_2', 'Soft')
        p.addModule('im_ck(X369A4EF0)', 'I_rst_clk_mgt|G_column_mgt[3].I_sqm_adc', 'ck_adc_3', 'Soft')

        p.addRegion(CLK_SQM_ADC_0.n, CLK_SQM_ADC_0.c, CLK_SQM_ADC_0.r, CLK_SQM_ADC_0.w, CLK_SQM_ADC_0.h, False)
        p.addRegion(CLK_SQM_ADC_1.n, CLK_SQM_ADC_1.c, CLK_SQM_ADC_1.r, CLK_SQM_ADC_1.w, CLK_SQM_ADC_1.h, False)
        p.addRegion(CLK_SQM_ADC_2.n, CLK_SQM_ADC_2.c, CLK_SQM_ADC_2.r, CLK_SQM_ADC_2.w, CLK_SQM_ADC_2.h, False)
        p.addRegion(CLK_SQM_ADC_3.n, CLK_SQM_ADC_3.c, CLK_SQM_ADC_3.r, CLK_SQM_ADC_3.w, CLK_SQM_ADC_3.h, False)

        p.confineModule('ck_adc_0', CLK_SQM_ADC_0.n)
        p.confineModule('ck_adc_1', CLK_SQM_ADC_1.n)
        p.confineModule('ck_adc_2', CLK_SQM_ADC_2.n)
        p.confineModule('ck_adc_3', CLK_SQM_ADC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_0', 'Soft', SQM_ADC_PWDN_0.c, SQM_ADC_PWDN_0.r, SQM_ADC_PWDN_0.w, SQM_ADC_PWDN_0.h, SQM_ADC_PWDN_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_1', 'Soft', SQM_ADC_PWDN_1.c, SQM_ADC_PWDN_1.r, SQM_ADC_PWDN_1.w, SQM_ADC_PWDN_1.h, SQM_ADC_PWDN_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_2', 'Soft', SQM_ADC_PWDN_2.c, SQM_ADC_PWDN_2.r, SQM_ADC_PWDN_2.w, SQM_ADC_PWDN_2.h, SQM_ADC_PWDN_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_3', 'Soft', SQM_ADC_PWDN_3.c, SQM_ADC_PWDN_3.r, SQM_ADC_PWDN_3.w, SQM_ADC_PWDN_3.h, SQM_ADC_PWDN_3.n, False)

        p.addModule('squid_adc_mgt', 'G_column_mgt[0].I_squid_adc_mgt', 'squid_adc_mgt_0', 'Soft')
        p.addModule('squid_adc_mgt', 'G_column_mgt[1].I_squid_adc_mgt', 'squid_adc_mgt_1', 'Soft')
        p.addModule('squid_adc_mgt', 'G_column_mgt[2].I_squid_adc_mgt', 'squid_adc_mgt_2', 'Soft')
        p.addModule('squid_adc_mgt', 'G_column_mgt[3].I_squid_adc_mgt', 'squid_adc_mgt_3', 'Soft')

        p.addRegion(SQM_ADC_0.n, SQM_ADC_0.c, SQM_ADC_0.r, SQM_ADC_0.w, SQM_ADC_0.h, False)
        p.addRegion(SQM_ADC_1.n, SQM_ADC_1.c, SQM_ADC_1.r, SQM_ADC_1.w, SQM_ADC_1.h, False)
        p.addRegion(SQM_ADC_2.n, SQM_ADC_2.c, SQM_ADC_2.r, SQM_ADC_2.w, SQM_ADC_2.h, False)
        p.addRegion(SQM_ADC_3.n, SQM_ADC_3.c, SQM_ADC_3.r, SQM_ADC_3.w, SQM_ADC_3.h, False)

        p.confineModule('squid_adc_mgt_0', SQM_ADC_0.n)
        p.confineModule('squid_adc_mgt_1', SQM_ADC_1.n)
        p.confineModule('squid_adc_mgt_2', SQM_ADC_2.n)
        p.confineModule('squid_adc_mgt_3', SQM_ADC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_0', 'Soft', CLK_SQM_DAC_0.c, CLK_SQM_DAC_0.r, CLK_SQM_DAC_0.w, CLK_SQM_DAC_0.h, 'CLK_SQM_DAC_0_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_1', 'Soft', CLK_SQM_DAC_1.c, CLK_SQM_DAC_1.r, CLK_SQM_DAC_1.w, CLK_SQM_DAC_1.h, 'CLK_SQM_DAC_1_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_2', 'Soft', CLK_SQM_DAC_2.c, CLK_SQM_DAC_2.r, CLK_SQM_DAC_2.w, CLK_SQM_DAC_2.h, 'CLK_SQM_DAC_2_bis', False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_3', 'Soft', CLK_SQM_DAC_3.c, CLK_SQM_DAC_3.r, CLK_SQM_DAC_3.w, CLK_SQM_DAC_3.h, 'CLK_SQM_DAC_3_bis', False)

        p.addModule('im_ck(X2C9B091B)', 'I_rst_clk_mgt|G_column_mgt[0].I_sqm_dac_out', 'squid_dac_mgt_0', 'Soft')
        p.addModule('im_ck(X2C9B091B)', 'I_rst_clk_mgt|G_column_mgt[1].I_sqm_dac_out', 'squid_dac_mgt_1', 'Soft')
        p.addModule('im_ck(X2C9B091B)', 'I_rst_clk_mgt|G_column_mgt[2].I_sqm_dac_out', 'squid_dac_mgt_2', 'Soft')
        p.addModule('im_ck(X2C9B091B)', 'I_rst_clk_mgt|G_column_mgt[3].I_sqm_dac_out', 'squid_dac_mgt_3', 'Soft')

        p.addRegion(CLK_SQM_DAC_0.n, CLK_SQM_DAC_0.c, CLK_SQM_DAC_0.r, CLK_SQM_DAC_0.w, CLK_SQM_DAC_0.h, False)
        p.addRegion(CLK_SQM_DAC_1.n, CLK_SQM_DAC_1.c, CLK_SQM_DAC_1.r, CLK_SQM_DAC_1.w, CLK_SQM_DAC_1.h, False)
        p.addRegion(CLK_SQM_DAC_2.n, CLK_SQM_DAC_2.c, CLK_SQM_DAC_2.r, CLK_SQM_DAC_2.w, CLK_SQM_DAC_2.h, False)
        p.addRegion(CLK_SQM_DAC_3.n, CLK_SQM_DAC_3.c, CLK_SQM_DAC_3.r, CLK_SQM_DAC_3.w, CLK_SQM_DAC_3.h, False)

        p.confineModule('squid_dac_mgt_0', CLK_SQM_DAC_0.n)
        p.confineModule('squid_dac_mgt_1', CLK_SQM_DAC_1.n)
        p.confineModule('squid_dac_mgt_2', CLK_SQM_DAC_2.n)
        p.confineModule('squid_dac_mgt_3', CLK_SQM_DAC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_0', 'Soft', SQM_DAC_SLEEP_0.c, SQM_DAC_SLEEP_0.r, SQM_DAC_SLEEP_0.w, SQM_DAC_SLEEP_0.h, SQM_DAC_SLEEP_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_1', 'Soft', SQM_DAC_SLEEP_1.c, SQM_DAC_SLEEP_1.r, SQM_DAC_SLEEP_1.w, SQM_DAC_SLEEP_1.h, SQM_DAC_SLEEP_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_2', 'Soft', SQM_DAC_SLEEP_2.c, SQM_DAC_SLEEP_2.r, SQM_DAC_SLEEP_2.w, SQM_DAC_SLEEP_2.h, SQM_DAC_SLEEP_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_3', 'Soft', SQM_DAC_SLEEP_3.c, SQM_DAC_SLEEP_3.r, SQM_DAC_SLEEP_3.w, SQM_DAC_SLEEP_3.h, SQM_DAC_SLEEP_3.n, False)

        p.addModule('pulse_shaping(X47E1BBE6)', 'G_column_mgt[0].I_sqm_dac_mgt|I_pulse_shaping', 'sqm_dac_pls_mgt_0', 'Soft')
        p.addModule('pulse_shaping(XEECAB54F)', 'G_column_mgt[1].I_sqm_dac_mgt|I_pulse_shaping', 'sqm_dac_pls_mgt_1', 'Soft')
        p.addModule('pulse_shaping(XEECAB54F)', 'G_column_mgt[2].I_sqm_dac_mgt|I_pulse_shaping', 'sqm_dac_pls_mgt_2', 'Soft')
        p.addModule('pulse_shaping(X47E1BBE6)', 'G_column_mgt[3].I_sqm_dac_mgt|I_pulse_shaping', 'sqm_dac_pls_mgt_3', 'Soft')

        p.addRegion(SQM_DAC_PLS_0.n, SQM_DAC_PLS_0.c, SQM_DAC_PLS_0.r, SQM_DAC_PLS_0.w, SQM_DAC_PLS_0.h, False)
        p.addRegion(SQM_DAC_PLS_1.n, SQM_DAC_PLS_1.c, SQM_DAC_PLS_1.r, SQM_DAC_PLS_1.w, SQM_DAC_PLS_1.h, False)
        p.addRegion(SQM_DAC_PLS_2.n, SQM_DAC_PLS_2.c, SQM_DAC_PLS_2.r, SQM_DAC_PLS_2.w, SQM_DAC_PLS_2.h, False)
        p.addRegion(SQM_DAC_PLS_3.n, SQM_DAC_PLS_3.c, SQM_DAC_PLS_3.r, SQM_DAC_PLS_3.w, SQM_DAC_PLS_3.h, False)

        p.confineModule('sqm_dac_pls_mgt_0', SQM_DAC_PLS_0.n)
        p.confineModule('sqm_dac_pls_mgt_1', SQM_DAC_PLS_1.n)
        p.confineModule('sqm_dac_pls_mgt_2', SQM_DAC_PLS_2.n)
        p.confineModule('sqm_dac_pls_mgt_3', SQM_DAC_PLS_3.n)

        p.addModule('sqm_dac_mgt(X0097C298)', 'G_column_mgt[0].I_sqm_dac_mgt', 'sqm_dac_mgt_0', 'Soft')
        p.addModule('sqm_dac_mgt(XECC18118)', 'G_column_mgt[1].I_sqm_dac_mgt', 'sqm_dac_mgt_1', 'Soft')
        p.addModule('sqm_dac_mgt(XECC18118)', 'G_column_mgt[2].I_sqm_dac_mgt', 'sqm_dac_mgt_2', 'Soft')
        p.addModule('sqm_dac_mgt(X0097C298)', 'G_column_mgt[3].I_sqm_dac_mgt', 'sqm_dac_mgt_3', 'Soft')

        p.addRegion(SQM_DAC_0.n, SQM_DAC_0.c, SQM_DAC_0.r, SQM_DAC_0.w, SQM_DAC_0.h, False)
        p.addRegion(SQM_DAC_1.n, SQM_DAC_1.c, SQM_DAC_1.r, SQM_DAC_1.w, SQM_DAC_1.h, False)
        p.addRegion(SQM_DAC_2.n, SQM_DAC_2.c, SQM_DAC_2.r, SQM_DAC_2.w, SQM_DAC_2.h, False)
        p.addRegion(SQM_DAC_3.n, SQM_DAC_3.c, SQM_DAC_3.r, SQM_DAC_3.w, SQM_DAC_3.h, False)

        p.confineModule('sqm_dac_mgt_0', SQM_DAC_0.n)
        p.confineModule('sqm_dac_mgt_1', SQM_DAC_1.n)
        p.confineModule('sqm_dac_mgt_2', SQM_DAC_2.n)
        p.confineModule('sqm_dac_mgt_3', SQM_DAC_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID AMP DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('sqa_dac_mgt', 'G_column_mgt[0].I_sqa_dac_mgt', 'sqa_dac_mgt_0', 'Soft')
        p.addModule('sqa_dac_mgt', 'G_column_mgt[1].I_sqa_dac_mgt', 'sqa_dac_mgt_1', 'Soft')
        p.addModule('sqa_dac_mgt', 'G_column_mgt[2].I_sqa_dac_mgt', 'sqa_dac_mgt_2', 'Soft')
        p.addModule('sqa_dac_mgt', 'G_column_mgt[3].I_sqa_dac_mgt', 'sqa_dac_mgt_3', 'Soft')

        p.addRegion(SQA_DAC_0.n, SQA_DAC_0.c, SQA_DAC_0.r, SQA_DAC_0.w, SQA_DAC_0.h, False)
        p.addRegion(SQA_DAC_1.n, SQA_DAC_1.c, SQA_DAC_1.r, SQA_DAC_1.w, SQA_DAC_1.h, False)
        p.addRegion(SQA_DAC_2.n, SQA_DAC_2.c, SQA_DAC_2.r, SQA_DAC_2.w, SQA_DAC_2.h, False)
        p.addRegion(SQA_DAC_3.n, SQA_DAC_3.c, SQA_DAC_3.r, SQA_DAC_3.w, SQA_DAC_3.h, False)

        p.confineModule('sqa_dac_mgt_0', SQA_DAC_0.n)
        p.confineModule('sqa_dac_mgt_1', SQA_DAC_1.n)
        p.confineModule('sqa_dac_mgt_2', SQA_DAC_2.n)
        p.confineModule('sqa_dac_mgt_3', SQA_DAC_3.n)

        p.addModule('sqa_fbk_mgt', 'G_column_mgt[0].I_sqa_fbk_mgt', 'sqa_fbk_mgt_0', 'Soft')
        p.addModule('sqa_fbk_mgt', 'G_column_mgt[1].I_sqa_fbk_mgt', 'sqa_fbk_mgt_1', 'Soft')
        p.addModule('sqa_fbk_mgt', 'G_column_mgt[2].I_sqa_fbk_mgt', 'sqa_fbk_mgt_2', 'Soft')
        p.addModule('sqa_fbk_mgt', 'G_column_mgt[3].I_sqa_fbk_mgt', 'sqa_fbk_mgt_3', 'Soft')

        p.addRegion(SQA_FBK_0.n, SQA_FBK_0.c, SQA_FBK_0.r, SQA_FBK_0.w, SQA_FBK_0.h, False)
        p.addRegion(SQA_FBK_1.n, SQA_FBK_1.c, SQA_FBK_1.r, SQA_FBK_1.w, SQA_FBK_1.h, False)
        p.addRegion(SQA_FBK_2.n, SQA_FBK_2.c, SQA_FBK_2.r, SQA_FBK_2.w, SQA_FBK_2.h, False)
        p.addRegion(SQA_FBK_3.n, SQA_FBK_3.c, SQA_FBK_3.r, SQA_FBK_3.w, SQA_FBK_3.h, False)

        p.confineModule('sqa_fbk_mgt_0', SQA_FBK_0.n)
        p.confineModule('sqa_fbk_mgt_1', SQA_FBK_1.n)
        p.confineModule('sqa_fbk_mgt_2', SQA_FBK_2.n)
        p.confineModule('sqa_fbk_mgt_3', SQA_FBK_3.n)

        # ------------------------------------------------------------------------------------------------------
        #   EP SPI constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('spi_slave(XCA4B7C09)', 'I_ep_cmd|I_spi_slave', 'ep_cmd_spi_slave', 'Soft')
        p.addRegion(EP_CMD.n, EP_CMD.c, EP_CMD.r, EP_CMD.w, EP_CMD.h, False)
        p.confineModule('ep_cmd_spi_slave', EP_CMD.n)

        p.addModule('ep_cmd', 'I_ep_cmd', 'ep_cmd', 'Soft')
        p.addRegion(REGISTER_MGT.n, REGISTER_MGT.c, REGISTER_MGT.r, REGISTER_MGT.w, REGISTER_MGT.h, False)
        p.confineModule('ep_cmd', REGISTER_MGT.n)

        # ------------------------------------------------------------------------------------------------------
        #   Science constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('science_data_mgt', 'I_science_data_mgt', 'science_data_mgt', 'Soft')
        p.addRegion(SCIENCE_MGT.n, SCIENCE_MGT.c, SCIENCE_MGT.r, SCIENCE_MGT.w, SCIENCE_MGT.h, False)
        p.confineModule('science_data_mgt', SCIENCE_MGT.n)

        # ------------------------------------------------------------------------------------------------------
        #   Internal constraints
        # ------------------------------------------------------------------------------------------------------
        p.addModule('register_mgt', 'I_register_mgt', 'register_mgt', 'Soft')
        p.confineModule('register_mgt', REGISTER_MGT.n)

def placing_constraints(p,modelboard):
    if   modelboard == 'dk':

        # ------------------------------------------------------------------------------------------------------
        #   Mapping directive
        # ------------------------------------------------------------------------------------------------------
        p.injectLowskew('rst')
        p.injectLowskew('rst_sqm_adc_dac')
        p.setSite('I_top_dmx_dm_clk|I_rst_clk_mgt|rst_sqm_adc_dac_lc_reg','TILE[32x2]')

        p.setSite('*G_column_mgt[0].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[21x14]')
        p.setSite('*G_column_mgt[1].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[23x14]')
        p.setSite('*G_column_mgt[2].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[25x14]')
        p.setSite('*G_column_mgt[3].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[27x14]')

    elif modelboard == 'dm':

        # ------------------------------------------------------------------------------------------------------
        #   WFG location
        # ------------------------------------------------------------------------------------------------------
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk','CKG3.WFG_C1')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_adc_dac','CKG3.WFG_C2')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_90','CKG3.WFG_C3')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_adc_dac_90','CKG3.WFG_C4')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_adc_out','CKG3.WFG_M1')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_dac_out','CKG3.WFG_M2')
        p.addWFGLocation('I_rst_clk_mgt|I_pll|I_wfg_clk_sync_ref','CKG3.WFG_M3')

        # ------------------------------------------------------------------------------------------------------
        #   Mapping directive
        # ------------------------------------------------------------------------------------------------------
        p.injectLowskew('rst')
        p.injectLowskew('rst_sqm_adc_dac')
        p.setSite('I_rst_clk_mgt|rst_sqm_adc_dac_lc_reg','TILE[37x22]')
        p.setSite('*G_column_mgt[0].I_squid_adc_mgt|rst_sqm_adc_dac_lc*','TILE[30x18]')

        p.setSite('*G_column_mgt[0].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[33x6]')
        p.setSite('*G_column_mgt[1].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[25x18]')
        p.setSite('*G_column_mgt[2].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[17x18]')
        p.setSite('*G_column_mgt[3].I_sqm_fbk_mgt|o_sqm_data_fbk_reg*','TILE[15x6]')

def routing_constraints(p,modelboard):
    print("No routing common constraints")

def add_constraints(p,modelboard,step):
    if step == "Synthesize":
        synthesis_constraints(p,modelboard)
    elif step == "Place":
        placing_constraints(p,modelboard)
    elif step == "Route":
        routing_constraints(p,modelboard)
