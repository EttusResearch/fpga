create_project -in_memory -part xc7z020clg484-1
read_ip axi_datamover_0/axi_datamover_0.xci
read_ip fifo_4k_2clk/fifo_4k_2clk.xci
read_ip fifo_short_2clk/fifo_short_2clk.xci
read_ip processing_system7_0/processing_system7_0.xci
read_ip catcodec_mmcm/catcodec_mmcm.xci
read_ip e300_ps_fclk0_mmcm/e300_ps_fclk0_mmcm.xci
read_ip axi4_to_axi3_protocol_converter/axi4_to_axi3_protocol_converter.xci
read_ip axi3_to_axi4lite_protocol_converter/axi3_to_axi4lite_protocol_converter.xci
read_ip axi4_fifo_512x64/axi4_fifo_512x64.xci
set_property GENERATE_SYNTH_CHECKPOINT TRUE [get_files [get_property IP_FILE [get_ips *]]]
generate_target -force all [get_ips *]
synth_ip [get_ips *]
