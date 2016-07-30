onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_ack/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_ack/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_ack/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_ack/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_ack/tready
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_cmd/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_cmd/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_cmd/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_cmd/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/cvita_cmd/tready
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_axis_data/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_axis_data/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_axis_data/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_axis_data/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_axis_data/tready
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_cvita_data/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_cvita_data/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_cvita_data/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_cvita_data/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/m_cvita_data/tready
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_axis_data/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_axis_data/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_axis_data/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_axis_data/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_axis_data/tready
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_cvita_data/clk
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_cvita_data/tdata
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_cvita_data/tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_cvita_data/tlast
add wave -noupdate /noc_block_invert_tb/noc_block_tb/s_cvita_data/tready
add wave -noupdate /noc_block_invert_tb/noc_block_invert/i_tdata
add wave -noupdate /noc_block_invert_tb/noc_block_invert/i_tlast
add wave -noupdate /noc_block_invert_tb/noc_block_invert/i_tready
add wave -noupdate /noc_block_invert_tb/noc_block_invert/i_tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_invert/m_axis_data_tdata
add wave -noupdate /noc_block_invert_tb/noc_block_invert/m_axis_data_tlast
add wave -noupdate /noc_block_invert_tb/noc_block_invert/m_axis_data_tready
add wave -noupdate /noc_block_invert_tb/noc_block_invert/m_axis_data_tuser
add wave -noupdate /noc_block_invert_tb/noc_block_invert/m_axis_data_tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_invert/s_axis_data_tdata
add wave -noupdate /noc_block_invert_tb/noc_block_invert/s_axis_data_tlast
add wave -noupdate /noc_block_invert_tb/noc_block_invert/s_axis_data_tready
add wave -noupdate /noc_block_invert_tb/noc_block_invert/s_axis_data_tuser
add wave -noupdate /noc_block_invert_tb/noc_block_invert/s_axis_data_tvalid
add wave -noupdate /noc_block_invert_tb/noc_block_invert/o_tdata
add wave -noupdate /noc_block_invert_tb/noc_block_invert/o_tlast
add wave -noupdate /noc_block_invert_tb/noc_block_invert/o_tready
add wave -noupdate /noc_block_invert_tb/noc_block_invert/o_tvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {192737430 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 508
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
WaveRestoreZoom {0 ps} {1050 us}
