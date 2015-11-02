//
// Copyright 2015 Ettus Research LLC
//

module noc_block_radio_core #(
  parameter NOC_ID = 64'h12AD_1000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter NUM_RADIOS = 1
)(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  // Ports connected to radio front end
  input  [NUM_RADIOS*32-1:0] rx, input rx_stb,
  output [NUM_RADIOS*32-1:0] tx, input tx_stb,
  // Interfaces to front panel and daughter board
  input pps, output [NUM_RADIOS-1:0] sync,
  input [NUM_RADIOS*32-1:0] misc_ins, output [NUM_RADIOS*32-1:0] misc_outs,
  inout [NUM_RADIOS*32-1:0] fp_gpio, inout [NUM_RADIOS*32-1:0] db_gpio, output [NUM_RADIOS*32-1:0] leds,
  output [NUM_RADIOS*8-1:0] sen, output [NUM_RADIOS-1:0] sclk, output [NUM_RADIOS-1:0] mosi, input [NUM_RADIOS-1:0] miso,
  output [63:0] debug
);

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0]                   set_data;
  wire [7:0]                    set_addr;
  wire [NUM_RADIOS-1:0]         set_stb;
  wire [63:0]                   set_time;
  wire [8*NUM_RADIOS-1:0]       rb_addr;
  wire [64*NUM_RADIOS-1:0]      rb_data;

  wire [63:0]                   cmdout_tdata, ackin_tdata;
  wire                          cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*NUM_RADIOS-1:0]      str_sink_tdata, str_src_tdata;
  wire [NUM_RADIOS-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [NUM_RADIOS-1:0]         clear_tx_seqnum;
  wire [16*NUM_RADIOS-1:0]      src_sid, next_dst_sid, resp_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_RADIOS),
    .OUTPUT_PORTS(NUM_RADIOS),
    .STR_SINK_FIFOSIZE({NUM_RADIOS{STR_SINK_FIFOSIZE[7:0]}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time), .rb_addr(rb_addr), .rb_data(rb_data),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(resp_dst_sid), .resp_out_dst_sid(/* Unused */),
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

  ////////////////////////////////////////////////////////////
  //
  // Radio Cores
  //
  ////////////////////////////////////////////////////////////
  // Radio response packet mux
  axi_mux  #(.WIDTH(64), .BUFFER(1), .SIZE(NUM_RADIOS))
  axi_mux_cmd (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .i_tdata(resp_tdata), .i_tlast(resp_tlast), .i_tvalid(resp_tvalid), .i_tready(resp_tready),
    .o_tdata(cmdout_tdata), .o_tlast(cmdout_tlast), .o_tvalid(cmdout_tvalid), .o_tready(cmdout_tready));

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
        .clear_tx_seqnum(clear_tx_seqnum[i]), // Note: +1 due to block port 0 is for frontend control
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
        .m_axis_config_tready(1'b0));

      radio_core #(
        .BASE(128), // Offset to user register addr space
        .RADIO_NUM(i))
      radio_core (
        .clk(ce_clk), .reset(ce_rst),
        .src_sid(src_sid[16*i+15:16*i]),
        .dst_sid(next_dst_sid[16*i+15:16*i]),
        .resp_dst_sid(resp_dst_sid[16*i+15:16*i]),
        .rx(rx[32*i+31:32*i]), .rx_stb(rx_stb),
        .tx(tx[32*i+31:32*i]), .tx_stb(tx_stb),
        .pps(pps),
        .misc_ins(misc_ins[32*i+31:32*i]), .misc_outs(misc_outs[32*i+31:32*i]), .sync(sync[i]),
        .fp_gpio(fp_gpio[32*i+31:32*i]), .db_gpio(db_gpio[32*i+31:32*i]), .leds(leds[32*i+31:32*i]),
        .sen(sen[8*i+7:8*i]), .sclk(sclk[i]), .mosi(mosi[i]), .miso(miso[i]),
        .set_stb(set_stb[i]), .set_addr(set_addr), .set_data(set_data), .set_time(set_time), .rb_addr(rb_addr[8*i+7:8*i]), .rb_data(rb_data[64*i+63:64*i]),
        .tx_tdata(m_axis_data_tdata[i]), .tx_tlast(m_axis_data_tlast[i]), .tx_tvalid(m_axis_data_tvalid[i]), .tx_tready(m_axis_data_tready[i]), .tx_tuser(m_axis_data_tuser[i]),
        .rx_tdata(s_axis_data_tdata[i]), .rx_tlast(s_axis_data_tlast[i]), .rx_tvalid(s_axis_data_tvalid[i]), .rx_tready(s_axis_data_tready[i]), .rx_tuser(s_axis_data_tuser[i]),
        .resp_tdata(resp_tdata[64*i+63:64*i]), .resp_tlast(resp_tlast[i]), .resp_tvalid(resp_tvalid[i]), .resp_tready(resp_tready[i]));
    end
  endgenerate

endmodule