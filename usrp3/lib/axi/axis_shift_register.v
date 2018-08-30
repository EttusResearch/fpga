//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: axis_shift_register
// Description: 
//   An AXI-Stream wrapper module for a multi-cycle operation
//   with clock-enables. This can most commonly be used with DSP
//   operations like filters.
//
// Parameters:
//   - WIDTH: The bitwidth of the data bus
//   - LATENCY: Number of stages in the shift register
//   - SIDEBAND_DATAPATH: If SIDEBAND_DATAPATH==1 then tdata is managed
//       outside this module and imported from s_sideband_data. 
//       If SIDEBAND_DATAPATH=0, then tdata is managed internally and 
//       the sideband signals are unused.
//       Useful when using this module to manage a DSP pipeline where the
//       data could be changing in each stage.
//   - PIPELINE: Which ports to pipeline? {NONE, IN, OUT, INOUT}
//
// Signals:
//   - i_* : Input sample stream (AXI-Stream)
//   - o_* : Output sample stream (AXI-Stream)
//   - stage_stb : Transfer strobe for each stage 
//   - m_sideband_data : Master data port to feed the sideband datapath  
//   - s_sideband_data : Slave data port to consume from the sideband datapath  

module axis_shift_register #(
  parameter WIDTH             = 32,
  parameter LATENCY           = 3,
  parameter SIDEBAND_DATAPATH = 0,
  parameter PIPELINE          = "NONE"
)(
  // Clock, reset and settings
  input  wire               clk,              // Clock
  input  wire               reset,            // Reset
  // Serial Data In (AXI-Stream)              
  input  wire [WIDTH-1:0]   s_axis_tdata,     // Input stream tdata
  input  wire               s_axis_tlast,     // Input stream tlast
  input  wire               s_axis_tvalid,    // Input stream tvalid
  output wire               s_axis_tready,    // Input stream tready
  // Serial Data Out (AXI-Stream)             
  output wire [WIDTH-1:0]   m_axis_tdata,     // Output stream tdata
  output wire               m_axis_tlast,     // Output stream tlast
  output wire               m_axis_tvalid,    // Output stream tvalid
  input  wire               m_axis_tready,    // Output stream tready
  // Signals for the sideband data path                     
  output wire [LATENCY-1:0] stage_stb,        // Transfer strobe out. bit[i] = stage[i]
  output wire [LATENCY-1:0] stage_eop,        // Transfer end-of-packet out. bit[i] = stage[i]
  output wire [WIDTH-1:0]   m_sideband_data,  // Sideband data out for external consumer
  input  wire [WIDTH-1:0]   s_sideband_data   // Sideband data in from external producer
);
  // Shift register width depends on whether the datapath is internal
  localparam SHREG_WIDTH = SIDEBAND_DATAPATH[0] ? 1 : (WIDTH+1);

  //----------------------------------------------
  // Pipeline Logic
  // (fifo_flop2 is used because it breaks timing
  //  path going both ways: valid and ready)
  //----------------------------------------------
  wire [WIDTH-1:0]        i_tdata, o_tdata;
  wire                    i_tlast, o_tlast;
  wire                    i_tvalid, o_tvalid;
  wire                    i_tready, o_tready;

  generate
    // Shift register input
    if (PIPELINE == "IN" || PIPELINE == "INOUT") begin
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) in_pipe_i (
        .clk(clk), .reset(reset), .clear(1'b0),
        .i_tdata({s_axis_tlast, s_axis_tdata}), .i_tvalid(s_axis_tvalid), .i_tready(s_axis_tready),
        .o_tdata({i_tlast, i_tdata}), .o_tvalid(i_tvalid), .o_tready(i_tready),
        .space(), .occupied()
      );
    end else begin
      assign {i_tlast, i_tdata} = {s_axis_tlast, s_axis_tdata};
      assign i_tvalid = s_axis_tvalid;
      assign s_axis_tready = i_tready;
    end

    // Shift register output
    if (PIPELINE == "OUT" || PIPELINE == "INOUT") begin
      axi_fifo_flop2 #(.WIDTH(WIDTH+1)) out_pipe_i (
        .clk(clk), .reset(reset), .clear(1'b0),
        .i_tdata({o_tlast, o_tdata}), .i_tvalid(o_tvalid), .i_tready(o_tready),
        .o_tdata({m_axis_tlast, m_axis_tdata}), .o_tvalid(m_axis_tvalid), .o_tready(m_axis_tready),
        .space(), .occupied()
      );
    end else begin
      assign {m_axis_tlast, m_axis_tdata} = {o_tlast, o_tdata};
      assign m_axis_tvalid = o_tvalid;
      assign o_tready = m_axis_tready;
    end
  endgenerate

  assign m_sideband_data = i_tdata;

  //----------------------------------------------
  // Shift register stages
  //----------------------------------------------
  // Individual stage wires
  wire [SHREG_WIDTH-1:0]  stg_tdata [0:LATENCY];
  wire                    stg_tvalid[0:LATENCY];
  wire                    stg_tready[0:LATENCY];

  genvar i;
  generate
    // Shift register input
    assign stg_tdata[0] = SIDEBAND_DATAPATH[0] ? i_tlast : {i_tlast, i_tdata};
    assign stg_tvalid[0] = i_tvalid;
    assign i_tready = stg_tready[0];
    // Shift register output
    assign o_tlast = stg_tdata[LATENCY][SHREG_WIDTH-1];
    assign o_tdata = SIDEBAND_DATAPATH[0] ? s_sideband_data : stg_tdata[LATENCY][WIDTH-1:0];
    assign o_tvalid = stg_tvalid[LATENCY];
    assign stg_tready[LATENCY] = o_tready;

    for (i = 0; i < LATENCY; i=i+1) begin: stages
      axi_fifo_flop #(.WIDTH(WIDTH+1)) reg_i (
        .clk(clk), .reset(reset), .clear(1'b0),
        .i_tdata(stg_tdata[i  ]), .i_tvalid(stg_tvalid[i  ]), .i_tready(stg_tready[i  ]),
        .o_tdata(stg_tdata[i+1]), .o_tvalid(stg_tvalid[i+1]), .o_tready(stg_tready[i+1]),
        .occupied(), .space()
      );
      assign stage_stb[i] = stg_tvalid[i] & stg_tready[i];
      assign stage_eop[i] = stage_stb[i] & stg_tdata[i][SHREG_WIDTH-1];
    end
  endgenerate
endmodule // axis_shift_register
