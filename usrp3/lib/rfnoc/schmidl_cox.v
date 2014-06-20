
module schmidl_cox
  (input clk, input reset, input clear,
   input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
   output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [31:0] 	 n0_tdata, n1_tdata, n2_tdata, n3_tdata, n4_tdata, n5_tdata, n6_tdata, n7_tdata, n8_tdata, n9_tdata, n10_tdata, n11_tdata, n12_tdata;
   wire  	 n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n6_tlast, n7_tlast, n8_tlast, n9_tlast, n10_tlast, n11_tlast, n12_tlast;
   wire  	 n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n6_tvalid, n7_tvalid, n8_tvalid, n9_tvalid, n10_tvalid, n11_tvalid, n12_tvalid;
   wire  	 n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n6_tready, n7_tready, n8_tready, n9_tready, n10_tready, n11_tready, n12_tready;

   split_stream #(.WIDTH(32), .ACTIVE_MASK(4'b0011)) split_head
     (.i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o0_tdata(n0_tdata), .o0_tlast(n0_tlast), .o0_tvalid(n0_tvalid), .o0_tready(n0_tready),
      .o1_tdata(n1_tdata), .o1_tlast(n1_tlast), .o1_tvalid(n1_tvalid), .o1_tready(n1_tready));
   
   split_stream #(.WIDTH(32), .ACTIVE_MASK(4'b0011)) split_delayed
     (.i_tdata(n3_tdata), .i_tlast(n3_tlast), .i_tvalid(n3_tvalid), .i_tready(n3_tready),
      .o0_tdata(n2_tdata), .o0_tlast(n2_tlast), .o0_tvalid(n2_tvalid), .o0_tready(n2_tready),
      .o1_tdata(n12_tdata), .o1_tlast(n12_tlast), .o1_tvalid(n12_tvalid), .o1_tready(n12_tready));
   
   delay #(.MAX_LEN_LOG2(8), .WIDTH(32)) delay_input
     (.clk(clk), .reset(reset), .clear(clear),
      .len(16),
      .i_tdata(n0_tdata), .i_tlast(n0_tlast), .i_tvalid(n0_tvalid), .i_tready(n0_tready),
      .o_tdata(n3_tdata), .o_tlast(n3_tlast), .o_tvalid(n3_tvalid), .o_tready(n3_tready));

   conj #(.WIDTH(16)) conj
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
      .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

   complex_multiplier cmult1
     (.aclk(clk), .aresetn(~reset),
      .s_axis_a_tdata(n1_tdata), .s_axis_a_tlast(n1_tlast), .s_axis_a_tvalid(n1_tvalid), .s_axis_a_tready(n1_tready),
      .s_axis_b_tdata(n4_tdata), .s_axis_b_tlast(n4_tlast), .s_axis_b_tvalid(n4_tvalid), .s_axis_b_tready(n4_tready),
      .s_axis_ctrl_tdata(0), .s_axis_ctrl_tvalid(1'b1), .s_axis_ctrl_tready(),
      .m_axis_dout_tdata(n5_tdata), .m_axis_dout_tlast(n5_tlast), .m_axis_dout_tvalid(n5_tvalid), .m_axis_dout_tready(n5_tready));

   wire [23:0] 	 i_ma, q_ma;
   assign n6_tdata = {i_ma[23:8], q_ma[23:8]};
   
   // moving average of I for S&C metric
   moving_sum #(.MAX_LEN_LOG2(8), .WIDTH(16)) ma_i
     (.clk(clk), .reset(reset), .clear(clear),
      .len(144),
      .i_tdata(n5_tdata[31:16]), .i_tlast(n5_tlast), .i_tvalid(n5_tvalid), .i_tready(n5_tready),
      .o_tdata(i_ma), .o_tlast(n6_tlast), .o_tvalid(n6_tvalid), .o_tready(n6_tready));
      
   // moving average of Q for S&C metric
   moving_sum #(.MAX_LEN_LOG2(8), .WIDTH(16)) ma_q
     (.clk(clk), .reset(reset), .clear(clear),
      .len(144),
      .i_tdata(n5_tdata[15:0]), .i_tlast(n5_tlast), .i_tvalid(n5_tvalid), .i_tready(),
      .o_tdata(q_ma), .o_tlast(), .o_tvalid(), .o_tready(n6_tready));

   // magnitude of delay conjugate multiply
   complex_to_magphase c2magphase 
     (.aclk(clk), .aresetn(~reset),
      .s_axis_cartesian_tdata(n6_tdata), .s_axis_cartesian_tlast(n6_tlast), .s_axis_cartesian_tvalid(n6_tvalid), .s_axis_cartesian_tready(n6_tready),
      .m_axis_dout_tdata(n7_tdata), .m_axis_dout_tlast(n7_tlast), .m_axis_dout_tvalid(n7_tvalid), .m_axis_dout_tready(n7_tready));
   
   // extract magnitude from cordic
   wire [15:0] n7_tdata_mag;
   wire [15:0] n7_tdata_phase;
   assign n7_tdata_mag = {n7_tdata[15:0]};
   assign n7_tdata_phase = {n7_tdata[31:16]};
   
   // magnitude of input signal conjugate multiply
   complex_to_magsq #(.WIDTH(16)) cmag2
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(n12_tdata), .i_tlast(n12_tlast), .i_tvalid(n12_tvalid), .i_tready(n12_tready),
      .o_tdata(n8_tdata), .o_tlast(n8_tlast), .o_tvalid(n8_tvalid), .o_tready(n8_tready));

   wire [39:0] 	 n9_unscaled;
   assign n9_tdata = n9_unscaled[39:8];
   
   // moving average of input signal power
   moving_sum #(.MAX_LEN_LOG2(8), .WIDTH(32)) ma_pow
     (.clk(clk), .reset(reset), .clear(clear),
      .len(144),
      .i_tdata(n8_tdata), .i_tlast(n8_tlast), .i_tvalid(n8_tvalid), .i_tready(n8_tready),
      .o_tdata(n9_unscaled), .o_tlast(n9_tlast), .o_tvalid(n9_tvalid), .o_tready(n9_tready));

   // insert fifo to solve deadlock
   axi_fifo_short #(.WIDTH(33)) fifo1
   (.clk(clk), .reset(reset), .clear(clear),
    .i_tdata({n9_tlast, n9_tdata}), .i_tvalid(n9_tvalid), .i_tready(n9_tready),
    .o_tdata({n11_tlast, n11_tdata}), .o_tvalid(n11_tvalid), .o_tready(n11_tready));
      
   // compare scaled version of lower rail with upper rail to see if it is over the desired threshold ?(in0 < in1*scalar)
   wire burst_detect;
   threshold_scaled #(.WIDTH(32), .SCALAR(131072)) thresh1
    (.clk(clk), .reset(reset), .clear(clear),
     .i0_tdata(n11_tdata), .i0_tlast(n11_tlast), .i0_tvalid(n11_tvalid), .i0_tready(n11_tready),
     .i1_tdata({16'd0, n7_tdata_mag}), .i1_tlast(n7_tlast), .i1_tvalid(n7_tvalid), .i1_tready(n7_tready),
     .o_tdata(burst_detect), .o_tlast(n10_tlast), .o_tvalid(n10_tvalid), .o_tready(n10_tready));
   assign n10_tdata[31:0] = {31'd0, burst_detect};

   assign o_tdata = n10_tdata[31:0];
   assign o_tlast = n10_tlast;
   assign o_tvalid = n10_tvalid;
   assign n10_tready = o_tready;

endmodule // schmidl_cox
