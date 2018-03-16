//
// Copyright 2014-2016 Ettus Research LLC
//

module noc_block_fosphor #(
  parameter NOC_ID = 64'h666f_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter MTU = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////

  wire [63:0] set_data_f;
  wire [15:0] set_addr_f;
  wire  [1:0] set_stb_f;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire  [63:0] str_sink_tdata;
  wire         str_sink_tlast, str_sink_tvalid, str_sink_tready;
  wire [127:0] str_src_tdata;
  wire   [1:0] str_src_tlast, str_src_tvalid, str_src_tready;

  wire [1:0]  clear_tx_seqnum, clear_tx_seqnum_bclk;
  wire [15:0] src_sid[0:1], next_dst_sid[0:1];

  synchronizer #(.INITIAL_VAL(1'b0), .WIDTH(2)) clear_tx_sync_i (
    .clk(bus_clk), .rst(1'b0), .in(clear_tx_seqnum), .out(clear_tx_seqnum_bclk));

  // Shell instance
  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(1),
    .OUTPUT_PORTS(2),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE),
    .MTU({2{MTU[7:0]}})
  ) inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data_f), .set_addr(set_addr_f), .set_stb(set_stb_f), .set_time(), .set_has_time(),
    .rb_stb(2'b11), .rb_addr(), .rb_data(128'd0),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),

    // Advanced user ports
    .vita_time(64'd0),
    .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid({src_sid[1],src_sid[0]}),
    .next_dst_sid({next_dst_sid[1],next_dst_sid[0]}),
    .resp_in_dst_sid(),
    .resp_out_dst_sid(),
    .debug(debug)
  );

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;


  ////////////////////////////////////////////////////////////
  //
  // CHDR deframer
  //
  ////////////////////////////////////////////////////////////

  wire [31:0]  in_tdata;
  wire         in_tlast;
  wire         in_tvalid;
  wire         in_tready;
  wire [127:0] in_tuser;

  chdr_deframer_2clk deframer (
    .samp_clk(ce_clk), .samp_rst(ce_rst), .pkt_clk(bus_clk), .pkt_rst(bus_rst),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(in_tdata), .o_tuser(in_tuser), .o_tlast(in_tlast), .o_tvalid(in_tvalid), .o_tready(in_tready)
  );


  ////////////////////////////////////////////////////////////
  //
  // CHDR framer
  //
  ////////////////////////////////////////////////////////////

  wire [31:0]  hist_tdata,  wf_tdata;
  wire [31:0]  hist_tdatas, wf_tdatas;
  wire         hist_tlast,  wf_tlast;
  wire         hist_tvalid, wf_tvalid;
  wire         hist_tready, wf_tready;
  wire [127:0] hist_tuser,  wf_tuser;
  wire         hist_teob,   wf_teob;

  wire         hist_tvalid_c, wf_tvalid_c;
  wire         hist_tready_c, wf_tready_c;

  wire [127:0] hist_chdr,   wf_chdr;

  // Histogram
  noc_block_fosphor_chdr inst_hist_chdr (
    .clk(ce_clk), .rst(ce_rst),
    .i_tuser(in_tuser), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
    .o_chdr(hist_chdr), .o_tlast(hist_tlast), .o_tvalid(hist_tvalid), .o_tready(hist_tready)
  );

  assign hist_tuser = {
    hist_chdr[127:125],         // Type + has_time
    hist_teob,                  // EOB
    hist_chdr[123:112],         // Seq Num
    2'b00, hist_chdr[111:98],   // length in bytes (input size / 4)
    src_sid[0],                 // SRC SID
    next_dst_sid[0],            // DST SID
    hist_chdr[63:0]             // Timestamp
  };

  assign hist_tdatas = { hist_tdata[7:0], hist_tdata[15:8], hist_tdata[23:16], hist_tdata[31:24] };

  chdr_framer_2clk #(
    .SIZE(MTU)
  ) framer_hist (
    .samp_clk(ce_clk), .samp_rst(ce_rst | clear_tx_seqnum[0]), .pkt_clk(bus_clk), .pkt_rst(bus_rst | clear_tx_seqnum_bclk[0]),
    .i_tdata(hist_tdatas), .i_tuser(hist_tuser), .i_tlast(hist_tlast), .i_tvalid(hist_tvalid), .i_tready(hist_tready),
    .o_tdata(str_src_tdata[63:0]), .o_tlast(str_src_tlast[0]), .o_tvalid(str_src_tvalid[0]), .o_tready(str_src_tready[0])
  );

  // Waterfall
  noc_block_fosphor_chdr inst_wf_chdr (
    .clk(ce_clk), .rst(ce_rst),
    .i_tuser(in_tuser), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
    .o_chdr(wf_chdr), .o_tlast(wf_tlast), .o_tvalid(wf_tvalid), .o_tready(wf_tready)
  );

  assign wf_tuser = {
    wf_chdr[127:125],           // Type + has_time
    1'b0,                       // EOB
    wf_chdr[123:112],           // Seq Num
    2'b00, wf_chdr[111:98],     // length in bytes (input size / 4)
    src_sid[1],                 // SRC SID
    next_dst_sid[1],            // DST SID
    wf_chdr[63:0]               // Timestamp
  };

  assign wf_tdatas = { wf_tdata[7:0], wf_tdata[15:8], wf_tdata[23:16], wf_tdata[31:24] };

  chdr_framer_2clk #(
    .SIZE(MTU)
  ) framer_wf (
    .samp_clk(ce_clk), .samp_rst(ce_rst | clear_tx_seqnum[1]), .pkt_clk(bus_clk), .pkt_rst(bus_rst | clear_tx_seqnum_bclk[1]),
    .i_tdata(wf_tdatas), .i_tuser(wf_tuser), .i_tlast(wf_tlast), .i_tvalid(wf_tvalid), .i_tready(wf_tready),
    .o_tdata(str_src_tdata[127:64]), .o_tlast(str_src_tlast[1]), .o_tvalid(str_src_tvalid[1]), .o_tready(str_src_tready[1])
  );


  ////////////////////////////////////////////////////////////
  //
  // Setting registers
  //
  ////////////////////////////////////////////////////////////

  // Address mapping
  localparam [7:0] AXI_WRAPPER_BASE = 128;

  localparam [7:0] SR_ENABLE        = AXI_WRAPPER_BASE + 32;
  localparam [7:0] SR_CLEAR         = AXI_WRAPPER_BASE + 33;
  localparam [7:0] SR_RANDOM        = AXI_WRAPPER_BASE + 34;

  localparam [7:0] SR_HIST_DECIM    = AXI_WRAPPER_BASE + 40;
  localparam [7:0] SR_OFFSET        = AXI_WRAPPER_BASE + 42;
  localparam [7:0] SR_SCALE         = AXI_WRAPPER_BASE + 43;
  localparam [7:0] SR_TRISE         = AXI_WRAPPER_BASE + 44;
  localparam [7:0] SR_TDECAY        = AXI_WRAPPER_BASE + 45;
  localparam [7:0] SR_ALPHA         = AXI_WRAPPER_BASE + 46;
  localparam [7:0] SR_EPSILON       = AXI_WRAPPER_BASE + 47;

  localparam [7:0] SR_WF_CTRL       = AXI_WRAPPER_BASE + 48;
  localparam [7:0] SR_WF_DECIM      = AXI_WRAPPER_BASE + 49;

  // Bus
  wire [31:0] set_data;
  wire  [7:0] set_addr;
  wire        set_stb;

  // Config wires
  wire clear_req;
  wire [ 1:0] cfg_random;
  wire [ 1:0] cfg_enable;
  wire [11:0] cfg_hist_decim;
  wire cfg_hist_decim_changed;
  wire [15:0] cfg_offset;
  wire [15:0] cfg_scale;
  wire [15:0] cfg_trise;
  wire [15:0] cfg_tdecay;
  wire [15:0] cfg_alpha;
  wire [15:0] cfg_epsilon;
  wire [ 7:0] cfg_wf_ctrl;
  wire [ 7:0] cfg_wf_decim;
  wire cfg_wf_decim_changed;

  // Bus (only port 0)
  assign set_data = set_data_f[31:0];
  assign set_addr = set_addr_f[7:0];
  assign set_stb  = set_stb_f[0];

  // Module enable
  setting_reg #(
    .my_addr(SR_ENABLE), .awidth(8), .width(2))
  sr_enable (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_enable));

  // Clear request
  setting_reg #(
    .my_addr(SR_CLEAR), .awidth(8), .width(1))
  sr_clear (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(), .changed(clear_req));

  // Randomness config
  setting_reg #(
    .my_addr(SR_RANDOM), .awidth(8), .width(2))
  sr_random (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_random));

  // Histogram decimation config
  setting_reg #(
    .my_addr(SR_HIST_DECIM), .awidth(8), .width(12))
  sr_hist_decim (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_hist_decim), .changed(cfg_hist_decim_changed));

  // Histogram bin mapping - offset
  setting_reg #(
    .my_addr(SR_OFFSET), .awidth(8), .width(16))
  sr_offset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_offset));

  // Histogram bin mapping - scale
  setting_reg #(
    .my_addr(SR_SCALE), .awidth(8), .width(16))
  sr_scale (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_scale));

  // Histogram rise time constant
  setting_reg #(
    .my_addr(SR_TRISE), .awidth(8), .width(16))
  sr_trise (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_trise));

  // Histogram decay time constant
  setting_reg #(
    .my_addr(SR_TDECAY), .awidth(8), .width(16))
  sr_tdecay (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_tdecay));

  // Live spectrum - average alpha
  setting_reg #(
    .my_addr(SR_ALPHA), .awidth(8), .width(16))
  sr_alpha (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_alpha));

  // Live spectrum - max-hold decay
  setting_reg #(
    .my_addr(SR_EPSILON), .awidth(8), .width(16))
  sr_epsilon (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_epsilon));

  // Waterfall control config
  setting_reg #(
    .my_addr(SR_WF_CTRL), .awidth(8), .width(8))
  sr_wf_ctrl (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_wf_ctrl));

  // Waterfall decimation config
  setting_reg #(
    .my_addr(SR_WF_DECIM), .awidth(8), .width(8))
  sr_wf_decim (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_wf_decim), .changed(cfg_wf_decim_changed));


  ////////////////////////////////////////////////////////////
  //
  // fosphor core
  //
  ////////////////////////////////////////////////////////////

  // Core block
  f15_core inst_fosphor (
    .clk(ce_clk), .reset(ce_rst),
    .clear_req(clear_req),
    .cfg_random(cfg_random),
    .cfg_offset(cfg_offset), .cfg_scale(cfg_scale),
    .cfg_trise(cfg_trise), .cfg_tdecay(cfg_tdecay),
    .cfg_alpha(cfg_alpha), .cfg_epsilon(cfg_epsilon),
    .cfg_decim(cfg_hist_decim), .cfg_decim_changed(cfg_hist_decim_changed),
    .cfg_wf_div(cfg_wf_ctrl[1:0]), .cfg_wf_mode(cfg_wf_ctrl[7]),
    .cfg_wf_decim(cfg_wf_decim), .cfg_wf_decim_changed(cfg_wf_decim_changed),
    .i_tdata(in_tdata), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
    .o_hist_tdata(hist_tdata), .o_hist_tlast(hist_tlast), .o_hist_tvalid(hist_tvalid_c), .o_hist_tready(hist_tready_c), .o_hist_teob(hist_teob),
    .o_wf_tdata(wf_tdata), .o_wf_tlast(wf_tlast), .o_wf_tvalid(wf_tvalid_c), .o_wf_tready(wf_tready_c)
  );

  // Enable / Disable logic
  assign hist_tready_c = hist_tready   | ~cfg_enable[0];
  assign hist_tvalid   = hist_tvalid_c &  cfg_enable[0];
  assign wf_tready_c   = wf_tready     | ~cfg_enable[1];
  assign wf_tvalid     = wf_tvalid_c   &  cfg_enable[1];

endmodule


// CHDR header handling submodule
module noc_block_fosphor_chdr
(
  input clk, input rst,
  input  [127:0] i_tuser, input i_tlast, input i_tvalid, input i_tready,
  output [127:0] o_chdr,  input o_tlast, input o_tvalid, input o_tready
);

  reg chdr_cap_next, chdr_pending, chdr_cur_valid;
  wire chdr_cap_cur;
  reg [127:0] chdr_next;
  reg [127:0] chdr_cur;

  always @(posedge clk)
  begin
    // When to capture Next
    if (rst)
      chdr_cap_next <= 1'b1;
    else if (i_tvalid & i_tready)
      chdr_cap_next <= i_tlast;

    // Next CHDR
    if (chdr_cap_next)
      chdr_next <= i_tuser;

    // When to capture
    if (chdr_cap_next)
      chdr_pending <= 1'b1;
    else if (chdr_cap_cur)
      chdr_pending <= 1'b0;

    // Current CHDR
    if (chdr_cap_cur)
      chdr_cur <= chdr_next;

    if (rst)
      chdr_cur_valid <= 1'b0;
    else if (chdr_cap_cur)
      chdr_cur_valid <= chdr_pending;
  end

  assign chdr_cap_cur = chdr_pending & ((o_tlast & o_tvalid & o_tready) | ~chdr_cur_valid);
  assign o_chdr = chdr_cur;

endmodule // noc_block_fosphor_chdr
