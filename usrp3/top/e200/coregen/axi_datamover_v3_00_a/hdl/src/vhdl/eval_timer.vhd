-------------------------------------------------------------------------------
-- $Id: eval_timer.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- eval_timer.vhd - entity/architecture pair
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
-- Filename:        eval_timer.vhd
-- Version:         v1.00a
-- Description:     40-bit counter that enables IP to be used in an evaluation
--                  mode. Once the counter expires, the eval_timeout signal
--                  asserts and can be used to reset the IP.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  eval_timer.vhd
--
-------------------------------------------------------------------------------
-- Author:          ALS
-- History:
--  ALS         09/12/01      -- Created from PCI eval timer
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

library unisim;
use unisim.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--          No generics
--
-- Definition of Ports:
--          Clk             -- clock
--          Rst             -- active high reset
--          Eval_timeout    -- timer has expired
-------------------------------------------------------------------------------

entity eval_timer is
  port (
    Clk             : in   std_logic;
    Rst             : in   std_logic;
    Eval_timeout    : out  std_logic
    );

end entity eval_timer;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of eval_timer is

-----------------------------------------------------------------------------
-- Constant Declarations
-----------------------------------------------------------------------------
  constant NUM_BITS     : integer   := 8;
-----------------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------------
  
  signal co          : std_logic_vector(0 to 4); -- carry out  
  signal ceo         : std_logic_vector(0 to 4); -- count enable out
  signal ceo_d1      : std_logic_vector(0 to 4); -- registered count enable out 
  
  signal zeros       : std_logic_vector(NUM_BITS-1 downto 0);

-----------------------------------------------------------------------------
-- Component Declarations
-----------------------------------------------------------------------------

component Counter is
   generic(
            C_NUM_BITS : Integer := 9
          );

  port (
    Clk           : in  std_logic;
    Rst           : in  std_logic;  
    Load_In       : in  std_logic_vector(C_NUM_BITS - 1 downto 0);
    Count_Enable  : in  std_logic;
    Count_Load    : in  std_logic;
    Count_Down    : in  std_logic;
    Count_Out     : out std_logic_vector(C_NUM_BITS - 1 downto 0);
    Carry_Out     : out std_logic 
    );
end component Counter;

component FDRE
  port (
    Q : out std_logic;
    C : in std_logic;
    CE : in std_logic;
    D : in std_logic;
    R : in std_logic
  );
end component;

component FDR
  port (
    Q : out std_logic;
    C : in std_logic;
    D : in std_logic;
    R : in std_logic
  );
end component;


begin  -- VHDL_RTL
-- set the load value to zero
zeros <= (others => '0');
-- Generate a 40-bit counter from 5 8-bit counters. Register the carry-out between counters
-- to avoid timing problems.

COUNTER_GEN: for i in 0 to 4 generate
    -- first 8-bit counter
    FIRST: if i = 0 generate
        COUNT_0_I: Counter
            generic map (C_NUM_BITS => NUM_BITS)
            port map ( Clk => Clk,
                       Rst => Rst,
                       Load_in => zeros,
                       Count_Enable => '1',
                       Count_Load => '0',
                       Count_Down => '0',
                       Count_out => open,
                       Carry_Out => co(0)
                     );
        -- register the carry out to create the count enable out 
          ceo(i) <= co(i);
          FDR_0_I: FDR
            port map (
              Q => ceo_d1(i),
              C => Clk,
              D => ceo(i),
              R => Rst
            );

   end generate FIRST;
   -- all other eight bit counters and the carry out register
   ALL_OTHERS: if i /= 0 generate
        COUNT_I: Counter
            generic map (C_NUM_BITS => NUM_BITS)
            port map ( Clk => Clk,
                       Rst => Rst,
                       Load_in => zeros,
                       Count_Enable => ceo_d1(i-1),
                       Count_Load => '0',
                       Count_Down => '0',
                       Count_out => open,
                       Carry_Out => co(i)
                     );

        -- register the carry out AND the count enable to create the count enable out      
          ceo(i) <= co(i) and ceo_d1(i-1);
          FDR_0_I: FDR
            port map (
              Q => ceo_d1(i),
              C => Clk,
              D => ceo(i),
              R => Rst
            );
        

   
  end generate ALL_OTHERS;
  
end generate COUNTER_GEN;

-- Using the final carry out as a CE, clock a '1' to assert and hold the eval_timeout signal.
FDRE_I: FDRE
  port map (
    Q => eval_timeout, --[out]
    C => Clk, --[in]
    CE => ceo_d1(4), --[in]
    D => '1', --[in]
    R => Rst --[in]
  );

                                 

end imp;

