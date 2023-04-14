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
    output            rx_tteptr_fifo_empty
    );

wire    [1:0]   speed;
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
    .tteptr_fifo_empty(rx_tteptr_fifo_empty)
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
    .counter_ns('b0)
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

smi_config  #(
.REF_CLK                 (200                   ),        
.MDC_CLK                 (500                   )
)
smi_config_inst
(
.clk                    (clk                    ),
.rst_n                  (rstn_sys               ),         
.mdc                    (MDC                    ),
.mdio                   (MDIO                   ),
.link                   (link                   ),
.speed                  (speed                  ),
.led                    (led                    )    
);  
endmodule
