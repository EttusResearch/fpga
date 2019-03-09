//
// Copyright 2016 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Special NoC Block where the internal NoC Shell / AXI Wrapper interfaces are exposed via ports.
// Created for use with RFNoC test benches.

module noc_block_export_io
#(
  parameter NOC_ID = 64'hFFFF_FFFF_FFFF_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter MTU = 11,
  parameter NUM_PORTS = 1,
  parameter USE_SEQ_NUM = 0  // 0: Use sequence number from AXI Wrapper & s_cvita_data header,
                             //    Warning: Sequence number can get out of sync if using both
                             //             s_axis_data and s_cvita_data on the same block port
                             //             which could break flow control / cause a lockup
                             // 1: Recalculate automatically, generally use this option
)(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  // Interface to crossbar
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  /* Export user signals */
  // Settings bus
  output [NUM_PORTS-1:0] set_stb, output [NUM_PORTS*32-1:0] set_data, output [NUM_PORTS*8-1:0] set_addr,
  input [NUM_PORTS-1:0] rb_stb, output [NUM_PORTS*8-1:0] rb_addr,   input [NUM_PORTS*64-1:0] rb_data,
  // CVITA command and response interfaces, interfaces directly to NoC Shell
  input [63:0] s_cvita_cmd_tdata, input s_cvita_cmd_tlast, input s_cvita_cmd_tvalid, output s_cvita_cmd_tready,
  output [63:0] m_cvita_ack_tdata, output m_cvita_ack_tlast, output m_cvita_ack_tvalid, input m_cvita_ack_tready,
  // CVITA data & AXI stream interfaces
  // - One per block port
  // - Share interface with NoC Shell via mux / demux logic
  input [NUM_PORTS*64-1:0] s_cvita_data_tdata, input [NUM_PORTS-1:0] s_cvita_data_tlast,
  input [NUM_PORTS-1:0] s_cvita_data_tvalid, output [NUM_PORTS-1:0] s_cvita_data_tready,
  output [NUM_PORTS*64-1:0] m_cvita_data_tdata, output [NUM_PORTS-1:0] m_cvita_data_tlast,
  output [NUM_PORTS-1:0] m_cvita_data_tvalid, input [NUM_PORTS-1:0] m_cvita_data_tready,
  input [NUM_PORTS*32-1:0] s_axis_data_tdata, input [NUM_PORTS-1:0] s_axis_data_tlast,
  input [NUM_PORTS-1:0] s_axis_data_tvalid, output [NUM_PORTS-1:0] s_axis_data_tready,
  output [NUM_PORTS*32-1:0] m_axis_data_tdata, output [NUM_PORTS-1:0] m_axis_data_tlast,
  output [NUM_PORTS-1:0] m_axis_data_tvalid, input [NUM_PORTS-1:0] m_axis_data_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [NUM_PORTS*64-1:0] str_sink_tdata, str_src_tdata;
  wire [NUM_PORTS-1:0]    str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;
  wire [NUM_PORTS*64-1:0] str_sink_tdata_bclk, str_src_tdata_bclk;
  wire [NUM_PORTS-1:0]    str_sink_tlast_bclk, str_sink_tvalid_bclk, str_sink_tready_bclk, str_src_tlast_bclk, str_src_tvalid_bclk, str_src_tready_bclk;

  wire [NUM_PORTS-1:0]         clear_tx_seqnum;
  wire [NUM_PORTS*16-1:0]      src_sid, next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_PORTS),
    .OUTPUT_PORTS(NUM_PORTS),
    .USE_GATE_MASK({NUM_PORTS{1'b1}}),
    .STR_SINK_FIFOSIZE({NUM_PORTS{STR_SINK_FIFOSIZE[7:0]}}),
    .MTU({NUM_PORTS{MTU[7:0]}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(), .set_has_time(),
    .rb_stb(rb_stb), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(s_cvita_cmd_tdata), .cmdout_tlast(s_cvita_cmd_tlast), .cmdout_tvalid(s_cvita_cmd_tvalid), .cmdout_tready(s_cvita_cmd_tready),
    .ackin_tdata(m_cvita_ack_tdata), .ackin_tlast(m_cvita_ack_tlast), .ackin_tvalid(m_cvita_ack_tvalid), .ackin_tready(m_cvita_ack_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata_bclk), .str_sink_tlast(str_sink_tlast_bclk), .str_sink_tvalid(str_sink_tvalid_bclk), .str_sink_tready(str_sink_tready_bclk),
    // Stream Source
    .str_src_tdata(str_src_tdata_bclk), .str_src_tlast(str_src_tlast_bclk), .str_src_tvalid(str_src_tvalid_bclk), .str_src_tready(str_src_tready_bclk),
    // Misc
    .vita_time(64'd0), .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // Instantiate AXI Wrapper and Mux / Demux with CVITA interface
  //
  ////////////////////////////////////////////////////////////
  genvar i;
  generate
    for (i = 0; i < NUM_PORTS; i = i + 1) begin
      axi_fifo_2clk #(
        .WIDTH(65), .SIZE(5)
      ) str_sink_2clk_i (
        .reset(bus_rst), .i_aclk(bus_clk),
        .i_tdata({str_sink_tlast_bclk[i], str_sink_tdata_bclk[64*i+63:64*i]}), .i_tvalid(str_sink_tvalid_bclk[i]), .i_tready(str_sink_tready_bclk[i]),
        .o_aclk(ce_clk),
        .o_tdata({str_sink_tlast[i], str_sink_tdata[64*i+63:64*i]}), .o_tvalid(str_sink_tvalid[i]), .o_tready(str_sink_tready[i])
      );
    
      axi_fifo_2clk #(
        .WIDTH(65), .SIZE(5)
      ) str_src_2clk_i (
        .reset(ce_rst), .i_aclk(ce_clk),
        .i_tdata({str_src_tlast[i], str_src_tdata[64*i+63:64*i]}), .i_tvalid(str_src_tvalid[i]), .i_tready(str_src_tready[i]),
        .o_aclk(bus_clk),
        .o_tdata({str_src_tlast_bclk[i], str_src_tdata_bclk[64*i+63:64*i]}), .o_tvalid(str_src_tvalid_bclk[i]), .o_tready(str_src_tready_bclk[i])
      );

      wire [63:0] aw_i_tdata, aw_o_tdata;
      wire        aw_i_tlast, aw_i_tvalid, aw_i_tready, aw_o_tlast, aw_o_tvalid, aw_o_tready;

      wire [127:0] s_axis_data_tuser = {2'd0 /* Data */, 1'b0 /* No time */, 1'b0 /* No EOB */,
                                        28'd0 /* Seq num & length automatically handled */,
                                        src_sid[16*i+15:16*i], next_dst_sid[16*i+15:16*i], 64'd0};

      axi_wrapper #(
        .MTU(MTU),
        .NUM_AXI_CONFIG_BUS(1),
        .SIMPLE_MODE(0))
      axi_wrapper (
        .bus_clk(ce_clk), .bus_rst(ce_rst),
        .clk(ce_clk), .reset(ce_rst),
        .clear_tx_seqnum(clear_tx_seqnum[0]),
        .next_dst(),
        .set_stb(), .set_addr(), .set_data(),
        .i_tdata(aw_i_tdata), .i_tlast(aw_i_tlast), .i_tvalid(aw_i_tvalid), .i_tready(aw_i_tready),
        .o_tdata(aw_o_tdata), .o_tlast(aw_o_tlast), .o_tvalid(aw_o_tvalid), .o_tready(aw_o_tready),
        .m_axis_data_tdata(m_axis_data_tdata[32*i+31:32*i]),
        .m_axis_data_tlast(m_axis_data_tlast[i]),
        .m_axis_data_tvalid(m_axis_data_tvalid[i]),
        .m_axis_data_tready(m_axis_data_tready[i]),
        .m_axis_data_tuser(), // Unused
        .s_axis_data_tdata(s_axis_data_tdata[32*i+31:32*i]),
        .s_axis_data_tlast(s_axis_data_tlast[i]),
        .s_axis_data_tvalid(s_axis_data_tvalid[i]),
        .s_axis_data_tready(s_axis_data_tready[i]),
        .s_axis_data_tuser(s_axis_data_tuser),
        .m_axis_config_tdata(),
        .m_axis_config_tlast(),
        .m_axis_config_tvalid(),
        .m_axis_config_tready(),
        .m_axis_pkt_len_tdata(),
        .m_axis_pkt_len_tvalid(),
        .m_axis_pkt_len_tready());

      // Demux input stream into either CVITA inteface, AXI stream interface, or both depend on their tready state
      // - Wait until header comes in then select whether to output on via AXI Wrapper or CVITA interface
      //   depending on which one is ready. If both are ready, output on both.
      reg hold_until_ready = 1'b1;
      reg [3:0] output_streams;  // 0: Invalid, 1: AXI Wrapper, 2: CVITA, 3: Both AXI Wrapper & CVITA
      always @(posedge ce_clk) begin
        if (ce_rst | clear_tx_seqnum[i]) begin
          hold_until_ready <= 1'b1;
          output_streams   <= 4'b0;
        end else begin
          // Demux to stream that ready to accept data (or both if both are ready)
          if (hold_until_ready & str_sink_tvalid[i] & (m_cvita_data_tready[i] | m_axis_data_tready[i])) begin
            hold_until_ready <= 1'b0;
            output_streams   <= {2'b0, m_cvita_data_tready[i], m_axis_data_tready[i]};
          end
          if (str_sink_tlast[i] & str_sink_tvalid[i] & str_sink_tready[i]) begin
            hold_until_ready <= 1'b1;
            output_streams   <= 4'b0;
          end
        end
      end

      wire str_sink_tvalid_int, str_sink_tready_int;
      assign str_sink_tready[i]  = str_sink_tready_int & ~hold_until_ready;
      assign str_sink_tvalid_int = str_sink_tvalid[i] & ~hold_until_ready;

      wire [63:0] m_cvita_tdata, m_axis_tdata;
      wire m_cvita_tlast, m_cvita_tvalid, m_cvita_tready, m_axis_tlast, m_axis_tvalid, m_axis_tready;
      wire [63:0] invalid_tdata, both_tdata;
      wire invalid_tlast, invalid_tvalid, both_tlast, both_tvalid, both_tready;
      axi_demux #(.WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0), .SIZE(4)) axi_demux (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
        .header(), .dest(output_streams),
        .i_tdata(str_sink_tdata[64*i+63:64*i]), .i_tlast(str_sink_tlast[i]), .i_tvalid(str_sink_tvalid_int), .i_tready(str_sink_tready_int),
        .o_tdata({both_tdata,m_cvita_tdata,m_axis_tdata,invalid_tdata}),
        .o_tlast({both_tlast,m_cvita_tlast,m_axis_tlast,invalid_tlast}),
        .o_tvalid({both_tvalid,m_cvita_tvalid,m_axis_tvalid,invalid_tvalid}),
        .o_tready({both_tready,m_cvita_tready,m_axis_tready,1'b0 /* Never output on invalid stream */}));

      assign m_cvita_data_tdata[64*i+63:64*i] = both_tvalid ? both_tdata : m_cvita_tdata;
      assign m_cvita_data_tlast[i]            = both_tvalid ? both_tlast : m_cvita_tlast;
      assign m_cvita_data_tvalid[i]           = both_tvalid ? 1'b1       : m_cvita_tvalid;
      assign m_cvita_tready                   = both_tvalid ? 1'b0       : m_cvita_data_tready[i];
      assign aw_i_tdata                       = both_tvalid ? both_tdata : m_axis_tdata;
      assign aw_i_tlast                       = both_tvalid ? both_tlast : m_axis_tlast;
      assign aw_i_tvalid                      = both_tvalid ? 1'b1       : m_axis_tvalid;
      assign m_axis_tready                    = both_tvalid ? 1'b0       : aw_i_tready;
      assign both_tready                      = both_tvalid ? 1'b0       : m_cvita_data_tready[i] & m_axis_data_tready[i];

      // Mux CVITA and AXI stream interfaces
      // - If USE_SEQ_NUM = 1, replace sequence number in header so it is consistent even
      //   if using both the AXI Wrapper and CVITA interfaces.
      wire hdr_stb, vita_time_stb;
      wire [1:0] pkt_type;
      wire eob, has_time;
      wire [15:0] payload_length;
      wire [15:0] src_sid_x;
      wire [15:0] dst_sid;
      wire [63:0] vita_time;
      wire [63:0] str_src_tdata_int, str_src_tdata_mux;
      wire str_src_tlast_mux, str_src_tvalid_mux, str_src_tready_mux;
      reg [11:0] tx_seqnum_cnt;
      // Logic to control replacing sequence number
      always @(posedge ce_clk) begin
        if (ce_rst | clear_tx_seqnum[i]) begin
          tx_seqnum_cnt   <= 'd0;
        end else begin
          if (str_src_tlast[i] & str_src_tvalid[i] & str_src_tready[i]) begin
            tx_seqnum_cnt <= tx_seqnum_cnt + 1'b1;
          end
        end
      end

      cvita_hdr_parser #(.REGISTER(0)) cvita_hdr_parser (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
        .hdr_stb(hdr_stb),
        .pkt_type(pkt_type), .eob(eob), .has_time(has_time),
        .seqnum(), .length(), .payload_length(payload_length),
        .src_sid(src_sid_x), .dst_sid(dst_sid),
        .vita_time_stb(vita_time_stb), .vita_time(vita_time),
        .i_tdata(str_src_tdata_mux), .i_tlast(str_src_tlast_mux), .i_tvalid(str_src_tvalid_mux), .i_tready(str_src_tready_mux),
        .o_tdata(str_src_tdata_int), .o_tlast(str_src_tlast[i]), .o_tvalid(str_src_tvalid[i]), .o_tready(str_src_tready[i]));

      wire [127:0] modified_header;
      cvita_hdr_encoder cvita_hdr_encoder (
        .pkt_type(pkt_type), .eob(eob), .has_time(has_time),
        .seqnum(tx_seqnum_cnt), .payload_length(payload_length),
        .src_sid(src_sid_x), .dst_sid(dst_sid),
        .vita_time(vita_time),
        .header(modified_header));

      assign str_src_tdata[64*i+63:64*i] = (USE_SEQ_NUM == 1) ? str_src_tdata_int :
                                                      hdr_stb ? modified_header[127:64] :
                                                vita_time_stb ? modified_header[63:0] :
                                                                str_src_tdata_int;

      axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0), .SIZE(2)) axi_mux (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
        .i_tdata({s_cvita_data_tdata[64*i+63:64*i], aw_o_tdata}), .i_tlast({s_cvita_data_tlast[i], aw_o_tlast}),
        .i_tvalid({s_cvita_data_tvalid[i], aw_o_tvalid}), .i_tready({s_cvita_data_tready[i], aw_o_tready}),
        .o_tdata(str_src_tdata_mux), .o_tlast(str_src_tlast_mux), .o_tvalid(str_src_tvalid_mux), .o_tready(str_src_tready_mux));

    end
  endgenerate

endmodule