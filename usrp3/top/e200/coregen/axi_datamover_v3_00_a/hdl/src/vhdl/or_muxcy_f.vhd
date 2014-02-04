-------------------------------------------------------------------------------
-- $Id: or_muxcy_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- or_muxcy_f
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
-- ** Copyright (c) 2006-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:       or_muxcy_f.vhd
--
-- Description:
--                  (Note: It is recommended to use this module sparingly.
--                   XST synthesis inferral of reduction-OR functionality
--                   has progressed to where a carry-chain implementation
--                   will be selected if it has advantages. At the same
--                   time, if a rigid carry chain structure is not imposed,
--                   XST has more degrees of freedom for optimization.
--
--                   This module can be used to get an inferred implementation
--                   by specifying C_FAMILY = "nofamily", which is the default
--                   value of this Generic. It is equally possible to use
--                   a reduction-or function (see or_reduce, below, for an
--                   example) instead of this module.
--
--                   If however the designer wants without compromise
--                   a structural carry-chain implementation, then this
--                   module can be used with C_FAMILY set to the target
--                   Xilinx FPGA family.
--
--                   End of Note.
--                  )
--
--
--                 Or_out <= or_reduce(In_bus)
--
--                 i.e., OR together the bits in In_bus and assign to Or_out.
--
--                 The implementation uses a single LUT if possible.
--                 Otherwise, if C_FAMILY supports the carry chain concept,
--                 it uses a minimal number of LUTs on a carry chain.
--                 The native LUT size of C_FAMILY is taken into account.
--                  
-------------------------------------------------------------------------------
-- Structure:       Common use module
-------------------------------------------------------------------------------

-- Author:      FLO
-- History:
--  FLO         07/06/06      -- First version - derived from or_with_enable_f
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
library ieee;
use     ieee.std_logic_1164.all;
--
entity or_muxcy_f is
    generic (
        C_NUM_BITS             : integer;
        C_FAMILY               : string := "nofamily"
    );
    port (
        In_bus      : in  std_logic_vector(0 to C_NUM_BITS-1);
        Or_out      : out std_logic     
    );
end or_muxcy_f;


library proc_common_v3_00_a;
use     proc_common_v3_00_a.family_support.all;
        -- Makes visible the function 'supported' and related types,
        -- including enumeration literals for the unisim primitives (e.g.
        -- the "u_" prefixed identifiers such as u_MUXCY, u_LUT4, etc.).

library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
--
architecture implementation of or_muxcy_f is

    ----------------------------------------------------------------------------
    -- Here is determined the largest LUT width supported by the target family.
    -- If no LUT is supported, the width is set to a very large number, which,
    -- as things are structured, will cause an inferred implementation
    -- to be used.
    ----------------------------------------------------------------------------
    constant lut_size : integer
                      := native_lut_size(fam_as_string => C_FAMILY,
                                         no_lut_return_val => integer'high);

    ----------------------------------------------------------------------------
    -- Here is determined which structural or inferred implementation to use.
    ----------------------------------------------------------------------------
    constant USE_STRUCTURAL_A : boolean := supported(C_FAMILY, u_MUXCY) and
                                           In_bus'length > lut_size;
              -- Structural implementation not needed if the number
              -- bits to be ORed will fit into a single LUT.
    constant USE_INFERRED     : boolean := not USE_STRUCTURAL_A;


    ----------------------------------------------------------------------------
    -- Reduction OR function.
    ----------------------------------------------------------------------------
    function or_reduce (v : std_logic_vector) return std_logic is
        variable r : std_logic := '0';
    begin
        for i in v'range loop
            r := r or v(i);
        end loop;
        return r;
    end;

    ----------------------------------------------------------------------------
    -- Min function.
    ----------------------------------------------------------------------------
    function min (a, b: natural) return natural is
    begin
        if (a>b) then return b; else return a; end if;
    end;

    ----------------------------------------------------------------------------
    -- Signal to recast In_bus into a local array whose index bounds and
    -- direction are known.
    ----------------------------------------------------------------------------
    signal OB : std_logic_vector(0 to In_bus'length-1);

   ---------------------------------------------------------------------------- 
   -- Unisim components declared locally for maximum avoidance of default
   -- binding and vcomponents version issues.
   ---------------------------------------------------------------------------- 
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

    OB <= In_bus;

    ----------------------------------------------------------------------------
    -- Inferred implementation.
    ----------------------------------------------------------------------------
    INFERRED_GEN : if USE_INFERRED generate
    begin
        Or_out <= or_reduce(OB);
    end generate INFERRED_GEN;


    ----------------------------------------------------------------------------
    -- Structural implementation.
    ----------------------------------------------------------------------------
    STRUCTURAL_A_GEN : if USE_STRUCTURAL_A generate
        constant NUM_LUTS : positive := ((OB'length + lut_size - 1) / lut_size);
        signal cy : std_logic_vector(0 to NUM_LUTS);
    begin
        --
        cy(0) <= '0';
        --
        GEN : for i in 0 to NUM_LUTS-1 generate
            signal lut : std_logic;
        begin
            lut <= not or_reduce(OB(i*lut_size to
                                 min((i+1)*lut_size-1, OB'right))); -- The min
                                 -- function catches the case where one LUT
                                 -- is partial (i.e., not all inputs are used).
            --
            I_MUXCY : component MUXCY
                      port map  (O =>cy(NUM_LUTS - i),
                                 CI=>cy(NUM_LUTS - 1 - i),
                                 DI=>'1',
                                 S =>lut);
            -- Note on cy handling: As done here, the partial LUT, if any,
            --                      is placed at the start of the cy chain.
        end generate;
        --
        Or_out <= cy(NUM_LUTS);
        --
    end generate STRUCTURAL_A_GEN;

end implementation;

