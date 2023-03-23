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
input               rstn,
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
output              tteptr_fifo_empty
    );

parameter DELAY=2;  
parameter CRC_RESULT_VALUE=32'hc704dd7b;
parameter TTE_VALUE=8'h92;
parameter MTU=1500;

assign  gtx_clk = rx_clk & speed[1];
//============================================  
//generte a pipeline of input gm_rx_d.   
//============================================  
reg     [7:0]  rx_d_reg;
always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
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
always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
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
always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
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
always @(posedge rx_clk  or negedge rstn)
    if(!rstn)nib_cnt<=#DELAY 0;
    else if(nib_cnt_clr) nib_cnt<=#DELAY 0; 
    else nib_cnt<=#DELAY nib_cnt+1; 

assign byte_cnt = speed[1]?nib_cnt:{1'b0,nib_cnt[12:1]};

wire    byte_dv;
assign  byte_dv=nib_cnt[0] | speed[1];

wire    byte_bp;
assign  byte_bp=(byte_cnt>(MTU+8));
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

always @(posedge rx_clk  or negedge rstn)
    if(!rstn)begin
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
//crc signal.   
//============================================ 
reg     [7:0]   crc_din;
wire    load_init;
wire    calc;
wire    d_valid;
wire    [31:0]  crc_result;

assign  load_init = nib_cnt_clr;

always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
        crc_din<=#DELAY 0;
        end
    else begin
        crc_din<=#DELAY data_ram_dout;
        end

crc32_8023 u_crc32_8023(
    .clk(rx_clk), 
    .reset(!rstn), 
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
reg     [7:0]	data_fifo_din;
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
always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
        data_fifo_wr_reg<=#DELAY 0;
        end
    else begin
        data_fifo_wr_reg<=#DELAY data_fifo_wr;
        end

always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
        data_fifo_din<=#DELAY 0;
        end
    else begin
        data_fifo_din<=#DELAY data_ram_dout;
        end

wire    bp;
assign  bp=(data_fifo_depth>2578) | ptr_fifo_full;

reg     [2:0]   be_state;
always @(posedge rx_clk  or negedge rstn)
    if(!rstn)begin
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
            ptr_fifo_din[12:0]<=#DELAY ram_cnt_be-1;
            if((ram_cnt_be<65) | (ram_cnt_be>1519)) ptr_fifo_din[14]<=#DELAY 1;
            else ptr_fifo_din[14]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) ptr_fifo_din[15]<=#DELAY 1'b0;
            else ptr_fifo_din[15]<=#DELAY 1'b1;
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
always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
        tte_fifo_wr_reg<=#DELAY 0;
        end
    else begin
        tte_fifo_wr_reg<=#DELAY tte_fifo_wr;
        end

always @(posedge rx_clk or negedge rstn)
    if(!rstn)begin
        tte_fifo_din<=#DELAY 0;
        end
    else begin
        tte_fifo_din<=#DELAY data_ram_dout;
        end

wire    tte_bp;
assign  tte_bp=(tte_fifo_depth>2578) | tteptr_fifo_full;

reg     [2:0]   tte_state;
always @(posedge rx_clk  or negedge rstn)
    if(!rstn)begin
        tte_state<=#DELAY 0;
        tteptr_fifo_din<=#DELAY 0;
        tteptr_fifo_wr<=#DELAY 0;
        tte_fifo_wr<=#DELAY 0;
        ram_nibble_tte<=#DELAY 0;
        end
    else begin
        case(tte_state)
        0: begin
            if(load_tte & !bp)begin
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
            tteptr_fifo_din[12:0]<=#DELAY ram_cnt_tte-1;
            if((ram_cnt_tte<65) | (ram_cnt_tte>1519)) tteptr_fifo_din[14]<=#DELAY 1;
            else tteptr_fifo_din[14]<=#DELAY 0;
            if(crc_result==CRC_RESULT_VALUE) tteptr_fifo_din[15]<=#DELAY 1'b0;
            else tteptr_fifo_din[15]<=#DELAY 1'b1;
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

assign  data_ram_addrb = ram_cnt_be[10:0] | ram_cnt_tte[10:0] ;
assign  calc = data_fifo_wr_dv | tte_fifo_wr_dv;
assign  d_valid = data_fifo_wr_dv | tte_fifo_wr_dv;
//============================================  
//fifo used. 
//============================================  
afifo_w8_d4k u_data_fifo (
  .rst(!rstn),                      // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(data_fifo_din),              // input [7 : 0] din
  .wr_en(data_fifo_wr_dv),             // input wr_en
  .rd_en(data_fifo_rd),             // input rd_en
  .dout(data_fifo_dout),            // output [7 : 0]       
  .full(), 
  .empty(), 
  .rd_data_count(), 				// output [11 : 0] rd_data_count
  .wr_data_count(data_fifo_depth) 	// output [11 : 0] wr_data_count
);

afifo_w16_d32 u_ptr_fifo (
  .rst(!rstn),                      // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(ptr_fifo_din),               // input [15 : 0] din
  .wr_en(ptr_fifo_wr),              // input wr_en
  .rd_en(ptr_fifo_rd),              // input rd_en
  .dout(ptr_fifo_dout),             // output [15 : 0] dout
  .full(ptr_fifo_full),             // output full
  .empty(ptr_fifo_empty)            // output empty
);
afifo_w8_d4k u_tte_fifo (
  .rst(!rstn),                      // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(tte_fifo_din),              // input [7 : 0] din
  .wr_en(tte_fifo_wr_dv),             // input wr_en
  .rd_en(tte_fifo_rd),             // input rd_en
  .dout(tte_fifo_dout),            // output [7 : 0]       
  .full(), 
  .empty(), 
  .rd_data_count(), 				// output [11 : 0] rd_data_count
  .wr_data_count(tte_fifo_depth) 	// output [11 : 0] wr_data_count
);

afifo_w16_d32 u_tteptr_fifo (
  .rst(!rstn),                      // input rst
  .wr_clk(rx_clk),                  // input wr_clk
  .rd_clk(clk),                     // input rd_clk
  .din(tteptr_fifo_din),               // input [15 : 0] din
  .wr_en(tteptr_fifo_wr),              // input wr_en
  .rd_en(tteptr_fifo_rd),              // input rd_en
  .dout(tteptr_fifo_dout),             // output [15 : 0] dout
  .full(tteptr_fifo_full),             // output full
  .empty(tteptr_fifo_empty)            // output empty
);
endmodule
