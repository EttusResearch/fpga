//////////////////////////////////////
//
//  2017 Ettus Research
//
//////////////////////////////////////

module n310_core
#(
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 32  // Width of the address bus
)
(
 //Clocks and resets
  input         radio_clk,
  input         radio_rst,
  input         bus_clk,
  input         bus_rst,

  input [31:0]  s_axi_awaddr,
  input         s_axi_awvalid,
  output        s_axi_awready,

  input [31:0]  s_axi_wdata,
  input [3:0]   s_axi_wstrb,
  input         s_axi_wvalid,
  output        s_axi_wready,

  output [1:0]  s_axi_bresp,
  output        s_axi_bvalid,
  input         s_axi_bready,

  input [31:0]  s_axi_araddr,
  input         s_axi_arvalid,
  output        s_axi_arready,

  output [31:0] s_axi_rdata,
  output [1:0]  s_axi_rresp,
  output        s_axi_rvalid,
  input         s_axi_rready,

  // Radio 0
  input  [31:0] rx0,
  output [31:0] tx0,

  // Radio 1
  input  [31:0]  rx1,
  output [31:0]  tx1,

  // DMA
  output [63:0] dmao_tdata,
  output        dmao_tlast,
  output        dmao_tvalid,
  input         dmao_tready,

  input [63:0]  dmai_tdata,
  input         dmai_tlast,
  input         dmai_tvalid,
  output        dmai_tready,

  // v2e (vita to ethernet) and e2v (eth to vita)
  output [63:0] v2e0_tdata,
  output        v2e0_tvalid,
  output        v2e0_tlast,
  input         v2e0_tready,

  output [63:0] v2e1_tdata,
  output        v2e1_tlast,
  output        v2e1_tvalid,
  input         v2e1_tready,

  input  [63:0] e2v0_tdata,
  input         e2v0_tlast,
  input         e2v0_tvalid,
  output        e2v0_tready,

  input  [63:0] e2v1_tdata,
  input         e2v1_tlast,
  input         e2v1_tvalid,
  output        e2v1_tready
);

  // Computation engines that need access to IO
  localparam NUM_IO_CE = 3;

  //////////////////////////////////////////////////////////////////////////////////////////////
  // Global Registers
  //////////////////////////////////////////////////////////////////////////////////////////////
  localparam REG_BASE_MISC = 0; // axi interconnect takes care of that

  wire                     reg_wr_req;
  wire [REG_AWIDTH-1:0]    reg_wr_addr;
  wire [REG_DWIDTH-1:0]    reg_wr_data;
  wire [REG_DWIDTH/8-1:0]  reg_wr_keep;
  wire                     reg_rd_req;
  wire  [REG_AWIDTH-1:0]   reg_rd_addr;
  reg                      reg_rd_resp;
  reg   [REG_DWIDTH-1:0]   reg_rd_data;

  axil_regport_master #(
    .DWIDTH   (REG_DWIDTH), // Width of the AXI4-Lite data bus (must be 32 or 64)
    .AWIDTH   (REG_AWIDTH), // Width of the address bus
    .WRBASE   (0),          // Write address base
    .RDBASE   (0),          // Read address base
    .TIMEOUT  (10)          // log2(timeout). Read will timeout after (2^TIMEOUT - 1) cycles
  ) regport_master_i (
    // Clock and reset
    .s_axi_aclk    (bus_clk),
    .s_axi_aresetn (~bus_rst),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    // Register port: Write port (domain: reg_clk)
    .reg_clk       (bus_clk),
    .reg_wr_req    (reg_wr_req),
    .reg_wr_addr   (reg_wr_addr),
    .reg_wr_data   (reg_wr_data),
    .reg_wr_keep   (/*unused*/),
    // Register port: Read port (domain: reg_clk)
    .reg_rd_req    (reg_rd_req),
    .reg_rd_addr   (reg_rd_addr),
    .reg_rd_resp   (reg_rd_resp),
    .reg_rd_data   (reg_rd_data)
  );

  localparam REG_GIT_HASH    = 14'd0;
  localparam REG_NUM_CE      = 14'd4;
  localparam REG_SCRATCH     = 14'd8;

  reg [31:0] scratch_reg;

  always @ (posedge bus_clk)
    if (bus_rst) begin
      scratch_reg <= 32'hdead_babe;
    end
    else begin
    if (reg_wr_req)
      case (reg_wr_addr)
        REG_SCRATCH:
          scratch_reg <= reg_wr_data;
      endcase
    end

  always @ (posedge bus_clk)
    if (bus_rst)
      reg_rd_resp <= 1'b0;

    else begin
      if (reg_rd_req) begin
        reg_rd_resp <= 1'b1;

        case (reg_rd_addr)
        REG_GIT_HASH:
          reg_rd_data <= 32'h`GIT_HASH;

        REG_NUM_CE:
          reg_rd_data <= NUM_IO_CE;

        REG_SCRATCH:
          reg_rd_data <= scratch_reg;
        default:
          reg_rd_resp <= 1'b0;
        endcase
      end
      else if (reg_rd_resp) begin
          reg_rd_resp <= 1'b0;
      end
    end



   wire     [NUM_IO_CE*64-1:0]  ioce_flat_o_tdata;
   wire     [NUM_IO_CE*64-1:0]  ioce_flat_i_tdata;
   wire     [63:0]              ioce_o_tdata[0:NUM_IO_CE-1];
   wire     [63:0]              ioce_i_tdata[0:NUM_IO_CE-1];
   wire     [NUM_IO_CE-1:0]     ioce_o_tlast;
   wire     [NUM_IO_CE-1:0]     ioce_o_tvalid;
   wire     [NUM_IO_CE-1:0]     ioce_o_tready;
   wire     [NUM_IO_CE-1:0]     ioce_i_tlast;
   wire     [NUM_IO_CE-1:0]     ioce_i_tvalid;
   wire     [NUM_IO_CE-1:0]     ioce_i_tready;

   genvar ioce_i;
   generate for (ioce_i = 0; ioce_i < NUM_IO_CE; ioce_i = ioce_i + 1) begin
      assign ioce_o_tdata[ioce_i] = ioce_flat_o_tdata[ioce_i*64 + 63 : ioce_i*64];
      assign ioce_flat_i_tdata[ioce_i*64+63:ioce_i*64] = ioce_i_tdata[ioce_i];
   end endgenerate

   // Number of Radio Cores Instantiated
   localparam NUM_RADIO_CORES = 2;
/*
   //////////////////////////////////////////////////////////////////////////////////////////////
   // RFNoC
   //////////////////////////////////////////////////////////////////////////////////////////////

   // Included automatically instantiated CEs sources file created by RFNoC mod tool
`ifdef RFNOC
 `ifdef N300
   `include "rfnoc_ce_auto_inst_n300.v"
 `endif
 `ifdef N310
   `include "rfnoc_ce_auto_inst_n310.v"
 `endif
`else
 `ifdef N300
   `include "rfnoc_ce_default_inst_n300.v"
 `endif
 `ifdef N310
   `include "rfnoc_ce_default_inst_n310.v"
 `endif
`endif

   wire  [(NUM_CE)*64-1:0] ce_o_tdata;
   wire  [(NUM_CE)-1:0]    ce_o_tlast;
   wire  [(NUM_CE)-1:0]    ce_o_tvalid;
   wire  [(NUM_CE)-1:0]    ce_o_tready;

   wire  [(NUM_CE)*64-1:0] ce_i_tdata;
   wire  [(NUM_CE)-1:0]    ce_i_tlast;
   wire  [(NUM_CE)-1:0]    ce_i_tvalid;
   wire  [(NUM_CE)-1:0]    ce_i_tready;
   // //////////////////////////////////////////////////////////////////////
   // axi_crossbar ports
   // 0  - ETH0
   // 1  - ETH1
   // 2  - DMA
   // 3  - CE0
   // ...
   // 15 - CE13
   // //////////////////////////////////////////////////////////////////////

  // Base width of crossbar based on fixed components (ethernet, DMA)
   localparam XBAR_FIXED_PORTS = 3;
   localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE;

   // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
   axi_crossbar #(
      .FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_NUM_PORTS), .NUM_OUTPUTS(XBAR_NUM_PORTS))
   inst_axi_crossbar (
      .clk(clk), .reset(reset), .clear(0),
      .local_addr(),
      .set_stb(), .set_addr(), .set_data(),
      .i_tdata({ce_i_tdata,dmai_tdata,e2v1_tdata,e2v0_tdata}),
      .i_tlast({ce_i_tlast,dmai_tlast,e2v1_tlast,e2v0_tlast}),
      .i_tvalid({ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .i_tready({ce_i_tready,dmai_tready,e2v1_tready,e2v0_tready}),
      .o_tdata({ce_o_tdata,dmao_tdata,v2e1_tdata,v2e0_tdata}),
      .o_tlast({ce_o_tlast,dmao_tlast,v2e1_tlast,v2e0_tlast}),
      .o_tvalid({ce_o_tvalid,dmao_tvalid,v2e1_tvalid,v2e0_tvalid}),
      .o_tready({ce_o_tready,dmao_tready,v2e1_tready,v2e0_tready}),
      .pkt_present({ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid})
      //.rb_rd_stb(rb_rd_stb && (rb_addr == RB_CROSSBAR)),
      //.rb_addr(rb_addr_xbar), .rb_data(rb_data_crossbar)
      );

*/

   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // Radios
   //
   /////////////////////////////////////////////////////////////////////////////////////////////

endmodule //n310_core
