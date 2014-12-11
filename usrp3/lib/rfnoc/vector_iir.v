//
// Copyright 2014 Ettus Research LLC
//
// H(z) = alpha/(1 - beta*z^-1)
// Typically beta = 1 - alpha

module vector_iir
  #(parameter SR_VECTOR_LEN=0,
    parameter SR_ALPHA=0,
    parameter SR_BETA=0,
    parameter MAX_LOG2_OF_SIZE = 10,
    parameter IWIDTH=16,
    parameter OWIDTH=16,
    parameter CWIDTH=25,
    parameter PWIDTH=48)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [IWIDTH*2-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [OWIDTH*2-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);
   
   wire [CWIDTH-1:0] 	  n0_tdata, n5_tdata;
   wire [PWIDTH*2-1:0] 	  n1_tdata, n2_tdata;
   wire [OWIDTH*2-1:0] 	  n3_tdata, n4_tdata, n7_tdata;
   wire 		  n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n7_tlast;
   wire 		  n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n7_tvalid;
   wire 		  n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n7_tready;
   
   wire [MAX_LOG2_OF_SIZE-1:0] vector_len;
   
   setting_reg #(.my_addr(SR_VECTOR_LEN), .width(MAX_LOG2_OF_SIZE)) reg_len
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data), .out(vector_len));

   axi_setting_reg #(.ADDR(SR_BETA), .WIDTH(CWIDTH), .ALWAYS_VALID(1)) c1
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(n0_tdata), .o_tlast(n0_tlast), .o_tvalid(n0_tvalid), .o_tready(n0_tready));
   
   axi_setting_reg #(.ADDR(SR_ALPHA), .WIDTH(CWIDTH), .ALWAYS_VALID(1)) c2
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(n5_tdata), .o_tlast(n5_tlast), .o_tvalid(n5_tvalid), .o_tready(n5_tready));
   
   mult_rc #(.WIDTH_A(CWIDTH), .WIDTH_B(IWIDTH), .WIDTH_P(PWIDTH), .LATENCY(4), .CASCADE_OUT(1)) mul_c1
     (.clk(clk), .reset(reset),
      .a_tdata(n0_tdata), .a_tlast(n0_tlast), .a_tvalid(n0_tvalid), .a_tready(n0_tready),
      .b_tdata(i_tdata), .b_tlast(i_tlast), .b_tvalid(i_tvalid), .b_tready(i_tready),
      .p_tdata(n1_tdata), .p_tlast(n1_tlast), .p_tvalid(n1_tvalid), .p_tready(n1_tready));

   mult_add_rc #(.WIDTH_A(CWIDTH), .WIDTH_B(OWIDTH), .WIDTH_P(PWIDTH), .LATENCY(4),
		 .CASCADE_IN(1), .CASCADE_OUT(0)) mul_add_c2
     (.clk(clk), .reset(reset),
      .a_tdata(n5_tdata), .a_tlast(n5_tlast), .a_tvalid(n5_tvalid), .a_tready(n5_tready),
      .b_tdata(n4_tdata), .b_tlast(n4_tlast), .b_tvalid(n4_tvalid), .b_tready(n4_tready),
      .c_tdata(n1_tdata), .c_tlast(n1_tlast), .c_tvalid(n1_tvalid), .c_tready(n1_tready),
      .p_tdata(n2_tdata), .p_tlast(n2_tlast), .p_tvalid(n2_tvalid), .p_tready(n2_tready));

   round_and_clip_complex #(.WIDTH_IN(PWIDTH), .WIDTH_OUT(OWIDTH), .CLIP_BITS(0), .FIFOSIZE(0)) round_and_clip
     (.clk(clk), .reset(reset),
      .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n7_tdata), .o_tlast(n7_tlast), .o_tvalid(n7_tvalid), .o_tready(n7_tready));
        
   split_stream_fifo #(.WIDTH(OWIDTH*2), .ACTIVE_MASK(4'b0011)) split_output
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(n7_tdata), .i_tlast(n7_tlast), .i_tvalid(n7_tvalid), .i_tready(n7_tready),
      .o0_tdata(n3_tdata), .o0_tlast(n3_tlast), .o0_tvalid(n3_tvalid), .o0_tready(n3_tready),
      .o1_tdata(o_tdata), .o1_tlast(o_tlast), .o1_tvalid(o_tvalid), .o1_tready(o_tready),
      .o2_tready(1'b0), .o3_tready(1'b0));

   delay_type3 #(.FIFOSIZE(MAX_LOG2_OF_SIZE), .MAX_LEN_LOG2(MAX_LOG2_OF_SIZE), .WIDTH(OWIDTH*2)) delay_input
     (.clk(clk), .reset(reset), .clear(clear),
      .len(vector_len),
      .i_tdata(n3_tdata), .i_tlast(n3_tlast), .i_tvalid(n3_tvalid), .i_tready(n3_tready),
      .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

endmodule // vector_iir
