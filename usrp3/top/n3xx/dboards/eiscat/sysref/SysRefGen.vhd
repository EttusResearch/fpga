-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

library work;

entity SysRefGen is
  port (
    aReset                 : in  boolean;

    --
    SampleClk1x            : in  std_logic;
    SampleClk2x            : in  std_logic;

    --
    s2SysRefTriggerIn      : in  std_logic;
    s2SysRefToAdcOut       : out std_logic;
    s2SysRefToFpgaOut      : out std_logic;

    s2SlowClkPhase         : out std_logic


  );
end SysRefGen;


architecture rtl of SysRefGen is

  signal sSlowClkToggle,
         s2SlowClkPhaseCap,
         s2SlowClkPhaseLcl,
         s2SysRefTriggerInDly,
         s2SysRefTriggerInDly2,
         s2SendSysRefDly,
         sSendSysRefDly,
         sSendSysRef,
         s2SysRefOut,
         s2FastClkToggle,
         s2FastClkToggleDly : std_logic;

begin

  Gen1xToggle : process(aReset, SampleClk1x)
  begin
    if aReset then
      sSlowClkToggle <= '0';
    elsif rising_edge(SampleClk1x) then
      sSlowClkToggle <= not sSlowClkToggle;
    end if;
  end process;

  Gen2xToggle : process(aReset, SampleClk2x)
  begin
    if aReset then
      s2FastClkToggle    <= '0';
      s2FastClkToggleDly <= '0';
      s2SlowClkPhaseLcl  <= '0';
    elsif rising_edge(SampleClk2x) then
      s2FastClkToggle    <= sSlowClkToggle;
      s2FastClkToggleDly <= s2FastClkToggle;
      s2SlowClkPhaseLcl  <= (s2FastClkToggleDly xor s2FastClkToggle);
    end if;
  end process;

  s2SlowClkPhase <= s2SlowClkPhaseLcl;

  -- Condition SYSREF
  ConditionSysRef : process(aReset, SampleClk2x)
  begin
    if aReset then
      s2SysRefTriggerInDly  <= '0';
      s2SysRefTriggerInDly2 <= '0';
      s2SlowClkPhaseCap <= '0';
    elsif rising_edge(SampleClk2x) then
      s2SysRefTriggerInDly  <= s2SysRefTriggerIn;
      s2SysRefTriggerInDly2 <= s2SysRefTriggerInDly;
      if s2SysRefTriggerIn='1' then
        s2SlowClkPhaseCap <= s2SlowClkPhaseLcl;
      end if;
    end if;
  end process;

  s2SysRefOut  <= s2SysRefTriggerInDly when s2SlowClkPhaseCap = '0'
                 else s2SysRefTriggerInDly2;
  s2SysRefToAdcOut <= s2SysRefOut;

  InternalSysRefDelayFastClkProc : process(aReset, SampleClk2x)
  begin
    if aReset then
      s2SendSysRefDly <= '0';
    elsif rising_edge(SampleClk2x) then
      s2SendSysRefDly <= s2SysRefOut;
    end if;
  end process;

  InternalSysRefDelaySlowClkProc : process(aReset, SampleClk1x)
  begin
    if aReset then
      sSendSysRef     <= '0';
      sSendSysRefDly  <= '0';
    elsif rising_edge(SampleClk1x) then
      sSendSysRef     <= s2SendSysRefDly;
      sSendSysRefDly  <= sSendSysRef;
    end if;
  end process;

  s2SysRefToFpgaOut <= sSendSysRef;


end rtl;

