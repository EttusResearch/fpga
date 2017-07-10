module zf_equalizer(input clk, input reset, input clear,
    input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);
    
    localparam ST_WAIT_FOR_FRAME = 2'd0;
    localparam ST_ESTIMATE = 2'd1;
    localparam ST_EQUALIZE = 2'd2;
    reg [1:0] state;
    
    localparam signed MAX_POS_VALUE = 16'd32767;
    localparam signed MAX_NEG_VALUE = -16'd32767;
    
    wire do_op = 0;
    
    axi_fifo #(.SIZE(52)) int_axi_fifo_channel
    
    //1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1
    reg signed [31:0] long_preamble_rom [52:0];
    
    initial()
    begin
    	long_preamble_rom[0] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[1] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[2] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[3] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[4] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[5] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[6] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[7] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[8] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[9] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[10] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[11] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[12] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[13] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[14] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[15] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[16] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[17] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[18] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[19] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[20] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[21] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[22] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[23] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[24] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[25] = {MAX_POS_VALUE, 16'b0};
    	
    	long_preamble_rom[26] = {16'b0, 16'b0};
    	
    	long_preamble_rom[27] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[28] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[29] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[30] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[31] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[32] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[33] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[34] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[35] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[36] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[37] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[38] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[39] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[40] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[41] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[42] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[43] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[44] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[45] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[46] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[47] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[48] = {MAX_NEG_VALUE, 16'b0};
    	long_preamble_rom[49] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[50] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[51] = {MAX_POS_VALUE, 16'b0};
    	long_preamble_rom[52] = {MAX_POS_VALUE, 16'b0};
    end
    
    @always(posedge (clk))
    begin
    if(reset | clear)   
        begin
                
        end
   	else
    	begin
        if(do_op)
        	begin
        	case(state)
				ST_WAIT_FOR_FRAME :
					begin
						
					end
				ST_ESTIMATE :
					begin
						
					end
				ST_EQUALIZE : 
					begin
					
					end		
			end
        end
    end
    	
    
    

endmodule
