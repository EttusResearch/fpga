# Gather all external parameters
set top_level $env(TOP_MODULE)
set xilinx_part $env(DEVICE)
set short_hash $env(SHORT_HASH)
set name $env(NAME)
set output_dir $env(OUTPUT_DIR)

# STEP#0: create a project
create_project -in_memory -part $xilinx_part

# STEP#1: setup design sources and constraints

##################################################
# Add the Verilog sources
##################################################
foreach source $env(VERILOG_SOURCES) {
    puts ">>> Adding Verilog file to build: $source"
    read_verilog $source
}

##################################################
# Add the VHDL sources
##################################################
foreach source $env(VHDL_SOURCES) {
    puts ">>> Adding VHDL file to build: $source"
    read_vhdl -library work $source
}

##################################################
# Add the XDC sources
##################################################
foreach source $env(XDC_SOURCES) {
    puts ">>> Adding XDC file to build: $source"
    read_xdc $source
}

##################################################
# Add the EDIF / NGC sources
##################################################
foreach source $env(EDIF_NGC_SOURCES) {
    puts ">>> Adding EDIF / NGC file to build: $source"
    read_edif $source
}

##################################################
# Add the IP sources
##################################################
foreach source $env(IP_DIRS) {
    foreach xci_file [glob -nocomplain -types f -directory $source *.xci] {
        puts ">>> Adding IP file to build: $xci_file"
        read_ip $xci_file
    }
}

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
generate_target  all [get_ips *]

synth_design -top $top_level -part $xilinx_part -verilog_define DELETE_FORMAT_CONVERSION -verilog_define GIT_HASH=$short_hash

write_checkpoint -force $output_dir/post_synth

report_utilization -file $output_dir/post_synth_util.rpt

report_drc -ruledeck methodology_checks -file $output_dir/methodology.rpt

report_high_fanout_nets  -file $output_dir/high_fanout_nets.rpt

# STEP#3: run placement and logic optimization, report utilization and timing estimates

opt_design

power_opt_design

place_design

phys_opt_design

write_checkpoint -force $output_dir/post_place

report_clock_utilization -file $output_dir/clock_util.rpt

report_utilization -file $output_dir/post_place_util.rpt

report_timing -sort_by group -max_paths 5 -path_type summary -file $output_dir/post_place_timing.rpt

# STEP#4: run router, report actual utilization and timing, write checkpoint design, run DRCs

route_design

write_checkpoint -force $output_dir/post_route

report_timing_summary -file $output_dir/post_route_timing_summary.rpt

report_utilization -file $output_dir/post_route_util.rpt

report_power -file $output_dir/post_route_power.rpt

report_drc -file $output_dir/post_imp_drc.rpt

write_verilog -force $output_dir/${top_level}_impl_netlist.v

write_xdc -no_fixed_only -force $output_dir/${top_level}_impl.xdc

# STEP#5: generate a bitstream

write_bitstream -force $output_dir/${top_level}.bit

write_debug_probes -force $output_dir/${top_level}.ltx