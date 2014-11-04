//
// Copyright 2014 Ettus Research LLC
//
// FIXME -- detect seqnum errors?

module chdr_deframer
  (input clk, input reset, input clear,
   input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
   output [31:0] o_tdata, output reg [127:0] o_tuser, output o_tlast, output o_tvalid, input o_tready);
   
   localparam ST_HEAD = 2'd0;
   localparam ST_TIME = 2'd1;
   localparam ST_BODY = 2'd2;
   
   reg [1:0] 	 chdr_state;
   reg 		 odd_length;
   reg 		 even_phase;
   
   assign o_tdata = even_phase ? i_tdata[31:0] : i_tdata[63:32];
   assign o_tlast = i_tlast & (even_phase | odd_length);
   assign o_tvalid = i_tvalid & (chdr_state == ST_BODY);
   assign i_tready = (chdr_state == ST_BODY) ? o_tready & ( even_phase | (odd_length & i_tlast)) : 1'b1;
   
   always @(posedge clk)
     if(reset)
       chdr_state <= ST_HEAD;
     else
       case(chdr_state)
	 ST_HEAD :
	   if(i_tvalid & i_tready)
	     begin
		even_phase <= 1'b0;
		odd_length <= i_tdata[34] ^ (i_tdata[33] | i_tdata[32]);
		o_tuser[127:64] <= i_tdata;
		o_tuser[63:0] <= 64'd0;
		if(i_tdata[61])
		  chdr_state <= ST_TIME;
		else
		  chdr_state <= ST_BODY;
	     end // if (i_tvalid & i_tready)
	 ST_TIME :
	   if(i_tvalid & i_tready)
	     begin
		o_tuser[63:0] <= i_tdata;
		chdr_state <= ST_BODY;
	     end
	 ST_BODY :
	   if(o_tvalid & o_tready)
	     begin
		even_phase <= ~even_phase;
		if(o_tlast)
		  chdr_state <= ST_HEAD;
	     end
       endcase // case (chdr_state)
   
endmodule // chdr_deframer
