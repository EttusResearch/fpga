
// Copyright 2014 Ettus Research

// Wrap basic AXIS-in, AXIS-out blocks, like Xilinx FIR, which produce one output for every input item
// Assumes 32-bit elements (like 16cs) carried over AXI

module simple_axi_wrapper
  #(parameter BASE=0)
   (input clk, input reset,

    // To NoC Shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output reg i_tready,
    output reg [63:0] o_tdata, output reg o_tlast, output reg o_tvalid, input o_tready,
    
    // To AXI IP
    output reg [31:0] m_axis_data_tdata, output reg m_axis_data_tlast, output reg m_axis_data_tvalid, input m_axis_data_tready,
    input [31:0] s_axis_data_tdata, input s_axis_data_tlast, input s_axis_data_tvalid, output reg s_axis_data_tready
    );

   // Paramters for both input and output state machines
   localparam ST_HEAD = 3'd0;
   localparam ST_TIME = 3'd1;
   localparam ST_ODD  = 3'd2;
   localparam ST_EVEN = 3'd3;
   localparam ST_DUMP = 3'd4;
   
   // Set next destination in chain
   wire [15:0] 	 next_destination;
   
   setting_reg #(.my_addr(BASE), .width(16)) new_destination
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(next_destination[15:0]));

   // FIFO to hold header while their data is in the AXI DSP unit
   // Only 32 packets can be in-flight due to length of header FIFO

   reg [127:0] 	 header_in;
   wire [127:0]  header_out;
   wire 	 header_in_tready, header_out_tvalid;
   reg 		 header_out_tready, header_in_tvalid;
   
   reg [63:0] 	 held_header;
   wire 	 write_header = ~i_tlast & i_tvalid & m_axis_data_tready & ( (n2a_state==ST_TIME) | ((n2a_state==ST_HEAD) & ~i_tdata[61]) );
   
   always @(posedge clk)
     if(n2a_state == ST_HEAD)
       held_header <= i_tdata;
   
   axi_fifo_short #(.WIDTH(128)) header_queue
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(header_in), .i_tvalid(header_in_tvalid), .i_tready(header_in_tready),
      .o_tdata(header_out), .o_tvalid(header_out_tvalid), .o_tready(header_out_tready),
      .space(), .occupied());
   
   // ////////////////////////
   // NoC to AXI IP

   reg [1:0] 	 n2a_state;
   reg 		 odd;
   wire 	 bad_packet = i_tdata[63:62] != 2'b00;
   
   always @(posedge clk)
     if(reset)
       n2a_state <= ST_HEAD;
     else
       case(n2a_state)
	 ST_HEAD :
	   if(i_tvalid & header_in_tready)
	     begin
		odd <= i_tdata[34] ^ (i_tdata[33] | i_tdata[32]);
		if(bad_packet & ~i_tlast)
		  n2a_state <= ST_DUMP;   // FIXME Or maybe we just pass them through?
		else
		  if(~i_tlast)
		    if(i_tdata[61])
		      n2a_state <= ST_TIME;
		    else
		      if(header_in_tready)
			n2a_state <= ST_ODD;
	     end // if (i_tvalid & header_in_tready)
	 
	   ST_TIME :
	     if(i_tvalid & header_in_tready)
	       if(i_tlast)
		 n2a_state <= ST_HEAD;
	       else
		 if(header_in_tready)
		   n2a_state <= ST_ODD;
	   
	   ST_ODD :
	     if(i_tvalid & m_axis_data_tready)
	       if(i_tlast & odd)
		 n2a_state <= ST_HEAD;
	       else
		 n2a_state <= ST_EVEN;
	   
	   ST_EVEN :
	     if(i_tvalid & m_axis_data_tready)
	       if(i_tlast)
		 n2a_state <= ST_HEAD;
	       else
		 n2a_state <= ST_ODD;
	   
	 endcase // case (n2a_state)

   always @*
     case(n2a_state)
       ST_HEAD : 
	 begin
	    i_tready <= header_in_tready;
	    header_in <= {i_tdata, i_tdata};  // simpler mux if we just repeat
	    header_in_tvalid <= i_tvalid & ~i_tdata[61] & ~bad_packet; // Don't write if time is coming next or this is a short packet
	    m_axis_data_tdata <= i_tdata[31:0]; // ignored
	    m_axis_data_tlast <= 1'b0;
	    m_axis_data_tvalid <= 1'b0;
	 end
       ST_TIME : 
	 begin
	    i_tready <= header_in_tready;
	    header_in <= {held_header, i_tdata};
	    header_in_tvalid <= i_tvalid & ~bad_packet; // Don't write if this is a short packet
	    m_axis_data_tdata <= i_tdata[31:0];  //ignored
	    m_axis_data_tlast <= 1'b0;
	    m_axis_data_tvalid <= 1'b0;
	 end
       ST_ODD : 
	 begin
	    i_tready <= m_axis_data_tready & i_tlast & odd;
	    header_in <= {i_tdata, i_tdata};  // ignored
	    header_in_tvalid <= 1'b0;
	    m_axis_data_tdata <= i_tdata[63:32];
	    m_axis_data_tlast <= i_tlast & odd;
	    m_axis_data_tvalid <= i_tvalid;
	 end
       ST_EVEN : 
	 begin
	    i_tready <= m_axis_data_tready;
	    header_in <= {i_tdata, i_tdata};  // ignored
	    header_in_tvalid <= 1'b0;
	    m_axis_data_tdata <= i_tdata[31:0];
	    m_axis_data_tlast <= i_tlast;
	    m_axis_data_tvalid <= i_tvalid;
	 end
       default : 
	 begin
	    i_tready <= 1'b0;
	    header_in <= {i_tdata, i_tdata};  // ignored
	    header_in_tvalid <= 1'b0;
	    m_axis_data_tdata <= i_tdata[31:0]; // ignored
	    m_axis_data_tlast <= 1'b0;
	    m_axis_data_tvalid <= 1'b0;
	 end


     endcase // case (n2a_state)

   // /////////////////////////////////////////////////////////////
   // AXI back to NoC

   reg [2:0] a2n_state;

   always @(posedge clk)
     if(reset)
       a2n_state <= ST_HEAD;
     else
       case(a2n_state)
	 ST_HEAD :
	   begin
	      if(o_tvalid & o_tready)
		if(header_out[125])
		  a2n_state <= ST_TIME;
		else
		  a2n_state <= ST_ODD;
	   end
	 ST_TIME :
	   if(o_tvalid & o_tready)
	     a2n_state <= ST_ODD;
	 ST_ODD :
	   if(o_tready)
	     if(o_tvalid & o_tlast)
	       a2n_state <= ST_HEAD;
	     else
	       if(s_axis_data_tvalid)
		 a2n_state <= ST_EVEN;
	 ST_EVEN :
	   if(o_tvalid & o_tready)
	     if(o_tlast)
	       a2n_state <= ST_HEAD;
	     else
	       a2n_state <= ST_ODD;
       endcase // case (a2n_state)

   reg [31:0] held_data;
   always @(posedge clk)
     if(a2n_state == ST_ODD)
       held_data <= s_axis_data_tdata;
   
   always @*
     begin
	case(a2n_state)
	  ST_HEAD :
	    begin
	       o_tdata <= { header_out[127:96], header_out[79:64], next_destination };
	       o_tlast <= 1'b0;
	       o_tvalid <= header_out_tvalid;
	       s_axis_data_tready <= 1'b0;
	       header_out_tready <= ~header_out[125] & o_tready;
	    end
	  ST_TIME :
	    begin
	       o_tdata <= header_out[63:0];
	       o_tlast <= 1'b0;
	       o_tvalid <= header_out_tvalid;
	       s_axis_data_tready <= 1'b0;
	       header_out_tready <= o_tready;
	    end
	  ST_ODD :
	    begin
	       o_tdata <= { s_axis_data_tdata, s_axis_data_tdata };  // 2nd half replicated, but doesn't matter, makes simpler mux
	       o_tlast <= s_axis_data_tlast;
	       o_tvalid <= s_axis_data_tlast & s_axis_data_tvalid;
	       s_axis_data_tready <= o_tready;
	       header_out_tready <= 1'b0;
	    end
	  ST_EVEN :
	    begin
	       o_tdata <= { held_data, s_axis_data_tdata };
	       o_tlast <= s_axis_data_tlast;
	       o_tvalid <= s_axis_data_tvalid;
	       s_axis_data_tready <= o_tready;
	       header_out_tready <= 1'b0;
	    end
	  default :
	    begin
	       o_tdata <= { held_data, s_axis_data_tdata };
	       o_tlast <= s_axis_data_tlast;
	       o_tvalid <= 1'b0;
	       s_axis_data_tready <= 1'b0;
	       header_out_tready <= 1'b0;
	    end
	endcase // case (a2n_state)
     end // always @ *
   
endmodule // simple_axi_wrapper
