`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: RGMII TX interface
// Module Name: mac_t_rgmii
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 1.00 - Functionality Test Passed
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mac_t_rgmii(
    input           rstn_sys,       // async reset, system side
    input           tx_clk,         // mii/rgmii tx clk
    output          tx_dv,          // (g)mii tx valid
    output  [ 3:0]  tx_d,           // (g)mii tx data

    input           speed,          // speed from mdio

    // normal dataflow
    output          data_fifo_rd,
    input   [ 7:0]  data_fifo_dout, // registered output, better timing
    output reg      ptr_fifo_rd, 
    input   [15:0]  ptr_fifo_dout,
    input           ptr_fifo_empty

);

    reg     [ 1:0]  rstn_mac;

    always @(posedge tx_clk) begin
        rstn_mac    <=  {rstn_mac, rstn_sys};
    end

    reg     [ 5:0]  tx_state, tx_state_next;
    reg     [95:0]  tx_buffer;      // extended buffer for PTP operations
    reg     [ 3:0]  tx_buf_rdy;     // ready when buffer is filled

    reg     [11:0]  tx_cnt_front;   // frontend count
    reg     [ 4:0]  tx_cnt_front_1;
    reg     [11:0]  tx_cnt_back;    // backend count
    reg     [11:0]  tx_cnt_back_1;
    reg     [11:0]  tx_byte_cnt;    // total byte count
    reg     [ 1:0]  tx_byte_valid;
    reg             tx_read_req;    // generate read signal for 4-bit MII

    reg             data_fifo_en;
    assign          data_fifo_rd    =   data_fifo_en && (speed || tx_read_req);

    reg             crc_init;
    reg             crc_cal;
    reg             crc_dv;
    wire    [31:0]  crc_result;
    wire    [ 7:0]  crc_dout;

    wire    [ 7:0]  tx_data_in;
    wire    [15:0]  tx_ptr_in;
    assign          tx_data_in  =   data_fifo_dout;
    assign          tx_ptr_in   =   ptr_fifo_dout;

    always @(*) begin
        case(tx_state)
            'd01: tx_state_next = (!ptr_fifo_empty) ? 'd2 : 'd1;
            'd02: tx_state_next = 'd4;
            'd04: tx_state_next = 'd8;
            'd08: tx_state_next = (tx_cnt_front == tx_byte_cnt) && (speed || tx_read_req) ? 'd16 : 'd8;
            'd16: tx_state_next = (tx_cnt_front_1 == 'h17) ? 'd1 : 'd16;
            default: tx_state_next = tx_state;
        endcase
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            tx_state    <=  1;
        end
        else begin
            tx_state    <=  tx_state_next;
        end
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            tx_cnt_front    <=  'b1;
            tx_cnt_front_1  <=  'h2;
            tx_byte_valid   <=  'b0;
        end
        else begin
            if (data_fifo_rd) begin
                tx_cnt_front    <=  tx_cnt_front + 1'b1;
            end
            // else if (tx_state_next == 1) begin
            else if (tx_state_next[0]) begin
                // tx_cnt_front    <=  speed[1];
                tx_cnt_front    <=  'b1;
            end
            // if (tx_state_next == 32) begin
            if (tx_state[4]) begin
                if (speed || tx_read_req) begin
                    tx_cnt_front_1  <=  tx_cnt_front_1 + 1'b1;
                end
            end
            else begin
                tx_cnt_front_1  <=  speed ? 'h2 : 'b0;
            end
            tx_byte_valid   <=  {tx_byte_valid[0], data_fifo_rd};
        end
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            ptr_fifo_rd     <=  'b0;
            data_fifo_en    <=  'b0;
            tx_byte_cnt     <=  'b0;
            tx_read_req     <=  'b1;
        end        
        else begin
            // if (tx_state_next == 1) begin
            if (tx_state_next[0]) begin
                ptr_fifo_rd     <=  'b0;
                data_fifo_en    <=  'b0;
                tx_byte_cnt     <=  'b0;
                tx_read_req     <=  'b1;
            end
            // else if (tx_state_next == 2) begin
            else if (tx_state_next[1]) begin
                ptr_fifo_rd     <=  'b1;
                tx_read_req     <=  !tx_read_req;
            end
            // else if (tx_state_next == 4) begin
            else if (tx_state_next[2]) begin
                ptr_fifo_rd     <=  'b0;
                data_fifo_en    <=  'b1;
                tx_read_req     <=  !tx_read_req;
            end
            // else if (tx_state_next == 8) begin
            else if (tx_state_next[3]) begin
                // tx_byte_cnt     <=  tx_ptr_in[11:0] + !speed[1];
                tx_byte_cnt     <=  tx_ptr_in[11:0];
                tx_read_req     <=  !tx_read_req;
            end
            // else if (tx_state_next == 16) begin
            else if (tx_state_next[4]) begin
                data_fifo_en    <=  'b0;
                tx_read_req     <=  !tx_read_req;
            end
            // else if (tx_state_next == 32) begin
            // else if (tx_state_next[5]) begin
                // tx_read_req     <=  !tx_read_req;
            // end
        end
    end

    reg     [ 3:0]  mii_state, mii_state_next;

    reg     [ 7:0]  mii_d;
    reg             mii_dv;

    wire    [ 7:0]  mii_d_in;
    // assign          mii_d_in    =   (mii_state == 'h08)                 ?   crc_dout        :
    assign          mii_d_in    =   (mii_state[3])                      ?   crc_dout        :
                                    tx_buffer[7:0];

    always @(*) begin
        case(mii_state)
            'h01: mii_state_next = tx_buf_rdy[3] && (speed || tx_read_req)? 'h2 : 'h1;
            'h02: mii_state_next = (tx_cnt_back_1 == 0) && (speed || tx_read_req) ? 'h4 : 'h2;
            'h04: mii_state_next = (tx_cnt_back_1 == tx_byte_cnt) && (speed || tx_read_req) ? 'h8 : 'h4;
            'h08: mii_state_next = !tx_buf_rdy[3] && (speed || tx_read_req) ? 'h1 : 'h8;
            default: mii_state_next = mii_state; 
        endcase
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            mii_state   <=  'h1;
        end
        else begin
            mii_state   <=  mii_state_next;
        end
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            tx_buf_rdy  <=  'b0;
            crc_init    <=  'b0;
            crc_cal     <=  'b0;
            crc_dv      <=  'b0;
        end
        else begin
            if (tx_byte_valid[1]) begin
                tx_buf_rdy  <=  {tx_buf_rdy[2:0], 1'b1};
            end
            else if (mii_state[3] && (speed || tx_read_req)) begin
                tx_buf_rdy  <=  {tx_buf_rdy[2:0], 1'b0};
            end
            if (mii_state_next[0]) begin
                crc_init    <=  'b0;
                crc_cal     <=  'b0;
                crc_dv      <=  'b0;
            end
            else if (mii_state_next[1]) begin
                crc_init    <=  'b1;
                crc_cal     <=  'b0;
                crc_dv      <=  'b0;
            end
            else if (mii_state_next[2]) begin
                crc_init    <=  'b0;
                crc_cal     <=  'b1;
                // crc_dv      <=  'b1;
                crc_dv      <=  (speed || tx_read_req);
            end
            else if (mii_state_next[3]) begin
                crc_init    <=  'b0;
                crc_cal     <=  'b0;
                // crc_dv      <=  'b1;
                crc_dv      <=  (speed || !tx_read_req);
            end
        end
    end

    always @(posedge tx_clk) begin
        if (!rstn_mac) begin
            tx_buffer       <=  {8'hd5, {7{8'h55}}, {4{8'b0}}};
            tx_cnt_back_1   <=  12'hFFA;
            mii_d           <=  'b0;
            mii_dv          <=  'b0;
        end
        else begin  // initialize tx buffer
            if (tx_state[0]) begin
                tx_buffer   <=  {8'hd5, {7{8'h55}}, {4{8'b0}}};
            end
            else if (tx_byte_valid[1]) begin
                tx_buffer   <=  {tx_data_in, tx_buffer[95:8]};
            end
            else if (!mii_state_next[0] && (speed || tx_read_req)) begin
                tx_buffer   <=  {tx_data_in, tx_buffer[95:8]};
            end
            if (!mii_state_next[0]) begin
                // if (speed || tx_read_req) begin
                //     mii_d           <=  mii_d_in;
                //     mii_dv          <=  1'b1;
                // end
                // else begin
                //     mii_d           <=  mii_d >> 4;
                // end
                if (speed) begin
                    mii_d   <=  mii_d_in;
                    mii_dv  <=  1'b1;
                end
                else begin
                    if (tx_read_req) begin
                        mii_d   <=  {2{mii_d_in[3:0]}};
                        mii_dv  <=  1'b1;
                    end
                    else begin
                        mii_d   <=  {2{mii_d_in[7:4]}};
                    end
                end
            end
            else begin
                mii_dv          <=  'b0;
            end
            if (!mii_state[0]) begin
                if (speed || tx_read_req) begin
                    tx_cnt_back_1   <=  tx_cnt_back_1 + 1'b1;
                end
            end
            else begin
                tx_cnt_back_1   <=  12'hFFA;
            end
        end
    end

    oddr_4 u_oddr_4 (
        .din(mii_d),
        .clk(tx_clk),
        .q(tx_d)
    );

    oddr_1 u_oddr_1 (
        .din({2{mii_dv}}),
        .clk(tx_clk),
        .q(tx_dv)
    );

    crc32 u_crc32_8023(
        .clk(tx_clk),
        .rstn(rstn_sys), 
        .d(mii_d_in), 
        .load_init(crc_init),
        .calc(crc_cal), 
        .d_valid(crc_dv), 
        .crc_reg(crc_result), 
        .crc(crc_dout)
    );

endmodule