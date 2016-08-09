//
// Copyright 2014 Ettus Research LLC
//

module periodic_framer
  #(parameter BASE=0,
    parameter WIDTH=32)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [WIDTH-1:0] stream_i_tdata, input stream_i_tlast, input stream_i_tvalid, output stream_i_tready,
    input [31:0] trigger_tdata, input trigger_tlast, input trigger_tvalid, output trigger_tready,
    output [WIDTH-1:0] stream_o_tdata, output stream_o_tlast, output stream_o_tvalid, input stream_o_tready,
    output eob);

   wire [15:0] 	       frame_len;
   wire [15:0] 	       gap_len;
   wire [15:0] 	       offset;
   
   wire [15:0] 	       numsymbols_max, numsymbols_thisburst, numsymbols_short;
   wire [15:0] 	       burst_len;
   wire 	       set_numsymbols;

   setting_reg #(.my_addr(BASE), .width(16)) reg_frame_len
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(frame_len), .changed());

   setting_reg #(.my_addr(BASE+1), .width(16)) reg_gap_len
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(gap_len), .changed());

   setting_reg #(.my_addr(BASE+2), .width(16)) reg_offset
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(offset), .changed());

   setting_reg #(.my_addr(BASE+3), .width(16)) reg_max_symbols
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(numsymbols_max), .changed());

   setting_reg #(.my_addr(BASE+4), .width(16)) reg_symbols_short
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(numsymbols_short), .changed(set_numsymbols));

   localparam ST_WAIT_FOR_TRIG = 2'd0;
   localparam ST_DO_OFFSET = 2'd1;
   localparam ST_FRAME = 2'd2;
   localparam ST_GAP = 2'd3;

   reg [1:0] 	       state;
   reg [15:0] 	       counter;
   reg 		       first_symbol;
   reg [15:0] 	       numsymbols;
   
   wire 	       consume;
   
   reg 	      shorten_burst;
   always @(posedge clk)
     if(reset | clear)
       shorten_burst <= 1'b0;
     else if(set_numsymbols)
       shorten_burst <= 1'b1;
     else if(state == ST_WAIT_FOR_TRIG)
       shorten_burst <= 1'b0;

   assign numsymbols_thisburst = shorten_burst ? numsymbols_short : numsymbols_max;

   always @(posedge clk)
     if(reset | clear)
       state <= ST_WAIT_FOR_TRIG;
     else
       if(consume)
	 case(state)
	   ST_WAIT_FOR_TRIG :
	     if(trigger_tlast)
	       begin
		  state <= ST_DO_OFFSET;
		  counter <= 16'b1;
	       end
	   ST_DO_OFFSET :
	     if(counter >= offset)
	       begin
		  state <= ST_FRAME;
		  counter <= 16'b1;
		  first_symbol <= 1'b1;
		  numsymbols <= 16'd1;
	       end
	     else
	       counter <= counter + 16'd1;
	   ST_FRAME :
	     if(counter >= frame_len)
	       begin
		  first_symbol <= 1'b0;
		  if(~first_symbol)   // 802.11 does not have a CP between two LTFs
		    if(numsymbols >= numsymbols_thisburst)
		      state <= ST_WAIT_FOR_TRIG;
		    else
		      state <= ST_GAP;
		  counter <= 1;
		  numsymbols <= numsymbols + 1;
	       end
	     else
	       counter <= counter + 16'd1;
	   ST_GAP :
	     if(counter >= gap_len)
	       begin
		  state <= ST_FRAME;
		  counter <= 1;
	       end
	     else
	       counter <= counter + 16'd1;
	 endcase // case (state)

   assign stream_o_tdata = stream_i_tdata;
   assign stream_o_tlast = (state == ST_FRAME) & (counter >= frame_len);
   assign stream_o_tvalid = stream_i_tvalid & trigger_tvalid & (state == ST_FRAME);

   assign stream_i_tready = consume;
   assign trigger_tready = consume;
   assign consume = stream_i_tvalid & trigger_tvalid & ((state != ST_FRAME) | stream_o_tready);

   assign eob = (numsymbols >=  numsymbols_thisburst);
      
endmodule // periodic_framer
