/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Beamforming Delay And Sum
// Input:  NUM_CHANNELS=16 input streams of CHANNEL_WIDTH=14 bits each from ADC
//         Settings reg configuration ports set_stb, set_addr, set_data
//         
// Output: NUM_BEAMS=10 output streams of OUTPUT_WIDTH=16 bits to upper noc_block level. 
// 
// Calculates beamforming operations on input radio_rx streams generating output beams.
// Total number of instanced FIR Filters is NUM_CHANNELS x NUM_BEAMS 
//
// Flow of data:
//
//  NOTE: fifo really means fifo_flop which is a single stage of flip flop piplining
//  radio_rx [CHANNEL_WIDTH] (14 bits) -> intial fifo [CHANNEL_WIDTH] (14 bits) -> digital gain [CHANNEL_WIDTH+GAIN_WIDTH] (32 bits) -> 
//  rounder [COEFF_WIDTH] (18 bits) -> fifo [COEFF_WIDTH] (18 bits) x 2 ->
//  FIR Filters [FILTER_OUT_WIDTH] (40 bits) -> intermediate fifo [FILTER_OUT_WIDTH] (40 bits) x 2 -> 
//  Multi-Sum Module [FILTER_OUT_WIDTH+$clog2(NUM_CHANNELS+1)] (45 bits) -> intermediate fifo [FILTER_OUT_WIDTH+$clog2(NUM_CHANNELS+1)] (45 bits) -> 
//  round and clip [OUTPUT_WIDTH] (16 bits) -> final fifo [OUTPUT_WIDTH] (16 bits)
//
  
  
module beamform_delay_and_sum
#(parameter NUM_CHANNELS=16,
  parameter NUM_BEAMS=10,
  parameter CHANNEL_WIDTH=14,
  parameter GAIN_WIDTH=18,
  parameter COEFF_WIDTH=18,
  parameter FILTER_OUT_WIDTH=16, //when using Jonathon's FIR
  parameter OUTPUT_WIDTH=16,
  parameter JONATHONS_FIR=1,
  parameter SR_FIR_COMMANDS_RELOAD=128,
  parameter SR_FIR_BRAM_WRITE_TAPS=129,
  parameter SR_FIR_COMMANDS_CTRL_TIME_HI=130,
  parameter SR_FIR_COMMANDS_CTRL_TIME_LO=131,
  parameter SR_CHANNEL_GAIN_BASE=190) (
  input clk, input rst,
  //input antenna sources
  input [NUM_CHANNELS*(CHANNEL_WIDTH+2)-1:0] radio_rx_tdata, 
  input [NUM_CHANNELS-1:0] radio_rx_tvalid, 
  //output beam contributions from these antennas
  output [NUM_BEAMS*OUTPUT_WIDTH-1:0] contribute_beams_tdata,  
  output [NUM_BEAMS-1:0] contribute_beams_tvalid,  
  //settings registers stuff
  output reg [1:0] error_stb,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  
  input [63:0] vita_time,
  input [15:0] final_sum,
  input final_sum_valid,
  input final_sum_ready
  );

  localparam INTER_SUM_WIDTH = (2+FILTER_OUT_WIDTH);
  localparam FULL_SUM_WIDTH = (4+FILTER_OUT_WIDTH);
  
  wire [15:0] radio_rx_tdata0 = radio_rx_tdata[15:0];


  //output from radio rx input fifos. Connects to digital gain multiplier
  //CHANNEL_WIDTH=14
  //14 bit, 1 integer bit. 1.0 float = 2**13-1
  wire [NUM_CHANNELS*CHANNEL_WIDTH-1:0] radio_rx_fifo_tdata; 
  wire [NUM_CHANNELS-1:0] radio_rx_fifo_tvalid; 
  
  //debug wire
  wire [CHANNEL_WIDTH-1:0] radio_rx_fifo_tdata0 = radio_rx_fifo_tdata[CHANNEL_WIDTH-1:0];
  
  //settings reg for digital gain input
  //GAIN_WIDTH=18
  //18 bit. 5 integer bits. 1.0 float = 2**13-1, 16.0 float = 2**17-1
  wire [NUM_CHANNELS*GAIN_WIDTH-1:0] digital_gain;  
  
  //debug wire
  wire [GAIN_WIDTH-1:0] digital_gain0 = digital_gain[GAIN_WIDTH-1:0];

  //output of digital gain multiplier
  //CHANNEL_WIDTH+GAIN_WIDTH=32
  //32 bit, 6 integer bits. 1.0 float = 2**26-1, 32.0 float = 2**32-1
  wire [(NUM_CHANNELS*(CHANNEL_WIDTH+GAIN_WIDTH))-1:0]rx_gain_tdata;
  wire [NUM_CHANNELS-1:0] rx_gain_tvalid; 
  
  //debug wire
  wire [(CHANNEL_WIDTH+GAIN_WIDTH)-1:0] rx_gain_tdata0 = rx_gain_tdata[(CHANNEL_WIDTH+GAIN_WIDTH)-1:0];
  
  //output of digital gain rounder
  //GAIN_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
  wire [NUM_CHANNELS*GAIN_WIDTH-1:0]rx_gain_rounded_tdata;
  wire [NUM_CHANNELS-1:0] rx_gain_rounded_tvalid; 
  
  //debug wire
  wire [GAIN_WIDTH-1:0] rx_gain_rounded_tdata0 = rx_gain_rounded_tdata[GAIN_WIDTH-1:0];

  //output from fifo flops after digital gain multiplier.
  //COEFF_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
  (* dont_touch = "true" *)
  wire [NUM_CHANNELS*NUM_BEAMS*COEFF_WIDTH-1:0] rx_gain_fifo_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] rx_gain_fifo_tvalid;
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] rx_gain_fifo_tready; //keeping this tready output from FIR filter
  
  //debug wire 
  wire [COEFF_WIDTH-1:0] rx_gain_fifo_tdata0 = rx_gain_fifo_tdata[COEFF_WIDTH-1:0];
  
  
  //output from fir filters
  //FILTER_OUT_WIDTH=16
  //16 bits, 1 integer bit. 1.0 float = 2**15-1
  wire [NUM_CHANNELS*NUM_BEAMS*FILTER_OUT_WIDTH-1:0] fir_filter_delay_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] fir_filter_delay_tvalid; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] fir_filter_delay_tlast; 
  
  //debug wire
  wire [FILTER_OUT_WIDTH-1:0] fir_filter_delay_tdata0 = fir_filter_delay_tdata[FILTER_OUT_WIDTH-1:0];

  //intermediate fifo to help with timing?
  //FILTER_OUT_WIDTH=16
  //16 bits, 1 integer bit. 1.0 float = 2**15-1
  wire [NUM_CHANNELS*NUM_BEAMS*FILTER_OUT_WIDTH-1:0] fir_filter_delay_fifo_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] fir_filter_delay_fifo_tvalid; 
  
  //debug wire
  wire [FILTER_OUT_WIDTH-1:0] fir_filter_delay_fifo_tdata0 = fir_filter_delay_fifo_tdata[FILTER_OUT_WIDTH-1:0];
  
  //sum the antenna sources into lower half beam contribution
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_1st_quart_tdata; //$clog2(NUM_CHANNELS)=4 
  wire [NUM_BEAMS-1:0] beam_sum_1st_quart_tvalid; 
  
  //debug wire
  wire [INTER_SUM_WIDTH-1:0] beam_sum_1st_quart_tdata0 = beam_sum_1st_quart_tdata[INTER_SUM_WIDTH-1:0];
  
  //intermediate fifo after lower half summation
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_1st_quart_fifo_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_1st_quart_fifo_tvalid;
    
  //sum the antenna sources into upper half beam contribution
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_2nd_quart_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_2nd_quart_tvalid; 
  
  //intermediate fifo after upper half summation
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_2nd_quart_fifo_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_2nd_quart_fifo_tvalid;
  
  //sum the antenna sources into lower half beam contribution
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_3rd_quart_tdata; //$clog2(NUM_CHANNELS)=4 
  wire [NUM_BEAMS-1:0] beam_sum_3rd_quart_tvalid; 
  
  //intermediate fifo after lower half summation
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_3rd_quart_fifo_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_3rd_quart_fifo_tvalid;
    
  //sum the antenna sources into upper half beam contribution
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_4th_quart_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_4th_quart_tvalid; 
  
  //intermediate fifo after upper half summation
  //INTER_SUM_WIDTH=2+FILTER_OUT_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*INTER_SUM_WIDTH-1:0] beam_sum_4th_quart_fifo_tdata; //$clog2(NUM_CHANNELS+1)=4 
  wire [NUM_BEAMS-1:0] beam_sum_4th_quart_fifo_tvalid;
    
  //sum the antenna sources into a beam contribution
  //FULL_SUM_WIDTH=4+FILTER_OUT_WIDTH=20
  //20 bits, 5 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*FULL_SUM_WIDTH-1:0] beam_sum_full_tdata; //$clog2(NUM_CHANNELS+1)=5 
  wire [NUM_BEAMS-1:0] beam_sum_full_tvalid; 
  
  //debug wire
  wire [FULL_SUM_WIDTH-1:0] beam_sum_full_tdata0 = beam_sum_full_tdata[FULL_SUM_WIDTH-1:0];
  
  //intermediate fifo after summation
  //FULL_SUM_WIDTH=4+FILTER_OUT_WIDTH=20
  //20 bits, 5 integer bits. 1.0 float = 2**15-1
  wire [NUM_BEAMS*FULL_SUM_WIDTH-1:0] beam_sum_full_fifo_tdata; //$clog2(NUM_CHANNELS+1)=5 
  wire [NUM_BEAMS-1:0] beam_sum_full_fifo_tvalid; 
  
  //debug wire
  wire [FULL_SUM_WIDTH-1:0] beam_sum_full_fifo_tdata0 = beam_sum_full_fifo_tdata[FULL_SUM_WIDTH-1:0];
  
  //final fifo after rounding summation
  //OUTPUT_WIDTH=16
  //16 bits, 1 integer bits. 1.0 float = 2**15-1  
  wire [NUM_BEAMS*OUTPUT_WIDTH-1:0] beam_sum_rounded_tdata;  
  wire [NUM_BEAMS-1:0] beam_sum_rounded_tvalid; 
  
  //debug wire
  wire [OUTPUT_WIDTH-1:0] beam_sum_rounded_tdata0 = beam_sum_rounded_tdata[OUTPUT_WIDTH-1:0];

  //reload FIR coeff
  //COEFF_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
  (* dont_touch = "true" *)
  wire [NUM_CHANNELS*NUM_BEAMS*COEFF_WIDTH-1:0] m_axis_reload_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tlast; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tvalid; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tready;
  
  //COEFF_WIDTH=18
  //18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1 
  (* dont_touch = "true" *)
  wire [NUM_CHANNELS*NUM_BEAMS*COEFF_WIDTH-1:0] m_axis_reload_fifo_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_fifo_tlast; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_fifo_tvalid; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_fifo_tready;

  wire [10*COEFF_WIDTH-1:0] fir_filter_coeffs_out0;
  wire [39:0] accum_out0;
 
  //for configuring/reloading taps of the FIR filters
  //unused in Jonathon's FIR filter impl
  wire [NUM_CHANNELS*NUM_BEAMS*8-1:0] m_axis_config_tdata; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_config_tvalid; 
  wire [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_config_tready;

  
  wire [1:0] settings_error_stb;
  
  wire [31:0] tap_error_tdata;
  wire tap_error_tlast, tap_error_tvalid, tap_error_tready;
  wire [127:0] tap_error_tuser;
  
  //inside this module is settings regs for configuring delay filter FIR Filter taps and also re-writing the filter taps
  //need to determine Settings reg addresses.
  (* keep_hierarchy = "yes" *)
  settings_reg_fir_tap_bram_config #(.NUM_CHANNELS(NUM_CHANNELS), .NUM_BEAMS(NUM_BEAMS), .NUM_TAPS(10), .TAP_BITS(COEFF_WIDTH), 
    .SR_FIR_COMMANDS_RELOAD(SR_FIR_COMMANDS_RELOAD), .SR_FIR_BRAM_WRITE_TAPS(SR_FIR_BRAM_WRITE_TAPS),
    .SR_FIR_COMMANDS_CTRL_TIME_HI(SR_FIR_COMMANDS_CTRL_TIME_HI), .SR_FIR_COMMANDS_CTRL_TIME_LO(SR_FIR_COMMANDS_CTRL_TIME_LO)) 
    delay_config_inst (
    .clk(clk), .rst(rst), .clear(0),
    //settings reg i/o
    .error_stb(settings_error_stb),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    //fir filter config/reload outputs. NUM_CHANNELS*NUM_BEAMS sets of each. 
    .m_axis_config_tdata(m_axis_config_tdata),
    .m_axis_config_tvalid(m_axis_config_tvalid),
    .m_axis_config_tready(m_axis_config_tready),
    
    .m_axis_reload_tdata(m_axis_reload_tdata),
    .m_axis_reload_tlast(m_axis_reload_tlast),
    .m_axis_reload_tvalid(m_axis_reload_tvalid),
    .m_axis_reload_tready(m_axis_reload_tready),
    
    .vita_time(vita_time),
    
    .error_tdata(tap_error_tdata), //32 bits
    .error_tlast(tap_error_tlast), .error_tvalid(tap_error_tvalid), .error_tready(tap_error_tready), 
    .error_tuser(tap_error_tuser) //128 bits
  ); 
 
  assign tap_error_tready = 1'b1;


  genvar j, k, q;
  generate 
  for (j = 0; j < NUM_CHANNELS; j = j + 1) begin : gen_channels
  
     // setting reg for digital gain muliplier
    setting_reg #(
      .my_addr(SR_CHANNEL_GAIN_BASE+j), .awidth(8), .width(18), .at_reset(1))
    sr_digial_gain (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(digital_gain[GAIN_WIDTH*j+GAIN_WIDTH-1:GAIN_WIDTH*j]), .changed());

    //input FIFO
    //clip input with fifo. 16 bits becomes 14 bits, clip bottom 2 bips though. 
    //14 bit, 1 integer bit. 1.0 float = 2**13-1
    axi_fifo #(
      .WIDTH(CHANNEL_WIDTH), .SIZE(1))
    inst_axi_fifo (
      .clk(clk), .reset(rst), .clear(1'b0),
      .i_tdata(radio_rx_tdata[(CHANNEL_WIDTH+2)*j+CHANNEL_WIDTH+1:(CHANNEL_WIDTH+2)*j+2]), //do some magic here by dropping top 2 bits of input since we know they are zero
      .i_tvalid(radio_rx_tvalid[j]), 
      .i_tready(),
      .o_tdata(radio_rx_fifo_tdata[CHANNEL_WIDTH*j+CHANNEL_WIDTH-1:CHANNEL_WIDTH*j]), 
      .o_tvalid(radio_rx_fifo_tvalid[j]), 
      .o_tready(1'b1),
      .space(), .occupied());

    //digital gain multiplier
    //input a: digital_gain
    //         18 bit. 5 integer bits. 1.0 float = 2**13-1, 16.0 float = 2**17-1
    //input b: radio_rx_fifo
    //         14 bit, 1 integer bit. 1.0 float = 2**13-1
    //output p: rx_gain
    //          32 bit, 6 integer bits. 1.0 float = 2**26-1, 32.0 float = 2**32-1
    mult #(.WIDTH_A(GAIN_WIDTH), .WIDTH_B(CHANNEL_WIDTH), .WIDTH_P(CHANNEL_WIDTH+GAIN_WIDTH), .DROP_TOP_P(5),
                  .LATENCY(4), .CASCADE_OUT(0)) mult_i(
      .clk(clk), .reset(rst),
      .a_tdata(digital_gain[GAIN_WIDTH*j+GAIN_WIDTH-1:GAIN_WIDTH*j]), 
      .a_tlast(1'b0), 
      .a_tvalid(radio_rx_fifo_tvalid[j]), 
      .a_tready(),
      .b_tdata(radio_rx_fifo_tdata[CHANNEL_WIDTH*j+CHANNEL_WIDTH-1:CHANNEL_WIDTH*j]), 
      .b_tlast(1'b0), 
      .b_tvalid(radio_rx_fifo_tvalid[j]), 
      .b_tready(),
      .p_tdata(rx_gain_tdata[(CHANNEL_WIDTH+GAIN_WIDTH)*j+(CHANNEL_WIDTH+GAIN_WIDTH)-1:(CHANNEL_WIDTH+GAIN_WIDTH)*j]), 
      .p_tlast(), 
      .p_tvalid(rx_gain_tvalid[j]), 
      .p_tready(1'b1));
      
    // Clip extra bits for bit growth and round
    //input i: rx_gain
    //         32 bit, 6 integer bits. 1.0 float = 2**26-1, 32.0 float = 2**32-1
    //output o: rx_gain_rounded
    //          18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
    axi_round_and_clip #(
      .WIDTH_IN(CHANNEL_WIDTH+GAIN_WIDTH),
      .WIDTH_OUT(COEFF_WIDTH),
      .CLIP_BITS(3))
    inst_axi_round_and_clip_gain (
      .clk(clk), .reset(rst),
      .i_tdata(rx_gain_tdata[(CHANNEL_WIDTH+GAIN_WIDTH)*j+(CHANNEL_WIDTH+GAIN_WIDTH)-1:(CHANNEL_WIDTH+GAIN_WIDTH)*j]),
      .i_tlast(1'b0),
      .i_tvalid(rx_gain_tvalid[j]),
      .i_tready(),
      .o_tdata(rx_gain_rounded_tdata[COEFF_WIDTH*j+COEFF_WIDTH-1:COEFF_WIDTH*j]),
      .o_tlast(),
      .o_tvalid(rx_gain_rounded_tvalid[j]),
      .o_tready(1'b1)); 
      
    for (k = 0; k < NUM_BEAMS; k = k + 1) begin : gen_beams
      //input i: rx_gain_rounded
      //          18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      //output o: rx_gain_fifo
      //          18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      axi_fifo #(
        .WIDTH(COEFF_WIDTH), .SIZE(3))
      inst_axi_fifo_post_gain (
        .clk(clk), .reset(rst), .clear(1'b0),
        .i_tdata(rx_gain_rounded_tdata[COEFF_WIDTH*j+COEFF_WIDTH-1:COEFF_WIDTH*j]),
        .i_tvalid(rx_gain_rounded_tvalid[j]),
        .i_tready(),
        .o_tdata(rx_gain_fifo_tdata[(COEFF_WIDTH*(NUM_CHANNELS*k+j))+COEFF_WIDTH-1:(COEFF_WIDTH*(NUM_CHANNELS*k+j))]),
        .o_tvalid(rx_gain_fifo_tvalid[NUM_CHANNELS*k+j]),
        .o_tready(1'b1),  
        .space(), .occupied());

      //input i: m_axis_reload
      //          18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      //output o: m_axis_reload_fifo
      //          18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      (* keep_hierarchy = "yes" *)
      axi_fifo #(
        .WIDTH(COEFF_WIDTH+1), .SIZE(4))
      inst_axi_fifo_reload (
        .clk(clk), .reset(rst), .clear(1'b0),
        .i_tdata({m_axis_reload_tlast[NUM_CHANNELS*k+j], m_axis_reload_tdata[(COEFF_WIDTH*(NUM_CHANNELS*k+j))+COEFF_WIDTH-1:(COEFF_WIDTH*(NUM_CHANNELS*k+j))]}),
        .i_tvalid(m_axis_reload_tvalid[NUM_CHANNELS*k+j]),
        .i_tready(m_axis_reload_tready[NUM_CHANNELS*k+j]),
        .o_tdata({m_axis_reload_fifo_tlast[NUM_CHANNELS*k+j] , m_axis_reload_fifo_tdata[(COEFF_WIDTH*(NUM_CHANNELS*k+j))+COEFF_WIDTH-1:(COEFF_WIDTH*(NUM_CHANNELS*k+j))]}),
        .o_tvalid(m_axis_reload_fifo_tvalid[NUM_CHANNELS*k+j]),
        .o_tready(m_axis_reload_fifo_tready[NUM_CHANNELS*k+j]),  
        .space(), .occupied());

 
      // Jonathons FIR Filter
      //The main difference between the Xilinx IP and Jonathon's custom FIR filter is:
      // - Xilinx IP uses Half-ish as many DSPs total
      // - Jonathon's core uses way less LUT/Regs, which from the looks of it are a major constraint we had for timing.
      // Now we have more logic to play with for other uses, which we may need in the top level design. 
      //input s_axis: rx_gain_fifo
      //              18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      //parameter input s_axis_reload: m_axis_reload_fifo
      //              18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
      //intermediate accumulator: sample_accum
      //                          40 bits, 10 integer bits. 1.0 float = 2**30-1
      //output m_axis_data: fir_filter_delay
      //                    16 bits, 1 integer bit. 1.0 float = 2**15-1
      axi_fir_filter #(
        .IN_WIDTH(COEFF_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .OUT_WIDTH(FILTER_OUT_WIDTH),
        .NUM_COEFFS(10),
        .COEFFS_VEC(0),
        .RELOADABLE_COEFFS(1),
        .BLANK_OUTPUT(0),
        // Optional optimizations
        .SYMMETRIC_COEFFS(0),
        .SKIP_ZERO_COEFFS(0),
        .USE_EMBEDDED_REGS_COEFFS(1))
      inst_axi_fir_filter (
        .clk(clk),
        .reset(rst),
        .clear(rst),
        .s_axis_data_tdata(rx_gain_fifo_tdata[(COEFF_WIDTH*(NUM_CHANNELS*k+j))+COEFF_WIDTH-1:(COEFF_WIDTH*(NUM_CHANNELS*k+j))]),
        .s_axis_data_tlast(1'b0),
        .s_axis_data_tvalid(rx_gain_fifo_tvalid[NUM_CHANNELS*k+j]),//each valid goes to many filters
        .s_axis_data_tready(rx_gain_fifo_tready[NUM_CHANNELS*k+j]), //Each filter controls 1 tready
        .m_axis_data_tdata(fir_filter_delay_tdata[(FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))+FILTER_OUT_WIDTH-1:(FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))]),
        .m_axis_data_tvalid(fir_filter_delay_tvalid[NUM_CHANNELS*k+j]),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(fir_filter_delay_tlast[NUM_CHANNELS*k+j]),
        .s_axis_reload_tdata(m_axis_reload_fifo_tdata[(COEFF_WIDTH*(NUM_CHANNELS*k+j))+COEFF_WIDTH-1:(COEFF_WIDTH*(NUM_CHANNELS*k+j))]),
        .s_axis_reload_tvalid(m_axis_reload_fifo_tvalid[NUM_CHANNELS*k+j]),
        .s_axis_reload_tready(m_axis_reload_fifo_tready[NUM_CHANNELS*k+j]),
        .s_axis_reload_tlast(m_axis_reload_fifo_tlast[NUM_CHANNELS*k+j]));
      assign m_axis_config_tready[NUM_CHANNELS*k+j] = 1'b1;
      
                
      //intermediate fifo FIFO fir_filter_delay_rounded_fifo_tdata
      //input i: fir_filter_delay
      //         16 bits, 1 integer bit. 1.0 float = 2**15-1
      //output o: fir_filter_delay_fifo
      //          16 bits, 1 integer bit. 1.0 float = 2**15-1
      axi_fifo #(
        .WIDTH(FILTER_OUT_WIDTH), .SIZE(3))
      inst_axi_fifo_post_delay (
        .clk(clk), .reset(rst), .clear(1'b0),
        .i_tdata(fir_filter_delay_tdata[(FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))+FILTER_OUT_WIDTH-1:(FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))]), 
        .i_tvalid(fir_filter_delay_tvalid[NUM_CHANNELS*k+j]), .i_tready(),
        .o_tdata(fir_filter_delay_fifo_tdata[((FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))+FILTER_OUT_WIDTH-1):(FILTER_OUT_WIDTH*(NUM_CHANNELS*k+j))]),
        .o_tvalid(fir_filter_delay_fifo_tvalid[NUM_CHANNELS*k+j]), .o_tready(1'b1),
        .space(), .occupied());         
   
    end
  end
  endgenerate
          
          
    generate
    for (k = 0; k < NUM_BEAMS; k = k + 1) begin : sum_contributions     
      //need to do some math to figure out which wires go where in the addition stage. 1 filter output per antenna. 10 sums total
        
        //cannot for the life of me figure out how to do a generate statement for all 4 quarters of the summation right now.
        //summing 4 inputs, 1st quarter of the beam channels
        //input i: fir_filter_delay_fifo
        //         16 bits, 1 integer bit. 1.0 float = 2**15-1
        //output sum: beam_sum_1st_quart
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        multi_stream_add #(.WIDTH(FILTER_OUT_WIDTH),.NUM_INPUTS(NUM_CHANNELS/4)) msa_inst_1st_quart (
          .clk(clk), .rst(rst),
          .i_tdata(fir_filter_delay_fifo_tdata[FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS/4)-1:FILTER_OUT_WIDTH*NUM_CHANNELS*k]), 
          .i_tlast(1'b0), 
          .i_tvalid(fir_filter_delay_fifo_tvalid[NUM_CHANNELS*k+NUM_CHANNELS/4-1:NUM_CHANNELS*k]), 
          .i_tready(),
          .sum_tdata(beam_sum_1st_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),  
          .sum_tlast(),
          .sum_tvalid(beam_sum_1st_quart_tvalid[k]),  
          .sum_tready(1'b1));
        
        //summing 4 inputs, 2nd quarter of the beam channels
        //input i: fir_filter_delay_fifo
        //         16 bits, 1 integer bit. 1.0 float = 2**15-1
        //output sum: beam_sum_2nd_quart
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        multi_stream_add #(.WIDTH(FILTER_OUT_WIDTH),.NUM_INPUTS(NUM_CHANNELS/4)) msa_inst_2nd_quart (
          .clk(clk), .rst(rst),
          .i_tdata(fir_filter_delay_fifo_tdata[FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS/2)-1:FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS/4)]), 
          .i_tlast(1'b0), 
          .i_tvalid(fir_filter_delay_fifo_tvalid[NUM_CHANNELS*k+NUM_CHANNELS/2-1:NUM_CHANNELS*k+NUM_CHANNELS/4]), 
          .i_tready(),
          .sum_tdata(beam_sum_2nd_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),  
          .sum_tlast(),
          .sum_tvalid(beam_sum_2nd_quart_tvalid[k]),  
          .sum_tready(1'b1));
        
        //summing 4 inputs, 3rd quarter of the beam channels
        //input i: fir_filter_delay_fifo
        //         16 bits, 1 integer bit. 1.0 float = 2**15-1
        //output sum: beam_sum_3rd_quart
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        multi_stream_add #(.WIDTH(FILTER_OUT_WIDTH),.NUM_INPUTS(NUM_CHANNELS/4)) msa_inst_3rd_quart (
          .clk(clk), .rst(rst),
          .i_tdata(fir_filter_delay_fifo_tdata[FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS*3/4)-1:FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS/2)]), 
          .i_tlast(1'b0), 
          .i_tvalid(fir_filter_delay_fifo_tvalid[NUM_CHANNELS*k+NUM_CHANNELS*3/4-1:NUM_CHANNELS*k+NUM_CHANNELS/2]), 
          .i_tready(),
          .sum_tdata(beam_sum_3rd_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),  
          .sum_tlast(),
          .sum_tvalid(beam_sum_3rd_quart_tvalid[k]),  
          .sum_tready(1'b1));
        
        //summing 4 inputs, 4th quarter of the beam channels
        //input i: fir_filter_delay_fifo
        //         16 bits, 1 integer bit. 1.0 float = 2**15-1
        //output sum: beam_sum_4th_quart
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1        
        multi_stream_add #(.WIDTH(FILTER_OUT_WIDTH),.NUM_INPUTS(NUM_CHANNELS/4)) msa_inst_4th_quart (
          .clk(clk), .rst(rst),
          .i_tdata(fir_filter_delay_fifo_tdata[FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS)-1:FILTER_OUT_WIDTH*(NUM_CHANNELS*k+NUM_CHANNELS*3/4)]), 
          .i_tlast(1'b0), 
          .i_tvalid(fir_filter_delay_fifo_tvalid[NUM_CHANNELS*k+NUM_CHANNELS-1:NUM_CHANNELS*k+NUM_CHANNELS*3/4]), 
          .i_tready(),
          .sum_tdata(beam_sum_4th_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),  
          .sum_tlast(),
          .sum_tvalid(beam_sum_4th_quart_tvalid[k]),  
          .sum_tready(1'b1));

        //post quarter sum fifo to ease timing
        //input i: beam_sum_1st_quart
        //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        //output o: beam_sum_1st_quart_fifo
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1    
        axi_fifo #(
          .WIDTH(INTER_SUM_WIDTH), .SIZE(1))
        inst_axi_fifo_1st_quart (
          .clk(clk), .reset(rst), .clear(1'b0),
          .i_tdata(beam_sum_1st_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]), 
          .i_tvalid(beam_sum_1st_quart_tvalid[k]), .i_tready(),
          .o_tdata(beam_sum_1st_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),
          .o_tvalid(beam_sum_1st_quart_fifo_tvalid[k]), .o_tready(1'b1),
          .space(), .occupied());
        //post quarter sum fifo to ease timing
        //input i: beam_sum_2nd_quart
        //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        //output o: beam_sum_2nd_quart_fifo
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1              
        axi_fifo #(
          .WIDTH(INTER_SUM_WIDTH), .SIZE(1))
        inst_axi_fifo_2nd_quart (
          .clk(clk), .reset(rst), .clear(1'b0),
          .i_tdata(beam_sum_2nd_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]), 
          .i_tvalid(beam_sum_2nd_quart_tvalid[k]), .i_tready(),
          .o_tdata(beam_sum_2nd_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),
          .o_tvalid(beam_sum_2nd_quart_fifo_tvalid[k]), .o_tready(1'b1),
          .space(), .occupied());
        //post quarter sum fifo to ease timing
        //input i: beam_sum_1st_quart
        //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        //output o: beam_sum_1st_quart_fifo
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1    
        axi_fifo #(
            .WIDTH(INTER_SUM_WIDTH), .SIZE(1))
          inst_axi_fifo_3rd_quart (
            .clk(clk), .reset(rst), .clear(1'b0),
            .i_tdata(beam_sum_3rd_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]), 
            .i_tvalid(beam_sum_3rd_quart_tvalid[k]), .i_tready(),
            .o_tdata(beam_sum_3rd_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),
            .o_tvalid(beam_sum_3rd_quart_fifo_tvalid[k]), .o_tready(1'b1),
            .space(), .occupied());
        //post quarter sum fifo to ease timing
        //input i: beam_sum_1st_quart
        //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        //output o: beam_sum_1st_quart_fifo
        //            18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1             
        axi_fifo #(
          .WIDTH(INTER_SUM_WIDTH), .SIZE(1))
        inst_axi_fifo_4th_quart (
          .clk(clk), .reset(rst), .clear(1'b0),
          .i_tdata(beam_sum_4th_quart_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]), 
          .i_tvalid(beam_sum_4th_quart_tvalid[k]), .i_tready(),
          .o_tdata(beam_sum_4th_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]),
          .o_tvalid(beam_sum_4th_quart_fifo_tvalid[k]), .o_tready(1'b1),
          .space(), .occupied());
                   
        //final summation of the 4 quarter sums, just 2 inputs
        //input i: beam_sum_1st_quart_fifo
        //         18 bits, 3 integer bits. 1.0 float = 2**15-1, 4.0 float = 2**17-1
        //output sum: beam_sum_full
        //            20 bits, 5 integer bits. 1.0 float = 2**15-1, 16.0 float = 2**19-1          
        multi_stream_add #(.WIDTH(INTER_SUM_WIDTH),.NUM_INPUTS(4)) msa_inst_last (
          .clk(clk), .rst(rst),
          .i_tdata({beam_sum_1st_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k],
          beam_sum_2nd_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k],
          beam_sum_3rd_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k],
          beam_sum_4th_quart_fifo_tdata[(INTER_SUM_WIDTH)*k+(INTER_SUM_WIDTH)-1:(INTER_SUM_WIDTH)*k]}), 
          .i_tlast(1'b0), 
          .i_tvalid({beam_sum_1st_quart_fifo_tvalid[k], beam_sum_2nd_quart_fifo_tvalid[k], beam_sum_3rd_quart_fifo_tvalid[k], beam_sum_4th_quart_fifo_tvalid[k]}), 
          .i_tready(),
          .sum_tdata(beam_sum_full_tdata[(FULL_SUM_WIDTH)*k+(FULL_SUM_WIDTH)-1:(FULL_SUM_WIDTH)*k]),  
          .sum_tlast(),
          .sum_tvalid(beam_sum_full_tvalid[k]),  
          .sum_tready(1'b1));
       
        //final fifo after summation, after rounding, before final output contribution beams
        //input i: beam_sum_full
        //         20 bits, 5 integer bits. 1.0 float = 2**15-1, 16.0 float = 2**19-1         
        //output o: beam_sum_full_fifo
        //            20 bits, 5 integer bits. 1.0 float = 2**15-1, 16.0 float = 2**19-1         
        axi_fifo #(
          .WIDTH(FULL_SUM_WIDTH), .SIZE(1))
        inst_axi_fifo_sum (
          .clk(clk), .reset(rst), .clear(1'b0),
          .i_tdata(beam_sum_full_tdata[(FULL_SUM_WIDTH)*k+(FULL_SUM_WIDTH)-1:(FULL_SUM_WIDTH)*k]), 
          .i_tvalid(beam_sum_full_tvalid[k]), .i_tready(),
          .o_tdata(beam_sum_full_fifo_tdata[(FULL_SUM_WIDTH)*k+(FULL_SUM_WIDTH)-1:(FULL_SUM_WIDTH)*k]),
          .o_tvalid(beam_sum_full_fifo_tvalid[k]), .o_tready(1'b1),
          .space(), .occupied());              

        // Clip extra bits for bit growth and round
        //input i: beam_sum_full_fifo
        //         20 bits, 5 integer bits. 1.0 float = 2**15-1, 16.0 float = 2**19-1         
        //output o: beam_sum_full_fifo
        //          16 bits, 1 integer bits. 1.0 float = 2**15-1
        axi_clip #(
          .WIDTH_IN(FULL_SUM_WIDTH),
          .WIDTH_OUT(OUTPUT_WIDTH))
        inst_axi_clip_sum (
          .clk(clk), .reset(rst),
          .i_tdata(beam_sum_full_fifo_tdata[(FULL_SUM_WIDTH)*k+(FULL_SUM_WIDTH)-1:(FULL_SUM_WIDTH)*k]),
          .i_tlast(1'b0),
          .i_tvalid(beam_sum_full_fifo_tvalid[k]),
          .i_tready(),
          .o_tdata(beam_sum_rounded_tdata[OUTPUT_WIDTH*k+OUTPUT_WIDTH-1:OUTPUT_WIDTH*k]),
          .o_tlast(),
          .o_tvalid(beam_sum_rounded_tvalid[k]),
          .o_tready(1'b1)); 
        
        //final fifo after summation, after rounding, before final output contribution beams
        //input i: beam_sum_full_fifo
        //          16 bits, 1 integer bits. 1.0 float = 2**15-1
        //output o: beam_sum_full_fifo
        //          16 bits, 1 integer bits. 1.0 float = 2**15-1
        axi_fifo #(
          .WIDTH(OUTPUT_WIDTH), .SIZE(1))
        inst_axi_fifo_final (
          .clk(clk), .reset(rst), .clear(1'b0),
          .i_tdata(beam_sum_rounded_tdata[OUTPUT_WIDTH*k+OUTPUT_WIDTH-1:OUTPUT_WIDTH*k]), 
          .i_tvalid(beam_sum_rounded_tvalid[k]), .i_tready(),
          .o_tdata(contribute_beams_tdata[OUTPUT_WIDTH*k+OUTPUT_WIDTH-1:OUTPUT_WIDTH*k]),
          .o_tvalid(contribute_beams_tvalid[k]), .o_tready(1'b1),
          .space(), .occupied());              
    end     
    endgenerate 
/*    
    ila_beamform inst_ila (
      .clk(clk), // input wire clk
      .probe0(radio_rx_fifo_tdata0), // input wire [13:0]  probe0  channel 0
      .probe1(digital_gain0), // input wire [17:0]  probe1 channel 0
      .probe2(rx_gain_tdata0), // input wire [31:0]  probe2
      .probe3(rx_gain_rounded_tdata0), // input wire [17:0]  probe2
      .probe4(rx_gain_fifo_tdata0), // input wire [17:0]  probe2
      .probe5(fir_filter_delay_tdata0), // input wire [15:0]  probe2
      .probe6(beam_sum_1st_quart_tdata0), // input wire [17:0]  probe2
      .probe7(beam_sum_full_tdata0), // input wire [19:0]  probe2
      .probe8(beam_sum_full_fifo_tdata0), // input wire [19:0]  probe2
      .probe9(beam_sum_rounded_tdata0), // input wire [15:0]  probe2  
      .probe10(beam_sum_rounded_tvalid[0]), //input wire
      .probe11(final_sum),
      .probe12(final_sum_valid),
      .probe13(final_sum_ready),
      .probe14(accum_out0),
      .probe15(fir_filter_coeffs_out0[COEFF_WIDTH-1:0]),
      .probe16(fir_filter_coeffs_out0[2*COEFF_WIDTH-1:1*COEFF_WIDTH]),
      .probe17(fir_filter_coeffs_out0[3*COEFF_WIDTH-1:2*COEFF_WIDTH]),
      .probe18(fir_filter_coeffs_out0[4*COEFF_WIDTH-1:3*COEFF_WIDTH]),
      .probe19(fir_filter_coeffs_out0[5*COEFF_WIDTH-1:4*COEFF_WIDTH]),
      .probe20(fir_filter_coeffs_out0[6*COEFF_WIDTH-1:5*COEFF_WIDTH]),
      .probe21(fir_filter_coeffs_out0[7*COEFF_WIDTH-1:6*COEFF_WIDTH]),
      .probe22(fir_filter_coeffs_out0[8*COEFF_WIDTH-1:7*COEFF_WIDTH]),
      .probe23(fir_filter_coeffs_out0[9*COEFF_WIDTH-1:8*COEFF_WIDTH]),
      .probe24(fir_filter_coeffs_out0[10*COEFF_WIDTH-1:9*COEFF_WIDTH])
    );
*/
endmodule
