//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: axi_replay.v
// Description:
//
// This block implements the state machine and control logic for recording and 
// playback of AXI-Stream data, using a DMA-accessible memory as a buffer.

`default_nettype none


module axi_replay #(
  parameter DATA_WIDTH  = 64,
  parameter ADDR_WIDTH  = 32, // Byte address width used by DMA master
  parameter COUNT_WIDTH = 8   // Length of counters used to connect to the DMA 
                              // master's read and write interfaces.
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
  input  wire [DATA_WIDTH-1:0] i_tdata,
  input  wire                  i_tvalid,
  input  wire                  i_tlast,
  output wire                  i_tready,

  // Output
  output wire [DATA_WIDTH-1:0] o_tdata,
  output wire [         127:0] o_tuser,
  output wire                  o_tvalid,
  output wire                  o_tlast,
  input  wire                  o_tready,

  //---------------------------------------------------------------------------
  // DMA Interface
  //---------------------------------------------------------------------------

  // Write interface
  output reg  [ ADDR_WIDTH-1:0] write_addr,       // Byte address for start of write
                                                  // transaction (64-bit aligned).
  output reg  [COUNT_WIDTH-1:0] write_count,      // Count of 64-bit words to write, minus 1.
  output reg                    write_ctrl_valid,
  input  wire                   write_ctrl_ready,
  output wire [ DATA_WIDTH-1:0] write_data,
  output wire                   write_data_valid,
  input  wire                   write_data_ready,

  // Read interface
  output reg  [ ADDR_WIDTH-1:0] read_addr,       // Byte address for start of read
                                                 // transaction (64-bit aligned).
  output reg  [COUNT_WIDTH-1:0] read_count,      // Count of 64-bit words to read, minus 1.
  output reg                    read_ctrl_valid,
  input  wire                   read_ctrl_ready,
  input  wire [ DATA_WIDTH-1:0] read_data,
  input  wire                   read_data_valid,
  output wire                   read_data_ready
);

  //---------------------------------------------------------------------------
  // Constants
  //---------------------------------------------------------------------------

  // Size constants
  localparam CMD_WIDTH   = 32;           // Command width
  localparam LINES_WIDTH = 28;           // Width of cmd_num_lines
  localparam WORD_SIZE   = DATA_WIDTH/8; // Size of DATA_WIDTH in bytes

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


  // Memory buffering parameters:
  //
  // Log base 2 of the depth of the input and output FIFOs to use. The FIFOs 
  // should be large enough to store more than a complete burst 
  // (MEM_BURST_SIZE). A size of 9 (512 64-bit words) is one 36-kbit BRAM.
  localparam REC_FIFO_ADDR_WIDTH  = 9;  // Log2 of input/record FIFO size
  localparam PLAY_FIFO_ADDR_WIDTH = 9;  // Log2 of output/playback FIFO size
  localparam HDR_FIFO_ADDR_WIDTH  = 5;  // Log2 of output/time FIFO size
  //
  // Amount of data to buffer before writing to RAM. This should be a power of 
  // two so that it evenly divides the AXI_ALIGNMENT requirement. It also must 
  // not exceed 2**COUNT_WIDTH (the maximum count allowed by DMA master).
  localparam MEM_BURST_SIZE = 2**COUNT_WIDTH;  // Size in DATA_WIDTH-sized words
  //
  // AXI alignment requirement (4096 bytes) in DATA_WIDTH-bit words
  localparam AXI_ALIGNMENT = 4096 / WORD_SIZE;
  //
  // Clock cycles to wait before writing something less than MEM_BURST_SIZE 
  // to memory.
  localparam DATA_WAIT_TIMEOUT = 31;  


  //---------------------------------------------------------------------------
  // Signals
  //---------------------------------------------------------------------------

  // Command wires
  wire                   cmd_send_imm_cf, cmd_chain_cf, cmd_reload_cf, cmd_stop_cf;
  wire [LINES_WIDTH-1:0] cmd_num_lines_cf;
  wire [           63:0] cmd_time_cf;

  // Settings registers signals
  wire [ ADDR_WIDTH-1:0] rec_base_addr_tmp,    rec_base_addr_sr;    // Byte address
  wire [ ADDR_WIDTH-1:0] rec_buffer_size_tmp,  rec_buffer_size_sr;  // Size in bytes
  wire [ ADDR_WIDTH-1:0] play_base_addr_tmp,   play_base_addr_sr;   // Byte address
  wire [ ADDR_WIDTH-1:0] play_buffer_size_tmp, play_buffer_size_sr; // Size in bytes
  reg                    rec_restart;
  reg                    rec_restart_clear;
  wire [  CMD_WIDTH-1:0] command;
  wire                   command_valid;
  wire            [63:0] command_time;
  reg                    play_halt;
  reg                    play_halt_clear;
  wire [  COUNT_WIDTH:0] play_max_len_sr;  // Width is COUNT_WIDTH+1 to support 2**COUNT_WIDTH

  // Command FIFO
  wire cmd_fifo_valid;
  reg  cmd_fifo_ready;

  // Record Data FIFO (Input)
  wire [DATA_WIDTH-1:0] rec_fifo_o_tdata;
  wire                  rec_fifo_o_tvalid;
  wire                  rec_fifo_o_tready;
  wire [          15:0] rec_fifo_occupied;

  // Playback Data FIFO (Output)
  wire [DATA_WIDTH-1:0] play_fifo_i_tdata; 
  wire                  play_fifo_i_tvalid;
  wire                  play_fifo_i_tready;
  wire [          15:0] play_fifo_space;    // Free space in play_axi_fifo

  // Buffer usage registers
  reg [ADDR_WIDTH-1:0] rec_buffer_avail;  // Amount of free buffer space in words
  reg [ADDR_WIDTH-1:0] rec_buffer_used;   // Amount of occupied buffer space in words


  //---------------------------------------------------------------------------
  // Registers
  //---------------------------------------------------------------------------

  // Record Base Address Register. Address is a byte address. This must be a 
  // multiple of 8 bytes.
  setting_reg #(
    .my_addr (SR_REC_BASE_ADDR),
    .width   (ADDR_WIDTH)
  ) sr_rec_base_addr (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (rec_base_addr_tmp),
    .changed ()
  );
  assign rec_base_addr_sr = { rec_base_addr_tmp[ADDR_WIDTH-1:3], 3'b0 };


  // Record Buffer Size Register. This indicates the portion of the RAM 
  // allocated to the record buffer, in bytes. This should be a multiple of 8 
  // bytes.
  setting_reg #(
    .my_addr (SR_REC_BUFFER_SIZE),
    .width   (ADDR_WIDTH)
  ) sr_rec_buffer_size (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (rec_buffer_size_tmp),
    .changed ()
  );
  assign rec_buffer_size_sr = { rec_buffer_size_tmp[ADDR_WIDTH-1:3], 3'b0 };


  // Playback Base Address Register. Address is a byte address. This must be a 
  // multiple of the 8 bytes.   
  setting_reg #(
    .my_addr (SR_PLAY_BASE_ADDR),
    .width   (ADDR_WIDTH)
  ) sr_play_base_addr (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (play_base_addr_tmp),
    .changed ()
  );
  assign play_base_addr_sr = { play_base_addr_tmp[ADDR_WIDTH-1:3], 3'b0 };


  // Playback Buffer Size Register. This indicates the portion of the RAM 
  // allocated to the record buffer, in bytes. This should be a multiple of 8 
  // bytes.
  setting_reg #(
    .my_addr (SR_PLAY_BUFFER_SIZE),
    .width   (ADDR_WIDTH)
  ) sr_play_buffer_size (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (play_buffer_size_tmp),
    .changed ()
  );
  assign play_buffer_size_sr = { play_buffer_size_tmp[ADDR_WIDTH-1:3], 3'b0 };


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
  //   num_lines [27:0]  Number of 64-bit words to transfer to/from block.
  //
  setting_reg #(
    .my_addr (SR_RX_CTRL_COMMAND),
    .width   (CMD_WIDTH)
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
    .width   (32)
  ) sr_time_hi (
    .clk     (clk),
    .rst     (rst),
    .strobe  (set_stb),
    .addr    (set_addr),
    .in      (set_data),
    .out     (command_time[63:32]),
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
    .width   (COUNT_WIDTH+1),
    .at_reset({1'b1, {COUNT_WIDTH{1'b0}}})
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
      SR_REC_FULLNESS     : rb_data = rec_buffer_used * WORD_SIZE;
      SR_PLAY_BASE_ADDR   : rb_data = play_base_addr_sr;
      SR_PLAY_BUFFER_SIZE : rb_data = play_buffer_size_sr;
      SR_RX_CTRL_MAXLEN   : rb_data = {{(64-(COUNT_WIDTH+1)){1'b0}}, play_max_len_sr};
      default             : rb_data = 32'h0;
    endcase
  end


  //---------------------------------------------------------------------------
  // Playback Command FIFO
  //---------------------------------------------------------------------------
  //
  // This block queues up commands for playback control.
  //
  //---------------------------------------------------------------------------

  axi_fifo_short #(
    .WIDTH (CMD_WIDTH + 64)
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
  // This FIFO stores data to be recording into the RAM buffer.
  //
  //---------------------------------------------------------------------------

  axi_fifo #(
    .WIDTH (DATA_WIDTH),
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
  localparam REC_DMA_REQ         = 2;
  localparam REC_WAIT_DMA_START  = 3;
  localparam REC_WAIT_DMA_COMMIT = 4;

  // State Signals
  reg [2:0] rec_state;

  // Registers
  reg [ADDR_WIDTH-1:0] rec_buffer_size; // Last buffer size pulled from settings register
  reg [ADDR_WIDTH-1:0] rec_addr;        // Current offset into record buffer
  reg [ADDR_WIDTH-1:0] rec_size;        // Number of words to transfer next
  reg [ADDR_WIDTH-1:0] rec_size_0;      // Pipeline stage for computation of rec_size

  reg signed [ADDR_WIDTH:0] rec_size_aligned; // rec_size reduced to not cross 4k boundary

  // Timer to count how many cycles we've been waiting for new data
  reg [$clog2(DATA_WAIT_TIMEOUT+1)-1:0] rec_wait_timer;
  reg                                   rec_wait_timeout;

  always @(posedge clk) begin
    if (rst) begin
      rec_state        <= REC_WAIT_FIFO;
      write_ctrl_valid <= 1'b0;
      rec_wait_timer   <= 0;
      rec_wait_timeout <= 0;
      rec_buffer_avail <= 0;
      rec_buffer_used  <= 0;

      // Don't care:
      rec_addr    <= 0;
      rec_size_0  <= {ADDR_WIDTH{1'bX}};
      rec_size    <= {ADDR_WIDTH{1'bX}};
      write_count <= {COUNT_WIDTH{1'bX}};
      write_addr  <= {ADDR_WIDTH{1'bX}};

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
        // timer. Latch timeout condition when we reach out limit.
        rec_wait_timer <= rec_wait_timer + 1;

        if (rec_wait_timer == DATA_WAIT_TIMEOUT) begin
          rec_wait_timeout <= 1'b1;
        end
      end

      // Pre-calculate the aligned size
      rec_size_aligned <= $signed(AXI_ALIGNMENT) - $signed(rec_addr & (AXI_ALIGNMENT-1));

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
            rec_buffer_size <= rec_buffer_size_sr / WORD_SIZE;   // Store size in words

            // Reset counters and address any time we update the buffer size or 
            // base address.
            rec_buffer_avail <= rec_buffer_size_sr / WORD_SIZE;  // Store size in words
            rec_buffer_used  <= 0;
            rec_addr         <= rec_base_addr_sr;

          // Check if there's room left in the record RAM buffer
          end else if (rec_buffer_used < rec_buffer_size) begin
            // See if we can transfer a full burst
            if (rec_fifo_occupied >= MEM_BURST_SIZE && rec_buffer_avail >= MEM_BURST_SIZE) begin
              rec_size_0 <= MEM_BURST_SIZE;
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
          // cross 4k boundaries (boo), and the axi_dma_master doesn't handle 
          // this automatically (boo again). 
          rec_size <= ($signed({1'b0,rec_size_0}) > rec_size_aligned) ? 
                      rec_size_aligned : rec_size_0;

          // DMA interface is ready, so transaction will begin
          rec_state <= REC_DMA_REQ;
        end

        REC_DMA_REQ : begin
          // The write count written to the DMA engine should be 1 less than 
          // the number of words you want to write (not the number of bytes).
          write_count <= rec_size - 1;

          // Create the physical RAM byte address by combining the address and 
          // base address.
          write_addr <= rec_addr;

          // Once the interface is ready, make the DMA request
          if (write_ctrl_ready) begin
            // Request the write transaction
            write_ctrl_valid <= 1'b1;
            rec_state        <= REC_WAIT_DMA_START;
          end
        end

        REC_WAIT_DMA_START : begin
          // Wait until DMA interface deasserts ready, indicating it has 
          // started on the request.
          write_ctrl_valid <= 1'b0;
          if (!write_ctrl_ready) begin
            rec_state <= REC_WAIT_DMA_COMMIT;
          end
        end

        REC_WAIT_DMA_COMMIT : begin
          // Wait for the DMA interface to reassert write_ctrl_ready, which 
          // signals that the DMA engine has received a response for the whole 
          // write transaction and (we assume) it has been committed to RAM. 
          // After this, we can update the write address and start the next 
          // transaction.
          if (write_ctrl_ready) begin
             rec_addr         <= rec_addr + (rec_size * WORD_SIZE);
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

  // Connect output of record FIFO to input of DMA write interface
  assign write_data        = rec_fifo_o_tdata;
  assign write_data_valid  = rec_fifo_o_tvalid;
  assign rec_fifo_o_tready = write_data_ready;


  //---------------------------------------------------------------------------
  // Playback State Machine
  //---------------------------------------------------------------------------

  // FSM States
  localparam PLAY_IDLE            = 0;
  localparam PLAY_WAIT_DATA_READY = 1;
  localparam PLAY_SIZE_CALC       = 2;
  localparam PLAY_DMA_REQ         = 3;
  localparam PLAY_WAIT_DMA_START  = 4;
  localparam PLAY_WAIT_DMA_COMMIT = 5;
  localparam PLAY_DONE_CHECK      = 6;

  // State Signals
  reg [2:0] play_state;

  // Registers
  reg [ADDR_WIDTH-1:0] play_addr;         // Current byte offset into record buffer
  reg [ADDR_WIDTH-1:0] play_addr_0;       // Pipeline stage for computing play_addr
  reg [ADDR_WIDTH-1:0] play_addr_1;       // Pipeline stage for computing play_addr
  reg [ADDR_WIDTH-1:0] play_buffer_end;   // Address of location after end of buffer
  reg [ADDR_WIDTH-1:0] max_dma_size;      // Maximum size of next transfer, in words
  //
  reg [LINES_WIDTH-1:0] cmd_num_lines;        // Copy of cmd_num_lines from last command
  reg [LINES_WIDTH-1:0] play_words_remaining; // Number of lines left to read for command
  reg                   cmd_chain;            // Copy of cmd_chain from last command
  reg                   cmd_reload;           // Copy of cmd_reload from last command
  reg                   cmd_send_imm;         // Copy of cmd_send_imm  from last command
  reg            [63:0] cmd_time;             // COpy of cmd_time from last command
  reg                   last_trans;           // Is this the last read transaction for the command?

  reg play_full_burst_avail;     // True if we there's a full burst to read
  reg play_buffer_avail_nonzero; // True if > 0
  reg cmd_num_lines_cf_nonzero;  // True if > 0
  reg max_dma_size_ok;           // True if it's OK to read max_dma_size

  reg [ADDR_WIDTH-1:0] max_dma_size_m1;         // max_dma_size - 1
  reg [ADDR_WIDTH-1:0] play_words_remaining_m1; // play_words_remaining - 1

  reg [ADDR_WIDTH-1:0] play_buffer_avail;   // Number of words left to read in record buffer
  reg [ADDR_WIDTH-1:0] play_buffer_avail_0; // Pipeline stage for computing play_buffer_avail

  always @(posedge clk)
  begin
    if (rst) begin
      play_state     <= PLAY_IDLE;
      cmd_fifo_ready <= 1'b0;

      // Don't care:
      play_full_burst_avail     <= 1'bX;
      play_buffer_avail_nonzero <= 1'bX;
      cmd_num_lines_cf_nonzero  <= 1'bX;
      play_buffer_end           <= {ADDR_WIDTH{1'bX}};
      read_ctrl_valid           <= 1'bX;
      play_halt_clear           <= 1'bX;
      play_addr                 <= {ADDR_WIDTH{1'bX}};
      cmd_num_lines             <= {LINES_WIDTH{1'bX}};
      cmd_reload                <= 1'bX;
      cmd_chain                 <= 1'bX;
      cmd_send_imm              <= 1'bX;
      cmd_time                  <= {64{1'bX}};
      play_buffer_avail         <= {ADDR_WIDTH{1'bX}};
      play_words_remaining      <= {LINES_WIDTH{1'bX}};
      max_dma_size              <= {ADDR_WIDTH{1'bX}};
      play_words_remaining_m1   <= {ADDR_WIDTH{1'bX}};
      max_dma_size_m1           <= {ADDR_WIDTH{1'bX}};
      max_dma_size_ok           <= 1'bX;
      read_count                <= {COUNT_WIDTH{1'bX}};
      read_addr                 <= {ADDR_WIDTH{1'bX}};
      play_addr_0               <= {ADDR_WIDTH{1'bX}};
      play_buffer_avail_0       <= {ADDR_WIDTH{1'bX}};
      play_addr_1               <= {ADDR_WIDTH{1'bX}};
      last_trans                <= 1'bX;

    end else begin
      
      // Calculate how many words are left to read from the record buffer
      play_full_burst_avail     <= (play_buffer_avail >= MEM_BURST_SIZE);
      play_buffer_avail_nonzero <= (play_buffer_avail > 0);
      cmd_num_lines_cf_nonzero  <= (cmd_num_lines_cf > 0);
      play_buffer_end           <= play_base_addr_sr + play_buffer_size_sr;

      // Default values
      cmd_fifo_ready  <= 1'b0;
      read_ctrl_valid <= 1'b0;
      play_halt_clear <= 1'b0;

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
          play_buffer_avail <= play_buffer_size_sr / WORD_SIZE;

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
          max_dma_size  <= play_full_burst_avail ? MEM_BURST_SIZE : play_buffer_avail;

          // Check if we got a halt command while waiting
          if (play_halt) begin
            play_halt_clear <= 1'b1;
            play_state      <= PLAY_IDLE;

          // Wait for output FIFO to empty sufficiently so we can read an 
          // entire burst at once. This may be more space than needed, but we 
          // won't know the exact size until the next state.
          end else if (play_fifo_space >= MEM_BURST_SIZE) begin
            play_state <= PLAY_SIZE_CALC;
          end
        end

        PLAY_SIZE_CALC : begin
          // Do some intermediate calculations to determine what the read_count 
          // should be.
          play_words_remaining_m1 <= play_words_remaining-1;
          max_dma_size_m1         <= max_dma_size-1;
          max_dma_size_ok         <= play_words_remaining >= max_dma_size;
          last_trans              <= (play_words_remaining <= max_dma_size) && 
                                     !cmd_chain && !cmd_reload;
          play_state              <= PLAY_DMA_REQ;
        end

        PLAY_DMA_REQ : begin
          // Load the size of the next read into a register. We try to read the 
          // max amount available (up to the burst size) or however many words 
          // are needed to reach the end of the RAM buffer.
          //
          // The read count written to the DMA engine should be 1 less than the 
          // number of words you want to read (not the number of bytes).
          read_count <= max_dma_size_ok ? max_dma_size_m1 : play_words_remaining_m1;

          // Load the address to read. Note that we don't do an alignment check 
          // since we assume that multiples of MEM_BURST_SIZE meet the 
          // AXI_ALIGNMENT requirement.
          read_addr <= play_addr;

          // Request the read transaction as soon as DMA interface is ready
          if (read_ctrl_ready) begin
            read_ctrl_valid <= 1'b1;
            play_state      <= PLAY_WAIT_DMA_START;
          end
        end

        PLAY_WAIT_DMA_START : begin
          // Wait until DMA interface deasserts ready, indicating it has 
          // started on the request.
          read_ctrl_valid <= 1'b0;
          if (!read_ctrl_ready) begin
            // Update values for next transaction
            play_addr_0          <= play_addr + ({{(ADDR_WIDTH-COUNT_WIDTH){1'b0}}, read_count} + 1) * WORD_SIZE;
            play_words_remaining <= play_words_remaining - ({1'b0, read_count} + 1);
            play_buffer_avail_0  <= play_buffer_avail - ({1'b0, read_count} + 1);

            play_state <= PLAY_WAIT_DMA_COMMIT;
          end
        end

        PLAY_WAIT_DMA_COMMIT : begin
          // Wait for the DMA interface to reassert read_ctrl_ready, which 
          // signals that the DMA engine has received a response for the whole 
          // read transaction.
          if (read_ctrl_ready) begin
            // Check if we need to wrap the address for the next transaction
            if (play_addr_0 >= play_buffer_end) begin
              play_addr_1       <= play_base_addr_sr;
              play_buffer_avail <= play_buffer_size_sr / WORD_SIZE;
            end else begin
              play_addr_1       <= play_addr_0;
              play_buffer_avail <= play_buffer_avail_0;
            end

            // Update the time for the first word of the next transaction
            cmd_time <= cmd_time + (read_count + 1) * (DATA_WIDTH/32);

            play_state <= PLAY_DONE_CHECK;
          end
        end

        PLAY_DONE_CHECK : begin
          play_addr <= play_addr_1;

          // Check if we have more data to transfer for this command
          if (play_words_remaining) begin
            play_state <= PLAY_WAIT_DATA_READY;

          // Check if we're chaining
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
          // Nothing left to do
          end else begin
            play_state <= PLAY_IDLE;
          end
        end
      endcase

    end
  end

  // Connect output of DMA master to playback data FIFO
  assign play_fifo_i_tdata  = read_data;
  assign play_fifo_i_tvalid = read_data_valid;
  assign read_data_ready    = play_fifo_i_tready;


  //---------------------------------------------------------------------------
  // TLAST and TUSER Generation
  //---------------------------------------------------------------------------
  //
  // This block monitors the signals to/from the DMA master and generates the
  // TLAST and TUSER signals. We assert TLAST at the end of every read
  // transaction and after every play_max_len_sr words, so that no packets are
  // longer than the length indicated by the max_len register.
  //
  // TUSER consists of the timestamp, has_time flag, and eob flag. These are
  // generated by the playback logic for each DMA transaction.
  //
  // The timing of this block relies on the fact that read_ctrl_ready is not 
  // reasserted by the DMA master until after TLAST gets asserted.
  //
  //---------------------------------------------------------------------------

  reg [COUNT_WIDTH-1:0] read_counter;
  reg [  COUNT_WIDTH:0] length_counter;
  reg [           63:0] time_counter;
  reg                   play_fifo_i_tlast;
  reg                   has_time;
  reg                   eob;

  always @(posedge clk)
  begin
    if (rst) begin
      play_fifo_i_tlast <= 1'b0;
      // Don't care:
      read_counter      <= {COUNT_WIDTH{1'bX}};
      length_counter    <= {COUNT_WIDTH+1{1'bX}};
      time_counter      <= 64'bX;
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

      // Track the number of words read out by DMA master
      end else if (read_data_valid && read_data_ready) begin
        read_counter   <= read_counter - 1;
        length_counter <= length_counter - 1;
        time_counter   <= time_counter + (DATA_WIDTH/32);  // Add number of samples per word

        // Check if the word currently being output is the last word of a 
        // packet, which means we need to clear tlast. 
        if (play_fifo_i_tlast) begin
          // But make sure that the next word isn't also the last of a DMA 
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

  axi_fifo #(
    .WIDTH (DATA_WIDTH+1),
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
  // one word per packet. This will be used to drive TUSER.
  //
  //---------------------------------------------------------------------------

  wire [65:0] hdr_fifo_i_tdata;
  wire        hdr_fifo_i_tvalid;
  wire        hdr_fifo_i_tready;
  wire [65:0] hdr_fifo_o_tdata;
  wire        hdr_fifo_o_tready;

  axi_fifo #(
    .WIDTH (66),
    .SIZE  (HDR_FIFO_ADDR_WIDTH)
  ) hdr_axi_fifo (
    .clk      (clk),
    .reset    (rst),
    .clear    (1'b0),
    //
    .i_tdata  (hdr_fifo_i_tdata),
    .i_tvalid (hdr_fifo_i_tvalid),
    .i_tready (hdr_fifo_i_tready),
    //
    .o_tdata  (hdr_fifo_o_tdata),
    .o_tvalid (),
    .o_tready (hdr_fifo_o_tready),
    //
    .space    (),
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
    .has_time       (hdr_fifo_o_tdata[65]),
    .eob            (hdr_fifo_o_tdata[64]),
    .seqnum         (12'h000),                 // To be filled in later
    .payload_length (16'h0000),                // To be filled in later
    .src_sid        (16'h0000),                // To be filled in later
    .dst_sid        (16'h0000),                // To be filled in later
    .vita_time      (hdr_fifo_o_tdata[63:0]), // Timestamp
    .header         (o_tuser)
  );

  // FIXME: There's nothing to prevent overflow on hdr_axi_fifo. Right now we
  // just assume we'll never have more than 2^HDR_FIFO_ADDR_WIDTH packets
  // buffered at one time.

endmodule


`default_nettype wire