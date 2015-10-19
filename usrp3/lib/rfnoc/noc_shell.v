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
  #(parameter [63:0] NOC_ID = 64'hDEAD_BEEF_0123_4567,        // Unique block ID
    parameter BLOCK_PORTS = 1,                                // Number of input / output port pairs, min 1, Note: Not both ports have to be used
    parameter [BLOCK_PORTS*8-1:0] STR_SINK_FIFOSIZES = {BLOCK_PORTS{8'd11}}, // Flattened array of each block port's window sizes
    parameter [BLOCK_PORTS*8-1:0] MTU = {BLOCK_PORTS{8'd10}}, // Flattened array of maximum (output) packet sizes (sizes FIFO used with packet gate)
    parameter [BLOCK_PORTS-1:0] USE_GATE_MASK = 'd0)          // Bit mask enabling axi gate per block port (i.e. 3'b101, enable packet gate on block ports 0 & 2.)
   (// RFNoC interfaces, to Crossbar, all on bus_clk
    input bus_clk, input bus_rst,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,

    // Computation Engine interfaces, all on local clock
    input clk, input reset,
    
    // Control Sink
    output [31:0] set_data, output [7:0] set_addr, output [BLOCK_PORTS-1:0] set_stb, output [63:0] set_time,
    input [(BLOCK_PORTS-1)*64+63:0] rb_data,

    // Control Source
    input [63:0] cmdout_tdata, input cmdout_tlast, input cmdout_tvalid, output cmdout_tready,
    output [63:0] ackin_tdata, output ackin_tlast, output ackin_tvalid, input ackin_tready,
    
    // Stream Sink
    output [BLOCK_PORTS*64-1:0] str_sink_tdata, output [BLOCK_PORTS-1:0] str_sink_tlast,
    output [BLOCK_PORTS-1:0] str_sink_tvalid, input [BLOCK_PORTS-1:0] str_sink_tready,
    
    // Stream Source
    input [BLOCK_PORTS*64-1:0] str_src_tdata, input [BLOCK_PORTS-1:0] str_src_tlast,
    input [BLOCK_PORTS-1:0] str_src_tvalid, output [BLOCK_PORTS-1:0] str_src_tready,

    // Misc
    output [BLOCK_PORTS-1:0] clear_tx_seqnum,        // Clear TX Sequence Number, one per output port
    output [BLOCK_PORTS*16-1:0] src_sid,             // Stream ID of block port, one per input and/or output port
    output [BLOCK_PORTS*16-1:0] next_dst_sid,        // Stream ID of downstream block, one per output port
    output [BLOCK_PORTS*16-1:0] forwarding_dst_sid,  // Stream ID of block to forward errors / special messages, one per input and/or output port

    output [63:0] debug
    );

   localparam SR_FLOW_CTRL_CYCS_PER_ACK      = 0;
   localparam SR_FLOW_CTRL_PKTS_PER_ACK      = 1;
   localparam SR_FLOW_CTRL_WINDOW_SIZE       = 2;
   localparam SR_FLOW_CTRL_WINDOW_EN         = 3;
   localparam SR_SRC_SID                     = 4;
   localparam SR_NEXT_DST_SID                = 5;
   localparam SR_FORWARDING_DST_SID          = 6;
   localparam SR_ERROR_POLICY                = 7;
   localparam SR_CLEAR_FC                    = 126;
   localparam SR_RB_ADDR                     = 127;
   
   localparam RB_NOC_ID                      = 0;
   localparam RB_BLOCK_PORT_SETTINGS         = 1;
   localparam RB_GLOBAL_SETTINGS             = 2;
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

   wire [BLOCK_PORTS-1:0] clear_fc;
   wire [1:0] rb_addr[0:BLOCK_PORTS-1];

   genvar k;
   generate
     for (k = 0; k < BLOCK_PORTS; k = k + 1) begin
       setting_reg #(.my_addr(SR_RB_ADDR), .width(2), .at_reset(0)) sr_rb_addr
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(rb_addr[k]),.changed());

       reg [63:0] rb_data_gen;
       always @(posedge clk) begin
         if (reset) begin
           rb_data_gen <= 64'd0;
         end else begin
           case(rb_addr[k])
             RB_NOC_ID              : rb_data_gen <= NOC_ID;
             // Block port specific settings
             RB_BLOCK_PORT_SETTINGS : rb_data_gen <= {src_sid[16*k+15:16*k],            // SRC SID / SID of this block port
                                                      next_dst_sid[16*k+15:16*k],       // Next Dest SID
                                                      forwarding_dst_sid[16*k+15:16*k], // Forwarding Dest SID (usually for sending errors back to the host)
                                                      MTU[8*k+7:8*k],                   // MTU
                                                      STR_SINK_FIFOSIZES[8*k+7:8*k]};   // Window size
             // NoC Shell global settings shared across all block ports
             RB_GLOBAL_SETTINGS     : rb_data_gen <= {59'd0, BLOCK_PORTS[4:0]};         // Need 5 bits as we can have up to 16 ports
             RB_USER_RB_DATA        : rb_data_gen <= rb_data[64*k+63:64*k];
           endcase
         end
       end

       assign rb_data_flat[64*k+63:64*k] = rb_data_gen;

       // Clearing the flow control window can also be used to reset the sequence number
       assign clear_tx_seqnum[k] = clear_fc[k];
       setting_reg #(.my_addr(SR_CLEAR_FC), .at_reset(0)) sr_clear_fc
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(),.changed(clear_fc[k]));
       // Stream ID of this RFNoC block
       setting_reg #(.my_addr(SR_SRC_SID), .width(16), .at_reset(0)) sr_block_sid
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(src_sid[16*k+15:16*k]),.changed());
       // Destination Stream ID of the next RFNoC block
       setting_reg #(.my_addr(SR_NEXT_DST_SID), .width(16), .at_reset(0)) sr_next_dst_sid
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(next_dst_sid[16*k+15:16*k]),.changed());
       setting_reg #(.my_addr(SR_NEXT_DST_SID), .width(16), .at_reset(0)) sr_forwarding_dst_sid
         (.clk(clk),.rst(reset),.strobe(set_stb[k]),.addr(set_addr),
          .in(set_data),.out(forwarding_dst_sid[16*k+15:16*k]),.changed());
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Source
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*BLOCK_PORTS-1:0] dataout_ports_tdata;
   wire [BLOCK_PORTS-1:0]    dataout_ports_tvalid, dataout_ports_tready, dataout_ports_tlast;

   wire [64*BLOCK_PORTS-1:0] fcin_ports_tdata;
   wire [BLOCK_PORTS-1:0]    fcin_ports_tvalid, fcin_ports_tready, fcin_ports_tlast;

   wire [63:0]               header_fcin;

   genvar i;
   generate
     if(BLOCK_PORTS == 1) begin : gen_noc_output_port
       noc_output_port #(
         .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
         .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN),
         .PORT_NUM(0), .MTU(MTU), .USE_GATE(USE_GATE_MASK))
       noc_output_port (
         .clk(clk), .reset(reset),
         .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
         .dataout_tdata(dataout_tdata), .dataout_tlast(dataout_tlast), .dataout_tvalid(dataout_tvalid), .dataout_tready(dataout_tready),
         .fcin_tdata(fcin_tdata), .fcin_tlast(fcin_tlast), .fcin_tvalid(fcin_tvalid), .fcin_tready(fcin_tready),
         .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready));
     end else begin : gen_noc_output_port
       for (i=0 ; i < BLOCK_PORTS ; i = i + 1) begin : loop
         noc_output_port #(
           .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
           .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN),
           .PORT_NUM(i), .MTU(MTU[8*i+7:8*i]), .USE_GATE(USE_GATE_MASK[i]))
         noc_output_port (
           .clk(clk), .reset(reset),
           .set_stb(set_stb[i]), .set_addr(set_addr), .set_data(set_data),
           .dataout_tdata(dataout_ports_tdata[64*i+63:64*i]), .dataout_tlast(dataout_ports_tlast[i]),
           .dataout_tvalid(dataout_ports_tvalid[i]), .dataout_tready(dataout_ports_tready[i]),
           .fcin_tdata(fcin_ports_tdata[64*i+63:64*i]), .fcin_tlast(fcin_ports_tlast[i]),
           .fcin_tvalid(fcin_ports_tvalid[i]), .fcin_tready(fcin_ports_tready[i]),
           .str_src_tdata(str_src_tdata[64*i+63:64*i]), .str_src_tlast(str_src_tlast[i]),
           .str_src_tvalid(str_src_tvalid[i]), .str_src_tready(str_src_tready[i]));
         axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(BLOCK_PORTS)) axi_mux (
           .clk(clk), .reset(reset), .clear(1'b0),
           .i_tdata(dataout_ports_tdata), .i_tlast(dataout_ports_tlast), .i_tvalid(dataout_ports_tvalid), .i_tready(dataout_ports_tready),
           .o_tdata(dataout_tdata), .o_tlast(dataout_tlast), .o_tvalid(dataout_tvalid), .o_tready(dataout_tready));
         axi_demux #(.WIDTH(64), .SIZE(BLOCK_PORTS)) axi_demux (
           .clk(clk), .reset(reset), .clear(1'b0),
           .header(header_fcin), .dest(header_fcin[3:0]),
           .i_tdata(fcin_tdata), .i_tlast(fcin_tlast), .i_tvalid(fcin_tvalid), .i_tready(fcin_tready),
           .o_tdata(fcin_ports_tdata), .o_tlast(fcin_ports_tlast), .o_tvalid(fcin_ports_tvalid), .o_tready(fcin_ports_tready));
       end
     end
   endgenerate

   ///////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink
   ///////////////////////////////////////////////////////////////////////////////////////
   wire [64*BLOCK_PORTS-1:0] datain_ports_tdata;
   wire [BLOCK_PORTS-1:0]    datain_ports_tvalid, datain_ports_tready, datain_ports_tlast;

   wire [64*BLOCK_PORTS-1:0] fcout_ports_tdata;
   wire [BLOCK_PORTS-1:0]    fcout_ports_tvalid, fcout_ports_tready, fcout_ports_tlast;

   wire [63:0]               header_datain;

   genvar j;
   generate
     if (BLOCK_PORTS == 1) begin : gen_noc_input_port
       noc_input_port #(
         .SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK),
         .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK),
         .SR_ERROR_POLICY(SR_ERROR_POLICY),
         .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZES))
       noc_input_port (
         .clk(clk), .reset(reset), .clear(clear_fc),
         .forwarding_sid({src_sid,forwarding_dst_sid}),
         .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
         .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
         .o_tdata(str_sink_tdata), .o_tlast(str_sink_tlast), .o_tvalid(str_sink_tvalid), .o_tready(str_sink_tready),
         .fc_tdata(fcout_tdata), .fc_tlast(fcout_tlast), .fc_tvalid(fcout_tvalid), .fc_tready(fcout_tready));
     end else begin : gen_noc_input_port
       for(j=0; j<BLOCK_PORTS; j=j+1) begin : loop
         noc_input_port #(
           .SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK),
           .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK),
           .SR_ERROR_POLICY(SR_ERROR_POLICY),
           .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZES[j]))
         noc_input_port (
           .clk(clk), .reset(reset), .clear(clear_fc[j]),
           .forwarding_sid({src_sid[16*j+15:16*j],forwarding_dst_sid[16*j+15:16*j]}),
           .set_stb(set_stb[j]), .set_addr(set_addr), .set_data(set_data),
           .i_tdata(datain_ports_tdata[64*j+63:64*j]), .i_tlast(datain_ports_tlast[j]),
           .i_tvalid(datain_ports_tvalid[j]), .i_tready(datain_ports_tready[j]),
           .o_tdata(str_sink_tdata[64*j+63:64*j]), .o_tlast(str_sink_tlast[j]),
           .o_tvalid(str_sink_tvalid[j]), .o_tready(str_sink_tready[j]),
           .fc_tdata(fcout_ports_tdata[64*j+63:64*j]), .fc_tlast(fcout_ports_tlast[j]),
           .fc_tvalid(fcout_ports_tvalid[j]), .fc_tready(fcout_ports_tready[j]));
         axi_demux #(.WIDTH(64), .SIZE(BLOCK_PORTS)) axi_demux (
           .clk(clk), .reset(reset), .clear(1'b0),
           .header(header_datain), .dest(header_datain[3:0]),
           .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
           .o_tdata(datain_ports_tdata), .o_tlast(datain_ports_tlast), .o_tvalid(datain_ports_tvalid), .o_tready(datain_ports_tready));
         axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(BLOCK_PORTS)) axi_mux (.clk(clk), .reset(reset), .clear(1'b0),
           .i_tdata(fcout_ports_tdata), .i_tlast(fcout_ports_tlast), .i_tvalid(fcout_ports_tvalid), .i_tready(fcout_ports_tready),
           .o_tdata(fcout_tdata), .o_tlast(fcout_tlast), .o_tvalid(fcout_tvalid), .o_tready(fcout_tready));
       end
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
