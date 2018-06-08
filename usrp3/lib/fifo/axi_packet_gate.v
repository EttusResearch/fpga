//
// Copyright 2012 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Description:
//   Holds packets in a FIFO until they are complete. This allows buffering 
//   slowly-built packets so they don't clog up downstream logic. If o_tready
//   is held high, this module guarantees that o_tvalid will not be deasserted
//   until a full packet is transferred. This module can also optionally drop
//   a packet if the i_terror bit is asserted along with i_tlast. This allows
//   discarding packet, say, if a CRC check fails.
//   NOTE:
//   - The maximum size of a packet that can pass through this module is
//     2^SIZE lines. If a larger packet is sent, this module will lock up.
//   - Assuming that upstream is valid and downstream is ready, the maximum 
//     in to out latency is (2^SIZE + 2) clock cycles. 2^SIZE because this
//     module gates a packet, 1 cycle for the RAM read and 1 more cycle for
//     the output register.

module axi_packet_gate #(
  parameter WIDTH = 64,   // Width of datapath
  parameter SIZE  = 10    // log2 of the buffer size (must be >= MTU of packet)
) (
  input  wire             clk, 
  input  wire             reset, 
  input  wire             clear,
  input  wire [WIDTH-1:0] i_tdata,
  input  wire             i_tlast,
  input  wire             i_terror,
  input  wire             i_tvalid,
  output wire             i_tready,
  output reg  [WIDTH-1:0] o_tdata = {WIDTH{1'b0}},
  output reg              o_tlast = 1'b0,
  output reg              o_tvalid = 1'b0,
  input  wire             o_tready
);

  localparam [SIZE-1:0] ADDR_ZERO = {SIZE{1'b0}};
  localparam [SIZE-1:0] ADDR_ONE  = {{(SIZE-1){1'b0}}, 1'b1};
  localparam [SIZE:0]   CNT_ZERO  = {(SIZE+1){1'b0}};
  localparam [SIZE:0]   CNT_ONE   = {{SIZE{1'b0}}, 1'b1};

  // -------------------------------------------
  // RAM block that will hold pkts
  // -------------------------------------------
  wire            wr_en, rd_en;
  wire [WIDTH:0]  wr_data, rd_data;
  reg  [SIZE-1:0] wr_addr = ADDR_ZERO, rd_addr = ADDR_ZERO;

  // We need to instantiate a simple dual-port RAM here so
  // we use the ram_2port module with one read port and one
  // write port and "NO-CHANGE" mode.
  ram_2port #(
    .DWIDTH (WIDTH+1), .AWIDTH(SIZE),
    .RW_MODE("NO-CHANGE"), .OUT_REG(0)
  ) ram_i (
    .clka (clk), .ena(1'b1), .wea(wr_en),
    .addra(wr_addr), .dia(wr_data), .doa(),
    .clkb (clk), .enb(rd_en), .web(1'b0),
    .addrb(rd_addr), .dib(), .dob(rd_data)
  );

  // FIFO empty/full logic. The condition for both
  // empty and full is when rd_addr == wr_addr. However,
  // it matters if we approach that case from the low side
  // or the high side. So keep track of the almost empty/full
  // state for determine if the next transaction will cause
  // the FIFO to be truly empty or full.
  reg  ram_full = 1'b0, ram_empty = 1'b1;
  wire almost_full  = (wr_addr == rd_addr - ADDR_ONE);
  wire almost_empty = (wr_addr == rd_addr + ADDR_ONE);

  always @(posedge clk) begin
    if (reset | clear) begin
      ram_full <= 1'b0;
    end else begin
      if (almost_full) begin
        if (wr_en & ~rd_en)
          ram_full <= 1'b1;
      end else begin
        if (~wr_en & rd_en)
          ram_full <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset | clear) begin
      ram_empty <= 1'b1;
    end else begin
      if (almost_empty) begin
        if (rd_en & ~wr_en)
          ram_empty <= 1'b1;
      end else begin
        if (~rd_en & wr_en)
          ram_empty <= 1'b0;
      end
    end
  end

  // -------------------------------------------
  // Write state machine
  // -------------------------------------------
  reg  [SIZE-1:0] wr_head_addr  = ADDR_ZERO;
  reg  [SIZE:0]   in_pkt_cnt    = CNT_ZERO;

  assign i_tready = ~ram_full;
  assign wr_en    = i_tvalid & i_tready;
  assign wr_data  = {i_tlast, i_tdata};

  always @(posedge clk) begin
    if (reset | clear) begin
      wr_addr <= ADDR_ZERO;
      wr_head_addr <= ADDR_ZERO;
      in_pkt_cnt <= CNT_ZERO;
    end else begin
      if (wr_en) begin
        if (i_tlast) begin
          if (i_terror) begin
            // Incoming packet had an error. Rewind the write
            // pointer and pretend that a packet never came in.
            wr_addr <= wr_head_addr;
          end else begin
            // Incoming packet had no error, advance wr_addr and
            // wr_head_addr for the next packet.
            wr_addr <= wr_addr + ADDR_ONE;
            wr_head_addr <= wr_addr + ADDR_ONE;
            in_pkt_cnt <= in_pkt_cnt + CNT_ONE;
          end
        end else begin
          // Packet is still in progress, only update wr_addr
          wr_addr <= wr_addr + ADDR_ONE;
        end
      end
    end
  end

  // -------------------------------------------
  // Read state machine
  // -------------------------------------------
  reg  [SIZE:0] out_pkt_cnt   = CNT_ZERO;
  reg           rd_data_valid = 1'b0;
  wire          update_out_reg;
  wire          ready_to_read = (~ram_empty) & (in_pkt_cnt != out_pkt_cnt);

  // Read from RAM if
  // - A full packet has been written AND
  // - Output data is not valid OR is currently being transferred
  assign rd_en = ready_to_read & (update_out_reg | ~rd_data_valid);

  always @(posedge clk) begin
    if (reset | clear) begin
      rd_data_valid <= 1'b0;
      rd_addr <= ADDR_ZERO;
    end else begin
      if (update_out_reg | ~rd_data_valid) begin
        // Output data is not valid OR is currently being transferred
        if (ready_to_read) begin
          rd_data_valid <= 1'b1;
          rd_addr <= rd_addr + ADDR_ONE;
        end else begin
          rd_data_valid <= 1'b0;  // Don't read
        end
      end
    end
  end

  // Instantiate an output register to break critical paths starting
  // at the RAM module. When ram_2port is inferred as BRAM, the tools
  // should absorb this register into the BRAM block without using
  // SLICE resources.
  always @(posedge clk) begin
    if (reset | clear) begin
      o_tvalid <= 1'b0;
    end else if (update_out_reg) begin
      o_tvalid <= rd_data_valid;
      {o_tlast, o_tdata} <= rd_data;
    end
  end
  // Update the output reg only *after* the downstream
  // block has consumed the current value
  assign update_out_reg = o_tready | ~o_tvalid;

  // Output packet counter
  always @(posedge clk) begin
    if (reset | clear) begin
      out_pkt_cnt <= CNT_ZERO;
    end else if (o_tvalid & o_tready & o_tlast) begin
      out_pkt_cnt <= out_pkt_cnt + CNT_ONE;
    end
  end

endmodule
