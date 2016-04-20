//
// Copyright 2016 Ettus Research
//
// Configurable packet upsizer / downsizer.
// - Can be used with CVITA packets or regular AXI stream (set i_tuser to 0, ignore o_tuser)
// - When aggregating packets, can drop or pass through partial packets.
//   If dropping partial packets:
//   - An output FIFO will be instantiated which will increase resource utilization
//   - Can set EOB on previous full packet after receiving a partial packet
// 

module axi_packet_resizer #(
  parameter WIDTH               = 32,      // Input bit width
  parameter EN_DROP_PARTIAL_PKT = 0,       // Enable support for dropping partial packets, adds extra FIFO of depth log2(MAX_PKT_SIZE)
  parameter MAX_PKT_SIZE        = 4096,
  parameter SR_PKT_SIZE         = 0,
  parameter SR_DROP_PARTIAL_PKT = 1        // Only used if EN_DROP_PARTIAL_PKT == 1
)(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready, input [127:0] i_tuser,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready, output [127:0] o_tuser
);

  wire [$clog2(MAX_PKT_SIZE+1)-1:0] pkt_size;
  setting_reg #(.my_addr(SR_PKT_SIZE), .width($clog2(MAX_PKT_SIZE+1)), .at_reset('d0)) sr_pkt_size (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(pkt_size), .changed());

  wire drop_partial_pkt, eob_out;
  generate
    if (EN_DROP_PARTIAL_PKT == 1) begin
      setting_reg #(.my_addr(SR_DROP_PARTIAL_PKT), .width(2), .at_reset('d0)) sr_drop_partial_pkt (
        .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
        .out({eob_out,drop_partial_pkt}), .changed());
    end else begin
      assign drop_partial_pkt = 1'b0;
    end
  endgenerate

  wire eob_in;
  cvita_hdr_decoder cvita_hdr_decoder (
    .header(i_tuser), .pkt_type(), .eob(eob_in),
    .has_time(), .seqnum(), .length(), .payload_length(),
    .src_sid(), .dst_sid(), .vita_time());

  wire i_tlast_int;
  reg [$clog2(MAX_PKT_SIZE+1)-1:0] counter = WIDTH/8;
  always @(posedge clk) begin
    if (reset | clear) begin
      counter <= WIDTH/8;
    end else begin
      if (i_tvalid & i_tready) begin
        if (i_tlast_int) begin
          counter <= WIDTH/8;
        end else begin
          counter <= counter + WIDTH/8;
        end
      end
    end
  end

  assign i_tlast_int = (i_tlast & eob_in) | (counter >= pkt_size);

  generate
    if (EN_DROP_PARTIAL_PKT == 1) begin
      // Output is broken into a FIFO + register stage. FIFO is used to drop partial packets,
      // register stage holds the last line of the previous full packet and will only release
      // once the next packet comes in. 
      // - If the next packet is a full packet, last line is released
      // - If the next packet is a partial packet, last line is release with EOB optionally set, 
      //   and partial packet is dropped by clearing the FIFO

      reg drop, throttle_input, full_packets;
      reg first_header = 1'b1;
      reg [15:0] full_packet_cnt;

      wire hold_last_line = drop_partial_pkt &
                            eob_out &           // If not setting EOB, no point in holding last line
                            full_packets &      // Hold last line unless we have another full packet
                            ~throttle_input;    // In process of dropping a packet

      // FIFO to hold a full packet + a little extra
      // - Will not output until at least one full packet is in FIFO
      wire [WIDTH-1:0] int_tdata;
      wire [127:0] int_tuser;
      wire int_tlast, int_tvalid, int_tvalid_int, int_tready, int_tready_int, i_tvalid_int, i_tready_int;
      axi_fifo_cascade #(.WIDTH(WIDTH+1), .SIZE($clog2(MAX_PKT_SIZE+1))) axi_fifo (
        .clk(clk), .reset(reset), .clear(clear | drop),
        .i_tdata({i_tlast_int,i_tdata}), .i_tvalid(i_tvalid_int), .i_tready(i_tready_int),
        .o_tdata({int_tlast,int_tdata}), .o_tvalid(int_tvalid_int), .o_tready(int_tready_int),
        .space(), .occupied());
      assign i_tvalid_int   = i_tvalid & ~throttle_input;
      assign i_tready       = i_tready_int & ~throttle_input;
      assign int_tvalid     = int_tvalid_int & (full_packets | ~drop_partial_pkt);
      assign int_tready_int = int_tready & (full_packets | ~drop_partial_pkt);

      // Only store first header to use for output packets
      axi_fifo_flop2 #(.WIDTH(128)) axi_fifo_flop2_header (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(i_tuser), .i_tvalid(first_header & i_tvalid & i_tlast & i_tready), .i_tready(),
        .o_tdata(int_tuser), .o_tvalid(), .o_tready(int_tvalid & int_tlast & int_tready),
        .space(), .occupied());

      // Output register stage to hold last line until next packet
      // - If dropping partial packets, holds off releasing last line until another 
      //   full packet comes in. This is needed so EOB can be set if the next packet is a 
      //   partial packet.
      wire o_tvalid_int, o_tready_int;
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) axi_fifo_flop2_last_line (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata({int_tlast,int_tdata}), .i_tvalid(int_tvalid), .i_tready(int_tready),
        .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid_int), .o_tready(o_tready_int),
        .space(), .occupied());
      assign o_tvalid     = o_tvalid_int & ~(hold_last_line & int_tlast);
      assign o_tready_int = o_tready & ~(hold_last_line & int_tlast);

      wire [127:0] set_eob_header, o_tuser_int;
      cvita_hdr_encoder cvita_hdr_encoder (
        .pkt_type(2'd0), .eob(eob_out & drop), .has_time(1'b0),
        .seqnum(12'd0), .length(16'd0),
        .src_sid(16'd0), .dst_sid(16'd0),
        .vita_time(64'd0),
        .header(set_eob_header));

      axi_fifo_flop2 #(.WIDTH(128)) axi_fifo_flop2_header2 (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(int_tuser), .i_tvalid(int_tvalid & int_tlast & int_tready), .i_tready(),
        .o_tdata(o_tuser_int), .o_tvalid(), .o_tready(o_tvalid & o_tlast & o_tready),
        .space(), .occupied());
      assign o_tuser = o_tuser_int | set_eob_header;

      // Logic to control dropping partial packets and setting EOB
      always @(posedge clk) begin
        if (reset | clear) begin
          drop             <= 1'b0;
          first_header     <= 1'b1;
          full_packet_cnt  <= 0;
          full_packets     <= 1'b0;
          throttle_input   <= 1'b0;
        end else begin
          // Track first header
          if (first_header & i_tvalid & (i_tlast & ~eob_in) & i_tready) begin
            first_header <= 1'b0;
          end else if (i_tvalid & i_tready & i_tlast_int) begin
            first_header <= 1'b1;
          end
          // Count number of full packets in FIFO
          if ( (i_tvalid & i_tready & (counter >= pkt_size)) &
              ~(int_tlast & int_tvalid & int_tready)) begin
            full_packet_cnt <= full_packet_cnt + 1'b1;
            full_packets    <= 1'b1;
          end else if (~(i_tvalid & i_tready & (counter >= pkt_size)) &
                        (int_tlast & int_tvalid & int_tready)) begin
            full_packet_cnt <= full_packet_cnt - 1'b1;
            if (full_packet_cnt == 1) begin
              full_packets  <= 1'b0;
            end
          end
          // Drop partial packets
          if (drop_partial_pkt & i_tvalid & i_tready & (i_tlast & eob_in) & (counter < pkt_size)) begin
            throttle_input   <= 1'b1;
            if (~full_packets) begin
              drop           <= 1'b1;
            end
          end
          if (throttle_input) begin
            if (~drop) begin
              if (~full_packets) begin
                drop         <= 1'b1;
              end
            end else begin
              drop           <= 1'b0;
              throttle_input <= 1'b0;
            end
          end
        end
      end

    // No dropping of partial packets, so just send everything through
    end else begin
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) axi_fifo_flop2 (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata({i_tlast_int,i_tdata}), .i_tvalid(i_tvalid), .i_tready(i_tready),
        .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
        .space(), .occupied());

      // Hold header until end of packet / burst
      axi_fifo_flop2 #(.WIDTH(128)) axi_fifo_flop2_header (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(i_tuser), .i_tvalid(i_tvalid & i_tlast_int & i_tready), .i_tready(),
        .o_tdata(o_tuser), .o_tvalid(), .o_tready(o_tvalid & o_tlast & o_tready),
        .space(), .occupied());
    end
  endgenerate

endmodule