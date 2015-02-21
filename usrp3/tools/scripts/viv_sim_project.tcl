#
# Copyright 2014 Ettus Research
#

# ---------------------------------------
# Gather all external parameters
# ---------------------------------------
set design_srcs $::env(VIV_DESIGN_SRCS)
set sim_srcs    $::env(VIV_SIM_SRCS)
set sim_top     $::env(VIV_SIM_TOP)
set part_name   $::env(VIV_PART_NAME)
set vivado_mode $::env(VIV_MODE)

set sim_fileset "sim_1"

# ---------------------------------------
# Vivado Commands
# ---------------------------------------
puts "BUILDER: Creating Vivado simulation project part $part_name"
create_project -part $part_name -force sim_proj/sim_proj
#open_project sim_project/sim_project.xpr

foreach src_file $design_srcs {
    set src_ext [file extension $src_file ]
    if [expr [lsearch {.vhd .vhdl} $src_ext] >= 0] {
        puts "BUILDER: Adding VHDL    : $src_file"
        read_vhdl -library work $src_file
    } elseif [expr [lsearch {.v .sv} $src_ext] >= 0] {
        puts "BUILDER: Adding Verilog : $src_file"
        read_verilog $src_file
    } elseif [expr [lsearch {.sv} $src_ext] >= 0] {
        puts "BUILDER: Adding SVerilog: $src_file"
        read_verilog -sv $src_file
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

foreach sim_src $sim_srcs {
    add_files -fileset $sim_fileset -norecurse $sim_src
}

set_property target_simulator XSim [current_project]
set_property top $sim_top [get_filesets $sim_fileset]

launch_simulation

if [string equal $vivado_mode "batch"] {
    puts "BUILDER: Closing project"
    close_project
} else {
    puts "BUILDER: In GUI mode. Leaving project open."
}
