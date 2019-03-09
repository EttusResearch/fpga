-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
--
-- Purpose: JESD204B setup constants and functions.
--
-- vreview_group JesdCore
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgRegs.all;

package PkgJesdConfig is

  -- "JESD" in ASCII - with the core number 0 or 1 on the LSb.
  constant kJesdSignature : std_logic_vector(31 downto 0) := x"4a455344";

  -- Register endpoints
  constant kJesdRegsInEndpointA   : RegOffset_t := (kOffset => 16#0000#,   -- 0x2000 to
                                                    kWidth  => 16#1000#);  -- 0x21FF
  constant kJesdRegsInEndpointB   : RegOffset_t := (kOffset => 16#1000#,   -- 0x3000 to
                                                    kWidth  => 16#1000#);  -- 0x31FF
  constant kJesdDrpRegsInEndpoint : RegOffset_t := (kOffset => 16#0800#,   -- 0x2800 to
                                                    kWidth  => 16#0800#);  -- 0x2FFF


  -- Selects the UsrClk2 for the transceivers. For 64-bit wide transceivers, the
  -- UsrClk = 2*UserClk2 frequency. For 32-bit wide transceivers, UsrClk = UserClk2
  -- frequency. This is a generalization, the clock ratio should be confirmed based on 
  -- the transceiver configuration.
  -- The EISCAT transceivers use the single rate reference, hence = false.
  constant kDoubleRateUsrClk : boolean := false;

  constant kAdcDataWidth     : integer := 16; -- ADC data width in bits. The 2 LSbs = 0s.
  constant kSamplesPerCycle  : integer := 1;  -- Number of samples per SampleClk1x

  constant kGtxDrpAddrWidth  : natural := 9;
  constant kQpllDrpAddrWidth : natural := 8;
  -- Max supported number of lanes
  constant kMaxNumLanes      : natural := 4;
  -- Max supported number of quads (normally there is 1 quad per 4 lanes but disconnect
  -- the definitions to allow quad sharing)
  constant kMaxNumQuads      : natural := 1;


  -- JESD setup - LMFS = 2441, HD = 0
  -- While several of these constants are marked as unused, it is helpful to leave them
  -- here for reference (the values are correct!).
  constant kNumLanes               : natural   := 2;     -- L
  constant kNumConvs               : positive  := 4;     -- M unused for EISCAT
  constant kOctetsPerFrame         : natural   := 4;     -- F
  constant kDacJesdSamplesPerCycle : integer   := 1;     -- S unused for EISCAT
  constant kOctetsPerLane          : natural   := 4;     -- MGT data is kOctetsPerLane*8 = 32 bits wide
  constant kNumQuads               : natural   := 1;     -- unused for EISCAT
  constant kHighDensity            : boolean   := false; -- HD unused for EISCAT
  constant kFramesPerMulti         : natural   := 16;    -- K

  -- In the EISCAT case we are one SPC, so this value is simply the number of frames
  -- (samples) per multiframe. Used in the RX core.
  constant kUserClksPerMulti : integer := kFramesPerMulti;

  type NaturalVector is array ( natural range <>) of natural;

  -- The lanes are swapped on the motherboard, but since we're RX only and not going to
  -- run CheckPAR on this design, we're OK with leaving these matching here and fixing
  -- it in the XDC file.
  constant kRxLaneIndices : NaturalVector(kNumLanes - 1 downto 0) :=
    (
      -- MGT => ADC (in above table)
      0 => 0,
      1 => 1
    );


  -- The master transceiver channel for channel bonding. E(kMasterBondingChannel)
  -- must have the highest value decrementing to b"000" for that last channels to bond.
  constant kMasterBondingChannel : integer := 1;

  -- Channel bonding occurs when a master detects a K-char sequence and aligns its
  -- internal FIFO to the start of this sequence. A signal is then generated to other 
  -- slave transceivers that cause them to bond to the sequence - this bonding signal is
  -- cascaded from master to slave to slave to slave, etc where each slave must know how
  -- many levels to the master there are. The last slave to bond must be at level b"000"
  -- and the master is at the highest level; the number of levels in the sequence is
  -- governed by the size of the transceiver FIFO (see the Xilinx user guides for more
  -- information).
  type BondLevels_t is array(0 to kNumLanes - 1) of std_logic_vector(2 downto 0);
  constant kBondLevel : BondLevels_t := (
      0 => b"000", -- Control from 1
      1 => b"001"  -- Master
    );


  -- User Rx Data
  -- ADC Word data width: 16 sample bits (EISCAT)
  constant kAdcWordWidth : integer := kAdcDataWidth;
  subtype AdcWord_t is std_logic_vector(kAdcWordWidth - 1 downto 0);
  type AdcWordArray_t is array(kSamplesPerCycle*4 - 1 downto 0) of AdcWord_t; 
  -- The *4 is because there are four channels per "sample" of each ADC.


  -- Option to pipeline stages to improve timing, if needed
  constant kPipelineDetectCharsStage : boolean := false;
  constant kPipelineCharReplStage    : boolean := false;

end package;
