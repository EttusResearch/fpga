-------------------------------------------------------------------------------
-- $Id:$
-------------------------------------------------------------------------------
-- sync_fifo_fg.vhd
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
-- Filename:        sync_fifo_fg.vhd
--
-- Description:     
-- This HDL file adapts the legacy CoreGen Sync FIFO interface to the new                
-- FIFO Generator Sync FIFO interface. This wrapper facilitates the "on
-- the fly" call of FIFO Generator during design implementation.                
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sync_fifo_fg.vhd
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
-- Date:            $1/16/2008$
--
-- History:
--   DET   1/16/2008       Initial Version
-- 
--     DET     7/30/2008     for EDK 11.1
-- ~~~~~~
--     - Replaced fifo_generator_v4_2 component with fifo_generator_v4_3
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
--     DET     4/9/2009     EDK 11.2
-- ~~~~~~
--     - Replaced FIFO Generator version 5.1 with 5.2.
-- ^^^^^^
--
--
--     DET     2/9/2010     for EDK 12.1
-- ~~~~~~
--     - Updated the S6/V6 FIFO Generator version from V5.2 to V5.3.
-- ^^^^^^
--
--     DET     3/10/2010     For EDK 12.x
-- ~~~~~~
--   -- Per CR553307
--     - Updated the S6/V6 FIFO Generator version from V5.3 to V6.1.
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
use proc_common_v3_00_a.coregen_comp_defs.all;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.family_support.all;


-- synopsys translate_off
library XilinxCoreLib;
--use XilinxCoreLib.all;
-- synopsys translate_on


-------------------------------------------------------------------------------

entity sync_fifo_fg is
  generic (
    C_FAMILY             :    String  := "virtex5"; -- new for FIFO Gen
    C_DCOUNT_WIDTH       :    integer := 4 ;
    C_ENABLE_RLOCS       :    integer := 0 ; -- not supported in sync fifo
    C_HAS_DCOUNT         :    integer := 1 ;
    C_HAS_RD_ACK         :    integer := 0 ;
    C_HAS_RD_ERR         :    integer := 0 ;
    C_HAS_WR_ACK         :    integer := 0 ;
    C_HAS_WR_ERR         :    integer := 0 ;
    C_HAS_ALMOST_FULL    :    integer := 0 ;
    C_MEMORY_TYPE        :    integer := 0 ;  -- 0 = distributed RAM, 1 = BRAM
    C_PORTS_DIFFER       :    integer := 0 ;  
    C_RD_ACK_LOW         :    integer := 0 ;
    C_USE_EMBEDDED_REG   :    integer := 0 ;
    C_READ_DATA_WIDTH    :    integer := 16;
    C_READ_DEPTH         :    integer := 16;
    C_RD_ERR_LOW         :    integer := 0 ;
    C_WR_ACK_LOW         :    integer := 0 ;
    C_WR_ERR_LOW         :    integer := 0 ;
    C_PRELOAD_REGS       :    integer := 0 ;  -- 1 = first word fall through
    C_PRELOAD_LATENCY    :    integer := 1 ;  -- 0 = first word fall through
    C_WRITE_DATA_WIDTH   :    integer := 16;
    C_WRITE_DEPTH        :    integer := 16
    );
  port (
    Clk          : in  std_logic;
    Sinit        : in  std_logic;
    Din          : in  std_logic_vector(C_WRITE_DATA_WIDTH-1 downto 0);
    Wr_en        : in  std_logic;
    Rd_en        : in  std_logic;
    Dout         : out std_logic_vector(C_READ_DATA_WIDTH-1 downto 0);
    Almost_full  : out std_logic;
    Full         : out std_logic;
    Empty        : out std_logic;
    Rd_ack       : out std_logic;
    Wr_ack       : out std_logic;
    Rd_err       : out std_logic;
    Wr_err       : out std_logic;
    Data_count   : out std_logic_vector(C_DCOUNT_WIDTH-1 downto 0)
    );

end entity sync_fifo_fg;


architecture implementation of sync_fifo_fg is

 -- Function delarations 
 
 
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: GetMaxDepth
    --
    -- Function Description:
    -- Returns the largest value of either Write depth or Read depth
    -- requested by input parameters.
    --
    -------------------------------------------------------------------
    function GetMaxDepth (rd_depth : integer; 
                          wr_depth : integer) 
                          return integer is
    
      Variable max_value : integer := 0;
    
    begin
       
       If (rd_depth < wr_depth) Then
         max_value := wr_depth;
       else
         max_value := rd_depth;
       End if;
      
      return(max_value);
      
    end function GetMaxDepth;
    
  
                
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: GetMemType
    --
    -- Function Description:
    -- Generates the required integer value for the FG instance assignment
    -- of the C_MEMORY_TYPE parameter. Derived from
    -- the input memory type parameter C_MEMORY_TYPE.
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
  
    
    Constant FAMILY_TO_USE        : string  := get_root_family(C_FAMILY);  -- function from family_support.vhd
    
    
    Constant FAMILY_NOT_SUPPORTED : boolean := (equalIgnoringCase(FAMILY_TO_USE, "nofamily"));
    
    Constant FAMILY_IS_SUPPORTED  : boolean := not(FAMILY_NOT_SUPPORTED);
    
    
    Constant FAM_IS_S3_V4_V5      : boolean := (equalIgnoringCase(FAMILY_TO_USE, "spartan3" ) or 
                                                equalIgnoringCase(FAMILY_TO_USE, "virtex4"  ) or 
                                                equalIgnoringCase(FAMILY_TO_USE, "virtex5")) and
                                                FAMILY_IS_SUPPORTED;
    
    Constant FAM_IS_NOT_S3_V4_V5  : boolean := not(FAM_IS_S3_V4_V5) and
                                               FAMILY_IS_SUPPORTED;
    
    
    

    -- Calculate associated FIFO characteristics
    Constant MAX_DEPTH           : integer := GetMaxDepth(C_READ_DEPTH,C_WRITE_DEPTH);
    Constant FGEN_CNT_WIDTH      : integer := log2(MAX_DEPTH)+1;
    Constant ADJ_FGEN_CNT_WIDTH  : integer := FGEN_CNT_WIDTH-1;
    
    -- Get the integer value for a Block memory type fifo generator call
    Constant FG_MEM_TYPE         : integer := GetMemType(C_MEMORY_TYPE);
    
    
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
    Constant FG_IMP_TYPE         : integer := 0;
    
     
     
    -- The programable thresholds are not used so this is housekeeping.
    Constant PROG_FULL_THRESH_ASSERT_VAL : integer := MAX_DEPTH-3;
    Constant PROG_FULL_THRESH_NEGATE_VAL : integer := MAX_DEPTH-4;
  
 
 
    -- Constant zeros for programmable threshold inputs
    Constant PROG_RDTHRESH_ZEROS : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1
                                   DOWNTO 0) := (OTHERS => '0');
    Constant PROG_WRTHRESH_ZEROS : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 
                                   DOWNTO 0) := (OTHERS => '0');
    
    
 -- Signals
    
    signal sig_full            : std_logic;
    signal sig_full_fg_datacnt : std_logic_vector(FGEN_CNT_WIDTH-1 downto 0);
    signal sig_prim_fg_datacnt : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 downto 0);


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
        
        
             -- Wait until second rising clock edge to issue assertion
             Wait until Clk = '1';
             wait until Clk = '0';
             Wait until Clk = '1';
             
             -- Report an error in simulation environment
             assert FALSE report "********* UNSUPPORTED FPGA DEVICE! Check C_FAMILY parameter assignment!" 
                          severity ERROR;
  
             Wait;-- halt this process
             
           end process DO_ASSERTION; 
        
        
        
       -- synthesis translate_on
       


       
    
       -- Tie outputs to logic low or logic high as required
       Dout           <= (others => '0');  -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
       Almost_full    <= '0'            ;  -- : out std_logic;  
       Full           <= '0'            ;  -- : out std_logic; 
       Empty          <= '1'            ;  -- : out std_logic; 
       Rd_ack         <= '0'            ;  -- : out std_logic;
       Wr_ack         <= '0'            ;  -- : out std_logic;
       Rd_err         <= '1'            ;  -- : out std_logic;
       Wr_err         <= '1'            ;  -- : out std_logic
       Data_count     <= (others => '0');  -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
   
     end generate GEN_NO_FAMILY;
 
 
  
   
   
   
   
   
   
   
   
 
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: V5_AND_EARLIER
  --
  -- If Generate Description:
  -- This IfGen implements the fifo using FIFO Generator 4.3
  -- when the designated FPGA Family is Spartan3, Virtex4, or
  -- Virtex5.
  --
  ------------------------------------------------------------
  V5_AND_EARLIER: if(FAM_IS_S3_V4_V5) generate
  begin
   
     Full <= sig_full;
 
   
     -- Create legacy data count by concatonating the Full flag to the 
     -- MS Bit position of the FIFO data count
     -- This is per the Fifo Generator Migration Guide
     sig_full_fg_datacnt <= sig_full & sig_prim_fg_datacnt;  
     
     Data_count <=  sig_full_fg_datacnt(FGEN_CNT_WIDTH-1 downto 
                    FGEN_CNT_WIDTH-C_DCOUNT_WIDTH);   
   
   
  
   -------------------------------------------------------------------------------
   -- Instantiate the generalized FIFO Generator instance
   --
   -- NOTE:
   -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
   -- This is a Coregen FIFO Generator Call module for 
   -- BRAM implementations of a legacy Sync FIFO
   --
   -------------------------------------------------------------------------------
    I_SYNC_FIFO_BRAM : fifo_generator_v4_3 
      generic map(
        C_COMMON_CLOCK                 =>  1,   
        C_COUNT_TYPE                   =>  0,   
        C_DATA_COUNT_WIDTH             =>  ADJ_FGEN_CNT_WIDTH,   -- what to do here ???
        C_DEFAULT_VALUE                =>  "BlankString",         -- what to do here ???
        C_DIN_WIDTH                    =>  C_WRITE_DATA_WIDTH,   
        C_DOUT_RST_VAL                 =>  "0",   
        C_DOUT_WIDTH                   =>  C_READ_DATA_WIDTH,   
        C_ENABLE_RLOCS                 =>  0,                     -- not supported
        C_FAMILY                       =>  FAMILY_TO_USE,
        C_HAS_ALMOST_EMPTY             =>  1,   
        C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,                                           
        C_HAS_BACKUP                   =>  0,   
        C_HAS_DATA_COUNT               =>  C_HAS_DCOUNT,   
        C_HAS_MEMINIT_FILE             =>  0,   
        C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,   
        C_HAS_RD_DATA_COUNT            =>  0,              -- not used for sync FIFO
        C_HAS_RD_RST                   =>  0,              -- not used for sync FIFO
        C_HAS_RST                      =>  0,              -- not used for sync FIFO
        C_HAS_SRST                     =>  1,   
        C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,   
        C_HAS_VALID                    =>  C_HAS_RD_ACK,   
        C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,   
        C_HAS_WR_DATA_COUNT            =>  0,              -- not used for sync FIFO
        C_HAS_WR_RST                   =>  0,              -- not used for sync FIFO
        C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,  
        C_INIT_WR_PNTR_VAL             =>  0,   
        C_MEMORY_TYPE                  =>  FG_MEM_TYPE,    
        C_MIF_FILE_NAME                =>  "BlankString",    
        C_OPTIMIZATION_MODE            =>  0,   
        C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,   
        C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,     -- 1 = first word fall through                                      
        C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,  -- 0 = first word fall through                                          
        C_PRIM_FIFO_TYPE               =>  "512x36", -- only used for V5 Hard FIFO   
        C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,   
        C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,   
        C_PROG_EMPTY_TYPE              =>  0,   
        C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,   
        C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,   
        C_PROG_FULL_TYPE               =>  0,   
        C_RD_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,   
        C_RD_DEPTH                     =>  MAX_DEPTH,   
        C_RD_FREQ                      =>  1,   
        C_RD_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,   
        C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,   
        C_USE_DOUT_RST                 =>  1,   
        C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG,   ----0, Fixed CR#658129   
        C_USE_FIFO16_FLAGS             =>  0,   
        C_USE_FWFT_DATA_COUNT          =>  0,   
        C_VALID_LOW                    =>  C_RD_ACK_LOW,   
        C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,   
        C_WR_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,   
        C_WR_DEPTH                     =>  MAX_DEPTH,   
        C_WR_FREQ                      =>  1,   
        C_WR_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,   
        C_WR_RESPONSE_LATENCY          =>  1,   
        C_USE_ECC                      =>  0,   
        C_FULL_FLAGS_RST_VAL           =>  0,   
        C_HAS_INT_CLK                  =>  0,  
        C_MSGON_VAL                    =>  1
       )
      port map (
        CLK                       =>  Clk,                  -- : IN  std_logic := '0';
        BACKUP                    =>  '0',                  -- : IN  std_logic := '0';
        BACKUP_MARKER             =>  '0',                  -- : IN  std_logic := '0';
        DIN                       =>  Din,                  -- : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_EMPTY_THRESH         =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_EMPTY_THRESH_ASSERT  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_EMPTY_THRESH_NEGATE  =>  PROG_RDTHRESH_ZEROS,  -- : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_FULL_THRESH          =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_FULL_THRESH_ASSERT   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        PROG_FULL_THRESH_NEGATE   =>  PROG_WRTHRESH_ZEROS,  -- : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        RD_CLK                    =>  '0',                  -- : IN  std_logic := '0';
        RD_EN                     =>  Rd_en,                -- : IN  std_logic := '0';
        RD_RST                    =>  '0',                  -- : IN  std_logic := '0';
        RST                       =>  '0',                  -- : IN  std_logic := '0';
        SRST                      =>  Sinit,                -- : IN  std_logic := '0';
        WR_CLK                    =>  '0',                  -- : IN  std_logic := '0';
        WR_EN                     =>  Wr_en,                -- : IN  std_logic := '0';
        WR_RST                    =>  '0',                  -- : IN  std_logic := '0';
        INT_CLK                   =>  '0',                  -- : IN  std_logic := '0';

        ALMOST_EMPTY              =>  open,                 -- : OUT std_logic;
        ALMOST_FULL               =>  Almost_full,          -- : OUT std_logic;                                                      
        DATA_COUNT                =>  sig_prim_fg_datacnt,  -- : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
        DOUT                      =>  Dout,                 -- : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
        EMPTY                     =>  Empty,                -- : OUT std_logic;
        FULL                      =>  sig_full,             -- : OUT std_logic;
        OVERFLOW                  =>  Wr_err,               -- : OUT std_logic;
        PROG_EMPTY                =>  open,                 -- : OUT std_logic;
        PROG_FULL                 =>  open,                 -- : OUT std_logic;
        VALID                     =>  Rd_ack,               -- : OUT std_logic;
        RD_DATA_COUNT             =>  open,                 -- : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
        UNDERFLOW                 =>  Rd_err,               -- : OUT std_logic;
        WR_ACK                    =>  Wr_ack,               -- : OUT std_logic;
        WR_DATA_COUNT             =>  open,                 -- : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
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
  -- This IfGen implements the fifo using fifo_generator_v9_1
  -- when the designated FPGA Family is Spartan-6, Virtex-6 or
  -- later.
  --
  ------------------------------------------------------------
  V6_S6_AND_LATER: if(FAM_IS_NOT_S3_V4_V5) generate
  begin
   
     Full <= sig_full;
 
   
     -- Create legacy data count by concatonating the Full flag to the 
     -- MS Bit position of the FIFO data count
     -- This is per the Fifo Generator Migration Guide
     sig_full_fg_datacnt <= sig_full & sig_prim_fg_datacnt;  
     
     Data_count <=  sig_full_fg_datacnt(FGEN_CNT_WIDTH-1 downto 
                    FGEN_CNT_WIDTH-C_DCOUNT_WIDTH);   
   
   
  
        
        
    -------------------------------------------------------------------------------
    -- Instantiate the generalized FIFO Generator instance
    --
    -- NOTE:
    -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
    -- This is a Coregen FIFO Generator Call module for 
    -- BRAM implementations of a legacy Sync FIFO
    --
    -------------------------------------------------------------------------------
    I_SYNC_FIFO_BRAM : fifo_generator_v9_1 
      generic map(
        C_COMMON_CLOCK                 =>  1,                                           
        C_COUNT_TYPE                   =>  0,                                           
        C_DATA_COUNT_WIDTH             =>  ADJ_FGEN_CNT_WIDTH,   -- what to do here ??? 
        C_DEFAULT_VALUE                =>  "BlankString",         -- what to do here ???
        C_DIN_WIDTH                    =>  C_WRITE_DATA_WIDTH,                          
        C_DOUT_RST_VAL                 =>  "0",                                         
        C_DOUT_WIDTH                   =>  C_READ_DATA_WIDTH,                           
        C_ENABLE_RLOCS                 =>  0,                     -- not supported      
        C_FAMILY                       =>  FAMILY_TO_USE,                                    
        C_FULL_FLAGS_RST_VAL           =>  0,                                           
        C_HAS_ALMOST_EMPTY             =>  1,                                           
        C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,                                           
        C_HAS_BACKUP                   =>  0,                                           
        C_HAS_DATA_COUNT               =>  C_HAS_DCOUNT,                                
        C_HAS_INT_CLK                  =>  0,                                            
        C_HAS_MEMINIT_FILE             =>  0,                                           
        C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,                                
        C_HAS_RD_DATA_COUNT            =>  0,              -- not used for sync FIFO    
        C_HAS_RD_RST                   =>  0,              -- not used for sync FIFO    
        C_HAS_RST                      =>  0,              -- not used for sync FIFO    
        C_HAS_SRST                     =>  1,                                           
        C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,                                
        C_HAS_VALID                    =>  C_HAS_RD_ACK,                                
        C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,                                
        C_HAS_WR_DATA_COUNT            =>  0,              -- not used for sync FIFO    
        C_HAS_WR_RST                   =>  0,              -- not used for sync FIFO    
        C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,                                 
        C_INIT_WR_PNTR_VAL             =>  0,                                           
        C_MEMORY_TYPE                  =>  FG_MEM_TYPE,                                 
        C_MIF_FILE_NAME                =>  "BlankString",                               
        C_OPTIMIZATION_MODE            =>  0,                                           
        C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,                                
        C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,  -- 0 = first word fall through                                          
        C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,     -- 1 = first word fall through                                      
        C_PRIM_FIFO_TYPE               =>  "512x36", -- only used for V5 Hard FIFO      
        C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,                                           
        C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,                                           
        C_PROG_EMPTY_TYPE              =>  0,                                           
        C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,                 
        C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,                 
        C_PROG_FULL_TYPE               =>  0,                                           
        C_RD_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,                          
        C_RD_DEPTH                     =>  MAX_DEPTH,                                   
        C_RD_FREQ                      =>  1,                                           
        C_RD_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,                          
        C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,                                
        C_USE_DOUT_RST                 =>  1,                                           
        C_USE_ECC                      =>  0,                                           
        C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG,   ----0, Fixed CR#658129                                           
        C_USE_FIFO16_FLAGS             =>  0,                                           
        C_USE_FWFT_DATA_COUNT          =>  0,                                           
        C_VALID_LOW                    =>  C_RD_ACK_LOW,                                
        C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,                                
        C_WR_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,                          
        C_WR_DEPTH                     =>  MAX_DEPTH,                                   
        C_WR_FREQ                      =>  1,                                           
        C_WR_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,                          
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
      port map(
        BACKUP                    =>  '0',                  
        BACKUP_MARKER             =>  '0',                  
        CLK                       =>  Clk,                  
        RST                       =>  '0',                  
        SRST                      =>  Sinit,                
        WR_CLK                    =>  '0',                  
        WR_RST                    =>  '0',                  
        RD_CLK                    =>  '0',                  
        RD_RST                    =>  '0',                  
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
        FULL                      =>  sig_full,                          
        ALMOST_FULL               =>  Almost_full,                       
        WR_ACK                    =>  Wr_ack,                            
        OVERFLOW                  =>  Wr_err,                            
        EMPTY                     =>  Empty,                             
        ALMOST_EMPTY              =>  open,                              
        VALID                     =>  Rd_ack,                            
        UNDERFLOW                 =>  Rd_err,                            
        DATA_COUNT                =>  sig_prim_fg_datacnt,               
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
        AXI_W_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
        AXI_W_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
        AXI_B_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
        AXI_B_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
        AXI_R_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
        AXI_R_PROG_EMPTY        =>  open,                 --        : OUT STD_LOGIC := '1';

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
        AXIS_UNDERFLOW          =>  open,                  --         : OUT std_logic
        AXIS_PROG_FULL         =>  open,                 --        : OUT STD_LOGIC := '0';
        AXIS_PROG_EMPTY        =>  open                 --        : OUT STD_LOGIC := '1';

       
        );
        
        
        
        
  end generate V6_S6_AND_LATER;



end implementation;
