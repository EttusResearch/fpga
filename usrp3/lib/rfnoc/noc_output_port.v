
// NoC Output port.  Implements source flow control on a single stream

module noc_output_port
  #(parameter BASE=0,
    parameter PORT_NUM=0,
    parameter MTU=10)
   (input clk, input reset,
    // Settings bus
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    // To NoC Shell
    output [63:0] dataout_tdata, output dataout_tlast, output dataout_tvalid, input dataout_tready,
    input [63:0] fcin_tdata, input fcin_tlast, input fcin_tvalid, output fcin_tready,
    // To CE
    input [63:0] str_src_tdata, input str_src_tlast, input str_src_tvalid, output str_src_tready
    );
   
   wire [63:0] 	 str_src_tdata_int;
   wire 	 str_src_tlast_int, str_src_tvalid_int, str_src_tready_int;
   
   axi_packet_gate #(.WIDTH(64), .SIZE(MTU)) str_src_gate
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(str_src_tdata), .i_tlast(str_src_tlast), .i_terror(1'b0), .i_tvalid(str_src_tvalid), .i_tready(str_src_tready),
      .o_tdata(str_src_tdata_int), .o_tlast(str_src_tlast_int), .o_tvalid(str_src_tvalid_int), .o_tready(str_src_tready_int));
   
   source_flow_control #(.BASE(BASE)) sfc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .fc_tdata(fcin_tdata), .fc_tlast(fcin_tlast), .fc_tvalid(fcin_tvalid), .fc_tready(fcin_tready),
      .in_tdata(str_src_tdata_int), .in_tlast(str_src_tlast_int), .in_tvalid(str_src_tvalid_int), .in_tready(str_src_tready_int),
      .out_tdata(dataout_tdata), .out_tlast(dataout_tlast), .out_tvalid(dataout_tvalid), .out_tready(dataout_tready),
      .debug() );
   
endmodule // noc_output_port
