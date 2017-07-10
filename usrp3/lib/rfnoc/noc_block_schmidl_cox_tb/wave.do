onerror {resume}
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox { /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[31:16]} i
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox { /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[15:0]} q
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_fft { /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tdata[31:16]} i
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_fft { /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tdata[15:0]} q
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_fft { /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tdata[31:16]} i_in
quietly virtual signal -install /noc_block_schmidl_cox_tb/noc_block_fft { /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tdata[15:0]} q_in
quietly WaveActivateNextPane {} 0
add wave -noupdate /noc_block_schmidl_cox_tb/bus_clk
add wave -noupdate /noc_block_schmidl_cox_tb/bus_rst
add wave -noupdate /noc_block_schmidl_cox_tb/ce_clk
add wave -noupdate /noc_block_schmidl_cox_tb/ce_rst
add wave -noupdate -group noc_block_tb_m_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_m_cvita_data/clk
add wave -noupdate -group noc_block_tb_m_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_m_cvita_data/tdata
add wave -noupdate -group noc_block_tb_m_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_m_cvita_data/tlast
add wave -noupdate -group noc_block_tb_m_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_m_cvita_data/tready
add wave -noupdate -group noc_block_tb_m_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_m_cvita_data/tvalid
add wave -noupdate -group noc_block_tb_s_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_s_cvita_data/clk
add wave -noupdate -group noc_block_tb_s_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_s_cvita_data/tdata
add wave -noupdate -group noc_block_tb_s_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_s_cvita_data/tlast
add wave -noupdate -group noc_block_tb_s_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_s_cvita_data/tready
add wave -noupdate -group noc_block_tb_s_cvita_data /noc_block_schmidl_cox_tb/noc_block_tb_s_cvita_data/tvalid
add wave -noupdate -group noc_block_tb_cvita_cmd /noc_block_schmidl_cox_tb/noc_block_tb_cvita_cmd/clk
add wave -noupdate -group noc_block_tb_cvita_cmd /noc_block_schmidl_cox_tb/noc_block_tb_cvita_cmd/tdata
add wave -noupdate -group noc_block_tb_cvita_cmd /noc_block_schmidl_cox_tb/noc_block_tb_cvita_cmd/tlast
add wave -noupdate -group noc_block_tb_cvita_cmd /noc_block_schmidl_cox_tb/noc_block_tb_cvita_cmd/tready
add wave -noupdate -group noc_block_tb_cvita_cmd /noc_block_schmidl_cox_tb/noc_block_tb_cvita_cmd/tvalid
add wave -noupdate -group noc_block_tb_cvita_ack /noc_block_schmidl_cox_tb/noc_block_tb_cvita_ack/clk
add wave -noupdate -group noc_block_tb_cvita_ack /noc_block_schmidl_cox_tb/noc_block_tb_cvita_ack/tdata
add wave -noupdate -group noc_block_tb_cvita_ack /noc_block_schmidl_cox_tb/noc_block_tb_cvita_ack/tlast
add wave -noupdate -group noc_block_tb_cvita_ack /noc_block_schmidl_cox_tb/noc_block_tb_cvita_ack/tready
add wave -noupdate -group noc_block_tb_cvita_ack /noc_block_schmidl_cox_tb/noc_block_tb_cvita_ack/tvalid
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_m_cvita[2]/clk}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_m_cvita[2]/tdata}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_m_cvita[2]/tlast}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_m_cvita[2]/tready}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_m_cvita[2]/tvalid}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_s_cvita[2]/clk}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_s_cvita[2]/tdata}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_s_cvita[2]/tlast}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_s_cvita[2]/tready}
add wave -noupdate -group tb_cvita {/noc_block_schmidl_cox_tb/xbar_s_cvita[2]/tvalid}
add wave -noupdate -divider {File Source}
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/i_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/i_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/i_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/i_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/o_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/o_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/o_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_file_source/o_tvalid
add wave -noupdate -divider {Schmidl Cox}
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/i_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/i_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/i_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/i_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/o_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/o_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/o_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/o_tvalid
add wave -noupdate -format Analog-Step -height 84 -max 30000.0 -min -30000.0 -radix decimal -childformat {{{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[31]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[30]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[29]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[28]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[27]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[26]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[25]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[24]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[23]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[22]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[21]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[20]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[19]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[18]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[17]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i[16]} -radix decimal}} -subitemconfig {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[31]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[30]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[29]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[28]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[27]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[26]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[25]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[24]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[23]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[22]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[21]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[20]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[19]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[18]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[17]} {-radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata[16]} {-radix decimal}} /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i
add wave -noupdate -format Analog-Step -height 84 -max 30000.0 -min -30000.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/q
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/i_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n0_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n0_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n0_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n0_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n1_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n1_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n1_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n1_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n2_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n2_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n2_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n2_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n3_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n3_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n3_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n3_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n4_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n4_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n4_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n4_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n5_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n5_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n5_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n5_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_round_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_round_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_round_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n6_round_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_tvalid
add wave -noupdate -radix unsigned /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_strip_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_phase_strip_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_phase_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_phase_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_phase_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_phase_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_round_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_round_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_round_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n7_mag_square_round_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_round_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_round_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_round_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_round_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_fractional
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_integer
add wave -noupdate -radix unsigned -childformat {{{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[45]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[44]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[43]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[42]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[41]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[40]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[39]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[38]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[37]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[36]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[35]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[34]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[33]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[32]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[31]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[30]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[29]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[28]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[27]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[26]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[25]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[24]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[23]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[22]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[21]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[20]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[19]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[18]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[17]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[16]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[15]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[14]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[13]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[12]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[11]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[10]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[9]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[8]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[7]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[6]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[5]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[4]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[3]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[2]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[1]} -radix unsigned} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[0]} -radix unsigned}} -subitemconfig {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[45]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[44]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[43]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[42]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[41]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[40]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[39]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[38]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[37]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[36]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[35]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[34]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[33]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[32]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[31]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[30]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[29]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[28]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[27]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[26]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[25]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[24]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[23]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[22]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[21]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[20]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[19]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[18]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[17]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[16]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[15]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[14]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[13]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[12]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[11]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[10]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[9]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[8]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[7]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[6]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[5]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[4]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[3]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[2]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[1]} {-height 17 -radix unsigned} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric[0]} {-height 17 -radix unsigned}} /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_tvalid
add wave -noupdate -radix decimal -childformat {{{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[15]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[14]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[13]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[12]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[11]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[10]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[9]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[8]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[7]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[6]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[5]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[4]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[3]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[2]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[1]} -radix decimal} {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[0]} -radix decimal}} -subitemconfig {{/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[15]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[14]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[13]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[12]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[11]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[10]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[9]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[8]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[7]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[6]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[5]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[4]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[3]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[2]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[1]} {-height 17 -radix decimal} {/noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata[0]} {-height 17 -radix decimal}} /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/D_metric_q1_14_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n8_shift_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n8_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n8_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n8_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n8_tvalid
add wave -noupdate -radix hexadecimal /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n9_sig_energy_square_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n10_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n10_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n10_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n10_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n12_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n12_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n12_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n12_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n13_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n13_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n13_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n13_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n14_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n14_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n14_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n14_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n15_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n15_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n15_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n15_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n16_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n16_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n16_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n16_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n17_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n17_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n17_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n17_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n18_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n18_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n18_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/n18_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/o_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/o_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/o_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/o_tvalid
add wave -noupdate -divider {Plataeu Detector}
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/clk
add wave -noupdate -format Analog-Step -height 84 -max 32767.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_avg_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_avg_tvalid
add wave -noupdate -radix unsigned /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_sum
add wave -noupdate -radix unsigned /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/d_metric_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/max_phase
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/max_val
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/output_ready
add wave -noupdate -radix decimal /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_avg_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_avg_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_sum
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/phase_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/reset
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/state
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/threshold
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/thresh_exceeded
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/thresh_exceeded_cnt
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/trigger
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/trigger_phase_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/trigger_phase_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/trigger_phase_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/trigger_phase_tvalid
add wave -noupdate -radix decimal /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/max_val_90
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_schmidl_cox/schmidl_cox/plateau_detector/max_cnt
add wave -noupdate -divider FFT
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/i_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/i_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/i_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/i_tvalid
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/o_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/o_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/o_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/o_tvalid
add wave -noupdate -clampanalog 1 -format Analog-Step -height 84 -max 1000.0 -min -1000.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_fft/i_in
add wave -noupdate -clampanalog 1 -format Analog-Step -height 84 -max 1000.0 -min -1000.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_fft/q_in
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/m_axis_data_tvalid
add wave -noupdate -clampanalog 1 -format Analog-Step -height 84 -max 3000.0 -min -3000.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_fft/i
add wave -noupdate -clampanalog 1 -format Analog-Step -height 84 -max 3000.0 -min -3000.0 -radix decimal /noc_block_schmidl_cox_tb/noc_block_fft/q
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tdata
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tlast
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tready
add wave -noupdate /noc_block_schmidl_cox_tb/noc_block_fft/fft_shift_o_tvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20432519 ps} 0} {{Cursor 2} {585711758 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 770
configure wave -valuecolwidth 174
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
WaveRestoreZoom {0 ps} {8244811 ps}
set IgnoreFailure 1
set StdArithNoWarnings 1
set NumericStdNoWarnings 1