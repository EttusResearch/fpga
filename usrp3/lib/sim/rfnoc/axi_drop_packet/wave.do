onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/clk
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/reset
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/clear
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i_tdata
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i_tvalid
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i_tlast
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i_terror
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i_tready
add wave -noupdate -radix unsigned /axi_drop_packet_tb/axi_drop_packet/o_tdata
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/o_tvalid
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/o_tlast
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/o_tready
add wave -noupdate -radix unsigned /axi_drop_packet_tb/axi_drop_packet/int_tdata
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/int_tlast
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/int_tvalid
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/int_tready
add wave -noupdate -radix unsigned /axi_drop_packet_tb/axi_drop_packet/wr_addr
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/prev_wr_addr
add wave -noupdate -radix unsigned /axi_drop_packet_tb/axi_drop_packet/rd_addr
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/in_pkt_cnt
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/out_pkt_cnt
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/full
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/empty
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/mem
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/i
add wave -noupdate /axi_drop_packet_tb/axi_drop_packet/hold
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {864000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 363
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1123328 ps}
