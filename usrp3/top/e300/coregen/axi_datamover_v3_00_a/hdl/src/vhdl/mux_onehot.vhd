-------------------------------------------------------------------------------
-- $Id: mux_onehot.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- mux_onehot - arch and entity
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
-- Filename:        mux_onehot.vhd
--
-- Description:     Parameterizable multiplexer with one hot select lines
--                  
--
-------------------------------------------------------------------------------
-- Structure:   
--      Multi- use module
--------------------------------------------------------------------------------
-- Author:      BLT
-- History:
--  BLT             2/22/01      -- First version
--
--  ALS             3/30/01     
-- ^^^^^^
--      Added process to replicate select bus for each of the data buses 
-- ~~~~~~
--
--  ALS             4/19/01
-- ^^^^^^
--      Modified assignments of DI and CI to use signals one and zero. VHDL87 
--      doesn't support direct assignment of these signals to '0' and '1'.
-- ~~~~~~
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Incorporated new disclaimer header
-- ^^^^^^
--
---------------------------------------------------------------------------------
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
-- Generic definitions:
--
--      C_DW: Data width of buses entering the mux. Valid range is 1 to 256.
--      C_NB: Number of data buses entering the mux. Valid range is 1 to 64.
--
--      The input data is represented by a one-dimensional bus that is made up
--      of all of the data buses concatenated together. For example, a 4 to 1
--      mux with 2 bit data buses (C_DW=2,C_NB=4) is represented by:
--          
--        D = (Bus0Data0, Bus0Data1, Bus1Data0, Bus1Data1, Bus2Data0, Bus2Data1,
--             Bus3Data0, Bus3Data1)
--      
--      There is a separate select line for EACH data bit, leaving it to the 
--      user to set fanout on the select lines before using this mux. The select
--      bus into the mux is created by concatenating the one-hot select bus for
--      a single output bit as many times as needed for the data width. Continuing
--      the 4 to 1, 2 bit example from above:
--
--        S = (Sel0Data0,Sel1Data0,Sel2Data0,Sel3Data0,
--             Sel0Data1,Sel1Data1,Sel2Data1,Sel3Data1)
--
--      4/3/01 ALS - modified the code slightly to have the select bus generated
--      from within this code - input select bus is simply one bit per bus
---------------------------------------------------------------------------------  
library ieee;
use ieee.std_logic_1164.all;

-- UNISIM library is required when Xilinx primitives are instantiated.
library unisim;
use unisim.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_DW: Data width of buses entering the mux. Valid range is 1 to 256.
--      C_NB: Number of data buses entering the mux. Valid range is 1 to 64.
--
--      The input data is represented by a one-dimensional bus that is made up
--      of all of the data buses concatenated together. For example, a 4 to 1
--      mux with 2 bit data buses (C_DW=2,C_NB=4) is represented by:
--          
--        D = (Bus0Data0, Bus0Data1, Bus1Data0, Bus1Data1, Bus2Data0, Bus2Data1,
--             Bus3Data0, Bus3Data1)
--      
--      There is a separate select line for EACH data bit, leaving it to the 
--      user to set fanout on the select lines before using this mux. The select
--      bus into the mux is created by concatenating the one-hot select bus for
--      a single output bit as many times as needed for the data width. Continuing
--      the 4 to 1, 2 bit example from above:
--
--        S = (Sel0Data0,Sel1Data0,Sel2Data0,Sel3Data0,
--             Sel0Data1,Sel1Data1,Sel2Data1,Sel3Data1)
--
--      4/3/01 ALS - modified the code slightly to have the select bus generated
--      from within this code - input select bus is simply one bit per bus
--
-- Definition of Ports:
--      input D           -- input data bus
--      input S           -- input select bus
--
--      output Y          -- output bus
-------------------------------------------------------------------------------

entity mux_onehot is 
   generic( C_DW: integer := 32;
            C_NB: integer := 5 );
   port(
      D: in std_logic_vector(0 to C_DW*C_NB-1);
      S: in std_logic_vector(0 to C_NB-1);
      Y: out std_logic_vector(0 to C_DW-1));

end mux_onehot;

architecture imp of mux_onehot is

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal Dreord:      std_logic_vector(0 to C_DW*((C_NB+1)/2)*2-1);
signal sel:         std_logic_vector(0 to C_DW*((C_NB+1)/2)*2-1);
signal lutout:      std_logic_vector(0 to (C_DW*(C_NB+1)/2)-1); 
signal cyout:       std_logic_vector(0 to (C_DW*(C_NB+1)/2)-1); 
signal one:         std_logic := '1';
signal zero:        std_logic := '0';

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------
-- MUXCY used to multiplex busses
component MUXCY 
port( 
      O        :  out   STD_LOGIC; 
      DI       :  in    STD_LOGIC; 
      CI       :  in    STD_LOGIC; 
      S        :  in    STD_LOGIC); 
end component; 
begin

-- Reorder data buses

REORD: process( D )
variable m,n: integer;
begin

for m in 0 to C_DW-1 loop
  for n in 0 to C_NB-1 loop
    Dreord( m*C_NB+n) <= D( n*C_DW+m );
  end loop;
end loop;
end process REORD;

-------------------------------------------------------------------------------
-- REPSELS_PROCESS
-------------------------------------------------------------------------------
-- The one-hot select bus contains 1-bit for each bus. To more easily
-- parameterize the carry chains and reduce loading on the select bus, these 
-- signals are replicated into a bus that replicates the select bits for the 
-- data width of the busses
-------------------------------------------------------------------------------
REPSELS_PROCESS : process ( S )
variable i, j   : integer;

begin
    -- loop through all data bits and busses
    for i in 0 to C_DW-1 loop
        for j in 0 to C_NB-1 loop
            sel(i*C_NB+j) <= S(j);
        end loop;
    end loop;
end process REPSELS_PROCESS;

-- Handle case for even number of buses

EVEN_GEN: if C_NB rem 2 = 0 and C_NB /= 2 generate
    DATA_WIDTH_GEN: for i in 0 to C_DW-1 generate

        lutout(i*(C_NB+1)/2) <= not((Dreord(i*C_NB)   and sel(i*C_NB)) or
                                    (Dreord(i*C_NB+1) and sel(i*C_NB+1)));
        CYMUX_FIRST: MUXCY
            port map (CI=> zero,
                      DI=> one,
                      S=>lutout(i*(C_NB+1)/2),
                      O=>cyout(i*(C_NB+1)/2));

        NUM_BUSES_GEN: for j in 1 to (C_NB+1)/2-1 generate
            lutout(i*(C_NB+1)/2+j) <= not((Dreord(i*C_NB+j*2)   and sel(i*C_NB+j*2)) or
                                          (Dreord(i*C_NB+j*2+1) and sel(i*C_NB+j*2+1)));
            CARRY_MUX: MUXCY
                port map (CI=>cyout(i*(C_NB+1)/2+j-1),
                          DI=> one,
                          S=>lutout(i*(C_NB+1)/2+j),
                          O=>cyout(i*(C_NB+1)/2+j));
        end generate;
    Y(i) <= cyout(i*(C_NB+1)/2+(C_NB+1)/2-1);
    end generate;
end generate;

-- Handle case for odd number of buses

ODD_GEN: if C_NB rem 2 /= 0 and C_NB /= 1 generate
    DATA_WIDTH_GEN: for i in 0 to C_DW-1 generate
        lutout(i*(C_NB+1)/2) <= not((Dreord(i*C_NB)   and sel(i*C_NB)) or
                                    (Dreord(i*C_NB+1) and sel(i*C_NB+1)));
        CYMUX_FIRST: MUXCY
            port map (CI=> zero,
                      DI=> one,
                      S=>lutout(i*(C_NB+1)/2),
                      O=>cyout(i*(C_NB+1)/2));

        NUM_BUSES_GEN: for j in 1 to (C_NB+1)/2-2 generate
            lutout(i*(C_NB+1)/2+j) <= not((Dreord(i*C_NB+j*2)   and sel(i*C_NB+j*2)) or
                                          (Dreord(i*C_NB+j*2+1) and sel(i*C_NB+j*2+1)));
            CARRY_MUX: MUXCY
                port map (CI=>cyout(i*(C_NB+1)/2+j-1),
                          DI=> one,
                          S=>lutout(i*(C_NB+1)/2+j),
                          O=>cyout(i*(C_NB+1)/2+j));
        end generate;
        
        ODD_BUS_GEN: for j in (C_NB+1)/2-1 to (C_NB+1)/2-1 generate
            lutout(i*(C_NB+1)/2+j) <= not((Dreord(i*C_NB+j*2)   and sel(i*C_NB+j*2)));
            CARRY_MUX: MUXCY
                port map (CI=>cyout(i*(C_NB+1)/2+j-1),
                          DI=> one,
                          S=>lutout(i*(C_NB+1)/2+j),
                          O=>cyout(i*(C_NB+1)/2+j));
        end generate;
    Y(i) <= cyout(i*(C_NB+1)/2+(C_NB+1)/2-1);
    end generate;
end generate;

ONE_GEN: if C_NB = 1 generate
    Y <= D;
end generate;

TWO_GEN: if C_NB = 2 generate
    DATA_WIDTH_GEN2: for i in 0 to C_DW-1 generate
        lutout(i*(C_NB+1)/2) <= ((Dreord(i*C_NB)   and sel(i*C_NB)) or
                                 (Dreord(i*C_NB+1) and sel(i*C_NB+1)));
        Y(i) <= lutout(i*(C_NB+1)/2);
    end generate;
end generate;   

end imp;
            
                      

