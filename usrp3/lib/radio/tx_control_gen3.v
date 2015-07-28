//
// Copyright 2014 Ettus Research LLC
//

module tx_control_gen3
  #(parameter SR_ERROR_POLICY=0)
   (input clk, input rst, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,

    input [63:0] vita_time,
    input [31:0] tx_tdata,
    input [127:0] tx_tuser,
    input tx_tlast,
    input tx_tvalid,
    output tx_tready,

    output reg error,
    output [11:0] seqnum,
    output reg [63:0] error_code,

    // To DSP Core
    output run, output [31:0] sample,
    input strobe
    );

   wire [63:0] 	  send_time = tx_tuser[63:0];
   assign 	  seqnum = tx_tuser[123:112];
   wire 	  eob = tx_tuser[124];
   wire 	  send_at = tx_tuser[125];

   wire 	  now, early, late, too_early;
   wire 	  policy_next_burst, policy_next_packet, policy_wait;
   wire 	  clear_seqnum;

   setting_reg #(.my_addr(SR_ERROR_POLICY), .width(3)) sr_error_policy
     (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out({policy_next_burst,policy_next_packet,policy_wait}),.changed(clear_seqnum));

   time_compare
     time_compare (.clk(clk), .reset(rst), .time_now(vita_time), .trigger_time(send_time),
		   .now(now), .early(early), .late(late), .too_early(too_early));

   reg [2:0]     state;

   localparam ST_IDLE  = 0;
   localparam ST_SAMP  = 1;
   localparam ST_ERROR = 2;
   localparam ST_WAIT  = 3;

   assign run = (state == ST_SAMP);

   reg [11:0]  expected_seqnum;

   wire [63:0] CODE_EOB_ACK            = {32'd1,20'd0,seqnum};
   wire [63:0] CODE_UNDERRUN           = {32'd2,20'd0,seqnum};
   wire [63:0] CODE_SEQ_ERROR          = {32'd4,4'd0,expected_seqnum,4'd0,seqnum};
   wire [63:0] CODE_TIME_ERROR         = {32'd8,20'd0,seqnum};
   //wire [63:0] CODE_UNDERRUN_MIDPKT    = {32'd16,20'd0,seqnum};
   wire [63:0] CODE_SEQ_ERROR_MIDBURST = {32'd32,4'd0,expected_seqnum,4'd0,seqnum};

   // FIXME should move seqnum error detection to noc_shell
   always @(posedge clk)
     if(rst | clear | clear_seqnum)
       expected_seqnum <= 12'd0;
     else
       if(tx_tvalid & tx_tready & tx_tlast)
	 expected_seqnum <= seqnum + 12'd1;

   always @(posedge clk)
     if(rst | clear)
       begin
	  state <= ST_IDLE;
	  error <= 1'b0;
	  error_code <= 64'd0;
       end
     else
       case(state)
	 ST_IDLE :
	   begin
	      error <= 1'b0;
	      if(tx_tvalid)
		if(expected_seqnum != seqnum)
		  begin
		     state <= ST_ERROR;
		     error <= 1'b1;
		     error_code <= CODE_SEQ_ERROR;
		  end
		else if(~send_at | now)
		  state <= ST_SAMP;
		else if(late)
		  begin
		     state <= ST_ERROR;
		     error <= 1'b1;
		     error_code <= CODE_TIME_ERROR;
		  end
	   end // case: ST_IDLE
	 ST_SAMP :
	   if(strobe)
	     if(~tx_tvalid)
	       begin
		  state <= ST_ERROR;
		  error <= 1'b1;
		  error_code <= CODE_UNDERRUN;
	       end
	     else if(expected_seqnum != seqnum)
	       begin
		  state <= ST_ERROR;
		  error <= 1'b1;
		  error_code <= CODE_SEQ_ERROR_MIDBURST;
	       end
	     else if(tx_tlast & eob)
	       begin
		  state <= ST_IDLE;
		  error <= 1'b1;
		  error_code <= CODE_EOB_ACK;
	       end
	 ST_ERROR :
	   begin
	      error <= 1'b0;
	      if(tx_tvalid & tx_tlast)
		if(policy_next_packet | (policy_next_burst & eob))
		  state <= ST_IDLE;
		else if(policy_wait)
		  state <= ST_WAIT;
	   end
       endcase // case (state)

   assign tx_tready = (state == ST_ERROR) | (strobe & (state == ST_SAMP));
   assign sample = tx_tdata;
   
endmodule // tx_control_gen3
