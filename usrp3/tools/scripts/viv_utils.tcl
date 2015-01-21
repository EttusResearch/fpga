#
# Copyright 2014 Ettus Research
#

# ---------------------------------------------------
# Create namespace and initialize global parameters
# ---------------------------------------------------
namespace eval ::vivado_utils {
    # Export commands
    namespace export \
        initialize_project \
        synthesize_design \
        generate_post_synth_reports \
        generate_post_place_reports \
        generate_post_route_reports \
        write_implementation_outputs \
        get_top_module \
        get_part_name \
        get_vivado_mode

    # Required environment variables
    variable g_top_module   $::env(VIV_TOP_MODULE)
    variable g_part_name    $::env(VIV_PART_NAME)
    variable g_output_dir   $::env(VIV_OUTPUT_DIR)
    variable g_source_files $::env(VIV_SOURCE_FILES)
    variable g_vivado_mode  $::env(VIV_MODE)

    # Optional environment variables
    variable g_verilog_defs ""
    if { [info exists ::env(VIV_VERILOG_DEFS) ] } {
        set g_verilog_defs  $::env(VIV_VERILOG_DEFS)
    }
    variable g_include_dirs ""
    if { [info exists ::env(VIV_INCLUDE_DIRS) ] } {
        set g_include_dirs  $::env(VIV_INCLUDE_DIRS)
    }
}

# ---------------------------------------------------
# Create a new project in memory and add source files
# ---------------------------------------------------
proc ::vivado_utils::initialize_project { {save_to_disk 0} } {
    variable g_top_module
    variable g_part_name
    variable g_output_dir
    variable g_source_files

    if {$save_to_disk == 1} {
        puts "BUILDER: Creating Vivado project ${g_top_module}_project.xpr for part $g_part_name"
        create_project -part $g_part_name ${g_top_module}_project
    } else {
        puts "BUILDER: Creating Vivado project in memory for part $g_part_name"
        create_project -in_memory -part $g_part_name
    }

    foreach src_file $g_source_files {
        set src_ext [file extension $src_file ]
        if [expr [lsearch {.vhd .vhdl} $src_ext] >= 0] {
            puts "BUILDER: Adding VHDL    : $src_file"
            read_vhdl -library work $src_file
        } elseif [expr [lsearch {.v} $src_ext] >= 0] {
            puts "BUILDER: Adding Verilog : $src_file"
            read_verilog $src_file
        } elseif [expr [lsearch {.xdc} $src_ext] >= 0] {
            puts "BUILDER: Adding XDC     : $src_file"
            read_xdc $src_file
        } elseif [expr [lsearch {.xci} $src_ext] >= 0] {
            puts "BUILDER: Adding IP      : $src_file"
            read_ip $src_file
        } elseif [expr [lsearch {.ngc .edif} $src_ext] >= 0] {
            puts "BUILDER: Adding Netlist : $src_file"
            read_edif $src_file
        } else {
            puts "BUILDER: \[WARNING\] File ignored!!!: $src_file"
        }
    }

    puts "BUILDER: Refreshing IP"
    generate_target all [get_ips *]
    synth_ip [get_ips *]

    puts "BUILDER: Setting $g_top_module as the top module"
    set_property top $g_top_module [current_fileset]
}

# ---------------------------------------------------
# Synthesize design (Shortcut for Vivado's synth_design)
# ---------------------------------------------------
proc ::vivado_utils::synthesize_design {args} {
    variable g_top_module
    variable g_part_name
    variable g_verilog_defs
    variable g_include_dirs

    set vdef_args ""
    foreach vdef $g_verilog_defs {
        set vdef_args [concat $vdef_args "-verilog_define $vdef"]
    }
    set incdir_args ""
    if { [string compare $g_include_dirs ""] != 0 } {
        set incdir_args "-include_dirs $g_include_dirs"
    }

    set synth_cmd "synth_design -top $g_top_module -part $g_part_name"
    set synth_cmd [concat $synth_cmd $vdef_args]
    set synth_cmd [concat $synth_cmd $incdir_args]
    set synth_cmd [concat $synth_cmd $args]
    puts "BUILDER: Synthesizing design"
    eval $synth_cmd
}

# ---------------------------------------------------
# Generate post synthesis reports and checkpoint
# ---------------------------------------------------
proc ::vivado_utils::generate_post_synth_reports {} {
    variable g_output_dir

    puts "BUILDER: Writing post-synthesis checkpoint"
    write_checkpoint -force $g_output_dir/post_synth 
    puts "BUILDER: Writing post-synthesis reports"
    report_utilization -file $g_output_dir/post_synth_util.rpt 
    report_drc -ruledeck methodology_checks -file $g_output_dir/methodology.rpt 
    report_high_fanout_nets -file $g_output_dir/high_fanout_nets.rpt 
}

# ---------------------------------------------------
# Generate post placement reports and checkpoint
# ---------------------------------------------------
proc ::vivado_utils::generate_post_place_reports {} {
    variable g_output_dir

    puts "BUILDER: Writing post-placement checkpoint"
    write_checkpoint -force $g_output_dir/post_place 
    puts "BUILDER: Writing post-placement reports"
    report_clock_utilization -file $g_output_dir/clock_util.rpt 
    report_utilization -file $g_output_dir/post_place_util.rpt 
    report_timing -sort_by group -max_paths 5 -path_type summary -file $g_output_dir/post_place_timing.rpt 
}

# ---------------------------------------------------
# Generate post route reports and checkpoint
# ---------------------------------------------------
proc ::vivado_utils::generate_post_route_reports {} {
    variable g_output_dir

    puts "BUILDER: Writing post-route checkpoint"
    write_checkpoint -force $g_output_dir/post_route 
    puts "BUILDER: Writing post-route reports"
    report_timing_summary -file $g_output_dir/post_route_timing_summary.rpt 
    report_utilization -file $g_output_dir/post_route_util.rpt 
    report_power -file $g_output_dir/post_route_power.rpt 
    report_drc -file $g_output_dir/post_imp_drc.rpt 
    report_timing -sort_by group -max_paths 10 -path_type summary -file $g_output_dir/post_route_timing.rpt 
}

# ---------------------------------------------------
# Export implementation
# ---------------------------------------------------
proc ::vivado_utils::write_implementation_outputs {} {
    variable g_output_dir
    variable g_top_module

    puts "BUILDER: Writing implementation netlist and XDC"
    write_verilog -force $g_output_dir/${g_top_module}_impl_netlist.v 
    write_xdc -no_fixed_only -force $g_output_dir/${g_top_module}_impl.xdc 
    puts "BUILDER: Writing bitstream"
    write_bitstream -force -bin_file $g_output_dir/${g_top_module}.bit 
    puts "BUILDER: Writing debug probes"
    write_debug_probes -force $g_output_dir/${g_top_module}.ltx
}

# ---------------------------------------------------
# Close project
# ---------------------------------------------------
proc ::vivado_utils::close_batch_project {} {
    variable g_vivado_mode
    
    if [string equal $g_vivado_mode "batch"] {
        puts "BUILDER: Closing project"
        close_project
    } else {
        puts "BUILDER: In GUI mode. Leaving project open."
    }
}

# ---------------------------------------------------
# Get state variables
# ---------------------------------------------------
proc ::vivado_utils::get_top_module {} {
    variable g_top_module
    return $g_top_module
}

proc ::vivado_utils::get_part_name {} {
    variable g_part_name
    return $g_part_name
}

proc ::vivado_utils::get_vivado_mode {} {
    variable g_vivado_mode
    return $g_vivado_mode
}
