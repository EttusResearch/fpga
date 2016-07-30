//
// Copyright 2015 Ettus Research
//
// Responds with flow control packets as input packets are consumed.

module flow_control_responder #(
  parameter SR_FLOW_CTRL_CYCS_PER_ACK = 0,
  parameter SR_FLOW_CTRL_PKTS_PER_ACK = 1,
  parameter USE_TIME = 1
)(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  output [63:0] fc_tdata, output fc_tlast, output fc_tvalid, input fc_tready
);

  wire enable_cycle;
  wire [23:0] cycles;
  wire [6:0] reserved1;
  setting_reg #(.my_addr(SR_FLOW_CTRL_CYCS_PER_ACK), .at_reset(0)) sr_cycles (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out({enable_cycle, reserved1, cycles}), .changed());

  wire enable_consumed;
  wire [15:0] packets;
  wire [14:0] reserved2;
   setting_reg #(.my_addr(SR_FLOW_CTRL_PKTS_PER_ACK), .at_reset(0)) sr_packets (
     .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr),
     .in(set_data), .out({enable_consumed, reserved2, packets}), .changed());

  wire hdr_stb;
  wire [11:0] seqnum;
  wire [15:0] src_sid;
  wire [15:0] dst_sid;
  wire [63:0] vita_time;
  // Extract header fields and also acts as a register stage
  cvita_hdr_parser #(.REGISTER(1)) cvita_hdr_parser (
    .clk(clk), .reset(reset), .clear(clear),
    .hdr_stb(hdr_stb),
    .pkt_type(), .eob(), .has_time(),
    .seqnum(seqnum), .length(),
    .src_sid(src_sid), .dst_sid(dst_sid),
    .vita_time_stb(), .vita_time(vita_time),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

  // Track sequence numbers across 12 bit boundary
  reg [31:0] seqnum_int, seqnum_hold;
  always @(posedge clk) begin
    if (reset | clear) begin
      seqnum_int <= 0;
    end else begin
      if (hdr_stb) begin
        seqnum_int[11:0] <= seqnum;
        if (seqnum_int[11:0] == 12'hFFF) begin
          seqnum_int[31:12] <= seqnum_int[31:12] + 1;
        end
      end
    end
  end

  wire [63:0] flow_ctrl_tdata;
  wire [127:0] flow_ctrl_tuser;
  wire flow_ctrl_tlast, flow_ctrl_tready;
  reg flow_ctrl_tvalid;

  wire packet_consumed = o_tvalid & o_tready & o_tlast;

  // Trigger flow control packets depending on either:
  //   - number of cycles after start of packet
  //   - number of packets consumed
  reg [24:0] cycle_count;
  reg [16:0] packet_count;
  always @(posedge clk) begin
    if (reset | clear) begin
      cycle_count  <= 0;
      packet_count <= 0;
      flow_ctrl_tvalid <= 1'b0;
      seqnum_hold <= 32'd0;
    end else begin
      if (flow_ctrl_tvalid & flow_ctrl_tready) begin
        flow_ctrl_tvalid <= 1'b0;
      end
      if ((enable_cycle & packet_consumed) | (cycle_count != 0)) begin
        cycle_count <= cycle_count + 1;
      end
      if (enable_consumed & packet_consumed) begin
        packet_count <= packet_count + 1;
      end
      if ((enable_cycle & (cycle_count >= cycles)) | (enable_consumed & (packet_count >= packets))) begin
        flow_ctrl_tvalid <= 1'b1;
        // Need to hold seqnum as next packet will update seqnum_int
        seqnum_hold <= seqnum_int;
        packet_count <= 0;
        cycle_count <= 0;
      end
    end
  end

  assign flow_ctrl_tdata = {32'h0, seqnum_hold};
  assign flow_ctrl_tuser = {2'b01, USE_TIME[0], 1'b0, 12'd0 /* handled by chdr framer */, 16'd0 /* here too */, {dst_sid, src_sid} /* Reverse SID */, vita_time};
  assign flow_ctrl_tlast = 1'b1;

  // Create flow control packets
  chdr_framer #(.SIZE(5), .WIDTH(64)) chdr_framer (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(flow_ctrl_tdata), .i_tuser(flow_ctrl_tuser), .i_tlast(flow_ctrl_tlast), .i_tvalid(flow_ctrl_tvalid), .i_tready(flow_ctrl_tready),
    .o_tdata(fc_tdata), .o_tlast(fc_tlast), .o_tvalid(fc_tvalid), .o_tready(fc_tready));

endmodule
