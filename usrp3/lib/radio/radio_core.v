//
// Copyright 2015 Ettus Research
//
// radio_core
//   Contains all clock-rate DSP components, all radio and hardware controls and settings
//   Designed to connect to a noc_shell

module radio_core #(
  parameter BASE = 0,
  parameter RADIO_NUM = 0,
  // Bypass signal processing blocks to save resources
  parameter BYPASS_TX_DC_OFFSET_CORR = 0,
  parameter BYPASS_RX_DC_OFFSET_CORR = 0,
  parameter BYPASS_TX_IQ_COMP = 0,
  parameter BYPASS_RX_IQ_COMP = 0,
  parameter DEVICE = "7SERIES"
)(
  input clk, input rst,
  input [15:0] src_sid,         // Stream ID of this block
  input [15:0] dst_sid,         // Stream ID of downstream block
  input [63:0] vita_time,
  input [63:0] vita_time_lastpps,
  // Interface to the physical radio (ADC, DAC, controls)
  input [31:0] rx, input rx_stb, output run_rx,
  output [31:0] tx, input tx_stb, output run_tx,
  // Interface to the NoC Shell
  input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data,
  input [31:0] tx_tdata, input tx_tlast, input tx_tvalid, output tx_tready, input [127:0] tx_tuser,
  output [31:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready, output [127:0] rx_tuser,
  output [63:0] txresp_tdata, output txresp_tlast, output txresp_tvalid, input txresp_tready
);

  wire [31:0] test_readback;

  wire [3:0]  rb_addr;
  wire        loopback;


  /********************************************************
  ** Settings Bus Register Addresses
  ********************************************************/
  // Addresses 0 - 2 in use outside this module
  localparam SR_LOOPBACK             = BASE + 8'd3;
  localparam SR_TEST                 = BASE + 8'd4;
  localparam SR_CODEC_IDLE           = BASE + 8'd5;
  localparam SR_RESP_DST_SID         = BASE + 8'd6;
  // TX / RX Control
  localparam SR_TX_CTRL_ERROR_POLICY = BASE + 8'd64;
  localparam SR_RX_CTRL_COMMAND      = BASE + 8'd80;
  localparam SR_RX_CTRL_TIME_HI      = BASE + 8'd81;
  localparam SR_RX_CTRL_TIME_LO      = BASE + 8'd82;
  localparam SR_RX_CTRL_HALT         = BASE + 8'd83;
  localparam SR_RX_CTRL_MAXLEN       = BASE + 8'd84;
  localparam SR_RX_CTRL_SID          = BASE + 8'd85;
  // TX / RX Frontend
  localparam SR_TX_DC_OFFSET_I       = BASE + 8'd96;
  localparam SR_TX_DC_OFFSET_Q       = BASE + 8'd97;
  localparam SR_TX_MAG_CORRECTION    = BASE + 8'd98;
  localparam SR_TX_PHASE_CORRECTION  = BASE + 8'd99;
  localparam SR_TX_MUX               = BASE + 8'd100;
  localparam SR_RX_SWAP_IQ           = BASE + 8'd112;
  localparam SR_RX_MAG_CORRECTION    = BASE + 8'd113;
  localparam SR_RX_PHASE_CORRECTION  = BASE + 8'd114;
  localparam SR_RX_OFFSET_I          = BASE + 8'd115;
  localparam SR_RX_OFFSET_Q          = BASE + 8'd116;
  // Misc
  localparam SR_READBACK             = BASE + 8'd127;

  localparam RB_VITA_TIME            = 4'd0;
  localparam RB_VITA_LASTPPS         = 4'd1;
  localparam RB_RX                   = 4'd2;
  localparam RB_TXRX                 = 4'd3;
  localparam RB_RADIO_NUM            = 4'd4;


  /********************************************************
  ** Settings Bus / Readback Registers
  ********************************************************/
  always @(posedge clk) begin
    if (rst) begin
      rb_data <= 64'd0;
    end else begin
      case (rb_addr)
        RB_VITA_TIME    : rb_data <= vita_time;
        RB_VITA_LASTPPS : rb_data <= vita_time_lastpps;
        RB_RX           : rb_data <= {rx, test_readback};
        RB_TXRX         : rb_data <= {tx,rx};
        RB_RADIO_NUM    : rb_data <= {32'h0,RADIO_NUM[31:0]};
        default         : rb_data <= 64'd0;
      endcase // case (rb_addr)
    end
  end

  // Set this register to loop TX data directly to RX data.
  setting_reg #(.my_addr(SR_LOOPBACK), .width(1)) sr_loopback (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(loopback), .changed());

  // Set this register to put a test value on the readback mux.
  setting_reg #(.my_addr(SR_TEST), .width(32)) sr_test (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(test_readback), .changed());

  setting_reg #(.my_addr(SR_READBACK), .width(4)) sr_rdback (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(rb_addr), .changed());


  /********************************************************
  ** TX Chain
  ********************************************************/
  wire        strobe_tx;
  wire [31:0] tx_idle;

  setting_reg #(.my_addr(SR_CODEC_IDLE), .awidth(8), .width(32)) sr_codec_idle (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(tx_idle), .changed());

  setting_reg #(.my_addr(SR_RESP_DST_SID), .awidth(16), .width(32)) sr_resp_dst_sid (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(resp_dst_sid), .changed());

  wire [175:0]  txsample_tdata;
  wire          txsample_tvalid, txsample_tready;
  wire [31:0]   sample_tx;
  wire          tx_ack, tx_error;
  wire [11:0]   seqnum;
  wire [63:0]   error_code;

  tx_control_gen3 #(.SR_ERROR_POLICY(SR_TX_CTRL_ERROR_POLICY)) tx_control_gen3 (
    .clk(clk), .rst(rst), .clear(1'b0),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .vita_time(vita_time),
    .tx_tdata(tx_tdata), .tx_tuser(tx_tuser), .tx_tlast(tx_tlast), .tx_tvalid(tx_tvalid), .tx_tready(tx_tready),
    .error(tx_error), .seqnum(seqnum), .error_code(error_code),
    .run(run_tx), .sample(sample_tx), .strobe(tx_stb));

  tx_responder tx_responder (
    .clk(clk), .reset(rst), .clear(1'b0),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .ack(tx_ack), .error(tx_error), .packet_consumed(1'b0),
    .seqnum(seqnum), .error_code(error_code),
    .sid({src_sid, resp_dst_sid}), .vita_time(vita_time),
    .o_tdata(txresp_tdata), .o_tlast(txresp_tlast), .o_tvalid(txresp_tvalid), .o_tready(txresp_tready));

  wire [15:0]   tx_i, tx_q;

  // TX DC Offset, Magnitude, & Phase correction
  tx_frontend_gen3 #(
    .SR_MAG_CORRECTION(SR_TX_MAG_CORRECTION),
    .SR_PHASE_CORRECTION(SR_TX_PHASE_CORRECTION),
    .SR_OFFSET_I(SR_TX_DC_OFFSET_I),
    .SR_OFFSET_Q(SR_TX_DC_OFFSET_Q),
    .SR_MUX(SR_TX_MUX),
    .BYPASS_DC_OFFSET_CORR(BYPASS_TX_DC_OFFSET_CORR),
    .BYPASS_IQ_COMP(BYPASS_TX_IQ_COMP),
    .DEVICE(DEVICE))
  tx_frontend_gen3 (
    .clk(clk), .rst(rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .tx_stb(tx_stb), .tx_i({sample_tx[31:16],8'h0}), .tx_q({sample_tx[15:0],8'h0}), .run(run_tx),
    .dac_stb(), .dac_i(tx_i), .dac_q(tx_q));

  assign tx        = run_tx ? {tx_i,tx_q} : tx_idle;


  /********************************************************
  ** RX Chain
  ********************************************************/
  wire         rx_fe_stb;
  wire [31:0]  rx_fe;
  wire [31:0]  sample_rx     = loopback ? tx   : rx_fe;     // Digital Loopback TX -> RX (Pipeline immediately inside rx_frontend)
  wire         sample_rx_stb = loopback ? 1'b1 : rx_fe_stb;

  rx_control_gen3 #(
    .SR_RX_CTRL_COMMAND(SR_RX_CTRL_COMMAND),
    .SR_RX_CTRL_TIME_HI(SR_RX_CTRL_TIME_HI),
    .SR_RX_CTRL_TIME_LO(SR_RX_CTRL_TIME_LO),
    .SR_RX_CTRL_HALT(SR_RX_CTRL_HALT),
    .SR_RX_CTRL_MAXLEN(SR_RX_CTRL_MAXLEN))
  rx_control_gen3 (
    .clk(clk), .rst(rst), .clear(1'b0),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .sid({src_sid,dst_sid}), .error_sid({src_sid,resp_dst_sid}), .vita_time(vita_time),
    .strobe(sample_rx_stb), .sample(sample_rx), .run(run_rx),
    .rx_tdata(rx_tdata), .rx_tlast(rx_tlast), .rx_tvalid(rx_tvalid), .rx_tready(rx_tready), .rx_tuser(rx_tuser));

  // RX DC offset, magnitude, phase correction, & CORDIC based fine frequency tuning
  rx_frontend_gen3 #(
    .SR_MAG_CORRECTION(SR_RX_MAG_CORRECTION),
    .SR_PHASE_CORRECTION(SR_RX_PHASE_CORRECTION),
    .SR_OFFSET_I(SR_RX_OFFSET_I),
    .SR_OFFSET_Q(SR_RX_OFFSET_Q),
    .SR_SWAP_IQ(SR_RX_SWAP_IQ),
    .BYPASS_DC_OFFSET_CORR(BYPASS_RX_DC_OFFSET_CORR),
    .BYPASS_IQ_COMP(BYPASS_RX_IQ_COMP),
    .DEVICE(DEVICE))
  rx_frontend_gen3 (
    .clk(clk),.rst(rst), .run(run_rx),
    .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
    .adc_stb(rx_stb), .adc_i(rx[31:16]),.adc_q(rx[15:0]),
    .rx_stb(rx_fe_stb), .rx_i(rx_fe[31:16]), .rx_q(rx_fe[15:0]));

endmodule