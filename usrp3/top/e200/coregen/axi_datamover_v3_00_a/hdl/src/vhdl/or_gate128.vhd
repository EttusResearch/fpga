-------------------------------------------------------------------------------
-- $Id: or_gate128.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- or_gate128.vhd - entity/architecture pair
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
-- Filename:        or_gate128.vhd
-- Version:         v1.00a
-- Description:     OR gate implementation
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  or_gate128.vhd
--
-------------------------------------------------------------------------------
-- Author:          B.L. Tise
-- History:
--   BLT           2001-05-23    First Version
-- ^^^^^^
--      First version of OPB Bus.
-- ~~~~~~
--   GAB           07/11/05  
-- ^^^^^^
--      Adjusted range on C_BUS_WIDTH to support 128 bit dwidths
--      Renamed to or_gate128.vhd
-- ~~~~~~
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library proc_common_v3_00_a;
use proc_common_v3_00_a.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--   C_OR_WIDTH           -- Which Xilinx FPGA family to target when
--                           syntesizing, affect the RLOC string values 
--   C_BUS_WIDTH          -- Which Y position the RLOC should start from
--
-- Definition of Ports:
--   A                    -- Input.  Input buses are concatenated together to
--                           form input A. Example: to OR buses R, S, and T,
--                           assign A <= R & S & T;
--   Y                    -- Output. Same width as input buses.
--
-------------------------------------------------------------------------------
entity or_gate128 is
  generic (
    C_OR_WIDTH   : natural range 1 to 32 := 17;
    C_BUS_WIDTH  : natural range 1 to 128 := 1;
    C_USE_LUT_OR : boolean := TRUE
    );
  port (
    A : in  std_logic_vector(0 to C_OR_WIDTH*C_BUS_WIDTH-1);
    Y : out std_logic_vector(0 to C_BUS_WIDTH-1)
    );
end entity or_gate128;

    
architecture imp of or_gate128 is

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------

component or_muxcy 
    generic (
            C_NUM_BITS      : integer   := 8
            );
    port    (
            In_bus          : in std_logic_vector(0 to C_NUM_BITS-1);
            Or_out          : out std_logic     
            );
end component or_muxcy;

signal test : std_logic_vector(0 to C_BUS_WIDTH-1);
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin
  USE_LUT_OR_GEN: if C_USE_LUT_OR generate
    OR_PROCESS: process( A ) is
    variable yi : std_logic_vector(0 to (C_OR_WIDTH));
    begin
      for j in 0 to C_BUS_WIDTH-1 loop
        yi(0) := '0';
        for i in 0 to C_OR_WIDTH-1 loop
          yi(i+1) := yi(i) or A(i*C_BUS_WIDTH+j);
        end loop;
        Y(j) <= yi(C_OR_WIDTH);
      end loop;
    end process OR_PROCESS;
  end generate USE_LUT_OR_GEN;

  USE_MUXCY_OR_GEN: if not C_USE_LUT_OR generate
    BUS_WIDTH_FOR_GEN: for i in 0 to C_BUS_WIDTH-1 generate
      signal in_Bus : std_logic_vector(0 to C_OR_WIDTH-1);
    begin
      ORDER_INPUT_BUS_PROCESS: process( A ) is
      begin
        for k in 0 to C_OR_WIDTH-1 loop
          in_Bus(k) <=  A(k*C_BUS_WIDTH+i);
        end loop;
      end process ORDER_INPUT_BUS_PROCESS;
      OR_BITS_I: or_muxcy
        generic map (
          C_NUM_BITS      => C_OR_WIDTH
          )  
        port map (
          In_bus          => in_Bus,    --[in]
          Or_out          => Y(i)       --[out]
          );
     end generate BUS_WIDTH_FOR_GEN;
   end generate USE_MUXCY_OR_GEN;

end architecture imp;
