`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2012 05:41:54 PM
// Design Name: 
// Module Name: master_slave_loopback_tester
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module master_slave_loopback_tester
#(
    parameter BASE_ADDR = 32'h40000000,
    parameter PROT = 3'b010 //data, non-secure, unpriv
)
(
    input clk,
    input rst,

    //GP0 write signals - slave
    input [31:0] GP0_AXI_AWADDR,
    input GP0_AXI_AWVALID,
    output GP0_AXI_AWREADY,
    input [31:0] GP0_AXI_WDATA,
    input [3:0] GP0_AXI_WSTRB,
    input GP0_AXI_WVALID,
    output GP0_AXI_WREADY,
    output [1:0] GP0_AXI_BRESP,
    output GP0_AXI_BVALID,
    input GP0_AXI_BREADY,

    //GP0 read signals - slave
    input [31:0] GP0_AXI_ARADDR,
    input GP0_AXI_ARVALID,
    output GP0_AXI_ARREADY,
    output [31:0] GP0_AXI_RDATA,
    output [1:0] GP0_AXI_RRESP,
    output GP0_AXI_RVALID,
    input GP0_AXI_RREADY,

    //HP0 write signals - master
    output [31:0] HP0_AXI_AWADDR,
    output [2:0] HP0_AXI_AWPROT,
    output HP0_AXI_AWVALID,
    input HP0_AXI_AWREADY,
    output [63:0] HP0_AXI_WDATA,
    output [3:0] HP0_AXI_WSTRB,
    output HP0_AXI_WVALID,
    input HP0_AXI_WREADY,
    input [1:0] HP0_AXI_BRESP,
    input HP0_AXI_BVALID,
    output HP0_AXI_BREADY,

    //HP0 read signals - master
    output [31:0] HP0_AXI_ARADDR,
    output [2:0] HP0_AXI_ARPROT,
    output HP0_AXI_ARVALID,
    input HP0_AXI_ARREADY,
    input [63:0] HP0_AXI_RDATA,
    input [1:0] HP0_AXI_RRESP,
    input HP0_AXI_RVALID,
    output HP0_AXI_RREADY,

    output [31:0] debug
    );


    reg [31:0] ddr_addr;
    reg [63:0] rd_ddr_data;
    reg [63:0] wr_ddr_data;

    //----------- a simple read state machine --------------//
    localparam RD_STATE_WAIT_GP0 = 0;
    localparam RD_STATE_ASSERT_GP0 = 1;
    localparam RD_STATE_READBACK_ADDR = 2;
    localparam RD_STATE_READ_DDR_ADDR = 3;
    localparam RD_STATE_READ_DDR_DATA = 4;
    localparam RD_STATE_READ_DATA = 5;

    reg [2:0] rd_state;
    always @(posedge clk) begin
        if (rst) begin
            rd_state <= RD_STATE_WAIT_GP0;
            rd_ddr_data <= 0;
        end
        else case (rd_state)
        RD_STATE_WAIT_GP0: begin
            if (GP0_AXI_ARVALID) begin
                rd_state <= RD_STATE_ASSERT_GP0;
            end
        end

        RD_STATE_ASSERT_GP0: begin
            if (GP0_AXI_ARVALID && GP0_AXI_ARREADY) begin
                if (GP0_AXI_ARADDR == BASE_ADDR) rd_state <= RD_STATE_READBACK_ADDR;
                else rd_state <= RD_STATE_READ_DDR_ADDR;
            end
        end

        RD_STATE_READBACK_ADDR: begin
            if (GP0_AXI_RVALID && GP0_AXI_RREADY) begin
                rd_state <= RD_STATE_WAIT_GP0;
            end
        end

        RD_STATE_READ_DDR_ADDR: begin
            if (HP0_AXI_ARVALID && HP0_AXI_ARREADY) begin
                rd_state <= RD_STATE_READ_DDR_DATA;
            end
        end

        RD_STATE_READ_DDR_DATA: begin
            if (HP0_AXI_RVALID && HP0_AXI_RREADY) begin
                rd_ddr_data <= HP0_AXI_RDATA;
                rd_state <= RD_STATE_READ_DATA;
            end
        end

        RD_STATE_READ_DATA: begin
            if (GP0_AXI_RVALID && GP0_AXI_RREADY) begin
                rd_state <= RD_STATE_WAIT_GP0;
            end
        end

        default: rd_state <= RD_STATE_WAIT_GP0;

        endcase //rd_state
    end

    //readback from the slave is either the address we wrote in, or the data from the DDR
    assign GP0_AXI_RDATA = (rd_state == RD_STATE_READBACK_ADDR)? ddr_addr : rd_ddr_data;
    //only acking address reads from the wait state
    assign GP0_AXI_ARREADY = (rd_state == RD_STATE_ASSERT_GP0);
    //when to release outputs from the slave
    assign GP0_AXI_RVALID = (rd_state == RD_STATE_READBACK_ADDR) || (rd_state == RD_STATE_READ_DATA);
    assign GP0_AXI_RRESP = 0;

    //the master read address always comes from the reg
    assign HP0_AXI_ARADDR = ddr_addr;
    assign HP0_AXI_ARVALID = (rd_state == RD_STATE_READ_DDR_ADDR);
    assign HP0_AXI_RREADY = (rd_state == RD_STATE_READ_DDR_DATA);
    assign HP0_AXI_ARPROT = PROT;

    //----------- a simple write state machine --------------//
    localparam WR_STATE_WAIT_GP0 = 0;
    localparam WR_STATE_SET_ADDR = 1;
    localparam WR_STATE_GET_DATA = 2;
    localparam WR_STATE_WRITE_ADDR = 3;
    localparam WR_STATE_WRITE_DATA = 4;
    localparam WR_STATE_WRITE_B = 5;

    reg [3:0] wstrb;

    reg [2:0] wr_state;
    always @(posedge clk) begin
        if (rst) begin
            wr_state <= WR_STATE_WAIT_GP0;
        end
        else case (wr_state)
        WR_STATE_WAIT_GP0: begin
            if (GP0_AXI_AWVALID && GP0_AXI_AWREADY) begin
                if (GP0_AXI_AWADDR == BASE_ADDR) wr_state <= WR_STATE_SET_ADDR;
                else wr_state <= WR_STATE_GET_DATA;
            end
        end

        WR_STATE_SET_ADDR: begin
            if (GP0_AXI_WVALID && GP0_AXI_WREADY) begin
                ddr_addr <= GP0_AXI_WDATA;
                wr_state <= WR_STATE_WAIT_GP0;
            end
        end

        WR_STATE_GET_DATA: begin
            if (GP0_AXI_WVALID && GP0_AXI_WREADY) begin
                wr_ddr_data <= GP0_AXI_WDATA;
                wstrb <= GP0_AXI_WSTRB;
                wr_state <= WR_STATE_WRITE_ADDR;
            end
        end

        WR_STATE_WRITE_ADDR: begin
            if (HP0_AXI_AWVALID && HP0_AXI_AWREADY) begin
                wr_state <= WR_STATE_WRITE_DATA;
            end
        end

        WR_STATE_WRITE_DATA: begin
            if (HP0_AXI_WVALID && HP0_AXI_WREADY) begin
                wr_state <= WR_STATE_WRITE_B;
            end
        end

        WR_STATE_WRITE_B: begin
            if (HP0_AXI_BREADY && HP0_AXI_BVALID) begin
                wr_state <= WR_STATE_WAIT_GP0;
            end
        end

        default: wr_state <= WR_STATE_WAIT_GP0;

        endcase //wr_state
    end

    //assign to slave write
    assign GP0_AXI_AWREADY = (wr_state == WR_STATE_WAIT_GP0);
    assign GP0_AXI_WREADY = (wr_state == WR_STATE_SET_ADDR) || (wr_state == WR_STATE_GET_DATA);
    assign GP0_AXI_BRESP = 0;
    assign GP0_AXI_BVALID = GP0_AXI_BREADY;

    //assign to master write
    assign HP0_AXI_AWVALID = (wr_state == WR_STATE_WRITE_ADDR);
    assign HP0_AXI_WVALID = (wr_state == WR_STATE_WRITE_DATA);
    assign HP0_AXI_AWADDR = ddr_addr;
    assign HP0_AXI_WDATA = wr_ddr_data;

    assign HP0_AXI_WSTRB = wstrb;
    assign HP0_AXI_AWPROT = PROT;
    assign HP0_AXI_BREADY = (wr_state == WR_STATE_WRITE_B);

endmodule
