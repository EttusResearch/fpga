//
// Copyright 2016 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Note: Register addresses defined radio_core_regs.vh

module noc_block_radio_core #(
  parameter NOC_ID = 64'h12AD_1000_0000_0000,
  parameter NUM_CHANNELS = 1,
  parameter WIDTH = 32,                          // Num bits width of the AXI stream data (can be 32 or 64)
  parameter STR_SINK_FIFOSIZE = {NUM_CHANNELS{8'd11}},
  parameter COMPAT_NUM_MAJOR  = 32'h1,
  parameter COMPAT_NUM_MINOR  = 32'h0,
  parameter MTU = 10                             //Log2 of maximum packet size (in 8-byte words)
)(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  // Output timed settings bus, one per radio
  output [NUM_CHANNELS-1:0] db_fe_set_stb, output [NUM_CHANNELS*8-1:0] db_fe_set_addr, output [NUM_CHANNELS*32-1:0] db_fe_set_data,
  input  [NUM_CHANNELS-1:0] db_fe_rb_stb,  output [NUM_CHANNELS*8-1:0] db_fe_rb_addr,  input  [NUM_CHANNELS*64-1:0] db_fe_rb_data,
  // Ports connected to radio front end
  input  [NUM_CHANNELS*WIDTH-1:0] rx, input [NUM_CHANNELS-1:0] rx_stb, output [NUM_CHANNELS-1:0] rx_running,
  output [NUM_CHANNELS*WIDTH-1:0] tx, input [NUM_CHANNELS-1:0] tx_stb, output [NUM_CHANNELS-1:0] tx_running,
  // Interfaces to front panel and daughter board
  input pps, input sync_in, output sync_out,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [NUM_CHANNELS*32-1:0]      set_data;
  wire [NUM_CHANNELS*8-1:0]       set_addr;
  wire [NUM_CHANNELS-1:0]         set_stb;
  wire [8*NUM_CHANNELS-1:0]       rb_addr;
  wire [64*NUM_CHANNELS-1:0]      rb_data;
  wire [NUM_CHANNELS-1:0]         rb_stb, rb_holdoff;

  wire [63:0]                     cmdout_tdata, ackin_tdata;
  wire                            cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*NUM_CHANNELS-1:0]      str_sink_tdata, str_src_tdata;
  wire [NUM_CHANNELS-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [63:0]                     vita_time;
  wire [NUM_CHANNELS-1:0]         clear_tx_seqnum;
  wire [16*NUM_CHANNELS-1:0]      src_sid, next_dst_sid, resp_in_dst_sid, resp_out_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_CHANNELS),
    .OUTPUT_PORTS(NUM_CHANNELS),
    .STR_SINK_FIFOSIZE({NUM_CHANNELS{STR_SINK_FIFOSIZE[7:0]}}),
    .MTU({NUM_CHANNELS{MTU[7:0]}}),
    .USE_TIMED_CMDS(1), // Settings bus transactions will occur at the vita time specified in the command packet
    .CMD_FIFO_SIZE({NUM_CHANNELS{8'd8}}), // Up to 128 commands in flight per radio (256/2 lines per command packet = 128 untimed commands, 256/3 timed)
    .RESP_FIFO_SIZE(5)) // Provide buffering for responses to prevent mux from back pressuring
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Compute Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(), .set_has_time(),
    .rb_stb(rb_stb), .rb_addr(rb_addr), .rb_data(rb_data),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .vita_time(vita_time), .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(resp_in_dst_sid), .resp_out_dst_sid(resp_out_dst_sid),
    .debug(debug)
  );

  // Disable unused response port
  assign ackin_tready        = 1'b1;

  wire [WIDTH-1:0]            m_axis_data_tdata[0:NUM_CHANNELS-1];
  wire [127:0]                m_axis_data_tuser[0:NUM_CHANNELS-1];
  wire [NUM_CHANNELS-1:0]     m_axis_data_tlast;
  wire [NUM_CHANNELS-1:0]     m_axis_data_tvalid;
  wire [NUM_CHANNELS-1:0]     m_axis_data_tready;

  wire [WIDTH-1:0]            s_axis_data_tdata[0:NUM_CHANNELS-1];
  wire [127:0]                s_axis_data_tuser[0:NUM_CHANNELS-1];
  wire [NUM_CHANNELS-1:0]     s_axis_data_tlast;
  wire [NUM_CHANNELS-1:0]     s_axis_data_tvalid;
  wire [NUM_CHANNELS-1:0]     s_axis_data_tready;

  wire [NUM_CHANNELS*64-1:0]  resp_tdata;
  wire [NUM_CHANNELS-1:0]     resp_tlast, resp_tvalid, resp_tready;

  ////////////////////////////////////////////////////////////
  //
  // Radio Cores
  //
  ////////////////////////////////////////////////////////////
  // Radio response packet mux
  axi_mux  #(.WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1), .SIZE(NUM_CHANNELS))
  axi_mux_cmd (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .i_tdata(resp_tdata), .i_tlast(resp_tlast), .i_tvalid(resp_tvalid), .i_tready(resp_tready),
    .o_tdata(cmdout_tdata), .o_tlast(cmdout_tlast), .o_tvalid(cmdout_tvalid), .o_tready(cmdout_tready)
  );

  // Mux settings buses for any resources shared between radio cores
  wire                     set_stb_mux;
  wire [7:0]               set_addr_mux;
  wire [31:0]              set_data_mux;
  settings_bus_mux #(
    .AWIDTH(8),
    .DWIDTH(32),
    .NUM_BUSES(NUM_CHANNELS))
  settings_bus_mux (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .in_set_stb(set_stb), .in_set_addr(set_addr), .in_set_data(set_data),
    .out_set_stb(set_stb_mux), .out_set_addr(set_addr_mux), .out_set_data(set_data_mux), .ready(1'b1)
  );

  // VITA time is shared between radio cores
  `include "radio_core_regs.vh"
  wire [63:0] vita_time_lastpps;
  timekeeper #(
    .SR_TIME_HI(SR_TIME_HI),
    .SR_TIME_LO(SR_TIME_LO),
    .SR_TIME_CTRL(SR_TIME_CTRL),
    .INCREMENT(WIDTH == 64 ? 64'h2 : 64'h1))
  timekeeper (
    .clk(ce_clk), .reset(ce_rst), .pps(pps), .sync_in(sync_in), .strobe(rx_stb[0]),
    .set_stb(set_stb_mux), .set_addr(set_addr_mux), .set_data(set_data_mux),
    .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
    .sync_out(sync_out)
  );


  wire [64*NUM_CHANNELS-1:0] rb_data_dp;
  wire [NUM_CHANNELS-1:0]    rb_stb_dp;

  // Expose settings bus externally
  assign db_fe_set_stb  = set_addr >= SR_DB_FE_BASE ? set_stb : 1'b0;
  assign db_fe_set_addr = set_addr;
  assign db_fe_set_data = set_data;
  assign db_fe_rb_addr  = rb_addr;

  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : gen
      ////////////////////////////////////////////////////////////
      //
      // AXI Wrapper
      // Convert RFNoC Shell interface into AXI stream interface
      // One per radio interface
      //
      ////////////////////////////////////////////////////////////
      axi_wrapper #(
        .MTU(MTU),
        .SIMPLE_MODE(0),
        .USE_SEQ_NUM(1),
        .WIDTH(WIDTH))
      axi_wrapper (
        .bus_clk(bus_clk), .bus_rst(bus_rst),
        .clk(ce_clk), .reset(ce_rst),
        .clear_tx_seqnum(clear_tx_seqnum[i]),
        .next_dst(next_dst_sid[16*i+15:16*i]),
        .set_stb(1'b0), .set_addr(8'd0), .set_data(32'd0),
        .i_tdata(str_sink_tdata[64*i+63:64*i]), .i_tlast(str_sink_tlast[i]), .i_tvalid(str_sink_tvalid[i]), .i_tready(str_sink_tready[i]),
        .o_tdata(str_src_tdata[64*i+63:64*i]), .o_tlast(str_src_tlast[i]), .o_tvalid(str_src_tvalid[i]), .o_tready(str_src_tready[i]),
        .m_axis_data_tdata(m_axis_data_tdata[i]),
        .m_axis_data_tuser(m_axis_data_tuser[i]),
        .m_axis_data_tlast(m_axis_data_tlast[i]),
        .m_axis_data_tvalid(m_axis_data_tvalid[i]),
        .m_axis_data_tready(m_axis_data_tready[i]),
        .s_axis_data_tdata(s_axis_data_tdata[i]),
        .s_axis_data_tuser(s_axis_data_tuser[i]),
        .s_axis_data_tlast(s_axis_data_tlast[i]),
        .s_axis_data_tvalid(s_axis_data_tvalid[i]),
        .s_axis_data_tready(s_axis_data_tready[i]),
        .m_axis_pkt_len_tdata(),
        .m_axis_pkt_len_tvalid(),
        .m_axis_pkt_len_tready(),
        .m_axis_config_tdata(),
        .m_axis_config_tlast(),
        .m_axis_config_tvalid(),
        .m_axis_config_tready(1'b0)
      );

      radio_datapath_core #(
        .RADIO_NUM(i),
        .WIDTH(WIDTH)
      ) radio_datapath_core_i (
        .clk(ce_clk), .reset(ce_rst),
        .clear_rx(clear_tx_seqnum[i]), .clear_tx(clear_tx_seqnum[i]),
        .src_sid(src_sid[16*i+15:16*i]),
        .dst_sid(next_dst_sid[16*i+15:16*i]),
        .rx_resp_dst_sid(resp_out_dst_sid[16*i+15:16*i]),
        .tx_resp_dst_sid(resp_in_dst_sid[16*i+15:16*i]),
        .rx(rx[WIDTH*i+:WIDTH]), .rx_stb(rx_stb[i]), .rx_running(rx_running[i]),
        .tx(tx[WIDTH*i+:WIDTH]), .tx_stb(tx_stb[i]), .tx_running(tx_running[i]),
        .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
        .set_stb(set_stb[i]), .set_addr(set_addr[8*i+7:8*i]), .set_data(set_data[32*i+31:32*i]),
        .rb_stb(rb_stb_dp[i]), .rb_addr(rb_addr[8*i+7:8*i]), .rb_data(rb_data_dp[64*i+63:64*i]), .rb_holdoff(~db_fe_rb_stb[i]),
        .tx_tdata(m_axis_data_tdata[i]), .tx_tlast(m_axis_data_tlast[i]), .tx_tvalid(m_axis_data_tvalid[i]), .tx_tready(m_axis_data_tready[i]), .tx_tuser(m_axis_data_tuser[i]),
        .rx_tdata(s_axis_data_tdata[i]), .rx_tlast(s_axis_data_tlast[i]), .rx_tvalid(s_axis_data_tvalid[i]), .rx_tready(s_axis_data_tready[i]), .rx_tuser(s_axis_data_tuser[i]),
        .resp_tdata(resp_tdata[64*i+63:64*i]), .resp_tlast(resp_tlast[i]), .resp_tvalid(resp_tvalid[i]), .resp_tready(resp_tready[i])
      );

      assign rb_stb[i]             = db_fe_rb_stb[i] | rb_stb_dp[i];
      assign rb_data[64*i+63:64*i] = (rb_addr[8*i+7:8*i] >= RB_DB_FE_BASE) ? db_fe_rb_data[64*i+63:64*i] :
                                     (rb_addr[8*i+7:8*i] == RB_COMPAT_NUM) ? {COMPAT_NUM_MAJOR, COMPAT_NUM_MINOR} :
                                                                             rb_data_dp[64*i+63:64*i];
    end
  endgenerate
endmodule
