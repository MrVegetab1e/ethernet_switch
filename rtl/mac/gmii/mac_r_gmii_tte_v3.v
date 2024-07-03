`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: 
// Module Name: mac_r_gmii_tte_v3
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


module mac_r_gmii_tte_v3(
input               rstn_sys,
input               rstn_mac,
input               clk,

input               rx_clk,
input               rx_dv,
input       [7:0]   gm_rx_d,
output              gtx_clk,

input       [1:0]   speed,  //ethernet speed 00:10M 01:100M 10:1000M
// input       [7:0]   speed_ext,

input               data_fifo_rd,
output      [8:0]   data_fifo_dout,
input               ptr_fifo_rd, 
output      [19:0]  ptr_fifo_dout,
output              ptr_fifo_empty,
input               tte_fifo_rd,
output      [7:0]   tte_fifo_dout,
input               tteptr_fifo_rd, 
output      [19:0]  tteptr_fifo_dout,
output              tteptr_fifo_empty,

input       [31:0]  counter_ns,
input       [31:0]  delay_fifo_dout,
output reg          delay_fifo_rd,
input               delay_fifo_empty,
// input       [63:0]  counter_ns_tx_delay,
// input       [63:0]  counter_ns_gtx_delay,

output              rx_mgnt_valid,
output      [19:0]  rx_mgnt_data,
input               rx_mgnt_resp,

input               rx_conf_valid,
output              rx_conf_resp,
input       [55:0]  rx_conf_data,

input               mac_conf_valid,
output              mac_conf_resp,
input       [ 3:0]  mac_conf_data
    );

parameter   DELAY=2;  
parameter   CRC_RESULT_VALUE=32'hc704dd7b;
parameter   TTE_VALUE=8'h92;
parameter   MTU=1500;
parameter   PTP_VALUE_HIGH=8'h88;
parameter   PTP_VALUE_LOWER=8'hf7;
parameter   UDP_V4_VALUE_HIGH=8'h08;
parameter   UDP_V4_VALUE_LOW=8'h00;
parameter   UDP_V6_VALUE_HIGH=8'h86;
parameter   UDP_V6_VALUE_LOW=8'hdd;
parameter   LLDP_VALUE_HI       =   8'h08;
parameter   LLDP_VALUE_LO       =   8'h01;
parameter   LLDP_PARAM_PORT     =   16'h1;
parameter   LLDP_DBG_PROTO      =   16'h0800;
parameter   LLDP_DBG_MAC        =   48'h60BEB403060E;
parameter   LLDP_DBG_PORT       =   16'h1;
parameter   LLDP_DBG_SPEED      =   2'b11;
parameter   LLDP_DBG_MODE       =   4'h1;
parameter   BCS_PROT_TIMER      =   625000;
parameter   BCS_PROT_QUOTA      =   3072;

reg [ 2:0] conf_state, conf_state_next;
reg [ 1:0] conf_valid_buf;
reg [47:0] lldp_mac_next;
reg [ 3:0] lldp_port_next;
reg [ 3:0] lldp_mode_next;

always @(*) begin
    case(conf_state)
        1 : conf_state_next =   conf_valid_buf[1]   ? 2 : 1;
        2 : conf_state_next =                             4;
        4 : conf_state_next =   !conf_valid_buf[1]  ? 1 : 4;
        default : conf_state_next = conf_state;
    endcase
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        conf_state  <=  1;
    end
    else begin
        conf_state  <=  conf_state_next;
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        conf_valid_buf  <=  'b0;
    end
    else begin
        conf_valid_buf  <=  {conf_valid_buf, rx_conf_valid};
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        lldp_mac_next   <=  LLDP_DBG_MAC;
        lldp_port_next  <=  LLDP_DBG_PORT[3:0];
        lldp_mode_next  <=  LLDP_DBG_MODE;
    end
    else if (conf_state[1]) begin
        // {lldp_mode_next, lldp_port_next, lldp_mac_next} <=  rx_conf_data;
        lldp_mode_next  <=  rx_conf_data[55:52];
        lldp_port_next  <=  rx_conf_data[51:48];
        lldp_mac_next   <=  rx_conf_data[47: 0];
    end
end

assign rx_conf_resp = conf_state[2];

    reg     [ 2:0]  mac_conf_state, mac_conf_state_next;
    reg     [ 1:0]  mac_conf_valid_buf;
    reg     [ 3:0]  mac_conf_reg;

    always @(*) begin
        case(mac_conf_state)
            1 : mac_conf_state_next =   mac_conf_valid_buf[1]   ? 2 : 1;
            2 : mac_conf_state_next =                             4;
            4 : mac_conf_state_next =   !mac_conf_valid_buf[1]  ? 1 : 4;
            default : mac_conf_state_next = mac_conf_state;
        endcase
    end

    always @(posedge rx_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mac_conf_state  <=  1;
        end
        else begin
            mac_conf_state  <=  mac_conf_state_next;
        end
    end

    always @(posedge rx_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mac_conf_valid_buf  <=  'b0;
        end
        else begin
            mac_conf_valid_buf  <=  {mac_conf_valid_buf, mac_conf_valid};
        end
    end

    always @(posedge rx_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            mac_conf_reg    <=  'h0;
        end
        else if (mac_conf_state[1]) begin
            mac_conf_reg    <=  mac_conf_data;
        end
    end

    assign mac_conf_resp = mac_conf_state[2];


//============================================  
//generte ptp message    
//============================================ 

reg     [ 7:0]  ptp_state;
reg     [ 3:0]  ptp_delay_state, ptp_delay_state_next;
reg     [19:0]  ptp_timeout_us; // 5us per cycle
reg     [15:0]  ptp_timeout;

reg             ptp_ethertype_ip;

reg     [63:0]  counter_ns_delay;
always @(*) begin
    case(ptp_delay_state)
        01: ptp_delay_state_next = !delay_fifo_empty ? 2 : 1;
        02: ptp_delay_state_next = 4;
        04: ptp_delay_state_next = 8;
        08: ptp_delay_state_next = (ptp_state == 23) || (ptp_state == 32) || (ptp_state == 44) || (ptp_timeout == 400) ? 1 : 8;
        default: ptp_delay_state_next = ptp_delay_state;
    endcase
end
always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        ptp_delay_state <=  1;
    end
    else begin
        ptp_delay_state <=  ptp_delay_state_next;
    end
end
always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        delay_fifo_rd       <=  'b0;
        counter_ns_delay    <=  'b0;
        ptp_timeout_us      <=  'b0;
        ptp_timeout         <=  'b0;
    end
    else begin
        if (ptp_delay_state_next[1]) begin
            delay_fifo_rd   <=  'b1;
        end
        else begin
            delay_fifo_rd   <=  'b0;
        end
        if (ptp_delay_state[2]) begin
            counter_ns_delay    <=  {16'b0, delay_fifo_dout, 16'b0};
        end
        if (ptp_delay_state[3]) begin
            if (ptp_timeout_us != 'hF423F) begin
                ptp_timeout_us  <=  ptp_timeout_us + 1'b1;
            end
            else begin
                ptp_timeout_us  <=  'b0;
                ptp_timeout     <=  ptp_timeout + 1'b1;
            end
        end
        else begin
            ptp_timeout_us  <=  'b0;
            ptp_timeout     <=  'b0;
        end
    end
end
// assign  counter_ns_delay = speed[1]?counter_ns_gtx_delay:counter_ns_tx_delay;

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
assign  byte_bp=(byte_cnt>(MTU+19));
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
reg     load_lldp;
reg     load_req;
reg     [12:0]  load_byte;
reg     [2:0]   st_state;
reg     [7:0]   st_type_state, st_type_state_next;

assign  nib_cnt_clr=(dv_sof & sfd) | ((st_state==1)& sfd);

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        st_state<=#DELAY 0;
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
            if (dv_eof || !rx_dv_reg0) begin
                st_state<=#DELAY 4;
            end
            else if (byte_bp) begin
                st_state<=#DELAY 3;
            end
            if(dv_eof || !rx_dv_reg0 || byte_bp)begin
                fv<=#DELAY 0;
                load_byte<=#DELAY byte_cnt;
                load_req<=#DELAY 1;
                end
            end
        3:begin
            load_req<=#DELAY 0;
            if(dv_eof || !rx_dv_reg0)begin
                st_state<=#DELAY 0;
            end
        end
        4:begin
            load_req<=#DELAY 0;
            st_state<=#DELAY 0;
        end
        endcase
    end

always @(*) begin
    case(st_type_state)
        01: st_type_state_next  =   (nib_cnt_clr) ? 02 : 01;
        02: begin
            if (dv_eof || !rx_dv_reg0) begin
                st_type_state_next  =   01;
            end
            else if (byte_cnt == 12 && byte_dv) begin
                st_type_state_next  =   (data_ram_din == 8'h08) ? 08 : 04;
            end
            else begin
                st_type_state_next  =   02;
            end
        end
        04: begin
            if (dv_eof || !rx_dv_reg0) begin
                st_type_state_next  =   01;
            end
            else if (byte_cnt == 13 && byte_dv) begin
                st_type_state_next  =   16;
            end
            else begin
                st_type_state_next  =   04;
            end
        end
        08: begin
            if (dv_eof || !rx_dv_reg0) begin
                st_type_state_next  =   01;
            end
            else if (byte_cnt == 13 && byte_dv) begin
                st_type_state_next  =   (data_ram_din == TTE_VALUE)     ? 32 : 
                                        (data_ram_din == LLDP_VALUE_LO) ? 64 :
                                        16;
            end
            else begin
                st_type_state_next  =   08;
            end
        end
        16: st_type_state_next  =   (dv_eof || !rx_dv_reg0)     ? 01  :
                                    (byte_cnt == 31 && byte_dv) ? 128 : 16;
        32: st_type_state_next  =   (dv_eof || !rx_dv_reg0)     ? 01  :
                                    (byte_cnt == 31 && byte_dv) ? 128 : 32;
        64: st_type_state_next  =   (dv_eof || !rx_dv_reg0)     ? 01  :
                                    (byte_cnt == 31 && byte_dv) ? 128 : 64;
        128: st_type_state_next =   (dv_eof || !rx_dv_reg0)     ? 01 : 128;
        default: st_type_state_next = st_type_state;
    endcase
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        st_type_state   <=  1;
    end
    else begin
        st_type_state   <=  st_type_state_next;
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        load_tte<=#DELAY 0;
        load_be<=#DELAY 0;
        load_lldp<=#DELAY 0;
    end
    else begin
        if (byte_cnt == 31) begin
            if (st_type_state[4]) begin
                load_tte<=#DELAY 0; 
                load_be<=#DELAY 1;
                load_lldp<=#DELAY 0;        
            end
            else if (st_type_state[5]) begin
                load_tte<=#DELAY 1;
                load_be<=#DELAY 0;
                load_lldp<=#DELAY 0;
            end
            else if (st_type_state[6]) begin
                load_tte<=#DELAY 0;
                load_be<=#DELAY 1;
                load_lldp<=#DELAY 1;
            end
        end
        else begin
            load_tte<=#DELAY 0;
            load_be<=#DELAY 0;
            load_lldp<=#DELAY 0;
        end
    end
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
                    else if (data_ram_din==UDP_V4_VALUE_HIGH) begin
                        ptp_reg_state<=#DELAY 8;
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
                if(byte_cnt==21 & byte_dv)begin
                    ptp_reg_state<=#DELAY 6;
                end
            end
            6:begin
                if(byte_dv)begin
                    if (byte_cnt==29) ptp_reg_state<=#DELAY 0;
                    ptp_messeage<=#DELAY {ptp_messeage, data_ram_din};
                end
            end
            8:begin
                if(byte_cnt==13 & byte_dv)begin
                    if(data_ram_din==UDP_V4_VALUE_LOW)begin
                        ptp_reg_state<=#DELAY 9;
                    end
                    else begin
                        ptp_reg_state<=#DELAY 0;
                    end
                end
            end
            9:begin
                if(byte_cnt==23 & byte_dv)begin
                    if(data_ram_din==8'h11)begin
                        ptp_reg_state<=#DELAY 10;
                    end
                    else begin
                        ptp_reg_state<=#DELAY 0;
                    end
                end
            end
            10:begin
                if(byte_cnt==36 & byte_dv)begin
                    if(data_ram_din==8'h01)begin
                        ptp_reg_state<=#DELAY 11;
                    end
                    else begin
                        ptp_reg_state<=#DELAY 0;
                    end
                end
            end
            11:begin
                if(byte_cnt==37 & byte_dv)begin
                    if(data_ram_din==8'h40)begin
                        ptp_reg_state<=#DELAY 12;
                    end
                    else begin
                        ptp_reg_state<=#DELAY 0;
                    end
                end
            end
            12:begin
                if(byte_cnt==42 & byte_dv)begin
                    if(data_ram_din[3:0]==4'b1001)begin
                        ptp_reg_state<=#DELAY 13;
                    end
                    else begin
                        ptp_reg_state<=#DELAY 0;
                    end
                end
            end
            13:begin
                if(byte_cnt==49 & byte_dv)begin
                    ptp_reg_state<=#DELAY 14;
                end
            end
            14:begin
                if(byte_dv)begin
                    if (byte_cnt==57) ptp_reg_state<=#DELAY 0;
                    ptp_messeage<=#DELAY {ptp_messeage, data_ram_din};
                end
            end
            default: begin
                ptp_reg_state<=#DELAY 0;
                ptp_messeage<=#DELAY 0;
            end
        endcase
    end

reg     [ 3:0]  lldp_reg_state;
reg     [15:0]  lldp_reg_buf;
reg     [17:0]  lldp_reg_cksm;

always @(posedge rx_clk or negedge rstn_mac) begin
    if(!rstn_mac)begin
        lldp_reg_state<=#DELAY 0;
        lldp_reg_cksm<=#DELAY 0;
    end
    else begin
        if (byte_dv) begin
            lldp_reg_buf<=#DELAY {lldp_reg_buf, data_ram_din};
        end
        if (byte_cnt==58 && byte_dv) begin
            lldp_reg_cksm<=#DELAY {2'b0, lldp_reg_buf};
        end
        if (byte_cnt==60 && byte_dv) begin
            lldp_reg_cksm<=#DELAY lldp_reg_cksm + {2'b0, lldp_reg_buf};
        end
        if (byte_cnt==62 && byte_dv) begin
            lldp_reg_cksm<=#DELAY lldp_reg_cksm + {2'b0, lldp_reg_buf};
        end
    end
end

//============================================  
//crc signal.   
//============================================ 
reg     [7:0]   crc_din;
wire    load_init;
wire    calc;
wire    d_valid;
wire    [31:0]  crc_result;

// assign  load_init = nib_cnt_clr;
// assign  load_init = |(st_type_state[6:4]);
assign  load_init = (load_be || load_tte);

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

reg [12:0]  tailtag_pos;
reg [ 3:0]  tailtag_port;

//============================================  
//be state.   
//============================================  
reg     [12:0]  ram_nibble_be;
wire    [12:0]  ram_cnt_be;
reg     [11:0]  load_byte_be;
reg     [7:0]	data_fifo_din_reg;
reg             data_fifo_wr;
reg             data_fifo_wr_reg;
reg             data_fifo_wr_reg_1;
(*MARK_DEBUG="true"*) wire            data_fifo_wr_dv;
(*MARK_DEBUG="true"*) wire    [11:0]  data_fifo_depth;
(*MARK_DEBUG="true"*) reg     [19:0]  ptr_fifo_din;
(*MARK_DEBUG="true"*) reg             ptr_fifo_wr;
(*MARK_DEBUG="true"*) wire            ptr_fifo_full;

reg [ 4:0] lldp_state, lldp_state_next;
reg [ 7:0] lldp_data;
reg [47:0] lldp_mac;
reg [15:0] lldp_port;
reg [ 1:0] lldp_speed_i;
// reg [ 1:0] lldp_speed_o;
reg [ 3:0] lldp_mode;
reg [23:0] lldp_cksm;
reg [15:0] lldp_cksm_1;
reg        lldp_sel;

reg     [ 5:0]  bcs_prot_cnt_bc;
reg             bcs_prot_cnt_gc;
reg     [27:0]  bcs_prot_cnt;
// reg     [15:0]  bcs_prot_quota;
reg     [15:0]  bcs_prot_byte_cnt_bc;
reg     [15:0]  bcs_prot_byte_cnt_gc;
reg             bcs_prot_block_bc;
reg             bcs_prot_block_gc;
reg             bcs_prot_drop_bc;
reg             bcs_prot_drop_gc;

assign  ram_cnt_be = speed[1]?ram_nibble_be:{1'b0,ram_nibble_be[12:1]};
assign  data_fifo_wr_dv = data_fifo_wr_reg & (ram_nibble_be[0] | speed[1]); 
//============================================  
//generte a pipeline    
//============================================  
always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        data_fifo_wr_reg <= #DELAY 0;
        data_fifo_wr_reg_1 <= #DELAY 0;
        end
    else begin
        data_fifo_wr_reg <= #DELAY data_fifo_wr;
        data_fifo_wr_reg_1 <= #DELAY data_fifo_wr_reg;
        end

always @(posedge rx_clk or negedge rstn_mac)
    if(!rstn_mac)begin
        data_fifo_din_reg<=#DELAY 0;
        end
    else begin
        data_fifo_din_reg<=#DELAY data_ram_dout;
        end

wire    bp;
assign  bp=(data_fifo_depth>2240) || ptr_fifo_full;

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
            else begin
                ram_nibble_be<=#DELAY 0;
            end
        end
        1:begin
            data_fifo_wr<=#DELAY 1;
            ram_nibble_be<=#DELAY ram_nibble_be+1;
            if(load_req)begin
                be_state<=#DELAY 2;
                load_byte_be<=#DELAY load_byte;
                end
        end
        2:begin
            if(ram_cnt_be<=load_byte_be)
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
            ptr_fifo_din[11:0]<=#DELAY ram_cnt_be-5;
            // if(mac_conf_reg[0]) ptr_fifo_din[11:0]<=#DELAY ram_cnt_be-6;
            // else ptr_fifo_din[11:0]<=#DELAY ram_cnt_be-5;
            // if((ram_cnt_be<65) | (ram_cnt_be>1519)) ptr_fifo_din[14]<=#DELAY 1;
            // else ptr_fifo_din[14]<=#DELAY 0;
            // if(crc_result==CRC_RESULT_VALUE) ptr_fifo_din[15]<=#DELAY 1'b0;
            // else ptr_fifo_din[15]<=#DELAY 1'b1;
            // if(mac_conf_reg[0] && ram_cnt_be<66) ptr_fifo_din[14]<=#DELAY 1;
            // else if(!mac_conf_reg[0] && ram_cnt_be<65) ptr_fifo_din[14]<=#DELAY 1;
            if(ram_cnt_be<65) ptr_fifo_din[14]<=#DELAY 1;
            else if (bcs_prot_drop_bc || bcs_prot_drop_gc) ptr_fifo_din[14]<=#DELAY 1;
            else ptr_fifo_din[14]<=#DELAY 0;
            // if(mac_conf_reg[0] && ram_cnt_be>1520) ptr_fifo_din[15]<=#DELAY 1;
            // else if(!mac_conf_reg[0] && ram_cnt_be>1519) ptr_fifo_din[15]<=#DELAY 1;
            if(ram_cnt_be>MTU+19) ptr_fifo_din[15]<=#DELAY 1;
            else if (bcs_prot_drop_bc || bcs_prot_drop_gc) ptr_fifo_din[15]<=#DELAY 1;
            else ptr_fifo_din[15]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) ptr_fifo_din[13]<=#DELAY 1'b0;
            else ptr_fifo_din[13]<=#DELAY 1'b1;
            // lldp pre-route
            ptr_fifo_din[12] <= mac_conf_reg[0];
            // if(!lldp_state[0]) ptr_fifo_din[19:16]<=#DELAY LLDP_DBG_PORT[3:0];
            if(mac_conf_reg[0]) ptr_fifo_din[19:16]<=#DELAY ptp_ethertype_ip ? 4'b0 : tailtag_port[3:0];
            else if(!lldp_state[0]) ptr_fifo_din[19:16]<=#DELAY lldp_port[3:0];
            else ptr_fifo_din[19:16]<=#DELAY 4'b0;
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

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        bcs_prot_cnt            <=  'b0;
        bcs_prot_cnt_bc         <=  'b0;
        bcs_prot_cnt_gc         <=  'b0;
        // bcs_prot_quota          <=  BCS_PROT_QUOTA;
        bcs_prot_byte_cnt_bc    <=  'b0;
        bcs_prot_byte_cnt_gc    <=  'b0;
        bcs_prot_block_bc       <=  'b0;
        bcs_prot_block_gc       <=  'b0;
        bcs_prot_drop_bc        <=  'b0;
        bcs_prot_drop_gc        <=  'b0;
    end
    else begin
        if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
            bcs_prot_cnt        <=  'b0;
        end
        else begin
            bcs_prot_cnt        <=  bcs_prot_cnt + 1'b1;
        end
        if (be_state != 0) begin
            if (speed[1]) begin
                if (ram_cnt_be > 1 && ram_cnt_be < 8) begin
                    bcs_prot_cnt_bc <=  (data_ram_dout == 8'hFF) ? bcs_prot_cnt_bc + 1'b1 : bcs_prot_cnt_bc;
                end
                if (ram_cnt_be == 2) begin
                    bcs_prot_cnt_gc <=  data_ram_dout[0];
                end
            end
            else begin
                if (!ram_nibble_be[0] && ram_cnt_be > 0 && ram_cnt_be < 7) begin
                    bcs_prot_cnt_bc <=  (data_ram_dout == 8'hFF) ? bcs_prot_cnt_bc + 1'b1 : bcs_prot_cnt_bc;
                end
                if (!ram_nibble_be[0] && ram_cnt_be == 1) begin
                    bcs_prot_cnt_gc <=  data_ram_dout[0];
                end
            end
        end
        else begin
            bcs_prot_cnt_bc <=  'b0;
            bcs_prot_cnt_gc <=  'b0;
        end
        // if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
        //     bcs_prot_quota      <=  BCS_PROT_QUOTA;
        // end
        if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
            bcs_prot_byte_cnt_bc    <=  'b0;
        end
        else if (ptr_fifo_wr && ~|(ptr_fifo_din[15:13]) && bcs_prot_cnt_bc == 'h6 && lldp_state[0]) begin
            bcs_prot_byte_cnt_bc   <=  bcs_prot_byte_cnt_bc + ptr_fifo_din[11:0];
        end
        if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
            bcs_prot_byte_cnt_gc    <=  'b0;
        end
        else if (ptr_fifo_wr && ~|(ptr_fifo_din[15:13]) && bcs_prot_cnt_bc != 'h6 && bcs_prot_cnt_gc && lldp_state[0]) begin
            bcs_prot_byte_cnt_gc   <=  bcs_prot_byte_cnt_gc + ptr_fifo_din[11:0];
        end
        if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
            bcs_prot_block_bc   <=  'b0;
        end
        else if (mac_conf_reg[1] && bcs_prot_byte_cnt_bc >= BCS_PROT_QUOTA) begin
            bcs_prot_block_bc   <=  'b1;
        end
        if (bcs_prot_cnt == BCS_PROT_TIMER - 1) begin
            bcs_prot_block_gc   <=  'b0;
        end
        else if (mac_conf_reg[2] && bcs_prot_byte_cnt_gc >= BCS_PROT_QUOTA) begin
            bcs_prot_block_gc   <=  'b1;
        end
        if (be_state == 3) begin
            bcs_prot_drop_bc    <=  bcs_prot_block_bc && bcs_prot_cnt_bc == 'h6 && lldp_state[0];
            bcs_prot_drop_gc    <=  bcs_prot_block_gc && bcs_prot_cnt_bc != 'h6 && bcs_prot_cnt_gc && lldp_state[0];
        end
    end
end

//============================================  
//PTP rx_state.   
//============================================ 
    reg     [7:0]   ptp_data; 
    reg             ptp_sel;
    // reg     [5:0]   ptp_state;
    reg     [31:0]  counter_ns_reg;
    reg     [63:0]  ptp_message_pad;

    reg     [31:0]  ptp_time_now;   // timestamp of now
    reg     [31:0]  ptp_time_now_1;
    reg     [31:0]  ptp_time_now_sys;   // timestamp of now, system side
    reg             ptp_time_req;       // lockup counter output for cross clk domain
    reg     [ 1:0]  ptp_time_req_mac;
    reg     [ 1:0]  ptp_time_rdy_sys;   // system side of lockup signal
    reg     [ 1:0]  ptp_time_rdy_mac;   // mac side of lockup signal

    always @(posedge clk or negedge rstn_sys) begin
        if (!rstn_sys) begin
            ptp_time_rdy_sys    <=  'b0;
            ptp_time_now_sys    <=  'b0;
        end
        else begin
            ptp_time_rdy_sys    <=  {ptp_time_rdy_sys[0], ptp_time_req_mac[1]};
            ptp_time_now_sys    <=  ptp_time_rdy_sys[1] ? ptp_time_now_sys : counter_ns;
        end
    end

    // always @(posedge tx_master_clk or negedge rstn_mac) begin
    always @(posedge rx_clk or negedge rstn_mac) begin
        if (!rstn_mac) begin
            ptp_time_now        <=  'b0;
            ptp_time_req_mac    <=  'b0;    // pulse signal
            ptp_time_rdy_mac    <=  'b0;
        end
        else begin
            ptp_time_req_mac[0] <=  (ptp_time_req || (ptp_time_req_mac && ~ptp_time_rdy_mac[1]));
            ptp_time_req_mac[1] <=  ptp_time_req_mac[0];
            ptp_time_rdy_mac    <=  {ptp_time_rdy_mac[0], ptp_time_rdy_sys[1]};
            ptp_time_now        <=  (ptp_time_req_mac == 2'b10) ? ptp_time_now_sys : ptp_time_now;
            // ptp_time_now        <=  (ptp_time_req_mac[0] && ptp_time_rdy_mac[1]) ? ptp_time_now_sys : ptp_time_now;
        end
    end

always @(posedge rx_clk  or negedge rstn_mac)
    if(!rstn_mac)begin
        ptp_state<=#DELAY 0;
        ptp_sel<=#DELAY 0;
        ptp_data<=#DELAY 0;
        // counter_ns_reg<=#DELAY 0;
        ptp_message_pad<=#DELAY 0;
        ptp_time_req<=#DELAY 0;
        ptp_ethertype_ip<=#DELAY 0;
    end
    else begin
        ptp_time_req<=#DELAY 0;
        case(ptp_state)
        0: begin
            if(!speed[1] && ram_cnt_be==13)begin //mii
                if(data_ram_dout==PTP_VALUE_HIGH)begin
                    ptp_state<=#DELAY 1;
                    ptp_ethertype_ip<=#DELAY 0;
                end
                else if(data_ram_dout==UDP_V4_VALUE_HIGH)begin
                    ptp_state<=#DELAY 35;
                end
                else if(data_ram_dout==UDP_V6_VALUE_HIGH)begin
                    ptp_state<=#DELAY 45;
                end
                else begin
                    ptp_ethertype_ip<=#DELAY 0;
                end
            end
            else if(speed[1] && ram_cnt_be==14)begin //gmii
                if(data_ram_dout==PTP_VALUE_HIGH)begin
                    ptp_state<=#DELAY 8;
                    ptp_ethertype_ip<=#DELAY 0;
                end
                else if(data_ram_dout==UDP_V4_VALUE_HIGH)begin
                    ptp_state<=#DELAY 35;
                end
                else if(data_ram_dout==UDP_V6_VALUE_HIGH)begin
                    ptp_state<=#DELAY 45;
                end
                else begin
                    ptp_ethertype_ip<=#DELAY 0;
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
                    // ptp_state<=#DELAY 3;
                    ptp_state<=#DELAY 33;
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
                // counter_ns_reg<=#DELAY counter_ns;
                // ptp_data<=#DELAY counter_ns[31:24];
                ptp_data<=#DELAY ptp_time_now[31:24];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 4;
            end
        end
        4:begin
            if(ram_cnt_be==31 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[23:16];
                ptp_data<=#DELAY ptp_time_now[23:16];
                ptp_state<=#DELAY 5;
            end
        end
        5:begin
            if(ram_cnt_be==32 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[15:8];
                ptp_data<=#DELAY ptp_time_now[15:8];
                ptp_state<=#DELAY 6;
            end
        end
        6:begin
            if(ram_cnt_be==33 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[7:0];
                ptp_data<=#DELAY ptp_time_now[7:0];
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
                    // ptp_state<=#DELAY 10;
                    ptp_state<=#DELAY 34;
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
                // counter_ns_reg<=#DELAY counter_ns;
                // ptp_data<=#DELAY counter_ns[31:24];
                ptp_data<=#DELAY ptp_time_now[31:24];
                ptp_sel<=#DELAY 1;
                ptp_state<=#DELAY 11;
            end
        end
        11:begin
            if(ram_cnt_be==33 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[23:16];
                ptp_data<=#DELAY ptp_time_now[23:16];
                ptp_state<=#DELAY 12;
            end
        end
        12:begin
            if(ram_cnt_be==34 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[15:8];
                ptp_data<=#DELAY ptp_time_now[15:8];
                ptp_state<=#DELAY 13;
            end
        end
        13:begin
            if(ram_cnt_be==35 & data_fifo_wr_dv)begin
                // ptp_data<=#DELAY counter_ns_reg[7:0];
                ptp_data<=#DELAY ptp_time_now[7:0];
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
        33:begin
            if(ram_cnt_be==22 & data_fifo_wr_dv)begin
                ptp_time_req<=#DELAY 1;
                ptp_state<=#DELAY 3;
            end
        end
        34:begin
            if(ram_cnt_be==24 & data_fifo_wr_dv)begin
                ptp_time_req<=#DELAY 1;
                ptp_state<=#DELAY 10;
            end
        end
        35:begin
            if ((!speed[1] && ram_cnt_be==14) || (speed[1] && ram_cnt_be==15))begin
                if(data_ram_dout==UDP_V4_VALUE_LOW)begin
                    ptp_state<=#DELAY 36;
                    ptp_ethertype_ip<=#DELAY 1;
                end
                else begin
                    ptp_state<=#DELAY 0;
                    ptp_ethertype_ip<=#DELAY 0;
                end
            end
        end
        36:begin
            if ((!speed[1] && ram_cnt_be==24) || (speed[1] && ram_cnt_be==25)) begin
                if(data_ram_dout==8'h11)begin
                    ptp_state<=#DELAY 37;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        37:begin
            if ((!speed[1] && ram_cnt_be==37) || (speed[1] && ram_cnt_be==38)) begin
                if(data_ram_dout==8'h01)begin
                    ptp_state<=#DELAY 38;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        38:begin
            if ((!speed[1] && ram_cnt_be==38) || (speed[1] && ram_cnt_be==39)) begin
                if(data_ram_dout==8'h3F)begin // event message
                    ptp_state<=#DELAY 39;
                end
                else if(data_ram_dout==8'h40)begin // general message
                    ptp_state<=#DELAY 42;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        39:begin
            if ((!speed[1] && ram_cnt_be==43) || (speed[1] && ram_cnt_be==44)) begin
                if(data_ram_dout[3:1]==0)begin // sync & delay_req
                    // ptp_state<=#DELAY 10;
                    ptp_state<=#DELAY 40;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        40:begin
            if (!speed[1]) begin
                if (ram_cnt_be == 50 & !data_fifo_wr_dv) begin
                    ptp_time_req<=#DELAY 1;
                end
                else begin
                    ptp_time_req<=#DELAY 0;
                end
                if (ram_cnt_be == 58 & !data_fifo_wr_dv) begin
                    ptp_time_now_1 <= ptp_time_now;
                    ptp_state<=#DELAY 41;
                end
            end
            else begin
                if (ram_cnt_be == 51) begin
                    ptp_time_req<=#DELAY 1;
                end
                else begin
                    ptp_time_req<=#DELAY 0;
                end
                if (ram_cnt_be == 59) begin
                    ptp_time_now_1 <= ptp_time_now;
                    ptp_state<=#DELAY 41;
                end
            end
        end
        41:begin
            if (speed[1] || !data_fifo_wr_dv) begin
                ptp_data<=#DELAY ptp_time_now_1[31:24];
                ptp_time_now_1<=#DELAY ptp_time_now_1 << 8;
                if (ram_cnt_be == 63 && !speed[1]) begin
                    ptp_sel<=#DELAY 0;
                    ptp_state<=#DELAY 0;
                end
                else if (ram_cnt_be == 64 && speed[1]) begin
                    ptp_sel<=#DELAY 0;
                    ptp_state<=#DELAY 0;
                end
                else begin
                    ptp_sel<=#DELAY 1;
                end
            end
        end
        42:begin
            if ((!speed[1] && ram_cnt_be==43) || (speed[1] && ram_cnt_be==44)) begin
                if(data_ram_dout[3:0]==4'b1001)begin // delay_resp
                    ptp_message_pad<=#DELAY ptp_messeage+counter_ns_delay;
                    ptp_state<=#DELAY 43;
                end
                else begin
                    ptp_state<=#DELAY 0;
                end
            end
        end
        43:begin
            if (speed[1] || !data_fifo_wr_dv) begin
                if (ram_cnt_be == 50 && !speed[1]) begin
                    ptp_state<=#DELAY 44;
                end
                else if (ram_cnt_be == 51 && speed[1]) begin
                    ptp_state<=#DELAY 44;
                end
            end
        end
        44:begin
            if (speed[1] || !data_fifo_wr_dv) begin
                ptp_data<=#DELAY ptp_message_pad[63:56];
                ptp_message_pad<=#DELAY ptp_message_pad << 8;
                if (ram_cnt_be == 59 && !speed[1]) begin
                    ptp_sel<=#DELAY 0;
                    ptp_state<=#DELAY 0;
                end
                else if (ram_cnt_be == 60 && speed[1]) begin
                    ptp_sel<=#DELAY 0;
                    ptp_state<=#DELAY 0;
                end
                else begin
                    ptp_sel<=#DELAY 1;
                end
            end
        end
        45:begin
            if ((!speed[1] && ram_cnt_be==14) || (speed[1] && ram_cnt_be==15))begin
                if(data_ram_dout==UDP_V6_VALUE_LOW)begin
                        ptp_state<=#DELAY 0;
                        ptp_ethertype_ip<=#DELAY 1;
                end
                else begin
                        ptp_state<=#DELAY 0;
                        ptp_ethertype_ip<=#DELAY 0;
                end
            end
        end
        endcase
    end

always @(*) begin
    case(lldp_state)
        // 01: begin
        //     if (load_be && load_lldp) begin
        //         if (speed[1]) begin
        //             lldp_state_next =   2;
        //         end
        //         else begin
        //             lldp_state_next =   4;
        //         end
        //     end 
        //     else begin
        //         lldp_state_next =   1;
        //     end 
        // end  
        01: lldp_state_next = (load_be && load_lldp && !bp)  ? 2 : 1;
        02: lldp_state_next = lldp_mode[1]                   ? 16:
                              lldp_mode[0]                   ? (speed[1] ? 4 : 8) : 
                              1;
        04: lldp_state_next = (be_state == 5)                ? 1 : 4;
        08: lldp_state_next = (be_state == 5)                ? 1 : 8;
        16: lldp_state_next = (be_state == 5)                ? 1 : 16;
        default: lldp_state_next = lldp_state;
    endcase
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        lldp_state  <=  1;
    end
    else begin
        lldp_state  <=  lldp_state_next;
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        lldp_mac        <=  LLDP_DBG_MAC;
        lldp_port       <=  LLDP_DBG_PORT;
        lldp_speed_i    <=  LLDP_DBG_SPEED;
        // lldp_speed_o    <=  LLDP_DBG_SPEED;
        lldp_mode       <=  LLDP_DBG_MODE;
    end
    // else if (lldp_state[1]) begin
    else if (load_be && !bp) begin
        lldp_mac        <=  lldp_mac_next;
        lldp_port       <=  {12'b0, lldp_port_next};
        lldp_speed_i    <=  speed;
        // lldp_speed_o    <=  lldp_port_next[3] ? speed_ext[7:6] :
        //                     lldp_port_next[2] ? speed_ext[5:4] :
        //                     lldp_port_next[1] ? speed_ext[3:2] :
        //                     lldp_port_next[0] ? speed_ext[1:0] :
        //                     2'b11;
        lldp_mode       <=  lldp_mode_next;
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        lldp_cksm   <=  24'h90F1;
        lldp_cksm_1 <=  'b0;
    end
    else begin
        if (lldp_state[1]) begin
            lldp_cksm   <=  24'h90F1;
            // lldp_cksm_1 <=  lldp_port + LLDP_PARAM_PORT;
            lldp_cksm_1 <=  {14'b0, lldp_speed_i} + LLDP_PARAM_PORT;
        end
        else if (lldp_state[2]) begin
            // if (ram_cnt_be == 1) begin
            //     lldp_cksm_1 <=  lldp_speed_i + lldp_speed_o;
            // end
            // else if (ram_cnt_be == 9) begin     // source mac
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 11) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 13) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 29) begin    // source ip
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 31) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 33) begin    // dest ip
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 35) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 37) begin    // source port
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 39) begin    // dest port
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // if (ram_cnt_be == 1) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 2) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1; 
            // end
            // else if (ram_cnt_be == 10) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 12) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 14) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 30) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 31) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 32) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 33) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 34) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 36) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 38) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 40) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // // else if (ram_cnt_be == 41) begin
            // //     lldp_cksm   <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // // end
            // else if (ram_cnt_be == 41) begin
            //     lldp_cksm   <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // end
            // else if (ram_cnt_be == 42) begin
            //     lldp_cksm   <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // end
            // if (ram_cnt_be == 2) begin
            //     lldp_cksm_1 <=  {14'b0, lldp_speed_i} + {14'b0, lldp_speed_o};
            // end
            // if (ram_cnt_be == 27) begin
            //     lldp_cksm_1 <=  {6'b0, lldp_reg_cksm};
            // end
            if (ram_cnt_be == 29) begin    // source ip
                lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 31) begin
                lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            end
            if (ram_cnt_be == 2) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            // else if (ram_cnt_be == 3) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1; 
            // end
            else if (ram_cnt_be == 9) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 11) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 13) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 29) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 30) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            else if (ram_cnt_be == 31) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 32) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            else if (ram_cnt_be == 33) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 34) begin
                lldp_cksm   <=  lldp_cksm + lldp_reg_cksm;
            end
            else if (ram_cnt_be == 35) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 37) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 39) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 40) begin
                lldp_cksm   <=  {16'b0, lldp_cksm[23:16]} + {8'b0, lldp_cksm[15:0]};
            end
            else if (ram_cnt_be == 41) begin
                lldp_cksm   <=  {16'b0, lldp_cksm[23:16]} + {8'b0, lldp_cksm[15:0]};
            end
        end
        else if (lldp_state[3]) begin
            // if (ram_cnt_be == 1 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  lldp_speed_i + lldp_speed_o;
            // end
            // else if (ram_cnt_be == 8 && !ram_nibble_be[0]) begin     // source mac
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 10 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 12 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 28 && !ram_nibble_be[0]) begin    // source ip
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 30 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 32 && !ram_nibble_be[0]) begin    // dest ip
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 34 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 36 && !ram_nibble_be[0]) begin    // source port
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // else if (ram_cnt_be == 38 && !ram_nibble_be[0]) begin    // dest port
            //     lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            // end
            // if (ram_cnt_be == 1 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 2 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1; 
            // end
            // else if (ram_cnt_be == 9 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 11 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 13 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 29 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 30 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 31 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 32 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 33 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 35 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 37 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // else if (ram_cnt_be == 39 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            // end
            // // else if (ram_cnt_be == 40 && !ram_nibble_be[0]) begin
            // //     lldp_cksm[15:0] <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // // end
            // else if (ram_cnt_be == 40 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // end
            // else if (ram_cnt_be == 41 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm[23:16] + lldp_cksm[15:0];
            // end
            // if (ram_cnt_be == 1 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {14'b0, lldp_speed_i} + {14'b0, lldp_speed_o};
            // end
            // if (ram_cnt_be == 26 && !ram_nibble_be[0]) begin
            //     lldp_cksm_1 <=  {6'b0, lldp_reg_cksm};
            // end
            if (ram_cnt_be == 28 && !ram_nibble_be[0]) begin    // source ip
                lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 30 && !ram_nibble_be[0]) begin
                lldp_cksm_1 <=  {data_fifo_din_reg, data_ram_dout};
            end
            if (ram_cnt_be == 1 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            // else if (ram_cnt_be == 2 && !ram_nibble_be[0]) begin
            //     lldp_cksm   <=  lldp_cksm + lldp_cksm_1; 
            // end
            else if (ram_cnt_be == 8 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 10 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 12 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 28 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 29 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            else if (ram_cnt_be == 30 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 31 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + lldp_cksm_1;
            end
            else if (ram_cnt_be == 32 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 33 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + lldp_reg_cksm;
            end
            else if (ram_cnt_be == 34 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 36 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 38 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  lldp_cksm + {data_fifo_din_reg, data_ram_dout};
            end
            else if (ram_cnt_be == 39 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  {16'b0, lldp_cksm[23:16]} + {8'b0, lldp_cksm[15:0]};
            end
            else if (ram_cnt_be == 40 && !ram_nibble_be[0]) begin
                lldp_cksm   <=  {16'b0, lldp_cksm[23:16]} + {8'b0, lldp_cksm[15:0]};
            end
        end
    end
end

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        lldp_sel    <=  'b0;
        lldp_data   <=  'b0;
    end
    else begin
        if (lldp_state[2]) begin
            if (ram_cnt_be == 2) begin          // gmii
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[47:40];
                lldp_data   <=  lldp_mac[47:40];
            end
            else if (ram_cnt_be == 3) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[39:32];
                lldp_data   <=  lldp_mac[39:32];
            end
            else if (ram_cnt_be == 4) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[31:24];
                lldp_data   <=  lldp_mac[31:24];
            end
            else if (ram_cnt_be == 5) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[23:16];
                lldp_data   <=  lldp_mac[23:16];
            end
            else if (ram_cnt_be == 6) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[15: 8];
                lldp_data   <=  lldp_mac[15: 8];
            end
            else if (ram_cnt_be == 7) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[ 7: 0];
                lldp_data   <=  lldp_mac[ 7: 0];
            end
            else if (ram_cnt_be == 14) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_DBG_PROTO[15: 8];
            end
            else if (ram_cnt_be == 15) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_DBG_PROTO[ 7: 0];
            end
            else if (ram_cnt_be == 42) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  ~lldp_cksm[15: 8];
            end
            else if (ram_cnt_be == 43) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  ~lldp_cksm[ 7: 0];
            end
            // else if (ram_cnt_be == 58) begin
            //     lldp_sel    <=  'b1;
            //     // lldp_data   <=  LLDP_DBG_PORT[15: 8];
            //     lldp_data   <=  lldp_port[15: 8];
            // end
            // else if (ram_cnt_be == 59) begin
            //     lldp_sel    <=  'b1;
            //     // lldp_data   <=  LLDP_DBG_PORT[ 7: 0];
            //     lldp_data   <=  lldp_port[ 7: 0];
            // end
            // else if (ram_cnt_be == 63) begin
            //     lldp_sel    <=  'b1;
            //     lldp_data   <=  {6'b0, lldp_speed_o};
            // end
            else if (ram_cnt_be == 64) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_PARAM_PORT[15: 8];
            end
            else if (ram_cnt_be == 65) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_PARAM_PORT[ 7: 0];
            end
            else if (ram_cnt_be == 69) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  {6'b0, lldp_speed_i};
            end
            else begin
                lldp_sel    <=  'b0;
            end
        end
        else if (lldp_state[3]) begin
            if (ram_cnt_be == 1 && !ram_nibble_be[0]) begin     // mii
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[47:40];
                lldp_data   <=  lldp_mac[47:40];
            end
            else if (ram_cnt_be == 2 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[39:32];
                lldp_data   <=  lldp_mac[39:32];
            end
            else if (ram_cnt_be == 3 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[31:24];
                lldp_data   <=  lldp_mac[31:24];
            end
            else if (ram_cnt_be == 4 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[23:16];
                lldp_data   <=  lldp_mac[23:16];
            end
            else if (ram_cnt_be == 5 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[15: 8];
                lldp_data   <=  lldp_mac[15: 8];
            end
            else if (ram_cnt_be == 6 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                // lldp_data   <=  LLDP_DBG_MAC[ 7: 0];
                lldp_data   <=  lldp_mac[ 7: 0];
            end
            else if (ram_cnt_be == 13 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_DBG_PROTO[15: 8];
            end
            else if (ram_cnt_be == 14 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_DBG_PROTO[ 7: 0];
            end
            else if (ram_cnt_be == 41 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  ~lldp_cksm[15: 8];
            end
            else if (ram_cnt_be == 42 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  ~lldp_cksm[ 7: 0];
            end
            // else if (ram_cnt_be == 57 && !ram_nibble_be[0]) begin
            //     lldp_sel    <=  'b1;
            //     // lldp_data   <=  LLDP_DBG_PORT[15: 8];
            //     lldp_data   <=  lldp_port[15: 8];
            // end
            // else if (ram_cnt_be == 58 && !ram_nibble_be[0]) begin
            //     lldp_sel    <=  'b1;
            //     // lldp_data   <=  LLDP_DBG_PORT[ 7: 0];
            //     lldp_data   <=  lldp_port[ 7: 0];
            // end
            // else if (ram_cnt_be == 62 && !ram_nibble_be[0]) begin
            //     lldp_sel    <=  'b1;
            //     lldp_data   <=  {6'b0, lldp_speed_o};
            // end
            else if (ram_cnt_be == 63 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_PARAM_PORT[15: 8];
            end
            else if (ram_cnt_be == 64 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  LLDP_PARAM_PORT[ 7: 0];
            end
            else if (ram_cnt_be == 68 && !ram_nibble_be[0]) begin
                lldp_sel    <=  'b1;
                lldp_data   <=  {6'b0, lldp_speed_i};
            end
            else begin
                lldp_sel    <=  'b0;
            end
        end
    end
end

//============================================  
//tte state.   
//============================================  
reg     [12:0]  ram_nibble_tte;
wire    [12:0]  ram_cnt_tte;
reg     [11:0]  load_byte_tte;
reg     [7:0]	tte_fifo_din;
reg             tte_fifo_wr;
reg             tte_fifo_wr_reg;
wire            tte_fifo_wr_dv;
wire    [11:0]  tte_fifo_depth;
reg     [19:0]  tteptr_fifo_din;
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
assign  tte_bp=(tte_fifo_depth>2240) || tteptr_fifo_full;

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
                load_byte_tte<=#DELAY load_byte;
                tte_state<=#DELAY 2;
                end
        end
        2:begin
            if(ram_cnt_tte<=load_byte_tte)
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
            tteptr_fifo_din[11:0]<=#DELAY ram_cnt_tte-5;
            // if(mac_conf_reg[0]) tteptr_fifo_din[11:0]<=#DELAY ram_cnt_tte-6;
            // else tteptr_fifo_din[11:0]<=#DELAY ram_cnt_tte-5;
            // if((ram_cnt_tte<65) | (ram_cnt_tte>1519)) tteptr_fifo_din[14]<=#DELAY 1;
            // else tteptr_fifo_din[14]<=#DELAY 0;
            // if(crc_result==CRC_RESULT_VALUE) tteptr_fifo_din[15]<=#DELAY 1'b0;
            // else tteptr_fifo_din[15]<=#DELAY 1'b1;
            // if(mac_conf_reg[0] && ram_cnt_tte<66) tteptr_fifo_din[14]<=#DELAY 1;
            // else if(!mac_conf_reg[0] && ram_cnt_tte<65) tteptr_fifo_din[14]<=#DELAY 1;
            if(ram_cnt_tte<65) tteptr_fifo_din[14]<=#DELAY 1;
            else tteptr_fifo_din[14]<=#DELAY 0;
            // if(mac_conf_reg[0] && ram_cnt_tte>1520) tteptr_fifo_din[15]<=#DELAY 1;
            // else if(!mac_conf_reg[0] && ram_cnt_tte>1519) tteptr_fifo_din[15]<=#DELAY 1;
            if(ram_cnt_tte>MTU+19) tteptr_fifo_din[15]<=#DELAY 1;
            else tteptr_fifo_din[15]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) tteptr_fifo_din[13]<=#DELAY 1'b0;
            else tteptr_fifo_din[13]<=#DELAY 1'b1;
            tteptr_fifo_din[12] <= mac_conf_reg[0];
            // if(mac_conf_reg[0]) tteptr_fifo_din[19:16]<=#DELAY tailtag_port[3:0];
            // else tteptr_fifo_din[19:16]<=#DELAY 4'b0;
            tteptr_fifo_din[19:16]<=#DELAY 0;
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

(*MARK_DEBUG="true"*) wire    [8:0]   data_fifo_din;

assign  data_ram_addrb = ram_cnt_be[10:0] | ram_cnt_tte[10:0] ;
assign  calc = data_fifo_wr_dv | tte_fifo_wr_dv;
assign  d_valid = data_fifo_wr_dv | tte_fifo_wr_dv;

assign  data_fifo_din[7:0]  =   (lldp_sel==1)   ?   lldp_data   :
                                (ptp_sel==1)    ?   ptp_data    : 
                                data_fifo_din_reg;
assign  data_fifo_din[8]    =   (data_fifo_wr_reg_1 ^ data_fifo_wr_reg) || (data_fifo_wr ^ data_fifo_wr_reg);

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        tailtag_pos     <=  'b0;
        tailtag_port    <=  'b0;
    end
    else begin
        if (load_req) begin
            if (speed[1]) begin
                tailtag_pos     <=  load_byte - 13'h2;
            end
            else begin
                tailtag_pos     <=  load_byte - 13'h3;
            end
        end
        if (be_state != 0 && ram_cnt_be == tailtag_pos && (!ram_nibble_be[0] | speed[1])) begin
            tailtag_port    <=  data_fifo_din_reg[ 3:0];
        end
        if (tte_state != 0 && ram_cnt_tte == tailtag_pos && (!ram_nibble_tte[0] | speed[1])) begin
            tailtag_port    <=  data_fifo_din_reg[ 3:0];
        end
    end
end

//============================================  
//fifo used. 
//============================================  

(*MARK_DEBUG = "true"*) wire        dbg_data_full;
(*MARK_DEBUG = "true"*) wire        dbg_data_empty;
(*MARK_DEBUG = "true"*) wire [11:0] dbg_data_fifo_depth;

(*MARK_DEBUG = "true"*) reg  [11:0] dbg_data_fifo_wr_len;
(*MARK_DEBUG = "true"*) reg         dbg_data_fifo_len_mismatch;

always @(posedge rx_clk or negedge rstn_mac) begin
    if (!rstn_mac) begin
        dbg_data_fifo_wr_len        <=  12'hFFC;
        dbg_data_fifo_len_mismatch  <=  'b0;
    end
    else begin
        if (ptr_fifo_wr) begin
            dbg_data_fifo_wr_len    <=  12'hFFC;
        end
        else if (data_fifo_wr_dv && !dbg_data_full) begin
            dbg_data_fifo_wr_len    <=  dbg_data_fifo_wr_len + 1'b1;
        end
        if (ptr_fifo_wr) begin
            if (ptr_fifo_din[11:0] != dbg_data_fifo_wr_len) begin
                dbg_data_fifo_len_mismatch  <=  'b1;
            end
            // else begin
                // dbg_data_fifo_len_mismatch  <=  'b0;
            // end
        end
    end
end



afifo_reg_w9_d4k u_data_fifo (
  .rst(!rstn_sys),                      // input rst
  .wr_clk(rx_clk),                      // input wr_clk
  .wr_en(data_fifo_wr_dv),              // input wr_en
  .din(data_fifo_din),                  // input [7 : 0] din
  .full(dbg_data_full), 
  .rd_clk(clk),                         // input rd_clk
  .rd_en(data_fifo_rd),                 // input rd_en
  .dout(data_fifo_dout),                // output [7 : 0]       
  .empty(dbg_data_empty), 
  .rd_data_count(dbg_data_fifo_depth),  // output [11 : 0] rd_data_count
  .wr_data_count(data_fifo_depth) 	    // output [11 : 0] wr_data_count
);

afifo_w20_d32 u_ptr_fifo (
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

afifo_w20_d32 u_tteptr_fifo (
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
reg [ 1:0] mgnt_resp_buf;
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
        08: mgnt_state_next  =   mgnt_resp_buf[1] ? 1 : 8;
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
        mgnt_resp_buf   <=  'b0;
    end
    else begin
        mgnt_resp_buf   <=  {mgnt_resp_buf, rx_mgnt_resp};
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
                mgnt_flag[1]    <=  load_lldp;
            end
            else if (load_tte && !tte_bp) begin
                mgnt_flag[7]    <=  'b0;
                mgnt_flag[3]    <=  'b1;
                mgnt_flag[1]    <=  'b0;
            end
            else if ((load_be && bp) || (load_tte && tte_bp)) begin
                mgnt_flag[7]    <=  'b1;
                mgnt_flag[3]    <=  'b0;
                mgnt_flag[1]    <=  'b0;
            end
        end
        else if (mgnt_state[1] && ptr_fifo_wr) begin
            mgnt_cnt        <=  ptr_fifo_din[11:0];
            mgnt_flag[6]    <=  (ptr_fifo_din[15:14] == 2'b10);
            mgnt_flag[5]    <=  (ptr_fifo_din[15:14] == 2'b01);
            mgnt_flag[4]    <=  ptr_fifo_din[15:13];
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
