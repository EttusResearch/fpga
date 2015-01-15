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
    parameter ALPHAWIDTH=18,
    parameter BETAWIDTH=25,
    parameter PWIDTH=25,
    parameter DROP_TOP_P=6)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [IWIDTH*2-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [OWIDTH*2-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [BETAWIDTH-1:0]   beta_tdata;
   wire [ALPHAWIDTH-1:0]  alpha_tdata;
   wire [95:0] 		  n1_tdata, n2_tdata;
   wire [PWIDTH*2-1:0] 	  n3_tdata, n4_tdata, n6_tdata, n7_tdata;
   wire                   beta_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, alpha_tlast, n6_tlast, n7_tlast;
   wire                   beta_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, alpha_tvalid, n6_tvalid, n7_tvalid;
   wire                   beta_tready, n1_tready, n2_tready, n3_tready, n4_tready, alpha_tready, n6_tready, n7_tready;

   wire [MAX_LOG2_OF_SIZE-1:0] vector_len;

   setting_reg #(.my_addr(SR_VECTOR_LEN), .width(MAX_LOG2_OF_SIZE)) reg_len
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data), .out(vector_len));

   axi_setting_reg #(.ADDR(SR_BETA), .WIDTH(BETAWIDTH), .REPEATS(1), .MSB_ALIGN(1)) c1
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(beta_tdata), .o_tlast(beta_tlast), .o_tvalid(beta_tvalid), .o_tready(beta_tready));

   axi_setting_reg #(.ADDR(SR_ALPHA), .WIDTH(ALPHAWIDTH), .REPEATS(1), .MSB_ALIGN(1)) c2
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(alpha_tdata), .o_tlast(alpha_tlast), .o_tvalid(alpha_tvalid), .o_tready(alpha_tready));

   mult_rc #(.WIDTH_REAL(BETAWIDTH), .WIDTH_CPLX(IWIDTH), .WIDTH_P(48), .LATENCY(4), .CASCADE_OUT(0)) mul_c1
     (.clk(clk), .reset(reset),
      .real_tdata(beta_tdata), .real_tlast(beta_tlast), .real_tvalid(beta_tvalid), .real_tready(beta_tready),
      .cplx_tdata(i_tdata), .cplx_tlast(i_tlast), .cplx_tvalid(i_tvalid), .cplx_tready(i_tready),
      .p_tdata(n1_tdata), .p_tlast(n1_tlast), .p_tvalid(n1_tvalid), .p_tready(n1_tready));

   mult_add_rc #(.WIDTH_REAL(ALPHAWIDTH), .WIDTH_CPLX(PWIDTH), .WIDTH_P(48), .LATENCY(4),
                 .CASCADE_IN(0), .CASCADE_OUT(0)) mul_add_c2
     (.clk(clk), .reset(reset),
      .real_tdata(alpha_tdata), .real_tlast(alpha_tlast), .real_tvalid(alpha_tvalid), .real_tready(alpha_tready),
      .cplx_tdata(n4_tdata), .cplx_tlast(n4_tlast), .cplx_tvalid(n4_tvalid), .cplx_tready(n4_tready),
      .c_tdata(n1_tdata), .c_tlast(n1_tlast), .c_tvalid(n1_tvalid), .c_tready(n1_tready),
      .p_tdata(n2_tdata), .p_tlast(n2_tlast), .p_tvalid(n2_tvalid), .p_tready(n2_tready));

   axi_bit_reduce #(.WIDTH_IN(48), .WIDTH_OUT(PWIDTH), .DROP_TOP(DROP_TOP_P), .VECTOR_WIDTH(2)) drop_p_bits
     (.i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n7_tdata), .o_tlast(n7_tlast), .o_tvalid(n7_tvalid), .o_tready(n7_tready));

   split_stream_fifo #(.WIDTH(PWIDTH*2), .ACTIVE_MASK(4'b0011)) split_output
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(n7_tdata), .i_tlast(n7_tlast), .i_tvalid(n7_tvalid), .i_tready(n7_tready),
      .o0_tdata(n3_tdata), .o0_tlast(n3_tlast), .o0_tvalid(n3_tvalid), .o0_tready(n3_tready),
      .o1_tdata(n6_tdata), .o1_tlast(n6_tlast), .o1_tvalid(n6_tvalid), .o1_tready(n6_tready),
      .o2_tready(1'b0), .o3_tready(1'b0));

   delay_type3 #(.FIFOSIZE(MAX_LOG2_OF_SIZE), .MAX_LEN_LOG2(MAX_LOG2_OF_SIZE), .WIDTH(PWIDTH*2)) delay_input
     (.clk(clk), .reset(reset), .clear(clear),
      .len(vector_len),
      .i_tdata(n3_tdata), .i_tlast(n3_tlast), .i_tvalid(n3_tvalid), .i_tready(n3_tready),
      .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

   axi_round_and_clip_complex #(.WIDTH_IN(PWIDTH), .WIDTH_OUT(OWIDTH), .CLIP_BITS(0), .FIFOSIZE(5)) round_and_clip
     (.clk(clk), .reset(reset),
      .i_tdata(n6_tdata), .i_tlast(n6_tlast), .i_tvalid(n6_tvalid), .i_tready(n6_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

endmodule // vector_iir
