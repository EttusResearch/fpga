//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_mgmt_pkt_handler
// Description:
//   This module sits inline on a CHDR stream and adds a management
//   node that is discoverable and configurable by software. As a 
//   management node, a control-port master to configure any slave.
//   The output CHDR stream has an additional tdest and tid which can
//   be used to make routing decisions for management packets only.
//   tid will be high when tdest should be used.
//
// Parameters:
//   - PROTOVER: RFNoC protocol version {8'd<major>, 8'd<minor>}
//   - CHDR_W: Widht of the CHDR bus in bits
//   - NODE_INFO: Info about the node that contains this management slave
//   - RESP_FIFO_SIZE: Log2 of the depth of the response FIFO
//                     Maximum value = 8
//
// Signals:
//   - s_axis_chdr_* : Input CHDR stream (AXI-Stream)
//   - m_axis_chdr_* : Output CHDR stream (AXI-Stream)
//   - ctrlport_* : Control-port master  

module chdr_mgmt_pkt_handler #(
  parameter [15:0] PROTOVER       = {8'd1, 8'd0},
  parameter        CHDR_W         = 256,
  parameter [47:0] NODE_INFO      = 48'd0,
  parameter        RESP_FIFO_SIZE = 5
)(
  // Clock, reset and settings
  input  wire              clk,
  input  wire              rst,
  // CHDR Data In (AXI-Stream)
  input  wire [CHDR_W-1:0] s_axis_chdr_tdata,
  input  wire              s_axis_chdr_tlast,
  input  wire              s_axis_chdr_tvalid,
  output wire              s_axis_chdr_tready,
  // CHDR Data Out (AXI-Stream)             
  output wire [CHDR_W-1:0] m_axis_chdr_tdata,
  output wire [1:0]        m_axis_chdr_tid,      // Routing mode. Valued defined in rfnoc_chdr_internal_utils.vh
  output wire [9:0]        m_axis_chdr_tdest,    // Manual routing destination (only valid for tid = CHDR_MGMT_ROUTE_TDEST)
  output wire              m_axis_chdr_tlast,
  output wire              m_axis_chdr_tvalid,
  input  wire              m_axis_chdr_tready,
  // Control port endpoint
  output wire              ctrlport_req_wr,
  output wire              ctrlport_req_rd,
  output wire [15:0]       ctrlport_req_addr,
  output wire [31:0]       ctrlport_req_data,
  input  wire              ctrlport_resp_ack,
  input  wire [31:0]       ctrlport_resp_data,
  // Operation strobe
  output wire              op_stb,
  output wire [15:0]       op_dst_epid,
  output wire [15:0]       op_src_epid
);

  // ---------------------------------------------------
  //  RFNoC Includes
  // ---------------------------------------------------
  `include "rfnoc_chdr_utils.vh"
  `include "rfnoc_chdr_internal_utils.vh"

  // ---------------------------------------------------
  //  Instantiate input demux and output mux to allow
  //  non-management packets to be bypassed
  // ---------------------------------------------------

  localparam CHDR_W_BYTES = CHDR_W / 8;
  parameter  LOG2_CHDR_W_BYTES = $clog2(CHDR_W_BYTES);

  wire [CHDR_W-1:0] s_mgmt_tdata, m_mgmt_tdata, bypass_tdata;
  wire [9:0]        m_mgmt_tdest, bypass_tdest;
  wire [1:0]        m_mgmt_tid, bypass_tid;
  wire              s_mgmt_tlast, s_mgmt_tvalid, s_mgmt_tready;
  wire              m_mgmt_tlast, m_mgmt_tvalid, m_mgmt_tready;
  wire              bypass_tlast, bypass_tvalid, bypass_tready;
  wire [CHDR_W-1:0] s_header;

  axi_demux #(
    .WIDTH(CHDR_W), .SIZE(2), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0)
  ) mgmt_demux_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .header(s_header), .dest(chdr_get_pkt_type(s_header[63:0]) == CHDR_PKT_TYPE_MGMT),
    .i_tdata(s_axis_chdr_tdata), .i_tlast(s_axis_chdr_tlast),
    .i_tvalid(s_axis_chdr_tvalid), .i_tready(s_axis_chdr_tready),
    .o_tdata({s_mgmt_tdata, bypass_tdata}), .o_tlast({s_mgmt_tlast, bypass_tlast}),
    .o_tvalid({s_mgmt_tvalid, bypass_tvalid}), .o_tready({s_mgmt_tready, bypass_tready})
  );
  assign {bypass_tid, bypass_tdest} = {CHDR_MGMT_ROUTE_EPID, 10'h0};

  axi_mux #(
    .WIDTH(CHDR_W+10+2), .SIZE(2), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1)
  ) mgmt_mux_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({m_mgmt_tid, m_mgmt_tdest, m_mgmt_tdata, bypass_tid, bypass_tdest, bypass_tdata}),
    .i_tlast({m_mgmt_tlast, bypass_tlast}),
    .i_tvalid({m_mgmt_tvalid, bypass_tvalid}), .i_tready({m_mgmt_tready, bypass_tready}),
    .o_tdata({m_axis_chdr_tid, m_axis_chdr_tdest, m_axis_chdr_tdata}),
    .o_tlast(m_axis_chdr_tlast),
    .o_tvalid(m_axis_chdr_tvalid), .o_tready(m_axis_chdr_tready)
  );

  // ---------------------------------------------------
  //  Convert management packets to 64-bit
  //  For CHDR_W > 64, only the bottom 64 bits are used
  // ---------------------------------------------------
  wire [63:0] i64_tdata;
  wire        i64_tlast, i64_tvalid;
  reg         i64_tready;
  reg [63:0]  o64_tdata;
  reg [9:0]   o64_tdest;
  reg [1:0]   o64_tid;
  reg         o64_tlast, o64_tvalid;
  wire        o64_tready;

  axi_fifo #(.WIDTH(65), .SIZE(1)) in_flop_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({s_mgmt_tlast, s_mgmt_tdata[63:0]}),
    .i_tvalid(s_mgmt_tvalid), .i_tready(s_mgmt_tready),
    .o_tdata({i64_tlast, i64_tdata}),
    .o_tvalid(i64_tvalid), .o_tready(i64_tready),
    .space(), .occupied()
  );

  axi_fifo #(.WIDTH(64+10+2+1), .SIZE(1)) out_flop_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({o64_tlast, o64_tdest, o64_tid, o64_tdata}),
    .i_tvalid(o64_tvalid), .i_tready(o64_tready),
    .o_tdata({m_mgmt_tlast, m_mgmt_tdest, m_mgmt_tid, m_mgmt_tdata[63:0]}),
    .o_tvalid(m_mgmt_tvalid), .o_tready(m_mgmt_tready),
    .space(), .occupied()
  );

  generate 
    if (CHDR_W > 64)
      assign m_mgmt_tdata[CHDR_W-1:CHDR_W-64] = 'h0;
  endgenerate

  // ---------------------------------------------------
  //  Parse management packet
  // ---------------------------------------------------
  localparam [3:0] ST_CHDR_IN_HDR     = 4'd0;   // Consuming input CHDR header
  localparam [3:0] ST_CHDR_IN_MDATA   = 4'd1;   // Discarding input CHDR metadata
  localparam [3:0] ST_MGMT_IN_HDR     = 4'd2;   // Consuming input management header
  localparam [3:0] ST_MGMT_OP_EXEC    = 4'd3;   // Management operation started
  localparam [3:0] ST_MGMT_OP_WAIT    = 4'd4;   // Waiting for management op to finish
  localparam [3:0] ST_MGMT_OP_DONE    = 4'd5;   // Consuming management op line
  localparam [3:0] ST_CHDR_OUT_HDR    = 4'd6;   // Outputing a CHDR header
  localparam [3:0] ST_MGMT_OUT_HDR    = 4'd7;   // Outputing a managment header
  localparam [3:0] ST_PASS_PAYLOAD    = 4'd8;   // Passing payload for downstream hops
  localparam [3:0] ST_MOD_LAST_HOP    = 4'd9;   // Processing last hop
  localparam [3:0] ST_POP_RESPONSE    = 4'd10;  // Popping response from response FIFO
  localparam [3:0] ST_APPEND_LAST_HOP = 4'd11;  // Appending response to last hop
  localparam [3:0] ST_FAILSAFE_DROP   = 4'd12;  // Something went wrong. Flushing input.

  // Pieces of state maintained by this state machine
  reg [3:0]  pkt_state = ST_CHDR_IN_HDR;        // The state variable
  reg [6:0]  num_mdata;                         // Number of metadata lines in packet
  reg [63:0] cached_chdr_hdr, cached_mgmt_hdr;  // Cached copies of the CHDR and mgmt headers
  reg [15:0] stripped_len;                      // The new CHDR length after ops are stripped
  reg [9:0]  hops_remaining;                    // Number of hops remaining until pkt is consumed
  reg [7:0]  resp_op_code;                      // Opcode for the response
  reg [47:0] resp_op_payload;                   // Payload for the response

  // Shortcuts
  wire [7:0]  op_code = chdr_mgmt_get_op_code(i64_tdata);
  wire [47:0] op_payload = chdr_mgmt_get_op_payload(i64_tdata);

  // Inputs and outputs for the response FIFO
  wire [55:0] resp_i_tdata, resp_o_tdata;
  wire        resp_i_tvalid, resp_o_tvalid;
  wire [7:0]  num_resp_pending;

  // The massive state machine
  // -------------------------
  always @(posedge clk) begin
    if (rst) begin
      // We just need to initialize pkt_state here.
      // All other registers are initialized in states before their usage
      pkt_state <= ST_CHDR_IN_HDR;
    end else begin
      case (pkt_state)

        // ST_CHDR_IN_HDR
        // ------------------
        // - Cache and consume the CHDR header. It will be modified
        //   later before the packet is sent out.
        // - Initialize CHDR specific state
        ST_CHDR_IN_HDR: begin
          if (i64_tvalid && i64_tready) begin
            cached_chdr_hdr <= i64_tdata;
            stripped_len <= chdr_get_length(i64_tdata);
            num_mdata <= chdr_get_num_mdata(i64_tdata) - 7'd1;
            if (!i64_tlast)
              pkt_state <= (chdr_get_num_mdata(i64_tdata) == 7'd0) ? 
                ST_MGMT_IN_HDR : ST_CHDR_IN_MDATA;
            else
              pkt_state <= ST_CHDR_IN_HDR;  // Premature termination
          end
        end

        // ST_CHDR_IN_MDATA
        // ------------------
        // - Discard incoming CHDR metadata
        ST_CHDR_IN_MDATA: begin
          if (i64_tvalid && i64_tready) begin
            num_mdata <= num_mdata - 7'd1;
            if (!i64_tlast)
              pkt_state <= (num_mdata == 7'd0) ? ST_MGMT_IN_HDR : ST_CHDR_IN_MDATA;
            else
              pkt_state <= ST_CHDR_IN_HDR;  // Premature termination
          end
        end

        // ST_MGMT_IN_HDR
        // ------------------
        // - Cache and consume the managment header. It will be modified
        //   later before the packet is sent out.
        // - Initialize management specific state
        ST_MGMT_IN_HDR: begin
          if (i64_tvalid && i64_tready) begin
            cached_mgmt_hdr <= i64_tdata;
            hops_remaining <= chdr_mgmt_get_num_hops(i64_tdata);
            pkt_state <= (!i64_tlast) ? ST_MGMT_OP_EXEC : ST_CHDR_IN_HDR;
          end
        end

        // ST_MGMT_OP_EXEC
        // ------------------
        // - We are processing a management operation for this hop
        // - Launch the requested action be looking at the op_code
        ST_MGMT_OP_EXEC: begin
          if (i64_tvalid) begin
            // Assume that the packet is getting routed normally
            // unless some operation changes that
            o64_tid   <= CHDR_MGMT_ROUTE_EPID;
            o64_tdest <= 10'd0;
            case (op_code)
              // Operation: Do nothing
              CHDR_MGMT_OP_NOP: begin
                // No-op. Jump to the finish state
                pkt_state <= ST_MGMT_OP_DONE;
              end
              // Operation: Advertise this management packet to outside logic
              CHDR_MGMT_OP_ADVERTISE: begin
                // Pretty much a no-op. Jump to the finish state
                pkt_state <= ST_MGMT_OP_DONE;
              end
              // Operation: Select a destination (tdest and tid) for the output CHDR stream
              CHDR_MGMT_OP_SEL_DEST: begin
                o64_tid   <= CHDR_MGMT_ROUTE_TDEST;
                o64_tdest <= chdr_mgmt_sel_dest_get_tdest(op_payload);
                pkt_state <= ST_MGMT_OP_DONE;   // Single cycle op
              end
              // Operation: Return the packet to source (turn it around)
              CHDR_MGMT_OP_RETURN: begin
                o64_tid   <= CHDR_MGMT_RETURN_TO_SRC;
                pkt_state <= ST_MGMT_OP_DONE; // Single cycle op
              end
              // Operation: Handle a node information request.
              //            Send the info as a response
              CHDR_MGMT_OP_INFO_REQ: begin
                pkt_state <= ST_MGMT_OP_DONE; // Single cycle op
              end
              // Operation: Handle a node information response.
              //            Treat as a no-op because this is a slave
              CHDR_MGMT_OP_INFO_RESP: begin
                pkt_state <= ST_MGMT_OP_DONE;
              end
              // Operation: Post a write on the outgoing control-port
              CHDR_MGMT_OP_CFG_WR_REQ: begin
                // ctrlport_req_* signals are assigned below
                pkt_state <= ST_MGMT_OP_WAIT; // Wait until ACKed
              end
              // Operation: Post a read on the outgoing control-port
              CHDR_MGMT_OP_CFG_RD_REQ: begin
                // ctrlport_req_* signals are assigned below
                pkt_state <= ST_MGMT_OP_WAIT; // Wait until ACKed
              end
              // Operation: Handle a read response.
              //            Treat as a no-op because this is a slave
              CHDR_MGMT_OP_CFG_RD_RESP: begin
                pkt_state <= ST_MGMT_OP_DONE;
              end
              default: begin
                // We should never get here
                pkt_state <= ST_CHDR_IN_HDR;
              end
            endcase
          end
        end

        // ST_MGMT_OP_WAIT
        // ------------------
        // - A management operation has started. We are waiting for it to finish
        ST_MGMT_OP_WAIT: begin
          if (i64_tvalid) begin
            if (op_code == CHDR_MGMT_OP_CFG_WR_REQ ||
                op_code == CHDR_MGMT_OP_CFG_RD_REQ) begin
              // Wait for an control-port transaction to finish
              if (ctrlport_resp_ack) begin
                pkt_state <= ST_MGMT_OP_DONE;
              end
            end else begin
              // All other operations should not get here
              pkt_state <= ST_MGMT_OP_DONE;
            end
          end
        end

        // ST_MGMT_OP_DONE
        // ------------------
        // - The management operation has finished
        // - Consume a word on the input CHDR stream and update interal state
        ST_MGMT_OP_DONE: begin
          if (i64_tvalid && i64_tready) begin
            if (!i64_tlast) begin
              // We just consumed 8-bytes from the incoming packet
              stripped_len <= stripped_len - CHDR_W_BYTES;
              // Check if this was the last op for this hop. If so start
              // to output a packet, otherwise start the next op.
              if (chdr_mgmt_get_ops_pending(i64_tdata) == 8'd0) begin
                hops_remaining <= hops_remaining - 10'd1;
                pkt_state <= ST_CHDR_OUT_HDR;
              end else begin
                pkt_state <= ST_MGMT_OP_EXEC;
              end
            end else begin
              // Premature termination or this is the last operation
              // Either way, move back to the beginning of the next pkt
              pkt_state <= ST_CHDR_IN_HDR;
            end
          end
        end

        // ST_CHDR_OUT_HDR
        // ------------------
        // - We are outputing the CHDR header
        ST_CHDR_OUT_HDR: begin
          if (o64_tvalid && o64_tready)
            pkt_state <= ST_MGMT_OUT_HDR;
        end

        // ST_CHDR_OUT_HDR
        // ------------------
        // - We are outputing the management header
        ST_MGMT_OUT_HDR: begin
          if (o64_tvalid && o64_tready)
            if (resp_o_tvalid && (hops_remaining == 10'd1))
              pkt_state <= ST_MOD_LAST_HOP;   // Special state to append responses to last hod
            else
              pkt_state <= ST_PASS_PAYLOAD;   // Just pass the data as-is
        end

        // ST_PASS_PAYLOAD
        // ------------------
        // - We are passing the payload for the downstream hops as-is
        ST_PASS_PAYLOAD: begin
          if (o64_tvalid && o64_tready) begin
            if (!i64_tlast) begin
              // Check if this was the last op for this hop. If so update
              // the hop count. If this is the last hop then enter the next
              // state to process it. We might need to append responses for our
              // management operations.
              if (chdr_mgmt_get_ops_pending(i64_tdata) == 8'd0) begin
                hops_remaining <= hops_remaining - 10'd1;
                if (resp_o_tvalid && (hops_remaining == 10'd1))
                  pkt_state <= ST_MOD_LAST_HOP;   // Special state to append responses to last hod
                else
                  pkt_state <= ST_PASS_PAYLOAD;   // Just pass the data as-is
              end else begin
                pkt_state <= ST_PASS_PAYLOAD;
              end
            end else begin
              pkt_state <= ST_CHDR_IN_HDR;
            end
          end
        end

        // ST_MOD_LAST_HOP
        // ------------------
        // - We are processing the last hop. We need a special state because we
        //   need to update the "ops_pending" field if we have responses to tack
        //   on to the end of the hop.
        // - We continue to pass the input to the output while modifying ops_pending
        // - For the last op, we move to the APPEND state if we need to add responses
        ST_MOD_LAST_HOP: begin
          if (o64_tvalid && o64_tready) begin
              // Check if this was the last op for this hop.
            if (chdr_mgmt_get_ops_pending(i64_tdata) == 8'd0) begin
              if (resp_o_tvalid)
                pkt_state <= ST_POP_RESPONSE;  // We have pending responses
              else
                pkt_state <= i64_tlast ? ST_CHDR_IN_HDR : ST_FAILSAFE_DROP;
            end
          end
        end

        // ST_POP_RESPONSE
        // ------------------
        // - Pop a response word from the FIFO
        ST_POP_RESPONSE: begin
          if (resp_o_tvalid) begin
            resp_op_code <= resp_o_tdata[7:0];
            resp_op_payload <= resp_o_tdata[55:8];
            pkt_state <= ST_APPEND_LAST_HOP;
          end
        end

        // ST_APPEND_LAST_HOP
        // ------------------
        // - Append the popped response to the output packet here
        // - Keep doing so until the response FIFO is empty
        ST_APPEND_LAST_HOP: begin
          if (o64_tvalid && o64_tready)
            pkt_state <= resp_o_tvalid ? ST_POP_RESPONSE : ST_CHDR_IN_HDR;
        end

        // ST_FAILSAFE_DROP
        // ------------------
        // - Something went wrong. Discard the packet and re-arm the state machine
        ST_FAILSAFE_DROP: begin
          if (i64_tvalid && i64_tready)
            pkt_state <= i64_tlast ? ST_CHDR_IN_HDR : ST_FAILSAFE_DROP;
        end

        default: begin
          // We should never get here
          pkt_state <= ST_CHDR_IN_HDR;
        end
      endcase
    end
  end

  // Logic to determine when to consume a word from the input CHDR stream
  always @(*) begin
    case (pkt_state)
      ST_CHDR_IN_HDR:
        i64_tready = 1'b1;        // Unconditionally consume header
      ST_CHDR_IN_MDATA:
        i64_tready = 1'b1;        // Unconditionally discard header
      ST_MGMT_IN_HDR:
        i64_tready = 1'b1;        // Unconditionally consume header
      ST_MGMT_OP_DONE:
        i64_tready = 1'b1;        // Operation is done. Consume op-word
      ST_PASS_PAYLOAD:
        i64_tready = o64_tready;  // We are passing input -> output
      ST_MOD_LAST_HOP:
        i64_tready = o64_tready;  // We are passing input -> output
      ST_FAILSAFE_DROP:
        i64_tready = 1'b1;        // Unconditionally consume to drop
      default:
        i64_tready = 1'b0;        // Hold the input. We are processing it
    endcase
  end

  // Swap src/dst EPIDs if returning packet to source
  wire [15:0] o64_dst_epid = (o64_tid == CHDR_MGMT_RETURN_TO_SRC) ? 
    chdr_mgmt_get_src_epid(cached_mgmt_hdr) : chdr_get_dst_epid(cached_chdr_hdr);
  wire [15:0] o64_src_epid = (o64_tid == CHDR_MGMT_RETURN_TO_SRC) ? 
    chdr_get_dst_epid(cached_chdr_hdr) : chdr_mgmt_get_src_epid(cached_mgmt_hdr);

  // Logic to drive the output CHDR stream
  always @(*) begin
    case (pkt_state)
      ST_CHDR_OUT_HDR: begin
        // We are generating new data using cached values.
        // Output header = Input header with new length
        o64_tdata  = chdr_set_length(
          chdr_set_dst_epid(cached_chdr_hdr, o64_dst_epid), 
          (stripped_len + (num_resp_pending << LOG2_CHDR_W_BYTES)));
        o64_tvalid = 1'b1;
        o64_tlast  = 1'b0;
      end
      ST_MGMT_OUT_HDR: begin
        // We are generating new data using cached values.
        // Output header = Input header with new num_hops and some protocol info
        o64_tdata  = chdr_mgmt_build_hdr(PROTOVER, chdr_w_to_enum(CHDR_W), 
          chdr_mgmt_get_num_hops(cached_mgmt_hdr) - 10'd1, o64_src_epid);
        o64_tvalid = 1'b1;
        o64_tlast  = 1'b0;
      end
      ST_PASS_PAYLOAD: begin
        // Input -> Output without modification
        o64_tdata  = i64_tdata;
        o64_tvalid = i64_tvalid;
        o64_tlast  = i64_tlast;
      end
      ST_MOD_LAST_HOP: begin
        // Input -> Output but update the ops_pending field
        o64_tdata  = chdr_mgmt_build_op(chdr_mgmt_get_op_payload(i64_tdata),
          chdr_mgmt_get_op_code(i64_tdata),
          chdr_mgmt_get_ops_pending(i64_tdata) + num_resp_pending);
        o64_tvalid = i64_tvalid;
        o64_tlast  = i64_tlast && !resp_o_tvalid;
      end
      ST_APPEND_LAST_HOP: begin
        // We are generating new data using cached values.
        o64_tdata  = chdr_mgmt_build_op(resp_op_payload, resp_op_code, num_resp_pending);
        o64_tvalid = 1'b1;
        o64_tlast  = !resp_o_tvalid;
      end
      default: begin
        // We are processing something. Don't output
        o64_tdata  = 64'h0;
        o64_tvalid = 1'b0;
        o64_tlast  = 1'b0;
      end
    endcase
  end

  // CHDR_MGMT_OP_ADVERTISE
  // ----------------------
  assign op_stb      = i64_tvalid && (pkt_state == ST_MGMT_OP_DONE) &&
                       (op_code == CHDR_MGMT_OP_ADVERTISE);
  assign op_dst_epid = chdr_get_dst_epid(cached_chdr_hdr);
  assign op_src_epid = chdr_mgmt_get_src_epid(cached_mgmt_hdr);

  // CHDR_MGMT_OP_CFG_WR_REQ
  // CHDR_MGMT_OP_CFG_RD_REQ
  // -----------------------
  // The request is sent out in the ST_MGMT_OP_EXEC state and we wait for a response
  // in the ST_MGMT_OP_WAIT state
  assign ctrlport_req_wr   = i64_tvalid && (pkt_state == ST_MGMT_OP_EXEC) &&
                             (op_code == CHDR_MGMT_OP_CFG_WR_REQ);
  assign ctrlport_req_rd   = i64_tvalid && (pkt_state == ST_MGMT_OP_EXEC) &&
                             (op_code == CHDR_MGMT_OP_CFG_RD_REQ);
  assign ctrlport_req_addr = chdr_mgmt_cfg_reg_get_addr(op_payload);
  assign ctrlport_req_data = chdr_mgmt_cfg_reg_get_data(op_payload);

  // CHDR_MGMT_OP_CFG_RD_REQ
  // CHDR_MGMT_OP_INFO_REQ
  // -----------------------
  // Collect the response for these operations and push to the response FIFO
  assign resp_i_tvalid = i64_tvalid && (
    ((pkt_state == ST_MGMT_OP_WAIT) && (op_code == CHDR_MGMT_OP_CFG_RD_REQ) && ctrlport_resp_ack) ||
    ((pkt_state == ST_MGMT_OP_DONE) && (op_code == CHDR_MGMT_OP_INFO_REQ)));
  assign resp_i_tdata = (op_code == CHDR_MGMT_OP_CFG_RD_REQ) ?
    {ctrlport_resp_data, ctrlport_req_addr, CHDR_MGMT_OP_CFG_RD_RESP} : // Ctrlport response
    {NODE_INFO, CHDR_MGMT_OP_INFO_RESP};                                // NodeInfo

  // The response FIFO should be deep enough to store all the responses
  wire [15:0] resp_fifo_occ;
  axi_fifo #(.WIDTH(56), .SIZE(RESP_FIFO_SIZE)) resp_fifo_i (
    .clk(clk), .reset(rst), .clear(pkt_state == ST_CHDR_IN_HDR),
    .i_tdata(resp_i_tdata), .i_tvalid(resp_i_tvalid),
    .i_tready(/* Must be high. Responses will be dropped if FIFO is full */),
    .o_tdata(resp_o_tdata), .o_tvalid(resp_o_tvalid),
    .o_tready(resp_o_tvalid && (pkt_state == ST_POP_RESPONSE)),
    .space(), .occupied(resp_fifo_occ)
  );
  assign num_resp_pending = resp_fifo_occ[7:0];

endmodule // chdr_mgmt_pkt_handler
