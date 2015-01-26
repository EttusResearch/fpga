//
// Copyright 2012 Ettus Research LLC
//


//
// 32 word FIFO with AXI4-STREAM interface.
//
// NOTE: This module uses the SRLC32E primitive explicitly and as such
// can only be used with Xilinx technology of the VIRTEX-6/SPARTAN-6/SIERIES-7 or newer.
//

module axi_fifo_short
  #(parameter WIDTH=32)
   (
    input clk, 
    input reset, 
    input clear,
    input [WIDTH-1:0] i_tdata,
    input i_tvalid,
    output i_tready,
    output reg [WIDTH-1:0] o_tdata,
    output reg o_tvalid,
    input o_tready,
    
    output reg [5:0] space,
    output reg [5:0] occupied
    );

   wire [WIDTH-1:0] int_tdata;
   wire int_tready;

   reg full, empty;
   wire write 	     = i_tvalid & i_tready;
   wire read 	     = ~empty & int_tready;

   assign i_tready  = ~full;

   reg [4:0] 	  a;
   genvar 	  i; 
   
   generate
      for (i=0;i<WIDTH;i=i+1)
	begin : gen_srlc32e
	   SRLC32E
	     srlc32e(.Q(int_tdata[i]), .Q31(),
		     .A(a), //.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.A4(a[4]),
		    .CE(write),.CLK(clk),.D(i_tdata[i]));
	end
   endgenerate
   
   always @(posedge clk)
     if(reset)
       begin
	  a <= 0;
	  empty <= 1;
	  full <= 0;
       end
     else if(clear)
       begin
	  a <= 0;
	  empty <= 1;
	  full<= 0;
       end
     else if(read & ~write)
       begin
	  full <= 0;
	  if(a==0)
	    empty <= 1;
	  else
	    a <= a - 1;
       end
     else if(write & ~read)
       begin
	  empty <= 0;
	  if(~empty)
	    a <= a + 1;
	  if(a == 30)
	    full <= 1;
       end

   // Output registred stage
   always @(posedge clk)
   begin
      // Valid flag
      if (reset | clear)
         o_tvalid <= 1'b0;
      else if (int_tready)
         o_tvalid <= ~empty;

      // Data
      if (int_tready)
         o_tdata <= int_tdata;
   end

   assign int_tready = o_tready | ~o_tvalid;

   // NOTE will fail if you write into a full fifo or read from an empty one

   //////////////////////////////////////////////////////////////
   // space and occupied are used for diagnostics, not 
   // guaranteed correct
   
   //assign space = full ? 0 : empty ? 16 : 15-a;
   //assign occupied = empty ? 0 : full ? 16 : a+1;

   always @(posedge clk)
     if(reset)
       space <= 6'd32;
     else if(clear)
       space <= 6'd32;
     else if(read & ~write)
       space <= space + 6'd1;
     else if(write & ~read)
       space <= space - 6'd1;
   
   always @(posedge clk)
     if(reset)
       occupied <= 6'd0;
     else if(clear)
       occupied <= 6'd0;
     else if(read & ~write)
       occupied <= occupied - 6'd1;
     else if(write & ~read)
       occupied <= occupied + 6'd1;
      
endmodule // axi_fifo_short

