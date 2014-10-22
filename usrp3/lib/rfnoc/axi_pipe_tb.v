
module axi_pipe_tb;

   initial $dumpfile("axi_pipe_tb.vcd");
   initial $dumpvars(0,axi_pipe_tb);

   reg clk = 0;
   always #100 clk <= ~clk;
   reg reset = 1;
   initial #1000 @(posedge clk) reset <= 1'b0;
   initial #30000 $finish;
   
   localparam LEN=3;
   wire [LEN-1:0] enables, valids;

   wire 	  i_tready, o_tvalid;
   reg 		  i_tvalid = 0;
   reg 		  o_tready = 0;
   
   axi_pipe #(.STAGES(LEN)) axi_pipe
     (.clk(clk), .reset(reset), .clear(0),
      .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tvalid(o_tvalid), .o_tready(o_tready),
      .enables(enables), .valids(valids));

   initial
     begin
	@(negedge reset);
	repeat (3)
	  @(posedge clk);
	i_tvalid <= 1;
	@(posedge clk);
	i_tvalid <= 0;
	repeat (12) @(posedge clk);
	@(posedge clk);
	o_tready <= 1;
	repeat (12) @(posedge clk);
	o_tready <= 0;
	i_tvalid <= 1;
	repeat (12) @(posedge clk);
	o_tready <= 1;
	i_tvalid <= 0;
	repeat (12) @(posedge clk);
	o_tready <= 0;
	i_tvalid <= 1;
	@(posedge clk);
	i_tvalid <= 0;
	@(posedge clk);
	i_tvalid <= 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	i_tvalid <= 0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	o_tready <= 1;

     end
   
endmodule // axi_pipe
