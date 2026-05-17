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
--!   @file                   mult_add_ext.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Realize the signed operation with extended bus in 5 clock cycles:
--!                            o_z = i_a * i_b  + i_c
--!                            LSB elaborated from saturation rank and result bus size
--!
--!                           The following inequation must be respected:
--!                           g_PORTB_S             <= c_MULT_ALU_PORTB_S      + c_MULT_ALU_MXX_SHF_S
--!                           g_PORTC_S             <= c_MULT_ALU_PORTC_S      + c_MULT_ALU_MXX_SHF_S
--!                           g_PORTA_SHF           <= c_MULT_ALU_PORTA_S  - 1
--!                           g_PORTA_S             <= c_MULT_ALU_PORTA_S      + g_PORTA_SHF
--!                           g_PORTB_S             <= c_MULT_ALU_RESULT_S - 1 - g_PORTA_SHF
--!                           g_PORTA_S + g_PORTB_S <= c_MULT_ALU_RESULT_S - 1 + g_PORTA_SHF
--!
--!                           The following maximal values respect the last inequations: (g_PORTA_SHF, g_PORTA_S, g_PORTB_S) =
--!                            (c_MULT_ALU_PORTA_S - 1, 2*c_MULT_ALU_PORTA_S - 1, c_MULT_ALU_PORTB_S + c_MULT_ALU_MXX_SHF_S - 3)
--!                            (c_MULT_ALU_PORTA_S - 1, 2*c_MULT_ALU_PORTA_S - 2, c_MULT_ALU_PORTB_S + c_MULT_ALU_MXX_SHF_S - 2)
--!                            (c_MULT_ALU_PORTA_S - 2, 2*c_MULT_ALU_PORTA_S - 4, c_MULT_ALU_PORTB_S + c_MULT_ALU_MXX_SHF_S - 1)
--!                            (c_MULT_ALU_PORTA_S - 3, 2*c_MULT_ALU_PORTA_S - 6, c_MULT_ALU_PORTB_S + c_MULT_ALU_MXX_SHF_S)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

library nx;
use     nx.nxpackage.all;

entity mult_add_ext is generic (
         g_PORTA_S            : integer                                                                     ; --! Port A bus size (constraints given by inequation in entity details)
         g_PORTB_S            : integer                                                                     ; --! Port B bus size (constraints given by inequation in entity details)
         g_PORTC_S            : integer                                                                     ; --! Port C bus size (<= c_MULT_ALU_PORTC_S  + c_MULT_ALU_MXX_SHF_S)
         g_PORTA_SHF          : integer                                                                     ; --! Port A shift    (<= c_MULT_ALU_PORTA_S  - 1)
         g_RESULT_S           : integer                                                                     ; --! Result bus size (<= c_MULT_ALU_RESULT_S + g_PORTA_SHF)
         g_LIN_SAT            : integer range 0 to 1                                                        ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           : integer                                                                       --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_a                  : in     std_logic_vector( g_PORTA_S-1 downto 0)                              ; --! Port A
         i_b                  : in     std_logic_vector( g_PORTB_S-1 downto 0)                              ; --! Port B
         i_c                  : in     std_logic_vector( g_PORTC_S-1 downto 0)                              ; --! Port C

         o_z                  : out    std_logic_vector(g_RESULT_S-1 downto 0)                                --! Result
   );
end entity mult_add_ext;

architecture RTL of mult_add_ext is
type     t_bitv_arr            is array (natural range <>) of bit_vector                                    ; --! Bit_vector array type

constant c_RESULT_TOT_S       : integer := g_PORTA_S + g_PORTB_S - 1                                        ; --! Result total bus size
constant c_SAT                : integer := g_LIN_SAT * c_RESULT_TOT_S + (1 - g_LIN_SAT) * g_SAT_RANK        ; --! Saturation
constant c_RESULT_LSB_POS     : integer := c_SAT - g_RESULT_S                                               ; --! Result LSB position
constant c_SAT_RNK            : integer := c_SAT - 1 - g_PORTA_SHF                                          ; --! Result LSB position

constant c_SAT_RANK           : bit_vector(c_MULT_ALU_SAT_RNK_S-1 downto 0):=
                                to_bitvector(std_logic_vector(to_unsigned(c_SAT_RNK,c_MULT_ALU_SAT_RNK_S))) ; --! Extrem values reached on result bus [-2**(c_SAT-1); 2**(c_SAT-1)-1]

constant c_DSP                : integer := 4                                                                ; --! DSP number
constant c_DSP0               : integer := 0                                                                ; --! DSP 0 value
constant c_DSP1               : integer := 1                                                                ; --! DSP 1 value
constant c_DSP2               : integer := 2                                                                ; --! DSP 2 value
constant c_DSP3               : integer := 3                                                                ; --! DSP 3 value


constant c_SAT_ENA            : bit_vector(c_DSP-1 downto 0):= c_MULT_ALU_PRM_ENA & c_MULT_ALU_PRM_DIS &
                                                               c_MULT_ALU_PRM_DIS & c_MULT_ALU_PRM_DIS      ; --! DSP Multiplexer Saturation Enable
constant c_MUX_X_SHIFT        : bit_vector(c_DSP-1 downto 0):= c_MULT_ALU_PRM_ENA & c_MULT_ALU_PRM_DIS &
                                                               c_MULT_ALU_PRM_ENA & c_MULT_ALU_PRM_DIS      ; --! DSP : MUX X shift
constant c_MUX_X              : t_bitv_arr(0 to c_DSP-1)(1 downto 0) := (c_LOW_LEV_B & c_LOW_LEV_B,           --! DSP0, MUX X selection: Port C
                                                                         c_HGH_LEV_B & c_HGH_LEV_B,           --! DSP1, MUX X selection: CZI(39:0) & Port C(15:0)
                                                                         c_LOW_LEV_B & c_LOW_LEV_B,           --! DSP2, MUX X selection: Port C
                                                                         c_HGH_LEV_B & c_HGH_LEV_B)         ; --! DSP3, MUX X selection: CZI(39:0) & Port C(15:0)
constant c_PR_A_B_MUX         : t_bitv_arr(0 to c_DSP-1)(1 downto 0) := (c_LOW_LEV_B & c_HGH_LEV_B,
                                                                         c_LOW_LEV_B & c_HGH_LEV_B,
                                                                         c_HGH_LEV_B & c_HGH_LEV_B,
                                                                         c_HGH_LEV_B & c_HGH_LEV_B)         ; --! DSP Multiplexer Port A/B pipe register level number
constant c_PR_Z_MUX           : bit_vector(c_DSP-1 downto 0):= c_MULT_ALU_PRM_ENA & c_MULT_ALU_PRM_DIS &
                                                               c_MULT_ALU_PRM_ENA & c_MULT_ALU_PRM_DIS      ; --! DSP Multiplexer Port Z pipe register level number

signal   ovf                  : std_logic_vector(c_DSP-1 downto 0)                                          ; --! Overflow
signal   port_a               : t_slv_arr(0 to c_DSP-1)( c_MULT_ALU_PORTA_S-1 downto 0)                     ; --! Port A
signal   port_b               : t_slv_arr(0 to c_DSP-1)( c_MULT_ALU_PORTB_S-1 downto 0)                     ; --! Port B
signal   port_c               : t_slv_arr(0 to c_DSP-1)( c_MULT_ALU_PORTC_S-1 downto 0)                     ; --! Port C
signal   port_czi             : t_slv_arr(0 to c_DSP-1)(c_MULT_ALU_RESULT_S-1 downto 0)                     ; --! Port CZI
signal   port_czo             : t_slv_arr(0 to c_DSP-1)(c_MULT_ALU_RESULT_S-1 downto 0)                     ; --! Port CZO
signal   port_z               : t_slv_arr(0 to c_DSP-1)(c_MULT_ALU_RESULT_S-1 downto 0)                     ; --! Port Z
signal   port_z_r             : t_slv_arr(0 to 1)(              g_PORTA_SHF-1 downto 0)                     ; --! Port Z register
signal   result               : std_logic_vector(            c_RESULT_TOT_S-1 downto 0)                     ; --! Result

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Operation: result = Sat(i_a * i_b  + i_c)
   --!    result[c_RESULT_TOT_S-1..0] = Sat(
   --!     (i_a[g_PORTA_S-1..g_PORTA_SHF]          * 2^g_PORTA_SHF          + i_a[g_PORTA_SHF-1..0]) *
   --!     (i_b[g_PORTB_S-1..c_MULT_ALU_MXX_SHF_S] * 2^c_MULT_ALU_MXX_SHF_S + i_b[c_MULT_ALU_MXX_SHF_S-1..0]) +
   --!      i_c[g_PORTC_S-1..c_MULT_ALU_MXX_SHF_S] * 2^c_MULT_ALU_MXX_SHF_S + i_c[c_MULT_ALU_MXX_SHF_S-1..0])
   --!     result[c_RESULT_TOT_S-1..0] = Sat(
   --!      (i_a[g_PORTA_S-1..g_PORTA_SHF] * i_b[g_PORTB_S-1..c_MULT_ALU_MXX_SHF_S] * 2^c_MULT_ALU_MXX_SHF_S + i_a[g_PORTA_S-1..g_PORTA_SHF] * i_b[c_MULT_ALU_MXX_SHF_S-1..0]) * 2^g_PORTA_SHF +
   --!      (i_a[g_PORTA_SHF-1..0]         * i_b[g_PORTB_S-1..c_MULT_ALU_MXX_SHF_S] + i_c[g_PORTC_S-1..c_MULT_ALU_MXX_SHF_S]) * 2^c_MULT_ALU_MXX_SHF_S +
   --!       i_a[g_PORTA_SHF-1..0]         * i_b[c_MULT_ALU_MXX_SHF_S-1..0]         + i_c[c_MULT_ALU_MXX_SHF_S-1..0])
   -- ------------------------------------------------------------------------------------------------------
   -- ------------------------------------------------------------------------------------------------------
   --!   DSP0 inputs configuration, operation:
   --!     czo[c_DSP0][g_PORTA_SHF+g_PORTB_S-c_MULT_ALU_MXX_SHF_S..0] = i_a[g_PORTA_SHF-1..0] * i_b[g_PORTB_S-1..c_MULT_ALU_MXX_SHF_S] + i_c[g_PORTC_S-1..c_MULT_ALU_MXX_SHF_S]
   --!     DSP MUX X selection: Port C
   -- ------------------------------------------------------------------------------------------------------
   port_a(c_DSP0)    <= std_logic_vector(resize(unsigned(i_a(g_PORTA_SHF-1 downto 0)),                    port_a(c_DSP0)'length));
   port_b(c_DSP0)    <= std_logic_vector(resize(  signed(i_b(  g_PORTB_S-1 downto c_MULT_ALU_MXX_SHF_S)), port_b(c_DSP0)'length));
   port_c(c_DSP0)    <= std_logic_vector(resize(  signed(i_c(  g_PORTC_S-1 downto c_MULT_ALU_MXX_SHF_S)), port_c(c_DSP0)'length));
   port_czi(c_DSP0)  <= c_ZERO(port_czi(c_DSP0)'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   DSP1 inputs configuration, operation:
   --!     port_z[c_DSP1][g_PORTA_SHF+g_PORTB_S..0] = czo[c_DSP0] * 2^c_MULT_ALU_MXX_SHF_S + i_a[g_PORTA_SHF-1..0] * i_b[c_MULT_ALU_MXX_SHF_S-1..0] + i_c[c_MULT_ALU_MXX_SHF_S-1..0]
   --!     DSP MUX X selection: CZI[c_MULT_ALU_RESULT_S-c_MULT_ALU_MXX_SHF_S-1..0] & Port C[c_MULT_ALU_MXX_SHF_S-1..0]
   --!     result[g_PORTA_SHF-1..0] = port_z[c_DSP1][g_PORTA_SHF-1..0]
   -- ------------------------------------------------------------------------------------------------------
   port_a(c_DSP1)    <= std_logic_vector(resize(unsigned(i_a(         g_PORTA_SHF-1 downto 0)), port_a(c_DSP1)'length));
   port_b(c_DSP1)    <= std_logic_vector(resize(unsigned(i_b(c_MULT_ALU_MXX_SHF_S-1 downto 0)), port_b(c_DSP1)'length));
   port_c(c_DSP1)    <= std_logic_vector(resize(unsigned(i_c(c_MULT_ALU_MXX_SHF_S-1 downto 0)), port_c(c_DSP1)'length));
   port_czi(c_DSP1)  <= port_czo(c_DSP0);

   -- ------------------------------------------------------------------------------------------------------
   --!   DSP2 inputs configuration, operation:
   --!     czo[c_DSP2][g_PORTA_S-g_PORTA_SHF+g_PORTB_S-c_MULT_ALU_MXX_SHF_S..0] = i_a[g_PORTA_S-1..g_PORTA_SHF] * i_b[g_PORTB_S-1..c_MULT_ALU_MXX_SHF_S]
   --!                                                                            + port_z[c_DSP1][g_PORTA_SHF+g_PORTB_S+1..g_PORTA_SHF+c_MULT_ALU_MXX_SHF_S]
   --!     DSP MUX X selection: Port C
   -- ------------------------------------------------------------------------------------------------------
   port_a(c_DSP2)    <= std_logic_vector(resize(  signed(i_a(                       g_PORTA_S-1 downto g_PORTA_SHF)),                      port_a(c_DSP2)'length));
   port_b(c_DSP2)    <= std_logic_vector(resize(  signed(i_b(                       g_PORTB_S-1 downto c_MULT_ALU_MXX_SHF_S)),             port_b(c_DSP2)'length));
   port_c(c_DSP2)    <= std_logic_vector(resize(  signed(port_z(c_DSP1)(  port_z(c_DSP1)'high   downto g_PORTA_SHF+c_MULT_ALU_MXX_SHF_S)), port_c(c_DSP2)'length));
   port_czi(c_DSP2)  <= c_ZERO(port_czi(c_DSP2)'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   DSP1 inputs configuration, operation:
   --!     port_z[c_DSP3][c_RESULT_TOT_S-g_PORTA_SHF-1..0] = Sat(czo[c_DSP2] * 2^c_MULT_ALU_MXX_SHF_S + i_a[g_PORTA_S-1..g_PORTA_SHF] * i_b[c_MULT_ALU_MXX_SHF_S-1..0]
   --!                                                       + port_z[c_DSP1][g_PORTA_SHF+c_MULT_ALU_MXX_SHF_S-1..g_PORTA_SHF])
   --!     DSP MUX X selection: CZI[c_MULT_ALU_RESULT_S-c_MULT_ALU_MXX_SHF_S-1..0] & Port C[c_MULT_ALU_MXX_SHF_S-1..0]
   --!     result[c_RESULT_TOT_S-1..g_PORTA_SHF] = port_z[c_DSP3][c_RESULT_TOT_S-g_PORTA_SHF-1..0]
   -- ------------------------------------------------------------------------------------------------------
   port_a(c_DSP3)    <= std_logic_vector(resize(  signed(i_a(                                  g_PORTA_S-1 downto g_PORTA_SHF)), port_a(c_DSP3)'length));
   port_b(c_DSP3)    <= std_logic_vector(resize(unsigned(i_b(                       c_MULT_ALU_MXX_SHF_S-1 downto 0)),           port_b(c_DSP3)'length));
   port_c(c_DSP3)    <= std_logic_vector(resize(unsigned(port_z(c_DSP1)(g_PORTA_SHF+c_MULT_ALU_MXX_SHF_S-1 downto g_PORTA_SHF)), port_c(c_DSP3)'length));
   port_czi(c_DSP3)  <= port_czo(c_DSP2);

   -- ------------------------------------------------------------------------------------------------------
   --!   DSP management
   -- ------------------------------------------------------------------------------------------------------
   G_dsp_mgt: for k in 0 to c_DSP-1 generate
   begin

      -- ------------------------------------------------------------------------------------------------------
      --!   NX_DSP_L_SPLIT IpCore instantiation
      -- ------------------------------------------------------------------------------------------------------
      I_dsp: entity nx.nx_dsp_l_split generic map (
         SIGNED_MODE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type                     ('0' = unsigned,           '1' = signed)
         PRE_ADDER_OP         => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! Pre-Adder operation           ('0' = add,                '1' = subtract)
         ALU_DYNAMIC_OP       => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU Dynamic operation enable  ('0' = ALU_STAT_OP used,   '1' = Port D LSB used)
         ALU_OP               => c_MULT_ALU_OP_ADDC   , -- bit_vector(MULT_ALU_OP_S-1 downto 0)             ; --! ALU Static operation
         ALU_MUX              => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU swap operands             ('0' = no swap,            '1' = swap)
         Z_FEEDBACK_SHL12     => c_MUX_X_SHIFT(k)     , -- bit                                              ; --! ALU shift of MUX_ALU input    (see below Z_FEEDBACK_SHL12 & MUX_X for configuration)
         ENABLE_SATURATION    => c_SAT_ENA(k)         , -- bit                                              ; --! Saturation enable             ('0' = disable,            '1' = enable)
         SATURATION_RANK      => c_SAT_RANK           , -- bit_vector(5 downto 0)                           ; --! Extrem values reached on result bus and overflow management
                                                                                                              --!   unsigned: range from             0  to 2**(SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(SAT_RANK) to 2**(SAT_RANK)   - 1

         MUX_CI               => c_MULT_ALU_PRM_NU    , -- bit                                              ; --! Multiplexer ALU Carry In ('0' = ALU Carry In,            '1' = Cascaded ALU Carry In)
         MUX_A                => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Port A       ('0' = Port A,                  '1' = Cascaded Port A)
         MUX_B                => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Port B       ('0' = Port B,                  '1' = Cascaded Port B)
         MUX_P                => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Pre-Adder    ('0' = MUX_PORTB,               '1' = MUX_PORTB +/- Port D)
         MUX_Y                => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Multiplier   ('0' = MUX_PORTA * MUX_PRE_ADD, '1' = MUX_PORTB & MUX_PORTA)
         MUX_X                => c_MUX_X(k)           , -- bit_vector(1 downto 0)                           ; --! Multiplexer ALU operand  ("X0X" = Port C,                "010" = MUX_ALU,
                                                                                                              --!   "011"= Cascaded Result Input, "110"= MUX_ALU(39:0) & Port C(15:0),
                                                                                                              --!   "111"= Cascaded Result Input(39:0) & Port C(15:0))
         CO_SEL               => c_MULT_ALU_PRM_NU    , -- bit                                              ; --! Multiplexer ALU Carry Out('0' = ALU(36),                 '1' = ALU(48))
         MUX_Z                => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer ALU ('0' = ALU(Port D, MUX_ALU_OP, MUX_MULT, MUX_CARRY) '1' = MUX_MULT)

         PR_CI_MUX            => c_HGH_LEV_B          , -- bit                                              ; --! Multiplexer ALU Carry In   pipe register level number
         PR_A_MUX             => c_PR_A_B_MUX(k)      , -- bit_vector(1 downto 0)                           ; --! Multiplexer Port A         pipe register level number
         PR_B_MUX             => c_PR_A_B_MUX(k)      , -- bit_vector(1 downto 0)                           ; --! Multiplexer Port B         pipe register level number
         PR_C_MUX             => c_HGH_LEV_B          , -- bit                                              ; --! Multiplexer Port C         pipe register level number
         PR_D_MUX             => c_HGH_LEV_B          , -- bit                                              ; --! Multiplexer Port D         pipe register level number
         PR_P_MUX             => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Pre-Adder      pipe register level number
         PR_MULT_MUX          => c_LOW_LEV_B          , -- bit                                              ; --! Multiplier Out             pipe register level number
         PR_Y_MUX             => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer Multiplier     pipe register level number
         PR_ALU_MUX           => c_LOW_LEV_B          , -- bit                                              ; --! ALU Out                    pipe register level number
         PR_X_MUX             => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer ALU operand    pipe register level number
         PR_CO_MUX            => c_LOW_LEV_B          , -- bit                                              ; --! Multiplexer ALU Carry Out  pipe register level number
         PR_OV_MUX            => c_HGH_LEV_B          , -- bit                                              ; --! Overflow                   pipe register level number
         PR_Z_MUX             => c_PR_Z_MUX(k)        , -- bit                                              ; --! Multiplexer ALU            pipe register level number
         PR_A_CASCADE_MUX     => c_LOW_LEV_B & c_LOW_LEV_B, -- bit_vector(1 downto 0)                       ; --! Cascaded Port A buffer     pipe register level number
         PR_B_CASCADE_MUX     => c_LOW_LEV_B & c_LOW_LEV_B, -- bit_vector(1 downto 0)                       ; --! Cascaded Port B buffer     pipe register level number

         ENABLE_PR_CI_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU Carry In   register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_A_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port A         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_B_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port B         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_C_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port C         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_D_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port D         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_P_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Pre-Adder      register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_MULT_RST   => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplier Out             register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_Y_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Multiplier     register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_ALU_RST    => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! ALU Out                    register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_X_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU operand    register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_CO_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU Carry Out  register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_OV_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Overflow                   register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_Z_RST      => c_MULT_ALU_PRM_ENA     -- bit                                                --! Multiplexer ALU            register reset ('0' = Disable, '1' = Enable)

   )     port map (
         ck                   => i_clk                , -- in     std_logic                                 ; --! Clock
         r                    => i_rst                , -- in     std_logic                                 ; --! Reset pipeline registers ('0' = Inactive, '1' = Active)
         rz                   => i_rst                , -- in     std_logic                                 ; --! Reset Z output register  ('0' = Inactive, '1' = Active)
         we                   => c_HGH_LEV            , -- in     std_logic                                 ; --! Write Enable ('0' = Internal registers frozen, '1' = Normal operation)

         ci                   => c_LOW_LEV            , -- in     std_logic                                 ; --! ALU Carry In
         a                    => port_a(k)            , -- in     slv(c_MULT_ALU_PORTA_S-1 downto 0)        ; --! Port A
         b                    => port_b(k)            , -- in     slv(c_MULT_ALU_PORTB_S-1 downto 0)        ; --! Port B
         c                    => port_c(k)            , -- in     slv(c_MULT_ALU_PORTC_S-1 downto 0)        ; --! Port C
         d                    => c_ZERO(c_MULT_ALU_PORTD_S-1 downto 0), -- in slv c_MULT_ALU_PORTD_S        ; --! Port D

         cci                  => c_ZERO(c_ZERO'low)   , -- in     std_logic                                 ; --! Cascaded ALU Carry In
         cai                  => c_ZERO(c_MULT_ALU_PORTA_S-1 downto 0), -- in slv c_MULT_ALU_PORTA_S        ; --! Cascaded Port A
         cbi                  => c_ZERO(c_MULT_ALU_PORTB_S-1 downto 0), -- in slv c_MULT_ALU_PORTB_S        ; --! Cascaded Port B
         czi                  => port_czi(k)          , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         co                   => open                 , -- out    std_logic                                 ; --! ALU Carry buffer           (MUX_CARRY_OUT registered output)
         co36                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 36
         co56                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 56
         ovf                  => ovf(k)               , -- out    std_logic                                 ; --! Overflow ('0' = No, '1' = Yes)
         z                    => port_z(k)            , -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Result buffer              (MUX_ALU       registered output)

         cco                  => open                 , -- out    std_logic                                 ; --! Cascaded ALU Carry buffer  (MUX_CARRY_OUT registered output)
         cao                  => open                 , -- out    slv(c_MULT_ALU_PORTA_S -1 downto 0)       ; --! Cascaded Port A buffer     (MUX_PORTA     registered output)
         cbo                  => open                 , -- out    slv(c_MULT_ALU_PORTB_S -1 downto 0)       ; --! Cascaded Port B buffer     (MUX_PORTB     registered output)
         czo                  => port_czo(k)            -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result buffer     (MUX_ALU       registered output)
      );

   end generate G_dsp_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Result
   -- ------------------------------------------------------------------------------------------------------
   P_result : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         port_z_r <= (others => c_ZERO(port_z_r(port_z_r'high)'range));
         result   <= c_ZERO(result'range);

      elsif rising_edge(i_clk) then
         port_z_r <= port_z(c_DSP1)(port_z_r(port_z_r'high)'range) & port_z_r(0 to port_z_r'high-1);
         result(c_RESULT_TOT_S-1 downto g_PORTA_SHF) <= port_z(c_DSP3)(c_RESULT_TOT_S-g_PORTA_SHF-1 downto 0);

         if ovf(ovf'high) = c_HGH_LEV then
            result(g_PORTA_SHF-1 downto 0) <= (others => port_z(c_DSP3)(port_z(c_DSP3)'low));

         else
            result(g_PORTA_SHF-1 downto 0) <= port_z_r(port_z_r'high);

         end if;

      end if;

   end process P_result;

   o_z <= result(g_RESULT_S+c_RESULT_LSB_POS-1 downto c_RESULT_LSB_POS);

end architecture RTL;
