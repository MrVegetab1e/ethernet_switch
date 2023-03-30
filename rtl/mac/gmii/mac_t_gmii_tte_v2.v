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
    input           rstn_sys,   // async rst
    input           rstn_mac,
    input           sys_clk,    // sys clk
    input           tx_clk,     // mii tx clk
    input           gtx_clk,    // gmii tx clk, 125MHz, External
    output          gtx_dv,     // (g)mii tx valid
    output  [ 7:0]  gtx_d,      // (g)mii tx data

    input   [ 1:0]  speed,      // speed from mdio

    // normal dataflow
    output          data_fifo_rd,
    input   [ 7:0]  data_fifo_din,
    output reg      ptr_fifo_rd, 
    input   [15:0]  ptr_fifo_din,
    input           ptr_fifo_empty,
    // tte dataflow
    output          tdata_fifo_rd,
    input   [ 7:0]  tdata_fifo_din,
    output reg      tptr_fifo_rd, 
    input   [15:0]  tptr_fifo_din,
    input           tptr_fifo_empty
);

    localparam DELAY = 2;

    localparam MAC_TX_STATE_IDLE = 1;   // idle, wait for ptr input
    localparam MAC_TX_STATE_STAR = 2;   // read ptr, initial for tx sequence
    localparam MAC_TX_STATE_PREA = 4;   // attach preamble sequence before frame
    localparam MAC_TX_STATE_PDAT = 8;   // 1 clk wait for fifo output
    localparam MAC_TX_STATE_DATA = 16;  // data transfer loop
    localparam MAC_TX_STATE_PCRC = 32;
    localparam MAC_TX_STATE_CRCV = 64;  // attach crc value at end

    localparam MAC_MII_STATE_IDLE = 1;  // idle, wait for ptr input
    localparam MAC_MII_STATE_PTR1 = 2;  // read ptr
    localparam MAC_MII_STATE_PTR2 = 4;  // ptr return, prepare for mii tx sequence
    localparam MAC_MII_STATE_DAT1 = 8;  // mii mode, output big end of data
    localparam MAC_MII_STATE_DAT2 = 16; // mii mode, output little end of data
    localparam MAC_MII_STATE_GDAT = 32; // gmii mode
    localparam MAC_MII_STATE_WAIT = 64; // wait as protocol required

    // no jitter clk switch
    reg     [ 1:0]  speed_reg;
    wire            speed_change;
    always @(posedge sys_clk or negedge rstn_sys) begin
        if (!rstn_sys) begin
            speed_reg   <=  'b0;
        end
        else begin
            speed_reg   <=   speed;
        end
    end
    assign          speed_change =  |(speed ^ speed_reg);

    wire            tx_master_clk;
    reg             tx_clk_en_reg_p;
    reg             tx_clk_en_reg_n;
    reg             gtx_clk_en_reg_p;
    reg             gtx_clk_en_reg_n;

    always @(posedge tx_clk or posedge speed_change or negedge rstn_sys) begin
        if (!rstn_sys || speed_change) begin
            tx_clk_en_reg_p     <=  'b0;
        end
        else begin
            tx_clk_en_reg_p     <=  !speed[1] && !gtx_clk_en_reg_n;
        end
    end 
    always @(negedge tx_clk or posedge speed_change or negedge rstn_sys) begin
        if (!rstn_sys || speed_change) begin
            tx_clk_en_reg_n     <=  'b0;
        end
        else begin
            tx_clk_en_reg_n     <=  tx_clk_en_reg_p;
        end
    end

    always @(posedge gtx_clk or posedge speed_change or negedge rstn_sys) begin
        if (!rstn_sys || speed_change) begin
            gtx_clk_en_reg_p    <=  'b0;
        end
        else begin
            gtx_clk_en_reg_p    <=  speed[1] && !tx_clk_en_reg_n;
        end
    end  
    always @(negedge gtx_clk or negedge speed_change or negedge rstn_sys) begin
        if (!rstn_sys || speed_change) begin
            gtx_clk_en_reg_n    <=  'b0;
        end
        else begin
            gtx_clk_en_reg_n    <=  gtx_clk_en_reg_p;
        end
    end

    assign  tx_master_clk   =   (tx_clk_en_reg_n && tx_clk) || (gtx_clk_en_reg_n && gtx_clk);

    reg     [ 6:0]  tx_state, tx_state_next;

    reg             tx_arb_dir;
    reg     [10:0]  tx_loop_cnt;
    reg     [10:0]  tx_byte_cnt;    // max len 1532B, min len 60B

    reg     [ 7:0]  tx_data_afifo_din;
    wire    [ 7:0]  tx_data_afifo_dout;
    reg             tx_data_afifo_wr;
    reg             tx_data_afifo_rd;
    wire    [11:0]  tx_data_afifo_depth;

    reg     [15:0]  tx_ptr_afifo_din;
    wire    [15:0]  tx_ptr_afifo_dout;
    reg             tx_ptr_afifo_wr;
    reg             tx_ptr_afifo_rd;
    wire            tx_ptr_afifo_empty;
    wire            tx_ptr_afifo_full;

    reg             crc_init;
    reg             crc_cal;
    reg             crc_dv;
    wire    [31:0]  crc_result;
    wire    [ 7:0]  crc_dout;

    wire    [ 7:0]  tx_data_in;

    assign          tx_data_in  = tx_arb_dir ? tdata_fifo_din : data_fifo_din;
    assign          data_fifo_rd    =   |(tx_state_next[4:3]) && ~tx_arb_dir;
    assign          tdata_fifo_rd   =   |(tx_state_next[4:3]) && tx_arb_dir;

    wire            tx_bp;
    wire            tx_bp_data;
    wire            tx_bp_ctrl;

    assign          tx_bp       =   tx_bp_data || tx_bp_ctrl;
    // assign          tx_bp_data  =   (tx_data_afifo_depth > (4096 - 1518 - 8)); // max len + preamble
    assign          tx_bp_data  =   tx_data_afifo_depth[11:4] > 8'hA0;
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
                if (tx_loop_cnt == 'b1)
                    tx_state_next   =   MAC_TX_STATE_PDAT;
                else
                    tx_state_next   =   MAC_TX_STATE_PREA;
            end
            MAC_TX_STATE_PDAT: begin
                tx_state_next   =   MAC_TX_STATE_DATA; 
            end
            MAC_TX_STATE_DATA: begin
                if (tx_loop_cnt == 'b1)
                    tx_state_next   =   MAC_TX_STATE_PCRC;
                else
                    tx_state_next   =   MAC_TX_STATE_DATA;
            end
            MAC_TX_STATE_PCRC: begin
                tx_state_next   =   MAC_TX_STATE_CRCV;
            end
            MAC_TX_STATE_CRCV: begin
                if (tx_loop_cnt == 'b1) begin
                    // (!tptr_fifo_empty || !ptr_fifo_empty) 
                    //     tx_state_next   =   MAC_TX_STATE_STAR;
                    // else
                    tx_state_next   =   MAC_TX_STATE_IDLE;
                end
                else
                    tx_state_next   =   MAC_TX_STATE_CRCV;
            end
        endcase
    end

    always @(posedge sys_clk or negedge rstn_sys) begin
        if (~rstn_sys) begin
            tx_state    <=  #2 MAC_TX_STATE_IDLE;
        end
        else begin
            tx_state    <=  #2 tx_state_next;
        end
    end

    always @(posedge sys_clk or negedge rstn_sys) begin
        if (~rstn_sys) begin
            tx_arb_dir          <=  'b0;
            tx_loop_cnt         <=  'b0;
            tx_byte_cnt         <=  'b0;
            ptr_fifo_rd         <=  'b0;
            // data_fifo_rd        <=  'b0;
            tptr_fifo_rd        <=  'b0;
            // tdata_fifo_rd       <=  'b0;
            tx_ptr_afifo_din    <=  'b0;
            tx_ptr_afifo_wr     <=  'b0;
            tx_data_afifo_din   <=  'b0;
            tx_data_afifo_wr    <=  'b0;
            crc_init            <=  'b0;
            crc_cal             <=  'b0;
            crc_dv              <=  'b0;
        end
        else begin
            if (tx_state_next == MAC_TX_STATE_STAR && tx_state != MAC_TX_STATE_STAR) begin
                tx_arb_dir          <=  !tptr_fifo_empty;
                tx_ptr_afifo_wr     <=  'b0;
                ptr_fifo_rd         <=  tptr_fifo_empty;
                tptr_fifo_rd        <=  !tptr_fifo_empty;
            end
            else if (tx_state_next == MAC_TX_STATE_PREA && tx_state != MAC_TX_STATE_PREA) begin
                tx_loop_cnt         <=  'h7;
                tx_data_afifo_wr    <=  'b1;
                tx_data_afifo_din   <=  8'h55;
                ptr_fifo_rd         <=  'b0;
                tptr_fifo_rd        <=  'b0;
            end
            else if (tx_state_next == MAC_TX_STATE_PREA) begin
                tx_loop_cnt         <=  tx_loop_cnt - 1'b1;
                tx_byte_cnt         <=  (tx_arb_dir) ? tptr_fifo_din[10:0] : ptr_fifo_din[10:0];
                crc_init            <=  'b1;
            end
            else if (tx_state_next == MAC_TX_STATE_PDAT && tx_state != MAC_TX_STATE_PDAT) begin
                tx_loop_cnt         <=  (tx_byte_cnt < 60) ? 60 : tx_byte_cnt;
                // data_fifo_rd        <=  !tx_arb_dir;
                // tdata_fifo_rd       <=  tx_arb_dir;
                tx_data_afifo_din   <=  8'hd5;
                crc_cal             <=  'b1;
                crc_dv              <=  'b1;
                crc_init            <=  'b0;
            end
            // else if (tx_state_next == MAC_TX_STATE_DATA && tx_state != MAC_TX_STATE_DATA) begin
                // crc_init            <=  1'b0;
            // end
            else if (tx_state_next == MAC_TX_STATE_DATA) begin
                tx_loop_cnt         <=  tx_loop_cnt - 1'b1;
                tx_data_afifo_din   <=  tx_data_in;
            end
            else if (tx_state_next == MAC_TX_STATE_PCRC && tx_state != MAC_TX_STATE_PCRC) begin
                tx_loop_cnt         <=  'h5;
                tx_data_afifo_din   <=  tx_data_in;
                crc_cal             <=  'b0;
                crc_dv              <=  'b0;
                // data_fifo_rd    <=  'b0;
                // tdata_fifo_rd   <=  'b0;
            end
            else if (tx_state_next == MAC_TX_STATE_CRCV && tx_state !== MAC_TX_STATE_CRCV) begin
                tx_data_afifo_wr    <=  'b0;
                crc_dv              <=  'b1;
            end
            else if (tx_state_next == MAC_TX_STATE_CRCV) begin
                tx_loop_cnt         <=  tx_loop_cnt - 1'b1;
                tx_data_afifo_wr    <=  'b1;
                tx_data_afifo_din   <=  crc_dout;
            end
            else if (tx_state_next == MAC_TX_STATE_IDLE && tx_state != MAC_TX_STATE_IDLE) begin
                tx_data_afifo_wr    <=  'b0;
                tx_ptr_afifo_wr     <=  'b1;
                tx_ptr_afifo_din    <=  {4'b0, speed[1], tx_byte_cnt + 11'd12};
                crc_dv              <=  'b0;
            end
            else if (tx_state == MAC_TX_STATE_IDLE) begin
                // tx_loop_cnt         <=  tx_loop_cnt - 1'b1;
                tx_ptr_afifo_wr     <=  'b0;
            end
        end
    end

    crc32_8023 u_crc32_8023(
        .clk(sys_clk), 
        .reset(!rstn_sys), 
        .d(tx_data_in), 
        .load_init(crc_init),
        .calc(crc_cal), 
        .d_valid(crc_dv), 
        .crc_reg(crc_result), 
        .crc(crc_dout)
    );


    afifo_w8_d4k u_data_fifo_tx (
        .rst(!rstn_sys),                      // input rst
        .wr_clk(sys_clk),                     // input wr_clk
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
        .rst(!rstn_sys),                      // input rst
        .wr_clk(sys_clk),                     // input wr_clk
        .rd_clk(tx_master_clk),                // input rd_clk
        .din(tx_ptr_afifo_din),             // input [15 : 0] din
        .wr_en(tx_ptr_afifo_wr),            // input wr_en
        .rd_en(tx_ptr_afifo_rd),            // input rd_en
        .dout(tx_ptr_afifo_dout),           // output [15 : 0] dout
        .full(tx_ptr_afifo_full),           // output full
        .empty(tx_ptr_afifo_empty)      	// output empty
    );

    (*MARK_DEBUG="true"*) reg [ 7:0]  mii_state, mii_state_next;
    (*MARK_DEBUG="true"*) reg [10:0]  mii_cnt;
    (*MARK_DEBUG="true"*) reg         mii_dv;
    (*MARK_DEBUG="true"*) reg [ 7:0]  mii_d;

    always @(*) begin
        case (mii_state)
            MAC_MII_STATE_IDLE:
                mii_state_next  <=  (!tx_ptr_afifo_empty) ? MAC_MII_STATE_PTR1 : MAC_MII_STATE_IDLE;
            MAC_MII_STATE_PTR1:
                mii_state_next  <=  MAC_MII_STATE_PTR2;
            MAC_MII_STATE_PTR2:
                mii_state_next  <=  (tx_ptr_afifo_dout[11]) ? MAC_MII_STATE_GDAT : MAC_MII_STATE_DAT1;
            MAC_MII_STATE_DAT1:
                mii_state_next  <=  MAC_MII_STATE_DAT2;
            MAC_MII_STATE_DAT2:
                mii_state_next  <=  (mii_cnt == 'h0) ? MAC_MII_STATE_WAIT : MAC_MII_STATE_DAT1;
            MAC_MII_STATE_GDAT:
                mii_state_next  <=  (mii_cnt == 'h0) ? MAC_MII_STATE_WAIT : MAC_MII_STATE_GDAT;
            MAC_MII_STATE_WAIT:
                mii_state_next  <=  (mii_cnt == 'b0) ? MAC_MII_STATE_IDLE : MAC_MII_STATE_WAIT;
        endcase
    end

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mii_state   <=  #2 MAC_TX_STATE_IDLE;
        end
        else begin
            mii_state   <=  #2 mii_state_next;
        end
    end

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
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
                tx_data_afifo_rd    <=  (mii_cnt == 'b0) ? 'b0 : 'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_GDAT) begin
                tx_data_afifo_rd    <=  (mii_cnt == 'b1) ? 'b0 : 'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_WAIT) begin
                tx_data_afifo_rd    <=  'b0;
            end
        end
    end

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mii_cnt <=  'b0;
        end
        else begin
            if (mii_state_next == MAC_MII_STATE_DAT1) begin
                mii_cnt <=  (mii_state == MAC_MII_STATE_PTR2) ? tx_ptr_afifo_dout[10:0] - 1'b1 : mii_cnt - 1'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_GDAT) begin
                mii_cnt <=  (mii_state == MAC_MII_STATE_PTR2) ? tx_ptr_afifo_dout[10:0] - 1'b1 : mii_cnt - 1'b1;
            end
            else if (mii_state_next == MAC_MII_STATE_WAIT) begin
                mii_cnt <=  (mii_state == MAC_MII_STATE_WAIT) ? mii_cnt - 1'b1 : 'd12;
            end
        end
    end

    always @(posedge tx_master_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mii_dv  <=  'b0;
            mii_d   <=  'b0;
        end
        else begin
            if (mii_state == MAC_MII_STATE_DAT1) begin
                mii_d   <=  {4'b0, tx_data_afifo_dout[3:0]};
                mii_dv  <=  'b1;
            end
            else if (mii_state == MAC_MII_STATE_DAT2) begin
                mii_d   <=  {4'b0, tx_data_afifo_dout[7:4]};
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