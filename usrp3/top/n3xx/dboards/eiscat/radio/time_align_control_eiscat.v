/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Time Align Control Eiscat
//
// takes in NUM_STREAMS different tuser/tlast AXIS
// gets time comparison on the tusers, using tlast to determine when to move to next time comparisons.
// Stores tusers in bram fifos that can store up to 32 tuser entries.
//
// Returns an error in the following conditions:
//  tlast is not present in all AXIS ports, meaning that different packet sizes are present.
//  time comparison returns not equal, meaning packets from different times are being compared.
//
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


module time_align_control_eiscat #(
  parameter NUM_STREAMS = 3
)(
  input clk, input reset,
  input clear, // Resets clear FIFOs
  input [31:0] resp_sid,
  //Input data
  //All T user streams
  input [NUM_STREAMS*128-1:0] i_tuser, input [NUM_STREAMS-1:0] i_tlast,
  input [NUM_STREAMS-1:0] i_tvalid, input [NUM_STREAMS-1:0] i_tready,
  output [127:0] o_tuser, //only 1 tuser for all the beams. later the sid will be replaced with something more appropriate where needed.
  // Error packets, In gen 3: unused as error packets must come inline with data, but we will use it here.
  output [63:0] resp_tdata, output [127:0] resp_tuser, output resp_tlast, output resp_tvalid, input resp_tready,
  //when there's an error, we need to clear all fifos and restart everything.
  output error_out
);


  reg [NUM_STREAMS*128-1:0] i_tuser_reg;
  reg [NUM_STREAMS*128-1:0] i_tuser_flop;
  reg [NUM_STREAMS*64-1:0] prev_time;
  reg [NUM_STREAMS*12-1:0] prev_seq_num;
  wire [NUM_STREAMS-1:0] stream_time_tvalid;
  reg [NUM_STREAMS-1:0] stream_time_tvalid_flop;
  wire [NUM_STREAMS-1:0] stream_time_tready;
  wire [NUM_STREAMS*128-1:0] o_tuser_fifo;
  reg  [127:0] o_tuser_fifo_reg;
  wire [NUM_STREAMS*64-1:0] in_compare;

  wire [NUM_STREAMS-2:0] now;
  wire [NUM_STREAMS-2:0] early;
  wire [NUM_STREAMS-2:0] late;
  wire [NUM_STREAMS-1:0] time_fifo_valid;
  reg time_fifo_ready;
  wire [NUM_STREAMS-1:0] time_fifo_valid_int;
  wire time_fifo_ready_int;
  reg clear_reg;

  wire [11:0] seqnum_cnt;
  wire [63:0] vita_time;
  wire [63:0] error_time;
  reg  [63:0] error_time_reg;
  reg  [31:0] error; //error code
  reg  error_reg; //set if an error

  //error packets registers
  reg [31:0] resp_reg_tdata;
  reg [127:0] resp_reg_tuser;
  reg resp_reg_tlast, resp_reg_tvalid;
  wire resp_reg_tready;
  wire [NUM_STREAMS*16-1:0] tuser_fifo_occupied;
  wire [NUM_STREAMS-1:0] tuser_fifo_is_occupied;
  wire [NUM_STREAMS-1:0] tuser_fifo_end_of_burst;
  reg  [NUM_STREAMS-1:0] tuser_fifo_end_of_burst_reg;
  reg force_eob_error_reg;


  wire cumulative_now;
  wire cumulative_early;
  wire cumulative_late;
  wire cumulative_time_valid;
  wire cumulative_is_occupied;
  wire cumulative_end_of_burst;
  reg  cumulative_end_of_burst_reg;
  reg  or_end_of_burst_reg;
  wire and_tlast;
  wire or_tlast;
  wire eob;

  //keep an eye on this to see if its a problem spot for timing.
  genvar t;
  generate
  for (t = 0; t < NUM_STREAMS; t = t + 1) begin
    always @ (posedge clk) begin
      if(reset | clear) begin
        prev_time[64*t+63:64*t] <= 0;
        i_tuser_reg[128*t+127:128*t] <= 128'h0FFF000000000000FFFFFFFFEEEEDDDD;//so that when we start with seqnum 000, this is triggered.
        prev_seq_num[12*t+11:12*t] <= 12'hFFF; //so that when we start with seqnum 000, this is triggered.
        //stream_time_tvalid[t] <= 1'b0;
      end else begin
        if(i_tvalid[t] & i_tready[t]) begin
          i_tuser_reg[128*t+127:128*t] <= i_tuser[128*t+127:128*t];
          prev_time[64*t+63:64*t] <= i_tuser_reg[128*t+63:128*t];
          prev_seq_num[12*t+11:12*t] <= i_tuser_reg[128*t+123:128*t+112];
          //stream_time_tvalid[t] <= (i_tuser_reg[128*t+123:128*t+112] != prev_seq_num[12*t+11:12*t]);
        end
      end
    end
    assign stream_time_tvalid[t] = (i_tuser_reg[128*t+123:128*t+112] != prev_seq_num[12*t+11:12*t]) & i_tvalid[t] & i_tready[t]; //bit 125 is HAS TIME. all valid tusers should have time.
    
    //register the time stream valid and tuser data one last time before the bram. should help timing.
    always @ (posedge clk) begin
      i_tuser_flop[128*t+127:128*t] <= i_tuser_reg[128*t+127:128*t];
      stream_time_tvalid_flop[t] <= stream_time_tvalid[t];
    end   
    
    //holds 2^6-1 = 63 tuser entries. More than enough.
    axi_fifo_bram #(.WIDTH(128), .SIZE(6)) tuser_fifo (
      .clk(clk),.reset(reset),.clear(clear | clear_reg),
      .i_tdata(i_tuser_flop[128*t+127:128*t]), .i_tvalid(stream_time_tvalid_flop[t]), .i_tready(stream_time_tready[t]),
      .o_tdata(o_tuser_fifo[128*t+127:128*t]),
      .o_tvalid(time_fifo_valid[t]), .o_tready(time_fifo_ready),
      .occupied(tuser_fifo_occupied[16*t+15:16*t]), .space() );

    assign tuser_fifo_is_occupied[t] = tuser_fifo_occupied[16*t+15:16*t] != 16'h0000;
    assign tuser_fifo_end_of_burst[t] = tuser_fifo_occupied[16*t+15:16*t] == 16'h0001;

    if ( t > 0) begin
       time_compare time_compare_inst (
       .clk(clk), .reset(reset),
       .time_now(o_tuser_fifo[63:0]), .trigger_time(o_tuser_fifo[128*t+63:128*t]),
       .now(now[t-1]), .early(early[t-1]), .late(late[t-1]), .too_early());
    end

  end
  endgenerate

  //cumulative signals of all the time comparisons and tlasts
  assign cumulative_now = &now;
  assign cumulative_early = |early;
  assign cumulative_late = |late;
  assign cumulative_time_valid = &time_fifo_valid;
  assign cumulative_is_occupied = &tuser_fifo_is_occupied;
  assign cumulative_end_of_burst = &tuser_fifo_end_of_burst;
  assign and_tlast = &i_tlast;
  assign or_tlast = |i_tlast;
  assign or_end_of_burst = |tuser_fifo_end_of_burst;
  assign error_out = error_reg;


  // State machine states
  localparam IBS_IDLE                = 0;
  localparam IBS_RUNNING             = 1;
  localparam IBS_LOAD_NEXT_TIME      = 5;
  localparam IBS_ERR_WAIT_FOR_READY  = 2;
  localparam IBS_ERR_SEND_PKT        = 3;
  localparam IBS_ERR_TIL_NEXT_RUN    = 4;

  // Error codes
  localparam ERR_TIME_OUTTA_SYNC      = 32'h20;
  localparam ERR_MISSING_TLAST        = 32'h10;

  reg [2:0] ibs_state;
  reg [27:0] lines_left, repeat_lines;
  reg [15:0] lines_left_pkt;

  assign error_time =  o_tuser_fifo[63:0]; //this device time is local device tuser time

  //register error_time and cumulative_end_of_burst_reg
  always @ (posedge clk) begin
    error_time_reg <= error_time;
    cumulative_end_of_burst_reg <= cumulative_end_of_burst;
    tuser_fifo_end_of_burst_reg <= tuser_fifo_end_of_burst;
    or_end_of_burst_reg <= or_end_of_burst;
  end

  assign seqnum_cnt = o_tuser_fifo[123:112];
  wire [127:0] error_header = {2'b11, 1'b1,           1'b1, seqnum_cnt,                  16'h24, resp_sid,  error_time_reg};


  //State Machine to handle errors.
  // Will always start in IDLE and won't move to next state until at least
  //1 clock cycle later because of syncronous RESET.
  always @(posedge clk) begin
    if (reset | clear) begin
      ibs_state      <= IBS_IDLE;
      resp_reg_tdata     <= 'd0;
      resp_reg_tlast     <= 1'b0;
      resp_reg_tvalid    <= 1'b0;
      resp_reg_tuser     <= 'd0;
      time_fifo_ready  <= 1'b0;
      error_reg <= 1'b0;
      error <= 'd0;
      force_eob_error_reg <= 1'b0;
    end else begin
      case (ibs_state)
        IBS_IDLE : begin
          force_eob_error_reg <= 1'b0;
          time_fifo_ready  <= 1'b0;
          error_reg <= 1'b0;
          error <= 'd0;
          if (cumulative_time_valid) begin
              ibs_state      <= IBS_RUNNING;
          end
        end

        IBS_RUNNING : begin
          o_tuser_fifo_reg <= {o_tuser_fifo[127:125], eob, o_tuser_fifo[123:0]};
          time_fifo_ready <= 1'b0;
          if (~cumulative_time_valid) begin
            ibs_state      <= IBS_IDLE;
          end
          else if (cumulative_time_valid) begin
            if (cumulative_now) begin
              if (and_tlast) begin
                ibs_state      <= IBS_LOAD_NEXT_TIME;
              end
              //missing TLAST
              else if (or_tlast) begin
                error <= ERR_MISSING_TLAST;
                ibs_state <= IBS_ERR_WAIT_FOR_READY;
                force_eob_error_reg <= 1'b1;
              end
            end
            else if (~cumulative_now) begin // TIME OUTTA SYNC
              error          <= ERR_TIME_OUTTA_SYNC;
              ibs_state      <= IBS_ERR_WAIT_FOR_READY;
              force_eob_error_reg <= 1'b1;
            end
          end
        end

        IBS_LOAD_NEXT_TIME: begin
          if(cumulative_is_occupied) begin
            time_fifo_ready <= 1'b1;
            ibs_state  <= IBS_IDLE;
          end
        end

        // Wait for output to be ready
        IBS_ERR_WAIT_FOR_READY : begin
          time_fifo_ready  <= 1'b1;
          o_tuser_fifo_reg <= {o_tuser_fifo[127:125], eob, o_tuser_fifo[123:0]};
          if (resp_reg_tready) begin
            resp_reg_tvalid <= 1'b1;
            resp_reg_tlast  <= 1'b0;
            resp_reg_tdata  <= error;
            resp_reg_tuser  <= error_header;
            ibs_state     <= IBS_ERR_SEND_PKT;
          end
        end

        IBS_ERR_SEND_PKT : begin
          time_fifo_ready <= 1'b0;
          error_reg <= 1'b1;
          if (resp_reg_tready) begin
            resp_reg_tvalid <= 1'b1;
            resp_reg_tlast  <= 1'b1;
            resp_reg_tdata  <= 'd0;
            if (resp_reg_tlast) begin
              resp_reg_tvalid <= 1'b0;
              resp_reg_tlast  <= 1'b0;
              ibs_state     <= IBS_ERR_TIL_NEXT_RUN;
            end
          end
        end
        //stay here until error clears and we start next run (initiated by a clear).
        IBS_ERR_TIL_NEXT_RUN: begin
        end

        default : ibs_state <= IBS_IDLE;
      endcase
    end
  end
  
  assign eob = cumulative_end_of_burst_reg | force_eob_error_reg;

  // Register output
  axi_fifo #(.WIDTH(193), .SIZE(1))
  axi_fifo_error_resp (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({resp_reg_tlast,resp_reg_tdata, 32'h00000000, resp_reg_tuser}), .i_tvalid(resp_reg_tvalid), .i_tready(resp_reg_tready),
    .o_tdata({resp_tlast, resp_tdata, resp_tuser}), .o_tvalid(resp_tvalid), .o_tready(resp_tready),
    .space(), .occupied());

  axi_fifo #(.WIDTH(128), .SIZE(1))
  axi_fifo_o_tuser (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(o_tuser_fifo_reg), .i_tvalid(1'b1), .i_tready(),
    .o_tdata(o_tuser), .o_tvalid(), .o_tready(1'b1),
    .space(), .occupied());
    
endmodule
