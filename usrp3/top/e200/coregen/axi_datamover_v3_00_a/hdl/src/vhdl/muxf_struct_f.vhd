-------------------------------------------------------------------------------
-- $Id: muxf_struct_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- srl_fifo_rbu_f - entity / architecture pair
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
-- Filename:        muxf_struct_f.vhd
--
-- Description:     Given a vector of input bits, Iv (not necessarily a
--                  power of two). and a select value, Sel, this block
--                  will build the multiplexing function
--
--                      O <= Iv(Sel) 
--
--                  using the MUXF (MUXF5, MUXF6, etc.) primitives of
--                  the target FPGA family, C_FAMILY, if possible and,
--                  otherwise, using inferred multiplexers.
--
--                  Since MUXF primitives are targeted, it is proper
--                  that the Iv signals are driven by LUTs.
--
--                  A help entity, muxf_struct, which is instantiated
--                  recursively, is used to facilitate the implementation.
--                  (So, compiling this file will add two entities,
--                  muxf_struct and muxf_struct_f, to the target library.)
-- 
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              muxf_struct_f.vhd
--                  muxf_struct (entity and architecture in this file)
--                      proc_common_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          Farrell Ostler
--
-- History:
--   FLO   12/05/05   First Version. Derived from srl_fifo_rbu.
--
-- ~~~~~~
--  FLO         2007-12-12
-- ^^^^^^
--  Using function clog2 now instead of log2 to eliminate superfluous warnings.
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
--      predecessor value by # clks:            "*_p#"

---(
--------------------------------------------------------------------------------
-- This is a helper entity. The entity declaration for muxf_struct_f is
-- further, below.
--------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library proc_common_v3_00_a;
use     proc_common_v3_00_a.proc_common_pkg.clog2;
use     proc_common_v3_00_a.family_support.all; -- supported, primitives_type
library unisim;
entity muxf_struct is
  generic (
        C_START_LEVEL : natural;
        C_NUM_INPUTS  : positive;
        C_NI_PO2E     : positive; -- Num Inputs, Power-of-2 Envelope
        C_FAMILY      : string
  );
  port (
                LO : out std_logic; -- Normally only one of
                O  : out std_logic; -- LO or O would be used.
                Iv : in  std_logic_vector(0 to C_NUM_INPUTS-1);
                Sel: in  std_logic_vector(0 to clog2(C_NI_PO2E)-1)
  );
end entity muxf_struct;

library proc_common_v3_00_a;
library unisim;
use     unisim.all; -- Makes unisim entities available for default binding.
--------------------------------------------------------------------------------
-- Line-length guideline purposely not followed in some places to expose parallel code structures.
--------------------------------------------------------------------------------
architecture imp of muxf_struct is
    --
    type  bo2na_type is array(boolean) of natural;
    constant bo2na      :  bo2na_type := (false => 0, true => 1);
    --
    constant SIZE   : natural := Iv'length;
    constant PO2E : natural := C_NI_PO2E;
    constant THIS_LEVEL : natural := C_START_LEVEL + clog2(PO2E);
    constant K_FAMILY : families_type := str2fam(C_FAMILY);
    constant S5 : boolean := supported(K_FAMILY, u_MUXF5_D) and THIS_LEVEL = 5;
    constant S6 : boolean := supported(K_FAMILY, u_MUXF6_D) and THIS_LEVEL = 6;
    constant S7 : boolean := supported(K_FAMILY, u_MUXF7_D) and THIS_LEVEL = 7;
    constant S8 : boolean := supported(K_FAMILY, u_MUXF8_D) and THIS_LEVEL = 8;
    constant INFERRED : boolean := not(S5 or S6 or S7 or S8);
    --
    signal s, i0, i1 : std_logic; -- If there is no i1 at a particular mux level,
        -- it is left undriven and s is tied to '0'.


    component MUXF5_D
        port
        (
            LO : out std_ulogic;
            O : out std_ulogic;
            I0 : in std_ulogic;
            I1 : in std_ulogic;
            S : in std_ulogic
        );
    end component;

    component MUXF6_D
        port
        (
            LO : out std_ulogic;
            O : out std_ulogic;
            I0 : in std_ulogic;
            I1 : in std_ulogic;
            S : in std_ulogic
        );
    end component;

    component MUXF7_D
        port
        (
            LO : out std_ulogic;
            O : out std_ulogic;
            I0 : in std_ulogic;
            I1 : in std_ulogic;
            S : in std_ulogic
        );
    end component;

    component MUXF8_D
        port
        (
            LO : out std_ulogic;
            O : out std_ulogic;
            I0 : in std_ulogic;
            I1 : in std_ulogic;
            S : in std_ulogic
        );
    end component;


begin
    -- Below, some generates and component instantiations are one per line
    -- to show similarities and differences.

    ----------------------------------------------------------------------------
    -- Base instance, just one or two inputs, no recursion. 
    ----------------------------------------------------------------------------
    E2_GEN : if PO2E=2 and SIZE=2 generate s <= Sel(0); i0 <= Iv(0); i1 <= Iv(1); end generate; 
    E1_GEN : if PO2E=2 and SIZE=1 generate s <= '0';    i0 <= Iv(0); end generate;-- No driver for i1

    
    ----------------------------------------------------------------------------
    -- Use recursion to get lower-level mux structures to feed the mux at
    -- this level.
    ----------------------------------------------------------------------------
    GT2_GEN : if PO2E > 2 generate
        constant NE : natural := PO2E/2; -- Next envelope.
        constant BOTH : boolean := (SIZE > NE); -- Needs recursive call for
            -- both the left and right sides; otherwise just a left-side
            -- recursive call is needed (with C_NI_PO2E reduced by half) and Iv
            -- passed down unchanged.
        constant LSIZE : natural :=   bo2na(BOTH)     * (2**(clog2(SIZE))/2)
                                    + bo2na(not BOTH) * SIZE;
                         -- 1st option above: LSIZE is next smaller power of 2
                         -- 2nd option above: SIZE is passed down unchanged
    begin

      LEFT_GEN : IF true generate
        I_I0 : entity work.muxf_struct
            generic map (C_START_LEVEL => C_START_LEVEL,
                         C_NUM_INPUTS  => LSIZE,
                         C_NI_PO2E     => NE,
                         C_FAMILY      => C_FAMILY
            )
            port map (LO  => i0,
                      O   => open,
                      Iv  => Iv(0 to LSIZE-1),
                      Sel => Sel(1 to Sel'right)
            )
        ;
      end generate;

      RIGHT_GEN : IF BOTH generate
        I_I1 : entity work.muxf_struct
            generic map (C_START_LEVEL => C_START_LEVEL,
                         C_NUM_INPUTS => SIZE-LSIZE,
                         C_NI_PO2E => NE,
                         C_FAMILY => C_FAMILY
            )
            port map (LO  => i1,
                      O   => open,
                      Iv  => Iv(LSIZE to SIZE-1),
                      Sel => Sel(1 to Sel'right)
            )
        ;
        s <= Sel(0);
      end generate;

      LEFT_ONLY_GEN : IF not BOTH generate
        s <= '0';
      end generate;

    end generate;

    -- Instantiate the mux at this level.
    --
    -- Structurals
    S5_GEN : if S5 generate I_F5 : component MUXF5_D port map ( LO => LO, O => O, I0 => i0, I1 => i1, S => s); end generate;
    S6_GEN : if S6 generate I_F6 : component MUXF6_D port map ( LO => LO, O => O, I0 => i0, I1 => i1, S => s); end generate;
    S7_GEN : if S7 generate I_F7 : component MUXF7_D port map ( LO => LO, O => O, I0 => i0, I1 => i1, S => s); end generate;
    S8_GEN : if S8 generate I_F8 : component MUXF8_D port map ( LO => LO, O => O, I0 => i0, I1 => i1, S => s); end generate;
    -- Inferred
    INFERRED_GEN : if INFERRED generate
        signal h : std_logic;
    begin
        h <= i0 when s = '0' else i1 ;
        LO <= h;
         O <= h;
    END generate;
    
end architecture imp;
---)


---(
--------------------------------------------------------------------------------
-- Generic descriptions
--------------------------------------------------------------------------------
-- C_START_LEVEL : natural  - The size of the LUTs feeding into MUXFN network.
--                            For example, for six-input LUTs,
--                            C__START_LEVEL = 6 and the first level of muxes
--                            are MUXF7.
-- C_NUM_INPUTS  : positive - The number of inputs to be muxed.
-- C_FAMILY      : string   - The target FPGA family.
--------------------------------------------------------------------------------
-- Port descriptions
--------------------------------------------------------------------------------
-- O  : out std_logic                                      - Mux ouput
-- Iv : in  std_logic_vector(0 to C_NUM_INPUTS-1)          - Mux inputs
-- Sel: in  std_logic_vector(0 to log2(C_NUM_INPUTS) - 1)  - Select lines.
--      - The Iv values must be ordered such that the correct
--      - one is selected according to O <= Iv(Sel).
--------------------------------------------------------------------------------
--
library ieee;
use     ieee.std_logic_1164.all;
library proc_common_v3_00_a;
use     proc_common_v3_00_a.proc_common_pkg.clog2;
--
entity muxf_struct_f is
  generic (
        C_START_LEVEL : natural;
        C_NUM_INPUTS  : positive;
        C_FAMILY      : string
  );
  port (
                O  : out std_logic;
                Iv : in  std_logic_vector(0 to C_NUM_INPUTS-1);
                Sel: in  std_logic_vector(0 to clog2(C_NUM_INPUTS) - 1)
  );
end muxf_struct_f;

architecture imp of muxf_struct_f is
begin

    MUXF_STRUCT_I : entity proc_common_v3_00_a.muxf_struct
    generic map (
        C_START_LEVEL => C_START_LEVEL,
        C_NUM_INPUTS  => C_NUM_INPUTS,
        C_NI_PO2E     => 2**clog2(C_NUM_INPUTS),
        C_FAMILY      => C_FAMILY
    )
    port map (
        LO  => open,
        O   => O,
        Iv  => Iv,
        Sel => Sel
    );

end imp;

---)
