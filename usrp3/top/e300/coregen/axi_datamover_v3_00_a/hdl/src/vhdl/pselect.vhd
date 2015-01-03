-------------------------------------------------------------------------------
-- $Id: pselect.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- pselect.vhd - entity/architecture pair
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
-- ** Copyright (c) 2001-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        pselect.vhd
--
-- Description:     Parameterizeable peripheral select (address decode).
--                  AValid qualifier comes in on Carry In at bottom 
--                  of carry chain. For version with AValid at top of
--                  carry chain, see pselect_top.vhd.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  pselect.vhd
--
-------------------------------------------------------------------------------
-- Author:          B.L. Tise
-- Revision:        $Revision: 1.1.4.1 $
-- Date:            $Date: 2010/09/14 22:35:47 $
--
-- History:
--   BLT            2001-04-10    First Version
--   BLT            2001-04-23    Moved function to this file
--   BLT            2001-05-21    Changed library to MicroBlaze
--   BLT            2001-08-13    Changed pragma to synthesis
--   ALS            2001-10-15    C_BAR is now padded to nearest multiple of 4
--                                to handle lut equations
--   FLO            2002-03-26    Corrected implementation for case where C_AB
--                                is not a multiple of 4 and the C_BAR values
--                                at the pad bits are not '0'.
--                                Removed implementation restriction that
--                                required C_AW = C_BAR'length.
--                                Added assertion to flag invalid generic
--                                combinations.

--   ALS, FLO       2002-04-09   -Implemented XST workaround for the case
--                                that C_AB = 0.
--                               -Removed remnants of earlier
--                                "instantiated-lut" implementation.
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library unisim;
use unisim.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_AB            -- number of address bits to decode
--          C_AW            -- width of address bus
--          C_BAR           -- base address of peripheral (peripheral select
--                             is asserted when the C_AB most significant
--                             address bits match the C_AB most significant
--                             C_BAR bits
-- Definition of Ports:
--          A               -- address input
--          AValid          -- address qualifier
--          CS              -- peripheral select
-------------------------------------------------------------------------------

entity pselect is
  
  generic (
    C_AB     : integer := 9;
    C_AW     : integer := 32;
    C_BAR    : std_logic_vector
    );
  port (
    A        : in   std_logic_vector(0 to C_AW-1);
    AValid   : in   std_logic;
    CS       : out  std_logic
    );

end entity pselect;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of pselect is

  component MUXCY is
    port (
      O  : out std_logic;
      CI : in  std_logic;
      DI : in  std_logic;
      S  : in  std_logic
    );
  end component MUXCY;
   
  attribute INIT        : string;

-----------------------------------------------------------------------------
-- Constant Declarations
-----------------------------------------------------------------------------
  constant  NUM_LUTS    : integer := (C_AB+3)/4;

  -- C_BAR may not be indexed from 0 and may not be ascending;
  -- BAR recasts C_BAR to have these properties.
  constant BAR          : std_logic_vector(0 to C_BAR'length-1) := C_BAR;
  
-----------------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------------
  
--signal    lut_out     : std_logic_vector(0 to NUM_LUTS-1);
  signal    lut_out     : std_logic_vector(0 to NUM_LUTS); -- XST workaround

  signal    carry_chain : std_logic_vector(0 to NUM_LUTS);


-------------------------------------------------------------------------------
-- Begin architecture section
-------------------------------------------------------------------------------
begin

--------------------------------------------------------------------------------
-- Check that the passed generics allow for correct implementation.
--------------------------------------------------------------------------------
-- synthesis translate_off
   assert (C_AB <= C_BAR'length) and (C_AB <= C_AW)
   report "pselect generic error: " &
          "(C_AB <= C_BAR'length) and (C_AB <= C_AW)" &
          " does not hold."
   severity failure;
-- synthesis translate_on


--------------------------------------------------------------------------------
-- Build the decoder using the fast carry chain.
--------------------------------------------------------------------------------

carry_chain(0) <= AValid;

XST_WA: if NUM_LUTS > 0 generate              -- workaround for XST; remove this
                                              -- enclosing generate when fixed
GEN_DECODE: for i in 0 to NUM_LUTS-1 generate
  signal   lut_in    : std_logic_vector(3 downto 0);
  signal   invert    : std_logic_vector(3 downto 0);
  begin
    GEN_LUT_INPUTS: for j in 0 to 3 generate
       -- Generate to assign address bits to LUT4 inputs
       GEN_INPUT: if i < NUM_LUTS-1 or j <= ((C_AB-1) mod 4) generate
         lut_in(j) <= A(i*4+j);
         invert(j) <= not BAR(i*4+j);
       end generate;
       -- Generate to assign one to remaining LUT4, pad, inputs
       GEN_ZEROS: if not(i < NUM_LUTS-1 or j <= ((C_AB-1) mod 4)) generate
         lut_in(j) <= '1';
         invert(j) <= '0';
       end generate;
    end generate;

    ---------------------------------------------------------------------------
    -- RTL LUT instantiation
    ---------------------------------------------------------------------------
    lut_out(i) <=  (lut_in(0) xor invert(0)) and
                   (lut_in(1) xor invert(1)) and
                   (lut_in(2) xor invert(2)) and
                   (lut_in(3) xor invert(3));


    MUXCY_I: MUXCY
      port map (
        O  => carry_chain(i+1), --[out]
        CI => carry_chain(i),   --[in]
        DI => '0',              --[in]
        S  => lut_out(i)        --[in]
      );    

end generate GEN_DECODE;
end generate XST_WA;

CS <= carry_chain(NUM_LUTS); -- assign end of carry chain to output;
                             -- if NUM_LUTS=0, then
                             -- CS <= carry_chain(0) <= AValid

end imp;

