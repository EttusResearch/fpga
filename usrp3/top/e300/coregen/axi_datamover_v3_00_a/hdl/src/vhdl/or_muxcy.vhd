-------------------------------------------------------------------------------
-- $Id: or_muxcy.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- or_muxcy
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
-- Filename:        or_muxcy.vhd
--
-- Description:     This file is used to OR together consecutive bits within
--                  sections of a bus.
--                  
-------------------------------------------------------------------------------
-- Structure:       Common use module
-------------------------------------------------------------------------------

-- Author:      ALS
-- History:
--  ALS         04/06/01      -- First version
--
--  ALS         05/18/01
-- ^^^^^^
--  Added use of carry chain muxes if number of bits is > 4
-- ~~~~~~
--  BLT         05/23/01
-- ^^^^^^
--  Removed pad_4 function, replaced with arithmetic expression
-- ~~~~~~
--  BLT         05/24/01
-- ^^^^^^
--  Removed Sig input, removed C_START_BIT and C_BUS_SIZE 
-- ~~~~~~
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
--      combinatorial signals:                  "*_cmb" 
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
use ieee.std_logic_1164.all;

-- Unisim library contains Xilinx primitives
library Unisim;
use Unisim.all;
-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_NUM_BITS              -- number of bits to OR in bus section
--
-- Definition of Ports:
--          input  In_Bus           -- bus containing bits to be ORd
--          output Or_out           -- OR result
--
-------------------------------------------------------------------------------
entity or_muxcy is
    generic (
            C_NUM_BITS      : integer   := 8
            );
    port    (
            In_bus          : in std_logic_vector(0 to C_NUM_BITS-1);
            Or_out          : out std_logic     
            );
end or_muxcy;


architecture implementation of or_muxcy is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- Pad the number of bits to OR to the next multiple of 4 
constant NUM_BITS_PAD       : integer   := ((C_NUM_BITS-1)/4+1)*4;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
-- define output of OR chain

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------
-- Carry Chain muxes are used to implement OR of 4 bits or more
component MUXCY
  port (
    O : out std_logic;
    CI : in std_logic;
    DI : in std_logic;
    S : in std_logic
  );
end component;

begin


-- If the number of bits to OR is 4 or less, a simple LUT can be used
LESSTHAN4_GEN: if C_NUM_BITS < 5 generate
-- define output of OR chain
signal or_tmp   : std_logic_vector(0 to C_NUM_BITS-1) := (others => '0');
begin
    BIT_LOOP: for i in 0 to C_NUM_BITS-1 generate
        FIRST: if i = 0 generate
            or_tmp(i) <= In_bus(0);
        end generate FIRST;
        
        REST: if i /= 0 generate
            or_tmp(i) <= or_tmp(i-1) or In_bus(i);
        end generate REST;
    end generate BIT_LOOP;
    
    Or_out <= or_tmp(C_NUM_BITS-1);
end generate LESSTHAN4_GEN;

-- If the number of bits to OR is 4 or more, then use LUTs and
-- carry chain. Pad the number of bits to the nearest multiple of 4
MORETHAN4_GEN: if C_NUM_BITS >= 5 generate

-- define output of LUTs
signal lut_out  : std_logic_vector(0 to NUM_BITS_PAD/4-1) := (others => '0');
-- define padded input bus
signal in_bus_pad   : std_logic_vector(0 to NUM_BITS_PAD-1) := (others => '0');
-- define output of OR chain
signal or_tmp  : std_logic_vector(0 to NUM_BITS_PAD/4-1) := (others => '0');


begin

    -- pad input bus
    in_bus_pad(0 to C_NUM_BITS-1) <= In_bus(0 to C_NUM_BITS-1);

    OR_GENERATE: for i in 0 to NUM_BITS_PAD/4-1 generate
        
        lut_out(i) <= not( in_bus_pad(i*4) or
                           in_bus_pad(i*4+1) or
                           in_bus_pad(i*4+2) or 
                           in_bus_pad(i*4+3) );
    
        FIRST:  if i = 0 generate
            FIRSTMUX_I: MUXCY
              port map (
                O   => or_tmp(i),   --[out]
                CI  => '0' ,        --[in]
                DI  => '1' ,        --[in]
                S   => lut_out(i)   --[in]
              );
        end generate FIRST;
    
        REST: if i /= 0 generate
            RESTMUX_I: MUXCY
              port map (
                O   => or_tmp(i),   --[out]
                CI  => or_tmp(i-1), --[in]
                DI  => '1' ,        --[in]
                S   => lut_out(i)   --[in]
              );
        end generate REST;
        
    end generate OR_GENERATE;
Or_out <= or_tmp(NUM_BITS_PAD/4-1);

end generate MORETHAN4_GEN;


end implementation;

