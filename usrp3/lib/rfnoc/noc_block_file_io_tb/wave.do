onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 30 {noc block}
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/i_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/i_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/i_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/i_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/o_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/o_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/o_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/o_tready
add wave -noupdate -divider -height 30 equalizer
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/clk_i
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/rst_i
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/sof_i
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/i_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/i_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/i_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/i_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/o_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/o_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/o_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/o_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/state
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/last_sof
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_count
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/sof
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/first_prembl_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/neg_prembl_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/applied_prembl_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_flop_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_flop_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_flop_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/prembl_flop_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/inv_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/inv_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/inv_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/inv_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_fifo_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_fifo_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_fifo_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_mul_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_fifo_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/eq_mul_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_tvalid
add wave -noupdate /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/skip_prembl_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_fifo_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_fifo_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_fifo_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/data_fifo_tready
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/mul_tdata
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/mul_tlast
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/mul_tvalid
add wave -noupdate -height 30 /noc_block_eq_tb/noc_block_eq/one_tap_equalizer_inst/mul_tready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {208000000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 217
configure wave -valuecolwidth 183
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
WaveRestoreZoom {137039568 ps} {300682128 ps}
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
