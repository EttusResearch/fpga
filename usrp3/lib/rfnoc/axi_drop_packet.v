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
      reg [WIDTH-1:0] int_tdata;
      reg int_tlast, int_tvalid;
      wire int_tready;

      reg [$clog2(MAX_PKT_SIZE)-1:0] wr_addr, prev_wr_addr, rd_addr;
      reg [$clog2(MAX_PKT_SIZE):0] in_pkt_cnt, out_pkt_cnt;
      reg full = 1'b0, empty = 1'b1;

      reg [WIDTH:0] mem[2**($clog2(MAX_PKT_SIZE))-1:0];
      // Initialize RAM to all zeros
      integer i;
      initial begin
        for (i = 0; i < (1 << $clog2(MAX_PKT_SIZE)); i = i + 1) begin
          mem[i] = 'd0;
        end
      end

      assign i_tready   = ~full;
      wire write        = i_tvalid & i_tready;
      wire read         = ~empty & ~hold & int_tready;
      wire almost_full  = (wr_addr == rd_addr-1'b1);
      wire almost_empty = (wr_addr == rd_addr+1'b1);

      // Write logic
      always @(posedge clk) begin
        if (write) begin
          mem[wr_addr] <= {i_tlast,i_tdata};
          wr_addr      <= wr_addr + 1'b1;
        end
        if (almost_full) begin
          if (write & ~read) begin
            full       <= 1'b1;
          end
        end else begin
          if (~write & read) begin
            full       <= 1'b0;
          end
        end
        // Rewind logic
        if (write & i_tlast) begin
          if (i_terror) begin
            wr_addr      <= prev_wr_addr;
          end else begin
            in_pkt_cnt   <= in_pkt_cnt + 1'b1;
            prev_wr_addr <= wr_addr + 1'b1;
          end
        end
        if (reset | clear) begin
          wr_addr       <= 0;
          prev_wr_addr  <= 0;
          in_pkt_cnt    <= 0;
          full          <= 1'b0;
        end
      end

      // Read logic
      wire hold         = (in_pkt_cnt == out_pkt_cnt);

      always @(posedge clk) begin
        if (int_tready) begin
          int_tdata      <= mem[rd_addr][WIDTH-1:0];
          int_tlast      <= mem[rd_addr][WIDTH];
          int_tvalid     <= ~empty & ~hold;
        end
        if (read) begin
          rd_addr      <= rd_addr + 1;
        end
        if (almost_empty) begin
          if (read & ~write) begin
            empty      <= 1'b1;
          end
        end else begin
          if (~read & write) begin
            empty      <= 1'b0;
          end
        end
        // Prevent output until we have a full packet
        if (int_tvalid & int_tready & int_tlast) begin
          out_pkt_cnt  <= out_pkt_cnt + 1'b1;
        end
        if (reset | clear) begin
          rd_addr     <= 0;
          out_pkt_cnt <= 0;
          empty       <= 1'b1;
          int_tvalid  <= 1'b0;
        end
      end

      // Output register stage
      // Added specifically to prevent Vivado synth from using a slice register instead 
      // of the block RAM primative's output register.
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) axi_fifo_flop2 (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata({int_tlast,int_tdata}), .i_tvalid(int_tvalid), .i_tready(int_tready),
        .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
        .space(), .occupied());
    end
  endgenerate

endmodule
