
module axi_pipe
  #(parameter STAGES=3)
   (input clk, input reset, input clear,
    input i_tvalid, output i_tready,
    output o_tvalid, input o_tready,
    output [STAGES-1:0] enables,
    output reg [STAGES-1:0] valids);

   assign o_tvalid = valids[STAGES-1];
   assign i_tready = enables[0];
   assign enables[STAGES-1] = o_tready;
   
   genvar 		    i;
   generate
      for(i=1; i<STAGES; i=i+1)
	always @(posedge clk)
	  if(reset | clear)
	    valids[i] <= 1'b0;
      	  else
	    valids[i] <= valids[i-1] | (valids[i] & ~enables[i]);
   endgenerate

   always @(posedge clk)
     if(reset | clear)
       valids[0] <= 1'b0;
     else
       valids[0] <= i_tvalid | (valids[0] & ~enables[0]);

   genvar 		    j;
   generate
      for(j=0; j<STAGES-1; j=j+1)
	assign enables[j] = o_tready | (|(~valids[STAGES-1:j+1]));
   endgenerate
   
       
endmodule // axi_pipe
