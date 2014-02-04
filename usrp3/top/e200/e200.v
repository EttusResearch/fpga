
`timescale 1ns / 1ps
//`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2012 06:12:45 PM
// Design Name: 
// Module Name: the_really_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module e200(
    ////////////////////////////////////////////////////////////
    // Begin External Connections
    ////////////////////////////////////////////////////////////
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
    // END ARM Connections
    ////////////////////////////////////////////////////////////
    // Control connections for FPGA
    //input wire SYSCLK_P;
    //input wire SYSCLK_N;
    //input wire PS_SRST_B;

    //AVR SPI IO
    output 	 AVR_CS_R,
    input 	 AVR_IRQ,
    input 	 AVR_MISO_R,
    output 	 AVR_MOSI_R,
    output 	 AVR_SCK_R,

    input 	 ONSWITCH_DB,

    // RF Board connections
    // Change to inout/output as they are implemented/tested
    input [34:0] DB_EXP_1_8V,

    //band selects
    output [2:0]  TX_BANDSEL,
    output [2:0]  RX1_BANDSEL,
    output [2:0]  RX2_BANDSEL,
    output [1:0]  RX2C_BANDSEL,
    output [1:0]  RX1B_BANDSEL,
    output [1:0]  RX1C_BANDSEL,
    output [1:0]  RX2B_BANDSEL,

    //enables
    output 	 TX_ENABLE1A,
    output 	 TX_ENABLE2A,
    output 	 TX_ENABLE1B,
    output 	 TX_ENABLE2B,

    //antenna selects
    output 	 VCTXRX1_V1,
    output 	 VCTXRX1_V2,
    output 	 VCTXRX2_V1,
    output 	 VCTXRX2_V2,
    output 	 VCRX1_V1,
    output 	 VCRX1_V2,
    output 	 VCRX2_V1,
    output 	 VCRX2_V2,

    // leds
    output LED_TXRX1_TX,
    output LED_TXRX1_RX,
    output LED_RX1_RX,
    output LED_TXRX2_TX,
    output LED_TXRX2_RX,
    output LED_RX2_RX,

    //adi io
    input [7:0]  CAT_CTRL_OUT,
    output [3:0]  CAT_CTRL_IN,
    output 	 CAT_RESET,
    output 	 CAT_CS,
    output 	 CAT_SCLK,
    output 	 CAT_MOSI,
    input 	 CAT_MISO,
    input 	 CAT_BBCLK_OUT, //unused
    output 	 CAT_SYNC,
    output 	 CAT_TXNRX,
    output 	 CAT_ENABLE,
    output 	 CAT_ENAGC,
    input 	 CAT_RX_FRAME,
    input 	 CAT_DATA_CLK,
    output 	 CAT_TX_FRAME,
    output 	 CAT_FB_CLK,
    input [11:0] CAT_P0_D,
    output [11:0] CAT_P1_D

    );

    //------------------------------------------------------------------
    //-- generate clock and reset signals
    //------------------------------------------------------------------
    wire bus_clk, radio_clk;
    wire bus_rst, radio_rst, sys_arst;
    wire host_rst = CAT_CS & CAT_MOSI;
    reset_sync radio_sync(.clk(radio_clk), .reset_in(sys_arst), .reset_out(radio_rst));

    ////////////////////////////////////////////////////////////
    //-- zynq system core super IO stub farm
    ////////////////////////////////////////////////////////////
    wire [31:0] ps_gpio_out, ps_gpio_in;

    wire [63:0] h2s_tdata;
    wire h2s_tvalid;
    wire h2s_tready;
    wire h2s_tlast;

    wire [63:0] s2h_tdata;
    wire s2h_tvalid;
    wire s2h_tready;
    wire s2h_tlast;

    zynq_system_core zynq_system_core
    (
        .MIO(MIO),
        .PS_SRSTB(PS_SRSTB),
        .PS_CLK(PS_CLK),
        .PS_PORB(PS_PORB),
        .DDR_Clk(DDR_Clk),
        .DDR_Clk_n(DDR_Clk_n),
        .DDR_CKE(DDR_CKE),
        .DDR_CS_n(DDR_CS_n),
        .DDR_RAS_n(DDR_RAS_n),
        .DDR_CAS_n(DDR_CAS_n),
        .DDR_WEB_pin(DDR_WEB_pin),
        .DDR_BankAddr(DDR_BankAddr),
        .DDR_Addr(DDR_Addr),
        .DDR_ODT(DDR_ODT),
        .DDR_DRSTB(DDR_DRSTB),
        .DDR_DQ(DDR_DQ),
        .DDR_DM(DDR_DM),
        .DDR_DQS(DDR_DQS),
        .DDR_DQS_n(DDR_DQS_n),
        .DDR_VRP(DDR_VRP),
        .DDR_VRN(DDR_VRN),

        .core_clk_out(bus_clk),
        .core_rst_out(bus_rst),
        .core_arst_out(sys_arst),

        .gpio_out(ps_gpio_out),
        .gpio_in(ps_gpio_in),

        .h2s_tdata(h2s_tdata),
        .h2s_tlast(h2s_tlast),
        .h2s_tvalid(h2s_tvalid),
        .h2s_tready(h2s_tready),

        .s2h_tdata(s2h_tdata),
        .s2h_tlast(s2h_tlast),
        .s2h_tvalid(s2h_tvalid),
        .s2h_tready(s2h_tready),

        .debug()
    );

    //------------------------------------------------------------------
    // CODEC capture/gen
    //------------------------------------------------------------------
    wire   rx_clk, rx_strobe, tx_clk, tx_strobe;
    wire [11:0] rx_i0, rx_q0, rx_i1, rx_q1;
    wire [11:0] tx_i0, tx_q0, tx_i1, tx_q1;
    wire        mimo_rx, mimo_tx;
    wire        mosi, miso, sclk;
    wire [7:0]  sen;
    assign radio_clk = rx_clk;

    wire codec_data_clk;
    BUFG codec_data_clk_bufg (.I(CAT_DATA_CLK), .O(codec_data_clk));
    //IBUFG codec_data_clk_bufg (.I(CAT_DATA_CLK), .O(codec_data_clk));

    // CMOS Data interface to catalina, ignore _n pins
    catcap_ddr_cmos catcap
     (.data_clk(codec_data_clk), .reset(radio_rst), .mimo(mimo_rx),
      .rx_frame(CAT_RX_FRAME), .rx_d(CAT_P0_D),
      .rx_clk(rx_clk), .rx_strobe(rx_strobe),
      .i0(rx_i0), .q0(rx_q0),
      .i1(rx_i1), .q1(rx_q1));

    assign tx_clk = rx_clk;

    catgen_ddr_cmos catgen
     (.data_clk(CAT_FB_CLK), .reset(radio_rst), .mimo(mimo_tx),
      .tx_frame(CAT_TX_FRAME), .tx_d(CAT_P1_D),
      .tx_clk(tx_clk), .tx_strobe(tx_strobe),
      .i0(tx_i0), .q0(tx_q0),
      .i1(tx_i1), .q1(tx_q1));

    assign CAT_CTRL_IN = 4'b1;
    assign CAT_ENAGC = 1'b1;
    assign CAT_TXNRX = 1'b1;
    assign CAT_ENABLE = 1'b1;
    assign CAT_RESET = !(sys_arst || host_rst);   // Codec Reset // RESETB // Operates active-low
    assign CAT_SYNC = 1'b0;

    //------------------------------------------------------------------
    //-- connect misc stuff to user GPIO
    //------------------------------------------------------------------
    assign AVR_SCK_R  = ps_gpio_out[0];    //54
    assign AVR_MOSI_R = ps_gpio_out[1];    //55
    assign AVR_CS_R   = ps_gpio_out[2];    //56
    assign ps_gpio_in[4] = AVR_MISO_R;    //58
    assign ps_gpio_in[5] = AVR_IRQ;       //59
    assign ps_gpio_in[7] = ONSWITCH_DB;   //61

    assign CAT_SCLK = ps_gpio_out[8];      //62
    assign CAT_MOSI = ps_gpio_out[9];      //63
    assign CAT_CS   = ps_gpio_out[10];     //64
    assign ps_gpio_in[12] = CAT_MISO;     //66

    //------------------------------------------------------------------
    //-- chipscope debugs
    //------------------------------------------------------------------
    /*
    wire [35:0] CONTROL;
    wire [255:0] DATA;
    wire [7:0] TRIG;

    chipscope_icon chipscope_icon(.CONTROL0(CONTROL));
    chipscope_ila chipscope_ila
    (
        .CONTROL(CONTROL), .CLK(bus_clk),
        .DATA(DATA), .TRIG0(TRIG)
    );

    assign DATA[63:0] = h2s_tdata;
    assign TRIG = {
        h2s_tlast, h2s_tvalid, h2s_tready, 1'b0,
        4'b0
    };
    assign DATA[64] = h2s_tlast;
    assign DATA[65] = h2s_tvalid;
    assign DATA[66] = h2s_tready;
    */

    //------------------------------------------------------------------
    //-- radio core from x300 for super fast bring up
    //------------------------------------------------------------------
    wire [31:0] rx_data0, rx_data1;
    wire rx_enb0, rx_enb1;
    assign rx_data0 = {rx_i0, 4'b0, rx_q0, 4'b0};
    assign rx_data1 = {rx_i1, 4'b0, rx_q1, 4'b0};

    wire [31:0] tx_data0, tx_data1;
    wire tx_enb0, tx_enb1;
    assign {tx_i0, tx_q0} = {tx_data0[31:20], tx_data0[15:4]};
    assign {tx_i1, tx_q1} = {tx_data1[31:20], tx_data1[15:4]};
    //assign DATA[255:224] = tx_data0;

    assign mimo_rx = rx_enb0 && rx_enb1;
    assign mimo_tx = tx_enb0 && tx_enb1;

    //abtraction for shared tx bandsel pins
    wire [2:0] TX1_BANDSEL;
    wire [2:0] TX2_BANDSEL; //unused
    assign TX_BANDSEL = TX1_BANDSEL;

    wire [31:0] gpio0, gpio1;

    assign {
        rx_enb0, tx_enb0, //2
        LED_TXRX1_TX, LED_TXRX1_RX, LED_RX1_RX, //3
        VCRX1_V2, VCRX1_V1, VCTXRX1_V2, VCTXRX1_V1, //4
        TX_ENABLE1B, TX_ENABLE1A, //2
        RX1C_BANDSEL, RX1B_BANDSEL, RX1_BANDSEL, TX1_BANDSEL //10
    } = gpio0[20:0];

    assign {
        rx_enb1, tx_enb1, //2
        LED_TXRX2_TX, LED_TXRX2_RX, LED_RX2_RX, //3
        VCRX2_V2, VCRX2_V1, VCTXRX2_V2, VCTXRX2_V1, //4
        TX_ENABLE2B, TX_ENABLE2A, //2
        RX2C_BANDSEL, RX2B_BANDSEL, RX2_BANDSEL, TX2_BANDSEL //10
    } = gpio1[20:0];

    e200_core e200_core
    (
        .bus_clk(bus_clk),
        .bus_rst(bus_rst),

        .h2s_tdata(h2s_tdata),
        .h2s_tlast(h2s_tlast),
        .h2s_tvalid(h2s_tvalid),
        .h2s_tready(h2s_tready),

        .s2h_tdata(s2h_tdata),
        .s2h_tlast(s2h_tlast),
        .s2h_tvalid(s2h_tvalid),
        .s2h_tready(s2h_tready),

        .radio_clk(radio_clk),
        .radio_rst(radio_rst),
        .rx_data0(rx_data0),
        .tx_data0(tx_data0),
        .rx_data1(rx_data1),
        .tx_data1(tx_data1),

        .ctrl_out0(gpio0),
        .ctrl_out1(gpio1),

        .debug()
    );

endmodule
