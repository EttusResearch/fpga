/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// RX Control Eiscat
// Converts strobed sample data from radio frontend to the AXI-Stream bus
// Outputs an error packet if an overrun, late timed command, or empty command fifo error occurs.
// Some differences in behavior and functionality compared to default RX Control Gen3 module, 
// so an entirely new one was made.
//
// HALT brings RX to an idle state as quickly as possible if RX is running
// without running the risk of leaving a packet fragment in downstream FIFO's.
// HALT also flushes all remaining pending commands in the commmand FIFO.
//

module rx_control_eiscat #(
  parameter SR_RX_CTRL_COMMAND = 0,     // Command FIFO
  parameter SR_RX_CTRL_TIME_HI = 1,     // Command execute time (high word)
  parameter SR_RX_CTRL_TIME_LO = 2,     // Command execute time (low word)
  parameter SR_RX_CTRL_HALT = 3,        // Halt command -> return to idle state
  parameter SR_RX_CTRL_MAXLEN = 4,      // Packet length
  parameter SR_RX_CTRL_CLEAR_CMDS = 5,   // Clear command FIFO
  parameter SR_RX_CTRL_OUTPUT_FORMAT = 6,   // Output format (use timestamps)
  parameter SR_RX_STREAM_ENABLE = 7,   // Enable Streams use bits 0-9 for each of 10 streams.
  parameter NUM_BEAMS = 10,
  parameter BEAM_WIDTH = 16
)(
  input clk, input reset,
  input clear, // Resets state machine and clear output FIFO.
  input [63:0] vita_time, input [31:0] sid, input [31:0] resp_sid,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  // Data packets
  output [NUM_BEAMS*BEAM_WIDTH-1:0] rx_tdata, output [NUM_BEAMS-1:0] rx_tlast, output [NUM_BEAMS-1:0] rx_tvalid, input [NUM_BEAMS-1:0] rx_tready, 
  output reg [127:0] rx_tuser, //only 1 tuser for all the beams. later the sid will be replaced with something more appropriate where needed.
  // Error packets, In gen 3: unused as error packets must come inline with data, but we will use it here.
  output [63:0] resp_tdata, output [127:0] resp_tuser, output resp_tlast, output resp_tvalid, input resp_tready,
  // From radio frontend
  output run, input [NUM_BEAMS*BEAM_WIDTH-1:0] sample, input [9:0] strobe,
  output clear_out,
  output [NUM_BEAMS-1:0] stream_enabled_out,
  output [2:0] ibs_state_out
);

  //error packets registers
  reg [63:0] resp_reg_tdata;
  reg [127:0] resp_reg_tuser;
  reg resp_reg_tlast, resp_reg_tvalid; 
  wire resp_reg_tready;


  reg [NUM_BEAMS*BEAM_WIDTH-1:0] rx_reg_tdata;
  reg [63:0] error;
  reg [NUM_BEAMS-1:0] rx_reg_tlast;
  reg [NUM_BEAMS-1:0] rx_reg_tvalid;
  wire [NUM_BEAMS-1:0] rx_reg_tready;
  reg [127:0] rx_reg_tuser, error_tuser;
  
  wire [NUM_BEAMS*BEAM_WIDTH-1:0] rx_bram_tdata;
  wire [NUM_BEAMS-1:0] rx_bram_tlast;
  wire [NUM_BEAMS-1:0] rx_bram_tvalid;
  wire [NUM_BEAMS-1:0] rx_bram_tready;
  wire [NUM_BEAMS*16-1:0] axi_fifo_bram_space;
  wire [NUM_BEAMS*16-1:0] axi_fifo_bram_occupied;

  wire [NUM_BEAMS-1:0] overflow = rx_tvalid & ~rx_tready; //if any valids and not ready

  wire [31:0] command_i;
  wire [63:0] time_i;
  wire store_command;

  wire send_imm, chain, reload, stop;
  wire [27:0] numlines; //SPP is 3992, with each sample 2 bytes. Standard packets are 8000 bytes.
  wire [63:0] rcvtime;
  wire use_timestamps;

  wire now, early, late;
  wire command_valid;
  reg command_ready;

  reg chain_sav, reload_sav;
  reg clear_halt;
  reg halt;
  wire set_halt;
  wire [15:0] maxlen;
  wire eob;
  reg [63:0] start_time;
  wire clear_cmds;
  reg clear_reg;
  wire [9:0] stream_enabled;
  wire stream_enable_changed;
  wire maxlen_changed;
  wire time_hi_changed;

  setting_reg #(.my_addr(SR_RX_CTRL_COMMAND)) sr_cmd (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(command_i),.changed());

  setting_reg #(.my_addr(SR_RX_CTRL_TIME_HI)) sr_time_h (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[63:32]),.changed(time_hi_changed));

  setting_reg #(.my_addr(SR_RX_CTRL_TIME_LO)) sr_time_l (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[31:0]),.changed(store_command));

  setting_reg #(.my_addr(SR_RX_CTRL_HALT)) sr_rx_halt (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(),.changed(set_halt));

  setting_reg #(.my_addr(SR_RX_CTRL_MAXLEN), .width(16)) sr_maxlen (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(maxlen),.changed(maxlen_changed));

  setting_reg #(.my_addr(SR_RX_CTRL_CLEAR_CMDS)) sr_clear_cmds (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(),.changed(clear_cmds));

  setting_reg #(.my_addr(SR_RX_CTRL_OUTPUT_FORMAT), .width(1), .at_reset(1'b1)) sr_output_format (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(use_timestamps),.changed());
  
  //stream enables, 10 bits for 10 streams  
  setting_reg #(.my_addr(SR_RX_STREAM_ENABLE), .width(10), .at_reset(10'h3FF)) sr_stream_enable (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(stream_enabled),.changed(stream_enable_changed));
    
  assign stream_enabled_out = stream_enabled;
  assign clear_out = clear_reg;

  always @(posedge clk)
    if (reset | clear | clear_halt | clear_cmds)
      halt <= 1'b0;
    else
      halt <= set_halt;

  axi_fifo_short #(.WIDTH(96)) commandfifo (
    .clk(clk),.reset(reset),.clear(clear | clear_halt | clear_cmds),
    .i_tdata({command_i,time_i}), .i_tvalid(store_command), .i_tready(),
    .o_tdata({send_imm,chain,reload,stop,numlines,rcvtime}),
    .o_tvalid(command_valid), .o_tready(command_ready),
    .occupied(), .space() );

  time_compare time_compare (
    .clk(clk), .reset(reset),
    .time_now(vita_time), .trigger_time(rcvtime), .now(now), .early(early), .late(late), .too_early());

  // State machine states
  localparam IBS_IDLE                = 0;
  localparam IBS_RUNNING             = 1;
  localparam IBS_ERR_WAIT_FOR_READY  = 2;
  localparam IBS_ERR_SEND_PKT        = 3;
  localparam IBS_OVERRUN_HANDLER     = 4;


  // Error codes
  localparam ERR_OVERRUN      = 64'h0000000800000000;
  localparam ERR_BROKENCHAIN  = 64'h0000000400000000;
  localparam ERR_LATECMD      = 64'h0000000200000000;

  reg [2:0] ibs_state;
  reg [27:0] lines_left, repeat_lines;
  reg [15:0] lines_left_pkt;
  assign ibs_state_out = ibs_state;

  reg [11:0] seqnum_cnt;
  reg [11:0] seqnum_del; //do a seqnum_del because of weird tuser behaviors...
  always @(posedge clk) begin
    if (reset | clear | clear_halt) begin
      seqnum_cnt <= 'd0;
    end else begin
      // Do not increment sequence number on error packets
      if (rx_reg_tlast & rx_reg_tready & rx_reg_tvalid) begin
        seqnum_cnt <= seqnum_cnt + 1'b1;
      end
    end
  end

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

  wire [127:0] error_header = {2'b11, 1'b1,           1'b1, seqnum_cnt,                  16'h24, resp_sid,  vita_time};
  wire [127:0] rx_header    = {2'b00, use_timestamps,  eob, seqnum_del, 16'b0 /*len ignored*/,      sid, start_time};

  always @(posedge clk) begin
    if (reset | clear) begin
      ibs_state      <= IBS_IDLE;
      lines_left     <= 'd0;
      lines_left_pkt <= 'd0;
      repeat_lines   <= 'd0;
      start_time     <= 'd0;
      seqnum_del     <= 'd0;
      chain_sav      <= 1'b0;
      reload_sav     <= 1'b0;
      clear_halt     <= 1'b0;
      rx_reg_tdata   <= 'd0;
      rx_reg_tlast   <= 10'b0;
      rx_reg_tvalid  <= 10'b0;
      rx_reg_tuser   <= 'd0;
      resp_reg_tdata     <= 'd0;
      resp_reg_tlast     <= 1'b0;
      resp_reg_tvalid    <= 1'b0;
      resp_reg_tuser     <= 'd0;
      command_ready  <= 1'b0;
      clear_reg <= 1'b1;
    end else begin
      case (ibs_state)
        IBS_IDLE : begin
          rx_reg_tlast   <= 10'b0;
          rx_reg_tvalid  <= 10'b0;
          command_ready  <= 1'b0;
          clear_halt     <= 1'b0; // Incase we got here through a HALT.
          clear_reg <= 1'b0; //if the host asks for a specific # of samples, the number it gets back will be less than what it asks for.
          //the use case of EISCAT is continuous streaming until the end the host receives a certain number of samples though
          //so this should work okay. (STOP command is sent after last requested sample is recieved)
          if (command_valid & rx_reg_tready) begin
            // There is a valid command to pop from FIFO
            if (stop) begin
              // Stop bit set in this command, go idle.
              command_ready <= 1'b1;
              ibs_state     <= IBS_IDLE;
            end else if (late & ~send_imm) begin
              // Got this command later than its execution time.
              command_ready <= 1'b1;
              error         <= ERR_LATECMD;
              ibs_state     <= IBS_ERR_WAIT_FOR_READY;
            end else if (now | send_imm) begin
              // Either its time to run this command or it should run immediately without a time.
              command_ready  <= 1'b1;
              lines_left     <= numlines;
              repeat_lines   <= numlines;
              chain_sav      <= chain;
              reload_sav     <= reload;
              lines_left_pkt <= maxlen;
              ibs_state      <= IBS_RUNNING;
            end
          end
        end

        IBS_RUNNING : begin
          command_ready <= 1'b0;
          clear_reg <= 1'b0;
          if (strobe) begin
            rx_reg_tvalid <= stream_enabled;
            rx_reg_tlast  <= {10{eob | (lines_left_pkt == 1)}};
            rx_reg_tuser  <= rx_header;
            rx_reg_tdata  <= sample;
            if (lines_left_pkt == 1) begin
              lines_left_pkt <= maxlen;
            end else begin
              lines_left_pkt <= lines_left_pkt - 1;
            end
            if (lines_left_pkt == maxlen) begin
              start_time <= vita_time;
              seqnum_del <= seqnum_cnt;
            end
            if (lines_left == 1) begin
              if (halt) begin // Provide Halt mechanism used to bring RX into known IDLE state at re-initialization.
                ibs_state <= IBS_IDLE;
                clear_halt <= 1'b1;
              end else if (chain_sav) begin // If chain_sav is true then execute the next command now this one finished.
                if (command_valid) begin
                  command_ready <= 1'b1;
                  lines_left    <= numlines;
                  repeat_lines  <= numlines;
                  chain_sav     <= chain;
                  reload_sav    <= reload;
                  if (stop) begin // If the new command includes stop then go idle.
                    ibs_state <= IBS_IDLE;
                  end
                end else if (reload_sav) begin // There is no new command to pop from FIFO so re-run previous command.
                  lines_left <= repeat_lines;
                end else begin // Chain has been broken, no commands left in FIFO and reload not set.
                  error         <= ERR_BROKENCHAIN;
                  ibs_state     <= IBS_ERR_WAIT_FOR_READY;
                end
              end else begin // Chain is not true, so don't look for new command, instead go idle.
                ibs_state <= IBS_IDLE;
              end
            end else begin // Still counting down lines in current command.
              lines_left <= lines_left - 28'd1;
            end
          end else begin
            rx_reg_tvalid <= 10'h000;  // Sample consumed, drop tvalid
          end
          // Overflow condition -- can occur regardless of strobe state
          if (overflow) begin
            if (lines_left_pkt[1:0] == 2'b01) begin
              rx_reg_tvalid  <= stream_enabled;      // Send final sample
              rx_reg_tlast   <= 10'h3FF;      // ... and end packet
              rx_reg_tuser   <= rx_header; // Update tuser with EOB set
              error          <= ERR_OVERRUN;
              ibs_state      <= IBS_ERR_WAIT_FOR_READY;
            end else begin
              rx_reg_tvalid  <= stream_enabled;      // Send final sample
              rx_reg_tuser   <= rx_header; // Update tuser with EOB set
              error          <= ERR_OVERRUN;
              ibs_state      <= IBS_OVERRUN_HANDLER;
              lines_left_pkt <= lines_left_pkt - 1;              
            end
          end
        end
        
        //IF overflow
        IBS_OVERRUN_HANDLER : begin
          clear_reg <= 1'b1;
          if (lines_left_pkt[1:0] == 2'b01) begin
            rx_reg_tvalid  <= stream_enabled;      // Send final sample
            rx_reg_tlast   <= 10'h3FF;      // ... and end packet
            rx_reg_tuser   <= rx_header; // Update tuser with EOB set
            error          <= ERR_OVERRUN;
            ibs_state      <= IBS_ERR_WAIT_FOR_READY;
          end else begin
            lines_left_pkt <= lines_left_pkt - 1;              
          end
        end

        // Wait for output to be ready
        IBS_ERR_WAIT_FOR_READY : begin
          command_ready  <= 1'b0;
          rx_reg_tvalid  <= 10'h000;      // Sent final packet, now 0
          if (resp_reg_tready) begin
            resp_reg_tvalid <= 1'b1;
            resp_reg_tlast  <= 1'b0;
            resp_reg_tdata  <= error;
            resp_reg_tuser  <= error_header;
            ibs_state     <= IBS_ERR_SEND_PKT;
          end
        end

        IBS_ERR_SEND_PKT : begin
          command_ready <= 1'b0;
          clear_reg <= 1'b1;
          if (rx_reg_tready) begin
            resp_reg_tvalid <= 1'b1;
            resp_reg_tlast  <= 1'b1;
            resp_reg_tdata  <= 'd0;
            if (resp_reg_tlast) begin
              resp_reg_tvalid <= 1'b0;
              resp_reg_tlast  <= 1'b0;
              ibs_state     <= IBS_IDLE;
            end
          end
        end

        default : ibs_state <= IBS_IDLE;
      endcase
    end
  end

  assign run = (ibs_state == IBS_RUNNING);

  assign eob = ((lines_left == 1) & ( !chain_sav | (command_valid & stop) | (!command_valid & !reload_sav) | halt)) | (|overflow);

  always @(posedge clk) begin
    if(rx_reg_tvalid) begin
      rx_tuser <= rx_reg_tuser;
    end
  end

  genvar n;
  generate 
  for (n = 0; n < NUM_BEAMS; n = n + 1) begin : gen_timed_beams
    //this exists solely to ensure that when an overflow occurs, the packet size is divisible by 4
    // so when passing accross aurora interfaces all the tlasts line up correctly.
    axi_fifo_bram #(.WIDTH(17), .SIZE(3))
    axi_fifo_bram_rx_data (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({rx_reg_tlast[n], rx_reg_tdata[n*BEAM_WIDTH+BEAM_WIDTH-1:n*BEAM_WIDTH]}), 
    .i_tvalid(rx_reg_tvalid[n]), .i_tready(rx_reg_tready[n]),
    .o_tdata({rx_bram_tlast[n], rx_bram_tdata[n*BEAM_WIDTH+BEAM_WIDTH-1:n*BEAM_WIDTH]}), 
    .o_tvalid(rx_bram_tvalid[n]), .o_tready(rx_bram_tready[n]),
    .space(axi_fifo_bram_space[n*16+16-1:n*16]),
    .occupied(axi_fifo_bram_occupied[n*16+16-1:n*16]));
    
    axi_fifo_flop2 #(.WIDTH(17))
    axi_fifo_flop2_rx_data (
      .clk(clk), .reset(reset), .clear(clear),
      .i_tdata({rx_bram_tlast[n], rx_bram_tdata[n*BEAM_WIDTH+BEAM_WIDTH-1:n*BEAM_WIDTH]}), 
      .i_tvalid(rx_bram_tvalid[n]), .i_tready(rx_bram_tready[n]),
      .o_tdata({rx_tlast[n], rx_tdata[n*BEAM_WIDTH+BEAM_WIDTH-1:n*BEAM_WIDTH]}), 
      .o_tvalid(rx_tvalid[n]), .o_tready(rx_tready[n]),
      .space(), .occupied());
  end    
  endgenerate
  // Register output
  axi_fifo #(.WIDTH(193), .SIZE(1))
  axi_fifo_error_resp (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({resp_reg_tlast, resp_reg_tdata, resp_reg_tuser}), .i_tvalid(resp_reg_tvalid), .i_tready(resp_reg_tready),
    .o_tdata({resp_tlast, resp_tdata, resp_tuser}), .o_tvalid(resp_tvalid), .o_tready(resp_tready),
    .space(), .occupied());

endmodule
