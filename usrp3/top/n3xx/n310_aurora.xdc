#
# Copyright 2016 Ettus Research LLC
#

set_property PACKAGE_PIN   AA8              [get_ports {MGT156MHZ_CLK1_P}]
set_property PACKAGE_PIN   AA7              [get_ports {MGT156MHZ_CLK1_N}]

#IOSTANDARD not required because this is a GT terminal
#set_property IOSTANDARD    LVDS_25  [get_ports {XG_CLK_*}]

create_clock -name AUR_CLK -period 6.400 -waveform {0.000 3.200} [get_ports MGT156MHZ_CLK1_P]
create_generated_clock -name aurora_init_clk [get_pins -hierarchical -filter {NAME =~ "*aurora_clk_gen_i/dclk_divide_by_2_buf/O"}]

set_clock_groups -asynchronous -group [get_clocks bus_clk] -group [get_clocks aurora_init_clk]

set_false_path -to [get_pins -hierarchical -filter {NAME =~ "sfp_wrapper*/sfpp_io*/aurora_phy*/aurora_64b66b_pcs_pma*/*/gt_reset_sync/stg1_*_cdc_to_reg/D"}]

