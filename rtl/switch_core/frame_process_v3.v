`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 22:00:40
// Design Name: 
// Module Name: tteframe_process_v3
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
// Revision 2.01 - Mgnt func added, now check for MAC validness
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module frame_process_v3 (
    input              clk,
    input              rstn,
    output reg         sfifo_rd,
    input       [ 7:0] sfifo_dout,
    output reg         ptr_sfifo_rd,
    input       [19:0] ptr_sfifo_dout,
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

    // output reg         sof,
    // output reg         dv,
    // output reg  [ 7:0] data

    // output reg [143:16] i_cell_data_fifo_dout,
    output     [127:0]  i_cell_data_fifo_dout,
    output reg          i_cell_data_fifo_wr,
    output reg [ 15:0]  i_cell_ptr_fifo_dout,
    output reg          i_cell_ptr_fifo_wr,
    input               i_cell_bp,

    // mgnt interface
    output              fp_stat_valid,
    input               fp_stat_resp,
    output     [  7:0]  fp_stat_data,
    input               fp_conf_valid,
    output              fp_conf_resp,
    input      [  1:0]  fp_conf_type,
    input      [ 15:0]  fp_conf_data

);

    reg     [  3:0]     frp_fwd_blk_vect, frp_fwd_blk_vect_next;
    reg     [  3:0]     frp_lrn_blk_vect, frp_lrn_blk_vect_next;
    
    // reg     [ 15:0]     frp_state, frp_state_next;
    reg     [  4:0]     frp_fnt_state, frp_fnt_state_next;
    reg     [  1:0]     frp_bak_state, frp_bak_state_next;

    reg     [127:0]     frp_buf;
    reg     [0:127]     frp_dout_buf;
    reg     [ 15:0]     frp_header;
    reg     [  3:0]     frp_lldp_prert;
    reg     [  5:0]     frp_multicast;
    reg     [  3:0]     frp_link_fwd;
    reg                 frp_link_src;
    reg                 frp_link_lrn;    

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
            // 08: frp_fnt_state_next  =   (frp_cnt_front == 'h8) ? 16 : 8;
            // 16: frp_fnt_state_next  =   (frp_cnt_front == 'hE) ? 32 : 16;
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
            // if (!frp_bak_state[0]) begin
            if (frp_bak_state[1]) begin
                frp_cnt_back    <=  frp_cnt_back + 1'b1;
            end
            else begin
                // frp_cnt_back    <=  'hFF3;
                frp_cnt_back    <=  'b1;
            end
            if (frp_fnt_state[2]) begin
                frp_len         <=  ptr_sfifo_dout[10:0];
                frp_len_1       <=  ptr_sfifo_dout[10:0] + 2;
            end
            if (frp_fnt_state[3]) begin
                // frp_len_pad[10:4]   <=  (frp_len[3:0] == 'b0) ? frp_len[10:4] : frp_len[10:4] + 1'b1;
                frp_len_pad[10:4]   <=  (frp_len_1[3:0] == 'b0) ? frp_len_1[10:4] : frp_len_1[10:4] + 1'b1;
                // frp_len_pad[10:4]   <=  (frp_len_1[3:0] == 'hF) ? frp_len_1[10:4] : frp_len_1[10:4] + 1'b1;
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
            frp_multicast   <=  'b0;
        end
        else begin
            if (frp_cnt_front >= 'h3 && frp_cnt_front <= 'h8) begin
                frp_multicast   <=  {frp_multicast, (sfifo_dout == 8'hFF)};
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
            frp_lldp_prert  <=  'b0;
            frp_header      <=  'b0;
            frp_link_fwd    <=  'b0;
            frp_link_lrn    <=  'b0;
        end
        else begin
            if (frp_fnt_state[2]) begin
                // source_portmap  <=  {12'b0, ptr_sfifo_dout[14:11]};
                source_portmap  <=  {12'b0, ptr_sfifo_dout[15:12]};
                frp_link_src    <=  (ptr_sfifo_dout[15:12] & frp_fwd_blk_vect) == 4'b0;
                frp_link_lrn    <=  (ptr_sfifo_dout[15:12] & frp_lrn_blk_vect) == 4'b0;
                frp_lldp_prert  <=  ptr_sfifo_dout[19:16];
            end
            if (frp_fnt_state[3]) begin
                if (frp_link_src) begin
                    frp_link_fwd    <=  (link & ~frp_fwd_blk_vect);
                    // frp_link_fwd    <=  link;
                end
                else begin
                    frp_link_fwd    <=  'b0;
                end
                // frp_link_fwd    <=  frp_link_src ? (link & !frp_fwd_blk_vect) : 4'b0;
            end
            // if (frp_cnt_front == 'h8) begin
            //     se_mac          <=  {frp_buf[39:0], sfifo_dout};
            //     se_hash         <=  {frp_buf[ 1:0], sfifo_dout};
            if (frp_cnt_front == 'h9) begin
                se_mac          <=  frp_buf[47:0];
                se_hash         <=  frp_buf[ 9:0];
                se_source       <=  'b0;
            end
            // else if (frp_cnt_front == 'hE) begin
            //     se_mac          <=  {frp_buf[39:0], sfifo_dout};
            //     se_hash         <=  {frp_buf[ 1:0], sfifo_dout};
            else if (frp_cnt_front == 'hF) begin
                se_mac          <=  frp_buf[47:0];                
                se_hash         <=  frp_buf[ 9:0];
                se_source       <=  'b1;
            end
            // if (frp_cnt_front == 'h8) begin
            if (frp_cnt_front == 'h9) begin
                se_req          <=  !frp_buf[40] && frp_link_src;
            end
            // else if (frp_cnt_front == 'hE) begin
            else if (frp_cnt_front == 'hF) begin
                se_req          <=  !frp_buf[40] && frp_link_lrn;
            end
            else begin
                se_req          <=  'b0;
            end
            // if (frp_cnt_front == 'hE) begin
            if (frp_cnt_front == 'hF) begin
                // frp_header      <=  {(se_result && link), 1'b0, frp_len_1};
                if (frp_lldp_prert != 0) begin
                    frp_header      <=  {1'b0, frp_len_1[10:8], 
                                        (frp_lldp_prert & frp_link_fwd), 
                                        frp_len_1[7:0]};                 
                end
                else if (se_mac[40]) begin
                    frp_header      <=  {1'b0, frp_len_1[10:8], 
                                        (~source_portmap[ 3:0] & frp_link_fwd), 
                                        frp_len_1[7:0]};
                end
                else begin
                    frp_header      <=  {1'b0, frp_len_1[10:8], 
                                        (se_result[ 3:0] & frp_link_fwd), 
                                        frp_len_1[7:0]};
                end
            end
        end
    end

    always @(*) begin
        case(frp_bak_state)
            01: frp_bak_state_next  =   (frp_wr_en[1] && frp_cnt_front == 'h10) ? 2 : 1;
            // 02: frp_bak_state_next  =   (frp_cnt_front == 'h10) ? 4 : 2;
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
                // i_cell_data_fifo_dout[frp_cnt_back[3:0]*16+:16] <=  frp_header[15:8];
                frp_dout_buf[frp_cnt_back[3:0]*8+:8]  <=  frp_header[15:8];
            end
            else if (frp_cnt_back == 'h2) begin
                // i_cell_data_fifo_dout[frp_cnt_back[3:0]*16+:16] <=  frp_header[ 7:0];
                frp_dout_buf[frp_cnt_back[3:0]*8+:8]  <=  frp_header[ 7:0];
            end
            else begin
                // i_cell_data_fifo_dout[frp_cnt_back[3:0]*16+:16] <=  frp_buf[127:120];
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
    // assign i_cell_data_fifo_dout = frp_dout_buf;

    reg     [ 3:0]  mgnt_tx_state, mgnt_tx_state_next;
    reg     [ 3:0]  mgnt_rx_state, mgnt_rx_state_next;
    reg     [ 1:0]  mgnt_rx_buf_type;
    reg     [15:0]  mgnt_rx_buf_data;
    reg     [ 7:0]  mgnt_flag;

    always @(*) begin
        case(mgnt_tx_state)
            1 : mgnt_tx_state_next  =   frp_fnt_state[0] && !ptr_sfifo_empty    ? 2 : 1;
            2 : mgnt_tx_state_next  =   (frp_cnt_front == 'h9)                  ? 4 : 2;
            4 : mgnt_tx_state_next  =   (frp_cnt_front == 'h16)                 ? 8 : 4;
            8 : mgnt_tx_state_next  =   fp_stat_resp                            ? 1 : 8;
            default : mgnt_tx_state_next    =   mgnt_tx_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mgnt_tx_state   <=  1;
        end
        else begin
            mgnt_tx_state   <=  mgnt_tx_state_next;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mgnt_flag   <=  'b0;
        end
        else begin
            if (frp_cnt_front == 'h9) begin
                if (frp_multicast == {6{1'b1}}) begin
                    mgnt_flag[ 2:0] <=  3'b100;
                end
                else if (frp_buf[40]) begin
                    mgnt_flag[ 2:0] <=  3'b010;
                end
                else begin
                    mgnt_flag[ 2:0] <=  3'b001;
                end
            end
            if (frp_cnt_front == 'hE) begin
                mgnt_flag[3]    <=  se_ack;
            end
            if (frp_cnt_front == 'hF) begin
                mgnt_flag[4]    <=  !frp_buf[40];
            end
            if (frp_cnt_front == 'h16) begin
                mgnt_flag[6]    <=  se_nak;
            end
            if (frp_fnt_state[0] && !ptr_sfifo_empty) begin
                mgnt_flag[7]    <=  i_cell_bp;
            end
        end
    end

    always @(*) begin
        case(mgnt_rx_state)
            1 : mgnt_rx_state_next  =   (fp_conf_valid) ? 2 : 1;
            2 : mgnt_rx_state_next  =   4;
            4 : mgnt_rx_state_next  =   8;
            8 : mgnt_rx_state_next  =   (!fp_conf_valid) ? 1 : 8;
            default : mgnt_rx_state_next    =   mgnt_rx_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mgnt_rx_state   <=  1;
        end
        else begin
            mgnt_rx_state   <=  mgnt_rx_state_next;
        end
    end

    always @(posedge clk) begin
        if (mgnt_rx_state[1]) begin
            mgnt_rx_buf_type    <=  fp_conf_type;
            mgnt_rx_buf_data    <=  fp_conf_data;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            frp_fwd_blk_vect        <=  'b0;
            frp_fwd_blk_vect_next   <=  'b0;
            frp_lrn_blk_vect        <=  'b0;
            frp_lrn_blk_vect_next   <=  'b0;
        end
        else begin
            if (mgnt_rx_state[2]) begin
                if (mgnt_rx_buf_type == 2'b0) begin
                    frp_fwd_blk_vect_next   <=  mgnt_rx_buf_data[3:0];
                end 
                if (mgnt_rx_buf_type == 2'b1) begin
                    frp_lrn_blk_vect_next   <=  mgnt_rx_buf_data[3:0];
                end
            end
            if (frp_fnt_state[1]) begin
                frp_fwd_blk_vect    <=  frp_fwd_blk_vect_next;
                frp_lrn_blk_vect    <=  frp_lrn_blk_vect_next;
            end
        end
    end

    assign  fp_stat_valid   =   mgnt_tx_state[3];
    assign  fp_stat_data    =   mgnt_flag;
    assign  fp_conf_resp    =   mgnt_rx_state[3];

endmodule
