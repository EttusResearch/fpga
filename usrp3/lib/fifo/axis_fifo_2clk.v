//
// Copyright 2016 Ettus Research
//

module axis_fifo_2clk #(
  parameter WIDTH      = 72
)(
  input                s_axis_areset,
  input                s_axis_aclk,
  input  [WIDTH-1:0]   s_axis_tdata,
  input                s_axis_tvalid,
  output               s_axis_tready,
  input                m_axis_aclk,
  output [WIDTH-1:0]   m_axis_tdata,
  output               m_axis_tvalid,
  input                m_axis_tready
);

  //----------------------------------------------
  // Pipeline Logic
  //----------------------------------------------
  wire [WIDTH-1:0]  i_tdata, o_tdata;
  wire              i_tvalid, o_tvalid, i_tready, o_tready;

  assign {m_axis_tdata, m_axis_tvalid} = {o_tdata, o_tvalid};
  assign o_tready = m_axis_tready;
  assign {i_tdata, i_tvalid} = {s_axis_tdata, s_axis_tvalid};
  assign s_axis_tready = i_tready;

  //----------------------------------------------
  // FIFO Logic
  //----------------------------------------------

  localparam BASE_WIDTH = 64;
  localparam NUM_FIFOS = ((WIDTH-1)/BASE_WIDTH)+1;
  localparam INT_WIDTH = BASE_WIDTH * NUM_FIFOS;

  wire [INT_WIDTH-1:0] i_flat_tdata, o_flat_tdata;
  wire [NUM_FIFOS-1:0] i_flat_tready, o_flat_tvalid;
  wire                 i_flat_tvalid, o_flat_tready;

  assign i_tready      = &i_flat_tready;
  assign o_tvalid      = &o_flat_tvalid;
  assign i_flat_tvalid = i_tvalid;
  assign o_flat_tready = o_tvalid & o_tready;

  assign o_tdata       = o_flat_tdata[WIDTH-1:0];
  assign i_flat_tdata  = {{(INT_WIDTH-WIDTH){1'b0}}, i_tdata};

  genvar i;
  generate
    for (i = 0; i < NUM_FIFOS; i = i + 1) begin: fifo_section
      axi64_4k_2clk_fifo axi_2clk_fifo_i (
        .s_aresetn(~s_axis_areset), .s_aclk(s_axis_aclk),
        .s_axis_tdata(i_flat_tdata[((i+1)*BASE_WIDTH)-1:i*BASE_WIDTH]),
        .s_axis_tvalid(i_flat_tvalid),
        .s_axis_tready(i_flat_tready[i]),
        .m_aclk(m_axis_aclk),
        .m_axis_tdata(o_flat_tdata[((i+1)*BASE_WIDTH)-1:i*BASE_WIDTH]),
        .m_axis_tvalid(o_flat_tvalid[i]),
        .m_axis_tready(o_flat_tready)
      );
    end
  endgenerate

endmodule
