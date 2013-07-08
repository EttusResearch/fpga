//
// Copyright 2012-2013 Ettus Research LLC
//


module noc_shell_tb();
   
   reg clk, reset;
   always
     #100 clk = ~clk;

   initial clk = 0;
   
   initial $dumpfile("noc_shell_tb.vcd");
   initial $dumpvars(0,noc_shell_tb);

   initial #1000000 $finish;

   wire [63:0] noci0_tdata, noco0_tdata, noci1_tdata, noco1_tdata;
   wire        noci0_tlast, noco0_tlast, noci1_tlast, noco1_tlast;
   wire        noci0_tvalid, noco0_tvalid, noci1_tvalid, noco1_tvalid;
   wire        noci0_tready, noco0_tready, noci1_tready, noco1_tready;

   // Generator
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_0
     (.clk(clk), .reset(reset),
      .noci_tdata(noci0_tdata), .noci_tlast(noci0_tlast), .noci_tvalid(noci0_tvalid), .noci_tready(noci0_tready),
      .noco_tdata(noco0_tdata), .noco_tlast(noco0_tlast), .noco_tvalid(noco0_tvalid), .noco_tready(noco0_tready),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(1'b1),
      .str_src_tdata(), .str_src_tlast(), .str_src_tvalid(), .str_src_tready()
      );

   // Dumper
   noc_shell #(.STR_SINK_FIFOSIZE(10)) noc_shell_1
     (.clk(clk), .reset(reset),
      .noci_tdata(noci1_tdata), .noci_tlast(noci1_tlast), .noci_tvalid(noci1_tvalid), .noci_tready(noci1_tready),
      .noco_tdata(noco1_tdata), .noco_tlast(noco1_tlast), .noco_tvalid(noco1_tvalid), .noco_tready(noco1_tready),
      .set_data(), .set_addr(), .set_stb(), .rb_data(64'd0),

      .str_sink_tdata(), .str_sink_tlast(), .str_sink_tvalid(), .str_sink_tready(),
      .str_src_tdata(), .str_src_tlast(), .str_src_tvalid(1'b0), .str_src_tready()
      );

   assign noci0_tdata = noco1_tdata;
   assign noci0_tlast = noco1_tlast;
   assign noci0_tvalid = noco1_tvalid;
   assign noco1_tready = noci0_tready;
   
   assign noci1_tdata = noco0_tdata;
   assign noci1_tlast = noco0_tlast;
   assign noci1_tvalid = noco0_tvalid;
   assign noco0_tready = noci1_tready;
   
   wire [31:0] set_data;
   wire [7:0]  set_addr;
   wire        set_stb;
   /*
   axi_crossbar #(.FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(2), .NUM_OUTPUTS(2)) crossbar
     (.clk(clk), .reset(reset), .clear(1'b0),
      .local_addr(),
      .i_tdata(), .i_tlast(), .i_tvalid(), .i_tready(),
      .pkt_present(),

      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .o_tdata(), .o_tlast(), .o_tvalid(), .o_tready(),

      .rb_rd_stb(), .rb_addr(), .rb_data());
   */
   
endmodule // noc_shell_tb
