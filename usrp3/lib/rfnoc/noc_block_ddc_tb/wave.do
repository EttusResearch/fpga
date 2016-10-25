onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/ce_clk
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/ce_rst
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/i_tdata
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/i_tlast
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/i_tready
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/i_tvalid
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/o_tdata
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/o_tlast
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/o_tready
add wave -noupdate /noc_block_ddc_tb/noc_block_ddc/o_tvalid
add wave -noupdate -divider {AXI Rate Change}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/i_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/i_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/i_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/i_tuser}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/i_tvalid}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/m_axis_data_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/m_axis_data_teob}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/m_axis_data_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/m_axis_data_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/m_axis_data_tvalid}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/s_axis_data_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/s_axis_data_teob}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/s_axis_data_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/s_axis_data_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/s_axis_data_tvalid}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/o_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/o_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/o_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/o_tuser}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/o_tvalid}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/genblk1/counter}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/genblk1/first_line}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_rate_change/inject_zeros}
add wave -noupdate -divider {AXI to Strobed}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/i_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/i_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/i_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/i_tvalid}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/out_data}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/out_last}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/out_rate}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/axi_to_strobed/out_stb}
add wave -noupdate -divider DDC
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_stb}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_last}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_i}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_q}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_stb_mux}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_last_mux}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_i_mux}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/rx_fe_q_mux}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/to_cordic_i}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/to_cordic_q}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_cordic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_cordic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_cordic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_cordic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_cordic_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_cordic_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_cordic_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_cordic_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_cic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_cic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_cic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_cic}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_hb1}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_hb1}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_hb1}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_hb1}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_hb2}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_hb2}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_hb2}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_hb2}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_hb3}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_hb3}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_hb3}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_hb3}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_unscaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_unscaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_unscaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_unscaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_scaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_scaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_scaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_scaled}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/last_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/i_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/q_clip}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/strobe}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/sample_last}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/ddc/sample}
add wave -noupdate -divider {Strobed to AXI}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/in_data}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/in_last}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/in_stb}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/o_tdata}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/o_tlast}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/o_tready}
add wave -noupdate {/noc_block_ddc_tb/noc_block_ddc/gen_ddc_chains[0]/strobed_to_axi/o_tvalid}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 758
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {14127 ps}
set IgnoreFailure 1
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
