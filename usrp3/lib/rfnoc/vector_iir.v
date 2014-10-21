

module vector_iir
  #(parameter BASE=0,
    parameter MAX_LOG2_OF_SIZE = 10)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);
   
   wire [31:0] 	  n0_tdata, n1_tdata, n2_tdata, n3_tdata, n4_tdata, n5_tdata, n6_tdata, n7_tdata, n8_tdata, n9_tdata;
   wire 	  n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n6_tlast, n7_tlast, n8_tlast, n9_tlast;
   wire 	  n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n6_tvalid, n7_tvalid, n8_tvalid, n9_tvalid;
   wire 	  n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n6_tready, n7_tready, n8_tready, n9_tready;
   
   wire [MAX_LOG2_OF_SIZE-1:0] vector_len;
   
   setting_reg #(.my_addr(BASE), .width(MAX_LOG2_OF_SIZE)) reg_len
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data), .out(vector_len));

   const_sreg #(.BASE(BASE+1), .WIDTH(32)) c1
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(n0_tdata), .o_tlast(n0_tlast), .o_tvalid(n0_tvalid), .o_tready(n0_tready));
   
   const_sreg #(.BASE(BASE+1), .WIDTH(32)) c2
     (.clk(clk), .reset(reset), .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(n5_tdata), .o_tlast(n5_tlast), .o_tvalid(n5_tvalid), .o_tready(n5_tready));
   
   cmul cmul_c1
     (.clk(clk), .reset(reset),
      .a_tdata(i_tdata), .a_tlast(i_tlast), .a_tvalid(i_tvalid), .a_tready(i_tready),
      .b_tdata(n0_tdata), .b_tlast(n0_tlast), .b_tvalid(n0_tvalid), .b_tready(n0_tready),
      .o_tdata(n1_tdata), .o_tlast(n1_tlast), .o_tvalid(n1_tvalid), .o_tready(n1_tready));

   cadd cadd
     (.clk(clk), .reset(reset),
      .a_tdata(n1_tdata), .a_tlast(n1_tlast), .a_tvalid(n1_tvalid), .a_tready(n1_tready),
      .b_tdata(n6_tdata), .b_tlast(n6_tlast), .b_tvalid(n6_tvalid), .b_tready(n6_tready),
      .o_tdata(n2_tdata), .o_tlast(n2_tlast), .o_tvalid(n2_tvalid), .o_tready(n2_tready));
      
   cmul cmul_c2
     (.clk(clk), .reset(reset),
      .a_tdata(n4_tdata), .a_tlast(n4_tlast), .a_tvalid(n4_tvalid), .a_tready(n4_tready),
      .b_tdata(n5_tdata), .b_tlast(n5_tlast), .b_tvalid(n5_tvalid), .b_tready(n5_tready),
      .o_tdata(n6_tdata), .o_tlast(n6_tlast), .o_tvalid(n6_tvalid), .o_tready(n6_tready));

   split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011)) split_output
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o0_tdata(n3_tdata), .o0_tlast(n3_tlast), .o0_tvalid(n3_tvalid), .o0_tready(n3_tready),
      .o1_tdata(o_tdata), .o1_tlast(o_tlast), .o1_tvalid(o_tvalid), .o1_tready(o_tready),
      .o2_tready(1'b0), .o3_tready(1'b0));

   delay #(.MAX_LEN_LOG2(MAX_LOG2_OF_SIZE), .WIDTH(32)) delay_input
     (.clk(clk), .reset(reset), .clear(clear),
      .len(vector_len),
      .i_tdata(n3_tdata), .i_tlast(n3_tlast), .i_tvalid(n3_tvalid), .i_tready(n3_tready),
      .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

endmodule // vector_iir
