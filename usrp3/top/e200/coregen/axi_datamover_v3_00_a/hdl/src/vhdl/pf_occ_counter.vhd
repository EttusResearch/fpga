-------------------------------------------------------------------------------
-- $Id: pf_occ_counter.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- pf_occ_counter - entity/architecture pair
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
-- Filename:        pf_occ_counter.vhd
--
-- Description:     Implements packet fifo occupancy counter. This special
--                  counter provides these functions:
--                      - up/down count control
--                      - pre-increment/pre-decrement of input load value
--                      - count by 2
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  pf_occ_counter.vhd
--
-------------------------------------------------------------------------------
-- Author:          B.L. Tise
-- Revision:        $Revision: 1.1.4.1 $
-- Date:            $Date: 2010/09/14 22:35:47 $
--
-- History:
--   D. Thorpe      2001-09-07    First Version
--                  - adapted from B Tise MicroBlaze counters
--
--   DET            2001-09-11
--                  - Added the Rst signal connect to the pf_counter_bit module
--
--   DET            2002-02-24
--                  - Changed the use of MUXCY_L to MUXCY.
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
use proc_common_v3_00_a.pf_counter_bit;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity pf_occ_counter is
  generic (
    C_COUNT_WIDTH : integer := 9
    );
  port (
    Clk           : in  std_logic;
    Rst           : in  std_logic;
    Carry_Out     : out std_logic;
    Load_In       : in  std_logic_vector(0 to C_COUNT_WIDTH-1);
    Count_Enable  : in  std_logic;
    Count_Load    : in  std_logic;
    Count_Down    : in  std_logic;
    Cnt_by_2      : In  std_logic;
    Count_Out     : out std_logic_vector(0 to C_COUNT_WIDTH-1)
    );
end entity pf_occ_counter;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture implementation of pf_occ_counter is

  component MUXCY is
    port (
      DI : in  std_logic;
      CI : in  std_logic;
      S  : in  std_logic;
      O  : out std_logic);
  end component MUXCY;


  constant CY_START : integer := 1;


  signal alu_cy             : std_logic_vector(0 to C_COUNT_WIDTH-1);
  signal iCount_Out         : std_logic_vector(0 to C_COUNT_WIDTH-2);
  signal i_mux_Count_Out    : std_logic_vector(0 to C_COUNT_WIDTH-2);
  signal count_clock_en     : std_logic;
  signal carry_out_lsb      : std_logic;
  signal carry_in_lsb       : std_logic;
  signal count_out_lsb      : std_logic;
  Signal mux_cnt_in_lsb     : std_logic;
  Signal carry_out_select_di: std_logic;
  Signal carry_start        : std_logic;
  Signal carry_start_select : std_logic;
  Signal by_2_carry_start   : std_logic;



begin  -- VHDL_RTL

  -----------------------------------------------------------------------------
  -- Generate the Counter bits
  -----------------------------------------------------------------------------

  count_clock_en <= Count_Enable or Count_Load;



    MUX_THE_LSB_INPUT : process (count_out_lsb, Load_In, Count_Load)
      Begin

         If (Count_Load = '0') Then
            mux_cnt_in_lsb <= count_out_lsb;
         else
            mux_cnt_in_lsb <= Load_In(C_COUNT_WIDTH-1);
         End if;

      End process MUX_THE_LSB_INPUT;




  carry_start        <= Count_Down xor Count_Enable;

  by_2_carry_start   <= Cnt_by_2 and  Count_Down;

  carry_start_select <= not(Cnt_by_2);


  I_MUXCY_LSB_IN : MUXCY
    port map (
      DI => by_2_carry_start,
      CI => carry_start,
      S  => carry_start_select,
      O  => carry_in_lsb);




  I_COUNTER_BIT_LSB : entity proc_common_v3_00_a.pf_counter_bit
    port map (
      Clk           => Clk,
      Rst           => Rst,
      Count_In      => mux_cnt_in_lsb,
      Load_In       => '0',
      Count_Load    => '0',
      Count_Down    => Count_Down,
      Carry_In      => carry_in_lsb,
      Clock_Enable  => count_clock_en,
      Result        => count_out_lsb,
      Carry_Out     => carry_out_lsb);




  carry_out_select_di <=  Count_Down xor Cnt_by_2;

  I_MUXCY_LSB_OUT : MUXCY
    port map (
      DI => carry_out_select_di,
      CI => carry_out_lsb,
      S  => carry_start_select,
      O  => alu_cy(C_COUNT_WIDTH-1));





  I_ADDSUB_GEN : for i in 0 to C_COUNT_WIDTH-2 generate

  begin



    MUX_THE_INPUT : process (iCount_Out, Load_In, Count_Load)
      Begin

         If (Count_Load = '0') Then
            i_mux_Count_Out(i) <= iCount_Out(i);
         else
            i_mux_Count_Out(i) <= Load_In(i);
         End if;

      End process MUX_THE_INPUT;




    Counter_Bit_I : entity proc_common_v3_00_a.pf_counter_bit
      port map (
        Clk           => Clk,
        Rst           => Rst,
        Count_In      => i_mux_Count_Out(i),
        Load_In       => '0',
        Count_Load    => '0',
        Count_Down    => Count_Down,
        Carry_In      => alu_cy(i+1),
        Clock_Enable  => count_clock_en,
        Result        => iCount_Out(i),
        Carry_Out     => alu_cy(i));


  end generate I_ADDSUB_GEN;





   Count_Out <= iCount_Out & count_out_lsb;

   Carry_Out <= '0';




end architecture implementation;

