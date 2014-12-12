#
# Copyright 2014 Ettus Research
#

# ---------------------------------------
# Gather all external parameters
# ---------------------------------------
set part_name $env(PART_NAME)
set xci_files $env(XCI_FILES)

# ---------------------------------------
# Vivado Commands
# ---------------------------------------
create_project -part $part_name -in_memory -ip
set_property target_simulator XSim [current_project]
foreach xci_file $xci_files {
    puts "BUILDER: Adding IP: $xci_file"
    add_files -norecurse -force $xci_file
}
puts "BUILDER: Upgrading IP"
upgrade_ip [get_ips *]
close_project