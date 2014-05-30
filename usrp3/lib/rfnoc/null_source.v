
// Copyright 2014, Ettus Research

// Dummy data source.  Turn it on by setting a packet length in its setting reg, turn it off by setting 0.  
// Will generate as fast as it can.

module null_source
  #(parameter BASE=0)
   (input clk, input reset,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [31:0] 	  sid;
   reg [11:0] 	  seqnum;
   wire [15:0] 	  rate;
   reg [1:0] 	  state;
   reg [15:0] 	  line_number;
   
   wire [63:0] 	  int_tdata;
   wire 	  int_tlast, int_tvalid, int_tready;

   wire [15:0] 	  len;
   reg [15:0] 	  count;
   reg [15:0] 	  packet_count;
   wire 	  changed_sid;
   wire 	  enable;
   
   setting_reg #(.my_addr(BASE), .width(32)) sid_reg
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sid), .changed(changed_sid));
   
   setting_reg #(.my_addr(BASE+1), .width(16)) len_reg
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(len), .changed());
		 
   setting_reg #(.my_addr(BASE+2), .width(16)) rate_reg
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rate), .changed());

   setting_reg #(.my_addr(BASE+3), .width(1)) enable_reg
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(enable), .changed());

   localparam IDLE = 2'd0;
   localparam HEAD = 2'd1;
   localparam DATA = 2'd2;

   always @(posedge clk)
     if(reset)
       begin
	  state <= IDLE;
	  count <= 0;
       end
     else
       begin
	  if(changed_sid)
	    seqnum <= 0;
	  case(state)
	    IDLE :
	      if(enable)
		state <= HEAD;
	    HEAD :
	      if(int_tvalid & int_tready)
		begin
		   count <= 1;
		   state <= DATA;
		   seqnum <= seqnum + 1;
		end
	    DATA :
	      if(int_tvalid & int_tready)
		if(count >= len)
		  begin
		     state <= IDLE;
		     count <= 0;
		  end
		else
		  count <= count + 1;
	    default :
	      state <= IDLE;
	  endcase // case (state)
       end // else: !if(reset)
   
   
   wire [15:0] pkt_len = { len[12:0], 3'b000 } + 16'd8;
   
   assign int_tdata = (state == HEAD) ? { 4'b0000, seqnum, pkt_len, sid } : {~count,count,count,count} ;
   assign int_tlast = (count >= len);

   reg [15:0]  line_timer;
   always @(posedge clk)
     if(reset)
       line_timer <= 0;
     else
       if(line_timer == 0)
	 line_timer <= rate;
       else
	 line_timer <= line_timer - 1;
   
   assign int_tvalid = ((state==HEAD)|(state==DATA)) & (line_timer==0);
   
   axi_packet_gate #(.WIDTH(64), .SIZE(10)) gate
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(int_tdata), .i_tlast(int_tlast), .i_terror(1'b0), .i_tvalid(int_tvalid), .i_tready(int_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));
   
endmodule // null_source
