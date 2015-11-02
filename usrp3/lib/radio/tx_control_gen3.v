//
// Copyright 2015 Ettus Research
//
// Converts AXI-Stream sample data to a strobed data interface for the radio frontend
// Outputs an error packet if an underrun or late timed command occurs.

module tx_control_gen3 #(
  parameter SR_ERROR_POLICY = 0   // What to do when errors occur -- wait for next packet or next burst
)(
  input clk, input reset, input clear,
  input [63:0] vita_time, input [31:0] resp_sid,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  // Data packets
  input [31:0] tx_tdata, input [127:0] tx_tuser, input tx_tlast, input tx_tvalid, output tx_tready,
  // Error packets
  output reg [63:0] resp_tdata, output reg [127:0] resp_tuser, output reg resp_tlast, output reg resp_tvalid, input resp_tready,
  // To radio frontend
  output run, output [31:0] sample, input strobe
);

  wire [63:0] send_time = tx_tuser[63:0];
  wire [11:0] seqnum    = tx_tuser[123:112];
  wire        eob       = tx_tuser[124];
  wire        send_at   = tx_tuser[125];

  wire now, early, late, too_early;
  wire policy_next_burst, policy_next_packet;

  setting_reg #(.my_addr(SR_ERROR_POLICY), .width(2), .at_reset(2'b01)) sr_error_policy (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out({policy_next_burst,policy_next_packet}),.changed());

  time_compare time_compare (
    .clk(clk), .reset(reset),
    .time_now(vita_time), .trigger_time(send_time),
    .now(now), .early(early), .late(late), .too_early(too_early));

  reg [2:0] state;

  localparam ST_IDLE        = 0;
  localparam ST_SAMP        = 1;
  localparam ST_ERROR_WAIT  = 2;

  assign run = (state == ST_SAMP) & ~(strobe & ~tx_tvalid); // Immediately drops run signal on underrun

  wire [63:0] CODE_EOB_ACK      = {32'd1,20'd0,seqnum};
  wire [63:0] CODE_UNDERRUN     = {32'd2,20'd0,seqnum};
  wire [63:0] CODE_TIME_ERROR   = {32'd8,20'd0,seqnum};

  wire [127:0] error_header     = {2'b11, 1'b1, 1'b1, 12'd0 /* don't care */, 16'd0 /* don't care */, resp_sid, vita_time};
  wire [127:0] resp_header      = {2'b11, 1'b1, 1'b0, 12'd0 /* don't care */, 16'd0 /* don't care */, resp_sid, vita_time};

  reg sop, eob_reg;

  always @(posedge clk) begin
    if (reset | clear) begin
      state       <= ST_IDLE;
      resp_tvalid <= 1'b0;
      resp_tlast  <= 1'b0;
      resp_tuser  <= 'd0;
      resp_tdata  <= 'd0;
      sop         <= 1'b1;
      eob_reg     <= 1'b0;
    end else begin
      // Deassert tvalid after response packet is consumed
      if (resp_tvalid & resp_tlast & resp_tready) begin
        resp_tvalid <= 1'b0;
        resp_tlast  <= 1'b0;
      end
      // Track start of packet
      if (tx_tvalid & tx_tready) begin
        if (tx_tlast) begin
          sop <= 1'b1;
        end else if (sop) begin
          eob_reg <= eob;
          sop     <= 1'b0;
        end
      end

      case (state)
        ST_IDLE : begin
          if (tx_tvalid) begin
            if (~send_at | now) begin
              state <= ST_SAMP;
            end else if (late) begin
              resp_tvalid <= 1'b1;
              resp_tlast  <= 1'b1;
              resp_tuser  <= error_header;
              resp_tdata  <= CODE_TIME_ERROR;
              state       <= ST_ERROR_WAIT;
            end
          end
        end

        ST_SAMP : begin
          if (strobe) begin
            if (~tx_tvalid) begin
              resp_tvalid <= 1'b1;
              resp_tlast  <= 1'b1;
              resp_tuser  <= error_header;
              resp_tdata  <= CODE_UNDERRUN;
              state       <= ST_ERROR_WAIT;
            end else begin
              if (tx_tlast & eob) begin
                resp_tvalid <= 1'b1;
                resp_tlast  <= 1'b1;
                resp_tuser  <= resp_header;
                resp_tdata  <= CODE_EOB_ACK;
                state       <= ST_IDLE;
              end
            end
          end
        end

        // Wait until end of packet or burst depending on the policy
        ST_ERROR_WAIT : begin
          // Two valid times to transition back to IDLE:
          // 1. We are at the end of a packet OR
          // 2. We are not currently receiving a packet
          if ((tx_tvalid & tx_tlast) | (~tx_tvalid & sop)) begin
            // Use eob_reg as eob may not be valid when tx_tvalid=0
            if (policy_next_packet | (policy_next_burst & eob_reg)) begin
              state <= ST_IDLE;
            end
          end
        end

        default : state <= ST_IDLE;
      endcase // case (state)
    end
  end

  // Read packet in 'sample' state or dump it in error state
  assign tx_tready = (state == ST_ERROR_WAIT) | (strobe & (state == ST_SAMP));
  assign sample = tx_tdata;

endmodule // tx_control_gen3
