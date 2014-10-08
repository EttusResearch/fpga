--SINGLE_FILE_TAG
-------------------------------------------------------------------------------
-- $Id: ipif_steer.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- IPIF_Steer - entity/architecture pair
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
-- Filename:        ipif_steer.vhd
-- Version:         v1.00b
-- Description:     Read and Write Steering logic for IPIF
--
--                  For writes, this logic steers data from the correct byte
--                  lane to IPIF devices which may be smaller than the bus
--                  width. The BE signals are also steered if the BE_Steer
--                  signal is asserted, which indicates that the address space
--                  being accessed has a smaller maximum data transfer size
--                  than the bus size. 
--
--                  For writes, the Decode_size signal determines how read
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
--              ipif_steer.vhd
--
-------------------------------------------------------------------------------
-- Author:      BLT
-- History:
--  BLT             2-5-2002      -- First version
-- ^^^^^^
--      First version of IPIF steering logic.
-- ~~~~~~
--  BLT             2-12-2002     -- Removed BE_Steer, now generated internally
--
--  DET             2-24-2002     -- Added 'When others' to size case statement
--                                   in BE_STEER_PROC process.
--
--  BLT            10-10-2002     -- Rewrote to get around some XST synthesis 
--                                   issues.
--
--  BLT            11-18-2002     -- Added addr_bits to sensitivity lists to
--                                   fix simulation bug
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
--     C_DWIDTH    : integer := width of host databus attached to the IPIF
--     C_SMALLEST  : integer := width of smallest device (not access size)
--                              attached to the IPIF
--     C_AWIDTH    : integer := width of the host address bus attached to
--                              the IPIF
--   port definitions:
--     Wr_Data_In         : in  Write Data In (from host data bus)
--     Rd_Data_In         : in  Read Data In (from IPIC data bus)
--     Addr               : in  Address bus from host address bus
--     BE_In              : in  Byte Enables In from host side
--     Decode_size        : in  Size of MAXIMUM data access allowed to
--                              a particular address map decode.
--
--                                Size indication (Decode_size)
--                                  001 - byte           
--                                  010 - halfword       
--                                  011 - word           
--                                  100 - doubleword     
--                                  101 - 128-b          
--                                  110 - 256-b
--                                  111 - 512-b
--                                  num_bytes = 2^(n-1)
--
--     Wr_Data_Out        : out Write Data Out (to IPIF data bus)
--     Rd_Data_Out        : out Read Data Out (to host data bus)
--     BE_Out             : out Byte Enables Out to IPIF side
-- 
-------------------------------------------------------------------------------

entity IPIF_Steer is
  generic (
    C_DWIDTH    : integer := 32;    -- 8, 16, 32, 64
    C_SMALLEST  : integer := 32;    -- 8, 16, 32, 64
    C_AWIDTH    : integer := 32
    );   
  port (
    Wr_Data_In         : in  std_logic_vector(0 to C_DWIDTH-1);
    Rd_Data_In         : in  std_logic_vector(0 to C_DWIDTH-1);
    Addr               : in  std_logic_vector(0 to C_AWIDTH-1);
    BE_In              : in  std_logic_vector(0 to C_DWIDTH/8-1);
    Decode_size        : in  std_logic_vector(0 to 2);
    Wr_Data_Out        : out std_logic_vector(0 to C_DWIDTH-1);
    Rd_Data_Out        : out std_logic_vector(0 to C_DWIDTH-1);
    BE_Out             : out std_logic_vector(0 to C_DWIDTH/8-1)
    );
end entity IPIF_Steer;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of IPIF_Steer is

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin -- architecture IMP
    
  -----------------------------------------------------------------------------
  -- OPB Data Muxing and Steering
  -----------------------------------------------------------------------------
  
  -- GEN_DWIDTH_SMALLEST
  
  GEN_SAME: if C_DWIDTH = C_SMALLEST generate
      Wr_Data_Out <= Wr_Data_In;
      BE_Out      <= BE_In;
      Rd_Data_Out <= Rd_Data_In;
  end generate GEN_SAME;
  
  
  GEN_16_8: if C_DWIDTH = 16 and C_SMALLEST = 8 generate
    signal addr_bits : std_logic;
  begin
    CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
    begin
      Wr_Data_Out <= Wr_Data_In;
      BE_Out      <= BE_In;
      Rd_Data_Out <= Rd_Data_In;
      
      addr_bits <= Addr(C_AWIDTH-1);
      case addr_bits is
        when '1' => 
          Wr_Data_Out(0 to 7)  <= Wr_Data_In(8 to 15);
           case Decode_size is
             when "001" => --B
               BE_Out(0) <= BE_In(1);
               BE_Out(1) <= '0';
               Rd_Data_Out(8 to 15) <= Rd_Data_In(0 to 7);
             when others => null;
           end case;
        when others => null;
      end case; 
    end process CONNECT_PROC;
  end generate GEN_16_8;
  
  GEN_32_8: if C_DWIDTH = 32 and C_SMALLEST = 8 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Addr(C_AWIDTH-2 to C_AWIDTH-1);   --a30 to a31
        case addr_bits is
         when "01" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(8 to 15);
           case Decode_size is
             when "001" => --B
               BE_Out(0) <= BE_In(1);
               BE_Out(1 to 3) <= (others => '0');
               Rd_Data_Out(8 to 15) <= Rd_Data_In(0 to 7);
             when "010" => --HW
               Rd_Data_Out(8 to 15) <= Rd_Data_In(8 to 15);
             when others => null;
           end case;              
         when "10" => 
           Wr_Data_Out(0 to 15)  <= Wr_Data_In(16 to 31);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(2);
               BE_Out(1 to 3) <= (others => '0');
               Rd_Data_Out(16 to 23) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(2 to 3);
               BE_Out(2 to 3) <= (others => '0');
               Rd_Data_Out(16 to 31) <= Rd_Data_In(0 to 15);
             when others => null;
           end case;
         when "11" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(24 to 31);
           Wr_Data_Out(8 to 15) <= Wr_Data_In(24 to 31);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(3);
               BE_Out(1 to 3) <= (others => '0');
               Rd_Data_Out(24 to 31) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(1) <= BE_In(3);
               BE_Out(2 to 3) <= (others => '0');
               Rd_Data_Out(16 to 31) <= Rd_Data_In(0 to 15);
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
  end generate GEN_32_8;
  
  GEN_32_16: if C_DWIDTH = 32 and C_SMALLEST = 16 generate
    signal addr_bits : std_logic;
  begin
    CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
    begin
      Wr_Data_Out <= Wr_Data_In;
      BE_Out      <= BE_In;
      Rd_Data_Out <= Rd_Data_In;

      addr_bits <= Addr(C_AWIDTH-2);   --a30
       case addr_bits is
        when '1' => 
          Wr_Data_Out(0 to 15)  <= Wr_Data_In(16 to 31);
          case Decode_size is
            when "010" => --HW
              BE_Out(0 to 1) <= BE_In(2 to 3);
              BE_Out(2 to 3) <= (others => '0');
              Rd_Data_Out(16 to 31) <= Rd_Data_In(0 to 15);
            when others => null;
          end case;
        when others => null;   
     end case;      
    end process CONNECT_PROC;
  end generate GEN_32_16;


  GEN_64_8: if C_DWIDTH = 64 and C_SMALLEST = 8 generate
     signal addr_bits : std_logic_vector(0 to 2);
   begin
     CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Addr(C_AWIDTH-3 to C_AWIDTH-1);   --a29 to a31
        case addr_bits is
         when "001" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(8 to 15);
           case Decode_size is
             when "001" => --B
               BE_Out(0) <= BE_In(1);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(8 to 15) <= Rd_Data_In(0 to 7);
             when others => null;
           end case;               
         when "010" => 
           Wr_Data_Out(0 to 15)  <= Wr_Data_In(16 to 31);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(2);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(16 to 23) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(2 to 3);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(16 to 31) <= Rd_Data_In(0 to 15);
             when others => null;
           end case;
         when "011" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(24 to 31);
           Wr_Data_Out(8 to 15) <= Wr_Data_In(24 to 31);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(3);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(24 to 31) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(2 to 3);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(24 to 31) <= Rd_Data_In(8 to 15);
             when others => null;
           end case;
         when "100" => 
           Wr_Data_Out(0 to 31)  <= Wr_Data_In(32 to 63);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(4);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(32 to 39) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(4 to 5);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(32 to 47) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when "101" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(40 to 47);
           Wr_Data_Out(8 to 15) <= Wr_Data_In(40 to 47);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(5);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(40 to 47) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(4 to 5);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(32 to 47) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when "110" => 
           Wr_Data_Out(0 to 15)  <= Wr_Data_In(48 to 63);
           Wr_Data_Out(16 to 31) <= Wr_Data_In(48 to 63);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(6);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(48 to 55) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(6 to 7);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(48 to 63) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when "111" => 
           Wr_Data_Out(0 to 7)  <= Wr_Data_In(56 to 63);
           Wr_Data_Out(8 to 15) <= Wr_Data_In(56 to 63);
           Wr_Data_Out(24 to 31) <= Wr_Data_In(56 to 63);
           case Decode_size is
             when "001" => -- B
               BE_Out(0) <= BE_In(7);
               BE_Out(1 to 7) <= (others => '0');
               Rd_Data_Out(56 to 63) <= Rd_Data_In(0 to 7);
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(6 to 7);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(48 to 63) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
  end generate GEN_64_8;
  
  GEN_64_16: if C_DWIDTH = 64 and C_SMALLEST = 16 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Addr(C_AWIDTH-3 to C_AWIDTH-2);   --a29 to a30
        case addr_bits is
         when "01" => 
           Wr_Data_Out(0 to 15)  <= Wr_Data_In(16 to 31);
           case Decode_size is
             when "010" => --HW
               BE_Out(0 to 1) <= BE_In(2 to 3);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(16 to 31) <= Rd_Data_In(0 to 15);
             when others => null;
           end case;               
         when "10" => 
           Wr_Data_Out(0 to 31)  <= Wr_Data_In(32 to 63);
           case Decode_size is
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(4 to 5);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(32 to 47) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when "11" => 
           Wr_Data_Out(0 to 15)  <= Wr_Data_In(48 to 63);
           Wr_Data_Out(16 to 31) <= Wr_Data_In(48 to 63);
           case Decode_size is
             when "010" => -- HW
               BE_Out(0 to 1) <= BE_In(6 to 7);
               BE_Out(2 to 7) <= (others => '0');
               Rd_Data_Out(48 to 63) <= Rd_Data_In(0 to 15);
             when "011" => -- FW
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_64_16;

  GEN_64_32: if C_DWIDTH = 64 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Addr,Wr_Data_In,BE_In,Rd_Data_In,Decode_size) 
     begin
       Wr_Data_Out <= Wr_Data_In;
       BE_Out      <= BE_In;
       Rd_Data_Out <= Rd_Data_In;
 
       addr_bits <= Addr(C_AWIDTH-3);   --a29
        case addr_bits is
         when '1' => 
           Wr_Data_Out(0 to 31)  <= Wr_Data_In(32 to 63);
           case Decode_size is
             when "011" => 
               BE_Out(0 to 3) <= BE_In(4 to 7);
               BE_Out(4 to 7) <= (others => '0');
               Rd_Data_Out(32 to 63) <= Rd_Data_In(0 to 31);
             when others => null;
           end case;
        when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_64_32;

  -- Size indication (Decode_size)
  -- n = 001 byte           2^0
  -- n = 010 halfword       2^1
  -- n = 011 word           2^2
  -- n = 100 doubleword     2^3
  -- n = 101 128-b
  -- n = 110 256-b
  -- n = 111 512-b
  -- num_bytes = 2^(n-1)
    
end architecture IMP;
