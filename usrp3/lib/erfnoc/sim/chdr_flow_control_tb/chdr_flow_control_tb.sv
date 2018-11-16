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

module chdr_flow_control_tb();
  `TEST_BENCH_INIT("chdr_flow_control_tb", `NUM_TEST_CASES, `NS_PER_TICK);

  `DEFINE_CLK(clk, 10.000, 50);
  `DEFINE_RESET(rst, 0, 100);

  localparam CHDR_W = 64;
  localparam INGRESS_BUFF_SIZE = 11;
  localparam MTU = 8;
  localparam INPUT_FLUSH_TIMEOUT_W = 5;
  localparam LOSSY = 1;
 
  wire [CHDR_W-1:0] chdr_tdata, msg_tdata, data_tdata;
  wire              chdr_tlast, chdr_tvalid, chdr_tready;
  wire              msg_tlast, msg_tvalid, msg_tready;
  wire              data_tlast, data_tvalid, data_tready;

  axis_master #(.DWIDTH(CHDR_W)) m_data (.clk(clk));
  axis_slave  #(.DWIDTH(CHDR_W)) s_data (.clk(clk));

  // RW registers
  logic        cfg_start;
  logic        cfg_pending;
  logic        cfg_failed;
  logic [15:0] cfg_this_epid;
  logic [15:0] cfg_dst_epid ;
  logic [39:0] cfg_fc_freq_bytes;
  logic [23:0] cfg_fc_freq_pkts;
  logic [15:0] cfg_fc_headroom_bytes;
  logic [7:0]  cfg_fc_headroom_pkts;
  logic        fc_enabled;
  logic [63:0] capacity_bytes;
  logic [39:0] capacity_pkts;

  axi_fifo #(.WIDTH(CHDR_W+1), .SIZE(1)) in_reg (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({m_data.axis.tlast, m_data.axis.tdata}),
    .i_tvalid(m_data.axis.tvalid), .i_tready(m_data.axis.tready),
    .o_tdata({data_tlast, data_tdata}),
    .o_tvalid(data_tvalid), .o_tready(data_tready),
    .space(), .occupied()
  );

  chdr_stream_output #(
    .CHDR_W(CHDR_W), .MTU(MTU)
  ) strm_output_i (
    .clk                  (clk),
    .rst                  (rst),
    .m_axis_chdr_tdata    (chdr_tdata),
    .m_axis_chdr_tlast    (chdr_tlast),
    .m_axis_chdr_tvalid   (chdr_tvalid),
    .m_axis_chdr_tready   (chdr_tready | LOSSY[0]),
    .s_axis_data_tdata    (data_tdata),
    .s_axis_data_tlast    (data_tlast),
    .s_axis_data_tvalid   (data_tvalid),
    .s_axis_data_tready   (data_tready),
    .s_axis_strs_tdata    (msg_tdata),
    .s_axis_strs_tlast    (msg_tlast),
    .s_axis_strs_tvalid   (msg_tvalid),
    .s_axis_strs_tready   (msg_tready),
    .cfg_start            (cfg_start),
    .cfg_pending          (cfg_pending),
    .cfg_failed           (cfg_failed),
    .cfg_dst_epid         (cfg_dst_epid),
    .cfg_this_epid        (cfg_this_epid),
    .cfg_fc_freq_bytes    (cfg_fc_freq_bytes),
    .cfg_fc_freq_pkts     (cfg_fc_freq_pkts),
    .cfg_fc_headroom_bytes(cfg_fc_headroom_bytes),
    .cfg_fc_headroom_pkts (cfg_fc_headroom_pkts),
    .fc_enabled           (fc_enabled),
    .capacity_bytes       (capacity_bytes),
    .capacity_pkts        (capacity_pkts),
    .seq_err_stb          (),
    .seq_err_cnt          (),
    .data_err_stb         (),
    .data_err_cnt         (),
    .route_err_stb        (),
    .route_err_cnt        ()
  );

  chdr_stream_input #(
    .CHDR_W(CHDR_W), .BUFF_SIZE(INGRESS_BUFF_SIZE),
    .FLUSH_TIMEOUT_W(INPUT_FLUSH_TIMEOUT_W)
  ) strm_input_i (
    .clk                (clk),
    .rst                (rst),
    .s_axis_chdr_tdata  (chdr_tdata),
    .s_axis_chdr_tlast  (chdr_tlast),
    .s_axis_chdr_tvalid (chdr_tvalid),
    .s_axis_chdr_tready (chdr_tready),
    .m_axis_data_tdata  (s_data.axis.tdata),
    .m_axis_data_tlast  (s_data.axis.tlast),
    .m_axis_data_tvalid (s_data.axis.tvalid),
    .m_axis_data_tready (s_data.axis.tready),
    .m_axis_strs_tdata  (msg_tdata),
    .m_axis_strs_tlast  (msg_tlast),
    .m_axis_strs_tvalid (msg_tvalid),
    .m_axis_strs_tready (msg_tready),
    .data_err_stb       (1'b0)
  );

  initial begin : tb_main
    string s;
    logic [15:0] seqnum = 0;
    logic [63:0] counter = 0;

    `TEST_CASE_START("Wait for Reset");
      m_data.reset();
      s_data.reset();
      cfg_start = 1'b0;
      cfg_this_epid = 16'h0;
      cfg_dst_epid = 16'h0;
      cfg_fc_freq_bytes = 40'h0;
      cfg_fc_freq_pkts = 24'h0;
      cfg_fc_headroom_bytes = 16'd0;
      cfg_fc_headroom_pkts = 8'd0;
      while (rst) @(posedge clk);
      @(posedge clk);
    `TEST_CASE_DONE(~rst);

    `TEST_CASE_START("Configure Stream");
      @(negedge clk);
      cfg_this_epid = 16'hDEAD;
      cfg_dst_epid = 16'hBEEF;
      cfg_fc_freq_bytes = 40'd800;
      cfg_fc_freq_pkts = 24'd10;
      cfg_fc_headroom_bytes = 16'd1000;
      cfg_fc_headroom_pkts = 8'd8;
      cfg_start = 1'b1;
      @(negedge clk);
      cfg_start = 1'b0;
      @(posedge clk);
    `TEST_CASE_DONE(1'b1);

    `TEST_CASE_START("Send packets");
      fork
        begin
          repeat (10000) begin
            counter = 0;
            m_data.push_word({6'h0, 3'd6, 7'd0, seqnum, 16'd200, cfg_dst_epid}, 0);
            repeat (23) begin
              m_data.push_word(counter, 0);
              counter = counter + 1;
            end
            m_data.push_word(counter, 1);
            seqnum = seqnum + 1;
          end
        end
        begin
          repeat (10000) @(posedge clk);
          repeat (10000 * 25) begin
            s_data.drop_word();
          end
        end
      join
    `TEST_CASE_DONE(1'b1);

    `TEST_BENCH_DONE;
  end
endmodule
