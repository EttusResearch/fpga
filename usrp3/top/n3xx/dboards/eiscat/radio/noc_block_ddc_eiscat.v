/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
/////////////////////////////////////////////////////////////////

module noc_block_ddc_eiscat #(
  parameter NOC_ID = 64'hDDC5_E15C_A700_0000,
  parameter STR_SINK_FIFOSIZE = 12,
  parameter MTU = 12,
  parameter NUM_CHAINS = 5,
  parameter COMPAT_NUM_MAJOR  = 32'h2,
  parameter COMPAT_NUM_MINOR  = 32'h0,
  parameter NUM_HB            = 3,
  parameter CIC_MAX_DECIM     = 255
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
    .STR_SINK_FIFOSIZE({NUM_CHAINS{STR_SINK_FIFOSIZE[7:0]}}),
    .MTU({NUM_CHAINS{MTU[7:0]}}),
    .USE_GATE_MASK(5'h1F))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(set_time), .set_has_time(set_has_time),
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

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_N_ADDR        = 128;
  localparam SR_M_ADDR        = 129;
  localparam SR_CONFIG_ADDR   = 130;
  localparam SR_FREQ_ADDR     = 132;
  localparam SR_SCALE_IQ_ADDR = 133;
  localparam SR_DECIM_ADDR    = 134;
  localparam SR_MUX_ADDR      = 135;
  localparam SR_COEFFS_ADDR   = 136;
  localparam RB_COMPAT_NUM    = 0;
  localparam RB_NUM_HB        = 1;
  localparam RB_CIC_MAX_DECIM = 2;
  localparam COMPAT_NUM       = {COMPAT_NUM_MAJOR, COMPAT_NUM_MINOR};

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

      // TODO Readback register for number of FIR filter taps
      always @*
        case(rb_addr[8*i+7:8*i])
          RB_COMPAT_NUM    : rb_data[64*i+63:64*i] <= {COMPAT_NUM};
          RB_NUM_HB        : rb_data[64*i+63:64*i] <= {NUM_HB};
          RB_CIC_MAX_DECIM : rb_data[64*i+63:64*i] <= {CIC_MAX_DECIM};
          default          : rb_data[64*i+63:64*i] <= 64'h0BADC0DE0BADC0DE;
        endcase

      axi_wrapper #(
        .SIMPLE_MODE(0),
        .MTU(MTU),
        .USE_SEQ_NUM(0))
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
      
      //Convert 32 bit 2 real samples into 16 bit 1 sample with 32->16 convert module
      //input m axis
      //output m axis 16
      wire [15:0]  m_axis_data16_tdata;
      wire         m_axis_data16_tlast;
      wire         m_axis_data16_tvalid;
      wire         m_axis_data16_tready;
      
      axi_fifo32_to_fifo16 axi_fifo32_to_fifo16_inst(
           .clk(ce_clk), .reset(ce_rst), .clear(),
           .i_tdata(m_axis_data_tdata),
           .i_tuser(3'b00), //need to figure out what to do with this
           .i_tlast(m_axis_data_tlast),
           .i_tvalid(m_axis_data_tvalid),
           .i_tready(m_axis_data_tready),
           .o_tdata(m_axis_data16_tdata),
           .o_tuser(),
           .o_tlast(m_axis_data16_tlast),
           .o_tvalid(m_axis_data16_tvalid),
           .o_tready(m_axis_data16_tready)
      );
  

      ////////////////////////////////////////////////////////////
      //
      // Timed Commands
      //
      ////////////////////////////////////////////////////////////
      wire [31:0]  m_axis_tagged_tdata;
      wire         m_axis_tagged_tlast;
      wire         m_axis_tagged_tvalid;
      wire         m_axis_tagged_tready;
      wire [127:0] m_axis_tagged_tuser;
      wire         m_axis_tagged_tag;

      wire         out_set_stb;
      wire [7:0]   out_set_addr;
      wire [31:0]  out_set_data;
      wire         timed_set_stb;
      wire [7:0]   timed_set_addr;
      wire [31:0]  timed_set_data;

      wire         timed_cmd_fifo_full;

      axi_tag_time #(
        .NUM_TAGS(1),
        .SR_TAG_ADDRS(SR_FREQ_ADDR))
      axi_tag_time (
        .clk(ce_clk),
        .reset(ce_rst),
        .clear(clear_tx_seqnum[i]),
        .tick_rate(16'd1),
        .timed_cmd_fifo_full(timed_cmd_fifo_full),
        .s_axis_data_tdata({m_axis_data16_tdata,16'b0}), .s_axis_data_tlast(m_axis_data16_tlast),
        .s_axis_data_tvalid(m_axis_data16_tvalid), .s_axis_data_tready(m_axis_data16_tready),
        .s_axis_data_tuser(m_axis_data_tuser),
        .m_axis_data_tdata(m_axis_tagged_tdata), .m_axis_data_tlast(m_axis_tagged_tlast),
        .m_axis_data_tvalid(m_axis_tagged_tvalid), .m_axis_data_tready(m_axis_tagged_tready),
        .m_axis_data_tuser(m_axis_tagged_tuser), .m_axis_data_tag(m_axis_tagged_tag),
        .in_set_stb(set_stb_int), .in_set_addr(set_addr_int), .in_set_data(set_data_int),
        .in_set_time(set_time_int), .in_set_has_time(set_has_time_int),
        .out_set_stb(out_set_stb), .out_set_addr(out_set_addr), .out_set_data(out_set_data),
        .timed_set_stb(timed_set_stb), .timed_set_addr(timed_set_addr), .timed_set_data(timed_set_data));

      // Hold off reading additional commands if internal FIFO is full
      assign rb_stb[i] = ~timed_cmd_fifo_full;

      ////////////////////////////////////////////////////////////
      //
      // Reduce Rate
      //
      ////////////////////////////////////////////////////////////
      wire [31:0] sample_in_tdata, sample_out_tdata;
      wire sample_in_tuser, sample_in_eob;
      wire sample_in_tvalid, sample_in_tready, sample_in_tlast;
      wire sample_out_tvalid, sample_out_tready;
      wire nc;
      wire warning_header_fifo_full;
      wire warning_long_throttle;
      wire error_extra_outputs;
      wire error_drop_pkt_lockup;
      axi_rate_change #(
        .WIDTH(33),
        .MAX_N(2040),
        .MAX_M(1),
        .SR_N_ADDR(SR_N_ADDR),
        .SR_M_ADDR(SR_M_ADDR),
        .SR_CONFIG_ADDR(SR_CONFIG_ADDR))
      axi_rate_change (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]), .clear_user(clear_user),
        .src_sid(src_sid[16*i+15:16*i]), .dst_sid(next_dst_sid[16*i+15:16*i]),
        .set_stb(out_set_stb), .set_addr(out_set_addr), .set_data(out_set_data),
        .i_tdata({m_axis_tagged_tag,m_axis_tagged_tdata}), .i_tlast(m_axis_tagged_tlast),
        .i_tvalid(m_axis_tagged_tvalid), .i_tready(m_axis_tagged_tready),
        .i_tuser(m_axis_tagged_tuser),
        .o_tdata({nc,s_axis_data_tdata}), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid),
        .o_tready(s_axis_data_tready), .o_tuser(s_axis_data_tuser),
        .m_axis_data_tdata({sample_in_tuser,sample_in_tdata}), .m_axis_data_tlast(sample_in_tlast),
        .m_axis_data_tvalid(sample_in_tvalid), .m_axis_data_tready(sample_in_tready),
        .s_axis_data_tdata({1'b0,sample_out_tdata}), .s_axis_data_tlast(1'b0),
        .s_axis_data_tvalid(sample_out_tvalid), .s_axis_data_tready(sample_out_tready),
        .warning_long_throttle(warning_long_throttle),
        .error_extra_outputs(error_extra_outputs),
        .error_drop_pkt_lockup(error_drop_pkt_lockup));
      
      assign sample_in_eob = m_axis_tagged_tuser[124]; //this should align with last packet output from axi_rate_change

      ////////////////////////////////////////////////////////////
      //
      // Digital Down Converter
      //
      ////////////////////////////////////////////////////////////
      
      ddc #(
        .SR_FREQ_ADDR(SR_FREQ_ADDR),
        .SR_SCALE_IQ_ADDR(SR_SCALE_IQ_ADDR),
        .SR_DECIM_ADDR(SR_DECIM_ADDR),
        .SR_MUX_ADDR(SR_MUX_ADDR),
        .SR_COEFFS_ADDR(SR_COEFFS_ADDR),
        .NUM_HB(NUM_HB),
        .CIC_MAX_DECIM(CIC_MAX_DECIM))
      ddc (
        .clk(ce_clk), .reset(ce_rst),
        .clear(clear_user | clear_tx_seqnum[i]), // Use AXI Rate Change's clear user to reset block to initial state after EOB
        .set_stb(out_set_stb), .set_addr(out_set_addr), .set_data(out_set_data),
        .timed_set_stb(timed_set_stb), .timed_set_addr(timed_set_addr), .timed_set_data(timed_set_data),
        .sample_in_tdata(sample_in_tdata), .sample_in_tlast(sample_in_tlast),
        .sample_in_tvalid(sample_in_tvalid), .sample_in_tready(sample_in_tready),
        .sample_in_tuser(sample_in_tuser), .sample_in_eob(sample_in_eob),
        .sample_out_tdata(sample_out_tdata), .sample_out_tlast(),
        .sample_out_tvalid(sample_out_tvalid), .sample_out_tready(sample_out_tready)
        );
        
    end
  endgenerate

endmodule
