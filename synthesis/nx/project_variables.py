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
#    @file                   project_variables.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nx project variables
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Project variables
DefaultProjectName  = 'dmx-fw'
DefaultModelBoard   = 'dm'
AllowedModelBoard   = ['dk','dm','em']
DefaultVariants     = ['NG-LARGE','NG-LARGE','ULTRA300']
DefaultTopCellName  = ['top_dmx_dk','top_dmx_dm','top_dmx_em']
#NanoXplore tool variables
DefaultTopCellLib   = 'work'
DefaultSeed         = ['1120','1920','XXXX']
DefaultTimingDriven = 'Yes'
DefaultSta          = 'routed'
DefaultStaCondition = 'worstcase'
DefaultBitstream    = 'Yes'
