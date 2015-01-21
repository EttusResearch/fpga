//
// Copyright 2015 Ettus Research LLC
//

module axi_fifo_flop2_tb();

  /*********************************************
  ** Clocks & Reset
  *********************************************/
  `define CE_CLOCK_FREQ 200e6
  `define RESET_TIME    100

  reg clk;
  initial clk = 1'b0;
  localparam CLOCK_PERIOD = 1e9/`CE_CLOCK_FREQ;
  always
    #(CLOCK_PERIOD) clk = ~clk;

  reg reset;
  initial begin
    reset = 1'b1;
    #(`RESET_TIME);
    @(posedge clk);
    reset = 1'b0;
  end

  /*********************************************
  ** DUT
  *********************************************/
  reg [31:0] i_tdata;
  reg i_tvalid, o_tready;
  wire i_tready, o_tvalid;
  wire [31:0] o_tdata;
  reg clear;

  axi_fifo_flop2 #(
    .WIDTH(32))
  dut_axi_fifo_flop2 (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied(occupied));

  /*********************************************
  ** Testbench
  *********************************************/ 
  localparam TEST_VECTOR_SIZE = 10;
  
  reg [TEST_VECTOR_SIZE-1:0] i_tvalid_sequence;
  reg [TEST_VECTOR_SIZE-1:0] o_tready_sequence;
  integer i,k,n,i_tready_timeout;
  reg [31:0] o_tdata_check;

  // Tests combinations of i_tvalid / o_tready sequences.
  // Test space depends on TEST_VECTOR_SIZE.
  // Example: TEST_VECTOR_SIZE = 10 => 1024*1024 number of test sequences,
  //          which is every possible 10 bit sequence of i_tvalid / o_tready.
  initial begin
    i_tvalid_sequence = {TEST_VECTOR_SIZE{1'd0}};
    o_tready_sequence = {TEST_VECTOR_SIZE{1'd0}};
    i_tdata = 32'd0;
    i_tvalid = 1'b0;
    o_tready = 1'b0;
    i_tready_timeout = 0;
    clear = 1'b0;
    @(negedge reset);
    $display("*****************************************************");
    $display("**              Begin Assertion Tests              **");
    $display("*****************************************************");
    for (i = 0; i < 2**TEST_VECTOR_SIZE; i = i + 1) begin
      i_tvalid_sequence = i_tvalid_sequence + 1;
      for (k = 0; k < 2**TEST_VECTOR_SIZE; k = k + 1) begin
        o_tready_sequence = o_tready_sequence + 1;
        for (n = 0; n < TEST_VECTOR_SIZE; n = n + 1) begin
          if (o_tready_sequence[n]) begin
            o_tready = 1'b1;
          end else begin
            o_tready = 1'b0;
          end
          // Special Case: If i_tready timed out, then i_tvalid is still asserted and we cannot
          //               deassert i_tvalid until we see a corresponding i_tready. This is a basic
          //               AXI stream requirement, so we will continue to assert i_tvalid regardless
          //               of what i_tvalid_sequence would have set i_tvalid for this loop. 
          if (i_tvalid_sequence[n] | (i_tready_timeout == TEST_VECTOR_SIZE)) begin
            i_tvalid = 1'b1;
            @(posedge clk);
            i_tready_timeout = 0;
            // Wait for i_tready until timeout. Timeouts may occur when o_tready_sequence
            // has o_tready not asserted for several clock cycles.
            while(~i_tready & (i_tready_timeout < TEST_VECTOR_SIZE)) begin
              @(posedge clk)
              i_tready_timeout = i_tready_timeout + 1;
            end
            if (i_tready_timeout < TEST_VECTOR_SIZE) begin 
              i_tdata = i_tdata + 32'd1;
            end
          end else begin
            i_tvalid = 1'b0;
            @(posedge clk);
          end
        end
      end
      $display("Test loop %d PASSED!",i);
      // Reset starting conditions for the test sequences
      clear = 1'b1;
      i_tdata = 32'd0;
      i_tvalid = 1'b0;
      o_tready = 1'b0;
      i_tready_timeout = 0;
      @(posedge clk);
      clear = 1'b0;
      @(posedge clk);
    end
    $display("All tests PASSED!");
    $stop;
  end

  // Check the input counting sequence independent of
  // i_tvalid / o_tready sequences.
  always @(posedge clk) begin
    if (reset) begin
      o_tdata_check <= 32'd0;
    end else begin
      if (clear) begin
        o_tdata_check <= 32'd0;
      end
      if (o_tready & o_tvalid) begin
        o_tdata_check <= o_tdata_check + 32'd1;
        if (o_tdata != o_tdata_check) begin
          $display("Loop %d FAILED!",i);
          $error("Incorrect output!");
          $stop;
        end
      end
    end
  end

endmodule