//
// Copyright 2016 Ettus Research
//

module noc_block_siggen #(
  parameter NOC_ID = 64'h5166_3110_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [15:0] src_sid;
  wire [15:0] next_dst_sid, resp_out_dst_sid;
  wire [15:0] resp_in_dst_sid;

  wire        clear_tx_seqnum;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Stream IDs set by host 
    .src_sid(src_sid),                   // SID of this block
    .next_dst_sid(next_dst_sid),         // Next destination SID
    .resp_in_dst_sid(resp_in_dst_sid),   // Response destination SID for input stream responses / errors
    .resp_out_dst_sid(resp_out_dst_sid), // Response destination SID for output stream responses / errors
    // Misc
    .vita_time('d0), .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  // Null sink
  assign str_sink_tready = 1'b1;

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////

  wire [31:0]  s_axis_data_tdata;
  wire [127:0] s_axis_data_tuser;
  wire         s_axis_data_tlast;
  wire         s_axis_data_tvalid;
  wire         s_axis_data_tready;
  wire         s_axis_data_tvalid_int;
  wire         s_axis_data_tready_int;
  wire [31:0]  s_axis_const_tdata;
  wire         s_axis_const_tvalid;
  wire         s_axis_const_tready;
  wire [31:0]  s_axis_sine_tdata;
  wire         s_axis_sine_tvalid;
  wire         s_axis_sine_tready;
  wire [31:0]  s_axis_noise_tdata;
  wire         s_axis_noise_tvalid;
  wire         s_axis_noise_tready;
  wire [63:0]  s_axis_gain_tdata;
  wire         s_axis_gain_tvalid;
  wire         s_axis_gain_tready;
  wire [31:0]  s_axis_mux_tdata;
  wire         s_axis_mux_tvalid;
  wire         s_axis_mux_tready;
  wire [15:0]  payload_length;
  wire [15:0]  gain;
  wire [1:0]   wave_type;
  wire         enable;

  axi_wrapper #(
    .SIMPLE_MODE(0),
    .RESIZE_OUTPUT_PACKET(1))
  axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(), .i_tlast(), .i_tvalid(), .i_tready(),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(),
    .m_axis_data_tlast(),
    .m_axis_data_tvalid(),
    .m_axis_data_tready(1'b1),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(/* Not needed due to RESIZE_OUTPUT_PACKET = 1 */),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tuser(s_axis_data_tuser),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  ////////////////////////////////////////////////////////////
  //
  // Signal Generator Block
  //
  ////////////////////////////////////////////////////////////
  localparam SR_PHASE_INC      = 129;
  localparam SR_CARTESIAN      = 130;
  localparam SR_ENABLE         = 132;
  localparam SR_CONSTANT       = 138;
  localparam SR_GAIN           = 139;
  localparam SR_PKT_SIZE       = 140;
  localparam SR_WAVEFORM       = 142;

  localparam CONST  = 2'd0;
  localparam SINE   = 2'd1;
  localparam NOISE  = 2'd2;

  cvita_hdr_encoder cvita_hdr_encoder (
    .pkt_type(2'd0), .eob(1'b0), .has_time(1'b0),
    .seqnum(12'd0), .payload_length(payload_length), .dst_sid(next_dst_sid), .src_sid(src_sid),
    .vita_time(64'd0),
    .header(s_axis_data_tuser));

  // Set packet size
  setting_reg #(
    .my_addr(SR_PKT_SIZE), .awidth(8), .width(16),
    .at_reset(4)) // Set a safe default packet size in case packet size is never set
  set_payload_length (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(payload_length), .changed());

  //settings bus for selecting wave type
  setting_reg #(
    .my_addr(SR_WAVEFORM), .awidth(8), .width(2))
  set_wave (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(wave_type), .changed());

  //Start/stop functionality
  //settings bus for start/stop
  setting_reg #(
    .my_addr(SR_ENABLE), .awidth(8), .width(1), .at_reset(0))
  set_enable (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(enable), .changed());

  // Enable logic
  assign s_axis_data_tvalid     = s_axis_data_tvalid_int & enable;
  assign s_axis_data_tready_int = s_axis_data_tready     & enable;

  ////////////////////////////////////////////////////////////
  //
  // Gain
  //
  ////////////////////////////////////////////////////////////
  setting_reg #(
    .my_addr(SR_GAIN), .awidth(8), .width(16), .at_reset({16'h7FFF /* approx 1.0 */}))
  set_gain (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(gain), .changed());

  mult_rc #(.WIDTH_REAL(16), .WIDTH_CPLX(16), .WIDTH_P(32), .DROP_TOP_P(5), .LATENCY(4)) mult_rc (
    .clk(ce_clk), .reset(ce_rst | clear_tx_seqnum),
    .real_tdata(gain), .real_tlast(1'b0), .real_tvalid(1'b1), .real_tready(),
    .cplx_tdata(s_axis_mux_tdata), .cplx_tlast(1'b0), .cplx_tvalid(s_axis_mux_tvalid), .cplx_tready(s_axis_mux_tready),
    .p_tdata(s_axis_gain_tdata), .p_tlast(), .p_tvalid(s_axis_gain_tvalid), .p_tready(s_axis_gain_tready));

  axi_round_and_clip_complex #(.WIDTH_IN(32), .WIDTH_OUT(16), .CLIP_BITS(1)) axi_round_and_clip_complex (
    .clk(ce_clk), .reset(ce_rst | clear_tx_seqnum),
    .i_tdata(s_axis_gain_tdata), .i_tlast(1'b0), .i_tvalid(s_axis_gain_tvalid), .i_tready(s_axis_gain_tready),
    .o_tdata(s_axis_data_tdata), .o_tlast(), .o_tvalid(s_axis_data_tvalid_int), .o_tready(s_axis_data_tready_int));

  ////////////////////////////////////////////////////////////
  //
  // Mux Signals
  //
  ////////////////////////////////////////////////////////////
  axi_mux_select #(.WIDTH(32), .SIZE(3)) axi_mux_select (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum),
    .select(wave_type),
    .i_tdata({s_axis_noise_tdata,s_axis_sine_tdata,s_axis_const_tdata}),
    .i_tlast({3'd0}), // Handled by packet sizing in AXI Wrapper
    .i_tvalid({s_axis_noise_tvalid,s_axis_sine_tvalid,s_axis_const_tvalid}),
    .i_tready({s_axis_noise_tready,s_axis_sine_tready,s_axis_const_tready}),
    .o_tdata(s_axis_mux_tdata), .o_tlast(), .o_tvalid(s_axis_mux_tvalid), .o_tready(s_axis_mux_tready));

  ////////////////////////////////////////////////////////////
  //
  // Sine_tone Block
  //
  ////////////////////////////////////////////////////////////
  sine_tone #(.WIDTH(32), .SR_PHASE_INC_ADDR(SR_PHASE_INC), .SR_CARTESIAN_ADDR(SR_CARTESIAN)) sine_tone_inst (
    .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum), .enable(1'b1),
    .set_stb(set_stb), .set_data(set_data), .set_addr(set_addr),
    .o_tdata(s_axis_sine_tdata), .o_tlast(), .o_tvalid(s_axis_sine_tvalid), .o_tready(s_axis_sine_tready));

  ////////////////////////////////////////////////////////////
  //
  // Constant Block
  //
  ////////////////////////////////////////////////////////////
  axi_setting_reg #(
    .ADDR(SR_CONSTANT), .AWIDTH(8), .WIDTH(32), .REPEATS(1))
  const_block (
    .clk(ce_clk), .reset(ce_rst | clear_tx_seqnum),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(s_axis_const_tdata), .o_tlast(), .o_tvalid(s_axis_const_tvalid), .o_tready(s_axis_const_tready));

  ////////////////////////////////////////////////////////////
  //
  // Noise Block
  //
  ////////////////////////////////////////////////////////////
  assign s_axis_noise_tvalid = 1'b1;
  rng rng (.clk(ce_clk), .rst(ce_rst | clear_tx_seqnum), .out(s_axis_noise_tdata));

endmodule
