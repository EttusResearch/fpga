//
// Copyright 2014-2016 Ettus Research
//

module noc_block_fft #(
  parameter EN_MAGNITUDE_OUT = 1,        // CORDIC based magnitude calculation
  parameter EN_MAGNITUDE_APPROX_OUT = 0, // Multiplier-less, lower resource usage
  parameter EN_MAGNITUDE_SQ_OUT = 1,     // Magnitude squared
  parameter EN_FFT_SHIFT = 1,            // Center zero frequency bin
  parameter NOC_ID = 64'hFF70_0000_0000_0000,
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

  wire        clear_tx_seqnum;
  wire [15:0] next_dst_sid;

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
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .vita_time(64'd0), .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 1;
  
  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;
  
  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;
  
  wire [31:0] m_axis_config_tdata;
  wire        m_axis_config_tvalid;
  wire        m_axis_config_tready;
  
  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

  axi_wrapper #(
    .SIMPLE_MODE(1),
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
    .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tuser(),
    .m_axis_config_tdata(m_axis_config_tdata),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(m_axis_config_tvalid),
    .m_axis_config_tready(m_axis_config_tready),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());
  
  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////
  
  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  localparam [7:0] SR_FFT_RESET     = 131;
  localparam [7:0] SR_FFT_SIZE_LOG2 = 132;
  localparam [7:0] SR_MAGNITUDE_OUT = 133;
  localparam MAX_FFT_SIZE_LOG2      = 11;

  localparam [1:0] COMPLEX_OUT = 0;
  localparam [1:0] MAG_OUT     = 1;
  localparam [1:0] MAG_SQ_OUT  = 2;

  wire [1:0]  magnitude_out;
  wire [31:0] fft_data_o_tdata;
  wire        fft_data_o_tlast;
  wire        fft_data_o_tvalid;
  wire        fft_data_o_tready;
  wire [15:0] fft_data_o_tuser;
  wire [31:0] fft_shift_o_tdata;
  wire        fft_shift_o_tlast;
  wire        fft_shift_o_tvalid;
  wire        fft_shift_o_tready;
  wire [31:0] fft_mag_i_tdata, fft_mag_o_tdata, fft_mag_o_tdata_int;
  wire        fft_mag_i_tlast, fft_mag_o_tlast;
  wire        fft_mag_i_tvalid, fft_mag_o_tvalid;
  wire        fft_mag_i_tready, fft_mag_o_tready;
  wire [31:0] fft_mag_sq_i_tdata, fft_mag_sq_o_tdata;
  wire        fft_mag_sq_i_tlast, fft_mag_sq_o_tlast;
  wire        fft_mag_sq_i_tvalid, fft_mag_sq_o_tvalid;
  wire        fft_mag_sq_i_tready, fft_mag_sq_o_tready;
  wire [31:0] fft_mag_round_i_tdata, fft_mag_round_o_tdata;
  wire        fft_mag_round_i_tlast, fft_mag_round_o_tlast;
  wire        fft_mag_round_i_tvalid, fft_mag_round_o_tvalid;
  wire        fft_mag_round_i_tready, fft_mag_round_o_tready;

  wire fft_reset;
  setting_reg #(
    .my_addr(SR_FFT_RESET), .awidth(8), .width(1))
  sr_fft_reset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(fft_reset), .changed());

  wire [$clog2(MAX_FFT_SIZE_LOG2)-1:0] fft_size_log2_tdata;
  axi_setting_reg #(
    .ADDR(SR_FFT_SIZE_LOG2), .AWIDTH(8), .WIDTH($clog2(MAX_FFT_SIZE_LOG2)))
  sr_fft_size_log2 (
    .clk(ce_clk), .reset(ce_rst), .error_stb(),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(fft_size_log2_tdata), .o_tlast(), .o_tvalid(fft_size_log2_tvalid), .o_tready(fft_size_log2_tready));

  axi_fft inst_axi_fft (
    .aclk(ce_clk), .aresetn(~(ce_rst | fft_reset)),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tvalid(fft_data_o_tvalid),
    .m_axis_data_tready(fft_data_o_tready),
    .m_axis_data_tlast(fft_data_o_tlast),
    .m_axis_data_tdata(fft_data_o_tdata),
    .m_axis_data_tuser(fft_data_o_tuser), // FFT index
    .s_axis_config_tdata(m_axis_config_tdata[23:0]),
    .s_axis_config_tvalid(m_axis_config_tvalid),
    .s_axis_config_tready(m_axis_config_tready),
    // Unused
    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt());

  // Mux control signals
  assign fft_shift_o_tready     = (magnitude_out == MAG_OUT)    ? fft_mag_i_tready         :
                                  (magnitude_out == MAG_SQ_OUT) ? fft_mag_sq_i_tready      : s_axis_data_tready;
  assign fft_mag_i_tvalid       = (magnitude_out == MAG_OUT)    ? fft_shift_o_tvalid       : 1'b0;
  assign fft_mag_i_tlast        = (magnitude_out == MAG_OUT)    ? fft_shift_o_tlast        : 1'b0;
  assign fft_mag_i_tdata        = fft_shift_o_tdata;
  assign fft_mag_o_tready       = (magnitude_out == MAG_OUT)    ? fft_mag_round_i_tready   : 1'b0;
  assign fft_mag_sq_i_tvalid    = (magnitude_out == MAG_SQ_OUT) ? fft_shift_o_tvalid       : 1'b0;
  assign fft_mag_sq_i_tlast     = (magnitude_out == MAG_SQ_OUT) ? fft_shift_o_tlast        : 1'b0;
  assign fft_mag_sq_i_tdata     = fft_shift_o_tdata;
  assign fft_mag_sq_o_tready    = (magnitude_out == MAG_SQ_OUT) ? fft_mag_round_i_tready   : 1'b0;
  assign fft_mag_round_i_tvalid = (magnitude_out == MAG_OUT)    ? fft_mag_o_tvalid         :
                                  (magnitude_out == MAG_SQ_OUT) ? fft_mag_sq_o_tvalid      : 1'b0;
  assign fft_mag_round_i_tlast  = (magnitude_out == MAG_OUT)    ? fft_mag_o_tlast          :
                                  (magnitude_out == MAG_SQ_OUT) ? fft_mag_sq_o_tlast       : 1'b0;
  assign fft_mag_round_i_tdata  = (magnitude_out == MAG_OUT)    ? fft_mag_o_tdata          : fft_mag_sq_o_tdata;
  assign fft_mag_round_o_tready = s_axis_data_tready;
  assign s_axis_data_tvalid     = (magnitude_out == MAG_OUT | magnitude_out == MAG_SQ_OUT) ? fft_mag_round_o_tvalid : fft_shift_o_tvalid;
  assign s_axis_data_tlast      = (magnitude_out == MAG_OUT | magnitude_out == MAG_SQ_OUT) ? fft_mag_round_o_tlast  : fft_shift_o_tlast;
  assign s_axis_data_tdata      = (magnitude_out == MAG_OUT | magnitude_out == MAG_SQ_OUT) ? fft_mag_round_o_tdata  : fft_shift_o_tdata;

  // Conditionally synth magnitude / magnitude^2 logic
  generate
    if (EN_MAGNITUDE_OUT | EN_MAGNITUDE_APPROX_OUT | EN_MAGNITUDE_SQ_OUT) begin
      setting_reg #(
        .my_addr(SR_MAGNITUDE_OUT), .awidth(8), .width(2))
      sr_magnitude_out (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb), .addr(set_addr), .in(set_data), .out(magnitude_out), .changed());
    end else begin
      // Magnitude calculation logic not included, so always bypass
      assign magnitude_out = 2'd0;
    end

    if (EN_FFT_SHIFT) begin
      fft_shift #(
        .MAX_FFT_SIZE_LOG2(MAX_FFT_SIZE_LOG2),
        .WIDTH(32))
      inst_fft_shift (
        .clk(ce_clk), .reset(ce_rst | fft_reset),
        .fft_size_log2_tdata(fft_size_log2_tdata),
        .fft_size_log2_tvalid(fft_size_log2_tvalid),
        .fft_size_log2_tready(fft_size_log2_tready),
        .i_tdata(fft_data_o_tdata),
        .i_tlast(fft_data_o_tlast),
        .i_tvalid(fft_data_o_tvalid),
        .i_tready(fft_data_o_tready),
        .i_tuser(fft_data_o_tuser[MAX_FFT_SIZE_LOG2-1:0]),
        .o_tdata(fft_shift_o_tdata),
        .o_tlast(fft_shift_o_tlast),
        .o_tvalid(fft_shift_o_tvalid),
        .o_tready(fft_shift_o_tready));
    end else begin
      assign fft_shift_o_tdata = fft_data_o_tdata;
      assign fft_shift_o_tlast = fft_data_o_tlast;
      assign fft_shift_o_tvalid = fft_data_o_tvalid;
      assign fft_data_o_tready = fft_shift_o_tready;
    end

    // More accurate magnitude calculation takes precedence if enabled
    if (EN_MAGNITUDE_OUT) begin
      complex_to_magphase
      inst_complex_to_magphase (
        .aclk(ce_clk), .aresetn(~(ce_rst | fft_reset)),
        .s_axis_cartesian_tvalid(fft_mag_i_tvalid),
        .s_axis_cartesian_tlast(fft_mag_i_tlast),
        .s_axis_cartesian_tready(fft_mag_i_tready),
        .s_axis_cartesian_tdata(fft_mag_i_tdata),
        .m_axis_dout_tvalid(fft_mag_o_tvalid),
        .m_axis_dout_tlast(fft_mag_o_tlast),
        .m_axis_dout_tdata(fft_mag_o_tdata_int),
        .m_axis_dout_tready(fft_mag_o_tready));
      assign fft_mag_o_tdata = {1'b0, fft_mag_o_tdata_int[15:0], 15'd0};
    end else if (EN_MAGNITUDE_APPROX_OUT) begin
      complex_to_mag_approx
      inst_complex_to_mag_approx (
        .clk(ce_clk), .reset(ce_rst | fft_reset), .clear(1'b0),
        .i_tvalid(fft_mag_i_tvalid),
        .i_tlast(fft_mag_i_tlast),
        .i_tready(fft_mag_i_tready),
        .i_tdata(fft_mag_i_tdata),
        .o_tvalid(fft_mag_o_tvalid),
        .o_tlast(fft_mag_o_tlast),
        .o_tready(fft_mag_o_tready),
        .o_tdata(fft_mag_o_tdata_int[15:0]));
      assign fft_mag_o_tdata = {1'b0, fft_mag_o_tdata_int[15:0], 15'd0};
    end else begin
      assign fft_mag_o_tdata = fft_mag_i_tdata;
      assign fft_mag_o_tlast = fft_mag_i_tlast;
      assign fft_mag_o_tvalid = fft_mag_i_tvalid;
      assign fft_mag_i_tready = fft_mag_o_tready;
    end

    if (EN_MAGNITUDE_SQ_OUT) begin
      complex_to_magsq
      inst_complex_to_magsq (
        .clk(ce_clk), .reset(ce_rst | fft_reset), .clear(1'b0),
        .i_tvalid(fft_mag_sq_i_tvalid),
        .i_tlast(fft_mag_sq_i_tlast),
        .i_tready(fft_mag_sq_i_tready),
        .i_tdata(fft_mag_sq_i_tdata),
        .o_tvalid(fft_mag_sq_o_tvalid),
        .o_tlast(fft_mag_sq_o_tlast),
        .o_tready(fft_mag_sq_o_tready),
        .o_tdata(fft_mag_sq_o_tdata));
    end else begin
      assign fft_mag_sq_o_tdata = fft_mag_sq_i_tdata;
      assign fft_mag_sq_o_tlast = fft_mag_sq_i_tlast;
      assign fft_mag_sq_o_tvalid = fft_mag_sq_i_tvalid;
      assign fft_mag_sq_i_tready = fft_mag_sq_o_tready;
    end

    // Convert to SC16
    if (EN_MAGNITUDE_OUT | EN_MAGNITUDE_APPROX_OUT | EN_MAGNITUDE_SQ_OUT) begin
      axi_round_and_clip #(
        .WIDTH_IN(32),
        .WIDTH_OUT(16),
        .CLIP_BITS(1))
      inst_axi_round_and_clip (
        .clk(ce_clk), .reset(ce_rst | fft_reset),
        .i_tdata(fft_mag_round_i_tdata),
        .i_tlast(fft_mag_round_i_tlast),
        .i_tvalid(fft_mag_round_i_tvalid),
        .i_tready(fft_mag_round_i_tready),
        .o_tdata(fft_mag_round_o_tdata[31:16]),
        .o_tlast(fft_mag_round_o_tlast),
        .o_tvalid(fft_mag_round_o_tvalid),
        .o_tready(fft_mag_round_o_tready));
      assign fft_mag_round_o_tdata[15:0] = {16{16'd0}};
    end else begin
      assign fft_mag_round_o_tdata = fft_mag_round_i_tdata;
      assign fft_mag_round_o_tlast = fft_mag_round_i_tlast;
      assign fft_mag_round_o_tvalid = fft_mag_round_i_tvalid;
      assign fft_mag_round_i_tready = fft_mag_round_o_tready;
    end
  endgenerate

  // Readback registers
  always @*
    case(rb_addr)
      8'd0    : rb_data <= {63'd0, fft_reset};
      8'd1    : rb_data <= {62'd0, magnitude_out};
      default : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase

endmodule
