//
// Copyright 2014 Ettus Research LLC
//

module peak_finder
  #(parameter SCALAR=131072)
   (input clk, input reset, input clear,
    input [31:0] i0_tdata, input i0_tlast, input i0_tvalid, output i0_tready,        // power measurment
    input [31:0] i1_tdata, input i1_tlast, input i1_tvalid, output i1_tready,        // cross power mag/phase
    output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

    wire [15:0] i_phase_tdata = i1_tdata[31:16];
    wire [15:0] i_mag_tdata = i1_tdata[15:0];

    // moved contents of threshold_scaled functionality here
    wire signed [31:0] scaled_input = (i_mag_tdata-1)*SCALAR;
    wire signed [31:0] difference = scaled_input - i0_tdata;
    wire thresh_met = difference > 0;

    // internal registers
    reg [63:0] counter;
    reg [7:0] debounce_counter;
    reg [15:0] max_val;
    reg [15:0] max_phase;
    reg [63:0] max_idx;

    // output registers
    reg found_burst;
    reg [15:0] burst_offset;
    reg [15:0] burst_phase;
   wire        do_op;

    // search for peaks durring (thresh_met = 1) periods
    // debounce the thresh_met line
    // send a notification and burst time/frequency downstream
    always @(posedge (clk))
        if(reset | clear)   
          begin
            counter <= 0;
            debounce_counter <= 0;
            max_val <= 0;
            max_phase <= 0;
            max_idx <= 0;
            found_burst <= 0;
            burst_offset <= 0;
            burst_phase <= 0;
          end
        else
            if(do_op)
              begin
                counter <= counter + 1;
                if(thresh_met | (debounce_counter > 0))
                  begin
                    if(thresh_met)
                        debounce_counter <= 5;
                    else
                        debounce_counter <= debounce_counter - 1;
                    if(i_mag_tdata > max_val)
                      begin
                        max_val <= i_mag_tdata;
                        max_phase <= i_phase_tdata;
                        max_idx <= counter;
                      end
                  end
                else
                  // we have concluded on a peak if max_idx > 0
                  if(max_idx > 0)
                    begin
                        found_burst <= 1;
                        burst_offset <= (counter - max_idx);
                        burst_phase <= max_phase;
                        max_val <= 0;
                        max_idx <= 0;
                    end
                  else
                    begin
                      found_burst <= 0;
                      burst_offset <= 0;
                      burst_phase <= 0;
                    end
              end

    assign o_tdata = {burst_phase, burst_offset};
    assign o_tlast = found_burst;

   assign do_op = (i0_tvalid & i1_tvalid & o_tready);
   
   assign o_tvalid = i0_tvalid & i1_tvalid;
   
    assign i0_tready = do_op;
    assign i1_tready = do_op;

endmodule // peak_finder


