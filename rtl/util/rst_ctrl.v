`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2023/03/29
// Design Name: Sync reset controller
// Module Name: rst_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Generate reset signal to properly initialize different modules
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rst_ctrl(
    input       src_clk,
    input       sys_clk,
    input       arstn,

    input       pll_locked,

    // output      rstn_pll,
    (*MAX_FANOUT=100*) output reg  rstn_sys,
    (*MAX_FANOUT=100*) output reg  rstn_mac,
    (*MAX_FANOUT=100*) output reg  rstn_phy
);

    localparam  RST_STATE_INIT = 1; // initial state, wait for PLL locked
    localparam  RST_STATE_WAIT = 2; // wait state
    localparam  RST_STATE_RSET = 4; // reset state, generate enough cycles for FIFOs to reset
    localparam  RST_STATE_IDLE = 8; // idle state, park here

    reg     [ 3:0]  rst_state, rst_state_next;
    reg             rst_sys_src, rst_mac_src, rst_phy_src;
    // reg     [ 3:0]  rst_pll_src;
    reg     [ 7:0]  rst_counter;

    // tri-seg state machine
    always @(*) begin
        case(rst_state)
            RST_STATE_INIT:
                rst_state_next = pll_locked ? RST_STATE_WAIT : RST_STATE_INIT;
            RST_STATE_WAIT:
                rst_state_next = (rst_counter[7]) ? RST_STATE_RSET : RST_STATE_WAIT;
            RST_STATE_RSET:
                rst_state_next = (!rst_counter[7]) ? RST_STATE_IDLE : RST_STATE_RSET;
            RST_STATE_IDLE:
                rst_state_next = RST_STATE_IDLE;
            default:
                rst_state_next = rst_state; 
        endcase
    end

    always @(posedge src_clk or negedge arstn) begin
        if (!arstn) begin
            rst_state       <=  RST_STATE_INIT;
        end
        else begin
            rst_state       <=  rst_state_next;
        end
    end

    always @(posedge src_clk or negedge arstn) begin
        if (!arstn) begin
            rst_counter     <=  'b0;
            // rst_pll_src     <=  'b0;
            rst_sys_src     <=  'b1;
            rst_mac_src     <=  'b1;
            rst_phy_src     <=  'b0;
        end
        else begin
            // rst_pll_src     <=  {rst_pll_src[2:0], 1'b1};
            if (rst_state == RST_STATE_WAIT) begin
                rst_counter     <=  rst_counter + 1'b1;
            end
            else if (rst_state == RST_STATE_RSET) begin
                rst_counter     <=  rst_counter + 1'b1;
                rst_sys_src     <=  'b0;
                rst_mac_src     <=  'b0;
                rst_phy_src     <=  'b1;
                // rst_sys_src     <=  'b1;
                // if (rst_counter[6]) begin
                //     rst_switch_src  <=  'b1;
                // end
            end
            else if (rst_state == RST_STATE_IDLE) begin
                rst_counter     <=  'b0;
                rst_sys_src     <=  'b1;
                rst_mac_src     <=  'b1;
                rst_phy_src     <=  'b1;
            end
        end
    end

    // assign  rstn_pll    =   rst_pll_src[3];

    // async reset, sync release
    always @(posedge sys_clk or negedge arstn) begin
        if (!arstn) begin
            rstn_sys    <=  'b0;
            rstn_mac    <=  'b0;
            rstn_phy    <=  'b0;
        end
        else begin
            rstn_sys    <=  rst_sys_src;
            rstn_mac    <=  rst_mac_src;
            rstn_phy    <=  rst_phy_src;
        end
    end

endmodule