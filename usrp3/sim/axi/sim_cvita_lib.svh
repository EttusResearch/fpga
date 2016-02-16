//
// Copyright 2015 Ettus Research LLC
//

`include "sim_axis_lib.svh"

typedef logic [63:0] cvita_pkt_t[$];

typedef enum logic [1:0] {
  DATA=2'b00, FC=2'b01, CMD=2'b10, RESP=2'b11
} cvita_pkt_type_t;

typedef struct packed {
  cvita_pkt_type_t pkt_type;
  logic            has_time;
  logic            eob;
  logic [11:0]     seqno;
  logic [15:0]     length;
  logic [15:0]     src_sid;
  logic [15:0]     dst_sid;
  logic [63:0]     timestamp;
} cvita_hdr_t;

function logic[63:0] flatten_chdr_no_ts(input cvita_hdr_t hdr);
  return {hdr.pkt_type, hdr.has_time, hdr.eob, hdr.seqno, hdr.length, hdr.src_sid, hdr.dst_sid};
endfunction

//TODO: This should be a function but it segfaults XSIM.
task automatic unflatten_chdr_no_ts;
  input logic[63:0] hdr_bits;
  output cvita_hdr_t hdr;
  begin
    hdr = '{
      pkt_type:cvita_pkt_type_t'(hdr_bits[63:62]), has_time:hdr_bits[61], eob:hdr_bits[60],
      seqno:hdr_bits[59:48], length:hdr_bits[47:32], src_sid:hdr_bits[31:16], dst_sid:hdr_bits[15:0], timestamp:0  //Default timestamp
    };
  end
endtask

// Extracts header from CVITA packets.
// Args:
// - pkt: CVITA packet
// - hdr: CVITA header
task automatic extract_chdr(ref cvita_pkt_t pkt, ref cvita_hdr_t hdr);
  begin
    unflatten_chdr_no_ts(pkt[0],hdr);
    if (hdr.has_time) begin
      hdr.timestamp = pkt[1];
      // Delete both header and time stamp
      pkt = pkt[2:$];
    end else begin
      // Delete header
      pkt = pkt[1:$];
    end
  end
endtask

// Drops header from CVITA packets leaving only payload data.
// Args:
// - pkt: CVITA packet
task automatic drop_chdr(ref cvita_pkt_t pkt);
  begin
    automatic cvita_hdr_t hdr;
    extract_chdr(pkt,hdr);
  end
endtask

task automatic unflatten_chdr;
  input logic[63:0] hdr_bits;
  input logic[63:0] timestamp;
  output cvita_hdr_t hdr;
  begin
    hdr = '{
      pkt_type:cvita_pkt_type_t'(hdr_bits[63:62]), has_time:hdr_bits[61], eob:hdr_bits[60],
      seqno:hdr_bits[59:48], length:hdr_bits[47:32], src_sid:hdr_bits[31:16], dst_sid:hdr_bits[15:0], timestamp:timestamp
    };
  end
endtask

function logic chdr_compare(input cvita_hdr_t a, input cvita_hdr_t b);
  return ((a.pkt_type == b.pkt_type) && (a.has_time == b.has_time) && (a.eob == b.eob) &&
          (a.seqno == b.seqno) && (a.length == b.length) && (a.src_sid == b.src_sid) && (a.dst_sid == b.dst_sid));
endfunction

typedef struct packed {
  logic [31:0]  count;
  logic [63:0]  sum;
  logic [63:0]  min;
  logic [63:0]  max;
  logic [63:0]  crc;
} cvita_stats_t;


class cvita_master #(parameter DWIDTH = 64) extends axis_master #(DWIDTH);

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) axis);
    super.new(axis);
  endfunction

  // Push a CVITA header into the stream
  // Args:
  // - hdr: The header to push
  task automatic push_hdr;
    input cvita_hdr_t hdr;
    this.push_word(flatten_chdr_no_ts(hdr), 0);
  endtask

  // Push a packet with random data onto to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  // - hdr: Header to attach to packet (length will be ignored)
  // - timestamp: Optional timestamp
  task automatic push_rand_pkt;
    input integer       num_samps;
    input cvita_hdr_t   hdr;
    begin
      cvita_hdr_t tmp_hdr = hdr;
      tmp_hdr.length = num_samps + (hdr.has_time ? 16 : 8);
      @(negedge this.axis.clk);
      this.push_hdr(tmp_hdr);
      if (hdr.has_time) this.push_word(hdr.timestamp, 0);

      repeat(num_samps-1) begin
        this.push_word({$random,$random}, 0);
      end
      this.push_word({$random,$random}, 1);
    end
  endtask

  // Push a packet with a ramp on to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  // - ramp_start: Start value for the ramp
  // - ramp_inc: Increment per clock cycle
  // - hdr: Header to attach to packet (length will be ignored)
  // - timestamp: Optional timestamp
  task automatic push_ramp_pkt;
    input integer       num_samps;
    input logic [63:0]  ramp_start;
    input logic [63:0]  ramp_inc;
    input cvita_hdr_t   hdr;
    begin
      automatic integer counter = 0;

      cvita_hdr_t tmp_hdr = hdr;
      tmp_hdr.length = num_samps + (hdr.has_time ? 16 : 8);
      @(negedge this.axis.clk);
      this.push_hdr(tmp_hdr);
      if (hdr.has_time) this.push_word(hdr.timestamp, 0);

      repeat(num_samps-1) begin
        this.push_word(ramp_start+(counter*ramp_inc), 0);
        counter = counter + 1;
      end
      this.push_word(ramp_start+(counter*ramp_inc), 1);
    end
  endtask

  // Push a packet on to the AXI Stream bus.
  // Args:
  // - pkt: Packet data (queue)
  task automatic push_pkt;
    input cvita_pkt_t pkt;
    begin
      for (int i = 0; i < pkt.size-1; i = i + 1) begin
        this.push_word(pkt[i], 0);
      end
      this.push_word(pkt[pkt.size-1], 1);
    end
  endtask

endclass


class cvita_slave #(parameter DWIDTH = 64) extends axis_slave #(DWIDTH);

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) axis);
    super.new(axis);
  endfunction

  function void wait_for_pkt_get_info_update(ref cvita_stats_t stats, virtual axis_t #(.DWIDTH(DWIDTH)) axis);
    stats.count = stats.count + 1;
    stats.sum   = stats.sum + axis.tdata;
    stats.crc   = stats.crc ^ axis.tdata;
    if (axis.tdata < stats.min) stats.min = axis.tdata;
    if (axis.tdata > stats.max) stats.max = axis.tdata;
  endfunction

  // Wait for a packet to finish on the bus
  task automatic wait_for_pkt_get_info;
    output cvita_hdr_t    hdr;
    output cvita_stats_t  stats;
    begin
      automatic logic is_hdr  = 1;
      automatic logic is_time = 0;
      stats.count = 32'h0;
      stats.sum   = 64'h0;
      stats.min   = 64'h7FFFFFFFFFFFFFFF;
      stats.max   = 64'h0;
      stats.crc   = 64'h0;

      @(posedge this.axis.clk);
      //Corner case. We are already looking at the end
      //of a packet i.e. its just a header
      if (this.axis.tready&this.axis.tvalid&this.axis.tlast) begin
        unflatten_chdr_no_ts(this.axis.tdata, hdr);
        @(negedge this.axis.clk);
      end else begin
        while(~(this.axis.tready&this.axis.tvalid&this.axis.tlast)) begin
          if (this.axis.tready&this.axis.tvalid) begin
            if (is_hdr) begin
              unflatten_chdr_no_ts(this.axis.tdata, hdr);
              is_time = hdr.has_time;
              is_hdr = 0;
            end else if (is_time) begin
              hdr.timestamp = this.axis.tdata;
              is_time = 0;
            end else begin
              wait_for_pkt_get_info_update(stats, this.axis);
            end
          end
          @(posedge this.axis.clk);
        end
        wait_for_pkt_get_info_update(stats, this.axis);
        @(negedge this.axis.clk);
      end
    end
  endtask

  // Pull a packet from the AXI Stream bus.
  // Args:
  // - pkt: Packet data (queue)
  task automatic pull_pkt;
    output cvita_pkt_t pkt;
    begin
      logic [63:0] word;
      logic eop = 0;

      while(~eop) begin
        this.pull_word(word,eop);
        pkt.push_back(word);
      end
    end
  endtask

  // Pull a packet from the AXI Stream bus and
  // drop it instead of passing data to the user.
  // Args: None
  task automatic drop_pkt;
    begin
      cvita_pkt_t pkt;
      this.pull_pkt(pkt);
    end
  endtask

endclass


class cvita_bus #(parameter DWIDTH = 64);

  cvita_master #(.DWIDTH(DWIDTH)) m_cvita;
  cvita_slave #(.DWIDTH(DWIDTH)) s_cvita;

  function new(virtual axis_t #(.DWIDTH(DWIDTH)) m_axis, virtual axis_t #(.DWIDTH(DWIDTH)) s_axis);
    this.m_cvita = new(m_axis);
    this.s_cvita = new(s_axis);
  endfunction

  task automatic push_word;
    input logic [DWIDTH-1:0] word;
    input logic eop;
    begin
      this.m_cvita.push_word(word, eop);
    end
  endtask

  task automatic push_bubble;
    begin
      this.m_cvita.push_bubble();
    end
  endtask

  task automatic push_hdr;
    input cvita_hdr_t hdr;
    this.m_cvita.push_hdr(hdr);
  endtask

  task automatic push_rand_pkt;
    input integer       num_samps;
    input cvita_hdr_t   hdr;
    begin
      this.m_cvita.push_rand_pkt(num_samps,hdr);
    end
  endtask

  // Push a packet with a ramp on to the AXI Stream bus
  // Args:
  // - num_samps: Packet size.
  // - ramp_start: Start value for the ramp
  // - ramp_inc: Increment per clock cycle
  // - hdr: Header to attach to packet (length will be ignored)
  // - timestamp: Optional timestamp
  task automatic push_ramp_pkt;
    input integer       num_samps;
    input logic [63:0]  ramp_start;
    input logic [63:0]  ramp_inc;
    input cvita_hdr_t   hdr;
    begin
      this.m_cvita.push_ramp_pkt(num_samps,ramp_start,ramp_inc,hdr);
    end
  endtask

  task automatic push_pkt;
    input cvita_pkt_t pkt;
    begin
      this.m_cvita.push_pkt(pkt);
    end
  endtask

  task automatic pull_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      this.s_cvita.pull_word(word, eop);
    end
  endtask

  task automatic copy_word;
    output logic [DWIDTH-1:0] word;
    output logic eop;
    begin
      this.s_cvita.copy_word(word, eop);
    end
  endtask

  task automatic wait_for_bubble;
    begin
      this.s_cvita.wait_for_bubble();
    end
  endtask

  task automatic wait_for_pkt;
    begin
      this.s_cvita.wait_for_pkt();
    end
  endtask

  task automatic wait_for_pkt_get_info;
    output cvita_hdr_t    hdr;
    output cvita_stats_t  stats;
    begin
      this.s_cvita.wait_for_pkt_get_info(hdr,stats);
    end
  endtask

  task automatic pull_pkt;
    output cvita_pkt_t pkt;
    begin
      this.s_cvita.pull_pkt(pkt);
    end
  endtask

  task automatic drop_pkt;
    begin
      this.s_cvita.drop_pkt();
    end
  endtask

endclass
