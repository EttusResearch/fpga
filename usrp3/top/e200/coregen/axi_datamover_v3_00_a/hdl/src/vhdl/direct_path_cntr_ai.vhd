
--ENTITY_TAG
-------------------------------------------------------------------------------
-- $Id: direct_path_cntr_ai.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
--  direct_path_cntr_ai.vhd - entity/arch
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
-- Filename:        direct_path_cntr_ai.vhd
--
-- Description:     Direct-path counter with arbitrary increment.
--
--                  This is an up counter with a combinatorial direct pass-
--                  through mode. The passed-through value also serves as
--                  the initial "loaded" value when the counter switches to
--                  count mode. In pass-though mode, Dout <= Din.
--
--                  The mode is controlled by two signals, Load_n and Cnt_en.
--                  The counter is in direct pass-through mode any time Load_n
--                  is true (low) and up to the first cycle where Cnt_en is
--                  true after Load_n goes false. When Load_n = '1' (load
--                  disabled) Dout increments by Delta each time Cnt_en is
--                  true at the positive edge of Clk.
--
--                  The implementation has a one-LUT delay from Din to Dout
--                  (via the XORCY) in direct pass-through mode and the same
--                  delay plus carry-chain propogation in count mode. There
--                  is an additional LUT delay (added to the Din to Dout
--                  delay) from the Load_n input or from the clock edge that
--                  puts the counter into count mode.
------------------------------------------------------------------------------- 
-- Structure:   direct_path_cntr_ai.vhd
-------------------------------------------------------------------------------
-- Author:      FLO
-- History:
--  FLO             12/02/2003  -- First version derived from
--                                 direct_path_cntr.vhd
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

entity direct_path_cntr_ai is
    generic (
        C_WIDTH   : natural := 8
    );
    port (
        Clk      : in  std_logic;
        Din      : in  std_logic_vector(0 to C_WIDTH-1);
        Dout     : out std_logic_vector(0 to C_WIDTH-1);
        Load_n   : in  std_logic;
        Cnt_en   : in  std_logic;
        Delta    : in  std_logic_vector(0 to C_WIDTH-1)
    );
end direct_path_cntr_ai;
  

library unisim;
use unisim.vcomponents.all;

architecture imp of direct_path_cntr_ai is

    signal q_i,
           lut_out,
           q_i_ns : std_logic_vector(0 to C_WIDTH-1);
    signal cry : std_logic_vector(0 to C_WIDTH);
    signal sel_cntr : std_logic;

    signal sel_cntr_and_Load_n : std_logic; -- AND of sel_cntr and Load_n

    signal mdelta : std_logic_vector(0 to Delta'length-1); -- "My delta"
           -- Delta, adjusted to assure ascending range referenced from zero.
    
begin

    mdelta <= Delta;

    ----------------------------------------------------------------------------
    -- Load_n takes effect combinatorially, causing Dout to be directly driven
    -- from Din when Load_n is asserted. When Load_n is not asserted, then the
    -- first clocking of asserted Cnt_en switches modes so that Dout is driven
    -- by the register value plus one. The value of Dout is clocked into the
    -- register with each Cnt_en, thus realizing the counting behavior.
    -- The combinatorial override of Load_n takes place in the LUT and covers
    -- the cycle that it takes for the mode to recover (since the mode FF has a
    -- synchronous reset). Use of an asynchronous reset is rejected as an
    -- option to avoid the requirement that Load_n be generated glitch free.
    ----------------------------------------------------------------------------

    I_MODE_SELECTION : process(Clk)
    begin
        if Clk'event and Clk='1' then
            if Load_n = '0' then
                sel_cntr <= '0';
            elsif Cnt_en = '1' then
                sel_cntr <= '1';
            end if;
        end if;
    end process;

    sel_cntr_and_Load_n <= sel_cntr and Load_n;


    Dout <= q_i_ns;

    cry(C_WIDTH) <= '0';


    PERBIT_GEN: for j in C_WIDTH-1 downto 0 generate
    begin

        ------------------------------------------------------------------------
        -- LUT output generation and MUXCY carry handling.
        ------------------------------------------------------------------------
        DELTA_LUT_GEN:      if j >= C_WIDTH-mdelta'length generate
            signal gen_cry: std_logic;
        begin

          lut_out(j) <= q_i(j) xor mdelta(mdelta'length + j - C_WIDTH)
                            when (sel_cntr_and_Load_n)='1'
                            else
                        Din(j);

          I_MULT_AND : MULT_AND
            port map (
            LO => gen_cry,
            I1 => sel_cntr_and_Load_n,
            I0 => q_i(j)
            );
  
          MUXCY_i1: MUXCY
            port map (
              DI => gen_cry,
              CI => cry(j+1),
              S  => lut_out(j),
              O  => cry(j)
            );
        end generate;
        --
        --
        NON_DELTA_LUT_GEN : if j <  C_WIDTH-mdelta'length generate
        begin
          lut_out(j) <= q_i(j) when (sel_cntr_and_Load_n)='1' else Din(j);

          MUXCY_i1: MUXCY
            port map (
              DI => '0',
              CI => cry(j+1),
              S  => lut_out(j),
              O  => cry(j)
            );
        end generate;

        ------------------------------------------------------------------------
        -- Apply the effect of carry in.
        ------------------------------------------------------------------------
        XORCY_i1: XORCY
          port map (
            LI => lut_out(j),
            CI => cry(j+1),
            O  =>  q_i_ns(j)
          );

        FDE_i1: FDE
          port map (
            Q  => q_i(j),
            C  => Clk,
            CE => Cnt_en,
            D  => q_i_ns(j)
          );

      end generate;

end imp;
