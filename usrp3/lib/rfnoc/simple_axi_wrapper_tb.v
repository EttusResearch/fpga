//
// Copyright 2012-2013 Ettus Research LLC
//


module simple_axi_wrapper_tb();
   
   xlnx_glbl glbl (.GSR(),.GTS());
   
   localparam STR_SINK_FIFOSIZE = 9;
      
   reg clk, reset;
   always
     #100 clk = ~clk;

   initial clk = 0;
   initial reset = 1;
   initial #1000 reset = 0;
   
   initial $dumpfile("simple_axi_wrapper_tb.vcd");
   initial $dumpvars(0,simple_axi_wrapper_tb);

   initial #1000000 $finish;

   wire [31:0] set_data;
   wire [7:0]  set_addr;
   wire        set_stb;

   wire [63:0] noci_tdata[PORTS-1:0];
   wire        noci_tlast[PORTS-1:0];
   wire        noci_tvalid[PORTS-1:0];
   wire        noci_tready[PORTS-1:0];

   wire [63:0] noco_tdata[PORTS-1:0];
   wire        noco_tlast[PORTS-1:0];
   wire        noco_tvalid[PORTS-1:0];
   wire        noco_tready[PORTS-1:0];

   reg [63:0]  src_tdata;
   reg 	       src_tlast, src_tvalid;
   wire        src_tready;

   reg [63:0]  cmdout_tdata;
   reg 	       cmdout_tlast, cmdout_tvalid;
   wire        cmdout_tready;

   localparam PORTS = 4;

   // FIR filter on port 1
   wire [31:0] set_data_1;
   wire [7:0]  set_addr_1;
   wire        set_stb_1;
   wire [63:0] s1o_tdata, s1i_tdata;
   wire        s1o_tlast, s1i_tlast, s1o_tvalid, s1i_tvalid, s1o_tready, s1i_tready;
   
   wire [31:0] pre_tdata, post_tdata;
   wire        pre_tlast, post_tlast, pre_tvalid, post_tvalid, pre_tready, post_tready;
   
   simple_axi_wrapper #(.BASE(8)) axi_wrapper_ce1
     (.clk(clk), .reset(reset),
      .set_stb(set_stb_1), .set_addr(set_addr_1), .set_data(set_data_1),
      .i_tdata(src_tdata), .i_tlast(src_tlast), .i_tvalid(src_tvalid), .i_tready(src_tready),
      .o_tdata(s1i_tdata), .o_tlast(s1i_tlast), .o_tvalid(s1i_tvalid), .o_tready(s1i_tready),
      .m_axis_data_tdata(pre_tdata),
      .m_axis_data_tlast(pre_tlast),
      .m_axis_data_tvalid(pre_tvalid),
      .m_axis_data_tready(pre_tready),
      .s_axis_data_tdata(post_tdata),
      .s_axis_data_tlast(post_tlast),
      .s_axis_data_tvalid(post_tvalid),
      .s_axis_data_tready(post_tready)
      );

   axi_fifo #(.WIDTH(33)) afifo
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({pre_tlast,pre_tdata}), .i_tvalid(pre_tvalid), .i_tready(pre_tready),
      .o_tdata({post_tlast,post_tdata}), .o_tvalid(post_tvalid), .o_tready(post_tready));

   assign s1i_tready = 1'b1;
   

      /*
   simple_fir simple_fir
     (.aresetn(clk), .aclk(reset),
      .s_axis_data_tvalid(pre_tvalid),
      .s_axis_data_tready(pre_tready),
      .s_axis_data_tlast(pre_tlast),
      .s_axis_data_tdata(pre_tdata),
      .m_axis_data_tvalid(post_tvalid),
      .m_axis_data_tready(post_tready),
      .m_axis_data_tlast(post_tlast),
      .m_axis_data_tdata(post_tdata),
      .s_axis_config_tvalid(1'b0), .s_axis_reload_tvalid(1'b0)
      );
      */
   
   task SendPacket;
      input [3:0]  flags;
      input [11:0] seqnum;
      input [15:0] len;
      input [31:0] sid;
      input [63:0] data;
      
      begin
	 @(posedge clk);
	 src_tdata <= { flags, seqnum, len*16'd8+16'd8, sid };
	 src_tlast <= 0;
	 src_tvalid <= 1;
	 @(posedge clk);
	 while(~src_tready)
	   @(posedge clk);
	 src_tdata <= data;
	 repeat(len-1)
	   begin
	      @(posedge clk);
	      while(~src_tready)
		@(posedge clk);
	      src_tdata <= src_tdata + 64'd1;
	   end
	 src_tlast <= 1;
	 @(posedge clk);
	 while(~src_tready)
	   @(posedge clk);
	 src_tvalid <= 0;
	 @(posedge clk);
      end
   endtask // SendPacket
   
   task SendCtrlPacket;
      input [11:0] seqnum;
      input [31:0] sid;
      input [63:0] data;
      
      begin
	 @(posedge clk);
	 cmdout_tdata <= { 4'h8, seqnum, 16'h16, sid };
	 cmdout_tlast <= 0;
	 cmdout_tvalid <= 1;
	 while(~cmdout_tready) #1;
	 
	 @(posedge clk);
	 cmdout_tdata <= data;
	 cmdout_tlast <= 1;
	 while(~cmdout_tready) #1;
	 
	 @(posedge clk);
	 cmdout_tvalid <= 0;
	 @(posedge clk);
      end
   endtask // SendCtrlPacket
   
   initial
     begin
	src_tdata <= 64'd0;
	src_tlast <= 1'b0;
	src_tvalid <= 1'b0;
	cmdout_tdata <= 64'd0;
	cmdout_tlast <= 1'b0;
	cmdout_tvalid <= 1'b0;
	@(negedge reset);
	@(posedge clk);
	
	@(posedge clk);
	// Port 0
	SendCtrlPacket(12'd0, 32'h0003_0000, {32'h0, 32'h0000_0003}); // Command packet to set up source control window size
	SendCtrlPacket(12'd0, 32'h0003_0000, {32'h1, 32'h0000_0001}); // Command packet to set up source control window enable
	SendCtrlPacket(12'd0, 32'h0003_0000, {32'h3, 32'h8000_0001}); // Command packet to set up flow control
	#10000;
	// Port 1
	SendCtrlPacket(12'd0, 32'h0003_0001, {32'h0, 32'h0000_0003}); // Command packet to set up source control window size
	SendCtrlPacket(12'd0, 32'h0003_0001, {32'h1, 32'h0000_0001}); // Command packet to set up source control window enable
	SendCtrlPacket(12'd0, 32'h0003_0001, {32'h3, 32'h8000_0001}); // Command packet to set up flow control
	SendCtrlPacket(12'd0, 32'h0003_0001, {32'h8, 32'h0001_0002}); // Rewrite SID, send on to port 2
	#10000;
	// Port 2
	SendCtrlPacket(12'd0, 32'h0003_0002, {32'h0, 32'h0000_0003}); // Command packet to set up source control window size
	SendCtrlPacket(12'd0, 32'h0003_0002, {32'h1, 32'h0000_0001}); // Command packet to set up source control window enable
	SendCtrlPacket(12'd0, 32'h0003_0002, {32'h3, 32'h8000_0001}); // Command packet to set up flow control

	#10000;
	SendPacket(4'h0, 12'd0, 16'd250, 32'h0000_0001, 64'hAAAA_AAAA_0000_0000); // data packet
	SendPacket(4'h0, 12'd1, 16'd250, 32'h0000_0001, 64'hBBBB_BBBB_0000_0000); // data packet
	SendPacket(4'h0, 12'd2, 16'd250, 32'h0000_0001, 64'hCCCC_CCCC_0000_0000); // data packet
	SendPacket(4'h0, 12'd3, 16'd250, 32'h0000_0001, 64'hDDDD_DDDD_0000_0000); // data packet
	SendPacket(4'h0, 12'd4, 16'd250, 32'h0000_0001, 64'hEEEE_EEEE_0000_0000); // data packet
	SendPacket(4'h0, 12'd5, 16'd250, 32'h0000_0001, 64'hFFFF_FFFF_0000_0000); // data packet
	SendPacket(4'h0, 12'd6, 16'd250, 32'h0000_0001, 64'h2222_2222_0000_0000); // data packet
     end

endmodule // simple_axi_wrapper_tb
