//
// Copyright 2013 Ettus Research LLC
//


// HALT brings RX to an idle state as quickly as possible if RX is running
// without running the risk of leaving a packet fragment in downstream FIFO's.
// HALT also flushes all remaining pending commands in the commmand FIFO.
// Unlike STOP, HALT doesn't ever create an ERROR packet.


module rx_control_gen3
  #(parameter BASE=0)
   (input clk, input reset, input clear,
    input set_stb, input [7:0] set_addr, input [31:0] set_data,
    
    input [63:0] vita_time,
    
    // DDC connections
    output run,
    input [31:0] sample,
    input strobe,
    
    output [31:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready,
    output [127:0] rx_tuser
    );
   
   wire [31:0] 	   command_i;
   wire [63:0] 	   time_i;
   wire 	   store_command;
   
   wire 	   send_imm, chain, reload, stop;
   wire [27:0] 	   numlines;
   wire [63:0] 	   rcvtime;
   
   wire 	   now, early, late;
   wire 	   command_valid;
   reg 		   command_ready;
   
   reg 		   chain_sav, reload_sav;
   reg 		   clear_halt;
   reg 		   halt;
   wire 	   set_halt;
   wire [15:0] 	   maxlen;
   wire [31:0] 	   sid;
   wire 	   eob;
   reg [31:0] 	   err_data;
   wire 	   sid_changed;
   wire 	   error_state;
   reg [63:0] 	   err_time, start_time;
   
   setting_reg #(.my_addr(BASE)) sr_cmd
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(command_i),.changed());
   
   setting_reg #(.my_addr(BASE+1)) sr_time_h
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(time_i[63:32]),.changed());
   
   setting_reg #(.my_addr(BASE+2)) sr_time_l
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(time_i[31:0]),.changed(store_command));
   
   setting_reg #(.my_addr(BASE+3)) sr_rx_halt
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(),.changed(set_halt));
   
   setting_reg #(.my_addr(BASE), .width(16)) sr_maxlen
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(maxlen),.changed());
   
   setting_reg #(.my_addr(BASE+1), .width(32)) sr_sid
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(sid),.changed(sid_changed));
   
   always @(posedge clk)
     if (reset | clear | clear_halt)
       halt <= 1'b0;
     else
       halt <= set_halt;
   
   axi_fifo_short #(.WIDTH(96)) commandfifo
     (.clk(clk),.reset(reset),.clear(clear | clear_halt),
      .i_tdata({command_i,time_i}), .i_tvalid(store_command), .i_tready(),
      .o_tdata({send_imm,chain,reload,stop,numlines,rcvtime}),
      .o_tvalid(command_valid), .o_tready(command_ready),
      .occupied(), .space() );
   
   time_compare 
     time_compare (.clk(clk), .reset(reset), .time_now(vita_time), .trigger_time(rcvtime), .now(now), .early(early), .late(late));
   
   localparam IBS_IDLE         = 0;
   localparam IBS_RUNNING      = 1;
   localparam IBS_OVERRUN      = 4;
   localparam IBS_BROKENCHAIN  = 5;
   localparam IBS_LATECMD      = 6;
   localparam IBS_ERR_END      = 7;
      
   reg [2:0] 	   ibs_state;
   reg [27:0] 	   lines_left, repeat_lines;
   reg [15:0] 	   lines_left_pkt;
   
   always @(posedge clk)
     if(reset | clear)
       begin
	  ibs_state <= IBS_IDLE;
	  chain_sav <= 1'b0;
	  reload_sav <= 1'b0;
	  clear_halt <= 1'b0;
       end
     else
       case (ibs_state)
	 IBS_IDLE : begin
	    clear_halt <= 1'b0; // Incase we got here through a HALT.
	    if (command_valid)
	      // There is a valid command to pop from FIFO.
	      if (stop) begin
		 // Stop bit set in this command, go idle.
		 ibs_state <= IBS_IDLE;
	      end else if (late & ~send_imm) begin
		 // Got this command later than its execution time.
		 ibs_state <= IBS_LATECMD;
		 err_time <= vita_time;
	      end else if (now | send_imm) begin
		 // Either its time to run this command or it should run immediately without a time.
		 ibs_state <= IBS_RUNNING;
		 lines_left <= numlines;
		 repeat_lines <= numlines;
		 chain_sav <= chain;
		 reload_sav <= reload;
		 lines_left_pkt <= maxlen;
	      end
	 end // case: IBS_IDLE
	 
	 IBS_RUNNING :
	   if (strobe) 
	     if (~rx_tready)  // Framing FIFO is full and we have just overrun.
	       begin
		  ibs_state <= IBS_OVERRUN;
		  err_time <= vita_time;
	       end 
	     else 
	       begin
		  if(lines_left_pkt == 1)
		    lines_left_pkt <= maxlen;
		  else
		    lines_left_pkt <= lines_left_pkt - 1;
		  if(lines_left_pkt == maxlen)
		    start_time <= vita_time;
		  if (lines_left == 1) 
		    begin
		       if (halt) // Provide Halt mechanism used to bring RX into known IDLE state at re-initialization.
			 begin
			    ibs_state <= IBS_IDLE;
			    clear_halt <= 1'b1;
			 end 
		       else if (chain_sav)  // If chain_sav is true then execute the next command now this one finished.
			 begin
			    if (command_valid)
			      begin
				 lines_left <= numlines;
				 repeat_lines <= numlines;
				 chain_sav <= chain;
				 reload_sav <= reload;
				 if (stop) // If the new command includes stop then go idle.
				   ibs_state <= IBS_IDLE;
			      end 
			    else if (reload_sav) // There is no new command to pop from FIFO so re-run previous command.
			      lines_left <= repeat_lines;
			    else // Chain has been broken, no commands left in FIFO and reload not set.
			      begin
				 ibs_state <= IBS_BROKENCHAIN;
				 err_time <= vita_time;
			      end
			 end // if (chain_sav)
		       else // Chain is not true, so don't look for new command, instead go idle.
			 ibs_state <= IBS_IDLE;
		    end // if (lines_left == 1)
		  else // Still counting down lines in current command.
		    lines_left <= lines_left - 28'd1;
	       end // else: !if(~rx_tready)
	 	     	 
	 IBS_OVERRUN: if(rx_tready) ibs_state <= IBS_ERR_END;
	 IBS_BROKENCHAIN: if(rx_tready) ibs_state <= IBS_ERR_END;
	 IBS_LATECMD: if(rx_tready) ibs_state <= IBS_ERR_END;
	 IBS_ERR_END: if(rx_tready) ibs_state <= IBS_IDLE;
	 
	 default: 
	   ibs_state <= IBS_IDLE;
       endcase // case (ibs_state)

   assign run = (ibs_state == IBS_RUNNING);
   
   always @*
     case(ibs_state)
       IBS_IDLE    : command_ready <= stop | late | now | send_imm;
       IBS_RUNNING : command_ready <= strobe & (lines_left == 1) & chain_sav;
       default     : command_ready <= 1'b0;
     endcase // case (ibs_state)
   
   assign eob = strobe && (lines_left == 1) && ( !chain_sav || (command_valid && stop) || (!command_valid && !reload_sav) || halt);
   
   always @*
     case (ibs_state)
       IBS_OVERRUN     : err_data <= 32'h8;
       IBS_BROKENCHAIN : err_data <= 32'h4;
       IBS_LATECMD     : err_data <= 32'h2;
       IBS_ERR_END     : err_data <= 32'h0;
       default         : err_data <= 32'h0;
     endcase // case (ibs_state)

   assign error_state = (ibs_state > IBS_RUNNING);
   
   assign rx_tdata = error_state ? err_data : sample;

   // FIXME need tlast on last line before an overrun error.  Broken chain gets eob, latecmd doesn't need it
   assign rx_tlast = error_state ? (ibs_state == IBS_ERR_END) : (eob | (lines_left_pkt == 1));
   
   assign rx_tvalid = error_state ? 1'b1 : (run & strobe);
   
   assign rx_tuser = error_state ? { 4'b1111 /*Error w/Time*/, 12'h0 /*seqnum ignored*/, 16'h0 /*len ignored */, sid, err_time } :
		     { 3'b001 /*Data w/Time*/, eob, 12'h0 /*seqnum ignored*/, 16'h0 /*len ignored */, sid, start_time };
   
endmodule // new_rx_control
