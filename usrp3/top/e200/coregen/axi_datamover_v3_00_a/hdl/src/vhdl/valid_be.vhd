--SINGLE_FILE_TAG
-------------------------------------------------------------------------------
-- $Id: valid_be.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- valid_be - entity/architecture pair
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
-- Filename:        valid_be.vhd
-- Version:         v1.00a
-- Description:     Determines valid OPB access for memory devices
--
-------------------------------------------------------------------------------
-- Structure: 
--
--              valid_be.vhd
-------------------------------------------------------------------------------
-- Author:      BLT
-- History:
--  ALS         09/21/01     -- First version
-- ^^^^^^
--      First version of valid_be created from BLT's file, valid_access. Made
--      modifications to support a target data bus width and a host data bus
--      width.
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-------------------------------------------------------------------------------
-- Port declarations
-------------------------------------------------------------------------------

entity valid_be is
  generic (
    C_HOST_DW           : integer range 8 to 256 := 32;
    C_TARGET_DW         : integer range 8 to 32  := 32
    );   
  port (
    OPB_BE_Reg     : in  std_logic_vector(0 to C_HOST_DW/8-1);
    Valid          : out std_logic
    );
end entity valid_be;


architecture implementation of valid_be is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant HOST_LOGVAL   : integer := log2(C_HOST_DW/8);  -- log value for host bus
constant TAR_LOGVAL    : integer := log2(C_TARGET_DW/8); -- log value for target bus

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin

-------------------------------------------------------------------------------
-- VALID_ACCESS_PROCESS: this is a general purpose process that returns 
-- whether or not a particular byte enable code is valid for a particular host
-- bus size and target bus size. The byte enable bus can be up to 32 bits wide, 
-- supporting host bus widths up to 256 bits.
--
-- Example:
--  HOST BUS SIZE(OPB)  TARGET BUS SIZE (SRAM)  Valid BE
--  -----------------   ----------------------  --------
--      8                       8                   '1'
--      16                      8                   "01"
--                                                  "10"
--      16                      16                  "01"
--                                                  "10"
--                                                  "11"
--      32                      8                   "0001"
--                                                  "0010"
--                                                  "0100"
--                                                  "1000"
--      32                      16                  "0001"
--                                                  "0010"
--                                                  "0100"
--                                                  "1000"
--                                                  "0011"
--                                                  "1100"
--      32                      32                  "0001"
--                                                  "0010"
--                                                  "0100"
--                                                  "1000"
--                                                  "0011"
--                                                  "1100"
--                                                  "1111"
-------------------------------------------------------------------------------

VALID_ACCESS_PROCESS: process (OPB_BE_Reg) is
  variable compare_Val : integer := 0;
begin
  Valid <= '0';
  for i in 0 to TAR_LOGVAL loop         -- loop for bits in target data bus
    compare_Val := pwr(2,pwr(2,i))-1;
    for j in 0 to pwr(2,HOST_LOGVAL-i) loop
      if Conv_integer('0' & OPB_BE_Reg) = compare_Val then Valid <= '1'; end if;
      compare_Val := compare_Val*pwr(2,pwr(2,i));
    end loop;
  end loop;
end process VALID_ACCESS_PROCESS;

end architecture implementation;
