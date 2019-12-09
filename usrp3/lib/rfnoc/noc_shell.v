//
// Copyright 2016 Ettus Research
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// User parameters:
//   NOC_ID               Unique block ID
//   INPUT_PORTS          Number of input ports, min 1
//   OUTPUT_PORTS         Number of output ports, min 1
//   USE_TIMED_CMDS       Use vita time in command packets for timing settings bus transactions
//   STR_SINK_FIFOSIZE    Vector of each block port's window sizes (size is power of 2, 8-bits per port)
//   MTU                  Vector of maximum output packet sizes (power of 2 size for FIFO used with packet gate, 8-bits per port)
//   USE_GATE_MASK        Bit mask enabling AXI gate per block port (i.e. 3'b101, enable packet gate on block ports 0 & 2.)
//                        Note: AXI gate is only needed for block ports not using AXI wrapper
//
// Advanced user parameters (generally leave at default values):
//   CMD_FIFO_SIZE        Vector of the depth of each block port's command packet FIFO. (8-bits per port)
//   BLOCK_PORTS          max(INPUT_PORTS, OUTPUT_PORTS), DO NOT OVERRIDE! Workaround to properly size port widths.

module noc_shell
  #(parameter [63:0] NOC_ID = 64'hDEAD_BEEF_0123_4567,
    parameter INPUT_PORTS = 1,
    parameter OUTPUT_PORTS = 1,
    parameter USE_TIMED_CMDS = 0,
    parameter [INPUT_PORTS*8-1:0] STR_SINK_FIFOSIZE = {INPUT_PORTS{8'd11}},
    parameter [OUTPUT_PORTS*8-1:0] MTU = {OUTPUT_PORTS{8'd10}},
    parameter [OUTPUT_PORTS-1:0] USE_GATE_MASK = 'd0,
    // Expert settings
    parameter BLOCK_PORTS = (INPUT_PORTS > OUTPUT_PORTS) ? INPUT_PORTS : OUTPUT_PORTS, // DO NOT OVERRIDE!
    parameter [BLOCK_PORTS*8-1:0] CMD_FIFO_SIZE = {BLOCK_PORTS{8'd5}},
    parameter RESP_FIFO_SIZE = 0)
   (// RFNoC interfaces, to Crossbar, all on bus_clk
    input bus_clk, input bus_rst,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,

    // Computation Engine interfaces, all on local clock
    input clk, input reset,

    // Control Sink
    output [BLOCK_PORTS*32-1:0] set_data, output [BLOCK_PORTS*8-1:0] set_addr, output [BLOCK_PORTS-1:0] set_stb,
    output [BLOCK_PORTS*64-1:0] set_time, output [BLOCK_PORTS-1:0] set_has_time,
    input [BLOCK_PORTS-1:0] rb_stb, output [BLOCK_PORTS*8-1:0] rb_addr, input [BLOCK_PORTS*64-1:0] rb_data,

    // Control Source
    input [63:0] cmdout_tdata, input cmdout_tlast, input cmdout_tvalid, output cmdout_tready,
    output [63:0] ackin_tdata, output ackin_tlast, output ackin_tvalid, input ackin_tready,

    // Stream Sink
    output [INPUT_PORTS*64-1:0] str_sink_tdata, output [INPUT_PORTS-1:0] str_sink_tlast,
    output [INPUT_PORTS-1:0] str_sink_tvalid, input [INPUT_PORTS-1:0] str_sink_tready,

    // Stream Source
    input [OUTPUT_PORTS*64-1:0] str_src_tdata, input [OUTPUT_PORTS-1:0] str_src_tlast,
    input [OUTPUT_PORTS-1:0] str_src_tvalid, output [OUTPUT_PORTS-1:0] str_src_tready,

    // Advanced user ports
    input [63:0] vita_time,
    output [OUTPUT_PORTS-1:0] clear_tx_seqnum,       // Clear TX Sequence Number, one per output port
    output [BLOCK_PORTS*16-1:0] src_sid,             // Stream ID of block port, one per input and/or output port
    output [OUTPUT_PORTS*16-1:0] next_dst_sid,       // Stream ID of downstream block, one per output port
    output [INPUT_PORTS*16-1:0] resp_in_dst_sid,     // Stream IDs to forward errors / special messages, one per input
    output [OUTPUT_PORTS*16-1:0] resp_out_dst_sid,   // and one per output port

    output [63:0] debug
    );

   `include "noc_shell_regs.vh"
   `include "chdr_pkt_types.vh"

   localparam RB_AWIDTH = 3;
   localparam [31:0] NOC_SHELL_MAJOR_COMPAT_NUM = 32'd6;
   localparam [31:0] NOC_SHELL_MINOR_COMPAT_NUM = 32'd0;

   wire [63:0] fcin_tdata, fcout_tdata, cmdin_tdata, ackout_tdata;
   wire fcin_tlast, fcout_tlast, cmdin_tlast, ackout_tlast;
   wire fcin_tvalid, fcout_tvalid, cmdin_tvalid, ackout_tvalid;
   wire fcin_tready, fcout_tready, cmdin_tready, ackout_tready;

   wire [63:0] dataout_tdata, datain_tdata, dataout_post_tdata, datain_pre_tdata;
   wire dataout_tlast, datain_tlast, dataout_post_tlast, datain_pre_tlast;
   wire dataout_tvalid, datain_tvalid, dataout_post_tvalid, datain_pre_tvalid;
   wire dataout_tready, datain_tready, dataout_post_tready, datain_pre_tready;

   wire [63:0] cmdout_tdata_bclk, ackout_tdata_bclk, ackin_tdata_bclk, cmdin_tdata_bclk;
   wire cmdout_tlast_bclk, ackout_tlast_bclk, ackin_tlast_bclk, cmdin_tlast_bclk;
   wire cmdout_tvalid_bclk, ackout_tvalid_bclk, ackin_tvalid_bclk, cmdin_tvalid_bclk;
   wire cmdout_tready_bclk, ackout_tready_bclk, ackin_tready_bclk, cmdin_tready_bclk;

   ///////////////////////////////////////////////////////////////////////////////////////
   // 2-clock fifos get cmd/ack ports into ce_clk domain
   ///////////////////////////////////////////////////////////////////////////////////////

   axi_fifo_2clk #(.WIDTH(65), .SIZE(5)) ackin_2clk_i   // Very little buffering needed here, only a clock domain crossing
     (.reset(bus_rst),
      .i_aclk(bus_clk), 
      .i_tvalid(ackin_tvalid_bclk), .i_tready(ackin_tready_bclk), .i_tdata({ackin_tlast_bclk, ackin_tdata_bclk}),
      .o_aclk(clk),
      .o_tvalid(ackin_tvalid), .o_tready(ackin_tready), .o_tdata({ackin_tlast,ackin_tdata}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(5)) cmdin_2clk_i   // Very little buffering needed here, only a clock domain crossing
     (.reset(bus_rst),
      .i_aclk(bus_clk), 
      .i_tvalid(cmdin_tvalid_bclk), .i_tready(cmdin_tready_bclk), .i_tdata({cmdin_tlast_bclk, cmdin_tdata_bclk}),
      .o_aclk(clk),
      .o_tvalid(cmdin_tvalid), .o_tready(cmdin_tready), .o_tdata({cmdin_tlast,cmdin_tdata}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(5)) ackout_2clk_i
     (.reset(reset),
      .i_aclk(clk),
      .i_tvalid(ackout_tvalid), .i_tready(ackout_tready), .i_tdata({ackout_tlast,ackout_tdata}),
      .o_aclk(bus_clk),
      .o_tvalid(ackout_tvalid_bclk), .o_tready(ackout_tready_bclk), .o_tdata({ackout_tlast_bclk,ackout_tdata_bclk}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(5)) cmdout_2clk_i
     (.reset(reset),
      .i_aclk(clk),
      .i_tvalid(cmdout_tvalid), .i_tready(cmdout_tready), .i_tdata({cmdout_tlast,cmdout_tdata}),
      .o_aclk(bus_clk),
      .o_tvalid(cmdout_tvalid_bclk), .o_tready(cmdout_tready_bclk), .o_tdata({cmdout_tlast_bclk,cmdout_tdata_bclk}));

   ///////////////////////////////////////////////////////////////////////////////////////
   // Mux and Demux to join/split streams going to/coming from RFNoC
   ///////////////////////////////////////////////////////////////////////////////////////
   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) output_mux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata(dataout_post_tdata), .i0_tlast(dataout_post_tlast), .i0_tvalid(dataout_post_tvalid), .i0_tready(dataout_post_tready),
      .i1_tdata(fcout_tdata), .i1_tlast(fcout_tlast), .i1_tvalid(fcout_tvalid), .i1_tready(fcout_tready),
      .i2_tdata(cmdout_tdata_bclk), .i2_tlast(cmdout_tlast_bclk), .i2_tvalid(cmdout_tvalid_bclk), .i2_tready(cmdout_tready_bclk),
      .i3_tdata(ackout_tdata_bclk), .i3_tlast(ackout_tlast_bclk), .i3_tvalid(ackout_tvalid_bclk), .i3_tready(ackout_tready_bclk),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

   wire [63:0] vheader;
   // Switch by packet type
   // Note: EOB is masked (i.e. ignored) except in the case for FC ACK
   wire [2:0] pkt_type_in = {vheader[63:62],vheader[60]};
   reg  [1:0] vdest;

   always @(*) begin
     case (pkt_type_in)
       DATA_PKT     : vdest = 2'd0;
       DATA_EOB_PKT : vdest = 2'd0;
       FC_RESP_PKT  : vdest = 2'd1;
       FC_ACK_PKT   : vdest = 2'd0; // FC ACK **must** remain in-line with data packets since it is FC'd
       CMD_PKT      : vdest = 2'd2;
       CMD_EOB_PKT  : vdest = 2'd2;
       RESP_PKT     : vdest = 2'd3;
       RESP_ERR_PKT : vdest = 2'd3;
       default      : vdest = 2'd0;
     endcase
   end

   axi_demux4 #(.ACTIVE_CHAN(4'b1111), .WIDTH(64)) input_demux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o0_tdata(datain_pre_tdata), .o0_tlast(datain_pre_tlast), .o0_tvalid(datain_pre_tvalid), .o0_tready(datain_pre_tready),
      .o1_tdata(fcin_tdata), .o1_tlast(fcin_tlast), .o1_tvalid(fcin_tvalid), .o1_tready(fcin_tready),
      .o2_tdata(cmdin_tdata_bclk), .o2_tlast(cmdin_tlast_bclk), .o2_tvalid(cmdin_tvalid_bclk), .o2_tready(cmdin_tready_bclk),
      .o3_tdata(ackin_tdata_bclk), .o3_tlast(ackin_tlast_bclk), .o3_tvalid(ackin_tvalid_bclk), .o3_tready(ackin_tready_bclk));

   ///////////////////////////////////////////////////////////////////////////////////////
   // Datapath gatekeepers
   ///////////////////////////////////////////////////////////////////////////////////////
   wire         flush_datain, flush_dataout, flush_datain_bclk, flush_dataout_bclk;
   wire [15:0]  datain_pkt_cnt, dataout_pkt_cnt, datain_pkt_cnt_bclk, dataout_pkt_cnt_bclk;

   datapath_gatekeeper #(
      .WIDTH(64), .COUNT_W(16)
   ) keeper_in_i (
      .clk(bus_clk), .reset(bus_rst),
      .s_axis_tdata(datain_pre_tdata), .s_axis_tlast(datain_pre_tlast),
      .s_axis_tvalid(datain_pre_tvalid), .s_axis_tready(datain_pre_tready),
      .m_axis_tdata(datain_tdata), .m_axis_tlast(datain_tlast),
      .m_axis_tvalid(datain_tvalid), .m_axis_tready(datain_tready),
      .flush(flush_datain_bclk), .flushing(), .pkt_count(datain_pkt_cnt_bclk)
   );

   datapath_gatekeeper #(
      .WIDTH(64), .COUNT_W(16)
   ) keeper_out_i (
      .clk(bus_clk), .reset(bus_rst),
      .s_axis_tdata(dataout_tdata), .s_axis_tlast(dataout_tlast),
      .s_axis_tvalid(dataout_tvalid), .s_axis_tready(dataout_tready),
      .m_axis_tdata(dataout_post_tdata), .m_axis_tlast(dataout_post_tlast),
      .m_axis_tvalid(dataout_post_tvalid), .m_axis_tready(dataout_post_tready),
      .flush(flush_dataout_bclk), .flushing(), .pkt_count(dataout_pkt_cnt_bclk)
   );

   synchronizer #( .INITIAL_VAL(0), .WIDTH(2) ) flush_sync_i (
      .clk(bus_clk), .rst(1'b0),
      .in({flush_datain, flush_dataout}), .out({flush_datain_bclk, flush_dataout_bclk})
   );

   axi_fifo_2clk #(.WIDTH(32), .SIZE(5)) data_cnt_2clk_i (.reset(reset),
      .i_aclk(bus_clk),
      .i_tvalid(1'b1), .i_tready(), .i_tdata({datain_pkt_cnt_bclk, dataout_pkt_cnt_bclk}),
      .o_aclk(clk),
      .o_tvalid(), .o_tready(1'b1), .o_tdata({datain_pkt_cnt, dataout_pkt_cnt})
   );

   ///////////////////////////////////////////////////////////////////////////////////////
   // Control Sink
   ///////////////////////////////////////////////////////////////////////////////////////

   wire [INPUT_PORTS-1:0] clear_rx_stb, clear_rx_stb_bclk;
   wire [OUTPUT_PORTS-1:0] clear_tx_stb, clear_tx_stb_bclk;
   wire [INPUT_PORTS-1:0] clear_rx_flush, clear_rx_clear, clear_rx_trig;
   wire [OUTPUT_PORTS-1:0] clear_tx_flush, clear_tx_clear, clear_tx_trig;

   assign flush_datain = |clear_rx_flush;
   assign flush_dataout = |clear_tx_flush;

   wire [64*BLOCK_PORTS-1:0] cmdin_ports_tdata;
   wire [BLOCK_PORTS-1:0]    cmdin_ports_tvalid, cmdin_ports_tready, cmdin_ports_tlast;
   wire [64*BLOCK_PORTS-1:0] ackout_ports_tdata;
   wire [BLOCK_PORTS-1:0]    ackout_ports_tvalid, ackout_ports_tready, ackout_ports_tlast;
   wire [63:0] cmd_header;

  wire [BLOCK_PORTS*32-1:0] set_data_bclk;
  wire [BLOCK_PORTS*8-1:0]  set_addr_bclk;
  wire [BLOCK_PORTS-1:0]    set_stb_bclk;

   genvar k;
   generate
     // Demux command packets to each block port's command packet processor
     axi_demux #(.WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0), .SIZE(BLOCK_PORTS)) axi_demux (
       .clk(clk), .reset(reset), .clear(1'b0),
       .header(cmd_header), .dest(cmd_header[3:0]),
       .i_tdata(cmdin_tdata), .i_tlast(cmdin_tlast), .i_tvalid(cmdin_tvalid), .i_tready(cmdin_tready),
       .o_tdata(cmdin_ports_tdata), .o_tlast(cmdin_ports_tlast), .o_tvalid(cmdin_ports_tvalid), .o_tready(cmdin_ports_tready));
     // Mux responses from each command packet processor
     axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(RESP_FIFO_SIZE), .POST_FIFO_SIZE(0), .SIZE(BLOCK_PORTS)) axi_mux (
       .clk(clk), .reset(reset), .clear(1'b0),
       .i_tdata(ackout_ports_tdata), .i_tlast(ackout_ports_tlast), .i_tvalid(ackout_ports_tvalid), .i_tready(ackout_ports_tready),
       .o_tdata(ackout_tdata), .o_tlast(ackout_tlast), .o_tvalid(ackout_tvalid), .o_tready(ackout_tready));

     for (k = 0; k < BLOCK_PORTS; k = k + 1) begin
       reg rb_stb_int;
       reg [63:0] rb_data_int;
       wire [RB_AWIDTH-1:0] rb_addr_noc_shell;
       cmd_pkt_proc #(
         .SR_AWIDTH(8),
         .SR_DWIDTH(32),
         .RB_AWIDTH(RB_AWIDTH),
         .RB_USER_AWIDTH(8),
         .RB_DWIDTH(64),
         .USE_TIME(USE_TIMED_CMDS),
         .SR_RB_ADDR(SR_RB_ADDR),
         .SR_RB_ADDR_USER(SR_RB_ADDR_USER),
         .DEFAULT_RB_ADDR(RB_USER_RB_DATA),
         .FIFO_SIZE(CMD_FIFO_SIZE[8*k+7:8*k]))
       cmd_pkt_proc (
         .clk(clk), .reset(reset), .clear(1'b0),
         .cmd_tdata(cmdin_ports_tdata[64*k+63:64*k]), .cmd_tlast(cmdin_ports_tlast[k]), .cmd_tvalid(cmdin_ports_tvalid[k]), .cmd_tready(cmdin_ports_tready[k]),
         .resp_tdata(ackout_ports_tdata[64*k+63:64*k]), .resp_tlast(ackout_ports_tlast[k]), .resp_tvalid(ackout_ports_tvalid[k]), .resp_tready(ackout_ports_tready[k]),
         .vita_time(vita_time),
         .set_stb(set_stb[k]), .set_addr(set_addr[8*k+7:8*k]), .set_data(set_data[32*k+31:32*k]),
         .set_time(set_time[64*k+63:64*k]), .set_has_time(set_has_time[k]),
         .rb_stb(rb_stb_int), .rb_data(rb_data_int), .rb_addr(rb_addr_noc_shell), .rb_addr_user(rb_addr[8*k+7:8*k]));

        axi_fifo_2clk #( .WIDTH(32+8), .SIZE(5) ) sett_bus_2clk_i (
          .reset(reset), .i_aclk(clk),
          .i_tdata({set_addr[8*k+7:8*k], set_data[32*k+31:32*k]}), .i_tvalid(set_stb[k]), .i_tready(),
          .o_aclk(bus_clk),
          .o_tdata({set_addr_bclk[8*k+7:8*k], set_data_bclk[32*k+31:32*k]}),
          .o_tvalid(set_stb_bclk[k]), .o_tready(set_stb_bclk[k]));

       localparam [31:0] STR_SINK_FIFO_SIZE_BYTES = (k < INPUT_PORTS) ? 2**(STR_SINK_FIFOSIZE[8*k+7:8*k]+3) : 0;
       // "Lines" is the most useful unit for the command FIFO size, since
       // commands take either 2 or 3 lines. Software can do the rest of the
       // math to figure out how many actual command packets it can send.
       localparam [31:0] CMD_FIFO_SIZE_LINES = 2**CMD_FIFO_SIZE[8*k+7:8*k];

       // Mux NoC Shell and user readback registers
       always @(posedge clk) begin
         if (reset) begin
           rb_stb_int  <= 1'b0;
           rb_data_int <= 64'd0;
         end else begin
           case(rb_addr_noc_shell)
             RB_NOC_ID               : {rb_stb_int, rb_data_int} <= {     1'b1, NOC_ID};
             RB_GLOBAL_PARAMS        : {rb_stb_int, rb_data_int} <= {     1'b1, {datain_pkt_cnt, dataout_pkt_cnt, 16'd0, 3'd0, INPUT_PORTS[4:0], 3'd0, OUTPUT_PORTS[4:0]}};
             RB_FIFOSIZE             : {rb_stb_int, rb_data_int} <= {     1'b1, {CMD_FIFO_SIZE_LINES, STR_SINK_FIFO_SIZE_BYTES}};
             RB_MTU                  : {rb_stb_int, rb_data_int} <= {     1'b1, {k < OUTPUT_PORTS ? MTU[8*k+7:8*k]              : 64'd0}};
             RB_BLOCK_PORT_SIDS      : {rb_stb_int, rb_data_int} <= {     1'b1, {src_sid[16*k+15:16*k],
                                                                                k < OUTPUT_PORTS ? next_dst_sid[16*k+15:16*k]     : 16'd0,
                                                                                k < INPUT_PORTS  ? resp_in_dst_sid[16*k+15:16*k]  : 16'd0,
                                                                                k < OUTPUT_PORTS ? resp_out_dst_sid[16*k+15:16*k] : 16'd0}};
             RB_USER_RB_DATA         : {rb_stb_int, rb_data_int} <= {rb_stb[k], rb_data[64*k+63:64*k]};
             RB_NOC_SHELL_COMPAT_NUM : {rb_stb_int, rb_data_int} <= {     1'b1, {NOC_SHELL_MAJOR_COMPAT_NUM, NOC_SHELL_MINOR_COMPAT_NUM}};
             default                 : {rb_stb_int, rb_data_int} <= {     1'b1, 64'h0BADC0DE0BADC0DE};
           endcase
           // Always clear strobe after settings bus transaction to avoid using stale readback data.
           // Note: This is necessary because we are registering the readback mux output.
           if (set_stb[k]) rb_stb_int <= 1'b0;
         end
       end

       // Stream ID of this RFNoC block
       setting_reg #(.my_addr(SR_SRC_SID), .width(16), .at_reset(0)) sr_block_sid
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
          .in(set_data[32*k+31:32*k]),.out(src_sid[16*k+15:16*k]),.changed());

       if (k < INPUT_PORTS) begin
         setting_reg #(.my_addr(SR_CLEAR_RX_FC), .width(2), .at_reset(0)) sr_clear_rx_fc
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
            .in(set_data[32*k+31:32*k]),.out({clear_rx_flush[k], clear_rx_clear[k]}),.changed(clear_rx_trig[k]));
         assign clear_rx_stb[k] = clear_rx_clear[k] & clear_rx_trig[k];
         setting_reg #(.my_addr(SR_RESP_IN_DST_SID), .width(16), .at_reset(0)) sr_resp_in_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
            .in(set_data[32*k+31:32*k]),.out(resp_in_dst_sid[16*k+15:16*k]),.changed());

         pulse_synchronizer clear_rx_stb_sync_i
           (.clk_a(clk), .rst_a(reset), .pulse_a(clear_rx_stb[k]), .busy_a(/*Ignored: Pulses from SW are slow*/),
            .clk_b(bus_clk), .pulse_b(clear_rx_stb_bclk[k]));
       end

       if (k < OUTPUT_PORTS) begin
         // Clearing the flow control window can also be used to reset the sequence number
         setting_reg #(.my_addr(SR_CLEAR_TX_FC), .width(2), .at_reset(0)) sr_clear_tx_fc
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
            .in(set_data[32*k+31:32*k]),.out({clear_tx_flush[k], clear_tx_clear[k]}),.changed(clear_tx_trig[k]));
         assign clear_tx_stb[k] = clear_tx_clear[k] & clear_tx_trig[k];
         // Destination Stream ID of the next RFNoC block
         setting_reg #(.my_addr(SR_NEXT_DST_SID), .width(16), .at_reset(0)) sr_next_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
            .in(set_data[32*k+31:32*k]),.out(next_dst_sid[16*k+15:16*k]),.changed());
         setting_reg #(.my_addr(SR_RESP_OUT_DST_SID), .width(16), .at_reset(0)) sr_resp_out_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr[8*k+7:8*k]),
            .in(set_data[32*k+31:32*k]),.out(resp_out_dst_sid[16*k+15:16*k]),.changed());

         pulse_synchronizer clear_tx_stb_sync_i
           (.clk_a(clk), .rst_a(reset), .pulse_a(clear_tx_stb[k]), .busy_a(/*Ignored: Pulses from SW are slow*/),
            .clk_b(bus_clk), .pulse_b(clear_tx_stb_bclk[k]));
         assign clear_tx_seqnum[k] = clear_tx_stb[k];

       end
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Source
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*OUTPUT_PORTS-1:0] dataout_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    dataout_ports_tvalid, dataout_ports_tready, dataout_ports_tlast;

   wire [64*OUTPUT_PORTS-1:0] fcin_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    fcin_ports_tvalid, fcin_ports_tready, fcin_ports_tlast;

   wire [63:0]               header_fcin;

   genvar i;
   generate
     for (i=0 ; i < OUTPUT_PORTS ; i = i + 1) begin : gen_noc_output_port
       noc_output_port #(
         .SR_FLOW_CTRL_EN(SR_FLOW_CTRL_EN),
         .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
         .SR_FLOW_CTRL_PKT_LIMIT(SR_FLOW_CTRL_PKT_LIMIT),
         .PORT_NUM(i), .MTU(MTU[8*i+7:8*i]), .USE_GATE(USE_GATE_MASK[i]))
       noc_output_port (
         .clk(bus_clk), .reset(bus_rst), .clear(clear_tx_stb_bclk[i]),
         .set_stb(set_stb_bclk[i]), .set_addr(set_addr_bclk[8*i+7:8*i]), .set_data(set_data_bclk[32*i+31:32*i]),
         .dataout_tdata(dataout_ports_tdata[64*i+63:64*i]), .dataout_tlast(dataout_ports_tlast[i]),
         .dataout_tvalid(dataout_ports_tvalid[i]), .dataout_tready(dataout_ports_tready[i]),
         .fcin_tdata(fcin_ports_tdata[64*i+63:64*i]), .fcin_tlast(fcin_ports_tlast[i]),
         .fcin_tvalid(fcin_ports_tvalid[i]), .fcin_tready(fcin_ports_tready[i]),
         .str_src_tdata(str_src_tdata[64*i+63:64*i]), .str_src_tlast(str_src_tlast[i]),
         .str_src_tvalid(str_src_tvalid[i]), .str_src_tready(str_src_tready[i]));
     end

     if (OUTPUT_PORTS == 1) begin
       assign dataout_tdata        = dataout_ports_tdata;
       assign dataout_tlast        = dataout_ports_tlast;
       assign dataout_tvalid       = dataout_ports_tvalid;
       assign dataout_ports_tready = dataout_tready;
       assign fcin_ports_tdata     = fcin_tdata;
       assign fcin_ports_tlast     = fcin_tlast;
       assign fcin_ports_tvalid    = fcin_tvalid;
       assign fcin_tready          = fcin_ports_tready;
     end else begin
       axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1), .SIZE(OUTPUT_PORTS)) axi_mux (
         .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
         .i_tdata(dataout_ports_tdata), .i_tlast(dataout_ports_tlast), .i_tvalid(dataout_ports_tvalid), .i_tready(dataout_ports_tready),
         .o_tdata(dataout_tdata), .o_tlast(dataout_tlast), .o_tvalid(dataout_tvalid), .o_tready(dataout_tready));
       axi_demux #(.WIDTH(64), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0), .SIZE(OUTPUT_PORTS)) axi_demux (
         .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
         .header(header_fcin), .dest(header_fcin[3:0]),
         .i_tdata(fcin_tdata), .i_tlast(fcin_tlast), .i_tvalid(fcin_tvalid), .i_tready(fcin_tready),
         .o_tdata(fcin_ports_tdata), .o_tlast(fcin_ports_tlast), .o_tvalid(fcin_ports_tvalid), .o_tready(fcin_ports_tready));
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*INPUT_PORTS-1:0] datain_ports_tdata;
   wire [INPUT_PORTS-1:0]    datain_ports_tvalid, datain_ports_tready, datain_ports_tlast;

   wire [64*INPUT_PORTS-1:0] fcout_ports_tdata;
   wire [INPUT_PORTS-1:0]    fcout_ports_tvalid, fcout_ports_tready, fcout_ports_tlast;

   wire [63:0]               header_datain;

   wire [BLOCK_PORTS*16-1:0] src_sid_bclk;
   wire [INPUT_PORTS*16-1:0] resp_in_dst_sid_bclk;

   axi_fifo_2clk #( .WIDTH(16*(BLOCK_PORTS+INPUT_PORTS)), .SIZE(0)) sid_settings_2clk_i (
     .reset(reset), .i_aclk(clk),
     .i_tdata({src_sid, resp_in_dst_sid}), .i_tvalid(1'b1), .i_tready(),
     .o_aclk(bus_clk),
     .o_tdata({src_sid_bclk, resp_in_dst_sid_bclk}), .o_tvalid(), .o_tready(1'b1));

   genvar j;
   generate
     for(j=0; j<INPUT_PORTS; j=j+1) begin : gen_noc_input_port
       noc_input_port #(
         .SR_FLOW_CTRL_BYTES_PER_ACK(SR_FLOW_CTRL_BYTES_PER_ACK),
         .SR_ERROR_POLICY(SR_ERROR_POLICY),
         .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE[8*j+7:8*j]))
       noc_input_port (
         .clk(bus_clk), .reset(bus_rst), .clear(clear_rx_stb_bclk[j]),
         .resp_sid({src_sid_bclk[16*j+15:16*j],resp_in_dst_sid_bclk[16*j+15:16*j]}),
         .set_stb(set_stb_bclk[j]), .set_addr(set_addr_bclk[8*j+7:8*j]), .set_data(set_data_bclk[32*j+31:32*j]),
         .i_tdata(datain_ports_tdata[64*j+63:64*j]), .i_tlast(datain_ports_tlast[j]),
         .i_tvalid(datain_ports_tvalid[j]), .i_tready(datain_ports_tready[j]),
         .o_tdata(str_sink_tdata[64*j+63:64*j]), .o_tlast(str_sink_tlast[j]),
         .o_tvalid(str_sink_tvalid[j]), .o_tready(str_sink_tready[j]),
         .fc_tdata(fcout_ports_tdata[64*j+63:64*j]), .fc_tlast(fcout_ports_tlast[j]),
         .fc_tvalid(fcout_ports_tvalid[j]), .fc_tready(fcout_ports_tready[j]));
     end

     if (INPUT_PORTS == 1) begin
       assign datain_ports_tdata  = datain_tdata;
       assign datain_ports_tlast  = datain_tlast;
       assign datain_ports_tvalid = datain_tvalid;
       assign datain_tready       = datain_ports_tready;
       assign fcout_tdata         = fcout_ports_tdata;
       assign fcout_tlast         = fcout_ports_tlast;
       assign fcout_tvalid        = fcout_ports_tvalid;
       assign fcout_ports_tready  = fcout_tready;
     end else begin
       axi_demux #(.WIDTH(64), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0), .SIZE(INPUT_PORTS)) axi_demux (
         .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
         .header(header_datain), .dest(header_datain[3:0]),
         .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
         .o_tdata(datain_ports_tdata), .o_tlast(datain_ports_tlast), .o_tvalid(datain_ports_tvalid), .o_tready(datain_ports_tready));
       axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1), .SIZE(INPUT_PORTS)) axi_mux (
         .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
         .i_tdata(fcout_ports_tdata), .i_tlast(fcout_ports_tlast), .i_tvalid(fcout_ports_tvalid), .i_tready(fcout_ports_tready),
         .o_tdata(fcout_tdata), .o_tlast(fcout_tlast), .o_tvalid(fcout_tvalid), .o_tready(fcout_tready));
     end
   endgenerate

   assign debug = 64'h0;

endmodule // noc_shell
