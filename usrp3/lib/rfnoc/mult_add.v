
// Copyright 2014 Ettus Research
// Write xilinx DSP48E1 primitive for mult-add with AXI interfaces

module mult_add
  #(parameter WIDTH_A=25,
    parameter WIDTH_B=18,
    parameter WIDTH_P=48,
    parameter LATENCY=3)
   (input clk, input reset,
    input [WIDTH_A-1:0] a_tdata, input a_tlast, input a_tvalid, output a_tready,
    input [WIDTH_B-1:0] b_tdata, input b_tlast, input b_tvalid, output b_tready,
    input [WIDTH_P-1:0] accin_tdata, input accin_tlast, input accin_tvalid, output accin_tready,
    output [WIDTH_P-1:0] accout_tdata, output accout_tlast, output accout_tvalid, input accout_tready);
   
   wire [47:0] 		   P1_OUT;
   wire [24:0] 		   A_IN = { a_tdata, {(25-(WIDTH_A)){1'b0}}};
   wire [17:0] 		   B_IN = { b_tdata, {(18-(WIDTH_B)){1'b0}}};
   assign accout_tdata = P1_OUT[47:48-WIDTH_P];
   
   localparam MREG_IN = 1;    // Always have this reg
   localparam PREG_IN = (LATENCY >= 3) ? 1 : 0;
   localparam A2REG_IN = (LATENCY >= 2) ? 1 : 0;
   localparam A1REG_IN = (LATENCY == 4) ? 1 : 0;
   localparam AREG_IN = A1REG_IN + A2REG_IN;

   wire [A1REG_IN:0] 		   en0, en1;
   wire [PREG_IN:0] 		   en_post;
   reg 				   CEP, CEM, CEA2, CEA1, CEB2, CEB1;
   wire 			   CE = 1'b1;   // FIXME
   wire 			   LOAD = 1'b1;
   
   always @*
     case(LATENCY)
       2 : {CEP, CEM, CEA2, CEA1, CEB2, CEB1} <= { 1'b0      , en_post[0], en0[0], 1'b0  , en1[0], 1'b0   };
       3 : {CEP, CEM, CEA2, CEA1, CEB2, CEB1} <= { en_post[1], en_post[0], en0[0], 1'b0  , en1[0], 1'b0   };
       4 : {CEP, CEM, CEA2, CEA1, CEB2, CEB1} <= { en_post[1], en_post[0], en0[1], en0[0], en1[1], en1[0] };
     endcase
	 
   axi_pipe_join #(.PRE_JOIN_STAGES0(AREG_IN), .PRE_JOIN_STAGES1(AREG_IN),
		   .POST_JOIN_STAGES(MREG_IN+PREG_IN)) axi_pipe
     (.clk(clk), .reset(reset), .clear(0),
      .i0_tlast(a_tlast), .i0_tvalid(a_tvalid), .i0_tready(a_tready),
      .i1_tlast(a_tlast), .i1_tvalid(b_tvalid), .i1_tready(b_tready),
      .o_tlast(accout_tlast), .o_tvalid(accout_tvalid), .o_tready(accout_tready),
      .enables0(en0), .enables1(en1), .enables_post(en_post));
   
   DSP48E1 #(.ACASCREG(AREG_IN),       
             .AREG(AREG_IN),           
             .ADREG(0),
             .DREG(0),
             .BCASCREG(AREG_IN),       
             .BREG(AREG_IN),           
             .MREG(MREG_IN),           
             .PREG(PREG_IN)) 
   DSP48_inst (.ACOUT(),          // Outputs start here
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
               .A({5'b0,A_IN}),   // Inputs start here
               .ACIN(30'b0),    
               .ALUMODE(4'b0000),   //////////////////////
               .B(B_IN),       
               .BCIN(18'b0),    
               .C(accin_tdata),          ///////////////////////
               .CARRYCASCIN(1'b0), 
               .CARRYIN(1'b0), 
               .CARRYINSEL(3'b0), 
               .CEA1(CEA1),      
               .CEA2(CEA2),      
               .CEAD(1'b0),
               .CEALUMODE(1'b1),   ////////////////////////
               .CEB1(CEB1),      
               .CEB2(CEB2),      
               .CEC(CE),       ///////////////////////////
               .CECARRYIN(CE), 
               .CECTRL(CE), 
               .CED(CE),
               .CEINMODE(CE),
               .CEM(CEM),       
               .CEP(CEP),       
               .CLK(clk),       
               .D(25'b0),
               .INMODE(5'b0),    ///////////////////////
               .MULTSIGNIN(1'b0), 
               .OPMODE({2'b01, LOAD, 4'b0101}), // ////////////////////
               .PCIN(48'b0),      //////////////////////
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
