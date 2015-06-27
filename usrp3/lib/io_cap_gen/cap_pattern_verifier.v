//
// Synthesizable test pattern checker
//

module cap_pattern_verifier #(
  parameter WIDTH       = 16,       //Width of data bus
  parameter PATTERN     = "RAMP",   //Pattern to detect. Choose from {RAMP, ONES, ZEROS, TOGGLE, LEFT_BARREL, RIGHT_BARREL}
  parameter RAMP_START  = 'h0000,   //Start value for ramp (PATTERN=RAMP only)
  parameter RAMP_STOP   = 'hFFFF,   //Stop value for ramp (PATTERN=RAMP only)
  parameter RAMP_INCR   = 'h0001,   //Increment for ramp (PATTERN=RAMP only)
  parameter BARREL_INIT = 'h0001,   //Initial value for the barrel shifter (PATTERN=*_BARREL only)
  parameter HOLD_CYCLES = 1         //Number of cycles to hold each value in the pattern
) (
  input             clk,
  input             rst,

  //Data input
  input             valid,
  input [WIDTH-1:0] data,

  //Status output (2 cycle latency)
  output reg [31:0] count,
  output reg [31:0] errors,
  output            locked,
  output            failed
);

  // Register the data to minimize fanout at source
  reg [WIDTH-1:0] data_reg;
  reg             valid_reg;
  always @(posedge clk) begin
    data_reg  <= data;
    valid_reg <= rst ? 1'b0 : valid;
  end

  // Define pattern start and next states
  wire [WIDTH-1:0]  patt_start;
  reg [WIDTH-1:0]   patt_next;
  generate if (PATTERN == "RAMP") begin
    assign patt_start = RAMP_START;
    always @(posedge clk) patt_next <= (data_reg==RAMP_STOP) ? RAMP_START : data_reg+RAMP_INCR;
  end else if (PATTERN == "ZEROS") begin
    assign patt_start = {WIDTH{1'b0}};
    always @(posedge clk) patt_next <= {WIDTH{1'b0}};
  end else if (PATTERN == "ONES") begin
    assign patt_start = {WIDTH{1'b1}};
    always @(posedge clk) patt_next <= {WIDTH{1'b1}};
  end else if (PATTERN == "TOGGLE") begin
    assign patt_start = {(WIDTH/2){2'b10}};
    always @(posedge clk) patt_next <= ~data_reg;
  end else if (PATTERN == "LEFT_BARREL") begin
    assign patt_start = BARREL_INIT;
    always @(posedge clk) patt_next <= {data_reg[WIDTH-2:0],data_reg[WIDTH-1]};
  end else if (PATTERN == "RIGHT_BARREL") begin
    assign patt_start = BARREL_INIT;
    always @(posedge clk) patt_next <= {data_reg[0],data_reg[WIDTH-1:1]};
  end endgenerate

  reg [1:0] state;
  localparam ST_IDLE    = 2'd0;
  localparam ST_LOCKED  = 2'd1;

  reg [7:0] cyc_count;

  always @(posedge clk) begin
    if (rst) begin
      count     <= 32'd0;
      errors    <= 32'd0;
      state     <= ST_IDLE;
      cyc_count <= 8'd0;
    end else begin
      if (valid_reg) begin    //Only do something if data is valid
        case (state)
          ST_IDLE: begin
            if (data_reg == patt_start) begin   //Trigger on start of pattern
              state     <= ST_LOCKED;
              count     <= 32'd1;
              cyc_count <= HOLD_CYCLES - 1;
            end
          end
          ST_LOCKED: begin
            if (cyc_count == 0) begin           //Hold counter has expired. Check next word
              count <= count + 32'd1;
              if (data_reg != patt_next) begin
                errors <= errors + 32'd1;
              end
              cyc_count <= HOLD_CYCLES - 1;
            end else begin                      //Hold until the next update
              cyc_count <= cyc_count - 1;
            end
          end
        endcase
      end
    end
  end  

  assign locked = (state == ST_LOCKED);
  assign failed = (errors != 32'd0) && locked;

endmodule



