//
// Copyright 2015 Ettus Research LLC
//

module rx_frontend_gen3 #(
  parameter SR_MAG_CORRECTION = 0,
  parameter SR_PHASE_CORRECTION = 1,
  parameter SR_OFFSET_I = 2,
  parameter SR_OFFSET_Q = 3,
  parameter SR_SWAP_IQ = 4,
  parameter BYPASS_DC_OFFSET_CORR = 0,
  parameter BYPASS_IQ_COMP = 0,
  parameter DEVICE = "7SERIES"
)(
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input adc_stb, input [15:0] adc_i, input [15:0] adc_q,
  output rx_stb, output [15:0] rx_i, output [15:0] rx_q
);

  wire               realmode;
  wire               swap_iq;
  wire               invert_i;
  wire               invert_q;
  wire [17:0]        scale_factor;
  wire [17:0]        mag_corr, phase_corr;

  reg  [23:0]        rx_i_mux, rx_q_mux;
  wire [35:0]        corr_i, corr_q;
  wire               adc_ofs_stb, adc_comp_stb;
  wire [23:0]        adc_i_ofs, adc_q_ofs, adc_i_comp, adc_q_comp;
  reg                adc_ofs_stb_dly;
  reg  [23:0]        adc_i_ofs_dly, adc_q_ofs_dly;
  reg                adc_mux_stb;
  reg  [15:0]        adc_i_mux, adc_q_mux;

  /********************************************************
  ** Settings Bus Registers
  ********************************************************/
  setting_reg #(.my_addr(SR_MAG_CORRECTION),.width(18)) sr_mag_corr (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(mag_corr),.changed());

  setting_reg #(.my_addr(SR_PHASE_CORRECTION),.width(18)) sr_phase_corr (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(phase_corr),.changed());

  setting_reg #(.my_addr(SR_SWAP_IQ), .width(4)) sr_mux_sel (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out({invert_i,invert_q,realmode,swap_iq}),.changed());

  /********************************************************
  ** DSP
  ********************************************************/
  // MUX so we can do realmode signals on either input
  always @(posedge clk) begin
    if (swap_iq) begin
      adc_i_mux <= invert_q ? ~adc_q   : adc_q;
      adc_q_mux <= realmode ? 16'd0 : invert_i ? ~adc_i : adc_i;
    end else begin
      adc_i_mux <= invert_i ? ~adc_i   : adc_i;
      adc_q_mux <= realmode ? 16'd0 : invert_q ? ~adc_q : adc_q;
    end
    adc_mux_stb <= adc_stb;
  end
  
  // DC offset correction
  generate
    if (BYPASS_DC_OFFSET_CORR == 1) begin
      rx_dcoffset #(.WIDTH(24),.ADDR(SR_OFFSET_I)) rx_dcoffset_i (
        .clk(clk),.rst(reset),.set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
        .in_stb(adc_mux_stb),.in({adc_i_mux,8'd0}),
        .out_stb(adc_ofs_stb),.out(adc_i_ofs));
      rx_dcoffset #(.WIDTH(24),.ADDR(SR_OFFSET_Q)) rx_dcoffset_q (
        .clk(clk),.rst(reset),.set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
        .in_stb(adc_mux_stb),.in({adc_q_mux,8'd0}),
        .out_stb(),.out(adc_q_ofs));
    end else begin
      assign adc_ofs_stb = adc_mux_stb;
      assign adc_i_ofs = {adc_i_mux,8'd0};
      assign adc_q_ofs = {adc_q_mux,8'd0};
    end
  endgenerate

  // I/Q compensation
  generate
    if (BYPASS_IQ_COMP == 1) begin

      MULT_MACRO #(
        .DEVICE(DEVICE), .LATENCY(1),
        .WIDTH_A(18), .WIDTH_B(18))
      mult_i (
        .CLK(clk), .RST(reset), .CE(adc_ofs_stb),
        .P(corr_i), .A(adc_i_ofs[23:6]), .B(mag_corr));
      MULT_MACRO #(
        .DEVICE(DEVICE), .LATENCY(1),
        .WIDTH_A(18), .WIDTH_B(18))
      mult_q (
        .CLK(clk), .RST(reset), .CE(adc_ofs_stb),
        .P(corr_q), .A(adc_i_ofs[23:6]), .B(phase_corr));

      // Delay to match path latencies
      always @(posedge clk) begin
        if (reset) begin
          adc_ofs_stb_dly <= 1'b0;
          adc_i_ofs_dly   <= 24'd0;
          adc_q_ofs_dly   <= 24'd0;
        end else begin
          adc_ofs_stb_dly <= adc_ofs_stb;
          if (adc_ofs_stb) begin
            adc_i_ofs_dly <= adc_i_ofs;
            adc_q_ofs_dly <= adc_q_ofs;
          end
        end
      end

      add2_and_clip_reg #(.WIDTH(24))
      add_clip_i (
        .clk(clk), .rst(reset),
        .in1(adc_i_ofs_dly), .in2(corr_i[35:12]), .strobe_in(adc_ofs_stb_dly),
        .sum(adc_i_comp), .strobe_out(adc_comp_stb));
      add2_and_clip_reg #(.WIDTH(24))
      add_clip_q (
        .clk(clk), .rst(reset), 
        .in1(adc_q_ofs_dly), .in2(corr_q[35:12]), .strobe_in(adc_ofs_stb_dly),
        .sum(adc_q_comp), .strobe_out());

    end else begin
      assign adc_comp_stb = adc_ofs_stb;
      assign adc_i_comp   = adc_i_ofs;
      assign adc_q_comp   = adc_q_ofs;
    end
  endgenerate

  // Round to short complex (sc16)
  round_sd #(.WIDTH_IN(24),.WIDTH_OUT(16)) round_i (
    .clk(clk),.reset(reset), .in(adc_i_comp),.strobe_in(adc_comp_stb), .out(rx_i), .strobe_out(rx_stb));
  round_sd #(.WIDTH_IN(24),.WIDTH_OUT(16)) round_q (
    .clk(clk),.reset(reset), .in(adc_q_comp),.strobe_in(adc_comp_stb), .out(rx_q), .strobe_out());

endmodule