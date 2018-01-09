-------------------------------------------------------------------------------
--
-- File: PkgJesdConfig.vhd
-- Author: National Instruments
-- Original Project: NI 5840
-- Date: 11 March 2016
--
-------------------------------------------------------------------------------
-- Copyright 2016-2018 Ettus Research, A National Instruments Company
-- SPDX-License-Identifier: LGPL-3.0
-------------------------------------------------------------------------------
--
-- Purpose: JESD204B setup constants and functions. These constants are shared
--          between RX and TX JESD cores.
--
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
  constant kJesdDrpRegsInEndpoint : RegOffset_t := (kOffset => 16#0800#,   -- 0x2800 to
                                                    kWidth  => 16#0800#);  -- 0x2FFF

  -- Selects the UsrClk2 for the transceivers. For 64-bit wide transceivers, the
  -- UsrClk = 2*UserClk2 frequency. For 32-bit wide transceivers, UsrClk = UserClk2
  -- frequency. This is a generalization, the clock ratio should be confirmed based on
  -- the transceiver configuration.
  -- The N310 transceivers use the single rate reference, hence = false.
  constant kDoubleRateUsrClk : boolean := false;

  -- For the N310, all lanes are in one quad and we use the QPLL.
  constant kJesdUseQpll : boolean := true;

  constant kAdcDataWidth     : integer := 14; -- ADC data width in bits
  constant kDacDataWidth     : integer := 16; -- DAC data width in bits
  --vhook_wrn Note: SampleClk1x = 245.76 MHz; therefore we have 2 samples p/ cycle (Conv. @ 491.52 MSPS).
  constant kSamplesPerCycle  : integer := 2;  -- Number of samples per SampleClk1x

  constant kGtxDrpAddrWidth    : natural := 9;
  constant kGtxAddrLsbPosition : natural := 2;
  constant kQpllDrpAddrWidth   : natural := 8;
  constant kGtxDrpDataWidth    : natural := 16;
  
  -- Max supported number of lanes
  constant kMaxNumLanes      : natural := 4;
  -- Max supported number of quads (normally there is 1 quad per 4 lanes but disconnect
  -- the definitions to allow quad sharing)
  constant kMaxNumQuads      : natural := 1;

  -- Rhodium:
  -- JESD shared setup - LMFS = 4211, HD = 1 (Samples are split across multiple lanes).
  constant kNumLanes               : natural   := 4;             -- L
  constant kNumConvs               : positive  := 2;             -- M
  constant kOctetsPerFrame         : natural   := 1;             -- F
  constant kDacJesdSamplesPerCycle : integer   := 1;             -- S
  constant kOctetsPerLane          : natural   := 2;             -- MGT data is kOctetsPerLane*8 = 16 bits wide
  constant kNumQuads               : natural   := kNumLanes/4;   -- 4 lanes per quad
  constant kHighDensity            : boolean   := true;          -- HD
  constant kConvResBits            : positive  := kDacDataWidth; -- Converter resolution in bits
  constant kConvSampleBits         : positive  := 16;            -- Sample Length in bits
  constant kInitLaneAlignCnt       : positive  := 4;
  constant kFramesPerMulti         : natural   := 24;            -- K

  -- Rhodium:
  -- The converters are running at 491.52 MSPS (DeviceClk), and the sampling clock at the
  -- FPGA (UserClk) is 245.76 MHz (491.52 / 2).
  --vhook_wrn For Rev. A the frame rate = DeviceClk = 491.52 MSPS
  -- Therefore, the frame rate is at DeviceClk freq., and the Multiframe rate is
  -- (frame rate / kFramesPerMulti) = 491.52 MHz / 24 = 20.48 MHz.
  -- kUserClksPerMulti is the (UsrClk rate / Multiframe rate) = 245.76 / 20.48 = 12
  constant kUserClksPerMulti : integer := 12;


  type NaturalVector is array ( natural range <>) of natural;


  --vhook_wrn Update PCB connections between transceivers and devices.

  -- The PCB connections are as follows:
  --
  --   Transceiver  MGT Channel   ADC Lane    DAC Lane
  --   ***********  ***********   ********    ********
  --   GT0: X0Y8        0            0           0
  --   GT1: X0Y9        1            1           1
  --   GT2: X0Y10       2            2           2
  --   GT3: X0Y11       3            3           3
  constant kRxLaneIndices : NaturalVector(kNumLanes - 1 downto 0) :=
    (
 -- MGT => ADC (in above table)
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3
    );

  constant kTxLaneIndices : NaturalVector(kNumLanes - 1 downto 0) :=
    (
 -- MGT => DAC lane
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3
    );

  constant kLaneToQuadMap : NaturalVector(kNumLanes - 1 downto 0) :=
    (
      -- All lanes are in one quad
      0 => 0,
      1 => 0,
      2 => 0,
      3 => 0
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
      1 => b"001", -- Master
      2 => b"000", -- Control from 1
      3 => b"000"  -- Control from 1
    );


  -- User Rx Data
  -- ADC Word data width: 14 sample bits + 2 tails bits
  constant kAdcWordWidth : integer := 16;
  subtype AdcWord_t is std_logic_vector(kAdcWordWidth - 1 downto 0);
  type AdcWordArray_t is array(kSamplesPerCycle*2 - 1 downto 0) of AdcWord_t; -- The *2 is because there are two samples (I and Q) per "sample"

  -- Constants to specify the contents of the AdcWord_t vector.
  constant kAdcWordDataMsb : integer := 15;
  constant kAdcWordDataLsb : integer := 2;
  constant kAdcWordOver    : integer := 1;
  constant kAdcWordCBit1   : integer := 0;


  -- Option to pipeline stages to improve timing, if needed
  constant kPipelineDetectCharsStage : boolean := false;
  constant kPipelineCharReplStage    : boolean := false;
  

  -- Data manipulation settings.
  type DataSettings_t is record
    InvertA  : std_logic;
    InvertB  : std_logic;
    ZeroA    : std_logic;
    ZeroB    : std_logic;
    AisI     : std_logic;
    BisQ     : std_logic;
  end record;

  constant kDataSettingsSize : integer := 6;
  subtype DataSettingsFlat_t is std_logic_vector(kDataSettingsSize - 1 downto 0);

  function   Flatten(TypeIn : DataSettings_t)                                   return std_logic_vector;
  function Unflatten(SlvIn  : std_logic_vector(kDataSettingsSize - 1 downto 0)) return DataSettings_t;

end package;


package body PkgJesdConfig is

  -- Data manipulation settings.
  function   Flatten(TypeIn     : DataSettings_t)   return std_logic_vector
  is
    variable ReturnVar : std_logic_vector(kDataSettingsSize - 1 downto 0);
  begin
    ReturnVar := (TypeIn.InvertA) &
                 (TypeIn.InvertB) &
                 (TypeIn.ZeroA)   &
                 (TypeIn.ZeroB)   &
                 (TypeIn.AisI)    &
                 (TypeIn.BisQ);
   return ReturnVar;
  end function Flatten;

  function Unflatten(SlvIn : std_logic_vector(kDataSettingsSize - 1 downto 0)) return DataSettings_t
  is
    variable ReturnVar : DataSettings_t;
  begin
    ReturnVar.InvertA := (SlvIn(5));
    ReturnVar.InvertB := (SlvIn(4));
    ReturnVar.ZeroA   := (SlvIn(3));
    ReturnVar.ZeroB   := (SlvIn(2));
    ReturnVar.AisI    := (SlvIn(1));
    ReturnVar.BisQ    := (SlvIn(0));
    return ReturnVar;
  end function Unflatten;

end package body;