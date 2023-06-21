`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 22:00:40
// Design Name: 
// Module Name: tteframe_process
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
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tteframe_process_retime(
input                	clk,
input                   rstn,
output  reg             sfifo_rd,
input        [7:0]      sfifo_dout,
output  reg             ptr_sfifo_rd,
input        [19:0]     ptr_sfifo_dout,
input                   ptr_sfifo_empty,

output  reg  [47:0]     se_dmac,
output  reg  [47:0]     se_smac,
(*MARK_DEBUG = "TRUE"*) output  reg  [11:0]     se_hash,
(*MARK_DEBUG = "TRUE"*) output  reg             se_req,
(*MARK_DEBUG = "TRUE"*) input                   se_ack,
(*MARK_DEBUG = "TRUE"*) input                   se_nak,
input        [15:0]     se_result,
input        [3:0]      link,                    

input                   bp0,
input                   bp1,
input                   bp2,
input                   bp3,
output  reg             sof,
output  reg             dv,
output  reg  [7:0]      data,

    // mgnt interface
    output              fp_stat_valid,
    input               fp_stat_resp,
    output     [  7:0]  fp_stat_data,
    input               fp_conf_valid,
    output              fp_conf_resp,
    input      [  1:0]  fp_conf_type,
    input      [ 15:0]  fp_conf_data
);

reg     [ 3:0]     frp_fwd_blk_vect, frp_fwd_blk_vect_next;

reg     [ 3:0]     frp_link_fwd;
reg                frp_link_src;
reg     [ 3:0]     frp_prert;

reg     [47:0]     source_mac;
reg     [47:0]     desti_mac;
reg     [15:0]     length_type;
reg     [5:0]      state;
reg     [10:0]     cnt;
// reg     [3:0]      egress_portmap;
reg     [11:0]     length;
reg     [5:0]      pad_cnt;

always@(posedge clk or negedge rstn)begin
    if(!rstn)begin
        sfifo_rd<=#2 0;
        ptr_sfifo_rd<=#2 0;
        se_dmac<=#2 0;
        se_smac<=#2 0;
        se_hash<=#2 0;
        se_req<=#2 0;
        sof<=#2 0;
        dv<=#2 0;
        data<=#2 0;
        state<=#2 0;
        cnt<=#2 0;
        // frp_link_fwd<=#2 0;
        // frp_link_src<=#2 0;
        end
    else  begin
        case(state)
        0:begin
            dv<=#2 0;
            if(!ptr_sfifo_empty)begin
                ptr_sfifo_rd<=#2 1;   	
                sfifo_rd<=#2 1;	
                state<=#2 1;         	
                end
            end
        1:begin
            ptr_sfifo_rd<=#2 0;
            // sfifo_rd<=#2 1;	
            state<=#2 2;
            end
        2:begin
            cnt<=#2 ptr_sfifo_dout[10:0];
            length<=#2 {1'b0,ptr_sfifo_dout[10:0]}; 
            frp_link_src<=#2 (ptr_sfifo_dout[15:12] & frp_fwd_blk_vect) == 4'b0;
            frp_prert<=#2 ptr_sfifo_dout[19:16];
            state<=#2 3;
            end
        3:begin
			length<=#2 length+2;
            frp_link_fwd<=#2 frp_link_src ? (link & ~frp_fwd_blk_vect) : 4'b0;
			// desti_mac[47:40]<=#2 sfifo_dout[7:0];
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 4;
            end
        4:begin
			pad_cnt<=#2 ~length[5:0];	
			// desti_mac[39:32]<=#2 sfifo_dout[7:0];
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 5;
            end
        5:begin
            // desti_mac[31:24]<=#2 sfifo_dout[7:0];
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 6;
            end
        6:begin
            // desti_mac[23:16]<=#2 sfifo_dout[7:0];
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 7;
            end
        7:begin
            // desti_mac[15:8]<=#2 sfifo_dout[7:0];
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 8;
            end
        8:begin
            desti_mac[7:0]<=#2 sfifo_dout[7:0];
            desti_mac[47:8]<=#2 desti_mac[39:0];
            state<=#2 9;
            end
        9:begin
            // source_mac[47:40]<=#2 sfifo_dout[7:0];
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            state<=#2 10;
            end
        10:begin
            // source_mac[39:32]<=#2 sfifo_dout[7:0];
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            state<=#2 11;
            end
        11:begin
            // source_mac[31:24]<=#2 sfifo_dout[7:0];
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            state<=#2 12;
            end
        12:begin
            // source_mac[23:16]<=#2 sfifo_dout[7:0];
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            state<=#2 13;
            end
        13:begin
            // source_mac[15:8]<=#2 sfifo_dout[7:0];
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            state<=#2 14;
            end
        14:begin
            source_mac[7:0]<=#2 sfifo_dout[7:0];
            source_mac[47:8]<=#2 source_mac[39:0];
            sfifo_rd<=#2 0;
            state<=#2 15;
            end
        15:begin
            // length_type[15:8]<=#2 sfifo_dout[7:0];
            length_type[7:0]<=#2 sfifo_dout[7:0];
            length_type[15:8]<=#2 length_type[7:0];
            // sfifo_rd<=#2 0;
            state<=#2 16;
            end
        16:begin
            length_type[7:0]<=#2 sfifo_dout[7:0];
            length_type[15:8]<=#2 length_type[7:0];
            cnt<=#2 cnt-14;
            state<=#2 19;
            end
        19:begin
            se_req<=#2 frp_link_src && (frp_prert == 4'b0);
            se_hash<=#2 {source_mac[4:0],desti_mac[6:0]};
            se_dmac<=#2 desti_mac;
            se_smac<=#2 source_mac;
            state<=#2 20;
            end
        20:begin
            if(frp_prert)begin
                se_req<=#2 0;
                state<=#2 22;
                // egress_portmap<=#2 frp_prert & link;
                data<=#2 {4'b0, frp_prert & link};
                dv<=#2 1;
                sof<=#2 1; 
                // len_tgt_combo <= {length[11:8], egress_portmap[3:0], length[7:0]}; 
                end                
            if(se_ack)begin
                se_req<=#2 0;
                state<=#2 22;
                data<=#2 {4'b0, se_result[3:0] & frp_link_fwd};
                dv<=#2 1;
                sof<=#2 1;
                // egress_portmap<=#2 se_result[3:0] & frp_link_fwd;
                // len_tgt_combo <= {length[11:8], egress_portmap[3:0], length[7:0]}; 
                end
            if(se_nak || !frp_link_src)begin
                se_req<=#2 0;
                state<=#2 21;
                dv<=#2 0;
                sof<=#2 0;
                // egress_portmap<=#2 0;
                // len_tgt_combo <= {length[11:8], 4'b0, length[7:0]}; 
                end
            end
        21:begin
            // data<=#2 {length[11:8],egress_portmap[3:0]}; 
            // data<=len_tgt_combo[15:8];
            // len_tgt_combo<=len_tgt_combo << 8;
            // dv<=#2 0;
            // sof<=#2 0;  
            state<=#2 23;
            end
        22:begin
            data<=#2 {ptr_sfifo_dout[15:12], length[11:8]};
            // data<=#2 {length[11:8],egress_portmap[3:0]};  
            // data<=len_tgt_combo[15:8];
            // len_tgt_combo<=len_tgt_combo << 8;
            // dv<=#2 1;
            // sof<=#2 1;
            sof<=#2 0;
            state<=#2 23;
            end
        23:begin
            data<=#2 length[7:0];
            // data<=len_tgt_combo[15:8];
            state<=#2 24;
            // sof<=#2 0;
            end
        24:begin
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 25;
            end
        25:begin
            // data<=#2 desti_mac[39:32];
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 26;
            end
        26:begin
            // data<=#2 desti_mac[31:24];
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 27;
            end
        27:begin
            // data<=#2 desti_mac[23:16];
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 28;
            end
        28:begin
            // data<=#2 desti_mac[15:8];
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 29; 
            end
        29:begin
            // data<=#2 desti_mac[7:0];
            data<=#2 desti_mac[47:40];
            desti_mac<=#2 desti_mac << 8;
            state<=#2 30;
            end
        30:begin
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            state<=#2 31;
            end
        31:begin
            // data<=#2 source_mac[39:32];
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            state<=#2 32;
            end 
        32:begin
            // data<=#2 source_mac[31:24];
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            state<=#2 33;
            end
        33:begin
            // data<=#2 source_mac[23:16];
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            state<=#2 34;
            end
        34:begin
            // data<=#2 source_mac[15:8];
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            state<=#2 35;
            end
        35:begin
            // data<=#2 source_mac[7:0];
            data<=#2 source_mac[47:40];
            source_mac<=#2 source_mac << 8;
            sfifo_rd<=#2 1;
            state<=#2 36;
            end
        36:begin
            data<=#2 length_type[15:8];
            length_type<=#2 length_type << 8;
            cnt<=#2 cnt-1;
            state<=#2 37;
            // sfifo_rd<=#2 1;
            end
        37:begin
            // data<=#2 length_type[7:0];
            data<=#2 length_type[15:8];
            cnt<=#2 cnt-1;
            state<=#2 38;
            end
        38:begin
            data<=#2 sfifo_dout;
            if(cnt>1) cnt<=#2 cnt-1;
            else begin
                cnt<=#2 0;
                sfifo_rd<=#2 0;
                state<=#2 39;
                end
            end
        39: begin
            data<=#2 sfifo_dout;
			state<=#2 40;
			end
        40: begin
            data<=#2 sfifo_dout;
			state<=#2 41;
			end
		41:begin
            data<=#2 0;
            if(pad_cnt==6'd63)begin
				dv<=#2 0;
				state<=#2 0;
				end
			else begin
                data<=#2 0;
				state<=#2 42;
                end
            end
		42:begin
			if(pad_cnt>0) begin
				// data<=#2 data+1;
				pad_cnt<=#2 pad_cnt-1;
				end
			else begin
				dv<=#2 0;
				state<=#2 0;
				end
			end
        endcase
        end
    end

    reg     [ 3:0]  mgnt_tx_state, mgnt_tx_state_next;
    reg     [ 3:0]  mgnt_rx_state, mgnt_rx_state_next;
    reg     [ 1:0]  mgnt_rx_buf_type;
    reg     [15:0]  mgnt_rx_buf_data;
    reg     [ 1:0]  mgnt_flag;

    always @(*) begin
        case(mgnt_tx_state)
            1 : mgnt_tx_state_next  =   (state == 0) && !ptr_sfifo_empty        ? 2 : 1;
            2 : mgnt_tx_state_next  =   (state == 21)                           ? 4 : 2;
            4 : mgnt_tx_state_next  =   fp_stat_resp                            ? 1 : 4;
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
            if (state == 20) begin
                mgnt_flag[0]    <=  se_ack;
            end
            if (state == 19) begin
                mgnt_flag[1]    <=  !source_mac[40] && !desti_mac[40];
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
        end
        else begin
            if (mgnt_rx_state[2]) begin
                if (mgnt_rx_buf_type == 2'b0) begin
                    frp_fwd_blk_vect_next   <=  mgnt_rx_buf_data;
                end 
            end
            if (state == 1) begin
                frp_fwd_blk_vect    <=  frp_fwd_blk_vect_next;
            end
        end
    end

    assign  fp_stat_valid   =   mgnt_tx_state[3];
    assign  fp_stat_data    =   {3'b0, mgnt_flag, 3'b1};
    assign  fp_conf_resp    =   mgnt_rx_state[3];

endmodule
