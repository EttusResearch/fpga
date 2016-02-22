//
// Copyright 2016 Ettus Research LLC
//
// Note: Register addresses defined radio_core_regs.vh

module noc_block_radio_core #(
  parameter NOC_ID = 64'h12AD_1000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter NUM_RADIOS = 1,
  // Drive SPI core with input spi_clk instead of ce_clk. This is useful if ce_clk is very slow which
  // would cause spi transactions to take a long time. WARNING: This adds a clock crossing FIFO!
  parameter USE_SPI_CLK = 0
)(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  // Output timed settings bus, one per radio
  output [NUM_RADIOS-1:0] ext_set_stb, output [NUM_RADIOS*8-1:0] ext_set_addr, output [NUM_RADIOS*32-1:0] ext_set_data,
  // Ports connected to radio front end
  input  [NUM_RADIOS*32-1:0] rx, input [NUM_RADIOS-1:0] rx_stb,
  output [NUM_RADIOS*32-1:0] tx, input [NUM_RADIOS-1:0] tx_stb,
  // Interfaces to front panel and daughter board
  input pps, output [NUM_RADIOS-1:0] sync,
  input [NUM_RADIOS*32-1:0] misc_ins, output [NUM_RADIOS*32-1:0] misc_outs,
  input [NUM_RADIOS*32-1:0] fp_gpio_in, output [NUM_RADIOS*32-1:0] fp_gpio_out, output [NUM_RADIOS*32-1:0] fp_gpio_ddr,
  input [NUM_RADIOS*32-1:0] db_gpio_in, output [NUM_RADIOS*32-1:0] db_gpio_out, output [NUM_RADIOS*32-1:0] db_gpio_ddr,
  output [NUM_RADIOS*32-1:0] leds,
  input spi_clk, input spi_rst,
  output [NUM_RADIOS*8-1:0] sen, output [NUM_RADIOS-1:0] sclk, output [NUM_RADIOS-1:0] mosi, input [NUM_RADIOS-1:0] miso,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [NUM_RADIOS*32-1:0]      set_data;
  wire [NUM_RADIOS*8-1:0]       set_addr;
  wire [NUM_RADIOS-1:0]         set_stb;
  wire [NUM_RADIOS*64-1:0]      set_time;
  wire [8*NUM_RADIOS-1:0]       rb_addr;
  wire [64*NUM_RADIOS-1:0]      rb_data;
  wire [NUM_RADIOS-1:0]         rb_stb;

  wire [63:0]                   cmdout_tdata, ackin_tdata;
  wire                          cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*NUM_RADIOS-1:0]      str_sink_tdata, str_src_tdata;
  wire [NUM_RADIOS-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [63:0]                   vita_time;
  wire [NUM_RADIOS-1:0]         clear_tx_seqnum;
  wire [16*NUM_RADIOS-1:0]      src_sid, next_dst_sid, resp_in_dst_sid, resp_out_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_RADIOS),
    .OUTPUT_PORTS(NUM_RADIOS),
    .STR_SINK_FIFOSIZE({NUM_RADIOS{STR_SINK_FIFOSIZE[7:0]}}),
    .USE_TIMED_CMDS(1), // Settings bus transactions will occur at the vita time specified in the command packet
    .CMD_FIFO_SIZE({NUM_RADIOS{8'd6}})) // Up to 64 commands in flight per radio
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time),
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

  localparam BASE = 128;

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

  // Mux settings buses for any resources shared between radio cores
  wire                     set_stb_mux;
  wire [7:0]               set_addr_mux;
  wire [31:0]              set_data_mux;
  settings_bus_mux #(
    .AWIDTH(8),
    .DWIDTH(32),
    .NUM_BUSES(NUM_RADIOS))
  settings_bus_mux (
    .clk(ce_clk), .reset(ce_rst),
    .in_set_stb(set_stb), .in_set_addr(set_addr), .in_set_data(set_data),
    .out_set_stb(set_stb_mux), .out_set_addr(set_addr_mux), .out_set_data(set_data_mux), .ready(1'b1));

  // VITA time is shared between radio cores
  `include "radio_core_regs.vh"
  wire [63:0] vita_time_lastpps;
  timekeeper #(
    .SR_TIME_HI(SR_TIME_HI),
    .SR_TIME_LO(SR_TIME_LO),
    .SR_TIME_CTRL(SR_TIME_CTRL))
  timekeeper (
    .clk(ce_clk), .reset(ce_rst), .pps(pps), .strobe(rx_stb),
    .set_stb(set_stb_mux), .set_addr(set_addr_mux), .set_data(set_data_mux),
    .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

  // Expose settings bus externally
  assign ext_set_stb  = set_stb;
  assign ext_set_addr = set_addr;
  assign ext_set_data = set_data;

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
        .MTU(10),
        .SIMPLE_MODE(0),
        .USE_SEQ_NUM(1))
      axi_wrapper (
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
        .m_axis_config_tready(1'b0));

      radio_core #(
        .RADIO_NUM(i),
        .USE_SPI_CLK(USE_SPI_CLK))
      radio_core (
        .clk(ce_clk), .reset(ce_rst),
        .clear_rx(clear_tx_seqnum[i]), .clear_tx(clear_tx_seqnum[i]),
        .src_sid(src_sid[16*i+15:16*i]),
        .dst_sid(next_dst_sid[16*i+15:16*i]),
        .rx_resp_dst_sid(resp_out_dst_sid[16*i+15:16*i]),
        .tx_resp_dst_sid(resp_in_dst_sid[16*i+15:16*i]),
        .rx(rx[32*i+31:32*i]), .rx_stb(rx_stb[i]),
        .tx(tx[32*i+31:32*i]), .tx_stb(tx_stb[i]),
        .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
        .pps(pps),
        .misc_ins(misc_ins[32*i+31:32*i]), .misc_outs(misc_outs[32*i+31:32*i]), .sync(sync[i]),
        .fp_gpio_in(fp_gpio_in[32*i+31:32*i]), .fp_gpio_out(fp_gpio_out[32*i+31:32*i]), .fp_gpio_ddr(fp_gpio_ddr[32*i+31:32*i]),
        .db_gpio_in(db_gpio_in[32*i+31:32*i]), .db_gpio_out(db_gpio_out[32*i+31:32*i]), .db_gpio_ddr(db_gpio_ddr[32*i+31:32*i]),
        .leds(leds[32*i+31:32*i]),
        .spi_clk(spi_clk), .spi_rst(spi_rst), .sen(sen[8*i+7:8*i]), .sclk(sclk[i]), .mosi(mosi[i]), .miso(miso[i]),
        .set_stb(set_stb[i]), .set_addr(set_addr[8*i+7:8*i]), .set_data(set_data[32*i+31:32*i]),
        .rb_stb(rb_stb[i]), .rb_addr(rb_addr[8*i+7:8*i]), .rb_data(rb_data[64*i+63:64*i]),
        .tx_tdata(m_axis_data_tdata[i]), .tx_tlast(m_axis_data_tlast[i]), .tx_tvalid(m_axis_data_tvalid[i]), .tx_tready(m_axis_data_tready[i]), .tx_tuser(m_axis_data_tuser[i]),
        .rx_tdata(s_axis_data_tdata[i]), .rx_tlast(s_axis_data_tlast[i]), .rx_tvalid(s_axis_data_tvalid[i]), .rx_tready(s_axis_data_tready[i]), .rx_tuser(s_axis_data_tuser[i]),
        .resp_tdata(resp_tdata[64*i+63:64*i]), .resp_tlast(resp_tlast[i]), .resp_tvalid(resp_tvalid[i]), .resp_tready(resp_tready[i]));
    end
  endgenerate
endmodule