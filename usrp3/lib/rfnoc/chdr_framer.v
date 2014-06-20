
module chdr_framer
  #(parameter SIZE=10)
   (input clk, input reset, input clear,
    input send_time, input [63:0] vita_time, input [31:0] sid, input eob, // only valid on i_tlast
    input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   localparam HDR_WIDTH = 64+32+16+1+1;
   
   wire [HDR_WIDTH-1:0] header_i_tdata;
   wire 		header_i_tvalid, header_i_tready;
   wire [63:0] 		body_i_tdata;
   wire 		body_i_tlast, body_i_tvalid, body_i_tready;

   wire [HDR_WIDTH-1:0] header_o_tdata;
   wire 		header_o_tvalid, header_o_tready;
   wire [63:0] 		body_o_tdata;
   wire 		body_o_tlast, body_o_tvalid, body_o_tready;
   reg 			even;
   reg [15:0] 		length;
   reg [11:0] 		seqnum;
   reg [31:0] 		held_i_tdata;

   always @(posedge clk)
     if(i_tvalid & i_tready)
       held_i_tdata <= i_tdata;
   
   assign i_tready = header_i_tready & body_i_tready;
   assign header_i_tvalid = i_tlast & i_tvalid & i_tready;
   assign body_i_tvalid = i_tvalid & i_tready & (i_tlast | even);
   assign body_i_tdata = even ? { held_i_tdata, i_tdata } : {i_tdata, i_tdata}; // really should be 0 in bottom, but this simplifies mux
   assign body_i_tlast = i_tlast;
   assign header_i_tdata = { send_time, eob, length, sid, vita_time };  // sid could be considered constant and taken out of the fifo?
   
   always @(posedge clk)
     if(reset | clear)
       even <= 0;
     else 
       if(i_tvalid & i_tready)
	 if(i_tlast)
	   even <= 0;
	 else
	   even <= ~even;

   // FIXME handle lengths of partial 32-bit words
   always @(posedge clk)
     if(reset | clear)
       length <= 0;
     else if(header_i_tready & header_i_tvalid)
       length <= 0;
     else if(i_tvalid & i_tready)
       length <= length + 4;
   
   axi_fifo_short #(.WIDTH(HDR_WIDTH)) header_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(header_i_tdata), .i_tvalid(header_i_tvalid), .i_tready(header_i_tready),
      .o_tdata(header_o_tdata), .o_tvalid(header_o_tvalid), .o_tready(header_o_tready));

   axi_fifo #(.WIDTH(65), .SIZE(SIZE)) body_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({body_i_tlast,body_i_tdata}), .i_tvalid(body_i_tvalid), .i_tready(body_i_tready),
      .o_tdata({body_o_tlast,body_o_tdata}), .o_tvalid(body_o_tvalid), .o_tready(body_o_tready));
     
   reg [3:0] 	  chdr_state;
   localparam ST_IDLE = 0;
   localparam ST_HEAD = 1;
   localparam ST_TIME = 2;
   localparam ST_BODY = 3;

   // FIXME need a what 
   always @(posedge clk)
     if(reset)
       chdr_state <= ST_IDLE;
     else
       case(chdr_state)
	 ST_IDLE :
	   if(header_o_tvalid & body_o_tvalid)
	     chdr_state <= ST_HEAD;
	 ST_HEAD :
	   if(o_tready)
	     if(header_o_tdata[HDR_WIDTH-1])   // time
	       chdr_state <= ST_TIME;
	     else
	       chdr_state <= ST_BODY;
	 ST_TIME :
	   if(o_tready)
	     chdr_state <= ST_BODY;
	 ST_BODY :
	   if(o_tready & body_o_tlast)
	     chdr_state <= ST_IDLE;
       endcase // case (chdr_state)

   always @(posedge clk)
     if(reset | clear)
       seqnum <= 12'd0;
     else
       if(o_tvalid & o_tready & o_tlast)
	 seqnum <= seqnum + 12'd1;
   
   wire [15:0] 	  out_length = header_o_tdata[111:96] + (header_o_tdata[113] ? 16'd20 : 16'd12);
   
   assign o_tvalid = (chdr_state == ST_HEAD) | (chdr_state == ST_TIME) | (body_o_tvalid & (chdr_state == ST_BODY));
   assign o_tlast = (chdr_state == ST_BODY) & body_o_tlast;
   assign o_tdata = (chdr_state == ST_HEAD) ? {2'b00, header_o_tdata[113:112], seqnum, out_length, header_o_tdata[95:64] } :
		    (chdr_state == ST_TIME) ? header_o_tdata[63:0] :
		    body_o_tdata;
   assign body_o_tready = (chdr_state == ST_BODY) & o_tready;
   assign header_o_tready = ((chdr_state == ST_TIME) | ((chdr_state == ST_HEAD) & ~header_o_tdata[HDR_WIDTH-1])) & o_tready;
   	 
endmodule // chdr_framer
