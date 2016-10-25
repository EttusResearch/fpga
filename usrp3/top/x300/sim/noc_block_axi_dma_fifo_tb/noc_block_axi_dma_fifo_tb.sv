`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 8

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_axi_dma_fifo_tb();
  `TEST_BENCH_INIT("noc_block_axi_dma_fifo_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/300e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;  // Number of test bench streams
  `DEFINE_CLK(sys_clk, 10, 50)            //100MHz sys_clk to generate DDR3 clocking
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      //100ns for GSR to deassert
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_axi_dma_fifo, 0);

  localparam SPP = 128; // Samples per packet

  wire calib_complete;
  axis_dram_fifo_dual #( .USE_SRAM_MEMORY(0)) inst_noc_block_dram_fifo_dut (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .sys_clk(sys_clk), .sys_rst_n(sys_rst_n),
    //AXIS
    .i_tdata(noc_block_axi_dma_fifo_i_tdata), .i_tlast(noc_block_axi_dma_fifo_i_tlast),
    .i_tvalid(noc_block_axi_dma_fifo_i_tvalid), .i_tready(noc_block_axi_dma_fifo_i_tready),
    .o_tdata(noc_block_axi_dma_fifo_o_tdata), .o_tlast(noc_block_axi_dma_fifo_o_tlast),
    .o_tvalid(noc_block_axi_dma_fifo_o_tvalid), .o_tready(noc_block_axi_dma_fifo_o_tready),
    .init_calib_complete(calib_complete)
  );
  
  logic [63:0] readback;
  
  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_axi_dma_fifo, RB_NOC_ID, readback);
    $display("Read NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_axi_dma_fifo.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,0,noc_block_axi_dma_fifo,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_axi_dma_fifo,0,noc_block_tb,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,1,noc_block_axi_dma_fifo,1,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_axi_dma_fifo,1,noc_block_tb,1,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Wait for DRAM calibration to complete
    ********************************************************/
    `TEST_CASE_START("Wait for DRAM calibration to complete");
    while (calib_complete !== 1'b1) @(posedge bus_clk);
    `TEST_CASE_DONE(calib_complete);

    /********************************************************
    ** Test 5 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Initialize FIFO 0");
    tb_streamer.write_user_reg(sid_noc_block_axi_dma_fifo, 128+1, {16'h0, 12'd280, 2'b00, 1'b0, 1'b0}, 0);

    tb_streamer.write_user_reg(sid_noc_block_axi_dma_fifo, 128, 32'd0, 0);
    tb_streamer.read_user_reg(sid_noc_block_axi_dma_fifo, 0, readback, 0);
    `ASSERT_ERROR(readback[15:0] == 16'd0, "Incorrect FIFO fullness!");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 6 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Initialize FIFO 1");
    tb_streamer.write_user_reg(sid_noc_block_axi_dma_fifo, 128+1, {16'h0, 12'd280, 2'b00, 1'b0, 1'b0}, 1);

    tb_streamer.write_user_reg(sid_noc_block_axi_dma_fifo, 128, 32'd0, 1);
    tb_streamer.read_user_reg(sid_noc_block_axi_dma_fifo, 0, readback, 1);
    `ASSERT_ERROR(readback[15:0] == 16'd0, "Incorrect FIFO fullness!");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 7 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test FIFO 0");
    fork
      begin
        cvita_payload_t send_payload;
        cvita_metadata_t md;
        for (int i = 0; i < SPP/2; i++) begin
          send_payload.push_back(64'(i));
        end
        tb_streamer.send(send_payload, md, 0);
      end
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        logic [63:0] expected_value;
        tb_streamer.recv(recv_payload, md, 0);
        for (int i = 0; i < SPP/2; i++) begin
          expected_value = i;
          $sformat(s, "Incorrect value received! Expected: %0d, Received: %0d", expected_value, recv_payload[i]);
          `ASSERT_ERROR(recv_payload[i] == expected_value, s);
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 8 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test FIFO 1");
    fork
      begin
        cvita_payload_t send_payload;
        cvita_metadata_t md;
        for (int i = 0; i < SPP/2; i++) begin
          send_payload.push_back(64'(i));
        end
        tb_streamer.send(send_payload, md, 1);
      end
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        logic [63:0] expected_value;
        tb_streamer.recv(recv_payload, md, 1);
        for (int i = 0; i < SPP/2; i++) begin
          expected_value = i;
          $sformat(s, "Incorrect value received! Expected: %0d, Received: %0d", expected_value, recv_payload[i]);
          `ASSERT_ERROR(recv_payload[i] == expected_value, s);
        end
      end
    join
    `TEST_CASE_DONE(1);


    `TEST_BENCH_DONE;
  end
endmodule
