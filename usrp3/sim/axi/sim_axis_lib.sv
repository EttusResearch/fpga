//
// Copyright 2015 Ettus Research LLC
//

interface axis_t #(parameter DWIDTH = 64)
                  (input clk);
  logic [DWIDTH-1:0]  tdata;
  logic               tvalid;
  logic               tlast;
  logic               tready;

  modport master (output tdata, output tvalid, output tlast, input tready);
  modport slave (input tdata, input tvalid, input tlast, output tready);

  // Push a word onto the AXI-Stream bus and wait for it to transfer
  // Args:
  // - word: The data to push onto the bus
  // - eop (optional): End of packet (asserts tlast)
  task automatic push_word;
    input logic [DWIDTH-1:0] word;
    input logic eop = 0;
    begin
      tvalid = 1;
      tlast  = eop;
      tdata  = word;
      @(posedge clk);                 //Put sample on data bus
      while(~tready) @(posedge clk);  //Wait until reciever ready
      tvalid = 0;
      tlast  = 0;
    end
  endtask

  // Push a bubble cycle onto the AXI-Stream bus
  task automatic push_bubble;
    begin
      tvalid = 0;
      @(posedge clk);
    end
  endtask

  // Wait for a sample to be transferred on the AXI Stream
  // bus and return the data and last
  // Args:
  // - word: The data pulled from the bus
  // - eop: End of packet (tlast)
  task automatic pull_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      while(~(tready&tvalid)) @(posedge clk);  //Wait until sample is transferred
      word = tdata;
      eop = tlast;
      @(posedge clk);
    end
  endtask

  // Wait for a bubble cycle on the AXI Stream bus
  task automatic wait_for_bubble;
    begin
      while(tready&tvalid) @(posedge clk);
      @(posedge clk);
    end
  endtask

  // Wait for a packet to finish on the bus
  task automatic wait_for_pkt;
    begin
      while(~(tready&tvalid&tlast)) @(posedge clk);
      @(posedge clk);
    end
  endtask

  // Push a packet with random data onto to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  task automatic push_rand_pkt;
    input integer num_samps;
    begin
      repeat(num_samps-1) begin
        push_word({(((DWIDTH-1)/32)+1){$random}}, 0);
      end
      push_word({(((DWIDTH-1)/32)+1){$random}}, 1);
    end
  endtask

  // Push a packet with a ramp on to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  // - ramp_start: Start value for the ramp
  // - ramp_inc: Increment per clock cycle
  task automatic push_ramp_pkt;
    input integer num_samps;
    input [DWIDTH-1:0] ramp_start;
    input [DWIDTH-1:0] ramp_inc;
    begin
      automatic integer counter = 0;
      repeat(num_samps-1) begin
        push_word(ramp_start+(counter*ramp_inc), 0);
        counter = counter + 1;
      end
      push_word(ramp_start+(counter*ramp_inc), 1);
    end
  endtask

endinterface
