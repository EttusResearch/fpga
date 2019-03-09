/////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Settings Reg to Configure FIR TAPs in Beamformer Matrix
//
// Input: Settings bus for configuration commands
//
// Output: AXIS Fir Filter Configuration lines
//
// Uses Noc Block settings regs to load commands into a command fifo.
// Each command is composed of a FIR filter index to specify which FIR we want
// to configure, and a TAP index which points to a set of taps preloaded in
// the tap BRAM. 
// TAP BRAM has 1000 tap values configured as delays for beamforming.
//
// 


module settings_reg_fir_tap_bram_config #(
  parameter NUM_CHANNELS = 16, 
  parameter NUM_BEAMS = 10,
  parameter NUM_TAPS = 10,
  parameter TAP_BITS = 18,
  parameter SR_FIR_COMMANDS_RELOAD = 220,
  parameter SR_FIR_COMMANDS_CTRL_TIME_HI = 221,
  parameter SR_FIR_COMMANDS_CTRL_TIME_LO = 222, 
  parameter SR_FIR_COMMANDS_CTRL_CLEAR_CMDS = 223, 
  parameter SR_FIR_BRAM_WRITE_TAPS = 224
  )(
  
  //basic settings reg configuration inputs
  input clk, input rst, input clear, 
  output reg [1:0] error_stb,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  
  
  output [NUM_CHANNELS*NUM_BEAMS*8-1:0] m_axis_config_tdata,
  output [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_config_tvalid,
  output [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_config_tlast,
  input [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_config_tready,
  
  output [NUM_CHANNELS*NUM_BEAMS*TAP_BITS-1:0] m_axis_reload_tdata,
  output [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tlast,
  output [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tvalid,
  input [NUM_CHANNELS*NUM_BEAMS-1:0] m_axis_reload_tready,

  input [63:0] vita_time,
  
  // ERROR packets
  output [31:0] error_tdata, output error_tlast, output error_tvalid, input error_tready, output [127:0] error_tuser  
);

  wire [22:0] command_i;
  wire [63:0] time_i;
  wire send_imm;
  wire [63:0] rcvtime;  
  wire store_command;
  
  wire [21:0] m_axis_reload_command_tdata;
  wire m_axis_reload_command_tvalid;
  wire m_axis_reload_command_tready;
  
  wire now, early, late, too_early;
  wire loading;
  
  reg [2:0] loader_state;
  
  reg command_ready;
  reg [21:0] m_axis_reload_command_tdata_sav;
  reg m_axis_reload_command_tvalid_sav;
  
  reg [31:0] error_reg_tdata, error;
  reg error_reg_tlast, error_reg_tvalid;
  wire error_reg_tready;
  reg [127:0] error_reg_tuser;
  wire [127:0] error_header;
  wire [31:0] resp_sid;

  wire [31:0] m_axis_bram_write_tap_tdata;
  wire m_axis_bram_write_tap_tvalid;
  wire m_axis_bram_write_tap_tready;  
  
  wire [7:0] demux_reload_dest;
  wire [3:0] demux_reload_channel;
  wire [3:0] demux_reload_beam;
  wire [13:0] bram_write_addr;
  wire [13:0] bram_read_addr; //13 bits. 10 bits for delay index, 4 bits for tap index
  wire [TAP_BITS-1:0] delay_tap_data_in;
  wire [TAP_BITS*NUM_TAPS-1:0] delay_tap_data_out;
  wire [TAP_BITS*(16-NUM_TAPS)-1:0] delay_tap_zeros_out;
  wire bram_ena;
  wire bram_wea;
  wire bram_enb;
  wire bram_enb_delay;
  
  reg [3:0] bram_enb_shift_reg; //delay the next step by some clock cycles so the bram contents are loaded.

  wire [NUM_TAPS-1:0] axi_mux_i_tlast;
  wire [NUM_TAPS-1:0] axi_mux_i_tready;
  wire [NUM_TAPS-1:0] axi_mux_i_tvalid;
  
  wire [TAP_BITS-1:0] axi_mux_o_tdata;
  wire axi_mux_o_tlast;
  wire axi_mux_o_tready;
  wire axi_mux_o_tvalid;

  wire [TAP_BITS*NUM_BEAMS-1:0] axi_demux_beams_o_tdata;
  wire [NUM_BEAMS-1:0] axi_demux_beams_o_tlast;
  wire [NUM_BEAMS-1:0] axi_demux_beams_o_tready;
  wire [NUM_BEAMS-1:0] axi_demux_beams_o_tvalid;
 
  
  reg [3:0] config_valid_shift_reg;
  wire finished;
  
  wire [7:0] m_axis_config_command_tdata;
  wire        m_axis_config_command_tvalid;
  wire        m_axis_config_command_tlast;
  wire        m_axis_config_command_tready;
  wire [7:0] demux_config_dest;
  
  //////
  // FIR FILTER AXIS RELOAD w/ delay tap bram logic
  //
  //////
  //"commands" are [8 bit FIR FIlter index] + [14 bit tap bram address], 
  //taps are in sets of 8 (8 taps per delay setting). so of the 14 bits of tap bram address, 
  //when reading a set of taps, address must read 14'bXX XXXX XXXX 0000. Bottom 4 bits must be 0 since taps are in sets of 16.
  //only 10 tags in each group of 16 are valid tap values. this is because 
  setting_reg #( .my_addr(SR_FIR_COMMANDS_RELOAD), .width(23)) //fifo size can hold all tap commands
  set_reload (
    .clk(clk), .rst(rst), .strobe(set_stb), .addr(set_addr), 
    .in(set_data), .out(command_i), .changed(store_command));

  setting_reg #(.my_addr(SR_FIR_COMMANDS_CTRL_TIME_HI)) sr_time_h (
    .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[63:32]),.changed());

  setting_reg #(.my_addr(SR_FIR_COMMANDS_CTRL_TIME_LO) ) sr_time_l (
    .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[31:0]),.changed());

  setting_reg #(.my_addr(SR_FIR_COMMANDS_CTRL_CLEAR_CMDS)) sr_clear_cmds (
    .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(),.changed(clear_cmds));

  axi_fifo #(.WIDTH(23+64), .SIZE(8) ) fir_ctrl_command_fifo ( //increase this size to at least 160 (number of FIR filters)
    .clk(clk), .reset(rst), .clear(clear | clear_cmds),
    .i_tdata({command_i,time_i}), .i_tvalid(store_command), .i_tready(),
    .o_tdata({send_imm, m_axis_reload_command_tdata, rcvtime}),
    .o_tvalid(m_axis_reload_command_tvalid), .o_tready(command_ready),
    .occupied(), .space());

  time_compare time_compare (
    .clk(clk), .reset(rst),
    .time_now(vita_time), .trigger_time(rcvtime), .now(now), .early(early), .late(late), .too_early(too_early));
  
    
    // State machine states
    localparam STATE_IDLE                = 0;
    localparam STATE_LOAD_TAPS           = 1;
    localparam STATE_READY_NEXT          = 2;
    localparam STATE_ERR_WAIT_FOR_READY  = 3;
    localparam STATE_ERR_SEND_PKT        = 4;
  
    // Error codes
    localparam ERR_OVERRUN      = 32'd8;
    localparam ERR_BROKENCHAIN  = 32'd4;
    localparam ERR_LATECMD      = 32'd2;
  
    always @(posedge clk) begin
    if (rst | clear) begin
      //reset things
      m_axis_reload_command_tdata_sav <= 22'b0;
      m_axis_reload_command_tvalid_sav <= 1'b0;
      command_ready <= 1'b0;
      loader_state      <= STATE_IDLE;
    end else begin
      case (loader_state)
        STATE_IDLE : begin
          command_ready  <= 1'b0;
          if (m_axis_reload_command_tvalid) begin
            // There is a valid command to pop from FIFO
            if (late & ~send_imm) begin
              // Got this command later than its execution time.
              command_ready <= 1'b1;
              error         <= ERR_LATECMD;
              loader_state     <= STATE_ERR_WAIT_FOR_READY;
            end else if (now | send_imm) begin
              // Either its time to run this command or it should run immediately without a time.
              command_ready  <= 1'b0;
              m_axis_reload_command_tdata_sav <= m_axis_reload_command_tdata;
              m_axis_reload_command_tvalid_sav <= m_axis_reload_command_tvalid;
              loader_state      <= STATE_LOAD_TAPS;
            end
          end
        end

        STATE_LOAD_TAPS : begin
          command_ready <= 1'b0;
          if (finished) begin
            command_ready <= 1'b1;
            loader_state = STATE_READY_NEXT;
          end  
        end
        
        //bubble state to let AXI control signals transition. Might be a way to merge this state into IDLE if I'm clever.
        STATE_READY_NEXT : begin
          if(m_axis_reload_command_tvalid) begin
            command_ready <= 1'b0;
            loader_state = STATE_IDLE;
          end  
        end
        
        // Wait for output to be ready
        STATE_ERR_WAIT_FOR_READY : begin
          command_ready  <= 1'b0;
          if (error_reg_tready) begin
            error_reg_tvalid <= 1'b1;
            error_reg_tlast  <= 1'b0;
            error_reg_tdata  <= error;
            error_reg_tuser  <= error_header;
            loader_state     <= STATE_ERR_SEND_PKT;
          end
        end
        
        STATE_ERR_SEND_PKT : begin
          command_ready <= 1'b0;
          if (error_reg_tready) begin
            error_reg_tvalid <= 1'b1;
            error_reg_tlast  <= 1'b1;
            error_reg_tdata  <= 'd0;
            if (error_reg_tlast) begin
              error_reg_tvalid <= 1'b0;
              error_reg_tlast  <= 1'b0;
              loader_state     <= STATE_IDLE;
            end
          end
        end

        default : loader_state <= STATE_IDLE;
      endcase
    end
  end

  assign loading = (loader_state == STATE_LOAD_TAPS);
  assign resp_sid = 8'h12345678;
  assign error_header = {2'b11, 1'b1,           1'b1, 12'b0,                  16'h24, resp_sid,  vita_time};


  // Register ERROR output stream. Not sure yet where this will go if anywhere at all.
  axi_fifo_flop2 #(.WIDTH(161))
  axi_fifo_flop2 (
    .clk(clk), .reset(rst), .clear(clear),
    .i_tdata({error_reg_tlast, error_reg_tdata, error_reg_tuser}), .i_tvalid(error_reg_tvalid), .i_tready(error_reg_tready),
    .o_tdata({error_tlast, error_tdata, error_tuser}), .o_tvalid(error_tvalid), .o_tready(error_tready),
    .space(), .occupied());

  
  //Writing BRAM taps does not require time.
  //"commands" are [18 bit TAP value] + [14 bit tap bram address], 
  //taps are in sets of 10 (10 taps per delay setting). so of the 14 bits of tap bram address, 
  //when writing a set of taps, address 10 taps at a time, read 14'bXX XXXX XXXX [0000-1001]. Bottom 3 bits 0-9 since taps are in sets of 10.
  axi_setting_reg #(
    .ADDR(SR_FIR_BRAM_WRITE_TAPS),
    .USE_ADDR_LAST(0),
    .WIDTH(32),
    .USE_FIFO(1),
    .FIFO_SIZE(5))
  set_bram_taps (
    .clk(clk),
    .reset(rst),
    .set_stb(set_stb),
    .set_addr(set_addr),
    .set_data(set_data),
    .o_tdata(m_axis_bram_write_tap_tdata),
    .o_tlast(),
    .o_tvalid(m_axis_bram_write_tap_tvalid),
    .o_tready(m_axis_bram_write_tap_tready)); //requires some sort of special logic for knowing when we are ready for the next command

  assign delay_tap_data_in = m_axis_bram_write_tap_tdata[31:14];
  assign bram_write_addr = m_axis_bram_write_tap_tdata[13:0];
  assign m_axis_bram_write_tap_tready = 1'b1;

  //enable the bram ports
  assign bram_ena = 1'b1;
  assign bram_wea = m_axis_bram_write_tap_tvalid;
  assign bram_enb = loading;
  
  //Write TAPS with PORT A, Read TAPS with PORT B
  delay_tap_bram delay_tap_bram_out (
    .clka(clk),    // input wire clka
    .ena(bram_ena),      // input wire ena
    .wea(bram_wea),      // input wire [0 : 0] wea
    .addra(bram_write_addr),  // input wire [13 : 0] addra
    .dina(delay_tap_data_in),    // input wire [18 : 0] dina
    .clkb(clk),    // input wire clkb
    .enb(bram_enb),      // input wire enb
    .addrb(bram_read_addr[13:4]),  // input wire [9 : 0] addrb
    .doutb({delay_tap_zeros_out, delay_tap_data_out})  // output wire [287 : 0] douta 16 x 18 = 288, but we're only using 180 bits.
  );
  
  //////
  // FIR FILTER AXIS RELOAD
  // LOAD TAPS FROM BRAM USING DATA FROM RELOAD COMMAND.
  //////

  assign demux_reload_dest = m_axis_reload_command_tdata[21:14];
  assign demux_reload_channel = demux_reload_dest[3:0];
  assign demux_reload_beam = demux_reload_dest[7:4];
  assign bram_read_addr = m_axis_reload_command_tdata[13:0];

  always @ (posedge clk) begin
    bram_enb_shift_reg <= {bram_enb_shift_reg[2:0], bram_enb};
  end
  
  assign bram_enb_delay = bram_enb_shift_reg[3];
  assign axi_mux_i_tvalid = {NUM_TAPS{bram_enb_delay}};
  assign axi_mux_i_tlast = {bram_enb_delay, 9'h0}; //9 = NUM_TAPS-1
  
  //delay tap mux with counter. the axi_mux module actually does round robin by default so thats cool.
  axi_mux #(.PRIO(0), .WIDTH(TAP_BITS), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0), .SIZE(NUM_TAPS)) axi_mux_reload (
    .clk(clk), .reset(rst | ~bram_enb_delay), .clear(1'b0),
    .i_tdata(delay_tap_data_out), .i_tlast(axi_mux_i_tlast | 1'b1 /* mux on each sample */),
    .i_tvalid(axi_mux_i_tvalid), .i_tready(axi_mux_i_tready),
    .o_tdata(axi_mux_o_tdata), .o_tlast(axi_mux_o_tlast), .o_tvalid(axi_mux_o_tvalid), .o_tready(axi_mux_o_tready));

  //2 layers of demux to lessen the fanout
  axi_demux #(.WIDTH(TAP_BITS), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(1), .SIZE(NUM_BEAMS)) axi_demux_beams (
    .clk(clk), .reset(rst | ~bram_enb_delay), .clear(1'b0),
    .header(), .dest(demux_reload_beam),
    .i_tdata(axi_mux_o_tdata), .i_tlast(axi_mux_o_tlast), .i_tvalid(axi_mux_o_tvalid), .i_tready(axi_mux_o_tready),
    .o_tdata(axi_demux_beams_o_tdata), .o_tlast(axi_demux_beams_o_tlast), .o_tvalid(axi_demux_beams_o_tvalid), .o_tready(axi_demux_beams_o_tready));

  genvar j;
  generate
  for (j = 0; j < NUM_BEAMS; j = j + 1) begin : gen_demux_per_beam
    axi_demux #(.WIDTH(TAP_BITS), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(1), .SIZE(NUM_CHANNELS)) axi_demux_channels (
        .clk(clk), .reset(rst | ~bram_enb_delay), .clear(1'b0),
        .header(), .dest(demux_reload_channel),
        .i_tdata(axi_demux_beams_o_tdata[TAP_BITS*j+TAP_BITS-1:TAP_BITS*j]), .i_tlast(axi_demux_beams_o_tlast[j]), 
        .i_tvalid(axi_demux_beams_o_tvalid[j]), .i_tready(axi_demux_beams_o_tready[j]),
        .o_tdata(m_axis_reload_tdata[NUM_CHANNELS*TAP_BITS*j+NUM_CHANNELS*TAP_BITS-1:NUM_CHANNELS*TAP_BITS*j]),
        .o_tlast(m_axis_reload_tlast[NUM_CHANNELS*j+NUM_CHANNELS-1:NUM_CHANNELS*j]),
        .o_tvalid(m_axis_reload_tvalid[NUM_CHANNELS*j+NUM_CHANNELS-1:NUM_CHANNELS*j]),
        .o_tready(m_axis_reload_tready[NUM_CHANNELS*j+NUM_CHANNELS-1:NUM_CHANNELS*j]));
  end
  endgenerate

  //debug wire
  wire [TAP_BITS-1:0] m_axis_reload_tdata0;
  wire m_axis_reload_tlast0;
  wire m_axis_reload_tvalid0;
  wire m_axis_reload_tready0;
  assign m_axis_reload_tdata0 = m_axis_reload_tdata[17:0];
  assign m_axis_reload_tlast0 = m_axis_reload_tlast[0];
  assign m_axis_reload_tvalid0 = m_axis_reload_tvalid[0];  
  assign m_axis_reload_tready0 = m_axis_reload_tready[0];  

  //////
  // FIR FILTER AXIS CONFIG
  // Do this after the taps have been loaded from bram
  //////
  
  //needs a delay to process the config command (to load the reload taps)
  always @ (posedge clk) begin
      config_valid_shift_reg <= {config_valid_shift_reg[2:0], axi_mux_i_tready[7]}; //when the last tap is loaded
  end
  
  assign demux_config_dest = m_axis_reload_command_tdata[20:13];
  assign m_axis_config_command_tdata = 8'b0;
  //when the last tap has been loaded to the 
  assign m_axis_config_command_tvalid = config_valid_shift_reg[2];
  assign finished = config_valid_shift_reg[3];
  


  axi_demux #(.WIDTH(8), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0), .SIZE(NUM_CHANNELS*NUM_BEAMS)) axi_demux_config (
    .clk(clk), .reset(rst), .clear(1'b0),
    .header(), .dest(demux_config_dest),
    .i_tdata(m_axis_config_command_tdata), .i_tlast(m_axis_config_command_tvalid), .i_tvalid(m_axis_config_command_tvalid), .i_tready(m_axis_config_command_tready),
    .o_tdata(m_axis_config_tdata), .o_tlast(m_axis_config_tlast), .o_tvalid(m_axis_config_tvalid), .o_tready(m_axis_config_tready));
    
  //debug wire
  wire [7:0] m_axis_config_tdata0;
  wire m_axis_config_tlast0;
  wire m_axis_config_tvalid0;
  wire m_axis_config_tready0;
  assign m_axis_config_tdata0 = m_axis_config_tdata[7:0];
  assign m_axis_config_tlast0 = m_axis_config_tdata[0];
  assign m_axis_config_tvalid0 = m_axis_config_tvalid[0];
  assign m_axis_config_tready0 =  m_axis_config_tready[0];

endmodule
