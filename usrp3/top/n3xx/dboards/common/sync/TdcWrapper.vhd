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
    -- for differences in sSpTransfer pulses across modules. This value is typically set once
    -- after running initial synchronization.
    sPpsClkCrossDelayVal : in  std_logic_vector(3 downto 0);
    -- PPS pulse output on the SampleClk domain.
    sPpsPulse            : out std_logic;


    -- FTDC Measurement Results : -------------------------------------------------------
    -- Final FTDC measurements in MeasClk ticks. Done will assert when Offset
    -- becomes valid and will remain asserted until aReset or mResetTdc asserts.
    -- FXP<+40,13> (13 integer bits... determined by the constants below)
    mRpOffset       : out std_logic_vector(39 downto 0);
    mSpOffset       : out std_logic_vector(39 downto 0);
    mOffsetsDone    : out std_logic;
    mOffsetsValid   : out std_logic;


    -- Setup for Sync Pulses : ----------------------------------------------------------
    -- Only load these counts when rResetTdc is asserted and rEnableTdc is de-asserted!!!
    -- If both of the above conditions are met, load the counts by pulsing Load
    -- when the counts are valid. It is not necessary to keep the count values valid
    -- after pulsing Load.
    rLoadRePulseCounts      : in std_logic;
    rRePulsePeriodInRClks   : in std_logic_vector(23 downto 0);
    rRePulseHighTimeInRClks : in std_logic_vector(23 downto 0);
    rLoadRpCounts       : in std_logic;
    rRpPeriodInRClks    : in std_logic_vector(15 downto 0);
    rRpHighTimeInRClks  : in std_logic_vector(15 downto 0);
    rLoadRptCounts      : in std_logic;
    rRptPeriodInRClks   : in std_logic_vector(15 downto 0);
    rRptHighTimeInRClks : in std_logic_vector(15 downto 0);
    sLoadSpCounts       : in std_logic;
    sSpPeriodInSClks    : in std_logic_vector(15 downto 0);
    sSpHighTimeInSClks  : in std_logic_vector(15 downto 0);
    sLoadSptCounts      : in std_logic;
    sSptPeriodInSClks   : in std_logic_vector(15 downto 0);
    sSptHighTimeInSClks : in std_logic_vector(15 downto 0);


    -- Sync Pulse Outputs : -------------------------------------------------------------
    -- The repeating pulses can be useful for many things, including passing triggers.
    rRpTransfer : out std_logic;
    sSpTransfer : out std_logic;

    -- Pin bouncers out and in. Must go to unused and unconnected pins on the FPGA!
    rGatedPulseToPin : inout std_logic;
    sGatedPulseToPin : inout std_logic
  );
end TdcWrapper;


architecture struct of TdcWrapper is

  -- Generic values for the TdcTop instantiation below. These generics are the maximum
  -- of possible values for all combinations of Sample and Reference clocks for the N3xx
  -- family of devices.
  constant kRClksPerRePulsePeriodBitsMax : integer := 24;
  constant kRClksPerRpPeriodBitsMax      : integer := 16;
  constant kSClksPerSpPeriodBitsMax      : integer := 16;
  constant kPulsePeriodCntSize           : integer := 13;
  -- The following are ideal values for balancing measurement time and accuracy, based
  -- on calcs given in the spec doc.
  constant kFreqRefPeriodsToCheckSize : integer := 17;
  constant kSyncPeriodsToStampSize    : integer := 10;

  --vhook_sigstart
  signal aResetBool: boolean;
  signal mOffsetsDoneBool: boolean;
  signal mOffsetsValidBool: boolean;
  signal mRpOffsetUns: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal mSpOffsetUns: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal rEnablePpsCrossingBool: boolean;
  signal rEnableTdcBool: boolean;
  signal rLoadRePulseCountsBool: boolean;
  signal rLoadRpCountsBool: boolean;
  signal rLoadRptCountsBool: boolean;
  signal rPpsPulseBool: boolean;
  signal rPpsPulseCapturedBool: boolean;
  signal rRePulseHighTimeInRClksUns: unsigned(kRClksPerRePulsePeriodBitsMax-1 downto 0);
  signal rRePulsePeriodInRClksUns: unsigned(kRClksPerRePulsePeriodBitsMax-1 downto 0);
  signal rReRunEnableBool: boolean;
  signal rResetTdcBool: boolean;
  signal rResetTdcDoneBool: boolean;
  signal rRpHighTimeInRClksUns: unsigned(kRClksPerRpPeriodBitsMax-1 downto 0);
  signal rRpPeriodInRClksUns: unsigned(kRClksPerRpPeriodBitsMax-1 downto 0);
  signal rRptHighTimeInRClksUns: unsigned(kRClksPerRpPeriodBitsMax-1 downto 0);
  signal rRptPeriodInRClksUns: unsigned(kRClksPerRpPeriodBitsMax-1 downto 0);
  signal rRpTransferBool: boolean;
  signal sLoadSpCountsBool: boolean;
  signal sLoadSptCountsBool: boolean;
  signal sPpsClkCrossDelayValUns: unsigned(3 downto 0);
  signal sPpsPulseBool: boolean;
  signal sSpHighTimeInSClksUns: unsigned(kSClksPerSpPeriodBitsMax-1 downto 0);
  signal sSpPeriodInSClksUns: unsigned(kSClksPerSpPeriodBitsMax-1 downto 0);
  signal sSptHighTimeInSClksUns: unsigned(kSClksPerSpPeriodBitsMax-1 downto 0);
  signal sSptPeriodInSClksUns: unsigned(kSClksPerSpPeriodBitsMax-1 downto 0);
  signal sSpTransferBool: boolean;
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
  rLoadRePulseCountsBool <= to_Boolean(rLoadRePulseCounts);
  rLoadRpCountsBool      <= to_Boolean(rLoadRpCounts);
  rLoadRptCountsBool     <= to_Boolean(rLoadRptCounts);
  sLoadSpCountsBool      <= to_Boolean(sLoadSpCounts);
  sLoadSptCountsBool     <= to_Boolean(sLoadSptCounts);
  rPpsPulseBool          <= to_Boolean(rPpsPulse);
  rEnablePpsCrossingBool <= to_Boolean(rEnablePpsCrossing);
  rRePulsePeriodInRClksUns   <= unsigned(rRePulsePeriodInRClks);
  rRePulseHighTimeInRClksUns <= unsigned(rRePulseHighTimeInRClks);
  rRpPeriodInRClksUns    <= unsigned(rRpPeriodInRClks);
  rRpHighTimeInRClksUns  <= unsigned(rRpHighTimeInRClks);
  rRptPeriodInRClksUns   <= unsigned(rRptPeriodInRClks);
  rRptHighTimeInRClksUns <= unsigned(rRptHighTimeInRClks);
  sSpPeriodInSClksUns    <= unsigned(sSpPeriodInSClks);
  sSpHighTimeInSClksUns  <= unsigned(sSpHighTimeInSClks);
  sSptPeriodInSClksUns   <= unsigned(sSptPeriodInSClks);
  sSptHighTimeInSClksUns <= unsigned(sSptHighTimeInSClks);

  -- Outputs
  rResetTdcDone      <= to_stdlogic(rResetTdcDoneBool);
  rPpsPulseCaptured  <= to_stdlogic(rPpsPulseCapturedBool);
  mOffsetsDone       <= to_stdlogic(mOffsetsDoneBool);
  mOffsetsValid      <= to_stdlogic(mOffsetsValidBool);
  rRpTransfer        <= to_stdlogic(rRpTransferBool);
  sSpTransfer        <= to_stdlogic(sSpTransferBool);
  sPpsPulse <= to_stdlogic(sPpsPulseBool);

  mRpOffset <= std_logic_vector(mRpOffsetUns);
  mSpOffset <= std_logic_vector(mSpOffsetUns);
  sPpsClkCrossDelayValUns <= unsigned(sPpsClkCrossDelayVal);

  --vhook_e TdcTop
  --vhook_a aReset               aResetBool
  --vhook_a rResetTdc            rResetTdcBool
  --vhook_a rResetTdcDone        rResetTdcDoneBool
  --vhook_a rEnableTdc           rEnableTdcBool
  --vhook_a rReRunEnable         rReRunEnableBool
  --vhook_a rPpsPulse            rPpsPulseBool
  --vhook_a rLoadRePulseCounts   rLoadRePulseCountsBool
  --vhook_a rLoadRpCounts        rLoadRpCountsBool
  --vhook_a rLoadRptCounts       rLoadRptCountsBool
  --vhook_a sLoadSpCounts        sLoadSpCountsBool
  --vhook_a sLoadSptCounts       sLoadSptCountsBool
  --vhook_a rPpsPulseCaptured    rPpsPulseCapturedBool
  --vhook_a rEnablePpsCrossing   rEnablePpsCrossingBool
  --vhook_a mOffsetsDone         mOffsetsDoneBool
  --vhook_a mOffsetsValid        mOffsetsValidBool
  --vhook_a mRpOffset            mRpOffsetUns
  --vhook_a mSpOffset            mSpOffsetUns
  --vhook_a sPpsClkCrossDelayVal sPpsClkCrossDelayValUns
  --vhook_a rRpTransfer          rRpTransferBool
  --vhook_a sSpTransfer          sSpTransferBool
  --vhook_a sPpsPulse            sPpsPulseBool
  --vhook_p {^rR(.*)In(.*)Clks}  rR$1In$2ClksUns
  --vhook_p {^sS(.*)In(.*)Clks}  sS$1In$2ClksUns
  TdcTopx: entity work.TdcTop (struct)
    generic map (
      kRClksPerRePulsePeriodBitsMax => kRClksPerRePulsePeriodBitsMax,  --integer range 3:32 :=24
      kRClksPerRpPeriodBitsMax      => kRClksPerRpPeriodBitsMax,       --integer range 3:16 :=16
      kSClksPerSpPeriodBitsMax      => kSClksPerSpPeriodBitsMax,       --integer range 3:16 :=16
      kPulsePeriodCntSize           => kPulsePeriodCntSize,            --integer:=13
      kFreqRefPeriodsToCheckSize    => kFreqRefPeriodsToCheckSize,     --integer:=17
      kSyncPeriodsToStampSize       => kSyncPeriodsToStampSize)        --integer:=10
    port map (
      aReset                  => aResetBool,                  --in  boolean
      RefClk                  => RefClk,                      --in  std_logic
      SampleClk               => SampleClk,                   --in  std_logic
      MeasClk                 => MeasClk,                     --in  std_logic
      rResetTdc               => rResetTdcBool,               --in  boolean
      rResetTdcDone           => rResetTdcDoneBool,           --out boolean
      rEnableTdc              => rEnableTdcBool,              --in  boolean
      rReRunEnable            => rReRunEnableBool,            --in  boolean
      rPpsPulse               => rPpsPulseBool,               --in  boolean
      rPpsPulseCaptured       => rPpsPulseCapturedBool,       --out boolean
      rEnablePpsCrossing      => rEnablePpsCrossingBool,      --in  boolean
      sPpsClkCrossDelayVal    => sPpsClkCrossDelayValUns,     --in  unsigned(3:0)
      sPpsPulse               => sPpsPulseBool,               --out boolean
      mRpOffset               => mRpOffsetUns,                --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mSpOffset               => mSpOffsetUns,                --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mOffsetsDone            => mOffsetsDoneBool,            --out boolean
      mOffsetsValid           => mOffsetsValidBool,           --out boolean
      rLoadRePulseCounts      => rLoadRePulseCountsBool,      --in  boolean
      rRePulsePeriodInRClks   => rRePulsePeriodInRClksUns,    --in  unsigned(kRClksPerRePulsePeriodBitsMax-1:0)
      rRePulseHighTimeInRClks => rRePulseHighTimeInRClksUns,  --in  unsigned(kRClksPerRePulsePeriodBitsMax-1:0)
      rLoadRpCounts           => rLoadRpCountsBool,           --in  boolean
      rRpPeriodInRClks        => rRpPeriodInRClksUns,         --in  unsigned(kRClksPerRpPeriodBitsMax-1:0)
      rRpHighTimeInRClks      => rRpHighTimeInRClksUns,       --in  unsigned(kRClksPerRpPeriodBitsMax-1:0)
      rLoadRptCounts          => rLoadRptCountsBool,          --in  boolean
      rRptPeriodInRClks       => rRptPeriodInRClksUns,        --in  unsigned(kRClksPerRpPeriodBitsMax-1:0)
      rRptHighTimeInRClks     => rRptHighTimeInRClksUns,      --in  unsigned(kRClksPerRpPeriodBitsMax-1:0)
      sLoadSpCounts           => sLoadSpCountsBool,           --in  boolean
      sSpPeriodInSClks        => sSpPeriodInSClksUns,         --in  unsigned(kSClksPerSpPeriodBitsMax-1:0)
      sSpHighTimeInSClks      => sSpHighTimeInSClksUns,       --in  unsigned(kSClksPerSpPeriodBitsMax-1:0)
      sLoadSptCounts          => sLoadSptCountsBool,          --in  boolean
      sSptPeriodInSClks       => sSptPeriodInSClksUns,        --in  unsigned(kSClksPerSpPeriodBitsMax-1:0)
      sSptHighTimeInSClks     => sSptHighTimeInSClksUns,      --in  unsigned(kSClksPerSpPeriodBitsMax-1:0)
      rRpTransfer             => rRpTransferBool,             --out boolean
      sSpTransfer             => sSpTransferBool,             --out boolean
      rGatedPulseToPin        => rGatedPulseToPin,            --inout std_logic
      sGatedPulseToPin        => sGatedPulseToPin);           --inout std_logic


end struct;


--------------------------------------------------------------------------------
-- Testbench for TdcWrapper
--------------------------------------------------------------------------------

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_TdcWrapper is end tb_TdcWrapper;

architecture test of tb_TdcWrapper is

  --vhook_sigstart
  signal aReset: std_logic;
  signal MeasClk: std_logic := '0';
  signal mOffsetsDone: std_logic;
  signal mOffsetsValid: std_logic;
  signal mRpOffset: std_logic_vector(39 downto 0);
  signal mSpOffset: std_logic_vector(39 downto 0);
  signal RefClk: std_logic := '0';
  signal rEnablePpsCrossing: std_logic;
  signal rEnableTdc: std_logic;
  signal rGatedPulseToPin: std_logic;
  signal rLoadRePulseCounts: std_logic;
  signal rLoadRpCounts: std_logic;
  signal rLoadRptCounts: std_logic;
  signal rPpsPulse: std_logic;
  signal rPpsPulseCaptured: std_logic;
  signal rRePulseHighTimeInRClks: std_logic_vector(23 downto 0);
  signal rRePulsePeriodInRClks: std_logic_vector(23 downto 0);
  signal rReRunEnable: std_logic;
  signal rResetTdc: std_logic;
  signal rResetTdcDone: std_logic;
  signal rRpHighTimeInRClks: std_logic_vector(15 downto 0);
  signal rRpPeriodInRClks: std_logic_vector(15 downto 0);
  signal rRptHighTimeInRClks: std_logic_vector(15 downto 0);
  signal rRptPeriodInRClks: std_logic_vector(15 downto 0);
  signal rRpTransfer: std_logic;
  signal SampleClk: std_logic := '0';
  signal sGatedPulseToPin: std_logic;
  signal sLoadSpCounts: std_logic;
  signal sLoadSptCounts: std_logic;
  signal sPpsClkCrossDelayVal: std_logic_vector(3 downto 0);
  signal sPpsPulse: std_logic;
  signal sSpHighTimeInSClks: std_logic_vector(15 downto 0);
  signal sSpPeriodInSClks: std_logic_vector(15 downto 0);
  signal sSptHighTimeInSClks: std_logic_vector(15 downto 0);
  signal sSptPeriodInSClks: std_logic_vector(15 downto 0);
  signal sSpTransfer: std_logic;
  --vhook_sigend

begin

  --vhook_e TdcWrapper dutx
  dutx: entity work.TdcWrapper (struct)
    port map (
      aReset                  => aReset,                   --in  std_logic
      RefClk                  => RefClk,                   --in  std_logic
      SampleClk               => SampleClk,                --in  std_logic
      MeasClk                 => MeasClk,                  --in  std_logic
      rResetTdc               => rResetTdc,                --in  std_logic
      rResetTdcDone           => rResetTdcDone,            --out std_logic
      rEnableTdc              => rEnableTdc,               --in  std_logic
      rReRunEnable            => rReRunEnable,             --in  std_logic
      rPpsPulse               => rPpsPulse,                --in  std_logic
      rPpsPulseCaptured       => rPpsPulseCaptured,        --out std_logic
      rEnablePpsCrossing      => rEnablePpsCrossing,       --in  std_logic
      sPpsClkCrossDelayVal    => sPpsClkCrossDelayVal,     --in  std_logic_vector(3:0)
      sPpsPulse               => sPpsPulse,                --out std_logic
      mRpOffset               => mRpOffset,                --out std_logic_vector(39:0)
      mSpOffset               => mSpOffset,                --out std_logic_vector(39:0)
      mOffsetsDone            => mOffsetsDone,             --out std_logic
      mOffsetsValid           => mOffsetsValid,            --out std_logic
      rLoadRePulseCounts      => rLoadRePulseCounts,       --in  std_logic
      rRePulsePeriodInRClks   => rRePulsePeriodInRClks,    --in  std_logic_vector(23:0)
      rRePulseHighTimeInRClks => rRePulseHighTimeInRClks,  --in  std_logic_vector(23:0)
      rLoadRpCounts           => rLoadRpCounts,            --in  std_logic
      rRpPeriodInRClks        => rRpPeriodInRClks,         --in  std_logic_vector(15:0)
      rRpHighTimeInRClks      => rRpHighTimeInRClks,       --in  std_logic_vector(15:0)
      rLoadRptCounts          => rLoadRptCounts,           --in  std_logic
      rRptPeriodInRClks       => rRptPeriodInRClks,        --in  std_logic_vector(15:0)
      rRptHighTimeInRClks     => rRptHighTimeInRClks,      --in  std_logic_vector(15:0)
      sLoadSpCounts           => sLoadSpCounts,            --in  std_logic
      sSpPeriodInSClks        => sSpPeriodInSClks,         --in  std_logic_vector(15:0)
      sSpHighTimeInSClks      => sSpHighTimeInSClks,       --in  std_logic_vector(15:0)
      sLoadSptCounts          => sLoadSptCounts,           --in  std_logic
      sSptPeriodInSClks       => sSptPeriodInSClks,        --in  std_logic_vector(15:0)
      sSptHighTimeInSClks     => sSptHighTimeInSClks,      --in  std_logic_vector(15:0)
      rRpTransfer             => rRpTransfer,              --out std_logic
      sSpTransfer             => sSpTransfer,              --out std_logic
      rGatedPulseToPin        => rGatedPulseToPin,         --inout std_logic
      sGatedPulseToPin        => sGatedPulseToPin);        --inout std_logic

  main: process

  begin
    report "TdcWrapper Test is EMPTY! (but that's ok in this case)" severity note;
    --vhook_nowarn tb_TdcWrapper.test.*
    wait;
  end process;

end test;
--synopsys translate_on
