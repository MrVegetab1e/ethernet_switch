`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: 
// Module Name: mac_r_gmii
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

module mac_t_gmii_tte_v2(
    input           rstn,       // async rst
    input           sys_clk,    // sys clk
    input           tx_clk,     // mii tx clk
    input           gtx_clk,    // gmii tx clk, 125MHz, External
    output          gtx_dv,     // (g)mii tx valid
    output  [ 7:0]  gtx_d,      // (g)mii tx data

    input   [ 1:0]  speed,      // speed from mdio

    // normal dataflow
    output reg      data_fifo_rd,
    input   [ 7:0]  data_fifo_din,
    output reg      ptr_fifo_rd, 
    input   [15:0]  ptr_fifo_din,
    input           ptr_fifo_empty,
    // tte dataflow
    output reg      tdata_fifo_rd,
    input   [ 7:0]  tdata_fifo_din,
    output reg      tptr_fifo_rd, 
    input   [15:0]  tptr_fifo_din,
    input           tptr_fifo_empty
);

    localparam DELAY = 2;

    localparam MAC_TX_STATE_IDLE = 1;
    localparam MAC_TX_STATE_STAR = 2;
    localparam MAC_TX_STATE_PREA = 4;
    localparam MAC_TX_STATE_DATA = 8;
    localparam MAC_TX_STATE_CRCV = 16;

    localparam MAC_MII_STATE_IDLE = 1;
    localparam MAC_MII_STATE_PTR1 = 2;
    localparam MAC_MII_STATE_PTR2 = 4;
    localparam MAC_MII_STATE_DAT1 = 8;
    localparam MAC_MII_STATE_DAT2 = 16;
    localparam MAC_MII_STATE_GDAT = 32;
    localparam MAC_MII_STATE_WAIT = 64;

    // no jitter clk switch
    wire            tx_master_clk;
    reg             tx_clk_en_reg_p;
    reg             tx_clk_en_reg_n;
    reg             gtx_clk_en_reg_p;
    reg             gtx_clk_en_reg_n;

    always @(posedge tx_clk) begin
        tx_clk_en_reg_p     <=  !speed[1] && !gtx_clk_en_reg_n;
    end 
    always @(negedge tx_clk) begin
        tx_clk_en_reg_n     <=  tx_clk_en_reg_p;
    end

    always @(posedge gtx_clk) begin
        gtx_clk_en_reg_p    <=  speed[1] && !tx_clk_en_reg_n;
    end  
    always @(negedge tx_clk) begin
        gtx_clk_en_reg_n    <=  gtx_clk_en_reg_p;
    end

    assign  tx_master_clk   =   (tx_clk_en_reg_p && tx_clk) || (gtx_clk_en_reg_n && gtx_clk);

    reg     [ 5:0]  tx_state, tx_state_next;

    reg             tx_arb_dir;
    reg     [10:0]  tx_loop_cnt;
    reg     [10:0]  tx_byte_cnt;    // max len 1532B, min len 60B

    reg     [ 7:0]  tx_data_afifo_din;
    wire    [ 7:0]  tx_data_afifo_dout;
    reg             tx_data_afifo_wr;
    reg             tx_data_afifo_rd;
    wire    [10:0]  tx_data_afifo_depth;

    reg     [15:0]  tx_ptr_afifo_din;
    reg     [15:0]  tx_ptr_afifo_dout;
    reg             tx_ptr_afifo_wr;
    reg             tx_ptr_afifo_rd;
    reg             tx_ptr_afifo_empty;
    wire            tx_ptr_afifo_full;

    wire            tx_bp;
    wire            tx_bp_data;
    wire            tx_bp_ctrl;

    assign          tx_bp       =   tx_bp_data || tx_bp_ctrl;
    assign          tx_bp_data  =   (tx_data_afifo_depth < (4096 - 1536 - 8)); // max len + preamble
    assign          tx_bp_ctrl  =   tx_ptr_afifo_full;

    always @(*) begin
        case (tx_state)
            MAC_TX_STATE_IDLE: begin
                if ((!tptr_fifo_empty || !ptr_fifo_empty) && !tx_bp)
                    tx_state_next   =   MAC_TX_STATE_STAR;
                else
                    tx_state_next   =   MAC_TX_STATE_IDLE;
            end
            MAC_TX_STATE_STAR: begin
                tx_state_next   =   MAC_TX_STATE_PREA;
            end
            MAC_TX_STATE_PREA: begin
                if (tx_loop_cnt == 'b0)
                    tx_state_next   =   MAC_TX_STATE_DATA;
                else
                    tx_state_next   =   MAC_TX_STATE_PREA;
            end
            MAC_TX_STATE_DATA: begin
                if (tx_loop_cnt == 'b0)
                    tx_state_next   =   MAC_TX_STATE_CRCV;
                else
                    tx_state_next   =   MAC_TX_STATE_DATA;
            end
            MAC_TX_STATE_CRCV: begin
                if (tx_loop_cnt == 'b0) begin
                    if (!tptr_fifo_empty || !ptr_fifo_empty) 
                        tx_state_next   =   MAC_TX_STATE_STAR;
                    else
                        tx_state_next   =   MAC_TX_STATE_IDLE;
                end
                else
                    tx_state_next   =   MAC_TX_STATE_CRCV;
            end
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if (rstn) begin
            tx_state    <=  MAC_TX_STATE_IDLE;
        end
        else begin
            tx_state    <=  tx_state_next;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (rstn) begin
            tx_arb_dir          <=  'b0;
            tx_loop_cnt         <=  'b0;
            tx_byte_cnt         <=  'b0;
            ptr_fifo_rd         <=  'b0;
            data_fifo_rd        <=  'b0;
            tptr_fifo_rd        <=  'b0;
            tdata_fifo_rd       <=  'b0;
            tx_ptr_afifo_din    <=  'b0;
            tx_ptr_afifo_wr     <=  'b0;
            tx_data_afifo_din   <=  'b0;
            tx_data_afifo_wr    <=  'b0;
        end
        else begin
            if (tx_state_next == MAC_TX_STATE_STAR && tx_state != MAC_TX_STATE_STAR) begin
                tx_arb_dir      <=  !tptr_fifo_empty;
                ptr_fifo_rd     <=  tptr_fifo_empty;
                tptr_fifo_rd    <=  !tptr_fifo_empty;
            end
            else if (tx_state_next == MAC_TX_STATE_PREA && tx_state != MAC_TX_STATE_PREA) begin
                tx_loop_cnt     <=  'h8;
                tx_byte_cnt     <=  (tx_arb_dir) ? tptr_fifo_din[10:0] : ptr_fifo_din[10:0];

                ptr_fifo_rd     <=  'b0;
                tptr_fifo_rd    <=  'b0;
            end
            else if (tx_state_next == MAC_TX_STATE_DATA && tx_state != MAC_TX_STATE_PREA) begin
                tx_loop_cnt     <=  (tx_byte_cnt < 60) ? 60 : tx_byte_cnt;
                data_fifo_rd    <=  !tx_arb_dir;
                tdata_fifo_rd   <=  tx_arb_dir;
            end
            else if (tx_state_next == MAC_TX_STATE_CRCV && tx_state != MAC_TX_STATE_CRCV) begin
                tx_loop_cnt     <=  'h4;
                data_fifo_rd    <=  'b0;
                tdata_fifo_rd   <=  'b0;
            end
            else begin
                tx_loop_cnt     <=  tx_loop_cnt - 1'b1;
            end
        end
    end

    crc32_8023 u_crc32_8023(
        .clk(clk), 
        .reset(!rstn), 
        .d(crc_din), 
        .load_init(crc_init),
        .calc(crc_cal), 
        .d_valid(crc_dv), 
        .crc_reg(crc_result), 
        .crc(crc_dout)
    );


    afifo_w8_d4k u_data_fifo_tx (
        .rst(!rstn),                      // input rst
        .wr_clk(clk),                     // input wr_clk
        .rd_clk(tx_master_clk),                // input rd_clk
        .din(tx_data_afifo_din),            // input [7 : 0] din
        .wr_en(tx_data_afifo_wr),           // input wr_en
        .rd_en(tx_data_afifo_rd),           // input rd_en
        .dout(tx_data_afifo_dout),          // output [7 : 0] dout
        .full(),                          // output full
        .empty(),                         // output empty
        .rd_data_count(),					// output [11 : 0] rd_data_count
        .wr_data_count(tx_data_afifo_depth) // output [11 : 0] wr_data_count
    );

    afifo_w16_d32 u_ptr_fifo_tx (
        .rst(!rstn),                      // input rst
        .wr_clk(clk),                     // input wr_clk
        .rd_clk(tx_master_clk),                // input rd_clk
        .din(tx_ptr_afifo_din),             // input [15 : 0] din
        .wr_en(tx_ptr_afifo_wr),            // input wr_en
        .rd_en(tx_ptr_afifo_rd),            // input rd_en
        .dout(tx_ptr_afifo_dout),           // output [15 : 0] dout
        .full(tx_ptr_afifo_full),           // output full
        .empty(tx_ptr_afifo_empty)      	// output empty
    );

    reg [ 6:0]  mii_state, mii_state_next;
    reg [10:0]  mii_cnt;
    reg         mii_dv;
    reg [ 7:0]  mii_d;

    always @(*) begin
        case (mii_state)
            MAC_MII_STATE_IDLE:
                mii_state_next  <=  (!tx_ptr_afifo_empty) ? MAC_MII_STATE_PTR1 : MAC_MII_STATE_IDLE;
            MAC_MII_STATE_PTR1:
                mii_state_next  <=  MAC_MII_STATE_PTR2;
            MAC_MII_STATE_PTR2:
                mii_state_next  <=  (tx_ptr_afifo_dout[11]) ? MAC_MII_STATE_GDAT : MAC_MII_STATE_PTR1;
            MAC_MII_STATE_DAT1:
                mii_state_next  <=  MAC_MII_STATE_DAT2;
            MAC_MII_STATE_DAT2:
                mii_state_next  <=  (mii_cnt == 'b1) ? MAC_MII_STATE_WAIT : MAC_MII_STATE_DAT1;
            MAC_MII_STATE_GDAT:
                mii_state_next  <=  (mii_cnt == 'b1) ? MAC_MII_STATE_WAIT : MAC_MII_STATE_GDAT;
            MAC_MII_STATE_WAIT:
                mii_state_next  <=  (mii_cnt == 'b1) ? MAC_MII_STATE_IDLE : MAC_MII_STATE_WAIT;
        endcase
    end

    always @(posedge tx_master_clk or negedge rstn) begin
        if (!rstn) begin
            mii_state   <=  MAC_TX_STATE_IDLE;
        end
        else begin
            mii_state   <=  mii_state_next;
        end
    end

    always @(posedge tx_master_clk or negedge rstn) begin
        if (!rstn) begin
            tx_data_afifo_rd    <=  'b0;
            tx_ptr_afifo_rd     <=  'b0;
        end
        else begin
            if (mii_state_next == MAC_MII_STATE_PTR1) begin
                tx_ptr_afifo_rd     <=  'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_PTR2) begin
                tx_data_afifo_rd    <=  'b1;
                tx_ptr_afifo_rd     <=  'b0;    
            end
            else if (mii_state_next == MAC_MII_STATE_DAT1) begin
                tx_data_afifo_rd    <=  'b0;
            end
            else if (mii_state_next == MAC_MII_STATE_DAT2) begin
                tx_data_afifo_rd    <=  'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_GDAT) begin
                tx_data_afifo_rd    <=  'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_WAIT) begin
                tx_data_afifo_rd    <=  'b0;
            end
        end
    end

    always @(posedge tx_master_clk or negedge rstn) begin
        if (!rstn) begin
            mii_cnt <=  'b0;
        end
        else begin
            if (mii_state_next == MAC_MII_STATE_DAT1) begin
                mii_cnt <=  (mii_state == MAC_MII_STATE_PTR2) ? tx_ptr_afifo_dout[10:0] : mii_cnt - 1'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_GDAT) begin
                mii_cnt <=  (mii_state == MAC_MII_STATE_PTR2) ? tx_ptr_afifo_dout[10:0] : mii_cnt - 1'b1;
            end
        end
    end

    always @(posedge tx_master_clk or negedge rstn) begin
        if (!rstn) begin
            mii_dv  <=  'b0;
            mii_d   <=  'b0;
        end
        else begin
            if (mii_state == MAC_MII_STATE_DAT1) begin
                mii_d   <=  {4'b0, tx_data_afifo_dout[7:4]};
                mii_dv  <=  'b1;
            end
            else if (mii_state == MAC_MII_STATE_DAT2) begin
                mii_d   <=  {4'b0, tx_data_afifo_dout[3:0]};
                mii_dv  <=  'b1;
            end
            else if (mii_state == MAC_MII_STATE_GDAT) begin
                mii_d   <=  tx_data_afifo_dout;
                mii_dv  <=  'b1;
            end
            else begin
                mii_d   <=  'b0;
                mii_dv  <=  'b0;
            end
        end
    end

    assign      gtx_d   =   mii_d;
    assign      gtx_dv  =   mii_dv;

endmodule