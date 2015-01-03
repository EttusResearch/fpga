-------------------------------------------------------------------------------
-- $Id: down_counter.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
------------------------------------------------------------------------------
-- PLB Arbiter
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
------------------------------------------------------------------------------
-- Filename:        down_counter.vhd
-- 
-- Description:     Parameterizable down counter with synchronous load and 
--                  reset.
-- 
-------------------------------------------------------------------------------
-- Structure:   
--      Multi-use module
-------------------------------------------------------------------------------
-- Author:      ALS
-- History:
--  ALS         04/10/01        -- First version
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
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_ARITH.all;

-- PROC_COMMON_PKG contains the RESET_ACTIVE constant
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;


-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_CNT_WIDTH                 -- counter width
--
-- Definition of Ports:
--      input Din                   -- data to be loaded into counter
--      input Load                  -- load control signal
--      input Cnt_en                -- count enable signal
--      input Clk                     
--      input Rst
--
--      output Cnt_out              -- counter output
-------------------------------------------------------------------------------

entity down_counter is
  generic (
           --  Select width of counter
           C_CNT_WIDTH : INTEGER := 4
           );
  port (
        Din     : in std_logic_vector(0 to C_CNT_WIDTH-1);
        Load    : in std_logic;
        Cnt_en  : in std_logic;  
        Cnt_out : out std_logic_vector(0 to C_CNT_WIDTH - 1 );
        
        Clk     : in std_logic;
        Rst     : in std_logic
        );
 
end down_counter;

architecture simulation of down_counter is

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
-- internal count
signal cnt : unsigned(0 to C_CNT_WIDTH - 1 );
 
 
begin

-------------------------------------------------------------------------------
-- COUNTER_PROCESS process
-------------------------------------------------------------------------------
COUNTER_PROCESS:process (Clk)
begin  
  if Clk'event and Clk = '1' then
    if Rst = RESET_ACTIVE then
      cnt <= (others => '0');
    elsif Load = '1' then
      cnt <= unsigned(Din);
    elsif Cnt_en = '1' then
      cnt <= cnt - 1;
    else
      cnt <= cnt;
    end if;
  end if;
end process COUNTER_PROCESS;


CNTOUT_PROCESS:process (cnt)
begin  
  Cnt_out <= conv_std_logic_vector(cnt, C_CNT_WIDTH);
end process CNTOUT_PROCESS;
            
end simulation;
