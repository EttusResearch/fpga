-------------------------------------------------------------------------------
--
-- File: TdcWrapper.vhd
-- Author: Daniel Jepson
-- Original Project: N310
-- Date: 22 June 2017
--
-------------------------------------------------------------------------------
-- (c) 2017 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
-------------------------------------------------------------------------------
--
-- Purpose:
--
-- Wrapper for the TDC VHDL so it works nicely with Verilog types.
--
-- vreview_group Tdc
-- vreview_reviewers dabaker sgupta jmarsar
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity TdcWrapper is
  port (
    -- Clocks and Resets : --------------------------------------------------------------
    -- Asynchronous global reset.
    aReset          : in  std_logic;
    -- Reference Clock
    RefClk          : in  std_logic;
    -- Sample Clock
    SampleClk       : in  std_logic;
    -- Measurement Clock must run at a very specific frequency, determined by the
    -- SampleClk, RefClk, and Sync Pulse rates... oh and a lot of math.
    MeasClk         : in  std_logic;


    -- Controls and Status : ------------------------------------------------------------
    -- Soft reset for the module. Wait until rResetTdcDone asserts before de-asserting
    -- the reset.
    rResetTdc          : in  std_logic;
    rResetTdcDone      : out std_logic;
    -- Once enabled, the TDC waits for the next PPS pulse to begin measurements. Leave
    -- this signal asserted for the measurement duration (there is no need to de-assert
    -- it unless you want to capture a different PPS edge).
    rEnableTdc         : in  std_logic;
    -- Assert this bit to allow the TDC to perform repeated measurements.
    rReRunEnable       : in  std_logic;

     -- Only required to pulse 1 RefClk cycle.
    rPpsPulse          : in  std_logic;
     -- Debug, held asserted when pulse is captured.
    rPpsPulseCaptured  : out std_logic;


    -- Crossing PPS into Sample Clock : -------------------------------------------------
    -- Enable crossing rPpsPulse into SampleClk domain. This should remain de-asserted
    -- until the TDC measurements are complete and sPpsClkCrossDelayVal is written.
    rEnablePpsCrossing   : in  std_logic;
    -- Programmable delay value for crossing clock domains. This is used to compensate
    -- for differences in sRTC pulses across modules. This value is typically set once
    -- after running initial synchronization.
    sPpsClkCrossDelayVal : in  std_logic_vector(3 downto 0);
    -- PPS pulse output on the SampleClk domain.
    sPpsPulse            : out std_logic;


    -- FTDC Measurement Results : -------------------------------------------------------
    -- Final FTDC measurements in MeasClk ticks. Done will assert when Offset
    -- becomes valid and will remain asserted until aReset or mResetTdc asserts.
    -- FXP<+40,13> (13 integer bits... determined by the constants below)
    mRspOffset      : out std_logic_vector(39 downto 0);
    mRtcOffset      : out std_logic_vector(39 downto 0);
    mOffsetsDone    : out std_logic;
    mOffsetsValid   : out std_logic;


    -- Setup for Sync Pulses : ----------------------------------------------------------
    -- Only load these counts when rResetTdc is asserted and rEnableTdc is de-asserted!!!
    -- If both of the above conditions are met, load the counts by pulsing Load
    -- when the counts are valid. It is not necessary to keep the count values valid
    -- after pulsing Load.
    rLoadRspCounts      : in std_logic;
    rRspPeriodInRClks   : in std_logic_vector(11 downto 0);
    rRspHighTimeInRClks : in std_logic_vector(11 downto 0);
    sLoadRtcCounts      : in std_logic;
    sRtcPeriodInSClks   : in std_logic_vector(11 downto 0);
    sRtcHighTimeInSClks : in std_logic_vector(11 downto 0);


    -- Sync Pulse Outputs : -------------------------------------------------------------
    -- The repeating pulses can be useful for many things, including passing triggers.
    rRSP               : out std_logic;
    sRTC               : out std_logic;

    -- Pin bouncers out and in. Must go to unused and unconnected pins on the FPGA!
    rGatedPulseToPin   : inout std_logic;
    sGatedPulseToPin   : inout std_logic
  );
end TdcWrapper;


architecture struct of TdcWrapper is

  -- Generic values for the TdcTop instantiation below. These generics are the maximum
  -- of possible values for all combinations of Sample and Reference clocks for the N310
  -- family of devices.
  constant kRClksPerRspPeriodBitsMax  : integer := 12;
  constant kSClksPerRtcPeriodBitsMax  : integer := 12;
  constant kPulsePeriodCntSize        : integer := 13;
  -- The following are ideal values for balancing measurement time and accuracy, based
  -- on calcs given in the spec doc.
  constant kFreqRefPeriodsToCheckSize : integer := 17;
  constant kSyncPeriodsToStampSize    : integer := 10;

  --vhook_sigstart
  signal aResetBool: boolean;
  signal mOffsetsDoneBool: boolean;
  signal mOffsetsValidBool: boolean;
  signal mRspOffsetUns: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal mRtcOffsetUns: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal rEnablePpsCrossingBool: boolean;
  signal rEnableTdcBool: boolean;
  signal rLoadRspCountsBool: boolean;
  signal rPpsPulseBool: boolean;
  signal rPpsPulseCapturedBool: boolean;
  signal rReRunEnableBool: boolean;
  signal rResetTdcBool: boolean;
  signal rResetTdcDoneBool: boolean;
  signal rRSPBool: boolean;
  signal rRspHighTimeInRClksUns: unsigned(kRClksPerRspPeriodBitsMax-1 downto 0);
  signal rRspPeriodInRClksUns: unsigned(kRClksPerRspPeriodBitsMax-1 downto 0);
  signal sLoadRtcCountsBool: boolean;
  signal sPpsClkCrossDelayValUns: unsigned(3 downto 0);
  signal sPpsPulseBool: boolean;
  signal sRTCBool: boolean;
  signal sRtcHighTimeInSClksUns: unsigned(kSClksPerRtcPeriodBitsMax-1 downto 0);
  signal sRtcPeriodInSClksUns: unsigned(kSClksPerRtcPeriodBitsMax-1 downto 0);
  --vhook_sigend

  function to_StdLogic(b : boolean) return std_ulogic is
  begin
    if b then
      return '1';
    else
      return '0';
    end if;
  end to_StdLogic;

  function to_Boolean (s : std_ulogic) return boolean is
  begin
    return (To_X01(s)='1');
  end to_Boolean;

begin

  -- Inputs
  aResetBool             <= to_Boolean(aReset);
  rResetTdcBool          <= to_Boolean(rResetTdc);
  rEnableTdcBool         <= to_Boolean(rEnableTdc);
  rReRunEnableBool       <= to_Boolean(rReRunEnable);
  rLoadRspCountsBool     <= to_Boolean(rLoadRspCounts);
  sLoadRtcCountsBool     <= to_Boolean(sLoadRtcCounts);
  rPpsPulseBool          <= to_Boolean(rPpsPulse);
  rEnablePpsCrossingBool <= to_Boolean(rEnablePpsCrossing);
  rRspPeriodInRClksUns   <= unsigned(rRspPeriodInRClks);
  rRspHighTimeInRClksUns <= unsigned(rRspHighTimeInRClks);
  sRtcPeriodInSClksUns   <= unsigned(sRtcPeriodInSClks);
  sRtcHighTimeInSClksUns <= unsigned(sRtcHighTimeInSClks);

  -- Outputs
  rResetTdcDone      <= to_stdlogic(rResetTdcDoneBool);
  rPpsPulseCaptured  <= to_stdlogic(rPpsPulseCapturedBool);
  mOffsetsDone       <= to_stdlogic(mOffsetsDoneBool);
  mOffsetsValid      <= to_stdlogic(mOffsetsValidBool);
  rRSP         <= to_stdlogic(rRSPBool);
  sRTC         <= to_stdlogic(sRTCBool);
  sPpsPulse    <= to_stdlogic(sPpsPulseBool);

  mRspOffset <= std_logic_vector(mRspOffsetUns);
  mRtcOffset <= std_logic_vector(mRtcOffsetUns);
  sPpsClkCrossDelayValUns <= unsigned(sPpsClkCrossDelayVal);

  --vhook_e TdcTop
  --vhook_a aReset             aResetBool
  --vhook_a rResetTdc          rResetTdcBool
  --vhook_a rResetTdcDone      rResetTdcDoneBool
  --vhook_a rEnableTdc         rEnableTdcBool
  --vhook_a rReRunEnable       rReRunEnableBool
  --vhook_a rPpsPulse          rPpsPulseBool
  --vhook_a rLoadRspCounts     rLoadRspCountsBool
  --vhook_a sLoadRtcCounts     sLoadRtcCountsBool
  --vhook_a rPpsPulseCaptured  rPpsPulseCapturedBool
  --vhook_a rEnablePpsCrossing rEnablePpsCrossingBool
  --vhook_a mOffsetsDone       mOffsetsDoneBool
  --vhook_a mOffsetsValid      mOffsetsValidBool
  --vhook_a mRspOffset         mRspOffsetUns
  --vhook_a mRtcOffset         mRtcOffsetUns
  --vhook_a sPpsClkCrossDelayVal sPpsClkCrossDelayValUns
  --vhook_a rRSP               rRSPBool
  --vhook_a sRTC               sRTCBool
  --vhook_a sPpsPulse          sPpsPulseBool
  --vhook_p {^rR(.*)In(.*)Clks} rR$1In$2ClksUns
  --vhook_p {^sR(.*)In(.*)Clks} sR$1In$2ClksUns
  TdcTopx: entity work.TdcTop (struct)
    generic map (
      kRClksPerRspPeriodBitsMax  => kRClksPerRspPeriodBitsMax,   --integer range 3:16 :=12
      kSClksPerRtcPeriodBitsMax  => kSClksPerRtcPeriodBitsMax,   --integer range 3:16 :=12
      kPulsePeriodCntSize        => kPulsePeriodCntSize,         --integer:=13
      kFreqRefPeriodsToCheckSize => kFreqRefPeriodsToCheckSize,  --integer:=17
      kSyncPeriodsToStampSize    => kSyncPeriodsToStampSize)     --integer:=10
    port map (
      aReset               => aResetBool,               --in  boolean
      RefClk               => RefClk,                   --in  std_logic
      SampleClk            => SampleClk,                --in  std_logic
      MeasClk              => MeasClk,                  --in  std_logic
      rResetTdc            => rResetTdcBool,            --in  boolean
      rResetTdcDone        => rResetTdcDoneBool,        --out boolean
      rEnableTdc           => rEnableTdcBool,           --in  boolean
      rReRunEnable         => rReRunEnableBool,         --in  boolean
      rPpsPulse            => rPpsPulseBool,            --in  boolean
      rPpsPulseCaptured    => rPpsPulseCapturedBool,    --out boolean
      rEnablePpsCrossing   => rEnablePpsCrossingBool,   --in  boolean
      sPpsClkCrossDelayVal => sPpsClkCrossDelayValUns,  --in  unsigned(3:0)
      sPpsPulse            => sPpsPulseBool,            --out boolean
      mRspOffset           => mRspOffsetUns,            --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mRtcOffset           => mRtcOffsetUns,            --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mOffsetsDone         => mOffsetsDoneBool,         --out boolean
      mOffsetsValid        => mOffsetsValidBool,        --out boolean
      rLoadRspCounts       => rLoadRspCountsBool,       --in  boolean
      rRspPeriodInRClks    => rRspPeriodInRClksUns,     --in  unsigned(kRClksPerRspPeriodBitsMax-1:0)
      rRspHighTimeInRClks  => rRspHighTimeInRClksUns,   --in  unsigned(kRClksPerRspPeriodBitsMax-1:0)
      sLoadRtcCounts       => sLoadRtcCountsBool,       --in  boolean
      sRtcPeriodInSClks    => sRtcPeriodInSClksUns,     --in  unsigned(kSClksPerRtcPeriodBitsMax-1:0)
      sRtcHighTimeInSClks  => sRtcHighTimeInSClksUns,   --in  unsigned(kSClksPerRtcPeriodBitsMax-1:0)
      rRSP                 => rRSPBool,                 --out boolean
      sRTC                 => sRTCBool,                 --out boolean
      rGatedPulseToPin     => rGatedPulseToPin,         --inout std_logic
      sGatedPulseToPin     => sGatedPulseToPin);        --inout std_logic


end struct;


