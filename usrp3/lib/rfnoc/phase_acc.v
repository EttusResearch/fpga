
module phase_acc
  #(parameter WIDTH = 16)
   (input clk, input reset, input clear,
    input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   reg [WIDTH-1:0]     acc, phase_inc;

   always @(posedge clk)
     if(reset | clear)
       acc <= 0;
     else if(i_tvalid & o_tready)
       if(i_tlast)
	 begin
	    acc <= i_tdata;
	    phase_inc <= i_tdata;
	 end
       else
	 acc <= acc + phase_inc;
   
   assign i_tready = o_tready;
   assign o_tvalid = i_tvalid;

   assign o_tlast = i_tlast;

   assign o_tdata = i_tlast ? {WIDTH{1'b0}} : acc;
   
   
endmodule // phase_acc

    