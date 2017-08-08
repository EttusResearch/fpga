-------------------------------------------------------------------------------
--
-- File: TdcTop.vhd
-- Author: Daniel Jepson
-- Original Project: N310
-- Date: 15 November 2016
--
-------------------------------------------------------------------------------
-- (c) 2016 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
-------------------------------------------------------------------------------
--
-- Purpose:
--
-- This top level module orchestrates both of the TDC Cores for the RSP and RTC. It
-- handles PPS capture, resets, re-run logic, and PPS crossing logic. The guts of the TDC
-- are all located in the Cores.
--
-- This file (and the Cores) follows exactly the "TDC Detail" diagram from this document:
-- //MI/RF/HW/USRP/N310/HWCode/Common/Synchronization/design/Diagrams.vsdx
--
--
--
-- To control this module:
--  0) Default values expected to be driven on the control inputs:
--       aReset     <= true
--       rResetTdc  <= true
--       rEnableTdc <= false
--       rReRunEnable <= false
--       rEnablePpsCrossing   <= false
--       sPpsClkCrossDelayVal <= don't care
--     Prior to starting the core, the Sync Pulse counters must be loaded. Apply the
--     correct count values to rRspPeriodInRClks, etc, and then pulse the load bit for
--     each RSP and RTC. It is critical that this step is performed before de-asserting
--     reset.
--
--  1) De-assert the global reset, aReset, as well as the synchronous reset, rResetTdc,
--     after all clocks are active and stable. Wait until rResetTdcDone is de-asserted.
--     If it doesn't de-assert, then one of your clocks isn't running.
--
--  2) At any point after rResetTdcDone de-asserts it is safe to assert rEnableTdc.
--     The rPpsPulse input is now actively listening for PPS activity and the TDC
--     will begin on the first PPS pulse received. After a PPS is received, the
--     rPpsPulseCaptured bit will assert and will remain asserted until aReset or
--     rResetTdc is asserted.
--
--  3) When the TDC measurement completes, mRspOffsetDone and mRtcOffsetDone will assert
--     (not necessarily at the same time). The results of the measurements will be valid
--     on mRspOffset and mRtcOffset.
--
--  4) To cross the PPS trigger into the SampleClk domain, first write the correct delay
--     value to sPpsClkCrossDelayVal. Then (or at the same time), enable the crossing
--     logic by asserting rEnablePpsCrossing. All subsequent PPS pulses will be crossed
--     deterministically. Although not the typical use case, sPpsClkCrossDelayVal can
--     be adjusted on the fly without producing output glitches, although output pulses
--     may be skipped.
--
--  5) To run the measurement again, assert the rReRunEnable input and capture the new
--     offsets whenever mRspOffsetValid or mRtcOffsetValid asserts.
--
--
--
-- Sync Pulse = RSP and RTC, which are the repeated pulses that are some integer
--  divisor of the Reference and Sample clocks. RSP = Repeated Sync Pulse in the
--  RefClk domain. RTC = Repeated TClk pulse in the SampleClk domain.
--
--
-- Clock period relationship requirements to meet system concerns:
--   1) MeasClkPeriod < 2*RefClkPeriod
--   2) MeasClkPeriod < 4*SampleClkPeriod
--
--
-- vreview_group Tdc
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity TdcTop is
  generic (
    -- Determines the maximum number of bits required to create the Gated and Freerunning
    -- sync pulsers. This value is based off of the RefClk and SyncPulse rates.
    -- For example, for a 25 MHz RefClk and a 40 kHz SyncPulse, we require 625
    -- RefClks per pulse, equating to 9 bits. Round to 12 for ease of implementation.
    kRClksPerRspPeriodBitsMax : integer range 3 to 16 := 12;
    -- This value is based off of the SampleClk and SyncPulse rates.
    -- For example, for a 156.3 MHz SampleClk and a 40 kHz SyncPulse, we require 3840
    -- SampleClks per pulse, equating to 11 bits. Round to 12 for ease of implementation.
    kSClksPerRtcPeriodBitsMax : integer range 3 to 16 := 12;
    -- Default: 40 kHz Sync Pulse Period (25us) sampled by a ~171 MHz MeasClk
    -- requires 4275 Measurement Clock periods = 13 bits.
    -- All other implementations of the TDC use fewer than 13 bits, but leave this set
    -- at 13 so we don't have to change it on a case-by-case basis.
    kPulsePeriodCntSize       : integer := 13;
    -- Number of FreqRef periods to be measured (in bits).
    kFreqRefPeriodsToCheckSize: integer := 17;
    -- Number of Sync Pulse Periods to be timestamped (in bits).
    kSyncPeriodsToStampSize   : integer := 10
  );
  port (

    -- Clocks and Resets : --------------------------------------------------------------
    -- Asynchronous global reset.
    aReset          : in  boolean;
    -- Reference Clock
    RefClk          : in  std_logic;
    -- Sample Clock
    SampleClk       : in  std_logic;
    -- Measurement Clock must run at a very specific frequency, determined by the
    -- SampleClk, RefClk, and Sync Pulse rates... oh and a lot of math/luck.
    MeasClk         : in  std_logic;


    -- Controls and Status : ------------------------------------------------------------
    -- Soft reset for the module. Wait until rResetTdcDone asserts before de-asserting
    -- the reset.
    rResetTdc          : in  boolean;
    rResetTdcDone      : out boolean;
    -- Once enabled, the TDC waits for the next PPS pulse to begin measurements. Leave
    -- this signal asserted for the measurement duration (there is no need to de-assert
    -- it unless you want to capture a different PPS edge).
    rEnableTdc         : in  boolean;
    -- Assert this bit to allow the TDC to perform repeated measurements.
    rReRunEnable       : in  boolean;

    -- Only required to pulse 1 RefClk cycle.
    rPpsPulse          : in  boolean;
    -- Debug, held asserted when pulse is captured.
    rPpsPulseCaptured  : out boolean;


    -- Crossing PPS into Sample Clock : -------------------------------------------------
    -- Enable crossing rPpsPulse into SampleClk domain. This should remain de-asserted
    -- until the TDC measurements are complete and sPpsClkCrossDelayVal is written.
    rEnablePpsCrossing   : in  boolean;
    -- Programmable delay value for crossing clock domains. This is used to compensate
    -- for differences in sRTC pulses across modules. This value is typically set once
    -- after running initial synchronization.
    sPpsClkCrossDelayVal : in  unsigned(3 downto 0);
    -- PPS pulse output on the SampleClk domain.
    sPpsPulse            : out boolean;


    -- FTDC Measurement Results : -------------------------------------------------------
    -- Final FTDC measurements in MeasClk ticks. Done will assert when *Offset
    -- becomes valid and will remain asserted until aReset or rResetTdc asserts.
    -- FXP<+40,13> where kPulsePeriodCntSize is the number of integer bits.
    mRspOffset      : out unsigned(kPulsePeriodCntSize+
                                   kSyncPeriodsToStampSize+
                                   kFreqRefPeriodsToCheckSize-1 downto 0);
    mRtcOffset      : out unsigned(kPulsePeriodCntSize+
                                   kSyncPeriodsToStampSize+
                                   kFreqRefPeriodsToCheckSize-1 downto 0);
    mOffsetsDone    : out boolean;
    mOffsetsValid   : out boolean;


    -- Setup for Sync Pulses : ----------------------------------------------------------
    -- Only load these counts when rResetTdc is asserted and rEnableTdc is de-asserted!!!
    -- If both of the above conditions are met, load the counts by pulsing Load
    -- when the counts are valid. It is not necessary to keep the count values valid
    -- after pulsing Load.
    rLoadRspCounts      : in boolean;
    rRspPeriodInRClks   : in unsigned(kRClksPerRspPeriodBitsMax - 1 downto 0);
    rRspHighTimeInRClks : in unsigned(kRClksPerRspPeriodBitsMax - 1 downto 0);
    sLoadRtcCounts      : in boolean;
    sRtcPeriodInSClks   : in unsigned(kSClksPerRtcPeriodBitsMax - 1 downto 0);
    sRtcHighTimeInSClks : in unsigned(kSClksPerRtcPeriodBitsMax - 1 downto 0);


    -- Sync Pulse Outputs : -------------------------------------------------------------
    -- The repeating pulses can be useful for many things, including passing triggers.
    rRSP               : out boolean;
    sRTC               : out boolean;

    -- Pin bouncers out and in. Must go to unused and unconnected pins on the FPGA!
    rGatedPulseToPin   : inout std_logic;
    sGatedPulseToPin   : inout std_logic
  );
end TdcTop;


architecture struct of TdcTop is

  component TdcCore
    generic (
      kSourceClksPerPulseMaxBits : integer range 3 to 16 := 12;
      kPulsePeriodCntSize        : integer := 13;
      kFreqRefPeriodsToCheckSize : integer := 17;
      kSyncPeriodsToStampSize    : integer := 10);
    port (
      aReset             : in  boolean;
      MeasClk            : in  std_logic;
      mResetPeriodMeas   : in  boolean;
      mPeriodMeasDone    : out boolean;
      mResetTdcMeas      : in  boolean;
      mRunTdcMeas        : in  boolean;
      mGatedPulse        : out boolean;
      mAvgOffset         : out unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
      mAvgOffsetDone     : out boolean;
      mAvgOffsetValid    : out boolean;
      SourceClk          : in  std_logic;
      sResetTdc          : in  boolean;
      sSyncPulseLoadCnt  : in  boolean;
      sSyncPulsePeriod   : in  unsigned(kSourceClksPerPulseMaxBits-1 downto 0);
      sSyncPulseHighTime : in  unsigned(kSourceClksPerPulseMaxBits-1 downto 0);
      sSyncPulseEnable   : in  boolean;
      sGatedPulse        : out boolean;
      sGatedPulseToPin   : inout std_logic);
  end component;

  --vhook_sigstart
  signal mRSP: boolean;
  signal mRspOffsetDoneLcl: boolean;
  signal mRspOffsetValidLcl: boolean;
  signal mRTC: boolean;
  signal mRtcOffsetDoneLcl: boolean;
  signal mRtcOffsetValidLcl: boolean;
  signal mRunTdc: boolean;
  signal rCrossTrigRFI: boolean;
  signal rGatedCptrPulseIn: boolean;
  signal rRspLcl: boolean;
  signal rSyncPulseEnable: boolean;
  signal sRtcLcl: boolean;
  signal sSyncPulseEnable: boolean;
  --vhook_sigend

  signal sSyncPulseEnable_ms : boolean;

  signal rSyncPulseEnableDly1, rSyncPulseEnableDly2, rSyncPulseEnableDly3 : boolean;

  signal mRtcDly,
         mRtcReDly1,
         mRtcReDly2,
         mRtcRe : boolean;

  signal rResetTdcFlop_ms, rResetTdcFlop,
         rResetTdcDone_ms,
         mRunTdcEnable_ms, mRunTdcEnable,
         mResetTdc_ms,     mResetTdc,
         sResetTdc_ms,     sResetTdc,
         mRspValidStored,  mRtcValidStored,
         mOffsetsValidLcl,
         rPpsPulseDly,  rPpsPulseRe,
         mReRunEnable_ms,  mReRunEnable  : boolean;

  type EnableFsmState_t is (Disabled, WaitForRunComplete, ReRuns);
  signal mEnableState : EnableFsmState_t;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of sSyncPulseEnable_ms : signal is "true";
  attribute ASYNC_REG of sSyncPulseEnable    : signal is "true";
  attribute ASYNC_REG of rResetTdcFlop_ms    : signal is "true";
  attribute ASYNC_REG of rResetTdcFlop       : signal is "true";
  attribute ASYNC_REG of rResetTdcDone_ms    : signal is "true";
  attribute ASYNC_REG of rResetTdcDone       : signal is "true";
  attribute ASYNC_REG of mRunTdcEnable_ms    : signal is "true";
  attribute ASYNC_REG of mRunTdcEnable       : signal is "true";
  attribute ASYNC_REG of mResetTdc_ms        : signal is "true";
  attribute ASYNC_REG of mResetTdc           : signal is "true";
  attribute ASYNC_REG of sResetTdc_ms        : signal is "true";
  attribute ASYNC_REG of sResetTdc           : signal is "true";
  attribute ASYNC_REG of mReRunEnable_ms     : signal is "true";
  attribute ASYNC_REG of mReRunEnable        : signal is "true";

begin


  -- Generate Resets : ------------------------------------------------------------------
  -- Double-sync the reset to the MeasClk domain and then back to the RefClk domain to
  -- prove it made it all the way into the TDC. Also move it into the SampleClk domain.
  -- ------------------------------------------------------------------------------------
  GenResets : process(aReset, RefClk)
  begin
    if aReset then
      rResetTdcFlop_ms <= true;
      rResetTdcFlop    <= true;
      rResetTdcDone_ms <= true;
      rResetTdcDone    <= true;
    elsif rising_edge(RefClk) then
      -- Run this through a double-sync in case the user defaults it to false, which
      -- could cause rResetTdcFlop_ms to go meta-stable.
      rResetTdcFlop_ms <= rResetTdc;
      rResetTdcFlop    <= rResetTdcFlop_ms;
      -- Second double-sync to move the reset from the MeasClk domain back to RefClk.
      rResetTdcDone_ms <= mResetTdc;
      rResetTdcDone    <= rResetTdcDone_ms;
    end if;
  end process;

  GenResetsMeasClk : process(aReset, MeasClk)
  begin
    if aReset then
      mResetTdc_ms <= true;
      mResetTdc    <= true;
    elsif rising_edge(MeasClk) then
      -- Move the reset from the RefClk to the MeasClk domain.
      mResetTdc_ms <= rResetTdcFlop;
      mResetTdc    <= mResetTdc_ms;
    end if;
  end process;

  GenResetsSampleClk : process(aReset, SampleClk)
  begin
    if aReset then
      sResetTdc_ms <= true;
      sResetTdc    <= true;
    elsif rising_edge(SampleClk) then
      -- Move the reset from the RefClk to the SampleClk domain.
      sResetTdc_ms <= rResetTdcFlop;
      sResetTdc    <= sResetTdc_ms;
    end if;
  end process;


  -- Generate Enables for TDCs : --------------------------------------------------------
  -- When the TDC is enabled by asserting rEnableTdc, we start "listening" for a PPS
  -- rising edge to occur. We capture the first edge we see and then keep the all the
  -- enables asserted until the TDC is disabled. The enabled are routed to each clock
  -- domain with the delays noted below:
  --
  -- Signal routing delay:
  --   rSyncPulseEnable -> RspTdc (0 delay cycles)
  --   rSyncPulseEnable -> Sync to SampleClk -> RtcTDC (1-2 SampleClk)
  --   rSyncPulseEnable -> Sync to MeasClk -> mRunTdc (RSP and RTC TDCs) (1-2 MeasClk)
  -- ------------------------------------------------------------------------------------
  EnableTdc : process(aReset, RefClk)
  begin
    if aReset then
      rPpsPulseDly         <= false;
      rSyncPulseEnable     <= false;
      rSyncPulseEnableDly1 <= false;
      rSyncPulseEnableDly2 <= false;
      rSyncPulseEnableDly3 <= false;
    elsif rising_edge(RefClk) then
      -- RE detector for PPS to ONLY trigger on the edge and not accidentally half
      -- way through the high time.
      rPpsPulseDly         <= rPpsPulse;
      -- When the TDC is enabled we capture the first PPS. This starts the Sync Pulses
      -- (RSP / RTC) as well as enables the TDC measurement for capturing edges. Note
      -- that this is independent from any synchronous reset such that we can control
      -- the PPS capture and the edge capture independently.
      if rEnableTdc then
        -- Future PPS pulses will be ignored until rEnableTdc is de-asserted.
        if rPpsPulseRe then
          rSyncPulseEnable <= true;
        end if;
      else
        rSyncPulseEnable <= false;
      end if;

      -- Delay
      rSyncPulseEnableDly1 <= rSyncPulseEnable;
      rSyncPulseEnableDly2 <= rSyncPulseEnableDly1;
      rSyncPulseEnableDly3 <= rSyncPulseEnableDly2;
    end if;
  end process;

  rPpsPulseRe <= rPpsPulse and not rPpsPulseDly;

  -- Local to debug outputs.
  rPpsPulseCaptured <= rSyncPulseEnable;

  -- Sync rSyncPulseEnable to other domains now... based on the "TDC Detail" diagram.
  SyncEnableToSampleClk : process(aReset, SampleClk)
  begin
    if aReset then
      sSyncPulseEnable_ms <= false;
      sSyncPulseEnable    <= false;
    elsif rising_edge(SampleClk) then
      sSyncPulseEnable_ms <= rSyncPulseEnableDly3;
      sSyncPulseEnable    <= sSyncPulseEnable_ms;
    end if;
  end process;

  -- Generate the master Run signal, as well as the repeat run.
  SyncEnableToMeasClk : process(aReset, MeasClk)
  begin
    if aReset then
      mRunTdcEnable_ms <= false;
      mRunTdcEnable    <= false;
      mReRunEnable_ms  <= false;
      mReRunEnable     <= false;
      mRunTdc <= false;
      mRtcDly <= false;
      mRtcReDly1 <= false;
      mRtcReDly2 <= false;
      mEnableState <= Disabled;
    elsif rising_edge(MeasClk) then
      mRunTdcEnable_ms <= rSyncPulseEnable;
      mRunTdcEnable    <= mRunTdcEnable_ms;
      mReRunEnable_ms  <= rReRunEnable;
      mReRunEnable     <= mReRunEnable_ms;

      -- Add two cycles of delay to the RTC RE signal to ensure the edge offset is
      -- adequately smaller than the RTC period. When these delays are not in place,
      -- the edge capture and processing algorithm occasionally rolls over a period
      -- to start at zero, throwing off the total offset measurement.
      mRtcReDly1 <= mRtcRe;
      mRtcReDly2 <= mRtcReDly1;

      mRtcDly <= mRTC;

      -- STATE MACHINE STARTUP !!! ------------------------------------------------------
      -- This state machine starts safely because it cannot change state until
      -- mRunTdcEnable is asserted, which cannot happen until several cycles after
      -- aReset de-assertion due to the double-synchronizer from the RefClk domain.
      -- --------------------------------------------------------------------------------
      -- De-assert strobe.
      mRunTdc <= false;

      case mEnableState is
        -- Transition to WaitForRunComplete when the TDC is enabled. Pulse mRunTdc here,
        -- and then wait for it to complete in WaitForRunComplete.
        when Disabled =>
          if mRunTdcEnable then
            mRunTdc <= true;
            mEnableState <= WaitForRunComplete;
          end if;

        -- The TDC measurement is complete when both offsets are valid. Go to the re-run
        -- state regardless of whether re-runs are enabled. If they aren't we just sit
        -- there and wait for more instructions...
        when WaitForRunComplete =>
          if mOffsetsValidLcl then
            mEnableState <= ReRuns;
          end if;

        -- Only pulse mRunTdc again after the rising edges of the RTC and RSP pulses have
        -- passed. Instead of checking on both edges, we know from system analysis
        -- that the RTC pulse is slightly delayed from the RSP, so we can just check
        -- on the rising edge of the RTC to ensure both pulses have passed.
        when ReRuns =>
          if mReRunEnable and mRtcReDly2 then
            mRunTdc <= true;
            mEnableState <= WaitForRunComplete;
          end if;

        when others =>
          mEnableState <= Disabled;
      end case;

      -- Synchronous reset for FSM.
      if mResetTdc or not mRunTdcEnable then
        mEnableState <= Disabled;
        mRunTdc <= false;
      end if;

    end if;
  end process;

  mRtcRe <= mRTC and not mRtcDly;



  -- Generate Output Valid Signals : ----------------------------------------------------
  -- Depending on how fast SW can read the measurements (and in what order they read)
  -- the readings could be out of sync with one another. This section conditions the
  -- output valid signals from each core and asserts a single output valid pulse after
  -- BOTH valids have asserted. It is agnostic to the order in which the valids assert.
  -- It creates a delay in the output valid assertion. Minimal delay is one MeasClk cycle
  -- if the core valids assert together. Worst-case delay is two MeasClk cycles after
  -- the latter of the two valids asserts. This is acceptable delay because the core
  -- cannot be re-run until both valids have asserted (mOffsetsValidLcl is fed back into
  -- the ReRun FSM above).
  -- ------------------------------------------------------------------------------------
  ConditionDataValidProc : process(aReset, MeasClk) is
  begin
    if aReset then
      mOffsetsValidLcl <= false;
      mRspValidStored  <= false;
      mRtcValidStored  <= false;
    elsif rising_edge(MeasClk) then
      -- Reset the strobe signals.
      mOffsetsValidLcl <= false;

      -- First, we're sensitive to the TDC sync reset signal.
      if mResetTdc then
        mOffsetsValidLcl <= false;
        mRspValidStored  <= false;
        mRtcValidStored  <= false;
      -- Case 1: Both Valid signals pulse at the same time.
      -- Case 4: Both Valid signals have been stored independently. Yes, this incurs
      --         a one-cycle delay in the output valid (from when the second one asserts)
      --         but it makes for cleaner code and is safe because by design because the
      --         valid signals cannot assert again for a longggg time.
      elsif (mRspOffsetValidLcl and mRtcOffsetValidLcl) or
            (mRspValidStored and mRtcValidStored) then
        mOffsetsValidLcl <= true;
        mRspValidStored  <= false;
        mRtcValidStored  <= false;
      -- Case 2: RSP Valid pulses alone.
      elsif mRspOffsetValidLcl then
        mRspValidStored <= true;
      -- Case 3: RTC Valid pulses alone.
      elsif mRtcOffsetValidLcl then
        mRtcValidStored <= true;
      end if;
    end if;
  end process;

  -- Local to output.
  mOffsetsValid <= mOffsetsValidLcl;
  -- Only assert done with both cores are done.
  mOffsetsDone  <= mRspOffsetDoneLcl and mRtcOffsetDoneLcl;



  -- Reference Clock TDC (RSP) : --------------------------------------------------------
  -- mRSP is only used for testbenching purposes, so ignore vhook warnings.
  --vhook_nowarn mRSP
  -- ------------------------------------------------------------------------------------

  --vhook   TdcCore    RspTdc
  --vhook_g kSourceClksPerPulseMaxBits kRClksPerRspPeriodBitsMax
  --vhook_a mResetPeriodMeas mResetTdc
  --vhook_a mResetTdcMeas    mResetTdc
  --vhook_a mPeriodMeasDone  open
  --vhook_a mRunTdcMeas      mRunTdc
  --vhook_a mGatedPulse      mRSP
  --vhook_a mAvgOffset       mRspOffset
  --vhook_a mAvgOffsetDone   mRspOffsetDoneLcl
  --vhook_a mAvgOffsetValid  mRspOffsetValidLcl
  --vhook_a SourceClk        RefClk
  --vhook_a sResetTdc        rResetTdcFlop
  --vhook_a sSyncPulseLoadCnt  rLoadRspCounts
  --vhook_a sSyncPulsePeriod   rRspPeriodInRClks
  --vhook_a sSyncPulseHighTime rRspHighTimeInRClks
  --vhook_a sSyncPulseEnable   rSyncPulseEnable
  --vhook_a sGatedPulse        rRspLcl
  --vhook_a {^sGated(.*)}      rGated$1
  RspTdc: TdcCore
    generic map (
      kSourceClksPerPulseMaxBits => kRClksPerRspPeriodBitsMax,   --integer range 3:16 :=12
      kPulsePeriodCntSize        => kPulsePeriodCntSize,         --integer:=13
      kFreqRefPeriodsToCheckSize => kFreqRefPeriodsToCheckSize,  --integer:=17
      kSyncPeriodsToStampSize    => kSyncPeriodsToStampSize)     --integer:=10
    port map (
      aReset             => aReset,               --in  boolean
      MeasClk            => MeasClk,              --in  std_logic
      mResetPeriodMeas   => mResetTdc,            --in  boolean
      mPeriodMeasDone    => open,                 --out boolean
      mResetTdcMeas      => mResetTdc,            --in  boolean
      mRunTdcMeas        => mRunTdc,              --in  boolean
      mGatedPulse        => mRSP,                 --out boolean
      mAvgOffset         => mRspOffset,           --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mAvgOffsetDone     => mRspOffsetDoneLcl,    --out boolean
      mAvgOffsetValid    => mRspOffsetValidLcl,   --out boolean
      SourceClk          => RefClk,               --in  std_logic
      sResetTdc          => rResetTdcFlop,        --in  boolean
      sSyncPulseLoadCnt  => rLoadRspCounts,       --in  boolean
      sSyncPulsePeriod   => rRspPeriodInRClks,    --in  unsigned(kSourceClksPerPulseMaxBits-1:0)
      sSyncPulseHighTime => rRspHighTimeInRClks,  --in  unsigned(kSourceClksPerPulseMaxBits-1:0)
      sSyncPulseEnable   => rSyncPulseEnable,     --in  boolean
      sGatedPulse        => rRspLcl,              --out boolean
      sGatedPulseToPin   => rGatedPulseToPin);    --inout std_logic

  -- Local to output
  rRSP <= rRspLcl;


  -- Sample Clock TDC (RTC) : -----------------------------------------------------------
  --
  -- ------------------------------------------------------------------------------------

  --vhook   TdcCore    RtcTdc
  --vhook_g kSourceClksPerPulseMaxBits kSClksPerRtcPeriodBitsMax
  --vhook_a mResetPeriodMeas mResetTdc
  --vhook_a mResetTdcMeas    mResetTdc
  --vhook_a mPeriodMeasDone  open
  --vhook_a mRunTdcMeas      mRunTdc
  --vhook_a mGatedPulse      mRTC
  --vhook_a mAvgOffset       mRtcOffset
  --vhook_a mAvgOffsetDone   mRtcOffsetDoneLcl
  --vhook_a mAvgOffsetValid  mRtcOffsetValidLcl
  --vhook_a SourceClk        SampleClk
  --vhook_a sResetTdc        sResetTdc
  --vhook_a sSyncPulseLoadCnt  sLoadRtcCounts
  --vhook_a sSyncPulsePeriod   sRtcPeriodInSClks
  --vhook_a sSyncPulseHighTime sRtcHighTimeInSClks
  --vhook_a sSyncPulseEnable sSyncPulseEnable
  --vhook_a sGatedPulse      sRtcLcl
  --vhook_a {^sGated(.*)}    sGated$1
  RtcTdc: TdcCore
    generic map (
      kSourceClksPerPulseMaxBits => kSClksPerRtcPeriodBitsMax,   --integer range 3:16 :=12
      kPulsePeriodCntSize        => kPulsePeriodCntSize,         --integer:=13
      kFreqRefPeriodsToCheckSize => kFreqRefPeriodsToCheckSize,  --integer:=17
      kSyncPeriodsToStampSize    => kSyncPeriodsToStampSize)     --integer:=10
    port map (
      aReset             => aReset,               --in  boolean
      MeasClk            => MeasClk,              --in  std_logic
      mResetPeriodMeas   => mResetTdc,            --in  boolean
      mPeriodMeasDone    => open,                 --out boolean
      mResetTdcMeas      => mResetTdc,            --in  boolean
      mRunTdcMeas        => mRunTdc,              --in  boolean
      mGatedPulse        => mRTC,                 --out boolean
      mAvgOffset         => mRtcOffset,           --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mAvgOffsetDone     => mRtcOffsetDoneLcl,    --out boolean
      mAvgOffsetValid    => mRtcOffsetValidLcl,   --out boolean
      SourceClk          => SampleClk,            --in  std_logic
      sResetTdc          => sResetTdc,            --in  boolean
      sSyncPulseLoadCnt  => sLoadRtcCounts,       --in  boolean
      sSyncPulsePeriod   => sRtcPeriodInSClks,    --in  unsigned(kSourceClksPerPulseMaxBits-1:0)
      sSyncPulseHighTime => sRtcHighTimeInSClks,  --in  unsigned(kSourceClksPerPulseMaxBits-1:0)
      sSyncPulseEnable   => sSyncPulseEnable,     --in  boolean
      sGatedPulse        => sRtcLcl,              --out boolean
      sGatedPulseToPin   => sGatedPulseToPin);    --inout std_logic

  -- Local to output
  sRTC <= sRtcLcl;


  -- Cross PPS to SampleClk : ----------------------------------------------------------
  -- Cross it safely and with deterministic delay.
  -- ------------------------------------------------------------------------------------

  -- Keep the module from over-pulsing itself by gating the input with the RFI signal,
  -- although at 1 Hz, this module should never run into the RFI de-asserted case
  -- by design.
  rGatedCptrPulseIn <= rCrossTrigRFI and rPpsPulseRe;

  --vhook_e CrossTrigger CrossCptrPulse
  --vhook_a rRSP              rRspLcl
  --vhook_a rReadyForInput    rCrossTrigRFI
  --vhook_a rEnableTrigger    rEnablePpsCrossing
  --vhook_a rTriggerIn        rGatedCptrPulseIn
  --vhook_a sRTC              sRtcLcl
  --vhook_a sElasticBufferPtr sPpsClkCrossDelayVal
  --vhook_a sTriggerOut       sPpsPulse
  CrossCptrPulse: entity work.CrossTrigger (rtl)
    port map (
      aReset            => aReset,                --in  boolean
      RefClk            => RefClk,                --in  std_logic
      rRSP              => rRspLcl,               --in  boolean
      rReadyForInput    => rCrossTrigRFI,         --out boolean
      rEnableTrigger    => rEnablePpsCrossing,    --in  boolean
      rTriggerIn        => rGatedCptrPulseIn,     --in  boolean
      SampleClk         => SampleClk,             --in  std_logic
      sRTC              => sRtcLcl,               --in  boolean
      sElasticBufferPtr => sPpsClkCrossDelayVal,  --in  unsigned(3:0)
      sTriggerOut       => sPpsPulse);            --out boolean


end struct;







--------------------------------------------------------------------------------
-- Testbench for TdcTop
--------------------------------------------------------------------------------

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity tb_TdcTop is end tb_TdcTop;

architecture test of tb_TdcTop is

  -- Constants for the clock periods.
  constant kSPer : time :=   8.000 ns; -- 125.00 MHz
  constant kMPer : time :=   5.848 ns; -- 171.00 MHz
  constant kRPer : time := 100.000 ns; --  10.00 MHz

  constant kRClksPerRspPeriodBitsMax : integer := 12;
  constant kSClksPerRtcPeriodBitsMax : integer := 12;

  -- Constants for the RSP/RTC pulses, based on the clock frequencies above. The periods
  -- should all divide into one another without remainders, so this is safe to do...
  -- High time is 50% duty cycle, or close to it if the period isn't a round number.
  constant kRspPeriod          : time    := 1000 ns;
  constant kRspPeriodInRClks   : integer := kRspPeriod/kRPer;
  constant kRspHighTimeInRClks : integer := integer(ceil(real(kRspPeriodInRClks)/2.0));
  constant kRtcPeriodInSClks   : integer := kRspPeriod/kSPer;
  constant kRtcHighTimeInSClks : integer := integer(ceil(real(kRtcPeriodInSClks)/2.0));

  -- This doesn't come out to a nice number (or shouldn't), but that's ok. Round up.
  constant kMeasClksPerRsp           : integer := kRspPeriod/kMPer+1;

  -- Inputs to DUT
  constant kPulsePeriodCntSize       : integer := integer(ceil(log2(real(kMeasClksPerRsp))));
  constant kFreqRefPeriodsToCheckSize: integer := 12; --17
  constant kSyncPeriodsToStampSize   : integer := 10;

  -- constant kFreqRefPeriodsToCheck    : integer := 2**kFreqRefPeriodsToCheckSize;
  constant kMeasurementTimeout : time :=
             kMPer*(kMeasClksPerRsp*(2**kSyncPeriodsToStampSize) +
                    40*(2**kSyncPeriodsToStampSize) +
                    kMeasClksPerRsp*(2**kFreqRefPeriodsToCheckSize)
                   );

  --vhook_sigstart
  signal aReset: boolean;
  signal MeasClk: std_logic := '0';
  signal mOffsetsDone: boolean;
  signal mOffsetsValid: boolean;
  signal mRspOffset: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal mRtcOffset: unsigned(kPulsePeriodCntSize+kSyncPeriodsToStampSize+kFreqRefPeriodsToCheckSize-1 downto 0);
  signal RefClk: std_logic := '0';
  signal rEnablePpsCrossing: boolean;
  signal rEnableTdc: boolean;
  signal rGatedPulseToPin: std_logic;
  signal rLoadRspCounts: boolean;
  signal rPpsPulse: boolean;
  signal rPpsPulseCaptured: boolean;
  signal rReRunEnable: boolean;
  signal rResetTdc: boolean;
  signal rResetTdcDone: boolean;
  signal rRSP: boolean;
  signal SampleClk: std_logic := '0';
  signal sGatedPulseToPin: std_logic;
  signal sLoadRtcCounts: boolean;
  signal sPpsClkCrossDelayVal: unsigned(3 downto 0);
  signal sPpsPulse: boolean;
  signal sRTC: boolean;
  --vhook_sigend

  signal StopSim : boolean;
  signal EnableOutputChecks : boolean := true;

  signal ExpectedRspOutput,
         ExpectedFinalMeas,
         ExpectedRtcOutput : real := 0.0;

  alias mRunTdc is <<signal .tb_TdcTop.dutx.mRunTdc : boolean>>;
  alias mRTC is <<signal .tb_TdcTop.dutx.mRTC : boolean>>;
  alias mRSP is <<signal .tb_TdcTop.dutx.mRSP : boolean>>;

  procedure ClkWait(
    signal   Clk   : in std_logic;
    X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(Clk);
    end loop;
  end procedure ClkWait;

  function OffsetToReal (Offset : unsigned) return real is
    variable TempVar : real := 0.0;
  begin
    TempVar :=
      real(to_integer(
        Offset(Offset'high downto kFreqRefPeriodsToCheckSize+kSyncPeriodsToStampSize))) +
      real(to_integer(
        Offset(kFreqRefPeriodsToCheckSize+kSyncPeriodsToStampSize-1 downto 0)))*
      real(2.0**(-(kFreqRefPeriodsToCheckSize+kSyncPeriodsToStampSize)));
    return TempVar;
  end OffsetToReal;

begin

  SampleClk   <= not SampleClk   after kSPer/2 when not StopSim else '0';
  RefClk      <= not RefClk      after kRPer/2 when not StopSim else '0';
  MeasClk     <= not MeasClk     after kMPer/2 when not StopSim else '0';


  main: process
  begin
    -- Defaults, per instructions in Purpose
    rResetTdc    <= true;
    rEnableTdc   <= false;
    rReRunEnable <= false;
    rEnablePpsCrossing <= false;
    rPpsPulse  <= false;
    rLoadRspCounts <= false;
    sLoadRtcCounts <= false;

    aReset <= true, false after kRPer*4;
    ClkWait(RefClk,10);

    -- Step 0 : -------------------------------------------------------------------------
    -- Prior to de-asserting reset, we need to load the counters, so pulse the loads.
    ClkWait(RefClk);
    rLoadRspCounts <= true;
    ClkWait(RefClk);
    rLoadRspCounts <= false;
    ClkWait(SampleClk);
    sLoadRtcCounts <= true;
    ClkWait(SampleClk);
    sLoadRtcCounts <= false;


    -- Step 1 : -------------------------------------------------------------------------
    report "De-asserting Synchronous Reset..." severity note;
    ClkWait(RefClk);
    rResetTdc <= false;
    wait until not rResetTdcDone for (kRPer*4)+(kMPer*2);
    assert not rResetTdcDone
      report "rRestTdcDone didn't de-assert in time"
      severity error;


    -- Step 2 : -------------------------------------------------------------------------
    report "Enabling TDC Measurement & Capturing PPS..." severity note;
    rEnableTdc <= true;
    ClkWait(RefClk,5);

    -- Trigger a PPS one-cycle pulse.
    rPpsPulse <= true;
    ClkWait(RefClk);
    rPpsPulse <= false;
    ClkWait(RefClk);
    assert rPpsPulseCaptured report "PPS not captured" severity error;


    -- Step 3 : -------------------------------------------------------------------------
    report "Waiting for Measurements to Complete..." severity note;
    -- Now wait for the measurement to complete.
    wait until mOffsetsDone for kMeasurementTimeout;
    assert mOffsetsDone
      report "Offset measurements not completed within timeout"
      severity error;

    -- Offset values checked below in CheckOutput.

    report "Printing Results..." & LF &
       "RSP:  " & real'image(OffsetToReal(mRspOffset)) &
       " Expected: " & real'image(ExpectedRspOutput) & LF &
       "RTC:  " & real'image(OffsetToReal(mRtcOffset)) &
       " Expected: " & real'image(ExpectedRtcOutput) & LF &
       "Meas: " & real'image((OffsetToReal(mRtcOffset-mRspOffset)*real(kMPer/1 ns)+
                              real(kRPer/1 ns)-real(kSPer/1 ns))/real(kSPer/1 ns)) &
       " Expected: " & real'image(ExpectedFinalMeas)
      severity note;


    -- Step 4 : -------------------------------------------------------------------------
    -- Trigger another PPS one-cycle pulse to watch it all cross over correctly.
    -- Issue the trigger around where a real PPS pulse will come (RE of RSP).
    -- First, set the programmable delay sPpsClkCrossDelayVal.
    ClkWait(SampleClk);
    sPpsClkCrossDelayVal <= to_unsigned(7, sPpsClkCrossDelayVal'length);
    ClkWait(RefClk);
    rEnablePpsCrossing   <= true;
    wait until rRSP and not rRSP'delayed;
    rPpsPulse <= true;
    ClkWait(RefClk);
    rPpsPulse <= false;
    ClkWait(RefClk);

    -- We expect the PPS output pulse to arrive after FE and RE of sRTC have passed,
    -- and then a few extra cycles of SampleClk delay on there as well.
    wait until (not sRTC) and (    sRTC'delayed); -- FE
    wait until (    sRTC) and (not sRTC'delayed); -- RE
    ClkWait(SampleClk, 2 + to_integer(sPpsClkCrossDelayVal));
    -- Check on falling edge of clock.
    wait until falling_edge(SampleClk);
    assert sPpsPulse and not sPpsPulse'delayed(kSPer) report "sPpsPulse did not assert";
    wait until falling_edge(SampleClk);
    assert not sPpsPulse report "sPpsPulse did not pulse correctly";


    -- Step 5 : -------------------------------------------------------------------------
    report "Repeating TDC Measurement..." severity note;
    ClkWait(RefClk);
    rReRunEnable <= true;

    -- Now wait for the measurement to complete.
    wait until mOffsetsValid for kMeasurementTimeout;
    assert mOffsetsValid
      report "Offset measurements not re-completed within timeout"
      severity error;

    -- Offset values checked below in CheckOutput.

    report "Printing Results..." & LF &
       "RSP:  " & real'image(OffsetToReal(mRspOffset)) &
       " Expected: " & real'image(ExpectedRspOutput) & LF &
       "RTC:  " & real'image(OffsetToReal(mRtcOffset)) &
       " Expected: " & real'image(ExpectedRtcOutput) & LF &
       "Meas: " & real'image((OffsetToReal(mRtcOffset-mRspOffset)*real(kMPer/1 ns)+
                              real(kRPer/1 ns)-real(kSPer/1 ns))/real(kSPer/1 ns)) &
       " Expected: " & real'image(ExpectedFinalMeas)
      severity note;

    ClkWait(MeasClk,100);


    -- Let it run for a while : ---------------------------------------------------------
    for i in 0 to 9 loop
      wait until mOffsetsValid for kMeasurementTimeout;
      assert mOffsetsValid
        report "Offset measurements not re-completed within timeout"
        severity error;
      report "Printing Results..." & LF &
         "RSP:  " & real'image(OffsetToReal(mRspOffset)) &
         " Expected: " & real'image(ExpectedRspOutput) & LF &
         "RTC:  " & real'image(OffsetToReal(mRtcOffset)) &
         " Expected: " & real'image(ExpectedRtcOutput) & LF &
         "Meas: " & real'image((OffsetToReal(mRtcOffset-mRspOffset)*real(kMPer/1 ns)+
                                real(kRPer/1 ns)-real(kSPer/1 ns))/real(kSPer/1 ns)) &
         " Expected: " & real'image(ExpectedFinalMeas)
        severity note;
    end loop;


    -- And stop it : --------------------------------------------------------------------
    report "Stopping Repeating TDC Measurements..." severity note;
    ClkWait(RefClk);
    rReRunEnable <= false;
    -- Wait to make sure it doesn't keep going.
    wait until mOffsetsValid
         for 2*(kMPer*(kMeasClksPerRsp*(2**kSyncPeriodsToStampSize) + 40*(2**kSyncPeriodsToStampSize)));
    assert not mOffsetsValid;



    -- Let it run for a while : ---------------------------------------------------------
    report "Starting again Repeating TDC Measurements..." severity note;
    ClkWait(RefClk);
    rReRunEnable <= true;
    for i in 0 to 2 loop
      wait until mOffsetsValid for kMeasurementTimeout;
      assert mOffsetsValid
        report "Offset measurements not re-completed within timeout"
        severity error;
      report "Printing Results..." & LF &
         "RSP:  " & real'image(OffsetToReal(mRspOffset)) &
         " Expected: " & real'image(ExpectedRspOutput) & LF &
         "RTC:  " & real'image(OffsetToReal(mRtcOffset)) &
         " Expected: " & real'image(ExpectedRtcOutput) & LF &
         "Meas: " & real'image((OffsetToReal(mRtcOffset-mRspOffset)*real(kMPer/1 ns)+
                                real(kRPer/1 ns)-real(kSPer/1 ns))/real(kSPer/1 ns)) &
         " Expected: " & real'image(ExpectedFinalMeas)
        severity note;
    end loop;


    StopSim <= true;
    wait;
  end process;


  ExpectedFinalMeasGen : process
    variable StartTime : time := 0 ns;
  begin
    wait until rPpsPulse;
    wait until rRsp;
    StartTime := now;
    wait until sRtc;
    ExpectedFinalMeas <= real((now - StartTime)/1 ps)/real((kSPer/1 ps));
    wait until rResetTdc;
  end process;


  ExpectedRspOutputGen : process
    variable StartTime : time := 0 ns;
  begin
    wait until mRunTdc;
    StartTime := now;
    wait until mRSP;
    ExpectedRspOutput <= real((now - StartTime)/1 ps)/real((kMPer/1 ps));
    wait until mOffsetsValid;
  end process;

  ExpectedRtcOutputGen : process
    variable StartTime : time := 0 ns;
  begin
    wait until mRunTdc;
    StartTime := now;
    wait until mRTC;
    ExpectedRtcOutput <= real((now - StartTime)/1 ps)/real((kMPer/1 ps));
    wait until mOffsetsValid;
  end process;

  CheckOutput : process(MeasClk)
  begin
    if falling_edge(MeasClk) then
      if EnableOutputChecks then

        if mOffsetsValid then
          assert (OffsetToReal(mRspOffset) < ExpectedRspOutput + 1.0) and
                 (OffsetToReal(mRspOffset) > ExpectedRspOutput - 1.0)
            report "Mismatch between mRspOffset and expected!" & LF &
               "Actual: " & real'image(OffsetToReal(mRspOffset)) & LF &
               "Expect: " & real'image(ExpectedRspOutput)
            severity error;
          assert (OffsetToReal(mRtcOffset) < ExpectedRtcOutput + 1.0) and
                 (OffsetToReal(mRtcOffset) > ExpectedRtcOutput - 1.0)
            report "Mismatch between mRtcOffset and expected!" & LF &
               "Actual: " & real'image(OffsetToReal(mRtcOffset)) & LF &
               "Expect: " & real'image(ExpectedRtcOutput)
            severity error;
        end if;
      end if;
    end if;
  end process;


  --vhook_e TdcTop dutx
  --vhook_a rRspPeriodInRClks    to_unsigned(kRspPeriodInRClks,   kRClksPerRspPeriodBitsMax)
  --vhook_a rRspHighTimeInRClks  to_unsigned(kRspHighTimeInRClks, kRClksPerRspPeriodBitsMax)
  --vhook_a sRtcPeriodInSClks    to_unsigned(kRtcPeriodInSClks,   kSClksPerRtcPeriodBitsMax)
  --vhook_a sRtcHighTimeInSClks  to_unsigned(kRtcHighTimeInSClks, kSClksPerRtcPeriodBitsMax)
  dutx: entity work.TdcTop (struct)
    generic map (
      kRClksPerRspPeriodBitsMax  => kRClksPerRspPeriodBitsMax,   --integer range 3:16 :=12
      kSClksPerRtcPeriodBitsMax  => kSClksPerRtcPeriodBitsMax,   --integer range 3:16 :=12
      kPulsePeriodCntSize        => kPulsePeriodCntSize,         --integer:=13
      kFreqRefPeriodsToCheckSize => kFreqRefPeriodsToCheckSize,  --integer:=17
      kSyncPeriodsToStampSize    => kSyncPeriodsToStampSize)     --integer:=10
    port map (
      aReset               => aReset,                                                       --in  boolean
      RefClk               => RefClk,                                                       --in  std_logic
      SampleClk            => SampleClk,                                                    --in  std_logic
      MeasClk              => MeasClk,                                                      --in  std_logic
      rResetTdc            => rResetTdc,                                                    --in  boolean
      rResetTdcDone        => rResetTdcDone,                                                --out boolean
      rEnableTdc           => rEnableTdc,                                                   --in  boolean
      rReRunEnable         => rReRunEnable,                                                 --in  boolean
      rPpsPulse            => rPpsPulse,                                                    --in  boolean
      rPpsPulseCaptured    => rPpsPulseCaptured,                                            --out boolean
      rEnablePpsCrossing   => rEnablePpsCrossing,                                           --in  boolean
      sPpsClkCrossDelayVal => sPpsClkCrossDelayVal,                                         --in  unsigned(3:0)
      sPpsPulse            => sPpsPulse,                                                    --out boolean
      mRspOffset           => mRspOffset,                                                   --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mRtcOffset           => mRtcOffset,                                                   --out unsigned(kPulsePeriodCntSize+ kSyncPeriodsToStampSize+ kFreqRefPeriodsToCheckSize-1:0)
      mOffsetsDone         => mOffsetsDone,                                                 --out boolean
      mOffsetsValid        => mOffsetsValid,                                                --out boolean
      rLoadRspCounts       => rLoadRspCounts,                                               --in  boolean
      rRspPeriodInRClks    => to_unsigned(kRspPeriodInRClks, kRClksPerRspPeriodBitsMax),    --in  unsigned(kRClksPerRspPeriodBitsMax-1:0)
      rRspHighTimeInRClks  => to_unsigned(kRspHighTimeInRClks, kRClksPerRspPeriodBitsMax),  --in  unsigned(kRClksPerRspPeriodBitsMax-1:0)
      sLoadRtcCounts       => sLoadRtcCounts,                                               --in  boolean
      sRtcPeriodInSClks    => to_unsigned(kRtcPeriodInSClks, kSClksPerRtcPeriodBitsMax),    --in  unsigned(kSClksPerRtcPeriodBitsMax-1:0)
      sRtcHighTimeInSClks  => to_unsigned(kRtcHighTimeInSClks, kSClksPerRtcPeriodBitsMax),  --in  unsigned(kSClksPerRtcPeriodBitsMax-1:0)
      rRSP                 => rRSP,                                                         --out boolean
      sRTC                 => sRTC,                                                         --out boolean
      rGatedPulseToPin     => rGatedPulseToPin,                                             --inout std_logic
      sGatedPulseToPin     => sGatedPulseToPin);                                            --inout std_logic


end test;
--synopsys translate_on
