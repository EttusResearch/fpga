-------------------------------------------------------------------------------
-- basic_sfifo_fg.vhd
-------------------------------------------------------------------------------
--
-- *************************************************************************
--
-- (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        basic_sfifo_fg.vhd
--
-- Description:     
-- This HDL file implements a basic synchronous (single clock) fifo using the
-- FIFO Generator tool. It is intended to offer a simple interface to the user
-- with the complexity of the FIFO Generator interface hidden from the user.               
--                  
-- Note that in normal op mode (not First Word Fall Through FWFT) the data count
-- output goes to zero when the FIFO goes full. This the way FIFO Generator works.
--                 
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              basic_sfifo_fg.vhd
--                 |
--                 |-- fifo_generator_v8_2
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.0 $
-- Date:            $3/07/2011$
--
-- History:
--   DET   3/07/2011       Initial Version
-- 
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.coregen_comp_defs.all;


-- synopsys translate_off
library XilinxCoreLib;
--use XilinxCoreLib.all;
-- synopsys translate_on


-------------------------------------------------------------------------------

entity basic_sfifo_fg is
  generic (
    
    C_DWIDTH                      : Integer :=  32 ;
      -- FIFO data Width (Read and write data ports are symetric)
    
    C_DEPTH                       : Integer := 512 ;
      -- FIFO Depth (set to power of 2)
 
    C_HAS_DATA_COUNT              : integer :=   1 ;
      -- 0 = Data Count output not needed
      -- 1 = Data Count output needed 
    
    C_DATA_COUNT_WIDTH            : integer :=  10 ;
    -- Data Count bit width (Max value is log2(C_DEPTH))
 
    C_IMPLEMENTATION_TYPE         : integer range 0 to 1 := 0;  
      --  0 = Common Clock BRAM / Distributed RAM (Synchronous FIFO)
      --  1 = Common Clock Shift Register (Synchronous FIFO)
    
    C_MEMORY_TYPE                 : integer := 1;
      --   0 = Any
      --   1 = BRAM
      --   2 = Distributed Memory  
      --   3 = Shift Registers
 
    C_PRELOAD_REGS                : integer := 1; 
      -- 0 = normal
      -- 1 = FWFT            
    
    C_PRELOAD_LATENCY             : integer := 0;              
      -- 0 = FWFT            
      -- 1 = normal
    
    C_USE_FWFT_DATA_COUNT         : integer := 0; 
      -- 0 = normal            
      -- 1 for FWFT
 
    C_FAMILY                      : string  := "virtex6"
  
    );
  port (
    CLK                           : IN  std_logic := '0';
    DIN                           : IN  std_logic_vector(C_DWIDTH-1 DOWNTO 0) := (OTHERS => '0');
    RD_EN                         : IN  std_logic := '0';  
    SRST                          : IN  std_logic := '0';
    WR_EN                         : IN  std_logic := '0';
    DATA_COUNT                    : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
    DOUT                          : OUT std_logic_vector(C_DWIDTH-1 DOWNTO 0);
    EMPTY                         : OUT std_logic;
    FULL                          : OUT std_logic
    );

end entity basic_sfifo_fg;


architecture implementation of basic_sfifo_fg is

  
  -- Constant Declarations  ----------------------------------------------
 
    Constant POINTER_WIDTH : integer := log2(C_DEPTH);
    
 
    -- Constant zeros for programmable threshold inputs
    Constant PROG_RDTHRESH_ZEROS : std_logic_vector(POINTER_WIDTH-1
                                   DOWNTO 0) := (OTHERS => '0');
    Constant PROG_WRTHRESH_ZEROS : std_logic_vector(POINTER_WIDTH-1 
                                   DOWNTO 0) := (OTHERS => '0');
    
    
    
    
 -- Signals

begin --(architecture implementation)

 



      
  -------------------------------------------------------------------------------
  -- Instantiate the generalized FIFO Generator instance
  --
  -- NOTE:
  -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
  -- This is a Coregen FIFO Generator Call module for 
  -- BRAM implementations of a basic Sync FIFO
  --
  -------------------------------------------------------------------------------
  I_BASIC_SFIFO : fifo_generator_v8_2 
    generic map(
      C_COMMON_CLOCK                 =>  1,                                           
      C_COUNT_TYPE                   =>  0,                                           
      C_DATA_COUNT_WIDTH             =>  C_DATA_COUNT_WIDTH,   
      C_DEFAULT_VALUE                =>  "BlankString",        
      C_DIN_WIDTH                    =>  C_DWIDTH,                          
      C_DOUT_RST_VAL                 =>  "0",
      C_DOUT_WIDTH                   =>  C_DWIDTH,
      C_ENABLE_RLOCS                 =>  0,  -- n0
      C_FAMILY                       =>  C_FAMILY,
      C_HAS_ALMOST_EMPTY             =>  0,  -- n0
      C_HAS_ALMOST_FULL              =>  0,  -- n0        
      C_HAS_BACKUP                   =>  0,  -- n0 
      C_HAS_DATA_COUNT               =>  C_HAS_DATA_COUNT,
      C_HAS_MEMINIT_FILE             =>  0,  -- n0
      C_HAS_OVERFLOW                 =>  0,  -- n0
      C_HAS_RD_DATA_COUNT            =>  0,  -- n0
      C_HAS_RD_RST                   =>  0,  -- n0
      C_HAS_RST                      =>  0,  -- n0
      C_HAS_SRST                     =>  1,  -- yes
      C_HAS_UNDERFLOW                =>  0,  -- n0
      C_HAS_VALID                    =>  0,  -- n0
      C_HAS_WR_ACK                   =>  0,  -- n0
      C_HAS_WR_DATA_COUNT            =>  0,  -- n0
      C_HAS_WR_RST                   =>  0,  -- n0
      C_IMPLEMENTATION_TYPE          =>  0,  -- Common clock BRAM
      C_INIT_WR_PNTR_VAL             =>  0,
      C_MEMORY_TYPE                  =>  C_MEMORY_TYPE,
      C_MIF_FILE_NAME                =>  "BlankString",
      C_OPTIMIZATION_MODE            =>  0,
      C_OVERFLOW_LOW                 =>  0,
      C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,                                        
      C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,                                    
      C_PRIM_FIFO_TYPE               =>  "512x36",
      C_PROG_EMPTY_THRESH_ASSERT_VAL =>  0,
      C_PROG_EMPTY_THRESH_NEGATE_VAL =>  0,
      C_PROG_EMPTY_TYPE              =>  0,
      C_PROG_FULL_THRESH_ASSERT_VAL  =>  0,
      C_PROG_FULL_THRESH_NEGATE_VAL  =>  0,
      C_PROG_FULL_TYPE               =>  0,
      C_RD_DATA_COUNT_WIDTH          =>  C_DATA_COUNT_WIDTH,
      C_RD_DEPTH                     =>  C_DEPTH,
      C_RD_FREQ                      =>  1,
      C_RD_PNTR_WIDTH                =>  POINTER_WIDTH,
      C_UNDERFLOW_LOW                =>  0,
      C_USE_DOUT_RST                 =>  1,
      C_USE_EMBEDDED_REG             =>  0,
      C_USE_FIFO16_FLAGS             =>  0,
      C_USE_FWFT_DATA_COUNT          =>  C_USE_FWFT_DATA_COUNT,
      C_VALID_LOW                    =>  0,
      C_WR_ACK_LOW                   =>  0,
      C_WR_DATA_COUNT_WIDTH          =>  C_DATA_COUNT_WIDTH,
      C_WR_DEPTH                     =>  C_DEPTH,
      C_WR_FREQ                      =>  1,
      C_WR_PNTR_WIDTH                =>  POINTER_WIDTH,
      C_WR_RESPONSE_LATENCY          =>  1,
      C_USE_ECC                      =>  0,
      C_FULL_FLAGS_RST_VAL           =>  0,
      C_ENABLE_RST_SYNC              =>  1,
      C_ERROR_INJECTION_TYPE         =>  0,
      C_HAS_INT_CLK                  =>  0,
      C_MSGON_VAL                    =>  1,
      

      -- AXI Interface related parameters start here
      C_INTERFACE_TYPE               =>  0,    --           : integer := 0; -- 0: Native Interface; 1: AXI Interface
      C_AXI_TYPE                     =>  0,    --           : integer := 0; -- 0: AXI Stream; 1: AXI Full; 2: AXI Lite
      C_HAS_AXI_WR_CHANNEL           =>  0,    --           : integer := 0;
      C_HAS_AXI_RD_CHANNEL           =>  0,    --           : integer := 0;
      C_HAS_SLAVE_CE                 =>  0,    --           : integer := 0;
      C_HAS_MASTER_CE                =>  0,    --           : integer := 0;
      C_ADD_NGC_CONSTRAINT           =>  0,    --           : integer := 0;
      C_USE_COMMON_OVERFLOW          =>  0,    --           : integer := 0;
      C_USE_COMMON_UNDERFLOW         =>  0,    --           : integer := 0;
      C_USE_DEFAULT_SETTINGS         =>  0,    --           : integer := 0;

      -- AXI Full/Lite
      C_AXI_ID_WIDTH                 =>  4 ,   --           : integer := 0;
      C_AXI_ADDR_WIDTH               =>  32,   --           : integer := 0;
      C_AXI_DATA_WIDTH               =>  64,   --           : integer := 0;
      C_HAS_AXI_AWUSER               =>  0 ,   --           : integer := 0;
      C_HAS_AXI_WUSER                =>  0 ,   --           : integer := 0;
      C_HAS_AXI_BUSER                =>  0 ,   --           : integer := 0;
      C_HAS_AXI_ARUSER               =>  0 ,   --           : integer := 0;
      C_HAS_AXI_RUSER                =>  0 ,   --           : integer := 0;
      C_AXI_ARUSER_WIDTH             =>  1 ,   --           : integer := 0;
      C_AXI_AWUSER_WIDTH             =>  1 ,   --           : integer := 0;
      C_AXI_WUSER_WIDTH              =>  1 ,   --           : integer := 0;
      C_AXI_BUSER_WIDTH              =>  1 ,   --           : integer := 0;
      C_AXI_RUSER_WIDTH              =>  1 ,   --           : integer := 0;
                                         
      -- AXI Streaming
      C_HAS_AXIS_TDATA               =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TID                 =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TDEST               =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TUSER               =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TREADY              =>  1 ,   --           : integer := 0;
      C_HAS_AXIS_TLAST               =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TSTRB               =>  0 ,   --           : integer := 0;
      C_HAS_AXIS_TKEEP               =>  0 ,   --           : integer := 0;
      C_AXIS_TDATA_WIDTH             =>  64,   --           : integer := 1;
      C_AXIS_TID_WIDTH               =>  8 ,   --           : integer := 1;
      C_AXIS_TDEST_WIDTH             =>  4 ,   --           : integer := 1;
      C_AXIS_TUSER_WIDTH             =>  4 ,   --           : integer := 1;
      C_AXIS_TSTRB_WIDTH             =>  4 ,   --           : integer := 1;
      C_AXIS_TKEEP_WIDTH             =>  4 ,   --           : integer := 1;

      -- AXI Channel Type
      -- WACH --> Write Address Channel
      -- WDCH --> Write Data Channel
      -- WRCH --> Write Response Channel
      -- RACH --> Read Address Channel
      -- RDCH --> Read Data Channel
      -- AXIS --> AXI Streaming
      C_WACH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logic
      C_WDCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
      C_WRCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
      C_RACH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
      C_RDCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
      C_AXIS_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie

      -- AXI Implementation Type
      -- 1 = Common Clock Block RAM FIFO
      -- 2 = Common Clock Distributed RAM FIFO
      -- 11 = Independent Clock Block RAM FIFO
      -- 12 = Independent Clock Distributed RAM FIFO
      C_IMPLEMENTATION_TYPE_WACH    =>  1,    --            : integer := 0;
      C_IMPLEMENTATION_TYPE_WDCH    =>  1,    --            : integer := 0;
      C_IMPLEMENTATION_TYPE_WRCH    =>  1,    --            : integer := 0;
      C_IMPLEMENTATION_TYPE_RACH    =>  1,    --            : integer := 0;
      C_IMPLEMENTATION_TYPE_RDCH    =>  1,    --            : integer := 0;
      C_IMPLEMENTATION_TYPE_AXIS    =>  1,    --            : integer := 0;

      -- AXI FIFO Type
      -- 0 = Data FIFO
      -- 1 = Packet FIFO
      -- 2 = Low Latency Data FIFO
      C_APPLICATION_TYPE_WACH      =>  0,    --             : integer := 0;
      C_APPLICATION_TYPE_WDCH      =>  0,    --             : integer := 0;
      C_APPLICATION_TYPE_WRCH      =>  0,    --             : integer := 0;
      C_APPLICATION_TYPE_RACH      =>  0,    --             : integer := 0;
      C_APPLICATION_TYPE_RDCH      =>  0,    --             : integer := 0;
      C_APPLICATION_TYPE_AXIS      =>  0,    --             : integer := 0;

      -- Enable ECC
      -- 0 = ECC disabled
      -- 1 = ECC enabled
      C_USE_ECC_WACH               =>  0,    --             : integer := 0;
      C_USE_ECC_WDCH               =>  0,    --             : integer := 0;
      C_USE_ECC_WRCH               =>  0,    --             : integer := 0;
      C_USE_ECC_RACH               =>  0,    --             : integer := 0;
      C_USE_ECC_RDCH               =>  0,    --             : integer := 0;
      C_USE_ECC_AXIS               =>  0,    --             : integer := 0;

      -- ECC Error Injection Type
      -- 0 = No Error Injection
      -- 1 = Single Bit Error Injection
      -- 2 = Double Bit Error Injection
      -- 3 = Single Bit and Double Bit Error Injection
      C_ERROR_INJECTION_TYPE_WACH  =>  0,    --             : integer := 0;
      C_ERROR_INJECTION_TYPE_WDCH  =>  0,    --             : integer := 0;
      C_ERROR_INJECTION_TYPE_WRCH  =>  0,    --             : integer := 0;
      C_ERROR_INJECTION_TYPE_RACH  =>  0,    --             : integer := 0;
      C_ERROR_INJECTION_TYPE_RDCH  =>  0,    --             : integer := 0;
      C_ERROR_INJECTION_TYPE_AXIS  =>  0,    --             : integer := 0;

      -- Input Data Width
      -- Accumulation of all AXI input signal's width
      C_DIN_WIDTH_WACH                    =>  32,     --      : integer := 1;
      C_DIN_WIDTH_WDCH                    =>  64,     --      : integer := 1;
      C_DIN_WIDTH_WRCH                    =>  2 ,     --      : integer := 1;
      C_DIN_WIDTH_RACH                    =>  32,     --      : integer := 1;
      C_DIN_WIDTH_RDCH                    =>  64,     --      : integer := 1;
      C_DIN_WIDTH_AXIS                    =>  1 ,     --      : integer := 1;

      C_WR_DEPTH_WACH                     =>  16  ,   --      : integer := 16;
      C_WR_DEPTH_WDCH                     =>  1024,   --      : integer := 16;
      C_WR_DEPTH_WRCH                     =>  16  ,   --      : integer := 16;
      C_WR_DEPTH_RACH                     =>  16  ,   --      : integer := 16;
      C_WR_DEPTH_RDCH                     =>  1024,   --      : integer := 16;
      C_WR_DEPTH_AXIS                     =>  1024,   --      : integer := 16;

      C_WR_PNTR_WIDTH_WACH                =>  4 ,     --      : integer := 4;
      C_WR_PNTR_WIDTH_WDCH                =>  10,     --      : integer := 4;
      C_WR_PNTR_WIDTH_WRCH                =>  4 ,     --      : integer := 4;
      C_WR_PNTR_WIDTH_RACH                =>  4 ,     --      : integer := 4;
      C_WR_PNTR_WIDTH_RDCH                =>  10,     --      : integer := 4;
      C_WR_PNTR_WIDTH_AXIS                =>  10,     --      : integer := 4;

      C_HAS_DATA_COUNTS_WACH              =>  0,      --      : integer := 0;
      C_HAS_DATA_COUNTS_WDCH              =>  0,      --      : integer := 0;
      C_HAS_DATA_COUNTS_WRCH              =>  0,      --      : integer := 0;
      C_HAS_DATA_COUNTS_RACH              =>  0,      --      : integer := 0;
      C_HAS_DATA_COUNTS_RDCH              =>  0,      --      : integer := 0;
      C_HAS_DATA_COUNTS_AXIS              =>  0,      --      : integer := 0;

      C_HAS_PROG_FLAGS_WACH               =>  0,      --      : integer := 0;
      C_HAS_PROG_FLAGS_WDCH               =>  0,      --      : integer := 0;
      C_HAS_PROG_FLAGS_WRCH               =>  0,      --      : integer := 0;
      C_HAS_PROG_FLAGS_RACH               =>  0,      --      : integer := 0;
      C_HAS_PROG_FLAGS_RDCH               =>  0,      --      : integer := 0;
      C_HAS_PROG_FLAGS_AXIS               =>  0,      --      : integer := 0;

      C_PROG_FULL_TYPE_WACH               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_TYPE_WDCH               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_TYPE_WRCH               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_TYPE_RACH               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_TYPE_RDCH               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_TYPE_AXIS               =>  5   ,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_WACH  =>  1023,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_WDCH  =>  1023,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_WRCH  =>  1023,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_RACH  =>  1023,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_RDCH  =>  1023,   --      : integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL_AXIS  =>  1023,   --      : integer := 0;

      C_PROG_EMPTY_TYPE_WACH              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_TYPE_WDCH              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_TYPE_WRCH              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_TYPE_RACH              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_TYPE_RDCH              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_TYPE_AXIS              =>  5   ,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH =>  1022,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH =>  1022,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH =>  1022,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH =>  1022,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH =>  1022,   --      : integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS =>  1022,   --      : integer := 0;

      C_REG_SLICE_MODE_WACH               =>  0,      --      : integer := 0;
      C_REG_SLICE_MODE_WDCH               =>  0,      --      : integer := 0;
      C_REG_SLICE_MODE_WRCH               =>  0,      --      : integer := 0;
      C_REG_SLICE_MODE_RACH               =>  0,      --      : integer := 0;
      C_REG_SLICE_MODE_RDCH               =>  0,      --      : integer := 0;
      C_REG_SLICE_MODE_AXIS               =>  0       --      : integer := 0

      )
    port map(
      BACKUP                    =>  '0',                  
      BACKUP_MARKER             =>  '0',                             
      CLK                       =>  CLK,                 -- uses this one            
      RST                       =>  '0',                             
      SRST                      =>  SRST,                -- uses this one            
      WR_CLK                    =>  '0',                             
      WR_RST                    =>  '0',                             
      RD_CLK                    =>  '0',                             
      RD_RST                    =>  '0',                             
      DIN                       =>  DIN,                 -- uses this one            
      WR_EN                     =>  WR_EN,               -- uses this one            
      RD_EN                     =>  RD_EN,               -- uses this one            
      PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  
      PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  
      PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  
      PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  
      PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  
      PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  
      INT_CLK                   =>  '0',                  
      INJECTDBITERR             =>  '0', 
      INJECTSBITERR             =>  '0', 
                                                                                                                                   
      DOUT                      =>  DOUT,                -- uses this one           
      FULL                      =>  FULL,                -- uses this one           
      ALMOST_FULL               =>  open,                       
      WR_ACK                    =>  open,                            
      OVERFLOW                  =>  open,                            
      EMPTY                     =>  EMPTY,               -- uses this one
      ALMOST_EMPTY              =>  open,                              
      VALID                     =>  open,                            
      UNDERFLOW                 =>  open,                            
      DATA_COUNT                =>  DATA_COUNT,          -- uses this one          
      RD_DATA_COUNT             =>  open,                              
      WR_DATA_COUNT             =>  open,                              
      PROG_FULL                 =>  open,                              
      PROG_EMPTY                =>  open,                              
      SBITERR                   =>  open,                              
      DBITERR                   =>  open,
           

      -- AXI Global Signal
      M_ACLK                    =>  '0',                   --       : IN  std_logic := '0';
      S_ACLK                    =>  '0',                   --       : IN  std_logic := '0';
      S_ARESETN                 =>  '0',                   --       : IN  std_logic := '0';
      M_ACLK_EN                 =>  '0',                   --       : IN  std_logic := '0';
      S_ACLK_EN                 =>  '0',                   --       : IN  std_logic := '0';

      -- AXI Full/Lite Slave Write Channel (write side)
      S_AXI_AWID                =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWADDR              =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWLEN               =>  (others => '0'),      --      : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWSIZE              =>  (others => '0'),      --      : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWBURST             =>  (others => '0'),      --      : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWLOCK              =>  (others => '0'),      --      : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWCACHE             =>  (others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWPROT              =>  (others => '0'),      --      : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWQOS               =>  (others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWREGION            =>  (others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWUSER              =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_AWVALID             =>  '0',                  --      : IN  std_logic := '0';
      S_AXI_AWREADY             =>  open,                 --      : OUT std_logic;
      S_AXI_WID                 =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_WDATA               =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_WSTRB               =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_WLAST               =>  '0',                  --      : IN  std_logic := '0';
      S_AXI_WUSER               =>  (others => '0'),      --      : IN  std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_WVALID              =>  '0',                  --      : IN  std_logic := '0';
      S_AXI_WREADY              =>  open,                 --      : OUT std_logic;
      S_AXI_BID                 =>  open,                 --      : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_BRESP               =>  open,                 --      : OUT std_logic_vector(2-1 DOWNTO 0);
      S_AXI_BUSER               =>  open,                 --      : OUT std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0);
      S_AXI_BVALID              =>  open,                 --      : OUT std_logic;
      S_AXI_BREADY              =>  '0',                  --      : IN  std_logic := '0';

      -- AXI Full/Lite Master Write Channel (Read side)
      M_AXI_AWID                =>  open,                 --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);
      M_AXI_AWADDR              =>  open,                 --       : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0);
      M_AXI_AWLEN               =>  open,                 --       : OUT std_logic_vector(8-1 DOWNTO 0);
      M_AXI_AWSIZE              =>  open,                 --       : OUT std_logic_vector(3-1 DOWNTO 0);
      M_AXI_AWBURST             =>  open,                 --       : OUT std_logic_vector(2-1 DOWNTO 0);
      M_AXI_AWLOCK              =>  open,                 --       : OUT std_logic_vector(2-1 DOWNTO 0);
      M_AXI_AWCACHE             =>  open,                 --       : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_AWPROT              =>  open,                 --       : OUT std_logic_vector(3-1 DOWNTO 0);
      M_AXI_AWQOS               =>  open,                 --       : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_AWREGION            =>  open,                 --       : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_AWUSER              =>  open,                 --       : OUT std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0);
      M_AXI_AWVALID             =>  open,                 --       : OUT std_logic;
      M_AXI_AWREADY             =>  '0',                  --       : IN  std_logic := '0';
      M_AXI_WID                 =>  open,                 --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);
      M_AXI_WDATA               =>  open,                 --       : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0);
      M_AXI_WSTRB               =>  open,                 --       : OUT std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0);
      M_AXI_WLAST               =>  open,                 --       : OUT std_logic;
      M_AXI_WUSER               =>  open,                 --       : OUT std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0);
      M_AXI_WVALID              =>  open,                 --       : OUT std_logic;
      M_AXI_WREADY              =>  '0',                  --       : IN  std_logic := '0';
      M_AXI_BID                 =>  (others => '0'),      --       : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      M_AXI_BRESP               =>  (others => '0'),      --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      M_AXI_BUSER               =>  (others => '0'),      --       : IN  std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      M_AXI_BVALID              =>  '0',                  --       : IN  std_logic := '0';
      M_AXI_BREADY              =>  open,                 --       : OUT std_logic;

      -- AXI Full/Lite Slave Read Channel (Write side)
      S_AXI_ARID               =>  (others => '0'),       --       : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARADDR             =>  (others => '0'),       --       : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0'); 
      S_AXI_ARLEN              =>  (others => '0'),       --       : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARSIZE             =>  (others => '0'),       --       : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARBURST            =>  (others => '0'),       --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARLOCK             =>  (others => '0'),       --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARCACHE            =>  (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARPROT             =>  (others => '0'),       --       : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARQOS              =>  (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARREGION           =>  (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARUSER             =>  (others => '0'),       --       : IN  std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXI_ARVALID            =>  '0',                   --       : IN  std_logic := '0';
      S_AXI_ARREADY            =>  open,                  --       : OUT std_logic;
      S_AXI_RID                =>  open,                  --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);       
      S_AXI_RDATA              =>  open,                  --       : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0); 
      S_AXI_RRESP              =>  open,                  --       : OUT std_logic_vector(2-1 DOWNTO 0);
      S_AXI_RLAST              =>  open,                  --       : OUT std_logic;
      S_AXI_RUSER              =>  open,                  --       : OUT std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0);
      S_AXI_RVALID             =>  open,                  --       : OUT std_logic;
      S_AXI_RREADY             =>  '0',                   --       : IN  std_logic := '0';

      -- AXI Full/Lite Master Read Channel (Read side)
      M_AXI_ARID               =>  open,                 --        : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);        
      M_AXI_ARADDR             =>  open,                 --        : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0);  
      M_AXI_ARLEN              =>  open,                 --        : OUT std_logic_vector(8-1 DOWNTO 0);
      M_AXI_ARSIZE             =>  open,                 --        : OUT std_logic_vector(3-1 DOWNTO 0);
      M_AXI_ARBURST            =>  open,                 --        : OUT std_logic_vector(2-1 DOWNTO 0);
      M_AXI_ARLOCK             =>  open,                 --        : OUT std_logic_vector(2-1 DOWNTO 0);
      M_AXI_ARCACHE            =>  open,                 --        : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_ARPROT             =>  open,                 --        : OUT std_logic_vector(3-1 DOWNTO 0);
      M_AXI_ARQOS              =>  open,                 --        : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_ARREGION           =>  open,                 --        : OUT std_logic_vector(4-1 DOWNTO 0);
      M_AXI_ARUSER             =>  open,                 --        : OUT std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0);
      M_AXI_ARVALID            =>  open,                 --        : OUT std_logic;
      M_AXI_ARREADY            =>  '0',                  --        : IN  std_logic := '0';
      M_AXI_RID                =>  (others => '0'),      --        : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');        
      M_AXI_RDATA              =>  (others => '0'),      --        : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
      M_AXI_RRESP              =>  (others => '0'),      --        : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
      M_AXI_RLAST              =>  '0',                  --        : IN  std_logic := '0';
      M_AXI_RUSER              =>  (others => '0'),      --        : IN  std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      M_AXI_RVALID             =>  '0',                  --        : IN  std_logic := '0';
      M_AXI_RREADY             =>  open,                 --        : OUT std_logic;

      -- AXI Streaming Slave Signals (Write side)
      S_AXIS_TVALID            =>  '0',                  --        : IN  std_logic := '0';
      S_AXIS_TREADY            =>  open,                 --        : OUT std_logic;
      S_AXIS_TDATA             =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXIS_TSTRB             =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXIS_TKEEP             =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXIS_TLAST             =>  '0',                  --        : IN  std_logic := '0';
      S_AXIS_TID               =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXIS_TDEST             =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      S_AXIS_TUSER             =>  (others => '0'),      --        : IN  std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

      -- AXI Streaming Master Signals (Read side)
      M_AXIS_TVALID            =>  open,                 --        : OUT std_logic;
      M_AXIS_TREADY            =>  '0',                  --        : IN  std_logic := '0';
      M_AXIS_TDATA             =>  open,                 --        : OUT std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0);
      M_AXIS_TSTRB             =>  open,                 --        : OUT std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0);
      M_AXIS_TKEEP             =>  open,                 --        : OUT std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0);
      M_AXIS_TLAST             =>  open,                 --        : OUT std_logic;
      M_AXIS_TID               =>  open,                 --        : OUT std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0);
      M_AXIS_TDEST             =>  open,                 --        : OUT std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0);
      M_AXIS_TUSER             =>  open,                 --        : OUT std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0);

      -- AXI Full/Lite Write Address Channel Signals
      AXI_AW_INJECTSBITERR     =>  '0',                  --        : IN  std_logic := '0';
      AXI_AW_INJECTDBITERR     =>  '0',                  --        : IN  std_logic := '0';
      AXI_AW_PROG_FULL_THRESH  =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_AW_PROG_EMPTY_THRESH =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_AW_DATA_COUNT        =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
      AXI_AW_WR_DATA_COUNT     =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
      AXI_AW_RD_DATA_COUNT     =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
      AXI_AW_SBITERR           =>  open,                 --        : OUT std_logic;
      AXI_AW_DBITERR           =>  open,                 --        : OUT std_logic;
      AXI_AW_OVERFLOW          =>  open,                 --        : OUT std_logic;
      AXI_AW_UNDERFLOW         =>  open,                 --        : OUT std_logic;

      -- AXI Full/Lite Write Data Channel Signals
      AXI_W_INJECTSBITERR      =>  '0',                  --        : IN  std_logic := '0';
      AXI_W_INJECTDBITERR      =>  '0',                  --        : IN  std_logic := '0';
      AXI_W_PROG_FULL_THRESH   =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_W_PROG_EMPTY_THRESH  =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_W_DATA_COUNT         =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
      AXI_W_WR_DATA_COUNT      =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
      AXI_W_RD_DATA_COUNT      =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
      AXI_W_SBITERR            =>  open,                 --        : OUT std_logic;
      AXI_W_DBITERR            =>  open,                 --        : OUT std_logic;
      AXI_W_OVERFLOW           =>  open,                 --        : OUT std_logic;
      AXI_W_UNDERFLOW          =>  open,                 --        : OUT std_logic;

      -- AXI Full/Lite Write Response Channel Signals
      AXI_B_INJECTSBITERR      =>  '0',                  --        : IN  std_logic := '0';
      AXI_B_INJECTDBITERR      =>  '0',                  --        : IN  std_logic := '0';
      AXI_B_PROG_FULL_THRESH   =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_B_PROG_EMPTY_THRESH  =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_B_DATA_COUNT         =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
      AXI_B_WR_DATA_COUNT      =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
      AXI_B_RD_DATA_COUNT      =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
      AXI_B_SBITERR            =>  open,                 --        : OUT std_logic;
      AXI_B_DBITERR            =>  open,                 --        : OUT std_logic;
      AXI_B_OVERFLOW           =>  open,                 --        : OUT std_logic;
      AXI_B_UNDERFLOW          =>  open,                 --        : OUT std_logic;

      -- AXI Full/Lite Read Address Channel Signals
      AXI_AR_INJECTSBITERR     =>  '0',                  --        : IN  std_logic := '0';
      AXI_AR_INJECTDBITERR     =>  '0',                  --        : IN  std_logic := '0';
      AXI_AR_PROG_FULL_THRESH  =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_AR_PROG_EMPTY_THRESH =>  (others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_AR_DATA_COUNT        =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
      AXI_AR_WR_DATA_COUNT     =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
      AXI_AR_RD_DATA_COUNT     =>  open,                 --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
      AXI_AR_SBITERR           =>  open,                 --        : OUT std_logic;
      AXI_AR_DBITERR           =>  open,                 --        : OUT std_logic;
      AXI_AR_OVERFLOW          =>  open,                 --        : OUT std_logic;
      AXI_AR_UNDERFLOW         =>  open,                 --        : OUT std_logic;

      -- AXI Full/Lite Read Data Channel Signals
      AXI_R_INJECTSBITERR     =>  '0',                  --         : IN  std_logic := '0';
      AXI_R_INJECTDBITERR     =>  '0',                  --         : IN  std_logic := '0';
      AXI_R_PROG_FULL_THRESH  =>  (others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_R_PROG_EMPTY_THRESH =>  (others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
      AXI_R_DATA_COUNT        =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
      AXI_R_WR_DATA_COUNT     =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
      AXI_R_RD_DATA_COUNT     =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
      AXI_R_SBITERR           =>  open,                 --         : OUT std_logic;
      AXI_R_DBITERR           =>  open,                 --         : OUT std_logic;
      AXI_R_OVERFLOW          =>  open,                 --         : OUT std_logic;
      AXI_R_UNDERFLOW         =>  open,                 --         : OUT std_logic;

      -- AXI Streaming FIFO Related Signals
      AXIS_INJECTSBITERR      =>  '0',                  --         : IN  std_logic := '0';
      AXIS_INJECTDBITERR      =>  '0',                  --         : IN  std_logic := '0';
      AXIS_PROG_FULL_THRESH   =>  (others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
      AXIS_PROG_EMPTY_THRESH  =>  (others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
      AXIS_DATA_COUNT         =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
      AXIS_WR_DATA_COUNT      =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
      AXIS_RD_DATA_COUNT      =>  open,                 --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
      AXIS_SBITERR            =>  open,                 --         : OUT std_logic;
      AXIS_DBITERR            =>  open,                 --         : OUT std_logic;
      AXIS_OVERFLOW           =>  open,                 --         : OUT std_logic;
      AXIS_UNDERFLOW          =>  open                  --         : OUT std_logic

     
      );
      

end implementation;
