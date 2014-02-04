//
// Copyright 2013 Ettus Research LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

//
// Tracks the number of complete packets in an AXI FIFO so that
// the XGE MAC can commit to transmitting a packet.
//
 
module axi_count_packets_in_fifo
  (
   input clk,
   input reset,
   input in_axis_tvalid,
   input in_axis_tready,
   input in_axis_tlast,
   input out_axis_tvalid,
   input out_axis_tready,
   input out_axis_tlast,
   input pkt_tx_full,
   output enable_tx
   );

   localparam WAIT_SOF = 0;
   localparam WAIT_EOF = 1;
   
   localparam WAIT_FULL = 0;
   localparam DELAY_TO_EOF = 0;
   localparam WAIT_SPACE = 2;
   
   
   reg 	      in_state, out_state;
   reg [1:0]  full_state;
   reg 	      pause_tx;
   	      
   reg [7:0] pkt_count;

   
   //
   // Count packets arriving into large FIFO
   //
   always @(posedge clk)
     if (reset) begin
	in_state <= WAIT_SOF;
     end else
       case(in_state)
	 WAIT_SOF: 
	   if (in_axis_tvalid && in_axis_tready) begin
	      in_state <= WAIT_EOF;
	   end else begin
	      in_state <= WAIT_SOF;
	   end
	 WAIT_EOF: 
	   if (in_axis_tlast && in_axis_tvalid && in_axis_tready) begin
	      in_state <= WAIT_SOF;
	   end else begin
	      in_state <= WAIT_EOF;
	   end
       endcase // case(in_state)
   

   //
   // Count packets leaving large FIFO
   //
   always @(posedge clk)
     if (reset) begin
	out_state <= WAIT_SOF;
     end else
       case(out_state)
	 WAIT_SOF: 
	   if (out_axis_tvalid && out_axis_tready) begin
	      out_state <= WAIT_EOF;
	   end else begin
	      out_state <= WAIT_SOF;
	   end
	 WAIT_EOF: 
	   if (out_axis_tlast && out_axis_tvalid && out_axis_tready) begin
	      out_state <= WAIT_SOF;
	   end else begin
	      out_state <= WAIT_EOF;
	   end
       endcase // case(in_state)
   

   //
   // Count packets in FIFO.
   // No protection on counter wrap, 
   // unclear how such an error could occur or how to gracefully deal with it.
   //
   always @(posedge clk)
     if (reset)
       pkt_count <= 0;
     else if (((out_state==WAIT_EOF) && out_axis_tlast && out_axis_tvalid && out_axis_tready) 
	      && ((in_state==WAIT_EOF) && in_axis_tlast && in_axis_tvalid && in_axis_tready))
       pkt_count <= pkt_count;
     else if ((out_state==WAIT_EOF) && out_axis_tlast && out_axis_tvalid && out_axis_tready)
       pkt_count <= pkt_count - 1;
     else if ((in_state==WAIT_EOF) && in_axis_tlast && in_axis_tvalid && in_axis_tready)
       pkt_count <= pkt_count + 1;
   

   //
   // Guard against Tx MAC overflow (as indicated by pkt_tx_full)
   //
   always @(posedge clk)
     if (reset) begin
	pause_tx <= 0;
	full_state <= WAIT_FULL;
     end	
     else begin
	pause_tx <= 0;	
	case(full_state)
	  WAIT_FULL:
	    // Search for pkt_tx_full going asserted
	    if (pkt_tx_full && (out_state == WAIT_SOF)) begin
	       full_state <= WAIT_SPACE;
	       pause_tx <= 1;
	    end else if (pkt_tx_full && (out_state == WAIT_EOF)) begin
	       full_state <= DELAY_TO_EOF;
	    end
	  
	  DELAY_TO_EOF:
	    // pkt_tx_full has gone asserted during Tx of a packet from FIFO.
	    // Wait until either FIFO has space again and transition direct to WAIT_FULL
	    // or at EOF if pkt_tx_full is still asserted the transition to WAIT_SPACE until
	    // MAC flags there is space again.
	    if (pkt_tx_full && out_axis_tlast && out_axis_tvalid && out_axis_tready) begin
	       full_state <= WAIT_SPACE;
	       pause_tx <= 1;
	    end else if (pkt_tx_full) begin
	       full_state <= DELAY_TO_EOF;
	    end else
	      full_state <= WAIT_FULL;
	  
	  WAIT_SPACE:
	    // Wait for MAC to flag space in internal Tx FIFO again then transition to WAIT_FULL.
	    if (pkt_tx_full) begin
	       full_state <= WAIT_SPACE;
	       pause_tx <= 1;
	    end else
	      full_state <= WAIT_FULL;
	  
	endcase // case(full_state)
     end
	

   // Enable Tx to MAC
   assign enable_tx = (pkt_count != 0) && ~pause_tx;
   
   
   

endmodule // count_tx_packets

