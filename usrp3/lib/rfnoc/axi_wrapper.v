
// Copyright 2014 Ettus Research

// Assumes 32-bit elements (like 16cs) carried over AXI
// User block controls packet sizes with tlast
// simple_mode=1 allows user to ignore chdr stuff, must produce 1 packet for each one consume
// simple_mode=0 user controls all chdr info, must control s_axis_data_tuser

// _tuser bit definitions
//  [127:64] == CHDR header
//    [127:126] == Packet type -- 00 for data, 01 for flow control, 10 for command, 11 for response
//    [125]     == Has time? (0 for no, 1 for time field on next line)
//    [124]     == EOB (end of burst indicator)
//    [123:112] == 12-bit sequence number
//    [111: 96] == 16-bit length in bytes
//    [ 95: 80] == SRC SID (stream ID)
//    [ 79: 64] == DST SID
//  [ 63: 0] == timestamp

module axi_wrapper
  #(parameter SR_AXI_CONFIG_BASE=129,   // AXI configuration bus base, settings bus address range size is 2*NUM_AXI_CONFIG_BUS
    parameter NUM_AXI_CONFIG_BUS=1,     // Number of AXI configuration busses
    parameter CONFIG_BUS_FIFO_DEPTH=5,  // Depth of AXI configuration bus FIFO. Note: AXI configuration bus lacks back pressure.
    parameter SIMPLE_MODE=1)            // 0 = User handles CHDR insertion via tuser signals, 1 = Automatically save / insert CHDR with internal FIFO
   (input clk, input reset,

    input clear_tx_seqnum,
    input [15:0] next_dst,

    // To NoC Shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
    
    // To AXI IP
    output [31:0] m_axis_data_tdata, output [127:0] m_axis_data_tuser, output m_axis_data_tlast, output m_axis_data_tvalid, input m_axis_data_tready,
    input [31:0] s_axis_data_tdata, input [127:0] s_axis_data_tuser, input s_axis_data_tlast, input s_axis_data_tvalid, output s_axis_data_tready,
    
    // Variable number of AXI configuration busses
    output [NUM_AXI_CONFIG_BUS*32-1:0] m_axis_config_tdata,
    output [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tlast,
    output [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tvalid,
    input [NUM_AXI_CONFIG_BUS-1:0] m_axis_config_tready
    );

   // /////////////////////////////////////////////////////////
   // Input side handling, chdr_deframer
   
   chdr_deframer chdr_deframer
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(m_axis_data_tdata), .o_tuser(m_axis_data_tuser), .o_tlast(m_axis_data_tlast), .o_tvalid(m_axis_data_tvalid), .o_tready(m_axis_data_tready));

   // /////////////////////////////////////////////////////////
   // Insert time and burst handling here.  A simple FIFO works only if packets are produced 1-for-1 (they may be of different sizes, though)
   wire [127:0] s_axis_data_tuser_int;
   reg          sof_in = 1'b1;
   wire [127:0] header_fifo_i_tdata  = {m_axis_data_tuser[127:96],m_axis_data_tuser[79:64],next_dst,m_axis_data_tuser[63:0]};
   wire         header_fifo_i_tvalid = sof_in & m_axis_data_tvalid & m_axis_data_tready;

   // Only store header once per packet
   always @(posedge clk)
     if(reset)
       sof_in <= 1'b1;
     else
       if(m_axis_data_tvalid & m_axis_data_tready)
         if(m_axis_data_tlast)
           sof_in <= 1'b1;
         else
           sof_in <= 1'b0;
   
   generate
      if(SIMPLE_MODE)
         begin
            // FIFO 
            axi_fifo_short #(.WIDTH(128)) header_fifo
            (.clk(clk), .reset(reset), .clear(1'b0),
             .i_tdata(header_fifo_i_tdata),
             .i_tvalid(header_fifo_i_tvalid), .i_tready(),
            .o_tdata(s_axis_data_tuser_int), .o_tvalid(), .o_tready(s_axis_data_tlast&s_axis_data_tvalid&s_axis_data_tready));
         end // if (SIMPLE_MODE)
      else
      assign s_axis_data_tuser_int = s_axis_data_tuser;
   endgenerate
   
   // /////////////////////////////////////////////////////////
   // Output side handling, chdr_framer
   chdr_framer #(.SIZE(10)) chdr_framer
     (.clk(clk), .reset(reset), .clear(clear_tx_seqnum),
      .i_tdata(s_axis_data_tdata), .i_tuser(s_axis_data_tuser_int), .i_tlast(s_axis_data_tlast), .i_tvalid(s_axis_data_tvalid), .i_tready(s_axis_data_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

   // /////////////////////////////////////////////////////////
   // Control bus handling
   // FIXME we could put inline control here...
   // Generate additional AXI stream interfaces for configuration. 
   // FIXME need to make sure we don't overrun this if core can backpressure us
   // Write to SR_AXI_CONFIG_BASE+1+2*(CONFIG BUS #) asserts tvalid, SR_AXI_CONFIG_BASE+1+2*(CONFIG BUS #)+1 asserts tvalid & tlast
   genvar k;
   generate
      for (k = 0; k < NUM_AXI_CONFIG_BUS; k = k + 1) begin
         axi_fifo #(.WIDTH(33), .SIZE(CONFIG_BUS_FIFO_DEPTH)) config_stream
           (.clk(clk), .reset(reset), .clear(1'b0),
            .i_tdata({(set_addr == (SR_AXI_CONFIG_BASE+2*k+1)),set_data}),
            .i_tvalid(set_stb & ((set_addr == (SR_AXI_CONFIG_BASE+2*k))|(set_addr == (SR_AXI_CONFIG_BASE+2*k+1)))),
            .i_tready(),
            .o_tdata({m_axis_config_tlast[k],m_axis_config_tdata[32*k+31:32*k]}),
            .o_tvalid(m_axis_config_tvalid[k]),
            .o_tready(m_axis_config_tready[k]));
      end
   endgenerate
   
endmodule // axi_wrapper
