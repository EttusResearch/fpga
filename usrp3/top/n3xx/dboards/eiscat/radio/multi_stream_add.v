//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Multi Stream Add
// Input:  NUM_INPUTS=16 input streams of WIDTH=40
//
// Output: NUM_BEAMS=10 output streams of OUTPUT_WIDTH=16 bits to upper noc_block level.
//
// Adds multiple sources all connected to i_tdata and outputs them in
// sum_tdata. Uses axi_join to combine axi ctrl wires to single output.
//
//

module multi_stream_add
  #(parameter WIDTH = 40,
    parameter NUM_INPUTS = 16,
    parameter LOG_INPUTS = $clog2(NUM_INPUTS))(
  input clk, input rst, input drop,
  input [NUM_INPUTS*WIDTH-1:0] i_tdata, input [NUM_INPUTS-1:0] i_tlast,
  input [NUM_INPUTS-1:0] i_tvalid, output [NUM_INPUTS-1:0] i_tready,
  output [LOG_INPUTS+WIDTH-1:0] sum_tdata,  output sum_tlast,
  output sum_tvalid,  input sum_tready
  );

  reg [LOG_INPUTS+WIDTH:0] full_sum;
  wire [NUM_INPUTS-1:0] i_tready_int;
  wire [NUM_INPUTS-1:0] i_tvalid_int;
  reg [NUM_INPUTS-1:0] drop_reg;

  assign sum_tdata = full_sum;

  genvar s;
  generate
    for (s = 0; s < (NUM_INPUTS); s = s + 1) begin
      always @(posedge clk)
        if (rst)
          drop_reg[s] <= 1'b0;
        else if (i_tvalid[s] & i_tlast[s] & i_tready[s] & drop)
          drop_reg[s] <= 1'b1;
        else if (drop_reg[s])
          drop_reg[s] <= drop;
        else
          drop_reg[s] <= 1'b0;

  // Drop incoming bad packets
  // Start Dropping : After tlast is asserted
  // Stop Dropping  : Immediately
    assign i_tready[s]     = (drop & drop_reg[s]) ? {NUM_INPUTS{1'b1}} : i_tready_int[s];
    assign i_tvalid_int[s] = (drop & drop_reg[s]) ? {NUM_INPUTS{1'b0}} : i_tvalid[s];
    end
  endgenerate

  axi_join #(.INPUTS(NUM_INPUTS)) aj_inst (
    .i_tlast(i_tlast), .i_tvalid(i_tvalid_int), .i_tready(i_tready_int),
    .o_tlast(sum_tlast), .o_tvalid(sum_tvalid), .o_tready(sum_tready));

  integer i;
  reg [LOG_INPUTS+WIDTH:0] temp_data;
  always @* begin
    temp_data = 0;
    for (i = 0; i < NUM_INPUTS; i = i + 1) begin
      temp_data = temp_data + {{LOG_INPUTS{i_tdata[i*WIDTH+WIDTH-1]}}, i_tdata[i*WIDTH +: WIDTH]};

      end
    full_sum = temp_data;
    end

endmodule

