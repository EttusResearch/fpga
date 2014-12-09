-------------------------------------------------------------------------------
-- $Id: inferred_lut4.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
--  inferred_lut4.vhd
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
-- Filename:        inferred_lut4.vhd
--
-- Description:     This module is used to infer a LUT4 instantiation in 
--                  structural VHDL. It is compatable with Synplicity and xst
--                  synthesis tools.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--               inferred_lut4.vhd
--
-------------------------------------------------------------------------------
-- Author:          D.Thorpe
--
-- History:
--   DET  2001-10-11   LUT4 implementation to work around xst lut4 problem with
--                     INIT generic. Adapted from XST France work-around
--                     solution sent to Bert Tise.
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Incorporated new disclaimer header
-- ^^^^^^
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "Bus_clk", "Bus_clk_div#", "Bus_clk_#x" 
--      Bus_rst signals:                          "rst", "rst_n" 
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
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_arith.all;

library ieee;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------------- 
 

  entity inferred_lut4 is 
   generic (INIT : bit_vector(15 downto 0)); 
   port ( 
     O : out std_logic; 
     I0 : in std_logic; 
     I1 : in std_logic; 
     I2 : in std_logic; 
     I3 : in std_logic 
   ); 
  end entity inferred_lut4; 

-------------------------------------------------------------------------------
  
  architecture implementation of inferred_lut4 is 
  
  
  signal b : std_logic_vector(3 downto 0); 
  signal tmp : integer range 0 to 15; 
  
  
  
  
  begin 
      
      b <= (I3, I2, I1, I0); 
      tmp <= conv_integer(b); 
      O <= To_StdUlogic(INIT(tmp)); 
  
  
  
  end architecture implementation; 
 
 
