#
# Copyright 2014 Ettus Research LLC
#


#*******************************************************************************
## Primary clock definitions

# Define clock FIXME Verify all clocks are rights
create_clock -name FPGA_REFCLK         -period 100.000 -waveform {0.000 50.000}   [get_ports FPGA_REFCLK]
create_clock -name ENET0_CLK125        -period 8.000   -waveform {0.000 4.000}    [get_ports ENET0_CLK125]
create_clock -name WB_20MHZ_CLK        -period 50.000  -waveform {0.000 25.000}   [get_ports WB_20MHZ_CLK]
#FIXME decided to choose this to be 200 MHz to match FPGA_CLK in x300 design. This is an arbitrary choice for now.
create_clock -name USRPIO_A_MGTCLK     -period 5.000   -waveform {0.000 2.500}    [get_ports USRPIO_A_MGTCLK_P]
create_clock -name USRPIO_B_MGTCLK     -period 5.000   -waveform {0.000 2.500}    [get_ports USRPIO_B_MGTCLK_P]


# FPGA_CLK_p/n is externally phase shifted to allow for crossing from the ADC clock domain
# to the radio_clk (aka FPGA_CLK_p/n) clock domain. To ensure this timing is consistent,
# lock the locations of the MMCM and BUFG to generate radio_clk.
#TODO these may need valid placements but these placements are for X300
#set_property LOC MMCME2_ADV_X0Y0 [get_cells -hierarchical -filter {NAME =~ "*radio_clk_gen/*mmcm_adv_inst"}]
#set_property LOC BUFGCTRL_X0Y8   [get_cells -hierarchical -filter {NAME =~ "*radio_clk_gen/*clkout1_buf"}]


#*******************************************************************************
## Aliases for auto-generated clocks
#FIXME add all clks
#create_generated_clock -name radio_clk                [get_pins -hierarchical -filter {NAME =~ "*radio_clk_gen/*/CLKOUT0"}]
#create_generated_clock -name radio_clk_2x             [get_pins -hierarchical -filter {NAME =~ "*radio_clk_gen/*/CLKOUT1"}]
create_generated_clock -name bus_clk                  -source [get_pins bus_clk_buf/I]


#*******************************************************************************
## Asynchronous clock groups

set_clock_groups -asynchronous -group [get_clocks bus_clk]      -group [get_clocks radio_clk]
set_clock_groups -asynchronous -group [get_clocks bus_clk]      -group [get_clocks ref_clk_10mhz]




# We also need to location constrain the first flops in the synchronizer to help the tools
# meet timing reliably

# ADC0
#set_property BEL A5FF           [get_cells {cap_db0/adc_data_rclk_reg*[0]}]


