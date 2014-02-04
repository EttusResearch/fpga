//
// Copyright 2013 Ettus Research LLC
//

//export lots of signals from the PS
//and export data mover fifos

module zynq_system_core
#(
    
    parameter CONFIG_BASE = 32'h40000000,
    parameter PAGE_WIDTH = 10,
    parameter STREAMS_WIDTH = 3,
    parameter CMDFIFO_DEPTH = 10
)
(
    // ARM Connections    
    inout [53:0] MIO,
    input 	 PS_SRSTB,
    input 	 PS_CLK,
    input 	 PS_PORB,
    inout 	 DDR_Clk,
    inout 	 DDR_Clk_n,
    inout 	 DDR_CKE,
    inout 	 DDR_CS_n,
    inout 	 DDR_RAS_n,
    inout 	 DDR_CAS_n,
    output 	 DDR_WEB_pin,
    inout [2:0]  DDR_BankAddr,
    inout [14:0] DDR_Addr,
    inout 	 DDR_ODT,
    inout 	 DDR_DRSTB,
    inout [31:0] DDR_DQ,
    inout [3:0]  DDR_DM,
    inout [3:0]  DDR_DQS,
    inout [3:0]  DDR_DQS_n,
    inout 	 DDR_VRP,
    inout 	 DDR_VRN,

    //clocks and reset from the fabric
    output core_clk_out,
    output core_rst_out,
    output core_arst_out,

    //gpio bus IO from the fabric
    output [31:0] gpio_out,
    input [31:0] gpio_in,

    //axi fifo out from data mover
    output [63:0] h2s_tdata,
    output h2s_tlast,
    output h2s_tvalid,
    input h2s_tready,

    //axi fifo in to data mover
    input [63:0] s2h_tdata,
    input s2h_tlast,
    input s2h_tvalid,
    output s2h_tready,

    output [31:0] debug

);

    ////////////////////////////////////////////////////////////
    //-- connections going into the blackbox stub
    ////////////////////////////////////////////////////////////
    wire [31:0] processing_system7_0_GPIO_I_pin;
    wire [31:0] processing_system7_0_GPIO_O_pin;
    wire processing_system7_0_FCLK_CLK0_pin;
    wire processing_system7_0_FCLK_RESET0_N_pin;
    wire [31:0] axi_ext_slave_conn_0_M_AXI_AWADDR_pin;
    wire axi_ext_slave_conn_0_M_AXI_AWVALID_pin;
    wire axi_ext_slave_conn_0_M_AXI_AWREADY_pin;
    wire [31:0] axi_ext_slave_conn_0_M_AXI_WDATA_pin;
    wire [3:0] axi_ext_slave_conn_0_M_AXI_WSTRB_pin;
    wire axi_ext_slave_conn_0_M_AXI_WVALID_pin;
    wire axi_ext_slave_conn_0_M_AXI_WREADY_pin;
    wire [1:0] axi_ext_slave_conn_0_M_AXI_BRESP_pin;
    wire axi_ext_slave_conn_0_M_AXI_BVALID_pin;
    wire axi_ext_slave_conn_0_M_AXI_BREADY_pin;
    wire [31:0] axi_ext_slave_conn_0_M_AXI_ARADDR_pin;
    wire axi_ext_slave_conn_0_M_AXI_ARVALID_pin;
    wire axi_ext_slave_conn_0_M_AXI_ARREADY_pin;
    wire [31:0] axi_ext_slave_conn_0_M_AXI_RDATA_pin;
    wire [1:0] axi_ext_slave_conn_0_M_AXI_RRESP_pin;
    wire axi_ext_slave_conn_0_M_AXI_RVALID_pin;
    wire axi_ext_slave_conn_0_M_AXI_RREADY_pin;
    wire [31:0] axi_ext_master_conn_0_S_AXI_AWADDR_pin;
    wire [2:0] axi_ext_master_conn_0_S_AXI_AWPROT_pin;
    wire axi_ext_master_conn_0_S_AXI_AWVALID_pin;
    wire axi_ext_master_conn_0_S_AXI_AWREADY_pin;
    wire [63:0] axi_ext_master_conn_0_S_AXI_WDATA_pin;
    wire [7:0] axi_ext_master_conn_0_S_AXI_WSTRB_pin;
    wire axi_ext_master_conn_0_S_AXI_WVALID_pin;
    wire axi_ext_master_conn_0_S_AXI_WREADY_pin;
    wire [1:0] axi_ext_master_conn_0_S_AXI_BRESP_pin;
    wire axi_ext_master_conn_0_S_AXI_BVALID_pin;
    wire axi_ext_master_conn_0_S_AXI_BREADY_pin;
    wire [31:0] axi_ext_master_conn_0_S_AXI_ARADDR_pin;
    wire [2:0] axi_ext_master_conn_0_S_AXI_ARPROT_pin;
    wire axi_ext_master_conn_0_S_AXI_ARVALID_pin;
    wire axi_ext_master_conn_0_S_AXI_ARREADY_pin;
    wire [63:0] axi_ext_master_conn_0_S_AXI_RDATA_pin;
    wire [1:0] axi_ext_master_conn_0_S_AXI_RRESP_pin;
    wire axi_ext_master_conn_0_S_AXI_RVALID_pin;
    wire axi_ext_master_conn_0_S_AXI_RREADY_pin;
    wire [3:0] axi_ext_master_conn_0_S_AXI_ARCACHE_pin;
    wire [7:0] axi_ext_master_conn_0_S_AXI_AWLEN_pin;
    wire [2:0] axi_ext_master_conn_0_S_AXI_AWSIZE_pin;
    wire [1:0] axi_ext_master_conn_0_S_AXI_AWBURST_pin;
    wire [3:0] axi_ext_master_conn_0_S_AXI_AWCACHE_pin;
    wire axi_ext_master_conn_0_S_AXI_WLAST_pin;
    wire [7:0] axi_ext_master_conn_0_S_AXI_ARLEN_pin;
    wire [1:0] axi_ext_master_conn_0_S_AXI_ARBURST_pin;
    wire [2:0] axi_ext_master_conn_0_S_AXI_ARSIZE_pin;
    wire [15:0] processing_system7_0_IRQ_F2P_pin;

    //------------------------------------------------------------------
    //-- misc IO assignments for output connection foo
    //------------------------------------------------------------------
    assign gpio_out = processing_system7_0_GPIO_O_pin;
    assign processing_system7_0_GPIO_I_pin = gpio_in;
    wire stream_irq;
    assign processing_system7_0_IRQ_F2P_pin[15:0] = {15'b0, stream_irq};
    BUFG core_clk_gen
    (
        .I(processing_system7_0_FCLK_CLK0_pin),
        .O(core_clk_out)
    );
    assign core_arst_out = !processing_system7_0_FCLK_RESET0_N_pin;
    reset_sync core_rst_gen
    (
        .clk(core_clk_out),
        .reset_in(core_arst_out),
        .reset_out(core_rst_out)
    );

    //------------------------------------------------------------------
    //-- FIFO fabric: data pusher, HP bus, GP bus
    //------------------------------------------------------------------
    zynq_fifo_top
    #(
        .CONFIG_BASE(CONFIG_BASE),
        .PAGE_WIDTH(PAGE_WIDTH),
        .H2S_STREAMS_WIDTH(STREAMS_WIDTH),
        .H2S_CMDFIFO_DEPTH(CMDFIFO_DEPTH),
        .S2H_STREAMS_WIDTH(STREAMS_WIDTH),
        .S2H_CMDFIFO_DEPTH(CMDFIFO_DEPTH)
    ) my_zynq_fifo_top
    (
        .clk(core_clk_out), .rst(core_rst_out),
        .CTL_AXI_AWADDR(axi_ext_slave_conn_0_M_AXI_AWADDR_pin),
        .CTL_AXI_AWVALID(axi_ext_slave_conn_0_M_AXI_AWVALID_pin),
        .CTL_AXI_AWREADY(axi_ext_slave_conn_0_M_AXI_AWREADY_pin),
        .CTL_AXI_WDATA(axi_ext_slave_conn_0_M_AXI_WDATA_pin),
        .CTL_AXI_WSTRB(axi_ext_slave_conn_0_M_AXI_WSTRB_pin),
        .CTL_AXI_WVALID(axi_ext_slave_conn_0_M_AXI_WVALID_pin),
        .CTL_AXI_WREADY(axi_ext_slave_conn_0_M_AXI_WREADY_pin),
        .CTL_AXI_BRESP(axi_ext_slave_conn_0_M_AXI_BRESP_pin),
        .CTL_AXI_BVALID(axi_ext_slave_conn_0_M_AXI_BVALID_pin),
        .CTL_AXI_BREADY(axi_ext_slave_conn_0_M_AXI_BREADY_pin),
        .CTL_AXI_ARADDR(axi_ext_slave_conn_0_M_AXI_ARADDR_pin),
        .CTL_AXI_ARVALID(axi_ext_slave_conn_0_M_AXI_ARVALID_pin),
        .CTL_AXI_ARREADY(axi_ext_slave_conn_0_M_AXI_ARREADY_pin),
        .CTL_AXI_RDATA(axi_ext_slave_conn_0_M_AXI_RDATA_pin),
        .CTL_AXI_RRESP(axi_ext_slave_conn_0_M_AXI_RRESP_pin),
        .CTL_AXI_RVALID(axi_ext_slave_conn_0_M_AXI_RVALID_pin),
        .CTL_AXI_RREADY(axi_ext_slave_conn_0_M_AXI_RREADY_pin),

        .DDR_AXI_AWADDR(axi_ext_master_conn_0_S_AXI_AWADDR_pin),
        .DDR_AXI_AWPROT(axi_ext_master_conn_0_S_AXI_AWPROT_pin),
        .DDR_AXI_AWVALID(axi_ext_master_conn_0_S_AXI_AWVALID_pin),
        .DDR_AXI_AWREADY(axi_ext_master_conn_0_S_AXI_AWREADY_pin),
        .DDR_AXI_WDATA(axi_ext_master_conn_0_S_AXI_WDATA_pin),
        .DDR_AXI_WSTRB(axi_ext_master_conn_0_S_AXI_WSTRB_pin),
        .DDR_AXI_WVALID(axi_ext_master_conn_0_S_AXI_WVALID_pin),
        .DDR_AXI_WREADY(axi_ext_master_conn_0_S_AXI_WREADY_pin),
        .DDR_AXI_BRESP(axi_ext_master_conn_0_S_AXI_BRESP_pin),
        .DDR_AXI_BVALID(axi_ext_master_conn_0_S_AXI_BVALID_pin),
        .DDR_AXI_BREADY(axi_ext_master_conn_0_S_AXI_BREADY_pin),
        .DDR_AXI_ARADDR(axi_ext_master_conn_0_S_AXI_ARADDR_pin),
        .DDR_AXI_ARPROT(axi_ext_master_conn_0_S_AXI_ARPROT_pin),
        .DDR_AXI_ARVALID(axi_ext_master_conn_0_S_AXI_ARVALID_pin),
        .DDR_AXI_ARREADY(axi_ext_master_conn_0_S_AXI_ARREADY_pin),
        .DDR_AXI_RDATA(axi_ext_master_conn_0_S_AXI_RDATA_pin),
        .DDR_AXI_RRESP(axi_ext_master_conn_0_S_AXI_RRESP_pin),
        .DDR_AXI_RVALID(axi_ext_master_conn_0_S_AXI_RVALID_pin),
        .DDR_AXI_RREADY(axi_ext_master_conn_0_S_AXI_RREADY_pin),
        .DDR_AXI_AWLEN(axi_ext_master_conn_0_S_AXI_AWLEN_pin ),
        .DDR_AXI_RLAST(axi_ext_master_conn_0_S_AXI_RLAST_pin ),
        .DDR_AXI_ARCACHE(axi_ext_master_conn_0_S_AXI_ARCACHE_pin ),
        .DDR_AXI_AWSIZE(axi_ext_master_conn_0_S_AXI_AWSIZE_pin ),
        .DDR_AXI_AWBURST(axi_ext_master_conn_0_S_AXI_AWBURST_pin ),
        .DDR_AXI_AWCACHE(axi_ext_master_conn_0_S_AXI_AWCACHE_pin ),
        .DDR_AXI_WLAST(axi_ext_master_conn_0_S_AXI_WLAST_pin ),
        .DDR_AXI_ARLEN(axi_ext_master_conn_0_S_AXI_ARLEN_pin ),
        .DDR_AXI_ARBURST(axi_ext_master_conn_0_S_AXI_ARBURST_pin ),
        .DDR_AXI_ARSIZE(axi_ext_master_conn_0_S_AXI_ARSIZE_pin ),

        .h2s_tdata(h2s_tdata),
        .h2s_tlast(h2s_tlast),
        .h2s_tvalid(h2s_tvalid),
        .h2s_tready(h2s_tready),

        .s2h_tdata(s2h_tdata),
        .s2h_tlast(s2h_tlast),
        .s2h_tvalid(s2h_tvalid),
        .s2h_tready(s2h_tready),

        .event_irq(stream_irq)
    );

    //------------------------------------------------------------------
    //-- the magic box with AXI interconnects and ARM shit
    //------------------------------------------------------------------
    e200_ps e200_ps_instance(
    .processing_system7_0_MIO(MIO),
    .processing_system7_0_PS_SRSTB_pin(PS_SRSTB),
    .processing_system7_0_PS_CLK_pin(PS_CLK),
    .processing_system7_0_PS_PORB_pin(PS_PORB),
    .processing_system7_0_DDR_Clk(DDR_Clk),
    .processing_system7_0_DDR_Clk_n(DDR_Clk_n),
    .processing_system7_0_DDR_CKE(DDR_CKE),
    .processing_system7_0_DDR_CS_n(DDR_CS_n),
    .processing_system7_0_DDR_RAS_n(DDR_RAS_n),
    .processing_system7_0_DDR_CAS_n(DDR_CAS_n),
    .processing_system7_0_DDR_WEB_pin(DDR_WEB_pin),
    .processing_system7_0_DDR_BankAddr(DDR_BankAddr),
    .processing_system7_0_DDR_Addr(DDR_Addr),
    .processing_system7_0_DDR_ODT(DDR_ODT),
    .processing_system7_0_DDR_DRSTB(DDR_DRSTB),
    .processing_system7_0_DDR_DQ(DDR_DQ),
    .processing_system7_0_DDR_DM(DDR_DM),
    .processing_system7_0_DDR_DQS(DDR_DQS),
    .processing_system7_0_DDR_DQS_n(DDR_DQS_n),
    .processing_system7_0_DDR_VRN(DDR_VRN),
    .processing_system7_0_DDR_VRP(DDR_VRP),
    .axi_ext_slave_conn_0_M_AXI_AWADDR_pin(axi_ext_slave_conn_0_M_AXI_AWADDR_pin),
    .axi_ext_slave_conn_0_M_AXI_AWVALID_pin(axi_ext_slave_conn_0_M_AXI_AWVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_AWREADY_pin(axi_ext_slave_conn_0_M_AXI_AWREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_WDATA_pin(axi_ext_slave_conn_0_M_AXI_WDATA_pin),
    .axi_ext_slave_conn_0_M_AXI_WSTRB_pin(axi_ext_slave_conn_0_M_AXI_WSTRB_pin),
    .axi_ext_slave_conn_0_M_AXI_WVALID_pin(axi_ext_slave_conn_0_M_AXI_WVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_WREADY_pin(axi_ext_slave_conn_0_M_AXI_WREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_BRESP_pin(axi_ext_slave_conn_0_M_AXI_BRESP_pin),
    .axi_ext_slave_conn_0_M_AXI_BVALID_pin(axi_ext_slave_conn_0_M_AXI_BVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_BREADY_pin(axi_ext_slave_conn_0_M_AXI_BREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_ARADDR_pin(axi_ext_slave_conn_0_M_AXI_ARADDR_pin),
    .axi_ext_slave_conn_0_M_AXI_ARVALID_pin(axi_ext_slave_conn_0_M_AXI_ARVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_ARREADY_pin(axi_ext_slave_conn_0_M_AXI_ARREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_RDATA_pin(axi_ext_slave_conn_0_M_AXI_RDATA_pin),
    .axi_ext_slave_conn_0_M_AXI_RRESP_pin(axi_ext_slave_conn_0_M_AXI_RRESP_pin),
    .axi_ext_slave_conn_0_M_AXI_RVALID_pin(axi_ext_slave_conn_0_M_AXI_RVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_RREADY_pin(axi_ext_slave_conn_0_M_AXI_RREADY_pin),
    .processing_system7_0_IRQ_F2P_pin(processing_system7_0_IRQ_F2P_pin),
    .processing_system7_0_GPIO_I_pin(processing_system7_0_GPIO_I_pin),
    .processing_system7_0_GPIO_O_pin(processing_system7_0_GPIO_O_pin),
    .processing_system7_0_FCLK_CLK0_pin(processing_system7_0_FCLK_CLK0_pin),
    .processing_system7_0_FCLK_RESET0_N_pin(processing_system7_0_FCLK_RESET0_N_pin),
    .axi_ext_master_conn_0_S_AXI_AWADDR_pin ( axi_ext_master_conn_0_S_AXI_AWADDR_pin ),
    .axi_ext_master_conn_0_S_AXI_AWPROT_pin ( axi_ext_master_conn_0_S_AXI_AWPROT_pin ),
    .axi_ext_master_conn_0_S_AXI_AWVALID_pin ( axi_ext_master_conn_0_S_AXI_AWVALID_pin ),
    .axi_ext_master_conn_0_S_AXI_AWREADY_pin ( axi_ext_master_conn_0_S_AXI_AWREADY_pin ),
    .axi_ext_master_conn_0_S_AXI_WDATA_pin ( axi_ext_master_conn_0_S_AXI_WDATA_pin ),
    .axi_ext_master_conn_0_S_AXI_WSTRB_pin ( axi_ext_master_conn_0_S_AXI_WSTRB_pin ),
    .axi_ext_master_conn_0_S_AXI_WVALID_pin ( axi_ext_master_conn_0_S_AXI_WVALID_pin ),
    .axi_ext_master_conn_0_S_AXI_WREADY_pin ( axi_ext_master_conn_0_S_AXI_WREADY_pin ),
    .axi_ext_master_conn_0_S_AXI_BRESP_pin ( axi_ext_master_conn_0_S_AXI_BRESP_pin ),
    .axi_ext_master_conn_0_S_AXI_BVALID_pin ( axi_ext_master_conn_0_S_AXI_BVALID_pin ),
    .axi_ext_master_conn_0_S_AXI_BREADY_pin ( axi_ext_master_conn_0_S_AXI_BREADY_pin ),
    .axi_ext_master_conn_0_S_AXI_ARADDR_pin ( axi_ext_master_conn_0_S_AXI_ARADDR_pin ),
    .axi_ext_master_conn_0_S_AXI_ARPROT_pin ( axi_ext_master_conn_0_S_AXI_ARPROT_pin ),
    .axi_ext_master_conn_0_S_AXI_ARVALID_pin ( axi_ext_master_conn_0_S_AXI_ARVALID_pin ),
    .axi_ext_master_conn_0_S_AXI_ARREADY_pin ( axi_ext_master_conn_0_S_AXI_ARREADY_pin ),
    .axi_ext_master_conn_0_S_AXI_RDATA_pin ( axi_ext_master_conn_0_S_AXI_RDATA_pin ),
    .axi_ext_master_conn_0_S_AXI_RRESP_pin ( axi_ext_master_conn_0_S_AXI_RRESP_pin ),
    .axi_ext_master_conn_0_S_AXI_RVALID_pin ( axi_ext_master_conn_0_S_AXI_RVALID_pin ),
    .axi_ext_master_conn_0_S_AXI_RREADY_pin ( axi_ext_master_conn_0_S_AXI_RREADY_pin ),
    .axi_ext_master_conn_0_S_AXI_AWLEN_pin ( axi_ext_master_conn_0_S_AXI_AWLEN_pin ),
    .axi_ext_master_conn_0_S_AXI_RLAST_pin ( axi_ext_master_conn_0_S_AXI_RLAST_pin ),
    .axi_ext_master_conn_0_S_AXI_ARCACHE_pin ( axi_ext_master_conn_0_S_AXI_ARCACHE_pin ),
    .axi_ext_master_conn_0_S_AXI_AWSIZE_pin ( axi_ext_master_conn_0_S_AXI_AWSIZE_pin ),
    .axi_ext_master_conn_0_S_AXI_AWBURST_pin ( axi_ext_master_conn_0_S_AXI_AWBURST_pin ),
    .axi_ext_master_conn_0_S_AXI_AWCACHE_pin ( axi_ext_master_conn_0_S_AXI_AWCACHE_pin ),
    .axi_ext_master_conn_0_S_AXI_WLAST_pin ( axi_ext_master_conn_0_S_AXI_WLAST_pin ),
    .axi_ext_master_conn_0_S_AXI_ARLEN_pin ( axi_ext_master_conn_0_S_AXI_ARLEN_pin ),
    .axi_ext_master_conn_0_S_AXI_ARBURST_pin ( axi_ext_master_conn_0_S_AXI_ARBURST_pin ),
    .axi_ext_master_conn_0_S_AXI_ARSIZE_pin ( axi_ext_master_conn_0_S_AXI_ARSIZE_pin ));

endmodule // zynq_system_core
