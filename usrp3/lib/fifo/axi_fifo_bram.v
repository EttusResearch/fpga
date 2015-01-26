//
// Copyright 2012-2014 Ettus Research LLC
//



// Block RAM AXI fifo


module axi_fifo_bram
  #(parameter WIDTH=32, SIZE=9)
   (input clk, input reset, input clear,
    input [WIDTH-1:0] i_tdata,
    input i_tvalid,
    output i_tready,
    output reg [WIDTH-1:0] o_tdata,
    output reg o_tvalid,
    input o_tready,
    
    output reg [15:0] space,
    output reg [15:0] occupied);

   wire 	      write 	     = i_tvalid & i_tready;
   wire 	      read 	     = ~empty & int_tready;
   wire 	      full, empty;
   
   wire [WIDTH-1:0] int_tdata;
   wire int_tready;

   assign i_tready  = ~full;

   // Read side states
   localparam 	  EMPTY = 0;
   localparam 	  PRE_READ = 1;
   localparam 	  READING = 2;

   reg [SIZE-1:0] wr_addr, rd_addr;
   reg [1:0] 	  read_state;

   reg 	  empty_reg, full_reg;
   always @(posedge clk)
     if(reset)
       wr_addr <= 0;
     else if(clear)
       wr_addr <= 0;
     else if(write)
       wr_addr <= wr_addr + 1;

   ram_2port #(.DWIDTH(WIDTH),.AWIDTH(SIZE))
     ram (.clka(clk),
	  .ena(1'b1),
	  .wea(write),
	  .addra(wr_addr),
	  .dia(i_tdata),
	  .doa(),

	  .clkb(clk),
	  .enb((read_state==PRE_READ)|read),
	  .web(1'b0),
	  .addrb(rd_addr),
	  .dib({WIDTH{1'b1}}),
	  .dob(int_tdata));

   always @(posedge clk)
     if(reset)
       begin
	  read_state <= EMPTY;
	  rd_addr <= 0;
	  empty_reg <= 1;
       end
     else
       if(clear)
	 begin
	    read_state <= EMPTY;
	    rd_addr <= 0;
	    empty_reg <= 1;
	 end
       else 
	 case(read_state)
	   EMPTY :
	     if(write)
	       begin
		  //rd_addr <= wr_addr;
		  read_state <= PRE_READ;
	       end
	   PRE_READ :
	     begin
		read_state <= READING;
		empty_reg <= 0;
		rd_addr <= rd_addr + 1;
	     end
	   
	   READING :
	     if(read)
	       if(rd_addr == wr_addr)
		 begin
		    empty_reg <= 1; 
		    if(write)
		      read_state <= PRE_READ;
		    else
		      read_state <= EMPTY;
		 end
	       else
		 rd_addr <= rd_addr + 1;
	 endcase // case(read_state)

   wire [SIZE-1:0] dont_write_past_me = rd_addr - 2;
   wire 	   becoming_full = wr_addr == dont_write_past_me;
     
   always @(posedge clk)
     if(reset)
       full_reg <= 0;
     else if(clear)
       full_reg <= 0;
     else if(read & ~write)
       full_reg <= 0;
     //else if(write & ~read & (wr_addr == (rd_addr-3)))
     else if(write & ~read & becoming_full)
       full_reg <= 1;

   //assign empty = (read_state != READING);
   assign empty = empty_reg;

   // assign full = ((rd_addr - 1) == wr_addr);
   assign full = full_reg;

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

   //////////////////////////////////////////////
   // space and occupied are for diagnostics only
   // not guaranteed exact

   localparam NUMLINES = (1<<SIZE);
   always @(posedge clk)
     if(reset)
       space <= NUMLINES;
     else if(clear)
       space <= NUMLINES;
     else if(read & ~write)
       space <= space + 16'b1;
     else if(write & ~read)
       space <= space - 16'b1;
   
   always @(posedge clk)
     if(reset)
       occupied <= 16'b0;
     else if(clear)
       occupied <= 16'b0;
     else if(read & ~write)
       occupied <= occupied - 16'b1;
     else if(write & ~read)
       occupied <= occupied + 16'b1;

endmodule // fifo_long
