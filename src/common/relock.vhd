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
--!   @file                   relock.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Relock function
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity relock is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_sqm_dta_err_cor    : in     std_logic_vector(c_SQM_DATA_FBK_S-1   downto 0)                      ; --! SQUID MUX Data error corrected (signed)
         i_fb0_rl_aln         : in     std_logic_vector(c_SQM_DATA_FBK_S-1   downto 0)                      ; --! Feedback value in open loop for relock alignment
         i_sqm_dta_err_cor_cs : in     std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_rl_rd_add      : in     std_logic_vector(      c_MUX_FACT_S-1 downto 0)                      ; --! Relock memories read address
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_squid_close_mode_n : in     std_logic                                                            ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         i_rldel              : in     std_logic_vector(c_DFLD_RLDEL_COL_S-1 downto 0)                      ; --! Relock delay
         i_rlthr              : in     std_logic_vector(c_DFLD_RLTHR_COL_S-1 downto 0)                      ; --! Relock threshold

         i_mem_dlcnt          : in     t_mem(
                                       add(    c_MEM_DLCNT_ADD_S-1 downto 0),
                                       data_w(c_DFLD_DLCNT_PIX_S-1 downto 0))                               ; --! Delock counter: memory inputs
         o_dlcnt_data         : out    std_logic_vector(c_DFLD_DLCNT_PIX_S-1 downto 0)                      ; --! Delock counter: data read
         o_dlflg              : out    std_logic_vector(c_DFLD_DLFLG_COL_S-1 downto 0)                      ; --! Delock flag ('0' = No delock on pixels, '1' = Delock on at least one pixel)

         o_rl_ena             : out    std_logic                                                              --! Relock enable ('0' = No, '1' = Yes)
   );
end entity relock;

architecture RTL of relock is
constant c_ERR_CS_THRCP_POS   : integer := 0                                                                ; --! SQUID MUX Data error corrected chip select Counter threshold exceed read compare
constant c_ERR_CS_THRWR_POS   : integer := c_ERR_CS_THRCP_POS + 1                                           ; --! SQUID MUX Data error corrected chip select Counter threshold exceed write position
constant c_ERR_CS_DLCWR_POS   : integer := c_ERR_CS_THRCP_POS + 1                                           ; --! SQUID MUX Data error corrected chip select Delock counter write position
constant c_FF_ERR_COR_CS_NB   : integer := c_ERR_CS_DLCWR_POS + 1                                           ; --! Flip-Flop number used for SQUID MUX Data error corrected chip select register

constant c_DLCNT_SAT          : integer := 2**c_DFLD_DLCNT_PIX_S - 1                                        ; --! Delock counter saturation value
constant c_CNT_THR_EXC_INIT   : std_logic_vector(c_DFLD_RLDEL_COL_S downto 0) :=
                                std_logic_vector(to_unsigned(1, c_DFLD_RLDEL_COL_S+1))                      ; --! Counter threshold exceed initialization value

signal   abs_dif_sqm_dta_fb0  : std_logic_vector(  c_SQM_DATA_FBK_S-1 downto 0)                             ; --! Absolute Data error corrected minus feedback value in open loop

signal   rlthr_r              : std_logic_vector(c_DFLD_RLTHR_COL_S-1 downto 0)                             ; --! Relock threshold register
signal   squid_close_mode_n_r : std_logic                                                                   ; --! SQUID MUX/AMP Close mode register ('0' = Yes, '1' = No)
signal   sqm_dta_err_cor_cs_r : std_logic_vector(c_FF_ERR_COR_CS_NB-1 downto 0)                             ; --! SQUID MUX Data error corrected chip select register

signal   mem_cnt_thr_exceed   : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(c_DFLD_RLDEL_COL_S downto 0)              ; --! Memory counter threshold exceed
signal   cnt_thr_exceed_rd    : std_logic_vector(c_DFLD_RLDEL_COL_S downto 0)                               ; --! Counter threshold exceed read
signal   cnt_thr_exceed_rd_r  : std_logic_vector(c_DFLD_RLDEL_COL_S downto 0)                               ; --! Counter threshold exceed read register
signal   cnt_thr_exd_rd_cmp   : std_logic                                                                   ; --! Counter threshold exceed read compare
signal   cnt_thr_exceed_wr    : std_logic_vector(c_DFLD_RLDEL_COL_S downto 0)                               ; --! Counter threshold exceed write

signal   mem_dlcnt_pp         : std_logic                                                                   ; --! Delock counter, TC/HK side: ping-pong buffer bit
signal   mem_dlcnt_prm        : t_mem(
                                add(              c_MEM_DLCNT_ADD_S-1 downto 0),
                                data_w(          c_DFLD_DLCNT_PIX_S-1 downto 0))                            ; --! Delock counter, getting parameter side: memory inputs

signal   dlcnt_rd             : std_logic_vector(c_DFLD_DLCNT_PIX_S-1 downto 0)                             ; --! Delock counter read
signal   dlcnt_wr             : std_logic_vector(c_DFLD_DLCNT_PIX_S-1 downto 0)                             ; --! Delock counter write
signal   dlcnt_wr_ena         : std_logic                                                                   ; --! Delock counter write enable ('0' = No, '1' = Yes)

signal   dlflag               : t_slv_arr(0 to c_DLFLG_MX_STIN(c_DLFLG_MX_STIN'high)-1)(0 downto 0)         ; --! Delock flags ('0' = No delock, '1' = Delock)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         rlthr_r              <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_RLTHR_I, rlthr_r'length));
         squid_close_mode_n_r <= c_HGH_LEV;
         sqm_dta_err_cor_cs_r <= c_ZERO(sqm_dta_err_cor_cs_r'range);

      elsif rising_edge(i_clk) then
         rlthr_r              <= i_rlthr;
         squid_close_mode_n_r <= i_squid_close_mode_n;
         sqm_dta_err_cor_cs_r <= sqm_dta_err_cor_cs_r(sqm_dta_err_cor_cs_r'high-1 downto 0) & i_sqm_dta_err_cor_cs;

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Relock: Absolute difference between Data error corrected and feedback value in open loop
   --    @Req : DRE-DMX-FW-REQ-0400
   -- ------------------------------------------------------------------------------------------------------
   P_abs_dif_sqm_dt_fb0 : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         abs_dif_sqm_dta_fb0   <= c_ZERO(abs_dif_sqm_dta_fb0'range);

      elsif rising_edge(i_clk) then
         if i_sqm_dta_err_cor_cs = c_HGH_LEV then
            if (signed(i_sqm_dta_err_cor) > signed(i_fb0_rl_aln)) then
               abs_dif_sqm_dta_fb0  <= std_logic_vector(signed(i_sqm_dta_err_cor) - signed(i_fb0_rl_aln));

            else
               abs_dif_sqm_dta_fb0  <= std_logic_vector(signed(i_fb0_rl_aln) - signed(i_sqm_dta_err_cor));

            end if;

         end if;

      end if;

   end process P_abs_dif_sqm_dt_fb0;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory counter threshold exceed
   --    @Req : DRE-DMX-FW-REQ-0400
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_thr_exceed_rd_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cnt_thr_exceed_rd      <= c_CNT_THR_EXC_INIT;
         cnt_thr_exceed_rd_r    <= c_CNT_THR_EXC_INIT;
         cnt_thr_exd_rd_cmp     <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         cnt_thr_exceed_rd      <= mem_cnt_thr_exceed(to_integer(unsigned(i_mem_rl_rd_add)));
         cnt_thr_exceed_rd_r    <= cnt_thr_exceed_rd;

         if squid_close_mode_n_r = c_LOW_LEV and (unsigned(cnt_thr_exceed_rd_r) >= resize(unsigned(i_rldel), cnt_thr_exceed_rd_r'length)) then
            cnt_thr_exd_rd_cmp  <= c_HGH_LEV;

         else
            cnt_thr_exd_rd_cmp  <= c_LOW_LEV;

         end if;

      end if;

   end process P_cnt_thr_exceed_rd_r;

   --! Counter threshold exceed
   P_cnt_thr_exceed_wr : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         cnt_thr_exceed_wr <= c_CNT_THR_EXC_INIT;

      elsif rising_edge(i_clk) then
         if sqm_dta_err_cor_cs_r(c_ERR_CS_THRCP_POS) = c_HGH_LEV then
            if squid_close_mode_n_r = c_HGH_LEV then
               cnt_thr_exceed_wr <= c_CNT_THR_EXC_INIT;

            elsif cnt_thr_exd_rd_cmp = c_HGH_LEV then
               cnt_thr_exceed_wr <= c_CNT_THR_EXC_INIT;

            elsif (unsigned(abs_dif_sqm_dta_fb0) > resize(unsigned(rlthr_r), abs_dif_sqm_dta_fb0'length)) then
               cnt_thr_exceed_wr <= std_logic_vector(unsigned(cnt_thr_exceed_rd_r) + 1);

            else
               cnt_thr_exceed_wr <= c_CNT_THR_EXC_INIT;

            end if;

         end if;

      end if;

   end process P_cnt_thr_exceed_wr;

   --! Counter threshold exceed: memory write
   P_mem_cnt_thr_exd_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if sqm_dta_err_cor_cs_r(c_ERR_CS_THRWR_POS) = c_HGH_LEV then
            mem_cnt_thr_exceed(to_integer(unsigned(i_mem_rl_rd_add))) <= cnt_thr_exceed_wr;

         end if;

      end if;

   end process P_mem_cnt_thr_exd_wr;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameter Delock counters
   -- @Req : DRE-DMX-FW-REQ-0435
   -- @Req : REG_CY_DELOCK_COUNTERS
   -- ------------------------------------------------------------------------------------------------------
   I_mem_dlcnt_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_DATA_TX   , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_DLCNT_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_DLCNT_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_RAM_INIT_EMPTY       -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_dlcnt          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_dlcnt_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_dlcnt_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => c_LOW_LEV            , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_dlcnt_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => dlcnt_rd             , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameter Delock counters: memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_dlcnt_prm.add     <= i_mem_rl_rd_add;
   mem_dlcnt_prm.we      <= sqm_dta_err_cor_cs_r(c_ERR_CS_DLCWR_POS) and dlcnt_wr_ena;
   mem_dlcnt_prm.cs      <= c_HGH_LEV;
   mem_dlcnt_prm.data_w  <= dlcnt_wr;
   mem_dlcnt_prm.pp      <= mem_dlcnt_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Delock counter write enable
   -- ------------------------------------------------------------------------------------------------------
   P_dlcnt_wr_ena : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         dlcnt_wr_ena <= c_HGH_LEV;

      elsif rising_edge(i_clk) then
         if i_mem_dlcnt.add = mem_dlcnt_prm.add then
            if (i_mem_dlcnt.we and i_mem_dlcnt.cs) = c_HGH_LEV then
               dlcnt_wr_ena <= c_LOW_LEV;

            end if;

         else
            dlcnt_wr_ena <= c_HGH_LEV;

         end if;

      end if;

   end process P_dlcnt_wr_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Delock counter write
   -- @Req : DRE-DMX-FW-REQ-0435
   -- ------------------------------------------------------------------------------------------------------
   P_dlcnt_wr : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         dlcnt_wr <= c_ZERO(dlcnt_wr'range);

      elsif rising_edge(i_clk) then
         if sqm_dta_err_cor_cs_r(c_ERR_CS_THRCP_POS) = c_HGH_LEV then
            if i_smfmd = c_DST_SMFMD_OFF then
               dlcnt_wr <= c_ZERO(dlcnt_wr'range);

            elsif dlcnt_wr_ena = c_LOW_LEV then
               dlcnt_wr <= c_ZERO(dlcnt_wr'range);

            elsif cnt_thr_exd_rd_cmp = c_HGH_LEV and
                  (dlcnt_rd /= std_logic_vector(to_unsigned(c_DLCNT_SAT, dlcnt_rd'length))) then
               dlcnt_wr <= std_logic_vector(unsigned(dlcnt_rd) + 1);

            else
               dlcnt_wr <= dlcnt_rd;

            end if;

         end if;

      end if;

   end process P_dlcnt_wr;

   -- ------------------------------------------------------------------------------------------------------
   --!   Delock flags
   --    @Req : DRE-DMX-FW-REQ-0430
   -- ------------------------------------------------------------------------------------------------------
   G_dlflag: for k in 0 to c_MUX_FACT-1 generate
   begin

      --! Delock flags
      P_dlflag : process (i_rst, i_clk)
      begin

         if i_rst = c_RST_LEV_ACT then
            dlflag(k)(dlflag(dlflag'low)'low) <= c_LOW_LEV;

         elsif rising_edge(i_clk) then
            if (sqm_dta_err_cor_cs_r(c_ERR_CS_DLCWR_POS) = c_HGH_LEV) and (i_mem_rl_rd_add = std_logic_vector(to_unsigned(k, i_mem_rl_rd_add'length))) then
               if dlcnt_wr = c_ZERO(dlcnt_wr'range) then
                  dlflag(k)(dlflag(dlflag'low)'low) <= c_LOW_LEV;

               else
                  dlflag(k)(dlflag(dlflag'low)'low) <= c_HGH_LEV;

               end if;

            end if;

         end if;

      end process P_dlflag;

   end generate G_dlflag;

   dlflag(c_MUX_FACT to c_DLFLG_MX_STIN(1)-1) <= (others => (others => c_LOW_LEV));

   G_mux_stage: for k in 0 to c_DLFLG_MX_STNB-1 generate
   constant c_MUX_NB          : integer   := c_DLFLG_MX_STIN(k+2) - c_DLFLG_MX_STIN(k+1)                    ; --! Multiplexer number by stage
   begin

      G_mux_nb: for l in 0 to c_MUX_NB - 1 generate
      begin

         I_multiplexer: entity work.multiplexer generic map (
            g_DATA_S          => 1                    , -- integer                                          ; --! Data bus size
            g_NB              => c_DLFLG_MX_INNB(k)     -- integer                                            --! Data bus number
         ) port map (
            i_rst             => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
            i_clk             => i_clk                , -- in     std_logic                                 ; --! System Clock
            i_data            => dlflag(
                                 l   *c_DLFLG_MX_INNB(k) + c_DLFLG_MX_STIN(k) to
                                (l+1)*c_DLFLG_MX_INNB(k) + c_DLFLG_MX_STIN(k)-1)                            , --! Data buses
            i_cs              => (others => c_HGH_LEV), -- in     std_logic_vector(g_NB-1 downto 0)         ; --! Chip selects ('0' = Inactive, '1' = Active)
            o_data_mux        => dlflag(c_DLFLG_MX_STIN(k+1)+l), -- out  slv(g_DATA_S-1 downto 0)           ; --! Multiplexed data
            o_cs_or           => open                   -- out    std_logic                                   --! Chip selects "or-ed"
         );

      end generate G_mux_nb;

   end generate G_mux_stage;

   o_dlflg <= dlflag(dlflag'high);

   -- ------------------------------------------------------------------------------------------------------
   --!   Relock enable
   --    @Req : DRE-DMX-FW-REQ-0400
   -- ------------------------------------------------------------------------------------------------------
   P_rl_ena : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_rl_ena <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         o_rl_ena <= cnt_thr_exd_rd_cmp;

      end if;

   end process P_rl_ena;

end architecture RTL;
