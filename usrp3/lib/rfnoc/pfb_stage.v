

// Copyright 2014, Ettus Research

module pfb_stage
  #(parameter BASE=0,
    parameter DWIDTH=16,          // Input data width
    parameter CWIDTH=25,          // Coefficient width
    parameter PWIDTH=48,          // Mult-Acc chain width
    parameter MAX_BINS_LOG2=10)   // How big to make delay lines
   
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [MAX_BINS_LOG2-1:0] bins,
    input [2*DWIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    input [2*PWIDTH-1:0] c_tdata, input c_tlast, input c_tvalid, output c_tready,
    output [2*DWIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
    output [2*PWIDTH-1:0] p_tdata, output p_tlast, output p_tvalid, input p_tready);

   wire [2*DWIDTH-1:0] 	     n1_tdata;  // split -> delay
   wire 		     n1_tlast, n1_tvalid, n1_tready;
   
   wire [2*DWIDTH-1:0] 	     n2_tdata;  // split -> address generator (data unused)
   wire 		     n2_tlast, n2_tvalid, n2_tready;
   
   wire [2*DWIDTH-1:0] 	     n3_tdata;  // split -> mult
   wire 		     n3_tlast, n3_tvalid, n3_tready;

   wire [MAX_BINS_LOG2-1:0]  n4_tdata;  // addresses from addr_gen -> coeff ram
   wire 		     n4_tlast, n4_tvalid, n4_tready;
   
   wire [CWIDTH-1:0] 	     n5_tdata;  // coefficients from RAM -> multiplier
   wire 		     n5_tlast, n5_tvalid, n5_tready;

   split_stream #(.WIDTH(DWIDTH*2), .ACTIVE_MASK(4'b0111)) splitter
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o0_tdata(n1_tdata), .o0_tlast(n1_tlast), .o0_tvalid(n1_tvalid), .o0_tready(n1_tready),
      .o1_tdata(n2_tdata), .o1_tlast(n2_tlast), .o1_tvalid(n2_tvalid), .o1_tready(n2_tready),
      .o2_tdata(n3_tdata), .o2_tlast(n3_tlast), .o2_tvalid(n3_tvalid), .o2_tready(n3_tready),
      .o3_tready(1'b1));

   delay #(.MAX_LEN_LOG2(MAX_BINS_LOG2), .WIDTH(DWIDTH*2)) delayline
     (.clk(clk), .reset(reset), .clear(clear),
      .len(bins),
      .i_tdata(n1_tdata), .i_tlast(n1_tlast), .i_tvalid(n1_tvalid), .i_tready(n1_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

   counter #(.WIDTH(MAX_BINS_LOG2)) addr_gen
     (.clk(clk), .reset(reset), .clear(clear),
      .max(bins),
      .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

   ram_to_fifo #(.DWIDTH(CWIDTH), .AWIDTH(MAX_BINS_LOG2)) coeffs_ram
     (.clk(clk), .reset(reset), .clear(clear),
      .config_tdata(m_axis_config_tdata), .config_tlast(m_axis_config_tlast), .config_tvalid(m_axis_config_tvalid), .config_tready(m_axis_config_tready),
      .i_tdata(n4_tdata), .i_tlast(n4_tlast), .i_tvalid(n4_tvalid), .i_tready(n4_tready),
      .o_tdata(n5_tdata), .o_tlast(n5_tlast), .o_tvalid(n5_tvalid), .o_tready(n5_tready));
   
   mult_add_rc #(.WIDTH_A(CWIDTH), .WIDTH_B(DWIDTH), .WIDTH_P(PWIDTH), .LATENCY(4)) mult_add_rc
     (.clk(clk), .reset(reset),
      .a_tdata(n5_tdata), .a_tlast(n5_tlast), .a_tvalid(n5_tvalid), .a_tready(n5_tready),
      .b_tdata(n3_tdata), .b_tlast(n3_tlast), .b_tvalid(n3_tvalid), .b_tready(n3_tready),
      .c_tdata(c_tdata), .c_tlast(c_tlast), .c_tvalid(c_tvalid), .c_tready(c_tready),
      .p_tdata(p_tdata), .p_tlast(p_tlast), .p_tvalid(p_tvalid), .p_tready(p_tready));
   
endmodule // pfb_stage
