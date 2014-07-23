
// Copyright 2014 Ettus Research

// Assumes 32-bit elements (like 16cs) carried over AXI
// User block controls packet sizes with tlast, numbers of packets do not need to coincide
// timestamps and EOB will be a bit harder to handle

module axi_wrapper
  #(parameter BASE=0)
   (input clk, input reset,

    // To NoC Shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
    
    // To AXI IP
    output [31:0] m_axis_data_tdata, output m_axis_data_tlast, output m_axis_data_tvalid, input m_axis_data_tready,
    input [31:0] s_axis_data_tdata, input s_axis_data_tlast, input s_axis_data_tvalid, output s_axis_data_tready,
    output [31:0] m_axis_config_tdata, output m_axis_config_tlast, output m_axis_config_tvalid, input m_axis_config_tready
    );

   // Set next destination in chain
   wire [15:0] 	 next_destination;
   wire 	 send_time_in, send_time_out;
   wire [63:0] 	 vita_time_in, vita_time_out;
   wire [31:0] 	 sid_in, sid_out;
   wire 	 eob_in, eob_out;
   wire 	 sof_in;
   
   setting_reg #(.my_addr(BASE), .width(16)) new_destination
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(next_destination[15:0]));

   chdr_deframer chdr_deframer
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(m_axis_data_tdata), .o_tlast(m_axis_data_tlast), .o_tvalid(m_axis_data_tvalid), .o_tready(m_axis_data_tready),
      .send_time(send_time_in), .vita_time(vita_time_in), .sid(sid_in), .eob(eob_in), .sof(sof_in));

   wire [15:0] 	 my_sid;
   assign sid_out = { my_sid, next_destination };
   
   axi_fifo_short #(.WIDTH(82)) header_fifo
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({send_time_in, vita_time_in, sid_in[15:0], eob_in}), .i_tvalid(sof_in&m_axis_data_tvalid&m_axis_data_tready), .i_tready(),
      .o_tdata({send_time_out, vita_time_out, my_sid, eob_out}), .o_tvalid(), .o_tready(s_axis_data_tlast&s_axis_data_tvalid&s_axis_data_tready));
      
   chdr_framer #(.SIZE(10)) chdr_framer
     (.clk(clk), .reset(reset), .clear(1'b0),
      .send_time(send_time_out), .vita_time(vita_time_out), .sid(sid_out), .eob(eob_out),
      .i_tdata(s_axis_data_tdata), .i_tlast(s_axis_data_tlast), .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));
          
   // Simple single line axi stream to config cores like FFT and FIR from Xilinx
   // FIXME need to make sure we don't overrun this if core can backpressure us
   // Write to BASE+8 is normal, BASE+9 asserts tlast
   axi_fifo_short #(.WIDTH(33)) config_stream
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({(set_addr == (BASE+9)),set_data}), .i_tvalid(set_stb & ((set_addr == (BASE+8))|(set_addr == (BASE+9)))), .i_tready(),
      .o_tdata({m_axis_config_tlast,m_axis_config_tdata}), .o_tvalid(m_axis_config_tvalid), .o_tready(m_axis_config_tready));
      
endmodule // axi_wrapper
