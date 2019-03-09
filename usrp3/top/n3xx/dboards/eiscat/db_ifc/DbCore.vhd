-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
--
-- Purpose:
--
-- Wrapper file for Daughterboard Control. This includes the semi-static control
-- and status registers, clocking, synchronization, and JESD204B cores.
--
-- There is no version register for the plain-text files here.
-- Version control for the Sync and JESD204B cores is internal to the netlists.
--
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


library work;
  use work.PkgEiscatPersonality.all;
  use work.PkgRegs.all;


entity DbCore is
  generic(
    -- Set to '1' to include the White Rabbit TDC.
    kInclWhiteRabbitTdc : std_logic := '0'
  );
  port(

    -- Resets --
    -- Asynchronous System-wide Bus Reset. Can be tied to '0' if the sync version is used.
    aReset                 : in  std_logic;
    -- Synchronous Reset (if unused, tie to '0')
    bReset                 : in  std_logic;

    -- Clocks --
    -- Register Bus Clock (any frequency)
    BusClk                 : in  std_logic;
    -- Always-on at 40 MHz
    Clk40                  : in  std_logic;
    -- Super secret crazy awesome measurement clock at weird frequencies.
    MeasClk                : in  std_logic;
    -- FPGA Sample Clock from DB LMK
    FpgaClk_p              : in  std_logic;
    FpgaClk_n              : in  std_logic;

    -- Sample Clock Sharing. The clocks generated in this module are automatically
    -- exported, so they must be driven back into the inputs at a higher level in
    -- order for this module to work!
    SampleClk1xOut         : out std_logic;
    SampleClk1x            : in  std_logic;
    SampleClk2xOut         : out std_logic;
    SampleClk2x            : in  std_logic;


    -- Register Ports --
    --
    bRegPortInFlat         : in  std_logic_vector(49 downto 0);
    bRegPortOutFlat        : out std_logic_vector(33 downto 0);

    -- Slot and DB ID values. These should be tied to constants!
    kDbId                  : in  std_logic_vector(15 downto 0);
    kSlotId                : in  std_logic;

    -- SYSREF --
    --
    -- Strobe to issue SYSREF to the FPGA. Needs to only a be a single cycle pulse.
    sSysRefToFpgaCore      : in  std_logic;


    -- JESD Signals --
    --
    -- GTX Sample Clock Reference Input. Direct connect to FPGA pins.
    JesdRefClk_p,
    JesdRefClk_n           : in  std_logic;

    -- ADC JESD PHY Interface. Direct connect to FPGA pins.
    aAdcRx_p,
    aAdcRx_n               : in  std_logic_vector(3 downto 0);
    aSyncAdcAOut_p,
    aSyncAdcAOut_n         : out std_logic;
    aSyncAdcBOut_p,
    aSyncAdcBOut_n         : out std_logic;

    -- Backdoor access to poking SYSREF.
    s2SysRefGo             : out std_logic;

    -- Debug Outputs for JESD.
    aAdcASync              : out std_logic;
    aAdcBSync              : out std_logic;


    -- Data Pipes from the ADCs --
    --
    -- Data is presented as one sample per cycle.
    -- s2AdcDataValid* asserts when ADC datas are valid. It will only assert every other
    -- SampleClk2x cycle.
    s2AdcDataValidA        : out std_logic;
    s2AdcDataSamples0A     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples1A     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples2A     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples3A     : out std_logic_vector(15 downto 0);
    s2AdcDataValidB        : out std_logic;
    s2AdcDataSamples0B     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples1B     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples2B     : out std_logic_vector(15 downto 0);
    s2AdcDataSamples3B     : out std_logic_vector(15 downto 0);

    -- RefClk & Timing & Sync --
    RefClk                 : in  std_logic;
    rPpsPulse              : in  std_logic;
    rGatedPulseToPin       : inout std_logic; -- straight to pin
    sGatedPulseToPin       : inout std_logic; -- straight to pin
    sPps                   : out std_logic;
    sPpsToIob              : out std_logic;

    -- White Rabbit Timing & Sync --
    WrRefClk               : in  std_logic;
    rWrPpsPulse            : in  std_logic;
    rWrGatedPulseToPin     : inout std_logic; -- straight to pin
    sWrGatedPulseToPin     : inout std_logic; -- straight to pin
    aPpsSfpSel             : in  std_logic_vector(1 downto 0);

    -- ADC SPIs
    aAdcSpiEn              : out   std_logic;
    aAdcAReset             : out   std_logic;
    aAdcBReset             : out   std_logic;

    -- LMK Locked & Temp/Voltage Bits
    aLmkStatus             : in  std_logic;
    aTmonAlert_n           : in  std_logic;
    aVmonAlert             : in  std_logic;

    -- DB Control
    aDbCtrlEn_n            : out   std_logic;
    aLmkSpiEn              : out   std_logic;
    aDbPwrEn               : out   std_logic;
    aLnaCtrlEn             : out   std_logic;
    aDbaCh0En_n            : out   std_logic;
    aDbaCh1En_n            : out   std_logic;
    aDbaCh2En_n            : out   std_logic;
    aDbaCh3En_n            : out   std_logic;
    aDbaCh4En_n            : out   std_logic;
    aDbaCh5En_n            : out   std_logic;
    aDbaCh6En_n            : out   std_logic;
    aDbaCh7En_n            : out   std_logic;
    
    -- Debug for Timing & Sync
    rRpTransfer            : out std_logic;
    sSpTransfer            : out std_logic;
    rWrRpTransfer          : out std_logic;
    sWrSpTransfer          : out std_logic

  );

end DbCore;


architecture RTL of DbCore is

  component SyncRegsIfc
    port (
      aReset               : in  STD_LOGIC;
      BusClk               : in  STD_LOGIC;
      bRegPortInFlat       : in  STD_LOGIC_VECTOR(49 downto 0);
      bRegPortOutFlat      : out STD_LOGIC_VECTOR(33 downto 0);
      RefClk               : in  STD_LOGIC;
      rResetTdc            : out STD_LOGIC;
      rResetTdcDone        : in  STD_LOGIC;
      rEnableTdc           : out STD_LOGIC;
      rReRunEnable         : out STD_LOGIC;
      rEnablePpsCrossing   : out STD_LOGIC;
      rPpsPulseCaptured    : in  STD_LOGIC;
      SampleClk            : in  STD_LOGIC;
      sPpsClkCrossDelayVal : out STD_LOGIC_VECTOR(3 downto 0);
      MeasClk              : in  STD_LOGIC;
      mRspOffset           : in  STD_LOGIC_VECTOR(39 downto 0);
      mRtcOffset           : in  STD_LOGIC_VECTOR(39 downto 0);
      mOffsetsDone         : in  STD_LOGIC;
      mOffsetsValid        : in  STD_LOGIC;
      rLoadRspCounts       : out STD_LOGIC;
      rRspPeriodInRClks    : out STD_LOGIC_VECTOR(11 downto 0);
      rRspHighTimeInRClks  : out STD_LOGIC_VECTOR(11 downto 0);
      sLoadRtcCounts       : out STD_LOGIC;
      sRtcPeriodInSClks    : out STD_LOGIC_VECTOR(11 downto 0);
      sRtcHighTimeInSClks  : out STD_LOGIC_VECTOR(11 downto 0));
  end component;
  component Jesd204bXcvrCore
    port (
      aReset             : in  STD_LOGIC;
      bReset             : in  STD_LOGIC;
      BusClk             : in  STD_LOGIC;
      ReliableClk40      : in  STD_LOGIC;
      FpgaClk1x          : in  STD_LOGIC;
      FpgaClk2x          : in  STD_LOGIC;
      bFpgaClksStable    : in  STD_LOGIC;
      bRegPortInFlat     : in  STD_LOGIC_VECTOR(49 downto 0);
      bRegPortOutFlat    : out STD_LOGIC_VECTOR(33 downto 0);
      fSysRefToFpgaCore  : in  STD_LOGIC;
      JesdRefClk_p       : in  STD_LOGIC;
      JesdRefClk_n       : in  STD_LOGIC;
      bJesdRefClkPresent : out STD_LOGIC;
      aAdcARx_p          : in  STD_LOGIC_VECTOR(1 downto 0);
      aAdcARx_n          : in  STD_LOGIC_VECTOR(1 downto 0);
      aAdcBRx_p          : in  STD_LOGIC_VECTOR(1 downto 0);
      aAdcBRx_n          : in  STD_LOGIC_VECTOR(1 downto 0);
      aSyncToAdcA_p      : out STD_LOGIC;
      aSyncToAdcA_n      : out STD_LOGIC;
      aSyncToAdcB_p      : out STD_LOGIC;
      aSyncToAdcB_n      : out STD_LOGIC;
      f2AdcDataValidA    : out STD_LOGIC;
      f2AdcDataSamples0A : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples1A : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples2A : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples3A : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataValidB    : out STD_LOGIC;
      f2AdcDataSamples0B : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples1B : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples2B : out STD_LOGIC_VECTOR(15 downto 0);
      f2AdcDataSamples3B : out STD_LOGIC_VECTOR(15 downto 0);
      aAdcASync          : out STD_LOGIC;
      aAdcBSync          : out STD_LOGIC);
  end component;

  function to_Boolean (s : std_ulogic) return boolean is
  begin
    return (To_X01(s)='1');
  end to_Boolean;

  function to_StdLogic(b : boolean) return std_ulogic is
  begin
    if b then
      return '1';
    else
      return '0';
    end if;
  end to_StdLogic;

  --vhook_sigstart
  signal bClockingRegPortOut: RegPortOut_t;
  signal bDbRegPortOut: RegPortOut_t;
  signal bFpgaClksStable: STD_LOGIC;
  signal bJesdCoreRegPortInFlat: STD_LOGIC_VECTOR(49 downto 0);
  signal bJesdCoreRegPortOutFlat: STD_LOGIC_VECTOR(33 downto 0);
  signal bJesdRefClkPresent: STD_LOGIC;
  signal bRadioClk1xEnabled: std_logic;
  signal bRadioClk2xEnabled: std_logic;
  signal bRadioClk3xEnabled: std_logic;
  signal bRadioClkMmcmReset: std_logic;
  signal bRadioClksValid: std_logic;
  signal bSyncRegPortInFlat: STD_LOGIC_VECTOR(49 downto 0);
  signal bSyncRegPortOutFlat: STD_LOGIC_VECTOR(33 downto 0);
  signal bSysRefGo: std_logic;
  signal mOffsetsDone: STD_LOGIC;
  signal mOffsetsValid: STD_LOGIC;
  signal mRspOffset: STD_LOGIC_VECTOR(39 downto 0);
  signal mRtcOffset: STD_LOGIC_VECTOR(39 downto 0);
  signal pPsDone: std_logic;
  signal pPsEn: std_logic;
  signal pPsInc: std_logic;
  signal PsClk: std_logic;
  signal rEnablePpsCrossing: STD_LOGIC;
  signal rEnableTdc: STD_LOGIC;
  signal rLoadRspCounts: STD_LOGIC;
  signal rPpsPulseCaptured: STD_LOGIC;
  signal rReRunEnable: STD_LOGIC;
  signal rResetTdc: STD_LOGIC;
  signal rResetTdcDone: STD_LOGIC;
  signal rRspHighTimeInRClks: STD_LOGIC_VECTOR(11 downto 0);
  signal rRspPeriodInRClks: STD_LOGIC_VECTOR(11 downto 0);
  signal SampleClk1xOutLcl: STD_LOGIC;
  signal sLoadRtcCounts: STD_LOGIC;
  signal sPpsClkCrossDelayVal: STD_LOGIC_VECTOR(3 downto 0);
  signal sRtcHighTimeInSClks: STD_LOGIC_VECTOR(11 downto 0);
  signal sRtcPeriodInSClks: STD_LOGIC_VECTOR(11 downto 0);
  signal sRegPps: std_logic;
  signal sWrPps: std_logic;
  --vhook_sigend

  signal bJesdRegPortInGrp, bSyncRegPortIn, bWrSyncRegPortIn, bRegPortIn : RegPortIn_t;
  signal bJesdRegPortOut, bSyncRegPortOut, bWrSyncRegPortOut, bRegPortOut : RegPortOut_t;

  signal sPpsSfpSel_ms, sPpsSfpSel : std_logic_vector(1 downto 0) := (others => '0');
  signal sUseWrTdcPps : boolean := false;
  signal sPpsInt, sPpsMuxed : std_logic := '0';

begin

  bRegPortOutFlat <= Flatten(bRegPortOut);
  bRegPortIn      <= Unflatten(bRegPortInFlat);


  -- Combine return RegPorts.
  bRegPortOut <=   bJesdRegPortOut
                 + bClockingRegPortOut + bSyncRegPortOut
                 + bDbRegPortOut;


  -- Clocking : -------------------------------------------------------------------------
  -- Automatically export the Sample Clocks and only use the incoming clocks in the
  -- remainder of the logic. For a single module, the clocks must be looped back
  -- in at a higher level!
  -- ------------------------------------------------------------------------------------

  --vhook_e RadioClocking
  --vhook_a aReset to_boolean(aReset)
  --vhook_a bReset to_boolean(bReset)
  --vhook_a RadioClk1x    SampleClk1xOutLcl
  --vhook_a RadioClk2x    SampleClk2xOut
  --vhook_a RadioClk3x    open
  RadioClockingx: entity work.RadioClocking (rtl)
    port map (
      aReset             => to_boolean(aReset),  --in  boolean
      bReset             => to_boolean(bReset),  --in  boolean
      BusClk             => BusClk,              --in  std_logic
      bRadioClkMmcmReset => bRadioClkMmcmReset,  --in  std_logic
      bRadioClksValid    => bRadioClksValid,     --out std_logic
      bRadioClk1xEnabled => bRadioClk1xEnabled,  --in  std_logic
      bRadioClk2xEnabled => bRadioClk2xEnabled,  --in  std_logic
      bRadioClk3xEnabled => bRadioClk3xEnabled,  --in  std_logic
      pPsInc             => pPsInc,              --in  std_logic
      pPsEn              => pPsEn,               --in  std_logic
      PsClk              => PsClk,               --in  std_logic
      pPsDone            => pPsDone,             --out std_logic
      FpgaClk_n          => FpgaClk_n,           --in  std_logic
      FpgaClk_p          => FpgaClk_p,           --in  std_logic
      RadioClk1x         => SampleClk1xOutLcl,   --out std_logic
      RadioClk2x         => SampleClk2xOut,      --out std_logic
      RadioClk3x         => open);               --out std_logic

  -- We need an internal copy of SampleClk1x for the TDC, since we don't want to try
  -- and align the other DB's clock accidentally.
  SampleClk1xOut <= SampleClk1xOutLcl;

  --vhook_e ClockingRegs
  --vhook_a aReset to_boolean(aReset)
  --vhook_a bRegPortOut       bClockingRegPortOut
  --vhook_a aRadioClksValid   bRadioClksValid
  ClockingRegsx: entity work.ClockingRegs (RTL)
    port map (
      aReset             => to_boolean(aReset),   --in  boolean
      BusClk             => BusClk,               --in  std_logic
      bRegPortOut        => bClockingRegPortOut,  --out RegPortOut_t
      bRegPortIn         => bRegPortIn,           --in  RegPortIn_t
      pPsInc             => pPsInc,               --out std_logic
      pPsEn              => pPsEn,                --out std_logic
      pPsDone            => pPsDone,              --in  std_logic
      PsClk              => PsClk,                --out std_logic
      bRadioClkMmcmReset => bRadioClkMmcmReset,   --out std_logic
      aRadioClksValid    => bRadioClksValid,      --in  std_logic
      bRadioClk1xEnabled => bRadioClk1xEnabled,   --out std_logic
      bRadioClk2xEnabled => bRadioClk2xEnabled,   --out std_logic
      bRadioClk3xEnabled => bRadioClk3xEnabled,   --out std_logic
      bJesdRefClkPresent => bJesdRefClkPresent);  --in  std_logic



  -- JESD204B : -------------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------

  bJesdRegPortInGrp <= Mask(RegPortIn       => bRegPortIn,
                            kRegisterOffset => kJesdRegGroupInDbRegs); -- 0x2000 to 0x3FFC

  -- Expand/compress the RegPort for moving through the netlist boundary.
  bJesdRegPortOut <= Unflatten(bJesdCoreRegPortOutFlat);
  bJesdCoreRegPortInFlat <= Flatten(bJesdRegPortInGrp);

  --vhook   Jesd204bXcvrCore
  --vhook_a bRegPortInFlat   bJesdCoreRegPortInFlat
  --vhook_a bRegPortOutFlat  bJesdCoreRegPortOutFlat
  --vhook_a aAdcARx_p        aAdcRx_p(1 downto 0)
  --vhook_a aAdcARx_n        aAdcRx_n(1 downto 0)
  --vhook_a aAdcBRx_p        aAdcRx_p(3 downto 2)
  --vhook_a aAdcBRx_n        aAdcRx_n(3 downto 2)
  --vhook_a aSyncToAdcA_p    aSyncAdcAOut_p
  --vhook_a aSyncToAdcA_n    aSyncAdcAOut_n
  --vhook_a aSyncToAdcB_p    aSyncAdcBOut_p
  --vhook_a aSyncToAdcB_n    aSyncAdcBOut_n
  --vhook_a FpgaClk1x        SampleClk1x
  --vhook_a FpgaClk2x        SampleClk2x
  --vhook_a ReliableClk40    Clk40
  --vhook_a {^f(.*)}         s$1
  Jesd204bXcvrCorex: Jesd204bXcvrCore
    port map (
      aReset             => aReset,                   --in  STD_LOGIC
      bReset             => bReset,                   --in  STD_LOGIC
      BusClk             => BusClk,                   --in  STD_LOGIC
      ReliableClk40      => Clk40,                    --in  STD_LOGIC
      FpgaClk1x          => SampleClk1x,              --in  STD_LOGIC
      FpgaClk2x          => SampleClk2x,              --in  STD_LOGIC
      bFpgaClksStable    => bFpgaClksStable,          --in  STD_LOGIC
      bRegPortInFlat     => bJesdCoreRegPortInFlat,   --in  STD_LOGIC_VECTOR(49:0)
      bRegPortOutFlat    => bJesdCoreRegPortOutFlat,  --out STD_LOGIC_VECTOR(33:0)
      fSysRefToFpgaCore  => sSysRefToFpgaCore,        --in  STD_LOGIC
      JesdRefClk_p       => JesdRefClk_p,             --in  STD_LOGIC
      JesdRefClk_n       => JesdRefClk_n,             --in  STD_LOGIC
      bJesdRefClkPresent => bJesdRefClkPresent,       --out STD_LOGIC
      aAdcARx_p          => aAdcRx_p(1 downto 0),     --in  STD_LOGIC_VECTOR(1:0)
      aAdcARx_n          => aAdcRx_n(1 downto 0),     --in  STD_LOGIC_VECTOR(1:0)
      aAdcBRx_p          => aAdcRx_p(3 downto 2),     --in  STD_LOGIC_VECTOR(1:0)
      aAdcBRx_n          => aAdcRx_n(3 downto 2),     --in  STD_LOGIC_VECTOR(1:0)
      aSyncToAdcA_p      => aSyncAdcAOut_p,           --out STD_LOGIC
      aSyncToAdcA_n      => aSyncAdcAOut_n,           --out STD_LOGIC
      aSyncToAdcB_p      => aSyncAdcBOut_p,           --out STD_LOGIC
      aSyncToAdcB_n      => aSyncAdcBOut_n,           --out STD_LOGIC
      f2AdcDataValidA    => s2AdcDataValidA,          --out STD_LOGIC
      f2AdcDataSamples0A => s2AdcDataSamples0A,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples1A => s2AdcDataSamples1A,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples2A => s2AdcDataSamples2A,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples3A => s2AdcDataSamples3A,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataValidB    => s2AdcDataValidB,          --out STD_LOGIC
      f2AdcDataSamples0B => s2AdcDataSamples0B,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples1B => s2AdcDataSamples1B,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples2B => s2AdcDataSamples2B,       --out STD_LOGIC_VECTOR(15:0)
      f2AdcDataSamples3B => s2AdcDataSamples3B,       --out STD_LOGIC_VECTOR(15:0)
      aAdcASync          => aAdcASync,                --out STD_LOGIC
      aAdcBSync          => aAdcBSync);               --out STD_LOGIC

  -- Just combine the first two enables, since they're the ones that are used for JESD.
  bFpgaClksStable <= bRadioClksValid and bRadioClk1xEnabled and bRadioClk2xEnabled;


  -- Timing and Sync : ------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------

  bSyncRegPortIn <= Mask(RegPortIn       => bRegPortIn,
                         kRegisterOffset => kTdc0OffsetsInEndpoint); -- 0x0200

  --vhook_e TdcWrapper
  --vhook_# Use the local copy of the SampleClock, since we want the TDC to measure the
  --vhook_# clock offset for this daughterboard, not the global SampleClock.
  --vhook_a SampleClk SampleClk1xOutLcl
  --vhook_a sPpsPulse sRegPps
  TdcWrapperx: entity work.TdcWrapper (struct)
    port map (
      BusClk           => BusClk,             --in  std_logic
      bBusReset        => bReset,          --in  std_logic
      RefClk           => RefClk,             --in  std_logic
      SampleClk        => SampleClk1xOutLcl,  --in  std_logic
      MeasClk          => MeasClk,            --in  std_logic
      bSyncRegPortOut  => bSyncRegPortOut,    --out RegPortOut_t
      bSyncRegPortIn   => bSyncRegPortIn,     --in  RegPortIn_t
      rPpsPulse        => rPpsPulse,          --in  std_logic
      sPpsPulse        => sRegPps,            --out std_logic
      rRpTransfer      => rRpTransfer,        --out std_logic
      sSpTransfer      => sSpTransfer,        --out std_logic
      rGatedPulseToPin => rGatedPulseToPin,   --inout std_logic
      sGatedPulseToPin => sGatedPulseToPin);  --inout std_logic

  WrTdcGen: if kInclWhiteRabbitTdc = '1' generate
    bWrSyncRegPortIn <= Mask(RegPortIn       => bRegPortIn,
                             kRegisterOffset => kTdc1OffsetsInEndpoint); -- 0x0400

    --vhook_e TdcWrapper WrTdcWrapperx
    --vhook_# Use the local copy of the SampleClock, since we want the TDC to measure the
    --vhook_# clock offset for this daughterboard, not the global SampleClock.
    --vhook_a bSyncRegPortIn  bWrSyncRegPortIn
    --vhook_a bSyncRegPortOut bWrSyncRegPortOut
    --vhook_a SampleClk SampleClk1xOutLcl
    --vhook_a RefClk WrRefClk
    --vhook_a rPpsPulse rWrPpsPulse
    --vhook_a sPpsPulse sWrPps
    --vhook_a rRpTransfer rWrRpTransfer
    --vhook_a sSpTransfer sWrSpTransfer
    --vhook_a rGatedPulseToPin rWrGatedPulseToPin
    --vhook_a sGatedPulseToPin sWrGatedPulseToPin
    WrTdcWrapperx: entity work.TdcWrapper (struct)
      port map (
        BusClk           => BusClk,              --in  std_logic
        bBusReset        => bReset,           --in  std_logic
        RefClk           => WrRefClk,            --in  std_logic
        SampleClk        => SampleClk1xOutLcl,   --in  std_logic
        MeasClk          => MeasClk,             --in  std_logic
        bSyncRegPortOut  => bWrSyncRegPortOut,   --out RegPortOut_t
        bSyncRegPortIn   => bWrSyncRegPortIn,    --in  RegPortIn_t
        rPpsPulse        => rWrPpsPulse,         --in  std_logic
        sPpsPulse        => sWrPps,              --out std_logic
        rRpTransfer      => rWrRpTransfer,       --out std_logic
        sSpTransfer      => sWrSpTransfer,       --out std_logic
        rGatedPulseToPin => rWrGatedPulseToPin,  --inout std_logic
        sGatedPulseToPin => sWrGatedPulseToPin); --inout std_logic
  end generate WrTdcGen;

  WrTdcNotGen: if kInclWhiteRabbitTdc = '0' generate
    bWrSyncRegPortOut <= kRegPortOutZero;
    sWrPps <= '0';
    rWrRpTransfer <= '0';
    sWrSpTransfer <= '0';
    rWrGatedPulseToPin <= '0';
    sWrGatedPulseToPin <= '0';
  end generate WrTdcNotGen;

  -- Mux the output PPS based on the SFP selection bits. Encoding is one-hot, with zero
  -- also a valid state. Regardless of whether the user selects SFP0 or SFP1 as the time
  -- source, there is only one White Rabbit TDC, so '01' and '10' are equivalent.
  -- '00': Use the PPS output from the "regular" TDC.
  -- '01': Use the PPS output from the "white rabbit" TDC.
  -- '10': Use the PPS output from the "white rabbit" TDC.
  PpsOutputMux : process (SampleClk1xOutLcl)
  begin
    if rising_edge(SampleClk1xOutLcl) then
      -- Double-sync the control bits to the Sample Clock domain.
      sPpsSfpSel_ms <= aPpsSfpSel;
      sPpsSfpSel    <= sPpsSfpSel_ms;

      -- OR the control bits together to produce a single override enable for the WR TDC.
      sUseWrTdcPps <= to_boolean(sPpsSfpSel(0) or sPpsSfpSel(1));

      -- Flop the outputs. One flop for the PPS output IOB, the other for use internally.
      sPpsInt <= sPpsMuxed;
    end if;
  end process PpsOutputMux;

  sPpsMuxed <= sWrPps when sUseWrTdcPps else sRegPps;
  sPps      <= sPpsInt;
  sPpsToIob <= sPpsMuxed; -- No added flop here since there's an IOB outside this module.

  -- Daughterboard Control : ------------------------------------------------------------
  -- ------------------------------------------------------------------------------------

  --vhook_e DaughterboardRegs
  --vhook_a aReset to_boolean(aReset)
  --vhook_a bRegPortOut bDbRegPortOut
  DaughterboardRegsx: entity work.DaughterboardRegs (RTL)
    port map (
      aReset       => to_boolean(aReset),  --in  boolean
      BusClk       => BusClk,              --in  std_logic
      bRegPortOut  => bDbRegPortOut,       --out RegPortOut_t
      bRegPortIn   => bRegPortIn,          --in  RegPortIn_t
      kDbId        => kDbId,               --in  std_logic_vector(15:0)
      kSlotId      => kSlotId,             --in  std_logic
      aAdcSpiEn    => aAdcSpiEn,           --out std_logic
      aAdcAReset   => aAdcAReset,          --out std_logic
      aAdcBReset   => aAdcBReset,          --out std_logic
      aLmkStatus   => aLmkStatus,          --in  std_logic
      aTmonAlert_n => aTmonAlert_n,        --in  std_logic
      aVmonAlert   => aVmonAlert,          --in  std_logic
      aDbCtrlEn_n  => aDbCtrlEn_n,         --out std_logic
      aLmkSpiEn    => aLmkSpiEn,           --out std_logic
      aDbPwrEn     => aDbPwrEn,            --out std_logic
      aLnaCtrlEn   => aLnaCtrlEn,          --out std_logic
      aDbaCh0En_n  => aDbaCh0En_n,         --out std_logic
      aDbaCh1En_n  => aDbaCh1En_n,         --out std_logic
      aDbaCh2En_n  => aDbaCh2En_n,         --out std_logic
      aDbaCh3En_n  => aDbaCh3En_n,         --out std_logic
      aDbaCh4En_n  => aDbaCh4En_n,         --out std_logic
      aDbaCh5En_n  => aDbaCh5En_n,         --out std_logic
      aDbaCh6En_n  => aDbaCh6En_n,         --out std_logic
      aDbaCh7En_n  => aDbaCh7En_n,         --out std_logic
      bSysRefGo    => bSysRefGo);          --out std_logic


  -- Backdoor way of issuing SYSREF from the RegPort. Double-synchronize the trigger
  -- from the RegPort to the SampleClk2x domain, and then create a rising edge detector
  -- to form a single output pulse.
  SysRefBlock : block
    signal s2SysrefTrig_ms,
           s2SysrefTrig,
           s2SysrefTrigDly : std_logic;
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of s2SysrefTrig_ms : signal is "true";
    attribute ASYNC_REG of s2SysrefTrig    : signal is "true";
  begin
    SysRefPulser : process(aReset, SampleClk2x)
    begin
      if aReset='1' then
        s2SysrefTrig_ms <= '0';
        s2SysrefTrig    <= '0';
        s2SysrefTrigDly <= '0';
        s2SysRefGo      <= '0';
      elsif rising_edge(SampleClk2x) then
        s2SysrefTrig_ms <= bSysRefGo;
        s2SysrefTrig    <= s2SysrefTrig_ms;
        s2SysrefTrigDly <= s2SysrefTrig;

        s2SysRefGo <= s2SysrefTrig and not s2SysrefTrigDly;
      end if;
    end process;
  end block SysRefBlock;

end RTL;
