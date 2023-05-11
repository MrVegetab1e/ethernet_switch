`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 22:00:40
// Design Name: 
// Module Name: frame_process_v4
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
// Revision 3.00 - Enable back-to-back processing
// Revision 4.00 - Added support for LLDP
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module frame_process_v4 (
    input               clk,
    input               rstn,
    // frontend interface
    output reg          sfifo_rd,
    input       [ 7:0]  sfifo_dout,
    output reg          ptr_sfifo_rd,
    input       [15:0]  ptr_sfifo_dout,
    input               ptr_sfifo_empty,
    // backend interface
    output     [127:0]  i_cell_data_fifo_dout,
    output reg          i_cell_data_fifo_wr,
    output reg [ 15:0]  i_cell_ptr_fifo_dout,
    output reg          i_cell_ptr_fifo_wr,
    input               i_cell_bp,
    // flow table interface
    output reg  [47:0]  se_mac,
    output reg  [15:0]  source_portmap,
    output reg  [ 9:0]  se_hash,
    output reg          se_source,
    output reg          se_req,
    input               se_ack,
    input               se_nak,
    input       [15:0]  se_result,
    // mgnt interface
    input       [ 3:0]  link,
    input       [ 7:0]  speed

);

    parameter   FRP_DBG_LLDP_MAC    =   48'h020000123456;
    parameter   FRP_DBG_LLDP_PORT   =   4'b4;

    reg     [  4:0]     frp_fnt_state, frp_fnt_state_next;
    reg     [  1:0]     frp_bak_state, frp_bak_state_next;

    reg     [ 15:0]     lldp_state, lldp_state_next;

    reg     [127:0]     frp_buf;
    reg     [0:127]     frp_dout_buf;
    reg     [ 15:0]     frp_header;

    reg     [ 10:0]     frp_cnt_front;
    reg     [ 10:0]     frp_cnt_back;
    reg     [ 10:0]     frp_len;
    reg     [ 10:0]     frp_len_1;
    reg     [ 10:0]     frp_len_pad;
    reg     [ 10:0]     frp_len_back;
    reg     [ 10:0]     frp_len_back_pad;
    reg     [  1:0]     frp_wr_en;

    always @(*) begin
        case(frp_fnt_state)
            01: frp_fnt_state_next  =   (!ptr_sfifo_empty && !i_cell_bp) ? 2 : 1;
            02: frp_fnt_state_next  =   4;
            04: frp_fnt_state_next  =   8;
            08: frp_fnt_state_next  =  16;
            16: frp_fnt_state_next  =   (frp_cnt_front == frp_len) ? 1 : 16;
            default: frp_fnt_state_next =   frp_fnt_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            frp_fnt_state   <=  1;
        end
        else begin
            frp_fnt_state   <=  frp_fnt_state_next;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            // frp_buf         <=  'b0;
            // frp_cnt_front   <=  'b1;
            // frp_cnt_back    <=  'b1;
            frp_len         <=  'b0;
            frp_len_1       <=  'b0;
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
            if (frp_bak_state[1]) begin
                frp_cnt_back    <=  frp_cnt_back + 1'b1;
            end
            else begin
                frp_cnt_back    <=  'b1;
            end
            if (frp_fnt_state[2]) begin
                frp_len         <=  ptr_sfifo_dout[10:0];
                frp_len_1       <=  ptr_sfifo_dout[10:0] + 2;
            end
            if (frp_fnt_state[3]) begin
                frp_len_pad[10:4]   <=  (frp_len_1[3:0] == 'b0) ? frp_len_1[10:4] : frp_len_1[10:4] + 1'b1;
            end
            frp_buf     <=  {frp_buf, sfifo_dout};  
            frp_wr_en   <=  {frp_wr_en, sfifo_rd};
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sfifo_rd        <=  0;
            ptr_sfifo_rd    <=  0;
        end
        else begin
            if (frp_fnt_state_next[1]) begin
                ptr_sfifo_rd    <=  'b1;
            end
            else begin
                ptr_sfifo_rd    <=  'b0;
            end
            if (frp_fnt_state_next[3]) begin
                sfifo_rd        <=  'b1;
            end
            else if (frp_fnt_state_next[0]) begin
                sfifo_rd        <=  'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            se_mac          <=  'b0;
            se_hash         <=  'b0;
            se_source       <=  'b0;
            se_req          <=  'b0;
            source_portmap  <=  'b0;
            frp_header      <=  'b0;
        end
        else begin
            if (frp_fnt_state[2]) begin
                source_portmap  <=  {12'b0, ptr_sfifo_dout[14:11]};
            end
            if (frp_cnt_front == 'h9) begin
                se_mac          <=  frp_buf[47:0];
                se_hash         <=  frp_buf[ 9:0];
                se_source       <=  'b0;
            end
            else if (frp_cnt_front == 'hF) begin
                se_mac          <=  frp_buf[47:0];                
                se_hash         <=  frp_buf[ 9:0];
                se_source       <=  'b1;
            end
            if (frp_cnt_front == 'h9) begin
                se_req          <=  'b1;
            end
            else if (frp_cnt_front == 'hF) begin
                se_req          <=  'b1;
            end
            else begin
                se_req          <=  'b0;
            end
            if (frp_cnt_front == 'hF) begin
                frp_header      <=  {1'b0, frp_len_1[10:8], (se_result[ 3:0] & link), frp_len_1[7:0]};
            end
        end
    end

    always @(*) begin
        case(lldp_state)
            01: lldp_state_next =   (frp_cnt_front == 'hF && sfifo_dout == 'h08) ? 2 : 1;
            02: lldp_state_next =   sfifo_dout == 'h01 ? 4 : 1;
            04: lldp_state_next =   
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            lldp_state  <=  1;
        end
        else begin
            lldp_state  <=  lldp_state_next;
        end
    end

    always @(*) begin
        case(frp_bak_state)
            01: frp_bak_state_next  =   (frp_wr_en[1] && frp_cnt_front == 'h10) ? 2 : 1;
            02: frp_bak_state_next  =   (frp_cnt_back == frp_len_back) ? 1 : 2;
            default: frp_bak_state_next =   frp_bak_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            frp_bak_state   <=  1;
        end
        else begin
            frp_bak_state   <=  frp_bak_state_next;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            frp_len_back        <=  'b0;
            frp_len_back_pad    <=  'b0;
        end
        else if (frp_bak_state[0] && frp_bak_state_next[1]) begin
            frp_len_back        <=  frp_len_1;
            frp_len_back_pad    <=  frp_len_pad;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            // i_cell_data_fifo_dout   <=  'b0;
            // frp_dout_buf            <=  'b0;
            i_cell_data_fifo_wr     <=  'b0;
            // i_cell_ptr_fifo_dout    <=  'b0;
            i_cell_ptr_fifo_wr      <=  'b0;
        end
        else begin
            // if (frp_bak_state[2]) begin
            if (frp_cnt_back == 'h1) begin
                frp_dout_buf[frp_cnt_back[3:0]*8+:8]  <=  frp_header[15:8];
            end
            else if (frp_cnt_back == 'h2) begin
                frp_dout_buf[frp_cnt_back[3:0]*8+:8]  <=  frp_header[ 7:0];
            end
            else begin
                frp_dout_buf[frp_cnt_back[3:0]*8+:8]  <=  frp_buf[127:120];
            end
            // end
            if (frp_bak_state[1] && (frp_cnt_back[3:0] == 'h0 || frp_cnt_back == frp_len_back)) begin
                i_cell_data_fifo_wr     <=  'b1;
            end
            else begin
                i_cell_data_fifo_wr     <=  'b0;
            end
            if (frp_bak_state[1] && frp_cnt_back == frp_len_back) begin
                i_cell_ptr_fifo_dout    <=  {4'b0, frp_header[11:8], 1'b0, frp_len_back_pad[10:4]};
                i_cell_ptr_fifo_wr      <=  'b1;
            end
            else begin
                i_cell_ptr_fifo_wr      <=  'b0;
            end
        end
    end

    assign i_cell_data_fifo_dout = {frp_dout_buf[8:127], frp_dout_buf[0:7]};

endmodule
