//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_block_fft_vector_iir_tb();
  /*********************************************
  ** User variables
  *********************************************/
  localparam CLOCK_FREQ = 200e6;  // MHz
  localparam RESET_TIME = 100;    // ns

  /*********************************************
  ** Helper Tasks
  *********************************************/
  `include "rfnoc_sim_lib.v" 

  /*********************************************
  ** DUT
  *********************************************/
  wire [63:0] vector_iir_i_tdata, fft_i_tdata, keep_one_in_n_i_tdata;
  wire vector_iir_i_tlast, fft_i_tlast, keep_one_in_n_i_tlast;
  wire vector_iir_i_tvalid, fft_i_tvalid, keep_one_in_n_i_tvalid;
  wire vector_iir_i_tready, fft_i_tready, keep_one_in_n_i_tready;
  wire [63:0] vector_iir_o_tdata, fft_o_tdata, keep_one_in_n_o_tdata;
  wire vector_iir_o_tlast, fft_o_tlast, keep_one_in_n_o_tlast;
  wire vector_iir_o_tvalid, fft_o_tvalid, keep_one_in_n_o_tvalid;
  wire vector_iir_o_tready, fft_o_tready, keep_one_in_n_o_tready;

  noc_block_fft #(
    .ENABLE_MAGNITUDE_OUT(1))
  inst_noc_block_fft (
    .bus_clk(clk), .bus_rst(rst),
    .ce_clk(clk), .ce_rst(rst),
    .i_tdata(fft_o_tdata), .i_tlast(fft_o_tlast), .i_tvalid(fft_o_tvalid), .i_tready(fft_o_tready),
    .o_tdata(fft_i_tdata), .o_tlast(fft_i_tlast), .o_tvalid(fft_i_tvalid), .o_tready(fft_i_tready),
    .debug());

  noc_block_vector_iir inst_noc_block_vector_iir (
    .bus_clk(clk), .bus_rst(rst),
    .ce_clk(clk), .ce_rst(rst),
    .i_tdata(vector_iir_o_tdata), .i_tlast(vector_iir_o_tlast), .i_tvalid(vector_iir_o_tvalid), .i_tready(vector_iir_o_tready),
    .o_tdata(vector_iir_i_tdata), .o_tlast(vector_iir_i_tlast), .o_tvalid(vector_iir_i_tvalid), .o_tready(vector_iir_i_tready),
    .debug());

  noc_block_keep_one_in_n inst_noc_block_keep_one_in_n (
    .bus_clk(clk), .bus_rst(rst),
    .ce_clk(clk), .ce_rst(rst),
    .i_tdata(keep_one_in_n_o_tdata), .i_tlast(keep_one_in_n_o_tlast), .i_tvalid(keep_one_in_n_o_tvalid), .i_tready(keep_one_in_n_o_tready),
    .o_tdata(keep_one_in_n_i_tdata), .o_tlast(keep_one_in_n_i_tlast), .o_tvalid(keep_one_in_n_i_tvalid), .o_tready(keep_one_in_n_i_tready),
    .debug());

  reg        xbar_set_stb  = 1'b0;
  reg [8:0]  xbar_set_addr = 8'd0;
  reg [31:0] xbar_set_data = 32'd0;
  
  localparam [6:0] BASE         = 8'd0;
  localparam [7:0] XBAR_ADDR    = 8'd3;
  localparam NUM_CE             = 3;
  localparam XBAR_PORTS         = NUM_CE + 1;

  axi_crossbar #(
    .BASE(BASE),.FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_PORTS), .NUM_OUTPUTS(XBAR_PORTS))
  inst_axi_crossbar (
    .clk(clk), .reset(rst), .clear(1'b0),
    .local_addr(XBAR_ADDR),
    .set_stb(xbar_set_stb), .set_addr({BASE,xbar_set_addr}), .set_data(xbar_set_data),
    .i_tdata({keep_one_in_n_i_tdata,vector_iir_i_tdata,fft_i_tdata,i_tdata}),
    .i_tlast({keep_one_in_n_i_tlast,vector_iir_i_tlast,fft_i_tlast,i_tlast}),
    .i_tvalid({keep_one_in_n_i_tvalid,vector_iir_i_tvalid,fft_i_tvalid,i_tvalid}),
    .i_tready({keep_one_in_n_i_tready,vector_iir_i_tready,fft_i_tready,i_tready}),
    .o_tdata({keep_one_in_n_o_tdata,vector_iir_o_tdata,fft_o_tdata,o_tdata}),
    .o_tlast({keep_one_in_n_o_tlast,vector_iir_o_tlast,fft_o_tlast,o_tlast}),
    .o_tvalid({keep_one_in_n_o_tvalid,vector_iir_o_tvalid,fft_o_tvalid,o_tvalid}),
    .o_tready({keep_one_in_n_o_tready,vector_iir_o_tready,fft_o_tready,o_tready}),
    .pkt_present({keep_one_in_n_i_tvalid,vector_iir_i_tvalid,fft_i_tvalid,i_tvalid}),
    .rb_rd_stb(), .rb_addr(), .rb_data());

  localparam [3:0] FFT_XBAR_PORT           = 4'd1;
  localparam [3:0] VECTOR_IIR_XBAR_PORT    = 4'd2;
  localparam [3:0] KEEP_ONE_IN_N_XBAR_PORT = 4'd3;
  // Last 4 bits are block ports
  localparam [15:0] SRC_SID           = {     8'd0,                    4'd0, 4'd0};
  localparam [15:0] FFT_SID           = {XBAR_ADDR,           FFT_XBAR_PORT, 4'd0};
  localparam [15:0] VECTOR_IIR_SID    = {XBAR_ADDR,    VECTOR_IIR_XBAR_PORT, 4'd0};
  localparam [15:0] KEEP_ONE_IN_N_SID = {XBAR_ADDR, KEEP_ONE_IN_N_XBAR_PORT, 4'd0};

  localparam [15:0] FFT_SIZE = 256;
  
  wire [7:0] fft_size_log2 = $clog2(FFT_SIZE);      // Set FFT size
  wire fft_direction       = 0;                     // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale    = 12'b011010101010;      // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word = {fft_scale, fft_direction, fft_size_log2};
  integer i;

  localparam [31:0] ALPHA = $floor(0.9*2**31);
  localparam [31:0] BETA = $floor(0.1*2**31);

  initial begin
    @(negedge rst);
    @(posedge clk);
    
    // Program crossbar
    xbar_set_stb = 1'b1;
    // The crossbar's routing table forwards packets based on a SID to a particular crossbar port.
    // 16-bit SID: [ 15-8: Xbar Addr | 7-4: Xbar Port | 3-0: Block Port ] 
    // The crossbar is generic -- the SID is used as a address in the routing table
    // to lookup the appropriate crossbar port. Our SID format however has 
    // xbar port & block port defined, so we map our SID's xbar port one-to-one to the actual xbar port.
    // To handle remote vs local destinations, the routing table has two parts. The lower 256 addresses 
    // are used to forward packets not intended for this crossbar to remote destinations/other crossbars.
    // The upper 256 address are used for local addresses.
    //
    // Programming routing table:
    // -- Xbar set addr --
    // Bits 0-7: Lower 8-bits of incoming SID (7-4: Xbar Port, 3-0: Block Port)
    //        8: 0 = Remote, 1 = Local Destination
    // -- Xbar set data --
    // Bits 0-3: Destination Xbar Port
    xbar_set_addr = {1'b0,4'd0,4'd0};
    xbar_set_data = {28'd0,4'd0};
    @(posedge clk);
    xbar_set_stb = 1'b0;
    @(posedge clk);
    xbar_set_stb = 1'b1;
    xbar_set_addr = {1'b1,4'd1,4'd0};
    xbar_set_data = {28'd0,4'd1};
    @(posedge clk);
    xbar_set_stb = 1'b0;
    @(posedge clk);
    xbar_set_stb = 1'b1;
    xbar_set_addr = {1'b1,4'd2,4'd0};
    xbar_set_data = {28'd0,4'd2};
    @(posedge clk);
    xbar_set_stb = 1'b0;
    @(posedge clk);
    xbar_set_stb = 1'b1;
    xbar_set_addr = {1'b1,4'd3,4'd0};
    xbar_set_data = {28'd0,4'd3};
    @(posedge clk);
    xbar_set_stb = 1'b0;
    @(posedge clk);
    #1000;

    // Setup FFT
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});              // Command packet to set up flow control
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});               // Command packet to set up source control window size
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                 // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, SR_NEXT_DST_BASE, {16'd0, VECTOR_IIR_SID}});                      // Set next destination
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word}});                     // Configure FFT core
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, inst_noc_block_fft.SR_FFT_SIZE_LOG2, {24'd0, fft_size_log2}});    // Set FFT size register
    SendCtrlPacket(12'd0, {SRC_SID,FFT_SID}, {24'd0, inst_noc_block_fft.SR_MAGNITUDE_OUT, {31'd0, 1'b1}});             // Enable magnitude out
    #1000;

    // Setup Vector IIR
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});               // Command packet to set up flow control
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});                // Command packet to set up source control window size
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                  // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, SR_NEXT_DST_BASE, {16'd0,KEEP_ONE_IN_N_SID}});                 // Set next destination
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, inst_noc_block_vector_iir.SR_VECTOR_LEN, {16'd0, FFT_SIZE}});  // Set Vector length register
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, inst_noc_block_vector_iir.SR_ALPHA, ALPHA});
    SendCtrlPacket(12'd0, {SRC_SID,VECTOR_IIR_SID}, {24'd0, inst_noc_block_vector_iir.SR_BETA, BETA});
    #1000;

    // Setup Keep one in n
    SendCtrlPacket(12'd0, {SRC_SID,KEEP_ONE_IN_N_SID}, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});            // Command packet to set up flow control
    SendCtrlPacket(12'd0, {SRC_SID,KEEP_ONE_IN_N_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});             // Command packet to set up source control window size
    SendCtrlPacket(12'd0, {SRC_SID,KEEP_ONE_IN_N_SID}, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});               // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, {SRC_SID,KEEP_ONE_IN_N_SID}, {24'd0, SR_NEXT_DST_BASE, {16'd0,SRC_SID}});                        // Set next destination
    SendCtrlPacket(12'd0, {SRC_SID,KEEP_ONE_IN_N_SID}, {24'd0, inst_noc_block_keep_one_in_n.SR_N, {32'd4}});     // Keep 1 in 4
    #1000;

    // Send 1/8th sample rate sine wave
    @(posedge clk);
    forever begin
      SendChdr(CHDR_DATA_PKT_TYPE, 0, 12'd0, FFT_SIZE*SC16_NUM_BYTES, {SRC_SID,FFT_SID}, 0);
      for (i = 0; i < (FFT_SIZE/RFNOC_CHDR_NUM_SC16_PER_LINE/4); i = i + 1) begin
        SendPayload({ 16'd32767,     16'd0, 16'd23170, 16'd23170},0);
        SendPayload({     16'd0, 16'd32767,-16'd23170, 16'd23170},0);
        SendPayload({-16'd32767,     16'd0,-16'd23170,-16'd23170},0);
        SendPayload({     16'd0,-16'd32767, 16'd23170,-16'd23170},
          (i == (FFT_SIZE/RFNOC_CHDR_NUM_SC16_PER_LINE/4)-1)); // Assert tlast on final word
      end
    end
  end

endmodule