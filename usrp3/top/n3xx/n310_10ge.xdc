#
# Copyright 2014 Ettus Research LLC
#

set_property PACKAGE_PIN   AA8              [get_ports {MGT156MHZ_CLK1_P}]
set_property PACKAGE_PIN   AA7              [get_ports {MGT156MHZ_CLK1_N}]

# TODO: Check it
#IOSTANDARD not required because this is a GT terminal
#set_property IOSTANDARD    LVDS_25  [get_ports {XG_CLK_*}]

create_clock -name MGT156MHZ_CLK1 -period 6.400 -waveform {0.000 3.200} [get_ports MGT156MHZ_CLK1_P]
#
set_clock_groups -asynchronous -group [get_clocks bus_clk] -group [get_clocks MGT156MHZ_CLK1]
set_clock_groups -asynchronous -group [get_clocks -filter {NAME =~ *network_interface_*/sfpp_io_i/ten_gige_phy_i/ten_gig_eth_pcs_pma_i/*/gtxe2_i/RXOUTCLK}] -group [get_clocks MGT156MHZ_CLK1]
set_clock_groups -asynchronous -group [get_clocks -filter {NAME =~ *network_interface_*/sfpp_io_i/ten_gige_phy_i/ten_gig_eth_pcs_pma_i/*/gtxe2_i/TXOUTCLK}] -group [get_clocks MGT156MHZ_CLK1]
#
set_false_path -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ *sfpp_io_*/ten_gige_phy_i/*sync1_r_reg*}] -filter {NAME =~ *PRE}]
set_false_path -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ *sfpp_io_*/ten_gige_phy_i/*sync1_r_reg*}] -filter {NAME =~ *CLR}]
