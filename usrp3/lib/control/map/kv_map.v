//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: kv_map

module kv_map #(
  parameter KEY_WIDTH   = 16,
  parameter VAL_WIDTH   = 32,
  parameter SIZE        = 6,
  parameter INSERT_MODE = "LOSSY"
) (
  input  wire                 clk,
  input  wire                 reset,

  input  wire                 insert_stb,
  input  wire [KEY_WIDTH-1:0] insert_key,
  input  wire [VAL_WIDTH-1:0] insert_val,
  output wire                 insert_busy,

  input  wire                 find_key_stb,
  input  wire [KEY_WIDTH-1:0] find_key,
  output wire                 find_res_stb,
  output wire                 find_res_match,
  output wire [VAL_WIDTH-1:0] find_res_val,
  
  output wire [SIZE-1:0]      count
);

  // CAM lookup has a 1 cycle latency
  // The lookup address into the RAM is delayed by 1 cycle for timing
  localparam FIND_CYC = 2;

  wire                 insert_stb_cam, insert_busy_cam;
  reg  [SIZE-1:0]      insert_addr = {SIZE{1'b0}};
  reg                  insert_pending = 1'b0;
  wire [SIZE-1:0]      find_addr;
  reg  [SIZE-1:0]      find_addr_reg;
  wire                 find_match;
  reg                  find_match_del;
  reg [FIND_CYC:0]     find_key_stb_shreg;
  
  assign insert_stb_cam = insert_stb && 
    ((INSERT_MODE == "LOSSY") ? 1'b1 : (insert_addr != {SIZE{1'b1}}));
  assign insert_busy = insert_busy_cam ||
    ((INSERT_MODE == "LOSSY") ? 1'b0 : (insert_addr == {SIZE{1'b1}}));

  always @(posedge clk) begin
    if (reset) begin
      insert_pending <= 1'b0;
      insert_addr <= {SIZE{1'b0}};
    end else if (~insert_pending) begin
      insert_pending <= insert_stb_cam;
    end else begin
      if (~insert_busy_cam) begin
        insert_pending <= 1'b0;
        insert_addr <= insert_addr + 1'd1;
      end
    end
  end

  cam #(
    .DATA_WIDTH   (KEY_WIDTH),
    .ADDR_WIDTH   (SIZE),
    .CAM_STYLE    (SIZE > 8 ? "BRAM" : "SRL"),
    .SLICE_WIDTH  (SIZE > 8 ? 9 : 5)
  ) cam_i (
    .clk          (clk),
    .rst          (reset),
    .write_addr   (insert_addr),
    .write_data   (insert_key),
    .write_delete (1'b0),
    .write_enable (insert_stb_cam),
    .write_busy   (insert_busy_cam),
    .compare_data (find_key),
    .match_many   (),
    .match_single (),
    .match_addr   (find_addr),
    .match        (find_match)
  );

  always @(posedge clk)
    find_addr_reg <= find_addr;

  ram_2port #(
    .DWIDTH       (VAL_WIDTH),
    .AWIDTH       (SIZE)
  ) mem_i (
    .clka         (clk),
    .ena          (insert_stb_cam),
    .wea          (1'b1),
    .addra        (insert_addr),
    .dia          (insert_val),
    .doa          (/* Write port only */),
    .clkb         (clk),
    .enb          (1'b1),
    .web          (1'b0),
    .addrb        (find_addr_reg),
    .dib          (/* Read port only */),
    .dob          (find_res_val)
  );

  // Delay the find valid signal to account for the latency 
  // of the CAM and RAM
  always @(posedge clk) begin
    find_key_stb_shreg <= reset ? {(FIND_CYC+1){1'b0}} :
      {find_key_stb_shreg[FIND_CYC-1:0], find_key_stb};
  end
  assign find_res_stb = find_key_stb_shreg[FIND_CYC];

  // Delay the match signal to account for the latency of the RAM
  always @(posedge clk) begin
    find_match_del <= reset ? 1'b0 : find_match;
  end
  assign find_res_match = find_match_del;
  
  assign count = insert_addr;

endmodule
