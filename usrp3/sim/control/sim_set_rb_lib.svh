//
// Copyright 2015 Ettus Research LLC
//
`ifndef INCLUDED_SIM_SET_RB_LIB
`define INCLUDED_SIM_SET_RB_LIB

interface settings_bus_t #(parameter AWIDTH = 8, parameter DWIDTH = 32)(input clk);
  logic               stb;
  logic [AWIDTH-1:0]  addr;
  logic [DWIDTH-1:0]  data;

  modport master (output stb, output addr, output data);
  modport slave (input stb, input addr, input data);

endinterface

interface readback_bus_t #(parameter AWIDTH = 8, parameter DWIDTH = 64)(input clk);
  logic               stb;
  logic [AWIDTH-1:0]  addr;
  logic [DWIDTH-1:0]  data;

  modport master (output stb, input addr, output data);
  modport slave (input stb, output addr, input data);

endinterface

class settings_bus_master #(
  parameter SR_AWIDTH  = 8,
  parameter SR_DWIDTH  = 32,
  parameter RB_AWIDTH  = 8,
  parameter RB_DWIDTH  = 64,
  parameter TIMEOUT    = 65535 // read() timeout
);

  virtual settings_bus_t #(.AWIDTH(SR_AWIDTH), .DWIDTH(SR_DWIDTH)) settings_bus;
  virtual readback_bus_t #(.AWIDTH(RB_AWIDTH), .DWIDTH(RB_DWIDTH)) rb_bus;

  function new (
    virtual settings_bus_t #(.AWIDTH(SR_AWIDTH), .DWIDTH(SR_DWIDTH)) settings_bus,
    virtual readback_bus_t #(.AWIDTH(RB_AWIDTH), .DWIDTH(RB_DWIDTH)) rb_bus
  );
    this.settings_bus      = settings_bus;
    this.rb_bus            = rb_bus;
    this.settings_bus.stb  = 1'b0;
    this.settings_bus.addr = {SR_AWIDTH{1'b0}};
    this.settings_bus.data = {SR_DWIDTH{1'b0}};
  endfunction

  // Push a transaction onto the settings bus
  // Args:
  // - set_addr: Settings bus address
  // - set_data: Settings bus data
  // - rb_addr:  Readback bus address
  task write;
    input  [SR_AWIDTH-1:0] set_addr;
    input  [SR_DWIDTH-1:0] set_data;
    input  [RB_AWIDTH-1:0] rb_addr = {RB_AWIDTH{1'b0}}; // Optional
    begin
      @(negedge settings_bus.clk);
      settings_bus.stb  = 1'b1;
      settings_bus.addr = set_addr;
      settings_bus.data = set_data;
      rb_bus.addr       = rb_addr;
      @(negedge settings_bus.clk);
      settings_bus.stb  = 1'b0;
      settings_bus.addr = {SR_AWIDTH{1'b0}};
      settings_bus.data = {SR_DWIDTH{1'b0}};
      rb_bus.addr       = {RB_AWIDTH{1'b0}};
    end
  endtask

  // Pull a transaction from the readback bus. Typically called immediately after write().
  // Args:
  // - rb_data: Readback data
  task read;
    output [RB_DWIDTH-1:0] rb_data;
    begin
      while (~rb_bus.stb) begin
        automatic integer timeout_counter = 0;
        @(negedge rb_bus.clk);
        if (timeout_counter < TIMEOUT) begin
          timeout_counter++;
        end else begin
          $error("settings_bus_master::read(): Timeout waiting for readback strobe!");
          break;
        end
      end
      rb_data = rb_bus.data;
      @(negedge rb_bus.clk);
    end
  endtask

endclass

class settings_bus_slave #(
  parameter SR_AWIDTH  = 8,
  parameter SR_DWIDTH  = 32,
  parameter RB_AWIDTH  = 8,
  parameter RB_DWIDTH  = 64,
  parameter TIMEOUT    = 65535 // read() timeout
);

  virtual settings_bus_t #(.AWIDTH(SR_AWIDTH), .DWIDTH(SR_DWIDTH)) settings_bus;
  virtual readback_bus_t #(.AWIDTH(RB_AWIDTH), .DWIDTH(RB_DWIDTH)) rb_bus;

  function new (
    virtual settings_bus_t #(.AWIDTH(SR_AWIDTH), .DWIDTH(SR_DWIDTH)) settings_bus,
    virtual readback_bus_t #(.AWIDTH(RB_AWIDTH), .DWIDTH(RB_DWIDTH)) rb_bus
  );
    this.settings_bus = settings_bus;
    this.rb_bus       = rb_bus;
    this.rb_bus.stb   = 1'b0;
    this.rb_bus.data  = {RB_DWIDTH{1'b0}};
  endfunction

  // Push a transaction onto the readback bus
  // Args:
  // - rb_data: Readback data
  task write;
    input [RB_AWIDTH-1:0] rb_data;
    begin
      @(negedge settings_bus.clk);
      rb_bus.stb   = 1'b1;
      rb_bus.data  = rb_data;
      @(negedge settings_bus.clk);
      rb_bus.stb   = 1'b0;
      rb_bus.data  = {RB_DWIDTH{1'b0}};
    end
  endtask

  // Pull a transaction from the settings bus
  // Args:
  // - set_addr: Settings bus address
  // - set_data: Settings bus data
  // - rb_addr:  Readback bus address
  task read;
    output [SR_AWIDTH-1:0] set_addr;
    output [SR_DWIDTH-1:0] set_data;
    output [RB_AWIDTH-1:0] rb_addr;
    begin
      automatic integer timeout_counter = 0;
      while (~settings_bus.stb) begin
        @(negedge rb_bus.clk);
        if (timeout_counter < TIMEOUT) begin
          timeout_counter++;
        end else begin
          $error("settings_bus_master::read(): Timeout waiting for settings bus strobe!");
          break;
        end
      end
      set_addr = settings_bus.addr;
      set_data = settings_bus.data;
      rb_addr  = rb_bus.addr;
      @(negedge rb_bus.clk);
    end
  endtask

endclass

`endif