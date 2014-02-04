-------------------------------------------------------------------------------
-- $Id: pselect_mask.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- pselect_mask.vhd
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
-- ** Copyright (c) 2002-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        pselect_mask.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              pselect_mask.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.1.4.1 $
-- Date:            $Date: 2010/09/14 22:35:47 $
--
-- History:
--   goran  2002-02-06    First Version
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library Unisim;
use Unisim.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_AB            -- number of address bits to decode
--          C_AW            -- width of address bus
--          C_BAR           -- base address of peripheral (peripheral select
--                             is asserted when the C_AB most significant
--                             address bits match the C_AB most significant
--                             C_BAR bits
-- Definition of Ports:
--          A               -- address input
--          AValid          -- address qualifier
--          PS              -- peripheral select
-------------------------------------------------------------------------------

entity pselect_mask is

  generic (
    C_AW   : integer                   := 32;
    C_BAR  : std_logic_vector(0 to 31) := "00000000000000100000000000000000";
    C_MASK : std_logic_vector(0 to 31) := "00000000000001111100000000000000"
    );
  port (
    A     : in  std_logic_vector(0 to C_AW-1);
    Valid : in  std_logic;
    CS    : out std_logic
    );

end entity pselect_mask;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

library unisim;
use unisim.all;

architecture imp of pselect_mask is

--  component LUT4
--    generic(
--      INIT : bit_vector := X"0000"
--      );
--    port (
--      O  : out std_logic;
--      I0 : in  std_logic := '0';
--      I1 : in  std_logic := '0';
--      I2 : in  std_logic := '0';
--      I3 : in  std_logic := '0');
--  end component;

--  component MUXCY is
--    port (
--      O  : out std_logic;
--      CI : in  std_logic;
--      DI : in  std_logic;
--      S  : in  std_logic
--      );
--  end component MUXCY;

  function Nr_Of_Ones (S : std_logic_vector) return natural is
    variable tmp : natural := 0;
  begin  -- function Nr_Of_Ones
    for I in S'range loop
      if (S(I) = '1') then
        tmp := tmp + 1;
      end if;
    end loop;  -- I
    return tmp;
  end function Nr_Of_Ones;

  function fix_AB (B : boolean; I : integer) return integer is
  begin  -- function fix_AB
    if (not B) then
      return I + 1;
    else
      return I;
    end if;
  end function fix_AB;

  constant Nr      : integer := Nr_Of_Ones(C_MASK);
  constant Use_CIN : boolean := ((Nr mod 4) = 0);
  constant AB      : integer := fix_AB(Use_CIN, Nr);
  
  attribute INIT : string;

  constant NUM_LUTS    : integer := (AB-1)/4+1;
--   signal   lut_out     : std_logic_vector(0 to NUM_LUTS-1);
--   signal   carry_chain : std_logic_vector(0 to NUM_LUTS);

  -- function to initialize LUT within pselect 
  type int4 is array (3 downto 0) of integer;
  function pselect_init_lut(i        : integer;
                            AB       : integer;
                            NUM_LUTS : integer;
                            C_AW     : integer;
                            C_BAR    : std_logic_vector(0 to 31)) 
    return bit_vector is
    variable init_vector : bit_vector(15 downto 0) := X"0001";
    variable j           : integer                 := 0;
    variable val_in      : int4;
  begin
    for j in 0 to 3 loop
      if i < NUM_LUTS-1 or j <= ((AB-1) mod 4) then
        val_in(j) := conv_integer(C_BAR(i*4+j));
      else val_in(j) := 0;
      end if;
    end loop;
    init_vector := To_bitvector(conv_std_logic_vector(2**(val_in(3)*8+
                                                          val_in(2)*4+val_in(1)*2+val_in(0)*1),16));
    return init_vector;
  end pselect_init_lut;

  signal A_Bus : std_logic_vector(0 to AB);
  signal BAR   : std_logic_vector(0 to AB);

-------------------------------------------------------------------------------
-- Begin architecture section
-------------------------------------------------------------------------------
begin  -- VHDL_RTL

  Make_Busses : process (A,Valid) is
    variable tmp : natural;
  begin  -- process Make_Busses
    tmp   := 0;
    A_Bus <= (others => '0');
    BAR   <= (others => '0');
    for I in C_MASK'range loop
      if (C_MASK(I) = '1') then
        A_Bus(tmp) <= A(I);
        BAR(tmp)   <= C_BAR(I);
        tmp        := tmp + 1;
      end if;
    end loop;  -- I
    if (not Use_CIN) then
      BAR(tmp) <= '1';
      A_Bus(tmp) <= Valid;
    end if;
  end process Make_Busses;


--  More_Than_3_Bits : if (AB > 3) generate

--    Using_CIn: if (Use_CIN) generate
--      carry_chain(0) <= Valid;      
--    end generate Using_CIn;

--    No_CIn: if (not Use_CIN) generate
--      carry_chain(0) <= '1';
--    end generate No_CIn;

--    GEN_DECODE : for i in 0 to NUM_LUTS-1 generate
--      signal lut_in : std_logic_vector(3 downto 0);
--    begin
--      GEN_LUT_INPUTS : for j in 0 to 3 generate
--        -- Generate to assign address bits to LUT4 inputs
--        GEN_INPUT : if i < NUM_LUTS-1 or j <= ((AB-1) mod 4) generate
--          lut_in(j) <= A_Bus(i*4+j);
--        end generate;
--        -- Generate to assign zeros to remaining LUT4 inputs
--        GEN_ZEROS : if not(i < NUM_LUTS-1 or j <= ((AB-1) mod 4)) generate
--          lut_in(j) <= '0';
--        end generate;
--      end generate;

---------------------------------------------------------------------------------
---- RTL version without LUT instantiation for XST
---------------------------------------------------------------------------------

--      lut_out(i) <= (lut_in(0) xnor BAR(i*4+0)) and
--                     (lut_in(1) xnor BAR(i*4+1)) and
--                     (lut_in(2) xnor BAR(i*4+2)) and
--                     (lut_in(3) xnor BAR(i*4+3));

---------------------------------------------------------------------------------
---- Structural version with LUT instantiation for Synplicity (when RLOC is
----  desired for placing LUT
---------------------------------------------------------------------------------

----    LUT4_I : LUT4
----      generic map(
----        -- Function init_lut is used to generate INIT value for LUT4
----        INIT => pselect_init_lut(i,C_AB,NUM_LUTS,C_AW,C_BAR)
----        )
----      port map (
----        O  => lut_out(i),  -- [out]
----        I0 => lut_in(0),   -- [in]
----        I1 => lut_in(1),   -- [in]
----        I2 => lut_in(2),   -- [in]
----        I3 => lut_in(3));  -- [in]

---------------------------------------------------------------------------------

--      MUXCY_I : MUXCY
--        port map (
--          O  => carry_chain(i+1),       --[out]
--          CI => carry_chain(i),         --[in]
--          DI => '0',                    --[in]
--          S  => lut_out(i)              --[in]
--          );    
--    end generate;
--    CS <= carry_chain(NUM_LUTS);        -- assign end of carry chain to output
--  end generate More_Than_3_Bits;

--  Less_than_4_bits: if (AB < 4) generate
    CS <= Valid when A_Bus=BAR else '0';
--  end generate Less_than_4_bits;
end imp;

