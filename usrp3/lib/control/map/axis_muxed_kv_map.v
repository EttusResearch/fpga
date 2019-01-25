//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: axis_kv_map_multi

module axis_muxed_kv_map #(
  parameter KEY_WIDTH   = 16,
  parameter VAL_WIDTH   = 32,
  parameter SIZE        = 6,
  parameter NUM_PORTS   = 4
) (
  input  wire                             clk,
  input  wire                             reset,
                                          
  input  wire [KEY_WIDTH-1:0]             axis_insert_tdest,
  input  wire [VAL_WIDTH-1:0]             axis_insert_tdata,
  input  wire                             axis_insert_tvalid,
  output wire                             axis_insert_tready,

  input  wire [(KEY_WIDTH*NUM_PORTS)-1:0] axis_find_tdata,
  input  wire [NUM_PORTS-1:0]             axis_find_tvalid,
  output wire [NUM_PORTS-1:0]             axis_find_tready,

  output wire [(VAL_WIDTH*NUM_PORTS)-1:0] axis_result_tdata,
  output wire [NUM_PORTS-1:0]             axis_result_tkeep,
  output wire [NUM_PORTS-1:0]             axis_result_tvalid,
  input  wire [NUM_PORTS-1:0]             axis_result_tready
);

  parameter MUX_W = $clog2(NUM_PORTS) + KEY_WIDTH;
  parameter DEMUX_W = $clog2(NUM_PORTS) + VAL_WIDTH + 1;
  genvar i;

  localparam [1:0] ST_IDLE    = 2'd0;
  localparam [1:0] ST_REQUEST = 2'd1;
  localparam [1:0] ST_PENDING = 2'd2;

  //---------------------------------------------------------
  // Demux find ports
  //---------------------------------------------------------
  wire [KEY_WIDTH-1:0]          find_key, find_key_reg;
  wire [$clog2(NUM_PORTS)-1:0]  find_dest, find_dest_reg;
  wire                          find_key_valid, find_key_valid_reg;
  wire                          find_ready;
  reg                           find_in_progress = 1'b0;
  wire                          insert_busy;
  wire                          find_res_stb;
  wire [VAL_WIDTH-1:0]          find_res_val;
  wire                          find_res_match, find_res_ready;

  wire [(MUX_W*NUM_PORTS)-1:0] mux_tdata;
  generate for (i = 0; i < NUM_PORTS; i = i + 1) begin
    assign mux_tdata[(MUX_W*i)+KEY_WIDTH-1:MUX_W*i] = axis_find_tdata[(KEY_WIDTH*i)+:KEY_WIDTH];
    assign mux_tdata[(MUX_W*(i+1))-1:(MUX_W*i)+KEY_WIDTH] = i;
  end endgenerate

  axi_mux #(
    .WIDTH(KEY_WIDTH+$clog2(NUM_PORTS)), .SIZE(NUM_PORTS),
    .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE($clog2(NUM_PORTS))
  ) mux_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(mux_tdata), .i_tlast({NUM_PORTS{1'b1}}),
    .i_tvalid(axis_find_tvalid), .i_tready(axis_find_tready),
    .o_tdata({find_dest_reg, find_key_reg}), .o_tlast(),
    .o_tvalid(find_key_valid_reg), .o_tready(find_ready)
  );

  axi_fifo #(
    .WIDTH(KEY_WIDTH+$clog2(NUM_PORTS)), .SIZE(1)
  ) mux_reg_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata({find_dest_reg, find_key_reg}),
    .i_tvalid(find_key_valid_reg), .i_tready(find_ready),
    .o_tdata({find_dest, find_key}),
    .o_tvalid(find_key_valid), .o_tready(find_res_stb & find_res_ready),
    .space(), .occupied()
  );

  always @(posedge clk) begin
    if (reset) begin
      find_in_progress <= 1'b0;
    end else if (~find_in_progress) begin
      find_in_progress <= find_key_valid;
    end else begin
      if (find_res_stb & find_res_ready)
        find_in_progress <= 1'b0;
    end
  end

  //---------------------------------------------------------
  // Insert logic
  //---------------------------------------------------------
  reg [1:0] ins_state = ST_IDLE;
  always @(posedge clk) begin
    if (reset) begin
      ins_state <= ST_IDLE;
    end else begin
      case (ins_state)
        ST_IDLE:
          if (axis_insert_tvalid & ~insert_busy)
            ins_state <= ST_REQUEST;
        ST_REQUEST:
          ins_state <= ST_PENDING;
        ST_PENDING:
          if (~insert_busy)
            ins_state <= ST_IDLE;
        default:
          ins_state <= ST_IDLE;
      endcase
    end
  end
  assign axis_insert_tready = axis_insert_tvalid & (ins_state == ST_PENDING) & ~insert_busy;

  //---------------------------------------------------------
  // KV map instantiation
  //---------------------------------------------------------
  kv_map #(
    .KEY_WIDTH      (KEY_WIDTH),
    .VAL_WIDTH      (VAL_WIDTH),
    .SIZE           (SIZE),
    .INSERT_MODE    ("LOSSY")
  ) map_i (
    .clk            (clk),
    .reset          (reset),
    .insert_stb     (axis_insert_tvalid & (ins_state == ST_REQUEST)),
    .insert_key     (axis_insert_tdest),
    .insert_val     (axis_insert_tdata),
    .insert_busy    (insert_busy),
    .find_key_stb   (find_key_valid & ~find_in_progress),
    .find_key       (find_key),
    .find_res_stb   (find_res_stb),
    .find_res_match (find_res_match),
    .find_res_val   (find_res_val),
    .count          (/* unused */)
  );

  //---------------------------------------------------------
  // Mux results port
  //---------------------------------------------------------
  wire [(DEMUX_W*NUM_PORTS)-1:0] demux_tdata;
  wire [DEMUX_W-1:0] hdr;
  axi_demux #(
    .WIDTH(DEMUX_W), .SIZE(NUM_PORTS),
    .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0)
  ) demux_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .header(hdr), .dest(hdr[DEMUX_W-1:VAL_WIDTH+1]),
    .i_tdata({find_dest, find_res_match, find_res_val}), .i_tlast(1'b1),
    .i_tvalid(find_res_stb), .i_tready(find_res_ready),
    .o_tdata(demux_tdata), .o_tlast(),
    .o_tvalid(axis_result_tvalid), .o_tready(axis_result_tready)
  );

  generate for (i = 0; i < NUM_PORTS; i = i + 1) begin
    assign axis_result_tdata[(VAL_WIDTH*i)+:VAL_WIDTH] = demux_tdata[(DEMUX_W*i)+VAL_WIDTH-1:DEMUX_W*i];
    assign axis_result_tkeep[i] = demux_tdata[(DEMUX_W*i)+VAL_WIDTH];
  end endgenerate

endmodule
