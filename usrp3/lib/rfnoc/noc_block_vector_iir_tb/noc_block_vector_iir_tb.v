//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_block_vector_iir_tb();
  /*********************************************
  ** User variables
  *********************************************/
  localparam CLOCK_FREQ = 200e6;  // MHz
  localparam RESET_TIME = 100;    // ns

  /*********************************************
  ** Helper Tasks
  *********************************************/
  `include "rfnoc_sim_lib.v" 

  /*********************************************
  ** DUT
  *********************************************/
  noc_block_vector_iir inst_noc_block_vector_iir (
    .bus_clk(clk), .bus_rst(rst),
    .ce_clk(clk), .ce_rst(rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .debug());

  localparam [15:0] FFT_SIZE = 8;

  wire [7:0] fft_size_log2 = $clog2(FFT_SIZE);      // Set FFT size
  wire fft_direction       = 0;                     // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale    = 12'b011010101010;      // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word = {fft_scale, fft_direction, fft_size_log2};

  integer i;
  reg [63:0] payload = 64'd0;

  initial begin
    @(negedge rst);
    @(posedge clk);
    
    // Setup Vector IIR
    SendCtrlPacket(12'd0, 32'h0003_0000, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});               // Command packet to set up flow control
    SendCtrlPacket(12'd0, 32'h0003_0000, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});                // Command packet to set up source control window size
    SendCtrlPacket(12'd0, 32'h0003_0000, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                  // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, 32'h0003_0000, {24'd0, SR_NEXT_DST_BASE, {16'd0,32'h0000_0001}});                     // Set next destination
    SendCtrlPacket(12'd0, 32'h0003_0000, {32'd129, 16'd0, FFT_SIZE});  // Set Vector length register
    SendCtrlPacket(12'd0, 32'h0003_0000, {32'd130, 32'h7FFF_FFFF});    // Alpha = 1 (as close as we can get)
    SendCtrlPacket(12'd0, 32'h0003_0000, {32'd131, 32'h4000_0000});     // 1 - Alpha = 0.5
    #1000;

    // Send 1/8th sample rate sine wave
    @(posedge clk);
    forever begin
      SendChdr(CHDR_DATA_PKT_TYPE, 0, 12'd0, FFT_SIZE*SC16_NUM_BYTES, {32'h0000_0001,32'h0001_0003}, 0);
      for (i = 0; i < (FFT_SIZE/RFNOC_CHDR_NUM_SC16_PER_LINE); i = i + 1) begin
        payload[63:48] = 4*i;
        payload[47:32] = 4*i+1;
        payload[31:16] = 4*i+2;
        payload[15: 0] = 4*i+3;
        SendPayload(payload,(i == (FFT_SIZE/RFNOC_CHDR_NUM_SC16_PER_LINE)-1)); // Assert tlast on final word
      end
    end
  end

endmodule