/////////////////////////////////////////////////////////////////////
//
// Copyright 2014-2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: chdr_eth_framer
// Description:
//  - Takes a CHDR stream in and adds udp, ip, and ethernet framing
//  - Use a RAM indexed by destination field of stream ID
//    - Local RAM: For local host packets
//    - Remote RAM: For remote host with different local_addr
//
/////////////////////////////////////////////////////////////////////

module n3xx_chdr_eth_framer #(
  parameter BASE   = 0,
  parameter AWIDTH = 8
  )(
  input                clk,
  input                reset,
  input                clear,
  input                set_stb,
  input  [AWIDTH-1:0]  set_addr,
  input  [31:0]        set_data,
  input  [63:0]        in_tdata,
  input                in_tlast,
  input                in_tvalid,
  output               in_tready,
  output [63:0]        out_tdata,
  output [3:0]         out_tuser,
  output               out_tlast,
  output               out_tvalid,
  input                out_tready,
  input  [47:0]        mac_src,
  input  [31:0]        ip_src,
  input  [15:0]        udp_src,
  output [31:0]        debug
  );

  localparam [11:0] REG_LOCAL_DST_IP          = BASE + 'h0;
  localparam [11:0] REG_LOCAL_DST_UDP_MAC_MSB = BASE + 'h100;
  localparam [11:0] REG_LOCAL_DST_MAC_LSB     = BASE + 'h200;

  localparam [11:0] REG_REMOTE_DST_IP          = BASE + 'h340;
  localparam [11:0] REG_REMOTE_DST_UDP_MAC_MSB = BASE + 'h380;
  localparam [11:0] REG_REMOTE_DST_MAC_LSB     = BASE + 'h3c0;

  reg [7:0] 	  sid;
  reg [15:0] 	  chdr_len;
  reg [3:0]       local_addr;
  reg [2:0] 	  vef_state;
  localparam VEF_IDLE    = 3'd0;
  localparam VEF_PAYLOAD = 3'd7;

  reg [63:0] 	  tdata;

  always @(posedge clk)
    if(reset | clear)
      begin
        vef_state <= VEF_IDLE;
        sid <= 8'd0;
        chdr_len <= 16'd0;
        local_addr <= 4'd0;
      end
    else
    case(vef_state)
      VEF_IDLE :
        if(in_tvalid)
          begin
   	        vef_state <= 1;
   	        sid <= in_tdata[7:0];
   	        chdr_len <= in_tdata[47:32];
            local_addr <= in_tdata[11:8];
          end
      VEF_PAYLOAD :
        if(in_tvalid & out_tready)
          if(in_tlast)
            vef_state <= VEF_IDLE;
      default :
        if(out_tready)
          vef_state <= vef_state + 3'd1;
    endcase // case (vef_state)

  assign in_tready = (vef_state == VEF_PAYLOAD) ? out_tready : 1'b0;
  assign out_tvalid = (vef_state == VEF_PAYLOAD) ? in_tvalid : (vef_state == VEF_IDLE) ? 1'b0 : 1'b1;
  assign out_tlast = (vef_state == VEF_PAYLOAD) ? in_tlast : 1'b0;
  assign out_tuser = ((vef_state == VEF_PAYLOAD) & in_tlast) ? {1'b0,chdr_len[2:0]} : 4'b0000;
  assign out_tdata = tdata;

  wire [47:0] pad = 48'h0;
  wire [47:0] mac_dst;
  wire [47:0] mac_local_dst;
  wire [47:0] mac_remote_dst;
  wire [15:0] eth_type = 16'h0800;
  wire [15:0] misc_ip = { 4'd4 /* IPv4 */, 4'd5 /* IP HDR Len */, 8'h00 /* DSCP and ECN */};
  wire [15:0] ip_len = (16'd28 + chdr_len);  // 20 for IP, 8 for UDP
  wire [15:0] ident = 16'h0;
  wire [15:0] flag_frag = { 3'b010 /* don't fragment */, 13'h0 };
  wire [15:0] ttl_prot = { 8'h10 /* TTL */, 8'h11 /* UDP */ };
  wire [15:0] iphdr_local_checksum;
  wire [15:0] iphdr_remote_checksum;
  wire [15:0] iphdr_checksum;
  wire [31:0] ip_dst;
  wire [31:0] ip_local_dst;
  wire [31:0] ip_remote_dst;
  wire [15:0] udp_dst;
  wire [15:0] udp_local_dst;
  wire [15:0] udp_remote_dst;
  wire [15:0] udp_len = (16'd8 + chdr_len);
  wire [15:0] udp_checksum = 16'h0;

  // Tables of MAC/IP/UDP addresses for LOCAL sid

  ram_2port #(.DWIDTH(32), .AWIDTH(8)) ram_ip_local
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[11:8] == REG_LOCAL_DST_IP[11:8])), .addra(set_addr[7:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(sid[7:0]), .dib(32'hFFFF_FFFF), .dob(ip_local_dst));

  ram_2port #(.DWIDTH(32), .AWIDTH(8)) ram_udpmac_local
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[11:8] == REG_LOCAL_DST_UDP_MAC_MSB[11:8])), .addra(set_addr[7:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(sid[7:0]), .dib(32'hFFFF_FFFF), .dob({udp_local_dst,mac_local_dst[47:32]}));

  ram_2port #(.DWIDTH(32), .AWIDTH(8)) ram_maclower_local
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[11:8] == REG_LOCAL_DST_MAC_LSB[11:8])), .addra(set_addr[7:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(sid[7:0]), .dib(32'hFFFF_FFFF), .dob(mac_local_dst[31:0]));

  // Tables of MAC/IP/UDP addresses for REMOTE sid/local_addr
  // Support only for 16 local_address

  ram_2port #(.DWIDTH(32), .AWIDTH(4)) ram_ip_remote
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[7:4] == REG_REMOTE_DST_IP[7:4])), .addra(set_addr[3:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(local_addr), .dib(32'hFFFF_FFFF), .dob(ip_remote_dst));

  ram_2port #(.DWIDTH(32), .AWIDTH(4)) ram_udpmac_remote
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[7:4] == REG_REMOTE_DST_UDP_MAC_MSB[7:4])), .addra(set_addr[3:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(local_addr), .dib(32'hFFFF_FFFF), .dob({udp_remote_dst,mac_remote_dst[47:32]}));

  ram_2port #(.DWIDTH(32), .AWIDTH(4)) ram_maclower_remote
    (.clka(clk), .ena(1'b1), .wea(set_stb & (set_addr[7:4] == REG_REMOTE_DST_MAC_LSB[7:4])), .addra(set_addr[3:0]), .dia(set_data), .doa(),
     .clkb(clk), .enb(1'b1), .web(1'b0), .addrb(local_addr), .dib(32'hFFFF_FFFF), .dob(mac_remote_dst[31:0]));

  ip_hdr_checksum ip_hdr_checksum_local
    (.clk(clk), .in({misc_ip,ip_len,ident,flag_frag,ttl_prot,16'd0,ip_src,ip_local_dst}),
     .out(iphdr_local_checksum));
  ip_hdr_checksum ip_hdr_checksum_remote
    (.clk(clk), .in({misc_ip,ip_len,ident,flag_frag,ttl_prot,16'd0,ip_src,ip_remote_dst}),
     .out(iphdr_remote_checksum));

  assign mac_dst = (local_addr == 4'b0 | local_addr == 4'b1) ? mac_local_dst : mac_remote_dst;
  assign ip_dst = (local_addr == 4'b0 | local_addr == 4'b1) ? ip_local_dst : ip_remote_dst;
  assign udp_dst = (local_addr == 4'b0 | local_addr == 4'b1) ? udp_local_dst : udp_remote_dst;
  assign iphdr_checksum = (local_addr == 4'b0 | local_addr == 4'b1) ? iphdr_local_checksum : iphdr_remote_checksum;

  always @*
    case(vef_state)
      1 : tdata <= { pad[47:0], mac_dst[47:32]};
      2 : tdata <= { mac_dst[31:0], mac_src[47:16]};
      3 : tdata <= { mac_src[15:0], eth_type[15:0], misc_ip[15:0], ip_len[15:0] };
      4 : tdata <= { ident[15:0], flag_frag[15:0], ttl_prot[15:0], iphdr_checksum[15:0]};
      5 : tdata <= { ip_src, ip_dst};
      6 : tdata <= { udp_src, udp_dst, udp_len, udp_checksum};
      default : tdata <= in_tdata;
    endcase // case (vef_state)

endmodule // chdr_eth_framer
