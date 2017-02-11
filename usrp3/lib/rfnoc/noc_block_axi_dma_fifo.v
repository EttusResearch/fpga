//
// Copyright 2016 Ettus Research
//

module noc_block_axi_dma_fifo #(
  parameter NOC_ID = 64'hF1F0_D000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,             //Input buffering to tolerate DMA (usually DRAM) latency variation
  parameter NUM_FIFOS = 1,                      //Number of FIFOs that share the AXI4 memory space (max 4)
  parameter [NUM_FIFOS*30-1:0] DEFAULT_FIFO_BASE = {NUM_FIFOS{30'h00000000}}, //Default base addr for each FIFO (configurable via setting reg)
  parameter [NUM_FIFOS*30-1:0] DEFAULT_FIFO_SIZE = {NUM_FIFOS{30'h01FFFFFF}}, //Default size of each FIFO (configurable via setting reg)
  parameter [NUM_FIFOS*12-1:0] DEFAULT_BURST_TIMEOUT = {NUM_FIFOS{12'd256}}, //Timeout (in memory clock cycles) for issuing smaller than optimal bursts
  parameter EXTENDED_DRAM_BIST = 0              //Prune out additional BIST features for production
)(
  //
  // Clocks and Resets
  //
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,

  //
  // RFNoC CHDR interface to crossbar
  //
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,

  //
  // AXI Memory Mapped Interface
  //
  // -- AXI Write address channel
  output [(NUM_FIFOS*1)-1:0]    m_axi_awid,     // Write address ID. This signal is the identification tag for the write address signals
  output [(NUM_FIFOS*32)-1:0]   m_axi_awaddr,   // Write address. The write address gives the address of the first transfer in a write burst
  output [(NUM_FIFOS*8)-1:0]    m_axi_awlen,    // Burst length. The burst length gives the exact number of transfers in a burst.
  output [(NUM_FIFOS*3)-1:0]    m_axi_awsize,   // Burst size. This signal indicates the size of each transfer in the burst. 
  output [(NUM_FIFOS*2)-1:0]    m_axi_awburst,  // Burst type. The burst type and the size information, determine how the address is calculated
  output [(NUM_FIFOS*1)-1:0]    m_axi_awlock,   // Lock type. Provides additional information about the atomic characteristics of the transfer.
  output [(NUM_FIFOS*4)-1:0]    m_axi_awcache,  // Memory type. This signal indicates how transactions are required to progress
  output [(NUM_FIFOS*3)-1:0]    m_axi_awprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [(NUM_FIFOS*4)-1:0]    m_axi_awqos,    // Quality of Service, QoS. The QoS identifier sent for each write transaction
  output [(NUM_FIFOS*4)-1:0]    m_axi_awregion, // Region identifier. Permits a single physical interface on a slave to be re-used.
  output [(NUM_FIFOS*1)-1:0]    m_axi_awuser,   // User signal. Optional User-defined signal in the write address channel.
  output [(NUM_FIFOS*1)-1:0]    m_axi_awvalid,  // Write address valid. This signal indicates that the channel is signaling valid write addr
  input  [(NUM_FIFOS*1)-1:0]    m_axi_awready,  // Write address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Write data channel.
  output [(NUM_FIFOS*64)-1:0]   m_axi_wdata,    // Write data
  output [(NUM_FIFOS*8)-1:0]    m_axi_wstrb,    // Write strobes. This signal indicates which byte lanes hold valid data.
  output [(NUM_FIFOS*1)-1:0]    m_axi_wlast,    // Write last. This signal indicates the last transfer in a write burst
  output [(NUM_FIFOS*1)-1:0]    m_axi_wuser,    // User signal. Optional User-defined signal in the write data channel.
  output [(NUM_FIFOS*1)-1:0]    m_axi_wvalid,   // Write valid. This signal indicates that valid write data and strobes are available. 
  input  [(NUM_FIFOS*1)-1:0]    m_axi_wready,   // Write ready. This signal indicates that the slave can accept the write data.
  // -- AXI Write response channel signals
  input  [(NUM_FIFOS*1)-1:0]    m_axi_bid,      // Response ID tag. This signal is the ID tag of the write response. 
  input  [(NUM_FIFOS*2)-1:0]    m_axi_bresp,    // Write response. This signal indicates the status of the write transaction.
  input  [(NUM_FIFOS*1)-1:0]    m_axi_buser,    // User signal. Optional User-defined signal in the write response channel.
  input  [(NUM_FIFOS*1)-1:0]    m_axi_bvalid,   // Write response valid. This signal indicates that the channel is signaling a valid response
  output [(NUM_FIFOS*1)-1:0]    m_axi_bready,   // Response ready. This signal indicates that the master can accept a write response
  // -- AXI Read address channel
  output [(NUM_FIFOS*1)-1:0]    m_axi_arid,     // Read address ID. This signal is the identification tag for the read address group of signals
  output [(NUM_FIFOS*32)-1:0]   m_axi_araddr,   // Read address. The read address gives the address of the first transfer in a read burst
  output [(NUM_FIFOS*8)-1:0]    m_axi_arlen,    // Burst length. This signal indicates the exact number of transfers in a burst.
  output [(NUM_FIFOS*3)-1:0]    m_axi_arsize,   // Burst size. This signal indicates the size of each transfer in the burst.
  output [(NUM_FIFOS*2)-1:0]    m_axi_arburst,  // Burst type. The burst type and the size information determine how the address for each transfer
  output [(NUM_FIFOS*1)-1:0]    m_axi_arlock,   // Lock type. This signal provides additional information about the atomic characteristics
  output [(NUM_FIFOS*4)-1:0]    m_axi_arcache,  // Memory type. This signal indicates how transactions are required to progress 
  output [(NUM_FIFOS*3)-1:0]    m_axi_arprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [(NUM_FIFOS*4)-1:0]    m_axi_arqos,    // Quality of Service, QoS. QoS identifier sent for each read transaction.
  output [(NUM_FIFOS*4)-1:0]    m_axi_arregion, // Region identifier. Permits a single physical interface on a slave to be re-used
  output [(NUM_FIFOS*1)-1:0]    m_axi_aruser,   // User signal. Optional User-defined signal in the read address channel.
  output [(NUM_FIFOS*1)-1:0]    m_axi_arvalid,  // Read address valid. This signal indicates that the channel is signaling valid read addr
  input  [(NUM_FIFOS*1)-1:0]    m_axi_arready,  // Read address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Read data channel
  input  [(NUM_FIFOS*1)-1:0]    m_axi_rid,      // Read ID tag. This signal is the identification tag for the read data group of signals
  input  [(NUM_FIFOS*64)-1:0]   m_axi_rdata,    // Read data.
  input  [(NUM_FIFOS*2)-1:0]    m_axi_rresp,    // Read response. This signal indicates the status of the read transfer
  input  [(NUM_FIFOS*1)-1:0]    m_axi_rlast,    // Read last. This signal indicates the last transfer in a read burst.
  input  [(NUM_FIFOS*1)-1:0]    m_axi_ruser,    // User signal. Optional User-defined signal in the read data channel.
  input  [(NUM_FIFOS*1)-1:0]    m_axi_rvalid,   // Read valid. This signal indicates that the channel is signaling the required read data. 
  output [(NUM_FIFOS*1)-1:0]    m_axi_rready,   // Read ready. This signal indicates that the master can accept the read data and response

  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [(NUM_FIFOS*32)-1:0]     set_data;
  wire [(NUM_FIFOS*8)-1:0]      set_addr;
  wire [NUM_FIFOS-1:0]          set_stb;
  wire [(NUM_FIFOS*64)-1:0]     rb_data;

  wire [(NUM_FIFOS*64)-1:0]     str_sink_tdata, str_src_tdata;
  wire [NUM_FIFOS-1:0]          str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire [NUM_FIFOS-1:0]          clear_tx_seqnum;
  wire [(NUM_FIFOS*16)-1:0]     src_sid, next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(NUM_FIFOS),
    .OUTPUT_PORTS(NUM_FIFOS),
    .STR_SINK_FIFOSIZE({NUM_FIFOS{STR_SINK_FIFOSIZE[7:0]}}),
    .USE_TIMED_CMDS(0)) // Settings bus transactions will occur at the vita time specified in the command packet
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(bus_clk), .reset(bus_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(/* Unused */),
    .rb_stb({NUM_FIFOS{1'b1}}), .rb_data(rb_data), .rb_addr(),
    // Control Source
    .cmdout_tdata(64'h0), .cmdout_tlast(1'b0), .cmdout_tvalid(1'b0), .cmdout_tready(),
    .ackin_tdata(), .ackin_tlast(), .ackin_tvalid(), .ackin_tready(1'b1),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Stream IDs set by host 
    .src_sid(src_sid),                   // SID of this block
    .next_dst_sid(next_dst_sid),         // Next destination SID
    .resp_in_dst_sid(),   // Response destination SID for input stream responses / errors
    .resp_out_dst_sid(), // Response destination SID for output stream responses / errors
    // Misc
    .vita_time(64'd0),
    .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_USER_REG_BASE = 128;

  genvar i;
  generate
    for (i = 0; i < NUM_FIFOS; i = i + 1) begin:gen_dma_fifos
      ////////////////////////////////////////////////////////////
      //
      // AXI Wrapper
      // Convert RFNoC Shell interface into AXI stream interface
      //
      ////////////////////////////////////////////////////////////
      wire [63:0]  m_axis_data_tdata, s_axis_data_tdata;
      wire         m_axis_data_tlast, s_axis_data_tlast;
      wire         m_axis_data_tvalid, s_axis_data_tvalid;
      wire         m_axis_data_tready, s_axis_data_tready;

      assign m_axis_data_tdata  = str_sink_tdata[(64*(i+1))-1:64*i];
      assign m_axis_data_tlast  = str_sink_tlast[i];
      assign m_axis_data_tvalid = str_sink_tvalid[i];
      assign str_sink_tready[i] = m_axis_data_tready;

      reg         first_line;
      reg  [11:0] seqnum;
      wire [63:0] modified_header;
      always @(posedge bus_clk) begin
        if (bus_rst | clear_tx_seqnum[i]) begin
          first_line <= 1'b1;
          seqnum     <= 12'd0;
        end else begin
          if (s_axis_data_tvalid & s_axis_data_tready) begin
            if (s_axis_data_tlast) begin
              first_line <= 1'b1;
              seqnum     <= seqnum + 1;
            end else begin
              first_line <= 1'b0;
            end
          end
        end
      end

      wire [63:0] unused;
      cvita_hdr_modify cvita_hdr_modify (
        .header_in({s_axis_data_tdata,64'd0}),
        .header_out({modified_header,unused}),
        .use_pkt_type(1'b0),       .pkt_type(),
        .use_has_time(1'b0),       .has_time(),
        .use_eob(1'b0),            .eob(),
        .use_seqnum(1'b1),         .seqnum(seqnum),
        .use_length(1'b0),         .length(),
        .use_payload_length(1'b0), .payload_length(),
        .use_src_sid(1'b1),        .src_sid(src_sid[(16*(i+1))-1:16*i]),
        .use_dst_sid(1'b1),        .dst_sid(next_dst_sid[(16*(i+1))-1:16*i]),
        .use_vita_time(1'b0),      .vita_time());

      assign str_src_tdata[(64*(i+1))-1:64*i] = first_line ? modified_header : s_axis_data_tdata;
      assign str_src_tlast[i] = s_axis_data_tlast;
      assign str_src_tvalid[i] = s_axis_data_tvalid;
      assign s_axis_data_tready = str_src_tready[i];

      axi_dma_fifo #(
        .DEFAULT_BASE(DEFAULT_FIFO_BASE[(30*(i+1))-1:30*i]),
        .DEFAULT_MASK(~(DEFAULT_FIFO_SIZE[(30*(i+1))-1:30*i])),
        .DEFAULT_TIMEOUT(DEFAULT_BURST_TIMEOUT[(12*(i+1))-1:12*i]),
        .SR_BASE(SR_USER_REG_BASE),
        .EXT_BIST(EXTENDED_DRAM_BIST))
      axi_dma_fifo_i (
        //
        // Clocks and reset
        //
        .bus_clk(bus_clk), .bus_reset(bus_rst),
        .dram_clk(ce_clk), .dram_reset(ce_rst),
        //
        // AXI Write address channel
        //
        .m_axi_awid     (m_axi_awid[i]),
        .m_axi_awaddr   (m_axi_awaddr[(32*(i+1))-1:32*i]),
        .m_axi_awlen    (m_axi_awlen[(8*(i+1))-1:8*i]),
        .m_axi_awsize   (m_axi_awsize[(3*(i+1))-1:3*i]),
        .m_axi_awburst  (m_axi_awburst[(2*(i+1))-1:2*i]),
        .m_axi_awlock   (m_axi_awlock[i]),
        .m_axi_awcache  (m_axi_awcache[(4*(i+1))-1:4*i]),
        .m_axi_awprot   (m_axi_awprot[(3*(i+1))-1:3*i]),
        .m_axi_awqos    (m_axi_awqos[(4*(i+1))-1:4*i]),
        .m_axi_awregion (m_axi_awregion[(4*(i+1))-1:4*i]),
        .m_axi_awuser   (m_axi_awuser[i]),
        .m_axi_awvalid  (m_axi_awvalid[i]),
        .m_axi_awready  (m_axi_awready[i]),
        //
        // AXI Write data channel.
        //
        .m_axi_wdata    (m_axi_wdata[(64*(i+1))-1:64*i]),
        .m_axi_wstrb    (m_axi_wstrb[(8*(i+1))-1:8*i]),
        .m_axi_wlast    (m_axi_wlast[i]),
        .m_axi_wuser    (m_axi_wuser[i]),
        .m_axi_wvalid   (m_axi_wvalid[i]),
        .m_axi_wready   (m_axi_wready[i]),
        //
        // AXI Write response channel signals
        //
        .m_axi_bid      (m_axi_bid[i]),
        .m_axi_bresp    (m_axi_bresp[(2*(i+1))-1:2*i]),
        .m_axi_buser    (m_axi_buser[i]),
        .m_axi_bvalid   (m_axi_bvalid[i]),
        .m_axi_bready   (m_axi_bready[i]),
        //
        // AXI Read address channel
        //
        .m_axi_arid     (m_axi_arid[i]),
        .m_axi_araddr   (m_axi_araddr[(32*(i+1))-1:32*i]),
        .m_axi_arlen    (m_axi_arlen[(8*(i+1))-1:8*i]),
        .m_axi_arsize   (m_axi_arsize[(3*(i+1))-1:3*i]),
        .m_axi_arburst  (m_axi_arburst[(2*(i+1))-1:2*i]),
        .m_axi_arlock   (m_axi_arlock[i]),
        .m_axi_arcache  (m_axi_arcache[(4*(i+1))-1:4*i]),
        .m_axi_arprot   (m_axi_arprot[(3*(i+1))-1:3*i]),
        .m_axi_arqos    (m_axi_arqos[(4*(i+1))-1:4*i]),
        .m_axi_arregion (m_axi_arregion[(4*(i+1))-1:4*i]),
        .m_axi_aruser   (m_axi_aruser[i]),
        .m_axi_arvalid  (m_axi_arvalid[i]),
        .m_axi_arready  (m_axi_arready[i]),
        //
        // AXI Read data channel
        //
        .m_axi_rid      (m_axi_rid[i]),
        .m_axi_rdata    (m_axi_rdata[(64*(i+1))-1:64*i]),
        .m_axi_rresp    (m_axi_rresp[(2*(i+1))-1:2*i]),
        .m_axi_rlast    (m_axi_rlast[i]),
        .m_axi_ruser    (m_axi_ruser[i]),
        .m_axi_rvalid   (m_axi_rvalid[i]),
        .m_axi_rready   (m_axi_rready[i]),
        //
        // CHDR friendly AXI stream input
        //
        .i_tdata        (m_axis_data_tdata),
        .i_tlast        (m_axis_data_tlast),
        .i_tvalid       (m_axis_data_tvalid),
        .i_tready       (m_axis_data_tready),
        //
        // CHDR friendly AXI Stream output
        //
        .o_tdata        (s_axis_data_tdata),
        .o_tlast        (s_axis_data_tlast),
        .o_tvalid       (s_axis_data_tvalid),
        .o_tready       (s_axis_data_tready),
        //
        // Settings
        //
        .set_stb        (set_stb[i]),
        .set_addr       (set_addr[(8*(i+1))-1:8*i]),
        .set_data       (set_data[(32*(i+1))-1:32*i]),
        .rb_data        (rb_data[(64*i+32)-1:64*i]),
        //
        // Debug
        //
        .debug          ()
      );
      assign rb_data[(64*(i+1))-1:64*i+32] = 32'h0;

    end
  endgenerate

endmodule