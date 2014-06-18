

module complex_to_magsq
  #(parameter WIDTH=16)
   (input clk, input reset, input clear,
    input [2*WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [2*WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

    wire signed [WIDTH-1:0] in_i, in_q;
    wire [2*WIDTH-1:0] in_i_mag, in_q_mag;

   assign in_i = {i_tdata[2*WIDTH-1:WIDTH]};
   assign in_q = {i_tdata[WIDTH-1:0]};
   assign in_i_mag = in_i*in_i;
   assign in_q_mag = in_q*in_q;

   assign o_tdata = in_i_mag + in_q_mag;
   assign o_tlast = i_tlast;
   assign o_tvalid = i_tvalid;
   assign i_tready = o_tready;
   
endmodule // complex_to_magsq
