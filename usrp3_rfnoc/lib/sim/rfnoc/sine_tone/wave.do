onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sine_tone_tb/tc_running
add wave -noupdate /sine_tone_tb/tc_failed
add wave -noupdate /sine_tone_tb/tc_run_count
add wave -noupdate /sine_tone_tb/tc_pass_count
add wave -noupdate /sine_tone_tb/clk
add wave -noupdate /sine_tone_tb/rst
add wave -noupdate /sine_tone_tb/o_tdata
add wave -noupdate /sine_tone_tb/o_tlast
add wave -noupdate /sine_tone_tb/o_tvalid
add wave -noupdate /sine_tone_tb/o_tready
add wave -noupdate /sine_tone_tb/real_val
add wave -noupdate /sine_tone_tb/cplx_val
add wave -noupdate /sine_tone_tb/last
add wave -noupdate /glbl/GSR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {121 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {1 ns}
