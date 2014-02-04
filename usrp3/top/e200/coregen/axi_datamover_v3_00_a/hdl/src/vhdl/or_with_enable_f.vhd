-------------------------------------------------------------------------------
-- $Id: or_with_enable_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- or_with_enable_f
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
-- Filename:       or_with_enable_f.vhd
--
-- Description:    Y <= or_reduce(OR_bits) and Enable
--
--                 i.e., OR together the OR_bits and AND the result with Enable.
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
--  FLO         05/06/06      -- First version
-- ~~~~~~
-- FLO            05/25/06
-- ^^^^^^
--   -Using native_lut_size function from family_support.
--   -Moved C_FAMILY to end of generics.
--   -Minor cleanup.
-- ~~~~~~
-- FLO            11/17/07
-- ^^^^^^
--   -Work around because XST doesn't yet support or_reduce with null argument.
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
entity or_with_enable_f is
    generic (
        C_OR_WIDTH             : natural;
        C_FAMILY               : string := "nofamily"
    );
    port (
        OR_bits      : in  std_logic_vector(0 to C_OR_WIDTH-1);
        Enable       : in  std_logic;
        Y            : out std_logic     
    );
end or_with_enable_f;


library proc_common_v3_00_a;
use     proc_common_v3_00_a.family_support.all;
        -- Makes visible the function 'supported' and related types,
        -- including enumeration literals for the unisim primitives (e.g.
        -- the "u_" prefixed identifiers such as u_MUXCY, u_LUT4, etc.).

library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
--
architecture implementation of or_with_enable_f is

    ----------------------------------------------------------------------------
    -- Here is determined the largest LUT width supported by the target family.
    -- If no LUT is supported, the width is set to a very large number, which,
    -- as things are structured, will cause an inferred implementation
    -- to be used.
    ----------------------------------------------------------------------------
    constant LUT_SIZE : integer := native_lut_size(fam_as_string => C_FAMILY,
                                                   no_lut_return_val => integer'high
                                                  );

    ----------------------------------------------------------------------------
    -- Here is determined which structural or inferred implementation to use.
    ----------------------------------------------------------------------------
    constant USE_STRUCTURAL_A : boolean := supported(C_FAMILY, u_MUXCY) and
                                           OR_bits'length + 1 > LUT_SIZE;
              -- Structural implementation not needed if the number of logic
              -- inputs, i.e., the Enable plus the number of bits to be ORed,
              -- will fit into a single LUT.
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
    -- Signal to recast OR_bits into a local array whose index bounds and
    -- direction are known.
    ----------------------------------------------------------------------------
    signal OB : std_logic_vector(0 to OR_bits'length-1);

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

    OB <= OR_bits;

    ----------------------------------------------------------------------------
    -- Inferred implementation.
    ----------------------------------------------------------------------------
    INFERRED_GEN : if USE_INFERRED generate
    begin
        Y <= Enable and or_reduce(OB);
    end generate INFERRED_GEN;


    ----------------------------------------------------------------------------
    -- Structural implementation.
    ----------------------------------------------------------------------------
    STRUCTURAL_A_GEN : if USE_STRUCTURAL_A generate
        constant NUM_PURE_OR_LUTS : positive := (OB'length / LUT_SIZE);
        signal cy : std_logic_vector(0 to NUM_PURE_OR_LUTS);
        signal final_lut : std_logic;
    begin
        --
        cy(0) <= '0';
        --
        PURE_OR_GEN : for i in 0 to NUM_PURE_OR_LUTS-1 generate
            signal lut : std_logic;
        begin
            lut <= not or_reduce(OB(i*LUT_SIZE to (i+1)*LUT_SIZE-1));
            --
            I_MUXCY : component MUXCY
                      port map  (O =>cy(i+1),
                                 CI=>cy(i),
                                 DI=>'1',
                                 S =>lut);
        end generate;
        --
        XST_WA_GEN : if (OB'length mod LUT_SIZE) = 0 generate begin
          final_lut <=   Enable;
        end generate;
        --
        ORIG_GEN : if (OB'length mod LUT_SIZE) /= 0 generate begin
        final_lut <=   Enable 
                   and not or_reduce(OB(NUM_PURE_OR_LUTS*LUT_SIZE to OB'right));
        end generate;
        --
        I_MUXCY_FINAL : component MUXCY
                        port map  (O =>Y,
                                   CI=>cy(NUM_PURE_OR_LUTS),
                                   DI=>Enable,
                                   S =>final_lut);
        --
    end generate STRUCTURAL_A_GEN;

end implementation;

