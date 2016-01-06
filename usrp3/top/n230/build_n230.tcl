#
# Copyright 2014-2015 Ettus Research
#

source $::env(VIV_TOOLS_DIR)/scripts/viv_utils.tcl
source $::env(VIV_TOOLS_DIR)/scripts/viv_strategies.tcl

set safe_image $env(SAFE_MODE)

# STEP#1: Create project, add sources, refresh IP
vivado_utils::initialize_project

# STEP#2: Run synthesis 
vivado_utils::synthesize_design
vivado_utils::generate_post_synth_reports

# STEP#3: Run implementation strategy
vivado_strategies::implement_design [vivado_strategies::get_impl_preset "Default"]

# STEP#4: Generate reports
vivado_utils::generate_post_route_reports

# STEP#5: Generate a bitstream, netlist and debug probes

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [get_designs *]

# Multiboot settings
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [get_designs *]
#0xBEBC1 = 4s for a 50MHz clock divided down by 256. Each clock tick is 5120ns
set_property BITSTREAM.CONFIG.TIMER_CFG 0xBEBC1 [get_designs *]

if {$safe_image} {
    # Settings for SAFE Image Only
    set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 0x400000 [get_designs *]
    set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT Enable [get_designs *]
    set_property BITSTREAM.CONFIG.USERID 0x5AFE0000 [get_designs *]
} else {
    # Settings for PRODUCTION Image Only
    set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT Disable [get_designs *]
    set_property BITSTREAM.CONFIG.USERID 0xFFFF0000 [get_designs *]
}

vivado_utils::write_implementation_outputs

# Cleanup
vivado_utils::close_batch_project
