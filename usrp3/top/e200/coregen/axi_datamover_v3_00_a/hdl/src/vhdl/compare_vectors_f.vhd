-------------------------------------------------------------------------------
-- $Id: compare_vectors_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- compare_vectors_f.vhd - entity/architecture pair
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
-- ** Copyright (c) 2008-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:      compare_vectors_f.vhd
--
-- Description:   Compare vectors Vec1 and Vec2 for equality: Eq <= Vec1 = Vec2
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  -- compare_vectors_f.vhd
--                     -- family_support.vhd
--
-------------------------------------------------------------------------------
-- History:
-- FLO            04/26/06    First Version
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
use unisim.vcomponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.family_support.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
-- Definition of Generics:
--          C_WIDTH     -- number of bits to compare
--          C_FAMILY    -- target FPGA family
--
-- Definition of Ports:
--          Vec1           -- first  standard_logic_vector input
--          Vec2           -- second standard_logic_vector input
--          Eq             -- Vec1 = Vec2-------------------------------------------------------------------------------
-----------------------------------------------------------------------------
entity compare_vectors_f is
  generic (
    C_WIDTH    : natural;
    C_FAMILY   : string := "nofamily"
    );
  port (
    Vec1    : in   std_logic_vector(0 to C_WIDTH-1);
    Vec2    : in   std_logic_vector(0 to C_WIDTH-1);
    Eq      : out  std_logic
    );
end entity compare_vectors_f;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------
architecture imp of compare_vectors_f is
   
    type bo2sl_type is array (boolean) of std_logic;
    constant bo2sl  : bo2sl_type := (false => '0', true => '1');

    constant NLS : natural := native_lut_size(C_FAMILY);

    constant USE_INFERRED : boolean :=    not supported(C_FAMILY, u_MUXCY)
                                       or NLS<2 -- Native LUT not big enough.
                                       or 2*C_WIDTH <= NLS; -- Just one LUT
                                                            -- needed.

    function lut_val(V1, V2 : std_logic_vector) return std_logic is
        variable r : std_logic := '1';
    begin
        for i in V1'range loop
            r := r and bo2sl(V1(i) = V2(i));
        end loop;
        return r; -- Return V1=V2
    end;

    function min(i, j : integer) return integer is
    begin
        if i < j then return i; else return j; end if;
    end;

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

begin  --architecture

STRUCTURAL_A_GEN: if USE_INFERRED = false generate

    constant BPL : positive := NLS / 2; -- Bits per LUT is the native lut
                                        -- size divided by two.
    constant NUMLUTS : positive := (C_WIDTH+(BPL-1))/BPL; -- NUMLUTS will be
             -- greater than or equal to 2 because of how USE_INFERRED
             -- is declared.
    signal cyout : std_logic_vector(0 to NUMLUTS);
    signal lutout: std_logic_vector(0 to NUMLUTS-1);

begin

    cyout(0) <= '1';

    PER_LUT_GEN: for i in NUMLUTS - 1 downto 0 generate
        constant NI  : natural := NUMLUTS-1-i; -- Used to place high-order,
            -- low-index bits at the top of carry chain.
        constant BTL : positive := min(BPL, C_WIDTH-NI*BPL);
        -- Number of comparison bit positions at this LUT. (For the LUT at
        -- the bottom of the carry chain this may be less than BPL.)
    begin
        lutout(i) <= lut_val(V1 => Vec1(NI*BPL to NI*BPL+BTL-1),
                             V2 => Vec2(NI*BPL to NI*BPL+BTL-1)
                            ); -- Corres. sections of Vec1 and Vec2 are equal
        --
        MUXCY_I : component MUXCY
            port map (CI=>cyout(i),
                      DI=> '0',
                      S=>lutout(i),
                      O=>cyout(i+1));
    end generate;

    Eq <= cyout(NUMLUTS);

end generate;


INFERRED_GEN: if USE_INFERRED = true generate
    Eq <= '1' when Vec1 = Vec2 else '0';
end generate;


end imp;

