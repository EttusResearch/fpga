//
// Copyright 2015 Ettus Research
//

module noc_block_split_stream #(
  parameter NOC_ID = 64'h5757_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter NUM_OUTPUTS = 2)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);


  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0]    set_data;
  wire [7:0]     set_addr;
  wire [1:0]     set_stb;

  wire [63:0]    cmdout_tdata, ackin_tdata;
  wire           cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0]    str_sink_tdata;
  wire           str_sink_tlast, str_sink_tvalid, str_sink_tready;
  wire [63:0]    str_src_tdata[0:1];
  wire [1:0]     str_src_tlast, str_src_tvalid, str_src_tready;

  wire [31:0]    in_tdata;
  wire [127:0]   in_tuser;
  wire           in_tlast, in_tvalid, in_tready;

  wire [31:0]    out_tdata[0:1];
  wire [127:0]   out_tuser[0:1], out_tuser_pre[0:1];
  wire [1:0]     out_tlast, out_tvalid, out_tready;

  wire [1:0]     clear_tx_seqnum;
  wire [15:0]    src_sid[0:1], next_dst_sid[0:1];

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE),
    .INPUT_PORTS(1),
    .OUTPUT_PORTS(NUM_OUTPUTS))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Compute Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
    .rb_stb(1'b1), .rb_data(64'd0), .rb_addr(),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata({str_src_tdata[1],str_src_tdata[0]}), .str_src_tlast({str_src_tlast[1],str_src_tlast[0]}),
    .str_src_tvalid({str_src_tvalid[1],str_src_tvalid[0]}), .str_src_tready({str_src_tready[1],str_src_tready[0]}),
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid({src_sid[1],src_sid[0]}), .next_dst_sid({next_dst_sid[1],next_dst_sid[0]}),
    .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  chdr_deframer chdr_deframer (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(in_tdata), .o_tuser(in_tuser), .o_tlast(in_tlast), .o_tvalid(in_tvalid), .o_tready(in_tready));

  split_stream_fifo #(.WIDTH(128+32), .ACTIVE_MASK(4'b0011)) tuser_splitter (
    .clk(ce_clk), .reset(ce_rst), .clear(1'b0),
    .i_tdata({in_tuser,in_tdata}), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
    .o0_tdata({out_tuser_pre[0],out_tdata[0]}), .o0_tlast(out_tlast[0]), .o0_tvalid(out_tvalid[0]), .o0_tready(out_tready[0]),
    .o1_tdata({out_tuser_pre[1],out_tdata[1]}), .o1_tlast(out_tlast[1]), .o1_tvalid(out_tvalid[1]), .o1_tready(out_tready[1]),
    .o2_tready(1'b1), .o3_tready(1'b1));

  assign out_tuser[0] = { out_tuser_pre[0][127:96], src_sid[0], next_dst_sid[0], out_tuser_pre[0][63:0] };
  assign out_tuser[1] = { out_tuser_pre[1][127:96], src_sid[1], next_dst_sid[1], out_tuser_pre[1][63:0] };

  localparam MTU = 10;

  genvar i;
  generate
    for (i=0; i<NUM_OUTPUTS; i=i+1) begin
      chdr_framer #(.SIZE(MTU)) chdr_framer (
        .clk(ce_clk), .reset(ce_rst), .clear(clear_tx_seqnum[i]),
        .i_tdata(out_tdata[i]), .i_tuser(out_tuser[i]), .i_tlast(out_tlast[i]), .i_tvalid(out_tvalid[i]), .i_tready(out_tready[i]),
        .o_tdata(str_src_tdata[i]), .o_tlast(str_src_tlast[i]), .o_tvalid(str_src_tvalid[i]), .o_tready(str_src_tready[i]));
    end
  endgenerate

endmodule // noc_block_split_stream
