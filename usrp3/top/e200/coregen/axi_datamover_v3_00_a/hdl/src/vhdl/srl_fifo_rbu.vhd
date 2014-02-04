-------------------------------------------------------------------------------
-- $Id: srl_fifo_rbu.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- srl_fifo_rbu - entity / architecture pair
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2005-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        srl_fifo_rbu.vhd
--
-- Description:     A small-depth FIFO with capability to back up and reread data.
--                  SRL16 primitives are used for the FIFO storage.
--
--                  Features:
--                      - Width (arbitrary) and depth (1..16) are
--                        instance selectable.
--                      - Commands: read, write, and reread n.
--                      - Flags: empty and full.
--                      - The reread n command (executed by applying
--                        a non-zero value, n, to signal Num_To_Reread
--                        for one clock period) allows n
--                        previously read elements to be restored to the FIFO,
--                        limited, however, to the number of elements that have
--                        not been overwritten. (User's responsibility to
--                        assure that the elements being restored
--                        are actually in the FIFO storage.)
--                      - Commands may be asserted simultaneously.
--                        However, if read and reread n are asserted
--                        simultaneously, only the read is carried out.
--                      - Overflow and underflow are detected and latched until
--                        Reset. The state of the FIFO is undefined during
--------------------------------------------------------------------------------
--                        status of underflow and overflow. If neither overflow
--                        nor underflow needs to be detected, the
--                        Overflow and Underflow output ports may be left open
--                        to allow the tools to optimize away the associated
--                        logic.
--                      - The resources needed to address the storage scale with
--                        selected depth. (e.g. a 7-deep FIFO gets by with
--                        one fewer address bits than an 8-deep, etc.)
--                      - The Addr output is always one less than the current
--                        occupancy when the FIFO is non-empty, and is all ones
--                        otherwise.
--
--                  Srl_fifo_rbu is a descendent of srl_fifo and srl_fifo2,
--                  but the internals are somewhat reworked. The essential
--                  new feature is the read-backup capability. Other
--                  differences are:
--                      -The Data_Exists signal of those FIFOs--which
--                       had meaning "fifo not empty"--is eliminated and
--                       signal FIFO_Empty is available to determine the
--                       empty/non-empty condition.
--                      -The Addr output has a different definition than the
--                       two ancestor FIFOs. (Srl_fifo and srl_fifo2 have
--                       addr=0 when the FIFO contains one element and when
--                       the FIFO is empty.)
--                      -The ancestor FIFOs inhibited FIFO operations that
--                       would have caused an overflow or underflow but
--                       did not report the error. This FIFO allows the
--                       operation (which puts the FIFO in an undefined state)
--                       but reports the error.
--                      -If the overflow and underflow flags are not used,
--                       srl_fifo_rbu has no size disadvantage compared to
--                       srl_fifo and srl_fifo2, despite the added capability
--                       of reread n.
--                        
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo_rbu.vhd
--                  proc_common_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          Farrell Ostler for the enhancements relative to earlier
--                  srl_fifos. Original srl_fifo by Goran Bilski.
--
-- History:
--   FLO   05/01/02   First Version
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Changed proc_common library version to v3_00_a
--     - Incorporated new disclaimer header
-- ^^^^^^
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
--      predecessor value by # clks:            "*_p#"

library ieee;
library unisim;
library proc_common_v3_00_a;
use ieee.std_logic_1164.all;
use ieee.numeric_std.UNSIGNED;
use ieee.numeric_std.">=";
use ieee.numeric_std.TO_UNSIGNED;
use unisim.all;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity srl_fifo_rbu is
  generic (
    C_DWIDTH : positive := 8;
    C_DEPTH  : positive := 16;
    C_XON    : boolean  := false  -- for mixed mode sims
    );
  port (
    Clk           : in  std_logic;
    Reset         : in  std_logic;
    FIFO_Write    : in  std_logic;
    Data_In       : in  std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Read     : in  std_logic;
    Data_Out      : out std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Full     : out std_logic;
    FIFO_Empty    : out std_logic;
    Addr          : out std_logic_vector(0 to log2(C_DEPTH)-1);
    Num_To_Reread : in  std_logic_vector(0 to log2(C_DEPTH)-1);
    Underflow     : out std_logic;
    Overflow      : out std_logic
    );

--Note:
--ToDo, Num_To_Reread is a good candidate testcase for unconstrained ports.
--      The user would specify--by the width of the signal that is hooked up to
--      Num_To_Reread-- how many bits are needed for the reread count.
--      If Num_To_Reread were hooked up to the null array, then the
--      reread capability would be disabled.

end entity srl_fifo_rbu;


architecture imp of srl_fifo_rbu is

  component SRL16E is
      -- pragma translate_off
    generic (
      INIT : bit_vector := X"0000"
      );
      -- pragma translate_on    
    port (
      CE  : in  std_logic;
      D   : in  std_logic;
      Clk : in  std_logic;
      A0  : in  std_logic;
      A1  : in  std_logic;
      A2  : in  std_logic;
      A3  : in  std_logic;
      Q   : out std_logic);
  end component SRL16E;

  component MULT_AND
    port (
      I0 : in  std_logic;
      I1 : in  std_logic;
      LO : out std_logic);
  end component;

  component MUXCY_L
    port (
      DI : in  std_logic;
      CI : in  std_logic;
      S  : in  std_logic;
      LO : out std_logic);
  end component;

  component XORCY
    port (
      LI : in  std_logic;
      CI : in  std_logic;
      O  : out std_logic);
  end component;

  component FDS is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      D  : in  std_logic;
      S  : in  std_logic);
  end component FDS;

--function log2(n: natural) return natural is
--    variable i: integer := 1;
--    variable r: integer := 0;
--begin
--    while  i < n loop
--      i := 2*i; r := r+1;
--    end loop;
--    return r;
--end log2;

  function bitwise_or(s: std_logic_vector) return std_logic is
    variable v: std_logic := '0';
  begin
    for i in s'range loop
      v := v or s(i);
    end loop;
    return v;
  end bitwise_or;


  constant ADDR_BITS : integer := log2(C_DEPTH);
    -- An extra bit will be carried as the empty flag.

  signal addr_i                 : std_logic_vector(ADDR_BITS downto 0);  
  signal hsum_A                 : std_logic_vector(ADDR_BITS downto 0);
  signal addr_i_p1              : std_logic_vector(ADDR_BITS downto 0);
  signal num_to_reread_zeroext  : std_logic_vector(ADDR_BITS downto 0);
  signal addr_cy                : std_logic_vector(ADDR_BITS+1 downto 0);
  signal fifo_empty_i           : std_logic;
  signal overflow_i             : std_logic;
  signal underflow_i            : std_logic;
  signal srl16_addr             : std_logic_vector(3 downto 0);  
    -- Used to zero high-order bits if C_DEPTH is 7 or less.
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- C_DEPTH is positive, which ensures the fifo is at least 1 element deep.
  -- Make sure it is not greater than 16 locations deep.
  -----------------------------------------------------------------------------
  -- pragma translate_off
  assert C_DEPTH <= 16
    report "SRL Fifo's must be 16 or less elements deep"
    severity FAILURE;
  -- pragma translate_on


  FULL_PROCESS: process (Clk)
  begin
      if Clk'event and Clk='1' then
        if Reset='1' then
            FIFO_Full <= '0';
        else
            if addr_i_p1 = std_logic_vector(
                             TO_UNSIGNED(
                               C_DEPTH-1,ADDR_BITS+1
                             )
                           ) then
                FIFO_Full <= '1';
            else
                FIFO_Full <= '0';
            end if;
        end if;
      end if;
  end process;

  fifo_empty_i <= addr_i(ADDR_BITS);
  FIFO_Empty   <= fifo_empty_i;


  process (Num_To_Reread)
  begin
      num_to_reread_zeroext <= (others => '0');
      num_to_reread_zeroext(Num_To_Reread'length-1 downto 0) <= Num_To_Reread;
  end process;


  addr_cy(0) <= FIFO_Write;

  Addr_Counters : for I in 0 to ADDR_BITS generate

    hsum_A(I) <= ((FIFO_Read or num_to_reread_zeroext(i)) xor addr_i(I));

    MUXCY_L_I : MUXCY_L
      port map (
        DI => addr_i(I),                -- [in  std_logic]
        CI => addr_cy(I),               -- [in  std_logic]
        S  => hsum_A(I),                -- [in  std_logic]
        LO => addr_cy(I+1));            -- [out std_logic]

    XORCY_I : XORCY
      port map (
        LI => hsum_A(I),                -- [in  std_logic]
        CI => addr_cy(I),               -- [in  std_logic]
        O  => addr_i_p1(I));            -- [out std_logic]

    FDS_I : FDS
      port map (
        Q  => addr_i(I),                -- [out std_logic]
        C  => Clk,                      -- [in  std_logic]
        D  => addr_i_p1(I),             -- [in  std_logic]
        S  => Reset);                   -- [in  std_logic]

  end generate Addr_Counters;


  process (addr_i)
  begin
      srl16_addr <= (others => '0');
      srl16_addr(ADDR_BITS-1 downto 0) <= addr_i(ADDR_BITS-1 downto 0);
  end process;


  FIFO_RAM : for I in 0 to C_DWIDTH-1 generate
    SRL16E_I : SRL16E
      -- pragma translate_off
      generic map (
        INIT => x"0000")
      -- pragma translate_on
      port map (
        CE  => FIFO_Write,              -- [in  std_logic]
        D   => Data_In(I),              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => srl16_addr(0),           -- [in  std_logic]
        A1  => srl16_addr(1),           -- [in  std_logic]
        A2  => srl16_addr(2),           -- [in  std_logic]
        A3  => srl16_addr(3),           -- [in  std_logic]
        Q   => Data_Out(I));            -- [out std_logic]
  end generate FIFO_RAM;
  
  Addr(0 to ADDR_BITS-1) <= addr_i(ADDR_BITS-1 downto 0); 


  UNDERFLOW_PROCESS: process (Clk)
  begin
      if Clk'event and Clk='1' then
          if Reset = '1' then
              underflow_i <= '0';
          elsif underflow_i = '1' then
              underflow_i <= '1';      -- Underflow sticks until reset
          else
              underflow_i <= fifo_empty_i and FIFO_Read;
          end if;
      end if;
  end process;

  Underflow <= underflow_i;

  ------------------------------------------------------------------------------
  -- Overflow detection:
  -- The only case of non-erroneous operation for which addr_i (including
  -- the high-order bit used as the empty flag) taken as an unsigned value
  -- may be greater than or equal to C_DEPTH is when the FIFO is empty.
  -- No overflow is possible when FIFO_Read, since Num_To_Reread is
  -- overriden in this case and the number elements can at most remain
  -- unchanged (that being when there is a simultaneous FIFO_Write).
  -- However, when there is no FIFO_Read and but there is either a
  -- FIFO_Write or a restoration of one or more read elements, then
  -- addr_i becoming greater than or equal to C_DEPTH indicates an overflow.
  ------------------------------------------------------------------------------
  OVERFLOW_PROCESS: process (Clk)
  begin
      if Clk'event and Clk='1' then
          if Reset = '1' then
              overflow_i <= '0';
          elsif overflow_i = '1' then
              overflow_i <= '1';       -- Overflow sticks until Reset
          elsif FIFO_Read = '0' and
                (FIFO_Write= '1' or bitwise_or(Num_To_Reread)='1') and
                UNSIGNED(addr_i_p1) >= C_DEPTH then
              overflow_i <= '1';
          else
              overflow_i <= '0';
          end if;
      end if;
  end process;

  Overflow <= overflow_i;


end architecture imp;
