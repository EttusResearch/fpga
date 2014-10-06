
// FIXME axi_fifo_flop added by mne to address timing issues.  Should probably use a proper Xilinx coregen, though

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

   wire [2*WIDTH-1:0] mag = in_i_mag + in_q_mag;
   
   axi_fifo_flop #(.WIDTH(WIDTH*2+1)) axi_fifo_flop
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({i_tlast,mag}), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready));
      
endmodule // complex_to_magsq
