//
// Copyright 2016 Ettus Research
//
// - Tracks and fills out header information for an axi stream that is
//   asynchronous or does not have a 1:1 input / output ratio.
// - User must still pass through all received words and uses the tkeep
//   signal to flag which words to keep.
// - This module is not intended to work with decimation / interpolation blocks.
//
// Open design questions:
// - User specifies end of packet with i_tlast.
//   What if two separate tkeep "bursts" occur in a single packet?
//   The VITA time is only valid for the first "burst" due to the gap.
//   Should this module generate an internal tlast causing it to output
//   two packets in this case? Or should the responsibility be on the user
//   to assert tlast twice?
// - If tkeep bursts occurs between packet boundaries, an internal tlast is
//   generated splitting the burst up into two (or more) packets. This is 
//   an easy way to make sure the packet sizes are bounded and the VITA
//   time is correct. Is this desirable, since the downstream block
//   will likely want the full burst and is then forced to aggregate packets?
//

module cvita_async_stream #(
  parameter WIDTH            = 32,
  parameter HEADER_WIDTH     = 128,
  parameter HEADER_FIFO_SIZE = 5,
  parameter MAX_TICK_RATE    = 2**16-1)
(
  input clk,
  input reset,
  input clear,
  input [15:0] src_sid,
  input [15:0] dst_sid,
  input [$clog2(MAX_TICK_RATE)-1:0] tick_rate,
  output header_fifo_full,
  input [WIDTH-1:0] s_axis_data_tdata,
  input [HEADER_WIDTH-1:0] s_axis_data_tuser,
  input s_axis_data_tlast,
  input s_axis_data_tvalid,
  input s_axis_data_tready,
  input [WIDTH-1:0] i_tdata,
  input i_tlast,
  input i_tvalid,
  input i_tkeep,
  output i_tready,
  output [WIDTH-1:0] m_axis_data_tdata,
  output [HEADER_WIDTH-1:0] m_axis_data_tuser,
  output m_axis_data_tlast,
  output m_axis_data_tvalid,
  input m_axis_data_tready
);

  reg first_word;
  wire header_in_tready;
  wire [HEADER_WIDTH-1:0] header_out_tdata;
  wire header_out_tvalid, header_out_tready;

  reg [15:0] word_cnt;
  reg [16+$clog2(MAX_TICK_RATE)-1:0] time_cnt; // 16 bit payload length + max tick rate increment

  wire [63:0] vita_time;
  wire [15:0] payload_length;

  // Track first word to make sure header is read only once per packet
  always @(posedge clk) begin
    if (reset | clear) begin
      first_word <= 1'b1;
    end else begin
      if (s_axis_data_tvalid) begin
        if (first_word) begin
          first_word <= 1'b0;
        end else if (s_axis_data_tlast & s_axis_data_tready) begin
          first_word <= 1'b1;
        end
      end
    end
  end

  // Header FIFO
  axi_fifo #(.WIDTH(HEADER_WIDTH), .SIZE(HEADER_FIFO_SIZE)) axi_fifo (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(s_axis_data_tuser), .i_tvalid(s_axis_data_tvalid & first_word), .i_tready(header_in_tready),
    .o_tdata(header_out_tdata), .o_tvalid(header_out_tvalid), .o_tready(header_out_tready),
    .space(), .occupied());
  assign header_out_tready = i_tvalid & i_tready & (word_cnt >= payload_length);
  assign header_fifo_full = ~header_in_tready;

  // Track VITA time offset and word count for emptying header FIFO
  always @(posedge clk) begin
    if (reset | clear) begin
      word_cnt       <= WIDTH/8;
      time_cnt       <= 0;
    end else begin
      if (i_tvalid & i_tready) begin
        if (word_cnt >= payload_length) begin
          word_cnt <= WIDTH/8;
          time_cnt <= 0;
        end else begin
          word_cnt <= word_cnt + WIDTH/8;
          time_cnt <= time_cnt + tick_rate;
        end
      end
    end
  end

  // Form output header
  cvita_hdr_decoder cvita_hdr_decoder (
    .header(header_out_tdata),
    .pkt_type(), .eob(), .has_time(),
    .seqnum(), .payload_length(payload_length),
    .src_sid(), .dst_sid(),
    .vita_time(vita_time));

  cvita_hdr_modify cvita_hdr_modify (
    .header_in(header_out_tdata),
    .header_out(m_axis_data_tuser),
    .use_pkt_type(1'b0),       .pkt_type(),
    .use_has_time(1'b0),       .has_time(),
    .use_eob(1'b0),            .eob(),
    .use_seqnum(1'b0),         .seqnum(), // AXI Wrapper handles this
    .use_length(1'b0),         .length(), // AXI Wrapper handles this
    .use_payload_length(1'b0), .payload_length(),
    .use_src_sid(1'b1),        .src_sid(src_sid),
    .use_dst_sid(1'b1),        .dst_sid(dst_sid),
    .use_vita_time(1'b1),      .vita_time(vita_time + time_cnt));

  wire ready;
  reg [31:0] pipe0_tdata, pipe1_tdata;
  reg pipe0_tvalid, pipe1_tvalid;
  reg pipe0_tlast, pipe1_tlast;
  reg pipe0_tkeep;
  always @(posedge clk) begin
    if (reset | clear) begin
      pipe0_tdata        <= 'd0;
      pipe0_tvalid       <= 1'b0;
      pipe0_tlast        <= 1'b0;
      pipe0_tkeep        <= 1'b0;
      pipe1_tdata        <= 'd0;
      pipe1_tvalid       <= 1'b0;
      pipe1_tlast        <= 1'b0;
    end else begin
      if ((ready & i_tvalid) | ~pipe0_tvalid) begin
        pipe0_tdata    <= i_tdata;
        pipe0_tvalid   <= i_tvalid;
        pipe0_tlast    <= i_tlast | (word_cnt >= payload_length);
        pipe0_tkeep    <= i_tkeep;
      end
      if (ready & i_tvalid & pipe0_tvalid) begin
        pipe1_tdata    <= pipe0_tdata;
        pipe1_tvalid   <= pipe0_tvalid & pipe0_tkeep;
        pipe1_tlast    <= pipe0_tlast | ~i_tkeep;
      end
    end
  end

  assign ready              = m_axis_data_tready & header_out_tvalid;
  assign i_tready           = ready | ~pipe0_tvalid;
  assign m_axis_data_tdata  = pipe1_tdata;
  assign m_axis_data_tvalid = pipe1_tvalid;
  assign m_axis_data_tlast  = pipe1_tlast;

endmodule