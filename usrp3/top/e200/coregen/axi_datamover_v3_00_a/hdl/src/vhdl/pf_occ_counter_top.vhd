-------------------------------------------------------------------------------
-- $Id: pf_occ_counter_top.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- pf_occ_counter_top - entity/architecture pair
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
-- Filename:        pf_occ_counter_top.vhd
--
-- Description:     Implements parameterized up/down counter
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  pf_occ_counter_top.vhd
--
-------------------------------------------------------------------------------
-- Author:          D. Thorpe
-- Revision:        $Revision: 1.1.4.1 $
-- Date:            $Date: 2010/09/14 22:35:47 $
--
-- History:
--   DET            2001-08-30    First Version
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Changed proc_common library version to v3_00_a
--     - Incorporated new disclaimer header
-- ^^^^^^
--

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
--Use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;
library proc_common_v3_00_a;
use proc_common_v3_00_a.pf_occ_counter;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity pf_occ_counter_top is
  generic (
    C_COUNT_WIDTH : integer := 10
    );
  port (
    Clk           : in  std_logic;
    Rst           : in  std_logic;
    Load_Enable   : in  std_logic;
    Load_value    : in  std_logic_vector(0 to C_COUNT_WIDTH-1);
    Count_Down    : in  std_logic;
    Count_Up      : in  std_logic;
    By_2          : In  std_logic;
    Count_Out     : out std_logic_vector(0 to C_COUNT_WIDTH-1);
    almost_full   : Out std_logic;
    full          : Out std_logic;
    almost_empty  : Out std_logic;
    empty         : Out std_logic
   );
end entity pf_occ_counter_top;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture implementation of pf_occ_counter_top is


    Signal  sig_cnt_enable   : std_logic;
    Signal  sig_cnt_up_n_dwn : std_logic;
    Signal  sig_carry_out    : std_logic;
    Signal  sig_count_out    : std_logic_vector(0 to C_COUNT_WIDTH-1);
    Signal  upper_cleared    : std_logic;
    Signal  lower_set        : std_logic;
    Signal  lower_cleared    : std_logic;
    Signal  empty_state      : std_logic_vector(0 to 2);
    Signal  full_state       : std_logic_vector(0 to 3);

    Signal  sig_full         : std_logic;
    Signal  sig_almost_full  : std_logic;
    Signal  sig_going_full   : std_logic;
    Signal  sig_empty        : std_logic;
    Signal  sig_almost_empty : std_logic;




begin  -- VHDL_RTL


 full          <= sig_full;
 almost_full   <= sig_almost_full;
 empty         <= sig_empty;
 almost_empty  <= sig_almost_empty;



 -- Misc signal assignments
  Count_Out        <= sig_count_out;

  sig_cnt_enable   <=     (Count_Up and not(sig_full))
                      xor (Count_Down and not(sig_empty));

  sig_cnt_up_n_dwn <=  not(Count_Up);



  I_UP_DWN_COUNTER : entity proc_common_v3_00_a.pf_occ_counter

    generic map (
      C_COUNT_WIDTH
      )
    port map(
      Clk           =>  Clk,
      Rst           =>  Rst,
      Carry_Out     =>  sig_carry_out,
      Load_In       =>  Load_value,
      Count_Enable  =>  sig_cnt_enable,
      Count_Load    =>  Load_Enable,
      Count_Down    =>  sig_cnt_up_n_dwn,
      Cnt_by_2      =>  By_2,
      Count_Out     =>  sig_count_out
      );







  TEST_UPPER_BITS : process (sig_count_out)

    Variable all_cleared : boolean;
    Variable loop_count  : integer;

    Begin

        --loop_count    := 0;

       all_cleared   := True;

       for loop_count in 0 to C_COUNT_WIDTH-2 loop

         If (sig_count_out(loop_count) = '1') Then
            all_cleared       := False;
         else
            null;
         End if;

       End loop;





       -- -- Search through the upper counter bits starting with the MSB
       --  while (loop_count < C_COUNT_WIDTH-2) loop
       --
       --     If (sig_count_out(loop_count) = '1') Then
       --        all_cleared       := False;
       --     else
       --        null;
       --     End if;
       --
       --     loop_count := loop_count + 1;
       --
       --  End loop;



       -- now assign the outputs
        If (all_cleared) then
           upper_cleared <= '1';

        else
           upper_cleared <= '0';
       End if;


    End process TEST_UPPER_BITS;




    empty_state <= upper_cleared & sig_count_out(C_COUNT_WIDTH-2) &
                   sig_count_out(C_COUNT_WIDTH-1);



     STATIC_EMPTY_DETECT : process (empty_state)
        Begin
          Case empty_state Is
             When "100" =>
               sig_empty        <= '1';
               sig_almost_empty <= '0';
             When "101" =>
               sig_empty        <= '0';
               sig_almost_empty <= '1';

             When "110" =>
               sig_empty        <= '0';
               sig_almost_empty <= '0';

             When others   =>
               sig_empty        <= '0';
               sig_almost_empty <= '0';

             End case;
        End process STATIC_EMPTY_DETECT;





  TEST_LOWER_BITS : process (sig_count_out)

    Variable all_cleared : boolean;
    Variable all_set     : boolean;
    Variable loop_count  : integer;

    Begin

        --loop_count    := 1;
        all_set       := True;
        all_cleared   := True;

        for loop_count in 1 to C_COUNT_WIDTH-1 loop

           If (sig_count_out(loop_count) = '0') Then
              all_set       := False;
           else
              all_cleared   := False;
           End if;

        End loop;



       -- -- Search through the lower counter bits starting with the MSB+1
       --  while (loop_count < C_COUNT_WIDTH-1) loop
       --
       --     If (sig_count_out(loop_count) = '0') Then
       --        all_set       := False;
       --     else
       --        all_cleared   := False;
       --     End if;
       --
       --     loop_count := loop_count + 1;
       --
       --  End loop;

       -- now assign the outputs
        If (all_cleared) then
           lower_cleared <= '1';
           lower_set     <= '0';

        elsif (all_set) Then
           lower_cleared <= '0';
           lower_set     <= '1';

        else
           lower_cleared <= '0';
           lower_set     <= '0';
        End if;


    End process TEST_LOWER_BITS;




    full_state <=   sig_count_out(0)
                  & lower_set
                  & lower_cleared
                  & sig_count_out(C_COUNT_WIDTH-1);



     STATIC_FULL_DETECT : process (full_state, sig_count_out)
        Begin

          sig_full <= sig_count_out(0); -- MSB set implies full


          Case full_state Is

             When "0100" =>
               sig_almost_full <= '0';
               sig_going_full  <= '1';

             When "0101" =>
               sig_almost_full <= '1';
               sig_going_full  <= '0';

             When others   =>
               sig_almost_full <= '0';
               sig_going_full  <= '0';

             End case;
        End process STATIC_FULL_DETECT;





end architecture implementation;



