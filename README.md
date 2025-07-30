# dmx-fw
DRE-DEMUX TDM firmware: https://github.com/xifu-irap/dmx-fw

   - FPGA target: DK/DM: NG-LARGE (NanoXplore)
   - Synthesis tool: nxdesignsuite v24.3.0.0
   - Firmware specification:
      + IRAP/XIFU-DRE/FM/SP/0065 - DRE TDM firmware requirements, ed. 1.0
      + IRAP/XIFU-DRE/FM/SP/0069 - DRE Inter-Modules Telemetry And Commands Definition, ed. 5.0
      + IRAP/XIFU-DRE/FM/SP/0136 - FPAsim command dictionnary, ed. ??
   - FPASIM simulation coupling: https://github.com/xifu-irap/fpasim-fw (tag 2.2.3)

## 1. Directories and files description

   - (dir.) **constraints**: Synthesis tool constraints
      + (file) **nx/project_constraints.py**: constraints project
      + (file) **nx/project_ios.py**: I/O FPGA declaration
      + (file) **nx/project_parameters.py**: parameters project
      + (file) **nx/project_options.py**: options project
   - (dir.) **ip**: Synthesize source files linked to the FPGA technology
   - (dir.) **simu**: Simulation directory
      + (dir.) **conf**: Unitary test configuration files
      + (dir.) **result**: Unitary test results
      + (dir.) **script**: Modelsim scripts
      + (dir.) **tb**: Test bench and model component files for simulation
      + (dir.) **utest**: Unitary test scripts
   - (dir.) **src**: Synthesize source files independent to FPGA technology
   - (dir.) **synthesis**: Script files used by the synthesis tool
   - (file) **clean.sh**: Clean the project directories

## 2. Commands

   Questasim and nxdesignsuite must be previously installed.

   The parameters of the modelsim.ini file must be configured as follows:
   PathSeparator = :
   DatasetSeparator = /

   The script simu/script/no_regression.do must indicated the NX_MODEL_PATH where are located the vhdp files (deliver in nxdesignsuite archive and located in /share/modelsim/).
     $model_board: dk (Devkit Model), dm (Demonstrator Model), em (Engineering Model)

   - Synthesis tool:
      1. Position to the root path directory
      2. Run command: nxpython /synthesis/nx/nx_script.py --modelboard $model_board


   - No regression analysis (<path_dmx_fw> replaced by the Demux firmware location):
      1. Position to the path directory for result simulation storage (choosen by user)
      2. Run command: vsim -do <path_dmx_fw>/simu/script/run.do -l transcript
      3. The no regression results are stored in directory /simu/result


   - Code coverage analysis:
      1. Run no regression analysis
      2. Position to the path directory for result simulation storage (choosen by user)
      3. The code coverage analysis is stored in directory /coverage/$model_board/coverage/index.html


   - Play a specific unitary test, signal chronograms display (<path_dmx_fw> replaced by the Demux firmware location):
      1. Position to the path directory for result simulation storage (choosen by user)
      2. Run Questasim: vsim
      3. Run command: do <path_dmx_fw>/simu/script/no_regression.do $model_board
      4. Run function (XXXX: unitary test number on 4 characters): run_utest XXXX
      5. The unitary test result is stored in directory /simu/result/$model_board


   - Requirement Traceability Matrix
      1. Open Powershell
      2. Position to the root path directory
      3. Position to the path /simu/script/
      4. Run gen_trace_matrix.ps1 $model_board
      5. The Requirement Traceability Matrix is stored in directory /simu/result/$model_board

## 3. New unitary test creation

   For a new unitary test, it is necessary to create the following files, XXXX corresponding to unitary test number on 4 characters:
   - A script file named DRE_DMX_UT_XXXX, located in directory /simu/utest/$model_board, which describes the test scenario in the form of sequential commands
   - A configuration VHDL file named DRE_DMX_UT_XXXX_cfg.vhd, located in directory /simu/conf/$model_board, which describes the static parameters of the test.

   The configuration VHDL file can include the non nominal parameter generics of model components used by the unitary test, the generics of parser must be absolutely defined:
   - g_SIM_TIME (time)  : Simulation time
   - g_BRD_MDL  (string): Board model ("dk","dm","em")
   - g_TST_NUM  (string): Test number, corresponds to the XXXX value

## 4. Discrete inputs description (seen from simulation pilot side)

   Discrete inputs are grouped together in a 64 bits field (bit position 63 is the MSB, bit position 0 is the LSB):
   - Position 0: **rst**, Internal DRE-DEMUX: Reset asynchronous assertion, synchronous de-assertion on System Clock
   - Position 1: **clk_ref**, DRE-DEMUX input, Reference Clock
   - Position 2: **clk**, Internal DRE-DEMUX: System Clock
   - Position 3: **clk_sqm_adc_acq**, Internal DRE-DEMUX: SQUID MUX ADC Clock
   - Position 4: **clk_sqm_pls_shape**, Internal DRE-DEMUX: SQUID MUX pulse shaping Clock
   - Position 5: **ep_cmd_busy_n**, EP SPI model output, EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
   - Position 6: **ep_data_rx_rdy**, EP SPI model output, EP - Receipted data ready ('0' = Not ready, '1' = Ready)
   - Position 7+x:  **rst_sqm_adc(x)**, Internal DRE-DEMUX: Local reset asynchronous assertion, synchronous de-assertion on SQUID MUX ADC column 'x' (0->3)
   - Position 11+x: **rst_sqm_dac(x)**, Internal DRE-DEMUX: Local reset asynchronous assertion, synchronous de-assertion on SQUID MUX DAC column 'x' (0->3)
   - Position 15+x: **rst_sqa_mux(x)**, Internal DRE-DEMUX: Local reset asynchronous assertion, synchronous de-assertion on SQUID AMP MUX column 'x' (0->3)
   - Position 19: **sync**, Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   - Position 20+x: **sqm_adc_pwdn(x)**, SQUID MUX ADC column 'x' (0->3) – ADC Power Down ('0' = Inactive, '1' = Active)
   - Position 24+x: **sqm_dac_sleep(x)**, SQUID MUX DAC column 'x' (0->3) – DAC Sleep ('0' = Inactive, '1' = Active)
   - Position 28+x: **clk_sqm_adc(x)**, SQUID MUX ADC column 'x' (0->3) - Clock
   - Position 32+x: **clk_sqm_dac(x)**, SQUID MUX DAC column 'x' (0->3) - Clock
   - Position 36+x: **fpa_conf_busy(x)**, FPASIM column 'x' (0->3) - configuration ('0' = conf. over, '1' = conf. in progress)
   - Position 40: **clk_science_01**, Science Data, clock column 0/1
   - Position 41: **clk_science_23**, Science Data, clock column 2/3
   - Position 63-42: Not Used


## 5. Discrete outputs description (seen from simulation pilot side)

   Discrete outputs are grouped together in a 64 bits field (bit position 63 is the MSB, bit position 0 is the LSB):
  - Position 0: **arst_n**, DRE-DEMUX input, Asynchronous reset ('0' = Active, '1' = Inactive) NOT USED ANYMORE (generated inside the design)
  - Position 3-1: **brd_model(y)**, DRE-DEMUX input, Board model bit 'y' (0->2)
  - Position 5-4: **sw_adc_vin(1)/sw_adc_vin(0)**, SQUID model input, Switch ADC Voltage input ("00": SQUID MUX DAC voltage, "01": SQUID AMP DAC voltage, "10": FPASIM Error voltage)
  - Position 6: **frm_cnt_sc_rst**, Science Data model input, Frame counter science reset ('0' = Active, '1' = Inactive)
  - Position 7: **ras_data_valid**, RAS Data valid ('0' = No, '1' = Yes)


## 6. Check parameters enable (seen from simulation pilot side)

   Enable the display in result file of the report about the check parameters.
   Enables are grouped together in a 64 bits field (bit position 63 is the MSB, bit position 0 is the LSB):
   - **clk**, Internal DRE-DEMUX: System Clock
   - **clk_sqm_adc**, Internal DRE-DEMUX: SQUID MUX ADC Clock
   - **clk_sqm_pls_shape**, Internal DRE-DEMUX: SQUID MUX pulse shaping Clock
   - **clk_sqm_adc(x)**, Clock SQUID MUX ADC column 'x' (0->3)
   - **clk_sqm_dac(x)**, Clock SQUID MUX DAC column 'x' (0->3)
   - **clk_science_01**, Science Data - Clock channel 0/1
   - **clk_science_23**, Science Data - Clock channel 2/3

   - **spi_hk**, SPI ADC Housekeeping
   - **spi_sqa_lsb(x)**, SPI SQUID AMP DAC LSB column 'x' (0->3)
   - **spi_sqa_off(x)**, SPI SQUID AMP DAC Offset column 'x' (0->3)

   - **pulse_shaping**, SQUID MUX DAC pulse shaping


## 7. Science packet type

   Select the science packet type
   - **data_word**
   - **science**
   - **test_pattern**
   - **adc_dump**
   - **adc_data**
   - **ras_data_valid**
   - **demux_data_valid**


## 8. Unitary test script commands description

   The /simu/tb/parser.vhd file interprets the 4 characters commands located in the unitary test script.

   The commands are as follows:
   - Command CCMD **cmd** **end**: check the EP command return
      + Parameter **cmd** : EP command return value expected, constituted by the following fields, separated by delimiter "-" (Ex: R-Status-XXXX, R-Version-FW_VERSION-00):
         * *access* :
            * Value *R*: Mode read
            * Value *W*: Mode write
         * *address*: EP command name. Two manners to declare:
            * Either 16 bits hexa (underscore can be inserted), take back the register address specified in IRAP/XIFU-DRE/FM/SP/0069
            * Or take back the register name specified in IRAP/XIFU-DRE/FM/SP/0069 (case sensitive). Index between parenthesis can be informed for tables.
         * *data*: 16 bits hexa (underscore can be inserted), EP command return data. For the "Version" command, data can be dispatched by the field FW_VERSION, followed by 8 bits hexa
      + Parameter **end**:
         * Value *W*: wait the end of EP command transmit before handle a new command script
         * Value *N*: no wait time


   - Command CCPE **report** : Enable the display in result file of the report about the check parameters
      + Parameter **report** : parameters report select (see 6 on check parameters enable description)


   - Command CDIS **discrete_r** **value**: check discrete input
      + Parameter **discrete_r** : discrete input select (see 4 on discrete inputs description)
      + Parameter **value** : (1 bit U/X/0/1/Z/W/L/H/-) discrete input value expected


   - Command CLDC **channel** **value**: check level SQUID MUX ADC input (SQUID MUX/SQUID AMP DAC voltage can be loop back thanks to discrete outputs sw_adc_vin)
      + Parameter **channel**: decimal range 0 to c_NB_COL-1, channel number
      + Parameter **value** : SQUID MUX ADC input value expected in real


   - Command CSCP **science_ctrl_pos** **science_packet** : check the science packet type
      + Parameter **science_ctrl_pos**: decimal range 0 to c_SC_PKT_W_NB-1, science control position
      + Parameter **science_packet** : science packet type select (see 7 on science packet type description)


   - Command CTDC **channel** **ope** **time**: check time between the current time and last event SQUID MUX ADC input
      + Parameter **channel**: decimal range 0 to c_NB_COL-1, channel number
      + Parameter **ope** : ( ==, /=, <<, <=, >>, >= ), comparison operation
      + Parameter **time**: (decimal with unit ps, ns, us, ms, sec), comparison time


   - Command CTLE **discrete_r** **ope** **time**: check time between the current time and discrete input(s) last event
      + Parameter **discrete_r** : discrete input select (see 4 on discrete inputs description)
      + Parameter **ope** : ( ==, /=, <<, <=, >>, >= ), comparison operation
      + Parameter **time**: (decimal with unit ps, ns, us, ms, sec), comparison time


   - Command CTLR **ope** **time**: check time from the last record time
      + Parameter **ope** : ( ==, /=, <<, <=, >>, >= ), comparison operation
      + Parameter **time**: (decimal with unit ps, ns, us, ms, sec), comparison time


   - Command COMM: add comment in result file


   - Command RTIM: record current time


   - Command WAIT **time**: wait for time
      + Parameter **time**: (decimal with unit ps, ns, us, ms, sec), time to wait


   - Command WCMD **cmd** **end**: transmit EP command
      + Parameter **cmd** : EP command, constituted by the following fields, separated by delimiter "-" (Ex: R-Status-XXXX):
         * *access* :
            * Value *R*: Mode read
            * Value *W*: Mode write
         * *address*: EP command name. Two manners to declare:
            * Either 16 bits hexa (underscore can be inserted), take back the register address specified in IRAP/XIFU-DRE/FM/SP/0069
            * Or take back the register name specified in IRAP/XIFU-DRE/FM/SP/0069 (case sensitive). Index between parenthesis can be informed for tables.
         * *data*: 16 bits hexa (underscore can be inserted), EP command data
      + Parameter **end**:
         * Value *W*: wait the end of EP command transmit before handle a new command script
         * Value *R*: wait the end of EP command return (last command before) before handle a new command script
         * Value *N*: no wait time


   - Command WCMS **size**: write EP command word size (error case test)
      + Parameter **size** : decimal range 1 to 63, EP command word size


   - Command WDIS **discrete_w** **value**: write discrete output
      + Parameter **discrete_w** : discrete output select (see 5 on discrete outputs description)
      + Parameter **value** : (1 bit U/X/0/1/Z/W/L/H/-) discrete output value


   - Command WFMP **channel** **data**: write FPASIM "Make pulse" command
      + Parameter **channel** : decimal range 0 to c_NB_COL-1, channel number
      + Parameter **data** : 32 bits hexa (underscore can be inserted), FPASIM "Make pulse" data as defined by IRAP/XIFU-DRE/FM/SP/0136


   - Command WMDC **channel** **frame** **index** **data**: Write in ADC dump/science memories for data compare
      + Parameter **channel** : decimal range 0 to c_NB_COL-1, channel number
      + Parameter **frame** : decimal range 0 to c_MEM_SC_DTA_FRM_NB-1, frame number
      + Parameter **index** : decimal range 0 to c_MUX_FACT-1, memory index
      + Parameter **data**  : 32 bits hexa (underscore can be inserted), data ADC dump (16 bits) & Science (16 bits) to compare


   - Command WNBD **number**: write board reference number
      + Parameter **number**: decimal range 0 to 31, board reference number


   - Command WPFC **channel** **frequency**: write pulse shaping cut frequency for verification
      + Parameter **channel**: decimal range 0 to c_NB_COL-1, channel number
      + Parameter **frequency**: cut frequency in decimal (Hz)


   - Command WUDI **discrete_r** **value** or WUDI **mask** **data**: wait until event on discrete input(s)
      + Parameter **discrete_r** : discrete input select (see 4 on discrete inputs description)
      + Parameter **value** : (1 bit U/X/0/1/Z/W/L/H/-) discrete input value expected
      + Parameter **mask** : 64 bits hexa (underscore can be inserted), selection mask on discrete inputs (see 4 on discrete inputs description)
      + Parameter **data** : 64 bits hexa (underscore can be inserted), discrete inputs value expected

## 9. Unitary test result

   The unitary test result file is considered as pass when the last line mention "Simulation status: PASS" (FAIL otherwise).

   The dated warnings and errors are mentioned in the result file. The following global errors are indicated:
   - Error simulation time: The simulation time is not enough for handling all unitary test script commands => necessity to modify generic parameter g_SIM_TIME in the configuration VHDL file.
   - Error check discrete level: one or more discrete inputs level do not correspond to the expected value.
   - Error check command return: one or more EP command returns do not correspond to the expected value.
   - Error check time: one or more check times do not correspond to the expected comparison time.
   - Error check clocks parameters: clocks parameters error(s).
   - Error check spi parameters: spi bus parameters error(s).
   - Error check science packets: science packets error(s) (see scd result file for description).
   - Error check pulse shaping: SQUID MUX DAC pulse shaping error.


   The file transcript generated by Questasim must equally analyzed in order to detect eventual errors and warnings.

## 10. Devkit Model (DK)

   Pin compatibility with:
      + IRAP/XIFU-DRE/DM/SP/0148 - NG-LARGE DEVKIT/MEDUSA BENCH ICD, Ed. 2.3
      + TMTC-fw firmware 0015

   Implementation dmx-fw firmware on NG-LARGE Devkit with specific adaptation:
   - RAS Data Valid wired on Switch SW4
   - EP SPI select  wired on Switch SW5:
      + position right (GND select): SPI master from HE10
      + position left  (VCC select): SPI master from FMC1
   - Reference Clock wired on connector J9
   - Board reference field stucked to value 0b00000
   - Board model field stucked to value 0b111
   - Pixel sequence synchronization generated inside FPGA
   - Squid MUX DAC outputs looped back on ADC inputs
   - Squid AMP links opened
   - HK SPI emulated with the following values:
      + HK_P1V8_ANA: 1170
      + HK_P2V5_ANA:  878
      + HK_M2V5_ANA: 1463
      + HK_P3V3_ANA:  585
      + HK_M5V0_ANA: 1755
      + HK_P1V2_DIG: 2633
      + HK_P2V5_DIG: 2340
      + HK_P2V5_AUX: 3510
      + HK_P3V3_DIG: 2048
      + HK_VREF_TMP: 3803
      + HK_VREF_R2R: 4000
      + HK_VGND_OFF: 1261
      + HK_P5V0_ANA:  293
      + HK_TEMP_AVE: 2925
      + HK_TEMP_MAX: 3218
