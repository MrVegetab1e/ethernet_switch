`timescale 1ns / 1ps

module mac_top(
    input              clk,
    input              clk_125,
	input              rstn_sys,
    input              rstn_mac,

    input     [7:0]    GMII_RXD,
    input              GMII_RX_DV,
    input              GMII_RX_CLK,
    input              GMII_RX_ER,
                 
    output    [7:0]    GMII_TXD,
    output             GMII_TX_EN,
    input              MII_TX_CLK,
    output             GMII_TX_CLK, 
    output             GMII_TX_ER,

    output             MDC,                       //phy emdio clock
    inout              MDIO,                      //phy emdio data   

    output    [1:0]    led,
    output             link,

    output              interface_clk,

    output             tx_data_fifo_rd,
    input     [7:0]    tx_data_fifo_dout,
    output             tx_ptr_fifo_rd,
    input     [15:0]   tx_ptr_fifo_dout,
    input              tx_ptr_fifo_empty,
                  
    input             rx_data_fifo_rd,
    output    [7:0]   rx_data_fifo_dout,
    input             rx_ptr_fifo_rd,
	output    [15:0]  rx_ptr_fifo_dout,
    output            rx_ptr_fifo_empty,

    output             tx_tte_fifo_rd,
    input     [7:0]    tx_tte_fifo_dout,
    output             tx_tteptr_fifo_rd,
    input     [15:0]   tx_tteptr_fifo_dout,
    input              tx_tteptr_fifo_empty,
                  
    input             rx_tte_fifo_rd,
    output    [7:0]   rx_tte_fifo_dout,
    input             rx_tteptr_fifo_rd,
	output    [15:0]  rx_tteptr_fifo_dout,
    output            rx_tteptr_fifo_empty,

    // output    [6:0]   port_addr,
    // output    [15:0]  port_din,
    // output            port_req,
    // input             port_ack,

    input               sys_req_valid,
    input               sys_req_wr,
    input   [ 7:0]      sys_req_addr,
    output              sys_resp_valid,
    output  [ 7:0]      sys_resp_data,

    input     [31:0]  counter_ns

    );

parameter   PORT_RX_ADDR = 7'h10;
parameter   PORT_TX_ADDR = 7'h11;
parameter   PORT_ER_ADDR = 7'h12;
parameter   INIT = 0;

wire            time_rst;
wire    [ 1:0]  speed;
// wire    [63:0]  counter_delay;
wire            delay_fifo_wr;
wire    [31:0]  delay_fifo_din;
wire            delay_fifo_full;
wire            delay_fifo_rd;
wire    [31:0]  delay_fifo_dout;
wire            delay_fifo_empty;

wire            rx_mgnt_valid;
wire            rx_mgnt_resp;
wire    [19:0]  rx_mgnt_data;
wire            tx_mgnt_valid;
wire            tx_mgnt_resp;
wire    [15:0]  tx_mgnt_data;

assign          GMII_TX_CLK =   clk_125;        

mac_r_gmii_tte u_mac_r_gmii(
    .clk(clk),
    .rstn_sys(rstn_sys),
    .rstn_mac(rstn_mac),
    .rx_clk(GMII_RX_CLK),
    .rx_dv(GMII_RX_DV),
    .gm_rx_d(GMII_RXD),
    // .gtx_clk(GMII_TX_CLK),
    .speed(speed),
    .data_fifo_rd(rx_data_fifo_rd),
    .data_fifo_dout(rx_data_fifo_dout),
    .ptr_fifo_rd(rx_ptr_fifo_rd),
    .ptr_fifo_dout(rx_ptr_fifo_dout),
    .ptr_fifo_empty(rx_ptr_fifo_empty),
    .tte_fifo_rd(rx_tte_fifo_rd),
    .tte_fifo_dout(rx_tte_fifo_dout),
    .tteptr_fifo_rd(rx_tteptr_fifo_rd),
    .tteptr_fifo_dout(rx_tteptr_fifo_dout),
    .tteptr_fifo_empty(rx_tteptr_fifo_empty),
    .counter_ns(counter_ns),
    // .counter_ns_tx_delay(counter_delay),
    // .counter_ns_gtx_delay(counter_delay),
    .delay_fifo_dout(delay_fifo_dout),
    .delay_fifo_rd(delay_fifo_rd),
    .delay_fifo_empty(delay_fifo_empty),
    .rx_mgnt_valid(rx_mgnt_valid),
    .rx_mgnt_resp(rx_mgnt_resp),
    .rx_mgnt_data(rx_mgnt_data)
    );

mac_t_gmii_tte_v4 u_mac_t_gmii(
    .sys_clk(clk),
    .rstn_sys(rstn_sys),
    .rstn_mac(rstn_mac),
    .tx_clk(MII_TX_CLK),
    .gtx_clk(clk_125),
    .interface_clk(interface_clk),
    .gtx_dv(GMII_TX_EN),
    .gtx_d(GMII_TXD),
    .speed(speed),
    .data_fifo_rd(tx_data_fifo_rd),
    .data_fifo_din(tx_data_fifo_dout),
    .ptr_fifo_rd(tx_ptr_fifo_rd),
    .ptr_fifo_din(tx_ptr_fifo_dout),
    .ptr_fifo_empty(tx_ptr_fifo_empty),
    .tdata_fifo_rd(tx_tte_fifo_rd),
    .tdata_fifo_din(tx_tte_fifo_dout),
    .tptr_fifo_rd(tx_tteptr_fifo_rd),
    .tptr_fifo_din(tx_tteptr_fifo_dout),
    .tptr_fifo_empty(tx_tteptr_fifo_empty),
    .counter_ns(counter_ns),
    // .counter_delay(counter_delay),
    .delay_fifo_din(delay_fifo_din),
    .delay_fifo_wr(delay_fifo_wr),
    .delay_fifo_full(delay_fifo_full),
    .tx_mgnt_valid(tx_mgnt_valid),
    .tx_mgnt_resp(tx_mgnt_resp),
    .tx_mgnt_data(tx_mgnt_data)
    );

// mac_t_gmii_tte u_mac_t_gmii(
//     .clk(clk),
//     .rstn(rstn),
//     .tx_clk(MII_TX_CLK),
//     // .gtx_clk(GMII_TX_CLK),
//     .gtx_clk(clk_125),
//     .gtx_dv(GMII_TX_EN),
//     .gm_tx_d(GMII_TXD),
//     .speed(speed),
//     .data_fifo_rd(tx_data_fifo_rd),
//     .data_fifo_din(tx_data_fifo_dout),
//     .ptr_fifo_rd(tx_ptr_fifo_rd),
//     .ptr_fifo_din(tx_ptr_fifo_dout),
//     .ptr_fifo_empty(tx_ptr_fifo_empty),
//     .tdata_fifo_rd(tx_tte_fifo_rd),
//     .tdata_fifo_din(tx_tte_fifo_dout),
//     .tptr_fifo_rd(tx_tteptr_fifo_rd),
//     .tptr_fifo_din(tx_tteptr_fifo_dout),
//     .tptr_fifo_empty(tx_tteptr_fifo_empty)
//     );

afifo_w32_d32 ptp_delay_fifo (
    .rst(!rstn_mac),
    .wr_clk(interface_clk),
    .din(delay_fifo_din),
    .wr_en(delay_fifo_wr),
    .full(delay_fifo_full),
    .rd_clk(GMII_RX_CLK),
    .dout(delay_fifo_dout),
    .rd_en(delay_fifo_rd),
    .empty(delay_fifo_empty)
);

smi_config  #(
.REF_CLK                 (125                   ),        
.MDC_CLK                 (500                   )
)
smi_config_inst
(
.clk                    (clk_125                ),
.rst_n                  (rstn_mac               ),         
.mdc                    (MDC                    ),
.mdio                   (MDIO                   ),
.link                   (link                   ),
.speed                  (speed                  ),
.led                    (led                    )    
);

mac_ctrl #(
    .MGNT_REG_WIDTH  (16                     )
) mac_ctrl_inst (
    .clk_if          ( clk                    ),
    .rst_if          ( rstn_sys               ),
    .rx_mgnt_valid   ( rx_mgnt_valid          ),
    .rx_mgnt_data    ( rx_mgnt_data    [19:0] ),
    .tx_mgnt_valid   ( tx_mgnt_valid          ),
    .tx_mgnt_data    ( tx_mgnt_data    [15:0] ),
    .sys_req_valid   ( sys_req_valid          ),
    .sys_req_wr      ( sys_req_wr             ),
    .sys_req_addr    ( sys_req_addr    [ 7:0] ),

    .rx_mgnt_resp    ( rx_mgnt_resp           ),
    .tx_mgnt_resp    ( tx_mgnt_resp           ),
    .sys_resp_valid  ( sys_resp_valid         ),
    .sys_resp_data   ( sys_resp_data   [ 7:0] )
);

endmodule
