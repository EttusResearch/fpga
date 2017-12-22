#
# Copyright 2016 Ettus Research
#

source $::env(VIV_TOOLS_DIR)/scripts/viv_utils.tcl
source $::env(VIV_TOOLS_DIR)/scripts/viv_strategies.tcl

# STEP#1: Create project, add sources, refresh IP
vivado_utils::initialize_project

# STEP#2: Run synthesis
vivado_utils::synthesize_design
vivado_utils::generate_post_synth_reports

# STEP#3: Run implementation strategy
vivado_strategies::implement_design [vivado_strategies::get_impl_preset "Performance_ExplorePostRoutePhysOpt"]
# vivado_strategies::implement_design [vivado_strategies::get_impl_preset "Default"]

# STEP#4: Generate reports
vivado_utils::generate_post_route_reports

# STEP#5: Generate a bitstream, netlist and debug probes
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [get_designs *]
set byte_swap_bin 1
vivado_utils::write_implementation_outputs $byte_swap_bin

# Cleanup
vivado_utils::close_batch_project
