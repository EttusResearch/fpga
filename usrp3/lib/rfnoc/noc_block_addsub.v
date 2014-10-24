
module noc_block_addsub
  #(parameter NOC_ID = 64'hADD0_0000_0000_0000,
    parameter STR_SINK_FIFOSIZE = 11)
   (input bus_clk, input bus_rst,
    input ce_clk, input ce_rst,
    input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
    output [63:0] debug
    );

   localparam MTU = 10;
   
   /////////////////////////////////////////////////////////////
   //
   // RFNoC Shell
   //
   ////////////////////////////////////////////////////////////
   wire [31:0] 	  set_data;
   wire [7:0] 	  set_addr;
   wire 	  set_stb;
   
   wire [63:0] 	  cmdout_tdata, ackin_tdata;
   wire 	  cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;
   
   wire [127:0]   str_sink_tdata, str_src_tdata;
   wire [1:0] 	  str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

   wire [31:0] 	  in_tdata[0:1];
   wire [127:0]   in_tuser[0:1];
   wire [1:0] 	  in_tlast, in_tvalid, in_tready;
   
   wire [31:0] 	  out_tdata[0:1];
   wire [127:0]   out_tuser[0:1], out_tuser_pre[0:1];
   wire [1:0] 	  out_tlast, out_tvalid, out_tready;
   
   wire clear_tx_seqnum;

   noc_shell #(.NOC_ID(NOC_ID),
	       .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE),
	       .MTU(MTU),
	       .INPUT_PORTS(2),
	       .OUTPUT_PORTS(2)) inst_noc_shell
     (.bus_clk(bus_clk), .bus_rst(bus_rst),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
      // Compute Engine Clock Domain
      .clk(ce_clk), .reset(ce_rst),
      // Control Sink
      .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .rb_data(64'd0),
      // Control Source
      .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
      .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
      // Stream Sink
      .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
      // Stream Source
      .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
      .clear_tx_seqnum(clear_tx_seqnum),
      .debug(debug));

   genvar 	  i;
   generate
      for(i=0; i<2; i=i+1)
	chdr_deframer deframer
	    (.clk(ce_clk), .reset(ce_rst), .clear(1'b0),
	     .i_tdata(str_sink_tdata[i*64+63:i*64]), .i_tlast(str_sink_tlast[i]), .i_tvalid(str_sink_tvalid[i]), .i_tready(str_sink_tready[i]),
	     .o_tdata(in_tdata[i]), .o_tuser(in_tuser[i]), .o_tlast(in_tlast[i]), .o_tvalid(in_tvalid[i]), .o_tready(in_tready[i]));
   endgenerate
   
   addsub #(.WIDTH(16)) inst_addsub
     (.clk(ce_clk), .reset(ce_rst),
      .i0_tdata(in_tdata[0]), .i0_tlast(in_tlast[0]), .i0_tvalid(in_tvalid[0]), .i0_tready(in_tready[0]),
      .i1_tdata(in_tdata[1]), .i1_tlast(in_tlast[1]), .i1_tvalid(in_tvalid[1]), .i1_tready(in_tready[1]),
      .sum_tdata(out_tdata[0]), .sum_tlast(out_tlast[0]), .sum_tvalid(out_tvalid[0]), .sum_tready(out_tready[0]),
      .diff_tdata(out_tdata[1]), .diff_tlast(out_tlast[1]), .diff_tvalid(out_tvalid[1]), .diff_tready(out_tready[1]));

   // throw away tuser on 2nd input, just use first
   // FIXME we should probably stall the chain if this isn't ready for the last line of output

   wire [15:0] 	  next_destination[0:1];
   localparam SR_NEXT_DST_BASE = 128;
   
   setting_reg #(.my_addr(SR_NEXT_DST_BASE), .width(16)) next_destination_0
     (.clk(ce_clk), .rst(ce_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(next_destination[0]));

   setting_reg #(.my_addr(SR_NEXT_DST_BASE+1), .width(16)) next_destination_1
     (.clk(ce_clk), .rst(ce_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(next_destination[1]));

   split_stream_fifo #(.WIDTH(128), .ACTIVE_MASK(4'b0011)) tuser_splitter
     (.clk(ce_clk), .reset(ce_rst), .clear(1'b0),
      .i_tdata(in_tuser[0]), .i_tlast(1'b0), .i_tvalid(in_tvalid[0] & in_tlast[0]), .i_tready(),
      .o0_tdata(out_tuser_pre[0]), .o0_tlast(), .o0_tvalid(), .o0_tready(out_tlast[0] & out_tready[0]),
      .o1_tdata(out_tuser_pre[1]), .o1_tlast(), .o1_tvalid(), .o1_tready(out_tlast[1] & out_tready[1]),
      .o2_tready(1'b1), .o3_tready(1'b1));

   assign out_tuser[0] = { out_tuser_pre[0][127:96], out_tuser_pre[0][79:68], 4'b0000, next_destination[0], out_tuser_pre[0][63:0] };
   assign out_tuser[1] = { out_tuser_pre[1][127:96], out_tuser_pre[1][79:68], 4'b0001, next_destination[1], out_tuser_pre[1][63:0] };
   
   genvar 	  j;
   generate
      for(j=0; j<2; j=j+1)
	chdr_framer #(.SIZE(MTU)) framer
	    (.clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum),
	     .i_tdata(out_tdata[j]), .i_tuser(out_tuser[j]), .i_tlast(out_tlast[j]), .i_tvalid(out_tvalid[j]), .i_tready(out_tready[j]),
	     .o_tdata(str_src_tdata[j*64+63:j*64]), .o_tlast(str_src_tlast[j]), .o_tvalid(str_src_tvalid[j]), .o_tready(str_src_tready[j]));
   endgenerate

endmodule // noc_block_addsub
