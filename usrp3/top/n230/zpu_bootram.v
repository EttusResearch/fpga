//
// Copyright 2014 Ettus Research LLC
//

//
// Single ported SRAM on Wishbone bus I/F
//
module zpu_bootram (
   input wb_clk_i,
   input wb_rst_i,
   // Data access port.
   input [14:0] dwb_adr_i,
   input [31:0] dwb_dat_i,
   output [31:0] dwb_dat_o,
   input dwb_we_i,
   output reg dwb_ack_o,
   input dwb_stb_i,
   input [3:0] dwb_sel_i
);

   //---------------------------------------------------------
   // Mem ack logic
    //---------------------------------------------------------
   always @(posedge wb_clk_i) begin
      if (wb_rst_i)
         dwb_ack_o <= 0;
      else
         dwb_ack_o <= dwb_stb_i & ~dwb_ack_o;
   end

   bootram_8kx32 bootram_8kx32 (
      .clka(wb_clk_i),    // input clka
      .ena(dwb_stb_i),      // input ena
      .wea({4{(dwb_we_i & ~wb_rst_i)}}),      // input [3 : 0] wea
      .addra(dwb_adr_i[14:2]),  // input [12 : 0] addra
      .dina(dwb_dat_i),    // input [31 : 0] dina
      .douta(dwb_dat_o)  // output [31 : 0] douta
   );

endmodule
