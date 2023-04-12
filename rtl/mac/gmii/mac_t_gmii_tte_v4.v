`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: GMII TX interface, version 3
// Module Name: mac_t_gmii_tte_v3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Reworked again, ieee 1588 compatibility added
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Only 2 step clock support available now, need refinement
//////////////////////////////////////////////////////////////////////////////////

module mac_t_gmii_tte_v4(
    input           rstn_sys,       // async reset, system side
    input           rstn_mac,       // async reset, (g)mii side
    input           sys_clk,        // sys clk
    input           tx_clk,         // mii tx clk
    input           gtx_clk,        // gmii tx clk, 125MHz, External
    output          interface_clk,  // interface clk, drive output fifo
    output          gtx_dv,         // (g)mii tx valid
    output  [ 7:0]  gtx_d,          // (g)mii tx data

    input   [ 1:0]  speed,          // speed from mdio

    // normal dataflow
    output          data_fifo_rd,
    input   [ 7:0]  data_fifo_din,  // registered output, better timing
    input           data_fifo_empty,
    output reg      ptr_fifo_rd, 
    input   [15:0]  ptr_fifo_din,
    input           ptr_fifo_empty,
    // tte dataflow
    output          tdata_fifo_rd,
    input   [ 7:0]  tdata_fifo_din,
    input           tdata_fifo_empty,
    output reg      tptr_fifo_rd,
    input   [15:0]  tptr_fifo_din,
    input           tptr_fifo_empty,
    // 1588 interface
    input   [31:0]  counter_ns,         // current time
    output  [63:0]  counter_delay       // broadcast slave-master delay to rx port, update delay_resp
);

    localparam  MAC_TX_STATE_IDLE   =   1;  // idle state, wait for new packet
    localparam  MAC_TX_STATE_STA1   =   2;  // start state 1, read ptr
    localparam  MAC_TX_STATE_STA2   =   4;  // start state 2, process ptr
    localparam  MAC_TX_STATE_STA3   =   8;  // start state 3, wait until data arrive
    localparam  MAC_TX_STATE_STA4   =   16; // start state 4, wait until buffer is filled
    localparam  MAC_TX_STATE_PREA   =   32; // preamble state, not counting
    localparam  MAC_TX_STATE_DATA   =   64; // data state, count for data bytes
    localparam  MAC_TX_STATE_CRCV   =   128;// crc state, output crc value
    localparam  MAC_TX_STATE_WAIT   =   256;// wait state, comply with standard

    localparam  PTP_TX_STATE_IDLE   =   1;  // idle state, wait for ptp packet
    localparam  PTP_TX_STATE_TYPE   =   2;  // type state, check for ptp type
    localparam  PTP_TX_STATE_SYNC   =   4;  // sync state, update master-slave latency
    localparam  PTP_TX_STATE_DYRQ   =   8;  // delay_req state, update slave-master latency
    localparam  PTP_TX_STATE_FUP1   =   16; // follow_up state 1, wait for correctionField
    localparam  PTP_TX_STATE_FUP2   =   32; // follow_up state 2, update correctionField
    localparam  PTP_TX_STATE_FUP3   =   64; // follow_up state 3, replace data with new correctionField

    // no jitter clk switch
    reg     [ 1:0]  speed_reg;
    wire            speed_change;
    always @(posedge sys_clk or negedge rstn_sys) begin
        if (!rstn_sys) begin
            speed_reg   <=  2'b11;
        end
        else begin
            speed_reg   <=  speed;
        end
    end
    assign          speed_change =  |(speed ^ speed_reg);

    wire            tx_master_clk;
    reg             tx_clk_en_reg_p;
    reg             tx_clk_en_reg_n;
    reg             gtx_clk_en_reg_p;
    reg             gtx_clk_en_reg_n;

    always @(posedge tx_clk or posedge speed_change) begin
        if (speed_change) begin
            tx_clk_en_reg_p     <=  'b0;
        end
        else begin
            tx_clk_en_reg_p     <=  !speed[1] && !gtx_clk_en_reg_n;
        end
    end 
    always @(negedge tx_clk or posedge speed_change) begin
        if (speed_change) begin
            tx_clk_en_reg_n     <=  'b0;
        end
        else begin
            tx_clk_en_reg_n     <=  tx_clk_en_reg_p;
        end
    end

    always @(posedge gtx_clk or posedge speed_change) begin
        if (speed_change) begin
            gtx_clk_en_reg_p    <=  'b0;
        end
        else begin
            gtx_clk_en_reg_p    <=  speed[1] && !tx_clk_en_reg_n;
        end
    end  
    always @(negedge gtx_clk or negedge speed_change) begin
        if (speed_change) begin
            gtx_clk_en_reg_n    <=  'b0;
        end
        else begin
            gtx_clk_en_reg_n    <=  gtx_clk_en_reg_p;
        end
    end

    assign  tx_master_clk   =   (tx_clk_en_reg_n && tx_clk) || (gtx_clk_en_reg_n && gtx_clk);
    assign  interface_clk   =   tx_master_clk;

    reg     [15:0]  tx_state, tx_state_next;
    reg     [95:0]  tx_buffer;      // extended buffer for PTP operations
    reg     [47:0]  tx_buffer_cf;   // high 48 bit of correctionField

    reg             tx_arb_dir;
    reg     [10:0]  tx_cnt_front;   // frontend count
    reg     [10:0]  tx_cnt_back;    // backend count
    reg     [10:0]  tx_byte_cnt;    // total byte count
    reg     [ 1:0]  tx_byte_valid;
    reg             tx_read_req;    // generate read signal for 4-bit MII

    reg     [47:0]  ptp_delay_sync; // ingress-egress delay of sync
    reg     [47:0]  ptp_delay_req;  // ingress-egress delay of delay_req
    reg     [31:0]  ptp_time_ts;    // timestamp from packet
    reg     [31:0]  ptp_time_now;   // timestamp of now

    reg             crc_init;
    reg             crc_cal;
    reg             crc_dv;
    wire    [31:0]  crc_result;
    wire    [ 7:0]  crc_dout;

    wire    [ 7:0]  tx_data_in;
    wire    [15:0]  tx_ptr_in;
    assign          tx_data_in  =   tx_arb_dir ? tdata_fifo_din : data_fifo_din;
    assign          tx_ptr_in   =   tx_arb_dir ? tptr_fifo_din  : ptr_fifo_din;

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            ptr_fifo_rd     <=  'b0;
            tptr_fifo_rd    <=  'b0;
            crc_init        <=  'b0;
            crc_cal         <=  'b0;
            crc_dv          <=  'b0;
        end        
        else begin
            if (tx_state_next == 2) begin
                tx_arb_dir      <=  !tptr_fifo_empty;
                ptr_fifo_rd     <=  tptr_fifo_empty;
                tptr_fifo_rd    <=  !tptr_fifo_empty;
            end
            else if (tx_state_next == 4) begin
                ptr_fifo_rd     <=  'b0;
                tptr_fifo_rd    <=  'b0;
            end
            else if (tx_state_next == 8) begin
                tx_byte_cnt     <=  tx_ptr_in[10:0];
            end
            
        end
    end

    // always @(posedge tx_master_clk or negedge rstn_mac) begin
    //     if (!rstn_mac) begin
    //         tx_arb_dir  <=  'b0;
    //         tx_byte_cnt <=  'b0;
    //     end
    //     else begin
    //         if (tx_state_next == 2) begin
    //             tx_arb_dir  <=  tptr_fifo_empty;
    //         end
    //         else if (tx_state_next == 4) begin
    //             tx_byte_cnt <=  tx_ptr_in[10:0];
    //         end
    //     end
    // end

    // always @(*) begin
    //     if (tx_state == 2) begin
    //         ptr_fifo_rd     =   !tx_arb_dir;
    //         tptr_fifo_rd    =   tx_arb_dir;
    //     end
    //     else if (tx_state == 4) begin
            
    //     end
    // end

    reg     [15:0]  ptp_state, ptp_state_now;
    
    always @(*) begin
        case(ptp_state)
            PTP_TX_STATE_IDLE: begin

            end
            PTP_TX_STATE_TYPE: begin
                
            end
            PTP_TX_STATE_SYNC: begin
                
            end
            PTP_TX_STATE_DYRQ: begin
                
            end
            PTP_TX_STATE_FUP1: begin
                
            end
            PTP_TX_STATE_FUP2: begin
                
            end
            PTP_TX_STATE_FUP3: begin
                
            end
        endcase
    end

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            ptp_state   <=  PTP_TX_STATE_IDLE;
        end
        else begin
            ptp_state   <=  ptp_state_now;
        end
    end

    reg     [ 7:0]  mii_d;
    reg             mii_dv;

    wire    [ 7:0]  mii_d_in;
    assign          mii_d_in    =   (tx_state == MAC_TX_STATE_CRCV)     ?   crc_dout            :
                                    // (ptp_state == PTP_TX_STATE_FUP3)    ?   tx_buffer_cf[7:0]   :
                                    tx_buffer[7:0];

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            tx_buffer   <=  {8'hd5, {7{8'h55}}, {4{8'b0}}};
            tx_cnt_back <=  11'hFF9;
            tx_read_req <=  'b0;
            mii_d       <=  'b0;
            mii_dv      <=  'b0;
        end
        else begin  // initialize tx buffer
            if (tx_state == MAC_TX_STATE_STA4) begin
                tx_buffer   <=  {tx_data_in, tx_buffer[95:8]};
                mii_d       <=  'b0;
                mii_dv      <=  'b0;
            end     // send tx buffer
            else if (tx_state == MAC_TX_STATE_PREA || tx_state == MAC_TX_STATE_DATA || tx_state == MAC_TX_STATE_CRCV) begin
                if (speed[1] || tx_read_req) begin
                    tx_buffer   <=  {tx_data_in, tx_buffer[95:8]};
                    tx_cnt_back <=  tx_cnt_back + 1'b1;
                    mii_d       <=  mii_d_in;
                    mii_dv      <=  1'b1;
                    tx_read_req <=  1'b0;
                end
                else begin
                    mii_d       <=  mii_d >> 4;
                    mii_dv      <=  1'b1;
                    tx_read_req <=  1'b1;
                end
            end
            else begin
                tx_buffer   <=  {8'hd5, {7{8'h55}}, {4{8'b0}}};
                tx_cnt_back <=  11'hFF9;
                mii_d       <=  'b0;
                mii_dv      <=  'b0;
            end
        end
    end

    assign      gtx_d   =   mii_d;
    assign      gtx_dv  =   mii_dv;

    crc32_8023 u_crc32_8023(
        .clk(tx_master_clk), 
        .reset(!rstn_mac), 
        .d(mii_d_in), 
        .load_init(crc_init),
        .calc(crc_cal), 
        .d_valid(crc_dv), 
        .crc_reg(crc_result), 
        .crc(crc_dout)
    );

endmodule