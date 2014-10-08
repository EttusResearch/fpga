-------------------------------------------------------------------------------
-- $Id: mux_onehot_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- mux_onehot_f - arch and entity
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
-- Filename:        mux_onehot_f.vhd
--
-- Description:     Parameterizable multiplexer with one hot select lines.
--
--                  Please refer to the entity interface while reading the
--                  remainder of this description.
--
--                  If n is the index of the single select line of S(0 to C_NB-1)
--                  that is asserted, then
--
--                      Y(0 to C_DW-1) <= D(n*C_DW to n*C_DW + C_DW -1)
--
--                  That is, Y selects the nth group of C_DW consecutive
--                  bits of D.
--
--                  Note that C_NB = 1 is handled as a special case in which
--                  Y <= D, without regard to the select line, S.
--
--                  The Implementation depends on the C_FAMILY parameter.
--                  If the target family supports the needed primitives,
--                  a carry-chain structure will be implemented. Otherwise,
--                  an implementation dependent on synthesis inferral will
--                  be generated.
--
-------------------------------------------------------------------------------
-- Structure:   
--      mux_onehot_f
--          family_support
--------------------------------------------------------------------------------
-- Author:      FLO
-- History:
--  FLO             11/30/05      -- First version derived from mux_onehot.vhd
--                                -- by BLT and ALS.
--
-- ~~~~~~
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Changed proc_common library version to v3_00_a
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
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Generic and Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics and Ports
--
--      C_DW: Data width of buses entering the mux. Valid range is 1 to 256.
--      C_NB: Number of data buses entering the mux. Valid range is 1 to 64.
--
--      input D           -- input data bus
--      input S           -- input select bus
--      output Y          -- output bus
--
--      The input data is represented by a one-dimensional bus that is made up
--      of all of the data buses concatenated together. For example, a 4 to 1
--      mux with 2 bit data buses (C_DW=2,C_NB=4) is represented by:
--          
--        D = (Bus0Data0, Bus0Data1, Bus1Data0, Bus1Data1, Bus2Data0, Bus2Data1,
--             Bus3Data0, Bus3Data1)
--      
--        Y = (Bus0Data0, Bus0Data1) if S(0)=1 else
--            (Bus1Data0, Bus1Data1) if S(1)=1 else
--            (Bus2Data0, Bus2Data1) if S(2)=1 else
--            (Bus3Data0, Bus3Data1) if S(3)=1 
--
--        Only one bit of S should be asserted at a time.
--
-------------------------------------------------------------------------------

library proc_common_v3_00_a;
use     proc_common_v3_00_a.family_support.all; -- 'supported' function, etc.
--
entity mux_onehot_f is 
   generic( C_DW: integer := 32;
            C_NB: integer := 5;
            C_FAMILY : string := "virtexe");
   port(
      D: in std_logic_vector(0 to C_DW*C_NB-1);
      S: in std_logic_vector(0 to C_NB-1);
      Y: out std_logic_vector(0 to C_DW-1));

end mux_onehot_f;

library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
architecture imp of mux_onehot_f is

    constant NLS : natural := native_lut_size(fam_as_string => C_FAMILY,
                                              no_lut_return_val => 2*C_NB);

    function lut_val(D, S : std_logic_vector) return std_logic is
        variable rn : std_logic := '0';
    begin
        for i in D'range loop
            rn := rn or (S(i) and D(i));
        end loop;
        return not rn;
    end;

    function min(i, j : integer) return integer is
    begin
        if i < j then return i; else return j; end if;
    end;

-----------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal Dreord:      std_logic_vector(0 to C_DW*C_NB-1);
signal sel:         std_logic_vector(0 to C_DW*C_NB-1);

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------
component MUXCY
    port
    (
        O : out std_ulogic;
        CI : in std_ulogic;
        DI : in std_ulogic;
        S : in std_ulogic
    );
end component;

begin

-- Reorder data buses

WA_GEN : if C_DW > 0 generate -- XST WA
REORD: process( D )
variable m,n: integer;
begin
for m in 0 to C_DW-1 loop
  for n in 0 to C_NB-1 loop
    Dreord( m*C_NB+n) <= D( n*C_DW+m );
  end loop;
end loop;
end process REORD;
end generate;

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


GEN: if C_NB > 1 generate
    constant BPL : positive := NLS / 2; -- Buses per LUT is the native lut
                                        -- size divided by two.signals per bus.
    constant NUMLUTS : positive := (C_NB+(BPL-1))/BPL;
begin

    DATA_WIDTH_GEN: for i in 0 to C_DW-1 generate
        signal cyout  : std_logic_vector(0 to NUMLUTS);
        signal lutout : std_logic_vector(0 to NUMLUTS-1);
    begin

        cyout(0) <= '0';

        NUM_BUSES_GEN: for j in 0 to NUMLUTS - 1 generate
            constant BTL : positive := min(BPL, C_NB - j*BPL);
            -- Number of Buses This Lut (for last LUT this may be less than BPL)
        begin
            lutout(j) <= lut_val(D => Dreord(i*C_NB+j*BPL to i*C_NB+j*BPL+BTL-1),
                                 S =>    sel(i*C_NB+j*BPL to i*C_NB+j*BPL+BTL-1)
                                );

            MUXCY_GEN : if NUMLUTS > 1 generate
            MUXCY_I : component MUXCY
                port map (CI=>cyout(j),
                          DI=> '1',
                          S=>lutout(j),
                          O=>cyout(j+1));
            end generate;

        end generate;

    Y(i) <= cyout(NUMLUTS) when NUMLUTS > 1 else not lutout(0); -- If just one
                                            -- LUT, then take value from
                                            -- lutout rather than cyout.
    end generate;
end generate;


ONE_GEN: if C_NB = 1 generate
    Y <= D;
end generate;

end imp;

