//////////////////////////////////////
//
//  2017 Ettus Research
//
//////////////////////////////////////

module n310_core (

   //Clocks and resets
   input                radio_clk,
   input                radio_rst,
   input                bus_clk,
   input                bus_rst,

   // Radio 0
   input        [31:0]  rx0,
   output       [31:0]  tx0,
   //input        [31:0]  db0_gpio_in,
   //output       [31:0]  db0_gpio_out,
   //output       [31:0]  db0_gpio_ddr,
   //input        [31:0]  fp_gpio_in,
   //output       [31:0]  fp_gpio_out,
   //output       [31:0]  fp_gpio_ddr,
   //output       [7:0]   sen0,
   //output               sclk0,
   //output               mosi0,
   //input                miso0,
   //output       [2:0]   radio_led0,
   //output reg   [31:0]  radio0_misc_out,
   //input        [31:0]  radio0_misc_in,

   // Radio 1
   input        [31:0]  rx1,
   output       [31:0]  tx1,
   //input        [31:0]  db1_gpio_in,
   //output       [31:0]  db1_gpio_out,
   //output       [31:0]  db1_gpio_ddr,
   //output       [7:0]   sen1,
   //output               sclk1,
   //output               mosi1,
   //input                miso1,
   //output       [2:0]   radio_led1,
   //output reg   [31:0]  radio1_misc_out,
   //input        [31:0]  radio1_misc_in,

   // Clock control
   input                ext_ref_clk,

   // SFP+ 0 data stream
   output       [63:0]  sfp0_tx_tdata,
   output       [3:0]   sfp0_tx_tuser,
   output               sfp0_tx_tlast,
   output               sfp0_tx_tvalid,
   input                sfp0_tx_tready,

   input        [63:0]  sfp0_rx_tdata,
   input        [3:0]   sfp0_rx_tuser,
   input                sfp0_rx_tlast,
   input                sfp0_rx_tvalid,
   output               sfp0_rx_tready,

   input        [15:0]  sfp0_phy_status,

   // SFP+ 1 data stream
   output       [63:0]  sfp1_tx_tdata,
   output       [3:0]   sfp1_tx_tuser,
   output               sfp1_tx_tlast,
   output               sfp1_tx_tvalid,
   input                sfp1_tx_tready,

   input        [63:0]  sfp1_rx_tdata,
   input        [3:0]   sfp1_rx_tuser,
   input                sfp1_rx_tlast,
   input                sfp1_rx_tvalid,
   output               sfp1_rx_tready,

   // CPU
   output       [63:0]  cpui_tdata,
   output       [3:0]   cpui_tuser,
   output               cpui_tlast,
   output               cpui_tvalid,
   input                cpui_tready,

   input        [63:0]  cpuo_tdata,
   input        [3:0]   cpuo_tuser,
   input                cpuo_tlast,
   input                cpuo_tvalid,
   output               cpuo_tready,

   input        [15:0]  sfp1_phy_status
);

   // Computation engines that need access to IO
   localparam NUM_IO_CE = 3;

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

   /////////////////////////////////////////////////////////////////////////////////
   // Ethernet Soft Switch
   /////////////////////////////////////////////////////////////////////////////////

   eth_switch #(.NUM_CE(NUM_CE + NUM_IO_CE)) eth_switch
   (
    .clk(bus_clk),
    .reset(bus_rst),

    // Eth0
    .sfp0_tx_tdata(sfp0_tx_tdata),
    .sfp0_tx_tuser(sfp0_tx_tuser),
    .sfp0_tx_tlast(sfp0_tx_tlast),
    .sfp0_tx_tvalid(sfp0_tx_tvalid),
    .sfp0_tx_tready(sfp0_tx_tready),

    .sfp0_rx_tdata(sfp0_rx_tdata),
    .sfp0_rx_tuser(sfp0_rx_tuser),
    .sfp0_rx_tlast(sfp0_rx_tlast),
    .sfp0_rx_tvalid(sfp0_rx_tvalid),
    .sfp0_rx_tready(sfp0_rx_tready),

    // Eth1
    .sfp1_tx_tdata(sfp1_tx_tdata),
    .sfp1_tx_tuser(sfp1_tx_tuser),
    .sfp1_tx_tlast(sfp1_tx_tlast),
    .sfp1_tx_tvalid(sfp1_tx_tvalid),
    .sfp1_tx_tready(sfp1_tx_tready),

    .sfp1_rx_tdata(sfp1_rx_tdata),
    .sfp1_rx_tuser(sfp1_rx_tuser),
    .sfp1_rx_tlast(sfp1_rx_tlast),
    .sfp1_rx_tvalid(sfp1_rx_tvalid),
    .sfp1_rx_tready(sfp1_rx_tready),

    // Computation Engines
    .ce_o_tdata({ce_flat_o_tdata,ioce_flat_o_tdata}),
    .ce_o_tlast({ce_o_tlast,ioce_o_tlast}),
    .ce_o_tvalid({ce_o_tvalid,ioce_o_tvalid}),
    .ce_o_tready({ce_o_tready,ioce_o_tready}),

    .ce_i_tdata({ce_flat_i_tdata,ioce_flat_i_tdata}),
    .ce_i_tlast({ce_i_tlast,ioce_i_tlast}),
    .ce_i_tvalid({ce_i_tvalid,ioce_i_tvalid}),
    .ce_i_tready({ce_i_tready,ioce_i_tready}),

    // DMA
    .dmao_tdata(/*dmao_tdata*/),
    .dmao_tlast(/*dmao_tlast*/),
    .dmao_tvalid(/*dmao_tvalid*/),
    .dmao_tready(/*dmao_tready*/),

    .dmai_tdata(/*dmai_tdata*/),
    .dmai_tlast(/*dmai_tlast*/),
    .dmai_tvalid(/*dmai_tvalid*/),
    .dmai_tready(/*dmai_tready*/),

    // CPU
    .cpui_tdata(cpui_tdata),
    .cpui_tuser(cpui_tuser),
    .cpui_tlast(cpui_tlast),
    .cpui_tvalid(cpui_tvalid),
    .cpui_tready(cpui_tready),

    .cpuo_tdata(cpuo_tdata),
    .cpuo_tuser(cpuo_tuser),
    .cpuo_tlast(cpuo_tlast),
    .cpuo_tvalid(cpuo_tvalid),
    .cpuo_tready(cpuo_tready),

    //Status signals
    .sfp0_phy_status(sfp0_phy_status),
    .sfp1_phy_status(sfp1_phy_status)

   );

   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // Radios
   //
   /////////////////////////////////////////////////////////////////////////////////////////////

endmodule //n310_core
