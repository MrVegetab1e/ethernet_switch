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
    // tx side interface
    input           tx_mgnt_valid,
    output reg      tx_mgnt_resp,
    input   [15:0]  tx_mgnt_data,
    // sys side interface
    input           sys_req_valid,
    input           sys_req_wr,
    input   [ 7:0]  sys_req_addr,
    // input   [ 7:0]  sys_req_data,
    output          sys_resp_valid,
    output  [ 7:0]  sys_resp_data
);

    localparam  MGNT_MAC_RX_ADDR_PKT        =   'h00;
    localparam  MGNT_MAC_RX_ADDR_BYTE       =   'h01;
    localparam  MGNT_MAC_RX_ADDR_PKT_VLAN   =   'h02;
    localparam  MGNT_MAC_RX_ADDR_PKT_FC     =   'h03;
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

    reg     [ 2:0]  mgnt_rx_state, mgnt_rx_state_next;
    reg     [ 3:0]  mgnt_buf_rx_valid;
    reg     [19:0]  mgnt_buf_rx_data;
    reg     [ 2:0]  mgnt_tx_state, mgnt_tx_state_next;
    reg     [ 3:0]  mgnt_buf_tx_valid;
    reg     [15:0]  mgnt_buf_tx_data;

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_buf_rx_valid   <=  'b0;
            mgnt_buf_tx_valid   <=  'b0;
            rx_mgnt_resp        <=  'b0;
            tx_mgnt_resp        <=  'b0;
        end
        else begin
            mgnt_buf_rx_valid   <=  {mgnt_buf_rx_valid[2:0], rx_mgnt_valid};
            mgnt_buf_tx_valid   <=  {mgnt_buf_tx_valid[2:0], tx_mgnt_valid};
            rx_mgnt_resp        <=  (mgnt_rx_state == 4);
            tx_mgnt_resp        <=  (mgnt_tx_state == 4);
        end
    end

    always @(posedge clk_if) begin
        if (mgnt_buf_rx_valid == 4'hF) begin
            mgnt_buf_rx_data    <=  rx_mgnt_data;
        end
        if (mgnt_buf_tx_valid == 4'hF) begin
            mgnt_buf_tx_data    <=  tx_mgnt_data;
        end
    end

    always @(*) begin
        case(mgnt_rx_state)
            1 : mgnt_rx_state_next  =   (mgnt_buf_rx_valid[3])  ? 2 : 1;
            2 : mgnt_rx_state_next  =   4;
            4 : mgnt_rx_state_next  =   (!mgnt_buf_rx_valid[3]) ? 1 : 4;
            default : mgnt_rx_state_next    =   mgnt_rx_state;
        endcase
        case(mgnt_tx_state)
            1 : mgnt_tx_state_next  =   (mgnt_buf_tx_valid[3])  ? 2 : 1;
            2 : mgnt_tx_state_next  =   4;
            4 : mgnt_tx_state_next  =   (!mgnt_buf_tx_valid[3]) ? 1 : 4;
            default : mgnt_tx_state_next    =   mgnt_tx_state;
        endcase
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_rx_state   <=  1;
            mgnt_tx_state   <=  1;
        end
        else begin
            mgnt_rx_state   <=  mgnt_rx_state_next;
            mgnt_tx_state   <=  mgnt_tx_state_next;
        end
    end

    reg     [ 4:0]  mgnt_state, mgnt_state_next;
    reg             mgnt_reg_req_wr;
    reg     [ 7:0]  mgnt_reg_req_addr;
    reg             mgnt_reg_resp_valid;
    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_resp_data;
    reg     [MGNT_REG_WIDTH_L2-1:0] mgnt_cnt;

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_reg_req_wr     <=  'b0;
            mgnt_reg_req_addr   <=  'b0;
            mgnt_reg_resp_valid <=  'b0;
            mgnt_reg_resp_data  <=  'b0;
            mgnt_cnt            <=  'b1;
        end
        else begin
            if (sys_req_valid) begin
                mgnt_reg_req_wr     <=  sys_req_wr;
                mgnt_reg_req_addr   <=  sys_req_addr;
            end
            if (mgnt_state == 04) begin
                mgnt_reg_resp_valid <=  1'b1;
                mgnt_reg_resp_data  <=  mgnt_reg_req_addr[4] ? mgnt_reg_tx[mgnt_reg_req_addr] : mgnt_reg_rx[mgnt_reg_req_addr];
            end
            else if (mgnt_state == 08) begin
                if (mgnt_cnt == {MGNT_REG_WIDTH_L2{1'b1}}) mgnt_reg_resp_valid <=  1'b0;
                mgnt_cnt            <=  mgnt_cnt + 1'b1;
                mgnt_reg_resp_data  <=  mgnt_reg_resp_data << 8;
            end
            // else if (mgnt_state_next == 01) begin
                // mgnt_reg_resp_valid <=  1'b0;
            // end
        end
    end

    always @(*) begin
        case(mgnt_state)
            01: mgnt_state_next =   sys_req_valid                           ?  2 :  1;  // idle
            02: mgnt_state_next =   mgnt_reg_req_wr                         ? 16 :  4;  // dir
            04: mgnt_state_next =                                              8 ;      // rd
            08: mgnt_state_next =   (mgnt_cnt == {MGNT_REG_WIDTH_L2{1'b1}}) ?  1 :  8;  // rd loop
            16: mgnt_state_next =                                              1 ;      // wr
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
        if (!rst_if || (mgnt_state == 16 && mgnt_reg_req_addr == 'h0F)) begin
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
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_FC]    <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_FC] + 1'b1;
            end
            if (mgnt_buf_rx_data[12]) begin
                mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_VLAN]  <=  mgnt_reg_rx[MGNT_MAC_RX_ADDR_PKT_VLAN] + 1'b1;
            end
        end
    end

    always @(posedge clk_if) begin
        if (!rst_if || (mgnt_state == 16 && mgnt_reg_req_addr == 'h1F)) begin
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

    assign  sys_resp_valid  =   mgnt_reg_resp_valid;
    assign  sys_resp_data   =   mgnt_reg_resp_data[(MGNT_REG_WIDTH-1)-:8];

// mgnt_reg_rx_pkt         <=  'b0;
// mgnt_reg_rx_byte        <=  'b0;
// mgnt_reg_rx_pkt_vlan    <=  'b0;
// mgnt_reg_rx_pkt_fc      <=  'b0;
// mgnt_reg_rx_pkt_1588    <=  'b0;
// mgnt_reg_rx_pkt_tte     <=  'b0;
// mgnt_reg_rx_err_fcs     <=  'b0;
// mgnt_reg_rx_err_runt    <=  'b0;
// mgnt_reg_rx_err_jabber  <=  'b0;
// mgnt_reg_rx_err_bp      <=  'b0;
// mgnt_reg_rx_pkt         <=  mgnt_reg_rx_pkt + 1'b1;
// mgnt_reg_rx_byte        <=  mgnt_reg_rx_byte + mgnt_buf_rx_data[11:0];
// mgnt_reg_rx_pkt         <=  mgnt_reg_rx_pkt + 1'b1;
// mgnt_reg_rx_byte        <=  mgnt_reg_rx_byte + mgnt_buf_rx_data[11:0];
// mgnt_reg_rx_pkt_vlan    <=  mgnt_buf_rx_data[12] ?
//                             mgnt_reg_rx_pkt_vlan + 1'b1 :
//                             mgnt_reg_rx_pkt_vlan;
// mgnt_reg_rx_pkt_fc      <=  mgnt_buf_rx_data[13] ?
//                             mgnt_reg_rx_pkt_fc + 1'b1 :
//                             mgnt_reg_rx_pkt_fc;
// mgnt_reg_rx_pkt_1588    <=  mgnt_buf_rx_data[14] ?
//                             mgnt_reg_rx_pkt_1588 + 1'b1 :
//                             mgnt_reg_rx_pkt_1588;
// mgnt_reg_rx_pkt_tte     <=  mgnt_buf_rx_data[15] ?
//                             mgnt_reg_rx_pkt_tte + 1'b1 :
//                             mgnt_reg_rx_pkt_tte;
// mgnt_reg_rx_err_fcs     <=  mgnt_buf_rx_data[16] ?
//                             mgnt_reg_rx_err_fcs + 1'b1 :
//                             mgnt_reg_rx_err_fcs;
// mgnt_reg_rx_err_runt    <=  mgnt_buf_rx_data[17] ?
//                             mgnt_reg_rx_err_runt + 1'b1 :
//                             mgnt_reg_rx_err_runt;
// mgnt_reg_rx_err_jabber  <=  mgnt_buf_rx_data[18] ?
//                             mgnt_reg_rx_err_jabber + 1'b1 :
//                             mgnt_reg_rx_err_jabber;
// mgnt_reg_rx_err_bp      <=  mgnt_buf_rx_data[19] ?
//                             mgnt_reg_rx_err_bp + 1'b1 :
//                             mgnt_reg_rx_err_bp;

endmodule