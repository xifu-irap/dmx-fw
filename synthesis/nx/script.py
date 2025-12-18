# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Kevin Chopier, IRAP Toulouse.
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
#    email                   kchopier@nanoxplore.com
#    @file                   script.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Main Nx synthesis script
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

####################################################################################################
#########################################GLOBAL DECLARATION#########################################
####################################################################################################

#########################################LIBRARY IMPORTATION########################################
import sys
import traceback
import os
import time
import csv

from nxpython import *

from project_class import project_class

def print_duration(start_time,end_time):
    '''Get the duration in h, m and s'''
    duration = int(end_time - start_time)
    hours    = int(float(duration) / float(3600))
    minutes  = int((float(duration) - float(hours*3600)) / float(60))
    seconds  = int((float(duration) - float(hours*3600) - float(minutes*60)))
    printText('ELAPSED TIME: ' + str(hours) + ' hours ' + str(minutes) + ' minutes ' + str(seconds) + ' seconds' )

def __main__(ProjectName,ModelBoard,Variant,TopCellName,TopCellLib,Seed,TimingDriven,Sta,StaCondition,Bitstream,Progress,Suffix):

    ##########################################GLOBAL CONSTANT###########################################

    start_time = time.time()

    script_path  = os.getcwd()

    sources_files_directory = script_path + '/src'

    # Get Firmware ID
    with open(sources_files_directory + '/common/pkg_project.vhd') as pkg_project:
        reader_line = csv.reader(pkg_project, delimiter='#')

        for line in reader_line:
            if len(line) > 1:
                field = line[0].split()

                if field[1] == 'c_FW_VERSION':
                    Firmware_ID = line[1]

    BitstreamName = ProjectName + '-' + ModelBoard + '_' + Firmware_ID

    project_path = script_path + '/../../synthesis/'+ BitstreamName + '_' + Seed

    if not Suffix=='':
        project_path+='_' + Suffix

    original_project_path = project_path
    if not Progress=='scratch':
        project_path += '_' + Progress

    if not os.path.isdir(project_path):
            os.makedirs(project_path)

    ####################################################################################################
    ##########################################PROJECT CREATION##########################################
    ####################################################################################################

    ###########################################GLOBAL SETTING###########################################

    p = createProject(project_path)

    if Progress == 'scratch':
        p.setVariantName(Variant)
        p.setTopCellName(TopCellLib,TopCellName)
    else:
        p.load(original_project_path + '/' + Progress + '.nym')

    p.setAnalysisConditions(conditions = StaCondition)

    ###########################################MODEL BOARD SETTINGS#########################################

    project_custom = project_class(ModelBoard,Variant,Seed,sources_files_directory)

    if Progress == 'scratch':
        project_custom.add_files(p)
        project_custom.add_parameters(p)
        project_custom.add_options(p,TimingDriven)
        project_custom.add_ios(p)

        p.save(project_path + '/native'+'.nym')

    ####################################################################################################
    ##########################################PROJECT PROGRESS##########################################
    ####################################################################################################

    step_progress      = ['Synthesize','Place','Route']
    progress           = ['synthesized','placed','routed']
    nb_steps           = [2,5,3]
    allowed_start_step = [['scratch'],['scratch','synthesized'],['scratch','synthesized','placed']]

    for i in range(len(step_progress)):#Progress
        if Progress in allowed_start_step[i]:#Skip step_progress progress if already done
            project_custom.add_constraints(p,step_progress[i])
            for j in range(nb_steps[i]):
                if not p.progress(step_progress[i],j+1):#Browse all steps
                    p.destroy()
                    print_duration(start_time,time.time())
                    sys.exit(1)
                else:
                    print_duration(start_time,time.time())
                p.save(project_path + '/' + progress[i] + '_'+str(j+1)+'.nym')
                if (i==1 and j==0 and (Sta=='prepared' or Sta=='all')) or (i==2 and j==2 and (Sta=='routed' or Sta=='all')):# STA after Prepared or Routed
                    Timing_analysis = p.createAnalyzer()
                    Timing_analysis.launch({'maximumSlack': 500, 'searchPathsLimit': 30})
                if j == nb_steps[i]-1:#Last step of progress
                    p.save(project_path + '/' + progress[i] + '.nym')
                    p.save(project_path + '/' + progress[i] + '.vhd')
                    if i==2:#Routed
                        p.save(project_path + '/' + progress[i] + '.sdf',StaCondition)

    ############################################PROJECT REPORT##########################################

    p.reportInstances()
    p.reportRegions()
    p.reportDesignComplexity('design_complexity.html')

    ##########################################BISTREAM GENERATION#######################################

    if Bitstream == 'Yes':
        p.setDeviceID(15)                           # Broadcast mode
        p.generateBitstream(BitstreamName + '.nxb')

    ################################################SUMMARY#############################################
    print('Errors: ', getErrorCount())
    print('Warnings: ', getWarningCount())
    printText('Design successfully generated')

    print_duration(start_time,time.time())
