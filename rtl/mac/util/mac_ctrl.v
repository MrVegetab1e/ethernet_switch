`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2023/04/20
// Design Name: (G)MII interface system-side ctrl module
// Module Name: mac_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Provide an interface between spi interface and (G)MII interface
// Dependencies: 
// 
// Revision:
// Revision 0.01 - On Progress
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// rx data format
// [19:12] : frame flags
// [11: 0] : frame length
// tx data format
// [15:12] : frame flags
// [11: 0] : frame length
// lldp mode
// 4'b1 : sink mode(recv lldp pkt & redir for mcu)
// 4'b2 : src mode(send lldp pkt for designated port)
// 4'b4 : compatible mode(ignore lldp pkts)
// mdio cfg reg
// [ 1: 0] : speed(refer to phy datasheet)
// [ 2]    : auto negotiation
// [ 3]    : duplex
// [ 4]    : isolate
// [ 5]    : power down
// [ 6]    : restart auto negotiation 
// [ 7]    : soft reset

module mac_ctrl #(
    parameter   MGNT_REG_WIDTH      =   32,
    localparam  MGNT_REG_WIDTH_L2   =   $clog2(MGNT_REG_WIDTH/8)
) (
    input           clk_if,
    input           rst_if,
    // rx side interface
    input           rx_mgnt_valid,
    output reg      rx_mgnt_resp,
    input   [19:0]  rx_mgnt_data,
    output reg      rx_conf_valid,
    input           rx_conf_resp,
    output  [55:0]  rx_conf_data,
    // tx side interface
    input           tx_mgnt_valid,
    output reg      tx_mgnt_resp,
    input   [15:0]  tx_mgnt_data,
    // mdio side interface
    output          mdc,
    inout           mdio,
    output reg  [ 1:0]  speed,
    output reg          link,
    output reg  [ 1:0]  led,
    // sys side interface, cmd channel
    input           sys_req_valid,
    input           sys_req_wr,
    input   [ 7:0]  sys_req_addr,
    output          sys_req_ack,
    // sys side interface, tx channel
    input   [ 7:0]  sys_req_data,
    input           sys_req_data_valid,
    // sys side interface, rx channel
    output  [ 7:0]  sys_resp_data,
    output          sys_resp_data_valid
);

    localparam  MGNT_MAC_RX_ADDR_PKT        =   'h00;
    localparam  MGNT_MAC_RX_ADDR_BYTE       =   'h01;
    localparam  MGNT_MAC_RX_ADDR_PKT_VLAN   =   'h02;
    localparam  MGNT_MAC_RX_ADDR_PKT_LLDP   =   'h03;
    localparam  MGNT_MAC_RX_ADDR_PKT_1588   =   'h04;
    localparam  MGNT_MAC_RX_ADDR_PKT_TTE    =   'h05;
    localparam  MGNT_MAC_RX_ADDR_ERR_FCS    =   'h06;
    localparam  MGNT_MAC_RX_ADDR_ERR_RUNT   =   'h07;
    localparam  MGNT_MAC_RX_ADDR_ERR_JABR   =   'h08;
    localparam  MGNT_MAC_RX_ADDR_ERR_BP     =   'h09;
    localparam  MGNT_MAC_RX_FUNC_CLR        =   'h0F;

    localparam  MGNT_MAC_TX_ADDR_PKT        =   'h10;
    localparam  MGNT_MAC_TX_ADDR_BYTE       =   'h11;
    localparam  MGNT_MAC_TX_ADDR_PKT_TTE    =   'h12;
    localparam  MGNT_MAC_TX_ADDR_PKT_1588   =   'h13;
    localparam  MGNT_MAC_TX_ADDR_PKT_VLAN   =   'h14;
    localparam  MGNT_MAC_TX_ADDR_PKT_FC     =   'h15;
    localparam  MGNT_MAC_TX_FUNC_CLR        =   'h1F;

    localparam  MGNT_MAC_MDIO_ADDR_CFG      =   'h20;
    localparam  MGNT_MAC_MDIO_ADDR_STS      =   'h21;
    localparam  MGNT_MAC_MDIO_FUNC_UPD      =   'h2F;

    localparam  MGNT_MAC_LLDP_ADDR_0        =   'h80;
    localparam  MGNT_MAC_LLDP_ADDR_1        =   'h81;
    localparam  MGNT_MAC_LLDP_ADDR_2        =   'h82;
    localparam  MGNT_MAC_LLDP_PORT          =   'h83;
    localparam  MGNT_MAC_LLDP_MODE          =   'h84;
    localparam  MGNT_MAC_LLDP_FUNC          =   'h8F;

    integer i;

    // reg     [31:0]  mgnt_reg_rx_pkt;
    // reg     [31:0]  mgnt_reg_rx_byte;

    // reg     [31:0]  mgnt_reg_rx_pkt_vlan;
    // reg     [31:0]  mgnt_reg_rx_pkt_fc;
    // reg     [31:0]  mgnt_reg_rx_pkt_1588;
    // reg     [31:0]  mgnt_reg_rx_pkt_tte;
    // reg     [31:0]  mgnt_reg_rx_err_fcs;
    // reg     [31:0]  mgnt_reg_rx_err_runt;
    // reg     [31:0]  mgnt_reg_rx_err_jabber;
    // reg     [31:0]  mgnt_reg_rx_err_bp;

    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_rx [ 9: 0];

    // reg     [31:0]  mgnt_reg_tx_pkt;
    // reg     [31:0]  mgnt_reg_tx_byte;
    // reg     [31:0]  mgnt_reg_tx_pkt_tte;
    // reg     [31:0]  mgnt_reg_tx_pkt_1588;
    // reg     [31:0]  mgnt_reg_tx_pkt_vlan;
    // reg     [31:0]  mgnt_reg_tx_pkt_fc;

    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_tx [21:16];

    // reg     [47:0]  mgnt_reg_lldp_dest;
    // reg     [15:0]  mgnt_reg_lldp_port;
    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_lldp [4:0];

    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_mdio [1:0];

    reg     [ 2:0]  mgnt_rx_state, mgnt_rx_state_next;
    reg     [ 1:0]  mgnt_buf_rx_valid;
    reg     [19:0]  mgnt_buf_rx_data;
    reg     [ 2:0]  mgnt_tx_state, mgnt_tx_state_next;
    reg     [ 1:0]  mgnt_buf_tx_valid;
    reg     [15:0]  mgnt_buf_tx_data;
    reg     [ 1:0]  mgnt_lldp_state, mgnt_lldp_state_next;
    reg     [ 1:0]  mgnt_buf_lldp_resp;
    reg     [ 4:0]  mgnt_mdio_state, mgnt_mdio_state_next;

    reg     [ 5:0]  mgnt_state, mgnt_state_next;
    reg             mgnt_reg_req_wr;
    reg     [ 7:0]  mgnt_reg_req_addr;
    reg             mgnt_reg_req_ack;
    reg             mgnt_reg_resp_data_valid;
    // reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_resp_data;
    // reg     [MGNT_REG_WIDTH_L2-1:0] mgnt_cnt;
    reg     [MGNT_REG_WIDTH-1:0]    mgnt_rx_buf, mgnt_tx_buf;
    reg     [MGNT_REG_WIDTH_L2-1:0] mgnt_rx_cnt, mgnt_tx_cnt;


    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_buf_rx_valid   <=  'b0;
            mgnt_buf_tx_valid   <=  'b0;
            mgnt_buf_lldp_resp  <=  'b0;
            rx_mgnt_resp        <=  'b0;
            tx_mgnt_resp        <=  'b0;
            rx_conf_valid       <=  'b0;
        end
        else begin
            mgnt_buf_rx_valid   <=  {mgnt_buf_rx_valid, rx_mgnt_valid};
            mgnt_buf_tx_valid   <=  {mgnt_buf_tx_valid, tx_mgnt_valid};
            mgnt_buf_lldp_resp  <=  {mgnt_buf_lldp_resp, rx_conf_resp};
            rx_mgnt_resp        <=  (mgnt_rx_state[2]);
            tx_mgnt_resp        <=  (mgnt_tx_state[2]);
            rx_conf_valid       <=  (!mgnt_lldp_state[0]);
        end
    end

    always @(posedge clk_if) begin
        if (mgnt_buf_rx_valid == 2'h3) begin
            mgnt_buf_rx_data    <=  rx_mgnt_data;
        end
        if (mgnt_buf_tx_valid == 2'h3) begin
            mgnt_buf_tx_data    <=  tx_mgnt_data;
        end
    end

    always @(*) begin
        case(mgnt_rx_state)
            1 : mgnt_rx_state_next  =   (mgnt_buf_rx_valid[1])  ? 2 : 1;
            2 : mgnt_rx_state_next  =   4;
            4 : mgnt_rx_state_next  =   (!mgnt_buf_rx_valid[1]) ? 1 : 4;
            default : mgnt_rx_state_next    =   mgnt_rx_state;
        endcase
        case(mgnt_tx_state)
            1 : mgnt_tx_state_next  =   (mgnt_buf_tx_valid[1])  ? 2 : 1;
            2 : mgnt_tx_state_next  =   4;
            4 : mgnt_tx_state_next  =   (!mgnt_buf_tx_valid[1]) ? 1 : 4;
            default : mgnt_tx_state_next    =   mgnt_tx_state;
        endcase
        case(mgnt_lldp_state)
            1 : mgnt_lldp_state_next    =   (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_FUNC)  ? 2 : 1;
            2 : mgnt_lldp_state_next    =   (mgnt_buf_lldp_resp[1])                                     ? 1 : 2;
            default : mgnt_lldp_state_next  =   mgnt_lldp_state;
        endcase
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_rx_state   <=  1;
            mgnt_tx_state   <=  1;
            mgnt_lldp_state <=  1;
        end
        else begin
            mgnt_rx_state   <=  mgnt_rx_state_next;
            mgnt_tx_state   <=  mgnt_tx_state_next;
            mgnt_lldp_state <=  mgnt_lldp_state_next;
        end
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_reg_req_wr             <=  'b0; 
            mgnt_reg_req_addr           <=  'b0;
            mgnt_reg_req_ack            <=  'b0;
            // mgnt_reg_resp_data          <=  'b0;
            mgnt_reg_resp_data_valid    <=  'b0;
            mgnt_rx_cnt                 <=  'b0;
            mgnt_tx_cnt                 <=  'b0;
        end
        else begin
            if (sys_req_valid) begin
                mgnt_reg_req_wr             <=  sys_req_wr;
                mgnt_reg_req_addr           <=  sys_req_addr;
            end
            if (mgnt_state[0]) begin
                mgnt_tx_cnt                 <=  'b0;
            end
            if (mgnt_state[1]) begin
                mgnt_reg_resp_data_valid    <=  1'b1;
                mgnt_tx_buf                 <=  mgnt_reg_req_addr[7] ? 
                                                mgnt_reg_lldp[mgnt_reg_req_addr[3:0]] :
                                                mgnt_reg_req_addr[5] ? 
                                                mgnt_reg_mdio[mgnt_reg_req_addr] : 
                                                mgnt_reg_req_addr[4] ? 
                                                mgnt_reg_tx[mgnt_reg_req_addr] : 
                                                mgnt_reg_rx[mgnt_reg_req_addr] ;
                // mgnt_reg_resp_data          <=  mgnt_reg_req_addr[4] ? 
                //                                 mgnt_reg_tx[mgnt_reg_req_addr] : 
                //                                 mgnt_reg_rx[mgnt_reg_req_addr] ;
            end
            else if (mgnt_state[2]) begin
                if (mgnt_tx_cnt == {MGNT_REG_WIDTH_L2{1'b1}}) begin
                    mgnt_reg_resp_data_valid    <=  1'b0;
                end
                mgnt_tx_cnt                 <=  mgnt_tx_cnt + 1'b1;
                mgnt_tx_buf                 <=  mgnt_tx_buf << 8;
                // mgnt_cnt                    <=  mgnt_cnt + 1'b1;
                // mgnt_reg_resp_data          <=  mgnt_reg_resp_data << 8;
            end
            if (mgnt_state[0]) begin
                mgnt_rx_cnt                 <=  'b0;
            end
            else if (mgnt_state[3] && sys_req_data_valid) begin
                mgnt_rx_cnt                 <=  mgnt_rx_cnt + 1'b1;
                mgnt_rx_buf                 <=  {mgnt_rx_buf, sys_req_data};
            end
            if (mgnt_state_next[5]) begin
                mgnt_reg_req_ack            <=  'b1;
            end
            else if (mgnt_state_next[0]) begin
                mgnt_reg_req_ack            <=  'b0;
            end
            // else if (mgnt_state_next == 01) begin
                // mgnt_reg_resp_valid <=  1'b0;
            // end
        end
    end

    always @(*) begin
        case(mgnt_state)
            01: mgnt_state_next =   sys_req_valid && sys_req_wr                 ? 08 : 
                                    sys_req_valid && !sys_req_wr                ? 02 : 01;  // idle
            02: mgnt_state_next =                                                 04 ;      // rx
            04: mgnt_state_next =   (mgnt_tx_cnt == {MGNT_REG_WIDTH_L2{1'b1}})  ? 32 : 04;  // rx loop
            08: mgnt_state_next =   (mgnt_rx_cnt == {MGNT_REG_WIDTH_L2{1'b1}})  ? 16 : 08;      // tx
            16: mgnt_state_next =                                                 32 ;      
            32: mgnt_state_next =   !sys_req_valid                              ? 01 : 32;
            default: mgnt_state_next = mgnt_state;
        endcase
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_state  <=  1;
        end
        else begin
            mgnt_state  <=  mgnt_state_next;
        end
    end

    always @(posedge clk_if) begin
        // if (!rst_if || (mgnt_state == 16 && mgnt_reg_req_addr == 'h0F)) begin
        if (!rst_if) begin
            for (i = 0; i < 10; i = i + 1) begin
                mgnt_reg_rx[i]  <=  'b0;
            end
        end
        else if (mgnt_rx_state == 2) begin
            if (mgnt_buf_rx_data[19:16] == 'b0) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT]   <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT] + 1'b1;
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_BYTE]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_BYTE] + mgnt_buf_rx_data[11:0];
            end
            if (mgnt_buf_rx_data[19]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_BP]    <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_BP] + 1'b1;
            end
            if (mgnt_buf_rx_data[18]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_JABR]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_JABR] + 1'b1;
            end
            if (mgnt_buf_rx_data[17]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_RUNT]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_RUNT] + 1'b1;
            end
            if (mgnt_buf_rx_data[16]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_FCS]   <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_ERR_FCS] + 1'b1;
            end
            if (mgnt_buf_rx_data[15]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_TTE]   <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_TTE] + 1'b1;
            end
            if (mgnt_buf_rx_data[14]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_1588]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_1588] + 1'b1;
            end
            if (mgnt_buf_rx_data[13]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_LLDP]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_LLDP] + 1'b1;
            end
            if (mgnt_buf_rx_data[12]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_VLAN]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_VLAN] + 1'b1;
            end
        end
    end

    always @(posedge clk_if) begin
        // if (!rst_if || (mgnt_state == 16 && mgnt_reg_req_addr == 'h1F)) begin
        if (!rst_if) begin
            for (i = 0; i < 6; i = i + 1) begin
                mgnt_reg_tx[i+16]  <=  'b0;
            end
        end
        else if (mgnt_tx_state == 2) begin
            // if (mgnt_buf_tx_data[19:16] == 'b0) begin
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT]   <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT] + 1'b1;
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_BYTE]  <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_BYTE] + mgnt_buf_tx_data[11:0];
            // end
            if (mgnt_buf_tx_data[15]) begin
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_TTE]   <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_TTE] + 1'b1;
            end
            if (mgnt_buf_tx_data[14]) begin
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_1588]  <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_1588] + 1'b1;
            end
            if (mgnt_buf_tx_data[13]) begin
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_FC]    <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_FC] + 1'b1;
            end
            if (mgnt_buf_tx_data[12]) begin
                mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_VLAN]  <=  mgnt_reg_tx[MGNT_MAC_TX_ADDR_PKT_VLAN] + 1'b1;
            end
        end
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            for (i = 0; i < 4; i = i + 1) begin
                mgnt_reg_lldp[i]  <=  'b0;
            end
        end
        else begin
            if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_ADDR_0) begin
                mgnt_reg_lldp[0]    <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_ADDR_1) begin
                mgnt_reg_lldp[1]    <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_ADDR_2) begin
                mgnt_reg_lldp[2]    <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_PORT) begin
                mgnt_reg_lldp[3]    <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_LLDP_MODE) begin
                mgnt_reg_lldp[4]    <=  mgnt_rx_buf;
            end
        end
    end

    reg     [31:0]  mdio_timer;     // query link status
    reg             mdio_valid;
    reg             mdio_wr;
    reg     [ 9:0]  mdio_addr;
    reg     [15:0]  mdio_req_data;
    wire    [15:0]  mdio_resp_data;
    // reg     [15:0]  mdio_resp_data_reg;
    wire            mdio_resp_valid;

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mdio_timer      <=  'b0;
        end
        else begin
            if (mdio_timer == 32'd25000000) begin
                mdio_timer  <=  'b0;
            end
            else begin
                mdio_timer  <=  mdio_timer + 1'b1;
            end
        end
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_reg_mdio[0]    <=  'h40;
            mgnt_reg_mdio[1]    <=  'b0;
        end
        else begin
            if (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_MDIO_ADDR_CFG) begin
                mgnt_reg_mdio[0]    <=  mgnt_rx_buf;
            end
            if (mgnt_mdio_state[4] && mdio_resp_valid) begin
                mgnt_reg_mdio[1]    <=  mdio_resp_data;
            end
        end
    end

    always @(*) begin
        case(mgnt_mdio_state)
            // Idle state
            01: mgnt_mdio_state_next =  (mgnt_state[4] && mgnt_reg_req_addr == MGNT_MAC_MDIO_FUNC_UPD) ? 2 : 
                                        mdio_timer == 'b0 ? 8 : 1;
            // Update config
            02: mgnt_mdio_state_next =  4;
            04: mgnt_mdio_state_next =  (mdio_resp_valid) ? 1 : 4;
            // Read status
            08: mgnt_mdio_state_next =  16;
            16: mgnt_mdio_state_next =  (mdio_resp_valid) ? 1 : 16;
            default: mgnt_mdio_state_next = mgnt_mdio_state;
        endcase
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_mdio_state <=  1;
        end
        else begin
            mgnt_mdio_state <=  mgnt_mdio_state_next;
        end
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mdio_valid          <=  'b0;
            mdio_wr             <=  'b0;
            mdio_addr           <=  'b0;
            mdio_req_data       <=  'b0;
            // mdio_resp_data_reg  <=  'b0;
        end
        else begin
            if (mgnt_mdio_state[1]) begin
                mdio_valid      <=  'b1;
                mdio_wr         <=  'b1;
                mdio_addr       <=  10'h20;
                mdio_req_data   <=  {mgnt_reg_mdio[0][7], 
                                     1'b0, 
                                     mgnt_reg_mdio[0][0], 
                                     mgnt_reg_mdio[0][2], 
                                     mgnt_reg_mdio[0][5],
                                     mgnt_reg_mdio[0][4],
                                     mgnt_reg_mdio[0][6],
                                     mgnt_reg_mdio[0][3],
                                     1'b0,
                                     mgnt_reg_mdio[0][1],
                                     6'b0};
            end
            else if (mgnt_mdio_state[3]) begin
                mdio_valid      <=  'b1;
                mdio_wr         <=  'b0;
                mdio_addr       <=  10'h31;
            end
            else begin
                mdio_valid      <=  'b0;
            end
            // if (mgnt_mdio_state[4] && mdio_resp_valid) begin
            //     mdio_resp_data_reg  <=  mdio_resp_data;
            // end
        end
    end

    always @(posedge clk_if or negedge rst_if) begin
        if (!rst_if) begin
            speed   <=  2'b11;
            link    <=  1'b0;
            led     <=  2'b0;
        end
        else if (mgnt_mdio_state[4] && mdio_resp_valid) begin
            speed   <=  mdio_resp_data[15:14];
            link    <=  mdio_resp_data[10];
            led     <=  mdio_resp_data[15:14];
        end
    end

    smi_new #(
        .REF_CLK(125),
        .MDC_CLK(500)
    ) smi_inst (
        .clk(clk_if),
        .rstn(rst_if),
        .mdc(mdc),
        .mdio(mdio),
        .req_valid(mdio_valid),
        .req_wr(mdio_wr),
        .req_addr(mdio_addr),
        .req_data(mdio_req_data),
        .resp_valid(mdio_resp_valid),
        .resp_data(mdio_resp_data)
    );

    // assign  rx_conf_data        =   {mgnt_reg_lldp_port[3:0], mgnt_reg_lldp_dest};
    assign  rx_conf_data        =   {mgnt_reg_lldp[4][3:0],
                                     mgnt_reg_lldp[3][3:0],
                                     mgnt_reg_lldp[2],
                                     mgnt_reg_lldp[1],
                                     mgnt_reg_lldp[0]};

    assign  sys_req_ack         =   mgnt_reg_req_ack;
    assign  sys_resp_data_valid =   mgnt_reg_resp_data_valid;
    assign  sys_resp_data       =   mgnt_tx_buf[(MGNT_REG_WIDTH-1)-:8];



endmodule