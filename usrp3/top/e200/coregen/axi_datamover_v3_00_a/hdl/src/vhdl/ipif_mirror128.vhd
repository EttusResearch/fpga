--SINGLE_FILE_TAG
-------------------------------------------------------------------------------
-- $Id: ipif_mirror128.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- ipif_mirror128 - entity/architecture pair
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
-- Filename:        ipif_steer128.vhd
-- Version:         v1.00b
-- Description:     Read and Write Steering logic for IPIF
--
--                  For writes, this logic mirrors data from the master with 
--                  the smaller bus width to the correct byte lanes of the
--                  larger IPIF devices.  The BE signals are also mirrored.
--
--                  For reads, the Decode_size signal determines how read
--                  data is steered onto the byte lanes. To simplify the 
--                  logic, the read data is mirrored onto the entire data
--                  bus, insuring that the lanes corrsponding to the BE's
--                  have correct data.
-- 
--                  
--
-------------------------------------------------------------------------------
-- Structure: 
--
--              ipif_steer128.vhd
--
-------------------------------------------------------------------------------
-- Author:      Gary Burch
-- History:
--  GAB             10-10-2008      -- First version
-- ^^^^^^
--      First version of IPIF mirror logic.
-- ~~~~~~
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

library IEEE;
use IEEE.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Port declarations
--   generic definitions:
--     C_DWIDTH    : integer := width of IPIF Slave
--     C_SMALLEST  : integer := width of smallest Master (not access size)
--                              that will access the IPIF Slave
--     C_AWIDTH    : integer := width of the host address bus attached to
--                              the IPIF
--   port definitions:
--     Wr_Data_In         : in  Write Data In (from host data bus)
--     Rd_Data_In         : in  Read Data In (from IPIC data bus)
--     Addr               : in  Address bus from host address bus
--     BE_In              : in  Byte Enables In from host side
--     Decode_size        : in  Size of Master accessing slave
--                                Size indication (Decode_size)
--                                  00 - 32-Bit Master           
--                                  01 - 64-Bit Master
--                                  10 - 128-Bit Master  
--                                  11 - 256-Bit Master (Not Support)
--
--     Wr_Data_Out        : out Write Data Out (to IPIF data bus)
--     Rd_Data_Out        : out Read Data Out (to host data bus)
--     BE_Out             : out Byte Enables Out to IPIF side
-- 
-------------------------------------------------------------------------------

entity ipif_mirror128 is
  generic (
    C_DWIDTH    : integer := 32;    -- 64, 128 (Slave Dwidth)
    C_SMALLEST  : integer := 32;    -- 32, 64, 128 (Smallest Master)
    C_AWIDTH    : integer := 32
    );   
  port (
    Wr_Addr            : in  std_logic_vector(0 to C_AWIDTH-1);
    Wr_Size            : in  std_logic_vector(0 to 1);

    Rd_Addr            : in  std_logic_vector(0 to C_AWIDTH-1);
    Rd_Size            : in  std_logic_vector(0 to 1);



    Wr_Data_In         : in  std_logic_vector(0 to C_DWIDTH-1);
    Rd_Data_In         : in  std_logic_vector(0 to C_DWIDTH-1);
    BE_In              : in  std_logic_vector(0 to C_DWIDTH/8-1);
    Wr_Data_Out        : out std_logic_vector(0 to C_DWIDTH-1);
    Rd_Data_Out        : out std_logic_vector(0 to C_DWIDTH-1);
    BE_Out             : out std_logic_vector(0 to C_DWIDTH/8-1)
    );
end entity ipif_mirror128;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of ipif_mirror128 is

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin -- architecture IMP
    
  GEN_SAME: if C_DWIDTH <= C_SMALLEST generate
      Wr_Data_Out <= Wr_Data_In;
      BE_Out      <= BE_In;
      Rd_Data_Out <= Rd_Data_In;
  end generate GEN_SAME;
  
-------------------------------------------------------------------------------
-- Write Data Mirroring
-------------------------------------------------------------------------------
  
---------------------
-- 64 Bit Support --
---------------------

  GEN_WR_64_32: if C_DWIDTH = 64 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Wr_Addr,Wr_Data_In,BE_In,Wr_Size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
 
       addr_bits <= Wr_Addr(C_AWIDTH-3);   --a29
        case addr_bits is

         when '0' => 
           case Wr_Size is
             when "00" =>  -- 32-Bit Master 
                BE_Out(4 to 7)  <= (others => '0');
             when others => null;
           end case;
             
         when '1' => 
           case Wr_Size is
             when "00" =>  -- 32-Bit Master 
               Wr_Data_Out(32 to 63)  <= Wr_Data_In(0 to 31);
               BE_Out(4 to 7) <= BE_In(0 to 3);
               BE_Out(0 to 3) <= (others => '0');
             when others => null;
           end case;
        when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_WR_64_32;

---------------------
-- 128 Bit Support --
---------------------
  GEN_WR_128_32: if C_DWIDTH = 128 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Wr_Addr,Wr_Data_In,BE_In,Wr_Size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
 
       addr_bits <= Wr_Addr(C_AWIDTH-4 to C_AWIDTH-3);   
        case addr_bits is
         when "00" => --0
           case Wr_Size is
             when "00" => -- 32-Bit Master
               BE_Out(4 to 15)  <= (others => '0');
             when "01" => -- 64-Bit Master
               BE_Out(8 to 15)  <= (others => '0');
             when others => null;
           end case;

         when "01" => --4
           case Wr_Size is
             when "00" => -- 32-Bit Master
               Wr_Data_Out(32 to 63)  <= Wr_Data_In(0 to 31);
               BE_Out(4 to 7)   <= BE_In(0 to 3);
               BE_Out(0 to 3)   <= (others => '0');
               BE_Out(8 to 15)  <= (others => '0');
             when others => null;
           end case;
         when "10" => --8
           case Wr_Size is
             when "00" => --  32-Bit Master
               Wr_Data_Out(64 to 95)  <= Wr_Data_In(0 to 31);
               BE_Out(8 to 11)  <= BE_In(0 to 3);
               BE_Out(0 to 7)   <= (others => '0');
               BE_Out(12 to 15) <= (others => '0');
             when "01" => --  64-Bit Master
               Wr_Data_Out(64 to 127)  <= Wr_Data_In(0 to 63);
               BE_Out(8 to 15) <= BE_In(0 to 7);
               BE_Out(0 to 7)  <= (others => '0');
             when others => null;
           end case;
         when "11" => --C
           case Wr_Size is
             when "00" => --32-Bit Master
               Wr_Data_Out(96 to 127)  <= Wr_Data_In(0 to 31);
               BE_Out(12 to 15) <= BE_In(0 to 3);
               BE_Out(0 to 11)  <= (others => '0');
             when "01" => --64-Bit Master
               Wr_Data_Out(64 to 127)   <= Wr_Data_In(0 to 63);
               BE_Out(8 to 15) <= BE_In(0 to 7);
               BE_Out(0 to 7) <= (others => '0');
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_WR_128_32;

  GEN_WR_128_64: if C_DWIDTH = 128 and C_SMALLEST = 64 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Wr_Addr,Wr_Data_In,BE_In,Wr_Size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
       addr_bits <= Wr_Addr(C_AWIDTH-4);   
        case addr_bits is
          when '0' =>
           case Wr_Size is
             when "01" => -- 64-Bit Master
               BE_Out(8 to 15)  <= (others => '0');
             when others => null;
           end case;

         when '1' => --8
           case Wr_Size is
             when "01" => -- 64-Bit Master
               Wr_Data_Out(64 to 127)  <= Wr_Data_In(0 to 63);
               BE_Out(8 to 15)  <= BE_In(0 to 7);
               BE_Out(0 to 7)   <= (others => '0');
             when others => null;
           end case;
          when others =>
            null;
      end case;      
    end process CONNECT_PROC;
   end generate GEN_WR_128_64;





-------------------------------------------------------------------------------
-- Read Data Steering
-------------------------------------------------------------------------------

---------------------
-- 64 Bit Support --
---------------------

  GEN_RD_64_32: if C_DWIDTH = 64 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Rd_Addr,Rd_Data_In,Rd_Size) 
     begin
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Rd_Addr(C_AWIDTH-3);   --a29
        case addr_bits is
         when '1' => 
           case Rd_Size is
             when "00" =>  -- 32-Bit Master 
               Rd_Data_Out(0 to 31) <= Rd_Data_In(32 to 63);
             when others => null;
           end case;
        when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_RD_64_32;

---------------------
-- 128 Bit Support --
---------------------
  GEN_RD_128_32: if C_DWIDTH = 128 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Rd_Addr,Rd_Data_In,Rd_Size) 
     begin
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Rd_Addr(C_AWIDTH-4 to C_AWIDTH-3);   
        case addr_bits is
         when "01" => --4
           case Rd_Size is
             when "00" => -- 32-Bit Master
               Rd_Data_Out(0 to 31) <= Rd_Data_In(32 to 63);
             when others => null;
           end case;
         when "10" => --8
           case Rd_Size is
             when "00" => --  32-Bit Master
               Rd_Data_Out(0 to 31) <= Rd_Data_In(64 to 95);
             when "01" => --  64-Bit Master
               Rd_Data_Out(0 to 63) <= Rd_Data_In(64 to 127);
             when others => null;
           end case;
         when "11" => --C
           case Rd_Size is
             when "00" => --32-Bit Master
               Rd_Data_Out(0 to 31) <= Rd_Data_In(96 to 127);
             when "01" => --64-Bit Master
               Rd_Data_Out(0 to 63) <= Rd_Data_In(64 to 127);
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_RD_128_32;

  GEN_RD_128_64: if C_DWIDTH = 128 and C_SMALLEST = 64 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Rd_Addr,Rd_Data_In,Rd_Size) 
     begin
       Rd_Data_Out <= Rd_Data_In;
       addr_bits <= Rd_Addr(C_AWIDTH-4);   
        case addr_bits is
         when '1' => --8
           case Rd_Size is
             when "01" => -- 64-Bit Master
               Rd_Data_Out(0 to 63) <= Rd_Data_In(64 to 127);
             when others => null;
           end case;
          when others =>
            null;
      end case;      
    end process CONNECT_PROC;
   end generate GEN_RD_128_64;
    
end architecture IMP;
