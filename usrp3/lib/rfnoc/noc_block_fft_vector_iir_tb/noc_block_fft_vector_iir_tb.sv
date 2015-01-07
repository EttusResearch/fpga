//
// Copyright 2014-2015 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_block_fft_vector_iir_tb();
  // rfnoc_sim_lib options
  `define NUM_CE 3          // Redefined to correct value
  `define RFNOC_SIM_LIB_INC_AXI_WRAPPER
  `define SIMPLE_MODE 0
  `include "rfnoc_sim_lib.v" // Extremely useful for RFNoC based simulations

  /*********************************************
  ** DUT
  *********************************************/
  noc_block_fft #(
    .EN_MAGNITUDE_OUT(1),         // CORDIC based magnitude calculation
    .EN_MAGNITUDE_APPROX_OUT(0),  // Multiplier-less, lower resource usage
    .EN_MAGNITUDE_SQ_OUT(1),      // Magnitude squared
    .EN_FFT_SHIFT(1))             // Center zero frequency bin
  inst_noc_block_fft (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ce_clk), .ce_rst(ce_rst),
    .i_tdata(ce_o_tdata[0]), .i_tlast(ce_o_tlast[0]), .i_tvalid(ce_o_tvalid[0]), .i_tready(ce_o_tready[0]),
    .o_tdata(ce_i_tdata[0]), .o_tlast(ce_i_tlast[0]), .o_tvalid(ce_i_tvalid[0]), .o_tready(ce_i_tready[0]),
    .debug());

  noc_block_vector_iir inst_noc_block_vector_iir (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ce_clk), .ce_rst(ce_rst),
    .i_tdata(ce_o_tdata[1]), .i_tlast(ce_o_tlast[1]), .i_tvalid(ce_o_tvalid[1]), .i_tready(ce_o_tready[1]),
    .o_tdata(ce_i_tdata[1]), .o_tlast(ce_i_tlast[1]), .o_tvalid(ce_i_tvalid[1]), .o_tready(ce_i_tready[1]),
    .debug());

  noc_block_keep_one_in_n inst_noc_block_keep_one_in_n (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ce_clk), .ce_rst(ce_rst),
    .i_tdata(ce_o_tdata[2]), .i_tlast(ce_o_tlast[2]), .i_tvalid(ce_o_tvalid[2]), .i_tready(ce_o_tready[2]),
    .o_tdata(ce_i_tdata[2]), .o_tlast(ce_i_tlast[2]), .o_tvalid(ce_i_tvalid[2]), .o_tready(ce_i_tready[2]),
    .debug());

  localparam [3:0] FFT_XBAR_PORT           = 4'd0;
  localparam [3:0] VECTOR_IIR_XBAR_PORT    = 4'd1;
  localparam [3:0] KEEP_ONE_IN_N_XBAR_PORT = 4'd2;
  // Last 4 bits are block ports
  localparam [15:0] FFT_SID           = {XBAR_ADDR,           FFT_XBAR_PORT, 4'd0};
  localparam [15:0] VECTOR_IIR_SID    = {XBAR_ADDR,    VECTOR_IIR_XBAR_PORT, 4'd0};
  localparam [15:0] KEEP_ONE_IN_N_SID = {XBAR_ADDR, KEEP_ONE_IN_N_XBAR_PORT, 4'd0};

  localparam [15:0] FFT_SIZE = 256;
  
  wire [7:0] fft_size_log2 = $clog2(FFT_SIZE);      // Set FFT size
  wire fft_direction       = 0;                     // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale    = 12'b011010101010;      // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word = {fft_scale, fft_direction, fft_size_log2};
  integer i;

  wire signed [31:0] ALPHA = $floor(0.9*(2**31-1));
  wire signed [31:0] BETA = $floor(0.1*(2**31-1));

  initial begin
    @(negedge ce_rst);
    @(posedge ce_clk);

    // Setup FFT
    SendCtrlPacket(FFT_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});              // Command packet to set up flow control
    SendCtrlPacket(FFT_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});               // Command packet to set up source control window size
    SendCtrlPacket(FFT_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                 // Command packet to set up source control window enable
    SendCtrlPacket(FFT_SID, {24'd0, SR_NEXT_DST_BASE, {16'd0, VECTOR_IIR_SID}});                      // Set next destination
    SendCtrlPacket(FFT_SID, {24'd0, SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word}});                     // Configure FFT core
    SendCtrlPacket(FFT_SID, {24'd0, inst_noc_block_fft.SR_FFT_SIZE_LOG2, {24'd0, fft_size_log2}});    // Set FFT size register
    SendCtrlPacket(FFT_SID, {24'd0, inst_noc_block_fft.SR_MAGNITUDE_OUT, {30'd0, inst_noc_block_fft.MAG_SQ_OUT}});  // Enable magnitude out
    #1000;

    // Setup Vector IIR
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});               // Command packet to set up flow control
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});                // Command packet to set up source control window size
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                  // Command packet to set up source control window enable
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, SR_NEXT_DST_BASE, {16'd0,KEEP_ONE_IN_N_SID}});                 // Set next destination
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, inst_noc_block_vector_iir.SR_VECTOR_LEN, {16'd0, FFT_SIZE}});  // Set Vector length register
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, inst_noc_block_vector_iir.SR_ALPHA, ALPHA});
    SendCtrlPacket(VECTOR_IIR_SID, {24'd0, inst_noc_block_vector_iir.SR_BETA, BETA});
    #1000;

    // Setup Keep one in n
    SendCtrlPacket(KEEP_ONE_IN_N_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});            // Command packet to set up flow control
    SendCtrlPacket(KEEP_ONE_IN_N_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});             // Command packet to set up source control window size
    SendCtrlPacket(KEEP_ONE_IN_N_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});               // Command packet to set up source control window enable
    SendCtrlPacket(KEEP_ONE_IN_N_SID, {24'd0, SR_NEXT_DST_BASE, {16'd0,TESTBENCH_SID}});                  // Set next destination
    SendCtrlPacket(KEEP_ONE_IN_N_SID, {24'd0, inst_noc_block_keep_one_in_n.SR_N, {32'd4}});     // Keep 1 in 4
    #1000;

    // Send 1/8th sample rate sine wave
    tb_next_dst = FFT_SID;
    @(posedge ce_clk);
    forever begin
      for (i = 0; i < (FFT_SIZE/8); i = i + 1) begin
        SendAxi({ 16'd32767,     16'd0},0);
        SendAxi({ 16'd23170, 16'd23170},0);
        SendAxi({     16'd0, 16'd32767},0);
        SendAxi({-16'd23170, 16'd23170},0);
        SendAxi({-16'd32767,     16'd0},0);
        SendAxi({-16'd23170,-16'd23170},0);
        SendAxi({     16'd0,-16'd32767},0);
        SendAxi({ 16'd23170,-16'd23170},(i == (FFT_SIZE/8)-1)); // Assert tlast on final word
      end
    end
  end

  // Assertions
  integer k, l;
  reg [15:0] real_val;
  reg [15:0] cplx_val;
  reg [15:0] real_val_prev = 15'd0;
  reg last;
  localparam NUM_PASSES = 20;
  localparam FFT_BIN = FFT_SIZE/8 + FFT_SIZE/2;
  initial begin
    @(negedge ce_rst);
    @(posedge ce_clk);
    $display("*****************************************************");
    $display("**              Begin Assertion Tests              **");
    $display("*****************************************************");
    for (l = 0; l < NUM_PASSES; l = l + 1) begin
      for (k = 0; k < FFT_SIZE; k = k + 1) begin
        RecvAxi({real_val,cplx_val},last);
        if (k == FFT_BIN) begin
          // Assert that for the special case of a 1/8th sample rate sine wave input, 
          // the real part of the corresponding 1/8th sample rate FFT bin should always be greater than 0 and 
          // be monotonically increasing. The complex part should always be 0.
          assert(real_val > 32'd0) else begin $error("FFT bin %d real part is not greater than 0!",k); $stop(); end
          assert(real_val >= real_val_prev) else begin $error("FFT bin %d real part is not monotonically increasing!",k); $stop(); end
          assert(cplx_val == 32'd0) else begin $error("FFT bin %d complex part is not 0!",k); $stop(); end
          real_val_prev = tb_str_sink_tdata[63:32];
        end else begin
          // Assert all other FFT bins should be 0 for both complex and real parts
          assert(real_val == 32'd0) else begin $error("FFT bin %d real part is not 0!",k); $stop(); end
          assert(cplx_val == 32'd0) else begin $error("FFT bin %d complex part is not 0!",k); $stop(); end
        end
        // Check packet size via tlast assertion
        if (k == FFT_SIZE-1) begin
          assert(last == 1'b1) else begin $error("Detected late tlast!"); $stop(); end
        end else begin
          assert(last == 1'b0) else begin $error("Detected early tlast!"); $stop(); end
        end
      end
      $display("Test loop %d PASSED!",l);
    end
    $display("All tests PASSED!");
  end

endmodule