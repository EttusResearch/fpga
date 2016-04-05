//
// Copyright 2016 Ettus Research
//

module noc_block_ddc #(
  parameter NOC_ID = 64'hDDC0_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
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
  wire [8*NUM_CHAINS-1:0]       rb_addr;
  wire [64*NUM_CHAINS-1:0]      rb_data;
  wire [NUM_CHAINS-1:0]         rb_stb;

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
    .STR_SINK_FIFOSIZE({NUM_CHAINS{STR_SINK_FIFOSIZE[7:0]}}),
    .USE_TIMED_CMDS(1)) // Settings bus transactions will occur at the vita time specified in the command packet
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(/* Unused */),
    .rb_stb(rb_stb), .rb_data(rb_data), .rb_addr(rb_addr),
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

  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_USER_REG_BASE = 128;

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

      wire clear_eob;
      wire clear_ddc = clear_tx_seqnum[i] | clear_eob;

      wire        set_stb_int  = set_stb[i];
      wire [7:0]  set_addr_int = set_addr[8*i+7:8*i];
      wire [31:0] set_data_int = set_data[32*i+31:32*i];

      axi_wrapper #(
        .SIMPLE_MODE(0))
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
      // Reduce Rate
      //
      ////////////////////////////////////////////////////////////
      wire [31:0] sample_tdata, sample_ddc_tdata;
      wire sample_tvalid, sample_tlast, sample_tready, sample_teob;
      wire sample_ddc_tvalid, sample_ddc_tlast, sample_ddc_tready, sample_ddc_teob;
      axi_rate_change #(
        .WIDTH(32),
        .REDUCE_RATE(1),
        .MAX_RATE(2040),
        .MAX_PKT_SIZE(2048),
        .HEADER_FIFO_SIZE(1),
        .EN_DROP_PARTIAL_PKT(1),
        .SR_RATE(SR_USER_REG_BASE),
        .SR_CONFIG(SR_USER_REG_BASE+1),
        .SR_PKT_SIZE(SR_USER_REG_BASE+2),
        .SR_DROP_PARTIAL_PKT(SR_USER_REG_BASE+3))
      axi_rate_change (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]), .clear_eob(clear_eob),
        .src_sid(src_sid[16*i+15:16*i]), .dst_sid(next_dst_sid[16*i+15:16*i]),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid),
        .i_tready(m_axis_data_tready), .i_tuser(m_axis_data_tuser),
        .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid),
        .o_tready(s_axis_data_tready), .o_tuser(s_axis_data_tuser),
        .m_axis_data_tdata(sample_tdata), .m_axis_data_tlast(sample_tlast), .m_axis_data_tvalid(sample_tvalid),
        .m_axis_data_tready(sample_tready), .m_axis_data_teob(sample_teob),
        .s_axis_data_tdata(sample_ddc_tdata), .s_axis_data_tlast(sample_ddc_tlast), .s_axis_data_tvalid(sample_ddc_tvalid),
        .s_axis_data_tready(sample_ddc_tready), .s_axis_data_teob(sample_ddc_teob));

      assign sample_ddc_teob = sample_ddc_tlast;

      ////////////////////////////////////////////////////////////
      //
      // Digital Down Converter
      //
      ////////////////////////////////////////////////////////////
      wire [31:0] sample_in;
      wire sample_in_stb, sample_in_last, sample_in_rdy;
      axi_to_strobed #(.WIDTH(32), .FIFO_SIZE(1), .MIN_RATE(1)) axi_to_strobed (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_ddc),
        .out_rate(1'd1),
        .ready(sample_ddc_tready & sample_in_rdy), // Do not accept more data if upstream is throttled
        .error(), // Due to rate set to 1, may get errors but that is expected
        .i_tdata(sample_tdata), .i_tvalid(sample_tvalid), .i_tlast(sample_tlast & sample_teob), .i_tready(sample_tready),
        .out_stb(sample_in_stb), .out_last(sample_in_last), .out_data(sample_in));

      wire [31:0] sample_out;
      wire sample_out_stb, sample_out_last;
      ddc #(.BASE(SR_USER_REG_BASE+4)) ddc (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_ddc),
        .set_stb(set_stb_int), .set_addr(set_addr_int), .set_data(set_data_int),
        .sample_in(sample_in), .sample_in_stb(sample_in_stb), .sample_in_last(sample_in_last), .sample_in_rdy(sample_in_rdy),
        .sample_out(sample_out), .sample_out_stb(sample_out_stb), .sample_out_last(sample_out_last));

      strobed_to_axi #(.WIDTH(32), .FIFO_SIZE(5)) strobed_to_axi (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_ddc),
        .in_stb(sample_out_stb), .in_data(sample_out), .in_last(sample_out_last),
        .o_tdata(sample_ddc_tdata), .o_tlast(sample_ddc_tlast), .o_tvalid(sample_ddc_tvalid), .o_tready(sample_ddc_tready));
    end
  endgenerate

endmodule