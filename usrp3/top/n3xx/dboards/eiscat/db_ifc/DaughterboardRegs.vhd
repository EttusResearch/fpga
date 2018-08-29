-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
--
-- Purpose:
--
-- Register interface to the semi-static control lines for the EISCAT
-- Daughterboard. This module also allows back-door access to the SYSREF
-- driving logic in the FPGA (and to the ADCs).
--
-- XML register definition is included below the module.
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.PkgDaughterboardRegMap.all;
  use work.PkgRegs.all;


entity DaughterboardRegs is
  port(
    aReset                 : in  boolean;
    BusClk                 : in  std_logic;

    bRegPortOut            : out RegPortOut_t;
    bRegPortIn             : in  RegPortIn_t;

    -- Slot and DB ID values. These should be tied to constants!
    kDbId                  : in  std_logic_vector(15 downto 0);
    kSlotId                : in  std_logic;

    -- ADC Control
    aAdcSpiEn              : out std_logic;
    aAdcAReset             : out std_logic;
    aAdcBReset             : out std_logic;

    -- LMK Locked & Temp/Voltage Alert Bits
    aLmkStatus             : in  std_logic;
    aTmonAlert_n           : in  std_logic;
    aVmonAlert             : in  std_logic;

    -- DB Control
    aDbCtrlEn_n            : out std_logic;
    aLmkSpiEn              : out std_logic;
    aDbPwrEn               : out std_logic;
    aLnaCtrlEn             : out std_logic;
    aDbaCh0En_n            : out std_logic;
    aDbaCh1En_n            : out std_logic;
    aDbaCh2En_n            : out std_logic;
    aDbaCh3En_n            : out std_logic;
    aDbaCh4En_n            : out std_logic;
    aDbaCh5En_n            : out std_logic;
    aDbaCh6En_n            : out std_logic;
    aDbaCh7En_n            : out std_logic;

    bSysRefGo              : out std_logic

  );
end DaughterboardRegs;


architecture RTL of DaughterboardRegs is

  --vhook_sigstart
  --vhook_sigend

  signal bRegPortOutLcl : RegPortOut_t := kRegPortOutZero;

  signal aDbaCh0EnLcl,
         aDbaCh1EnLcl,
         aDbaCh2EnLcl,
         aDbaCh3EnLcl,
         aDbaCh4EnLcl,
         aDbaCh5EnLcl,
         aDbaCh6EnLcl,
         aDbaCh7EnLcl,
         aDbPwrEnLcl,
         aLnaCtrlEnLcl,
         aDbCtrlEnLcl,
         aLmkSpiEnLcl,
         aAdcSpiEnLcl,
         aAdcAResetLcl,
         aAdcBResetLcl,
         bLmkLocked_ms,
         bLmkLocked,
         bTmonAlert_msn,
         bTmonAlert_n,
         bVmonAlert_ms,
         bVmonAlert,
         bTmonAlertSticky,
         bVmonAlertSticky,
         bLmkUnlockedSticky  : std_logic := '0';

  signal bLmkUnlockedStickyReset,
         bTmonAlertStickyReset,
         bVmonAlertStickyReset : boolean := false;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of bLmkLocked_ms  : signal is "true";
  attribute ASYNC_REG of bLmkLocked     : signal is "true";
  attribute ASYNC_REG of bTmonAlert_msn : signal is "true";
  attribute ASYNC_REG of bTmonAlert_n   : signal is "true";
  attribute ASYNC_REG of bVmonAlert_ms  : signal is "true";
  attribute ASYNC_REG of bVmonAlert     : signal is "true";

begin



  -- Write Registers : ------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------
  WriteRegisters: process(aReset, BusClk)
  begin
    if aReset then
      -- Default everything here to de-asserted. Some of the lines on the DB are
      -- active-low, but we invert them after this register to keep all the logic
      -- here, and presented to SW, as active-high for simplicity.
      aAdcAResetLcl <= '0';
      aAdcBResetLcl <= '0';
      aAdcSpiEnLcl  <= '0';
      aDbPwrEnLcl   <= '0';
      aDbCtrlEnLcl  <= '0';
      aLmkSpiEnLcl  <= '0';
      aLnaCtrlEnLcl <= '0';
      aDbaCh0EnLcl  <= '0';
      aDbaCh1EnLcl  <= '0';
      aDbaCh2EnLcl  <= '0';
      aDbaCh3EnLcl  <= '0';
      aDbaCh4EnLcl  <= '0';
      aDbaCh5EnLcl  <= '0';
      aDbaCh6EnLcl  <= '0';
      aDbaCh7EnLcl  <= '0';
      bSysRefGo     <= '0';
      bLmkUnlockedStickyReset   <= false;
      bTmonAlertStickyReset     <= false;
      bVmonAlertStickyReset     <= false;
    elsif rising_edge(BusClk) then

      if RegWrite(kAdcControl, bRegPortIn) then
        if bRegPortIn.Data(kAdcAResetClear) = '1' then
          aAdcAResetLcl <= '0';
        elsif bRegPortIn.Data(kAdcAResetSet) = '1' then
          aAdcAResetLcl <= '1';
        end if;

        if bRegPortIn.Data(kAdcBResetClear) = '1' then
          aAdcBResetLcl <= '0';
        elsif bRegPortIn.Data(kAdcBResetSet) = '1' then
          aAdcBResetLcl <= '1';
        end if;

        if bRegPortIn.Data(kAdcSpiEnClear) = '1' then
          aAdcSpiEnLcl <= '0';
        elsif bRegPortIn.Data(kAdcSpiEnSet) = '1' then
          aAdcSpiEnLcl <= '1';
        end if;
      end if;


      if RegWrite(kDbEnables, bRegPortIn) then
        if bRegPortIn.Data(kDbPwrEnableClear) = '1' then
          aDbPwrEnLcl <= '0';
        elsif bRegPortIn.Data(kDbPwrEnableSet) = '1' then
          aDbPwrEnLcl <= '1';
        end if;

        if bRegPortIn.Data(kLnaCtrlEnableClear) = '1' then
          aLnaCtrlEnLcl <= '0';
        elsif bRegPortIn.Data(kLnaCtrlEnableSet) = '1' then
          aLnaCtrlEnLcl <= '1';
        end if;

        if bRegPortIn.Data(kLmkSpiEnableClear) = '1' then
          aLmkSpiEnLcl <= '0';
        elsif bRegPortIn.Data(kLmkSpiEnableSet) = '1' then
          aLmkSpiEnLcl <= '1';
        end if;

        if bRegPortIn.Data(kDbCtrlEnableClear) = '1' then
          aDbCtrlEnLcl <= '0';
        elsif bRegPortIn.Data(kDbCtrlEnableSet) = '1' then
          aDbCtrlEnLcl <= '1';
        end if;
      end if;


      if RegWrite(kDbChEnables, bRegPortIn) then
        aDbaCh0EnLcl <= bRegPortIn.Data(kCh0Enable);
        aDbaCh1EnLcl <= bRegPortIn.Data(kCh1Enable);
        aDbaCh2EnLcl <= bRegPortIn.Data(kCh2Enable);
        aDbaCh3EnLcl <= bRegPortIn.Data(kCh3Enable);
        aDbaCh4EnLcl <= bRegPortIn.Data(kCh4Enable);
        aDbaCh5EnLcl <= bRegPortIn.Data(kCh5Enable);
        aDbaCh6EnLcl <= bRegPortIn.Data(kCh6Enable);
        aDbaCh7EnLcl <= bRegPortIn.Data(kCh7Enable);
      end if;


      if RegWrite(kSysrefControl, bRegPortIn) then
        bSysRefGo <= bRegPortIn.Data(kSysrefGo);
      end if;

      -- Self-clearing strobe bit.
      bLmkUnlockedStickyReset <= false;
      if RegWrite(kLmkStatus, bRegPortIn) then
        bLmkUnlockedStickyReset <= bRegPortIn.Data(kLmkUnlockedStickyReset) = '1';
      end if;

      -- Self-clearing strobe bit.
      bTmonAlertStickyReset <= false;
      if RegWrite(kLmkStatus, bRegPortIn) then
        bTmonAlertStickyReset <= bRegPortIn.Data(kTmonAlertStickyReset) = '1';
      end if;

      -- Self-clearing strobe bit.
      bVmonAlertStickyReset <= false;
      if RegWrite(kLmkStatus, bRegPortIn) then
        bVmonAlertStickyReset <= bRegPortIn.Data(kVmonAlertStickyReset) = '1';
      end if;

    end if;
  end process WriteRegisters;


  -- Invert as needed for active-low signalling.
  aAdcSpiEn    <= aAdcSpiEnLcl;
  aAdcAReset   <= aAdcAResetLcl;
  aAdcBReset   <= aAdcBResetLcl;

  aDbCtrlEn_n  <= not aDbCtrlEnLcl;
  aLmkSpiEn    <= aLmkSpiEnLcl;
  aDbPwrEn     <= aDbPwrEnLcl;
  aLnaCtrlEn   <= aLnaCtrlEnLcl;
  aDbaCh0En_n  <= not aDbaCh0EnLcl;
  aDbaCh1En_n  <= not aDbaCh1EnLcl;
  aDbaCh2En_n  <= not aDbaCh2EnLcl;
  aDbaCh3En_n  <= not aDbaCh3EnLcl;
  aDbaCh4En_n  <= not aDbaCh4EnLcl;
  aDbaCh5En_n  <= not aDbaCh5EnLcl;
  aDbaCh6En_n  <= not aDbaCh6EnLcl;
  aDbaCh7En_n  <= not aDbaCh7EnLcl;


  DbStatus : process (aReset, BusClk)
  begin
    if aReset then
      bLmkLocked_ms      <= '0';
      bLmkLocked         <= '0';
      bLmkUnlockedSticky <= '0';
      bTmonAlert_msn     <= '0';
      bTmonAlert_n       <= '0';
      bTmonAlertSticky   <= '0';
      bVmonAlert_ms      <= '0';
      bVmonAlert         <= '0';
      bVmonAlertSticky   <= '0';
    elsif rising_edge(BusClk) then

      bLmkLocked_ms <= aLmkStatus;
      bLmkLocked    <= bLmkLocked_ms;

      -- The sticky will detect any condition where bLmkLocked goes *low*.
      if bLmkUnlockedStickyReset then
        bLmkUnlockedSticky <= not bLmkLocked;
      elsif bLmkLocked = '0' then
        bLmkUnlockedSticky <= '1';
      end if;


      bTmonAlert_msn <= aTmonAlert_n;
      bTmonAlert_n   <= bTmonAlert_msn;

      -- The sticky will detect any condition where bTmonAlert_n goes *low* (asserts).
      if bTmonAlertStickyReset then
        bTmonAlertSticky <= not bTmonAlert_n;
      elsif bTmonAlert_n = '0' then
        bTmonAlertSticky <= '1';
      end if;


      bVmonAlert_ms <= aVmonAlert;
      bVmonAlert    <= bVmonAlert_ms;

      -- The sticky will detect any condition where bVmonAlert goes *high*.
      if bVmonAlertStickyReset then
        bVmonAlertSticky <= bVmonAlert;
      elsif bVmonAlert = '1' then
        bVmonAlertSticky <= '1';
      end if;

    end if;
  end process;



  -- Read Registers : -------------------------------------------------------------------
  -- ------------------------------------------------------------------------------------
  ReadRegisters: process(aReset, BusClk)
  begin
    if aReset then
      bRegPortOutLcl           <= kRegPortOutZero;
    elsif rising_edge(BusClk) then

      -- Deassert strobes
      bRegPortOutLcl.Data      <= kRegPortDataZero;

      -- All of these transactions only take one clock cycle, so we do not have to
      -- de-assert the Ready signal (ever).
      bRegPortOutLcl.Ready <= true;

      if RegRead(kAdcControl, bRegPortIn) then
        bRegPortOutLcl.Data(kAdcAResetSet)     <= aAdcAResetLcl;
        bRegPortOutLcl.Data(kAdcAResetClear)   <= not aAdcAResetLcl;
        bRegPortOutLcl.Data(kAdcBResetSet)     <= aAdcBResetLcl;
        bRegPortOutLcl.Data(kAdcBResetClear)   <= not aAdcBResetLcl;
        bRegPortOutLcl.Data(kAdcSpiEnSet)      <= aAdcSpiEnLcl;
        bRegPortOutLcl.Data(kAdcSpiEnClear)    <= not aAdcSpiEnLcl;
      end if;

      if RegRead(kLmkStatus, bRegPortIn) then
        bRegPortOutLcl.Data(kLmkLocked)         <= bLmkLocked;
        bRegPortOutLcl.Data(kLmkUnlockedSticky) <= bLmkUnlockedSticky;
      end if;

      if RegRead(kDbEnables, bRegPortIn) then
        bRegPortOutLcl.Data(kDbPwrEnableSet)     <= aDbPwrEnLcl;
        bRegPortOutLcl.Data(kDbPwrEnableClear)   <= not aDbPwrEnLcl;
        bRegPortOutLcl.Data(kLnaCtrlEnableSet)   <= aLnaCtrlEnLcl;
        bRegPortOutLcl.Data(kLnaCtrlEnableClear) <= not aLnaCtrlEnLcl;
        bRegPortOutLcl.Data(kLmkSpiEnableSet)    <= aLmkSpiEnLcl;
        bRegPortOutLcl.Data(kLmkSpiEnableClear)  <= not aLmkSpiEnLcl;
        bRegPortOutLcl.Data(kDbCtrlEnableSet)    <= aDbCtrlEnLcl;
        bRegPortOutLcl.Data(kDbCtrlEnableClear)  <= not aDbCtrlEnLcl;
      end if;

      if RegRead(kTmonAlertStatus, bRegPortIn) then
        bRegPortOutLcl.Data(kTmonAlert)          <= not bTmonAlert_n;
        bRegPortOutLcl.Data(kTmonAlertSticky)    <= bTmonAlertSticky;
      end if;

      if RegRead(kVmonAlertStatus, bRegPortIn) then
        bRegPortOutLcl.Data(kVmonAlert)          <= bVmonAlert;
        bRegPortOutLcl.Data(kVmonAlertSticky)    <= bVmonAlertSticky;
      end if;

      if RegRead(kDaughterboardId, bRegPortIn) then
        bRegPortOutLcl.Data(kDbIdValMsb downto kDbIdVal) <= kDbId;
        bRegPortOutLcl.Data(kSlotIdVal)                  <= kSlotId;
      end if;

    end if;
  end process ReadRegisters;

  -- Local to output
  bRegPortOut <= bRegPortOutLcl;


end RTL;


--XmlParse xml_on
--<regmap name="DaughterboardRegMap">
--  <group name="StaticControl" order="1">
--
--    <register name="AdcControl" size="32" offset="0x00" attributes="Readable|Writable">
--      <info>
--      </info>
--
--      <bitfield name="AdcAResetSet" range="0" attributes="Strobe">
--        <info>
--          Defaults to '0'. Strobe this bit to assert ADC A Reset.
--        </info>
--      </bitfield>
--      <bitfield name="AdcAResetClear" range="4" attributes="Strobe">
--        <info>
--          Defaults to '1'. Strobe this bit to de-assert ADC A Reset.
--        </info>
--      </bitfield>
--
--      <bitfield name="AdcBResetSet" range="08" attributes="Strobe">
--        <info>
--          Defaults to '0'. Strobe this bit to assert ADC B Reset.
--        </info>
--      </bitfield>
--      <bitfield name="AdcBResetClear" range="12" attributes="Strobe">
--        <info>
--          Defaults to '1'. Strobe this bit to de-assert ADC B Reset.
--        </info>
--      </bitfield>
--
--      <bitfield name="AdcSpiEnSet" range="16" attributes="Strobe">
--        <info>
--          Defaults to '0'. Strobe this bit to assert the ADC SPI enable, which allows
--          communication via SPI to both of the ADCs. If de-asserted, then this control
--          tri-states the level translator on the DB and the ADC SPI lines are pulled
--          to de-asserted values by board pulls. This bit is only effective if
--          DbCtrlEnable is asserted in the DbEnables register.
--        </info>
--      </bitfield>
--      <bitfield name="AdcSpiEnClear" range="20" attributes="Strobe">
--        <info>
--          Defaults to '1'. Strobe this bit to de-assert the ADC SPI enable.
--        </info>
--      </bitfield>
--
--    </register>
--
--
--    <register name="LmkStatus" size="32" offset="0x04" attributes="Readable|Writable">
--      <bitfield name="LmkLocked" range="0">
--        <info>
--          Live reading of the LMK PLL Locked bits (PLL1 and PLL2)  line from the DB
--          (ANDed together).
--        </info>
--      </bitfield>
--      <bitfield name="LmkUnlockedSticky" range="1" attributes="Readable">
--        <info>
--          If the LMK ever reports an unlocked condition, this bit will set to '1'.
--          Clear it by strobing the LmkUnlockedStickyReset bit.
--        </info>
--      </bitfield>
--      <bitfield name="LmkUnlockedStickyReset" range="4" attributes="Strobe">
--        <info>
--          Clear LmkUnlockedSticky by strobing this bit.
--        </info>
--      </bitfield>
--    </register>
--
--
--    <register name="DbEnables" size="32" offset="0x08" attributes="Readable|Writable">
--      <info>
--      </info>
--
--      <bitfield name="DbPwrEnableSet"   range="0" attributes="Strobe">
--        <info>
--          Strobe this bit to enable the power on the DB. In order for this control to be
--          effective, DbCtrlEnable must be Set. Defaults to '0'.
--          Strobe this bit to assert. </info>
--      </bitfield>
--      <bitfield name="DbPwrEnableClear" range="4" attributes="Strobe">
--        <info> Defaults to '1'. Strobe this bit to de-assert. </info>
--      </bitfield>
--
--      <bitfield name="LnaCtrlEnableSet"   range="8" attributes="Strobe">
--        <info>
--          LnaCtrlEnable must be asserted (Set) for the values in DbChEnables to
--          be driven to the LNAs. If this control is cleared then the enables to the LNAs
--          are tri-stated by buffers on the DB and pulled to disabled by the LNA
--          internally. Defaults to '0'. Strobe this bit to assert. </info>
--      </bitfield>
--      <bitfield name="LnaCtrlEnableClear" range="12" attributes="Strobe">
--        <info> Defaults to '1'. Strobe this bit to de-assert. </info>
--      </bitfield>
--
--      <bitfield name="LmkSpiEnableSet"   range="16" attributes="Strobe">
--        <info>
--          Strobe this control to enable the DB level translators for the LMK SPI lines.
--          this control is cleared, then the LMK SPI lines will be tri-stated and pulled
--          to de-asserted values by pulls on the DB. Defaults to '0'.
--          Strobe this bit to assert. </info>
--      </bitfield>
--      <bitfield name="LmkSpiEnableClear" range="20" attributes="Strobe">
--        <info> Defaults to '1'. Strobe this bit to de-assert. </info>
--      </bitfield>
--
--      <bitfield name="DbCtrlEnableSet"   range="24" attributes="Strobe">
--        <info>
--          This is the one control to rule them all. This control must be set for any of the
--          other bits in this register to take effect. Defaults to '0'.
--          Strobe this bit to assert. </info>
--      </bitfield>
--      <bitfield name="DbCtrlEnableClear" range="28" attributes="Strobe">
--        <info> Defaults to '1'. Strobe this bit to de-assert. </info>
--      </bitfield>
--
--    </register>
--
--
--    <register name="DbChEnables" size="32" offset="0x0C" attributes="Readable|Writable">
--      <info>
--        Values in this register control the LNA enabled for each channel. A value of '1'
--        enables the LNA and a value of '0' disables it. These values are only valid
--        when the LnaCtrlEnableSet bit is asserted in the DbEnables register.
--      </info>
--
--      <bitfield name="Ch0Enable" range="0"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch1Enable" range="1"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch2Enable" range="2"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch3Enable" range="3"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch4Enable" range="4"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch5Enable" range="5"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch6Enable" range="6"> <info> Defaults to '0'. </info> </bitfield>
--      <bitfield name="Ch7Enable" range="7"> <info> Defaults to '0'. </info> </bitfield>
--
--    </register>
--
--
--    <register name="TmonAlertStatus" size="32" offset="0x10" attributes="Readable|Writable">
--      <bitfield name="TmonAlert" range="0" attributes="Readable">
--        <info>
--          Live reading of the TmonAlert line from the DB.
--        </info>
--      </bitfield>
--      <bitfield name="TmonAlertSticky" range="1" attributes="Readable">
--        <info>
--          If the Tmon line ever asserts, this bit will set to '1'.
--          Clear it by strobing the TmonAlertStickyReset bit.
--        </info>
--      </bitfield>
--      <bitfield name="TmonAlertStickyReset" range="4" attributes="Strobe">
--        <info>
--          Clear TmonAlertSticky by strobing this bit.
--        </info>
--      </bitfield>
--    </register>
--
--
--    <register name="VmonAlertStatus" size="32" offset="0x14" attributes="Readable|Writable">
--      <bitfield name="VmonAlert" range="0" attributes="Readable">
--        <info>
--          Live reading of the VmonAlert line from the DB.
--        </info>
--      </bitfield>
--      <bitfield name="VmonAlertSticky" range="1" attributes="Readable">
--        <info>
--          If the Vmon line ever asserts, this bit will set to '1'.
--          Clear it by strobing the VmonAlertStickyReset bit.
--        </info>
--      </bitfield>
--      <bitfield name="VmonAlertStickyReset" range="4" attributes="Strobe">
--        <info>
--          Clear VmonAlertSticky by strobing this bit.
--        </info>
--      </bitfield>
--    </register>
--
--
--    <register name="SysrefControl" size="32" offset="0x20" attributes="Writable">
--      <info>
--        Controls backdoor access to issuing SYSREF.
--      </info>
--      <bitfield name="SysrefGo" range="0">
--        <info>
--          Write this bit to '0', '1', and then '0' to trigger a set of SYSREF pulses.
--          Defaults to '0'.
--        </info>
--      </bitfield>
--    </register>
--
--
--    <register name="DaughterboardId" size="32" offset="0x30" attributes="Readable">
--      <info>
--      </info>
--      <bitfield name="DbIdVal" range="15..0">
--        <info>
--          ID for the DB with which this file is designed to communicate. Matches the DB
--          EEPROM ID.
--        </info>
--      </bitfield>
--      <bitfield name="SlotIdVal" range="16">
--        <info>
--          ID for the Slot this module controls. Options are 0 and 1 for the N310 MB.
--        </info>
--      </bitfield>
--    </register>
--
--  </group>
--
--
--</regmap>
--XmlParse xml_off
