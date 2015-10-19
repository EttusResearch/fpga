//
// Copyright 2015 Ettus Research LLC
//

module noc_block_radio_core #(
  parameter NOC_ID = 64'h12AD_1000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter NUM_RADIOS = 1,
  parameter BYPASS_TX_DC_OFFSET_CORR = 0,
  parameter BYPASS_RX_DC_OFFSET_CORR = 0,
  parameter BYPASS_TX_IQ_COMP = 0,
  parameter BYPASS_RX_IQ_COMP = 0,
  parameter DEVICE = "7SERIES"
)(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  // Ports connected to hardware
  input  [NUM_RADIOS*32-1:0] rx, input rx_stb,
  output [NUM_RADIOS*32-1:0] tx, input tx_stb,
  // Interface to front end control
  input pps, output [63:0] vita_time, output [NUM_RADIOS-1:0] run_rx, output [NUM_RADIOS-1:0] run_tx,
  output fe_set_stb, output [7:0] fe_set_addr, output [31:0] fe_set_data,  output [63:0] fe_set_time, input [7:0] fe_rb_addr, input [63:0] fe_rb_data,
  output [63:0] debug
);

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  // Block port 0 is used for front end / daughter board settings (no data xfer)
  // Block ports 1-15 are used for radios
  wire [31:0]                   set_data;
  wire [7:0]                    set_addr;
  wire [NUM_RADIOS:0]           set_stb;
  wire [63:0]                   set_time;
  wire [64*(NUM_RADIOS+1)-1:0]  rb_data;

  wire [63:0]                   cmdout_tdata, ackin_tdata;
  wire                          cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*(NUM_RADIOS+1)-1:0]  str_sink_tdata, str_src_tdata;
  wire [NUM_RADIOS:0]           str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [NUM_RADIOS:0]           clear_tx_seqnum;
  wire [16*(NUM_RADIOS+1)-1:0]  src_sid, next_dst_sid, forwarding_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .BLOCK_PORTS(NUM_RADIOS+1),
    // Block port 0 STR_SINK_FIFOSIZE = 0 as it only interacts with control packets and does not need a window buffer for data packets.
    .STR_SINK_FIFOSIZES({8'd0,{NUM_RADIOS{STR_SINK_FIFOSIZE[7:0]}}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time), .rb_data(rb_data),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(src_sid), .next_dst_sid(next_dst_sid), .forwarding_dst_sid(forwarding_dst_sid),
    .debug(debug));

  // Disable unused response port
  assign ackin_tready        = 1'b1;

  wire [31:0]               m_axis_data_tdata[0:NUM_RADIOS-1];
  wire [127:0]              m_axis_data_tuser[0:NUM_RADIOS-1];
  wire [NUM_RADIOS-1:0]     m_axis_data_tlast;
  wire [NUM_RADIOS-1:0]     m_axis_data_tvalid;
  wire [NUM_RADIOS-1:0]     m_axis_data_tready;

  wire [31:0]               s_axis_data_tdata[0:NUM_RADIOS-1];
  wire [127:0]              s_axis_data_tuser[0:NUM_RADIOS-1];
  wire [NUM_RADIOS-1:0]     s_axis_data_tlast;
  wire [NUM_RADIOS-1:0]     s_axis_data_tvalid;
  wire [NUM_RADIOS-1:0]     s_axis_data_tready;

  wire [NUM_RADIOS*64-1:0]  resp_tdata;
  wire [NUM_RADIOS-1:0]     resp_tlast, resp_tvalid, resp_tready;
  wire [NUM_RADIOS-1:0]     run_rx_int, run_tx_int;

  // Frontend control
  localparam SR_FE_READBACK = 255;
  localparam FE_CTRL_BLOCK_PORT = 0;
  assign fe_set_stb = set_stb[FE_CTRL_BLOCK_PORT-1];
  assign fe_set_addr = set_addr;
  assign fe_set_data = set_data;
  assign fe_set_time = set_time;
  assign rb_data[64*FE_CTRL_BLOCK_PORT+63:64*FE_CTRL_BLOCK_PORT] = fe_rb_data;
  // Disable unused data ports for frontend control block port
  assign str_sink_tready[FE_CTRL_BLOCK_PORT] = 1'b1;
  assign str_src_tdata[64*FE_CTRL_BLOCK_PORT+63:64*FE_CTRL_BLOCK_PORT] = 'd0;
  assign str_src_tlast[FE_CTRL_BLOCK_PORT] = 1'b0;
  assign str_src_tvalid[FE_CTRL_BLOCK_PORT] = 1'b0;

  setting_reg #(
    .my_addr(SR_FE_READBACK), .awidth(8), .width(8)) 
  sr_rdback (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(fe_set_stb), .addr(fe_set_addr), .in(fe_set_data), .out(fe_rb_addr), .changed());

  // Radio response packet mux
  axi_mux  #(.WIDTH(64), .BUFFER(1), .SIZE(NUM_RADIOS))
  axi_mux_cmd (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .i_tdata(resp_tdata), .i_tlast(resp_tlast), .i_tvalid(resp_tvalid), .i_tready(resp_tready),
    .o_tdata(cmdout_tdata), .o_tlast(cmdout_tlast), .o_tvalid(cmdout_tvalid), .o_tready(cmdout_tready));

  // VITA time
  localparam [7:0] SR_TIME_HI   = 128;
  localparam [7:0] SR_TIME_LO   = 129;
  localparam [7:0] SR_TIME_CTRL = 130;
  wire [63:0] vita_time_lastpps;
  timekeeper #(
    .SR_TIME_HI(SR_TIME_HI),
    .SR_TIME_LO(SR_TIME_LO),
    .SR_TIME_CTRL(SR_TIME_CTRL))
  timekeeper (
    .clk(ce_clk), .reset(ce_rst), .pps(pps),
    .set_stb(|set_stb[NUM_RADIOS-1:0]), .set_addr(set_addr), .set_data(set_data),
    .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

  genvar i;
  generate
    for (i = 0; i < NUM_RADIOS; i = i + 1) begin : gen
      ////////////////////////////////////////////////////////////
      //
      // AXI Wrapper
      // Convert RFNoC Shell interface into AXI stream interface
      // One per radio interface
      //
      ////////////////////////////////////////////////////////////
      axi_wrapper #(
        .SIMPLE_MODE(0))
      axi_wrapper (
        .clk(ce_clk), .reset(ce_rst),
        .clear_tx_seqnum(clear_tx_seqnum[i+1]), // Note: +1 due to block port 0 is for frontend control
        .next_dst(next_dst_sid[16*(i+1)+15:16*(i+1)]),
        .set_stb(1'b0), .set_addr(8'd0), .set_data(32'd0),
        .i_tdata(str_sink_tdata[64*(i+1)+63:64*(i+1)]), .i_tlast(str_sink_tlast[i+1]), .i_tvalid(str_sink_tvalid[i+1]), .i_tready(str_sink_tready[i+1]),
        .o_tdata(str_src_tdata[64*(i+1)+63:64*(i+1)]), .o_tlast(str_src_tlast[i+1]), .o_tvalid(str_src_tvalid[i+1]), .o_tready(str_src_tready[i+1]),
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
        .m_axis_config_tready(1'b0));

      ////////////////////////////////////////////////////////////
      //
      // Radio Core
      //
      ////////////////////////////////////////////////////////////
      radio_core #(
        .BASE(128), // Offset to user register addr space
        .RADIO_NUM(i),
        .BYPASS_TX_DC_OFFSET_CORR(BYPASS_TX_DC_OFFSET_CORR),
        .BYPASS_RX_DC_OFFSET_CORR(BYPASS_RX_DC_OFFSET_CORR),
        .BYPASS_TX_IQ_COMP(BYPASS_TX_IQ_COMP),
        .BYPASS_RX_IQ_COMP(BYPASS_RX_IQ_COMP),
        .DEVICE(DEVICE))
      radio_core (
        .clk(ce_clk), .reset(ce_rst),
        .src_sid(src_sid[16*(i+1)+15:16*(i+1)]),
        .dst_sid(next_dst_sid[16*(i+1)+15:16*(i+1)]),
        .forwarding_dst_sid(forwarding_dst_sid[16*(i+1)+15:16*(i+1)]),
        .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
        .rx(rx[32*i+31:32*i]), .rx_stb(rx_stb), .run_rx(run_rx[i]),
        .tx(tx[32*i+31:32*i]), .tx_stb(tx_stb), .run_tx(run_tx[i]),
        .set_stb(set_stb[i+1]), .set_addr(set_addr), .set_data(set_data), .rb_data(rb_data[64*(i+1)+63:64*(i+1)]),
        .tx_tdata(m_axis_data_tdata[i]), .tx_tlast(m_axis_data_tlast[i]), .tx_tvalid(m_axis_data_tvalid[i]), .tx_tready(m_axis_data_tready[i]), .tx_tuser(m_axis_data_tuser[i]),
        .rx_tdata(s_axis_data_tdata[i]), .rx_tlast(s_axis_data_tlast[i]), .rx_tvalid(s_axis_data_tvalid[i]), .rx_tready(s_axis_data_tready[i]), .rx_tuser(s_axis_data_tuser[i]),
        .resp_tdata(resp_tdata[64*i+63:64*i]), .resp_tlast(resp_tlast[i]), .resp_tvalid(resp_tvalid[i]), .resp_tready(resp_tready[i]));
    end
  endgenerate

endmodule