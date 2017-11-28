#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: GPL-3.0
#


#*******************************************************************************
## Daughterboard Clocks

# 122.88, 125, and 153.6 MHz Sample Clocks are allowable. Constrain the paths to the max
# rate in order to support all rates in a single FPGA image.
set SAMPLE_CLK_PERIOD 6.510
create_clock -name fpga_clk_a  -period $SAMPLE_CLK_PERIOD  [get_ports DBA_FPGA_CLK_P]
create_clock -name fpga_clk_b  -period $SAMPLE_CLK_PERIOD  [get_ports DBB_FPGA_CLK_P]
create_clock -name mgt_clk_dba -period $SAMPLE_CLK_PERIOD  [get_ports USRPIO_A_MGTCLK_P]
create_clock -name mgt_clk_dbb -period $SAMPLE_CLK_PERIOD  [get_ports USRPIO_B_MGTCLK_P]

# The Radio Clocks coming from the DBs are synchronized together (at the ADCs) to a
# typical value of less than 100ps. To give ourselves and Vivado some margin, we claim
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
# it cancels out the source latency during analysis. I tested this by setting the
# early and late numbers to zero and then their actual value, running timing reports
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
## Asynchronous clock groups

# MGT reference clocks are also async to everything.
set_clock_groups -asynchronous -group [get_clocks mgt_clk_dba -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks mgt_clk_dbb -include_generated_clocks]

# fpga_clk_a and fpga_clk_b are related to one another after synchronization.
# However, we do need to declare that these clocks (both a and b) and their children
# are async to the remainder of the design.
set_clock_groups -asynchronous -group [get_clocks {fpga_clk_a fpga_clk_b} -include_generated_clocks]



#*******************************************************************************
## DB Timing
#
# SPI ports, DSA controls, ATR bits, Mykonos GPIO, Mykonos Interrupt

# One of the PL_SPI_ADDR lines is used instead for the LMK SYNC strobe. This line is
# driven asynchronously.
set_output_delay -clock [get_clocks async_out_clk] 0.000 [get_ports DB*_CPLD_PL_SPI_ADDR[2]]
set_max_delay -to [get_ports DB*_CPLD_PL_SPI_ADDR[2]] 50.000
set_min_delay -to [get_ports DB*_CPLD_PL_SPI_ADDR[2]] 0.000

# The ATR bits are driven from the DB-A radio clock. Although they are received async in
# the CPLD, they should be tightly constrained in the FPGA to avoid any race conditions.
# The best way to do this is a skew constraint across all the bits.
# First, define one of the outputs as a clock (even though it isn't a clock).
## THIS CONSTRAINT IS CURRENTLY UNUSED SINCE THE ATR BITS ARE DRIVEN CONSTANT '1' ##
# maxSkew will most likely have to be tweaked

# create_generated_clock -name atr_bus_clk \
  # -source [get_pins [all_fanin -flat -only_cells -startpoints_only [get_ports DBA_ATR_RX_1]]/C] \
  # -divide_by 2 [get_ports DBA_ATR_RX_1]
# set maxSkew 1.00
# set maxDelay [expr {$maxSkew / 2}]
# # Then add the output delay on each of the ports.
# set_output_delay                        -clock [get_clocks atr_bus_clk] -max -$maxDelay [get_ports DB*_ATR_*X_*]
# set_output_delay -add_delay -clock_fall -clock [get_clocks atr_bus_clk] -max -$maxDelay [get_ports DB*_ATR_*X_*]
# set_output_delay                        -clock [get_clocks atr_bus_clk] -min  $maxDelay [get_ports DB*_ATR_*X_*]
# set_output_delay -add_delay -clock_fall -clock [get_clocks atr_bus_clk] -min  $maxDelay [get_ports DB*_ATR_*X_*]
# # Finally, make both the setup and hold checks use the same launching and latching edges.
# set_multicycle_path -setup -to [get_clocks atr_bus_clk] -start 0
# set_multicycle_path -hold  -to [get_clocks atr_bus_clk] -1


# Mykonos GPIO is driven from the DB-A radio clock. It is received asynchronously inside
# the chip, but should be (fairly) tightly controlled coming from the FPGA.
## NEED CONSTRAINT HERE ##

# Mykonos Interrupt is received asynchronously, and driven directly to the PS.
set_input_delay -clock [get_clocks async_in_clk] 0.000 [get_ports DB*_MYK_INTRQ]
set_max_delay -from [get_ports DB*_MYK_INTRQ] 50.000
set_min_delay -from [get_ports DB*_MYK_INTRQ] 0.000



#*******************************************************************************
## SYSREF/SYNC JESD Timing
#
# SYNC is async, SYSREF is tightly timed.

# The SYNC output for both DBs is governed by the JESD cores, which are solely driven by
# DB-A clock... but it is an asynchronous signal so we use the async_out_clk.
set_output_delay -clock [get_clocks async_out_clk] 0.000 [get_ports DB*_MYK_SYNC_IN_n]
set_max_delay -to [get_ports DB*_MYK_SYNC_IN_n] 50.000
set_min_delay -to [get_ports DB*_MYK_SYNC_IN_n] 0.000

# The SYNC input for both DBs is received by the DB-A clock inside the JESD cores... but
# again, it is asynchronous and therefore uses the async_in_clk.
set_input_delay -clock [get_clocks async_in_clk] 0.000 [get_ports DB*_MYK_SYNC_OUT_n]
set_max_delay -from [get_ports DB*_MYK_SYNC_OUT_n] 50.000
set_min_delay -from [get_ports DB*_MYK_SYNC_OUT_n] 0.000

# SYSREF is driven by the LMK directly to the FPGA. Timing analysis was performed once
# for the worst-case numbers across both DBs to produce one set of numbers for both DBs.
# Since we easily meet setup and hold in Vivado, then this is an acceptable approach.
# SYSREF is captured by the local clock from each DB, so we have two sets of constraints.
set_input_delay -clock fpga_clk_a_v -min -0.906 [get_ports DBA_FPGA_SYSREF_*]
set_input_delay -clock fpga_clk_a_v -max  0.646 [get_ports DBA_FPGA_SYSREF_*]

set_input_delay -clock fpga_clk_b_v -min -0.906 [get_ports DBB_FPGA_SYSREF_*]
set_input_delay -clock fpga_clk_b_v -max  0.646 [get_ports DBB_FPGA_SYSREF_*]
