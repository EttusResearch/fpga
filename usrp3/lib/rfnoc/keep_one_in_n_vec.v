//
// Copyright 2016 Ettus Research LLC
//

module keep_one_in_n_vec #(
  parameter KEEP_FIRST=0,  // 0: Drop n-1 words then keep last word, 1: Keep 1st word then drop n-1 
  parameter WIDTH=16
)(
  input clk, input reset,
  input [15:0] n,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  reg [15:0] counter;

  // n==0 lets everything through
  wire on_last_one  = ( (counter >= (n-1)) | (n == 0) );
  wire on_first_one = ( (counter == 0)     | (n == 0) );

  // Caution if changing n during operation!
  always @(posedge clk) begin
    if (reset) begin
       counter <= 0;
    end else begin
      if (i_tvalid & i_tready & i_tlast) begin
        if (on_last_one) begin
          counter <= 16'd0;
        end else begin
          counter <= counter + 16'd1;
        end
      end
    end
  end

  assign i_tready = o_tready | (KEEP_FIRST ? ~on_first_one : ~on_last_one);
  assign o_tvalid = i_tvalid & (KEEP_FIRST ?  on_first_one :  on_last_one);

  assign o_tdata = i_tdata;
  assign o_tlast = i_tlast;

endmodule // keep_one_in_n_vec
