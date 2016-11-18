onerror {resume}
radix define fixed#23#decimal#signed -fixed -fraction 23 -signed -base signed
quietly WaveActivateNextPane {} 0
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/NOC_ID
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/set_data
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/set_addr
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/set_stb
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/sum_len
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/divisor
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/sum_len_changed
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_sink_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_src_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_sink_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_sink_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_sink_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_src_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_src_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/str_src_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/m_axis_data_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/s_axis_data_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/m_axis_data_tuser
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/m_axis_data_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/m_axis_data_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/m_axis_data_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/s_axis_data_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/s_axis_data_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/s_axis_data_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/ipart_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/ipart_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/ipart_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/ipart_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qpart_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qpart_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qpart_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qpart_tready
add wave -noupdate -radix decimal /noc_block_moving_avg_tb/noc_block_moving_avg/isum_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/isum_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/isum_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/isum_tready
add wave -noupdate -radix decimal /noc_block_moving_avg_tb/noc_block_moving_avg/qsum_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qsum_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qsum_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qsum_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/idivisor_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/idividend_tready
add wave -noupdate -radix fixed#23#decimal#signed /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_tvalid
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qdivisor_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qdividend_tready
add wave -noupdate -radix decimal /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_rnd_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_rnd_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_rnd_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/iavg_rnd_tvalid
add wave -noupdate -radix decimal /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_rnd_tdata
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_rnd_tlast
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_rnd_tready
add wave -noupdate /noc_block_moving_avg_tb/noc_block_moving_avg/qavg_rnd_tvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9403586 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 389
configure wave -valuecolwidth 219
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {9370440 ps} {9448802 ps}
