#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: LGPL-3.0
#
# Timing analysis is performed in "/n3xx/dboards/mg/doc/mg_timing.xlsx". See
# the spreadsheet for more details and explanations.

#*******************************************************************************
## Daughterboard Clocks

# 208 MHz DB A & B clocks
set SampleClockPeriod 4.807
create_clock -name DbaFpgaClk          -period $SampleClockPeriod  [get_ports DBA_FPGA_CLK_P]
create_clock -name DbbFpgaClk          -period $SampleClockPeriod  [get_ports DBB_FPGA_CLK_P]
create_clock -name USRPIO_A_MGTCLK     -period $SampleClockPeriod  [get_ports {USRPIO_A_MGTCLK_P}]
create_clock -name USRPIO_B_MGTCLK     -period $SampleClockPeriod  [get_ports {USRPIO_B_MGTCLK_P}]

# The Radio Clocks coming from the DBs are synchronized together (at the ADCs) to a
# typical value of less than 100ps. To give ourselves and Vivado some margin, we claim
# here that the DB-B Radio Clock can arrive 500ps before or after the DB-A clock at
# the FPGA (note that the trace lengths of the Radio Clocks coming from the DBs to the
# FPGA are about 0.5" different, thereby incurring ~80ps of additional skew at the FPGA).
# There is one spot in the FPGA where we cross domains between the DB-A and
# DB-B clock, so we must ensure that Vivado can analyze that path safely.
set FpgaClkBEarly -0.5
set FpgaClkBLate   0.5
set_clock_latency  -source -early $FpgaClkBEarly [get_clocks DbbFpgaClk]
set_clock_latency  -source -late  $FpgaClkBLate  [get_clocks DbbFpgaClk]

# Virtual clocks for constraining I/O (used below)
create_clock -name AsyncInClk  -period 50.00
create_clock -name AsyncOutClk -period 50.00
create_clock -name DbaFpgaClkV -period $SampleClockPeriod
create_clock -name DbbFpgaClkV -period $SampleClockPeriod

# The set_clock_latency constraints set on DbbFpgaClk are problematic when used with
# I/O timing, since the analyzer gives us a double-hit on the latency. One workaround
# (used here) is to simply swap the early and late times for the virtual clock so that
# it cancels out the source latency during analysis. I tested this by setting the
# early and late numbers to zero and then their actual value, running timing reports
# on each. The slack report matches for both cases, showing that the reversed early/late
# numbers on the virtual clock zero out the latency effects on the actual clock.
#
# Note this is not a problem for the DbaFpgaClk, since no latency is added. So only apply
# it to DbbFpgaClkV.
set_clock_latency  -source -early $FpgaClkBLate  [get_clocks DbbFpgaClkV]
set_clock_latency  -source -late  $FpgaClkBEarly [get_clocks DbbFpgaClkV]


#*******************************************************************************
## Aliases for auto-generated clocks

create_generated_clock -name radio_clk_fb   [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKFBOUT}]
create_generated_clock -name radio_clk      [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKOUT0}]
create_generated_clock -name radio_clk_2x   [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKOUT1}]

create_generated_clock -name radio_clk_b_fb [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKFBOUT}]
create_generated_clock -name radio_clk_b    [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKOUT0}]
create_generated_clock -name radio_clk_b_2x [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKOUT1}]

# radio_clk and radio_clk_b are related to one another after synchronization.
# However, we do need to declare that these clocks (both a and b) are async to the remainder
# of the design.
set_clock_groups -asynchronous -group [get_clocks {Db*FpgaClk*} -include_generated_clocks]

#*******************************************************************************
## DB Timing
#
# Vastly asynchronous except for the SYSREF and SYNC lines.
# And SPI, yeah that matters too.


## Async Inputs: covers both daughterboards' three async inputs.
set AsyncDbInputs [get_ports {DB*LMK_STATUS DB*TMON_ALERT_N DB*VMON_ALERT}]
set_input_delay -clock [get_clocks AsyncInClk] 0.000 $AsyncDbInputs


## Async Outputs: again, covers both daughterboards.
set AsyncDbOutputs [get_ports {DB*ADC_A_RESET DB*LMK_SPI_EN DB*ADC_B_RESET DB*DC_PWR_EN \
                               DB*CH*EN_N DB*DB_CTRL_EN_N DB*LNA_CTRL_EN DB*ADC_SPI_EN}]
set_output_delay -clock [get_clocks AsyncOutClk] 0.000 $AsyncDbOutputs


## SPI Outputs: since these lines all come from the PS and I don't have access to the
# driving clock (or anything for that matter), I'm left with constraining the maximum
# and minimum delay on these lines, per a Xilinx AR:
# https://www.xilinx.com/support/answers/62122.html
set LmkSpiOuts [get_ports {DB*LMK_SCK DB*LMK_CS_N DB*LMK_SDI}]
set AdcSpiOuts [get_ports {DB*ADC*SCLK DB*ADC*CS_N DB*ADC*SDI}]

set MinOutDelay   3.0
set MaxOutDelay  12.0

set_max_delay $MaxOutDelay -to $LmkSpiOuts
set_min_delay $MinOutDelay -to $LmkSpiOuts
set_max_delay $MaxOutDelay -to $AdcSpiOuts
set_min_delay $MinOutDelay -to $AdcSpiOuts

# report_timing -to $LmkSpiOuts -max 20 -delay_type min_max -name LmkSpiOutTiming
# report_timing -to $AdcSpiOuts -max 20 -delay_type min_max -name AdcSpiOutTiming


## SPI Inputs
# set LmkSpiIns [get_ports {Db*LmkReadback}]
# set AdcSpiIns [get_ports {Db*Adc*Sdout}]

set MinInDelay   3.0
set MaxInDelay  10.0

# For some reason the following constraints weren't being picked up by the tools, but if
# I constrain it using the endpoint at the PS, the tools are happy... so we're going with
# that approach.
# set_max_delay $MaxInDelay -from $LmkSpiIns
# set_min_delay $MinInDelay -from $LmkSpiIns
# set_max_delay $MaxInDelay -from $AdcSpiIns
# set_min_delay $MinInDelay -from $AdcSpiIns

set PsSpi0Inputs [get_pins -hierarchical -filter {NAME =~ "*/PS7_i/EMIOSPI0MI"}]
set PsSpi1Inputs [get_pins -hierarchical -filter {NAME =~ "*/PS7_i/EMIOSPI1MI"}]

set_max_delay $MaxInDelay -to $PsSpi0Inputs
set_min_delay $MinInDelay -to $PsSpi0Inputs
set_max_delay $MaxInDelay -to $PsSpi1Inputs
set_min_delay $MinInDelay -to $PsSpi1Inputs

# report_timing -to $PsSpi0Inputs -max 30 -delay_type min_max -nworst 30 -name Spi0InTiming
# report_timing -to $PsSpi1Inputs -max 30 -delay_type min_max -nworst 30 -name Spi1InTiming



#*******************************************************************************
## SYSREF/SYNC JESD Timing
#
# Drive both outputs with respect to their virtual clock.

# SYSREF is driven in each DB's individual clock domain.
set_output_delay -clock DbaFpgaClkV -min  0.000 [get_ports {DBA_ADC*SYSREF_*}] -clock_fall
set_output_delay -clock DbaFpgaClkV -max  2.808 [get_ports {DBA_ADC*SYSREF_*}] -clock_fall

set_output_delay -clock DbbFpgaClkV -min  0.000 [get_ports {DBB_ADC*SYSREF_*}] -clock_fall
set_output_delay -clock DbbFpgaClkV -max  2.808 [get_ports {DBB_ADC*SYSREF_*}] -clock_fall


# SYNC for both DBs is governed by the JESD core, which is solely driven by DB-A clock,
# so we can lump all these outputs into one constraint... which should be pretty loose
# because it's really an async output.
set_output_delay -clock DbaFpgaClkV -min  0.000 [get_ports {DB*ADC*SYNC_*}]
set_output_delay -clock DbaFpgaClkV -max  1.000 [get_ports {DB*ADC*SYNC_*}]

