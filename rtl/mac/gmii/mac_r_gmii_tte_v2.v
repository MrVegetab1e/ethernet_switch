`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: GMII RX interface, version 2
// Module Name: mac_r_gmii_tte_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Reworked rx interface, ieee 1588 compatibility added
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mac_r_gmii_tte (
    input           clk_sys,
    input           rstn_sys,
    input           rstn_mac,

    input           rx_clk,
    input           rx_dv,
    input   [ 7:0]  gm_rx_d,

    input   [ 1:0]  speed,  //ethernet speed 00:10M 01:100M 10:1000M

    input           data_fifo_rd,
    output  [ 7:0]  data_fifo_dout,
    input           ptr_fifo_rd,
    output  [15:0]  ptr_fifo_dout,
    output          ptr_fifo_empty,
    input           tte_fifo_rd,
    output  [ 7:0]  tte_fifo_dout,
    input           tteptr_fifo_rd,
    output  [15:0]  tteptr_fifo_dout,
    output          tteptr_fifo_empty,

    input   [31:0]  counter_ns,
    input   [63:0]  counter_ns_tx_delay,
    input   [63:0]  counter_ns_gtx_delay,

    output          rx_mgnt_valid,
    output  [19:0]  rx_mgnt_data,
    input           rx_mgnt_resp
);

    // general
    localparam  DELAY               =   2;
    localparam  CRC_RESULT_VALUE    =   32'hc704dd7b;
    parameter   TTE_VALUE_HI        =   8'h08;
    parameter   TTE_VALUE_LO        =   8'h92;
    parameter   MTU                 =   1500;
    // ptp
    localparam  PTP_VALUE_HI        =   8'h88;
    localparam  PTP_VALUE_LO        =   8'hf7;
    localparam  PTP_TYPE_SYNC       =   4'h0;   // MsgType Sync
    localparam  PTP_TYPE_DYRQ       =   4'h1;   // MsgType Delay_Req
    localparam  PTP_TYPE_FLUP       =   4'h8;   // MsgType Follow_Up
    localparam  PTP_TYPE_DYRP       =   4'h9;   // MsgType Delay_Resp
    // lldp
    parameter   LLDP_VALUE_HI       =   8'h08;
    parameter   LLDP_VALUE_LO       =   8'h01;
    parameter   LLDP_DBG_PROTO      =   16'h0800;
    parameter   LLDP_DBG_MAC        =   48'h020000123456;
    parameter   LLDP_DBG_PORT       =   16'h8;

    localparam  PTP_RX_STATE_IDL1   =   1;  // idle state 1, wait for ptp packet
    localparam  PTP_RX_STATE_IDL2   =   2;  // idle state 2, wait for ptp packet
    localparam  PTP_RX_STATE_TYPE   =   4;  // type state, check for ptp type
    localparam  PTP_RX_STATE_SYNC   =   8;  // sync state, inject internal timestamp
    localparam  PTP_RX_STATE_DYRQ   =   16; // delay_req state, inject internal timestamp
    localparam  PTP_RX_STATE_DRP1   =   32; // delay_resp state 1, wait for correctionField
    localparam  PTP_RX_STATE_DRP2   =   64; // delay_resp state 2, update correctionField
    localparam  PTP_RX_STATE_DRP3   =   128;// delay_resp state 3, replace data with new correctionField

    reg     [15:0]  rx_state, rx_state_next;
    reg     [127:0] rx_buffer;
    reg     [ 7:0]  rx_buf_byte;
    reg     [ 7:0]  rx_buf_byte_1;
    reg     [ 1:0]  rx_buf_valid;
    reg             rx_buf_valid_1;

    reg     [ 1:0]  rx_arb_dir;
    reg     [11:0]  rx_cnt_front;
    reg     [11:0]  rx_cnt_back;
    reg     [11:0]  rx_byte_cnt;

    reg     [15:0]  lldp_state, lldp_state_next;

    reg             data_fifo_wr;
    reg     [ 7:0]  data_fifo_din;
    wire    [11:0]  data_fifo_depth;
    reg             ptr_fifo_wr;
    reg     [15:0]  ptr_fifo_din;
    wire            ptr_fifo_full;
    reg             tte_fifo_wr;
    reg     [ 7:0]  tte_fifo_din;
    wire    [11:0]  tte_fifo_depth;
    reg             tteptr_fifo_wr;
    reg     [15:0]  tteptr_fifo_din;
    wire            tteptr_fifo_full;

    reg     [15:0]  ptp_state, ptp_state_next;
    reg     [47:0]  ptp_cf;             // updated correctionField
    wire            ptp_carry;
    wire            ptp_carry_1;
    reg             ptp_carry_reg;
    reg             ptp_carry_reg_1;
    wire    [ 7:0]  ptp_cf_add;
    wire    [ 7:0]  ptp_cf_add_1;
    reg     [31:0]  ptp_time_now;       // timestamp of now
    reg     [31:0]  ptp_time_now_sys;   // timestamp of now, system side
    reg             ptp_time_req;       // lockup counter output for cross clk domain
    reg     [ 1:0]  ptp_time_req_mac;
    reg     [ 1:0]  ptp_time_rdy_sys;   // system side of lockup signal
    reg     [ 1:0]  ptp_time_rdy_mac;   // mac side of lockup signal

    reg             crc_init;
    reg             crc_cal;
    reg             crc_dv;
    wire    [31:0]  crc_result;
    wire    [ 7:0]  crc_dout;


    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            rx_buf_byte     <=  'b0;
            rx_buf_valid    <=  'b0;
        end
        else begin
            if (speed[1]) begin
                rx_buf_byte     <=  gm_rx_d;
                rx_buf_valid    <=  {2{rx_dv}};
            end
            else begin
                rx_buf_byte     <=  {gm_rx_d[3:0], rx_buf_byte[7:4]};
                rx_buf_valid    <=  {rx_buf_valid[0], rx_dv && !rx_buf_valid[0]};
            end
            rx_buf_byte_1   <=  rx_buf_byte;
            rx_buf_valid_1  <=  rx_buf_valid[1];
        end
    end

    always @(*) begin
        case(rx_state)
            01: begin
                if (rx_buf_valid_1 && rx_buf_byte_1 == 8'hd5) begin
                    rx_state_next   =   2;
                end
                else begin
                    rx_state_next   =   1;
                end
            end
            02: begin
                if (rx_buf_valid == 2'b0) begin
                    rx_state_next   =   1;
                end
                else if (rx_cnt_front == 12'hF && rx_buf_valid_1) begin
                    rx_state_next   =   4;
                end
                else begin
                    rx_state_next   =   2;
                end
            end
            04: begin
                if (rx_buf_valid == 2'b0 || rx_cnt_front == MTU) begin
                    rx_state_next   =   8;
                end
                else begin
                    rx_state_next   =   4;
                end
            end
            08: begin
                rx_state_next   =   1;
            end
            default: rx_state_next  =   rx_state;
        endcase
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            rx_state    <=  1;
        end
        else begin
            rx_state    <=  rx_state_next;
        end
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            rx_cnt_front    <=  'b1;
        end
        else begin
            if (rx_state == 1) begin
                rx_cnt_front    <=  'b1;
            end
            else if (rx_buf_valid_1) begin
                rx_cnt_front    <=  rx_cnt_front + 1'b1;
            end
        end
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            crc_init    <=  'b0;
            crc_cal     <=  'b0;
            crc_dv      <=  'b0;
        end
        else begin
            if (rx_state_next[0]) begin
                crc_init    <=  'b1;
                crc_cal     <=  'b0;
                crc_dv      <=  'b0;
            end
            else if (rx_state_next[1] || rx_state_next[2]) begin
                crc_init    <=  'b0;
                crc_cal     <=  'b1;
                crc_dv      <=  'b1;
            end
            else if (rx_state_next[3]) begin
                crc_init    <=  'b0;
                crc_cal     <=  'b1;
                crc_dv      <=  'b0;
            end
        end
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            rx_buffer       <=  'b0;
            rx_arb_dir      <=  'b0;
        end
        else begin
            if (rx_buf_valid_1) begin
                rx_buffer   <=  {rx_buffer, rx_buf_byte_1};
            end
            if (rx_cnt_front == 'hD && rx_buf_valid_1) begin
                if (rx_buf_byte_1 == TTE_VALUE_HI) begin
                    rx_arb_dir[1]   <=  'b1;
                end
                else begin
                    rx_arb_dir[1]   <=  'b0;
                end
            end
            if (rx_cnt_front == 'hE && rx_buf_valid_1) begin
                if (rx_buf_byte_1 == TTE_VALUE_LO) begin
                    rx_arb_dir[0]   <=  'b1;
                end
                else begin
                    rx_arb_dir[0]   <=  'b0;
                end
            end
        end
    end

    always @(*) begin
        case(ptp_state)
            PTP_RX_STATE_IDL1: begin
                if (rx_cnt_front == 'hD && rx_buf_byte_1 == PTP_VALUE_HI)
                    ptp_state_next  =   PTP_RX_STATE_IDL2;
                else
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
            end
            PTP_RX_STATE_IDL2: begin
                if (rx_cnt_front == 'hE && rx_buf_byte_1 == PTP_VALUE_LO)
                    ptp_state_next  =   PTP_RX_STATE_TYPE;
                else
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
            end
            PTP_RX_STATE_TYPE: begin
                if (rx_cnt_front == 'hF && rx_buf_byte_1[3:0] == PTP_TYPE_SYNC)
                    ptp_state_next  =   PTP_RX_STATE_SYNC;
                else if (rx_cnt_front == 'hF && rx_buf_byte_1[3:0] == PTP_TYPE_DYRQ)
                    ptp_state_next  =   PTP_RX_STATE_DYRQ;
                else if (rx_cnt_front == 'hF && rx_buf_byte_1[3:0] == PTP_TYPE_DYRP)
                    ptp_state_next  =   PTP_RX_STATE_DRP1;              
                else
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
            end
            PTP_RX_STATE_SYNC: begin
                if (rx_cnt_front == 'd46)
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
                else
                    ptp_state_next  =   PTP_RX_STATE_SYNC;
            end
            PTP_RX_STATE_DYRQ: begin
                if (rx_cnt_front == 'd46)
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
                else
                    ptp_state_next  =   PTP_RX_STATE_DYRQ;
            end
            PTP_RX_STATE_DRP1: begin
                if (rx_cnt_front == 'd28)
                    ptp_state_next  =   PTP_RX_STATE_DRP2;
                else
                    ptp_state_next  =   PTP_RX_STATE_DRP1;
            end
            PTP_RX_STATE_DRP2: begin
                if (rx_cnt_front == 'd40)
                    ptp_state_next  =   PTP_RX_STATE_DRP3;
                else
                    ptp_state_next  =   PTP_RX_STATE_DRP2;
            end
            PTP_RX_STATE_DRP3: begin
                if (rx_cnt_front == 'd46)
                    ptp_state_next  =   PTP_RX_STATE_IDL1;
                else
                    ptp_state_next  =   PTP_RX_STATE_DRP3;
            end
        endcase
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            ptp_state   <=  1;
        end
        else begin
            ptp_state   <=  ptp_state_next;
        end
    end

    always @(posedge rx_clk) begin
        
    end

    crc32_8023 u_crc32_8023(
        .clk(rx_clk),
        .reset(!rstn_mac), 
        .d(rx_buf_byte_1), 
        .load_init(crc_init),
        .calc(crc_cal), 
        .d_valid(crc_dv), 
        .crc_reg(crc_result), 
        .crc(crc_dout)
    );

    always @(posedge rx_clk) begin
        if (!rstn_mac) begin
            data_fifo_wr    <=  'b0;
            data_fifo_din   <=  'b0;
            ptr_fifo_wr     <=  'b0;
            ptr_fifo_din    <=  'b0;
            tte_fifo_wr     <=  'b0;
            tte_fifo_din    <=  'b0;
            tteptr_fifo_wr  <=  'b0;
            tteptr_fifo_din <=  'b0;
        end
        else begin

        end
    end

    //============================================  
    //fifo used. 
    //============================================  

    (*MARK_DEBUG="true"*) wire dbg_data_empty;

    afifo_w8_d4k u_data_fifo (
        .rst          (!rstn_sys),          // input rst
        .wr_clk       (rx_clk),             // input wr_clk
        .rd_clk       (clk),                // input rd_clk
        .din          (data_fifo_din),      // input [7 : 0] din
        .wr_en        (data_fifo_wr),       // input wr_en
        .rd_en        (data_fifo_rd),       // input rd_en
        .dout         (data_fifo_dout),     // output [7 : 0]       
        .full         (),
        .empty        (dbg_data_empty),
        .rd_data_count(),                   // output [11 : 0] rd_data_count
        .wr_data_count(data_fifo_depth)     // output [11 : 0] wr_data_count
    );

    afifo_w16_d32 u_ptr_fifo (
        .rst   (!rstn_sys),      // input rst
        .wr_clk(rx_clk),         // input wr_clk
        .rd_clk(clk),            // input rd_clk
        .din   (ptr_fifo_din),   // input [15 : 0] din
        .wr_en (ptr_fifo_wr),    // input wr_en
        .rd_en (ptr_fifo_rd),    // input rd_en
        .dout  (ptr_fifo_dout),  // output [15 : 0] dout
        .full  (ptr_fifo_full),  // output full
        .empty (ptr_fifo_empty)  // output empty
    );
    afifo_w8_d4k u_tte_fifo (
        .rst          (!rstn_sys),       // input rst
        .wr_clk       (rx_clk),          // input wr_clk
        .rd_clk       (clk),             // input rd_clk
        .din          (tte_fifo_din),    // input [7 : 0] din
        .wr_en        (tte_fifo_wr),     // input wr_en
        .rd_en        (tte_fifo_rd),     // input rd_en
        .dout         (tte_fifo_dout),   // output [7 : 0]       
        .full         (),
        .empty        (),
        .rd_data_count(),                // output [11 : 0] rd_data_count
        .wr_data_count(tte_fifo_depth)   // output [11 : 0] wr_data_count
    );

    afifo_w16_d32 u_tteptr_fifo (
        .rst   (!rstn_sys),         // input rst
        .wr_clk(rx_clk),            // input wr_clk
        .rd_clk(clk),               // input rd_clk
        .din   (tteptr_fifo_din),   // input [15 : 0] din
        .wr_en (tteptr_fifo_wr),    // input wr_en
        .rd_en (tteptr_fifo_rd),    // input rd_en
        .dout  (tteptr_fifo_dout),  // output [15 : 0] dout
        .full  (tteptr_fifo_full),  // output full
        .empty (tteptr_fifo_empty)  // output empty
    );
endmodule
