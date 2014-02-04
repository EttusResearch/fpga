-------------------------------------------------------------------------------
-- $Id: pf_dpram_select.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- pf_dpram_select.vhd
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
-- Filename:        pf_dpram_select.vhd
--
-- Description:     This vhdl design file uses three input parameters describing
--                  the desired storage depth, data width, and FPGA family type.
--                  From these, the design selects the optimum Block RAM 
--                  primitive for the basic storage element and connects them  
--                  in parallel to accomodate the desired data width.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              pf_dpram_select.vhd
--
-------------------------------------------------------------------------------
-- Author:          D. Thorpe
-- Revision:        $Revision: 1.1.4.1 $
-- Date:            $Date: 2010/09/14 22:35:47 $
--
-- History:
--   DET  Oct. 7, 2001    First Version
--                      - Adopted design concepts from Goran Bilski's 
--                        opb_bram.vhd design in the formulation of this 
--                        design for the Mauna Loa packet FIFO dual port
--                        core function.
--
--  DET     Oct-31-2001
--          - Changed the generic input parameter C_FAMILY of type string
--            back to the boolean type parameter C_VIRTEX_II. XST support
--            change.
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
use IEEE.numeric_std.all;

                
library unisim;
use unisim.all; -- uses BRAM primitives 


-------------------------------------------------------------------------------

entity pf_dpram_select is
  generic (
    C_DP_DATA_WIDTH     : Integer  := 32;
    C_DP_ADDRESS_WIDTH  : Integer  := 9;
    C_VIRTEX_II         : Boolean  := true
    );
  port (
    
    -- Write Port signals
    Wr_rst      : In  std_logic;
    Wr_Clk      : in  std_logic;
    Wr_Enable   : In  std_logic;
    Wr_Req      : In  std_logic;
    Wr_Address  : in  std_logic_vector(0 to C_DP_ADDRESS_WIDTH-1);
    Wr_Data     : In  std_logic_vector(0 to C_DP_DATA_WIDTH-1);
    
    -- Read Port Signals
    Rd_rst      : In  std_logic;
    Rd_Clk      : in  std_logic;
    Rd_Enable   : In  std_logic;
    Rd_Address  : in  std_logic_vector(0 to C_DP_ADDRESS_WIDTH-1);
    Rd_Data     : out std_logic_vector(0 to C_DP_DATA_WIDTH-1)

    );

end entity pf_dpram_select;

                
architecture implementation of pf_dpram_select is

   
   
   
   Type family_type is (
                        any      ,
                        x4k      ,
                        x4ke     ,
                        x4kl     ,
                        x4kex    ,
                        x4kxl    ,
                        x4kxv    ,
                        x4kxla   ,
                        spartan  ,
                        spartanxl,
                        spartan2 ,
                        spartan2e,
                        virtex   ,
                        virtexe  ,
                        virtex2  ,
                        virtex2p ,
                        unsupported
                       );
 
 
   
    Type bram_prim_type is (
                            use_srl     ,
                            B4_S1_S1    ,
                            B4_S2_S2    ,
                            B4_S4_S4    ,
                            B4_S8_S8    ,
                            B4_S16_S16  ,
                            B16_S1_S1   ,
                            B16_S2_S2   ,
                            B16_S4_S4   ,
                            B16_S9_S9   ,
                            B16_S18_S18 ,
                            B16_S36_S36 ,
                            indeterminate
                           );
   
   
   
 
  -----------------------------------------------------------------------------
  -- This function converts the input C_VIRTEX_II boolean type to an enumerated 
  -- type. Only Virtex and Virtex II types are currently supported. This 
  -- used to convert a string to a family type function but string support in
  -- the synthesis tools was found to be mutually exclusive between Synplicity
  -- and XST.
  -----------------------------------------------------------------------------
  function get_prim_family (vertex2_select : boolean) return family_type is
     
     Variable prim_family : family_type; 
     
     begin
       If (vertex2_select) Then
            prim_family :=  virtex2;
       else
            prim_family :=  virtex;

       End if;
         
       
       Return (prim_family);
       
     end function get_prim_family;
  
 
 
  
  
  
  -----------------------------------------------------------------------------
  -- This function chooses the optimum BRAM primitive to utilize as
  -- specified by the inputs for data depth, data width, and FPGA part family.
  -----------------------------------------------------------------------------
  function get_bram_primitive (target_depth: integer;
                               target_width: integer;
                               family : family_type )
                               return bram_prim_type is
  
     Variable primitive : bram_prim_type;
  
  begin

    Case family Is

      When virtex2p | virtex2  => 
      
         Case target_depth Is
         
           When 1 | 2  =>
           
              primitive  := indeterminate; -- depth is too small for BRAM
                                           -- based fifo control logic
           
            
           When 4 | 8 | 16 => 
           
              -- primitive  := use_srl;  -- activate when SRL FIFO incorporated 
                                
               Case target_width Is      -- use BRAM for now

                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When 2  => 
                   primitive  := B16_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B16_S4_S4;
                   
                 When 5 | 6 | 7 | 8 | 9  => 
                   primitive  := B16_S9_S9;
                   
                 When 10 | 11 | 12 | 13 | 14 |
                      15 | 16 | 17 | 18  => 
                   primitive  := B16_S18_S18;
                   
                 When others   => 
                   primitive  := B16_S36_S36;
                   
               End case;
                                   
           when 32 | 64 | 128 | 256 | 512 =>
                 
           
               Case target_width Is

                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When 2  => 
                   primitive  := B16_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B16_S4_S4;
                   
                 When 5 | 6 | 7 | 8 | 9  => 
                   primitive  := B16_S9_S9;
                   
                 When 10 | 11 | 12 | 13 | 14 |
                      15 | 16 | 17 | 18  => 
                   primitive  := B16_S18_S18;
                   
                 When others   => 
                   primitive  := B16_S36_S36;
                   
               End case;
           
           When 1024 => 
           
               Case target_width Is
                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When 2  => 
                   primitive  := B16_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B16_S4_S4;
                   
                 When 5 | 6 | 7 | 8 | 9  => 
                   primitive  := B16_S9_S9;
                   
                 When others   => 
                   primitive  := B16_S18_S18;
                   
               End case;
               
           When 2048 => 
           
               Case target_width Is
                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When 2  => 
                   primitive  := B16_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B16_S4_S4;
                   
                 When others   => 
                   primitive  := B16_S9_S9;
                   
               End case;
           
           When 4096 => 
           
               Case target_width Is
                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When 2  => 
                   primitive  := B16_S2_S2;
                   
                 When others   => 
                   primitive  := B16_S4_S4;
                   
               End case;
           
           When 8192 => 
           
               Case target_width Is
                 When 1  => 
                   primitive  := B16_S1_S1;
                   
                 When others   => 
                   primitive  := B16_S2_S2;
                   
               End case;
           
           When 16384 => 
           
               primitive  := B16_S1_S1;
           
           When others   => 
           
             primitive  := indeterminate;
             
         End case;
      
      
      When spartan2 | spartan2e | virtex | virtexe  =>
      
         Case target_depth Is
         
           When 1  | 2   => 
           
              primitive  := indeterminate; -- depth is too small for BRAM
                                           -- based fifo control logic   
           
           
           When 4   | 8   | 16 => 
           
              -- primitive  := use_srl; -- activate this when SRL FIFO is
                                        -- incorporated
               
               Case target_width Is     -- use BRAM for now

                 When 1  => 
                   primitive  := B4_S1_S1;
                   
                 When 2  => 
                   primitive  := B4_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B4_S4_S4;
                   
                 When 5 | 6 | 7 | 8   => 
                   primitive  := B4_S8_S8;
                   
                 When others   => 
                   primitive  := B4_S16_S16;
                   
               End case;
              
           
           when 32 | 64 | 128 | 256 => 
           
               Case target_width Is

                 When 1  => 
                   primitive  := B4_S1_S1;
                   
                 When 2  => 
                   primitive  := B4_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B4_S4_S4;
                   
                 When 5 | 6 | 7 | 8   => 
                   primitive  := B4_S8_S8;
                   
                 When others   => 
                   primitive  := B4_S16_S16;
                   
               End case;
           
           
           
           when  512  => 
           
               Case target_width Is

                 When 1  => 
                   primitive  := B4_S1_S1;
                   
                 When 2  => 
                   primitive  := B4_S2_S2;
                   
                 When 3 | 4  => 
                   primitive  := B4_S4_S4;
                   
                 When others   => 
                   primitive  := B4_S8_S8;
                   
               End case;
           
                        
                        
           When 1024 => 
           
               Case target_width Is

                 When 1  => 
                   primitive  := B4_S1_S1;
                   
                 When 2  => 
                   primitive  := B4_S2_S2;
                 
                 When others   => 
                   primitive  := B4_S4_S4;
                   
               End case;
               
               
           When 2048 => 
           
               Case target_width Is

                 When 1  => 
                   primitive  := B4_S1_S1;
                 
                 When others   => 
                   primitive  := B4_S2_S2;
                   
               End case;
               
           
           When 4096 => 
           
              primitive  := B4_S1_S1; 
               
           When others   => 
           
             primitive  := indeterminate;
             
         End case;
      
      
      When others   => 
      
          primitive  := indeterminate;
           
    End case;
    
    

    Return primitive;
  
  end function get_bram_primitive;
  

 
  -----------------------------------------------------------------------------
  -- This function calculates the number of BRAM primitives required as
  -- specified by the inputs for data width and BRAM primitive type.
  -----------------------------------------------------------------------------
  function get_num_prims (bram_prim : bram_prim_type; 
                          mem_width : integer) 
                          return integer is
  
    Variable bram_num : integer;
    
  begin
  
      Case bram_prim Is

        When B16_S1_S1 | B4_S1_S1 => 
           bram_num := mem_width;
           

        When B16_S2_S2 | B4_S2_S2 => 
           bram_num := (mem_width+1)/2;
           

        When B16_S4_S4 | B4_S4_S4 => 
           bram_num := (mem_width+3)/4;
           

        When B4_S8_S8 => 
           bram_num := (mem_width+7)/8;
           
        
        When B16_S9_S9 => 
           bram_num := (mem_width+8)/9;
           

        When B4_S16_S16 => 
           bram_num := (mem_width+15)/16;
           
        
        When B16_S18_S18 => 
           bram_num := (mem_width+17)/18;
           

        When B16_S36_S36 => 
           bram_num := (mem_width+35)/36;
           
        When others   => 
           bram_num := 1;
           
      End case;
    
    
     Return (bram_num);
     
  end function get_num_prims;
  
 
 
 -- Now set the global CONSTANTS needed for IF-Generates
 
 
  
   -- Determine the number of BRAM storage locations needed   
   constant FIFO_DEPTH     : Integer  := 2**C_DP_ADDRESS_WIDTH;
   
   
   -- Convert the input C_VIRTEX_II generic boolean to enumerated type
   Constant BRAM_FAMILY    : family_type := 
   
                 get_prim_family(C_VIRTEX_II);
                 
   
   -- Select the optimum BRAM primitive to use
   constant BRAM_PRIMITIVE : bram_prim_type :=
    
                 get_bram_primitive(FIFO_DEPTH, 
                                    C_DP_DATA_WIDTH,
                                    BRAM_FAMILY);
                                    
                                    
   -- Calculate how many of the selected primitives are needed
   -- to populate the desired data width                                 
   constant BRAM_NUM       : integer := 
   
                 get_num_prims(BRAM_PRIMITIVE, 
                               C_DP_DATA_WIDTH);
      
      
  
  
  
begin  -- architecture
    
    
   ----------------------------------------------------------------------------
   -- Using VII 512 x 36 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S36_S36 : if (BRAM_PRIMITIVE = B16_S36_S36) generate 

      
      component RAMB16_S36_S36
        port (DIA    : in STD_LOGIC_VECTOR (31 downto 0);
              DIB    : in STD_LOGIC_VECTOR (31 downto 0);
              DIPA   : in STD_LOGIC_VECTOR (3 downto 0);
              DIPB   : in STD_LOGIC_VECTOR (3 downto 0);
              ENA    : in std_logic;
              ENB    : in std_logic;
              WEA    : in std_logic;
              WEB    : in std_logic;
              SSRA   : in std_logic;
              SSRB   : in std_logic;
              CLKA   : in std_logic;
              CLKB   : in std_logic;
              ADDRA  : in STD_LOGIC_VECTOR (8 downto 0);
              ADDRB  : in STD_LOGIC_VECTOR (8 downto 0);
              DOA    : out STD_LOGIC_VECTOR (31 downto 0);
              DOB    : out STD_LOGIC_VECTOR (31 downto 0);
              DOPA   : out STD_LOGIC_VECTOR (3 downto 0);
              DOPB   : out STD_LOGIC_VECTOR (3 downto 0)); 
      end component;
   
                      
      Constant PRIM_ADDR_WIDTH  : integer := 9;  -- 512 deep
      Constant PRIM_PDBUS_WIDTH : integer := 4;  -- 4 parity data bits
      Constant PRIM_DBUS_WIDTH  : integer := 32;  -- 4 parity data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
        
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
         
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;                                   
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_512x32 : RAMB16_S36_S36
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   DIPA   =>   slice_a_pdbus_in(i),    
                   DIPB   =>   slice_b_pdbus_in(i),    
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i),    
                   DOPA   =>   slice_a_pdbus_out(i),   
                   DOPB   =>   slice_b_pdbus_out(i)     
                   );
     
     
     End generate BRAM_LOOP; 
           
   
   end generate Using_RAMB16_S36_S36;
   --==========================================================================                      


  
  
   ----------------------------------------------------------------------------
   -- Using VII 1024 x 18 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S18_S18 : if (BRAM_PRIMITIVE = B16_S18_S18) generate 

      
      component RAMB16_S18_S18 
        port (DIA    : in STD_LOGIC_VECTOR (15 downto 0);
              DIB    : in STD_LOGIC_VECTOR (15 downto 0);
              DIPA   : in STD_LOGIC_VECTOR (1 downto 0);
              DIPB   : in STD_LOGIC_VECTOR (1 downto 0);
              ENA    : in std_logic;
              ENB    : in std_logic;
              WEA    : in std_logic;
              WEB    : in std_logic;
              SSRA   : in std_logic;
              SSRB   : in std_logic;
              CLKA   : in std_logic;
              CLKB   : in std_logic;
              ADDRA  : in STD_LOGIC_VECTOR (9 downto 0);
              ADDRB  : in STD_LOGIC_VECTOR (9 downto 0);
              DOA    : out STD_LOGIC_VECTOR (15 downto 0);
              DOB    : out STD_LOGIC_VECTOR (15 downto 0);
              DOPA   : out STD_LOGIC_VECTOR (1 downto 0);
              DOPB   : out STD_LOGIC_VECTOR (1 downto 0)
             ); 
      
      end component;
     
      
                      
      Constant PRIM_ADDR_WIDTH  : integer := 10; -- 1024 deep
      Constant PRIM_PDBUS_WIDTH : integer := 2;  -- 2 parity data bits
      Constant PRIM_DBUS_WIDTH  : integer := 16; -- 16 data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_1024x18 : RAMB16_S18_S18
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   DIPA   =>   slice_a_pdbus_in(i),    
                   DIPB   =>   slice_b_pdbus_in(i),    
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i),    
                   DOPA   =>   slice_a_pdbus_out(i),   
                   DOPB   =>   slice_b_pdbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB16_S18_S18;
   --==========================================================================                         
  
  
  
   ----------------------------------------------------------------------------
   -- Using VII 2048 x 9 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S9_S9 : if (BRAM_PRIMITIVE = B16_S9_S9) generate 

      
      component RAMB16_S9_S9
        port (
          DIA   : in  std_logic_vector (7 downto 0);
          DIB   : in  std_logic_vector (7 downto 0);
          DIPA  : in  std_logic_vector (0 downto 0);
          DIPB  : in  std_logic_vector (0 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          SSRA  : in  std_logic;
          SSRB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (10 downto 0);
          ADDRB : in  std_logic_vector (10 downto 0);
          DOA   : out std_logic_vector (7 downto 0);
          DOB   : out std_logic_vector (7 downto 0);
          DOPA  : out std_logic_vector (0 downto 0);
          DOPB  : out std_logic_vector (0 downto 0) ); 
      end component;
     
      
      Constant PRIM_ADDR_WIDTH  : integer := 11; -- 2048 deep
      Constant PRIM_PDBUS_WIDTH : integer := 1;  -- 1 parity data bit
      Constant PRIM_DBUS_WIDTH  : integer := 8;  -- 8 data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
         
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_2048x9 : RAMB16_S9_S9
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   DIPA   =>   slice_a_pdbus_in(i),    
                   DIPB   =>   slice_b_pdbus_in(i),    
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i),    
                   DOPA   =>   slice_a_pdbus_out(i),   
                   DOPB   =>   slice_b_pdbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB16_S9_S9;
   --==========================================================================                         
  
  
  
  
   ----------------------------------------------------------------------------
   -- Using VII 4096 x 4 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S4_S4 : if (BRAM_PRIMITIVE = B16_S4_S4) generate 

      
      component RAMB16_S4_S4
        port (
          DIA   : in  std_logic_vector (3 downto 0);
          DIB   : in  std_logic_vector (3 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          SSRA  : in  std_logic;
          SSRB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (11 downto 0);
          ADDRB : in  std_logic_vector (11 downto 0);
          DOA   : out std_logic_vector (3 downto 0);
          DOB   : out std_logic_vector (3 downto 0) ); 
      end component;
      
      
      
      Constant PRIM_ADDR_WIDTH  : integer := 12; -- 4096 deep
      Constant PRIM_PDBUS_WIDTH : integer := 0;  -- 0 parity data bits
      Constant PRIM_DBUS_WIDTH  : integer := 4;  -- 4 data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      --type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
      --                            std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           --slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           --port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           --slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           --port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_4096x4 : RAMB16_S4_S4
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB16_S4_S4;
   --==========================================================================                         
  
  
   
   
   ----------------------------------------------------------------------------
   -- Using VII 8192 x 2 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S2_S2 : if (BRAM_PRIMITIVE = B16_S2_S2) generate 

      
      component RAMB16_S2_S2
        port (
          DIA   : in  std_logic_vector (1 downto 0);
          DIB   : in  std_logic_vector (1 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          SSRA  : in  std_logic;
          SSRB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (12 downto 0);
          ADDRB : in  std_logic_vector (12 downto 0);
          DOA   : out std_logic_vector (1 downto 0);
          DOB   : out std_logic_vector (1 downto 0) ); 
      end component;
      
      
      
      Constant PRIM_ADDR_WIDTH  : integer := 13; -- 8192 deep
      Constant PRIM_PDBUS_WIDTH : integer := 0;  -- 0 parity data bits
      Constant PRIM_DBUS_WIDTH  : integer := 2;  -- 2 data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
                      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      --type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
      --                            std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           --slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           --port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           --slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           --port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_8192x2 : RAMB16_S2_S2
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB16_S2_S2;
   --==========================================================================                         
  
  
  
   ----------------------------------------------------------------------------
   -- Using VII 16384 x 1 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB16_S1_S1 : if (BRAM_PRIMITIVE = B16_S1_S1) generate 

      
      component RAMB16_S1_S1
        port (
          DIA   : in  std_logic_vector (0 downto 0);
          DIB   : in  std_logic_vector (0 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          SSRA  : in  std_logic;
          SSRB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (13 downto 0);
          ADDRB : in  std_logic_vector (13 downto 0);
          DOA   : out std_logic_vector (0 downto 0);
          DOB   : out std_logic_vector (0 downto 0) ); 
      end component;

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 14; -- 16384 deep
      Constant PRIM_PDBUS_WIDTH : integer := 0;  -- 0 parity data bits
      Constant PRIM_DBUS_WIDTH  : integer := 1;  -- 1 data bits
      Constant SLICE_DBUS_WIDTH : integer := PRIM_DBUS_WIDTH
                                             + PRIM_PDBUS_WIDTH; -- (data + parity)
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * SLICE_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
      --type   pdbus_slice_array is array(BRAM_NUM downto 1) of 
      --                            std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
                      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_in    : pdbus_slice_array;  -- std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_a_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_in     : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_in    : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_b_dbus_out    : dbus_slice_array;  --std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      --Signal slice_b_pdbus_out   : pdbus_slice_array;  --std_logic_vector(PRIM_PDBUS_WIDTH-1 downto 0);
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <= Wr_Enable; 
          port_a_wr_enable   <= Wr_Req; 
          port_a_ssr         <= Wr_rst;          
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= Rd_rst;          
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
         
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
                                              
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           --slice_a_pdbus_in(i) <= port_a_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
     
           slice_a_dbus_in(i)  <= port_a_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           --port_a_data_out((i*SLICE_DBUS_WIDTH)-1 downto                                                              
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_a_pdbus_out(i);                                                   
                                                                
                                                                
           port_a_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto                                                                              
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           --slice_b_pdbus_in(i) <= port_b_data_in((i*SLICE_DBUS_WIDTH)-1 downto
           --                                   (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH);                                  
                                              
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto
                                              (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH);
 
           
           --port_b_data_out((i*SLICE_DBUS_WIDTH)-1 downto         
           --                (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH) <= slice_b_pdbus_out(i);
 
                                                                                  
                                               
           port_b_data_out((i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-1 downto        
                           (i*SLICE_DBUS_WIDTH)-PRIM_PDBUS_WIDTH-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB16_16384x1 : RAMB16_S1_S1
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   SSRA   =>   port_a_ssr,          
                   SSRB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB16_S1_S1;
   --==========================================================================                         
  
  
  
  -- End of Virtex-II and Virtex-II Pro support
  --///////////////////////////////////////////////////////////////////////////
  
  
                                               
                                               
                                               
                                               
                                               
                                               
                                               
  --///////////////////////////////////////////////////////////////////////////
  -- Start Spartan-II, Spartan-IIE, Virtex, and VirtexE support                                             
                                               
                                               
   ----------------------------------------------------------------------------
   -- Using Spartan-II, Spartan-IIE, Virtex, and VirtexE
   -- 4096 x 1 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB4_S1_S1 : if (BRAM_PRIMITIVE = B4_S1_S1) generate 

      
      component RAMB4_S1_S1
        port (
          DIA   : in  std_logic_vector (0 downto 0);
          DIB   : in  std_logic_vector (0 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          RSTA  : in  std_logic;
          RSTB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (11 downto 0);
          ADDRB : in  std_logic_vector (11 downto 0);
          DOA   : out std_logic_vector (0 downto 0);
          DOB   : out std_logic_vector (0 downto 0)); 
      end component;

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 12; -- 4096 deep
      Constant PRIM_DBUS_WIDTH  : integer := 1;  -- 1 data bit
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * PRIM_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  
      Signal slice_a_dbus_out    : dbus_slice_array;  
      Signal slice_b_dbus_in     : dbus_slice_array;  
      Signal slice_b_dbus_out    : dbus_slice_array;  
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <=  Wr_Enable; 
          port_a_wr_enable   <=  Wr_Req; 
          port_a_ssr         <=  wr_rst;         -- no output reset value
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= rd_rst;          -- no output reset value
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_dbus_in(i)  <= port_a_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*PRIM_DBUS_WIDTH)-1 downto                                                                              
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*PRIM_DBUS_WIDTH)-1 downto        
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB4_4096x1 : RAMB4_S1_S1
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   RSTA   =>   port_a_ssr,          
                   RSTB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB4_S1_S1;
   --==========================================================================                         
                                               
                                               
                                               
                                               
   ----------------------------------------------------------------------------
   -- Using Spartan-II, Spartan-IIE, Virtex, and VirtexE
   -- 2048 x 2 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB4_S2_S2 : if (BRAM_PRIMITIVE = B4_S2_S2) generate 

      
      component RAMB4_S2_S2
        port (
          DIA   : in  std_logic_vector (1 downto 0);
          DIB   : in  std_logic_vector (1 downto 0);
          ENA   : in  std_logic;
          ENB   : in  std_logic;
          WEA   : in  std_logic;
          WEB   : in  std_logic;
          RSTA  : in  std_logic;
          RSTB  : in  std_logic;
          CLKA  : in  std_logic;
          CLKB  : in  std_logic;
          ADDRA : in  std_logic_vector (10 downto 0);
          ADDRB : in  std_logic_vector (10 downto 0);
          DOA   : out std_logic_vector (1 downto 0);
          DOB   : out std_logic_vector (1 downto 0)); 
      end component;

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 11; -- 2048 deep
      Constant PRIM_DBUS_WIDTH  : integer := 2;  -- 2 data bits
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * PRIM_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  
      Signal slice_a_dbus_out    : dbus_slice_array;  
      Signal slice_b_dbus_in     : dbus_slice_array;  
      Signal slice_b_dbus_out    : dbus_slice_array;  
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <=  Wr_Enable; 
          port_a_wr_enable   <=  Wr_Req; 
          port_a_ssr         <=  wr_rst;         -- no output reset value
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= rd_rst;          -- no output reset value
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
         
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_dbus_in(i)  <= port_a_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*PRIM_DBUS_WIDTH)-1 downto                                                                              
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*PRIM_DBUS_WIDTH)-1 downto        
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB4_2048x2 : RAMB4_S2_S2
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   RSTA   =>   port_a_ssr,          
                   RSTB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB4_S2_S2;
   --==========================================================================                         
                                               
                                               
                                               
                                               
   ----------------------------------------------------------------------------
   -- Using Spartan-II, Spartan-IIE, Virtex, and VirtexE
   -- 1024 x 4 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB4_S4_S4 : if (BRAM_PRIMITIVE = B4_S4_S4) generate 

      
      component RAMB4_S4_S4                          
        port (                                       
          DIA   : in  std_logic_vector (3 downto 0); 
          DIB   : in  std_logic_vector (3 downto 0); 
          ENA   : in  std_logic;                    
          ENB   : in  std_logic;                    
          WEA   : in  std_logic;                    
          WEB   : in  std_logic;                    
          RSTA  : in  std_logic;                    
          RSTB  : in  std_logic;                    
          CLKA  : in  std_logic;                    
          CLKB  : in  std_logic;                    
          ADDRA : in  std_logic_vector (9 downto 0); 
          ADDRB : in  std_logic_vector (9 downto 0); 
          DOA   : out std_logic_vector (3 downto 0); 
          DOB   : out std_logic_vector (3 downto 0)); 
      end component;                                 

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 10; -- 1024 deep
      Constant PRIM_DBUS_WIDTH  : integer := 4;  -- 4 data bits
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * PRIM_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  
      Signal slice_a_dbus_out    : dbus_slice_array;  
      Signal slice_b_dbus_in     : dbus_slice_array;  
      Signal slice_b_dbus_out    : dbus_slice_array;  
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <=  Wr_Enable; 
          port_a_wr_enable   <=  Wr_Req; 
          port_a_ssr         <=  wr_rst;         -- no output reset value
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= rd_rst;          -- no output reset value
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_dbus_in(i)  <= port_a_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*PRIM_DBUS_WIDTH)-1 downto                                                                              
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*PRIM_DBUS_WIDTH)-1 downto        
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB4_1024x4 : RAMB4_S4_S4
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   RSTA   =>   port_a_ssr,          
                   RSTB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB4_S4_S4;
   --==========================================================================                         
                                               
                                               
 
 
   ----------------------------------------------------------------------------
   -- Using Spartan-II, Spartan-IIE, Virtex, and VirtexE
   -- 512 x 8 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB4_S8_S8 : if (BRAM_PRIMITIVE = B4_S8_S8) generate 

      
      component RAMB4_S8_S8                          
        port (                                       
          DIA   : in  std_logic_vector (7 downto 0); 
          DIB   : in  std_logic_vector (7 downto 0); 
          ENA   : in  std_logic;                    
          ENB   : in  std_logic;                    
          WEA   : in  std_logic;                    
          WEB   : in  std_logic;                    
          RSTA  : in  std_logic;                    
          RSTB  : in  std_logic;                    
          CLKA  : in  std_logic;                    
          CLKB  : in  std_logic;                    
          ADDRA : in  std_logic_vector (8 downto 0); 
          ADDRB : in  std_logic_vector (8 downto 0); 
          DOA   : out std_logic_vector (7 downto 0); 
          DOB   : out std_logic_vector (7 downto 0)); 
      end component;                                 

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 9; -- 512 deep
      Constant PRIM_DBUS_WIDTH  : integer := 8; -- 8 data bits
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * PRIM_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  
      Signal slice_a_dbus_out    : dbus_slice_array;  
      Signal slice_b_dbus_in     : dbus_slice_array;  
      Signal slice_b_dbus_out    : dbus_slice_array;  
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <=  Wr_Enable; 
          port_a_wr_enable   <=  Wr_Req; 
          port_a_ssr         <=  wr_rst;         -- no output reset value
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= rd_rst;          -- no output reset value
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
       
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_dbus_in(i)  <= port_a_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*PRIM_DBUS_WIDTH)-1 downto                                                                              
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*PRIM_DBUS_WIDTH)-1 downto        
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB4_512x8 : RAMB4_S8_S8
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   RSTA   =>   port_a_ssr,          
                   RSTB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB4_S8_S8;
   --==========================================================================                         




   ----------------------------------------------------------------------------
   -- Using Spartan-II, Spartan-IIE, Virtex, and VirtexE
   -- 256 x 16 Dual Port Primitive
   ----------------------------------------------------------------------------
   Using_RAMB4_S16_S16 : if (BRAM_PRIMITIVE = B4_S16_S16) generate 

      
      component RAMB4_S16_S16                              
        port (DIA    : in  STD_LOGIC_VECTOR (15 downto 0);  
              DIB    : in  STD_LOGIC_VECTOR (15 downto 0);  
              ENA    : in  std_logic;                      
              ENB    : in  std_logic;                      
              WEA    : in  std_logic;                      
              WEB    : in  std_logic;                      
              RSTA   : in  std_logic;                      
              RSTB   : in  std_logic;                      
              CLKA   : in  std_logic;                      
              CLKB   : in  std_logic;                      
              ADDRA  : in  STD_LOGIC_VECTOR (7 downto 0);   
              ADDRB  : in  STD_LOGIC_VECTOR (7 downto 0);   
              DOA    : out STD_LOGIC_VECTOR (15 downto 0); 
              DOB    : out STD_LOGIC_VECTOR (15 downto 0));
      end component;                                        
      

      
      
      Constant PRIM_ADDR_WIDTH  : integer := 8;  -- 256 deep
      Constant PRIM_DBUS_WIDTH  : integer := 16; -- 16 data bits
      
      Constant BRAM_DATA_WIDTH  : integer := BRAM_NUM * PRIM_DBUS_WIDTH;
      
      
      
      type   dbus_slice_array  is array(BRAM_NUM downto 1) of 
                                  std_logic_vector(PRIM_DBUS_WIDTH-1 downto 0);
      
                      
      Signal slice_a_dbus_in     : dbus_slice_array;  
      Signal slice_a_dbus_out    : dbus_slice_array;  
      Signal slice_b_dbus_in     : dbus_slice_array;  
      Signal slice_b_dbus_out    : dbus_slice_array;  
      Signal slice_a_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      Signal slice_b_abus        : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);
      
      signal port_a_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_a_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);    
      signal port_a_enable       : std_logic;                                       
      signal port_a_wr_enable    : std_logic;                                       
      signal port_a_ssr          : std_logic;                                       
                                                                                      
      signal port_b_addr         : std_logic_vector(PRIM_ADDR_WIDTH-1 downto 0);    
      signal port_b_data_in      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_data_out     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);       
      signal port_b_enable       : std_logic;                                          
      signal port_b_wr_enable    : std_logic;                                          
      signal port_b_ssr          : std_logic;                                          
            

   begin  -- generate
       
     
          
          port_a_enable      <=  Wr_Enable; 
          port_a_wr_enable   <=  Wr_Req; 
          port_a_ssr         <=  wr_rst;         -- no output reset value
          
        
          port_b_data_in     <= (others => '0'); -- no input data to port B     
          port_b_enable      <= Rd_Enable;
          port_b_wr_enable   <= '0';             -- no writing to port B
          port_b_ssr         <= rd_rst;          -- no output reset value
                
          
          
          -- translate big-endian and little_endian indexes of the
          -- data buses
          TRANSLATE_DATA : process (Wr_Data, port_b_data_out)
            Begin

              port_a_data_in <= (others => '0');
        
              for i in C_DP_DATA_WIDTH-1 downto 0 loop
          
                 port_a_data_in(i)             <= Wr_Data(C_DP_DATA_WIDTH-1-i); 
                 Rd_Data(C_DP_DATA_WIDTH-1-i)  <= port_b_data_out(i);
                 
              End loop; 
              
              
            End process TRANSLATE_DATA; 
            
        
          -- translate big-endian and little_endian indexes of the
          -- address buses (makes simulation easier)
          TRANSLATE_ADDRESS : process (Wr_Address, Rd_Address)
            Begin
        
              port_a_addr <= (others => '0');  
              port_b_addr <= (others => '0');  
                
              for i in C_DP_ADDRESS_WIDTH-1 downto 0 loop
          
                 port_a_addr(i)   <=  Wr_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 port_b_addr(i)   <=  Rd_Address(C_DP_ADDRESS_WIDTH-1-i); 
                 
              End loop; 
              
              
            End process TRANSLATE_ADDRESS; 
            
                
      slice_a_abus     <= port_a_addr;                                   
      slice_b_abus     <= port_b_addr;
         
   
          
     BRAM_LOOP : for i in BRAM_NUM  downto 1 generate
         
           
           
           
           slice_a_dbus_in(i)  <= port_a_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
                                              
                                                                
                                                                
           port_a_data_out((i*PRIM_DBUS_WIDTH)-1 downto                                                                              
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_a_dbus_out(i); 
                                                                  
                                              
           
           
           slice_b_dbus_in(i)  <= port_b_data_in((i*PRIM_DBUS_WIDTH)-1 downto
                                              (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH);
 
           
           port_b_data_out((i*PRIM_DBUS_WIDTH)-1 downto        
                           (i*PRIM_DBUS_WIDTH)-PRIM_DBUS_WIDTH) <= slice_b_dbus_out(i);                                                     
                                              
            
                                              
                                              
          -- Port A is fixed as the input (write) port
          -- Port B is fixed as the output (read) port
           I_DPB4_256x16 : RAMB4_S16_S16
             port map(
                   DIA    =>   slice_a_dbus_in(i),     
                   DIB    =>   slice_b_dbus_in(i),     
                   ENA    =>   port_a_enable,       
                   ENB    =>   port_b_enable,       
                   WEA    =>   port_a_wr_enable,    
                   WEB    =>   port_b_wr_enable,    
                   RSTA   =>   port_a_ssr,          
                   RSTB   =>   port_b_ssr,          
                   CLKA   =>   Wr_Clk,              
                   CLKB   =>   Rd_Clk,              
                   ADDRA  =>   slice_a_abus,        
                   ADDRB  =>   slice_b_abus,        
                   DOA    =>   slice_a_dbus_out(i),    
                   DOB    =>   slice_b_dbus_out(i)    
                   );
     
     
     End generate BRAM_LOOP; 
           
   end generate Using_RAMB4_S16_S16;
   --==========================================================================                         





 
 
 
  
   
   UNSUPPORTED_FAMILY : if (BRAM_PRIMITIVE = indeterminate) generate
       
     
     begin
    
      --   assert (false)
      --      report "Unsupported Part Family Selected or FIFO Depth/Width is invalid!"
      --      severity failure;
      --    
        
      
   end generate UNSUPPORTED_FAMILY;
        
        
  
  
end architecture implementation;



