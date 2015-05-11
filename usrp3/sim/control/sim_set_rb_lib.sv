//
// Copyright 2015 Ettus Research LLC
//

interface settings_t #(parameter AWIDTH = 8, parameter DWIDTH = 32)
                      (input clk);
  logic               stb;
  logic [AWIDTH-1:0]  addr;
  logic [DWIDTH-1:0]  data;

  modport master (output stb, output addr, output data);
  modport slave (input stb, input addr, input data);

  // Push a transaction onto the settings bus
  // Args:
  // - set_addr: Address
  // - set_data: Data
  task write;
    input [AWIDTH-1:0] set_addr;
    input [DWIDTH-1:0] set_data;
    begin
      @(negedge clk);
      stb   = 1'b0;
      addr  = {AWIDTH{1'b0}};
      data  = {DWIDTH{1'b0}};
      @(negedge clk);
      stb   = 1'b1;
      addr  = set_addr;
      data  = set_data;
      @(negedge clk);
      stb   = 1'b0;
      addr  = {AWIDTH{1'b0}};
      data  = {DWIDTH{1'b0}};
    end
  endtask

endinterface
