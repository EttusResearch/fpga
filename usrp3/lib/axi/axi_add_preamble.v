//
// Copyright 2016 Ettus Research LLC
//
// Adds preamble and CRC/num_words check
// 0xBA5EBA77B01DFACE <packet> [crc, num_words]
//

module axi_add_preamble #(
  parameter WIDTH=64
) (
   input clk,
   input reset,
   input clear,
   //
   input [WIDTH-1:0] i_tdata,
   input i_tlast,
   input i_tvalid,
   output i_tready,
   //
   output reg [WIDTH-1:0] o_tdata,
   output o_tvalid,
   input o_tready
);

   //States
   localparam IDLE = 0;
   localparam PREAMBLE = 1;
   localparam PASS = 2;
   localparam CRC = 3;
   
   reg [1:0]  state, next_state;
   
   reg [31:0] word_count;
  reg [31:0] checksum_reg;
  always @(posedge clk) begin
     if (state == IDLE) begin
        checksum_reg <= 0;
        word_count <= 0;
     end else if (i_tready && i_tvalid) begin
        checksum_reg <= checksum_reg ^ i_tdata[31:0] ^ i_tdata[63:32];
        word_count <= word_count+1;
     end
  end
      
   always @(posedge clk) 
      if (reset | clear) begin
         state <= IDLE;
      end else begin
         state <= next_state;
      end 

   always @(*) begin
      case(state)
         IDLE: begin
            if (i_tvalid) begin
               next_state = PREAMBLE;
            end else begin
               next_state = IDLE;
            end
         end 

         PREAMBLE: begin
            if(o_tready) begin
                next_state = PASS;
            end else begin
                next_state = PREAMBLE;
            end
         end

         PASS: begin
            if(i_tready && i_tvalid && i_tlast) begin
                 next_state = CRC;
             end else begin
                 next_state = PASS;
             end
         end

         CRC: begin
            if(o_tready) begin
                 next_state = IDLE;
             end else begin
                 next_state = CRC;
             end
         end
        
      endcase
   end 

   //
   // Muxes
   //
   always @*
      begin
         case(state)
            IDLE:       o_tdata = 0;
            PASS:       o_tdata = i_tdata;
            PREAMBLE:   o_tdata = 64'hBA5EBA77B01DFACE;
            CRC:        o_tdata = {checksum_reg,word_count};
         endcase 
      end

   assign o_tvalid = (state == PASS) ? i_tvalid : (state != IDLE);
   assign i_tready = (state == PASS) ? o_tready : 1'b0;

endmodule 



