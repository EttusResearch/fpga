//
// Copyright 2014 Ettus Research LLC
//
//
// Strips preamble and CRC/num_words check
// 0xBA5EBA77B01DFACE <packet> [crc, num_words] 
//

module axi_strip_preamble #(
  parameter WIDTH=64,
  parameter MAX_PKT_SIZE=1024
) (
   input clk,
   input reset,
   input clear,
   //
   input [WIDTH-1:0] i_tdata,
   input i_tvalid,
   output i_tready,
   //
   output [WIDTH-1:0] o_tdata,
   output o_tlast,
   output o_tvalid,
   input  o_tready,
   //
   output error
);
    
   reg [1:0] state, next_state;
   
   localparam IDLE = 0;
   localparam PASS = 1;
   localparam FINISH = 2;
   
   wire premem_tvalid;
   wire premem_tready;
   
   reg [31:0] checksum, checksum_r;
   reg [31:0] word_count, word_count_r;
   
   wire det_preamble = i_tdata == 64'hBA5EBA77B01DFACE;
   wire det_crc = (word_count == i_tdata[31:0]) && (checksum == i_tdata[63:32]);

   always @(posedge clk) begin
      if (state == IDLE) begin
         checksum <= 0;
         checksum_r <= 0;
         word_count <= 0;
         word_count_r <= 0;
      end else if ((state == PASS) && i_tready && i_tvalid) begin
         checksum <= checksum ^ i_tdata[31:0] ^ i_tdata[63:32];
         checksum_r <= checksum;
         word_count <= word_count+1'b1;
         word_count_r <= word_count;
      end
   end

   always @(posedge clk) begin
      if (reset | clear) begin
         state <= IDLE;
      end else begin
         state <= next_state;
      end
   end
   
   assign error = (state == PASS) && det_preamble && i_tvalid;

   always @(*) begin
      case(state)
         IDLE: begin
            if (det_preamble && i_tvalid)
               next_state = PASS;
            else
               next_state = IDLE;
         end 
         
         PASS: begin
            if((det_preamble && i_tvalid ) || (det_crc && premem_tready && i_tvalid )) begin //Exit if preamble or crc is detected
                next_state = IDLE; //Note if preamble is detected in PASS state an error is thrown to reset the write memory
            end else begin
                next_state = PASS;
            end
         end
         
         default: begin
            next_state = IDLE;
        end

      endcase
   end 

   assign premem_tvalid = (state == PASS) ? i_tvalid : 1'b0;
   assign i_tready = (state == PASS) ? premem_tready : 1'b1;
   
   wire [WIDTH-1:0] mem_tdata;
   wire premem_gated_tvalid;
   wire mem_tvalid;

   // Input register stage
   // Added to delay input to memory so we can peek ahead and see if crc is coming in
   // Gate ready and valid by the next incoming sample valid
   // This is so we can detect the last valid sample and then use the crc to set last
   axi_fifo_flop2 #(.WIDTH(WIDTH)) axi_fifo_flop_premem (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(i_tdata), .i_tvalid(premem_tvalid & ~det_crc), .i_tready(premem_tready),
        .o_tdata(mem_tdata), .o_tvalid(premem_gated_tvalid), .o_tready(mem_tready & premem_tvalid),
        .space(), .occupied());
   
   assign mem_tvalid = premem_tvalid & premem_gated_tvalid;
   
   /////////////////////////////////////////////////
   //Fifo to store incoming packets
   //The write pntr rewinds whenever an error occurs
   /////////////////////////////////////////////////
   
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

   assign mem_tready   = ~full;
   wire write        = mem_tvalid & mem_tready & ~error;
   wire read         = ~hold & int_tready;
   wire almost_full  = (wr_addr == rd_addr-1'b1);
   wire almost_empty = (wr_addr == rd_addr+1'b1);

   // Write logic
   always @(posedge clk) begin
     if (write) begin
       mem[wr_addr] <= {det_crc,mem_tdata};
     end

     // Rewind logic
     if(error)
        wr_addr <= prev_wr_addr;
     else if(write)
        wr_addr <= wr_addr + 1'b1;
        
     if (almost_full) begin
       if (write & ~read) begin
         full       <= 1'b1;
       end
     end else begin
       if (~write & read) begin
         full       <= 1'b0;
       end
     end
        
     if (write & det_crc) begin
       in_pkt_cnt   <= in_pkt_cnt + 1'b1;
       prev_wr_addr <= wr_addr + 1'b1;
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
   wire [WIDTH-1:0] int_tdata = mem[rd_addr][WIDTH-1:0];
   wire int_tlast = mem[rd_addr][WIDTH];
   wire int_tvalid = ~empty & ~hold;

   always @(posedge clk) begin
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
       empty <= 1'b1;
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

endmodule

  
