//
// Copyright 2016 Ettus Research
//

module noc_block_duc #(
  parameter NOC_ID = 64'hD0C0_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 12,
  parameter NUM_CHAINS = 1

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
  wire [8*NUM_CHAINS-1:0]       rb_addr;
  wire [64*NUM_CHAINS-1:0]      rb_data;

  wire [63:0]                   cmdout_tdata, ackin_tdata;
  wire                          cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [64*NUM_CHAINS-1:0]      str_sink_tdata, str_src_tdata;
  wire [NUM_CHAINS-1:0]         str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [63:0]                   vita_time;
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
  localparam SR_INTERP_ADDR    = 131;
  localparam SR_FREQ_ADDR      = 132;
  localparam SR_SCALE_IQ_ADDR  = 133;

  genvar i;
  generate
    for (i = 0; i < NUM_CHAINS; i = i + 1) begin : gen_duc_chains
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
      wire clear_duc = clear_tx_seqnum[i] | clear_user;

      wire        set_stb_int      = set_stb[i];
      wire [7:0]  set_addr_int     = set_addr[8*i+7:8*i];
      wire [31:0] set_data_int     = set_data[32*i+31:32*i];
      wire [63:0] set_time_int     = set_time[64*i+63:64*i];
      wire        set_has_time_int = set_has_time[i];

      axi_wrapper #(
        .SIMPLE_MODE(0),
        .MTU(12)) // Increased MTU until cordic_timed bubble is fixed
      axi_wrapper (
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

      ////////////////////////////////////////////////////////////
      //
      // Timed CORDIC
      // - Implements timed cordic tunes. Placed between AXI Wrapper
      //   and AXI Rate Change due to it needing access to the
      //   vita time of the samples.
      //
      ////////////////////////////////////////////////////////////
      wire [31:0]  m_axis_rc_tdata;
      wire         m_axis_rc_tlast;
      wire         m_axis_rc_tvalid;
      wire         m_axis_rc_tready;
      wire [127:0] m_axis_rc_tuser;

      cordic_timed #(
        .SR_FREQ_ADDR(SR_FREQ_ADDR),
        .SR_SCALE_IQ_ADDR(SR_SCALE_IQ_ADDR))
      cordic_timed (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .set_time(set_time_int), .set_has_time(set_has_time_int),
        .i_tdata(m_axis_rc_tdata), .i_tlast(m_axis_rc_tlast), .i_tvalid(m_axis_rc_tvalid),
        .i_tready(m_axis_rc_tready), .i_tuser(m_axis_rc_tuser),
        .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid),
        .o_tready(s_axis_data_tready), .o_tuser(s_axis_data_tuser));

      ////////////////////////////////////////////////////////////
      //
      // Increase Rate
      //
      ////////////////////////////////////////////////////////////
      wire [31:0] sample_tdata, sample_duc_tdata;
      wire sample_tvalid, sample_tready;
      wire sample_duc_tvalid, sample_duc_tready;
      axi_rate_change #(
        .WIDTH(32),
        .MAX_N(1),
        .MAX_M(512),
        .SR_N_ADDR(SR_N_ADDR),
        .SR_M_ADDR(SR_M_ADDR),
        .SR_CONFIG_ADDR(SR_CONFIG_ADDR))
      axi_rate_change (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]), .clear_user(clear_user),
        .src_sid(src_sid[16*i+15:16*i]), .dst_sid(next_dst_sid[16*i+15:16*i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata({m_axis_data_tdata}), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid),
        .i_tready(m_axis_data_tready), .i_tuser(m_axis_data_tuser),
        .o_tdata(m_axis_rc_tdata), .o_tlast(m_axis_rc_tlast), .o_tvalid(m_axis_rc_tvalid),
        .o_tready(m_axis_rc_tready), .o_tuser(m_axis_rc_tuser),
        .m_axis_data_tdata({sample_tdata}), .m_axis_data_tlast(), .m_axis_data_tvalid(sample_tvalid),
        .m_axis_data_tready(sample_tready),
        .s_axis_data_tdata(sample_duc_tdata), .s_axis_data_tlast(1'b0), .s_axis_data_tvalid(sample_duc_tvalid),
        .s_axis_data_tready(sample_duc_tready));

      ////////////////////////////////////////////////////////////
      //
      // Digital Up Converter
      //
      ////////////////////////////////////////////////////////////
      duc #(
        .SR_INTERP_ADDR(SR_INTERP_ADDR))
      duc (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_duc),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata(sample_tdata), .i_tvalid(sample_tvalid), .i_tready(sample_tready),
        .o_tdata(sample_duc_tdata), .o_tvalid(sample_duc_tvalid), .o_tready(sample_duc_tready));

    end
  endgenerate

endmodule
