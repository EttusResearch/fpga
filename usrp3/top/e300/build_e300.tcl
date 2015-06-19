#
# Copyright 2015 Ettus Research
#

source $::env(VIV_TOOLS_DIR)/scripts/viv_utils.tcl

# -------------------------------------------------
# STEP#1: Create project, add sources, refresh IP
# -------------------------------------------------
vivado_utils::initialize_project

# -------------------------------------------------
# STEP#2: Run synthesis 
# -------------------------------------------------
vivado_utils::synthesize_design
vivado_utils::generate_post_synth_reports

# -------------------------------------------------
# STEP#3: Run placement and logic optimization
# -------------------------------------------------
opt_design
power_opt_design
place_design
phys_opt_design
vivado_utils::generate_post_place_reports

# -------------------------------------------------
# STEP#4: Run router, Report actual utilization and timing
# -------------------------------------------------
route_design
vivado_utils::generate_post_route_reports

# -------------------------------------------------
# STEP#5: If timing fails, run placer & router with high effort settings
# -------------------------------------------------
for {set i 0} {$i < 3} {incr i} {
  # Stop if timing is met
  if {[get_property SLACK [get_timing_paths ]] >= 0} {break};

  place_design -post_place_opt
  phys_opt_design -directive Explore
  vivado_utils::generate_post_place_reports {_timing_fixup_iter_$i}
  route_design -directive Explore -tns_cleanup
  phys_opt_design -directive AggressiveExplore
  vivado_utils::generate_post_route_reports {_timing_fixup_iter_$i}
}

# -------------------------------------------------
# STEP#6: Generate a bitstream, netlist and debug probes
# -------------------------------------------------
vivado_utils::write_implementation_outputs

vivado_utils::close_batch_project
