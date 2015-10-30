//
// Copyright 2015 Ettus Research
//
// Issues
//   Inline vs. Async commands
//   Command and Response forwarding
//   Different seqnums on incoming and outgoing
//   Multiple streams
//   Seqnum for different types
module noc_shell
  #(parameter [63:0] NOC_ID = 64'hDEAD_BEEF_0123_4567,          // Unique block ID
    parameter INPUT_PORTS = 1,                                  // Number of input ports, min 1
    parameter OUTPUT_PORTS = 1,                                 // Number of output ports, min 1
    parameter BLOCK_PORTS = (INPUT_PORTS > OUTPUT_PORTS) ? INPUT_PORTS : OUTPUT_PORTS, // max(INPUT_PORTS, OUTPUT_PORTS), DO NOT OVERRIDE! Needed to properly size port widths.
    parameter [INPUT_PORTS*8-1:0] STR_SINK_FIFOSIZE = {INPUT_PORTS{8'd11}}, // Flattened array of each block port's window sizes
    parameter [OUTPUT_PORTS*8-1:0] MTU = {OUTPUT_PORTS{8'd10}}, // Flattened array of maximum (output) packet sizes (sizes FIFO used with packet gate)
    parameter [OUTPUT_PORTS-1:0] USE_GATE_MASK = 'd0)           // Bit mask enabling AXI gate per block port (i.e. 3'b101, enable packet gate on block ports 0 & 2.)
                                                                // Note: AXI gate is only needed ports not using AXI wrapper
   (// RFNoC interfaces, to Crossbar, all on bus_clk
    input bus_clk, input bus_rst,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,

    // Computation Engine interfaces, all on local clock
    input clk, input reset,
    
    // Control Sink
    output [31:0] set_data, output [7:0] set_addr, output [BLOCK_PORTS-1:0] set_stb, output [63:0] set_time,
    output [BLOCK_PORTS*8-1:0] rb_addr, input [BLOCK_PORTS*64-1:0] rb_data,

    // Control Source
    input [63:0] cmdout_tdata, input cmdout_tlast, input cmdout_tvalid, output cmdout_tready,
    output [63:0] ackin_tdata, output ackin_tlast, output ackin_tvalid, input ackin_tready,
    
    // Stream Sink
    output [INPUT_PORTS*64-1:0] str_sink_tdata, output [INPUT_PORTS-1:0] str_sink_tlast,
    output [INPUT_PORTS-1:0] str_sink_tvalid, input [INPUT_PORTS-1:0] str_sink_tready,
    
    // Stream Source
    input [OUTPUT_PORTS*64-1:0] str_src_tdata, input [OUTPUT_PORTS-1:0] str_src_tlast,
    input [OUTPUT_PORTS-1:0] str_src_tvalid, output [OUTPUT_PORTS-1:0] str_src_tready,

    // Advanced user ports
    output [OUTPUT_PORTS-1:0] clear_tx_seqnum,       // Clear TX Sequence Number, one per output port
    output [BLOCK_PORTS*16-1:0] src_sid,             // Stream ID of block port, one per input and/or output port
    output [OUTPUT_PORTS*16-1:0] next_dst_sid,       // Stream ID of downstream block, one per output port
    output [INPUT_PORTS*16-1:0] resp_in_dst_sid,     // Stream IDs to forward errors / special messages, one per input
    output [OUTPUT_PORTS*16-1:0] resp_out_dst_sid,   // and one per output port

    output [63:0] debug
    );

   localparam SR_FLOW_CTRL_CYCS_PER_ACK      = 0;
   localparam SR_FLOW_CTRL_PKTS_PER_ACK      = 1;
   localparam SR_FLOW_CTRL_WINDOW_SIZE       = 2;
   localparam SR_FLOW_CTRL_WINDOW_EN         = 3;
   localparam SR_ERROR_POLICY                = 4;
   localparam SR_SRC_SID                     = 5;
   localparam SR_NEXT_DST_SID                = 6;
   localparam SR_RESP_IN_DST_SID             = 7;
   localparam SR_RESP_OUT_DST_SID            = 8;
   localparam SR_RB_ADDR_USER                = 124;
   localparam SR_CLEAR_RX_FC                 = 125;
   localparam SR_CLEAR_TX_FC                 = 126;
   localparam SR_RB_ADDR                     = 127;
   
   localparam RB_NOC_ID                      = 0;
   localparam RB_BLOCK_PORT_PARAMS           = 1;
   localparam RB_BLOCK_PORT_SIDS             = 2;
   localparam RB_USER_RB_DATA                = 3;
   // Allocate all regs 128-255 to user device
   
   wire [63:0] 	  dataout_tdata, datain_tdata, fcin_tdata, fcout_tdata,
		  cmdin_tdata,  ackout_tdata;
   wire 	  dataout_tlast, datain_tlast, fcin_tlast, fcout_tlast,
		  cmdin_tlast,  ackout_tlast;
   wire 	  dataout_tvalid, datain_tvalid, fcin_tvalid, fcout_tvalid,
		  cmdin_tvalid, ackout_tvalid;
   wire 	  dataout_tready, datain_tready, fcin_tready, fcout_tready,
		  cmdin_tready,  ackout_tready;

   wire [31:0] 	  debug_sfc;
   
   ///////////////////////////////////////////////////////////////////////////////////////
   // 2-clock fifos to get the computation engine on its own clock
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [63:0] 	  i_tdata_b, o_tdata_b;
   wire 	  i_tlast_b, o_tlast_b, i_tvalid_b, o_tvalid_b, i_tready_b, o_tready_b;
   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(5)) in_fifo   // Very little buffering needed here, only a clock domain crossing
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(i_tvalid), .i_tready(i_tready), .i_tdata({i_tlast,i_tdata}),
      .o_aclk(clk), .o_tvalid(i_tvalid_b), .o_tready(i_tready_b), .o_tdata({i_tlast_b,i_tdata_b}));
   
   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(9)) out_fifo
     (.reset(bus_rst),
      .i_aclk(clk), .i_tvalid(o_tvalid_b), .i_tready(o_tready_b), .i_tdata({o_tlast_b,o_tdata_b}),
      .o_aclk(bus_clk), .o_tvalid(o_tvalid), .o_tready(o_tready), .o_tdata({o_tlast,o_tdata}));
   
   ///////////////////////////////////////////////////////////////////////////////////////
   // Mux and Demux to join/split streams going to/coming from RFNoC
   ///////////////////////////////////////////////////////////////////////////////////////
   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) output_mux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i0_tdata(dataout_tdata), .i0_tlast(dataout_tlast), .i0_tvalid(dataout_tvalid), .i0_tready(dataout_tready),
      .i1_tdata(fcout_tdata), .i1_tlast(fcout_tlast), .i1_tvalid(fcout_tvalid), .i1_tready(fcout_tready),
      .i2_tdata(cmdout_tdata), .i2_tlast(cmdout_tlast), .i2_tvalid(cmdout_tvalid), .i2_tready(cmdout_tready),
      .i3_tdata(ackout_tdata), .i3_tlast(ackout_tlast), .i3_tvalid(ackout_tvalid), .i3_tready(ackout_tready),
      .o_tdata(o_tdata_b), .o_tlast(o_tlast_b), .o_tvalid(o_tvalid_b), .o_tready(o_tready_b));

   wire [63:0] 	 vheader;
   wire [1:0] 	 vdest = vheader[63:62];  // Switch by packet type

   axi_demux4 #(.ACTIVE_CHAN(4'b1111), .WIDTH(64)) input_demux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(i_tdata_b), .i_tlast(i_tlast_b), .i_tvalid(i_tvalid_b), .i_tready(i_tready_b),
      .o0_tdata(datain_tdata), .o0_tlast(datain_tlast), .o0_tvalid(datain_tvalid), .o0_tready(datain_tready),
      .o1_tdata(fcin_tdata), .o1_tlast(fcin_tlast), .o1_tvalid(fcin_tvalid), .o1_tready(fcin_tready),
      .o2_tdata(cmdin_tdata), .o2_tlast(cmdin_tlast), .o2_tvalid(cmdin_tvalid), .o2_tready(cmdin_tready),
      .o3_tdata(ackin_tdata), .o3_tlast(ackin_tlast), .o3_tvalid(ackin_tvalid), .o3_tready(ackin_tready));

   ///////////////////////////////////////////////////////////////////////////////////////
   // Control Sink (required)
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [BLOCK_PORTS*64-1:0] rb_data_flat;
   cmd_pkt_proc #(.NUM_SR_BUSES(BLOCK_PORTS)) cmd_pkt_proc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .cmd_tdata(cmdin_tdata), .cmd_tlast(cmdin_tlast), .cmd_tvalid(cmdin_tvalid), .cmd_tready(cmdin_tready),
      .resp_tdata(ackout_tdata), .resp_tlast(ackout_tlast), .resp_tvalid(ackout_tvalid), .resp_tready(ackout_tready),
      .vita_time(64'd0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .set_time(set_time),
      .ready(1'b1), .readback(rb_data_flat));

   wire [INPUT_PORTS-1:0] clear_rx_fc;
   wire [OUTPUT_PORTS-1:0] clear_tx_fc;
   wire [1:0] rb_addr_noc_shell[0:BLOCK_PORTS-1];

   genvar k;
   generate
     for (k = 0; k < BLOCK_PORTS; k = k + 1) begin
       setting_reg #(.my_addr(SR_RB_ADDR), .width(2), .at_reset(0)) sr_rb_addr
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(rb_addr_noc_shell[k]),.changed());
       setting_reg #(.my_addr(SR_RB_ADDR_USER), .width(8), .at_reset(0)) sr_rb_addr_user
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(rb_addr[8*k+7:8*k]),.changed());

       reg [63:0] rb_data_gen;
       always @(posedge clk) begin
         if (reset) begin
           rb_data_gen <= 64'd0;
         end else begin
           case(rb_addr_noc_shell[k])
             RB_NOC_ID                : rb_data_gen <= NOC_ID;
             RB_BLOCK_PORT_PARAMS     : rb_data_gen <= {40'd0,
                                                        INPUT_PORTS[4:0], OUTPUT_PORTS[4:0],
                                                        k < OUTPUT_PORTS ? MTU[8*k+7:8*k]                 : 8'd0,
                                                        k < INPUT_PORTS  ? STR_SINK_FIFOSIZE[8*k+7:8*k]   : 8'd0};
             RB_BLOCK_PORT_SIDS       : rb_data_gen <= {src_sid[16*k+15:16*k],
                                                        k < OUTPUT_PORTS ? next_dst_sid[16*k+15:16*k]     : 16'd0,
                                                        k < INPUT_PORTS  ? resp_in_dst_sid[16*k+15:16*k]  : 16'd0,
                                                        k < OUTPUT_PORTS ? resp_out_dst_sid[16*k+15:16*k] : 16'd0};
             RB_USER_RB_DATA          : rb_data_gen <= rb_data[64*k+63:64*k];
           endcase
         end
       end

       assign rb_data_flat[64*k+63:64*k] = rb_data_gen;

       // Stream ID of this RFNoC block
       setting_reg #(.my_addr(SR_SRC_SID), .width(16), .at_reset(0)) sr_block_sid
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(src_sid[16*k+15:16*k]),.changed());

       if (k < INPUT_PORTS) begin
         setting_reg #(.my_addr(SR_CLEAR_RX_FC), .at_reset(0)) sr_clear_rx_fc
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
            .in(set_data),.out(),.changed(clear_rx_fc[k]));
         setting_reg #(.my_addr(SR_RESP_IN_DST_SID), .width(16), .at_reset(0)) sr_resp_in_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
            .in(set_data),.out(resp_in_dst_sid[16*k+15:16*k]),.changed());
       end

       if (k < OUTPUT_PORTS) begin
         // Clearing the flow control window can also be used to reset the sequence number
         assign clear_tx_seqnum[k] = clear_tx_fc[k];
         setting_reg #(.my_addr(SR_CLEAR_TX_FC), .at_reset(0)) sr_clear_tx_fc
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
            .in(set_data),.out(),.changed(clear_tx_fc[k]));
         // Destination Stream ID of the next RFNoC block
         setting_reg #(.my_addr(SR_NEXT_DST_SID), .width(16), .at_reset(0)) sr_next_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
            .in(set_data),.out(next_dst_sid[16*k+15:16*k]),.changed());
         setting_reg #(.my_addr(SR_RESP_OUT_DST_SID), .width(16), .at_reset(0)) sr_resp_out_dst_sid
           (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
            .in(set_data),.out(resp_out_dst_sid[16*k+15:16*k]),.changed());
       end
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Source
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*OUTPUT_PORTS-1:0] dataout_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    dataout_ports_tvalid, dataout_ports_tready, dataout_ports_tlast;

   wire [64*OUTPUT_PORTS-1:0] fcin_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    fcin_ports_tvalid, fcin_ports_tready, fcin_ports_tlast;

   wire [63:0]               header_fcin;

   genvar i;
   generate
     if(OUTPUT_PORTS == 1) begin : gen_noc_output_port
       noc_output_port #(
         .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
         .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN),
         .PORT_NUM(0), .MTU(MTU), .USE_GATE(USE_GATE_MASK))
       noc_output_port (
         .clk(clk), .reset(reset), .clear(clear_tx_fc),
         .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
         .dataout_tdata(dataout_tdata), .dataout_tlast(dataout_tlast), .dataout_tvalid(dataout_tvalid), .dataout_tready(dataout_tready),
         .fcin_tdata(fcin_tdata), .fcin_tlast(fcin_tlast), .fcin_tvalid(fcin_tvalid), .fcin_tready(fcin_tready),
         .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready));
     end else begin : gen_noc_output_port
       for (i=0 ; i < OUTPUT_PORTS ; i = i + 1) begin : loop
         noc_output_port #(
           .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
           .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN),
           .PORT_NUM(i), .MTU(MTU[8*i+7:8*i]), .USE_GATE(USE_GATE_MASK[i]))
         noc_output_port (
           .clk(clk), .reset(reset), .clear(clear_tx_fc[i]),
           .set_stb(set_stb[i]), .set_addr(set_addr), .set_data(set_data),
           .dataout_tdata(dataout_ports_tdata[64*i+63:64*i]), .dataout_tlast(dataout_ports_tlast[i]),
           .dataout_tvalid(dataout_ports_tvalid[i]), .dataout_tready(dataout_ports_tready[i]),
           .fcin_tdata(fcin_ports_tdata[64*i+63:64*i]), .fcin_tlast(fcin_ports_tlast[i]),
           .fcin_tvalid(fcin_ports_tvalid[i]), .fcin_tready(fcin_ports_tready[i]),
           .str_src_tdata(str_src_tdata[64*i+63:64*i]), .str_src_tlast(str_src_tlast[i]),
           .str_src_tvalid(str_src_tvalid[i]), .str_src_tready(str_src_tready[i]));
       end
       axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(OUTPUT_PORTS)) axi_mux (
         .clk(clk), .reset(reset), .clear(1'b0),
         .i_tdata(dataout_ports_tdata), .i_tlast(dataout_ports_tlast), .i_tvalid(dataout_ports_tvalid), .i_tready(dataout_ports_tready),
         .o_tdata(dataout_tdata), .o_tlast(dataout_tlast), .o_tvalid(dataout_tvalid), .o_tready(dataout_tready));
       axi_demux #(.WIDTH(64), .SIZE(OUTPUT_PORTS)) axi_demux (
         .clk(clk), .reset(reset), .clear(1'b0),
         .header(header_fcin), .dest(header_fcin[3:0]),
         .i_tdata(fcin_tdata), .i_tlast(fcin_tlast), .i_tvalid(fcin_tvalid), .i_tready(fcin_tready),
         .o_tdata(fcin_ports_tdata), .o_tlast(fcin_ports_tlast), .o_tvalid(fcin_ports_tvalid), .o_tready(fcin_ports_tready));
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*INPUT_PORTS-1:0] datain_ports_tdata;
   wire [INPUT_PORTS-1:0]    datain_ports_tvalid, datain_ports_tready, datain_ports_tlast;

   wire [64*INPUT_PORTS-1:0] fcout_ports_tdata;
   wire [INPUT_PORTS-1:0]    fcout_ports_tvalid, fcout_ports_tready, fcout_ports_tlast;

   wire [63:0]               header_datain;

   genvar j;
   generate
     if (INPUT_PORTS == 1) begin : gen_noc_input_port
       noc_input_port #(
         .SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK),
         .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK),
         .SR_ERROR_POLICY(SR_ERROR_POLICY),
         .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
       noc_input_port (
         .clk(clk), .reset(reset), .clear(clear_rx_fc),
         .resp_sid({src_sid,resp_dst_sid}),
         .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
         .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
         .o_tdata(str_sink_tdata), .o_tlast(str_sink_tlast), .o_tvalid(str_sink_tvalid), .o_tready(str_sink_tready),
         .fc_tdata(fcout_tdata), .fc_tlast(fcout_tlast), .fc_tvalid(fcout_tvalid), .fc_tready(fcout_tready));
     end else begin : gen_noc_input_port
       for(j=0; j<INPUT_PORTS; j=j+1) begin : loop
         noc_input_port #(
           .SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK),
           .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK),
           .SR_ERROR_POLICY(SR_ERROR_POLICY),
           .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE[8*j-7:8*j]))
         noc_input_port (
           .clk(clk), .reset(reset), .clear(clear_rx_fc[j]),
           .resp_sid({src_sid[16*j+15:16*j],resp_in_dst_sid[16*j+15:16*j]}),
           .set_stb(set_stb[j]), .set_addr(set_addr), .set_data(set_data),
           .i_tdata(datain_ports_tdata[64*j+63:64*j]), .i_tlast(datain_ports_tlast[j]),
           .i_tvalid(datain_ports_tvalid[j]), .i_tready(datain_ports_tready[j]),
           .o_tdata(str_sink_tdata[64*j+63:64*j]), .o_tlast(str_sink_tlast[j]),
           .o_tvalid(str_sink_tvalid[j]), .o_tready(str_sink_tready[j]),
           .fc_tdata(fcout_ports_tdata[64*j+63:64*j]), .fc_tlast(fcout_ports_tlast[j]),
           .fc_tvalid(fcout_ports_tvalid[j]), .fc_tready(fcout_ports_tready[j]));
       end
       axi_demux #(.WIDTH(64), .SIZE(INPUT_PORTS)) axi_demux (
         .clk(clk), .reset(reset), .clear(1'b0),
         .header(header_datain), .dest(header_datain[3:0]),
         .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
         .o_tdata(datain_ports_tdata), .o_tlast(datain_ports_tlast), .o_tvalid(datain_ports_tvalid), .o_tready(datain_ports_tready));
       axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(INPUT_PORTS)) axi_mux (
         .clk(clk), .reset(reset), .clear(1'b0),
         .i_tdata(fcout_ports_tdata), .i_tlast(fcout_ports_tlast), .i_tvalid(fcout_ports_tvalid), .i_tready(fcout_ports_tready),
         .o_tdata(fcout_tdata), .o_tlast(fcout_tlast), .o_tvalid(fcout_tvalid), .o_tready(fcout_tready));
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Debug pins
   ///////////////////////////////////////////////////////////////////////////////////////
   assign debug[31:0] = { // input side 16 bits
			  4'b0000,
			  i_tvalid_b, i_tready_b,
			  datain_tvalid, datain_tready,
			  fcin_tvalid, fcin_tready,
			  cmdin_tvalid, cmdin_tready,
			  ackin_tvalid, ackin_tready,
			  str_sink_tvalid, str_sink_tready,
			  // output side 16 bits
			  2'b00,
			  o_tvalid_b, o_tready_b,
			  dataout_tvalid, dataout_tready,
			  fcout_tvalid, fcout_tready,
			  cmdout_tvalid, cmdout_tready,
			  ackout_tvalid, ackout_tready,
			  2'b00,
			  str_src_tvalid, str_src_tready
			  };

   assign debug[63:32] = debug_sfc;
   
endmodule // noc_shell
