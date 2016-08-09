
// Copyright Ettus Research 2014

module pfb
  #(parameter BASE=0,
    parameter TAPS_PER_BIN=4,
    parameter MAX_BINS_LOG2=10,
    parameter WIDTH_IN=16,
    parameter WIDTH_OUT=16,
    parameter PWIDTH=48,
    parameter CLIP_BITS=4,
    parameter USE_CASCADE=1)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [2*WIDTH_IN-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [2*WIDTH_IN-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [2*WIDTH_IN-1:0]    delay_tdata[0:TAPS_PER_BIN];
   wire [TAPS_PER_BIN:0]    delay_tlast, delay_tvalid, delay_tready;
   
   wire [2*PWIDTH-1:0] 	    int_result_tdata[0:TAPS_PER_BIN];
   wire [TAPS_PER_BIN:0]    int_result_tlast, int_result_tvalid, int_result_tready;
   
   wire [MAX_BINS_LOG2-1:0] bins;
   
   setting_reg #(.my_addr(BASE), .width(MAX_BINS_LOG2)) reg_bins
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(bins), .changed());

   // Connect input side of systolic chain
   assign delay_tdata[0] = i_tdata;
   assign delay_tlast[0] = i_tlast;
   assign delay_tvalid[0] = i_tvalid;
   assign i_tready = delay_tready[0];

   // Constant zero for product input side of chain
   assign int_result_tdata[0]  = {2*PWIDTH{1'b0}};
   assign int_result_tlast[0]  = 1'b0;
   assign int_result_tvalid[0] = 1'b1;

   // Instantiate systolic chain of stages, each with 2 in 2 out
   genvar 			    i;
   generate
      for(i=0;i<TAPS_PER_BIN;i=i+1)
	pfb_stage #(.BASE(BASE+i*2+2), .DWIDTH(WIDTH_IN), .CWIDTH(25), .PWIDTH(PWIDTH), .MAX_BINS_LOG2(MAX_BINS_LOG2),
		    .CASCADE_IN((USE_CASCADE == 0)|(i == 0) ? 0 : 1),
		    .CASCADE_OUT((USE_CASCADE == 0)|(i == (TAPS_PER_BIN-1)) ? 0 : 1)) stage
	    (.clk(clk), .reset(reset), .clear(clear),
	     .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	     .bins(bins),
	     .i_tdata(delay_tdata[i]), .i_tlast(delay_tlast[i]), .i_tvalid(delay_tvalid[i]), .i_tready(delay_tready[i]),
	     .c_tdata(int_result_tdata[i]), .c_tlast(int_result_tlast[i]), .c_tvalid(int_result_tvalid[i]), .c_tready(int_result_tready[i]),
	     .o_tdata(delay_tdata[i+1]), .o_tlast(delay_tlast[i+1]), .o_tvalid(delay_tvalid[i+1]), .o_tready(delay_tready[i+1]),
	     .p_tdata(int_result_tdata[i+1]), .p_tlast(int_result_tlast[i+1]), .p_tvalid(int_result_tvalid[i+1]), .p_tready(int_result_tready[i+1]));
   endgenerate

   // Terminate delay output.  Hopefully the last delay line will get optimized out since it is unused.
   assign delay_tready[TAPS_PER_BIN] = 1'b1;

   // Connect complex round to product output
   axi_round_and_clip_complex #(.WIDTH_IN(PWIDTH), .WIDTH_OUT(WIDTH_OUT), .CLIP_BITS(CLIP_BITS), .FIFOSIZE(0)) round_complex
     (.clk(clk), .reset(reset),
      .i_tdata(int_result_tdata[TAPS_PER_BIN]), .i_tlast(int_result_tlast[TAPS_PER_BIN]),
      .i_tvalid(int_result_tvalid[TAPS_PER_BIN]), .i_tready(int_result_tready[TAPS_PER_BIN]),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));
      
endmodule // pfb
