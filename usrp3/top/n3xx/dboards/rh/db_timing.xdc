#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: LGPL-3.0
#
# Timing analysis is performed in "usrp3/top/n3xx/dboards/rh/doc/rh_timing.xlsx".
# See this spreadsheet for more details and explanations.

#*******************************************************************************
## Daughterboard Clocks
#
# 122.88, 200, 245.76 and 250 MHz Sample Rates are allowable with 2:1/1:2 DSP and 
# 2 samples/cycle arriving at the FPGA:
#
#            <-- 2:1/1:2 -->
#     | Supported   | Sample rate  | FPGA Clk  |
#     |sample rates | at JESD core | Frequency |
#     |   (MSPS)    |    (MSPS)    |   (MHz)   |
#     |-------------|--------------|-----------|
#     |   122.88    |    491.52    |  245.76   | (uses DUC/DDC)
#     |   200.00    |    400.00    |  200.00   |
#     |   245.76    |    491.52    |  245.76   |
#     |   250.00    |    500.00    |  250.00   |
#
# Therefore, supported sample clocks are: 122.88, 200, 245.76 and 250 MHz.
# Constrain the paths to the max rate to support all rates in a single FPGA image.
set SAMPLE_CLK_PERIOD 4.00
create_clock -name fpga_clk_a  -period $SAMPLE_CLK_PERIOD  [get_ports DBA_FPGA_CLK_P]
create_clock -name fpga_clk_b  -period $SAMPLE_CLK_PERIOD  [get_ports DBB_FPGA_CLK_P]
create_clock -name mgt_clk_dba -period $SAMPLE_CLK_PERIOD  [get_ports DBA_MGTCLK_P]
create_clock -name mgt_clk_dbb -period $SAMPLE_CLK_PERIOD  [get_ports DBB_MGTCLK_P]

# The Radio Clocks coming from the DBs are synchronized together (at the converters) to
# a typical value of less than 100ps. To give ourselves and Vivado some margin, we claim
# here that the DB-B Radio Clock can arrive 500ps before or after the DB-A clock at
# the FPGA (note that the trace lengths of the Radio Clocks coming from the DBs to the
# FPGA are about 0.5" different, thereby incurring ~80ps of additional skew at the FPGA).
# There is one spot in the FPGA where we cross domains between the DB-A and
# DB-B clock, so we must ensure that Vivado can analyze that path safely.
set FPGA_CLK_EARLY -0.5
set FPGA_CLK_LATE   0.5
set_clock_latency  -source -early $FPGA_CLK_EARLY [get_clocks fpga_clk_b]
set_clock_latency  -source -late  $FPGA_CLK_LATE  [get_clocks fpga_clk_b]

# Virtual clocks for constraining I/O (used below)
create_clock -name fpga_clk_a_v -period $SAMPLE_CLK_PERIOD
create_clock -name fpga_clk_b_v -period $SAMPLE_CLK_PERIOD

# The set_clock_latency constraints set on fpga_clk_b are problematic when used with
# I/O timing, since the analyzer gives us a double-hit on the latency. One workaround
# (used here) is to simply swap the early and late times for the virtual clock so that
# it cancels out the source latency during analysis. D. Jepson tested this by setting
# the early and late numbers to zero and then their actual value, running timing reports
# on each. The slack report matches for both cases, showing that the reversed early/late
# numbers on the virtual clock zero out the latency effects on the actual clock.
#
# Note this is not a problem for the fpga_clk_a, since no latency is added. So only apply
# it to fpga_clk_b_v.
set_clock_latency  -source -early $FPGA_CLK_LATE  [get_clocks fpga_clk_b_v]
set_clock_latency  -source -late  $FPGA_CLK_EARLY [get_clocks fpga_clk_b_v]



#*******************************************************************************
## Aliases for auto-generated clocks

create_generated_clock -name radio_clk_fb   [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKFBOUT}]
create_generated_clock -name radio_clk      [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKOUT0}]
create_generated_clock -name radio_clk_2x   [get_pins {dba_core/RadioClockingx/RadioClkMmcm/CLKOUT1}]

create_generated_clock -name radio_clk_b_fb [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKFBOUT}]
create_generated_clock -name radio_clk_b    [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKOUT0}]
create_generated_clock -name radio_clk_b_2x [get_pins {dbb_core/RadioClockingx/RadioClkMmcm/CLKOUT1}]



#*******************************************************************************
## Generated clocks for output busses to the daughterboard
#
# These clock definitions need to come above the set_clock_groups commands below to work!

# Define clocks on the PL SPI clock output pins for both DBs. Actual divider values are
# set by SW at run-time. Current divider value is 125 based on what radio clock
# rate is set.
# For the CPLD SPI endpoint alone, we need it to run at ~50 MHz (writes only), this means
# that at times, the PL SPI will have its divider set to 5 (radio_clock = 250 MHz) or 4
# (radio_clock = 200 MHz).
# Using an overconstraining approach, we set the divider to 4.
# Also, having a divider value set to an even number makes timing analysis much easier
# for constraining skew, due to how the tools interpret the edges.
set PL_SPI_DIVIDE_VAL 4
set PL_SPI_CLK_A [get_ports DBA_CPLD_PL_SPI_SCLK]
create_generated_clock -name pl_spi_clk_a \
  -source [get_pins [all_fanin -flat -only_cells -startpoints_only $PL_SPI_CLK_A]/C] \
  -divide_by $PL_SPI_DIVIDE_VAL $PL_SPI_CLK_A
set PL_SPI_CLK_B [get_ports DBB_CPLD_PL_SPI_SCLK]
create_generated_clock -name pl_spi_clk_b \
  -source [get_pins [all_fanin -flat -only_cells -startpoints_only $PL_SPI_CLK_B]/C] \
  -divide_by $PL_SPI_DIVIDE_VAL $PL_SPI_CLK_B



#*******************************************************************************
## Asynchronous clock groups

# MGT reference clocks are also async to everything.
set_clock_groups -asynchronous -group [get_clocks mgt_clk_dba -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks mgt_clk_dbb -include_generated_clocks]

# fpga_clk_a and fpga_clk_b are related to one another after synchronization.
# However, we do need to declare that these clocks (both a and b) and their children
# are async to the remainder of the design. Use the wildcard at the end to grab the
# virtual clock as well as the real ones.
set_clock_groups -asynchronous -group [get_clocks {fpga_clk_a* fpga_clk_b*} -include_generated_clocks]



#*******************************************************************************
## PS SPI: since these lines all come from the PS and I don't have access to the
# driving clock (or anything for that matter), I'm left with constraining the maximum
# and minimum delay on these lines, per a Xilinx AR:
# https://www.xilinx.com/support/answers/62122.html
set CPLD_SPI_OUTS [get_ports {DB*_CPLD_PS_SPI_SCLK \
                              DB*_CPLD_PS_SPI_MOSI \
                              DB*_CPLD_PS_SPI_CS_B \
                              DB*_CLKDIS_SPI_CS_B \
                              DB*_PHDAC_SPI_CS_B \
                              DB*_ADC_SPI_CS_B \
                              DB*_DAC_SPI_CS_B}]

# The actual min and max path delays before applying constraints were (from report_timing):
#    3.332 ns (Min at Fast Process Corner)
#   10.596 ns (Max at Slow Process Corner)
# Therefore, we round those number to their immediate succesor respectively.
# After implementation, the tools were unable to meet timing when leaving a 11 ns max
# delay value, so it was incremented.
set MIN_OUT_DELAY  3.0
set MAX_OUT_DELAY 12.0

set_max_delay $MAX_OUT_DELAY -to $CPLD_SPI_OUTS
set_min_delay $MIN_OUT_DELAY -to $CPLD_SPI_OUTS

# report_timing -to $CPLD_SPI_OUTS -max_paths 20 -delay_type min_max -name CpldSpiOutTiming

# The actual min and max path delays before applying constraints were (from report_timing):
#   2.733 ns (Min at Fast Process Corner)
#   6.071 ns (Max at Slow Process Corner)
# Therefore, we round those number to their immediate succesor respectively.
set MIN_IN_DELAY   3.0
set MAX_IN_DELAY   7.0

set PS_SPI_INPUTS_0 [get_pins -hierarchical -filter {NAME =~ "*/PS7_i/EMIOSPI0MI"}]
set PS_SPI_INPUTS_1 [get_pins -hierarchical -filter {NAME =~ "*/PS7_i/EMIOSPI1MI"}]

set_max_delay $MAX_IN_DELAY -to $PS_SPI_INPUTS_0
set_min_delay $MIN_IN_DELAY -to $PS_SPI_INPUTS_0
set_max_delay $MAX_IN_DELAY -to $PS_SPI_INPUTS_1
set_min_delay $MIN_IN_DELAY -to $PS_SPI_INPUTS_1

# report_timing -to $PS_SPI_INPUTS_0 -max_paths 30 -delay_type min_max -nworst 30 -name Spi0InTiming
# report_timing -to $PS_SPI_INPUTS_1 -max_paths 30 -delay_type min_max -nworst 30 -name Spi1InTiming



#*******************************************************************************
## PL SPI to the CPLD
#
# All of these lines are driven or received from flops in simple_spi_core. The CPLD
# calculations assume the FPGA has less than 6 ns of skew between the SCK and
# SDI/CS_n. Pretty easy constraint to write! See above for the clock definition.
# Do this for DBA and DBB independently.
set MAX_SKEW 6.0
set SETUP_SKEW [expr {$MAX_SKEW / 2}]
set HOLD_SKEW  [expr {$MAX_SKEW / 2}]
# Do not set the output delay constraint on the clock line!
set PORT_LIST_A [get_ports {DBA_CPLD_PL_SPI_CS_B \
                            DBA_CPLD_PL_SPI_MOSI \
                            DBA_TXLO_SPI_CS_B    \
                            DBA_RXLO_SPI_CS_B    \
                            DBA_LODIS_SPI_CS_B  }]
set PORT_LIST_B [get_ports {DBB_CPLD_PL_SPI_CS_B \
                            DBB_CPLD_PL_SPI_MOSI \
                            DBB_TXLO_SPI_CS_B    \
                            DBB_RXLO_SPI_CS_B    \
                            DBB_LODIS_SPI_CS_B  }]
# Then add the output delay on each of the ports.
set_output_delay                        -clock [get_clocks pl_spi_clk_a] -max -$SETUP_SKEW $PORT_LIST_A
set_output_delay -add_delay -clock_fall -clock [get_clocks pl_spi_clk_a] -max -$SETUP_SKEW $PORT_LIST_A
set_output_delay                        -clock [get_clocks pl_spi_clk_a] -min  $HOLD_SKEW  $PORT_LIST_A
set_output_delay -add_delay -clock_fall -clock [get_clocks pl_spi_clk_a] -min  $HOLD_SKEW  $PORT_LIST_A
set_output_delay                        -clock [get_clocks pl_spi_clk_b] -max -$SETUP_SKEW $PORT_LIST_B
set_output_delay -add_delay -clock_fall -clock [get_clocks pl_spi_clk_b] -max -$SETUP_SKEW $PORT_LIST_B
set_output_delay                        -clock [get_clocks pl_spi_clk_b] -min  $HOLD_SKEW  $PORT_LIST_B
set_output_delay -add_delay -clock_fall -clock [get_clocks pl_spi_clk_b] -min  $HOLD_SKEW  $PORT_LIST_B
# Finally, make both the setup and hold checks use the same launching and latching edges.
set_multicycle_path -setup -from [get_clocks radio_clk] -to [get_clocks pl_spi_clk_a] -start 0
set_multicycle_path -hold  -from [get_clocks radio_clk] -to [get_clocks pl_spi_clk_a] -1
set_multicycle_path -setup -from [get_clocks radio_clk] -to [get_clocks pl_spi_clk_b] -start 0
set_multicycle_path -hold  -from [get_clocks radio_clk] -to [get_clocks pl_spi_clk_b] -1

# For SDO input timing (MISO), we need to look at the CPLD's constraints on turnaround
# time plus any board propagation delay.
set MISO_INPUT_A [get_ports DBA_CPLD_PL_SPI_MISO]
set MISO_INPUT_B [get_ports DBB_CPLD_PL_SPI_MISO]
set_input_delay -clock [get_clocks pl_spi_clk_a] -clock_fall -max  12.192  $MISO_INPUT_A
set_input_delay -clock [get_clocks pl_spi_clk_a] -clock_fall -min   6.496  $MISO_INPUT_A
set_input_delay -clock [get_clocks pl_spi_clk_b] -clock_fall -max  12.192  $MISO_INPUT_B
set_input_delay -clock [get_clocks pl_spi_clk_b] -clock_fall -min   6.496  $MISO_INPUT_B
# Since the input delay span is clearly more than a period of the radio_clk, we need to
# add a multicycle path here as well to define the clock divider ratio. The MISO data
# is driven on the falling edge of the SPI clock and captured on the rising edge, so we
# only have one half of a SPI clock cycle for our setup. Hold is left alone and is OK
# as-is due to the delays in the CPLD and board.
# IMPORTANT! The pl_spi_clk_* full rate is only used for writes, any readback from the
# endpoint must not be performed at rate higher than pl_spi_clk_* / 4.
# For example, if we overconstrain pl_spi_clk_* @ 62.5 MHz, the fastest rate we will
# constrain the FPGA is to 62.5/4 = 15.625 MHz.
# This is the reason why we multiply the PL_SPI_DIVIDE_VAL by 4 below:
set SETUP_CYCLES [expr {$PL_SPI_DIVIDE_VAL * 4 / 2}]
set HOLD_CYCLES 0
set_multicycle_path -setup -from [get_clocks pl_spi_clk_a] -through $MISO_INPUT_A \
  $SETUP_CYCLES
set_multicycle_path -hold  -from [get_clocks pl_spi_clk_a] -through $MISO_INPUT_A -end \
  [expr {$SETUP_CYCLES + $HOLD_CYCLES - 1}]
set_multicycle_path -setup -from [get_clocks pl_spi_clk_b] -through $MISO_INPUT_B \
  $SETUP_CYCLES
set_multicycle_path -hold  -from [get_clocks pl_spi_clk_b] -through $MISO_INPUT_B -end \
  [expr {$SETUP_CYCLES + $HOLD_CYCLES - 1}]


#*******************************************************************************
## SYSREF/SYNC JESD Timing
#
# SYNC is async, SYSREF is tightly timed.

# The SYNC output (to ADC) for both DBs is governed by the JESD cores, which are solely
# driven by DB-A clock... but it is an asynchronous signal so we use the async_out_clk.
set_output_delay -clock [get_clocks async_out_clk] 0.000 [get_ports DB*_ADC_SYNCB_P]
set_max_delay -to [get_ports DB*_ADC_SYNCB_P] 50.000
set_min_delay -to [get_ports DB*_ADC_SYNCB_P] 0.000

# The SYNC input (from DAC) for both DBs is received by the DB-A clock inside the JESD
# cores... but again, it is asynchronous and therefore uses the async_in_clk.
set_input_delay -clock [get_clocks async_in_clk] 0.000 [get_ports DB*_DAC_SYNCB_P]
set_max_delay -from [get_ports DB*_DAC_SYNCB_P] 50.000
set_min_delay -from [get_ports DB*_DAC_SYNCB_P] 0.000

# SYSREF is driven by the LMK directly to the FPGA. Timing analysis was performed once
# for the worst-case numbers across both DBs to produce one set of numbers for both DBs.
# Since we easily meet setup and hold in Vivado, then this is an acceptable approach.
# SYSREF is captured by the local clock from each DB, so we have two sets of constraints.
set_input_delay -clock fpga_clk_a_v -min -0.479 [get_ports DBA_FPGA_SYSREF_*]
set_input_delay -clock fpga_clk_a_v -max  0.661 [get_ports DBA_FPGA_SYSREF_*]

set_input_delay -clock fpga_clk_b_v -min -0.479 [get_ports DBB_FPGA_SYSREF_*]
set_input_delay -clock fpga_clk_b_v -max  0.661 [get_ports DBB_FPGA_SYSREF_*]


#*******************************************************************************
## PPS Timing

# Due to the N3xx synchronization and clocking structure, the PPS output is driven from
# the Sample Clock domain instead of the input Reference Clock. Constrain the output as
# tightly as possible to accurately mimic the internal Sample Clock timing.
set SETUP_SKEW  2.0
set HOLD_SKEW  -0.5
set_output_delay -clock [get_clocks fpga_clk_a_v] -max -$SETUP_SKEW [get_ports REF_1PPS_OUT]
set_output_delay -clock [get_clocks fpga_clk_a_v] -min  $HOLD_SKEW  [get_ports REF_1PPS_OUT]
set_multicycle_path -setup -to [get_ports REF_1PPS_OUT] -start 0
set_multicycle_path -hold  -to [get_ports REF_1PPS_OUT] -1
