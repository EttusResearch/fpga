//
// Copyright 2016 Ettus Research
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module noc_block_ducddc #(
  parameter NOC_ID            = 64'hD0C0_DDC0_0000_0001,
  parameter STR_SINK_FIFOSIZE = 11,     //Log2 of input buffer size in 8-byte words (must hold at least 2 MTU packets)
  parameter MTU               = 10,     //Log2 of output buffer size in 8-byte words (must hold at least 1 MTU packet)
  parameter NUM_CHAINS        = 1,
  parameter COMPAT_NUM_MAJOR  = 32'h2,
  parameter COMPAT_NUM_MINOR  = 32'h0,
  parameter DUC_NUM_HB        = 2,
  parameter DUC_CIC_MAX_INTERP = 16,
  parameter DDC_NUM_HB        = 2,
  parameter DDC_CIC_MAX_DECIM = 16
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
  wire [NUM_CHAINS*32-1:0]      set_data;
  wire [NUM_CHAINS*8-1:0]       set_addr;
  wire [NUM_CHAINS-1:0]         set_stb;
  wire [NUM_CHAINS*64-1:0]      set_time;
  wire [NUM_CHAINS-1:0]         set_has_time;
  wire [NUM_CHAINS-1:0]         rb_stb;
  wire [8*NUM_CHAINS-1:0]       rb_addr;
  reg [64*NUM_CHAINS-1:0]       rb_data;

  wire [63:0]                   cmdout_tdata, ackin_tdata;
  wire                          cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*NUM_CHAINS-1:0]      str_sink_tdata, str_src_tdata;
  wire [NUM_CHAINS-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [NUM_CHAINS-1:0]         clear_tx_seqnum;
  wire [16*NUM_CHAINS-1:0]      src_sid, next_dst_sid, resp_in_dst_sid, resp_out_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_CHAINS),
    .OUTPUT_PORTS(NUM_CHAINS),
    .STR_SINK_FIFOSIZE({NUM_CHAINS{STR_SINK_FIFOSIZE[7:0]}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time), .set_has_time(set_has_time),
    .rb_stb({NUM_CHAINS{1'b1}}), .rb_data(rb_data), .rb_addr(rb_addr),
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
    .vita_time(64'd0),
    .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_N_ADDR         = 128;
  localparam SR_M_ADDR         = 129;
  localparam SR_CONFIG_ADDR    = 130;

  // DUC-Specific Regs
  localparam SR_DUC_INTERP_ADDR    = 131;
  localparam SR_DUC_FREQ_ADDR      = 132;
  localparam SR_DUC_SCALE_IQ_ADDR  = 133;
  localparam RB_DUC_COMPAT_NUM     = 0;
  localparam RB_DUC_NUM_HB         = 1;
  localparam RB_DUC_CIC_MAX_INTERP = 2;
  localparam DUC_COMPAT_NUM        = {COMPAT_NUM_MAJOR, COMPAT_NUM_MINOR};
  localparam DUC_MAX_M = DUC_CIC_MAX_INTERP * 2<<(DUC_NUM_HB-1);

  localparam SR_DDC_FREQ_ADDR     = 141;
  localparam SR_DDC_SCALE_IQ_ADDR = 142;
  localparam SR_DDC_DECIM_ADDR    = 143;
  localparam SR_DDC_MUX_ADDR      = 144;
  localparam SR_DDC_COEFFS_ADDR   = 145;
  localparam RB_DDC_COMPAT_NUM    = 10;
  localparam RB_DDC_NUM_HB        = 11;
  localparam RB_DDC_CIC_MAX_DECIM = 12;
  localparam DDC_COMPAT_NUM       = {COMPAT_NUM_MAJOR, COMPAT_NUM_MINOR};
  localparam DDC_MAX_N = DDC_CIC_MAX_DECIM * 2<<(DDC_NUM_HB-1);

  localparam SR_SPP_OUT = 150;

  genvar i;
  generate
    for (i = 0; i < NUM_CHAINS; i = i + 1) begin : gen_ddc_chains
      ////////////////////////////////////////////////////////////
      //
      // AXI Wrapper
      // Convert RFNoC Shell interface into AXI stream interface
      //
      ////////////////////////////////////////////////////////////
      wire [31:0]  m_axis_data_tdata;
      wire         m_axis_data_tlast;
      wire         m_axis_data_tvalid;
      wire         m_axis_data_tready;
      wire [127:0] m_axis_data_tuser;

      wire [31:0]  s_axis_data_tdata;
      wire         s_axis_data_tlast;
      wire         s_axis_data_tvalid;
      wire         s_axis_data_tready;
      wire [127:0] s_axis_data_tuser;

      wire clear_user;

      wire        set_stb_int      = set_stb[i];
      wire [7:0]  set_addr_int     = set_addr[8*i+7:8*i];
      wire [31:0] set_data_int     = set_data[32*i+31:32*i];
      wire [63:0] set_time_int     = set_time[64*i+63:64*i];
      wire        set_has_time_int = set_has_time[i];

      wire [15:0] spp_out;
      setting_reg #(.my_addr(SR_SPP_OUT), .awidth(8), .width(16), .at_reset(1))
      set_spp_temp_inst (
        .clk(ce_clk), .rst(ce_rst),
        .strobe(set_stb_int), .addr(set_addr_int), .in(set_data_int),
        .out(spp_out), .changed());

      // TODO Readback register for number of FIR filter taps
      always @*
        case(rb_addr[8*i+7:8*i])
          RB_DUC_COMPAT_NUM    : rb_data[64*i+63:64*i] <= {DUC_COMPAT_NUM};
          RB_DUC_NUM_HB        : rb_data[64*i+63:64*i] <= {DUC_NUM_HB};
          RB_DUC_CIC_MAX_INTERP : rb_data[64*i+63:64*i] <= {DUC_CIC_MAX_INTERP};
          RB_DDC_COMPAT_NUM    : rb_data[64*i+63:64*i] <= {DDC_COMPAT_NUM};
          RB_DDC_NUM_HB        : rb_data[64*i+63:64*i] <= {DDC_NUM_HB};
          RB_DDC_CIC_MAX_DECIM : rb_data[64*i+63:64*i] <= {DDC_CIC_MAX_DECIM};
          default          : rb_data[64*i+63:64*i] <= 64'h0BADC0DE0BADC0DE;
        endcase

      axi_wrapper #(
        .SIMPLE_MODE(0),
        .MTU(MTU))
      axi_wrapper (
        .bus_clk(bus_clk), .bus_rst(bus_rst),
        .clk(ce_clk), .reset(ce_rst),
        .clear_tx_seqnum(clear_tx_seqnum[i]),
        .next_dst(next_dst_sid[16*i+15:16*i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata(str_sink_tdata[64*i+63:64*i]), .i_tlast(str_sink_tlast[i]), .i_tvalid(str_sink_tvalid[i]), .i_tready(str_sink_tready[i]),
        .o_tdata(str_src_tdata[64*i+63:64*i]), .o_tlast(str_src_tlast[i]), .o_tvalid(str_src_tvalid[i]), .o_tready(str_src_tready[i]),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tlast(m_axis_data_tlast),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tuser(m_axis_data_tuser),
        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tlast(s_axis_data_tlast),
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

      // // Temporary Hack: dont use axi_rate_change
      // //  ... just expose a register to force SPP
      // //  and then set RESIZE_OUTPUT_PACKET(1)
      // cvita_hdr_encoder cvita_hdr_encoder (
      //   .pkt_type(2'd0), .eob(1'b0), .has_time(1'b0),
      //   .seqnum(12'd0), .payload_length(spp_out),
      //   .dst_sid(next_dst_sid[16*i+15:16*i]), .src_sid(src_sid),
      //   .vita_time(64'd0),
      //   .header(s_axis_data_tuser));

      ////////////////////////////////////////////////////////////
      //
      // Reduce Rate
      //
      ////////////////////////////////////////////////////////////
      wire [31:0] sample_in_tdata;
      wire sample_in_tvalid, sample_in_tready;
      wire [31:0] sample_out_tdata;
      wire sample_out_tvalid, sample_out_tready;
      wire warning_long_throttle;
      wire error_extra_outputs;
      wire error_drop_pkt_lockup;
      axi_rate_change #(
        .WIDTH(32),
        .MAX_N(DDC_MAX_N),
        .MAX_M(DUC_MAX_M),
        .SR_N_ADDR(SR_N_ADDR),
        .SR_M_ADDR(SR_M_ADDR),
        .SR_CONFIG_ADDR(SR_CONFIG_ADDR))
      axi_rate_change (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]), .clear_user(clear_user),
        .src_sid(src_sid[16*i+15:16*i]), .dst_sid(next_dst_sid[16*i+15:16*i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid),
        .i_tready(m_axis_data_tready), .i_tuser(m_axis_data_tuser),
        .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid),
        .o_tready(s_axis_data_tready), .o_tuser(s_axis_data_tuser),
        .m_axis_data_tdata(sample_in_tdata),
        .m_axis_data_tlast(),
        .m_axis_data_tvalid(sample_in_tvalid),
        .m_axis_data_tready(sample_in_tready),
        .s_axis_data_tdata(sample_out_tdata),
        .s_axis_data_tlast(1'b0),
        .s_axis_data_tvalid(sample_out_tvalid),
        .s_axis_data_tready(sample_out_tready),
        .warning_long_throttle(warning_long_throttle),
        .error_extra_outputs(error_extra_outputs),
        .error_drop_pkt_lockup(error_drop_pkt_lockup));

      ////////////////////////////////////////////////////////////
      //
      // Digital Up Converter
      //
      ////////////////////////////////////////////////////////////

      wire [31:0] sample_duc_tdata;
      wire sample_duc_tvalid, sample_duc_tready;
      duc #(
        .SR_INTERP_ADDR(SR_DUC_INTERP_ADDR),
        .SR_SCALE_ADDR(SR_DUC_SCALE_IQ_ADDR),
        .NUM_HB(DUC_NUM_HB),
        .CIC_MAX_INTERP(DUC_CIC_MAX_INTERP))
      duc (
        .clk(ce_clk), .reset(ce_rst),
        .clear(clear_user | clear_tx_seqnum[i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata(sample_in_tdata), .i_tvalid(sample_in_tvalid), .i_tready(sample_in_tready),
        .o_tdata(sample_duc_tdata), .o_tvalid(sample_duc_tvalid), .o_tready(sample_duc_tready));

      ////////////////////////////////////////////////////////////
      //
      // Digital Down Converter
      //
      ////////////////////////////////////////////////////////////

      ddc #(
        .SR_FREQ_ADDR(SR_DDC_FREQ_ADDR),
        .SR_SCALE_IQ_ADDR(SR_DDC_SCALE_IQ_ADDR),
        .SR_DECIM_ADDR(SR_DDC_DECIM_ADDR),
        .SR_MUX_ADDR(SR_DDC_MUX_ADDR),
        .SR_COEFFS_ADDR(SR_DDC_COEFFS_ADDR),
        .NUM_HB(DDC_NUM_HB),
        .CIC_MAX_DECIM(DDC_CIC_MAX_DECIM))
      ddc (
        .clk(ce_clk), .reset(ce_rst),
        .clear(clear_user | clear_tx_seqnum[i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .timed_set_stb(), .timed_set_addr(), .timed_set_data(),
        .sample_in_tdata(sample_duc_tdata), .sample_in_tlast(1'b0),
        .sample_in_tvalid(sample_duc_tvalid), .sample_in_tready(sample_duc_tready),
        .sample_in_tuser(1'b0), .sample_in_eob(1'b0),
        .sample_out_tdata(sample_out_tdata), .sample_out_tlast(),
        .sample_out_tvalid(sample_out_tvalid), .sample_out_tready(sample_out_tready)
        );

    end
  endgenerate

endmodule
