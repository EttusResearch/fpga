//
// Copyright 2012-2013 Ettus Research LLC
//


module noc_shell_tb();
   localparam STR_SINK_FIFOSIZE = 9;
      
   reg clk, reset;
   always
     #100 clk = ~clk;

   initial clk = 0;
   initial reset = 1;
   initial #1000 reset = 0;
   
   initial $dumpfile("noc_shell_tb.vcd");
   initial $dumpvars(0,noc_shell_tb);

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

   wire [63:0] dst_tdata;
   wire        dst_tlast, dst_tvalid;
   reg 	       dst_tready;
 	       
   localparam PORTS = 4;

   reg 	       set_stb_xbar;
   reg [15:0]  set_addr_xbar;
   reg [31:0]  set_data_xbar;

   axi_crossbar #(.FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(PORTS), .NUM_OUTPUTS(PORTS)) crossbar
     (.clk(clk), .reset(reset), .clear(1'b0),
      .local_addr(8'd0),
      .pkt_present({noci_tvalid[3],noci_tvalid[2],noci_tvalid[1],noci_tvalid[0]}),
      
      .i_tdata({noci_tdata[3],noci_tdata[2],noci_tdata[1],noci_tdata[0]}),
      .i_tlast({noci_tlast[3],noci_tlast[2],noci_tlast[1],noci_tlast[0]}),
      .i_tvalid({noci_tvalid[3],noci_tvalid[2],noci_tvalid[1],noci_tvalid[0]}),
      .i_tready({noci_tready[3],noci_tready[2],noci_tready[1],noci_tready[0]}),

      .o_tdata({noco_tdata[3],noco_tdata[2],noco_tdata[1],noco_tdata[0]}),
      .o_tlast({noco_tlast[3],noco_tlast[2],noco_tlast[1],noco_tlast[0]}),
      .o_tvalid({noco_tvalid[3],noco_tvalid[2],noco_tvalid[1],noco_tvalid[0]}),
      .o_tready({noco_tready[3],noco_tready[2],noco_tready[1],noco_tready[0]}),

      .set_stb(set_stb_xbar), .set_addr(set_addr_xbar), .set_data(set_data_xbar),
      .rb_rd_stb(1'b0), .rb_addr(0), .rb_data());
   
   // Generator on port 0
   noc_shell #(.STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) noc_shell_0
     (.bus_clk(clk), .bus_rst(reset),
      .i_tdata(noco_tdata[0]), .i_tlast(noco_tlast[0]), .i_tvalid(noco_tvalid[0]), .i_tready(noco_tready[0]),
      .o_tdata(noci_tdata[0]), .o_tlast(noci_tlast[0]), .o_tvalid(noci_tvalid[0]), .o_tready(noci_tready[0]),
      .clk(clk), .reset(reset),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .cmdout_tdata(64'h0), .cmdout_tlast(1'b0), .cmdout_tvalid(1'b0), .cmdout_tready(),
      .ackin_tdata(), .ackin_tlast(), .ackin_tvalid(), .ackin_tready(1'b1),
      
      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(1'b1), // unused port
      .str_src_tdata(src_tdata), .str_src_tlast(src_tlast), .str_src_tvalid(src_tvalid), .str_src_tready(src_tready)
      );

   // Converter on port 1
   wire [31:0] set_data_1;
   wire [7:0]  set_addr_1;
   wire        set_stb_1;
   wire [63:0] s1o_tdata, s1i_tdata;
   wire        s1o_tlast, s1i_tlast, s1o_tvalid, s1i_tvalid, s1o_tready, s1i_tready;
   
   noc_shell #(.STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) noc_shell_1
     (.bus_clk(clk), .bus_rst(reset),
      .i_tdata(noco_tdata[1]), .i_tlast(noco_tlast[1]), .i_tvalid(noco_tvalid[1]), .i_tready(noco_tready[1]),
      .o_tdata(noci_tdata[1]), .o_tlast(noci_tlast[1]), .o_tvalid(noci_tvalid[1]), .o_tready(noci_tready[1]),
      .clk(clk), .reset(reset),
      .set_data(set_data_1), .set_addr(set_addr_1), .set_stb(set_stb_1), .rb_data(64'd0),

      .cmdout_tdata(64'h0), .cmdout_tlast(1'b0), .cmdout_tvalid(1'b0), .cmdout_tready(),
      .ackin_tdata(), .ackin_tlast(), .ackin_tvalid(), .ackin_tready(1'b1),
      
      .str_sink_tdata(s1o_tdata), .str_sink_tlast(s1o_tlast), .str_sink_tvalid(s1o_tvalid), .str_sink_tready(s1o_tready),
      .str_src_tdata(s1i_tdata), .str_src_tlast(s1i_tlast), .str_src_tvalid(s1i_tvalid), .str_src_tready(s1i_tready)
      );

   chdr_8sc_to_16sc #(.BASE(8)) conv_8_16
     (.clk(clk), .reset(reset),
      .set_stb(set_stb_1), .set_addr(set_addr_1), .set_data(set_data_1),
      .i_tdata(s1o_tdata), .i_tlast(s1o_tlast), .i_tvalid(s1o_tvalid), .i_tready(s1o_tready),
      .o_tdata(s1i_tdata), .o_tlast(s1i_tlast), .o_tvalid(s1i_tvalid), .o_tready(s1i_tready));
      
   // Dumper on port 2
   noc_shell #(.STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) noc_shell_2
     (.bus_clk(clk), .bus_rst(reset),
      .i_tdata(noco_tdata[2]), .i_tlast(noco_tlast[2]), .i_tvalid(noco_tvalid[2]), .i_tready(noco_tready[2]),
      .o_tdata(noci_tdata[2]), .o_tlast(noci_tlast[2]), .o_tvalid(noci_tvalid[2]), .o_tready(noci_tready[2]),
      
      .clk(clk), .reset(reset),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .cmdout_tdata(64'h0), .cmdout_tlast(1'b0), .cmdout_tvalid(1'b0), .cmdout_tready(),
      .ackin_tdata(), .ackin_tlast(), .ackin_tvalid(), .ackin_tready(1'b1),
      
      .str_sink_tdata(dst_tdata), .str_sink_tlast(dst_tlast), .str_sink_tvalid(dst_tvalid), .str_sink_tready(dst_tready),
      .str_src_tdata(64'd0), .str_src_tlast(1'd0), .str_src_tvalid(1'b0), .str_src_tready() // unused port
      );

   // Control Source on port 3
   noc_shell #(.STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) noc_shell_3
     (.bus_clk(clk), .bus_rst(reset),
      .i_tdata(noco_tdata[3]), .i_tlast(noco_tlast[3]), .i_tvalid(noco_tvalid[3]), .i_tready(noco_tready[3]),
      .o_tdata(noci_tdata[3]), .o_tlast(noci_tlast[3]), .o_tvalid(noci_tvalid[3]), .o_tready(noci_tready[3]),
      
      .clk(clk), .reset(reset),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
      .ackin_tdata(), .ackin_tlast(), .ackin_tvalid(), .ackin_tready(1'b1),
      
      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(1'b1), // unused port
      .str_src_tdata(64'd0), .str_src_tlast(1'd0), .str_src_tvalid(1'b0), .str_src_tready() // unused port
      );
   
   task SetXbar;
      input [15:0] start_reg;
      input [7:0]  start_val;
      
      begin
	 repeat (PORTS)
	   begin
	      repeat (1)
		begin
		   SetXbar_reg(start_reg,start_val);
		   start_reg <= start_reg + 1;
		   @(posedge clk);
		end
	      start_val <= start_val + 1;
	      @(posedge clk);
	   end
      end
   endtask // SetXbar
   
   task SetXbar_reg;
      input [15:0] addr;
      input [31:0] data;
      begin
	 @(posedge clk);
	 set_stb_xbar <= 1'b1;
	 set_addr_xbar <= addr;
	 set_data_xbar <= data;
	 @(posedge clk);
	 set_stb_xbar <= 1'b0;
	 @(posedge clk);
      end
   endtask // set_xbar
   
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
	dst_tready <= 1'b1;
	@(negedge reset);
	@(posedge clk);
	SetXbar(256,0);
	
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

endmodule // noc_shell_tb
