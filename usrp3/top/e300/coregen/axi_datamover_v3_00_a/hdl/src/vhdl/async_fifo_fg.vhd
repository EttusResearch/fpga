-------------------------------------------------------------------------------
-- $Id:$
-------------------------------------------------------------------------------
-- async_fifo_fg.vhd
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
-- ** Copyright (c) 2008, 2009, 2010 Xilinx, Inc. All rights reserved.    **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        async_fifo_fg.vhd
--
-- Description:     
-- This HDL file adapts the legacy CoreGen Async FIFO interface to the new                
-- FIFO Generator async FIFO interface. This wrapper facilitates the "on
-- the fly" call of FIFO Generator during design implementation.                
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              async_fifo_fg.vhd
--                 |
--                 |-- fifo_generator_v4_3
--                 |
--                 |-- fifo_generator_v9_1
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.5.2.68 $
-- Date:            $1/15/2008$
--
-- History:
--   DET   1/15/2008       Initial Version
-- 
--     DET     7/30/2008     for EDK 11.1
-- ~~~~~~
--     - Added parameter C_ALLOW_2N_DEPTH to enable use of FIFO Generator
--       feature of specifing 2**N depth of FIFO, Legacy CoreGen Async FIFOs
--       only allowed (2**N)-1 depth specification. Parameter is defalted to 
--       the legacy CoreGen method so current users are not impacted.
--     - Incorporated calculation and assignment corrections for the Read and 
--       Write Pointer Widths.
--     - Upgraded to FIFO Generator Version 4.3.
--     - Corrected a swap of the Rd_Err and the Wr_Err connections on the FIFO
--       Generator instance.
-- ^^^^^^
--
--      MSH and DET     3/2/2009     For Lava SP2
-- ~~~~~~
--     - Added FIFO Generator version 5.1 for use with Virtex6 and Spartan6 
--       devices.
--     - IfGen used so that legacy FPGA families still use Fifo Generator 
--       version 4.3.
-- ^^^^^^
--
--     DET     2/9/2010     for EDK 12.1
-- ~~~~~~
--     - Updated the S6/V6 FIFO Generator version from V5.2 to V5.3.
-- ^^^^^^
--
--     DET     3/10/2010     For EDK 12.x
-- ~~~~~~
--   -- Per CR553307
--     - Updated the S6/V6 FIFO Generator version from V5.3 to 6_1.
-- ^^^^^^
--
--     DET     6/18/2010     EDK_MS2
-- ~~~~~~
--    -- Per IR565916
--     - Added derivative part type checks for S6 or V6.
-- ^^^^^^
--
--     DET     8/30/2010     EDK_MS4
-- ~~~~~~
--    -- Per CR573867
--     - Updated the S6/V6 FIFO Generator version from V6.1 to 7.2.
--     - Added all of the AXI parameters and ports. They are not used
--       in this application.
--     - Updated method for derivative part support using new family
--       aliasing function in family_support.vhd.
--     - Incorporated an implementation to deal with unsupported FPGA
--       parts passed in on the C_FAMILY parameter.
-- ^^^^^^
--
--     DET     10/4/2010     EDK 13.1
-- ~~~~~~
--     - Updated the FIFO Generator version from V7.2 to 7.3.
-- ^^^^^^
--
--     DET     12/8/2010     EDK 13.1
-- ~~~~~~
--    -- Per CR586109
--     - Updated the FIFO Generator version from V7.3 to 8.1.
-- ^^^^^^
--
--     DET     3/2/2011     EDK 13.2
-- ~~~~~~
--    -- Per CR595473
--     - Update to use fifo_generator_v8_2
-- ^^^^^^
--
--
--     RBODDU  08/18/2011     EDK 13.3
-- ~~~~~~
--     - Update to use fifo_generator_v8_3
-- ^^^^^^
--
--     RBODDU  06/07/2012     EDK 14.2
-- ~~~~~~
--     - Update to use fifo_generator_v9_1
-- ^^^^^^
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.coregen_comp_defs.all;
use proc_common_v3_00_a.family_support.all;


-- synopsys translate_off
library XilinxCoreLib;
--use XilinxCoreLib.all;
-- synopsys translate_on


-------------------------------------------------------------------------------

entity async_fifo_fg is
  generic (
        C_ALLOW_2N_DEPTH   : Integer := 0;  -- New paramter to leverage FIFO Gen 2**N depth
        C_FAMILY           : String  := "virtex5";  -- new for FIFO Gen
        C_DATA_WIDTH       : integer := 16;
        C_ENABLE_RLOCS     : integer := 0 ;  -- not supported in FG
        C_FIFO_DEPTH       : integer := 15;
        C_HAS_ALMOST_EMPTY : integer := 1 ;
        C_HAS_ALMOST_FULL  : integer := 1 ;
        C_HAS_RD_ACK       : integer := 0 ;
        C_HAS_RD_COUNT     : integer := 1 ;
        C_HAS_RD_ERR       : integer := 0 ;
        C_HAS_WR_ACK       : integer := 0 ;
        C_HAS_WR_COUNT     : integer := 1 ;
        C_HAS_WR_ERR       : integer := 0 ;
        C_RD_ACK_LOW       : integer := 0 ;
        C_RD_COUNT_WIDTH   : integer := 3 ;
        C_RD_ERR_LOW       : integer := 0 ;
        C_USE_EMBEDDED_REG : integer := 0 ;  -- Valid only for BRAM based FIFO, otherwise needs to be set to 0
        C_PRELOAD_REGS     : integer := 0 ;   
        C_PRELOAD_LATENCY  : integer := 1 ;  -- needs to be set 2 when C_USE_EMBEDDED_REG = 1 
        C_USE_BLOCKMEM     : integer := 1 ;  -- 0 = distributed RAM, 1 = BRAM
        C_WR_ACK_LOW       : integer := 0 ;
        C_WR_COUNT_WIDTH   : integer := 3 ;
        C_WR_ERR_LOW       : integer := 0   
    );
  port (
        Din            : in std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
        Wr_en          : in std_logic := '1';
        Wr_clk         : in std_logic := '1';
        Rd_en          : in std_logic := '0';
        Rd_clk         : in std_logic := '1';
        Ainit          : in std_logic := '1';   
        Dout           : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        Full           : out std_logic; 
        Empty          : out std_logic; 
        Almost_full    : out std_logic;  
        Almost_empty   : out std_logic;  
        Wr_count       : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
        Rd_count       : out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
        Rd_ack         : out std_logic;
        Rd_err         : out std_logic;
        Wr_ack         : out std_logic;
        Wr_err         : out std_logic
    );

end entity async_fifo_fg;


architecture implementation of async_fifo_fg is

 -- Function delarations 
    
    
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: GetMemType
    --
    -- Function Description:
    -- Generates the required integer value for the FG instance assignment
    -- of the C_MEMORY_TYPE parameter. Derived from
    -- the input memory type parameter C_USE_BLOCKMEM.
    -- 
    -- FIFO Generator values
    --   0 = Any
    --   1 = BRAM
    --   2 = Distributed Memory  
    --   3 = Shift Registers
    --
    -------------------------------------------------------------------
    function GetMemType (inputmemtype : integer) return integer is
    
      Variable memtype : Integer := 0;
      
    begin
    
       If (inputmemtype = 0) Then -- distributed Memory 
         memtype := 2;
       else
         memtype := 1;            -- BRAM
       End if;
      
      return(memtype);
      
    end function GetMemType;
    
                                    
    
  
  
  
  
  
  -- Constant Declarations  ----------------------------------------------
  
    
    Constant FAMILY_TO_USE       : string  := get_root_family(C_FAMILY);  -- function from family_support.vhd
    
    
    Constant FAMILY_NOT_SUPPORTED : boolean := (equalIgnoringCase(FAMILY_TO_USE, "nofamily"));
    
    Constant FAMILY_IS_SUPPORTED  : boolean := not(FAMILY_NOT_SUPPORTED);
    
    
    Constant FAM_IS_S3_V4_V5      : boolean := (equalIgnoringCase(FAMILY_TO_USE, "spartan3" ) or 
                                                equalIgnoringCase(FAMILY_TO_USE, "virtex4"  ) or 
                                                equalIgnoringCase(FAMILY_TO_USE, "virtex5")) and
                                                FAMILY_IS_SUPPORTED;
    
    Constant FAM_IS_NOT_S3_V4_V5  : boolean := not(FAM_IS_S3_V4_V5) and
                                               FAMILY_IS_SUPPORTED;
    
    
    

    -- Get the integer value for a Block memory type fifo generator call
    Constant FG_MEM_TYPE         : integer := GetMemType(C_USE_BLOCKMEM);
    
    
    -- Set the required integer value for the FG instance assignment
    -- of the C_IMPLEMENTATION_TYPE parameter. Derived from
    -- the input memory type parameter C_MEMORY_TYPE.
    --
    --  0 = Common Clock BRAM / Distributed RAM (Synchronous FIFO)
    --  1 = Common Clock Shift Register (Synchronous FIFO)
    --  2 = Independent Clock BRAM/Distributed RAM (Asynchronous FIFO)
    --  3 = Independent/Common Clock V4 Built In Memory -- not used in legacy fifo calls
    --  5 = Independent/Common Clock V5 Built in Memory  -- not used in legacy fifo calls
    --
    Constant FG_IMP_TYPE         : integer := 2;
    
    
    

begin --(architecture implementation)

 
 

 
   
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_NO_FAMILY
  --
  -- If Generate Description:
  --   This IfGen is implemented if an unsupported FPGA family
  -- is passed in on the C_FAMILY parameter,
  --
  ------------------------------------------------------------
  GEN_NO_FAMILY : if (FAMILY_NOT_SUPPORTED) generate
     
     begin
  
       
       
       -- synthesis translate_off
  
        
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: DO_ASSERTION
        --
        -- Process Description:
        -- Generate a simulation error assertion for an unsupported 
        -- FPGA family string passed in on the C_FAMILY parameter.
        --
        -------------------------------------------------------------
        DO_ASSERTION : process 
           begin
        
             -- Wait until second rising wr clock edge to issue assertion
             Wait until Wr_clk = '1';
             wait until Wr_clk = '0';
             Wait until Wr_clk = '1';
             
             -- Report an error in simulation environment
             assert FALSE report "********* UNSUPPORTED FPGA DEVICE! Check C_FAMILY parameter assignment!" 
                          severity ERROR;
  
             Wait; -- halt this process
             
           end process DO_ASSERTION; 
        
        
        
       -- synthesis translate_on
       


       
    
       -- Tie outputs to logic low or logic high as required
       Dout           <= (others => '0');  -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
       Full           <= '0'            ;  -- : out std_logic; 
       Empty          <= '1'            ;  -- : out std_logic; 
       Almost_full    <= '0'            ;  -- : out std_logic;  
       Almost_empty   <= '0'            ;  -- : out std_logic;  
       Wr_count       <= (others => '0');  -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
       Rd_count       <= (others => '0');  -- : out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
       Rd_ack         <= '0'            ;  -- : out std_logic;
       Rd_err         <= '1'            ;  -- : out std_logic;
       Wr_ack         <= '0'            ;  -- : out std_logic;
       Wr_err         <= '1'            ;  -- : out std_logic
   
     end generate GEN_NO_FAMILY;
 
 
  
   
   
   
   
   
   
   
   
 
 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: LEGACY_COREGEN_DEPTH
 --
 -- If Generate Description:
 --     This IfGen implements the FIFO Generator call where
 -- the User specified depth and count widths follow the 
 -- legacy CoreGen Async FIFO requirements of depth being 
 -- (2**N)-1 and the count widths set to reflect the (2**N)-1
 -- FIFO depth. 
 --
 -- Special Note:
 -- The legacy CoreGen Async FIFOs would only support fifo depths of (2**n)-1 
 -- and the Dcount widths were 1 less than if a full 2**n depth were supported.
 -- Thus legacy IP will be calling this wrapper with the (2**n)-1 FIFo depths
 -- specified and the Dcount widths smaller by 1 bit.
 -- This wrapper file has to account for this since the new FIFO Generator 
 -- does not follow this convention for Async FIFOs and expects depths to 
 -- be specified in full 2**n values.
 --
 ------------------------------------------------------------
 LEGACY_COREGEN_DEPTH : if (C_ALLOW_2N_DEPTH = 0 and
                            FAMILY_IS_SUPPORTED) generate
 
  -- IfGen Constant Declarations -------------
   
   -- See Special Note above for reasoning behind
   -- this adjustment of the requested FIFO depth and data count
   -- widths.
   Constant ADJUSTED_AFIFO_DEPTH : integer := C_FIFO_DEPTH+1;
   Constant ADJUSTED_RDCNT_WIDTH : integer := C_RD_COUNT_WIDTH;
   Constant ADJUSTED_WRCNT_WIDTH : integer := C_WR_COUNT_WIDTH;
   
   -- The programable thresholds are not used so this is housekeeping.
   Constant PROG_FULL_THRESH_ASSERT_VAL : integer := ADJUSTED_AFIFO_DEPTH-3;
   Constant PROG_FULL_THRESH_NEGATE_VAL : integer := ADJUSTED_AFIFO_DEPTH-4;
 
    
    -- The parameters C_RD_PNTR_WIDTH and C_WR_PNTR_WIDTH for Fifo_generator_v4_3 core 
    -- must be in the range of 4 thru 22.  The setting is dependant upon the 
    -- log2 function of the MIN and MAX FIFO DEPTH settings in coregen.  Since Async FIFOs
    -- previous to development of fifo generator do not support separate read and 
    -- write fifo widths (and depths dependant upon the widths) both of the pointer value 
    -- calculations below will use the parameter ADJUSTED_AFIFO_DEPTH.  The valid range for 
    -- the ADJUSTED_AFIFO_DEPTH is 16 to 65536 (the async FIFO range is 15 to 65,535...it 
    -- must be equal to (2^N-1;, N = 4 to 16) per DS232 November 11, 2004 - 
    -- Asynchronous FIFO v6.1)                            
    Constant ADJUSTED_RD_PNTR_WIDTH : integer range 4 to 22 := log2(ADJUSTED_AFIFO_DEPTH);
    Constant ADJUSTED_WR_PNTR_WIDTH : integer range 4 to 22 := log2(ADJUSTED_AFIFO_DEPTH);

 
    -- Constant zeros for programmable threshold inputs
    Constant PROG_RDTHRESH_ZEROS : std_logic_vector(ADJUSTED_RD_PNTR_WIDTH-1
                                   DOWNTO 0) := (OTHERS => '0');
    Constant PROG_WRTHRESH_ZEROS : std_logic_vector(ADJUSTED_WR_PNTR_WIDTH-1 
                                   DOWNTO 0) := (OTHERS => '0');
    
      
  -- IfGen Signal Declarations --------------
  
   Signal sig_full_fifo_rdcnt : std_logic_vector(ADJUSTED_RDCNT_WIDTH-1 DOWNTO 0);
   Signal sig_full_fifo_wrcnt : std_logic_vector(ADJUSTED_WRCNT_WIDTH-1 DOWNTO 0);


 
   begin
    
     -- Rip the LS bits of the write data count and assign to Write Count 
     -- output port  
     Wr_count  <= sig_full_fifo_wrcnt(C_WR_COUNT_WIDTH-1 downto 0);
 
     -- Rip the LS bits of the read data count and assign to Read Count 
     -- output port  
     Rd_count  <= sig_full_fifo_rdcnt(C_RD_COUNT_WIDTH-1 downto 0);
 
 
     
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: V5_AND_EARLIER
     --
     -- If Generate Description:
     --  This IFGen Implements the FIFO using FIFO Generator 4.3
     --  for FPGA Families earlier than Virtex-6 and Spartan-6.
     --
     ------------------------------------------------------------
     V5_AND_EARLIER : if (FAM_IS_S3_V4_V5) generate
     
       begin

         -------------------------------------------------------------------------------
         -- Instantiate the generalized FIFO Generator instance
         --
         -- NOTE:
         -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
         -- This is a Coregen FIFO Generator Call module for 
         -- legacy BRAM implementations of an Async FIFo.
         --
         -------------------------------------------------------------------------------
         I_ASYNC_FIFO_BRAM : fifo_generator_v4_3
            generic map(
              C_COMMON_CLOCK                 =>  0,   
              C_COUNT_TYPE                   =>  0,   
              C_DATA_COUNT_WIDTH             =>  ADJUSTED_WRCNT_WIDTH,   
              C_DEFAULT_VALUE                =>  "BlankString",          
              C_DIN_WIDTH                    =>  C_DATA_WIDTH,   
              C_DOUT_RST_VAL                 =>  "0",   
              C_DOUT_WIDTH                   =>  C_DATA_WIDTH,   
              C_ENABLE_RLOCS                 =>  C_ENABLE_RLOCS,   
              C_FAMILY                       =>  FAMILY_TO_USE,             
              C_HAS_ALMOST_EMPTY             =>  C_HAS_ALMOST_EMPTY,   
              C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,   
              C_HAS_BACKUP                   =>  0,   
              C_HAS_DATA_COUNT               =>  0,   
              C_HAS_MEMINIT_FILE             =>  0,   
              C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,   
              C_HAS_RD_DATA_COUNT            =>  C_HAS_RD_COUNT,   
              C_HAS_RD_RST                   =>  0,   
              C_HAS_RST                      =>  1,   
              C_HAS_SRST                     =>  0,   
              C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,   
              C_HAS_VALID                    =>  C_HAS_RD_ACK,   
              C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,   
              C_HAS_WR_DATA_COUNT            =>  C_HAS_WR_COUNT,   
              C_HAS_WR_RST                   =>  0,   
              C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,     
              C_INIT_WR_PNTR_VAL             =>  0,   
              C_MEMORY_TYPE                  =>  FG_MEM_TYPE,      
              C_MIF_FILE_NAME                =>  "BlankString",    
              C_OPTIMIZATION_MODE            =>  0,   
              C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,   
              C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,  ----0, Fixed CR#658129   
              C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,   ----1, Fixed CR#658129   
              C_PRIM_FIFO_TYPE               =>  "512x36",  -- only used for V5 Hard FIFO   
              C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,   
              C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,   
              C_PROG_EMPTY_TYPE              =>  0,   
              C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,   
              C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,   
              C_PROG_FULL_TYPE               =>  0,   
              C_RD_DATA_COUNT_WIDTH          =>  ADJUSTED_RDCNT_WIDTH,   
              C_RD_DEPTH                     =>  ADJUSTED_AFIFO_DEPTH,   
              C_RD_FREQ                      =>  1,   
              C_RD_PNTR_WIDTH                =>  ADJUSTED_RD_PNTR_WIDTH,   
              C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,   
              C_USE_DOUT_RST                 =>  1,   
              C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG, ----0, Fixed CR#658129  
              C_USE_FIFO16_FLAGS             =>  0,   
              C_USE_FWFT_DATA_COUNT          =>  0,   
              C_VALID_LOW                    =>  0,   
              C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,   
              C_WR_DATA_COUNT_WIDTH          =>  ADJUSTED_WRCNT_WIDTH,   
              C_WR_DEPTH                     =>  ADJUSTED_AFIFO_DEPTH,   
              C_WR_FREQ                      =>  1,   
              C_WR_PNTR_WIDTH                =>  ADJUSTED_WR_PNTR_WIDTH,   
              C_WR_RESPONSE_LATENCY          =>  1,   
              C_USE_ECC                      =>  0,   
              C_FULL_FLAGS_RST_VAL           =>  0,   
              C_HAS_INT_CLK                  =>  0,                                                   
              C_MSGON_VAL                    =>  1 --cannot find info on this, leave at default : integer := 1
             )
            port map (
              CLK                       =>  '0',                  
              BACKUP                    =>  '0',                  
              BACKUP_MARKER             =>  '0',                  
              DIN                       =>  Din,                  
              PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  
              PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  
              PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  
              PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  
              PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  
              PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  
              RD_CLK                    =>  Rd_clk,               
              RD_EN                     =>  Rd_en,                
              RD_RST                    =>  Ainit,                
              RST                       =>  Ainit,                
              SRST                      =>  '0',                  
              WR_CLK                    =>  Wr_clk,               
              WR_EN                     =>  Wr_en,                
              WR_RST                    =>  Ainit,                
              INT_CLK                   =>  '0',                  

              ALMOST_EMPTY              =>  Almost_empty,         
              ALMOST_FULL               =>  Almost_full,          
              DATA_COUNT                =>  open,                 
              DOUT                      =>  Dout,                 
              EMPTY                     =>  Empty,                
              FULL                      =>  Full,                 
              OVERFLOW                  =>  Wr_err,               
              PROG_EMPTY                =>  open,                 
              PROG_FULL                 =>  open,                 
              VALID                     =>  Rd_ack,               
              RD_DATA_COUNT             =>  sig_full_fifo_rdcnt,  
              UNDERFLOW                 =>  Rd_err,               
              WR_ACK                    =>  Wr_ack,               
              WR_DATA_COUNT             =>  sig_full_fifo_wrcnt,  
              SBITERR                   =>  open,                 
              DBITERR                   =>  open                  
             );
           
       end generate V5_AND_EARLIER;
  




     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: V6_S6_AND_LATER
     --
     -- If Generate Description:
     --  This IFGen Implements the FIFO using fifo_generator_v9_1
     --  for FPGA Families that are Virtex-6, Spartan-6, and later.
     --
     ------------------------------------------------------------
     V6_S6_AND_LATER : if (FAM_IS_NOT_S3_V4_V5) generate
     
       begin

         -------------------------------------------------------------------------------
         -- Instantiate the generalized FIFO Generator instance
         --
         -- NOTE:
         -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
         -- This is a Coregen FIFO Generator Call module for 
         -- legacy BRAM implementations of an Async FIFo.
         --
         -------------------------------------------------------------------------------
         I_ASYNC_FIFO_BRAM : fifo_generator_v9_1
            generic map(
              C_COMMON_CLOCK                 =>  0,   
              C_COUNT_TYPE                   =>  0,   
              C_DATA_COUNT_WIDTH             =>  ADJUSTED_WRCNT_WIDTH,   
              C_DEFAULT_VALUE                =>  "BlankString",          
              C_DIN_WIDTH                    =>  C_DATA_WIDTH,   
              C_DOUT_RST_VAL                 =>  "0",   
              C_DOUT_WIDTH                   =>  C_DATA_WIDTH,   
              C_ENABLE_RLOCS                 =>  C_ENABLE_RLOCS,   
              C_FAMILY                       =>  FAMILY_TO_USE,             
              C_FULL_FLAGS_RST_VAL           =>  0,   
              C_HAS_ALMOST_EMPTY             =>  C_HAS_ALMOST_EMPTY,   
              C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,   
              C_HAS_BACKUP                   =>  0,   
              C_HAS_DATA_COUNT               =>  0,   
              C_HAS_INT_CLK                  =>  0,                                                   
              C_HAS_MEMINIT_FILE             =>  0,   
              C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,   
              C_HAS_RD_DATA_COUNT            =>  C_HAS_RD_COUNT,   
              C_HAS_RD_RST                   =>  0,   
              C_HAS_RST                      =>  1,   
              C_HAS_SRST                     =>  0,   
              C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,   
              C_HAS_VALID                    =>  C_HAS_RD_ACK,   
              C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,   
              C_HAS_WR_DATA_COUNT            =>  C_HAS_WR_COUNT,   
              C_HAS_WR_RST                   =>  0,   
              C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,     
              C_INIT_WR_PNTR_VAL             =>  0,   
              C_MEMORY_TYPE                  =>  FG_MEM_TYPE,      
              C_MIF_FILE_NAME                =>  "BlankString",    
              C_OPTIMIZATION_MODE            =>  0,   
              C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,   
              C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,   ----1, Fixed CR#658129   
              C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,    ----0, Fixed CR#658129   
              C_PRIM_FIFO_TYPE               =>  "512x36",  -- only used for V5 Hard FIFO   
              C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,   
              C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,   
              C_PROG_EMPTY_TYPE              =>  0,   
              C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,   
              C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,   
              C_PROG_FULL_TYPE               =>  0,   
              C_RD_DATA_COUNT_WIDTH          =>  ADJUSTED_RDCNT_WIDTH,   
              C_RD_DEPTH                     =>  ADJUSTED_AFIFO_DEPTH,   
              C_RD_FREQ                      =>  1,   
              C_RD_PNTR_WIDTH                =>  ADJUSTED_RD_PNTR_WIDTH,   
              C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,   
              C_USE_DOUT_RST                 =>  1,   
              C_USE_ECC                      =>  0,   
              C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG, ----0, Fixed CR#658129   
              C_USE_FIFO16_FLAGS             =>  0,   
              C_USE_FWFT_DATA_COUNT          =>  0,   
              C_VALID_LOW                    =>  0,   
              C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,   
              C_WR_DATA_COUNT_WIDTH          =>  ADJUSTED_WRCNT_WIDTH,   
              C_WR_DEPTH                     =>  ADJUSTED_AFIFO_DEPTH,   
              C_WR_FREQ                      =>  1,   
              C_WR_PNTR_WIDTH                =>  ADJUSTED_WR_PNTR_WIDTH,   
              C_WR_RESPONSE_LATENCY          =>  1,   
              C_MSGON_VAL                    =>  1,
              C_ENABLE_RST_SYNC              =>  1,  
              C_ERROR_INJECTION_TYPE         =>  0,
              

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
              C_AXI_ID_WIDTH                 =>  4 ,    --           : integer := 0;
              C_AXI_ADDR_WIDTH               =>  32,    --           : integer := 0;
              C_AXI_DATA_WIDTH               =>  64,    --           : integer := 0;
              C_HAS_AXI_AWUSER               =>  0 ,    --           : integer := 0;
              C_HAS_AXI_WUSER                =>  0 ,    --           : integer := 0;
              C_HAS_AXI_BUSER                =>  0 ,    --           : integer := 0;
              C_HAS_AXI_ARUSER               =>  0 ,    --           : integer := 0;
              C_HAS_AXI_RUSER                =>  0 ,    --           : integer := 0;
              C_AXI_ARUSER_WIDTH             =>  1 ,    --           : integer := 0;
              C_AXI_AWUSER_WIDTH             =>  1 ,    --           : integer := 0;
              C_AXI_WUSER_WIDTH              =>  1 ,    --           : integer := 0;
              C_AXI_BUSER_WIDTH              =>  1 ,    --           : integer := 0;
              C_AXI_RUSER_WIDTH              =>  1 ,    --           : integer := 0;
                                                 
              -- AXI Streaming
              C_HAS_AXIS_TDATA               =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TID                 =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TDEST               =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TUSER               =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TREADY              =>  1 ,    --           : integer := 0;
              C_HAS_AXIS_TLAST               =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TSTRB               =>  0 ,    --           : integer := 0;
              C_HAS_AXIS_TKEEP               =>  0 ,    --           : integer := 0;
              C_AXIS_TDATA_WIDTH             =>  64,    --           : integer := 1;
              C_AXIS_TID_WIDTH               =>  8 ,    --           : integer := 1;
              C_AXIS_TDEST_WIDTH             =>  4 ,    --           : integer := 1;
              C_AXIS_TUSER_WIDTH             =>  4 ,    --           : integer := 1;
              C_AXIS_TSTRB_WIDTH             =>  4 ,    --           : integer := 1;
              C_AXIS_TKEEP_WIDTH             =>  4 ,    --           : integer := 1;

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
              C_DIN_WIDTH_WACH                    =>  32,    --      : integer := 1;
              C_DIN_WIDTH_WDCH                    =>  64,    --      : integer := 1;
              C_DIN_WIDTH_WRCH                    =>  2 ,    --      : integer := 1;
              C_DIN_WIDTH_RACH                    =>  32,    --      : integer := 1;
              C_DIN_WIDTH_RDCH                    =>  64,    --      : integer := 1;
              C_DIN_WIDTH_AXIS                    =>  1 ,    --      : integer := 1;

              C_WR_DEPTH_WACH                     =>  16  ,   --      : integer := 16;
              C_WR_DEPTH_WDCH                     =>  1024,   --      : integer := 16;
              C_WR_DEPTH_WRCH                     =>  16  ,   --      : integer := 16;
              C_WR_DEPTH_RACH                     =>  16  ,   --      : integer := 16;
              C_WR_DEPTH_RDCH                     =>  1024,   --      : integer := 16;
              C_WR_DEPTH_AXIS                     =>  1024,   --      : integer := 16;

              C_WR_PNTR_WIDTH_WACH                =>  4 ,    --      : integer := 4;
              C_WR_PNTR_WIDTH_WDCH                =>  10,    --      : integer := 4;
              C_WR_PNTR_WIDTH_WRCH                =>  4 ,    --      : integer := 4;
              C_WR_PNTR_WIDTH_RACH                =>  4 ,    --      : integer := 4;
              C_WR_PNTR_WIDTH_RDCH                =>  10,    --      : integer := 4;
              C_WR_PNTR_WIDTH_AXIS                =>  10,    --      : integer := 4;

              C_HAS_DATA_COUNTS_WACH              =>  0,    --      : integer := 0;
              C_HAS_DATA_COUNTS_WDCH              =>  0,    --      : integer := 0;
              C_HAS_DATA_COUNTS_WRCH              =>  0,    --      : integer := 0;
              C_HAS_DATA_COUNTS_RACH              =>  0,    --      : integer := 0;
              C_HAS_DATA_COUNTS_RDCH              =>  0,    --      : integer := 0;
              C_HAS_DATA_COUNTS_AXIS              =>  0,    --      : integer := 0;

              C_HAS_PROG_FLAGS_WACH               =>  0,    --      : integer := 0;
              C_HAS_PROG_FLAGS_WDCH               =>  0,    --      : integer := 0;
              C_HAS_PROG_FLAGS_WRCH               =>  0,    --      : integer := 0;
              C_HAS_PROG_FLAGS_RACH               =>  0,    --      : integer := 0;
              C_HAS_PROG_FLAGS_RDCH               =>  0,    --      : integer := 0;
              C_HAS_PROG_FLAGS_AXIS               =>  0,    --      : integer := 0;

              C_PROG_FULL_TYPE_WACH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_WDCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_WRCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_RACH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_RDCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_AXIS               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WACH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WDCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WRCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_RACH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_RDCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_AXIS  =>  1023,    --      : integer := 0;

              C_PROG_EMPTY_TYPE_WACH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_WDCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_WRCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_RACH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_RDCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_AXIS              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS =>  1022,    --      : integer := 0;

              C_REG_SLICE_MODE_WACH               =>  0,    --      : integer := 0;
              C_REG_SLICE_MODE_WDCH               =>  0,    --      : integer := 0;
              C_REG_SLICE_MODE_WRCH               =>  0,    --      : integer := 0;
              C_REG_SLICE_MODE_RACH               =>  0,    --      : integer := 0;
              C_REG_SLICE_MODE_RDCH               =>  0,    --      : integer := 0;
              C_REG_SLICE_MODE_AXIS               =>  0     --      : integer := 0

             )
            port map (
              BACKUP                    =>  '0',                  
              BACKUP_MARKER             =>  '0',                  
              CLK                       =>  '0',                  
              RST                       =>  Ainit,                
              SRST                      =>  '0',                  
              WR_CLK                    =>  Wr_clk,               
              WR_RST                    =>  Ainit,                
              RD_CLK                    =>  Rd_clk,               
              RD_RST                    =>  Ainit,                
              DIN                       =>  Din,                  
              WR_EN                     =>  Wr_en,                
              RD_EN                     =>  Rd_en,                
              PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  
              PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  
              PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  
              PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  
              PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  
              PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  
              INT_CLK                   =>  '0',                  
              INJECTDBITERR             =>  '0', -- new FG 5.1/5.2    
              INJECTSBITERR             =>  '0', -- new FG 5.1/5.2    

              DOUT                      =>  Dout,                 
              FULL                      =>  Full,                 
              ALMOST_FULL               =>  Almost_full,          
              WR_ACK                    =>  Wr_ack,               
              OVERFLOW                  =>  Wr_err,               
              EMPTY                     =>  Empty,                
              ALMOST_EMPTY              =>  Almost_empty,         
              VALID                     =>  Rd_ack,               
              UNDERFLOW                 =>  Rd_err,               
              DATA_COUNT                =>  open,                 
              RD_DATA_COUNT             =>  sig_full_fifo_rdcnt,  
              WR_DATA_COUNT             =>  sig_full_fifo_wrcnt,  
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
              AXI_AW_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_AW_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';


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
              AXI_W_PROG_FULL          =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_W_PROG_EMPTY         =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_B_PROG_FULL          =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_B_PROG_EMPTY         =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_AR_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_AR_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_R_PROG_FULL         =>  open,                 --         : OUT STD_LOGIC := '0';
              AXI_R_PROG_EMPTY        =>  open,                 --         : OUT STD_LOGIC := '1';

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
              AXIS_UNDERFLOW          =>  open,                 --         : OUT std_logic
              AXIS_PROG_FULL          =>  open,                 --         : OUT STD_LOGIC := '0';
              AXIS_PROG_EMPTY         =>  open                 --         : OUT STD_LOGIC := '1';

             
             );

       
       
       
       end generate V6_S6_AND_LATER;
   
   

 
 
    end generate LEGACY_COREGEN_DEPTH;
    
    
    
    
    
    
    
   
   
   
   
 

 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: USE_2N_DEPTH
 --
 -- If Generate Description:
 --     This IfGen implements the FIFO Generator call where
 -- the User may specify depth and count widths of 2**N 
 -- for Async FIFOs The associated count widths are set to 
 -- reflect the 2**N FIFO depth.
 --
 ------------------------------------------------------------
 USE_2N_DEPTH : if (C_ALLOW_2N_DEPTH = 1 and
                    FAMILY_IS_SUPPORTED) generate
 
    -- The programable thresholds are not used so this is housekeeping.
    Constant PROG_FULL_THRESH_ASSERT_VAL : integer := C_FIFO_DEPTH-3;
    Constant PROG_FULL_THRESH_NEGATE_VAL : integer := C_FIFO_DEPTH-4;
 
    
    Constant RD_PNTR_WIDTH : integer range 4 to 22 := log2(C_FIFO_DEPTH);
    Constant WR_PNTR_WIDTH : integer range 4 to 22 := log2(C_FIFO_DEPTH);
    
 
    -- Constant zeros for programmable threshold inputs
    Constant PROG_RDTHRESH_ZEROS : std_logic_vector(RD_PNTR_WIDTH-1
                                   DOWNTO 0) := (OTHERS => '0');
    Constant PROG_WRTHRESH_ZEROS : std_logic_vector(WR_PNTR_WIDTH-1 
                                   DOWNTO 0) := (OTHERS => '0');
    
    
    
    
    
  
  -- Signals Declarations
    Signal sig_full_fifo_rdcnt : std_logic_vector(C_RD_COUNT_WIDTH-1 DOWNTO 0);
    Signal sig_full_fifo_wrcnt : std_logic_vector(C_WR_COUNT_WIDTH-1 DOWNTO 0);


    begin
    
      -- Rip the LS bits of the write data count and assign to Write Count 
      -- output port  
      Wr_count  <= sig_full_fifo_wrcnt(C_WR_COUNT_WIDTH-1 downto 0);
   
      -- Rip the LS bits of the read data count and assign to Read Count 
      -- output port  
      Rd_count  <= sig_full_fifo_rdcnt(C_RD_COUNT_WIDTH-1 downto 0);
 
 
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: V5_AND_EARLIER
     --
     -- If Generate Description:
     --  This IFGen Implements the FIFO using FIFO Generator 4.3
     --  for FPGA Families earlier than Virtex-6 and Spartan-6.
     --
     ------------------------------------------------------------
     V5_AND_EARLIER : if (FAM_IS_S3_V4_V5) generate
     
       begin

         -------------------------------------------------------------------------------
         -- Instantiate the generalized FIFO Generator instance
         --
         -- NOTE:
         -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
         -- This is a Coregen FIFO Generator Call module for 
         -- legacy BRAM implementations of an Async FIFo.
         --
         -------------------------------------------------------------------------------
         I_ASYNC_FIFO_BRAM : fifo_generator_v4_3
            generic map(
              C_COMMON_CLOCK                 =>  0,                                              
              C_COUNT_TYPE                   =>  0,                                              
              C_DATA_COUNT_WIDTH             =>  C_WR_COUNT_WIDTH,                               
              C_DEFAULT_VALUE                =>  "BlankString",                                  
              C_DIN_WIDTH                    =>  C_DATA_WIDTH,                                   
              C_DOUT_RST_VAL                 =>  "0",                                            
              C_DOUT_WIDTH                   =>  C_DATA_WIDTH,                                   
              C_ENABLE_RLOCS                 =>  C_ENABLE_RLOCS,                                 
              C_FAMILY                       =>  FAMILY_TO_USE,                                       
              C_HAS_ALMOST_EMPTY             =>  C_HAS_ALMOST_EMPTY,                             
              C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,                              
              C_HAS_BACKUP                   =>  0,                                              
              C_HAS_DATA_COUNT               =>  0,                                              
              C_HAS_MEMINIT_FILE             =>  0,                                              
              C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,                                   
              C_HAS_RD_DATA_COUNT            =>  C_HAS_RD_COUNT,                                 
              C_HAS_RD_RST                   =>  0,                                              
              C_HAS_RST                      =>  1,                                              
              C_HAS_SRST                     =>  0,                                              
              C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,                                   
              C_HAS_VALID                    =>  C_HAS_RD_ACK,                                   
              C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,                                   
              C_HAS_WR_DATA_COUNT            =>  C_HAS_WR_COUNT,                                 
              C_HAS_WR_RST                   =>  0,                                              
              C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,                                    
              C_INIT_WR_PNTR_VAL             =>  0,                                              
              C_MEMORY_TYPE                  =>  FG_MEM_TYPE,                                    
              C_MIF_FILE_NAME                =>  "BlankString",                                  
              C_OPTIMIZATION_MODE            =>  0,                                              
              C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,                                   
              C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,    ----0, Fixed CR#658129                                              
              C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,   ----1, Fixed CR#658129                                              
              C_PRIM_FIFO_TYPE               =>  "512x36",  -- only used for V5 Hard FIFO        
              C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,                                              
              C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,                                              
              C_PROG_EMPTY_TYPE              =>  0,                                              
              C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,                    
              C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,                    
              C_PROG_FULL_TYPE               =>  0,                                              
              C_RD_DATA_COUNT_WIDTH          =>  C_RD_COUNT_WIDTH,                               
              C_RD_DEPTH                     =>  C_FIFO_DEPTH,                                   
              C_RD_FREQ                      =>  1,                                              
              C_RD_PNTR_WIDTH                =>  RD_PNTR_WIDTH,                                  
              C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,                                   
              C_USE_DOUT_RST                 =>  1,                                              
              C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG, ----0, Fixed CR#658129                                              
              C_USE_FIFO16_FLAGS             =>  0,                                              
              C_USE_FWFT_DATA_COUNT          =>  0,                                              
              C_VALID_LOW                    =>  0,                                              
              C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,                                   
              C_WR_DATA_COUNT_WIDTH          =>  C_WR_COUNT_WIDTH,                               
              C_WR_DEPTH                     =>  C_FIFO_DEPTH,                                   
              C_WR_FREQ                      =>  1,                                              
              C_WR_PNTR_WIDTH                =>  WR_PNTR_WIDTH,                                  
              C_WR_RESPONSE_LATENCY          =>  1,                                              
              C_USE_ECC                      =>  0,                                              
              C_FULL_FLAGS_RST_VAL           =>  0,                                              
              C_HAS_INT_CLK                  =>  0,                                              
              C_MSGON_VAL                    =>  1 
             )
            port map (
              CLK                       =>  '0',                  -- : IN  std_logic := '0';
              BACKUP                    =>  '0',                  -- : IN  std_logic := '0';
              BACKUP_MARKER             =>  '0',                  -- : IN  std_logic := '0';
              DIN                       =>  Din,                  -- : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              RD_CLK                    =>  Rd_clk,               -- : IN  std_logic := '0';
              RD_EN                     =>  Rd_en,                -- : IN  std_logic := '0';
              RD_RST                    =>  Ainit,                -- : IN  std_logic := '0';
              RST                       =>  Ainit,                -- : IN  std_logic := '0';
              SRST                      =>  '0',                  -- : IN  std_logic := '0';
              WR_CLK                    =>  Wr_clk,               -- : IN  std_logic := '0';
              WR_EN                     =>  Wr_en,                -- : IN  std_logic := '0';
              WR_RST                    =>  Ainit,                -- : IN  std_logic := '0';
              INT_CLK                   =>  '0',                  -- : IN  std_logic := '0';

              ALMOST_EMPTY              =>  Almost_empty,         -- : OUT std_logic;
              ALMOST_FULL               =>  Almost_full,          -- : OUT std_logic;
              DATA_COUNT                =>  open,                 -- : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
              DOUT                      =>  Dout,                 -- : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
              EMPTY                     =>  Empty,                -- : OUT std_logic;
              FULL                      =>  Full,                 -- : OUT std_logic;
              OVERFLOW                  =>  Rd_err,               -- : OUT std_logic;
              PROG_EMPTY                =>  open,                 -- : OUT std_logic;
              PROG_FULL                 =>  open,                 -- : OUT std_logic;
              VALID                     =>  Rd_ack,               -- : OUT std_logic;
              RD_DATA_COUNT             =>  sig_full_fifo_rdcnt,  -- : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
              UNDERFLOW                 =>  Wr_err,               -- : OUT std_logic;
              WR_ACK                    =>  Wr_ack,               -- : OUT std_logic;
              WR_DATA_COUNT             =>  sig_full_fifo_wrcnt,  -- : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
              SBITERR                   =>  open,                 -- : OUT std_logic;
              DBITERR                   =>  open                  -- : OUT std_logic
             );
           
       end generate V5_AND_EARLIER;
  




     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: V6_S6_AND_LATER
     --
     -- If Generate Description:
     --  This IFGen Implements the FIFO using fifo_generator_v9_1
     --  for FPGA Families that are Virtex-6, Spartan-6, and later.
     --
     ------------------------------------------------------------
     V6_S6_AND_LATER : if (FAM_IS_NOT_S3_V4_V5) generate
     
       begin

         -------------------------------------------------------------------------------
         -- Instantiate the generalized FIFO Generator instance
         --
         -- NOTE:
         -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
         -- This is a Coregen FIFO Generator Call module for 
         -- legacy BRAM implementations of an Async FIFo.
         --
         -------------------------------------------------------------------------------
         I_ASYNC_FIFO_BRAM : fifo_generator_v9_1
            generic map(
              C_COMMON_CLOCK                 =>  0,                                              
              C_COUNT_TYPE                   =>  0,                                              
              C_DATA_COUNT_WIDTH             =>  C_WR_COUNT_WIDTH,                               
              C_DEFAULT_VALUE                =>  "BlankString",                                  
              C_DIN_WIDTH                    =>  C_DATA_WIDTH,                                   
              C_DOUT_RST_VAL                 =>  "0",                                            
              C_DOUT_WIDTH                   =>  C_DATA_WIDTH,                                   
              C_ENABLE_RLOCS                 =>  C_ENABLE_RLOCS,                                 
              C_FAMILY                       =>  FAMILY_TO_USE,                                       
              C_FULL_FLAGS_RST_VAL           =>  0,                                              
              C_HAS_ALMOST_EMPTY             =>  C_HAS_ALMOST_EMPTY,                             
              C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,                              
              C_HAS_BACKUP                   =>  0,                                              
              C_HAS_DATA_COUNT               =>  0,                                              
              C_HAS_INT_CLK                  =>  0,                                                      
              C_HAS_MEMINIT_FILE             =>  0,                                              
              C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,                                   
              C_HAS_RD_DATA_COUNT            =>  C_HAS_RD_COUNT,                                 
              C_HAS_RD_RST                   =>  0,                                              
              C_HAS_RST                      =>  1,                                              
              C_HAS_SRST                     =>  0,                                              
              C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,                                   
              C_HAS_VALID                    =>  C_HAS_RD_ACK,                                   
              C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,                                   
              C_HAS_WR_DATA_COUNT            =>  C_HAS_WR_COUNT,                                 
              C_HAS_WR_RST                   =>  0,                                              
              C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,                                    
              C_INIT_WR_PNTR_VAL             =>  0,                                              
              C_MEMORY_TYPE                  =>  FG_MEM_TYPE,                                    
              C_MIF_FILE_NAME                =>  "BlankString",                                  
              C_OPTIMIZATION_MODE            =>  0,                                              
              C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,                                   
              C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,   ----1, Fixed CR#658129                                              
              C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,    ----0, Fixed CR#658129                                              
              C_PRIM_FIFO_TYPE               =>  "512x36",  -- only used for V5 Hard FIFO        
              C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,                                              
              C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,                                              
              C_PROG_EMPTY_TYPE              =>  0,                                              
              C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,                    
              C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,                    
              C_PROG_FULL_TYPE               =>  0,                                              
              C_RD_DATA_COUNT_WIDTH          =>  C_RD_COUNT_WIDTH,                               
              C_RD_DEPTH                     =>  C_FIFO_DEPTH,                                   
              C_RD_FREQ                      =>  1,                                              
              C_RD_PNTR_WIDTH                =>  RD_PNTR_WIDTH,                                  
              C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,                                   
              C_USE_DOUT_RST                 =>  1,                                              
              C_USE_ECC                      =>  0,                                              
              C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG, ----0, Fixed CR#658129                                              
              C_USE_FIFO16_FLAGS             =>  0,                                              
              C_USE_FWFT_DATA_COUNT          =>  0,                                              
              C_VALID_LOW                    =>  0,                                              
              C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,                                   
              C_WR_DATA_COUNT_WIDTH          =>  C_WR_COUNT_WIDTH,                               
              C_WR_DEPTH                     =>  C_FIFO_DEPTH,                                   
              C_WR_FREQ                      =>  1,                                              
              C_WR_PNTR_WIDTH                =>  WR_PNTR_WIDTH,                                  
              C_WR_RESPONSE_LATENCY          =>  1,                                              
              C_MSGON_VAL                    =>  1,
              C_ENABLE_RST_SYNC              =>  1,  
              C_ERROR_INJECTION_TYPE         =>  0,
              

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
              C_AXI_ID_WIDTH                 =>  4 ,    --          : integer := 0;
              C_AXI_ADDR_WIDTH               =>  32,    --          : integer := 0;
              C_AXI_DATA_WIDTH               =>  64,    --          : integer := 0;
              C_HAS_AXI_AWUSER               =>  0 ,    --          : integer := 0;
              C_HAS_AXI_WUSER                =>  0 ,    --          : integer := 0;
              C_HAS_AXI_BUSER                =>  0 ,    --          : integer := 0;
              C_HAS_AXI_ARUSER               =>  0 ,    --          : integer := 0;
              C_HAS_AXI_RUSER                =>  0 ,    --          : integer := 0;
              C_AXI_ARUSER_WIDTH             =>  1 ,    --          : integer := 0;
              C_AXI_AWUSER_WIDTH             =>  1 ,    --          : integer := 0;
              C_AXI_WUSER_WIDTH              =>  1 ,    --          : integer := 0;
              C_AXI_BUSER_WIDTH              =>  1 ,    --          : integer := 0;
              C_AXI_RUSER_WIDTH              =>  1 ,    --          : integer := 0;
                                                 
              -- AXI Streaming
              C_HAS_AXIS_TDATA               =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TID                 =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TDEST               =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TUSER               =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TREADY              =>  1 ,    --          : integer := 0;
              C_HAS_AXIS_TLAST               =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TSTRB               =>  0 ,    --          : integer := 0;
              C_HAS_AXIS_TKEEP               =>  0 ,    --          : integer := 0;
              C_AXIS_TDATA_WIDTH             =>  64,    --          : integer := 1;
              C_AXIS_TID_WIDTH               =>  8 ,    --          : integer := 1;
              C_AXIS_TDEST_WIDTH             =>  4 ,    --          : integer := 1;
              C_AXIS_TUSER_WIDTH             =>  4 ,    --          : integer := 1;
              C_AXIS_TSTRB_WIDTH             =>  4 ,    --          : integer := 1;
              C_AXIS_TKEEP_WIDTH             =>  4 ,    --          : integer := 1;

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
              C_DIN_WIDTH_WACH                    =>  32,      --      : integer := 1;
              C_DIN_WIDTH_WDCH                    =>  64,      --      : integer := 1;
              C_DIN_WIDTH_WRCH                    =>  2 ,      --      : integer := 1;
              C_DIN_WIDTH_RACH                    =>  32,      --      : integer := 1;
              C_DIN_WIDTH_RDCH                    =>  64,      --      : integer := 1;
              C_DIN_WIDTH_AXIS                    =>  1 ,      --      : integer := 1;

              C_WR_DEPTH_WACH                     =>  16  ,    --      : integer := 16;
              C_WR_DEPTH_WDCH                     =>  1024,    --      : integer := 16;
              C_WR_DEPTH_WRCH                     =>  16  ,    --      : integer := 16;
              C_WR_DEPTH_RACH                     =>  16  ,    --      : integer := 16;
              C_WR_DEPTH_RDCH                     =>  1024,    --      : integer := 16;
              C_WR_DEPTH_AXIS                     =>  1024,    --      : integer := 16;

              C_WR_PNTR_WIDTH_WACH                =>  4 ,      --      : integer := 4;
              C_WR_PNTR_WIDTH_WDCH                =>  10,      --      : integer := 4;
              C_WR_PNTR_WIDTH_WRCH                =>  4 ,      --      : integer := 4;
              C_WR_PNTR_WIDTH_RACH                =>  4 ,      --      : integer := 4;
              C_WR_PNTR_WIDTH_RDCH                =>  10,      --      : integer := 4;
              C_WR_PNTR_WIDTH_AXIS                =>  10,      --      : integer := 4;

              C_HAS_DATA_COUNTS_WACH              =>  0,       --      : integer := 0;
              C_HAS_DATA_COUNTS_WDCH              =>  0,       --      : integer := 0;
              C_HAS_DATA_COUNTS_WRCH              =>  0,       --      : integer := 0;
              C_HAS_DATA_COUNTS_RACH              =>  0,       --      : integer := 0;
              C_HAS_DATA_COUNTS_RDCH              =>  0,       --      : integer := 0;
              C_HAS_DATA_COUNTS_AXIS              =>  0,       --      : integer := 0;

              C_HAS_PROG_FLAGS_WACH               =>  0,       --      : integer := 0;
              C_HAS_PROG_FLAGS_WDCH               =>  0,       --      : integer := 0;
              C_HAS_PROG_FLAGS_WRCH               =>  0,       --      : integer := 0;
              C_HAS_PROG_FLAGS_RACH               =>  0,       --      : integer := 0;
              C_HAS_PROG_FLAGS_RDCH               =>  0,       --      : integer := 0;
              C_HAS_PROG_FLAGS_AXIS               =>  0,       --      : integer := 0;

              C_PROG_FULL_TYPE_WACH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_WDCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_WRCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_RACH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_RDCH               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_TYPE_AXIS               =>  5   ,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WACH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WDCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_WRCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_RACH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_RDCH  =>  1023,    --      : integer := 0;
              C_PROG_FULL_THRESH_ASSERT_VAL_AXIS  =>  1023,    --      : integer := 0;

              C_PROG_EMPTY_TYPE_WACH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_WDCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_WRCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_RACH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_RDCH              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_TYPE_AXIS              =>  5   ,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH =>  1022,    --      : integer := 0;
              C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS =>  1022,    --      : integer := 0;

              C_REG_SLICE_MODE_WACH               =>  0,       --      : integer := 0;
              C_REG_SLICE_MODE_WDCH               =>  0,       --      : integer := 0;
              C_REG_SLICE_MODE_WRCH               =>  0,       --      : integer := 0;
              C_REG_SLICE_MODE_RACH               =>  0,       --      : integer := 0;
              C_REG_SLICE_MODE_RDCH               =>  0,       --      : integer := 0;
              C_REG_SLICE_MODE_AXIS               =>  0        --      : integer := 0

             )
            port map (
              BACKUP                    =>  '0',                  -- : IN  std_logic := '0';
              BACKUP_MARKER             =>  '0',                  -- : IN  std_logic := '0';
              CLK                       =>  '0',                  -- : IN  std_logic := '0';
              RST                       =>  Ainit,                -- : IN  std_logic := '0';
              SRST                      =>  '0',                  -- : IN  std_logic := '0';
              WR_CLK                    =>  Wr_clk,               -- : IN  std_logic := '0';
              WR_RST                    =>  Ainit,                -- : IN  std_logic := '0';
              RD_CLK                    =>  Rd_clk,               -- : IN  std_logic := '0';
              RD_RST                    =>  Ainit,                -- : IN  std_logic := '0';
              DIN                       =>  Din,                  -- : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              WR_EN                     =>  Wr_en,                -- : IN  std_logic := '0';
              RD_EN                     =>  Rd_en,                -- : IN  std_logic := '0';
              PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
              INT_CLK                   =>  '0',                  -- : IN  std_logic := '0';
              INJECTDBITERR             =>  '0', -- new FG 5.1    -- : IN  std_logic := '0';
              INJECTSBITERR             =>  '0', -- new FG 5.1    -- : IN  std_logic := '0';

              DOUT                      =>  Dout,                 -- : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
              FULL                      =>  Full,                 -- : OUT std_logic;
              ALMOST_FULL               =>  Almost_full,          -- : OUT std_logic;
              WR_ACK                    =>  Wr_ack,               -- : OUT std_logic;
              OVERFLOW                  =>  Rd_err,               -- : OUT std_logic;
              EMPTY                     =>  Empty,                -- : OUT std_logic;
              ALMOST_EMPTY              =>  Almost_empty,         -- : OUT std_logic;
              VALID                     =>  Rd_ack,               -- : OUT std_logic;
              UNDERFLOW                 =>  Wr_err,               -- : OUT std_logic;
              DATA_COUNT                =>  open,                 -- : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
              RD_DATA_COUNT             =>  sig_full_fifo_rdcnt,  -- : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
              WR_DATA_COUNT             =>  sig_full_fifo_wrcnt,  -- : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
              PROG_FULL                 =>  open,                 -- : OUT std_logic;
              PROG_EMPTY                =>  open,                 -- : OUT std_logic;
              SBITERR                   =>  open,                 -- : OUT std_logic;
              DBITERR                   =>  open,                 -- : OUT std_logic
             
    
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
              AXI_AW_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_AW_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_W_PROG_FULL          =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_W_PROG_EMPTY         =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_B_PROG_FULL          =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_B_PROG_EMPTY         =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_AR_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
              AXI_AR_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
              AXI_R_PROG_FULL         =>  open,                 --         : OUT STD_LOGIC := '0';
              AXI_R_PROG_EMPTY        =>  open,                 --         : OUT STD_LOGIC := '1';

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
              AXIS_UNDERFLOW          =>  open,                 --         : OUT std_logic
              AXIS_PROG_FULL          =>  open,                 --         : OUT STD_LOGIC := '0';
              AXIS_PROG_EMPTY         =>  open                  --         : OUT STD_LOGIC := '1';

             
             );
       
       
       
       end generate V6_S6_AND_LATER;
   
 
 
    end generate USE_2N_DEPTH;
    -----------------------------------------------------------------------
 
 

end implementation;
