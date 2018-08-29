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

library UNISIM;
  use UNISIM.vcomponents.all;


entity SysRefCore is
  port(
    -- Async reset
    aReset             : in  std_logic;
    -- Sample Clocks
    SampleClk1xA       : in  std_logic;
    SampleClk2xA       : in  std_logic;
    SampleClk2xB       : in  std_logic;

    -- SYSREF outputs
    sSysRefToFpgaCore  : out std_logic;

    s2SysRefDbaAdcA_p,
    s2SysRefDbaAdcA_n  : out std_logic;
    s2SysRefDbaAdcB_p,
    s2SysRefDbaAdcB_n  : out std_logic;

    s2SysRefDbbAdcA_p,
    s2SysRefDbbAdcA_n  : out std_logic;
    s2SysRefDbbAdcB_p,
    s2SysRefDbbAdcB_n  : out std_logic;

    sSysRefToFpgaDelay : in  std_logic_vector(31 downto 0);

    -- Input pulse from the host (timed) in the SampleClk2xA domain. This must be a
    -- single cycle pulse!
    s2SysRefGo         : in  std_logic
  );
end SysRefCore;


architecture RTL of SysRefCore is

  --vhook_sigstart
  signal s2aSysRefGo: std_logic;
  signal s2bSysRefGo: std_logic;
  signal s2SysRefGoCond: std_logic;
  signal s2SysRefToDbA_AdcA: std_logic;
  signal s2SysRefToDbA_AdcB: std_logic;
  signal s2SysRefToDbB_AdcA: std_logic;
  signal s2SysRefToDbB_AdcB: std_logic;
  --vhook_sigend

  constant kNumPeriodsToSend : unsigned(4 downto 0) := to_unsigned(3, 5);
  constant kHighClocks       : unsigned(5 downto 0) := to_unsigned(31, 6);
  constant kLowClocks        : unsigned(5 downto 0) := to_unsigned(31, 6);
  constant kIssueSysRefOnFE  : boolean := true;

  signal sSysRefToFpgaCoreDly : std_logic_vector(31 downto 0) := (others => '0');

begin



  -- First, condition the GO signal to ensure it crosses clock domains correctly.

  --vhook_e ConditionSysRefRequest
  --vhook_a SampleClk1x SampleClk1xA
  --vhook_a SampleClk2x SampleClk2xA
  --vhook_a s2SlowClkPhase open
  ConditionSysRefRequestx: entity work.ConditionSysRefRequest (rtl)
    port map (
      aReset         => aReset,          --in  std_logic
      SampleClk1x    => SampleClk1xA,    --in  std_logic
      SampleClk2x    => SampleClk2xA,    --in  std_logic
      s2SysRefGo     => s2SysRefGo,      --in  std_logic
      s2SysRefGoCond => s2SysRefGoCond,  --out std_logic
      s2SlowClkPhase => open);           --out std_logic



  -- To maintain equal pipeline delays, flop the Go signal once more in the A domain,
  -- and transfer it synchronously (system timing met here) into the B domain.
  InternalSysRefDelayFastClkProcA : process(aReset, SampleClk2xA)
  begin
    if aReset ='1' then
      s2aSysRefGo <= '0';
    elsif rising_edge(SampleClk2xA) then
      s2aSysRefGo <= s2SysRefGoCond;
    end if;
  end process;

  InternalSysRefDelayFastClkProcB : process(aReset, SampleClk2xB)
  begin
    if aReset ='1' then
      s2bSysRefGo <= '0';
    elsif rising_edge(SampleClk2xB) then
      s2bSysRefGo <= s2SysRefGoCond;
    end if;
  end process;

  -- From the A 2x domain, we can safely pass the Go signal into the A 1x domain and
  -- bring it into all JESD cores.
  InternalSysRefDelaySlowClkProc : process(aReset, SampleClk1xA)
  begin
    if aReset ='1' then
      sSysRefToFpgaCoreDly <= (others => '0');
      sSysRefToFpgaCore    <= '0';
    elsif rising_edge(SampleClk1xA) then
      sSysRefToFpgaCoreDly <= sSysRefToFpgaCoreDly(sSysRefToFpgaCoreDly'high - 1 downto 0) & s2aSysRefGo;
      sSysRefToFpgaCore    <= sSysRefToFpgaCoreDly(to_integer(unsigned(sSysRefToFpgaDelay)));
    end if;
  end process;


  -- For each of the ADCs on each of the DBs, create a SYSREF engine. This is a bit
  -- overkill, but...
  --  - Each DB needs a separate clock.
  --  - Each ADC may or may not have SYSREF signal polarity swapped by the board, which
  --    we have to unswap here.

  --vhook_e SysRefDistribution SysRefDbA_AdcA
  --vhook_a SampleClk2x       SampleClk2xA
  --vhook_a sSendSysRef       s2aSysRefGo
  --vhook_a sSysRef           s2SysRefToDbA_AdcA
  --vhook_a sNumPeriodsToSend kNumPeriodsToSend
  --vhook_a sHighClocks       kHighClocks
  --vhook_a sLowClocks        kLowClocks
  --vhook_a sInvertPolarity   '0'
  SysRefDbA_AdcA: entity work.SysRefDistribution (RTL)
    generic map (kIssueSysRefOnFE => kIssueSysRefOnFE)  --boolean:=false
    port map (
      aReset            => aReset,              --in  std_logic
      SampleClk2x       => SampleClk2xA,        --in  std_logic
      sSysRef           => s2SysRefToDbA_AdcA,  --out std_logic
      sSendSysRef       => s2aSysRefGo,         --in  std_logic
      sNumPeriodsToSend => kNumPeriodsToSend,   --in  unsigned(4:0)
      sHighClocks       => kHighClocks,         --in  unsigned(5:0)
      sLowClocks        => kLowClocks,          --in  unsigned(5:0)
      sInvertPolarity   => '0');                --in  std_logic

  --vhook_e SysRefDistribution SysRefDbA_AdcB
  --vhook_a SampleClk2x       SampleClk2xA
  --vhook_a sSendSysRef       s2aSysRefGo
  --vhook_a sSysRef           s2SysRefToDbA_AdcB
  --vhook_a sNumPeriodsToSend kNumPeriodsToSend
  --vhook_a sHighClocks       kHighClocks
  --vhook_a sLowClocks        kLowClocks
  --vhook_a sInvertPolarity   '1'
  SysRefDbA_AdcB: entity work.SysRefDistribution (RTL)
    generic map (kIssueSysRefOnFE => kIssueSysRefOnFE)  --boolean:=false
    port map (
      aReset            => aReset,              --in  std_logic
      SampleClk2x       => SampleClk2xA,        --in  std_logic
      sSysRef           => s2SysRefToDbA_AdcB,  --out std_logic
      sSendSysRef       => s2aSysRefGo,         --in  std_logic
      sNumPeriodsToSend => kNumPeriodsToSend,   --in  unsigned(4:0)
      sHighClocks       => kHighClocks,         --in  unsigned(5:0)
      sLowClocks        => kLowClocks,          --in  unsigned(5:0)
      sInvertPolarity   => '1');                --in  std_logic

  --vhook_e SysRefDistribution SysRefDbB_AdcA
  --vhook_a SampleClk2x       SampleClk2xB
  --vhook_a sSendSysRef       s2bSysRefGo
  --vhook_a sSysRef           s2SysRefToDbB_AdcA
  --vhook_a sNumPeriodsToSend kNumPeriodsToSend
  --vhook_a sHighClocks       kHighClocks
  --vhook_a sLowClocks        kLowClocks
  --vhook_a sInvertPolarity   '0'
  SysRefDbB_AdcA: entity work.SysRefDistribution (RTL)
    generic map (kIssueSysRefOnFE => kIssueSysRefOnFE)  --boolean:=false
    port map (
      aReset            => aReset,              --in  std_logic
      SampleClk2x       => SampleClk2xB,        --in  std_logic
      sSysRef           => s2SysRefToDbB_AdcA,  --out std_logic
      sSendSysRef       => s2bSysRefGo,         --in  std_logic
      sNumPeriodsToSend => kNumPeriodsToSend,   --in  unsigned(4:0)
      sHighClocks       => kHighClocks,         --in  unsigned(5:0)
      sLowClocks        => kLowClocks,          --in  unsigned(5:0)
      sInvertPolarity   => '0');                --in  std_logic

  --vhook_e SysRefDistribution SysRefDbB_AdcB
  --vhook_a SampleClk2x       SampleClk2xB
  --vhook_a sSendSysRef       s2bSysRefGo
  --vhook_a sSysRef           s2SysRefToDbB_AdcB
  --vhook_a sNumPeriodsToSend kNumPeriodsToSend
  --vhook_a sHighClocks       kHighClocks
  --vhook_a sLowClocks        kLowClocks
  --vhook_a sInvertPolarity   '1'
  SysRefDbB_AdcB: entity work.SysRefDistribution (RTL)
    generic map (kIssueSysRefOnFE => kIssueSysRefOnFE)  --boolean:=false
    port map (
      aReset            => aReset,              --in  std_logic
      SampleClk2x       => SampleClk2xB,        --in  std_logic
      sSysRef           => s2SysRefToDbB_AdcB,  --out std_logic
      sSendSysRef       => s2bSysRefGo,         --in  std_logic
      sNumPeriodsToSend => kNumPeriodsToSend,   --in  unsigned(4:0)
      sHighClocks       => kHighClocks,         --in  unsigned(5:0)
      sLowClocks        => kLowClocks,          --in  unsigned(5:0)
      sInvertPolarity   => '1');                --in  std_logic


  SysRefOBuf_DbA_AdcA: OBUFDS
    port map (
      I  => s2SysRefToDbA_AdcA,
      O  => s2SysRefDbaAdcA_p,
      OB => s2SysRefDbaAdcA_n
    );

  SysRefOBuf_DbA_AdcB: OBUFDS
    port map (
      I  => s2SysRefToDbA_AdcB,
      O  => s2SysRefDbaAdcB_p,
      OB => s2SysRefDbaAdcB_n
    );

  SysRefOBuf_DbB_AdcA: OBUFDS
    port map (
      I  => s2SysRefToDbB_AdcA,
      O  => s2SysRefDbbAdcA_p,
      OB => s2SysRefDbbAdcA_n
    );

  SysRefOBuf_DbB_AdcB: OBUFDS
    port map (
      I  => s2SysRefToDbB_AdcB,
      O  => s2SysRefDbbAdcB_p,
      OB => s2SysRefDbbAdcB_n
    );

end RTL;




--------------------------------------------------------------------------------
-- Testbench for SysRefCore
--------------------------------------------------------------------------------

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_SysRefCore is end tb_SysRefCore;

architecture test of tb_SysRefCore is

  --vhook_sigstart
  signal aReset: std_logic;
  signal s2SysRefDbaAdcA_n: std_logic;
  signal s2SysRefDbaAdcA_p: std_logic;
  signal s2SysRefDbaAdcB_n: std_logic;
  signal s2SysRefDbaAdcB_p: std_logic;
  signal s2SysRefDbbAdcA_n: std_logic;
  signal s2SysRefDbbAdcA_p: std_logic;
  signal s2SysRefDbbAdcB_n: std_logic;
  signal s2SysRefDbbAdcB_p: std_logic;
  signal s2SysRefGo: std_logic;
  signal s2SysRefGoDly: std_logic;
  signal SampleClk1xA: std_logic := '0';
  signal sSysRefToFpgaCore0: std_logic;
  signal sSysRefToFpgaCore1: std_logic;
  signal sSysRefToFpgaDelay: std_logic_vector(31 downto 0);
  --vhook_sigend

  signal SampleClk2xA: std_logic := '1';
  signal SampleClk2xB: std_logic := '0';

  signal StopSim : boolean;
  constant kPer : time := 10 ns;

  procedure ClkWait(signal Clk : std_logic; X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(Clk);
    end loop;
  end procedure ClkWait;

begin

  SampleClk1xA <= not SampleClk1xA after kPer/2 when not StopSim else '0';
  SampleClk2xA <= not SampleClk2xA after kPer/4 when not StopSim else '0';
  SampleClk2xB <= not SampleClk2xB after kPer/4 when not StopSim else '0';

  --vhook_e SysRefCore SysRefCoreInPhase
  --vhook_a sSysRefToFpgaCore sSysRefToFpgaCore0
  SysRefCoreInPhase: entity work.SysRefCore (RTL)
    port map (
      aReset             => aReset,              --in  std_logic
      SampleClk1xA       => SampleClk1xA,        --in  std_logic
      SampleClk2xA       => SampleClk2xA,        --in  std_logic
      SampleClk2xB       => SampleClk2xB,        --in  std_logic
      sSysRefToFpgaCore  => sSysRefToFpgaCore0,  --out std_logic
      s2SysRefDbaAdcA_p  => s2SysRefDbaAdcA_p,   --out std_logic
      s2SysRefDbaAdcA_n  => s2SysRefDbaAdcA_n,   --out std_logic
      s2SysRefDbaAdcB_p  => s2SysRefDbaAdcB_p,   --out std_logic
      s2SysRefDbaAdcB_n  => s2SysRefDbaAdcB_n,   --out std_logic
      s2SysRefDbbAdcA_p  => s2SysRefDbbAdcA_p,   --out std_logic
      s2SysRefDbbAdcA_n  => s2SysRefDbbAdcA_n,   --out std_logic
      s2SysRefDbbAdcB_p  => s2SysRefDbbAdcB_p,   --out std_logic
      s2SysRefDbbAdcB_n  => s2SysRefDbbAdcB_n,   --out std_logic
      sSysRefToFpgaDelay => sSysRefToFpgaDelay,  --in  std_logic_vector(31:0)
      s2SysRefGo         => s2SysRefGo);         --in  std_logic


  --vhook_e SysRefCore SysRefCoreOutPhase
  --vhook_a s2SysRefGo s2SysRefGoDly
  --vhook_a sSysRefToFpgaCore sSysRefToFpgaCore1
  SysRefCoreOutPhase: entity work.SysRefCore (RTL)
    port map (
      aReset             => aReset,              --in  std_logic
      SampleClk1xA       => SampleClk1xA,        --in  std_logic
      SampleClk2xA       => SampleClk2xA,        --in  std_logic
      SampleClk2xB       => SampleClk2xB,        --in  std_logic
      sSysRefToFpgaCore  => sSysRefToFpgaCore1,  --out std_logic
      s2SysRefDbaAdcA_p  => s2SysRefDbaAdcA_p,   --out std_logic
      s2SysRefDbaAdcA_n  => s2SysRefDbaAdcA_n,   --out std_logic
      s2SysRefDbaAdcB_p  => s2SysRefDbaAdcB_p,   --out std_logic
      s2SysRefDbaAdcB_n  => s2SysRefDbaAdcB_n,   --out std_logic
      s2SysRefDbbAdcA_p  => s2SysRefDbbAdcA_p,   --out std_logic
      s2SysRefDbbAdcA_n  => s2SysRefDbbAdcA_n,   --out std_logic
      s2SysRefDbbAdcB_p  => s2SysRefDbbAdcB_p,   --out std_logic
      s2SysRefDbbAdcB_n  => s2SysRefDbbAdcB_n,   --out std_logic
      sSysRefToFpgaDelay => sSysRefToFpgaDelay,  --in  std_logic_vector(31:0)
      s2SysRefGo         => s2SysRefGoDly);      --in  std_logic


  process(SampleClk2xA)
  begin
    if rising_edge(SampleClk2xA) then
      s2SysRefGoDly <= s2SysRefGo;
    end if;
  end process;



  main: process

  begin
    s2SysRefGo <= '0';
    aReset <= '1', '0' after 10 ns;
    ClkWait(SampleClk1xA, 50);


    ClkWait(SampleClk2xA, 5);
    s2SysRefGo <= '1';
    ClkWait(SampleClk2xA, 1);
    s2SysRefGo <= '0';

    wait until (sSysRefToFpgaCore0)='1' for kPer*10;
    assert (sSysRefToFpgaCore0)='1'
      report "FPGA SysRef 0 didn't toggle"
      severity error;
    wait until (sSysRefToFpgaCore1)='1' for kPer*10;
    assert (sSysRefToFpgaCore1)='1'
      report "FPGA SysRef 1 didn't toggle"
      severity error;

    ClkWait(SampleClk2xA, 1000);


    StopSim <= true;
    wait;
  end process;

end test;
--synopsys translate_on
