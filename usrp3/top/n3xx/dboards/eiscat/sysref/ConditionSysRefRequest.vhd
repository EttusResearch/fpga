-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
--
-- Purpose:
--
--vhook_warn need some purpose here
-- vreview_group JesdCore
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ConditionSysRefRequest is
  port (
    aReset                 : in  std_logic;

    -- Sample Clocks
    SampleClk1x            : in  std_logic;
    SampleClk2x            : in  std_logic;

    -- Incoming and outgoing pulses. These only need to be 1 cycle long of the
    -- SampleClk2x domain.
    s2SysRefGo             : in  std_logic;
    s2SysRefGoCond         : out std_logic;

    -- Debug
    s2SlowClkPhase         : out std_logic


  );
end ConditionSysRefRequest;


architecture rtl of ConditionSysRefRequest is

  signal sSlowClkToggle,
         s2SlowClkPhaseCap,
         s2SlowClkPhaseLcl,
         s2SysRefGoCondNxt,
         s2SysRefTriggerInDly,
         s2SysRefTriggerInDly2,
         s2FastClkToggle,
         s2FastClkToggleDly : std_logic;

begin

  -- Start a toggle in the slow clock domain.
  Gen1xToggle : process(aReset, SampleClk1x)
  begin
    if aReset ='1' then
      sSlowClkToggle <= '0';
    elsif rising_edge(SampleClk1x) then
      sSlowClkToggle <= not sSlowClkToggle;
    end if;
  end process;

  -- Pass the slow toggle into the 2x domain, delay it by 1 cycle, then compare
  -- the original and delayed toggles to (magically) reveal the phase of the slow
  -- clock with respect to the fast clock.
  Gen2xToggle : process(aReset, SampleClk2x)
  begin
    if aReset ='1' then
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
    if aReset ='1' then
      s2SysRefTriggerInDly  <= '0';
      s2SysRefTriggerInDly2 <= '0';
      s2SlowClkPhaseCap     <= '0';
      s2SysRefGoCondNxt     <= '0';
      s2SysRefGoCond     <= '0';
    elsif rising_edge(SampleClk2x) then
      s2SysRefTriggerInDly  <= s2SysRefGo;
      s2SysRefTriggerInDly2 <= s2SysRefTriggerInDly;

      -- Sample the phase of the slow clock whenever we receive an input pulse.
      if s2SysRefGo = '1' then
        s2SlowClkPhaseCap <= s2SlowClkPhaseLcl;
      end if;

      -- This used to be combinatorial, but in order to have the Go signal leave
      -- this module directly from a flop, I need to flop the signal twice to maintain
      -- the correct phase relationship between the 1x and 2x domains.
      if s2SlowClkPhaseCap = '0' then
        s2SysRefGoCondNxt <= s2SysRefTriggerInDly;
      else
        s2SysRefGoCondNxt <= s2SysRefTriggerInDly2;
      end if;

      -- Flop this signal one more time in the 2x domain to guarantee direct crossings
      -- from flop-to-flop when crossing this signal to the other radio clock or
      -- to the 1x domain.
      s2SysRefGoCond <= s2SysRefGoCondNxt;
    end if;
  end process;



end rtl;

