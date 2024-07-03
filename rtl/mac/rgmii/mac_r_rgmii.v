`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: 
// Module Name: mac_r_rgmii
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


module mac_r_rgmii(
    input               rstn_sys,
    input               clk_sys,

    input               rx_clk,
    input               rx_dv,
    input       [3:0]   rx_d,

    input               speed,  //1: RGMII, 0: MII

    input               data_fifo_rd,
    output      [7:0]   data_fifo_dout,
    input               ptr_fifo_rd, 
    output      [19:0]  ptr_fifo_dout,
    output              ptr_fifo_empty
);

    parameter   DELAY=2;  
    parameter   CRC_RESULT_VALUE=32'hc704dd7b;
    parameter   MTU=1535;

    reg     [ 1:0]  rstn_mac;

    always @(posedge rx_clk) begin
        rstn_mac    <=  {rstn_mac, rstn_sys};
    end

    wire    [ 7:0]  rx_d_sdr;
    wire    [ 1:0]  rx_dv_sdr;
    reg     [ 7:0]  rx_d_buf;
    reg     [ 1:0]  rx_dv_buf;
    reg             rx_valid_fnt;
    reg             rx_valid_bak;

    reg     [ 7:0]  rx_state_fnt, rx_state_fnt_next;
    reg     [ 7:0]  rx_state_bak, rx_state_bak_next;
    reg     [11:0]  rx_cnt_fnt;
    reg     [11:0]  rx_cnt_bak;
    reg     [11:0]  rx_len;
    reg     [95:0]  rx_buf;

    wire            crc_dv;
    wire    [31:0]  crc_result;

    wire    [12:0]  data_fifo_depth;
    reg             ptr_fifo_wr;
    reg     [15:0]  ptr_fifo_din;
    wire            ptr_fifo_full;

    reg             bp;
    always @(posedge rx_clk) begin
        if (!rstn_mac[1]) begin
            bp  <=  1'b1;
        end
        else begin
            // bp  <=  (data_fifo_depth[12:8] < 5'h6) || (ptr_fifo_full);
            bp  <=  (data_fifo_depth[12:8] >= 'h0A) || (ptr_fifo_full);
            // bp  <=  (data_fifo_depth[11:8] >= 'h0A) || (ptr_fifo_full);
        end
    end
    // assign          bp  =   (data_fifo_depth[12:8] < 5'h6) || (ptr_fifo_full);

    // iddr_4 u_iddr_4 (
    //     .din(rx_d),
    //     .clk(rx_clk),
    //     .q(rx_d_sdr)
    // );

    // iddr_1 u_iddr_1 (
    //     .din(rx_dv),
    //     .clk(rx_clk),
    //     .q(rx_dv_sdr)
    // );

    reg     [ 3:0]  rx_d_p, rx_d_n;
    reg     [ 7:0]  rx_d_1;
    reg             rx_dv_p, rx_dv_n;
    reg     [ 1:0]  rx_dv_1;

    always @(posedge rx_clk) begin
        rx_d_p  <=  rx_d;
        rx_dv_p <=  rx_dv;
    end

    always @(negedge rx_clk) begin
        rx_d_n  <=  rx_d;
        rx_dv_n <=  rx_dv;
    end

    always @(posedge rx_clk) begin
        rx_d_1  <=  {rx_d_n, rx_d_p};
        rx_dv_1 <=  {rx_dv_n, rx_dv_p};
    end

    assign  rx_d_sdr    =   rx_d_1;
    assign  rx_dv_sdr   =   rx_dv_1;

    always @(posedge rx_clk) begin
        if (speed) begin
            rx_d_buf    <=  rx_d_sdr;
            rx_dv_buf   <=  rx_dv_sdr;
        end
        else begin
            rx_d_buf    <=  {rx_d_sdr[3:0], rx_d_buf[7:4]};
            rx_dv_buf   <=  {rx_dv_sdr[0], rx_dv_buf[1]};
        end
    end

    always @(posedge rx_clk) begin
        if (speed) begin
            rx_valid_fnt    <=  1'b1;
            rx_valid_bak    <=  1'b1;
        end
        else begin
            if (rx_dv_buf == 2'b0) begin
                rx_valid_fnt    <=  'b0;
            end
            else begin
                rx_valid_fnt    <=  !rx_valid_fnt;
            end
            if (rx_state_bak[0]) begin
                rx_valid_bak    <=  'b0;
            end
            else begin
                rx_valid_bak    <=  !rx_valid_bak;
            end
        end
    end

    always @(*) begin
        case(rx_state_fnt)
            01: rx_state_fnt_next   =   (rx_valid_fnt && rx_dv_buf == 2'b11 && rx_d_buf == 8'hD5) ? 2 : 1;
            02: rx_state_fnt_next   =   (rx_valid_fnt && rx_dv_buf != 2'b11) ? 1 : 2;
            default: rx_state_fnt_next = rx_state_fnt;
        endcase
    end

    always @(*) begin
        case(rx_state_bak)
            01: rx_state_bak_next   =   (rx_valid_fnt && rx_cnt_fnt == 'hB) ? 2 : 1;
            02: rx_state_bak_next   =   (rx_valid_bak && rx_cnt_bak == MTU) ? 4 : 
                                        (rx_valid_bak && rx_cnt_bak == rx_len) ? 4 : 2;
            04: rx_state_bak_next   =   1;
            default: rx_state_bak_next = rx_state_bak;
        endcase
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac[1]) begin
            rx_state_fnt    <=  1;
            rx_state_bak    <=  1;
        end
        else begin
            rx_state_fnt    <=  rx_state_fnt_next;
            rx_state_bak    <=  rx_state_bak_next;
        end
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac[1]) begin
            rx_cnt_fnt  <=  'b0;
            rx_cnt_bak  <=  'b1;
            rx_len      <=  'hFFF;
        end
        else begin
            if (rx_state_fnt[0]) begin
                rx_cnt_fnt  <=  'b0;
            end
            else if (rx_state_fnt[1] && rx_valid_fnt && rx_dv_buf == 2'b11) begin
                rx_cnt_fnt  <=  rx_cnt_fnt + 1'b1;
            end
            if (rx_state_bak[0]) begin
                rx_cnt_bak  <=  'b1;
            end
            else if (rx_state_bak[1] && rx_valid_bak)begin
                rx_cnt_bak  <=  rx_cnt_bak + 1'b1;
            end
            if (rx_state_bak[0]) begin
                rx_len      <=  'hFFF;
            end
            if (!rx_state_fnt[0] && rx_dv_buf != 2'b11) begin
                rx_len      <=  rx_cnt_fnt;
            end
        end
    end

    always @(posedge rx_clk) begin
        if (!rstn_mac[1]) begin
            ptr_fifo_wr     <=  'b0;
            // ptr_fifo_din    <=  'b0;
        end
        else begin
            if (rx_state_bak_next[2]) begin
                ptr_fifo_din[11:0]  <=  rx_cnt_bak;
            end
            if (rx_state_bak[2]) begin
                ptr_fifo_din[15]    <=  (crc_result != CRC_RESULT_VALUE);
                ptr_fifo_din[14]    <=  (rx_len > MTU);
                ptr_fifo_din[13]    <=  (rx_len < 64);
                ptr_fifo_din[12]    <=  1'b0;
                ptr_fifo_din[11:0]  <=  ptr_fifo_din[11:0] - 12'h4;
                // ptr_fifo_din[11:0]  <=  rx_cnt_bak - 1'b1;
            end
            if (rx_state_bak[2]) begin
                ptr_fifo_wr     <=  'b1;
            end
            else begin
                ptr_fifo_wr     <=  'b0;
            end
        end
    end

    always @(posedge rx_clk) begin
        if ((!rx_state_bak[0] && rx_valid_bak) || (rx_dv_buf == 2'b11 && rx_valid_fnt)) begin
            rx_buf  <=  {rx_buf, rx_d_buf};
        end
    end

    crc32_8023 u_crc32_8023(
        .clk(rx_clk),
        .reset(!rstn_mac[1]), 
        .d(rx_buf[95:88]), 
        .load_init(rx_state_bak[0]),
        .calc(rx_state_bak[1]), 
        .d_valid(rx_valid_bak), 
        .crc_reg(crc_result), 
        .crc()
    );

	// afifo_reg_w8_d4k u_data_fifo(
	// 	.Data(rx_buf[95:88]), //input [7:0] Data
	// 	.WrClk(rx_clk), //input WrClk
	// 	.RdClk(clk_sys), //input RdClk
	// 	.WrEn(!rx_state_bak[0]), //input WrEn
	// 	.RdEn(data_fifo_rd), //input RdEn
	// 	.Wnum(data_fifo_depth), //output [12:0] Wnum
	// 	.Q(data_fifo_dout), //output [7:0] Q
	// 	.Empty(Empty_o), //output Empty
	// 	.Full(Full_o) //output Full
	// );

    afifo_reg_w8_d4k u_data_fifo (
        .rst(rstn_mac[1]),                  // input rst
        .wr_clk(rx_clk),                    // input wr_clk
        .rd_clk(clk_sys),                   // input rd_clk
        .din(rx_buf[95:88]),                // input [7 : 0] din
        .wr_en(rx_state_bak[1] && rx_valid_bak),            // input wr_en
        .rd_en(data_fifo_rd),               // input rd_en
        .dout(data_fifo_dout),              // output [7 : 0]       
        .full(), 
        .empty(), 
        .rd_data_count(), 				    // output [11 : 0] rd_data_count
        .wr_data_count(data_fifo_depth) 	// output [11 : 0] wr_data_count
    );

    afifo_w16_d32 u_ptr_fifo (
        .rst(rstn_mac[1]),              // input rst
        .wr_clk(rx_clk),                // input wr_clk
        .rd_clk(clk_sys),               // input rd_clk
        .din(ptr_fifo_din),             // input [15 : 0] din
        .wr_en(ptr_fifo_wr),            // input wr_en
        .rd_en(ptr_fifo_rd),            // input rd_en
        .dout(ptr_fifo_dout),           // output [15 : 0] dout
        .full(ptr_fifo_full),           // output full
        .empty(ptr_fifo_empty)          // output empty
    ); 

endmodule
