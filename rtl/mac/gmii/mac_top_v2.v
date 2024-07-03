`timescale 1ns / 1ps

module mac_top_v2(
    input              clk,
    input              clk_ref,
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
    output    [1:0]    speed,
    input     [7:0]    speed_ext,

    output              interface_clk,

    output             tx_data_fifo_rd,
    input     [7:0]    tx_data_fifo_dout,
    output             tx_ptr_fifo_rd,
    input     [15:0]   tx_ptr_fifo_dout,
    input              tx_ptr_fifo_empty,
                  
    input             rx_data_fifo_rd,
    output    [8:0]   rx_data_fifo_dout,
    input             rx_ptr_fifo_rd,
	output    [19:0]  rx_ptr_fifo_dout,
    output            rx_ptr_fifo_empty,

    output             tx_tte_fifo_rd,
    input     [7:0]    tx_tte_fifo_dout,
    output             tx_tteptr_fifo_rd,
    input     [15:0]   tx_tteptr_fifo_dout,
    input              tx_tteptr_fifo_empty,
                  
    input             rx_tte_fifo_rd,
    output    [7:0]   rx_tte_fifo_dout,
    input             rx_tteptr_fifo_rd,
	output    [19:0]  rx_tteptr_fifo_dout,
    output            rx_tteptr_fifo_empty,

    // output    [6:0]   port_addr,
    // output    [15:0]  port_din,
    // output            port_req,
    // input             port_ack,

    input               sys_req_valid,
    input               sys_req_wr,
    input   [ 7:0]      sys_req_addr,
    output              sys_req_ack,
    input   [ 7:0]      sys_req_data,
    input               sys_req_data_valid,
    output  [ 7:0]      sys_resp_data,
    output              sys_resp_data_valid,

    input   [31:0]      counter_ns

    );

parameter   MAC_PORT = 1;
parameter   RX_DELAY = 8;
localparam  MAC_PORT_ONEH = (16'b1 << MAC_PORT);

integer i;
genvar n;

wire            time_rst;
// wire    [ 1:0]  speed;
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

wire            rx_conf_valid;
wire    [ 1:0]  rx_conf_resp;
wire    [55:0]  rx_conf_data;

wire            tx_mgnt_valid;
wire            tx_mgnt_resp;
wire    [15:0]  tx_mgnt_data;

wire            mac_conf_valid;
wire    [ 1:0]  mac_conf_resp;
wire    [ 3:0]  mac_conf_data;

assign          GMII_TX_CLK =   clk_125;        

wire    [ 7:0]  delay_rx_d;
wire            delay_rx_dv;
wire            delay_rx_er;
wire            delar_rx_clk;

reg     [ 7:0]  speed_all;

always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        speed_all[(2*i)+:2] = (i == MAC_PORT) ? speed : speed_ext[(2*i)+:2];
    end
end

generate
    for (n = 0; n < 8; n = n + 1) begin : rx_d_delay
        IDELAYE2 #(
            .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
            .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
            .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
            .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
            .IDELAY_VALUE(RX_DELAY),                // Input delay tap setting (0-31)
            .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
            .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
            .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
        ) (
            .CNTVALUEOUT(),            // 5-bit output: Counter value output
            .DATAOUT(delay_rx_d[n]),   // 1-bit output: Delayed data output
            .C(clk_ref),               // 1-bit input: Clock input
            .CE(1'b0),                 // 1-bit input: Active high enable increment/decrement input
            .CINVCTRL(1'b0),           // 1-bit input: Dynamic clock inversion input
            .CNTVALUEIN(),             // 5-bit input: Counter value input
            .DATAIN(),                 // 1-bit input: Internal delay data input
            .IDATAIN(GMII_RXD[n]),     // 1-bit input: Data input from the I/O
            .INC(1'b0),                // 1-bit input: Increment / Decrement tap delay input
            .LD(1'b0),                 // 1-bit input: Load IDELAY_VALUE input
            .LDPIPEEN(1'b0),           // 1-bit input: Enable PIPELINE register to load data input
            .REGRST(1'b0)              // 1-bit input: Active-high reset tap-delay input
        );
    end

    IDELAYE2 #(
        .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
        .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
        .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE(RX_DELAY),                // Input delay tap setting (0-31)
        .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
        .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
    )
    rx_dv_delay (
        .CNTVALUEOUT(),            // 5-bit output: Counter value output
        .DATAOUT(delay_rx_dv),     // 1-bit output: Delayed data output
        .C(clk_ref),               // 1-bit input: Clock input
        .CE(1'b0),                 // 1-bit input: Active high enable increment/decrement input
        .CINVCTRL(1'b0),           // 1-bit input: Dynamic clock inversion input
        .CNTVALUEIN(),             // 5-bit input: Counter value input
        .DATAIN(),                 // 1-bit input: Internal delay data input
        .IDATAIN(GMII_RX_DV),      // 1-bit input: Data input from the I/O
        .INC(1'b0),                // 1-bit input: Increment / Decrement tap delay input
        .LD(1'b0),                 // 1-bit input: Load IDELAY_VALUE input
        .LDPIPEEN(1'b0),           // 1-bit input: Enable PIPELINE register to load data input
        .REGRST(1'b0)              // 1-bit input: Active-high reset tap-delay input
    );

    IDELAYE2 #(
        .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
        .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
        .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE(RX_DELAY),                // Input delay tap setting (0-31)
        .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
        .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
    )
    rx_er_delay (
        .CNTVALUEOUT(),            // 5-bit output: Counter value output
        .DATAOUT(delay_rx_er),     // 1-bit output: Delayed data output
        .C(clk_ref),               // 1-bit input: Clock input
        .CE(1'b0),                 // 1-bit input: Active high enable increment/decrement input
        .CINVCTRL(1'b0),           // 1-bit input: Dynamic clock inversion input
        .CNTVALUEIN(),             // 5-bit input: Counter value input
        .DATAIN(),                 // 1-bit input: Internal delay data input
        .IDATAIN(GMII_RX_ER),      // 1-bit input: Data input from the I/O
        .INC(1'b0),                // 1-bit input: Increment / Decrement tap delay input
        .LD(1'b0),                 // 1-bit input: Load IDELAY_VALUE input
        .LDPIPEEN(1'b0),           // 1-bit input: Enable PIPELINE register to load data input
        .REGRST(1'b0)              // 1-bit input: Active-high reset tap-delay input
    );

endgenerate

// IDELAYE2 #(
//     .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
//     .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
//     .HIGH_PERFORMANCE_MODE("TRUE"),  // Reduced jitter ("TRUE"), Reduced power ("FALSE")
//     .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
//     .IDELAY_VALUE(RX_DELAY),         // Input delay tap setting (0-31)
//     .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
//     .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
//     .SIGNAL_PATTERN("CLOCK")         // DATA, CLOCK input signal
// )
// rx_er_delay (
//     .CNTVALUEOUT(),            // 5-bit output: Counter value output
//     .DATAOUT(delay_rx_clk),    // 1-bit output: Delayed data output
//     .C(clk_ref),               // 1-bit input: Clock input
//     .CE(1'b0),                 // 1-bit input: Active high enable increment/decrement input
//     .CINVCTRL(1'b0),           // 1-bit input: Dynamic clock inversion input
//     .CNTVALUEIN(),             // 5-bit input: Counter value input
//     .DATAIN(),                 // 1-bit input: Internal delay data input
//     .IDATAIN(GMII_RX_CLK),     // 1-bit input: Data input from the I/O
//     .INC(1'b0),                // 1-bit input: Increment / Decrement tap delay input
//     .LD(1'b0),                 // 1-bit input: Load IDELAY_VALUE input
//     .LDPIPEEN(1'b0),           // 1-bit input: Enable PIPELINE register to load data input
//     .REGRST(1'b0)              // 1-bit input: Active-high reset tap-delay input
// );

mac_r_gmii_tte_v3 #(
    .LLDP_PARAM_PORT (MAC_PORT_ONEH)
) u_mac_r_gmii (
    .clk(clk),
    .rstn_sys(rstn_sys),
    .rstn_mac(rstn_mac),
    .rx_clk(GMII_RX_CLK),
    .rx_dv(delay_rx_dv),
    .gm_rx_d(delay_rx_d),
    // .gtx_clk(GMII_TX_CLK),
    .speed(speed),
    // .speed_ext(speed_all),
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
    .rx_mgnt_data(rx_mgnt_data),
    .rx_conf_valid(rx_conf_valid),
    .rx_conf_resp(rx_conf_resp[0]),
    .rx_conf_data(rx_conf_data),
    .mac_conf_valid(mac_conf_valid),
    .mac_conf_resp(mac_conf_resp[0]),
    .mac_conf_data(mac_conf_data)
    );

mac_t_gmii_tte_v5 #(
    .LLDP_PARAM_PORT (MAC_PORT_ONEH)
) u_mac_t_gmii (
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
    .tx_mgnt_data(tx_mgnt_data),
    .rx_conf_valid(rx_conf_valid),
    .rx_conf_resp(rx_conf_resp[1]),
    .rx_conf_data(rx_conf_data[55:52]),
    .mac_conf_valid(mac_conf_valid),
    .mac_conf_resp(mac_conf_resp[1]),
    .mac_conf_data(mac_conf_data)
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

// smi_config  #(
// .REF_CLK                 (125                   ),        
// .MDC_CLK                 (500                   )
// )
// smi_config_inst
// (
// .clk                    (clk_125                ),
// .rst_n                  (rstn_mac               ),         
// .mdc                    (MDC                    ),
// .mdio                   (MDIO                   ),
// .link                   (link                   ),
// .speed                  (speed                  ),
// .led                    (led                    )    
// );

mac_ctrl_v2 #(
    .MGNT_REG_WIDTH     ( 16                         )
) mac_ctrl_inst (
    .clk_if             ( clk_125                    ),
    .rst_if             ( rstn_sys                   ),
    .rx_mgnt_valid      ( rx_mgnt_valid              ),
    .rx_mgnt_data       ( rx_mgnt_data        [19:0] ),
    .rx_conf_resp       ( rx_conf_resp        [ 1:0] ),
    .tx_mgnt_valid      ( tx_mgnt_valid              ),
    .tx_mgnt_data       ( tx_mgnt_data        [15:0] ),
    .mac_conf_resp      ( mac_conf_resp       [ 1:0] ),
    .sys_req_valid      ( sys_req_valid              ),
    .sys_req_wr         ( sys_req_wr                 ),
    .sys_req_addr       ( sys_req_addr        [ 7:0] ),
    .sys_req_data       ( sys_req_data        [ 7:0] ),
    .sys_req_data_valid ( sys_req_data_valid         ),

    .rx_mgnt_resp       ( rx_mgnt_resp               ),
    .rx_conf_valid      ( rx_conf_valid              ),
    .rx_conf_data       ( rx_conf_data        [55:0] ),
    .tx_mgnt_resp       ( tx_mgnt_resp               ),
    .mac_conf_valid     ( mac_conf_valid             ),
    .mac_conf_data      ( mac_conf_data       [ 3:0] ),
    .sys_req_ack        ( sys_req_ack                ),
    .sys_resp_data_valid( sys_resp_data_valid        ),
    .sys_resp_data      ( sys_resp_data       [ 7:0] ),

    .mdc                ( MDC                        ),
    .mdio               ( MDIO                       ),
    .link               ( link                       ),
    .speed              ( speed                      ),
    .led                ( led                        ) 
);

endmodule
