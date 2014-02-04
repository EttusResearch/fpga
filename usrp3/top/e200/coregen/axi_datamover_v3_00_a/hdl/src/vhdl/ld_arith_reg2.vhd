-------------------------------------------------------------------------------
-- $Id: ld_arith_reg2.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- Loadable arithmetic register.
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
-- ** Copyright (c) 2003-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        ld_arith_reg2.vhd
-- Version:         
--------------------------------------------------------------------------------
-- Description:   A register that can be loaded and added to or subtracted from
--                (but not both). The width of the register is specified
--                with a generic. The load value and the arith
--                value, i.e. the value to be added (subtracted), may be of
--                lesser width than the register and may be
--                offset from the LSB position. (Uncovered positions
--                load or add (subtract) zero.) The register can be
--                reset, via the RST signal, to a freely selectable value.
--                The register is defined in terms of big-endian bit ordering.
--
--                ld_arith_reg2 is derived from ld_arith_reg. There are a few
--                changes:
--                - The control signal for load is active-low, LOAD_n.
--                - Boolean generic C_LOAD_OVERRIDES reverses the default that
--                  OP overrides LOAD_n when both are asserted on the
--                  same cycle.
--                - The default width is 32.
--
-------------------------------------------------------------------------------
-- Structure: 
--
--              ld_arith_reg2.vhd
-------------------------------------------------------------------------------
-- Author:      FO
--
-- History:
--
--      FO      09/01/03     -- First version, derived from ld_arith_reg
--
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
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

library ieee;
use ieee.std_logic_1164.all;

entity ld_arith_reg2 is
    generic (
        ------------------------------------------------------------------------
        -- True if the arithmetic operation is add, false if subtract.
        C_ADD_SUB_NOT : boolean := false;
        ------------------------------------------------------------------------
        -- Width of the register.
        C_REG_WIDTH   : natural := 32;
        ------------------------------------------------------------------------
        -- Reset value. (No default, must be specified in the instantiation.)
        C_RESET_VALUE : std_logic_vector;
        ------------------------------------------------------------------------
        -- Width of the load data.
        C_LD_WIDTH    : natural :=  32;
        ------------------------------------------------------------------------
        -- Offset from the LSB (toward more significant) of the load data.
        C_LD_OFFSET   : natural :=  0;
        ------------------------------------------------------------------------
        -- Width of the arithmetic data.
        C_AD_WIDTH    : natural :=  32;
        ------------------------------------------------------------------------
        -- Offset from the LSB of the arithmetic data.
        C_AD_OFFSET   : natural :=  0;
        ------------------------------------------------------------------------
        C_LOAD_OVERRIDES : boolean := false
        ------------------------------------------------------------------------
        -- Dependencies: (1) C_LD_WIDTH + C_LD_OFFSET <= C_REG_WIDTH
        --               (2) C_AD_WIDTH + C_AD_OFFSET <= C_REG_WIDTH
        ------------------------------------------------------------------------
    );
    port (
        CK     : in  std_logic;
        RST    : in  std_logic; -- Reset to C_RESET_VALUE. (Overrides OP,LOAD_n)
        Q      : out std_logic_vector(0 to C_REG_WIDTH-1);
        LD     : in  std_logic_vector(0 to C_LD_WIDTH-1); -- Load data.
        AD     : in  std_logic_vector(0 to C_AD_WIDTH-1); -- Arith data.
        LOAD_n : in  std_logic; -- Active-low enable for the load op, Q <= LD.
        OP     : in  std_logic  -- Enable for the arith op, Q <= Q + AD.
                                -- (Q <= Q - AD if C_ADD_SUB_NOT = false.)
                                -- (Overrrides LOAD_n
                                --  unless C_LOAD_OVERRIDES = true)
    );
end ld_arith_reg2;
  

library unisim;
use unisim.all;

library ieee;
use ieee.numeric_std.all;

architecture imp of ld_arith_reg2 is

    component MULT_AND
       port(
          LO :  out   std_ulogic;
          I1 :  in    std_ulogic;
          I0 :  in    std_ulogic);
    end component;

    component MUXCY is
      port (
        DI : in  std_logic;
        CI : in  std_logic;
        S  : in  std_logic;
        O  : out std_logic);
    end component MUXCY;

    component XORCY is
      port (
        LI : in  std_logic;
        CI : in  std_logic;
        O  : out std_logic);
    end component XORCY;

    component FDRE is
      port (
        Q  : out std_logic;
        C  : in  std_logic;
        CE : in  std_logic;
        D  : in  std_logic;
        R  : in  std_logic
      );
    end component FDRE;
  
    component FDSE is
      port (
        Q  : out std_logic;
        C  : in  std_logic;
        CE : in  std_logic;
        D  : in  std_logic;
        S  : in  std_logic
      );
    end component FDSE;
  
    signal q_i,
           q_i_ns,
           xorcy_out,
           gen_cry_kill_n : std_logic_vector(0 to C_REG_WIDTH-1);
    signal cry : std_logic_vector(0 to C_REG_WIDTH);

begin

    -- synthesis translate_off

    assert C_LD_WIDTH + C_LD_OFFSET <= C_REG_WIDTH 
        report "ld_arith_reg2, constraint does not hold: " &
               "C_LD_WIDTH + C_LD_OFFSET <= C_REG_WIDTH"
        severity error;
    assert C_AD_WIDTH + C_AD_OFFSET <= C_REG_WIDTH 
        report "ld_arith_reg2, constraint does not hold: " &
               "C_AD_WIDTH + C_AD_OFFSET <= C_REG_WIDTH"
        severity error;

    -- synthesis translate_on

    Q <= q_i;

    cry(C_REG_WIDTH) <=
        '0'        when     C_ADD_SUB_NOT                          else
        LOAD_n     when not C_ADD_SUB_NOT and     C_LOAD_OVERRIDES else
        OP;     -- when not C_ADD_SUB_NOT and not C_LOAD_OVERRIDES

    PERBIT_GEN: for j in C_REG_WIDTH-1 downto 0 generate
        signal load_bit, arith_bit, CE : std_logic;
    begin

        ------------------------------------------------------------------------
        -- Assign to load_bit either zero or the bit from input port LD.
        ------------------------------------------------------------------------
        D_ZERO_GEN: if    j > C_REG_WIDTH - 1 - C_LD_OFFSET 
                       or j < C_REG_WIDTH - C_LD_WIDTH - C_LD_OFFSET generate
            load_bit <= '0';
        end generate;
        D_NON_ZERO_GEN: if    j <= C_REG_WIDTH - 1 - C_LD_OFFSET 
                          and j >= C_REG_WIDTH - C_LD_OFFSET - C_LD_WIDTH
        generate
            load_bit <= LD(j - (C_REG_WIDTH - C_LD_WIDTH - C_LD_OFFSET));
        end generate;

        ------------------------------------------------------------------------
        -- Assign to arith_bit either zero or the bit from input port AD.
        ------------------------------------------------------------------------
        AD_ZERO_GEN: if    j > C_REG_WIDTH - 1 - C_AD_OFFSET 
                        or j < C_REG_WIDTH - C_AD_WIDTH - C_AD_OFFSET
        generate
            arith_bit <= '0';
        end generate;
        AD_NON_ZERO_GEN: if    j <= C_REG_WIDTH - 1 - C_AD_OFFSET 
                           and j >= C_REG_WIDTH - C_AD_OFFSET - C_AD_WIDTH
        generate
            arith_bit <= AD(j - (C_REG_WIDTH - C_AD_WIDTH - C_AD_OFFSET));
        end generate;


        ------------------------------------------------------------------------
        -- LUT output generation.
        ------------------------------------------------------------------------

        ------------------------------------------------------------------------
        -- Adder case, OP overrides LOAD_n
        ------------------------------------------------------------------------
        Q_I_GEN_ADD_OO: if C_ADD_SUB_NOT and not C_LOAD_OVERRIDES generate
            q_i_ns(j) <= q_i(j) xor  arith_bit when  OP = '1' else load_bit;
        end generate;

        ------------------------------------------------------------------------
        -- Adder case, LOAD_n overrides OP
        ------------------------------------------------------------------------
        Q_I_GEN_ADD_LO: if C_ADD_SUB_NOT and     C_LOAD_OVERRIDES generate
            q_i_ns(j) <= load_bit when LOAD_n = '0' else q_i(j) xor  arith_bit;
        end generate;

        ------------------------------------------------------------------------
        -- Subtractor case, OP overrides LOAD_n
        ------------------------------------------------------------------------
        Q_I_GEN_SUB_OO: if not C_ADD_SUB_NOT and not C_LOAD_OVERRIDES generate
            q_i_ns(j) <= q_i(j) xnor arith_bit when  OP = '1' else load_bit;
        end generate;

        ------------------------------------------------------------------------
        -- Subtractor case, LOAD_n overrides OP
        ------------------------------------------------------------------------
        Q_I_GEN_SUB_LO: if not C_ADD_SUB_NOT and     C_LOAD_OVERRIDES generate
            q_i_ns(j) <= load_bit when LOAD_n = '0' else q_i(j) xnor arith_bit;
        end generate;



        ------------------------------------------------------------------------
        -- Kill carries (borrows) for loads but
        -- generate or kill carries (borrows) for add (sub).
        ------------------------------------------------------------------------
        MULT_AND_OO_GEN : if not C_LOAD_OVERRIDES generate
        MULT_AND_i1: MULT_AND
           port map (
              LO => gen_cry_kill_n(j),
              I1 => OP,
              I0 => Q_i(j)
           );
        end generate;

        MULT_AND_LO_GEN : if     C_LOAD_OVERRIDES generate
        MULT_AND_i1: MULT_AND
           port map (
              LO => gen_cry_kill_n(j),
              I1 => LOAD_n,
              I0 => Q_i(j)
           );
        end generate;

        ------------------------------------------------------------------------
        -- Propagate the carry (borrow) out.
        ------------------------------------------------------------------------
        MUXCY_i1: MUXCY
          port map (
            DI => gen_cry_kill_n(j),
            CI => cry(j+1),
            S  => q_i_ns(j),
            O  => cry(j)
          );

        ------------------------------------------------------------------------
        -- Apply the effect of carry (borrow) in.
        ------------------------------------------------------------------------
        XORCY_i1: XORCY
          port map (
            LI => q_i_ns(j),
            CI => cry(j+1),
            O  =>  xorcy_out(j)
          );


        CE <= not LOAD_n or OP;


        ------------------------------------------------------------------------
        -- Generate either a resettable or setable FF for bit j, depending
        -- on C_RESET_VALUE at bit j.
        ------------------------------------------------------------------------
        FF_RST0_GEN: if C_RESET_VALUE(j) = '0' generate
            FDRE_i1: FDRE
              port map (
                Q  => q_i(j),
                C  => CK,
                CE => CE,
                D  => xorcy_out(j),
                R  => RST
              );
        end generate;
        FF_RST1_GEN: if C_RESET_VALUE(j) = '1' generate
            FDSE_i1: FDSE
              port map (
                Q  => q_i(j),
                C  => CK,
                CE => CE,
                D  => xorcy_out(j),
                S  => RST
              );
        end generate;

      end generate;

end imp;
