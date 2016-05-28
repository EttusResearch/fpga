//
// Copyright 2016 Ettus Research
//
// AXI Stream FIFO with additional error port.
// If i_terror is asserted along with i_tlast, the current
// input packet will be dropped (by rewinding the write 
// pointer to the end+1 address of the last good packet).
// 
// Warning: Since this FIFO has to be able to rewind the
//    write pointer, it holds off output until it has
//    a full packet. In some cases, this could cause
//    transient bubble states.

module axi_drop_packet #(
  parameter WIDTH=32,
  parameter MAX_PKT_SIZE=1024
)(
  input clk, input reset, input clear,
  input [WIDTH-1:0] i_tdata,
  input i_tvalid,
  input i_tlast,
  input i_terror,
  output i_tready,
  output [WIDTH-1:0] o_tdata,
  output o_tvalid,
  output o_tlast,
  input o_tready
);

  generate
    // Packet size of 1 is efficiently implemented as a pass through with i_terror masking i_tvalid.
    if (MAX_PKT_SIZE == 1) begin
      assign o_tdata  = i_tdata;
      assign o_tlast  = i_tlast;
      assign o_tvalid = i_tvalid & ~i_terror;
      assign i_tready = o_tready;
    // All other packet sizes
    end else begin
      reg [WIDTH-1:0] int_tdata = {WIDTH{1'b0}};
      reg  int_tlast = 1'b0, int_tvalid;
      wire int_tready;

      reg [$clog2(MAX_PKT_SIZE)-1:0] wr_addr, prev_wr_addr, rd_addr;
      reg [$clog2(MAX_PKT_SIZE)-1:0] in_pkt_cnt, out_pkt_cnt;
      reg full, empty;

      reg [WIDTH:0] mem[0:2**($clog2(MAX_PKT_SIZE))-1];
      // Initialize RAM to all zeros
      integer i;
      initial begin
        for (i = 0; i < (1 << $clog2(MAX_PKT_SIZE)); i = i + 1) begin
          mem[i] = 'd0;
        end
      end

      // Write logic
      always @(posedge clk) begin
        if (reset | clear) begin
          wr_addr       <= 'd0;
          prev_wr_addr  <= 'd0;
          in_pkt_cnt    <= 'd0;
          full          <= 1'b0;
        end else begin
          if (i_tvalid & i_tready) begin
            mem[wr_addr] <= {i_tdata,i_tlast};
            wr_addr      <= wr_addr + 1'b1;
          end
          if (~full & (wr_addr == rd_addr-1'b1) & i_tvalid & i_tready) begin
            full         <= 1'b1;
          end
          if (full & int_tvalid & int_tready) begin
            full         <= 1'b0;
          end
          // Rewind logic
          if (i_tvalid & i_tready & i_tlast) begin
            if (i_terror) begin
              wr_addr      <= prev_wr_addr;
            end else begin
              in_pkt_cnt   <= in_pkt_cnt + 1'b1;
              prev_wr_addr <= wr_addr + 1'b1;
            end
          end
        end
      end

      assign i_tready = ~full;

      // Read logic
      wire hold = (in_pkt_cnt == out_pkt_cnt);

      always @(posedge clk) begin
        if (reset | clear) begin
          rd_addr     <= 'd0;
          out_pkt_cnt <= 'd0;
          empty       <= 1'b1;
          int_tvalid  <= 1'b0;
        end else begin
          if (~int_tvalid | int_tready) begin
            {int_tdata,int_tlast} <= mem[rd_addr];
            int_tvalid            <= ~empty & ~hold;
          end
          if ((~empty & ~hold) & (~int_tvalid | int_tready)) begin
            rd_addr      <= rd_addr + 1;
          end
          if (empty & i_tvalid & i_tready) begin
            empty        <= 1'b0;
          end
          if ((~empty & ~hold) & (wr_addr-1'b1 == rd_addr) & (~int_tvalid | int_tready)) begin
            if (~i_tvalid) begin
              empty      <= 1'b1;
            end
          end
          // Prevent output until we have a full packet
          if (int_tvalid & int_tready & int_tlast) begin
            out_pkt_cnt  <= out_pkt_cnt + 1'b1;
          end
        end
      end

      // Output register stage
      // Added specifically to prevent Vivado synth from putting block RAM
      // output register in a slice instead of using the one block RAM primitive
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) axi_fifo_flop2 (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata({int_tlast,int_tdata}), .i_tvalid(int_tvalid), .i_tready(int_tready),
        .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
        .space(), .occupied());
    end
  endgenerate

endmodule
