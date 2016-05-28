//
// Copyright 2016 Ettus Research
//
// - Implements rate change of N:M (a.k.a. M/N), handles headers automatically
// - User code is responsible for generating correct number of outputs per input
//   > Example: When set 1/N, after N input samples block should output 1 sample. If
//              user code's pipelining requires additional samples to "push" the 1
//              sample out, it is the user's responsibility to make the mechanism
//              (such as injecting extra samples) to do so.
// - Will always send an integer multiple of N samples to user logic. This ensures
//   the user will not need to manually clear a "partial output sample" stuck in their
//   pipeline due to an uneven (in respect to decimation rate) number of input samples.
// - Can optionally strobe clear_user after receiving packet with EOB
//   > enable_clear_user must be enabled via CONFIG settings register
//   > Warning: Input will be throttled until last packet has completely passed through
//     user code to prevent clearing valid data. In certain conditions, this throttling
//     can have a significant impact on throughput.
// - Output packet size will be identical to input packet size. The only exception is
//   the final output packet, which may be shorter due to a partial input packet.
// Limitations:
// - Rate changes are ignored while active. Block must be cleared or packet with EOB
//   (and enable_clear_user is set) will cause new rates to be loaded.
// - Can potentially use large amounts of block RAM when using large decimation rates
//   (greater than 2K). This occurs due to the feature that the block always sends a multiple
//   of N samples to the user. Implementing this feature requires N samples to be buffered.
// - Blocks with long pipelines may need to increase HEADER_FIFOSIZE
//

module axi_rate_change #(
  parameter WIDTH              = 32,     // Input bit width, must be a power of 2 and greater than or equal to 8.
  parameter MAX_N              = 2**16,
  parameter MAX_M              = 2**16,
  parameter HEADER_FIFOSIZE    = 5,      // Log2 depth of header FIFO. Default might need to be increased if user logic has long pipelines.
  // Settings registers
  parameter SR_N_ADDR                  = 0,
  parameter SR_N_FIXED                 = 1'b0,
  parameter SR_N_DEFAULT               = 1,
  parameter SR_M_ADDR                  = 1,
  parameter SR_M_FIXED                 = 1'b0,
  parameter SR_M_DEFAULT               = 1,
  parameter SR_CONFIG_ADDR             = 2,
  parameter SR_CONFIG_FIXED            = 1'b0,
  parameter SR_CONFIG_DEFAULT          = 1
)(
  input clk, input reset, input clear, output reg clear_user,
  input [15:0] src_sid, input [15:0] dst_sid,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready, input [127:0] i_tuser,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready, output [127:0] o_tuser,
  output [WIDTH-1:0] m_axis_data_tdata, output m_axis_data_tlast, output m_axis_data_tvalid, input m_axis_data_tready,
  input [WIDTH-1:0] s_axis_data_tdata, input s_axis_data_tlast, input s_axis_data_tvalid, output s_axis_data_tready
);

  wire [WIDTH-1:0] i_reg_tdata;
  wire i_reg_tvalid, i_reg_tready, i_reg_tlast;
  wire i_reg_tvalid_int, i_reg_tready_int, i_reg_tlast_int;

  reg throttle;
  reg first_header, first_header_in_burst;
  reg [15:0] payload_length_in_hold;
  reg [15:0] word_cnt_div_n;
  reg [$clog2(MAX_N+1)-1:0] word_cnt_div_n_frac = 1;
  reg [$clog2(MAX_N+1)-1:0] in_pkt_cnt = 1;

  /********************************************************
  ** Settings Registers
  ********************************************************/
  wire [$clog2(MAX_N+1)-1:0] n_sr;
  setting_reg #(.my_addr(SR_N_ADDR), .width($clog2(MAX_N+1)), .at_reset(SR_N_DEFAULT)) sr_n (
    .clk(clk), .rst(reset | SR_N_FIXED), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(n_sr), .changed());

  wire [$clog2(MAX_M+1)-1:0] m_sr;
  setting_reg #(.my_addr(SR_M_ADDR), .width($clog2(MAX_M+1)), .at_reset(SR_M_DEFAULT)) sr_m (
    .clk(clk), .rst(reset | SR_M_FIXED), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(m_sr), .changed());

  wire enable_clear_user; // Enable strobing clear_user between bursts. Causes a single cycle bubble.
  setting_reg #(.my_addr(SR_CONFIG_ADDR), .width(1), .at_reset(SR_CONFIG_DEFAULT)) sr_config (
    .clk(clk), .rst(reset | SR_CONFIG_FIXED), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(enable_clear_user), .changed());

  // Do not change rate unless block is not active
  reg active;
  reg [$clog2(MAX_N+1)-1:0] n = 1;
  reg [$clog2(MAX_M+1)-1:0] m = 1;
  always @(posedge clk) begin
    if (reset | clear | clear_user) begin
      active <= 1'b0;
    end else begin
      if (i_tready & i_tvalid) begin
        active <= 1'b1;
      end
    end
    if (clear | clear_user | ~active) begin
      n <= n_sr;
      m <= m_sr;
    end
  end

  /********************************************************
  ** Header, word count FIFOs
  ** - Header provides VITA Time and payload length for
  **   output packets
  ** - Word count provides a normalized count for the
  **   output state machine to know when it has consumed
  **   the final input sample in a burst.
  ********************************************************/
  // Decode input header
  wire [127:0] i_reg_tuser;
  wire has_time_in, eob_in, has_time_out, eob_out;
  wire [15:0] payload_length_in, payload_length_out;
  wire [63:0] vita_time_in, vita_time_out;
  cvita_hdr_decoder cvita_hdr_decoder_in_header (
    .header(i_reg_tuser), .pkt_type(), .eob(eob_in),
    .has_time(has_time_in), .seqnum(), .length(), .payload_length(payload_length_in),
    .src_sid(), .dst_sid(), .vita_time(vita_time_in));

  reg [80:0] header_fifo_in_tdata;
  wire [80:0] header_fifo_out_tdata;
  reg header_fifo_in_tvalid;
  wire header_fifo_in_tready, header_fifo_out_tvalid, header_fifo_out_tready;
  axi_fifo #(.WIDTH(81), .SIZE(HEADER_FIFOSIZE)) axi_fifo_in_header (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(header_fifo_in_tdata), .i_tvalid(header_fifo_in_tvalid), .i_tready(header_fifo_in_tready),
    .o_tdata(header_fifo_out_tdata), .o_tvalid(header_fifo_out_tvalid), .o_tready(header_fifo_out_tready),
    .space(), .occupied());

  reg [15:0] word_cnt_div_n_tdata;
  wire [15:0] word_cnt_div_n_fifo_tdata;
  reg word_cnt_div_n_tvalid;
  wire word_cnt_div_n_tready, word_cnt_div_n_fifo_tvalid, word_cnt_div_n_fifo_tready;
  axi_fifo #(.WIDTH(17), .SIZE(HEADER_FIFOSIZE)) axi_fifo_eob_word_cnt (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({eob_in,word_cnt_div_n_tdata}), .i_tvalid(word_cnt_div_n_tvalid), .i_tready(word_cnt_div_n_tready),
    .o_tdata({eob_out,word_cnt_div_n_fifo_tdata}), .o_tvalid(word_cnt_div_n_fifo_tvalid), .o_tready(word_cnt_div_n_fifo_tready),
    .space(), .occupied());

  /********************************************************
  ** Register input stream
  ** - Upsteam will be throttled when clearing user logic
  ********************************************************/
  // Input register with header
  axi_fifo_flop2 #(.WIDTH(WIDTH+1+128)) axi_fifo_flop2_input (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({i_tlast,i_tdata,i_tuser}), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata({i_reg_tlast,i_reg_tdata,i_reg_tuser}), .o_tvalid(i_reg_tvalid_int), .o_tready(i_reg_tready),
    .space(), .occupied());

  assign i_reg_tready     = i_reg_tready_int & header_fifo_in_tready & word_cnt_div_n_tready & ~throttle;
  assign i_reg_tvalid     = i_reg_tvalid_int & header_fifo_in_tready & word_cnt_div_n_tready & ~throttle;
  // Assert AXI Drop Partial Packet's i_tlast every N samples, which is used to detect and drop
  // partial output samples.
  assign i_reg_tlast_int  = (word_cnt_div_n_frac == n) | (eob_in & i_reg_tlast);

  /********************************************************
  ** Input state machine
  ********************************************************/
  reg [1:0] input_state;
  localparam RECV_FIRST_SAMPLE        = 0;
  localparam RECV                     = 1;
  localparam RECV_WAIT_FOR_USER_CLEAR = 2;

  always @(posedge clk) begin
    if (reset | clear) begin
      first_header          <= 1'b1;
      first_header_in_burst <= 1'b1;
      word_cnt_div_n        <= 0;
      word_cnt_div_n_frac   <= 1;
      in_pkt_cnt            <= 1;
      throttle              <= 1'b0;
      header_fifo_in_tvalid <= 1'b0;
      header_fifo_in_tdata  <= 'd0;
      word_cnt_div_n_tvalid <= 1'b0;
      word_cnt_div_n_tdata  <= 'd0;
      input_state           <= RECV_FIRST_SAMPLE;
    end else begin
      if (header_fifo_in_tvalid & header_fifo_in_tready) begin
        header_fifo_in_tvalid <= 1'b0;
      end
      if (word_cnt_div_n_tvalid & word_cnt_div_n_tready) begin
        word_cnt_div_n_tvalid <= 1'b0;
      end
      // Logic used by both RECV_FIRST_SAMPLE and RECV states
      // to track several variables:
      // word_cnt_div_n:      Number of words received divided by n.
      //                      Needed for tracking final sample in a burst.
      // word_cnt_div_n_frac: Used to increment word_cnt_div_n. Can be
      //                      thought of as the fractional part of
      //                      word_cnt_div_n.
      // in_pkt_cnt:          Similar to in_word_cnt, but for packets. Used
      //                      to determine when a group of N packets has been
      //                      received.
      // first_header:        We only use the header from the first packet in
      //                      a group of N packets (this greatly reduces
      //                      the header FIFO size).
      if (i_reg_tvalid & i_reg_tready) begin
        if (word_cnt_div_n_frac == n | (eob_in & i_reg_tlast)) begin
          if (i_reg_tlast & eob_in) begin
            word_cnt_div_n  <= 0;
          end else begin
            word_cnt_div_n  <= word_cnt_div_n + 1;
          end
          word_cnt_div_n_frac  <= 1;
        end else begin
          word_cnt_div_n_frac  <= word_cnt_div_n_frac + 1;
        end
        if (i_reg_tlast) begin
          if (in_pkt_cnt == n | eob_in) begin
            first_header          <= 1'b1;
            first_header_in_burst <= eob_in;
            in_pkt_cnt            <= 1;
          end else begin
            in_pkt_cnt            <= in_pkt_cnt + 1;
          end
        end
        if (first_header) begin
          first_header           <= 1'b0;
          payload_length_in_hold <= payload_length_in;
          if (first_header_in_burst) begin
            header_fifo_in_tdata <= {payload_length_in, has_time_in, vita_time_in};
          end else begin
            header_fifo_in_tdata <= {payload_length_in_hold, has_time_in, vita_time_in};
          end
        end
      end
      case (input_state)
        // Wait until we have enough samples to form one full
        // output sample. When we have enough, push the header to
        // the header FIFO. If we get an EOB before we have enough
        // input samples, axi_drop_partial_packet will drop the
        // "partial sample" and the state machine will remain in
        // this state.
        RECV_FIRST_SAMPLE : begin
          if (i_reg_tvalid & i_reg_tready) begin
            // Not enough for one output sample, clear output
            // Note: axi_drop_partial_packet automatically handles
            //       dropping the partial sample.
            if ((eob_in & i_reg_tlast) & (word_cnt_div_n_frac < n) & (in_pkt_cnt > 0)) begin
              word_cnt_div_n_tdata  <= word_cnt_div_n;
              word_cnt_div_n_tvalid <= 1'b1;
              input_state           <= RECV_WAIT_FOR_USER_CLEAR;
            // Have enough input samples for at least one output sample
            end else if (word_cnt_div_n_frac == n) begin
              header_fifo_in_tvalid <= 1'b1;
              // Only one output sample
              if (i_reg_tlast & eob_in) begin
                word_cnt_div_n_tdata  <= word_cnt_div_n + (word_cnt_div_n_frac == n);
                word_cnt_div_n_tvalid <= 1'b1;
                input_state           <= RECV_FIRST_SAMPLE;
              end else begin
                input_state           <= RECV;
              end
            end
          end
        end
        // We received enough input samples for at least one output sample.
        // Continue receiving samples until we have received N input packets
        // which will form at least one full output packet. If an EOB occurs,
        // optionally wait for user logic to be cleared.
        RECV : begin
          if (i_reg_tvalid & i_reg_tready) begin
            // Received enough packets to send one output packet (assuming N:1).
            // Send the word count so the output state machine knows when it go
            // on to the next header.
            if (i_reg_tlast) begin
              if (eob_in) begin
                word_cnt_div_n_tdata  <= word_cnt_div_n + (word_cnt_div_n_frac == n);
                word_cnt_div_n_tvalid <= 1'b1;
                if (enable_clear_user) begin
                  throttle    <= 1'b1;
                  input_state <= RECV_WAIT_FOR_USER_CLEAR;
                end else begin
                  input_state <= RECV_FIRST_SAMPLE;
                end
              end else if (in_pkt_cnt == n) begin
                input_state <= RECV_FIRST_SAMPLE;
              end
            end
          end
        end
        // Throttle upstream until last sample has been output and user logic is cleared
        // WARNING: This can be a huge bubble state! However, since it only happens with
        //          EOBs, it should be very infrequent.
        RECV_WAIT_FOR_USER_CLEAR : begin
          first_header           <= 1'b1;
          first_header_in_burst  <= 1'b1;
          word_cnt_div_n         <= 0;
          word_cnt_div_n_frac    <= 1;
          in_pkt_cnt             <= 1;
          if (clear_user) begin
            throttle             <= 1'b0;
            input_state          <= RECV_FIRST_SAMPLE;
          end
        end
        // Hit by a cosmic ray?
        default : begin
          first_header           <= 1'b1;
          first_header_in_burst  <= 1'b1;
          word_cnt_div_n         <= 0;
          word_cnt_div_n_frac    <= 1;
          in_pkt_cnt             <= 1;
          input_state            <= RECV_FIRST_SAMPLE;
        end
      endcase
    end
  end

  /********************************************************
  ** AXI Drop Partial Packet (to user)
  ** - Enforces sending integer multiple of N samples
  **   to user
  ********************************************************/
  axi_drop_partial_packet #(
    .WIDTH(WIDTH+1),
    .HOLD_LAST_WORD(1),
    .MAX_PKT_SIZE(MAX_N),
    .SR_PKT_SIZE_ADDR(SR_N_ADDR))
  axi_drop_partial_packet (
    .clk(clk), .reset(reset), .clear(clear),
    .flush(word_cnt_div_n_tvalid & word_cnt_div_n_tready),  // Flush on EOB
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata({i_reg_tlast,i_reg_tdata}), .i_tvalid(i_reg_tvalid), .i_tlast(i_reg_tlast_int), .i_tready(i_reg_tready_int),
    .o_tdata({m_axis_data_tlast,m_axis_data_tdata}), .o_tvalid(m_axis_data_tvalid), .o_tlast(/* Unused */), .o_tready(m_axis_data_tready));

  /********************************************************
  ** Output state machine
  ********************************************************/
  reg [1:0] output_state;
  localparam SEND             = 0;
  localparam SEND_CLEAR_USER  = 1;

  wire [WIDTH-1:0] o_reg_tdata;
  wire [127:0] o_reg_tuser;
  wire o_reg_tvalid, o_reg_tready, o_reg_tlast;
  wire o_reg_tvalid_int, o_reg_tready_int, o_reg_tlast_int;

  reg [15:0] out_payload_cnt = (WIDTH/8);
  reg [15:0] word_cnt_div_m;
  reg [$clog2(MAX_M+1)-1:0] word_cnt_div_m_frac = 1;
  reg [$clog2(MAX_M+1)-1:0] out_pkt_cnt = 1;
  always @(posedge clk) begin
    if (reset | clear) begin
      word_cnt_div_m      <= 1;
      word_cnt_div_m_frac <= 1;
      out_pkt_cnt         <= 1;
      out_payload_cnt     <= (WIDTH/8);
      clear_user          <= 1'b0;
      output_state        <= SEND;
    end else begin
      case (output_state)
        SEND : begin
          if (o_reg_tvalid & o_reg_tready) begin
            if (o_reg_tlast) begin
              if (out_pkt_cnt == m) begin
                out_pkt_cnt   <= 1;
              end else begin
                out_pkt_cnt   <= out_pkt_cnt + 1;
              end
              out_payload_cnt <= (WIDTH/8);
            end else begin
              out_payload_cnt <= out_payload_cnt + (WIDTH/8);
            end
            if (word_cnt_div_m_frac == m) begin
              word_cnt_div_m      <= word_cnt_div_m + 1;
              word_cnt_div_m_frac <= 1;
            end else begin
              word_cnt_div_m_frac <= word_cnt_div_m_frac + 1;
            end
            if (word_cnt_div_n_fifo_tvalid & (word_cnt_div_m == word_cnt_div_n_fifo_tdata) & (word_cnt_div_m_frac == m)) begin
              word_cnt_div_m      <= 1;
              if (enable_clear_user & eob_out) begin
                clear_user   <= 1'b1;
                output_state <= SEND_CLEAR_USER;
              end
            end
          end
        end
        SEND_CLEAR_USER : begin
          word_cnt_div_m      <= 1;
          word_cnt_div_m_frac <= 1;
          out_pkt_cnt         <= 1;
          out_payload_cnt     <= (WIDTH/8);
          clear_user          <= 1'b0;
          output_state        <= SEND;
        end
        default : begin
          output_state <= SEND;
        end
      endcase
    end
  end

  assign {payload_length_out,has_time_out,vita_time_out} = header_fifo_out_tdata;
  // Logic to pop header and word cnt FIFOs due to ...
  assign header_fifo_out_tready     = o_reg_tvalid_int & o_reg_tready_int &
                                      // ... end of a group of M output packets
                                      ((o_reg_tlast & out_pkt_cnt == m) |
                                      // ... EOB, could be a partial packet
                                      (word_cnt_div_n_fifo_tvalid & (word_cnt_div_m == word_cnt_div_n_fifo_tdata) & (word_cnt_div_m_frac == m)));
  assign word_cnt_div_n_fifo_tready = o_reg_tvalid_int & o_reg_tready_int &
                                      (word_cnt_div_n_fifo_tvalid & (word_cnt_div_m == word_cnt_div_n_fifo_tdata) & (word_cnt_div_m_frac == m));

  /********************************************************
  ** Adjust VITA time
  ********************************************************/
  reg first_pkt_out;
  reg [63:0] vita_time_accum, vita_time_reg;
  always @(posedge clk) begin
    if (reset | clear | clear_user) begin
      first_pkt_out       <= 1'b1;
      vita_time_accum     <= 64'd1;
    end else begin
      if (o_reg_tvalid & o_reg_tready) begin
        if (o_reg_tlast) begin
          vita_time_reg      <= vita_time_accum + vita_time_out;
          if (first_pkt_out) begin
            first_pkt_out    <= 1'b0;
          end
        end
        if (header_fifo_out_tready) begin
          first_pkt_out      <= 1'b1;
          vita_time_accum    <= 1;
        end else begin
          vita_time_accum    <= vita_time_accum + 1;
        end
      end
    end
  end

  // Create output header
  wire eob_out_int = (word_cnt_div_n_fifo_tvalid & (word_cnt_div_m == word_cnt_div_n_fifo_tdata) & (word_cnt_div_m_frac == m)) ? eob_out : 1'b0;
  cvita_hdr_encoder cvita_hdr_encoder (
    .pkt_type(2'd0), .eob(eob_out_int), .has_time(has_time_out),
    .seqnum(12'd0), .payload_length(16'd0), // Not needed, handled by AXI Wrapper
    .src_sid(src_sid), .dst_sid(dst_sid),
    .vita_time(first_pkt_out ? vita_time_out : vita_time_reg),
    .header(o_reg_tuser));

  /********************************************************
  ** Register input stream from user and output stream
  ********************************************************/
  assign o_reg_tvalid     = o_reg_tvalid_int & header_fifo_out_tvalid;
  assign o_reg_tready     = o_reg_tready_int & header_fifo_out_tvalid;
  assign o_reg_tlast      = o_reg_tlast_int |
                            // End of packet
                            (out_payload_cnt == payload_length_out) |
                            // EOB, could be a partial packet
                            (word_cnt_div_n_fifo_tvalid & (word_cnt_div_m == word_cnt_div_n_fifo_tdata) & (word_cnt_div_m_frac == m));

  axi_fifo_flop2 #(.WIDTH(WIDTH+1)) axi_fifo_flop2_from_user (
    .clk(clk), .reset(reset), .clear(clear),
    // FIXME: If user asserts tlast at the wrong time, it likely causes a deadlock. For now ignore tlast.
    //.i_tdata({s_axis_data_tlast,s_axis_data_tdata}), .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
    .i_tdata({1'b0,s_axis_data_tdata}), .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
    .o_tdata({o_reg_tlast_int,o_reg_tdata}), .o_tvalid(o_reg_tvalid_int), .o_tready(o_reg_tready),
    .space(), .occupied());

  // Output register with header
  axi_fifo_flop2 #(.WIDTH(WIDTH+1+128)) axi_fifo_flop2_output (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({o_reg_tlast,o_reg_tdata,o_reg_tuser}), .i_tvalid(o_reg_tvalid), .i_tready(o_reg_tready_int),
    .o_tdata({o_tlast,o_tdata,o_tuser}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

endmodule