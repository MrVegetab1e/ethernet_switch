`timescale 1ns / 1ps
module top_switch (
    input        sys_clk_p,      //system clock positive
    input        sys_clk_n,      //system clock negative 
    input        rstn,           //reset ,low active
    output [1:0] led,
    //spi_slave
    input        mosi,
    input        csb,
    input        sck,
    output       miso,
    output       int,
    //mac0 interface
    input  [7:0] GMII_RXD_0,
    input        GMII_RX_DV_0,
    input        GMII_RX_CLK_0,
    input        GMII_RX_ER_0,
    output [7:0] GMII_TXD_0,
    output       GMII_TX_EN_0,
    input        MII_TX_CLK_0,
    output       GMII_TX_CLK_0,
    output       GMII_TX_ER_0,
    output       phy_rstn_0,
    output       MDC_0,          //phy emdio clock
    inout        MDIO_0,         //phy emdio data      
    //mac1 interface
    input  [7:0] GMII_RXD_1,
    input        GMII_RX_DV_1,
    input        GMII_RX_CLK_1,
    input        GMII_RX_ER_1,
    output [7:0] GMII_TXD_1,
    output       GMII_TX_EN_1,
    input        MII_TX_CLK_1,
    output       GMII_TX_CLK_1,
    output       GMII_TX_ER_1,
    output       phy_rstn_1,
    output       MDC_1,          //phy emdio clock
    inout        MDIO_1,         //phy emdio data     
    //mac2 interface
    input  [7:0] GMII_RXD_2,
    input        GMII_RX_DV_2,
    input        GMII_RX_CLK_2,
    input        GMII_RX_ER_2,
    output [7:0] GMII_TXD_2,
    output       GMII_TX_EN_2,
    input        MII_TX_CLK_2,
    output       GMII_TX_CLK_2,
    output       GMII_TX_ER_2,
    output       phy_rstn_2,
    output       MDC_2,          //phy emdio clock
    inout        MDIO_2,         //phy emdio data       
    //mac3 interface
    input  [7:0] GMII_RXD_3,
    input        GMII_RX_DV_3,
    input        GMII_RX_CLK_3,
    input        GMII_RX_ER_3,
    output [7:0] GMII_TXD_3,
    output       GMII_TX_EN_3,
    input        MII_TX_CLK_3,
    output       GMII_TX_CLK_3,
    output       GMII_TX_ER_3,
    output       phy_rstn_3,
    output       MDC_3,          //phy emdio clock
    inout        MDIO_3          //phy emdio data     
);

    wire [1:0] led_r0;
    wire [1:0] led_r1;
    wire [1:0] led_r2;
    wire [1:0] led_r3;

    wire [3:0] link;

    wire       clk_in;
    wire       clk;
    wire       clk_125;

    wire       locked;
    // (*MARK_DEBUG="true"*) wire				rstn_pll;
    wire       rstn_sys;
    wire       rstn_mac;
    wire       rstn_phy;

    assign led = led_r0 & led_r1 & led_r2 & led_r3;
    //interface of interface mux and  switch_pos
    wire        emac0_interface_clk;

    wire        emac0_tx_data_fifo_rd;
    wire [ 7:0] emac0_tx_data_fifo_dout;
    wire        emac0_tx_ptr_fifo_rd;
    wire [15:0] emac0_tx_ptr_fifo_dout;
    wire        emac0_tx_ptr_fifo_empty;

    wire        emac0_rx_data_fifo_rd;
    wire [ 8:0] emac0_rx_data_fifo_dout;
    wire        emac0_rx_ptr_fifo_rd;
    wire [19:0] emac0_rx_ptr_fifo_dout;
    wire        emac0_rx_ptr_fifo_empty;

    wire        emac0_tx_tte_fifo_rd;
    wire [ 7:0] emac0_tx_tte_fifo_dout;
    wire        emac0_tx_tteptr_fifo_rd;
    wire [15:0] emac0_tx_tteptr_fifo_dout;
    wire        emac0_tx_tteptr_fifo_empty;

    wire        emac0_rx_tte_fifo_rd;
    wire [ 7:0] emac0_rx_tte_fifo_dout;
    wire        emac0_rx_tteptr_fifo_rd;
    wire [19:0] emac0_rx_tteptr_fifo_dout;
    wire        emac0_rx_tteptr_fifo_empty;

    wire        emac1_interface_clk;

    wire        emac1_tx_data_fifo_rd;
    wire [ 7:0] emac1_tx_data_fifo_dout;
    wire        emac1_tx_ptr_fifo_rd;
    wire [15:0] emac1_tx_ptr_fifo_dout;
    wire        emac1_tx_ptr_fifo_empty;

    wire        emac1_rx_data_fifo_rd;
    wire [ 8:0] emac1_rx_data_fifo_dout;
    wire        emac1_rx_ptr_fifo_rd;
    wire [19:0] emac1_rx_ptr_fifo_dout;
    wire        emac1_rx_ptr_fifo_empty;

    wire        emac1_tx_tte_fifo_rd;
    wire [ 7:0] emac1_tx_tte_fifo_dout;
    wire        emac1_tx_tteptr_fifo_rd;
    wire [15:0] emac1_tx_tteptr_fifo_dout;
    wire        emac1_tx_tteptr_fifo_empty;

    wire        emac1_rx_tte_fifo_rd;
    wire [ 7:0] emac1_rx_tte_fifo_dout;
    wire        emac1_rx_tteptr_fifo_rd;
    wire [19:0] emac1_rx_tteptr_fifo_dout;
    wire        emac1_rx_tteptr_fifo_empty;

    wire        emac2_interface_clk;

    wire        emac2_tx_data_fifo_rd;
    wire [ 7:0] emac2_tx_data_fifo_dout;
    wire        emac2_tx_ptr_fifo_rd;
    wire [15:0] emac2_tx_ptr_fifo_dout;
    wire        emac2_tx_ptr_fifo_empty;

    wire        emac2_rx_data_fifo_rd;
    wire [ 8:0] emac2_rx_data_fifo_dout;
    wire        emac2_rx_ptr_fifo_rd;
    wire [19:0] emac2_rx_ptr_fifo_dout;
    wire        emac2_rx_ptr_fifo_empty;

    wire        emac2_tx_tte_fifo_rd;
    wire [ 7:0] emac2_tx_tte_fifo_dout;
    wire        emac2_tx_tteptr_fifo_rd;
    wire [15:0] emac2_tx_tteptr_fifo_dout;
    wire        emac2_tx_tteptr_fifo_empty;

    wire        emac2_rx_tte_fifo_rd;
    wire [ 7:0] emac2_rx_tte_fifo_dout;
    wire        emac2_rx_tteptr_fifo_rd;
    wire [19:0] emac2_rx_tteptr_fifo_dout;
    wire        emac2_rx_tteptr_fifo_empty;

    wire        emac3_interface_clk;

    wire        emac3_tx_data_fifo_rd;
    wire [ 7:0] emac3_tx_data_fifo_dout;
    wire        emac3_tx_ptr_fifo_rd;
    wire [15:0] emac3_tx_ptr_fifo_dout;
    wire        emac3_tx_ptr_fifo_empty;

    wire        emac3_rx_data_fifo_rd;
    wire [ 8:0] emac3_rx_data_fifo_dout;
    wire        emac3_rx_ptr_fifo_rd;
    wire [19:0] emac3_rx_ptr_fifo_dout;
    wire        emac3_rx_ptr_fifo_empty;

    wire        emac3_tx_tte_fifo_rd;
    wire [ 7:0] emac3_tx_tte_fifo_dout;
    wire        emac3_tx_tteptr_fifo_rd;
    wire [15:0] emac3_tx_tteptr_fifo_dout;
    wire        emac3_tx_tteptr_fifo_empty;

    wire        emac3_rx_tte_fifo_rd;
    wire [ 7:0] emac3_rx_tte_fifo_dout;
    wire        emac3_rx_tteptr_fifo_rd;
    wire [19:0] emac3_rx_tteptr_fifo_dout;
    wire        emac3_rx_tteptr_fifo_empty;

    wire [ 1:0] emac0_speed;
    wire [ 1:0] emac1_speed;
    wire [ 1:0] emac2_speed;
    wire [ 1:0] emac3_speed;

    wire [ 7:0] speed;

    assign speed = {emac3_speed,
                    emac2_speed,
                    emac1_speed,
                    emac0_speed};

    // wire                 clk;

    // wire [ 6:0] port0_addr;
    // wire [15:0] port0_din;
    // wire        port0_req;
    // wire        port0_ack;

    // wire [ 6:0] port1_addr;
    // wire [15:0] port1_din;
    // wire        port1_req;
    // wire        port1_ack;

    // wire [ 6:0] port2_addr;
    // wire [15:0] port2_din;
    // wire        port2_req;
    // wire        port2_ack;

    // wire [ 6:0] port3_addr;
    // wire [15:0] port3_din;
    // wire        port3_req;
    // wire        port3_ack;

    wire    [ 7:0]  sys_req_valid;
    wire            sys_req_wr;
    wire    [ 7:0]  sys_req_addr;
    wire            sys_req_ack;
    wire    [ 7:0]  sys_req_data;
    wire            sys_req_data_valid;
    wire    [ 7:0]  sys_resp_data;
    wire            sys_resp_data_valid;

    wire            sys_req_ack_p0;
    wire    [ 7:0]  sys_resp_data_p0;
    wire            sys_resp_data_valid_p0;
    wire            sys_req_ack_p1;
    wire    [ 7:0]  sys_resp_data_p1;
    wire            sys_resp_data_valid_p1;
    wire            sys_req_ack_p2;
    wire    [ 7:0]  sys_resp_data_p2;
    wire            sys_resp_data_valid_p2;
    wire            sys_req_ack_p3;
    wire    [ 7:0]  sys_resp_data_p3;
    wire            sys_resp_data_valid_p3;
    wire            sys_req_ack_be;
    wire    [ 7:0]  sys_resp_data_be;
    wire            sys_resp_data_valid_be;
    wire            sys_req_ack_tte;
    wire    [ 7:0]  sys_resp_data_tte;
    wire            sys_resp_data_valid_tte;
    wire            sys_req_ack_ftm;
    wire    [ 7:0]  sys_resp_data_ftm;
    wire            sys_resp_data_valid_ftm;
    wire            sys_req_ack_ft;
    wire    [ 7:0]  sys_resp_data_ft;
    wire            sys_resp_data_valid_ft;

    assign  sys_req_ack         =   sys_req_ack_p0  ||
                                    sys_req_ack_p1  ||
                                    sys_req_ack_p2  ||
                                    sys_req_ack_p3  ||
                                    sys_req_ack_be  ||
                                    sys_req_ack_tte ||
                                    sys_req_ack_ft  ||
                                    sys_req_ack_ftm;
    assign  sys_resp_data_valid =   sys_resp_data_valid_p0  ||
                                    sys_resp_data_valid_p1  ||
                                    sys_resp_data_valid_p2  ||
                                    sys_resp_data_valid_p3  ||
                                    sys_resp_data_valid_be  ||
                                    sys_resp_data_valid_tte ||
                                    sys_resp_data_valid_ft  ||
                                    sys_resp_data_valid_ftm;
    assign  sys_resp_data       =   (sys_resp_data_valid_p0)  ? sys_resp_data_p0  :
                                    (sys_resp_data_valid_p1)  ? sys_resp_data_p1  :
                                    (sys_resp_data_valid_p2)  ? sys_resp_data_p2  :
                                    (sys_resp_data_valid_p3)  ? sys_resp_data_p3  :
                                    (sys_resp_data_valid_be)  ? sys_resp_data_be  :
                                    (sys_resp_data_valid_tte) ? sys_resp_data_tte :
                                    (sys_resp_data_valid_ft)  ? sys_resp_data_ft  :
                                    sys_resp_data_ftm;

    wire [31:0] counter_ns;

    counter counter_inst (
        .clk       (clk),
        .rst_n     (rstn_sys),
        .counter_ns(counter_ns)
    );

    IDELAYCTRL IDELAYCTRL_inst (
        .RDY(RDY), // 1-bit output: Ready output
        .REFCLK(clk_in), // 1-bit input: Reference clock input
        .RST(!rstn_mac)   // 1-bit input: Active high reset input
    );

    mac_top_v2 #(
        .MAC_PORT(0),
        // .RX_DELAY(10)
        .RX_DELAY(8)
    ) u_mac_top_0 (
        .clk(clk),
        .clk_ref(clk_in),
        .clk_125(clk_125),
        .rstn_sys(rstn_sys),
        .rstn_mac(rstn_mac),

        .GMII_RXD(GMII_RXD_0),
        .GMII_RX_DV(GMII_RX_DV_0),
        .GMII_RX_CLK(GMII_RX_CLK_0),
        .GMII_RX_ER(GMII_RX_ER_0),

        .GMII_TXD(GMII_TXD_0),
        .GMII_TX_EN(GMII_TX_EN_0),
        .MII_TX_CLK(MII_TX_CLK_0),
        .GMII_TX_CLK(GMII_TX_CLK_0),
        .GMII_TX_ER(GMII_TX_ER_0),

        .MDC (MDC_0),
        .MDIO(MDIO_0),

        .led (led_r0),
        .link(link[0]),
        .speed(emac0_speed),
        .speed_ext({speed[7:2], 2'b0}),

        .interface_clk(emac0_interface_clk),

        .rx_data_fifo_rd(emac0_rx_data_fifo_rd),
        .rx_data_fifo_dout(emac0_rx_data_fifo_dout),
        .rx_ptr_fifo_rd(emac0_rx_ptr_fifo_rd),
        .rx_ptr_fifo_dout(emac0_rx_ptr_fifo_dout),
        .rx_ptr_fifo_empty(emac0_rx_ptr_fifo_empty),

        .tx_data_fifo_rd(emac0_tx_data_fifo_rd),
        .tx_data_fifo_dout(emac0_tx_data_fifo_dout),
        .tx_ptr_fifo_rd(emac0_tx_ptr_fifo_rd),
        .tx_ptr_fifo_dout(emac0_tx_ptr_fifo_dout),
        .tx_ptr_fifo_empty(emac0_tx_ptr_fifo_empty),

        .rx_tte_fifo_rd(emac0_rx_tte_fifo_rd),
        .rx_tte_fifo_dout(emac0_rx_tte_fifo_dout),
        .rx_tteptr_fifo_rd(emac0_rx_tteptr_fifo_rd),
        .rx_tteptr_fifo_dout(emac0_rx_tteptr_fifo_dout),
        .rx_tteptr_fifo_empty(emac0_rx_tteptr_fifo_empty),

        .tx_tte_fifo_rd(emac0_tx_tte_fifo_rd),
        .tx_tte_fifo_dout(emac0_tx_tte_fifo_dout),
        .tx_tteptr_fifo_rd(emac0_tx_tteptr_fifo_rd),
        .tx_tteptr_fifo_dout(emac0_tx_tteptr_fifo_dout),
        .tx_tteptr_fifo_empty(emac0_tx_tteptr_fifo_empty),

        .sys_req_valid          (sys_req_valid[0]),
        .sys_req_wr             (sys_req_wr),
        .sys_req_addr           (sys_req_addr),
        .sys_req_ack            (sys_req_ack_p0),
        .sys_req_data           (sys_req_data),
        .sys_req_data_valid     (sys_req_data_valid),
        .sys_resp_data          (sys_resp_data_p0),
        .sys_resp_data_valid    (sys_resp_data_valid_p0),

        .counter_ns(counter_ns)
    );

    mac_top_v2 #(
        .MAC_PORT(1),
        // .RX_DELAY(8)
        .RX_DELAY(2)
    ) u_mac_top_1 (
        .clk(clk),
        .clk_ref(clk_in),
        .clk_125(clk_125),
        .rstn_sys(rstn_sys),
        .rstn_mac(rstn_mac),

        .GMII_RXD(GMII_RXD_1),
        .GMII_RX_DV(GMII_RX_DV_1),
        .GMII_RX_CLK(GMII_RX_CLK_1),
        .GMII_RX_ER(GMII_RX_ER_1),

        .GMII_TXD(GMII_TXD_1),
        .GMII_TX_EN(GMII_TX_EN_1),
        .MII_TX_CLK(MII_TX_CLK_1),
        .GMII_TX_CLK(GMII_TX_CLK_1),
        .GMII_TX_ER(GMII_TX_ER_1),

        .MDC (MDC_1),
        .MDIO(MDIO_1),

        .led (led_r1),
        .link(link[1]),
        .speed(emac1_speed),
        .speed_ext({speed[7:4], 2'b0, speed[1:0]}),

        .interface_clk(emac1_interface_clk),

        .rx_data_fifo_rd(emac1_rx_data_fifo_rd),
        .rx_data_fifo_dout(emac1_rx_data_fifo_dout),
        .rx_ptr_fifo_rd(emac1_rx_ptr_fifo_rd),
        .rx_ptr_fifo_dout(emac1_rx_ptr_fifo_dout),
        .rx_ptr_fifo_empty(emac1_rx_ptr_fifo_empty),

        .tx_data_fifo_rd(emac1_tx_data_fifo_rd),
        .tx_data_fifo_dout(emac1_tx_data_fifo_dout),
        .tx_ptr_fifo_rd(emac1_tx_ptr_fifo_rd),
        .tx_ptr_fifo_dout(emac1_tx_ptr_fifo_dout),
        .tx_ptr_fifo_empty(emac1_tx_ptr_fifo_empty),

        .rx_tte_fifo_rd(emac1_rx_tte_fifo_rd),
        .rx_tte_fifo_dout(emac1_rx_tte_fifo_dout),
        .rx_tteptr_fifo_rd(emac1_rx_tteptr_fifo_rd),
        .rx_tteptr_fifo_dout(emac1_rx_tteptr_fifo_dout),
        .rx_tteptr_fifo_empty(emac1_rx_tteptr_fifo_empty),

        .tx_tte_fifo_rd(emac1_tx_tte_fifo_rd),
        .tx_tte_fifo_dout(emac1_tx_tte_fifo_dout),
        .tx_tteptr_fifo_rd(emac1_tx_tteptr_fifo_rd),
        .tx_tteptr_fifo_dout(emac1_tx_tteptr_fifo_dout),
        .tx_tteptr_fifo_empty(emac1_tx_tteptr_fifo_empty),

        .sys_req_valid          (sys_req_valid[1]),
        .sys_req_wr             (sys_req_wr),
        .sys_req_addr           (sys_req_addr),
        .sys_req_ack            (sys_req_ack_p1),
        .sys_req_data           (sys_req_data),
        .sys_req_data_valid     (sys_req_data_valid),
        .sys_resp_data          (sys_resp_data_p1),
        .sys_resp_data_valid    (sys_resp_data_valid_p1),

        .counter_ns(counter_ns)

    );

    mac_top_v2 #(
        .MAC_PORT(2),
        // .RX_DELAY(4)
        .RX_DELAY(0)
    ) u_mac_top_2 (
        .clk(clk),
        .clk_ref(clk_in),
        .clk_125(clk_125),
        .rstn_sys(rstn_sys),
        .rstn_mac(rstn_mac),

        .GMII_RXD(GMII_RXD_2),
        .GMII_RX_DV(GMII_RX_DV_2),
        .GMII_RX_CLK(GMII_RX_CLK_2),
        .GMII_RX_ER(GMII_RX_ER_2),

        .GMII_TXD(GMII_TXD_2),
        .GMII_TX_EN(GMII_TX_EN_2),
        .MII_TX_CLK(MII_TX_CLK_2),
        .GMII_TX_CLK(GMII_TX_CLK_2),
        .GMII_TX_ER(GMII_TX_ER_2),

        .MDC (MDC_2),
        .MDIO(MDIO_2),

        .led (led_r2),
        .link(link[2]),
        .speed(emac2_speed),
        .speed_ext({speed[7:6], 2'b0, speed[3:0]}),

        .interface_clk(emac2_interface_clk),

        .rx_data_fifo_rd(emac2_rx_data_fifo_rd),
        .rx_data_fifo_dout(emac2_rx_data_fifo_dout),
        .rx_ptr_fifo_rd(emac2_rx_ptr_fifo_rd),
        .rx_ptr_fifo_dout(emac2_rx_ptr_fifo_dout),
        .rx_ptr_fifo_empty(emac2_rx_ptr_fifo_empty),

        .tx_data_fifo_rd(emac2_tx_data_fifo_rd),
        .tx_data_fifo_dout(emac2_tx_data_fifo_dout),
        .tx_ptr_fifo_rd(emac2_tx_ptr_fifo_rd),
        .tx_ptr_fifo_dout(emac2_tx_ptr_fifo_dout),
        .tx_ptr_fifo_empty(emac2_tx_ptr_fifo_empty),

        .rx_tte_fifo_rd(emac2_rx_tte_fifo_rd),
        .rx_tte_fifo_dout(emac2_rx_tte_fifo_dout),
        .rx_tteptr_fifo_rd(emac2_rx_tteptr_fifo_rd),
        .rx_tteptr_fifo_dout(emac2_rx_tteptr_fifo_dout),
        .rx_tteptr_fifo_empty(emac2_rx_tteptr_fifo_empty),

        .tx_tte_fifo_rd(emac2_tx_tte_fifo_rd),
        .tx_tte_fifo_dout(emac2_tx_tte_fifo_dout),
        .tx_tteptr_fifo_rd(emac2_tx_tteptr_fifo_rd),
        .tx_tteptr_fifo_dout(emac2_tx_tteptr_fifo_dout),
        .tx_tteptr_fifo_empty(emac2_tx_tteptr_fifo_empty),

        .sys_req_valid          (sys_req_valid[2]),
        .sys_req_wr             (sys_req_wr),
        .sys_req_addr           (sys_req_addr),
        .sys_req_ack            (sys_req_ack_p2),
        .sys_req_data           (sys_req_data),
        .sys_req_data_valid     (sys_req_data_valid),
        .sys_resp_data          (sys_resp_data_p2),
        .sys_resp_data_valid    (sys_resp_data_valid_p2),

        .counter_ns(counter_ns)

    );

    mac_top_v2 #(
        .MAC_PORT(3),
        // .RX_DELAY(4)
        .RX_DELAY(4)
    ) u_mac_top_3 (
        .clk(clk),
        .clk_ref(clk_in),
        .clk_125(clk_125),
        .rstn_sys(rstn_sys),
        .rstn_mac(rstn_mac),

        .GMII_RXD(GMII_RXD_3),
        .GMII_RX_DV(GMII_RX_DV_3),
        .GMII_RX_CLK(GMII_RX_CLK_3),
        .GMII_RX_ER(GMII_RX_ER_3),

        .GMII_TXD(GMII_TXD_3),
        .GMII_TX_EN(GMII_TX_EN_3),
        .MII_TX_CLK(MII_TX_CLK_3),
        .GMII_TX_CLK(GMII_TX_CLK_3),
        .GMII_TX_ER(GMII_TX_ER_3),

        .MDC (MDC_3),
        .MDIO(MDIO_3),

        .led (led_r3),
        .link(link[3]),
        .speed(emac3_speed),
        .speed_ext({2'b0, speed[5:0]}),

        .interface_clk(emac3_interface_clk),

        .rx_data_fifo_rd(emac3_rx_data_fifo_rd),
        .rx_data_fifo_dout(emac3_rx_data_fifo_dout),
        .rx_ptr_fifo_rd(emac3_rx_ptr_fifo_rd),
        .rx_ptr_fifo_dout(emac3_rx_ptr_fifo_dout),
        .rx_ptr_fifo_empty(emac3_rx_ptr_fifo_empty),

        .tx_data_fifo_rd(emac3_tx_data_fifo_rd),
        .tx_data_fifo_dout(emac3_tx_data_fifo_dout),
        .tx_ptr_fifo_rd(emac3_tx_ptr_fifo_rd),
        .tx_ptr_fifo_dout(emac3_tx_ptr_fifo_dout),
        .tx_ptr_fifo_empty(emac3_tx_ptr_fifo_empty),

        .rx_tte_fifo_rd(emac3_rx_tte_fifo_rd),
        .rx_tte_fifo_dout(emac3_rx_tte_fifo_dout),
        .rx_tteptr_fifo_rd(emac3_rx_tteptr_fifo_rd),
        .rx_tteptr_fifo_dout(emac3_rx_tteptr_fifo_dout),
        .rx_tteptr_fifo_empty(emac3_rx_tteptr_fifo_empty),

        .tx_tte_fifo_rd(emac3_tx_tte_fifo_rd),
        .tx_tte_fifo_dout(emac3_tx_tte_fifo_dout),
        .tx_tteptr_fifo_rd(emac3_tx_tteptr_fifo_rd),
        .tx_tteptr_fifo_dout(emac3_tx_tteptr_fifo_dout),
        .tx_tteptr_fifo_empty(emac3_tx_tteptr_fifo_empty),

        .sys_req_valid          (sys_req_valid[3]),
        .sys_req_wr             (sys_req_wr),
        .sys_req_addr           (sys_req_addr),
        .sys_req_ack            (sys_req_ack_p3),
        .sys_req_data           (sys_req_data),
        .sys_req_data_valid     (sys_req_data_valid),
        .sys_resp_data          (sys_resp_data_p3),
        .sys_resp_data_valid    (sys_resp_data_valid_p3),

        .counter_ns(counter_ns)

    );


    wire        sfifo_rd;
    wire [ 7:0] sfifo_dout;
    wire        ptr_sfifo_rd;
    wire [19:0] ptr_sfifo_dout;
    wire        ptr_sfifo_empty;
    interface_mux_v3 u_interface_mux (
        .clk_sys(clk),
        .rstn_sys(rstn_sys),
        .rx_data_fifo_dout0(emac0_rx_data_fifo_dout),
        .rx_data_fifo_rd0(emac0_rx_data_fifo_rd),
        .rx_ptr_fifo_dout0(emac0_rx_ptr_fifo_dout),
        .rx_ptr_fifo_rd0(emac0_rx_ptr_fifo_rd),
        .rx_ptr_fifo_empty0(emac0_rx_ptr_fifo_empty),

        .rx_data_fifo_dout1(emac1_rx_data_fifo_dout),
        .rx_data_fifo_rd1(emac1_rx_data_fifo_rd),
        .rx_ptr_fifo_dout1(emac1_rx_ptr_fifo_dout),
        .rx_ptr_fifo_rd1(emac1_rx_ptr_fifo_rd),
        .rx_ptr_fifo_empty1(emac1_rx_ptr_fifo_empty),

        .rx_data_fifo_dout2(emac2_rx_data_fifo_dout),
        .rx_data_fifo_rd2(emac2_rx_data_fifo_rd),
        .rx_ptr_fifo_dout2(emac2_rx_ptr_fifo_dout),
        .rx_ptr_fifo_rd2(emac2_rx_ptr_fifo_rd),
        .rx_ptr_fifo_empty2(emac2_rx_ptr_fifo_empty),

        .rx_data_fifo_dout3(emac3_rx_data_fifo_dout),
        .rx_data_fifo_rd3(emac3_rx_data_fifo_rd),
        .rx_ptr_fifo_dout3(emac3_rx_ptr_fifo_dout),
        .rx_ptr_fifo_rd3(emac3_rx_ptr_fifo_rd),
        .rx_ptr_fifo_empty3(emac3_rx_ptr_fifo_empty),

        .sfifo_rd(sfifo_rd),
        .sfifo_dout(sfifo_dout),
        .ptr_sfifo_rd(ptr_sfifo_rd),
        .ptr_sfifo_dout(ptr_sfifo_dout),
        .ptr_sfifo_empty(ptr_sfifo_empty)
    );

    wire        tte_sfifo_rd;
    wire [ 7:0] tte_sfifo_dout;
    wire        tteptr_sfifo_rd;
    wire [19:0] tteptr_sfifo_dout;
    wire        tteptr_sfifo_empty;
    interface_mux_v3 u_tteinterface_mux (
        .clk_sys(clk),
        .rstn_sys(rstn_sys),
        .rx_data_fifo_dout0({1'b0, emac0_rx_tte_fifo_dout}),
        .rx_data_fifo_rd0(emac0_rx_tte_fifo_rd),
        .rx_ptr_fifo_dout0(emac0_rx_tteptr_fifo_dout),
        .rx_ptr_fifo_rd0(emac0_rx_tteptr_fifo_rd),
        .rx_ptr_fifo_empty0(emac0_rx_tteptr_fifo_empty),

        .rx_data_fifo_dout1({1'b0, emac1_rx_tte_fifo_dout}),
        .rx_data_fifo_rd1(emac1_rx_tte_fifo_rd),
        .rx_ptr_fifo_dout1(emac1_rx_tteptr_fifo_dout),
        .rx_ptr_fifo_rd1(emac1_rx_tteptr_fifo_rd),
        .rx_ptr_fifo_empty1(emac1_rx_tteptr_fifo_empty),

        .rx_data_fifo_dout2({1'b0, emac2_rx_tte_fifo_dout}),
        .rx_data_fifo_rd2(emac2_rx_tte_fifo_rd),
        .rx_ptr_fifo_dout2(emac2_rx_tteptr_fifo_dout),
        .rx_ptr_fifo_rd2(emac2_rx_tteptr_fifo_rd),
        .rx_ptr_fifo_empty2(emac2_rx_tteptr_fifo_empty),

        .rx_data_fifo_dout3({1'b0, emac3_rx_tte_fifo_dout}),
        .rx_data_fifo_rd3(emac3_rx_tte_fifo_rd),
        .rx_ptr_fifo_dout3(emac3_rx_tteptr_fifo_dout),
        .rx_ptr_fifo_rd3(emac3_rx_tteptr_fifo_rd),
        .rx_ptr_fifo_empty3(emac3_rx_tteptr_fifo_empty),

        .sfifo_rd(tte_sfifo_rd),
        .sfifo_dout(tte_sfifo_dout),
        .ptr_sfifo_rd(tteptr_sfifo_rd),
        .ptr_sfifo_dout(tteptr_sfifo_dout),
        .ptr_sfifo_empty(tteptr_sfifo_empty)
    );

    // wire        sof;
    // wire        dv;
    // wire [ 7:0] data;

    wire [127:0] i_cell_data_fifo_dout;
    wire         i_cell_data_fifo_wr;
    wire [ 15:0] i_cell_ptr_fifo_dout;
    wire         i_cell_ptr_fifo_wr;
    wire         i_cell_bp;

    wire        se_source;
    wire [47:0] se_mac;
    wire [15:0] source_portmap;
    wire        se_req;
    wire        se_ack;
    wire [15:0] se_result;
    wire [ 9:0] se_hash;
    wire        se_nak;
    wire        aging_req;
    wire        aging_ack;

    wire        ftm_req_valid;
    wire        ftm_resp_ack;
    wire        ftm_resp_nak;
    wire [15:0] ftm_resp_result;

    wire        fp_stat_valid;
    wire        fp_stat_resp;
    wire [ 7:0] fp_stat_data;
    wire        fp_conf_valid;
    wire        fp_conf_resp;
    wire [ 1:0] fp_conf_type;
    wire [15:0] fp_conf_data;
    wire        swc_mgnt_valid;
    wire        swc_mgnt_resp;
    wire [ 7:0] swc_mgnt_data;

    wire        bp0;
    wire        bp1;
    wire        bp2;
    wire        bp3;

    switch_ctrl #(
        .SW_CTRL_TYPE            ( "BE"                        ),
        .MGNT_REG_WIDTH          ( 16                          )
    ) u_swctrl_be (
        .clk_if                  ( clk_125                     ),
        .rst_if                  ( rstn_sys                    ),
        .fp_stat_valid           ( fp_stat_valid               ),
        .fp_stat_data            ( fp_stat_data         [ 7:0] ),
        .fp_conf_resp            ( fp_conf_resp                ),
        .swc_mgnt_valid          ( swc_mgnt_valid              ),
        .swc_mgnt_data           ( swc_mgnt_data        [ 3:0] ),
        .sys_req_valid           ( sys_req_valid           [4] ),
        .sys_req_wr              ( sys_req_wr                  ),
        .sys_req_addr            ( sys_req_addr         [ 7:0] ),
        .sys_req_data            ( sys_req_data         [ 7:0] ),
        .sys_req_data_valid      ( sys_req_data_valid          ),

        .fp_stat_resp            ( fp_stat_resp                ),
        .fp_conf_valid           ( fp_conf_valid               ),
        .fp_conf_type            ( fp_conf_type         [ 1:0] ),
        .fp_conf_data            ( fp_conf_data         [15:0] ),
        .swc_mgnt_resp           ( swc_mgnt_resp               ),
        .sys_req_ack             ( sys_req_ack_be              ),
        .sys_resp_data           ( sys_resp_data_be     [ 7:0] ),
        .sys_resp_data_valid     ( sys_resp_data_valid_be      )
    );


    frame_process_v3 u_frame_process (
        .clk(clk),
        .rstn(rstn_sys),
        .sfifo_dout(sfifo_dout),
        .sfifo_rd(sfifo_rd),
        .ptr_sfifo_rd(ptr_sfifo_rd),
        .ptr_sfifo_empty(ptr_sfifo_empty),
        .ptr_sfifo_dout(ptr_sfifo_dout),

        // .sof (sof),
        // .dv  (dv),
        // .data(data),
        .i_cell_data_fifo_dout(i_cell_data_fifo_dout),
        .i_cell_data_fifo_wr(i_cell_data_fifo_wr),
        .i_cell_ptr_fifo_dout(i_cell_ptr_fifo_dout),
        .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),
        .i_cell_bp(i_cell_bp),

        .se_mac(se_mac),
        .se_req(se_req),
        .se_ack(se_ack),
        .source_portmap(source_portmap),
        .se_result(se_result),
        .se_nak(se_nak),
        .se_source(se_source),
        .se_hash(se_hash),
        .link(link),
        
        .ftm_req_valid(ftm_req_valid),
        .ftm_resp_ack(ftm_resp_ack),
        .ftm_resp_nak(ftm_resp_nak),
        .ftm_resp_result(ftm_resp_result),

        .fp_stat_valid(fp_stat_valid),
        .fp_stat_resp(fp_stat_resp),
        .fp_stat_data(fp_stat_data),
        .fp_conf_valid(fp_conf_valid),
        .fp_conf_resp(fp_conf_resp),
        .fp_conf_type(fp_conf_type),
        .fp_conf_data(fp_conf_data)

    );

    hash_2_bucket_mgnt #(
        .MGNT_REG_WIDTH ( 16 )
    ) u_hash (
        .clk(clk),
        .rstn(rstn_sys),
        .se_req(se_req),
        .se_ack(se_ack),
        .se_hash(se_hash),
        .se_portmap(source_portmap),
        .se_source(se_source),
        .se_result(se_result),
        .se_nak(se_nak),
        .se_mac(se_mac),
        .clk_if                  ( clk_125                     ),
        .rst_if                  ( rstn_sys                    ),
        .sys_req_valid           ( sys_req_valid           [5] ),
        .sys_req_wr              ( sys_req_wr                  ),
        .sys_req_addr            ( sys_req_addr         [ 7:0] ),
        .sys_req_data            ( sys_req_data         [ 7:0] ),
        .sys_req_data_valid      ( sys_req_data_valid          ),
        .sys_req_ack             ( sys_req_ack_ft              ),
        .sys_resp_data           ( sys_resp_data_ft     [ 7:0] ),
        .sys_resp_data_valid     ( sys_resp_data_valid_ft      )
    );

    hash_multicast #(
        .MGNT_REG_WIDTH ( 16 )
    ) u_hash_multicast (
        .clk_if                  ( clk_125                     ),
        .rst_if                  ( rstn_sys                    ),
        .clk_sys                 ( clk                         ),
        .rst_sys                 ( rstn_sys                    ),
        .ftm_req_valid           ( ftm_req_valid               ),
        .ftm_req_mac             ( se_mac               [15:0] ),
        .sys_req_valid           ( sys_req_valid           [6] ),
        .sys_req_wr              ( sys_req_wr                  ),
        .sys_req_addr            ( sys_req_addr         [ 7:0] ),
        .sys_req_data            ( sys_req_data         [ 7:0] ),
        .sys_req_data_valid      ( sys_req_data_valid          ),

        .ftm_resp_ack            ( ftm_resp_ack                ),
        .ftm_resp_nak            ( ftm_resp_nak                ),
        .ftm_resp_result         ( ftm_resp_result      [15:0] ),
        .sys_req_ack             ( sys_req_ack_ftm             ),
        .sys_resp_data           ( sys_resp_data_ftm    [ 7:0] ),
        .sys_resp_data_valid     ( sys_resp_data_valid_ftm     )
    );

    switch_top_v2 switch (
        .clk (clk),
        .rstn(rstn_sys),

        // .sof(sof),
        // .dv (dv),
        // .din(data),

        .i_cell_data_fifo_dout(i_cell_data_fifo_dout),
        .i_cell_data_fifo_wr(i_cell_data_fifo_wr),
        .i_cell_ptr_fifo_dout(i_cell_ptr_fifo_dout),
        .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),
        .i_cell_bp(i_cell_bp),

        .interface_clk0(emac0_interface_clk),
        .interface_clk1(emac1_interface_clk),
        .interface_clk2(emac2_interface_clk),
        .interface_clk3(emac3_interface_clk),
        .ptr_fifo_rd0(emac0_tx_ptr_fifo_rd),
        .ptr_fifo_rd1(emac1_tx_ptr_fifo_rd),
        .ptr_fifo_rd2(emac2_tx_ptr_fifo_rd),
        .ptr_fifo_rd3(emac3_tx_ptr_fifo_rd),
        .data_fifo_rd0(emac0_tx_data_fifo_rd),
        .data_fifo_rd1(emac1_tx_data_fifo_rd),
        .data_fifo_rd2(emac2_tx_data_fifo_rd),
        .data_fifo_rd3(emac3_tx_data_fifo_rd),
        .data_fifo_dout0(emac0_tx_data_fifo_dout),
        .data_fifo_dout1(emac1_tx_data_fifo_dout),
        .data_fifo_dout2(emac2_tx_data_fifo_dout),
        .data_fifo_dout3(emac3_tx_data_fifo_dout),
        .ptr_fifo_dout0(emac0_tx_ptr_fifo_dout),
        .ptr_fifo_dout1(emac1_tx_ptr_fifo_dout),
        .ptr_fifo_dout2(emac2_tx_ptr_fifo_dout),
        .ptr_fifo_dout3(emac3_tx_ptr_fifo_dout),
        .ptr_fifo_empty0(emac0_tx_ptr_fifo_empty),
        .ptr_fifo_empty1(emac1_tx_ptr_fifo_empty),
        .ptr_fifo_empty2(emac2_tx_ptr_fifo_empty),
        .ptr_fifo_empty3(emac3_tx_ptr_fifo_empty),

        .swc_mgnt_valid( swc_mgnt_valid              ),
        .swc_mgnt_data ( swc_mgnt_data        [ 3:0] ),
        .swc_mgnt_resp ( swc_mgnt_resp               )
    );

    wire        tte_sof;
    wire        tte_dv;
    wire [ 7:0] tte_data;
    wire [47:0] tte_se_dmac;
    wire [47:0] tte_se_smac;
    wire        tte_se_req;
    wire        tte_se_ack;
    wire [15:0] tte_se_result;
    wire [11:0] tte_se_hash;
    wire        tte_se_nak;

    wire        tte_fp_stat_valid;
    wire        tte_fp_stat_resp;
    wire [ 7:0] tte_fp_stat_data;
    wire        tte_fp_conf_valid;
    wire        tte_fp_conf_resp;
    wire [ 1:0] tte_fp_conf_type;
    wire [15:0] tte_fp_conf_data;
    wire        tte_swc_mgnt_valid;
    wire        tte_swc_mgnt_resp;
    wire [ 7:0] tte_swc_mgnt_data;

    wire        tte_bp0;
    wire        tte_bp1;
    wire        tte_bp2;
    wire        tte_bp3;

    switch_ctrl #(
        .SW_CTRL_TYPE            ( "TTE"                       ),
        .MGNT_REG_WIDTH          ( 16                          )
    ) u_swctrl_tte (
        .clk_if                  ( clk_125                     ),
        .rst_if                  ( rstn_sys                    ),
        .fp_stat_valid           ( tte_fp_stat_valid           ),
        .fp_stat_data            ( tte_fp_stat_data     [ 7:0] ),
        .fp_conf_resp            ( tte_fp_conf_resp            ),
        .swc_mgnt_valid          ( tte_swc_mgnt_valid          ),
        .swc_mgnt_data           ( tte_swc_mgnt_data    [ 3:0] ),
        .sys_req_valid           ( sys_req_valid           [7] ),
        .sys_req_wr              ( sys_req_wr                  ),
        .sys_req_addr            ( sys_req_addr         [ 7:0] ),
        .sys_req_data            ( sys_req_data         [ 7:0] ),
        .sys_req_data_valid      ( sys_req_data_valid          ),

        .fp_stat_resp            ( tte_fp_stat_resp            ),
        .fp_conf_valid           ( tte_fp_conf_valid           ),
        .fp_conf_type            ( tte_fp_conf_type     [ 1:0] ),
        .fp_conf_data            ( tte_fp_conf_data     [15:0] ),
        .swc_mgnt_resp           ( tte_swc_mgnt_resp           ),
        .sys_req_ack             ( sys_req_ack_tte             ),
        .sys_resp_data           ( sys_resp_data_tte    [ 7:0] ),
        .sys_resp_data_valid     ( sys_resp_data_valid_tte     )
    );

    tteframe_process_retime u_tteframe_process (
        .clk(clk),
        .rstn(rstn_sys),
        .sfifo_dout(tte_sfifo_dout),
        .sfifo_rd(tte_sfifo_rd),
        .ptr_sfifo_rd(tteptr_sfifo_rd),
        .ptr_sfifo_empty(tteptr_sfifo_empty),
        .ptr_sfifo_dout(tteptr_sfifo_dout),

        .sof (tte_sof),
        .dv  (tte_dv),
        .data(tte_data),

        .se_dmac(tte_se_dmac),
        .se_smac(tte_se_smac),
        .se_req(tte_se_req),
        .se_ack(tte_se_ack),
        .se_result(tte_se_result),
        .se_nak(tte_se_nak),
        .se_hash(tte_se_hash),
        .link(link),

        .fp_stat_valid(tte_fp_stat_valid),
        .fp_stat_resp(tte_fp_stat_resp),
        .fp_stat_data(tte_fp_stat_data),
        .fp_conf_valid(tte_fp_conf_valid),
        .fp_conf_resp(tte_fp_conf_resp),
        .fp_conf_type(tte_fp_conf_type),
        .fp_conf_data(tte_fp_conf_data),

        .bp0(tte_bp0),
        .bp1(tte_bp1),
        .bp2(tte_bp2),
        .bp3(tte_bp3)

    );

    wire hash_clear;
    wire hash_update;
    wire [11:0] hash;
    wire [119:0] flow;
    wire reg_rst;

    hash_tte_bucket u_ttehash (
        .clk(clk),
        .rstn(rstn_sys),
        .se_req(tte_se_req),
        .se_ack(tte_se_ack),
        .se_hash(tte_se_hash),
        .se_result(tte_se_result),
        .se_nak(tte_se_nak),
        .se_dmac(tte_se_dmac),
        .se_smac(tte_se_smac),
        .hash_clear(hash_clear),
        .hash_update(hash_update),
        .hash(hash),
        .flow(flow),
        .reg_rst(reg_rst)
    );

    // wire [127:0] flow_mux;
    // wire [11:0] hash_mux;
    // wire r_hash_clear;
    // wire r_hash_update;
    // wire ttehash_req;
    // wire ttehash_ack;

    // bus2ttehash bus2ttehashinst (
    //     .clk(clk),
    //     .rstn(rstn_sys),
    //     .flow_mux(flow_mux[119:0]),
    //     .hash_mux(hash_mux),
    //     .flow(flow),
    //     .hash(hash),
    //     .hash_clear(hash_clear),
    //     .hash_update(hash_update),
    //     .r_hash_clear(r_hash_clear),
    //     .r_hash_update(r_hash_update),
    //     .reg_rst(reg_rst),
    //     .ttehash_req(ttehash_req),
    //     .ttehash_ack(ttehash_ack)
    // );




    wire    spi_req;
    wire    spi_ack;
    wire    [6:0]   spi_addr;
    wire    [15:0]  spi_din;
    wire    [15:0]  spi_dout;


    // reg_ctrl reg_ctrl_inst (
    //     .clk(clk),
    //     .rst_n(rstn_sys),
    //     .spi_req(spi_req),
    //     .spi_ack(spi_ack),
    //     .ttehash_req(ttehash_req),
    //     .ttehash_ack(ttehash_ack),
    //     .spi_addr(spi_addr),
    //     .spi_din(spi_din),
    //     .spi_dout(spi_dout),
    //     .r_hash_clear(r_hash_clear),
    //     .r_hash_update(r_hash_update),
    //     .r_flow_mux(flow_mux),
    //     .r_hash(hash_mux)
    // );

    register_v2 #(
        .MGNT_REG_WIDTH(16)
    ) reg_v2_inst (
        .clk(clk_125),
        .rst(rstn_sys),
        .spi_wr(spi_req),
        .spi_op(spi_addr),
        .spi_din(spi_din),
        .spi_ack(spi_ack),
        .spi_dout(spi_dout),
        .sys_req_valid           ( sys_req_valid   [ 7:0]  ),
        .sys_req_wr              ( sys_req_wr              ),
        .sys_req_addr            ( sys_req_addr    [ 7:0]  ),
        .sys_req_ack             ( sys_req_ack             ),
        .sys_req_data            ( sys_req_data    [ 7:0]  ),
        .sys_req_data_valid      ( sys_req_data_valid      ),
        .sys_resp_data           ( sys_resp_data   [ 7:0]  ),
        .sys_resp_data_valid     ( sys_resp_data_valid     ),
        .ft_clear                ( hash_clear              ),
        .ft_update               ( hash_update             ),
        .ft_ack                  ( reg_rst                 ),
        .flow                    ( flow            [119:0] ),
        .hash                    ( hash            [11:0]  ),
        .link                    ( link                    ),
        .int                     ( int                     )
    );

    spi_process spi_process_inst (
        .clk     (clk_125),
        .rst_n   (rstn_sys),
        .csb     (csb),
        .mosi    (mosi),
        .sck     (sck),
        .miso    (miso),
        .reg_dout(spi_dout),
        .spi_req (spi_req),
        .spi_ack (spi_ack),
        .spi_addr(spi_addr),
        .reg_din (spi_din)
    );


    switch_top tteswitch (
        .clk (clk),
        .rstn(rstn_sys),

        .sof(tte_sof),
        .dv (tte_dv),
        .din(tte_data),

        .interface_clk0(emac0_interface_clk),
        .interface_clk1(emac1_interface_clk),
        .interface_clk2(emac2_interface_clk),
        .interface_clk3(emac3_interface_clk),
        .ptr_fifo_rd0(emac0_tx_tteptr_fifo_rd),
        .ptr_fifo_rd1(emac1_tx_tteptr_fifo_rd),
        .ptr_fifo_rd2(emac2_tx_tteptr_fifo_rd),
        .ptr_fifo_rd3(emac3_tx_tteptr_fifo_rd),
        .data_fifo_rd0(emac0_tx_tte_fifo_rd),
        .data_fifo_rd1(emac1_tx_tte_fifo_rd),
        .data_fifo_rd2(emac2_tx_tte_fifo_rd),
        .data_fifo_rd3(emac3_tx_tte_fifo_rd),
        .data_fifo_dout0(emac0_tx_tte_fifo_dout),
        .data_fifo_dout1(emac1_tx_tte_fifo_dout),
        .data_fifo_dout2(emac2_tx_tte_fifo_dout),
        .data_fifo_dout3(emac3_tx_tte_fifo_dout),
        .ptr_fifo_dout0(emac0_tx_tteptr_fifo_dout),
        .ptr_fifo_dout1(emac1_tx_tteptr_fifo_dout),
        .ptr_fifo_dout2(emac2_tx_tteptr_fifo_dout),
        .ptr_fifo_dout3(emac3_tx_tteptr_fifo_dout),
        .ptr_fifo_empty0(emac0_tx_tteptr_fifo_empty),
        .ptr_fifo_empty1(emac1_tx_tteptr_fifo_empty),
        .ptr_fifo_empty2(emac2_tx_tteptr_fifo_empty),
        .ptr_fifo_empty3(emac3_tx_tteptr_fifo_empty),
        
        .swc_mgnt_valid( tte_swc_mgnt_valid          ),
        .swc_mgnt_data ( tte_swc_mgnt_data    [ 3:0] ),
        .swc_mgnt_resp ( tte_swc_mgnt_resp           )
    );

    /*************************************************************************
generate single end clock
**************************************************************************/
    IBUFDS sys_clk_ibufgds (
        .O (clk_in),
        .I (sys_clk_p),
        .IB(sys_clk_n)
    );

    clk_wiz_0 u_pll (
        .resetn  (1'b1),
        .clk_in1 (clk_in),
        .clk_out1(clk),
        .clk_out2(clk_125),
        .locked  (locked)
    );

    rst_ctrl u_rst (
        .src_clk(clk_in),
        .sys_clk(clk),
        .arstn(rstn),
        .pll_locked(locked),
        // .rstn_pll(rstn_pll),
        .rstn_sys(rstn_sys),
        .rstn_mac(rstn_mac),
        .rstn_phy(rstn_phy)
    );

    assign phy_rstn_0 = 1'b1;
    assign phy_rstn_1 = 1'b1;
    assign phy_rstn_2 = 1'b1;
    assign phy_rstn_3 = 1'b1;

    // assign	phy_rstn_0 = rstn_phy;
    // assign	phy_rstn_1 = rstn_phy;
    // assign	phy_rstn_2 = rstn_phy;
    // assign	phy_rstn_3 = rstn_phy;

endmodule
