#
# Copyright 2018 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: LGPL-3.0
#
# Description: Timing constraints for the USRP E320
#


###############################################################################
# Input Clocks
###############################################################################

# Radio clock from AD9361
set rx_clk_period 8.138
create_clock -name rx_clk -period $rx_clk_period [get_ports RX_CLK_P]

# 1 Gigabit Ethernet Reference Clock
create_clock -name ge_clk  -period 8.000 [get_ports CLK_MGT_125M_P]

# 10 Gigabit and Aurora Reference Clock
create_clock -name xge_clk -period 6.400 [get_ports CLK_MGT_156_25M_P]



###############################################################################
# Rename Generated Clocks
###############################################################################

create_clock -name clk100 \
             -period   [get_property PERIOD      [get_clocks clk_fpga_0]] \
             [get_pins [get_property SOURCE_PINS [get_clocks clk_fpga_0]]]
set_input_jitter clk100 0.3

create_clock -name clk40 \
             -period   [get_property PERIOD      [get_clocks clk_fpga_1]] \
             [get_pins [get_property SOURCE_PINS [get_clocks clk_fpga_1]]]
set_input_jitter clk40 0.75

create_clock -name meas_clk_ref \
             -period   [get_property PERIOD      [get_clocks clk_fpga_2]] \
             [get_pins [get_property SOURCE_PINS [get_clocks clk_fpga_2]]]
set_input_jitter meas_clk_ref 0.18

create_clock -name bus_clk \
             -period   [get_property PERIOD      [get_clocks clk_fpga_3]] \
             [get_pins [get_property SOURCE_PINS [get_clocks clk_fpga_3]]]
set_input_jitter bus_clk 0.15

create_clock -name ddr3_clk_ref \
             -period   [get_property PERIOD      [get_clocks sys_clk_p]] \
             [get_ports sys_clk_p]

# MIG User Interface Clock
create_generated_clock -name ddr3_ui_clk \
  [get_pins {u_ddr3_32bit/u_ddr3_32bit_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT}]

# MIG User Interface Clock, twice the frequency
create_generated_clock -name ddr3_ui_clk_2x \
  [get_pins {u_ddr3_32bit/u_ddr3_32bit_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKOUT0}]



###############################################################################
# Asynchronous Clock Groups
###############################################################################
             
# All the clocks from the PS are asynchronous to everything else except clocks 
# generated from themselves.
set_clock_groups -asynchronous -group [get_clocks clk100       -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk40        -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks bus_clk      -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks meas_clk_ref -include_generated_clocks]

# All the clocks from the PL are asynchronous to everything else except clocks 
# generated from themselves.
set_clock_groups -asynchronous -group [get_clocks rx_clk  -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks ge_clk  -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks xge_clk -include_generated_clocks]



###############################################################################
# False Paths
###############################################################################

# DMA reset double synchronizer
set_false_path -through [get_pins e320_core_i/ddr3_dma_rst_sync_i/synchronizer_false_path/ui_clk_sync_rst]



###############################################################################
# LVDS Interface
###############################################################################

# LVDS interface is source synchronous DDR. tPCB numbers are taken from
# HyperLynx for the Rev B PCB. 10 ps was added to each PCB delay for additional
# margin.

# From the AD9361 data sheet
set tDDRX(min) 0.25
set tDDRX(max) 1.25
set tSTX(min)  1.0
set tHTX(min)  0.0

# Other timing parameters
set tCP2X(min) [expr 0.45 * $rx_clk_period]  ; # Worst-case bit period
set tTrns(max) 0.220   ; # Amount of time it takes an input to transition

# Input timing parameters
set tPCB_RX(max)  0.058   ; # Max delay by which the clock trace is longer than the data trace
set tPCB_RX(min) -0.059   ; # Min delay by which the clock trace is longer than the data trace
set tSetupIn  [expr $tCP2X(min) - $tDDRX(max) + $tPCB_RX(min)]
set tHoldIn   [expr $tDDRX(min) - $tTrns(max) - $tPCB_RX(max)]

# Input Setup/Hold (Rising Clock Edge)
set_input_delay -clock [get_clocks rx_clk] -max [expr $tCP2X(min) - $tSetupIn] [get_ports {RX_DATA_*[*] RX_FRAME_*}]
set_input_delay -clock [get_clocks rx_clk] -min $tHoldIn [get_ports {RX_DATA_*[*] RX_FRAME_*}]

# Input Setup/Hold (Falling Clock Edge)
set_input_delay -clock [get_clocks rx_clk] -max [expr $tCP2X(min) - $tSetupIn] [get_ports {RX_DATA_*[*] RX_FRAME_*}] -clock_fall -add_delay
set_input_delay -clock [get_clocks rx_clk] -min $tHoldIn [get_ports {RX_DATA_*[*] RX_FRAME_*}] -clock_fall -add_delay


# Output timing parameters
set tPCB_TX(max)  0.066   ; # Max delay by which the clock trace is longer than the data trace
set tPCB_TX(min) -0.049   ; # Min delay by which the clock trace is longer than the data trace
set tSetupOut  [expr $tSTX(min) - $tPCB_TX(min)]
set tHoldOut   [expr $tHTX(min) + $tPCB_TX(max)]

# Create tx_clk (FB_CLK)
create_generated_clock \
  -name tx_clk \
  -multiply_by 1 \
  -source [get_pins cat_io_lvds_dual_mode_i0/cat_io_lvds_i0/cat_output_lvds_i0/ddr_clk_oserdese2/CLK] \
  [get_ports TX_CLK_P]

# Output Setup
set_output_delay -clock [get_clocks tx_clk] -max $tSetupOut [get_ports {TX_DATA_*[*] TX_FRAME_*}]
set_output_delay -clock [get_clocks tx_clk] -max $tSetupOut [get_ports {TX_DATA_*[*] TX_FRAME_*}] -clock_fall -add_delay

# Output Hold
set_output_delay -clock [get_clocks tx_clk] -min [expr -$tHoldOut] [get_ports {TX_DATA_*[*] TX_FRAME_*}]
set_output_delay -clock [get_clocks tx_clk] -min [expr -$tHoldOut] [get_ports {TX_DATA_*[*] TX_FRAME_*}] -clock_fall -add_delay



###############################################################################
# Miscellaneous I/O Constraints
###############################################################################

# Transceiver
set_max_delay -to [get_ports XCVR_RESET_N] 50.0
set_min_delay -to [get_ports XCVR_RESET_N] 0.0
#
set_max_delay -from [get_ports XCVR_CTRL_OUT[*]] 5.0 -datapath_only
set_min_delay -from [get_ports XCVR_CTRL_OUT[*]] 0.0

# GPIO
set_max_delay -from [get_ports GPIO_PREBUFF[*]] 5.0 -datapath_only
set_min_delay -from [get_ports GPIO_PREBUFF[*]] 0.0
#
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports GPIO_DIR[*]]] \
              -to   [get_ports GPIO_DIR[*]] 8.0 -datapath_only
set_min_delay -to   [get_ports GPIO_DIR[*]] 0.0
#
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports GPIO_PREBUFF[*]]] \
              -to   [get_ports GPIO_PREBUFF[*]] 8.0 -datapath_only
set_min_delay -to   [get_ports GPIO_PREBUFF[*]] 0.0
#
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports GPIO_OE_N]] \
              -to   [get_ports GPIO_OE_N] 8.0 -datapath_only
set_min_delay -to   [get_ports GPIO_OE_N] 0.0
#
set_max_delay -to   [get_ports {EN_GPIO_2V5 EN_GPIO_3V3 EN_GPIO_VAR_SUPPLY}] 50.0
set_min_delay -to   [get_ports {EN_GPIO_2V5 EN_GPIO_3V3 EN_GPIO_VAR_SUPPLY}] 0.0

# GPS
set_max_delay -from [get_ports {GPS_ALARM GPS_LOCK GPS_PHASELOCK GPS_SURVEY GPS_WARMUP}] 10.0 -datapath_only
set_min_delay -from [get_ports {GPS_ALARM GPS_LOCK GPS_PHASELOCK GPS_SURVEY GPS_WARMUP}] 0.0
#
set_max_delay -to [get_ports GPS_INITSURV_N] 50.0
set_min_delay -to [get_ports GPS_INITSURV_N] 0.0
set_max_delay -to [get_ports GPS_RST_N] 50.0
set_min_delay -to [get_ports GPS_RST_N] 0.0
#
set_max_delay -to [get_ports CLK_GPS_PWR_EN] 50.0
set_min_delay -to [get_ports CLK_GPS_PWR_EN] 0.0

# Clock Control
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports CLK_REF_SEL]] \
              -to   [get_ports CLK_REF_SEL] 8.0 -datapath_only
set_min_delay -to   [get_ports CLK_REF_SEL] 0.0
#
set_max_delay -from [get_ports CLK_MUX_OUT] 5.0 -datapath_only
set_min_delay -from [get_ports CLK_MUX_OUT] 0.0

# DDR3
set_max_delay -to [get_ports ddr3_reset_n] 50.0
set_min_delay -to [get_ports ddr3_reset_n] 0.0

# LEDs
set_max_delay -to [get_ports RX1_GRN_ENA]   50.0
set_min_delay -to [get_ports RX1_GRN_ENA]   0.0
set_max_delay -to [get_ports TX1_RED_ENA]   50.0
set_min_delay -to [get_ports TX1_RED_ENA]   0.0
set_max_delay -to [get_ports TXRX1_GRN_ENA] 50.0
set_min_delay -to [get_ports TXRX1_GRN_ENA] 0.0
set_max_delay -to [get_ports RX2_GRN_ENA]   50.0
set_min_delay -to [get_ports RX2_GRN_ENA]   0.0
set_max_delay -to [get_ports TX2_RED_ENA]   50.0
set_min_delay -to [get_ports TX2_RED_ENA]   0.0
set_max_delay -to [get_ports TXRX2_GRN_ENA] 50.0
set_min_delay -to [get_ports TXRX2_GRN_ENA] 0.0
#
set_max_delay -to [get_ports LED_ACT1]  50.0
set_min_delay -to [get_ports LED_ACT1]  0.0
set_max_delay -to [get_ports LED_LINK1] 50.0
set_min_delay -to [get_ports LED_LINK1] 0.0

# Control Filters
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports FE*_SEL[*]]] \
              -to   [get_ports FE*_SEL[*]] 10.0 -datapath_only
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports RX*_SEL[*]]] \
              -to   [get_ports RX*_SEL[*]] 10.0 -datapath_only
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports RX*_BSEL[*]]] \
              -to   [get_ports RX*_BSEL[*]] 10.0 -datapath_only
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports TX*_BSEL[*]]] \
              -to   [get_ports TX*_BSEL[*]] 10.0 -datapath_only

# PA Control
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports TX_HFAMP*_ENA]] \
              -to   [get_ports TX_HFAMP*_ENA] 10.0 -datapath_only
set_max_delay -from [all_fanin -only_cells -startpoints_only -flat [get_ports TX_LFAMP*_ENA]] \
              -to   [get_ports TX_LFAMP*_ENA] 10.0 -datapath_only

