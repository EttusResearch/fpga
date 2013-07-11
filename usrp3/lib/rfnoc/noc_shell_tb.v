//
// Copyright 2012-2013 Ettus Research LLC
//


module noc_shell_tb();
   
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
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_0
     (.clk(clk), .reset(reset),
      .i_tdata(noco_tdata[0]), .i_tlast(noco_tlast[0]), .i_tvalid(noco_tvalid[0]), .i_tready(noco_tready[0]),
      .o_tdata(noci_tdata[0]), .o_tlast(noci_tlast[0]), .o_tvalid(noci_tvalid[0]), .o_tready(noci_tready[0]),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(1'b1), // unused port
      .str_src_tdata(src_tdata), .str_src_tlast(src_tlast), .str_src_tvalid(src_tvalid), .str_src_tready(src_tready)
      );

   wire [63:0] pass_tdata;
   wire        pass_tlast, pass_tvalid, pass_tready;
   
   // Passthrough on port 1
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_1
     (.clk(clk), .reset(reset),
      .i_tdata(noco_tdata[1]), .i_tlast(noco_tlast[1]), .i_tvalid(noco_tvalid[1]), .i_tready(noco_tready[1]),
      .o_tdata(noci_tdata[1]), .o_tlast(noci_tlast[1]), .o_tvalid(noci_tvalid[1]), .o_tready(noci_tready[1]),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(pass_tdata), .str_sink_tlast(pass_tlast), .str_sink_tvalid(pass_tvalid), .str_sink_tready(pass_tready),
      .str_src_tdata(pass_tdata), .str_src_tlast(pass_tlast), .str_src_tvalid(pass_tvalid), .str_src_tready(pass_tready)
      );

   // Dumper on port 2
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_2
     (.clk(clk), .reset(reset),
      .i_tdata(noco_tdata[2]), .i_tlast(noco_tlast[2]), .i_tvalid(noco_tvalid[2]), .i_tready(noco_tready[2]),
      .o_tdata(noci_tdata[2]), .o_tlast(noci_tlast[2]), .o_tvalid(noci_tvalid[2]), .o_tready(noci_tready[2]),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(dst_tdata), .str_sink_tlast(dst_tlast), .str_sink_tvalid(dst_tvalid), .str_sink_tready(dst_tready),
      .str_src_tdata(64'd0), .str_src_tlast(1'd0), .str_src_tvalid(1'b0), .str_src_tready() // unused port
      );

   // Control Source on port 3
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_3
     (.clk(clk), .reset(reset),
      .i_tdata(noco_tdata[3]), .i_tlast(noco_tlast[3]), .i_tvalid(noco_tvalid[3]), .i_tready(noco_tready[3]),
      .o_tdata(noci_tdata[3]), .o_tlast(noci_tlast[3]), .o_tvalid(noci_tvalid[3]), .o_tready(noci_tready[3]),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(1'b1), // unused port
      .str_src_tdata(64'd0), .str_src_tlast(1'd0), .str_src_tvalid(1'b0), .str_src_tready() // unused port
      );
   
   task SetXbar;
      input [15:0] start_reg;
      input [7:0]  start_val;
      
      begin
	 repeat (PORTS)
	   begin
	      repeat (4)
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
	 src_tdata <= { flags, seqnum, len*16'd2+16'd2, sid };
	 src_tlast <= 0;
	 src_tvalid <= 1;
	 @(posedge clk);
	 src_tdata <= data;
	 repeat(len-1)
	   begin
	      @(posedge clk);
	      src_tdata <= src_tdata + 64'd1;
	   end
	 src_tlast <= 1;
	 @(posedge clk);
	 src_tvalid <= 0;
	 @(posedge clk);
      end
   endtask // SendPacket
   
   initial
     begin
	src_tdata <= 64'd0;
	src_tlast <= 1'b0;
	src_tvalid <= 1'b0;
	dst_tready <= 1'b1;
	@(negedge reset);
	@(posedge clk);
	SetXbar(256,0);
	
	@(posedge clk);
	SendPacket(4'h8, 12'd0, 16'd1, 32'h0001_0004, {32'h3, 32'h8000_0001}); // Command packet to set up flow control
	#10000;
	SendPacket(4'h8, 12'd0, 16'd1, 32'h0001_0008, {32'h3, 32'h8000_0001}); // Command packet to set up flow control
	#10000;
	SendPacket(4'h0, 12'd0, 16'd10, 32'h0003_0006, 64'h0); // data packet
     end

endmodule // noc_shell_tb
