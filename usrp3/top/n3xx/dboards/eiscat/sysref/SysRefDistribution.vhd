-------------------------------------------------------------------------------
--
-- Copyright 2018 Ettus Research, a National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
--
-- Purpose:
--
-- This is a very rudimentary SYSREF generator. It accepts inputs from SW for
-- number and duration (high/low) of the SYSREF pulses, and then generates them
-- by SW request. It can output the pulses on the rising or falling edge of the clock
-- to assist in timing closure.
--
-- Latency through this module is 2.5-3 SampleClk2x cycles from sSendSysRef assertion
-- to sSysRef output, depending on the kIssueSysRefOnFE setting.
--
--                      __    __    __    __    __    __    __    __    __
-- Clk               __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
--                             _____
-- sSendSysRef       _________|     |________________________________________
--                                               _______________________
-- sSysRef           ___________________________|                       |____
--                                            _______________________
-- sSysRef (FE)      ________________________|                       |_______
--
--
-- Future Improvements:
-- 1) Change the generic kIssueSysRefOnFE to a SW-programmable
-- value and use with an ODDR for super-fast, SW-defined switching of edges!
-- 2) Consolidate the counters for high and low cycles down to 1 counter.
--
-- vreview_group JesdCore
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity SysRefDistribution is
  generic(
    -- Default for EISCAT.
    kIssueSysRefOnFE   : boolean := false
  );
  port(
    -- Async reset
    aReset             : in  std_logic;
    -- Sample Clocks
    SampleClk2x        : in  std_logic;

    -- SYSREF to Buffer Output
    sSysRef            : out std_logic;

    -- Input pulse from the host to trigger a SYSREF output.
    sSendSysRef        : in  std_logic;

    -- Control values for setting up the output pulses. Assign these values to one less
    -- than the desired value. These inputs should remain constant while this module is
    -- issuing pulses. Otherwise, pulse widths may not match throughout the sequence.
    -- It is expected that SW sets this module up once and then does not touch it again,
    -- so this should not be a problem.
    sNumPeriodsToSend  : in  unsigned(4 downto 0);
    sHighClocks        : in  unsigned(5 downto 0);
    sLowClocks         : in  unsigned(5 downto 0);

    -- The N310 Motherboard-Daughterboard combinations result in some LVDS pair swapping.
    -- This allows SW to un-swap the pairs on the fly and for each ADC.
    sInvertPolarity    : in  std_logic
  );
end SysRefDistribution;


architecture RTL of SysRefDistribution is

  --vhook_sigstart
  --vhook_sigend

  type State_t is (Idle, SysRefHigh, SysRefLow);
  signal sSysRefState : State_t;

  signal sHighClocksCnt    : unsigned(sHighClocks'range);
  signal sLowClocksCnt     : unsigned(sLowClocks'range);
  signal sSysRefPulsesCnt  : unsigned(sNumPeriodsToSend'range);
  signal sSysRefLcl  : std_logic;

  signal sSafeToStart, sSafeToStart_ms  : boolean := false;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of sSafeToStart_ms : signal is "true";
  attribute ASYNC_REG of sSafeToStart    : signal is "true";

begin

  -- SysRef Generation : ----------------------------------------------------------------
  -- This simple FSM generates a repeated SYSREF pulse that starts when SW strobes
  -- the sSendSysRef signal. It is completely SW-configurable (number of pulses,
  -- duration of high and low times). It is recommended that SW configure the generator
  -- before starting the sequence.
  --
  -- !!! SAFE STARTUP !!! : -------------------------------------------------------------
  -- This FSM starts safely because none of the outputs can change until sSafeToStart
  -- is asserted several clock cycles after aReset de-assertion.
  -- ------------------------------------------------------------------------------------
  SysRefFsm : process(aReset, SampleClk2x)
  begin
    if aReset ='1' then
      sSafeToStart_ms <= false;
      sSafeToStart    <= false;

      sSysRefState     <= Idle;
      sSysRefLcl       <= '0';
      sSysRefPulsesCnt <= (others => '0');
      sHighClocksCnt   <= (others => '0');
      sLowClocksCnt    <= (others => '0');

    elsif rising_edge(SampleClk2x) then
      sSafeToStart_ms <= true;
      sSafeToStart    <= sSafeToStart_ms;

      case sSysRefState is
        when Idle =>
          -- Note that sSysRefLcl is reset to '0', but could be driven to '1' immediately
          -- after sSafeToStart asserts, depending on the value set by SW. This is safe,
          -- both in terms of FPGA metastability as well as output value to the ADC,
          -- since this logic should be set up and running before the ADC is taken out
          -- of reset.
          if sSafeToStart then
            sSysRefLcl <= (sInvertPolarity); -- '0' in the non-inversion case.
            sSysRefPulsesCnt <= (others => '0');
            if sSendSysRef = '1' then
              sSysRefState   <= SysRefHigh;
              -- Capture High clock count for the next state.
              sHighClocksCnt <= sHighClocks;
            end if;
          end if;

        when SysRefHigh =>
          sSysRefLcl <= not (sInvertPolarity); -- '1' in the non-inversion case.
          if sHighClocksCnt = 0 then
            sSysRefState   <= SysRefLow;
            -- Capture Low clock count for the next state.
            sLowClocksCnt  <= sLowClocks;
          else
            sHighClocksCnt <= sHighClocksCnt - 1;
          end if;

        when SysRefLow =>
          sSysRefLcl <= (sInvertPolarity); -- '0' in the non-inversion case.
          if sLowClocksCnt = 0 then
            -- When done with all pulses, return to Idle without asserting SYSREF again.
            if sSysRefPulsesCnt >= sNumPeriodsToSend then
              sSysRefState <= Idle;
            else
              sSysRefPulsesCnt <= sSysRefPulsesCnt + 1;
              sSysRefState     <= SysRefHigh;
              sHighClocksCnt   <= sHighClocks;
            end if;
          else
            sLowClocksCnt <= sLowClocksCnt - 1;
          end if;

      end case;

    end if;
  end process;

  -- Output Signal Generators. Note the outputs of these flops should be driven
  -- straight to an OBUF. Don't pass Go, don't add more latency to the system.
  --
  -- Also note that these flops reset to '0', which matches the reset condition of
  -- sSysRefLcl. A while after aReset de-assertion, sSysRefLcl will transition to
  -- the correct value (based on SW inverting it or not).
  FallingEdgeGen : if kIssueSysRefOnFE generate
    FeProcess : process (aReset, SampleClk2x)
    begin
      if aReset ='1' then
        sSysRef <= '0';
      elsif falling_edge(SampleClk2x) then
        sSysRef <= sSysRefLcl;
      end if;
    end process;
  end generate;

  RisingEdgeGen : if not kIssueSysRefOnFE generate
    ReProcess : process (aReset, SampleClk2x)
    begin
      if aReset ='1' then
        sSysRef <= '0';
      elsif rising_edge(SampleClk2x) then
        sSysRef <= sSysRefLcl;
      end if;
    end process;
  end generate;



end RTL;



--------------------------------------------------------------------------------
-- Testbench for SysRefDistribution
--------------------------------------------------------------------------------

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_SysRefDistribution is end tb_SysRefDistribution;

architecture test of tb_SysRefDistribution is

  --vhook_sigstart
  signal aReset: std_logic;
  signal SampleClk2x: std_logic := '0';
  signal sInvertPolarity: std_logic;
  signal sSendSysRef: std_logic;
  signal sSysRef: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kPer : time := 10 ns;

  procedure ClkWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(SampleClk2x);
    end loop;
  end procedure ClkWait;

begin

  SampleClk2x <= not SampleClk2x after kPer/2 when not StopSim else '0';

  --vhook_e SysRefDistribution dutx
  --vhook_a kIssueSysRefOnFE true
  --vhook_a sNumPeriodsToSend to_unsigned(3, 5)
  --vhook_a sHighClocks to_unsigned(15, 6)
  --vhook_a sLowClocks  to_unsigned(15, 6)
  dutx: entity work.SysRefDistribution (RTL)
    generic map (kIssueSysRefOnFE => true)  --boolean:=false
    port map (
      aReset            => aReset,              --in  std_logic
      SampleClk2x       => SampleClk2x,         --in  std_logic
      sSysRef           => sSysRef,             --out std_logic
      sSendSysRef       => sSendSysRef,         --in  std_logic
      sNumPeriodsToSend => to_unsigned(3, 5),   --in  unsigned(4:0)
      sHighClocks       => to_unsigned(15, 6),  --in  unsigned(5:0)
      sLowClocks        => to_unsigned(15, 6),  --in  unsigned(5:0)
      sInvertPolarity   => sInvertPolarity);    --in  std_logic

  main: process


  begin
    sInvertPolarity <= '0';
    aReset <= '1', '0' after 10 ns;
    sSendSysRef <= '0';
    ClkWait(50);

    sSendSysRef <= '1';
    ClkWait(1);
    sSendSysRef <= '0';
    ClkWait(2);

    for i in 0 to 3 loop
      assert sSysRef = '1' report "SYSREF didn't assert after 2 clocks" severity error;
      ClkWait(16);
      assert sSysRef = '0' report "SYSREF didn't de-assert after 16 clocks" severity error;
      ClkWait(16);
    end loop;

    ClkWait(5);

    sSendSysRef <= '1';
    ClkWait(1);
    sSendSysRef <= '0';
    ClkWait(2);

    for i in 0 to 3 loop
      assert sSysRef = '1' report "SYSREF didn't assert after 2 clocks" severity error;
      ClkWait(16);
      assert sSysRef = '0' report "SYSREF didn't de-assert after 16 clocks" severity error;
      ClkWait(16);
    end loop;

    ClkWait(1000);
    StopSim <= true;
    wait;
  end process;

end test;
--synopsys translate_on
