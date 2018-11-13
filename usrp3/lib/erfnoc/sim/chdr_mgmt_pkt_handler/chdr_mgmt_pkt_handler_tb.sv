//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 13

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_axis_lib.svh"

module chdr_mgmt_pkt_handler_tb();
  `TEST_BENCH_INIT("chdr_mgmt_pkt_handler_tb", `NUM_TEST_CASES, `NS_PER_TICK);

  `DEFINE_CLK(clk, 10.000, 50);
  `DEFINE_RESET(rst, 0, 100);

  axis_master #(.DWIDTH(64)) m_chdr (.clk(clk));
  axis_slave  #(.DWIDTH(64+10+1)) s_chdr (.clk(clk));

  chdr_mgmt_pkt_handler #(
    .PROTOVER(16'hDEAD), .CHDR_W(64),
    .NODEINFO_TYPE(8'd6), .NODEINFO_INPUTS(1), .NODEINFO_OUTPUTS(1),
    .RESP_FIFO_SIZE(5)
  ) dut (
    .clk(clk), .rst(rst),
    .s_axis_chdr_tdata(m_chdr.axis.tdata),
    .s_axis_chdr_tlast(m_chdr.axis.tlast),
    .s_axis_chdr_tvalid(m_chdr.axis.tvalid),
    .s_axis_chdr_tready(m_chdr.axis.tready),
    .m_axis_chdr_tdata(s_chdr.axis.tdata[63:0]),
    .m_axis_chdr_tdest(s_chdr.axis.tdata[73:64]), 
    .m_axis_chdr_tid(s_chdr.axis.tdata[74]),
    .m_axis_chdr_tlast(s_chdr.axis.tlast),
    .m_axis_chdr_tvalid(s_chdr.axis.tvalid),
    .m_axis_chdr_tready(s_chdr.axis.tready | 1),
    .m_axis_rtcfg_tdata(),
    .m_axis_rtcfg_tdest(),
    .m_axis_rtcfg_tvalid(),
    .m_axis_rtcfg_tready(1),
    .ctrlport_req_wr(),
    .ctrlport_req_rd(),
    .ctrlport_req_addr(),
    .ctrlport_req_data(),
    .ctrlport_resp_ack(1'b1),
    .ctrlport_resp_data(32'hcdcdcdcd),
    .op_stb(),
    .op_dst_epid(),
    .op_src_epid()
  );

  initial begin : tb_main
    string s;

    `TEST_CASE_START("Wait for Reset");
      m_chdr.reset();
      s_chdr.reset();
      while (rst) @(posedge clk);
    `TEST_CASE_DONE(~rst);

    `TEST_CASE_START("Test");
      for (int k = 0; k < 1; k++) begin
        m_chdr.push_word({6'h00, 3'd0, 7'd0, 16'd0, 16'd96, 16'hBEEF}, 0);
        m_chdr.push_word({38'h0, 10'd3, 16'hF00D}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd0, 8'd5}, 0);
        m_chdr.push_word({48'h0000_0007, 8'd1, 8'd4}, 0);
        m_chdr.push_word({48'h00AB_1234, 8'd2, 8'd3}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd3, 8'd2}, 0);
        m_chdr.push_word({48'h0000_5678, 8'd6, 8'd1}, 0);
        m_chdr.push_word({48'h0000_9ABC, 8'd5, 8'd0}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd3, 8'd1}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd0, 8'd0}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd3, 8'd1}, 0);
        m_chdr.push_word({48'h0000_0000, 8'd0, 8'd0}, 1);
        repeat (50) @(posedge clk);
      end
    `TEST_CASE_DONE(~rst);

    `TEST_BENCH_DONE;
  end
endmodule
