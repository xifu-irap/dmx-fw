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
--!   @file                   pkg_fir.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP under-sampling filters parameters
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_fpga_tech.all;

package pkg_fir is

   -- ------------------------------------------------------------------------------------------------------
   --    SQUID AMP parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_SQA_FIR1_DCI_VAL   : integer := 32                                                               ; --! SQUID AMP: Filter FIR1 decimation value
constant c_SQA_FIR1_TAB_NW    : integer := 256                                                              ; --! SQUID AMP: Filter FIR1 table number word
constant c_SQA_FIR1_S         : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter FIR1 coefficient bus size
constant c_SQA_FIR1_FRC_S     : integer := integer(ceil(real(c_RAM_ECC_DATA_S-2) - log2(0.033186060773188))); --! SQUID AMP: Filter FIR1 coefficient fractional part
constant c_SQA_FIR1_COEF_SM_S : integer := c_SQA_FIR1_FRC_S + 1                                             ; --! SQUID AMP: Filter FIR1 coefficient sum bus size (sum slightly higher than 1.0)
constant c_SQA_FIR1_TAB_REAL  : real_vector(0 to c_SQA_FIR1_TAB_NW-1) :=                                      --! SQUID AMP: Filter FIR1 coefficients (symetrical FIR, Fs = 6.25 MHz) real vector
                               ( -0.0000000000000000000257, 0.0000000896358117296806, 0.0000003074050729944920, 0.0000005676776418460560,
                                  0.0000007747629430165470, 0.0000008254423670411830, 0.0000006117630629136700, 0.0000000240636295918251,
                                 -0.0000010458020130680500,-0.0000027010808964361800,-0.0000050366206797981300,-0.0000081353011937011800,
                                 -0.0000120644516679525000,-0.0000168723128365884000,-0.0000225846083397909000,-0.0000292012947339411000,
                                 -0.0000366935637659348000,-0.0000450011741421972000,-0.0000540301925940706000,-0.0000636512253759712000,
                                 -0.0000736982212040602000,-0.0000839679248388443000,-0.0000942200568453274000,-0.0001041782893697690000,
                                 -0.0001135320799314810000,-0.0001219394151650650000,-0.0001290305041380540000,-0.0001344124463422110000,
                                 -0.0001376748828055750000,-0.0001383966201512960000,-0.0001361531970573670000,-0.0001305253407310410000,
                                 -0.0001211082380473760000,-0.0001075215223148740000,-0.0000894198526770055000,-0.0000665039394359647000,
                                 -0.0000385318456301609000,-0.0000053303735720836700, 0.0000331936746644370000, 0.0000770425910488983000,
                                  0.0001261174521055390000, 0.0001802086591174630000, 0.0002389875874706430000, 0.0003019996064803510000,
                                  0.0003686587279811850000, 0.0004382441336304110000, 0.0005098988170486880000, 0.0005826305574774570000,
                                  0.0006553154165513840000, 0.0007267039191646060000, 0.0007954300434674930000, 0.0008600231041035900000,
                                  0.0009189225673424000000, 0.0009704957873587580000, 0.0010130586002418200000, 0.0010448986571789400000,
                                  0.0010643013215372700000, 0.0010695778972266700000, 0.0010590958988011000000, 0.0010313110183244000000,
                                  0.0009848003911961310000, 0.0009182967140234380000, 0.0008307227233384720000, 0.0007212255055674890000,
                                  0.0005892100771702490000, 0.0004343716502188080000, 0.0002567259837068660000, 0.0000566372152862144000,
                                 -0.0001651574275111260000,-0.0004075266227702810000,-0.0006689282172574440000,-0.0009473972818505240000,
                                 -0.0012405394375238600000,-0.0015455298732126200000,-0.0018591184102846600000,-0.0021776408927207700000,
                                 -0.0024970370983413800000,-0.0028128752755932300000,-0.0031203833137580600000,-0.0034144864533539700000,
                                 -0.0036898513394809500000,-0.0039409361155334900000,-0.0041620461497624900000,-0.0043473948843657400000,
                                 -0.0044911691978911200000,-0.0045875985785133300000,-0.0046310273199151500000,-0.0046159888747196900000,
                                 -0.0045372814342294900000,-0.0043900437490480400000,-0.0041698301642454600000,-0.0038726838161516300000,
                                 -0.0034952069264763400000,-0.0030346271338968800000,-0.0024888588239006400000,-0.0018565584546490900000,
                                 -0.0011371729297963200000,-0.0003309801381371120000, 0.0005608791360054640000, 0.0015363786295610000000,
                                  0.0025925939314375800000, 0.0037257001913225100000, 0.0049309805381794000000, 0.0062028453995380900000,
                                  0.0075348627661432400000, 0.0089197992961380200000, 0.0103496720009581000000, 0.0118158101038099000000,
                                  0.0133089265133430000000, 0.0148191982122344000000, 0.0163363547251468000000, 0.0178497737051041000000,
                                  0.0193485825638017000000, 0.0208217649716314000000, 0.0222582709689609000000, 0.0236471293629406000000,
                                  0.0249775610350351000000, 0.0262390917545484000000, 0.0274216630832794000000, 0.0285157399664571000000,
                                  0.0295124136352954000000, 0.0304034984965834000000, 0.0311816217540957000000, 0.0318403045943456000000,
                                  0.0323740338741209000000, 0.0327783233678413000000, 0.0330497637673357000000, 0.0331860607731880000000,
                                  0.0331860607731880000000, 0.0330497637673357000000, 0.0327783233678413000000, 0.0323740338741209000000,
                                  0.0318403045943456000000, 0.0311816217540957000000, 0.0304034984965834000000, 0.0295124136352954000000,
                                  0.0285157399664571000000, 0.0274216630832794000000, 0.0262390917545484000000, 0.0249775610350351000000,
                                  0.0236471293629406000000, 0.0222582709689609000000, 0.0208217649716314000000, 0.0193485825638017000000,
                                  0.0178497737051041000000, 0.0163363547251468000000, 0.0148191982122344000000, 0.0133089265133430000000,
                                  0.0118158101038099000000, 0.0103496720009581000000, 0.0089197992961380200000, 0.0075348627661432400000,
                                  0.0062028453995380900000, 0.0049309805381794000000, 0.0037257001913225100000, 0.0025925939314375800000,
                                  0.0015363786295610000000, 0.0005608791360054640000,-0.0003309801381371120000,-0.0011371729297963200000,
                                 -0.0018565584546490900000,-0.0024888588239006400000,-0.0030346271338968800000,-0.0034952069264763400000,
                                 -0.0038726838161516300000,-0.0041698301642454600000,-0.0043900437490480400000,-0.0045372814342294900000,
                                 -0.0046159888747196900000,-0.0046310273199151500000,-0.0045875985785133300000,-0.0044911691978911200000,
                                 -0.0043473948843657400000,-0.0041620461497624900000,-0.0039409361155334900000,-0.0036898513394809500000,
                                 -0.0034144864533539700000,-0.0031203833137580600000,-0.0028128752755932300000,-0.0024970370983413800000,
                                 -0.0021776408927207700000,-0.0018591184102846600000,-0.0015455298732126200000,-0.0012405394375238600000,
                                 -0.0009473972818505240000,-0.0006689282172574440000,-0.0004075266227702810000,-0.0001651574275111260000,
                                  0.0000566372152862144000, 0.0002567259837068660000, 0.0004343716502188080000, 0.0005892100771702490000,
                                  0.0007212255055674890000, 0.0008307227233384720000, 0.0009182967140234380000, 0.0009848003911961310000,
                                  0.0010313110183244000000, 0.0010590958988011000000, 0.0010695778972266700000, 0.0010643013215372700000,
                                  0.0010448986571789400000, 0.0010130586002418200000, 0.0009704957873587580000, 0.0009189225673424000000,
                                  0.0008600231041035900000, 0.0007954300434674930000, 0.0007267039191646060000, 0.0006553154165513840000,
                                  0.0005826305574774570000, 0.0005098988170486880000, 0.0004382441336304110000, 0.0003686587279811850000,
                                  0.0003019996064803510000, 0.0002389875874706430000, 0.0001802086591174630000, 0.0001261174521055390000,
                                  0.0000770425910488983000, 0.0000331936746644370000,-0.0000053303735720836700,-0.0000385318456301609000,
                                 -0.0000665039394359647000,-0.0000894198526770055000,-0.0001075215223148740000,-0.0001211082380473760000,
                                 -0.0001305253407310410000,-0.0001361531970573670000,-0.0001383966201512960000,-0.0001376748828055750000,
                                 -0.0001344124463422110000,-0.0001290305041380540000,-0.0001219394151650650000,-0.0001135320799314810000,
                                 -0.0001041782893697690000,-0.0000942200568453274000,-0.0000839679248388443000,-0.0000736982212040602000,
                                 -0.0000636512253759712000,-0.0000540301925940706000,-0.0000450011741421972000,-0.0000366935637659348000,
                                 -0.0000292012947339411000,-0.0000225846083397909000,-0.0000168723128365884000,-0.0000120644516679525000,
                                 -0.0000081353011937011800,-0.0000050366206797981300,-0.0000027010808964361800,-0.0000010458020130680500,
                                  0.0000000240636295918251, 0.0000006117630629136700, 0.0000008254423670411830, 0.0000007747629430165470,
                                  0.0000005676776418460560, 0.0000003074050729944920, 0.0000000896358117296806,-0.0000000000000000000257);
constant c_SQA_FIR1_TAB       :  t_slv_arr(0 to c_SQA_FIR1_TAB_NW-1)(c_SQA_FIR1_S-1 downto 0) :=
                                 real_arr_to_slv_arr(c_SQA_FIR1_TAB_REAL, c_SQA_FIR1_S, c_SQA_FIR1_FRC_S)   ; --! SQUID AMP: Filter FIR1 coefficients (symetrical FIR, Fs = 6.25 MHz)


constant c_SQA_FIR2_DCI_VAL   : integer := 4                                                                ; --! SQUID AMP: Filter FIR2 decimation value
constant c_SQA_FIR2_TAB_NW    : integer := 256                                                              ; --! SQUID AMP: Filter FIR2 table number word
constant c_SQA_FIR2_S         : integer := c_RAM_ECC_DATA_S                                                 ; --! SQUID AMP: Filter FIR2 coefficient bus size
constant c_SQA_FIR2_FRC_S     : integer := integer(ceil(real(c_RAM_ECC_DATA_S-2) - log2(0.222953780772677))); --! SQUID AMP: Filter FIR2 coefficient fractional part
constant c_SQA_FIR2_COEF_SM_S : integer := c_SQA_FIR2_FRC_S                                                 ; --! SQUID AMP: Filter FIR2 coefficient sum bus size
constant c_SQA_FIR2_TAB_REAL  : real_vector(0 to c_SQA_FIR2_TAB_NW-1) :=                                      --! SQUID AMP: Filter FIR2 coefficients (symetrical FIR, Fs = 195.3125 kHz)
                               ( -0.0000492418739540020000,-0.0000217321195356045000,-0.0000093968699264814700, 0.0000133631009058699000,
                                  0.0000336510421238082000, 0.0000413688453312139000, 0.0000264029196251721000,-0.0000057415035393666900,
                                 -0.0000433829219751607000,-0.0000640667690243118000,-0.0000549259618375960000,-0.0000125905475937706000,
                                  0.0000437586061536967000, 0.0000880205237242807000, 0.0000912708745930467000, 0.0000468717895609838000,
                                 -0.0000314880862189598000,-0.0001044111602521890000,-0.0001338680226091650000,-0.0000948370123397689000,
                                 -0.0000005923762346516250, 0.0001085291617740160000, 0.0001734846114447710000, 0.0001559293139213710000,
                                  0.0000519959662739864000,-0.0000911635032173165000,-0.0002043663785960250000,-0.0002210885434278110000,
                                 -0.0001238453886277280000, 0.0000508406891108996000, 0.0002157130795107710000, 0.0002845257328977410000,
                                  0.0002082157919719960000, 0.0000156744246857962000,-0.0002043797420123490000,-0.0003345693508232680000,
                                 -0.0003000100307112450000,-0.0001018542110467950000, 0.0001654066725095820000, 0.0003674204080627780000,
                                  0.0003878973098251260000, 0.0002041394899520200000,-0.0001039891953482560000,-0.0003773575918558810000,
                                 -0.0004687940612028890000,-0.0003124093770793600000, 0.0000223582414839610000, 0.0003696002569291540000,
                                  0.0005380063055930360000, 0.0004256070137275040000, 0.0000705567568851404000,-0.0003465030067912420000,
                                 -0.0006031481110436850000,-0.0005421258288479270000,-0.0001763651303386690000, 0.0003172332742969680000,
                                  0.0006696106570007760000, 0.0006749939436557510000, 0.0002978439522727870000,-0.0002788790601334240000,
                                 -0.0007505695608823480000,-0.0008369883812596750000,-0.0004561700691412910000, 0.0002249760380282810000,
                                  0.0008459268326297710000, 0.0010512032637623700000, 0.0006761460631485840000,-0.0001254001521054140000,
                                 -0.0009497002339055180000,-0.0013278176500983800000,-0.0009981254018063930000,-0.0000597691747018400000,
                                  0.0010260662490850000000, 0.0016702079084377700000, 0.0014529004938426400000, 0.0003947816920922620000,
                                 -0.0010213059320155200000,-0.0020463272718394800000,-0.0020671200020058000000,-0.0009423479656368900000,
                                  0.0008447623481433730000, 0.0023977702197975200000, 0.0028297466972683500000, 0.0017699346619492500000,
                                 -0.0003935823075694630000,-0.0026139782803903900000,-0.0036978466910130500000,-0.0029121089481873400000,
                                 -0.0004573080545972120000, 0.0025536095344542000000, 0.0045625887810055700000, 0.0043748417612825300000,
                                  0.0018165168756299900000,-0.0020264295352477300000,-0.0052656954786007100000,-0.0060942787794946000000,
                                 -0.0037843911741176900000, 0.0008277096686133240000, 0.0055692637808884000000, 0.0079511480389550500000,
                                  0.0064118984345662200000, 0.0012850216251477700000,-0.0051805021256380400000,-0.0097316213407248400000,
                                 -0.0097297173996229300000,-0.0045711959863830100000, 0.0036983533427344900000, 0.0111512811989739000000,
                                  0.0137337962255860000000, 0.0094042637457603000000,-0.0005769311873571400000,-0.0117825878416710000000,
                                 -0.0185004320252314000000,-0.0164297305093638000000,-0.0051758543000060500000, 0.0109737499154514000000,
                                  0.0243640458669072000000, 0.0273203768091315000000, 0.0159172466289296000000,-0.0072230839454243900000,
                                 -0.0328939822567855000000,-0.0480279752015271000000,-0.0407704879778593000000,-0.0054914208294543100000,
                                  0.0538173822880139000000, 0.1239898470503380000000, 0.1862721098016710000000, 0.2229537807726770000000,
                                  0.2229537807726770000000, 0.1862721098016710000000, 0.1239898470503380000000, 0.0538173822880139000000,
                                 -0.0054914208294543100000,-0.0407704879778593000000,-0.0480279752015271000000,-0.0328939822567855000000,
                                 -0.0072230839454243900000, 0.0159172466289296000000, 0.0273203768091315000000, 0.0243640458669072000000,
                                  0.0109737499154514000000,-0.0051758543000060500000,-0.0164297305093638000000,-0.0185004320252314000000,
                                 -0.0117825878416710000000,-0.0005769311873571400000, 0.0094042637457603000000, 0.0137337962255860000000,
                                  0.0111512811989739000000, 0.0036983533427344900000,-0.0045711959863830100000,-0.0097297173996229300000,
                                 -0.0097316213407248400000,-0.0051805021256380400000, 0.0012850216251477700000, 0.0064118984345662200000,
                                  0.0079511480389550500000, 0.0055692637808884000000, 0.0008277096686133240000,-0.0037843911741176900000,
                                 -0.0060942787794946000000,-0.0052656954786007100000,-0.0020264295352477300000, 0.0018165168756299900000,
                                  0.0043748417612825300000, 0.0045625887810055700000, 0.0025536095344542000000,-0.0004573080545972120000,
                                 -0.0029121089481873400000,-0.0036978466910130500000,-0.0026139782803903900000,-0.0003935823075694630000,
                                  0.0017699346619492500000, 0.0028297466972683500000, 0.0023977702197975200000, 0.0008447623481433730000,
                                 -0.0009423479656368900000,-0.0020671200020058000000,-0.0020463272718394800000,-0.0010213059320155200000,
                                  0.0003947816920922620000, 0.0014529004938426400000, 0.0016702079084377700000, 0.0010260662490850000000,
                                 -0.0000597691747018400000,-0.0009981254018063930000,-0.0013278176500983800000,-0.0009497002339055180000,
                                 -0.0001254001521054140000, 0.0006761460631485840000, 0.0010512032637623700000, 0.0008459268326297710000,
                                  0.0002249760380282810000,-0.0004561700691412910000,-0.0008369883812596750000,-0.0007505695608823480000,
                                 -0.0002788790601334240000, 0.0002978439522727870000, 0.0006749939436557510000, 0.0006696106570007760000,
                                  0.0003172332742969680000,-0.0001763651303386690000,-0.0005421258288479270000,-0.0006031481110436850000,
                                 -0.0003465030067912420000, 0.0000705567568851404000, 0.0004256070137275040000, 0.0005380063055930360000,
                                  0.0003696002569291540000, 0.0000223582414839610000,-0.0003124093770793600000,-0.0004687940612028890000,
                                 -0.0003773575918558810000,-0.0001039891953482560000, 0.0002041394899520200000, 0.0003878973098251260000,
                                  0.0003674204080627780000, 0.0001654066725095820000,-0.0001018542110467950000,-0.0003000100307112450000,
                                 -0.0003345693508232680000,-0.0002043797420123490000, 0.0000156744246857962000, 0.0002082157919719960000,
                                  0.0002845257328977410000, 0.0002157130795107710000, 0.0000508406891108996000,-0.0001238453886277280000,
                                 -0.0002210885434278110000,-0.0002043663785960250000,-0.0000911635032173165000, 0.0000519959662739864000,
                                  0.0001559293139213710000, 0.0001734846114447710000, 0.0001085291617740160000,-0.0000005923762346516250,
                                 -0.0000948370123397689000,-0.0001338680226091650000,-0.0001044111602521890000,-0.0000314880862189598000,
                                  0.0000468717895609838000, 0.0000912708745930467000, 0.0000880205237242807000, 0.0000437586061536967000,
                                 -0.0000125905475937706000,-0.0000549259618375960000,-0.0000640667690243118000,-0.0000433829219751607000,
                                 -0.0000057415035393666900, 0.0000264029196251721000, 0.0000413688453312139000, 0.0000336510421238082000,
                                  0.0000133631009058699000,-0.0000093968699264814700,-0.0000217321195356045000,-0.0000492418739540020000);
constant c_SQA_FIR2_TAB       :  t_slv_arr(0 to c_SQA_FIR2_TAB_NW-1)(c_SQA_FIR2_S-1 downto 0) :=
                                 real_arr_to_slv_arr(c_SQA_FIR2_TAB_REAL, c_SQA_FIR2_S, c_SQA_FIR2_FRC_S)   ; --! SQUID AMP: Filter FIR2 coefficients (symetrical FIR, Fs = 195.3125 kHz)

end pkg_fir;
