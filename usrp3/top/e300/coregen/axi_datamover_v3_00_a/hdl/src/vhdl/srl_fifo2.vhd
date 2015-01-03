-------------------------------------------------------------------------------
-- $Id: srl_fifo2.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- srl_fifo2 - entity / architecture pair
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
-- ** Copyright (c) 2002-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        srl_fifo2.vhd
--
-- Description:     same as srl_fifo except the Addr port has the correct bit
--                  ordering, there is a true FIFO_Empty port, and the C_DEPTH
--                  generic actually controlls how many elements the fifo will
--                  hold (up to 16).  includes an assertion statement to check
--                  that C_DEPTH is less than or equal to 16.  changed
--                  C_DATA_BITS to C_DWIDTH and changed it from natural to
--                  positive (the width should be 1 or greater, zero width
--                  didn't make sense to me!).  Changed C_DEPTH from natural
--                  to positive (zero elements doesn't make sense).
--                  The Addr port in srl_fifo has the bits reversed which
--                  made it more difficult to use.  C_DEPTH was not used in
--                  srl_fifo.  Data_Exists is delayed by one clock so it is
--                  not usefull for generating an empty flag.  FIFO_Empty is
--                  generated directly from the address, the same way that
--                  FIFO_Full is generated.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo2.vhd
--
-------------------------------------------------------------------------------
-- Author:          jam
--
-- History:
--   jam   02/20/02   First Version - modified from original srl_fifo
--
--   DCW    2002-03-12    Structural implementation of synchronous reset for
--                        Data_Exists DFF (using FDR)
--   jam   04/12/02   Added C_XON generic for mixed vhdl/verilog sims
--
--   als    2002-04-18    added default for XON generic in SRL16E, FDRE, and FDR
--                        component declarations
--   jam   2002-05-01  changed FIFO_Empty output from buffer_Empty, which had a
--                     clock delay, to the not of data_Exists_I, which doesn't
--                     have any delay
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
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
library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;  -- conv_std_logic_vector
use unisim.all;

entity srl_fifo2 is
  generic (
    C_DWIDTH : positive := 8;     -- changed to positive
    C_DEPTH  : positive := 16;    -- changed to positive
    C_XON    : boolean  := false  -- added for mixed mode sims
    );
  port (
    Clk         : in  std_logic;
    Reset       : in  std_logic;
    FIFO_Write  : in  std_logic;
    Data_In     : in  std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Read   : in  std_logic;
    Data_Out    : out std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Full   : out std_logic;
    FIFO_Empty  : out std_logic;  -- new port
    Data_Exists : out std_logic;
    Addr        : out std_logic_vector(0 to 3)
    );

end entity srl_fifo2;

architecture imp of srl_fifo2 is

   -- convert C_DEPTH to a std_logic_vector so FIFO_Full can be generated
   -- based on the selected depth rather than fixed at 16
  constant DEPTH : std_logic_vector(0 to 3) :=
                                            conv_std_logic_vector(C_DEPTH-1,4);

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

--  component LUT4
--    generic(
--      INIT : bit_vector := X"0000"
--      );
--    port (
--      O  : out std_logic;
--      I0 : in  std_logic;
--      I1 : in  std_logic;
--      I2 : in  std_logic;
--      I3 : in  std_logic);
--  end component;

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

  component FDRE is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  component FDR is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDR;

  signal addr_i       : std_logic_vector(0 to 3);  
  signal buffer_Full  : std_logic;
  signal buffer_Empty : std_logic;

  signal next_Data_Exists : std_logic;
  signal data_Exists_I    : std_logic;

  signal valid_Write : std_logic;

  signal hsum_A  : std_logic_vector(0 to 3);
  signal sum_A   : std_logic_vector(0 to 3);
  signal addr_cy : std_logic_vector(0 to 4);
  
begin  -- architecture IMP

   -- C_DEPTH is positive so that ensures the fifo is at least 1 element deep
   -- make sure it is not greater than 16 locations deep
   -- pragma translate_off
  assert C_DEPTH <= 16
    report "SRL Fifo's must be 16 or less elements deep"
    severity FAILURE;
   -- pragma translate_on

   -- since srl16 address is 3 downto 0 need to compare individual bits
   -- didn't muck with addr_i since the basic addressing works - Addr output
   -- is generated correctly below
  buffer_Full <= '1' when (addr_i(0) = DEPTH(3) and
                           addr_i(1) = DEPTH(2) and
                           addr_i(2) = DEPTH(1) and
                           addr_i(3) = DEPTH(0)
                          ) else '0';

  FIFO_Full <= buffer_Full;

  buffer_Empty <= '1' when (addr_i = "0000") else '0';

  FIFO_Empty <= not data_Exists_I;   -- generate a true empty flag with no delay
                                     -- was buffer_Empty, which had a clock dly

  next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                      (buffer_Empty and FIFO_Write) or
                      (data_Exists_I and not FIFO_Read);

  Data_Exists_DFF : FDR
    port map (
      Q  => data_Exists_I,            -- [out std_logic]
      C  => Clk,                      -- [in  std_logic]
      D  => next_Data_Exists,         -- [in  std_logic]
      R  => Reset);                   -- [in std_logic]

  Data_Exists <= data_Exists_I;
  
  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

  addr_cy(0) <= valid_Write;

  Addr_Counters : for I in 0 to 3 generate

    hsum_A(I) <= (FIFO_Read xor addr_i(I)) and (FIFO_Write or not buffer_Empty);

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
        O  => sum_A(I));                -- [out std_logic]

    FDRE_I : FDRE
      port map (
        Q  => addr_i(I),                -- [out std_logic]
        C  => Clk,                      -- [in  std_logic]
        CE => data_Exists_I,            -- [in  std_logic]
        D  => sum_A(I),                 -- [in  std_logic]
        R  => Reset);                   -- [in  std_logic]

  end generate Addr_Counters;

  FIFO_RAM : for I in 0 to C_DWIDTH-1 generate
    SRL16E_I : SRL16E
      -- pragma translate_off
      generic map (
        INIT => x"0000")
      -- pragma translate_on
      port map (
        CE  => valid_Write,             -- [in  std_logic]
        D   => Data_In(I),              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => addr_i(0),               -- [in  std_logic]
        A1  => addr_i(1),               -- [in  std_logic]
        A2  => addr_i(2),               -- [in  std_logic]
        A3  => addr_i(3),               -- [in  std_logic]
        Q   => Data_Out(I));            -- [out std_logic]
  end generate FIFO_RAM;
  
-------------------------------------------------------------------------------
-- INT_ADDR_PROCESS
-------------------------------------------------------------------------------
-- This process assigns the internal address to the output port
-------------------------------------------------------------------------------
   -- modified the process to flip the bits since the address bits from the
   -- srl16 are 3 downto 0 and Addr needs to be 0 to 3
  INT_ADDR_PROCESS:process (addr_i)
  begin   -- process
    for i in Addr'range
    loop
      Addr(i) <= addr_i(3 - i);  -- flip the bits to account for srl16 addr
    end loop;
  end process;
  
end architecture imp;
