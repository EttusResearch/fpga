//
// Copyright 2014 Ettus Research LLC
//

module window
  #(parameter SR_WINDOW_SIZE=0,
    parameter MAX_LOG2_OF_WINDOW_SIZE = 10)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [31:0] m_axis_config_tdata, input m_axis_config_tlast, input m_axis_config_tvalid, output m_axis_config_tready,
    input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);
   
   wire [31:0] 	  n0_tdata, n1_tdata, n3_tdata, n4_tdata, n5_tdata, n6_tdata, n7_tdata, n8_tdata, n9_tdata;
   wire 	  n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n6_tlast, n7_tlast, n8_tlast, n9_tlast;
   wire 	  n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n6_tvalid, n7_tvalid, n8_tvalid, n9_tvalid;
   wire 	  n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n6_tready, n7_tready, n8_tready, n9_tready;
   
   wire [MAX_LOG2_OF_WINDOW_SIZE-1:0] n2_tdata;
   wire [MAX_LOG2_OF_WINDOW_SIZE-1:0] max;
   
   setting_reg #(.my_addr(SR_WINDOW_SIZE), .width(MAX_LOG2_OF_WINDOW_SIZE)) reg_max
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data), .out(max));

   // FIXME need to set max
   // FIXME need to set coeffs into ram
   split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011)) split_head
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o0_tdata(n0_tdata), .o0_tlast(n0_tlast), .o0_tvalid(n0_tvalid), .o0_tready(n0_tready),
      .o1_tdata(n1_tdata), .o1_tlast(n1_tlast), .o1_tvalid(n1_tvalid), .o1_tready(n1_tready),
      .o2_tready(1'b0), .o3_tready(1'b0));

   counter #(.WIDTH(MAX_LOG2_OF_WINDOW_SIZE)) addr_gen
     (.clk(clk), .reset(reset), .clear(clear),
      .max(max),
      .i_tlast(n1_tlast), .i_tvalid(n1_tvalid), .i_tready(n1_tready),
      .o_tdata(n2_tdata), .o_tlast(n2_tlast), .o_tvalid(n2_tvalid), .o_tready(n2_tready));

   ram_to_fifo #(.DWIDTH(32), .AWIDTH(MAX_LOG2_OF_WINDOW_SIZE)) window_coeffs
     (.clk(clk), .reset(reset), .clear(clear),
      .config_tdata(m_axis_config_tdata), .config_tlast(m_axis_config_tlast), .config_tvalid(m_axis_config_tvalid), .config_tready(m_axis_config_tready),
      .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n3_tdata), .o_tlast(n3_tlast), .o_tvalid(n3_tvalid), .o_tready(n3_tready));
         
   // complex_mult assumes Q is high bits, I is low.  This is the opposite of our standard...
   complex_multiplier cmult1
     (.aclk(clk), .aresetn(~reset),
      .s_axis_a_tdata({n3_tdata[15:0], n3_tdata[31:16]}), .s_axis_a_tlast(n3_tlast), .s_axis_a_tvalid(n3_tvalid), .s_axis_a_tready(n3_tready),
      .s_axis_b_tdata({n0_tdata[15:0], n0_tdata[31:16]}), .s_axis_b_tlast(n0_tlast), .s_axis_b_tvalid(n0_tvalid), .s_axis_b_tready(n0_tready),
      .s_axis_ctrl_tdata(8'd0), .s_axis_ctrl_tvalid(1'b1), .s_axis_ctrl_tready(),
      .m_axis_dout_tdata({o_tdata[15:0], o_tdata[31:16]}), .m_axis_dout_tlast(o_tlast), .m_axis_dout_tvalid(o_tvalid), .m_axis_dout_tready(o_tready));

endmodule // window
