//
// Copyright 2015 Ettus Research
//
// Responds with an error packet if input packet is malformed.

module packet_error_responder #(
  parameter SR_ERROR_POLICY = 1,  // How to recover from packet errors 
  parameter USE_TIME = 0
)(
  input clk, input reset, input clear,
  input [31:0] sid, // Destination SID
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  output [63:0] resp_tdata, output resp_tlast, output resp_tvalid, input resp_tready
);

  wire clear_error;                     // On register write, reset error status
  wire send_error_pkt;                  // Send (1) or do not send (0) send error packets
  wire policy_continue;                 // Continue outputting packets after encountering error
  wire policy_wait_until_next_packet;   // Drop offending packet only
  wire policy_wait_until_next_burst;    // Drop packets after error until after EOB
  // Note: If no policy is set then packets will continuously be dropped until clear_error is asserted by a register write
  setting_reg #(.my_addr(SR_ERROR_POLICY), .width(4), .at_reset(4'b0101)) sr_error_policy (
    .clk(clk), .rst(reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out({policy_wait_until_next_burst, policy_wait_until_next_packet, policy_continue, send_error_pkt}), .changed(clear_error));

  wire hdr_stb, eob;
  wire [63:0] vita_time;
  wire [11:0] seqnum;
  wire [63:0] int_tdata;
  wire int_tlast, int_tvalid, int_tready;
  // Extract header fields and also acts as a register stage
  cvita_hdr_parser #(.REGISTER(1)) cvita_hdr_parser (
    .clk(clk), .reset(reset), .clear(clear),
    .hdr_stb(hdr_stb),
    .pkt_type(), .eob(eob), .has_time(),
    .seqnum(seqnum), .length(),
    .src_sid(), .dst_sid(),
    .vita_time_stb(), .vita_time(vita_time),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(int_tdata), .o_tlast(int_tlast), .o_tvalid(int_tvalid), .o_tready(int_tready));

  reg [11:0] seqnum_expected, seqnum_error;
  wire error_stb = (seqnum_expected != seqnum) & hdr_stb;

  wire [63:0] error_tdata;
  wire [127:0] error_tuser;
  wire error_tlast, error_tready;
  reg error_tvalid, error_hold, first_packet, clear_error_hold;
  wire packet_consumed = int_tvalid & int_tready & int_tlast;

  always @(posedge clk) begin
    if (reset | clear) begin
      seqnum_expected   <= 12'd0;
      seqnum_error      <= 12'd0;
      first_packet      <= 1'b1;
      error_tvalid      <= 1'b0;
      error_hold        <= 1'b0;
      clear_error_hold  <= 1'b0;
    end else begin
      // Trigger error packet
      if (error_stb) begin
        seqnum_error <= seqnum;
        error_tvalid <= send_error_pkt;
        // Policy continue essentially masks errors
        error_hold   <= ~policy_continue;
      end
      // Latch clear error so we will continue on the next packet
      // but only if there is an actual error.
      if (clear_error & error_hold) begin
        clear_error_hold <= 1'b1;
      end
      // Error packet consumed
      if (error_tvalid & error_tready) begin
        error_tvalid <= 1'b0;
      end
      if (packet_consumed) begin
        // Track sequence number
        seqnum_expected <= seqnum + 1'b1;
        // Recover from error depending on policy
        if (policy_wait_until_next_packet | (eob & policy_wait_until_next_burst) | clear_error_hold | clear_error) begin
          clear_error_hold <= 1'b0;
          error_hold       <= 1'b0;
        end
        if (eob) begin
          first_packet <= 1'b1;
        end else begin
          first_packet <= 1'b0;
        end
      end
    end
  end

  // Drop packet on error by masking input valid with error status. User can override using policy continue.
  // Need to use separate error and error_hold signals to ensure we drop the first and subsequent lines of the packet.
  axi_fifo_flop2 #(.WIDTH(65)) axi_fifo_flop (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({int_tlast, int_tdata}), .i_tvalid(int_tvalid & (~(error_stb | error_hold) | policy_continue)), .i_tready(int_tready),
    .o_tdata({o_tlast, o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

  wire [63:0] CODE_SEQ_ERROR          = {32'd4,4'd0,seqnum_expected,4'd0,seqnum_error};
  wire [63:0] CODE_SEQ_ERROR_MIDBURST = {32'd32,4'd0,seqnum_expected,4'd0,seqnum_error};

  assign error_tdata = first_packet ? CODE_SEQ_ERROR : CODE_SEQ_ERROR_MIDBURST;
  assign error_tuser = {2'b11, USE_TIME[0], 1'b1, 12'd0 /* handled by chdr framer */, 16'd0 /* here too */, sid, vita_time};
  assign error_tlast = 1'b1;

  // Create error packets
  chdr_framer #(.SIZE(5), .WIDTH(64)) chdr_framer_resp_pkt (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(error_tdata), .i_tuser(error_tuser), .i_tlast(error_tlast), .i_tvalid(error_tvalid), .i_tready(error_tready),
    .o_tdata(resp_tdata), .o_tlast(resp_tlast), .o_tvalid(resp_tvalid), .o_tready(resp_tready));

endmodule
