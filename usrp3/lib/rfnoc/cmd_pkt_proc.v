//
// Copyright 2014 Ettus Research LLC
//

// Command Packet Processor
//  Accepts compressed vita extension context packets of the following form:
//       { VITA Compressed Header, Stream ID }
//       { Optional 64 bit time }
//       { 16'h0, setting bus address [15:0], setting [31:0] }
//
//  If there is a timestamp, packet is held until that time comes.
//  Goes immediately if there is no timestamp or if time has passed.
//  Sends out setting to setting bus, and then generates a response packet
//  with the same sequence number, the src/dest swapped streamid, and the actual time
//  the setting was sent.
//
// Note -- if t0 is the requested time, the actual send time on the setting bus is t0 + 1 cycle.
// Note 2 -- if t1 is the actual time the setting bus, t1+2 is the reported time.

module cmd_pkt_proc #(
   parameter NUM_SR_BUSES = 1)
  (input clk, input reset, input clear,

   input [63:0] cmd_tdata, input cmd_tlast, input cmd_tvalid, output reg cmd_tready,
   output reg [63:0] resp_tdata, output reg resp_tlast, output resp_tvalid, input resp_tready,

   input [63:0] vita_time,

   output [NUM_SR_BUSES-1:0] set_stb, output [7:0] set_addr, output [31:0] set_data, output reg [63:0] set_time,
   input ready,

   input [NUM_SR_BUSES*64-1:0] readback);

   localparam RC_HEAD   = 4'd0;
   localparam RC_TIME   = 4'd1;
   localparam RC_DATA   = 4'd2;
   localparam RC_DUMP   = 4'd3;
   localparam RC_RESP_WAIT = 4'd4;
   localparam RC_RESP_HEAD = 4'd5;
   localparam RC_RESP_TIME = 4'd6;
   localparam RC_RESP_DATA = 4'd7;

   wire 	 IS_EC = cmd_tdata[63:62] == 2'b10;
   wire 	 HAS_TIME = cmd_tdata[61];
   reg 		 HAS_TIME_reg;

   reg [3:0] 	 rc_state;

   reg [11:0] seqnum_reg;
   reg [31:0] sid_reg;
   reg [15:0] src_sid_reg, dst_sid_reg;
   reg [3:0] block_port_reg;
   wire [11:0] seqnum    = cmd_tdata[59:48];
   wire [31:0] sid       = cmd_tdata[31:0];
   wire [15:0] src_sid   = sid[31:16];
   wire [15:0] dst_sid   = sid[15:0];
   wire [3:0] block_port = sid[3:0];
   reg [NUM_SR_BUSES-1:0] block_port_stb;
   integer k;

   always @(posedge clk)
     if(reset)
       begin
	  rc_state <= RC_HEAD;
	  HAS_TIME_reg <= 1'b0;
	  sid_reg <= 'd0;
	  seqnum_reg <= 'd0;
	  set_time <= 'd0;
	  src_sid_reg <= 'd0;
	  dst_sid_reg <= 'd0;
	  block_port_reg <= 'd0;
	  block_port_stb <= 'd0;
       end
     else
	 case(rc_state)
	   RC_HEAD :
	     if(cmd_tvalid)
	       begin
		  src_sid_reg <= src_sid;
		  dst_sid_reg <= dst_sid;
		  block_port_reg <= block_port;
		  // Set strobe for addressed block port's settings register bus
		  for (k = 0; k < NUM_SR_BUSES; k = k + 1) begin
		    if (block_port == k) begin
		      block_port_stb[k] <= 1'b1;
		    end else begin
		      block_port_stb[k] <= 1'b0;
		    end
		  end
		  seqnum_reg <= seqnum;
		  HAS_TIME_reg <= HAS_TIME;
		  if(IS_EC)
		    if(HAS_TIME) begin
		      rc_state <= RC_TIME;
		    end else begin
		      set_time <= 64'd0;
		      rc_state <= RC_DATA;
		    end
		  else
		    if(~cmd_tlast)
		      rc_state <= RC_DUMP;
	       end

	   RC_TIME :
	     if(cmd_tvalid) begin
	       set_time <= cmd_tdata;
	       if(cmd_tlast)
		 rc_state <= RC_RESP_WAIT;
	       else
		 rc_state <= RC_DATA;
		 end

	   RC_DATA :
	     if(cmd_tvalid)
	       if(ready)
		 if(cmd_tlast)
		   rc_state <= RC_RESP_WAIT;
		 else
		   rc_state <= RC_DUMP;

	   RC_DUMP :
	     if(cmd_tvalid)
	       if(cmd_tlast)
		 rc_state <= RC_RESP_WAIT;

	   // Wait a clock cycle to ensure readback
	   // has time to propagate
	   RC_RESP_WAIT :
	     rc_state <= RC_RESP_HEAD;

	   RC_RESP_HEAD :
	     if(resp_tready)
	       rc_state <= RC_RESP_TIME;

	   RC_RESP_TIME :
	     if(resp_tready)
	       rc_state <= RC_RESP_DATA;

	   RC_RESP_DATA:
	     if(resp_tready)
	       rc_state <= RC_HEAD;
	   
	   default :
	     rc_state <= RC_HEAD;
	 endcase // case (rc_state)

   always @*
     case (rc_state)
       RC_HEAD : cmd_tready <= 1'b1;
       RC_TIME : cmd_tready <= cmd_tlast;
       RC_DATA : cmd_tready <= ready;
       RC_DUMP : cmd_tready <= 1'b1;
       default : cmd_tready <= 1'b0;
     endcase // case (rc_state)

   reg [63:0] readback_reg;
   wire [63:0] readback_mux[0:NUM_SR_BUSES-1];
   always @(posedge clk) begin
     if (reset | clear) begin
       readback_reg   <= 64'd0;
     end else begin
       if (block_port_reg > NUM_SR_BUSES-1) begin
         readback_reg <= 64'd0;
       end else begin
         readback_reg <= readback_mux[block_port_reg];
       end
     end
   end

   genvar i;
   generate
     for (i = 0; i < NUM_SR_BUSES; i = i + 1) begin
       assign set_stb[i] = (rc_state == RC_DATA) & ready & cmd_tvalid & block_port_stb[i];
       assign readback_mux[i] = readback[64*i+63:64*i];
     end
   endgenerate

   assign set_addr = cmd_tdata[39:32];
   assign set_data = cmd_tdata[31:0];

   always @*
     case (rc_state)
       RC_RESP_HEAD : { resp_tlast, resp_tdata } <= {1'b0, 4'hE, seqnum_reg, 16'd24, dst_sid_reg, src_sid_reg};
       RC_RESP_TIME : { resp_tlast, resp_tdata } <= {1'b0, vita_time};
       RC_RESP_DATA : { resp_tlast, resp_tdata } <= {1'b1, readback_reg};
       default : { resp_tlast, resp_tdata } <= 65'h0;
     endcase // case (rc_state)

   assign resp_tvalid = (rc_state == RC_RESP_HEAD) | (rc_state == RC_RESP_TIME) | (rc_state == RC_RESP_DATA);
   
endmodule // radio_ctrl_proc

