//
// Copyright 2014-2017 Ettus Research
//
// Parameterized FIR filter RFNoC block with optional reloadable
// coefficients.
// Has several optimizations to resource utilization such as
// using half the number of DSP slices for symmetric coefficients,
// skipping coefficients that are always set to zero, and using
// internal DSP slice registers to hold coefficients.
//
// For the most efficient DSP slice inference use these settings:
// - COEFF_WIDTH < 18
//
// Settings Registers:
//   SR_RELOAD                - Reload register. Write NUM_COEFFS coefficients to this register
//                              to load new taps.
//   RB_NUM_COEFFS            - Number of coefficients
//
// Parameters:
//   IN_WIDTH                 - Input width
//   COEFF_WIDTH              - Coefficient width
//   OUT_WIDTH                - Output width
//   NUM_COEFFS               - Number of coefficients / taps
//   CLIP_BITS                - If IN_WIDTH != OUT_WIDTH, number of MSBs to drop
//   ACCUM_WIDTH              - Accumulator width
//   COEFFS_VEC               - Vector of NUM_COEFFS values each of width COEFF_WIDTH to
//                              initialize coeffs. Defaults to an impulse.
//   RELOADABLE_COEFFS        - Enable (1) or disable (0) reloading coefficients at runtime (via reload bus)
//   BLANK_OUTPUT             - Enable (0) or disable (1) output tvalid when filling internal pipeline
//   BLANK_OUTPUT_SET_TLAST   - Set output tlast at end of resetting internal pipeline
//   SYMMETRIC_COEFFS         - Reduce multiplier usage by approx half if coefficients are symmetric
//   SKIP_ZERO_COEFFS         - Reduce multiplier usage by assuming zero valued coefficients in
//                              DEFAULT_COEFFS are always zero. Useful for halfband filters.
//   USE_EMBEDDED_REGS_COEFFS - Reduce register usage by only using embedded registers in DSP slices.
//                              Updating taps while streaming will cause temporary output corruption!
//
// Note: If using USE_EMBEDDED_REGS_COEFFS, coefficients must be written at least once as COEFFS_VEC is ignored!
//
module noc_block_fir_filter #(
  parameter NOC_ID                   = 64'hF112_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE        = 11,
  parameter COEFF_WIDTH              = 16,
  parameter NUM_COEFFS               = 41,
  parameter [NUM_COEFFS*COEFF_WIDTH-1:0] COEFFS_VEC = 
    {{1'b0,{(COEFF_WIDTH-1){1'b1}}},{(COEFF_WIDTH*(NUM_COEFFS-1)){1'b0}}}, // Impulse
  parameter RELOADABLE_COEFFS        = 1,
  parameter SYMMETRIC_COEFFS         = 0,
  parameter SKIP_ZERO_COEFFS         = 0,
  parameter USE_EMBEDDED_REGS_COEFFS = 1
)(
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
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .vita_time(), .debug(debug));

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;

  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;

  axi_wrapper #(
    .SIMPLE_MODE(1))
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
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready(),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready());

  ////////////////////////////////////////////////////////////
  //
  // FIR Filter Implementation
  //
  ////////////////////////////////////////////////////////////
  wire [COEFF_WIDTH-1:0] m_axis_fir_reload_tdata;
  wire m_axis_fir_reload_tvalid, m_axis_fir_reload_tready, m_axis_fir_reload_tlast;

  localparam SR_RELOAD       = 128;
  localparam SR_RELOAD_TLAST = 129;
  localparam RB_NUM_COEFFS   = 0;

  // Readback register for number of FIR filter taps
  always @*
    case(rb_addr)
      RB_NUM_COEFFS : rb_data <= {NUM_COEFFS};
      default       : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase

  // FIR filter coefficient reload bus
  axi_setting_reg #(
    .ADDR(SR_RELOAD),
    .USE_ADDR_LAST(1),
    .ADDR_LAST(SR_RELOAD_TLAST),
    .WIDTH(COEFF_WIDTH))
  set_coeff (
    .clk(ce_clk),
    .reset(ce_rst),
    .set_stb(set_stb),
    .set_addr(set_addr),
    .set_data(set_data),
    .o_tdata(m_axis_fir_reload_tdata),
    .o_tlast(m_axis_fir_reload_tlast),
    .o_tvalid(m_axis_fir_reload_tvalid),
    .o_tready(m_axis_fir_reload_tready));

  // SC16 format
  localparam IN_WIDTH    = 16;
  localparam OUT_WIDTH   = 16;

  // I
  axi_fir_filter #(
    .IN_WIDTH(IN_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .OUT_WIDTH(OUT_WIDTH),
    .NUM_COEFFS(NUM_COEFFS),
    .COEFFS_VEC(COEFFS_VEC),
    .RELOADABLE_COEFFS(RELOADABLE_COEFFS),
    .BLANK_OUTPUT(1),
    .BLANK_OUTPUT_SET_TLAST(0),
    // Optional optimizations
    .SYMMETRIC_COEFFS(SYMMETRIC_COEFFS),
    .SKIP_ZERO_COEFFS(SKIP_ZERO_COEFFS),
    .USE_EMBEDDED_REGS_COEFFS(USE_EMBEDDED_REGS_COEFFS))
  inst_axi_fir_filter_i (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear_tx_seqnum),
    .s_axis_data_tdata(m_axis_data_tdata[2*IN_WIDTH-1:IN_WIDTH]),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tdata(s_axis_data_tdata[2*OUT_WIDTH-1:OUT_WIDTH]),
    .m_axis_data_tlast(s_axis_data_tlast),
    .m_axis_data_tvalid(s_axis_data_tvalid),
    .m_axis_data_tready(s_axis_data_tready),
    .s_axis_reload_tdata(m_axis_fir_reload_tdata),
    .s_axis_reload_tlast(m_axis_fir_reload_tlast),
    .s_axis_reload_tvalid(m_axis_fir_reload_tvalid),
    .s_axis_reload_tready(m_axis_fir_reload_tready));

  // Q
  axi_fir_filter #(
    .IN_WIDTH(IN_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .OUT_WIDTH(OUT_WIDTH),
    .NUM_COEFFS(NUM_COEFFS),
    .COEFFS_VEC(COEFFS_VEC),
    .RELOADABLE_COEFFS(RELOADABLE_COEFFS),
    .BLANK_OUTPUT(1),
    .BLANK_OUTPUT_SET_TLAST(0),
    // Optional optimizations
    .SYMMETRIC_COEFFS(SYMMETRIC_COEFFS),
    .SKIP_ZERO_COEFFS(SKIP_ZERO_COEFFS),
    .USE_EMBEDDED_REGS_COEFFS(USE_EMBEDDED_REGS_COEFFS))
  inst_axi_fir_filter_q (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear_tx_seqnum),
    .s_axis_data_tdata(m_axis_data_tdata[IN_WIDTH-1:0]),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(),
    .m_axis_data_tdata(s_axis_data_tdata[OUT_WIDTH-1:0]),
    .m_axis_data_tlast(),
    .m_axis_data_tvalid(),
    .m_axis_data_tready(s_axis_data_tready),
    .s_axis_reload_tdata(m_axis_fir_reload_tdata),
    .s_axis_reload_tlast(m_axis_fir_reload_tlast),
    .s_axis_reload_tvalid(m_axis_fir_reload_tvalid),
    .s_axis_reload_tready());

endmodule
