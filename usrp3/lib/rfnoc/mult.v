
// Write xilinx DSP48E1 primitive for multiplication with AXI interfaces
// Latency must be 1 to 4
// FIXME A and B ports are coupled, but we could allow them to separately pipeline

module mult
  #(parameter WIDTH_A=25,
    parameter WIDTH_B=18,
    parameter WIDTH_P=0,
    parameter LATENCY=3)
   (input clk, input reset,
    input [WIDTH_A-1:0] a_tdata, input a_tlast, input a_tvalid, output a_tready,
    input [WIDTH_B-1:0] b_tdata, input b_tlast, input b_tvalid, output b_tready,
    /* p_tdata declared below */ output p_tlast, output p_tvalid, output p_tready);
   
   localparam WIDTH_P_IN = (WIDTH_P == 0) ? (WIDTH_A+WIDTH_B) : WIDTH_P;
   output [WIDTH_P_IN-1:0] p_tdata;

   wire [47:0] 		   P1_OUT;
   wire [24:0] 		   A_IN = { a_tdata, {(25-(WIDTH_A)){1'b0}}};
   wire [17:0] 		   B_IN = { b_tdata, {(18-(WIDTH_B)){1'b0}}};
   assign p_tdata = P1_OUT[42 : (42-((WIDTH_A+WIDTH_B)-1))];
   
   wire 		   in_tvalid = a_tvalid & b_tvalid;
   wire 		   in_tready;
   
   assign a_tready = in_tvalid & in_tready;
   assign b_tready = in_tvalid & in_tready;

   localparam MREG_IN = 1;    // Always have this reg
   localparam PREG_IN = (LATENCY >= 3) ? 1 : 0;
   localparam A2REG_IN = (LATENCY >= 2) ? 1 : 0;
   localparam A1REG_IN = (LATENCY == 4) ? 1 : 0;

   wire [LATENCY-1:0] 	   enables;
   wire 		   CEP, CEM, CEA2, CEA1;
   assign { CEP, CEM, CEA2, CEA1 } = (LATENCY == 4) ? enables[3:0] :
				     (LATENCY == 3) ? {enables[2:0], 1'b0} :
				     (LATENCY == 2) ? {1'b0, enables[1:0], 1'b0} :
				     /* LATENCY == 1 */ {1'b0, enables[0], 2'b0};
   
   axi_pipe #(.STAGES(LATENCY)) axi_pipe
     (.clk(clk), .reset(reset), .clear(0),
      .i_tvalid(in_tvalid), .i_tready(in_tready),
      .o_tvalid(p_tvalid), .o_tready(p_tready),
      .enables(enables), .valids());
   
   DSP48E1 #(.ACASCREG(A1REG_IN+A2REG_IN),       
             .AREG(A1REG_IN+A2REG_IN),           
             .ADREG(0),
             .DREG(0),
             .BCASCREG(A1REG_IN+A2REG_IN),       
             .BREG(A1REG_IN+A2REG_IN),           
             .MREG(MREG_IN),           
             .PREG(PREG_IN)) 
   DSP48_inst (.ACOUT(),   
               .BCOUT(),  
               .CARRYCASCOUT(), 
               .CARRYOUT(), 
               .MULTSIGNOUT(), 
               .OVERFLOW(), 
               .P(P1_OUT),          
               .PATTERNBDETECT(), 
               .PATTERNDETECT(), 
               .PCOUT(),  
               .UNDERFLOW(), 
               .A({5'b0,A_IN}),          
               .ACIN(30'b0),    
               .ALUMODE(4'b0000), 
               .B(B_IN),          
               .BCIN(18'b0),    
               .C(48'b0),          
               .CARRYCASCIN(1'b0), 
               .CARRYIN(1'b0), 
               .CARRYINSEL(3'b0), 
               .CEA1(CEA1),      
               .CEA2(CEA2),      
               .CEAD(1'b0),
               .CEALUMODE(1'b1), 
               .CEB1(CEA1),      
               .CEB2(CEA2),      
               .CEC(CE),      
               .CECARRYIN(CE), 
               .CECTRL(CE), 
               .CED(CE),
               .CEINMODE(CE),
               .CEM(CEM),       
               .CEP(CEP),       
               .CLK(clk),       
               .D(25'b0),
               .INMODE(5'b0),
               .MULTSIGNIN(1'b0), 
               .OPMODE(7'b0000101), 
               .PCIN(48'b0),      
               .RSTA(reset),     
               .RSTALLCARRYIN(reset), 
               .RSTALUMODE(reset), 
               .RSTB(reset),     
               .RSTC(reset),   
               .RSTD(reset),  
               .RSTCTRL(reset),
               .RSTINMODE(reset), 
               .RSTM(reset), 
               .RSTP(reset));
   
endmodule // mult
