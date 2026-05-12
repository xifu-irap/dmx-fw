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
#    @file                   gen_trace_matrix.ps1
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Generation of Requirement Traceability Matrix from pattern located in directories of source files.
#                             The pattern must be separated from requirement tag by a colon (:).
#                                * Command line argument 0: model board (dk, dm, em)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Parameter declaration
$model_board=$args[0]

if ($model_board -eq "dk")
{
   $source_path      = "..\..\src\common","..\..\src\dm","..\..\ip\nx\NG-LARGE" # Paths of source directory to analyse
   $file_out_dir     = "..\result\dk"                                           # Path of generated output file
}
elseif ($model_board -eq "dm")
{
   $source_path      = "..\..\src\common","..\..\src\dm","..\..\ip\nx\NG-LARGE" # Paths of source directory to analyse
   $file_out_dir     = "..\result\dm"                                           # Path of generated output file
}
else
{
   $source_path      = "..\..\src\common","..\..\src\em","..\..\ip\nx\U300"     # Paths of source directory to analyse
   $file_out_dir     = "..\result\em"                                           # Path of generated output file
}

$comment_pattern  = "--"                                             # Comment pattern of files to analyse
$req_pattern      = "@Req"                                           # Requirement pattern of files to analyse
$file_out_name    = "Traceability.csv"                               # File output name with extension

$file_out_header  = "Requirement ID;File name;Line number in file"
$file_temp       = "$($file_out_name).old"                           # Temporary file

# Write header in Temporary file
write-Output "$($file_out_header)"> $file_out_dir\$file_temp

# Initialize source directory paths
$source_dir_list = $source_path -split ","
$source_dir = @()

# Get the list of the files included in each source directory
for($path_num=0; $path_num -lt $source_dir_list.length;$path_num++)
{
   $source_dir += Get-ChildItem -path $($source_dir_list[$path_num]) -File
}

foreach ($source_file in $source_dir)
{
   # Get the lines including requirement pattern in the source files
   $select_file = select-string -path $source_file.FullName -pattern $req_pattern

   foreach ($source_line in $select_file)
   {
      $source_field    = $source_line -split ":"                                                               # Split the requirement pattern line in more fields
      $source_field[4] = $source_field[4] -replace " "                                                         # Drop space included in the requirement pattern field
      write-Output "$($source_field[4]);$($source_file.Name);$($source_field[2])">> $file_out_dir\$file_temp   # Reorganize requirement pattern field before writing in temporary file
   }
}

# Split first line of output file header in more fields
$file_out_col = $file_out_header -split ";"

# Sort the Temporary file table following the order:
#   1.Requirement ID
#   2.File name
#   3.Line number in file
# Write result in final file
import-csv $file_out_dir\$file_temp -Delimiter ';' | sort-object -Property "$($file_out_col[0])", "$($file_out_col[1])", "$($file_out_col[2])" | export-csv $file_out_dir\$file_out_name -notypeinformation -Delimiter ';'

# Delete Temporary file
del $file_out_dir\$file_temp