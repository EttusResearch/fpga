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
create_generated_clock -name bus_clk_270  [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT1}]
create_generated_clock -name clk200       [get_pins {bus_clk_gen_i/inst/mmcm_adv_inst/CLKOUT2}]

## Virtual clocks 

# Codec interface clock
create_clock -name CODEC_CLK -period 5

#
# Show which clocks that hand off data are Async
#
set_clock_groups -group  [get_clocks sdr_clk] -group  [get_clocks bus_clk] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk] -group  [get_clocks clkout0] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk_2x] -group  [get_clocks bus_clk] -asynchronous
set_clock_groups -group  [get_clocks sdr_clk_2x] -group  [get_clocks clkout0] -asynchronous
set_clock_groups -group  [get_clocks bus_clk] -group  [get_clocks clkout0] -asynchronous

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
