//
// Copyright 2020 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: axi_replay.v
//
// Description:
//
//   This block implements the registers, state machines, and control logic for
//   recording and playback of AXI-Stream data using an attached memory as a
//   buffer. It has a set of registers for controlling recording and a set of
//   registers for controlling playback. See rfnoc_replay_regs.vh for a
//   description of the registers.
//
//   RECORDING
//
//   The AXI-Stream data received on the input port is written to the attached
//   memory into a buffer space configured by the record registers. The
//   REG_REC_BASE_ADDR register indicates the starting address for the record
//   buffer and SR_REC_BUFFER_SIZE indicates how much memory to allocate for
//   recording. SR_REC_FULLNESS can be used to determine how much data has
//   been buffered. Once the configured buffer size has filled, the block stops
//   accepting data. That is, it will deassert i_tready to stall any input
//   data. Recording can be restarted (SR_REC_RESTART) to accept the remaining
//   data and write it at the beginning of the configured buffer.
//
//   PLAYBACK
//
//   Playback is completely independent of recording. The playback buffer is
//   configured similarly to the radio block using its own registers. Playback
//   is started by writing a command to the SR_RX_CTRL_TIME register.
//
//   A timestamp for playback can also be specified by setting
//   SR_RX_CTRL_TIME and clearing the send_imm bit as part of the
//   command write. The timestamp will then be included in all output packets,
//   starting with the provided timestamp value and auto-incrementing for every
//   4 bytes of data in each packet.
//
//   When playback reaches the end of the configured playback buffer, if more
//   words were requested, it will loop back to the beginning of the buffer to
//   continue playing data. The last packet of playback will always have the
//   EOB flag set (e.g., after num_lines words have been played back or
//   after stop has been issued).
//
//   MEMORY SHARING
//
//   Because the record and playback logic share the same memory and can
//   operate independently, care must be taken to manage the record and
//   playback buffers. You should ensure that recording is complete before
//   trying to play back the recorded data. Simultaneous recording and playing
//   back is allowed, but is only recommended when the recording and playback
//   are to different sections of memory, such that unintended overlap of the
//   write/read pointers will never occur.
//
//   Furthermore, if multiple replay modules are instantiated and share the
//   same external memory, care must be taken to not unintentionally affect the
//   contents of neighboring buffers.
//
//   MEMORY WORD SIZE
//
//   The address and size registers are in terms of bytes. But playback and
//   recording length and fullness are in terms of memory words (MEM_DATA_W
//   bits wide). The current implementation can't read/write to the memory in
//   units other than the memory word size. So care must be taken to ensure
//   that num_lines and SR_RX_CTRL_MAXLEN always indicate the
//   number of memory words intended. The number of samples to playback or
//   record must always represent an amount of data that is a multiple of the
//   memory word size.
//

`default_nettype none


module axi_replay #(
  parameter MEM_DATA_W  = 64,
  parameter MEM_ADDR_W  = 34, // Byte address width used by memory controller
  parameter MEM_COUNT_W = 8   // Length of counters used to connect to the
                              // memory interface's read and write ports.
) (
  input wire clk,
  input wire rst,  // Synchronous to clk

  //---------------------------------------------------------------------------
  // Settings Bus
  //---------------------------------------------------------------------------

  input  wire        set_stb,
  input  wire [ 7:0] set_addr,
  input  wire [31:0] set_data,
  output reg  [31:0] rb_data,
  input  wire [ 7:0] rb_addr,

  //---------------------------------------------------------------------------
  // AXI Stream Interface
  //---------------------------------------------------------------------------

  // Input
  input  wire [MEM_DATA_W-1:0] i_tdata,
  input  wire                  i_tvalid,
  input  wire                  i_tlast,
  output wire                  i_tready,

  // Output
  output wire [MEM_DATA_W-1:0] o_tdata,
  output wire [         127:0] o_tuser,
  output wire                  o_tvalid,
  output wire                  o_tlast,
  input  wire                  o_tready,

  //---------------------------------------------------------------------------
  // Memory Interface
  //---------------------------------------------------------------------------

  // Write interface
  output reg  [ MEM_ADDR_W-1:0] write_addr,      // Byte address for start of write
                                                 // transaction (64-bit aligned).
  output reg  [MEM_COUNT_W-1:0] write_count,     // Count of 64-bit words to write, minus 1.
  output reg                    write_ctrl_valid,
  input  wire                   write_ctrl_ready,
  output wire [ MEM_DATA_W-1:0] write_data,
  output wire                   write_data_valid,
  input  wire                   write_data_ready,

  // Read interface
  output reg  [ MEM_ADDR_W-1:0] read_addr,       // Byte address for start of read
                                                 // transaction (64-bit aligned).
  output reg  [MEM_COUNT_W-1:0] read_count,      // Count of 64-bit words to read, minus 1.
  output reg                    read_ctrl_valid,
  input  wire                   read_ctrl_ready,
  input  wire [ MEM_DATA_W-1:0] read_data,
  input  wire                   read_data_valid,
  output wire                   read_data_ready
);

  //---------------------------------------------------------------------------
  // Constants
  //---------------------------------------------------------------------------

  localparam NUM_WORDS_W = 28;                // Width of cmd_num_lines
  localparam TIME_W      = 64;                // Width of timestamp
  localparam CMD_W       = 32;                // Width of command
  localparam WPP_W       = 13;                // Length of words-per-packet
  localparam MEM_SIZE_W  = MEM_ADDR_W + 1;    // Number of bits needed to
                                              // represent memory size in bytes.

  // Memory Alignment
  //
  // Size of DATA_WIDTH in bytes
  localparam BYTES_PER_WORD = MEM_DATA_W/8;
  //
  // The lower MEM_ALIGN bits for all memory byte addresses should be 0.
  localparam MEM_ALIGN = $clog2(MEM_DATA_W / 8);
  //
  // AXI alignment requirement (4096 bytes) in MEM_DATA_W-bit words
  localparam AXI_ALIGNMENT = 4096 / BYTES_PER_WORD;

  // Memory Buffering Parameters
  //
  // Log base 2 of the depth of the input and output FIFOs to use. The FIFOs
  // should be large enough to store more than a complete burst
  // (MEM_BURST_LEN). A size of 9 (512 64-bit words) is one 36-kbit BRAM.
  localparam REC_FIFO_ADDR_WIDTH  = 9;  // Log2 of input/record FIFO size
  localparam PLAY_FIFO_ADDR_WIDTH = 9;  // Log2 of output/playback FIFO size
  localparam HDR_FIFO_ADDR_WIDTH  = 5;  // Log2 of output/time FIFO size
  //
  // Amount of data to buffer before writing to RAM. It must not exceed
  // 2**MEM_COUNT_W (the maximum count allowed by an AXI master).
  localparam MEM_BURST_LEN = 2**MEM_COUNT_W;  // Size in MEM_DATA_W-sized words
  //
  // Clock cycles to wait before writing something less than MEM_BURST_LEN
  // to memory.
  localparam DATA_WAIT_TIMEOUT = 31;

  // Register offsets
  localparam [7:0] SR_REC_BASE_ADDR    = 128;
  localparam [7:0] SR_REC_BUFFER_SIZE  = 129;
  localparam [7:0] SR_REC_RESTART      = 130;
  localparam [7:0] SR_REC_FULLNESS     = 131;
  localparam [7:0] SR_PLAY_BASE_ADDR   = 132;
  localparam [7:0] SR_PLAY_BUFFER_SIZE = 133;
  localparam [7:0] SR_RX_CTRL_COMMAND  = 152; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_TIME_HI  = 153; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_TIME_LO  = 154; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_HALT     = 155; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_MAXLEN   = 156; // Same offset as radio


  //---------------------------------------------------------------------------
  // Functions
  //---------------------------------------------------------------------------

  function integer max(input integer a, b);
    begin
      if (a > b) max = a;
      else max = b;
    end
  endfunction

  function integer min(input integer a, b);
    begin
      if (a < b) min = a;
      else min = b;
    end
  endfunction

  // This zeros the lower MEM_ALIGN bits of the input address.
  function [MEM_SIZE_W-1:0] mem_align(input [MEM_SIZE_W-1:0] addr);
    begin
      mem_align = { addr[MEM_SIZE_W-1 : MEM_ALIGN], {MEM_ALIGN{1'b0}} };
    end
  endfunction


  //---------------------------------------------------------------------------
  // Data FIFO Signals
  //---------------------------------------------------------------------------

  // Record Data FIFO (Input)
  wire [MEM_DATA_W-1:0] rec_fifo_o_tdata;
  wire                  rec_fifo_o_tvalid;
  wire                  rec_fifo_o_tready;
  wire [          15:0] rec_fifo_occupied;

  // Playback Data FIFO (Output)
  wire [MEM_DATA_W-1:0] play_fifo_i_tdata;
  wire                  play_fifo_i_tvalid;
  wire                  play_fifo_i_tready;
  wire [          15:0] play_fifo_space;


  //---------------------------------------------------------------------------
  // Registers
  //---------------------------------------------------------------------------

  // Settings registers signals
  wire [ MEM_ADDR_W-1:0] rec_base_addr_sr;    // Byte address
  wire [ MEM_SIZE_W-1:0] rec_buffer_size_sr;  // Size in bytes
  wire [ MEM_ADDR_W-1:0] play_base_addr_sr;   // Byte address
  wire [ MEM_SIZE_W-1:0] play_buffer_size_sr; // Size in bytes

  wire [ MEM_ADDR_W-1:0] rec_base_addr_tmp;    // Byte address
  wire [ MEM_SIZE_W-1:0] rec_buffer_size_tmp;  // Size in bytes
  wire [ MEM_ADDR_W-1:0] play_base_addr_tmp;   // Byte address
  wire [ MEM_SIZE_W-1:0] play_buffer_size_tmp; // Size in bytes

  wire [     63:0] reg_rec_fullness;
  reg              rec_restart_clear;
  reg              rec_restart;
  wire [CMD_W-1:0] command;
  wire             command_valid;
  wire [     63:0] command_time;
  reg              play_halt;
  reg              play_halt_clear;
  wire [WPP_W-1:0] play_max_len_sr;

  // Record Base Address Register. Address is a byte address. This must be a
  // multiple of 8 bytes.
  setting_reg #(
    .my_addr (SR_REC_BASE_ADDR),
    .width   (MEM_ADDR_W)
  ) sr_rec_base_addr (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (rec_base_addr_tmp),
    .changed ()
  );
  assign rec_base_addr_sr = { rec_base_addr_tmp[MEM_ADDR_W-1:3], 3'b0 };


  // Record Buffer Size Register. This indicates the portion of the RAM
  // allocated to the record buffer, in bytes. This should be a multiple of 8
  // bytes.
  setting_reg #(
    .my_addr (SR_REC_BUFFER_SIZE),
    .width   (MEM_SIZE_W)
  ) sr_rec_buffer_size (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (rec_buffer_size_tmp),
    .changed ()
  );
  assign rec_buffer_size_sr = { rec_buffer_size_tmp[MEM_SIZE_W-1:3], 3'b0 };


  // Playback Base Address Register. Address is a byte address. This must be a
  // multiple of the 8 bytes.
  setting_reg #(
    .my_addr (SR_PLAY_BASE_ADDR),
    .width   (MEM_ADDR_W)
  ) sr_play_base_addr (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (play_base_addr_tmp),
    .changed ()
  );
  assign play_base_addr_sr = { play_base_addr_tmp[MEM_ADDR_W-1:3], 3'b0 };


  // Playback Buffer Size Register. This indicates the portion of the RAM
  // allocated to the record buffer, in bytes. This should be a multiple of 8
  // bytes.
  setting_reg #(
    .my_addr (SR_PLAY_BUFFER_SIZE),
    .width   (MEM_SIZE_W)
  ) sr_play_buffer_size (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (play_buffer_size_tmp),
    .changed ()
  );
  assign play_buffer_size_sr = { play_buffer_size_tmp[MEM_SIZE_W-1:3], 3'b0 };


  // Record Buffer Restart Register. Software must write to this register after
  // updating the base address or buffer size. A write to this register means
  // we need to stop any recording in progress and reset the record buffers
  // according to the current buffer base address and size registers.
  always @(posedge clk)
  begin : sr_restart
    if(rst) begin
      rec_restart <= 1'b0;
    end else begin
      if(set_stb & (set_addr == SR_REC_RESTART)) begin
        rec_restart <= 1'b1;
      end else if (rec_restart_clear) begin
        rec_restart <= 1'b0;
      end
    end
  end


  // Halt Register. A write to this register stops any replay operation as soon
  // as the current DRAM transaction completes.
  always @(posedge clk)
  begin : sr_halt
    if(rst) begin
      play_halt <= 1'b0;
    end else begin
      if(set_stb & (set_addr == SR_RX_CTRL_HALT)) begin
        play_halt <= 1'b1;
      end else if (play_halt_clear) begin
        play_halt <= 1'b0;
      end
    end
  end


  // Play Command Register
  //
  // This register mirrors the behavior of the RFNoC RX radio block. All
  // commands are queued up in the replay command FIFO. The fields are as
  // follows.
  //
  //   send_imm    [31]  Send command immediately (don't use time).
  //
  //   chain       [30]  When done with num_lines, immediately run next command.
  //
  //   reload      [29]  When done with num_lines, rerun the same command if
  //                     cmd_chain is set and no new command is available.
  //
  //   stop        [28]  When done with num_lines, stop transferring if
  //                     cmd_chain is set.
  //
  //   num_lines [27:0]  Number of words to transfer to/from block.
  //
  setting_reg #(
    .my_addr (SR_RX_CTRL_COMMAND),
    .width   (CMD_W)
  ) sr_command (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (command),
    .changed (command_valid)
  );

  // Playback Start Time (Upper Bits)
  setting_reg #(
    .my_addr (SR_RX_CTRL_TIME_HI),
    .width   (TIME_W-32)
  ) sr_time_hi (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (command_time[TIME_W-1:32]),
    .changed ()
  );

  // Playback Start Time (Lower Bits)
  setting_reg #(
    .my_addr (SR_RX_CTRL_TIME_LO),
    .width   (32)
  ) sr_time_lo (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (command_time[31:0]),
    .changed ()
  );

  // Max Length Register. This register sets the number of words for the
  // maximum packet size.
  setting_reg #(
    .my_addr (SR_RX_CTRL_MAXLEN),
    .width   (WPP_W),
    .at_reset(1 << MEM_COUNT_W)
  ) sr_max_len (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (play_max_len_sr),
    .changed ()
  );


  // Implement register read
  always @(*) begin
    case (rb_addr)
      SR_REC_BASE_ADDR    : rb_data = rec_base_addr_sr;
      SR_REC_BUFFER_SIZE  : rb_data = rec_buffer_size_sr;
      SR_REC_FULLNESS     : rb_data = reg_rec_fullness;
      SR_PLAY_BASE_ADDR   : rb_data = play_base_addr_sr;
      SR_PLAY_BUFFER_SIZE : rb_data = play_buffer_size_sr;
      SR_RX_CTRL_MAXLEN   : rb_data = {{(64-WPP_W){1'b0}}, play_max_len_sr};
      default             : rb_data = 32'h0;
    endcase
  end


  //---------------------------------------------------------------------------
  // Playback Command FIFO
  //---------------------------------------------------------------------------
  //
  // This block queues up commands for playback.
  //
  //---------------------------------------------------------------------------

  // Command FIFO Signals
  wire                   cmd_send_imm_cf, cmd_chain_cf, cmd_reload_cf, cmd_stop_cf;
  wire [NUM_WORDS_W-1:0] cmd_num_lines_cf;
  wire [     TIME_W-1:0] cmd_time_cf;
  wire                   cmd_fifo_valid;
  reg                    cmd_fifo_ready;

  axi_fifo_short #(
    .WIDTH (CMD_W + TIME_W)
  ) command_fifo (
    .clk      (clk),
    .reset    (rst),
    .clear    (play_halt_clear),
    .i_tdata  ({command, command_time}),
    .i_tvalid (command_valid),
    .i_tready (),
    .o_tdata  ({cmd_send_imm_cf, cmd_chain_cf, cmd_reload_cf, cmd_stop_cf, cmd_num_lines_cf, cmd_time_cf}),
    .o_tvalid (cmd_fifo_valid),
    .o_tready (cmd_fifo_ready),
    .occupied (),
    .space    ()
  );


  //---------------------------------------------------------------------------
  // Record Input Data FIFO
  //---------------------------------------------------------------------------
  //
  // This FIFO stores data to be recorded into the external memory.
  //
  //---------------------------------------------------------------------------

  axi_fifo #(
    .WIDTH (MEM_DATA_W),
    .SIZE  (REC_FIFO_ADDR_WIDTH)
  ) rec_axi_fifo (
    .clk      (clk),
    .reset    (rst),
    .clear    (1'b0),
    //
    .i_tdata  (i_tdata),
    .i_tvalid (i_tvalid),
    .i_tready (i_tready),
    //
    .o_tdata  (rec_fifo_o_tdata),
    .o_tvalid (rec_fifo_o_tvalid),
    .o_tready (rec_fifo_o_tready),
    //
    .space    (),
    .occupied (rec_fifo_occupied)
  );


  //---------------------------------------------------------------------------
  // Record State Machine
  //---------------------------------------------------------------------------

  // FSM States
  localparam REC_WAIT_FIFO       = 0;
  localparam REC_CHECK_ALIGN     = 1;
  localparam REC_MEM_REQ         = 2;
  localparam REC_WAIT_MEM_START  = 3;
  localparam REC_WAIT_MEM_COMMIT = 4;

  // State Signals
  reg [2:0] rec_state;

  // Registers
  reg [MEM_SIZE_W-1:0] rec_buffer_size; // Last buffer size pulled from register
  reg [MEM_ADDR_W-1:0] rec_addr;        // Current offset into record buffer
  reg [MEM_ADDR_W-1:0] rec_size;        // Number of words to transfer next
  reg [MEM_ADDR_W-1:0] rec_size_0;      // Pipeline stage for computation of rec_size

  // Buffer usage registers
  reg [MEM_SIZE_W-1:0] rec_buffer_avail;  // Amount of free buffer space in words
  reg [MEM_SIZE_W-1:0] rec_buffer_used;   // Amount of occupied buffer space in words

  reg [MEM_SIZE_W-1:0] rec_size_aligned;  // Max record size until the next 4k boundary

  // Timer to count how many cycles we've been waiting for new data
  reg [$clog2(DATA_WAIT_TIMEOUT+1)-1:0] rec_wait_timer;
  reg                                   rec_wait_timeout;

  assign reg_rec_fullness = rec_buffer_used * BYTES_PER_WORD;

  always @(posedge clk) begin
    if (rst) begin
      rec_state        <= REC_WAIT_FIFO;
      write_ctrl_valid <= 1'b0;
      rec_wait_timer   <= 0;
      rec_wait_timeout <= 0;
      rec_buffer_avail <= 0;
      rec_buffer_used  <= 0;

      // Don't care:
      rec_addr    <= {MEM_ADDR_W{1'bX}};
      rec_size_0  <= {MEM_ADDR_W{1'bX}};
      rec_size    <= {MEM_ADDR_W{1'bX}};
      write_count <= {MEM_COUNT_W{1'bX}};
      write_addr  <= {MEM_ADDR_W{1'bX}};

    end else begin

      // Default assignments
      rec_restart_clear <= 1'b0;

      // Update wait timer
      if (i_tvalid || !rec_fifo_occupied) begin
        // If a new word is presented to the input FIFO, or the FIFO is empty,
        // then reset the timer.
        rec_wait_timer   <= 0;
        rec_wait_timeout <= 1'b0;
      end else if (rec_fifo_occupied) begin
        // If no new word is written, but there's data in the FIFO, update the
        // timer. Latch timeout condition when we reach our limit.
        rec_wait_timer <= rec_wait_timer + 1;

        if (rec_wait_timer == DATA_WAIT_TIMEOUT) begin
          rec_wait_timeout <= 1'b1;
        end
      end

      // Pre-calculate the aligned size in words
      rec_size_aligned <= AXI_ALIGNMENT - ((rec_addr/BYTES_PER_WORD) & (AXI_ALIGNMENT-1));

      //
      // State logic
      //
      case (rec_state)

        REC_WAIT_FIFO : begin
          // Wait until there's enough data to initiate a transfer from the
          // FIFO to the RAM.

          // Check if a restart was requested on the record interface
          if (rec_restart) begin
            rec_restart_clear <= 1'b1;

            // Latch the new register values. We don't want them to change
            // while we're running.
            rec_buffer_size <= rec_buffer_size_sr / BYTES_PER_WORD;   // Store size in words

            // Reset counters and address any time we update the buffer size or
            // base address.
            rec_buffer_avail <= rec_buffer_size_sr / BYTES_PER_WORD;  // Store size in words
            rec_buffer_used  <= 0;
            rec_addr         <= rec_base_addr_sr;

          // Check if there's room left in the record RAM buffer
          end else if (rec_buffer_used < rec_buffer_size) begin
            // See if we can transfer a full burst
            if (rec_fifo_occupied >= MEM_BURST_LEN && rec_buffer_avail >= MEM_BURST_LEN) begin
              rec_size_0 <= MEM_BURST_LEN;
              rec_state  <= REC_CHECK_ALIGN;

            // Otherwise, if we've been waiting a long time, see if we can
            // transfer less than a burst.
            end else if (rec_fifo_occupied > 0 && rec_wait_timeout) begin
              rec_size_0 <= (rec_fifo_occupied <= rec_buffer_avail) ?
                            rec_fifo_occupied : rec_buffer_avail;
              rec_state  <= REC_CHECK_ALIGN;
            end
          end
        end

        REC_CHECK_ALIGN : begin
          // Check the address alignment, since AXI requires that an access not
          // cross 4k boundaries (boo), and the memory interface doesn't handle
          // this automatically (boo again).
          rec_size <= rec_size_0 > rec_size_aligned ?
                      rec_size_aligned : rec_size_0;

          // Memory interface is ready, so transaction will begin
          rec_state <= REC_MEM_REQ;
        end

        REC_MEM_REQ : begin
          // The write count written to the memory interface should be 1 less
          // than the number of words you want to write (not the number of
          // bytes).
          write_count <= rec_size - 1;

          // Create the physical RAM byte address by combining the address and
          // base address.
          write_addr <= rec_addr;

          // Once the interface is ready, make the memory request
          if (write_ctrl_ready) begin
            // Request the write transaction
            write_ctrl_valid <= 1'b1;
            rec_state        <= REC_WAIT_MEM_START;
          end
        end

        REC_WAIT_MEM_START : begin
          // Wait until memory interface deasserts ready, indicating it has
          // started on the request.
          write_ctrl_valid <= 1'b0;
          if (!write_ctrl_ready) begin
            rec_state <= REC_WAIT_MEM_COMMIT;
          end
        end

        REC_WAIT_MEM_COMMIT : begin
          // Wait for the memory interface to reassert write_ctrl_ready, which
          // signals that the interface has received a response for the whole
          // write transaction and (we assume) it has been committed to RAM.
          // After this, we can update the write address and start the next
          // transaction.
          if (write_ctrl_ready) begin
             rec_addr         <= rec_addr + (rec_size * BYTES_PER_WORD);
             rec_buffer_used  <= rec_buffer_used + rec_size;
             rec_buffer_avail <= rec_buffer_avail - rec_size;
             rec_state        <= REC_WAIT_FIFO;
          end
        end

        default : begin
          rec_state <= REC_WAIT_FIFO;
        end

      endcase
    end
  end

  // Connect output of record FIFO to input of the memory write interface
  assign write_data        = rec_fifo_o_tdata;
  assign write_data_valid  = rec_fifo_o_tvalid;
  assign rec_fifo_o_tready = write_data_ready;


  //---------------------------------------------------------------------------
  // Playback State Machine
  //---------------------------------------------------------------------------

  // FSM States
  localparam PLAY_IDLE            = 0;
  localparam PLAY_WAIT_DATA_READY = 1;
  localparam PLAY_CHECK_ALIGN     = 2;
  localparam PLAY_SIZE_CALC       = 3;
  localparam PLAY_MEM_REQ         = 4;
  localparam PLAY_WAIT_MEM_START  = 5;
  localparam PLAY_WAIT_MEM_COMMIT = 6;
  localparam PLAY_DONE_CHECK      = 7;

  // State Signals
  reg [2:0] play_state;

  // Registers
  reg [MEM_ADDR_W-1:0] play_addr;         // Current byte offset into record buffer
  reg [  MEM_ADDR_W:0] play_addr_0;       // Pipeline stage for computing play_addr.
                                          // One bit larger to detect address wrapping.
  reg [MEM_ADDR_W-1:0] play_addr_1;       // Pipeline stage for computing play_addr
  reg [MEM_SIZE_W-1:0] play_buffer_end;   // Address of location after end of buffer
  reg [MEM_ADDR_W-1:0] max_read_size;     // Maximum size of next transfer, in words
  reg [MEM_ADDR_W-1:0] next_read_size;    // Actual size of next transfer, in words
  reg [MEM_ADDR_W-1:0] play_size_aligned; // Max play size until the next 4K boundary
  //
  reg [NUM_WORDS_W-1:0] play_words_remaining; // Number of words left for playback command
  reg [NUM_WORDS_W-1:0] cmd_num_lines;        // Copy of cmd_num_lines from last command
  reg                   cmd_chain;            // Copy of cmd_chain from last command
  reg                   cmd_reload;           // Copy of cmd_reload from last command
  reg                   cmd_send_imm;         // Copy of cmd_send_imm  from last command
  reg      [TIME_W-1:0] cmd_time;             // Copy of cmd_time_cf from last command
  reg                   last_trans;           // Is this the last read transaction for the command?

  reg play_full_burst_avail;      // True if we there's a full burst to read
  reg play_buffer_avail_nonzero;  // True if play_buffer_avail > 0
  reg cmd_num_lines_cf_nonzero;   // True if cmd_num_lines_cf > 0
  reg next_read_size_ok;          // True if it's OK to read next_read_size

  reg [MEM_ADDR_W-1:0] next_read_size_m1;       // next_read_size - 1
  reg [MEM_ADDR_W-1:0] play_words_remaining_m1; // play_words_remaining - 1

  reg [MEM_SIZE_W-1:0] play_buffer_avail;   // Number of words left to read in record buffer
  reg [MEM_SIZE_W-1:0] play_buffer_avail_0; // Pipeline stage for computing play_buffer_avail

  reg pause_data_transfer;

  always @(posedge clk)
  begin
    if (rst) begin
      play_state     <= PLAY_IDLE;
      cmd_fifo_ready <= 1'b0;

      // Don't care:
      play_full_burst_avail     <= 1'bX;
      play_buffer_avail_nonzero <= 1'bX;
      cmd_num_lines_cf_nonzero  <= 1'bX;
      play_buffer_end           <= {MEM_SIZE_W{1'bX}};
      read_ctrl_valid           <= 1'bX;
      play_halt_clear           <= 1'bX;
      play_addr                 <= {MEM_ADDR_W{1'bX}};
      cmd_num_lines             <= {NUM_WORDS_W{1'bX}};
      cmd_reload                <= 1'bX;
      cmd_chain                 <= 1'bX;
      cmd_send_imm              <= 1'bX;
      cmd_time                  <= {64{1'bX}};
      play_buffer_avail         <= {MEM_SIZE_W{1'bX}};
      play_size_aligned         <= {MEM_SIZE_W{1'bX}};
      play_words_remaining      <= {NUM_WORDS_W{1'bX}};
      max_read_size             <= {MEM_ADDR_W{1'bX}};
      next_read_size            <= {MEM_ADDR_W{1'bX}};
      play_words_remaining_m1   <= {MEM_ADDR_W{1'bX}};
      next_read_size_m1         <= {MEM_ADDR_W{1'bX}};
      next_read_size_ok         <= 1'bX;
      read_count                <= {MEM_COUNT_W{1'bX}};
      read_addr                 <= {MEM_ADDR_W{1'bX}};
      play_addr_0               <= {MEM_ADDR_W+1{1'bX}};
      play_buffer_avail_0       <= {MEM_SIZE_W{1'bX}};
      play_addr_1               <= {MEM_ADDR_W{1'bX}};
      last_trans                <= 1'b0;

    end else begin

      // Calculate how many words are left to read from the record buffer
      play_full_burst_avail     <= (play_buffer_avail >= MEM_BURST_LEN);
      play_buffer_avail_nonzero <= (play_buffer_avail > 0);
      cmd_num_lines_cf_nonzero  <= (cmd_num_lines_cf > 0);
      play_buffer_end           <= play_base_addr_sr + play_buffer_size_sr;

      play_size_aligned <= AXI_ALIGNMENT - ((play_addr/BYTES_PER_WORD) & (AXI_ALIGNMENT-1));

      // Default values
      cmd_fifo_ready    <= 1'b0;
      read_ctrl_valid   <= 1'b0;
      play_halt_clear   <= 1'b0;

      //
      // State logic
      //
      case (play_state)
        PLAY_IDLE : begin
          // Always start reading at the start of the record buffer
          play_addr <= play_base_addr_sr;

          // Save off command info, in case we need to repeat the command
          cmd_num_lines <= cmd_num_lines_cf;
          cmd_reload    <= cmd_reload_cf;
          cmd_chain     <= cmd_chain_cf;
          cmd_send_imm  <= cmd_send_imm_cf;
          cmd_time      <= cmd_time_cf;

          // Save the buffer info so it doesn't update during playback
          play_buffer_avail <= play_buffer_size_sr / BYTES_PER_WORD;

          // Wait until we receive a command and we have enough data recorded
          // to honor it.
          if (cmd_fifo_valid && ~play_halt_clear) begin
            // Load the number of word remaining to complete this command
            play_words_remaining <= cmd_num_lines_cf;

            if (cmd_stop_cf) begin
              // Do nothing, except clear command from the FIFO
              cmd_fifo_ready <= 1'b1;
            end else if (play_buffer_avail_nonzero &&
                         cmd_num_lines_cf_nonzero) begin
              // Dequeue the command from the FIFO
              cmd_fifo_ready <= 1'b1;

              play_state <= PLAY_WAIT_DATA_READY;
            end
          end else if (play_halt) begin
            // In case we get a HALT after a command has finished
            play_halt_clear <= 1'b1;
          end
        end

        PLAY_WAIT_DATA_READY : begin
          // Save the maximum size we can read from RAM
          max_read_size <= play_full_burst_avail ? MEM_BURST_LEN : play_buffer_avail;

          // Check if we got a halt command while waiting
          if (play_halt) begin
            play_halt_clear <= 1'b1;
            play_state      <= PLAY_IDLE;

          // Wait for output FIFO to empty sufficiently so we can read an
          // entire burst at once. This may be more space than needed, but we
          // won't know the exact size until the next state.
          end else if (play_fifo_space >= MEM_BURST_LEN) begin
            play_state <= PLAY_CHECK_ALIGN;
          end
        end

        PLAY_CHECK_ALIGN : begin
          // Check the address alignment, since AXI requires that an access not
          // cross 4k boundaries (boo), and the memory interface doesn't handle
          // this automatically (boo again).
          next_read_size <= max_read_size > play_size_aligned ?
                            play_size_aligned : max_read_size;
          play_state <= PLAY_SIZE_CALC;
        end

        PLAY_SIZE_CALC : begin
          // Do some intermediate calculations to determine what the read_count
          // should be.
          play_words_remaining_m1 <= play_words_remaining-1;
          next_read_size_m1       <= next_read_size-1;
          next_read_size_ok       <= play_words_remaining >= next_read_size;
          play_state              <= PLAY_MEM_REQ;

          // Check if this is the last memory transaction
          if (cmd_fifo_valid && cmd_stop_cf) begin
            // Received a stop command
            last_trans <= 1'b1;
          end else if (cmd_chain) begin
            // There's another command after this one
            last_trans <= 1'b0;
          end else begin
            // If not stopping, see if this is the last transaction for a
            // finite playback command.
            last_trans <= (play_words_remaining <= next_read_size);
          end
        end

        PLAY_MEM_REQ : begin
          // Load the size of the next read into a register. We try to read the
          // max amount available (up to the burst size) or however many words
          // are needed to reach the end of the RAM buffer.
          //
          // The read count written to the memory interface should be 1 less
          // than the number of words you want to read (not the number of
          // bytes).
          read_count <= next_read_size_ok ? next_read_size_m1 : play_words_remaining_m1;

          // Load the address to read
          read_addr <= play_addr;

          // Request the read transaction as soon as memory interface is ready
          if (read_ctrl_ready) begin
            read_ctrl_valid <= 1'b1;
            play_state      <= PLAY_WAIT_MEM_START;
          end
        end

        PLAY_WAIT_MEM_START : begin
          // Wait until memory interface deasserts ready, indicating it has
          // started on the request.
          read_ctrl_valid <= 1'b0;
          if (!read_ctrl_ready) begin
            // Update values for next transaction
            play_addr_0 <= play_addr +
              ({{(MEM_ADDR_W-MEM_COUNT_W){1'b0}}, read_count} + 1) * BYTES_PER_WORD;
            play_words_remaining <= play_words_remaining - ({1'b0, read_count} + 1);
            play_buffer_avail_0  <= play_buffer_avail - ({1'b0, read_count} + 1);

            play_state <= PLAY_WAIT_MEM_COMMIT;
          end
        end

        PLAY_WAIT_MEM_COMMIT : begin
          // Wait for the memory interface to reassert read_ctrl_ready, which
          // signals that the interface has received a response for the whole
          // read transaction.
          if (read_ctrl_ready) begin
            // Check if we need to wrap the address for the next transaction.
            if (play_addr_0 >= play_buffer_end) begin
              play_addr_1       <= play_base_addr_sr;
              play_buffer_avail <= play_buffer_size_sr / BYTES_PER_WORD;
            end else begin
              play_addr_1       <= play_addr_0[MEM_ADDR_W-1:0];
              play_buffer_avail <= play_buffer_avail_0;
            end

            // Update the time for the first word of the next transaction
            cmd_time <= cmd_time + (read_count + 1) * (MEM_DATA_W/32);

            play_state <= PLAY_DONE_CHECK;
          end
        end

        PLAY_DONE_CHECK : begin
          play_addr <= play_addr_1;


          // Check if we have more data to transfer for this command
          if (last_trans) begin
            play_state <= PLAY_IDLE;
          end else begin
            if (play_words_remaining) begin
              // We still have words left for the current command
              play_state <= PLAY_WAIT_DATA_READY;
            end else if (cmd_chain) begin
              // Check if there's a new command waiting
              if (cmd_fifo_valid) begin
                // Load the next command. Note that we don't reset the playback
                // address when commands are chained together.
                play_words_remaining <= cmd_num_lines_cf;
                cmd_num_lines        <= cmd_num_lines_cf;
                cmd_reload           <= cmd_reload_cf;
                cmd_chain            <= cmd_chain_cf;

                // Dequeue the command from the FIFO
                cmd_fifo_ready <= 1'b1;

                // Stop if it's a stop command, otherwise restart
                if (cmd_stop_cf) begin
                  play_state <= PLAY_IDLE;
                end else begin
                  play_state <= PLAY_WAIT_DATA_READY;
                end

              // Check if we need to restart the previous command
              end else if (cmd_reload) begin
                play_words_remaining <= cmd_num_lines;
                play_state           <= PLAY_WAIT_DATA_READY;
              end
            end
          end
        end
      endcase

    end
  end


  //---------------------------------------------------------------------------
  // TLAST and TUSER Generation
  //---------------------------------------------------------------------------
  //
  // This section monitors the signals to/from the memory interface and
  // generates the TLAST and TUSER signals. We assert TLAST at the end of 
  // every read transaction and after every play_max_len_sr words, so 
  // that no packets are longer than the length indicated by the max_len
  // register.
  //
  // TUSER consists of the timestamp, has_time flag, and eob
  // flag. These are generated by the playback logic for each memory
  // transaction.
  //
  // The timing of this block relies on the fact that read_ctrl_ready is not
  // reasserted by the memory interface until after TLAST gets asserted.
  //
  //---------------------------------------------------------------------------

  reg [MEM_COUNT_W-1:0] read_counter;
  reg [      WPP_W-1:0] length_counter;
  reg [     TIME_W-1:0] time_counter;
  reg                   play_fifo_i_tlast;
  reg                   has_time;
  reg                   eob;

  always @(posedge clk)
  begin
    if (rst) begin
      play_fifo_i_tlast <= 1'b0;
      // Don't care:
      read_counter      <= {MEM_COUNT_W{1'bX}};
      length_counter    <= {MEM_COUNT_W+1{1'bX}};
      time_counter      <= {TIME_W{1'bX}};
      has_time          <= 1'bX;
      eob               <= 1'bX;
    end else begin
      // Check if we're requesting a read transaction
      if (read_ctrl_valid && read_ctrl_ready) begin
        // Initialize read_counter for new transaction
        read_counter   <= read_count;
        length_counter <= play_max_len_sr;
        time_counter   <= cmd_time;
        has_time       <= ~cmd_send_imm;
        eob            <= last_trans && (read_count < play_max_len_sr);

        // If read_count is 0, then the first word is also the last word
        if (read_count == 0) begin
          play_fifo_i_tlast <= 1'b1;
        end

      // Track the number of words read out by memory interface
      end else if (read_data_valid && read_data_ready) begin
        read_counter   <= read_counter - 1;
        length_counter <= length_counter - 1;
        time_counter   <= time_counter + (MEM_DATA_W/32);  // Add number of samples per word

        // Check if the word currently being output is the last word of a
        // packet, which means we need to clear tlast.
        if (play_fifo_i_tlast) begin
          // But make sure that the next word isn't also the last of a memory
          // burst, for which we will need to keep tlast asserted.
          if (read_counter != 1) begin
            play_fifo_i_tlast <= 1'b0;
          end

          // Restart length counter
          length_counter <= play_max_len_sr;

          // Check if next packet is the end of the burst (EOB)
          eob <= last_trans && (read_counter <= play_max_len_sr);

        // Check if the next word to be output should be the last of a packet.
        end else if (read_counter == 1 || length_counter == 2) begin
          play_fifo_i_tlast <= 1'b1;
        end
      end

    end
  end


  //---------------------------------------------------------------------------
  // Playback Output Data FIFO
  //---------------------------------------------------------------------------
  //
  // The play_axi_fifo buffers data that has been read out of RAM as part of a
  // playback operation.
  //
  //---------------------------------------------------------------------------

  // Connect output of memory read interface to play_axi_fifo
  assign play_fifo_i_tdata  = read_data;
  assign play_fifo_i_tvalid = read_data_valid    & ~pause_data_transfer;
  assign read_data_ready    = play_fifo_i_tready & ~pause_data_transfer;

  axi_fifo #(
    .WIDTH (MEM_DATA_W+1),
    .SIZE  (PLAY_FIFO_ADDR_WIDTH)
  ) play_axi_fifo (
    .clk      (clk),
    .reset    (rst),
    .clear    (1'b0),
    //
    .i_tdata  ({play_fifo_i_tlast, play_fifo_i_tdata}),
    .i_tvalid (play_fifo_i_tvalid),
    .i_tready (play_fifo_i_tready),
    //
    .o_tdata  ({o_tlast, o_tdata}),
    .o_tvalid (o_tvalid),
    .o_tready (o_tready),
    //
    .space    (play_fifo_space),
    .occupied ()
  );

  reg play_fifo_i_sop = 1'b1;

  // Make play_fifo_i_sop true whenever the next play_fifo_i word is the start
  // of a packet.
  always @(posedge clk) begin
    if (rst) begin
      play_fifo_i_sop <= 1'b1;
    end else begin
      if (play_fifo_i_tvalid & play_fifo_i_tready) begin
        play_fifo_i_sop <= play_fifo_i_tlast;
      end
    end
  end


  //---------------------------------------------------------------------------
  // Header Info FIFO
  //---------------------------------------------------------------------------
  //
  // The hdr_axi_fifo contains the header information for the next packet, with
  // one word per packet.
  //
  //---------------------------------------------------------------------------

  wire [(TIME_W+2)-1:0] hdr_fifo_i_tdata;
  wire                  hdr_fifo_i_tvalid;
  wire [(TIME_W+2)-1:0] hdr_fifo_o_tdata;
  wire                  hdr_fifo_o_tready;

  wire [15:0] hdr_fifo_space;

  axi_fifo #(
    .WIDTH (TIME_W+2),
    .SIZE  (HDR_FIFO_ADDR_WIDTH)
  ) hdr_axi_fifo (
    .clk      (clk),
    .reset    (rst),
    .clear    (1'b0),
    //
    .i_tdata  (hdr_fifo_i_tdata),
    .i_tvalid (hdr_fifo_i_tvalid),
    .i_tready (),
    //
    .o_tdata  (hdr_fifo_o_tdata),
    .o_tvalid (),
    .o_tready (hdr_fifo_o_tready),
    //
    .space    (hdr_fifo_space),
    .occupied ()
  );

  assign hdr_fifo_i_tdata = {has_time, eob, time_counter};

  // Pop the timestamp whenever we finish reading out a data packet
  assign hdr_fifo_o_tready = o_tvalid & o_tready & o_tlast;

  // Write the timestamp at the start of each packet
  assign hdr_fifo_i_tvalid = play_fifo_i_tvalid & play_fifo_i_tready & play_fifo_i_sop;

  // Build the packet header (TUSER)
  cvita_hdr_encoder cvita_hdr_encoder_i (
    .pkt_type       (2'b00),                   // Packet Type = 0 (Data)
    .has_time       (hdr_fifo_o_tdata[TIME_W+1]),
    .eob            (hdr_fifo_o_tdata[TIME_W+0]),
    .seqnum         (12'h000),                 // To be filled in later
    .payload_length (16'h0000),                // To be filled in later
    .src_sid        (16'h0000),                // To be filled in later
    .dst_sid        (16'h0000),                // To be filled in later
    .vita_time      (hdr_fifo_o_tdata[0+:TIME_W]), // Timestamp
    .header         (o_tuser)
  );

  // The following state machine prevents overflow of the hdr_axi_fifo by
  // stopping data transfer if it is almost full. It monitors the state of the
  // current transfer so as to not violate the AXI-Stream protocol.
  reg hdr_fifo_almost_full;

  always @(posedge clk) begin
    if (rst) begin
      hdr_fifo_almost_full <= 0;
      pause_data_transfer  <= 0;
    end else begin
      hdr_fifo_almost_full <= (hdr_fifo_space < 4);

      if (pause_data_transfer) begin
        if (!hdr_fifo_almost_full) pause_data_transfer <= 0;
      end else begin
        // If we're not asserting tvalid, or we're completing a transfer this
        // cycle, then it is safe to gate tvalid on the next cycle.
        if (hdr_fifo_almost_full &&
           (!play_fifo_i_tvalid || (play_fifo_i_tvalid && play_fifo_i_tready))) begin
          pause_data_transfer <= 1;
        end
      end
    end
  end

endmodule


`default_nettype wire
