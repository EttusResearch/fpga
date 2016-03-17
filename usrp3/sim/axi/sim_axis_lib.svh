//
// Copyright 2015 Ettus Research LLC
//
`ifndef INCLUDED_SIM_AXIS_LIB
`define INCLUDED_SIM_AXIS_LIB

interface axis_t #(parameter DWIDTH = 32)(input clk);
  logic [DWIDTH-1:0] tdata;
  logic              tvalid;
  logic              tlast;
  logic              tready;

  modport master (
    output tdata,
    output tvalid,
    output tlast,
    input tready);

  modport slave (
    input tdata,
    input tvalid,
    input tlast,
    output tready);
endinterface


class axis_master #(parameter DWIDTH = 32);

  virtual axis_t #(.DWIDTH(DWIDTH)) axis;

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) axis);
    this.axis = axis;
    this.axis.tdata = {DWIDTH{1'b0}};
    this.axis.tvalid = 1'b0;
    this.axis.tlast = 1'b0;
  endfunction

  // Push a word onto the AXI-Stream bus and wait for it to transfer
  // Args:
  // - word: The data to push onto the bus
  // - eop (optional): End of packet (asserts tlast)
  task automatic push_word;
    input logic [DWIDTH-1:0] word;
    input logic eop;
    begin
      this.axis.tvalid = 1;
      this.axis.tlast  = eop;
      this.axis.tdata  = word;
      @(posedge this.axis.clk);                                //Put sample on data bus
      while(~this.axis.tready) @(posedge this.axis.clk);    //Wait until receiver ready
      @(negedge this.axis.clk);                                //Put sample on data bus
      this.axis.tvalid = 0;
      this.axis.tlast  = 0;
    end
  endtask

  // Push a bubble cycle onto the AXI-Stream bus
  task automatic push_bubble;
    begin
      this.axis.tvalid = 0;
      @(negedge this.axis.clk);
    end
  endtask

  // Push a packet with random data onto to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  task automatic push_rand_pkt;
    input integer num_samps;
    begin
      @(negedge this.axis.clk);
      repeat(num_samps-1) begin
        this.push_word({(((DWIDTH-1)/32)+1){$random}}, 0);
      end
      this.push_word({(((DWIDTH-1)/32)+1){$random}}, 1);
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
      @(negedge this.axis.clk);
      repeat(num_samps-1) begin
        this.push_word(ramp_start+(counter*ramp_inc), 0);
        counter = counter + 1;
      end
      this.push_word(ramp_start+(counter*ramp_inc), 1);
    end
  endtask

endclass


class axis_slave #(parameter DWIDTH = 32);

  virtual axis_t #(.DWIDTH(DWIDTH)) axis;

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) axis);
    this.axis = axis;
    this.axis.tready = 1'b0;
  endfunction

  // Accept a sample on the AXI Stream bus and
  // return the data and last
  // Args:
  // - word: The data pulled from the bus
  // - eop: End of packet (tlast)
  task automatic pull_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      this.axis.tready = 1;
      while(~this.axis.tvalid) @(posedge this.axis.clk);
      word = this.axis.tdata;
      eop = this.axis.tlast;
      @(negedge this.axis.clk);
      this.axis.tready = 0;
    end
  endtask

  // Wait for a sample to be transferred on the AXI Stream
  // bus and return the data and last. Note, this task only
  // observes the bus and does not affect the AXI control
  // signals.
  // Args:
  // - word: The data pulled from the bus
  // - eop: End of packet (tlast)
  task automatic copy_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      while(~(this.axis.tready&this.axis.tvalid)) @(posedge this.axis.clk);  // Wait until sample is transferred
      word = this.axis.tdata;
      eop = this.axis.tlast;
      @(negedge this.axis.clk);
    end
  endtask

  // Wait for a bubble cycle on the AXI Stream bus
  task automatic wait_for_bubble;
    begin
      while(this.axis.tready&this.axis.tvalid) @(posedge this.axis.clk);
      @(negedge this.axis.clk);
    end
  endtask

  // Wait for a packet to finish on the bus
  task automatic wait_for_pkt;
    begin
      while(~(this.axis.tready&this.axis.tvalid&this.axis.tlast)) @(posedge this.axis.clk);
      @(negedge this.axis.clk);
    end
  endtask

endclass


class axis_bus #(parameter DWIDTH = 32);

  axis_master #(.DWIDTH(DWIDTH)) m_axis;
  axis_slave #(.DWIDTH(DWIDTH)) s_axis;

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) m_axis, virtual axis_t #(.DWIDTH(DWIDTH)) s_axis);
    this.m_axis = new(m_axis);
    this.s_axis = new(s_axis);
  endfunction

  // Class tasks from base classes
  task automatic push_word;
    input logic [DWIDTH-1:0] word;
    input logic eop;
    begin
      this.m_axis.push_word(word, eop);
    end
  endtask

  task automatic push_bubble;
    begin
      this.m_axis.push_bubble();
    end
  endtask

  task automatic push_rand_pkt;
    input integer num_samps;
    begin
      this.m_axis.push_rand_pkt(num_samps);
    end
  endtask

  task automatic push_ramp_pkt;
    input integer num_samps;
    input [DWIDTH-1:0] ramp_start;
    input [DWIDTH-1:0] ramp_inc;
    begin
      this.m_axis.push_ramp_pkt(num_samps, ramp_start, ramp_inc);
    end
  endtask

  task automatic pull_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      this.s_axis.pull_word(word, eop);
    end
  endtask

  task automatic copy_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      this.s_axis.copy_word(word, eop);
    end
  endtask

  task automatic wait_for_bubble;
    begin
      this.s_axis.wait_for_bubble();
    end
  endtask

  task automatic wait_for_pkt;
    begin
      this.s_axis.wait_for_pkt();
    end
  endtask

endclass

`endif