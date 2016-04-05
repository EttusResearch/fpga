//
// Copyright 2016 Ettus Research
//
// Adapts rate between input and output
// - Supports N:1 and 1:N rates
// - Can accept CVITA packets and handle header (on tuser) automatically
//   > Set i_tuser to 0 and ignore i_tuser if using AXI stream without CVITA packetization
// - Can optionally inject zeros on EOB to push out data in filters / blocks with 
//   internal state / pipelining. Most AXI stream based designs should not
//   require this, but legacy strobed blocks may benefit from this feature.
//   > Requires user block to use m_axis_data_teob / s_axis_data_teob.
//   > Optional clear eob bit will be strobed after injecting zeros ends, allowing blocks
//     such as filter to be automatically reset at the end of a burst.
// Limitations:
// - Input packet size must match output packet size
//

module axi_rate_change #(
  parameter WIDTH               = 32,  // Input bit width
  parameter REDUCE_RATE         = 1,   // 0: Increase rate, 1: Decrease rate
  parameter MAX_RATE            = 1,   // Maximum input packets consumed per output
  parameter MAX_PKT_SIZE        = 256, // Maximum output packet size
  parameter HEADER_FIFO_SIZE    = 5,   // Default should generally work unless user block has deep pipelining and uses short packets
  parameter EN_DROP_PARTIAL_PKT = 0,   // Enable support for dropping partial packets, adds extra FIFO of depth log2(MAX_PKT_SIZE)
  parameter SR_RATE             = 0,
  parameter SR_CONFIG           = 1,
  parameter SR_PKT_SIZE         = 2,
  parameter SR_DROP_PARTIAL_PKT = 3    // Only used if EN_DROP_PARTIAL_PKT == 1
)(
  input clk, input reset, input clear, output reg clear_eob,
  input [15:0] src_sid, input [15:0] dst_sid,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready, input [127:0] i_tuser,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready, output [127:0] o_tuser,
  output [WIDTH-1:0] m_axis_data_tdata, output m_axis_data_tlast, output m_axis_data_tvalid, input m_axis_data_tready, output m_axis_data_teob,
  input [WIDTH-1:0] s_axis_data_tdata, input s_axis_data_tlast, input s_axis_data_tvalid, output s_axis_data_tready, input s_axis_data_teob
);

  wire [$clog2(MAX_RATE+1)-1:0] rate;
  setting_reg #(.my_addr(SR_RATE), .width($clog2(MAX_RATE+1)), .at_reset(1 /* Default no rate change */)) sr_rate (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(rate), .changed());

  wire enable_clear_eob;    // Enable strobing clear_eob between bursts. Causes a single cycle bubble.
  wire enable_inject_zeros; // Enable injecting zeros at the end of a burst to clear out pipeline.
  setting_reg #(.my_addr(SR_CONFIG), .width(2), .at_reset(2'b0)) sr_config (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out({enable_clear_eob,enable_inject_zeros}), .changed());

  wire [$clog2(MAX_PKT_SIZE+1)-1:0] pkt_size;
  setting_reg #(
    .my_addr(SR_PKT_SIZE), .width($clog2(MAX_PKT_SIZE+1)),
    .at_reset(0)) // If user forgets to set this, will cause a lock up in this block
  sr_pkt_size (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(pkt_size), .changed());

  wire [127:0] header_fifo_tdata, header_tdata;
  wire header_fifo_tvalid, header_fifo_tready, header_tvalid, header_tready;
  generate
    if (REDUCE_RATE == 1) begin
      reg first_line = 1'b1;
      reg [$clog2(MAX_PKT_SIZE+1)-1:0] counter = WIDTH/8;
      always @(posedge clk) begin
        if (reset | clear) begin
          first_line   <= 1'b1;
          counter      <= WIDTH/8;
        end else begin
          if (first_line & i_tvalid & i_tready) begin
            first_line <= 1'b0;
          end
          if (i_tvalid & i_tlast & i_tready) begin
            first_line <= 1'b1;
          end
          if (s_axis_data_tvalid & s_axis_data_tready) begin
            if ((counter >= pkt_size) | (s_axis_data_tlast & s_axis_data_teob)) begin
              counter      <= WIDTH/8;
            end else begin
              counter      <= counter + 1'b1;
            end
          end
        end
      end

      keep_one_in_n #(
        .WIDTH(128),
        .KEEP_FIRST(1),  // Keep first header in set of n headers instead of last
        .MAX_N(MAX_RATE))
      keep_one_in_n (
        .clk(clk), .reset(reset | clear),
        .n(rate), .vector_mode(1'b1),
        .i_tdata(i_tuser), .i_tlast(1'b1), .i_tvalid(i_tvalid & first_line & i_tready), .i_tready(),
        .o_tdata(header_fifo_tdata), .o_tlast(), .o_tvalid(header_fifo_tvalid), .o_tready(header_fifo_tready));

      // Small FIFO to absorb pipeline latency
      axi_fifo #(.WIDTH(128), .SIZE(HEADER_FIFO_SIZE)) axi_fifo (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(header_fifo_tdata), .i_tvalid(header_fifo_tvalid), .i_tready(header_fifo_tready),
        .o_tdata(header_tdata), .o_tvalid(header_tvalid), .o_tready(header_tready),
        .space(), .occupied());
      assign header_tready = s_axis_data_tvalid & s_axis_data_tready &
                             ((counter >= pkt_size) | (s_axis_data_tlast & s_axis_data_teob));

    end else begin // Interpolate
      
    end
  endgenerate

  wire eob;
  cvita_hdr_decoder cvita_hdr_decoder_tuser (
    .header(i_tuser),
    .pkt_type(), .eob(eob), .has_time(),
    .seqnum(), .length(),
    .src_sid(), .dst_sid(),
    .vita_time());

  reg inject_zeros;
  always @(posedge clk) begin
    if (reset | clear) begin
      inject_zeros   <= 1'b0;
      clear_eob      <= 1'b0;
    end else begin
      if (eob & i_tvalid & i_tlast & i_tready) begin
        inject_zeros <= enable_inject_zeros;
      end
      if (s_axis_data_teob & s_axis_data_tvalid & s_axis_data_tready & s_axis_data_tlast) begin
        inject_zeros <= 1'b0;
        clear_eob    <= enable_clear_eob;
      end
      if (clear_eob) begin
        clear_eob    <= 1'b0;
      end
    end
  end

  assign m_axis_data_tdata  = inject_zeros ?  'd0 : i_tdata;
  assign m_axis_data_tvalid = inject_zeros ? 1'b1 : i_tvalid & ~clear_eob;
  assign m_axis_data_tlast  = inject_zeros ? 1'b0 : i_tlast;
  assign m_axis_data_teob   = inject_zeros ? 1'b0 : eob;
  assign i_tready           = inject_zeros ? 1'b0 : m_axis_data_tready & ~clear_eob;

  // Set EOB in header
  wire [127:0] header_tdata_int;
  cvita_hdr_modify cvita_hdr_modify (
    .header_in(header_tdata),
    .header_out(header_tdata_int),
    .use_pkt_type(1'b0),  .pkt_type(),
    .use_has_time(1'b0),  .has_time(),
    .use_eob(1'b1),       .eob(s_axis_data_teob),
    .use_seqnum(1'b0),    .seqnum(),
    .use_length(1'b0),    .length(),
    .use_src_sid(1'b1),   .src_sid(src_sid),
    .use_dst_sid(1'b1),   .dst_sid(dst_sid),
    .use_vita_time(1'b0), .vita_time());

  // Packet resizer
  wire s_axis_data_tvalid_int, s_axis_data_tready_int;
  assign s_axis_data_tvalid_int = s_axis_data_tvalid & header_tvalid & ~clear_eob; // Do not load data when clearing
  assign s_axis_data_tready     = s_axis_data_tready_int & header_tvalid & ~clear_eob;
  axi_packet_resizer #(
    .WIDTH(WIDTH),
    .EN_DROP_PARTIAL_PKT(EN_DROP_PARTIAL_PKT),
    .MAX_PKT_SIZE(MAX_PKT_SIZE),
    .SR_PKT_SIZE(SR_PKT_SIZE),
    .SR_DROP_PARTIAL_PKT(SR_DROP_PARTIAL_PKT))
  axi_packet_resizer (
    .clk(clk), .reset(reset), .clear(clear),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(s_axis_data_tdata), .i_tlast(s_axis_data_tlast), .i_tvalid(s_axis_data_tvalid_int), .i_tready(s_axis_data_tready_int), .i_tuser(header_tdata_int),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready), .o_tuser(o_tuser));

endmodule