set ip_file $env(IP_FILE)
create_project -in_memory -part xc7z020clg484-1
read_ip $ip_file
if { [catch {set_property GENERATE_SYNTH_CHECKPOINT TRUE [get_files [get_property IP_FILE [get_ips *]]]} code]} {
    puts "WARNING: This IP block has READ-ONLY attirbute for GENERATE_SYNTH_CHECKPOINT.\n No .dcp file wil be generated and this Make target will always run.\n"
    generate_target -force all [get_ips *]
} else {
    generate_target -force all [get_ips *]
    synth_ip [get_ips *]
}
