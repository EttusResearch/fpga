
-------------------------------------------------------------------------------
-- counter_f - entity/architecture pair
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
-- ** Copyright (c) 2006-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        counter_f.vhd
--
-- Description:     Implements a parameterizable N-bit counter_f
--                      Up/Down Counter
--                      Count Enable
--                      Parallel Load
--                      Synchronous Reset
--                      The structural implementation has incremental cost
--                      of one LUT per bit.
--                      Precedence of operations when simultaneous:
--                        reset, load, count
--
--                  A default inferred-RTL implementation is provided and
--                  is used if the user explicitly specifies C_FAMILY=nofamily
--                  or ommits C_FAMILY (allowing it to default to nofamily).
--                  The default implementation is also used
--                  if needed primitives are not available in FPGAs of the
--                  type given by C_FAMILY.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  counter_f.vhd
--                      family_support.vhd
--
-------------------------------------------------------------------------------
-- Author: FLO & Nitin   06/06/2006   First Version, functional equivalent
--                                    of counter.vhd.
-- History:
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
use IEEE.numeric_std.unsigned;
use IEEE.numeric_std."+";
use IEEE.numeric_std."-";

library unisim;
use unisim.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.family_support.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity counter_f is
    generic(
            C_NUM_BITS : integer := 9;
            C_FAMILY   : string := "nofamily"
           );

    port(
         Clk           : in  std_logic;
         Rst           : in  std_logic;
         Load_In       : in  std_logic_vector(C_NUM_BITS - 1 downto 0);
         Count_Enable  : in  std_logic;
         Count_Load    : in  std_logic;
         Count_Down    : in  std_logic;
         Count_Out     : out std_logic_vector(C_NUM_BITS - 1 downto 0);
         Carry_Out     : out std_logic
        );
end entity counter_f;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of counter_f is

    ---------------------------------------------------------------------
    -- Component declarations
    ---------------------------------------------------------------------  
    component MUXCY_L is
      port (
        DI : in  std_logic;
        CI : in  std_logic;
        S  : in  std_logic;
        LO : out std_logic);
    end component MUXCY_L;

    component XORCY is
      port (
        LI : in  std_logic;
        CI : in  std_logic;
        O  : out std_logic);
    end component XORCY;

    component FDRE is
      port (
        Q  : out std_logic;
        C  : in  std_logic;
        CE : in  std_logic;
        D  : in  std_logic;
        R  : in  std_logic
      );
    end component FDRE;

    ---------------------------------------------------------------------
    -- Constant declarations
    ---------------------------------------------------------------------
    constant USE_STRUCTURAL_A : boolean :=
             supported(C_FAMILY, (u_MUXCY_L, u_XORCY, u_FDRE));
  
    constant USE_INFERRED : boolean := not USE_STRUCTURAL_A;

---------------------------------------------------------------------
-- Begin architecture
---------------------------------------------------------------------
begin

    ---------------------------------------------------------------------
    -- Generate structural code
    ---------------------------------------------------------------------
    STRUCTURAL_A_GEN : if USE_STRUCTURAL_A generate

        signal alu_cy         : std_logic_vector(C_NUM_BITS+1 downto 0);
        signal alu_cy_init    : std_logic;
        signal icount_out     : std_logic_vector(C_NUM_BITS downto 0);
        signal icount_out_x   : std_logic_vector(C_NUM_BITS downto 0);
        signal load_in_x      : std_logic_vector(C_NUM_BITS downto 0);
        signal count_AddSub   : std_logic_vector(C_NUM_BITS downto 0);
        signal count_Result   : std_logic_vector(C_NUM_BITS downto 0);
        signal count_clock_en : std_logic;

    begin

        alu_cy_init <= (Count_Down and Count_Load) or
                       (not Count_Down and not Count_load);

        I_MUXCY_I : component MUXCY_L
          port map (
            DI => '0',
            CI => '1',
            S  => alu_cy_init,
            LO => alu_cy(0));

        count_clock_en <= Count_Enable or Count_Load;

        load_in_x    <= ('0' & Load_In);

        -- Mask out carry position to retain legacy self-clear on next enable.
        icount_out_x <= ('0' & icount_out(C_NUM_BITS-1 downto 0));

        -----------------------------------------------------------------
        -- Generate counter using MUXCY_L, XORCY and FDRE
        -----------------------------------------------------------------
        I_ADDSUB_GEN : for i in 0 to C_NUM_BITS generate

            count_AddSub(i) <= load_in_x(i) xor Count_Down
                                            when Count_Load ='1' else
                               icount_out_x(i) xor Count_Down ; -- LUT

            MUXCY_I : component MUXCY_L
              port map (
                DI => Count_Down,
                CI => alu_cy(i),
                S  => count_AddSub(i),
                LO => alu_cy(i+1));

            XOR_I : component XORCY
              port map (
                LI => count_AddSub(i),
                CI => alu_cy(i),
                O  => count_Result(i));

            FDRE_I: component FDRE
              port map (
                Q  => iCount_Out(i),
                C  => Clk,
                CE => count_clock_en,
                D  => count_Result(i),
                R  => Rst);      

        end generate I_ADDSUB_GEN;


        Carry_Out <= icount_out(C_NUM_BITS);
        Count_Out <= icount_out(C_NUM_BITS-1 downto 0);

    end generate STRUCTURAL_A_GEN;


    ---------------------------------------------------------------------
    -- Generate Inferred code
    ---------------------------------------------------------------------
    --INFERRED_GEN : if USE_INFERRED generate
    INFERRED_GEN : if (not USE_STRUCTURAL_A) generate

        signal icount_out    : unsigned(C_NUM_BITS downto 0);
        signal icount_out_x  : unsigned(C_NUM_BITS downto 0);
        signal load_in_x     : unsigned(C_NUM_BITS downto 0);

    begin

        load_in_x    <= unsigned('0' & Load_In);

        -- Mask out carry position to retain legacy self-clear on next enable.
 --        icount_out_x <= ('0' & icount_out(C_NUM_BITS-1 downto 0)); -- Echeck WA
         icount_out_x <= unsigned('0' & std_logic_vector(icount_out(C_NUM_BITS-1 downto 0)));

        -----------------------------------------------------------------
        -- Process to generate counter with - synchronous reset, load,
        -- counter enable, count down / up features.
        -----------------------------------------------------------------
        CNTR_PROC : process(Clk)
        begin
            if Clk'event and Clk = '1' then
                if Rst = '1' then
                    icount_out <= (others => '0');
                elsif Count_Load = '1' then
                    icount_out <= load_in_x;
                elsif Count_Down = '1'  and Count_Enable = '1' then
                    icount_out <= icount_out_x - 1;
                elsif Count_Enable = '1' then
                    icount_out <= icount_out_x + 1;
                end if;
            end if;
        end process CNTR_PROC;

        Carry_Out <= icount_out(C_NUM_BITS);
        Count_Out <= std_logic_vector(icount_out(C_NUM_BITS-1 downto 0));

    end generate INFERRED_GEN;


end architecture imp;
---------------------------------------------------------------
-- End of file counter_f.vhd
---------------------------------------------------------------
