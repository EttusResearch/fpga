//
// Copyright 2014 Ettus Research LLC
//

module window
  #(parameter SR_WINDOW_SIZE = 0,
    parameter MAX_LOG2_OF_WINDOW_SIZE = 10,
    parameter COEFF_WIDTH = 16)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [COEFF_WIDTH-1:0] m_axis_coeff_tdata, input m_axis_coeff_tlast, input m_axis_coeff_tvalid, output m_axis_coeff_tready,
    input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [31:0]  n0_tdata, n1_tdata, n3_tdata, n4_tdata, n5_tdata, n6_tdata, n7_tdata, n8_tdata, n9_tdata;
   wire         n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n6_tlast, n7_tlast, n8_tlast, n9_tlast;
   wire         n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n6_tvalid, n7_tvalid, n8_tvalid, n9_tvalid;
   wire         n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n6_tready, n7_tready, n8_tready, n9_tready;

   wire [MAX_LOG2_OF_WINDOW_SIZE-1:0] n2_tdata;
   wire [MAX_LOG2_OF_WINDOW_SIZE-1:0] max;

   setting_reg #(.my_addr(SR_WINDOW_SIZE), .width(MAX_LOG2_OF_WINDOW_SIZE)) reg_max
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data), .out(max));

   split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011)) split_head
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o0_tdata(n0_tdata), .o0_tlast(n0_tlast), .o0_tvalid(n0_tvalid), .o0_tready(n0_tready),
      .o1_tdata(n1_tdata), .o1_tlast(n1_tlast), .o1_tvalid(n1_tvalid), .o1_tready(n1_tready),
      .o2_tready(1'b0), .o3_tready(1'b0));

   counter #(.WIDTH(MAX_LOG2_OF_WINDOW_SIZE)) addr_gen
     (.clk(clk), .reset(reset), .clear(clear),
      .max(max),
      .i_tlast(1'b0), .i_tvalid(n1_tvalid), .i_tready(n1_tready),
      .o_tdata(n2_tdata), .o_tlast(n2_tlast), .o_tvalid(n2_tvalid), .o_tready(n2_tready));

   ram_to_fifo #(.DWIDTH(COEFF_WIDTH), .AWIDTH(MAX_LOG2_OF_WINDOW_SIZE)) window_coeffs
     (.clk(clk), .reset(reset), .clear(clear),
      .config_tdata(m_axis_coeff_tdata), .config_tlast(m_axis_coeff_tlast), .config_tvalid(m_axis_coeff_tvalid), .config_tready(m_axis_coeff_tready),
      .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n3_tdata), .o_tlast(n3_tlast), .o_tvalid(n3_tvalid), .o_tready(n3_tready));

   mult_rc #(.WIDTH_REAL(COEFF_WIDTH), .WIDTH_CPLX(16), .WIDTH_P(16), .DROP_TOP_P(6))
   inst_mult_rc (
     .clk(clk), .reset(reset),
     .real_tdata(n3_tdata), .real_tlast(n3_tlast), .real_tvalid(n3_tvalid), .real_tready(n3_tready),
     .cplx_tdata(n0_tdata), .cplx_tlast(n0_tlast), .cplx_tvalid(n0_tvalid), .cplx_tready(n0_tready),
     .p_tdata(o_tdata), .p_tlast(o_tlast), .p_tvalid(o_tvalid), .p_tready(o_tready));

endmodule // window