onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /noc_block_fft_tb/bus_clk
add wave -noupdate /noc_block_fft_tb/bus_rst
add wave -noupdate /noc_block_fft_tb/ce_clk
add wave -noupdate /noc_block_fft_tb/ce_rst
add wave -noupdate /noc_block_fft_tb/real_val
add wave -noupdate /noc_block_fft_tb/cplx_val
add wave -noupdate /noc_block_fft_tb/noc_block_tb_m_axis_data/tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb_m_axis_data/tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_tb_m_axis_data/tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb_m_axis_data/tready
add wave -noupdate /noc_block_fft_tb/noc_block_tb_s_axis_data/tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb_s_axis_data/tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_tb_s_axis_data/tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb_s_axis_data/tready
add wave -noupdate -divider {Export IO}
add wave -noupdate /noc_block_fft_tb/tb_next_dst
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/i_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/i_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/i_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/i_tready
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/o_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/o_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/o_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb/inst_noc_shell/o_tready
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_sink_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_sink_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_sink_tready
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_sink_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_src_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_src_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_src_tready
add wave -noupdate /noc_block_fft_tb/noc_block_tb/str_src_tvalid
add wave -noupdate -divider Crossbar
add wave -noupdate /noc_block_fft_tb/axi_crossbar/flat_i_tdata
add wave -noupdate /noc_block_fft_tb/axi_crossbar/i_tlast
add wave -noupdate /noc_block_fft_tb/axi_crossbar/i_tready
add wave -noupdate /noc_block_fft_tb/axi_crossbar/i_tvalid
add wave -noupdate /noc_block_fft_tb/axi_crossbar/flat_o_tdata
add wave -noupdate /noc_block_fft_tb/axi_crossbar/o_tlast
add wave -noupdate /noc_block_fft_tb/axi_crossbar/o_tready
add wave -noupdate /noc_block_fft_tb/axi_crossbar/o_tvalid
add wave -noupdate -divider FFT
add wave -noupdate /noc_block_fft_tb/noc_block_fft/i_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_fft/i_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_fft/i_tready
add wave -noupdate /noc_block_fft_tb/noc_block_fft/i_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_fft/o_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_fft/o_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_fft/o_tready
add wave -noupdate /noc_block_fft_tb/noc_block_fft/o_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_fft/m_axis_data_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_fft/m_axis_data_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_fft/m_axis_data_tready
add wave -noupdate /noc_block_fft_tb/noc_block_fft/m_axis_data_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_fft/inst_axi_fft/m_axis_data_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_fft/inst_axi_fft/m_axis_data_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_fft/inst_axi_fft/m_axis_data_tready
add wave -noupdate /noc_block_fft_tb/noc_block_fft/inst_axi_fft/m_axis_data_tvalid
add wave -noupdate /noc_block_fft_tb/noc_block_fft/s_axis_data_tdata
add wave -noupdate /noc_block_fft_tb/noc_block_fft/s_axis_data_tlast
add wave -noupdate /noc_block_fft_tb/noc_block_fft/s_axis_data_tready
add wave -noupdate /noc_block_fft_tb/noc_block_fft/s_axis_data_tvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4735013 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 470
configure wave -valuecolwidth 218
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
configure wave -timelineunits ps
update
WaveRestoreZoom {4117229 ps} {16194911 ps}
set IgnoreFailure 1
set StdArithNoWarnings 1
set NumericStdNoWarnings 1