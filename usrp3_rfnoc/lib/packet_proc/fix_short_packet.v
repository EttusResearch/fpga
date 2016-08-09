
// Copyright 2015 Ettus Research

module fix_short_packet
  (input clk, input reset, input clear,
   input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
   output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   reg [12:0] 	 lines_left;

   reg [1:0] 	 state;
   localparam ST_CHDR =   2'd0;
   localparam ST_PACKET = 2'd1;
   localparam ST_DUMP =   2'd2;
   
   wire 	 lastline = (lines_left == 0);
   wire [12:0] 	 packet_length = i_tdata[47:35] + (|i_tdata[34:32]);
   
   always @(posedge clk)
     if(reset | clear)
       begin
	  state <= ST_CHDR;
	  lines_left <= 13'd0;
       end
     else
       if(i_tvalid & i_tready)
	 case(state)
	   ST_CHDR :
	     if((packet_length == 1) && ~i_tlast)  // First line is valid, dump rest
	       state <= ST_DUMP;
	     else
	       begin
		  lines_left <= packet_length - 2;
		  state <= ST_PACKET;
	       end
	   
	   ST_PACKET :
	     if(lastline & ~i_tlast)
	       state <= ST_DUMP;
	     else if(i_tlast)
	       state <= ST_CHDR;
	     else
	       lines_left <= lines_left - 1;
	   
	   ST_DUMP :
	     if(i_tlast)
	       state <= ST_CHDR;
	 endcase // case (state)
   
   assign o_tdata = i_tdata;
   assign o_tlast = i_tlast | ((state == ST_CHDR) & (packet_length == 1)) | ((state == ST_PACKET) & lastline);
   assign o_tvalid = i_tvalid & (state != ST_DUMP);

   assign i_tready = o_tready | (state == ST_DUMP);
   
endmodule // fix_short_packet
