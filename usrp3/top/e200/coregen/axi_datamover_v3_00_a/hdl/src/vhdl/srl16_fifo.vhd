-------------------------------------------------------------------------------
-- $Id: srl16_fifo.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- srl16_fifo.vhd
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
-- Filename:        srl16_fifo.vhd
--
-- Description:
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              srl16_fifo.vhd
--
-------------------------------------------------------------------------------
-- Author:          D.Thorpe
--
-- History:
--   DET  2001-10-11    First Version adapted from Goran B. srl_fifo.vhd
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
--      clock signals:                          "Bus_clk", "Bus_clk_div#", "Bus_clk_#x"
--      Bus_rst signals:                          "rst", "rst_n"
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
library unisim;
use unisim.vcomponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.pf_adder;
use proc_common_v3_00_a.pf_counter_top;
use proc_common_v3_00_a.pf_occ_counter_top;

library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_arith.all;

library ieee;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------

entity srl16_fifo is
  generic (
    C_FIFO_WIDTH       : integer range 1 to 128 := 8;
        -- Width of FIFO Data Bus

    C_FIFO_DEPTH_LOG2X : integer range 2 to 4 := 4;
        -- Depth of FIFO in address bit width
        -- ie 4 = 16 locations deep
        --    3 =  8 locations deep
        --    2 =  4  ocations deep

    C_INCLUDE_VACANCY : Boolean := true
        -- Command to include vacancy calculation

    );
  port (
    Bus_clk     : in  std_logic;
    Bus_rst     : in  std_logic;
    Wr_Req      : in  std_logic;
    Wr_Data     : in  std_logic_vector(0 to C_FIFO_WIDTH-1);
    Rd_Req      : in  std_logic;
    Rd_Data     : out std_logic_vector(0 to C_FIFO_WIDTH-1);
    Full        : out std_logic;
    Almostfull  : Out std_logic;
    Empty       : Out std_logic;
    Almostempty : Out std_logic;
    Occupancy   : Out std_logic_vector(0 to C_FIFO_DEPTH_LOG2X);
    Vacancy     : Out std_logic_vector(0 to C_FIFO_DEPTH_LOG2X)
    );

end entity srl16_fifo;


-------------------------------------------------------------------------------

architecture implementation of srl16_fifo is


   Signal sig_occupancy       : std_logic_vector(0 to C_FIFO_DEPTH_LOG2X);
   Signal sig_occ_load_value  : std_logic_vector(0 to C_FIFO_DEPTH_LOG2X);
   Signal sig_addr_load_value : std_logic_vector(0 to C_FIFO_DEPTH_LOG2X-1);
   Signal sig_logic_low       : std_logic;
   signal sig_almost_full     : std_logic;
   signal sig_full            : std_logic;
   signal sig_almost_empty    : std_logic;
   signal sig_empty           : std_logic;

   signal sig_valid_write     : std_logic;
   signal sig_inc_addr        : std_logic;
   signal sig_dec_addr        : std_logic;
   signal sig_valid_read      : std_logic;
   signal sig_addr            : std_logic_vector(0 to C_FIFO_DEPTH_LOG2X-1);
   signal sig_srl_addr        : std_logic_vector(0 to 3);
   signal sig_addr_is_nonzero : std_logic;
   signal sig_addr_is_zero    : std_logic;


begin  -- architecture implementation


   -- Misc I/O

   Full         <= sig_full;

   Almostfull   <= sig_almost_full;

   Empty        <= sig_empty;

   Almostempty  <= sig_almost_empty;

   Occupancy    <= sig_occupancy;



   ----------------------------------------------------------------------------
   -- Occupancy Counter Function
   ----------------------------------------------------------------------------
    sig_occ_load_value <= (others => '0');
    sig_logic_low      <= '0';


   I_OCCUPANCY_CNTR : entity proc_common_v3_00_a.pf_occ_counter_top
    generic map(
      C_COUNT_WIDTH => C_FIFO_DEPTH_LOG2X+1
      )
    port map(
      Clk           =>  Bus_clk,
      Rst           =>  Bus_rst,
      Load_Enable   =>  sig_logic_low,
      Load_value    =>  sig_occ_load_value,
      Count_Down    =>  sig_valid_read,
      Count_Up      =>  sig_valid_write,
      By_2          =>  sig_logic_low,
      Count_Out     =>  sig_occupancy,
      almost_full   =>  sig_almost_full,
      full          =>  sig_full,
      almost_empty  =>  sig_almost_empty,
      empty         =>  sig_empty
     );


   ----------------------------------------------------------------------------
   -- Address Counter Function
   ----------------------------------------------------------------------------
    sig_addr_load_value <= (others => '0');

    sig_addr_is_nonzero <=   (sig_srl_addr(0)
                           or sig_srl_addr(1)
                           or sig_srl_addr(2)
                           or sig_srl_addr(3));

    sig_addr_is_zero    <= not(sig_addr_is_nonzero);


    sig_valid_write <= Wr_Req and not(sig_full);

    sig_valid_read  <= Rd_Req and not(sig_empty);

    sig_inc_addr    <= (sig_valid_write and not(sig_empty))
                       and not(sig_valid_read and sig_addr_is_zero);

    sig_dec_addr    <= sig_valid_read and sig_addr_is_nonzero;


  I_ADDR_CNTR : entity proc_common_v3_00_a.pf_counter_top
     generic map(
       C_COUNT_WIDTH => C_FIFO_DEPTH_LOG2X
       )
     port map(
       Clk           =>  Bus_clk,
       Rst           =>  Bus_rst,
       Load_Enable   =>  sig_logic_low,
       Load_value    =>  sig_addr_load_value,
       Count_Down    =>  sig_dec_addr,
       Count_Up      =>  sig_inc_addr,
       Count_Out     =>  sig_addr
       );



   ASSIGN_ADDRESS : process(sig_addr)
    Begin

       sig_srl_addr <= (others => '0'); -- assign default values

       for i in 0 to C_FIFO_DEPTH_LOG2X-1 loop
                  sig_srl_addr((4-C_FIFO_DEPTH_LOG2X)+i) <= sig_addr(i);
           end loop;
        end process ASSIGN_ADDRESS;




   ----------------------------------------------------------------------------
   -- SRL memory function
   ----------------------------------------------------------------------------
   FIFO_RAM : for i in 0 to C_FIFO_WIDTH-1 generate

    I_SRL16E : SRL16E
      -- pragma translate_off
      generic map (
        INIT => x"0000")
      -- pragma translate_on
      port map (
        CE  => sig_valid_write,
        D   => Wr_Data(i),
        Clk => Bus_clk,
        A0  => sig_srl_addr(3),
        A1  => sig_srl_addr(2),
        A2  => sig_srl_addr(1),
        A3  => sig_srl_addr(0),
        Q   => Rd_Data(i)
        );

  end generate FIFO_RAM;




   INCLUDE_VACANCY : if (C_INCLUDE_VACANCY = true) generate

       Constant  REGISTER_VACANCY  : boolean   := false;
       Constant  OCC_CNTR_WIDTH    : integer   := C_FIFO_DEPTH_LOG2X+1;
       Constant  MAX_OCCUPANCY     : integer   := 2**C_FIFO_DEPTH_LOG2X;


       Signal  slv_max_vacancy  : std_logic_vector(0 to OCC_CNTR_WIDTH-1);
       Signal  int_vacancy      : std_logic_vector(0 to OCC_CNTR_WIDTH-1);



   begin

       Vacancy         <=  int_vacancy; -- set to zeroes for now.


       slv_max_vacancy <= CONV_STD_LOGIC_VECTOR(MAX_OCCUPANCY, OCC_CNTR_WIDTH);

       I_VAC_CALC : entity proc_common_v3_00_a.pf_adder
       generic map(
         C_REGISTERED_RESULT => REGISTER_VACANCY,
         C_COUNT_WIDTH       => OCC_CNTR_WIDTH
         )
       port map (
         Clk           =>  Bus_Clk,
         Rst           =>  Bus_rst,
         Ain           =>  slv_max_vacancy,
         Bin           =>  sig_occupancy,
         Add_sub_n     =>  '0', -- always subtract
         result_out    =>  int_vacancy
         );


   end generate; -- INCLUDE_VACANCY





   OMIT_VACANCY : if (C_INCLUDE_VACANCY = false) generate


       Signal int_vacancy : std_logic_vector(0 to C_FIFO_DEPTH_LOG2X);

   begin

       int_vacancy <= (others => '0');

       Vacancy     <=  int_vacancy; -- set to zeroes for now.

   end generate; -- INCLUDE_VACANCY







end architecture implementation;



