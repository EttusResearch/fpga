#
# Copyright 2014-2016 Ettus Research LLC
#

#*******************************************************************************
## Clock definitions

## Primary clocks

# 40 MHz continuous direct from pll
create_clock -name CODEC_MAIN_CLK -period 25.000 [get_ports CODEC_MAIN_CLK_P]
# 125 MHz ethernet osc clock
create_clock -name ETH_CLK -period 8.000 [get_ports SFPX_CLK_P]
# We really need 184.32 MHz (5.425ns) but we give ourselves some margin here by over constraining to 200MHz.
create_clock -name CODEC_DATA_CLK -period 5.000 -waveform {0.75 3.25} [get_ports CODEC_DATA_CLK_P]
# 92.16 MHz LOOP CLK
#create_clock -period 10.851 [get_ports CODEC_LOOP_CLK_IN_P]

## Derived clocks
create_generated_clock -name bus_clk      [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT0}]
create_generated_clock -name clk200       [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT1}]
create_generated_clock -name clk100       [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT2}]
create_generated_clock -name ram_ui_clk   [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT3}]
create_generated_clock -name ram_io_clk   [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT4}]

## Virtual clocks 

# Codec interface clock
create_clock -name CODEC_CLK -period 5

#
# Show which clocks that hand off data are Async
#
set_clock_groups -group  [get_clocks sdr_clk] -group  [get_clocks bus_clk] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk] -group  [get_clocks eth_mmcm_clkout0] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk_2x] -group  [get_clocks bus_clk] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk_2x] -group  [get_clocks eth_mmcm_clkout0] -asynchronous
set_clock_groups -group  [get_clocks bus_clk] -group  [get_clocks eth_mmcm_clkout0] -asynchronous

# Delays created to maximize setup/hold window without creating timing violations.
# In the application we can program delays at all drivers.
set_input_delay -clock [get_clocks CODEC_CLK] -max 1.9 [get_ports RX_DATA_*]
set_input_delay -clock [get_clocks CODEC_CLK] -min 1.1 [get_ports RX_DATA_*] -add_delay
set_input_delay -clock [get_clocks CODEC_CLK] -max 1.9 [get_ports RX_DATA_*] -add_delay -clock_fall
set_input_delay -clock [get_clocks CODEC_CLK] -min 1.1 [get_ports RX_DATA_*] -add_delay -clock_fall

set_input_delay -clock [get_clocks CODEC_CLK] -max 1.9 [get_ports RX_FRAME_*]
set_input_delay -clock [get_clocks CODEC_CLK] -min 1.1 [get_ports RX_FRAME_*] -add_delay
set_input_delay -clock [get_clocks CODEC_CLK] -max 1.9 [get_ports RX_FRAME_*] -add_delay -clock_fall
set_input_delay -clock [get_clocks CODEC_CLK] -min 1.1 [get_ports RX_FRAME_*] -add_delay -clock_fall

#
# Catalina LOC fixes
#
#set_property LOC OLOGIC_X0Y28 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/ddr_clk_oserdese2}]
#set_property LOC OLOGIC_X0Y20 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/ddr_frame_oserdese2}]
#set_property LOC OLOGIC_X0Y27 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/ddr_clk_oserdese2}]
#set_property LOC OLOGIC_X0Y19 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/ddr_frame_oserdese2}]
#set_property LOC OLOGIC_X0Y30 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[0].ddr_data_oserdese2}]
#set_property LOC OLOGIC_X0Y18 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[1].ddr_data_oserdese2}]
#set_property LOC OLOGIC_X0Y36 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[2].ddr_data_oserdese2}]
#set_property LOC OLOGIC_X0Y16 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[3].ddr_data_oserdese2}]
#set_property LOC OLOGIC_X0Y32 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[4].ddr_data_oserdese2}]
#set_property LOC OLOGIC_X0Y34 [get_cells {cat_int_ddr_lvds/cat_output_diff_i0/generate_data_bus[5].ddr_data_oserdese2}]

# Loopback signal starts in bus_clk, ends in radio_clk
set_max_delay -from [get_cells n230_core/sr_loopback/out_reg[*]] -to [get_cells n230_core/rx0_post_loop_reg[*]] -datapath_only 5.0
set_max_delay -from [get_cells n230_core/sr_loopback/out_reg[*]] -to [get_cells n230_core/rx1_post_loop_reg[*]] -datapath_only 5.0

# We constrain RAM_CLK to work at 120MHz to be conservative
#
create_generated_clock -name RAM_CLK -source [get_pins ext_fifo_i/ram_clk_out_i/C] -multiply_by 1 [get_ports RAM_CLK]
# No real path from RAM_CLK to internal clock(s)
set_clock_groups -group [get_clocks RAM_CLK] -group  [get_clocks bus_clk] -asynchronous

set t_sram_clk_period   [get_property PERIOD [get_clocks RAM_CLK]]
set t_sram_out_setup    1.500
set t_sram_out_hold     0.500
set t_sram_in_setup     [expr 1.500 + 3.500]
set t_sram_in_hold      1.500

# One cycle latency so move setup and hold times back by one period
set_input_delay -clock  [get_clocks RAM_CLK] -max [expr $t_sram_in_setup - $t_sram_clk_period]  [get_ports RAM_D*]
set_input_delay -clock  [get_clocks RAM_CLK] -min [expr $t_sram_in_hold - $t_sram_clk_period]   [get_ports RAM_D*]
set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_D*]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_D*]

set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_A*]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_A*]

set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_CENn]
set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_WEn]
set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_OEn]
set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_LDn]
set_output_delay -clock [get_clocks RAM_CLK] -max $t_sram_out_setup                             [get_ports RAM_CE1n]

set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_CENn]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_WEn]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_OEn]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_LDn]
set_output_delay -clock [get_clocks RAM_CLK] -min [expr -$t_sram_out_hold]                      [get_ports RAM_CE1n]
