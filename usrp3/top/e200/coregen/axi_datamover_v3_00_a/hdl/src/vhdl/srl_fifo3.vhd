-------------------------------------------------------------------------------
-- $Id: srl_fifo3.vhd,v 1.1.4.1 2010/09/14 22:35:47 dougt Exp $
-------------------------------------------------------------------------------
-- srl_fifo3 - entity / architecture pair
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
-- Filename:        srl_fifo3.vhd
--
-- Description:     same as srl_fifo except the Addr port has the correct bit
--                  ordering, there is a true FIFO_Empty port, and the C_DEPTH
--                  generic actually controlls how many elements the fifo will
--                  hold (up to 16).  includes an assertion statement to check
--                  that C_DEPTH is less than or equal to 16.  changed
--                  C_DATA_BITS to C_DWIDTH and changed it from natural to
--                  positive (the width should be 1 or greater, zero width
--                  didn't make sense to me!).  Changed C_DEPTH from natural
--                  to positive (zero elements doesn't make sense).
--                  The Addr port in srl_fifo has the bits reversed which
--                  made it more difficult to use.  C_DEPTH was not used in
--                  srl_fifo.  Data_Exists is delayed by one clock so it is
--                  not usefull for generating an empty flag.  FIFO_Empty is
--                  generated directly from the address, the same way that
--                  FIFO_Full is generated.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo3.vhd
--
-------------------------------------------------------------------------------
-- Author:          jam
--
-- History:
--   JAM   2002-02-02   First Version - modified from original srl_fifo
--
--   DCW   2002-03-12   Structural implementation of synchronous reset for
--                      Data_Exists DFF (using FDR)
--
--   JAM   2002-04-12   Added C_XON generic for mixed vhdl/verilog sims
--
--   als   2002-04-18   Added default for XON generic in SRL16E, FDRE, and FDR
--                      component declarations
--
--   JAM   2002-05-01   Changed FIFO_Empty output from buffer_Empty, which had
--                      a clock delay, to the not of data_Exists_I, which
--                      doesn't have any delay
--
--   DCW   2004-10-15   Changed unisim.all to unisim.vcomponents.
--                      Added C_FAMILY generic.
--                      Added C_AWIDTH generic.
--                      
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.family.all;

library unisim;
use unisim.vcomponents.all;

entity srl_fifo3 is
  generic (
           C_FAMILY : string   := "virtex4";  -- latest and greatest
           C_DWIDTH : positive := 8;          -- changed to positive
           C_AWIDTH : positive := 4;          -- changed to positive
           C_DEPTH  : positive := 16          -- changed to positive
          );

  port    (
           Clk         : in  std_logic;
           Reset       : in  std_logic;
           FIFO_Write  : in  std_logic;
           Data_In     : in  std_logic_vector(0 to C_DWIDTH-1);
           FIFO_Read   : in  std_logic;
           Data_Out    : out std_logic_vector(0 to C_DWIDTH-1);
           FIFO_Full   : out std_logic;
           FIFO_Empty  : out std_logic;
           Data_Exists : out std_logic;
           Addr        : out std_logic_vector(0 to C_AWIDTH-1)
          );

end entity srl_fifo3;

architecture imp of srl_fifo3 is

------------------------------------------------------------------------------
-- Architecture BEGIN
------------------------------------------------------------------------------

begin

------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                   GENERATE FOR C_DEPTH LESS THAN 17
------------------------------------------------------------------------------
------------------------------------------------------------------------------

C_DEPTH_LT_17 : if (C_DEPTH < 17) generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    -- convert C_DEPTH to a std_logic_vector so FIFO_Full can be generated
    -- based on the selected depth rather than fixed at 16
    constant DEPTH : std_logic_vector(0 to 3) :=
                                           conv_std_logic_vector(C_DEPTH-1,4);

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i       : std_logic_vector(0 to 3);  
    signal buffer_Full  : std_logic;
    signal buffer_Empty : std_logic;

    signal next_Data_Exists : std_logic;
    signal data_Exists_I    : std_logic;

    signal valid_Write : std_logic;

    signal hsum_A  : std_logic_vector(0 to 3);
    signal sum_A   : std_logic_vector(0 to 3);
    signal addr_cy : std_logic_vector(0 to 4);

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------

    component SRL16E is
        -- pragma translate_off
        generic (
                 INIT : bit_vector := X"0000"
                );
        -- pragma translate_on    
        port (
              CE  : in  std_logic;
              D   : in  std_logic;
              Clk : in  std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              Q   : out std_logic
             );
    end component SRL16E;

    component MULT_AND
        port (
              I0 : in  std_logic;
              I1 : in  std_logic;
              LO : out std_logic
             );
    end component;

    component MUXCY_L
        port (
              DI : in  std_logic;
              CI : in  std_logic;
              S  : in  std_logic;
              LO : out std_logic
             );
    end component;

    component XORCY
        port (
              LI : in  std_logic;
              CI : in  std_logic;
              O  : out std_logic
             );
    end component;

    component FDRE is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              CE : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDRE;

    component FDR is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDR;

    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------

    begin

    --------------------------------------------------------------------------
    -- Depth check and assertion
    --------------------------------------------------------------------------

    -- C_DEPTH is positive so that ensures the fifo is at least 1 element deep
    -- make sure it is not greater than 16 locations deep
    -- pragma translate_off
    assert C_DEPTH <= 16
    report "SRL Fifo's must be 16 or less elements deep"
    severity FAILURE;
    -- pragma translate_on

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------

    -- since srl16 address is 3 downto 0 need to compare individual bits
    -- didn't muck with addr_i since the basic addressing works - Addr output
    -- is generated correctly below

    buffer_Full <= '1' when (addr_i(0) = DEPTH(3) and
                             addr_i(1) = DEPTH(2) and
                             addr_i(2) = DEPTH(1) and
                             addr_i(3) = DEPTH(0)   ) else '0';

    FIFO_Full <= buffer_Full;

    buffer_Empty <= '1' when (addr_i = "0000") else '0';

    FIFO_Empty <= not data_Exists_I;   -- generate a true empty flag with no delay
                                       -- was buffer_Empty, which had a clock dly

    next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                        (buffer_Empty and FIFO_Write) or
                        (data_Exists_I and not FIFO_Read);

    Data_Exists <= data_Exists_I;
  
    valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

    addr_cy(0) <= valid_Write;

    --------------------------------------------------------------------------
    -- Data Exists DFF Instance
    --------------------------------------------------------------------------

    DATA_EXISTS_DFF : FDR
        port map (
                  Q  => data_Exists_I,     -- [out std_logic]
                  C  => Clk,               -- [in  std_logic]
                  D  => next_Data_Exists,  -- [in  std_logic]
                  R  => Reset              -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- GENERATE ADDRESS COUNTERS
    --------------------------------------------------------------------------

    Addr_Counters : for i in 0 to 3 generate

        hsum_A(i) <= (FIFO_Read xor addr_i(i)) and
                     (FIFO_Write or not buffer_Empty);

        MUXCY_L_I : MUXCY_L
            port map (
                      DI => addr_i(i),      -- [in  std_logic]
                      CI => addr_cy(i),     -- [in  std_logic]
                      S  => hsum_A(i),      -- [in  std_logic]
                      LO => addr_cy(i+1)    -- [out std_logic]
                     );

        XORCY_I : XORCY
            port map (
                      LI => hsum_A(i),      -- [in  std_logic]
                      CI => addr_cy(i),     -- [in  std_logic]
                      O  => sum_A(i)        -- [out std_logic]
                     );

        FDRE_I : FDRE
            port map (
                      Q  => addr_i(i),      -- [out std_logic]
                      C  => Clk,            -- [in  std_logic]
                      CE => data_Exists_i,  -- [in  std_logic]
                      D  => sum_A(i),       -- [in  std_logic]
                      R  => Reset           -- [in  std_logic]
                     );

    end generate Addr_Counters;

    --------------------------------------------------------------------------
    -- GENERATE FIFO RAM
    --------------------------------------------------------------------------

    FIFO_RAM : for I in 0 to C_DWIDTH-1 generate

        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      CE  => valid_Write,     -- [in  std_logic]
                      D   => Data_In(I),      -- [in  std_logic]
                      Clk => Clk,             -- [in  std_logic]
                      A0  => addr_i(0),       -- [in  std_logic]
                      A1  => addr_i(1),       -- [in  std_logic]
                      A2  => addr_i(2),       -- [in  std_logic]
                      A3  => addr_i(3),       -- [in  std_logic]
                      Q   => Data_Out(I)      -- [out std_logic]
                     );

    end generate FIFO_RAM;
  
    --------------------------------------------------------------------------
    -- INT_ADDR_PROCESS
    --------------------------------------------------------------------------
    -- This process assigns the internal address to the output port
    --------------------------------------------------------------------------
       -- modified the process to flip the bits since the address bits from
       -- the srl16 are 3 downto 0 and Addr needs to be 0 to 3

      INT_ADDR_PROCESS:process (addr_i)
      begin
          for i in Addr'range
          loop
              Addr(i) <= addr_i(3 - i); -- flip the bits to account
          end loop;                        --  for srl16 addr
      end process;

end generate;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
--   GENERATE FOR C_DEPTH GREATER THAN 16, LESS THAN 32, 
--   AND VIRTEX-E AND OLDER FAMILIES
------------------------------------------------------------------------------
------------------------------------------------------------------------------

C_DEPTH_16_32_VE : if ( ( (C_DEPTH > 16) and (C_DEPTH < 33) ) and
                        ( equalIgnoreCase(C_FAMILY,"virtex")  or
                          equalIgnoreCase(C_FAMILY,"virtexe") or
                          equalIgnoreCase(C_FAMILY,"spartan3e") or
                          equalIgnoreCase(C_FAMILY,"spartan3") ) )
generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i             : std_logic_vector(0 to 4);

    signal addr_i_1           : std_logic_vector(3 downto 0);  
    signal buffer_Full_1      : std_logic;
    signal next_buffer_Full_1 : std_logic;
    signal next_Data_Exists_1 : std_logic;
    signal data_Exists_I_1    : std_logic;
    signal FIFO_Write_1       : std_logic;
    signal Data_In_1          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_1        : std_logic;
    signal Data_Out_1         : std_logic_vector(0 to C_DWIDTH-1);

    signal addr_i_2           : std_logic_vector(3 downto 0);  
    signal buffer_Full_2      : std_logic;
    signal next_buffer_Full_2 : std_logic;
    signal next_Data_Exists_2 : std_logic;
    signal data_Exists_I_2    : std_logic;
    signal FIFO_Write_2       : std_logic;
    signal Data_In_2          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_2        : std_logic;
    signal Data_Out_2         : std_logic_vector(0 to C_DWIDTH-1);

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------

    component SRL16E is
        -- pragma translate_off
        generic (
                 INIT : bit_vector := X"0000"
                );
        -- pragma translate_on    
        port (
              CE  : in  std_logic;
              D   : in  std_logic;
              Clk : in  std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              Q   : out std_logic
             );
    end component SRL16E;

    component FDR is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDR;

    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------
  
    begin

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------

    next_Data_Exists_1 <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_1(0))
                          and not(addr_i_1(1)) and not(addr_i_1(2)) 
                          and not(addr_i_1(3))) or data_Exists_I_1) and not
                          (FIFO_Read and not(FIFO_Write) and not(addr_i_1(0))
                          and not(addr_i_1(1)) and not(addr_i_1(2))
                          and not(addr_i_1(3)));  

    FIFO_Write_1 <= FIFO_Write;
    FIFO_Write_2 <= FIFO_Write;
    FIFO_Read_1  <= FIFO_Read;
    FIFO_Read_2  <= FIFO_Read;
    data_Exists  <= data_Exists_I_1;
    Data_Out     <= Data_Out_2 when (data_Exists_I_2 = '1') else Data_Out_1;
    Data_In_2    <= Data_Out_1;
    Data_In_1    <= Data_In;
    FIFO_Full    <= buffer_Full_2;

    next_buffer_Full_1  <= '1' when (addr_i_1 = "1111") else '0';

    next_Data_Exists_2  <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_2(0))
                           and not(addr_i_2(1)) and not(addr_i_2(2)) and not 
                           (addr_i_2(3)) and (buffer_Full_1)) or data_Exists_I_2)
                           and not(FIFO_Read and not(FIFO_Write) and 
                           not(addr_i_2(0)) and not(addr_i_2(1)) and 
                           not(addr_i_2(2)) and not(addr_i_2(3)));  

    next_buffer_Full_2  <= '1' when (addr_i_2 = "1111") else '0';

    FIFO_Empty <= not next_Data_Exists_1 and not next_Data_Exists_2;
                                -- generate a true empty flag with no delay
                                -- was buffer_Empty, which had a clock dly


    --------------------------------------------------------------------------
    -- Address Processes
    --------------------------------------------------------------------------

    ADDRS_1 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_1 <= "0000";
            elsif ((buffer_Full_1='0') and (FIFO_Write='1') and
                   (FIFO_Read='0') and (data_Exists_I_1='1')) then
                addr_i_1 <= addr_i_1 + 1;
            elsif (not(addr_i_1 = "0000") and (FIFO_Read='1') and 
                  (FIFO_Write='0') and (data_Exists_I_2='0')) then
                addr_i_1 <= addr_i_1 - 1;
            else
                null;
            end if;
        end if;
    end process;

    ADDRS_2 : process (Clk)
        begin
            if (clk'event and clk = '1') then
                if (Reset = '1') then
                    addr_i_2 <= "0000";
                elsif ((buffer_Full_2='0') and (FIFO_Write = '1') and
                      (FIFO_Read = '0') and (buffer_Full_1 = '1') and
                      (data_Exists_I_2='1')) then
                    addr_i_2 <= addr_i_2 + 1;
                elsif (not(addr_i_2 = "0000") and (FIFO_Read = '1') and
                      (FIFO_Write = '0')) then
                    addr_i_2 <= addr_i_2 - 1;
                else
                    null;
                end if;
            end if;
    end process;

    ADDR_OUT : process (addr_i_1, addr_i_2, data_Exists_I_2)
        begin
            if  (data_Exists_I_2 = '0') then
                Addr <= '0' & addr_i_1;
            else
                Addr <= '1' & addr_i_2;
            end if;
    end process;

    --------------------------------------------------------------------------
    -- Data Exists Instances
    --------------------------------------------------------------------------

    DATA_EXISTS_1_DFF : FDR
        port map (
                  Q  => data_Exists_I_1,    -- [out std_logic]
                  C  => Clk,                -- [in  std_logic]
                  D  => next_Data_Exists_1, -- [in  std_logic]
                  R  => Reset               -- [in  std_logic]
                       );
         
    DATA_EXISTS_2_DFF : FDR
        port map (
                  Q  => data_Exists_I_2,     -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_Data_Exists_2,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- Buffer Full Instances
    --------------------------------------------------------------------------
  
    BUFFER_FULL_1_DFF : FDR
        port map (
                  Q  => buffer_Full_1,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_1,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    BUFFER_FULL_2_DFF : FDR
        port map (
                  Q  => buffer_Full_2,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_2,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- GENERATE FIFO RAMS
    --------------------------------------------------------------------------

    FIFO_RAM_1 : for i in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      CE  => FIFO_Write_1,   -- [in  std_logic]
                      D   => Data_In_1(i),   -- [in  std_logic]
                      Clk => Clk,            -- [in  std_logic]
                      A0  => addr_i_1(0),    -- [in  std_logic]
                      A1  => addr_i_1(1),    -- [in  std_logic]
                      A2  => addr_i_1(2),    -- [in  std_logic]
                      A3  => addr_i_1(3),    -- [in  std_logic]
                      Q   => Data_Out_1(i)   -- [out std_logic]
                     );
    end generate FIFO_RAM_1;

    FIFO_RAM_2 : for i in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      CE  => FIFO_Write_2,   -- [in  std_logic]
                      D   => Data_In_2(i),   -- [in  std_logic]
                      Clk => Clk,            -- [in  std_logic]
                      A0  => addr_i_2(0),    -- [in  std_logic]
                      A1  => addr_i_2(1),    -- [in  std_logic]
                      A2  => addr_i_2(2),    -- [in  std_logic]
                      A3  => addr_i_2(3),    -- [in  std_logic]
                      Q   => Data_Out_2(i)   -- [out std_logic]
                     );
    end generate FIFO_RAM_2;

end generate;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
--   GENERATE FOR C_DEPTH GREATER THAN 16, LESS THAN 32, 
--   AND VIRTEX-2 AND NEWER FAMILIES
------------------------------------------------------------------------------
------------------------------------------------------------------------------

C_DEPTH_16_32_V2 : if ( ( (C_DEPTH > 16) and (C_DEPTH < 33) ) and
                        ( equalIgnoreCase(C_FAMILY,"virtex2")  or
                          equalIgnoreCase(C_FAMILY,"virtex2p") or
                          equalIgnoreCase(C_FAMILY,"virtex4") ) )
generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    constant DEPTH : std_logic_vector(0 to 4) :=
                                      conv_std_logic_vector(C_DEPTH-1,5);

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i       : std_logic_vector(0 to 4);  
    signal buffer_Full  : std_logic;
    signal buffer_Empty : std_logic;

    signal next_Data_Exists : std_logic;
    signal data_Exists_I    : std_logic;

    signal valid_Write : std_logic;

    signal hsum_A  : std_logic_vector(0 to 4);
    signal sum_A   : std_logic_vector(0 to 4);
    signal addr_cy : std_logic_vector(0 to 5);
    
    signal D_Out_ls : std_logic_vector(0 to C_DWIDTH-1); 
    signal D_Out_ms : std_logic_vector(0 to C_DWIDTH-1); 
    signal q15      : std_logic_vector(0 to C_DWIDTH-1);

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------

    component SRL16E is
        -- pragma translate_off
        generic ( INIT : bit_vector := X"0000" );
        -- pragma translate_on    
        port (
              CE  : in  std_logic;
              D   : in  std_logic;
              Clk : in  std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              Q   : out std_logic
             );
    end component SRL16E;

    component MUXCY_L
        port (
              DI : in  std_logic;
              CI : in  std_logic;
              S  : in  std_logic;
              LO : out std_logic
             );
    end component;

    component XORCY
        port (
              LI : in  std_logic;
              CI : in  std_logic;
              O  : out std_logic
             );
    end component;

    component FDRE is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              CE : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDRE;

    component FDR is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDR;

    component MUXF5
        port (
              O  : out std_logic;
              I0 : in std_logic;
              I1 : in std_logic;
              S  : in std_logic
             );
    end component;

    component SRLC16E
        -- pragma translate_off
        generic ( INIT : bit_vector := X"0000" );
        -- pragma translate_on    
        port (
              Q   : out std_logic;
              Q15 : out std_logic;
              A0  : in std_logic;
              A1  : in std_logic;
              A2  : in std_logic;
              A3  : in std_logic;
              CE  : in std_logic;
              CLK : in std_logic;
              D   : in std_logic
             );
    end component;

    component LUT3
        generic( INIT : bit_vector := X"0" );
        port(
             O  : out std_ulogic;
             I0 : in  std_ulogic;
             I1 : in  std_ulogic;
             I2 : in  std_ulogic
            );
    end component;

    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------
  
    begin

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------

    --buffer_Full <= '1' when (addr_i = "11111") else '0';
    
    buffer_Full <= '1' when (addr_i(0) = DEPTH(4) and
                             addr_i(1) = DEPTH(3) and
                             addr_i(2) = DEPTH(2) and
                             addr_i(3) = DEPTH(1) and
                             addr_i(4) = DEPTH(0) ) else '0';

    FIFO_Full    <= buffer_Full;

    buffer_Empty <= '1' when (addr_i = "00000") else '0';

    FIFO_Empty   <= not data_Exists_I;   -- generate a true empty flag with no delay
                                         -- was buffer_Empty, which had a clock dly
    Data_Exists  <= data_Exists_I;
    addr_cy(0)   <= valid_Write;

    next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                        (buffer_Empty and FIFO_Write) or
                        (data_Exists_I and not FIFO_Read);

    --------------------------------------------------------------------------
    -- Data Exists DFF Instance
    --------------------------------------------------------------------------

    DATA_EXISTS_DFF : FDR
        port map (
                  Q  => data_Exists_i,     -- [out std_logic]
                  C  => Clk,               -- [in  std_logic]
                  D  => next_Data_Exists,  -- [in  std_logic]
                  R  => Reset              -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- Valid Write LUT Instance
    --------------------------------------------------------------------------
  
    -- XST CR183399 WA  
    --  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

    VALID_WRITE_I : LUT3 
      generic map ( INIT => X"8A" )
      port map (
                O  => valid_Write,
                I0 => FIFO_Write,
                I1 => FIFO_Read,
                I2 => buffer_Full 
               );
    --END XST WA for CR183399

    --------------------------------------------------------------------------
    -- GENERATE ADDRESS COUNTERS
    --------------------------------------------------------------------------

    ADDR_COUNTERS : for i in 0 to 4 generate

        hsum_A(I) <= (FIFO_Read xor addr_i(i)) and
                     (FIFO_Write or not buffer_Empty);

        MUXCY_L_I : MUXCY_L
            port map (
                      DI => addr_i(i),        -- [in  std_logic]
                      CI => addr_cy(i),       -- [in  std_logic]
                      S  => hsum_A(i),        -- [in  std_logic]
                      LO => addr_cy(i+1)      -- [out std_logic]
                     );

        XORCY_I : XORCY
            port map (
                      LI => hsum_A(i),        -- [in  std_logic]
                      CI => addr_cy(i),       -- [in  std_logic]
                      O  => sum_A(i)          -- [out std_logic]
                     );

        FDRE_I : FDRE
            port map (
                      Q  => addr_i(i),        -- [out std_logic]
                      C  => Clk,              -- [in  std_logic]
                      CE => data_Exists_i,    -- [in  std_logic]
                      D  => sum_A(i),         -- [in  std_logic]
                      R  => Reset             -- [in  std_logic]
                     );

    end generate Addr_Counters;

    --------------------------------------------------------------------------
    -- GENERATE FIFO RAMS
    --------------------------------------------------------------------------

    FIFO_RAM : for i in 0 to C_DWIDTH-1 generate
        SRLC16E_LS : SRLC16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      Q   => D_Out_ls(i),
                      Q15 => q15(i),
                      A0  => addr_i(0),
                      A1  => addr_i(1),
                      A2  => addr_i(2),
                      A3  => addr_i(3),
                      CE  => valid_Write,
                      CLK => Clk,
                      D   => Data_In(i)
                     );

      SRL16E_MS : SRL16E
        -- pragma translate_off
        generic map ( INIT => x"0000" )
        -- pragma translate_on
        port map (
                  CE  => valid_Write,  
                  D   => q15(i),  
                  Clk => Clk,  
                  A0  => addr_i(0),  
                  A1  => addr_i(1),  
                  A2  => addr_i(2),  
                  A3  => addr_i(3),  
                  Q   => D_Out_ms(i)
                 );
         
     MUXF5_I: MUXF5
         port map (
                   O  => Data_Out(i),  --[out]
                   I0 => D_Out_ls(i),  --[in]
                   I1 => D_Out_ms(i),  --[in]
                   S  => addr_i(4)     --[in]
                  );
           
    end generate FIFO_RAM;
  
    --------------------------------------------------------------------------
    -- INT_ADDR_PROCESS
    --------------------------------------------------------------------------
    -- This process assigns the internal address to the output port
    --------------------------------------------------------------------------

    INT_ADDR_PROCESS:process (addr_i)
    begin   -- process
        for i in Addr'range
        loop
            Addr(i) <= addr_i(4 - i); --flip the bits to account for srl16 addr
        end loop;
    end process;

end generate;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
--   GENERATE FOR C_DEPTH GREATER THAN 32, LESS THAN 65, 
--   AND VIRTEX-E AND OLDER FAMILIES
------------------------------------------------------------------------------
------------------------------------------------------------------------------

C_DEPTH_32_64_VE : if ( (C_DEPTH > 32) and (C_DEPTH < 65) and
                        ( equalIgnoreCase(C_FAMILY,"virtex")  or
                          equalIgnoreCase(C_FAMILY,"virtexe") or
                          equalIgnoreCase(C_FAMILY,"spartan3e") or
                          equalIgnoreCase(C_FAMILY,"spartan3") ) )
generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i_1           : std_logic_vector(3 downto 0);  
    signal buffer_Full_1      : std_logic;
    signal next_buffer_Full_1 : std_logic;
    signal next_Data_Exists_1 : std_logic;
    signal data_Exists_I_1    : std_logic;
    signal FIFO_Write_1       : std_logic;
    signal Data_In_1          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_1        : std_logic;
    signal Data_Out_1         : std_logic_vector(0 to C_DWIDTH-1);

    signal addr_i_2           : std_logic_vector(3 downto 0);  
    signal buffer_Full_2      : std_logic;
    signal next_buffer_Full_2 : std_logic;
    signal next_Data_Exists_2 : std_logic;
    signal data_Exists_I_2    : std_logic;
    signal FIFO_Write_2       : std_logic;
    signal Data_In_2          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_2        : std_logic;
    signal Data_Out_2         : std_logic_vector(0 to C_DWIDTH-1);

    signal addr_i_3           : std_logic_vector(3 downto 0);  
    signal buffer_Full_3      : std_logic;
    signal next_buffer_Full_3 : std_logic;
    signal next_Data_Exists_3 : std_logic;
    signal data_Exists_I_3    : std_logic;
    signal FIFO_Write_3       : std_logic;
    signal Data_In_3          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_3        : std_logic;
    signal Data_Out_3         : std_logic_vector(0 to C_DWIDTH-1);

    signal addr_i_4           : std_logic_vector(3 downto 0);  
    signal buffer_Full_4      : std_logic;
    signal next_buffer_Full_4 : std_logic;
    signal next_Data_Exists_4 : std_logic;
    signal data_Exists_I_4    : std_logic;
    signal FIFO_Write_4       : std_logic;
    signal Data_In_4          : std_logic_vector(0 to C_DWIDTH-1);
    signal FIFO_Read_4        : std_logic;
    signal Data_Out_4         : std_logic_vector(0 to C_DWIDTH-1);

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------
    
    component SRL16E is
        -- pragma translate_off
        generic ( INIT : bit_vector := X"0000" );
        -- pragma translate_on    
        port (
              CE  : in  std_logic;
              D   : in  std_logic;
              Clk : in  std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              Q   : out std_logic
             );
    end component SRL16E;

    component FDR is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDR;

    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------
  
    begin

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------

    FIFO_Write_1 <= FIFO_Write;
    FIFO_Read_1  <= FIFO_Read;
    FIFO_Write_2 <= FIFO_Write and buffer_Full_1;
    FIFO_Read_2  <= FIFO_Read;
    FIFO_Write_3 <= FIFO_Write and buffer_Full_2;
    FIFO_Read_3  <= FIFO_Read;
    FIFO_Write_4 <= FIFO_Write and buffer_Full_3;
    FIFO_Read_4  <= FIFO_Read;

    Data_In_1    <= Data_In;
    Data_In_2    <= Data_Out_1;
    Data_In_3    <= Data_Out_2;
    Data_In_4    <= Data_Out_3;
    FIFO_Full    <= buffer_Full_4;

    next_buffer_Full_1  <= '1' when (addr_i_1 = "1111") else '0';
    next_buffer_Full_2  <= '1' when (addr_i_2 = "1111") else '0';
    next_buffer_Full_3  <= '1' when (addr_i_3 = "1111") else '0';
    next_buffer_Full_4  <= '1' when (addr_i_4 = "1111") else '0';

    next_Data_Exists_1 <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_1(0))
                          and not(addr_i_1(1)) and not(addr_i_1(2))
                          and not(addr_i_1(3))) or data_Exists_I_1) and
                          not(FIFO_Read and not(FIFO_Write) 
                          and not(addr_i_1(0)) and not(addr_i_1(1)) and not
                          (addr_i_1(2)) and not(addr_i_1(3)));

    next_Data_Exists_2 <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_2(0))
                          and not(addr_i_2(1)) and not(addr_i_2(2))
                          and not(addr_i_2(3)) and (buffer_Full_1)) or
                          data_Exists_I_2) and not(FIFO_Read and not(FIFO_Write)
                          and not(addr_i_2(0)) and not(addr_i_2(1)) and not
                          (addr_i_2(2)) and not(addr_i_2(3)));

    next_Data_Exists_3 <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_3(0))
                          and not(addr_i_3(1)) and not(addr_i_3(2)) and not
                          (addr_i_3(3)) and (buffer_Full_2)) or data_Exists_I_3)
                          and not(FIFO_Read and not(FIFO_Write) and not
                          (addr_i_3(0)) and not(addr_i_3(1)) and not
                          (addr_i_3(2)) and not(addr_i_3(3)));  

    next_Data_Exists_4 <= ((FIFO_Write and not(FIFO_Read) and not(addr_i_4(0))
                          and not(addr_i_4(1)) and not(addr_i_4(2)) and not
                          (addr_i_4(3)) and (buffer_Full_3)) or data_Exists_I_4)
                          and not(FIFO_Read and not(FIFO_Write) and 
                          not(addr_i_4(0)) and not(addr_i_4(1)) and 
                          not(addr_i_4(2)) and not(addr_i_4(3)));

    data_Exists <= data_Exists_I_1;

    Data_Out    <= Data_Out_4 when (data_Exists_I_4 = '1') else 
                   Data_Out_3 when (data_Exists_I_3 = '1') else
                   Data_Out_2 when (data_Exists_I_2 = '1') else
                   Data_Out_1;
 
    FIFO_Empty <= not data_Exists_I_1;

    --------------------------------------------------------------------------
    -- Address Processes
    --------------------------------------------------------------------------

    ADDRS_1 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_1 <= "0000";
            elsif ((buffer_Full_1='0') and (FIFO_Write='1') and
                  (FIFO_Read='0') and (data_Exists_I_1='1')) then
                addr_i_1 <= addr_i_1 + 1;
            elsif (not(addr_i_1 = "0000") and (FIFO_Read='1') and
                  (FIFO_Write='0') and (data_Exists_I_2='0')) then
                addr_i_1 <= addr_i_1 - 1;
            else
                null;
            end if;
        end if;
    end process;

    ADDRS_2 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_2 <= "0000";
            elsif ((buffer_Full_2='0') and (FIFO_Write = '1') and
                  (FIFO_Read = '0') and (buffer_Full_1 = '1') and
                  (data_Exists_I_2='1')) then
                addr_i_2 <= addr_i_2 + 1;
            elsif (not(addr_i_2 = "0000") and (FIFO_Read = '1') and
                  (FIFO_Write = '0') and (data_Exists_I_3='0')) then
                addr_i_2 <= addr_i_2 - 1;
            else
                null;
            end if;
        end if;
    end process;

    ADDRS_3 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_3 <= "0000";
            elsif ((buffer_Full_3='0') and (FIFO_Write = '1') and
                  (FIFO_Read = '0') and (buffer_Full_2 = '1') and
                  (data_Exists_I_3='1')) then
                addr_i_3 <= addr_i_3 + 1;
            elsif (not(addr_i_3 = "0000") and (FIFO_Read = '1') and
                  (FIFO_Write = '0') and (data_Exists_I_4='0')) then
                addr_i_3 <= addr_i_3 - 1;
            else
                null;
            end if;
        end if;
    end process;

    ADDRS_4 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_4 <= "0000";
            elsif ((buffer_Full_4='0') and (FIFO_Write = '1') and
                  (FIFO_Read = '0') and (buffer_Full_3 = '1') and
                  (data_Exists_I_4='1')) then
                addr_i_4 <= addr_i_4 + 1;
            elsif (not(addr_i_4 = "0000") and (FIFO_Read = '1') and
                  (FIFO_Write = '0')) then
                addr_i_4 <= addr_i_4 - 1;
            else
                null;
            end if;
        end if;
    end process;

    ADDR_OUT : process (addr_i_1, addr_i_2, addr_i_3, addr_i_4,
                        data_Exists_I_2, data_Exists_I_3, data_Exists_I_4)
        begin
            if ( (data_Exists_I_2 = '0')   and
                 (data_Exists_I_3 = '0')   and
                 (data_Exists_I_4 = '0') )
            then
                Addr <= "00" & addr_i_1;
            elsif ( (data_Exists_I_3 = '0')   and
                    (data_Exists_I_4 = '0') )
            then
                Addr <= "01" & addr_i_2;
            elsif ( (data_Exists_I_4 = '0') )
            then
                Addr <= "10" & addr_i_3;
            else
                Addr <= "11" & addr_i_4;
            end if;
    end process;

    --------------------------------------------------------------------------
    -- Data Exists Instances
    --------------------------------------------------------------------------    

    DATA_EXISTS_1_DFF : FDR
        port map (
                  Q  => data_Exists_I_1,     -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_Data_Exists_1,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 ); 
                          
    DATA_EXISTS_2_DFF : FDR
      port map (
                Q  => data_Exists_I_2,       -- [out std_logic]
                C  => Clk,                   -- [in  std_logic]
                D  => next_Data_Exists_2,    -- [in  std_logic]
                R  => Reset                  -- [in  std_logic]
               );
                          
    DATA_EXISTS_3_DFF : FDR
      port map (
                Q  => data_Exists_I_3,       -- [out std_logic]
                C  => Clk,                   -- [in  std_logic]
                D  => next_Data_Exists_3,    -- [in  std_logic]
                R  => Reset                  -- [in  std_logic]
               );
                          
    DATA_EXISTS_4_DFF : FDR
      port map (
                Q  => data_Exists_I_4,       -- [out std_logic]
                C  => Clk,                   -- [in  std_logic]
                D  => next_Data_Exists_4,    -- [in  std_logic]
                R  => Reset                  -- [in  std_logic]
               );

    --------------------------------------------------------------------------
    -- Buffer Full Instances
    --------------------------------------------------------------------------

    BUFFER_FULL_1_DFF : FDR
        port map (
                  Q  => buffer_Full_1,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_1,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    BUFFER_FULL_2_DFF : FDR
        port map (
                  Q  => buffer_Full_2,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_2,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );
       
    BUFFER_FULL_3_DFF : FDR
        port map (
                  Q  => buffer_Full_3,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_3,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    BUFFER_FULL_4_DFF : FDR
        port map (
                  Q  => buffer_Full_4,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_buffer_Full_4,  -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- GENERATE FIFO RAMS
    --------------------------------------------------------------------------

    FIFO_RAM_1 : for I in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
              CE  => FIFO_Write_1,   -- [in  std_logic]
              D   => Data_In_1(I),   -- [in  std_logic]
              Clk => Clk,            -- [in  std_logic]
              A0  => addr_i_1(0),    -- [in  std_logic]
              A1  => addr_i_1(1),    -- [in  std_logic]
              A2  => addr_i_1(2),    -- [in  std_logic]
              A3  => addr_i_1(3),    -- [in  std_logic]
              Q   => Data_Out_1(I)   -- [out std_logic]
             );
    end generate FIFO_RAM_1; 

    FIFO_RAM_2 : for I in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
              CE  => FIFO_Write_2,    -- [in  std_logic]
              D   => Data_In_2(I),    -- [in  std_logic]
              Clk => Clk,             -- [in  std_logic]
              A0  => addr_i_2(0),     -- [in  std_logic]
              A1  => addr_i_2(1),     -- [in  std_logic]
              A2  => addr_i_2(2),     -- [in  std_logic]
              A3  => addr_i_2(3),     -- [in  std_logic]
              Q   => Data_Out_2(I)    -- [out std_logic]
             );
    end generate FIFO_RAM_2;

    FIFO_RAM_3 : for I in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
              CE  => FIFO_Write_3,    -- [in  std_logic]
              D   => Data_In_3(I),    -- [in  std_logic]
              Clk => Clk,             -- [in  std_logic]
              A0  => addr_i_3(0),     -- [in  std_logic]
              A1  => addr_i_3(1),     -- [in  std_logic]
              A2  => addr_i_3(2),     -- [in  std_logic]
              A3  => addr_i_3(3),     -- [in  std_logic]
              Q   => Data_Out_3(I)    -- [out std_logic]
             );
    end generate FIFO_RAM_3;

    FIFO_RAM_4 : for I in 0 to C_DWIDTH-1 generate
        SRL16E_I : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
              CE  => FIFO_Write_4,    -- [in  std_logic]
              D   => Data_In_4(I),    -- [in  std_logic]
              Clk => Clk,             -- [in  std_logic]
              A0  => addr_i_4(0),     -- [in  std_logic]
              A1  => addr_i_4(1),     -- [in  std_logic]
              A2  => addr_i_4(2),     -- [in  std_logic]
              A3  => addr_i_4(3),     -- [in  std_logic]
              Q   => Data_Out_4(I)    -- [out std_logic]
             );
    end generate FIFO_RAM_4;

end generate;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
--   GENERATE FOR C_DEPTH GREATER THAN 32, LESS THAN 65, 
--   AND VIRTEX-2 AND NEWER FAMILIES
------------------------------------------------------------------------------
------------------------------------------------------------------------------

C_DEPTH_32_64_V2 : if ( (C_DEPTH > 32) and (C_DEPTH < 65) and
                        ( equalIgnoreCase(C_FAMILY,"virtex2")  or
                          equalIgnoreCase(C_FAMILY,"virtex2p") or
                          equalIgnoreCase(C_FAMILY,"virtex4") ) )
generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    constant DEPTH : std_logic_vector(0 to 5) :=
                                        conv_std_logic_vector(C_DEPTH-1,6);

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i       : std_logic_vector(0 to 5);  
    signal buffer_Full  : std_logic;
    signal buffer_Empty : std_logic;

    signal next_Data_Exists : std_logic;
    signal data_Exists_I    : std_logic;

    signal valid_Write : std_logic;

    signal hsum_A  : std_logic_vector(0 to 5);
    signal sum_A   : std_logic_vector(0 to 5);
    signal addr_cy : std_logic_vector(0 to 6);
    
    signal D_Out_ls_1  : std_logic_vector(0 to C_DWIDTH-1); 
    signal D_Out_ls_2  : std_logic_vector(0 to C_DWIDTH-1); 
    signal D_Out_ls_3  : std_logic_vector(0 to C_DWIDTH-1); 
    signal D_Out_ms    : std_logic_vector(0 to C_DWIDTH-1); 
    signal Data_O_ls   : std_logic_vector(0 to C_DWIDTH-1); 
    signal Data_O_ms   : std_logic_vector(0 to C_DWIDTH-1); 
    signal q15_1       : std_logic_vector(0 to C_DWIDTH-1); 
    signal q15_2       : std_logic_vector(0 to C_DWIDTH-1); 
    signal q15_3       : std_logic_vector(0 to C_DWIDTH-1);

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------

    component SRL16E is
        -- pragma translate_off
        generic ( INIT : bit_vector := X"0000" );
        -- pragma translate_on    
        port (
              CE  : in  std_logic;
              D   : in  std_logic;
              Clk : in  std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              Q   : out std_logic
             );
    end component SRL16E;

    component MUXCY_L
        port (
              DI : in  std_logic;
              CI : in  std_logic;
              S  : in  std_logic;
              LO : out std_logic
             );
    end component;

    component XORCY
        port (
              LI : in  std_logic;
              CI : in  std_logic;
              O  : out std_logic
             );
    end component;
    
    component FDRE is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              CE : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDRE;

    component FDR is
        port (
              Q  : out std_logic;
              C  : in  std_logic;
              D  : in  std_logic;
              R  : in  std_logic
             );
    end component FDR;

    component MUXF5
        port (
              O  : out std_logic;
              I0 : in  std_logic;
              I1 : in  std_logic;
              S  : in  std_logic
             );
    end component;

    component MUXF6
        port (
              O  : out std_logic;
              I0 : in  std_logic;
              I1 : in  std_logic;
              S  : in  std_logic
             );
    end component;

    component SRLC16E
        -- pragma translate_off
        generic ( INIT : bit_vector := X"0000" );
        -- pragma translate_on    
        port (
              Q   : out std_logic;
              Q15 : out std_logic;
              A0  : in  std_logic;
              A1  : in  std_logic;
              A2  : in  std_logic;
              A3  : in  std_logic;
              CE  : in  std_logic;
              CLK : in  std_logic;
              D   : in  std_logic
             );
    end component;

    -- XST WA for CR183399 
    component LUT3
        generic( INIT : bit_vector := X"0" );
        port(
             O  : out std_ulogic;
             I0 : in  std_ulogic;
             I1 : in  std_ulogic;
             I2 : in  std_ulogic
             );
     end component;

    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------
  
    begin

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------

    --  buffer_Full <= '1' when (addr_i = "11111") else '0';
    buffer_Full <= '1' when (addr_i(0) = DEPTH(5) and
                             addr_i(1) = DEPTH(4) and
                             addr_i(2) = DEPTH(3) and
                             addr_i(3) = DEPTH(2) and
                             addr_i(4) = DEPTH(1) and
                             addr_i(5) = DEPTH(0)
                            ) else '0';

    FIFO_Full   <= buffer_Full;

    buffer_Empty <= '1' when (addr_i = "000000") else '0';

    FIFO_Empty <= not data_Exists_I;   -- generate a true empty flag with no delay
                                       -- was buffer_Empty, which had a clock dly

    next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                        (buffer_Empty and FIFO_Write) or
                        (data_Exists_I and not FIFO_Read);

    Data_Exists <= data_Exists_I;
    addr_cy(0)  <= valid_Write;

    --------------------------------------------------------------------------
    -- Data Exists DFF Instance
    --------------------------------------------------------------------------

    Data_Exists_DFF : FDR
        port map (
                  Q  => data_Exists_I,       -- [out std_logic]
                  C  => Clk,                 -- [in  std_logic]
                  D  => next_Data_Exists,    -- [in  std_logic]
                  R  => Reset                -- [in  std_logic]
                 );

    --------------------------------------------------------------------------
    -- Valid Write LUT Instance
    --------------------------------------------------------------------------
  
    -- XST CR183399 WA  
    --  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

    VALID_WRITE_I : LUT3 
      generic map ( INIT => X"8A" )
      port map (
                O  => valid_Write,           -- [out std_logic]
                I0 => FIFO_Write,            -- [in  std_logic]
                I1 => FIFO_Read,             -- [in  std_logic]
                I2 => buffer_Full            -- [in  std_logic]
               );
    --END XST WA for CR183399

    --------------------------------------------------------------------------
    -- GENERATE ADDRESS COUNTERS
    --------------------------------------------------------------------------

    ADDR_COUNTERS : for i in 0 to 5 generate

        hsum_A(I) <= (FIFO_Read xor addr_i(I)) and
                     (FIFO_Write or not buffer_Empty);

        MUXCY_L_I : MUXCY_L
            port map (
                      DI => addr_i(i),           -- [in  std_logic]
                      CI => addr_cy(i),          -- [in  std_logic]
                      S  => hsum_A(i),           -- [in  std_logic]
                      LO => addr_cy(i+1)         -- [out std_logic]
                     );

        XORCY_I : XORCY
            port map (
                      LI => hsum_A(i),           -- [in  std_logic]
                      CI => addr_cy(i),          -- [in  std_logic]
                      O  => sum_A(i)             -- [out std_logic]
                     );

        FDRE_I : FDRE
            port map (
                      Q  => addr_i(i),           -- [out std_logic]
                      C  => Clk,                 -- [in  std_logic]
                      CE => data_Exists_i,       -- [in  std_logic]
                      D  => sum_A(i),            -- [in  std_logic]
                      R  => Reset                -- [in  std_logic]
                     );

    end generate ADDR_COUNTERS;

    --------------------------------------------------------------------------
    -- GENERATE FIFO RAMS
    --------------------------------------------------------------------------

    FIFO_RAM : for i in 0 to C_DWIDTH-1 generate

        SRLC16E_LS1 : SRLC16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      Q   => D_Out_ls_1(i),  --[out]
                      Q15 => q15_1(i),       --[out]
                      A0  => addr_i(0),      --[in]
                      A1  => addr_i(1),      --[in]
                      A2  => addr_i(2),      --[in]
                      A3  => addr_i(3),      --[in]
                      CE  => valid_Write,    --[in]
                      CLK => Clk,            --[in]
                      D   => Data_In(i)      --[in]
                     );

        SRLC16E_LS2 : SRLC16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      Q   => D_Out_ls_2(i),  --[out]
                      Q15 => q15_2(i),       --[out]
                      A0  => addr_i(0),      --[in]
                      A1  => addr_i(1),      --[in]
                      A2  => addr_i(2),      --[in]
                      A3  => addr_i(3),      --[in]
                      CE  => valid_Write,    --[in]
                      CLK => Clk,            --[in]
                      D   => q15_1(i)        --[in]
                     );
       
        MUXF5_LS: MUXF5
            port map (
              O  => Data_O_LS(i),            --[out]
              I0 => D_Out_ls_1(I),           --[in]
              I1 => D_Out_ls_2(I),           --[in]
              S  => addr_i(4)                --[in]
             );
   
        
        SRLC16E_LS3 : SRLC16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      Q   => D_Out_ls_3(i),  --[out]
                      Q15 => q15_3(i),       --[out]
                      A0  => addr_i(0),      --[in]
                      A1  => addr_i(1),      --[in]
                      A2  => addr_i(2),      --[in]
                      A3  => addr_i(3),      --[in]
                      CE  => valid_Write,    --[in]
                      CLK => Clk,            --[in]
                      D   => q15_2(i)        --[in]
                     );

        SRL16E_MS : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      CE  => valid_Write,    --[in]
                      D   => q15_3(i),       --[in]
                      Clk => Clk,            --[in]
                      A0  => addr_i(0),      --[in]
                      A1  => addr_i(1),      --[in]
                      A2  => addr_i(2),      --[in]
                      A3  => addr_i(3),      --[in]
                      Q   => D_Out_ms(I)     --[out]
                     );
           
        MUXF5_MS: MUXF5
            port map (
                      O  => Data_O_MS(i),    --[out]
                      I0 => D_Out_ls_3(i),   --[in]
                      I1 => D_Out_ms(i),     --[in]
                      S  => addr_i(4)        --[in]
                     );
   
        MUXF6_I: MUXF6
            port map (
                      O  => Data_out(i),     --[out]
                      I0 => Data_O_ls(i),    --[in]
                      I1 => Data_O_ms(i),    --[in]
                      S  => addr_i(5)        --[in]
                     );

    end generate FIFO_RAM;

    --------------------------------------------------------------------------
    -- INT_ADDR_PROCESS
    --------------------------------------------------------------------------
    -- This process assigns the internal address to the output port
    --------------------------------------------------------------------------
    INT_ADDR_PROCESS:process (addr_i)
    begin
        for i in Addr'range
        loop
            Addr(i) <= addr_i(5 - i);  -- flip the bits to account for srl16 addr
        end loop;
    end process;
  
end generate;

end architecture imp;
