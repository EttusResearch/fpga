//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Multi Stream Aurora Handler (Nanopitch connections)
// Input:  NUM_STREAMS=5 input streams of DATA_WIDTH=16 bits AXI Streams
//         rx_tuser includes start time.
//         Will also include device inputs for Aurora
//
// Output: NUM_STREAMS=5 output streams of DATA_WIDTH=16 bits AXI Streams
//         Will also include device outputs for Aurora.
//
// Send input streams across Aurora lane to neighbor.
// Receive output streams across Aurora lane from neighbor.
// Perform some conversion to/from 16 bit AXIS to/from 64 bit AXIS CHDR Packets.
//
// Flow of data:
// 2 seperate data paths for input and output aurora lanes
// STREAMS TO NEIGHBORS (STN) input data from streamform calc to Aurora TX
// streams_to_neighbors (16 bits @ 104 MSPS x NUM_STREAMS) ->
// stn32 (32 bits @ 52 MSPS x NUM_STREAMS) ->
// stn_s_axis_data (32 bits @ 52 MSPS x NUM_STREAMS) into AXI WRAPPER->
// stn_str_src (64 bit CHDR packets 208 MHz x NUM_STREAMS) from AXI WRAPPER ->
// stn_str_src_fifo (64 bit CHDR packets 208 MHz x NUM_STREAMS) LARGE FIFO TO STORE PACKETS ->
// aurora_s_axis (64 bit CHDR packet 208 MHz) MUX'd into 1 stream to aurora_mac core ->
// m_i (64 bit CHDR packet) in aurora phy core clock domain ->
// tx (serial device I/O)
//
// Aurora RX from neighbor to output STREAMS FROM NEIGHBORS (SFN)
// rx (serial device I/O)
// m_o (64 bit CHDR packet) in aurora phy core clock domain ->
// aurora_m_axis (64 bit CHDR packet 208 MHz) ->
// aurora_m_axis_fifo (64 bit CHDR packet 208 MHz) delays axis stream until extract dst ->
// sfn_str_sink_fifo (64 bit CHDR packet 208 MHz x NUM_STREAMS) LARGE FIFO TO STORE PACKETS ->
// sfn_str_sink (64 bit CHDR packet 208 MHz x NUM_STREAMS) into AXI WRAPPER ->
// sfn_m_axis_data (32 bits @ 208 MHz x NUM_STREAMS) ->
// sfn16 (16 bits @  x NUM_STREAMS) ->
// streams_from_neighbors (16 bits @ 104 MSPS x NUM_STREAMS)
//

module multi_stream_aurora_handler #(
  parameter NUM_STREAMS = 5,
  parameter DATA_WIDTH = 16,
  parameter AURORA_DEBUG = 0
)(
  //ce_clk
  input clk, input rst,
  //bus clk
  input bus_clk, input bus_rst,
  input clear,
  input [(NUM_STREAMS)-1:0] clear_tx_seqnum,
  //streams to neighbors
  input [127:0] rx_tuser,
  input [(NUM_STREAMS)*16-1:0] rx_src_sid,
  input [(NUM_STREAMS)*16-1:0] rx_dst_sid,
  input [(NUM_STREAMS)*DATA_WIDTH-1:0] streams_to_neighbors_tdata,
  input [(NUM_STREAMS)-1:0] streams_to_neighbors_tlast,
  input [(NUM_STREAMS)-1:0] streams_to_neighbors_tvalid,
  output [(NUM_STREAMS)-1:0] streams_to_neighbors_tready,
  output [(NUM_STREAMS)*128-1:0] streams_to_neighbors_tuser,

  //streams from neighbors
  output [(NUM_STREAMS)*DATA_WIDTH-1:0] streams_from_neighbors_tdata,
  output [(NUM_STREAMS)-1:0] streams_from_neighbors_tlast,
  output [(NUM_STREAMS)-1:0] streams_from_neighbors_tvalid,
  input [(NUM_STREAMS)-1:0] streams_from_neighbors_tready,
  output reg [(NUM_STREAMS)*128-1:0] streams_from_neighbors_tuser,

  //i/o to NPIO MGT cores synchronous to bus_clk
  input [63:0]  i_npio_tdata,
  input         i_npio_tvalid,
  input         i_npio_tlast,
  output        i_npio_tready,  

  output [63:0] o_npio_tdata,
  output        o_npio_tvalid,
  output        o_npio_tlast,
  input         o_npio_tready  
);

  //after converting from 16->32 bits (STN: STREAMS TO NEIGHBORS)
  wire [(NUM_STREAMS)*DATA_WIDTH*2-1:0] stn32_tdata;
  wire [(NUM_STREAMS)-1:0] stn32_tlast;
  wire [(NUM_STREAMS)-1:0] stn32_tvalid;
  wire [(NUM_STREAMS)-1:0] stn32_tready;

  //through a fifo to the axi wrapper for each stream (stream). (STN: STREAMS TO NEIGHBORS)
  wire [(NUM_STREAMS)*DATA_WIDTH*2-1:0] stn_s_axis_data_tdata;
  wire [(NUM_STREAMS)-1:0] stn_s_axis_data_tlast;
  wire [(NUM_STREAMS)-1:0] stn_s_axis_data_tvalid;
  wire [(NUM_STREAMS)-1:0] stn_s_axis_data_tready;
  reg [(NUM_STREAMS)*128-1:0] stn_s_axis_data_tuser;

  //o_tdata of axi_wrapper (str_src) (STN: STREAMS TO NEIGHBORS)
  wire [(NUM_STREAMS)*64-1:0] stn_str_src_tdata;
  wire [(NUM_STREAMS)-1:0] stn_str_src_tlast;
  wire [(NUM_STREAMS)-1:0] stn_str_src_tvalid;
  wire [(NUM_STREAMS)-1:0] stn_str_src_tready;
  wire [(NUM_STREAMS)*16-1:0] stn_axis_data_count;

  //through a large fifo (STN: STREAMS TO NEIGHBORS)
  wire [(NUM_STREAMS)*64-1:0] stn_str_src_fifo_tdata;
  wire [(NUM_STREAMS)-1:0] stn_str_src_fifo_tlast;
  wire [(NUM_STREAMS)-1:0] stn_str_src_fifo_tvalid;
  wire [(NUM_STREAMS)-1:0] stn_str_src_fifo_tready;

  //s_axis_tdata to user interface aurora channel (STN: STREAMS TO NEIGHBORS)
  wire [63:0] aurora_s_axis_tdata;
  wire aurora_s_axis_tlast;
  wire aurora_s_axis_tvalid;
  wire aurora_s_axis_tready;

  //active port for stn mux
  wire [3:0] mux_st_port_out;

  //m_axis_tdata to user interface aurora channel (SFN: STREAMS FROM NEIGHBORS)
  wire [63:0] aurora_m_axis_tdata;
  wire aurora_m_axis_tlast;
  wire aurora_m_axis_tvalid;
  wire aurora_m_axis_tready;

  //demux using destination from chdr packet
  reg [2:0] demux_dest;

  //output of demux to large fifo (SFN: STREAMS FROM NEIGHBORS)
  wire [(NUM_STREAMS)*64-1:0] sfn_str_sink_fifo_tdata;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_fifo_tlast;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_fifo_tvalid;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_fifo_tready;

  //TO AXI WRAPPER STR SINK input (SFN: STREAMS FROM NEIGHBORS)
  wire [(NUM_STREAMS)*64-1:0] sfn_str_sink_tdata;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_tlast;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_tvalid;
  wire [(NUM_STREAMS)-1:0] sfn_str_sink_tready;
  wire [(NUM_STREAMS)*16-1:0] sfn_axis_data_count;

  //m_axis of axi_wrapper (SFN: STREAMS FROM NEIGHBORS)
  wire [(NUM_STREAMS)*DATA_WIDTH*2-1:0] sfn_m_axis_data_tdata;
  wire [(NUM_STREAMS)-1:0] sfn_m_axis_data_tlast;
  wire [(NUM_STREAMS)-1:0] sfn_m_axis_data_tvalid;
  wire [(NUM_STREAMS)-1:0] sfn_m_axis_data_tready;
  wire [(NUM_STREAMS)*128-1:0] sfn_m_axis_data_tuser;

  //after converting from 32->16 bits (SFN: STREAMS FROM NEIGHBORS)
  wire [(NUM_STREAMS)*DATA_WIDTH-1:0] sfn16_tdata;
  wire [(NUM_STREAMS)-1:0] sfn16_tlast;
  wire [(NUM_STREAMS)-1:0] sfn16_tvalid;
  wire [(NUM_STREAMS)-1:0] sfn16_tready;

  // _tuser bit definitions
  //  [127:64] == CHDR header
  //    [127:126] == Packet type -- 00 for data, 01 for flow control, 10 for command, 11 for response
  //    [125]     == Has time? (0 for no, 1 for time field on next line)
  //    [124]     == EOB (end of burst indicator)
  //    [123:112] == 12-bit sequence number
  //    [111: 96] == 16-bit length in bytes
  //    [ 95: 80] == SRC SID (stream ID)
  //    [ 79: 64] == DST SID
  //  [ 63: 0] == timestamp

  //cvita/chdr header parser
  wire hdr_stb;
  wire [1:0] pkt_type;
  wire eob;
  wire has_time;
  wire [11:0] seqnum;
  wire [15:0] length;
  wire [15:0] payload_length;
  wire [15:0] src_sid;
  wire [15:0] dst_sid;
  wire vita_time_stb_hdr_parser;
  wire [63:0] vita_time_hdr_parser;

   //channel SIDS
  //assign channel_sids = 20'h43210;

  assign streams_to_neighbors_tuser = stn_s_axis_data_tuser;

  genvar b;
  generate
  for (b = 0; b < NUM_STREAMS; b = b + 1) begin : gen_aurora_streams

    //assign channel sids.

    ///////////////////////////////////////////////////////////////////
    //  STREAMS TO NEIGHBORS (MODULE INPUT) -> AXI WRAPPER (S_AXIS INPUT)
    ///////////////////////////////////////////////////////////////////
    //data to this and below fifo are from streamforming calculation module going to s_axis_tdata on the axi_wrapper
    axi_fifo16_to_fifo32 axi_fifo16_to_fifo32_inst(
     .clk(clk), .reset(rst), .clear(clear | clear_tx_seqnum[b]),
     .i_tdata(streams_to_neighbors_tdata[DATA_WIDTH*b+DATA_WIDTH-1:DATA_WIDTH*b]),
     .i_tuser(2'b00), //need to figure out what to do with this
     .i_tlast(streams_to_neighbors_tlast[b]),
     .i_tvalid(streams_to_neighbors_tvalid[b]),
     .i_tready(streams_to_neighbors_tready[b]),
     .o_tdata(stn32_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:DATA_WIDTH*2*b]),
     .o_tuser(),
     .o_tlast(stn32_tlast[b]),
     .o_tvalid(stn32_tvalid[b]),
     .o_tready(stn32_tready[b])
     );

    axi_fifo #(.WIDTH(33), .SIZE(1)) fifo32bit_before_axi_wrapper (
      .clk(clk), .reset(rst), .clear(clear | clear_tx_seqnum[b]),
      .i_tdata({stn32_tlast[b],stn32_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:DATA_WIDTH*2*b]}),
      .i_tvalid(stn32_tvalid[b]),
      .i_tready(stn32_tready[b]),
      .o_tdata({stn_s_axis_data_tlast[b],stn_s_axis_data_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:DATA_WIDTH*2*b]}),
      .o_tvalid(stn_s_axis_data_tvalid[b]),
      .o_tready(stn_s_axis_data_tready[b]),
      .occupied(), .space());
    ///////////////////////////////////////////////////////////////////

    //do some clever things with tuser
    always @(posedge clk) begin
      stn_s_axis_data_tuser[128*b+127:128*b] <= {rx_tuser[127:96],rx_src_sid[16*b+15:16*b],rx_dst_sid[16*b+15:16*b],rx_tuser[63:0]}; //only thing that needs to be changed is the bottom SID
    end
    //////////////////////////////////////////////////////
    // AURORA DEMUX SFN -> AXI WRAPPER SFN STR SINK
    //////////////////////////////////////////////////////
    axi_fifo #(.WIDTH(65), .SIZE(11)) sfn_16k_fifo
      (.clk(bus_clk), .reset(bus_rst), .clear(clear | clear_tx_seqnum[b]),
      .i_tdata({sfn_str_sink_fifo_tlast[b],sfn_str_sink_fifo_tdata[64*b+63:64*b]}),
      .i_tvalid(sfn_str_sink_fifo_tvalid[b]), .i_tready(sfn_str_sink_fifo_tready[b]),
      .o_tdata({sfn_str_sink_tlast[b],sfn_str_sink_tdata[64*b+63:64*b]}),
      .o_tvalid(sfn_str_sink_tvalid[b]), .o_tready(sfn_str_sink_tready[b]),
      .occupied(sfn_axis_data_count[16*b+15:16*b]), .space());

    //Need this clock crossing to get data into bus_clk domain for npio core axis
    axi_wrapper #(
      .MTU(10),
      .SIMPLE_MODE(0),
      .USE_SEQ_NUM(1))
    inst_axi_wrapper (
      .clk(clk), .reset(rst),
      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .clear_tx_seqnum(clear | clear_tx_seqnum[b]),
      .next_dst(0), //need to figure out how to handle this guy
      .set_stb(0), .set_addr(0), .set_data(0),
      .i_tdata(sfn_str_sink_tdata[DATA_WIDTH*4*b+4*DATA_WIDTH-1:DATA_WIDTH*4*b]), //input from aurora
      .i_tlast(sfn_str_sink_tlast[b]),
      .i_tvalid(sfn_str_sink_tvalid[b]),
      .i_tready(sfn_str_sink_tready[b]),
      .o_tdata(stn_str_src_tdata[DATA_WIDTH*4*b+4*DATA_WIDTH-1:DATA_WIDTH*4*b]), //output to aurora
      .o_tlast(stn_str_src_tlast[b]),
      .o_tvalid(stn_str_src_tvalid[b]),
      .o_tready(stn_str_src_tready[b]),
      .m_axis_data_tdata(sfn_m_axis_data_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:DATA_WIDTH*2*b]), //output stream
      .m_axis_data_tlast(sfn_m_axis_data_tlast[b]),
      .m_axis_data_tvalid(sfn_m_axis_data_tvalid[b]),
      .m_axis_data_tready(sfn_m_axis_data_tready[b]),
      .m_axis_data_tuser(sfn_m_axis_data_tuser[128*b+127:128*b]), //extract time out of this for time alignment in received data
      .s_axis_data_tdata(stn_s_axis_data_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:DATA_WIDTH*2*b]), //input stream
      .s_axis_data_tlast(stn_s_axis_data_tlast[b]),
      .s_axis_data_tvalid(stn_s_axis_data_tvalid[b]),
      .s_axis_data_tready(stn_s_axis_data_tready[b]),
      .s_axis_data_tuser(stn_s_axis_data_tuser[128*b+127:128*b]), //need to do clever things with inserting the vita_time into this.
      .m_axis_pkt_len_tdata(),
      .m_axis_pkt_len_tvalid(),
      .m_axis_pkt_len_tready(),
      .m_axis_config_tdata(),
      .m_axis_config_tlast(),
      .m_axis_config_tvalid(),
      .m_axis_config_tready());

    always @(posedge clk) begin
      streams_from_neighbors_tuser[128*b+127:128*b] <= sfn_m_axis_data_tuser[128*b+127:128*b];
    end
    //assign demux_dest = sfn_m_axis_data_tuser[67:64];

    //////////////////////////////////////////////////////
    // AXI WRAPPER STR CHD PACKETS -> AURORA (STREAM TO NEIGHBOR) LARGE FIFO BEFORE MUX
    //////////////////////////////////////////////////////
    axi_fifo #(.WIDTH(65), .SIZE(11)) stn_16k_fifo
      (.clk(bus_clk), .reset(bus_rst), .clear(clear | clear_tx_seqnum[b]),
      .i_tdata({stn_str_src_tlast[b],stn_str_src_tdata[64*b+63:64*b]}),
      .i_tvalid(stn_str_src_tvalid[b]), .i_tready(stn_str_src_tready[b]),
      .o_tdata({stn_str_src_fifo_tlast[b],stn_str_src_fifo_tdata[64*b+63:64*b]}),
      .o_tvalid(stn_str_src_fifo_tvalid[b]), .o_tready(stn_str_src_fifo_tready[b]),
      .occupied(stn_axis_data_count[16*b+15:16*b]), .space());

    ///////////////////////////////////////////////////////////////////////
    // AXI WRAPPER M AXIS SFN  -> STREAMS FROM NEIGHBORS (MODULE OUTPUT)
    ///////////////////////////////////////////////////////////////////////
    // take 32 bit m_axis from demux
    axi_fifo32_to_fifo16 axi_fifo32_to_fifo16_inst(
      .clk(clk), .reset(rst), .clear(clear | clear_tx_seqnum[b]),
      .i_tdata(sfn_m_axis_data_tdata[DATA_WIDTH*2*b+2*DATA_WIDTH-1:2*DATA_WIDTH*b]),
      .i_tuser(3'b00), //need to figure out what to do with this
      .i_tlast(sfn_m_axis_data_tlast[b]),
      .i_tvalid(sfn_m_axis_data_tvalid[b]),
      .i_tready(sfn_m_axis_data_tready[b]),
      .o_tdata(sfn16_tdata[DATA_WIDTH*b+DATA_WIDTH-1:DATA_WIDTH*b]),
      .o_tuser(),
      .o_tlast(sfn16_tlast[b]),
      .o_tvalid(sfn16_tvalid[b]),
      .o_tready(sfn16_tready[b])
    );

    //output of this axi_fifo is final output of this module.
    axi_fifo #(.WIDTH(17), .SIZE(1)) fifo16bit_after_axi_wrapper (
      .clk(clk), .reset(rst), .clear(clear | clear_tx_seqnum[b]),
      .i_tdata({sfn16_tlast[b],sfn16_tdata[DATA_WIDTH*b+DATA_WIDTH-1:DATA_WIDTH*b]}),
      .i_tvalid(sfn16_tvalid[b]),
      .i_tready(sfn16_tready[b]),
      .o_tdata({streams_from_neighbors_tlast[b],streams_from_neighbors_tdata[DATA_WIDTH*b+DATA_WIDTH-1:DATA_WIDTH*b]}),
      .o_tvalid(streams_from_neighbors_tvalid[b]),
      .o_tready(streams_from_neighbors_tready[b]),
      .occupied(), .space());
     ///////////////////////////////////////////////////////////////////////

  end
  endgenerate

  ////////////////////////////////////////////////////////////////////
  // CHDR PACKET FROM AXI WRAPPER -> MUX'd to AUROR (S_AXIS INPUT)
  ////////////////////////////////////////////////////////////////////
  //takes in 5 data streams, and switches between them
  //needs some sort of logic in the valid signal based on the occupied/space of the previous axi_fifo
  axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(2), .POST_FIFO_SIZE(1), .SIZE(NUM_STREAMS)) aurora_axi_mux (
    .clk(bus_clk), .reset(bus_rst), .clear(clear | {|clear_tx_seqnum}),
    .i_tdata(stn_str_src_fifo_tdata),
    .i_tlast(stn_str_src_fifo_tlast),
    .i_tvalid(stn_str_src_fifo_tvalid),
    .i_tready(stn_str_src_fifo_tready),
    .o_tdata(aurora_s_axis_tdata),
    .o_tlast(aurora_s_axis_tlast),
    .o_tvalid(aurora_s_axis_tvalid),
    .o_tready(aurora_s_axis_tready));

  ///////////////////////////////////////////////////
  // AURORA M AXIS FIFO -> DEMUX'd to AXI WRAPPER STR SINK
  ///////////////////////////////////////////////////
  //might need to delay input of this
  axi_demux #(.WIDTH(64), .PRE_FIFO_SIZE(2), .POST_FIFO_SIZE(2), .SIZE(NUM_STREAMS)) axi_demux (
    .clk(bus_clk), .reset(bus_rst), .clear(clear | {|clear_tx_seqnum}),
    .header(), .dest(demux_dest), //get header from axi
    .i_tdata(aurora_m_axis_tdata),
    .i_tlast(aurora_m_axis_tlast),
    .i_tvalid(aurora_m_axis_tvalid),
    .i_tready(aurora_m_axis_tready),
    .o_tdata(sfn_str_sink_fifo_tdata),
    .o_tlast(sfn_str_sink_fifo_tlast),
    .o_tvalid(sfn_str_sink_fifo_tvalid),
    .o_tready(sfn_str_sink_fifo_tready));

  // Extracts header fields from CHDR packet
  cvita_hdr_parser #(.REGISTER(0)) cvita_hdr_parser (
    .clk(bus_clk), .reset(bus_rst), .clear(clear | {|clear_tx_seqnum}),
    .hdr_stb(hdr_stb),
    .pkt_type(pkt_type), .eob(eob), .has_time(has_time),
    .seqnum(seqnum), .length(length), .payload_length(payload_length),
    .src_sid(src_sid), .dst_sid(dst_sid),
    .vita_time_stb(vita_time_stb_hdr_parser), .vita_time(vita_time_hdr_parser),
    .i_tdata(aurora_m_axis_tdata), .i_tlast(aurora_m_axis_tlast), .i_tvalid(aurora_m_axis_tvalid), .i_tready(),
    .o_tdata(), .o_tlast(), .o_tvalid(), .o_tready(1'b1));

  always @ (posedge bus_clk)
    if (hdr_stb)
      demux_dest <= src_sid[2:0];

  //figure out header stuff from m_axis_tuser
generate
if (AURORA_DEBUG == 1) begin
  //DEBUG TEST just loop this back, good for simulation.
  assign aurora_m_axis_tdata = aurora_s_axis_tdata;
  assign aurora_m_axis_tvalid = aurora_s_axis_tvalid;
  assign aurora_m_axis_tlast = aurora_s_axis_tlast;
  assign aurora_s_axis_tready = aurora_m_axis_tready;
end else begin
//attach to 64 bit axi bus I/O which attaches to NPIO wrapper core
  assign aurora_m_axis_tdata = i_npio_tdata;
  assign aurora_m_axis_tvalid = i_npio_tvalid;
  assign aurora_m_axis_tlast = i_npio_tlast;
  assign i_npio_tready = aurora_m_axis_tready;
  assign o_npio_tdata = aurora_s_axis_tdata;
  assign o_npio_tvalid = aurora_s_axis_tvalid;
  assign o_npio_tlast = aurora_s_axis_tlast;
  assign aurora_s_axis_tready = o_npio_tready;
end
endgenerate

endmodule
