-------------------------------------------------------------------------------
--
-- File: DbCore.vhd
-- Author: Daniel Jepson
-- Original Project: N310
-- Date: 12 April 2017
--
-------------------------------------------------------------------------------
-- (c) 2017 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
-------------------------------------------------------------------------------
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
  use work.PkgMgPersonality.all;
  use work.PkgRegs.all;
  use work.PkgJesdConfig.all;


entity DbCore is
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
    kSlotId                : in  std_logic;


    -- SYSREF --
    --
    -- SYSREF from the LMK
    sSysRefFpgaLvds_p,
    sSysRefFpgaLvds_n      : in  std_logic;

    sSysRef                : out std_logic;
    aLmkSync               : out std_logic;


    -- JESD Signals --
    --
    -- GTX Sample Clock Reference Input. Direct connect to FPGA pins.
    JesdRefClk_p,
    JesdRefClk_n           : in  std_logic;

    -- ADC JESD PHY Interface. Direct connect to FPGA pins.
    aAdcRx_p,
    aAdcRx_n               : in  std_logic_vector(3 downto 0);
    aSyncAdcOut_n          : out std_logic;

    -- DAC JESD PHY Interface. Direct connect to FPGA pins.
    aDacTx_p,
    aDacTx_n               : out std_logic_vector(3 downto 0);
    aSyncDacIn_n           : in  std_logic;


    -- Debug Outputs for JESD.
    aAdcSync               : out std_logic;
    aDacSync               : out std_logic;


    -- Data Pipes to/from the DACs/ADCs --
    --
    -- Data is presented as one sample per cycle.
    -- sAdcDataValid asserts when ADC datas are valid. sDacReadyForInput asserts when
    -- DAC data is ready to be received.
    sAdcDataValid          : out std_logic;
    sAdcDataSamples0I      : out std_logic_vector(15 downto 0);
    sAdcDataSamples0Q      : out std_logic_vector(15 downto 0);
    sAdcDataSamples1I      : out std_logic_vector(15 downto 0);
    sAdcDataSamples1Q      : out std_logic_vector(15 downto 0);
    sDacReadyForInput      : out std_logic;
    sDacDataSamples0I      : in  std_logic_vector(15 downto 0);
    sDacDataSamples0Q      : in  std_logic_vector(15 downto 0);
    sDacDataSamples1I      : in  std_logic_vector(15 downto 0);
    sDacDataSamples1Q      : in  std_logic_vector(15 downto 0);


    -- RefClk & Timing & Sync --
    RefClk                 : in  std_logic;
    rPpsPulse              : in  std_logic;
    rGatedPulseToPin       : inout std_logic; -- straight to pin
    sGatedPulseToPin       : inout std_logic; -- straight to pin

    -- Debug Outputs
    rRSP                   : out std_logic;
    sRTC                   : out std_logic;
    sPps                   : out std_logic


    -- DB Control Signals
    -- aAdcSpiEn              : out   std_logic

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
      aReset                : in  STD_LOGIC;
      bReset                : in  STD_LOGIC;
      BusClk                : in  STD_LOGIC;
      ReliableClk40         : in  STD_LOGIC;
      FpgaClk1x             : in  STD_LOGIC;
      FpgaClk2x             : in  STD_LOGIC;
      bFpgaClksStable       : in  STD_LOGIC;
      bRegPortInFlat        : in  STD_LOGIC_VECTOR(49 downto 0);
      bRegPortOutFlat       : out STD_LOGIC_VECTOR(33 downto 0);
      aLmkSync              : out STD_LOGIC;
      cSysRefFpgaLvds_p     : in  STD_LOGIC;
      cSysRefFpgaLvds_n     : in  STD_LOGIC;
      fSysRef               : out STD_LOGIC;
      CaptureSysRefClk      : in  STD_LOGIC;
      JesdRefClk_p          : in  STD_LOGIC;
      JesdRefClk_n          : in  STD_LOGIC;
      bJesdRefClkPresent    : out STD_LOGIC;
      aAdcRx_p              : in  STD_LOGIC_VECTOR(3 downto 0);
      aAdcRx_n              : in  STD_LOGIC_VECTOR(3 downto 0);
      aSyncAdcOut_n         : out STD_LOGIC;
      aDacTx_p              : out STD_LOGIC_VECTOR(3 downto 0);
      aDacTx_n              : out STD_LOGIC_VECTOR(3 downto 0);
      aSyncDacIn_n          : in  STD_LOGIC;
      fAdc0DataFlat         : out STD_LOGIC_VECTOR(31 downto 0);
      fAdc1DataFlat         : out STD_LOGIC_VECTOR(31 downto 0);
      fDac0DataFlat         : in  STD_LOGIC_VECTOR(31 downto 0);
      fDac1DataFlat         : in  STD_LOGIC_VECTOR(31 downto 0);
      fAdcDataValid         : out STD_LOGIC;
      fDacReadyForInput     : out STD_LOGIC;
      bDac0DataSettingsFlat : in  STD_LOGIC_VECTOR(5 downto 0);
      bDac1DataSettingsFlat : in  STD_LOGIC_VECTOR(5 downto 0);
      bAdc0DataSettingsFlat : in  STD_LOGIC_VECTOR(5 downto 0);
      bAdc1DataSettingsFlat : in  STD_LOGIC_VECTOR(5 downto 0);
      aDacSync              : out STD_LOGIC;
      aAdcSync              : out STD_LOGIC);
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
  signal bAdc0DataSettingsFlat: STD_LOGIC_VECTOR(5 downto 0);
  signal bAdc1DataSettingsFlat: STD_LOGIC_VECTOR(5 downto 0);
  signal bClockingRegPortOut: RegPortOut_t;
  signal bDac0DataSettingsFlat: STD_LOGIC_VECTOR(5 downto 0);
  signal bDac1DataSettingsFlat: STD_LOGIC_VECTOR(5 downto 0);
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
  signal sAdc0DataFlat: STD_LOGIC_VECTOR(31 downto 0);
  signal sAdc1DataFlat: STD_LOGIC_VECTOR(31 downto 0);
  signal SampleClk1xOutLcl: STD_LOGIC;
  signal sDac0DataFlat: STD_LOGIC_VECTOR(31 downto 0);
  signal sDac1DataFlat: STD_LOGIC_VECTOR(31 downto 0);
  signal sLoadRtcCounts: STD_LOGIC;
  signal sPpsClkCrossDelayVal: STD_LOGIC_VECTOR(3 downto 0);
  signal sRtcHighTimeInSClks: STD_LOGIC_VECTOR(11 downto 0);
  signal sRtcPeriodInSClks: STD_LOGIC_VECTOR(11 downto 0);
  --vhook_sigend

  signal bJesdRegPortInGrp, bSyncRegPortInGrp, bRegPortIn : RegPortIn_t;
  signal bJesdRegPortOut, bSyncRegPortOut, bRegPortOut : RegPortOut_t;

  signal sAdc0Data, sAdc1Data : AdcData_t;
  signal sDac0Data, sDac1Data : DacData_t;

  constant kDataControlDefault : DataSettings_t :=
    (AisI => '1',
     BisQ => '1',
     others => '0');

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
  --vhook_a FpgaClk1x        SampleClk1x
  --vhook_a FpgaClk2x        SampleClk2x
  --vhook_a ReliableClk40    Clk40
  --vhook_a CaptureSysRefClk   SampleClk1xOutLcl
  --vhook_a cSysRefFpgaLvds_p  sSysRefFpgaLvds_p
  --vhook_a cSysRefFpgaLvds_n  sSysRefFpgaLvds_n
  --vhook_a {^f(.*)}         s$1
  Jesd204bXcvrCorex: Jesd204bXcvrCore
    port map (
      aReset                => aReset,                   --in  STD_LOGIC
      bReset                => bReset,                   --in  STD_LOGIC
      BusClk                => BusClk,                   --in  STD_LOGIC
      ReliableClk40         => Clk40,                    --in  STD_LOGIC
      FpgaClk1x             => SampleClk1x,              --in  STD_LOGIC
      FpgaClk2x             => SampleClk2x,              --in  STD_LOGIC
      bFpgaClksStable       => bFpgaClksStable,          --in  STD_LOGIC
      bRegPortInFlat        => bJesdCoreRegPortInFlat,   --in  STD_LOGIC_VECTOR(49:0)
      bRegPortOutFlat       => bJesdCoreRegPortOutFlat,  --out STD_LOGIC_VECTOR(33:0)
      aLmkSync              => aLmkSync,                 --out STD_LOGIC
      cSysRefFpgaLvds_p     => sSysRefFpgaLvds_p,        --in  STD_LOGIC
      cSysRefFpgaLvds_n     => sSysRefFpgaLvds_n,        --in  STD_LOGIC
      fSysRef               => sSysRef,                  --out STD_LOGIC
      CaptureSysRefClk      => SampleClk1xOutLcl,        --in  STD_LOGIC
      JesdRefClk_p          => JesdRefClk_p,             --in  STD_LOGIC
      JesdRefClk_n          => JesdRefClk_n,             --in  STD_LOGIC
      bJesdRefClkPresent    => bJesdRefClkPresent,       --out STD_LOGIC
      aAdcRx_p              => aAdcRx_p,                 --in  STD_LOGIC_VECTOR(3:0)
      aAdcRx_n              => aAdcRx_n,                 --in  STD_LOGIC_VECTOR(3:0)
      aSyncAdcOut_n         => aSyncAdcOut_n,            --out STD_LOGIC
      aDacTx_p              => aDacTx_p,                 --out STD_LOGIC_VECTOR(3:0)
      aDacTx_n              => aDacTx_n,                 --out STD_LOGIC_VECTOR(3:0)
      aSyncDacIn_n          => aSyncDacIn_n,             --in  STD_LOGIC
      fAdc0DataFlat         => sAdc0DataFlat,            --out STD_LOGIC_VECTOR(31:0)
      fAdc1DataFlat         => sAdc1DataFlat,            --out STD_LOGIC_VECTOR(31:0)
      fDac0DataFlat         => sDac0DataFlat,            --in  STD_LOGIC_VECTOR(31:0)
      fDac1DataFlat         => sDac1DataFlat,            --in  STD_LOGIC_VECTOR(31:0)
      fAdcDataValid         => sAdcDataValid,            --out STD_LOGIC
      fDacReadyForInput     => sDacReadyForInput,        --out STD_LOGIC
      bDac0DataSettingsFlat => bDac0DataSettingsFlat,    --in  STD_LOGIC_VECTOR(5:0)
      bDac1DataSettingsFlat => bDac1DataSettingsFlat,    --in  STD_LOGIC_VECTOR(5:0)
      bAdc0DataSettingsFlat => bAdc0DataSettingsFlat,    --in  STD_LOGIC_VECTOR(5:0)
      bAdc1DataSettingsFlat => bAdc1DataSettingsFlat,    --in  STD_LOGIC_VECTOR(5:0)
      aDacSync              => aDacSync,                 --out STD_LOGIC
      aAdcSync              => aAdcSync);                --out STD_LOGIC

  -- Just combine the first two enables, since they're the ones that are used for JESD.
  bFpgaClksStable <= bRadioClksValid and bRadioClk1xEnabled and bRadioClk2xEnabled;

  -- Compress/expand the flat data types from the netlist and route to top level.
  sAdc0Data     <= Unflatten(sAdc0DataFlat);
  sAdc1Data     <= Unflatten(sAdc1DataFlat);
  sDac0DataFlat <= Flatten(sDac0Data);
  sDac1DataFlat <= Flatten(sDac1Data);

  sAdcDataSamples0I <= sAdc0Data.I;
  sAdcDataSamples0Q <= sAdc0Data.Q;
  sAdcDataSamples1I <= sAdc1Data.I;
  sAdcDataSamples1Q <= sAdc1Data.Q;

  sDac0Data.I <= sDacDataSamples0I;
  sDac0Data.Q <= sDacDataSamples0Q;
  sDac1Data.I <= sDacDataSamples1I;
  sDac1Data.Q <= sDacDataSamples1Q;

  -- Compress the flat data control types from the netlist and route from top level.
  --vhook_warn Data Settings vector tied to default.
  bAdc0DataSettingsFlat <= Flatten(kDataControlDefault);
  bAdc1DataSettingsFlat <= Flatten(kDataControlDefault);
  bDac0DataSettingsFlat <= Flatten(kDataControlDefault);
  bDac1DataSettingsFlat <= Flatten(kDataControlDefault);


  -- Timing and Sync : ------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------

  --vhook_e TdcWrapper
  --vhook_a SampleClk SampleClk1xOutLcl
  --vhook_a sPpsPulse sPps
  --vhook_a sGatedPulseToPin sGatedPulseToPin
  --vhook_a {^s(.*)}  s$1
  TdcWrapperx: entity work.TdcWrapper (struct)
    port map (
      aReset               => aReset,                --in  std_logic
      RefClk               => RefClk,                --in  std_logic
      SampleClk            => SampleClk1xOutLcl,     --in  std_logic
      MeasClk              => MeasClk,               --in  std_logic
      rResetTdc            => rResetTdc,             --in  std_logic
      rResetTdcDone        => rResetTdcDone,         --out std_logic
      rEnableTdc           => rEnableTdc,            --in  std_logic
      rReRunEnable         => rReRunEnable,          --in  std_logic
      rPpsPulse            => rPpsPulse,             --in  std_logic
      rPpsPulseCaptured    => rPpsPulseCaptured,     --out std_logic
      rEnablePpsCrossing   => rEnablePpsCrossing,    --in  std_logic
      sPpsClkCrossDelayVal => sPpsClkCrossDelayVal,  --in  std_logic_vector(3:0)
      sPpsPulse            => sPps,                  --out std_logic
      mRspOffset           => mRspOffset,            --out std_logic_vector(39:0)
      mRtcOffset           => mRtcOffset,            --out std_logic_vector(39:0)
      mOffsetsDone         => mOffsetsDone,          --out std_logic
      mOffsetsValid        => mOffsetsValid,         --out std_logic
      rLoadRspCounts       => rLoadRspCounts,        --in  std_logic
      rRspPeriodInRClks    => rRspPeriodInRClks,     --in  std_logic_vector(11:0)
      rRspHighTimeInRClks  => rRspHighTimeInRClks,   --in  std_logic_vector(11:0)
      sLoadRtcCounts       => sLoadRtcCounts,        --in  std_logic
      sRtcPeriodInSClks    => sRtcPeriodInSClks,     --in  std_logic_vector(11:0)
      sRtcHighTimeInSClks  => sRtcHighTimeInSClks,   --in  std_logic_vector(11:0)
      rRSP                 => rRSP,                  --out std_logic
      sRTC                 => sRTC,                  --out std_logic
      rGatedPulseToPin     => rGatedPulseToPin,      --inout std_logic
      sGatedPulseToPin     => sGatedPulseToPin);     --inout std_logic


  bSyncRegPortInGrp <= Mask(RegPortIn       => bRegPortIn,
                            kRegisterOffset => kSyncOffsetsInEndpoint); -- 0x0200

  -- Expand/compress the RegPort for moving through the netlist boundary.
  bSyncRegPortOut <= Unflatten(bSyncRegPortOutFlat);
  bSyncRegPortInFlat <= Flatten(bSyncRegPortInGrp);

  --vhook   SyncRegsIfc
  --vhook_a bRegPortInFlat  bSyncRegPortInFlat
  --vhook_a bRegPortOutFlat bSyncRegPortOutFlat
  --vhook_a SampleClk SampleClk1xOutLcl
  --vhook_a {^s(.*)}  s$1
  SyncRegsIfcx: SyncRegsIfc
    port map (
      aReset               => aReset,                --in  STD_LOGIC
      BusClk               => BusClk,                --in  STD_LOGIC
      bRegPortInFlat       => bSyncRegPortInFlat,    --in  STD_LOGIC_VECTOR(49:0)
      bRegPortOutFlat      => bSyncRegPortOutFlat,   --out STD_LOGIC_VECTOR(33:0)
      RefClk               => RefClk,                --in  STD_LOGIC
      rResetTdc            => rResetTdc,             --out STD_LOGIC
      rResetTdcDone        => rResetTdcDone,         --in  STD_LOGIC
      rEnableTdc           => rEnableTdc,            --out STD_LOGIC
      rReRunEnable         => rReRunEnable,          --out STD_LOGIC
      rEnablePpsCrossing   => rEnablePpsCrossing,    --out STD_LOGIC
      rPpsPulseCaptured    => rPpsPulseCaptured,     --in  STD_LOGIC
      SampleClk            => SampleClk1xOutLcl,     --in  STD_LOGIC
      sPpsClkCrossDelayVal => sPpsClkCrossDelayVal,  --out STD_LOGIC_VECTOR(3:0)
      MeasClk              => MeasClk,               --in  STD_LOGIC
      mRspOffset           => mRspOffset,            --in  STD_LOGIC_VECTOR(39:0)
      mRtcOffset           => mRtcOffset,            --in  STD_LOGIC_VECTOR(39:0)
      mOffsetsDone         => mOffsetsDone,          --in  STD_LOGIC
      mOffsetsValid        => mOffsetsValid,         --in  STD_LOGIC
      rLoadRspCounts       => rLoadRspCounts,        --out STD_LOGIC
      rRspPeriodInRClks    => rRspPeriodInRClks,     --out STD_LOGIC_VECTOR(11:0)
      rRspHighTimeInRClks  => rRspHighTimeInRClks,   --out STD_LOGIC_VECTOR(11:0)
      sLoadRtcCounts       => sLoadRtcCounts,        --out STD_LOGIC
      sRtcPeriodInSClks    => sRtcPeriodInSClks,     --out STD_LOGIC_VECTOR(11:0)
      sRtcHighTimeInSClks  => sRtcHighTimeInSClks);  --out STD_LOGIC_VECTOR(11:0)



  -- Daughterboard Control : ------------------------------------------------------------
  -- ------------------------------------------------------------------------------------

  --vhook_e DaughterboardRegs
  --vhook_a aReset to_boolean(aReset)
  --vhook_a bRegPortOut bDbRegPortOut
  --vhook_a kDbId       std_logic_vector(to_unsigned(16#150#,16))
  DaughterboardRegsx: entity work.DaughterboardRegs (RTL)
    port map (
      aReset      => to_boolean(aReset),                         --in  boolean
      BusClk      => BusClk,                                     --in  std_logic
      bRegPortOut => bDbRegPortOut,                              --out RegPortOut_t
      bRegPortIn  => bRegPortIn,                                 --in  RegPortIn_t
      kDbId       => std_logic_vector(to_unsigned(16#150#,16)),  --in  std_logic_vector(15:0)
      kSlotId     => kSlotId);                                   --in  std_logic


end RTL;
