`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: 
// Module Name: mac_r_gmii_tte
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


module mac_r_gmii_tte(
input               rstn_sys,
input               rstn_mac,
input               clk,

input               rx_clk,
input               rx_dv,
input       [7:0]   gm_rx_d,
output              gtx_clk,

input       [1:0]   speed,  //ethernet speed 00:10M 01:100M 10:1000M

input               data_fifo_rd,
output      [7:0]   data_fifo_dout,
input               ptr_fifo_rd, 
output      [15:0]  ptr_fifo_dout,
output              ptr_fifo_empty,
input               tte_fifo_rd,
output      [7:0]   tte_fifo_dout,
input               tteptr_fifo_rd, 
output      [15:0]  tteptr_fifo_dout,
output              tteptr_fifo_empty,

input       [31:0]  counter_ns,
input       [63:0]  counter_ns_tx_delay,
input       [63:0]  counter_ns_gtx_delay,

output              rx_mgnt_valid,
output      [19:0]  rx_mgnt_data,
input               rx_mgnt_resp
    );

parameter DELAY=2;  
parameter CRC_RESULT_VALUE=32'hc704dd7b;
parameter TTE_VALUE=8'h92;
parameter MTU=1500;
parameter PTP_VALUE_HIGH=8'h88;
parameter PTP_VALUE_LOWER=8'hf7;

//============================================  
//generte ptp message    
//============================================ 
wire    [63:0]  counter_ns_delay;
assign  counter_ns_delay = speed[1]?counter_ns_gtx_delay:counter_ns_tx_delay;

assign  gtx_clk = rx_clk & speed[1];
//============================================  
//generte a pipeline of input gm_rx_d.   
//============================================  
reg     [7:0]  rx_d_reg;
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        rx_d_reg<=#DELAY 0;
        end
    else if(speed[1])begin
        rx_d_reg<=#DELAY gm_rx_d;
        end
    else begin
        rx_d_reg<=#DELAY 0;
        end
//============================================  
//generte a pipeline of input m_rx_d.   
//============================================  
reg     [3:0]	rx_d_reg0;
reg     [3:0]   rx_d_reg1;
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        rx_d_reg0<=#DELAY 0;
        rx_d_reg1<=#DELAY 0;
        end
    else if(!speed[1])begin
        rx_d_reg0<=#DELAY gm_rx_d;
        rx_d_reg1<=#DELAY rx_d_reg0;        
        end
    else begin
        rx_d_reg0<=#DELAY 0;
        rx_d_reg1<=#DELAY 0;
        end
//============================================  
//generte a pipeline of input rx_dv.   
//============================================  
reg             rx_dv_reg0;
reg             rx_dv_reg1;
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        rx_dv_reg0<=#DELAY 0;
        rx_dv_reg1<=#DELAY 0;
        end
    else begin
        rx_dv_reg0<=#DELAY rx_dv;
        rx_dv_reg1<=#DELAY rx_dv_reg0;
        end
//============================================  
//generte internal control signals. 
//============================================  
wire dv_sof;
wire dv_eof;
wire sfd;
assign  dv_sof=rx_dv_reg0  & !rx_dv_reg1;
assign  dv_eof=!rx_dv_reg0 &  rx_dv_reg1;
assign  sfd=rx_dv_reg0  & ((rx_d_reg==8'b11010101) | (rx_d_reg0==4'b1101));

wire    nib_cnt_clr;
reg     [12:0]  nib_cnt;
wire    [12:0]  byte_cnt;
always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)nib_cnt<=#DELAY 0;
    else if(nib_cnt_clr) nib_cnt<=#DELAY 0; 
    else nib_cnt<=#DELAY nib_cnt+1; 

assign byte_cnt = speed[1]?nib_cnt:{1'b0,nib_cnt[12:1]};

wire    byte_dv;
assign  byte_dv=nib_cnt[0] | speed[1];

wire    byte_bp;
assign  byte_bp=(byte_cnt>(MTU+18));
//============================================  
//short-term rx_state.   
//============================================ 
reg     fv; 
wire    data_ram_wr;
assign  data_ram_wr=rx_dv_reg0 & fv & byte_dv;
wire    [10:0]  data_ram_addra;
assign  data_ram_addra=byte_cnt[10:0];
wire    [7:0]   data_ram_din;
assign  data_ram_din=rx_d_reg | {rx_d_reg0[3:0],rx_d_reg1[3:0]};
wire    [7:0]   data_ram_dout;
wire    [10:0]  data_ram_addrb;

reg     load_tte;
reg     load_be;
reg     load_req;
reg     [12:0]  load_byte;
reg     [2:0]   st_state;

assign  nib_cnt_clr=(dv_sof & sfd) | ((st_state==1)& sfd);

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        st_state<=#DELAY 0;
        load_tte<=#DELAY 0;
        load_be<=#DELAY 0;
        load_req<=#DELAY 0;
        load_byte<=#DELAY 0;
        fv<=#DELAY 0;
    end
    else begin
        case(st_state)
        0: begin
            if(dv_sof)begin
                if(!sfd) begin
                    st_state<=#DELAY 1;
                    end
                else begin
                    st_state<=#DELAY 2;
                    fv<=#DELAY 1;
                    end
                end
            end
        1:begin
            if(rx_dv_reg0)begin
                if(sfd) begin
                    fv<=#DELAY 1;
                    st_state<=#DELAY 2;
                    end
                end
            else st_state<=#DELAY 0;
            end
        2:begin
            if(byte_cnt==13 & byte_dv)begin
                st_state<=#DELAY 3;
                if(data_ram_din==TTE_VALUE)begin
                    load_tte<=#DELAY 1;
                    load_be<=#DELAY 0;
                end
                else begin
                    load_tte<=#DELAY 0;
                    load_be<=#DELAY 1;
                end
            end
            else if(dv_eof | (!rx_dv_reg0))begin
                fv<=#DELAY 0;
                st_state<=#DELAY 0;
            end
        end
        3:begin
            load_tte<=#DELAY 0;
            load_be<=#DELAY 0;
            st_state<=#DELAY 4;
        end
        4:begin
            if(dv_eof | (!rx_dv_reg0) | byte_bp)begin
                fv<=#DELAY 0;
                load_byte<=#DELAY byte_cnt;
                load_req<=#DELAY 1;
                st_state<=#DELAY 5;
                end
            end
        5:begin
            load_req<=#DELAY 0;
            st_state<=#DELAY 0;
        end
        endcase
    end


dpsram_w8_d2k u_data_ram(
  .clka(rx_clk),            // input wire clka
  .wea(data_ram_wr),        // input wire [0 : 0] wea
  .addra(data_ram_addra),   // input wire [10 : 0] addra
  .dina(data_ram_din),      // input wire [7 : 0] dina
  .clkb(rx_clk),            // input wire clkb
  .addrb(data_ram_addrb),   // input wire [10 : 0] addrb
  .doutb(data_ram_dout)     // output wire [7 : 0] doutb
);

//============================================  
//PTP_rx_state.   
//============================================ 

reg     [63:0]  ptp_messeage;
reg     [3:0]   ptp_reg_state;

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        ptp_reg_state<=#DELAY 0;
        ptp_messeage<=#DELAY 0;
    end
    else begin
        case(ptp_reg_state)
        0: begin
            if(dv_sof)begin
                if(!sfd) begin
                    ptp_reg_state<=#DELAY 1;
                    end
                else begin
                    ptp_reg_state<=#DELAY 2;
                    end
                end
            end
        1:begin
            if(rx_dv_reg0)begin
                if(sfd) begin
                    ptp_reg_state<=#DELAY 2;
                    end
                end
            else ptp_reg_state<=#DELAY 0;
            end
        2:begin
            if(byte_cnt==12 & byte_dv)begin
                if(data_ram_din==PTP_VALUE_HIGH)begin
                    ptp_reg_state<=#DELAY 3;
                end
                else begin
                    ptp_reg_state<=#DELAY 0;
                end
            end
        end
        3:begin
            if(byte_cnt==13 & byte_dv)begin
                if(data_ram_din==PTP_VALUE_LOWER)begin
                    ptp_reg_state<=#DELAY 4;
                end
                else begin
                    ptp_reg_state<=#DELAY 0;
                end
            end
        end
        4:begin
            if(byte_cnt==14 & byte_dv)begin
                if(data_ram_din[3:0]==4'b1001)begin
                    ptp_reg_state<=#DELAY 5;
                end
                else begin
                    ptp_reg_state<=#DELAY 0;
                end
            end
        end
        5:begin
            if(byte_cnt==22 & byte_dv)begin
                ptp_messeage[63:56]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 6;
            end
        end
        6:begin
            if(byte_cnt==23 & byte_dv)begin
                ptp_messeage[55:48]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 7;
            end
        end
        7:begin
            if(byte_cnt==24 & byte_dv)begin
                ptp_messeage[47:40]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 8;
            end
        end
        8:begin
            if(byte_cnt==25 & byte_dv)begin
                ptp_messeage[39:32]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 9;
            end
        end
        9:begin
            if(byte_cnt==26 & byte_dv)begin
                ptp_messeage[31:24]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 10;
            end
        end
        10:begin
            if(byte_cnt==27 & byte_dv)begin
                ptp_messeage[23:16]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 11;
            end
        end
        11:begin
            if(byte_cnt==28 & byte_dv)begin
                ptp_messeage[15:8]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 12;
            end
        end
        12:begin
            if(byte_cnt==29 & byte_dv)begin
                ptp_messeage[7:0]<=#DELAY data_ram_din;
                ptp_reg_state<=#DELAY 0;
            end
        end
        endcase
    end

//============================================  
//crc signal.   
//============================================ 
reg     [7:0]   crc_din;
wire    load_init;
wire    calc;
wire    d_valid;
wire    [31:0]  crc_result;

assign  load_init = nib_cnt_clr;

always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        crc_din<=#DELAY 0;
        end
    else begin
        crc_din<=#DELAY data_ram_dout;
        end

crc32_8023 u_crc32_8023(
    .clk(rx_clk), 
    .reset(!rstn_mac), 
    .d(crc_din), 
    .load_init(load_init),
    .calc(calc), 
    .d_valid(d_valid), 
    .crc_reg(crc_result), 
    .crc()
    );

//============================================  
//be state.   
//============================================  
reg     [12:0]  ram_nibble_be;
wire    [12:0]  ram_cnt_be;
reg     [7:0]	data_fifo_din_reg;
reg             data_fifo_wr;
reg             data_fifo_wr_reg;
wire            data_fifo_wr_dv;
wire    [11:0]  data_fifo_depth;
reg     [15:0]  ptr_fifo_din;
reg             ptr_fifo_wr;
wire            ptr_fifo_full;

assign  ram_cnt_be = speed[1]?ram_nibble_be:{1'b0,ram_nibble_be[12:1]};
assign  data_fifo_wr_dv = data_fifo_wr_reg & (ram_nibble_be[0] | speed[1]); 
//============================================  
//generte a pipeline    
//============================================  
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        data_fifo_wr_reg<=#DELAY 0;
        end
    else begin
        data_fifo_wr_reg<=#DELAY data_fifo_wr;
        end

always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        data_fifo_din_reg<=#DELAY 0;
        end
    else begin
        data_fifo_din_reg<=#DELAY data_ram_dout;
        end

wire    bp;
assign  bp=(data_fifo_depth>2564) | ptr_fifo_full;

reg     [2:0]   be_state;

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        be_state<=#DELAY 0;
        ptr_fifo_din<=#DELAY 0;
        ptr_fifo_wr<=#DELAY 0;
        data_fifo_wr<=#DELAY 0;
        ram_nibble_be<=#DELAY 0;
        end
    else begin
        case(be_state)
        0: begin
            if(load_be & !bp)begin
                ram_nibble_be<=#DELAY ram_nibble_be+1;
                be_state<=#DELAY 1;
                end
            end
        1:begin
            data_fifo_wr<=#DELAY 1;
            ram_nibble_be<=#DELAY ram_nibble_be+1;
            if(load_req)begin
                be_state<=#DELAY 2;
                end
        end
        2:begin
            if(ram_cnt_be<=load_byte)
                ram_nibble_be<=#DELAY ram_nibble_be+1;
            else begin
                data_fifo_wr<=#DELAY 0;
                be_state<=#DELAY 3;
            end
        end
        3:begin
            be_state<=#DELAY 4;
        end
        4:begin
            // ptr_fifo_din[12:0]<=#DELAY ram_cnt_be-1;
            ptr_fifo_din[12:0]<=#DELAY ram_cnt_be-5;
            // if((ram_cnt_be<65) | (ram_cnt_be>1519)) ptr_fifo_din[14]<=#DELAY 1;
            // else ptr_fifo_din[14]<=#DELAY 0;
            // if(crc_result==CRC_RESULT_VALUE) ptr_fifo_din[15]<=#DELAY 1'b0;
            // else ptr_fifo_din[15]<=#DELAY 1'b1;
            if(ram_cnt_be<65) ptr_fifo_din[14]<=#DELAY 1;
            else ptr_fifo_din[14]<=#DELAY 0;
            if(ram_cnt_be>1519) ptr_fifo_din[15]<=#DELAY 1;
            else ptr_fifo_din[15]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) ptr_fifo_din[13]<=#DELAY 1'b0;
            else ptr_fifo_din[13]<=#DELAY 1'b1;
            ptr_fifo_wr<=#DELAY 1;
            be_state<=#DELAY 5;
        end
        5:begin
            ptr_fifo_wr<=#DELAY 0;
            ram_nibble_be<=#DELAY 0;
            be_state<=#DELAY 0;
        end
        endcase
        end


//============================================  
//PTP rx_state.   
//============================================ 
reg     [7:0]   ptp_data; 
reg             ptp_sel;
reg     [5:0]   ptp_state;
reg     [31:0]  counter_ns_reg;
reg     [63:0]  ptp_message_pad;

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        ptp_state<=#DELAY 0;
        ptp_sel<=#DELAY 0;
        ptp_data<=#DELAY 0;
        counter_ns_reg<=#DELAY 0;
        ptp_message_pad<=#DELAY 0;
    end
    else begin
        case(ptp_state)
        0: begin
            if(ram_cnt_be==13)begin //mii
                if(data_ram_dout==PTP_VALUE_HIGH)begin
                    ptp_state<=#DELAY 1;
                end
            end
            else if(ram_cnt_be==14)begin //gmii
                if(data_ram_dout==PTP_VALUE_HIGH)begin
                    ptp_state<=#DELAY 8;
                end
            end
        end
        1:begin
            if(ram_cnt_be==14)begin
                if(data_ram_dout==PTP_VALUE_LOWER)begin
                    ptp_state<=#DELAY 2;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        2:begin
            if(ram_cnt_be==15)begin
                if(data_ram_dout[3:1]==0)begin
                    ptp_state<=#DELAY 3;
                end
                else if(data_ram_dout[3:0]==4'b1001)begin
                    ptp_state<=#DELAY 15;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        3:begin
            if(ram_cnt_be==30 & data_fifo_wr_dv)begin
                counter_ns_reg<=#DELAY counter_ns;
                ptp_data<=#DELAY counter_ns[31:24];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 4;
            end
        end
        4:begin
            if(ram_cnt_be==31 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[23:16];
                ptp_state<=#DELAY 5;
            end
        end
        5:begin
            if(ram_cnt_be==32 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[15:8];
                ptp_state<=#DELAY 6;
            end
        end
        6:begin
            if(ram_cnt_be==33 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[7:0];
                ptp_state<=#DELAY 7;
            end
        end
        7:begin
            if(ram_cnt_be==34 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY 0;
                ptp_state<=#DELAY 0;
                ptp_sel<=#DELAY 0;
            end
        end
        8:begin
            if(ram_cnt_be==15)begin
                if(data_ram_dout==PTP_VALUE_LOWER)begin
                    ptp_state<=#DELAY 9;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        9:begin
            if(ram_cnt_be==16)begin
                if(data_ram_dout[3:1]==0)begin
                    ptp_state<=#DELAY 10;
                end
                else if(data_ram_dout[3:0]==4'b1001)begin
                    ptp_message_pad<=#DELAY ptp_messeage+counter_ns_delay;
                    ptp_state<=#DELAY 24;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        10:begin
            if(ram_cnt_be==32 & data_fifo_wr_dv)begin
                counter_ns_reg<=#DELAY counter_ns;
                ptp_data<=#DELAY counter_ns[31:24];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 11;
            end
        end
        11:begin
            if(ram_cnt_be==33 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[23:16];
                ptp_state<=#DELAY 12;
            end
        end
        12:begin
            if(ram_cnt_be==34 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[15:8];
                ptp_state<=#DELAY 13;
            end
        end
        13:begin
            if(ram_cnt_be==35 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY counter_ns_reg[7:0];
                ptp_state<=#DELAY 14;
            end
        end
        14:begin
            if(ram_cnt_be==36 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY 0;
                ptp_state<=#DELAY 0;
                ptp_sel<=#DELAY 0;
            end
        end
        15:begin
            if(ram_cnt_be==22 & data_fifo_wr_dv)begin
                ptp_message_pad<=#DELAY ptp_messeage+counter_ns_delay;
                ptp_data<=#DELAY ptp_messeage[63:56];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 16;
            end
        end
        16:begin
            if(ram_cnt_be==23 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[55:48];
                ptp_state<=#DELAY 17;
            end
        end
        17:begin
            if(ram_cnt_be==24 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[47:40];
                ptp_state<=#DELAY 18;
            end
        end
        18:begin
            if(ram_cnt_be==25 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[39:32];
                ptp_state<=#DELAY 19;
            end
        end
        19:begin
            if(ram_cnt_be==26 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[31:24];
                ptp_state<=#DELAY 20;
            end
        end
        20:begin
            if(ram_cnt_be==27 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[23:16];
                ptp_state<=#DELAY 21;
            end
        end
        21:begin
            if(ram_cnt_be==28 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[15:8];
                ptp_state<=#DELAY 22;
            end
        end
        22:begin
            if(ram_cnt_be==29 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[7:0];
                ptp_state<=#DELAY 23;
            end
        end
        23:begin
            if(ram_cnt_be==30 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY 0;
                ptp_state<=#DELAY 0;
                ptp_sel<=#DELAY 0;
            end
        end
        24:begin
            if(ram_cnt_be==24 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[63:56];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 25;
            end
        end
        25:begin
            if(ram_cnt_be==25 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[55:48];
                ptp_state<=#DELAY 26;
            end
        end
        26:begin
            if(ram_cnt_be==26 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[47:40];
                ptp_state<=#DELAY 27;
            end
        end
        27:begin
            if(ram_cnt_be==27 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[39:32];
                ptp_state<=#DELAY 28;
            end
        end
        28:begin
            if(ram_cnt_be==28 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[31:24];
                ptp_state<=#DELAY 29;
            end
        end
        29:begin
            if(ram_cnt_be==29 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[23:16];
                ptp_state<=#DELAY 30;
            end
        end
        30:begin
            if(ram_cnt_be==30 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[15:8];
                ptp_state<=#DELAY 31;
            end
        end
        31:begin
            if(ram_cnt_be==31 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY ptp_message_pad[7:0];
                ptp_state<=#DELAY 32;
            end
        end
        32:begin
            if(ram_cnt_be==32 & data_fifo_wr_dv)begin
                ptp_data<=#DELAY 0;
                ptp_state<=#DELAY 0;
                ptp_sel<=#DELAY 0;
            end
        end
        endcase
    end



//============================================  
//tte state.   
//============================================  
reg     [12:0]  ram_nibble_tte;
wire    [12:0]  ram_cnt_tte;
reg     [7:0]	tte_fifo_din;
reg             tte_fifo_wr;
reg             tte_fifo_wr_reg;
wire            tte_fifo_wr_dv;
wire    [11:0]  tte_fifo_depth;
reg     [15:0]  tteptr_fifo_din;
reg             tteptr_fifo_wr;
wire            tteptr_fifo_full;

assign  ram_cnt_tte = speed[1]?ram_nibble_tte:{1'b0,ram_nibble_tte[12:1]};
assign  tte_fifo_wr_dv = tte_fifo_wr_reg & (ram_nibble_tte[0] | speed[1]);
//============================================  
//generte a pipeline    
//============================================  
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        tte_fifo_wr_reg<=#DELAY 0;
        end
    else begin
        tte_fifo_wr_reg<=#DELAY tte_fifo_wr;
        end

always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        tte_fifo_din<=#DELAY 0;
        end
    else begin
        tte_fifo_din<=#DELAY data_ram_dout;
        end

wire    tte_bp;
assign  tte_bp=(tte_fifo_depth>2564) | tteptr_fifo_full;

reg     [2:0]   tte_state;
always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        tte_state<=#DELAY 0;
        tteptr_fifo_din<=#DELAY 0;
        tteptr_fifo_wr<=#DELAY 0;
        tte_fifo_wr<=#DELAY 0;
        ram_nibble_tte<=#DELAY 0;
        end
    else begin
        case(tte_state)
        0: begin
            // if(load_tte & !bp)begin
            if(load_tte & !tte_bp) begin
                ram_nibble_tte<=#DELAY ram_nibble_tte+1;
                tte_state<=#DELAY 1;
                end
            end
        1:begin
            tte_fifo_wr<=#DELAY 1;
            ram_nibble_tte<=#DELAY ram_nibble_tte+1;
            if(load_req)begin
                tte_state<=#DELAY 2;
                end
        end
        2:begin
            if(ram_cnt_tte<=load_byte)
                ram_nibble_tte<=#DELAY ram_nibble_tte+1;
            else begin
                tte_fifo_wr<=#DELAY 0;
                tte_state<=#DELAY 3;
            end
        end
        3:begin
            tte_state<=#DELAY 4;
        end
        4:begin
            // tteptr_fifo_din[12:0]<=#DELAY ram_cnt_tte-1;
            tteptr_fifo_din[12:0]<=#DELAY ram_cnt_tte-5;
            // if((ram_cnt_tte<65) | (ram_cnt_tte>1519)) tteptr_fifo_din[14]<=#DELAY 1;
            // else tteptr_fifo_din[14]<=#DELAY 0;
            // if(crc_result==CRC_RESULT_VALUE) tteptr_fifo_din[15]<=#DELAY 1'b0;
            // else tteptr_fifo_din[15]<=#DELAY 1'b1;
            if(ram_cnt_tte<65) tteptr_fifo_din[14]<=#DELAY 1;
            else tteptr_fifo_din[14]<=#DELAY 0;
            if(ram_cnt_tte>1519) tteptr_fifo_din[15]<=#DELAY 1;
            else tteptr_fifo_din[15]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) tteptr_fifo_din[13]<=#DELAY 1'b0;
            else tteptr_fifo_din[13]<=#DELAY 1'b1;
            tteptr_fifo_wr<=#DELAY 1;
            tte_state<=#DELAY 5;
        end
        5:begin
            tteptr_fifo_wr<=#DELAY 0;
            ram_nibble_tte<=#DELAY 0;
            tte_state<=#DELAY 0;
        end
        endcase
        end

wire    [7:0]   data_fifo_din;

assign  data_ram_addrb = ram_cnt_be[10:0] | ram_cnt_tte[10:0] ;
assign  calc = data_fifo_wr_dv | tte_fifo_wr_dv;
assign  d_valid = data_fifo_wr_dv | tte_fifo_wr_dv;

assign  data_fifo_din = (ptp_sel==1)?ptp_data:data_fifo_din_reg;

//============================================  
//fifo used. 
//============================================  

(*MARK_DEBUG="true"*) wire dbg_data_empty;

afifo_reg_w8_d4k u_data_fifo (
  .rst(!rstn_sys),                  // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(data_fifo_din),              // input [7 : 0] din
  .wr_en(data_fifo_wr_dv),          // input wr_en
  .rd_en(data_fifo_rd),             // input rd_en
  .dout(data_fifo_dout),            // output [7 : 0]       
  .full(), 
  .empty(dbg_data_empty), 
  .rd_data_count(), 				// output [11 : 0] rd_data_count
  .wr_data_count(data_fifo_depth) 	// output [11 : 0] wr_data_count
);

afifo_w16_d32 u_ptr_fifo (
  .rst(!rstn_sys),                  // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(ptr_fifo_din),               // input [15 : 0] din
  .wr_en(ptr_fifo_wr),              // input wr_en
  .rd_en(ptr_fifo_rd),              // input rd_en
  .dout(ptr_fifo_dout),             // output [15 : 0] dout
  .full(ptr_fifo_full),             // output full
  .empty(ptr_fifo_empty)            // output empty
);
afifo_reg_w8_d4k u_tte_fifo (
  .rst(!rstn_sys),                  // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(tte_fifo_din),               // input [7 : 0] din
  .wr_en(tte_fifo_wr_dv),           // input wr_en
  .rd_en(tte_fifo_rd),              // input rd_en
  .dout(tte_fifo_dout),             // output [7 : 0]       
  .full(), 
  .empty(), 
  .rd_data_count(), 				// output [11 : 0] rd_data_count
  .wr_data_count(tte_fifo_depth) 	// output [11 : 0] wr_data_count
);

afifo_w16_d32 u_tteptr_fifo (
  .rst(!rstn_sys),                  // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(tteptr_fifo_din),            // input [15 : 0] din
  .wr_en(tteptr_fifo_wr),           // input wr_en
  .rd_en(tteptr_fifo_rd),           // input rd_en
  .dout(tteptr_fifo_dout),          // output [15 : 0] dout
  .full(tteptr_fifo_full),          // output full
  .empty(tteptr_fifo_empty)         // output empty
);

reg [ 3:0] mgnt_state, mgnt_state_next;
reg [11:0] mgnt_cnt;
reg [ 7:0] mgnt_flag;

always @(*) begin
    case(mgnt_state)
        01: begin
            if (load_be) begin
                if (!bp) mgnt_state_next = 2;
                else mgnt_state_next = 8;
            end
            else if (load_tte) begin
                if (!tte_bp) mgnt_state_next = 4;
                else mgnt_state_next = 8;
            end
            else begin
                mgnt_state_next = 1;
            end
        end
        02: mgnt_state_next  =   ptr_fifo_wr ? 8 : 2;
        04: mgnt_state_next  =   tteptr_fifo_wr ? 8 : 4;
        08: mgnt_state_next  =   rx_mgnt_resp ? 1 : 8;
        default: mgnt_state_next    =   1;
    endcase
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        mgnt_state  <=  1;
    end
    else begin
        mgnt_state  <=  mgnt_state_next;
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        mgnt_flag   <=  'b0;
        mgnt_cnt    <=  'b0;
    end
    else begin
        if (mgnt_state[0]) begin
            if (load_be && !bp) begin
                mgnt_flag[7]    <=  'b0;
                mgnt_flag[3]    <=  'b0;
            end
            else if (load_tte && !tte_bp) begin
                mgnt_flag[7]    <=  'b0;
                mgnt_flag[3]    <=  'b1;
            end
            else if ((load_be && bp) || (load_tte && tte_bp)) begin
                mgnt_flag[7]    <=  'b1;
                mgnt_flag[3]    <=  'b0;
            end
        end
        else if (mgnt_state[1] && ptr_fifo_wr) begin
            mgnt_cnt        <=  ptr_fifo_din[11:0];
            mgnt_flag[6:4]  <=  ptr_fifo_din[15:13];
        end
        else if (mgnt_state[2] && tteptr_fifo_wr) begin
            mgnt_cnt        <=  tteptr_fifo_din[11:0];
            mgnt_flag[6:4]  <=  tteptr_fifo_din[15:13];
        end
    end
end

assign  rx_mgnt_data    =   {mgnt_flag, mgnt_cnt};
assign  rx_mgnt_valid   =   (mgnt_state == 8);

// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_pkt_be;
// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_bp_fifo_be;
// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_bp_busy_be;
// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_pkt_tte;
// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_bp_fifo_tte;
// (*MARK_DEBUG="true"*)   reg [15:0] dbg_mac_r_bp_busy_tte;

// always @(posedge rx_clk or negedge rstn_mac) begin
//     if (!rstn_mac) begin
//         dbg_mac_r_pkt_be        <=  'b0;
//         dbg_mac_r_bp_fifo_be    <=  'b0;
//         dbg_mac_r_bp_busy_be    <=  'b0;
//     end
//     else begin
//         if (load_be) begin
//             if (be_state == 0 && !bp) begin
//                 dbg_mac_r_pkt_be    <=  dbg_mac_r_pkt_be + 1'b1;
//             end
//             else if (be_state == 0 && bp) begin
//                 dbg_mac_r_bp_fifo_be    <=  dbg_mac_r_bp_fifo_be + 1'b1;
//             end
//             else if (be_state != 0) begin
//                 dbg_mac_r_bp_busy_be    <=  dbg_mac_r_bp_busy_be + 1'b1;
//             end
//         end
//     end
// end

// always @(posedge rx_clk or negedge rstn_mac) begin
//     if (!rstn_mac) begin
//         dbg_mac_r_pkt_tte       <=  'b0;
//         dbg_mac_r_bp_fifo_tte   <=  'b0;
//         dbg_mac_r_bp_busy_tte   <=  'b0;
//     end
//     else begin
//         if (load_tte) begin
//             if (tte_state == 0 && !tte_bp) begin
//                 dbg_mac_r_pkt_tte       <=  dbg_mac_r_pkt_tte + 1'b1;
//             end
//             else if (tte_state == 0 && tte_bp) begin
//                 dbg_mac_r_bp_fifo_tte   <=  dbg_mac_r_bp_fifo_tte + 1'b1;
//             end
//             else if (tte_state != 0) begin
//                 dbg_mac_r_bp_busy_tte   <=  dbg_mac_r_bp_busy_tte + 1'b1;
//             end
//         end
//     end
// end

endmodule
