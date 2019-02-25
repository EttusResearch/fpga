//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: rfnoc_core_regs
// Description:
//   The main software interface module for an assembled rfnoc
//   design
//

module rfnoc_core_regs #(
  parameter [15:0] PROTOVER             = {8'd1, 8'd0},
  parameter [15:0] DEVICE_TYPE          = 16'd0,
  parameter [9:0]  NUM_BLOCKS           = 0,
  parameter [9:0]  NUM_STREAM_ENDPOINTS = 0,
  parameter [9:0]  NUM_TRANSPORTS       = 0,
  parameter [11:0] NUM_EDGES            = 0,
  parameter [0:0]  CHDR_XBAR_PRESENT    = 1,
  parameter        EDGE_TBL_FILE        = ""
)(
  // Clock and reset
  input  wire                        rfnoc_ctrl_clk,
  input  wire                        rfnoc_ctrl_rst,
  // AXIS-Control Bus
  input  wire [31:0]                 s_axis_ctrl_tdata,
  input  wire                        s_axis_ctrl_tlast,
  input  wire                        s_axis_ctrl_tvalid,
  output wire                        s_axis_ctrl_tready,
  output wire [31:0]                 m_axis_ctrl_tdata,
  output wire                        m_axis_ctrl_tlast,
  output wire                        m_axis_ctrl_tvalid,
  input  wire                        m_axis_ctrl_tready,
  // Global info
  input  wire [15:0]                 device_id,
  // Backend config/status for each block
  output wire [(512*NUM_BLOCKS)-1:0] rfnoc_core_config,
  input  wire [(512*NUM_BLOCKS)-1:0] rfnoc_core_status
);

  `include "rfnoc_axis_ctrl_utils.vh"

  // -----------------------------------
  // AXIS-Ctrl Slave
  // -----------------------------------

  wire         ctrlport_req_wr;
  wire         ctrlport_req_rd;
  wire [19:0]  ctrlport_req_addr;
  wire [31:0]  ctrlport_req_data;
  reg          ctrlport_resp_ack;
  reg  [31:0]  ctrlport_resp_data;

  // The port ID of this endpoint must be zero
  localparam [9:0] RFNOC_CORE_PORT_ID = 10'd0;

  ctrlport_endpoint #(
    .THIS_PORTID(RFNOC_CORE_PORT_ID), .SYNC_CLKS(1),
    .AXIS_CTRL_MST_EN(0), .AXIS_CTRL_SLV_EN(1),
    .SLAVE_FIFO_SIZE(5)
  ) ctrlport_ep_i (
    .rfnoc_ctrl_clk           (rfnoc_ctrl_clk     ),
    .rfnoc_ctrl_rst           (rfnoc_ctrl_rst     ),
    .ctrlport_clk             (rfnoc_ctrl_clk     ),
    .ctrlport_rst             (rfnoc_ctrl_rst     ),
    .s_rfnoc_ctrl_tdata       (s_axis_ctrl_tdata  ),
    .s_rfnoc_ctrl_tlast       (s_axis_ctrl_tlast  ),
    .s_rfnoc_ctrl_tvalid      (s_axis_ctrl_tvalid ),
    .s_rfnoc_ctrl_tready      (s_axis_ctrl_tready ),
    .m_rfnoc_ctrl_tdata       (m_axis_ctrl_tdata  ),
    .m_rfnoc_ctrl_tlast       (m_axis_ctrl_tlast  ),
    .m_rfnoc_ctrl_tvalid      (m_axis_ctrl_tvalid ),
    .m_rfnoc_ctrl_tready      (m_axis_ctrl_tready ),
    .m_ctrlport_req_wr        (ctrlport_req_wr    ),
    .m_ctrlport_req_rd        (ctrlport_req_rd    ),
    .m_ctrlport_req_addr      (ctrlport_req_addr  ),
    .m_ctrlport_req_data      (ctrlport_req_data  ),
    .m_ctrlport_req_byte_en   (/* not supported */),
    .m_ctrlport_req_has_time  (/* not supported */),
    .m_ctrlport_req_time      (/* not supported */),
    .m_ctrlport_resp_ack      (ctrlport_resp_ack  ),
    .m_ctrlport_resp_status   (AXIS_CTRL_STS_OKAY ),
    .m_ctrlport_resp_data     (ctrlport_resp_data ),
    .s_ctrlport_req_wr        (1'b0               ),
    .s_ctrlport_req_rd        (1'b0               ),
    .s_ctrlport_req_addr      (20'd0              ),
    .s_ctrlport_req_portid    (10'd0              ),
    .s_ctrlport_req_rem_epid  (16'd0              ),
    .s_ctrlport_req_rem_portid(10'd0              ),
    .s_ctrlport_req_data      (32'h0              ),
    .s_ctrlport_req_byte_en   (4'h0               ),
    .s_ctrlport_req_has_time  (1'b0               ),
    .s_ctrlport_req_time      (1'b0               ),
    .s_ctrlport_resp_ack      (/* unused */       ),
    .s_ctrlport_resp_status   (/* unused */       ),
    .s_ctrlport_resp_data     (/* unused */       )
  );

  // ------------------------------------------------
  // Segment Address space into the three functions:
  // - Block Specific (incl. global regs)
  // - Connections
  // ------------------------------------------------

  reg  [15:0] req_addr      = 16'h0;
  reg  [31:0] req_data      = 32'h0;
  reg         blk_req_wr    = 1'b0;
  reg         blk_req_rd    = 1'b0;
  reg         blk_resp_ack  = 1'b0;
  reg  [31:0] blk_resp_data = 32'h0;
  reg         con_req_wr    = 1'b0;
  reg         con_req_rd    = 1'b0;
  reg         con_resp_ack  = 1'b0;
  reg  [31:0] con_resp_data = 32'h0;

  // Shortcuts
  wire blk_addr_space = (ctrlport_req_addr[19:16] == 4'd0);
  wire con_addr_space = (ctrlport_req_addr[19:16] == 4'd1);

  // ControlPort MUX
  always @(posedge rfnoc_ctrl_clk) begin
    // Write strobe
    blk_req_wr <= ctrlport_req_wr & blk_addr_space;
    con_req_wr <= ctrlport_req_wr & con_addr_space;
    // Read strobe
    blk_req_rd <= ctrlport_req_rd & blk_addr_space;
    con_req_rd <= ctrlport_req_rd & con_addr_space;
    // Address and Data (shared)
    req_addr <= ctrlport_req_addr[15:0];
    req_data <= ctrlport_req_data;
    // Response
    ctrlport_resp_ack <= blk_resp_ack | con_resp_ack;
    if (blk_resp_ack)
      ctrlport_resp_data <= blk_resp_data;
    else
      ctrlport_resp_data <= con_resp_data;
  end

  // -----------------------------------
  // Block Address Space
  // -----------------------------------

  // Arrange the backend block wires into a 2-d array where the 
  // outer index represents the slot number and the inner index represents
  // a register index for that slot. We have 512 bits of read/write
  // data which translates to 16 32-bit registers per slot. The first slot
  // belongs to this endpoint, the next N slots map to the instantiated
  // stream endpoints and the remaining slots map to block control and
  // status endpoint. The slot number has a 1-to-1 mapping to the port
  // number on the control crossbar.
  localparam NUM_REGS_PER_SLOT = 512/32;
  parameter  NUM_SLOTS = 1 /*this*/ + NUM_STREAM_ENDPOINTS + $clog2(NUM_BLOCKS);
  localparam BLOCK_OFFSET = 1 /*this*/ + NUM_STREAM_ENDPOINTS;
  
  reg  [31:0] config_arr_2d [0:NUM_SLOTS-1][0:NUM_REGS_PER_SLOT-1];
  wire [31:0] status_arr_2d [0:NUM_SLOTS-1][0:NUM_REGS_PER_SLOT-1];

  genvar b, i;
  generate
    for (b = 0; b < NUM_BLOCKS; b=b+1) begin
      for (i = 0; i < NUM_REGS_PER_SLOT; i=i+1) begin
        assign rfnoc_core_config[(b*512)+(i*32) +: 32] = config_arr_2d[b+BLOCK_OFFSET][i];
        assign status_arr_2d[b+BLOCK_OFFSET][i] = rfnoc_core_status[(b*512)+(i*32) +: 32];
      end
    end
  endgenerate

  always @(posedge rfnoc_ctrl_clk) begin
    if (rfnoc_ctrl_rst) begin
      blk_resp_ack <= 1'b0;
    end else begin
      // All transactions finish in 1 cycle
      blk_resp_ack <= blk_req_wr | blk_req_rd;
      // Handle register writes
      if (blk_req_wr) begin
        config_arr_2d[req_addr[$clog2(NUM_SLOTS)-1:6]][req_addr[5:2]] <= req_data;
      end
      // Handle register reads
      if (blk_req_rd) begin
        blk_resp_data <= status_arr_2d[req_addr[$clog2(NUM_SLOTS)-1:6]][req_addr[5:2]];
      end
    end
  end

  // Global Registers
  localparam [3:0] REG_GLOBAL_PROTOVER    = 4'd0;  // Offset = 0x00
  localparam [3:0] REG_GLOBAL_PORT_CNT    = 4'd1;  // Offset = 0x04
  localparam [3:0] REG_GLOBAL_EDGE_CNT    = 4'd2;  // Offset = 0x08
  localparam [3:0] REG_GLOBAL_DEVICE_INFO = 4'd3;  // Offset = 0x0C

  // Signature and protocol version
  assign status_arr_2d[RFNOC_CORE_PORT_ID][REG_GLOBAL_PROTOVER] = {16'h12C6, PROTOVER[15:0]};

  // Global port count register
  localparam [0:0] STATIC_ROUTER_PRESENT = (NUM_EDGES == 12'd0) ? 1'b0 : 1'b1;
  assign status_arr_2d[RFNOC_CORE_PORT_ID][REG_GLOBAL_PORT_CNT] = 
    {STATIC_ROUTER_PRESENT, CHDR_XBAR_PRESENT,
     NUM_TRANSPORTS[9:0], NUM_BLOCKS[9:0], NUM_STREAM_ENDPOINTS[9:0]};
  // Global edge count register
  assign status_arr_2d[RFNOC_CORE_PORT_ID][REG_GLOBAL_EDGE_CNT] = {20'd0, NUM_EDGES[11:0]};
  // Device information
  assign status_arr_2d[RFNOC_CORE_PORT_ID][REG_GLOBAL_DEVICE_INFO] = {DEVICE_TYPE, device_id};

  // -----------------------------------
  // Connections Address Space
  // -----------------------------------

  // All inter-block static connections must be stored in a memory
  // file which will be used to initialize a ROM that can be read
  // by software for topology discovery. The format of the memory
  // must be as follows:
  // * Word Width: 32 bits
  // * Maximum Depth: 16384 entries
  // * Layout:
  //   - 0x000 : HEADER
  //   - 0x001 : EDGE_0_DEF 
  //   - 0x002 : EDGE_1_DEF
  //   ...
  //   - 0xFFF : EDGE_4094_DEF
  //
  // where:
  // * HEADER       = {18'd0, NumEntries[13:0]}
  // * EDGE_<N>_DEF = {SrcBlkIndex[9:0], SrcBlkPort[5:0], DstBlkIndex[9:0], DstBlkPort[5:0]}
  //
  // The BlkIndex is the port number of the block on the control crossbar amd the BlkPort is
  // the index of the input or output port of the block.

  generate if (EDGE_TBL_FILE == "" || NUM_EDGES == 0) begin
    // If no file is specified or if the number of edges is zero
    // then just return zero for all transactions
    always @(posedge rfnoc_ctrl_clk) begin
      con_resp_ack  <= (con_req_wr | con_req_rd);
      con_resp_data <= 32'h0;
    end
  end else begin
    // Initialize ROM from file and read it during a reg transaction
    reg [31:0] edge_tbl_rom[0:NUM_EDGES];
    initial begin
      $readmemh(EDGE_TBL_FILE, edge_tbl_rom, 0, NUM_EDGES);
    end
    always @(posedge rfnoc_ctrl_clk) begin
      con_resp_ack  <= (con_req_wr | con_req_rd);
      con_resp_data <= edge_tbl_rom[req_addr[$clog2(NUM_EDGES+1)+1:2]];
    end
  end endgenerate

endmodule // rfnoc_core_regs

