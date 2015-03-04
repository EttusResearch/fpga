//
// Copyright 2015 Ettus Research LLC
//

`include "sim_axis_lib.sv"

typedef enum logic [1:0] {
  DATA=2'b00, FC=2'b01, CMD=2'b10, RESP=2'b11
} cvita_pkt_t;
  
typedef struct packed {
  logic [31:0]  sid;
  logic [15:0]  length;
  logic [11:0]  seqno;
  logic         eob;
  logic         has_time;
  cvita_pkt_t   pkt_type;
  logic [63:0]  timestamp;
} cvita_hdr_t;

function logic[63:0] flatten_chdr_no_ts(input cvita_hdr_t hdr);
  return {hdr.pkt_type, hdr.has_time, hdr.eob, hdr.seqno, hdr.length, hdr.sid};
endfunction

//TODO: This should be a function but it segfaults XSIM.
task automatic unflatten_chdr_no_ts;
  input logic[63:0] hdr_bits;
  output cvita_hdr_t hdr;
  begin
    hdr = '{
      pkt_type:cvita_pkt_t'(hdr_bits[63:62]), has_time:hdr_bits[61], eob:hdr_bits[60],
      seqno:hdr_bits[59:48], length:hdr_bits[47:32], sid:hdr_bits[31:0], timestamp:0  //Default timestamp
    };
  end
endtask

task automatic unflatten_chdr;
  input logic[63:0] hdr_bits;
  input logic[63:0] timestamp;
  output cvita_hdr_t hdr;
  begin
    hdr = '{
      pkt_type:cvita_pkt_t'(hdr_bits[63:62]), has_time:hdr_bits[61], eob:hdr_bits[60],
      seqno:hdr_bits[59:48], length:hdr_bits[47:32], sid:hdr_bits[31:0], timestamp:timestamp
    };
  end
endtask

function logic chdr_compare(input cvita_hdr_t a, input cvita_hdr_t b);
  return ((a.pkt_type == b.pkt_type) && (a.has_time == b.has_time) && (a.eob == b.eob) &&
          (a.seqno == b.seqno) && (a.length == b.length) && (a.sid == b.sid));
endfunction

typedef struct packed {
  logic [31:0]  count;
  logic [63:0]  sum;
  logic [63:0]  min;
  logic [63:0]  max;
  logic [63:0]  crc;
} cvita_stats_t;


interface cvita_stream_t (input clk);
  axis_t #(.DWIDTH(64)) axis (.clk(clk));

  // Push a CVITA header into the stream
  // Args:
  // - hdr: The header to push
  task automatic push_hdr;
    input cvita_hdr_t hdr;
    axis.push_word(flatten_chdr_no_ts(hdr), 0);
  endtask

  // Push a word onto the AXI-Stream bus and wait for it to transfer
  // Args:
  // - word: The data to push onto the bus
  // - eop (optional): End of packet (asserts tlast)
  task automatic push_data;
    input logic [63:0] word;
    input logic eop = 0;
    axis.push_word(word, eop);
  endtask
  
  // Push a bubble cycle on the AXI-Stream bus
  task automatic push_bubble;
    axis.push_bubble();
  endtask

  // Wait for a sample to be transferred on the AXI Stream
  // bus and return the data and last
  // Args:
  // - word: The data pulled from the bus
  // - eop: End of packet (tlast)
  task automatic pull_word;
    output logic [63:0] word;
    output logic eop;
    axis.pull_word(word, eop);
  endtask

  // Wait for a bubble cycle on the AXI Stream bus
  task automatic wait_for_bubble;
    axis.wait_for_bubble();
  endtask

  // Wait for a packet to show up on the bus
  task automatic wait_for_pkt_start;
    axis.wait_for_pkt_start();
  endtask

  // Wait for a packet to finish on the bus
  task automatic wait_for_pkt_end;
    axis.wait_for_pkt_end();
  endtask

  // Wait for a packet to finish on the bus
  task automatic wait_for_pkt_end_get_info;
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
      while(~(axis.tready&axis.tvalid&axis.tlast)) begin
        @(posedge clk);
        if (is_hdr) begin
          unflatten_chdr_no_ts(axis.tdata, hdr);
          is_time = hdr.has_time;
          is_hdr = 0;
        end else if (is_time) begin
          hdr.timestamp = axis.tdata;
          is_time = 0;
        end else begin
          stats.count = stats.count + 1;
          stats.sum   = stats.sum + axis.tdata;
          stats.crc   = stats.crc ^ axis.tdata;
          if (axis.tdata < stats.min) stats.min = axis.tdata;
          if (axis.tdata > stats.max) stats.max = axis.tdata;
        end
      end
      @(posedge clk);
    end
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
      push_hdr(tmp_hdr);
      if (hdr.has_time) push_data(hdr.timestamp, 0);

      repeat(num_samps-1) begin
        axis.push_word({$random,$random}, 0);
      end
      axis.push_word({$random,$random}, 1);
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
      push_hdr(tmp_hdr);
      if (hdr.has_time) push_data(hdr.timestamp, 0);

      repeat(num_samps-1) begin
        axis.push_word(ramp_start+(counter*ramp_inc), 0);
        counter = counter + 1;
      end
      axis.push_word(ramp_start+(counter*ramp_inc), 1);
    end
  endtask

endinterface