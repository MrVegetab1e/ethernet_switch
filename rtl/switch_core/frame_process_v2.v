`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 22:00:40
// Design Name: 
// Module Name: tteframe_process_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 1.00 - Timing Optimization
// Revision 2.00 - Reworked
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module frame_process_v2 (
    input              clk,
    input              rstn,
    output reg         sfifo_rd,
    input       [ 7:0] sfifo_dout,
    output reg         ptr_sfifo_rd,
    input       [15:0] ptr_sfifo_dout,
    input              ptr_sfifo_empty,

    output reg  [47:0] se_mac,
    output reg  [15:0] source_portmap,
    output reg  [ 9:0] se_hash,
    output reg         se_source,
    output reg         se_req,
    input              se_ack,
    input              se_nak,
    input       [15:0] se_result,
    input       [ 3:0] link,

    output reg         sof,
    output reg         dv,
    output reg  [ 7:0] data
);

    reg     [ 15:0]     frp_state, frp_state_next;
    reg     [112:0]     frp_buf;
    reg     [ 16:0]     frp_header;
    reg     [ 10:0]     frp_cnt_front;
    reg     [ 10:0]     frp_cnt_back;
    reg     [ 10:0]     frp_len;
    reg     [ 10:0]     frp_len_pad;
    reg     [  1:0]     frp_wr_en;

    always @(*) begin
        case(frp_state)
            01: frp_state_next  =   (ptr_sfifo_empty) ? 2 : 1;              // idle
            02: frp_state_next  =   4;                                      // read ptr
            04: frp_state_next  =   8;
            08: frp_state_next  =   (frp_cnt_front == 12'hC) ? 16 : 8;       // read mac
            // 08: frp_state_next  =   (se_ack || se_nak) ? 16 : 8;            // req for dst mac
            // 16: frp_state_next  =   (se_ack || se_nak) ? 16 : 8;         // req for src mac
            16: frp_state_next  =   (frp_cnt_back == frp_len) ? 32 : 16;
            32: frp_state_next  =   (frp_cnt_back == frp_len_pad) ? 1 : 32; // transfer data and padding
            default: frp_state_next  =  frp_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            frp_state   <=  1;
        end
        else begin
            frp_state   <=  frp_state_next;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            // frp_buf         <=  'b0;
            frp_cnt_front   <=  'b1;
            frp_cnt_back    <=  'b1;
            frp_len         <=  'b0;
            frp_len_pad     <=  'b0;
            frp_wr_en       <=  'b0;
        end
        else begin
            if (sfifo_rd) begin
                frp_cnt_front   <=  frp_cnt_front + 1'b1;
            end
            else begin
                frp_cnt_front   <=  'b1;
            end
            if (frp_wr_en[1]) begin
                frp_cnt_back    <=  'b0;
            end
            else begin
                frp_cnt_back    <=  'hFF3;
            end
            if (frp_state[2]) begin
                frp_len             <=  ptr_sfifo_dout[10:0];
                frp_len_pad[10:6]   <=  (ptr_sfifo_dout[5:0] == 'b0) ? 
                                        ptr_sfifo_dout[10:6] : 
                                        ptr_sfifo_dout[10:6] + 1'b1;
            end
            frp_buf     <=  {frp_buf, sfifo_dout};  
            frp_wr_en   <=  {frp_wr_en, sfifo_rd};
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sfifo_rd        <=  0;
            ptr_sfifo_rd    <=  0;
            sof             <=  0;
            dv              <=  0;
            data            <=  0;
        end
        else begin
            if (frp_state_next[1]) begin
                ptr_sfifo_rd    <=  'b1;
            end
            else begin
                ptr_sfifo_rd    <=  'b0;
            end
            if (frp_state_next[1]) begin
                sfifo_rd        <=  'b1;
            end
            else if (frp_cnt_front == frp_len) begin
                sfifo_rd        <=  'b0;
            end
            if (frp_cnt_back == 'hFFF) begin
                dv              <=  'b1;
            end
            else if (frp_cnt_back == frp_len_pad) begin
                dv              <=  'b0;
            end
            if (frp_cnt_back == 'hFFF) begin
                sof             <=  'b1;
            end
            else if (frp_cnt_back == 'h000) begin
                sof             <=  'b0;
            end
            if (frp_cnt_back == 'hFFF) begin
                data            <=  frp_header[16:8];
            end
            else if (frp_cnt_back == 'h000) begin
                data            <=  frp_header[7:0];
            end
            else begin
                data            <=  frp_buf[112:105];
            end
            // else if (frp_state[4]) begin
            //     data            <=  frp_buf[112:105];
            // else begin
            //     data            <=  'b0;
            // end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            se_mac          <=  0;
            source_portmap  <=  0;
            se_hash         <=  0;
            se_source       <=  0;
            se_req          <=  0;
        end
        else begin
            
        end
    end


endmodule
