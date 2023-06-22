`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2023/04/20
// Design Name: Switch system-side ctrl module
// Module Name: switch_ctrl
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

// fp stat data format
// [ 2: 0] : pkt dst mac type, {BROADCAST, MULTICAST, UNICAST}
// [ 3] : pkt dst mac hit(unicast)
// [ 4] : pkt src mac valid
// [ 5] : pkt src mac learnt
// [ 6] : pkt src learn - ft full
// [ 7] : fp backpressure
// swc stat data format
// [ 0] : blackhole (no valid dest)
// [ 1] : bp, fp_empty
// [ 2] : bp, qc_full
// [ 3] : bp, backend
// BE mode register r/w property
// frp, reg 0-7 : r/o;
// frp, reg 8-9 : r/w;
// frp, reg F   : w/o;
// swc, reg 0-4 : r/o;
// swc, reg F   : w/o;
// TTE mode register r/w property
// frp, reg 0-3 : r/o;
// frp, reg 4   : r/w;
// frp, reg F   : w/o;
// swc, reg 0-4 : r/o;
// swc, reg F   : w/o;

module switch_ctrl #(
    parameter   SW_CTRL_TYPE        =   "BE",
    parameter   MGNT_REG_WIDTH      =   32,
    localparam  MGNT_REG_WIDTH_L2   =   $clog2(MGNT_REG_WIDTH/8)
) (
    input           clk_if,
    input           rst_if,
    // frame_process side interface
    input           fp_stat_valid,  // status channel
    output reg      fp_stat_resp,
    input   [ 7:0]  fp_stat_data,
    output reg      fp_conf_valid,  // config channel
    input           fp_conf_resp,
    output  [ 1:0]  fp_conf_type,
    output  [15:0]  fp_conf_data,
    // switch_core side interface
    input           swc_mgnt_valid,
    output reg      swc_mgnt_resp,
    input   [ 3:0]  swc_mgnt_data,
    // ft control interface
    // output reg      aging_req,
    // input           aging_ack, 
    // sys side interface, cmd channel
    input           sys_req_valid,
    input           sys_req_wr,
    input   [ 7:0]  sys_req_addr,
    output reg      sys_req_ack,
    // sys side interface, tx channel
    input   [ 7:0]  sys_req_data,
    input           sys_req_data_valid,
    // sys side interface, rx channel
    output  [ 7:0]  sys_resp_data,
    output reg      sys_resp_data_valid
);

    if (SW_CTRL_TYPE != "BE" && SW_CTRL_TYPE != "TTE") begin  // check for valid param
        $fatal(1,"Fatal elab. error, Invalid parameter value", SW_CTRL_TYPE);
    end

    // frame_process reg addr, be mode
    localparam  MGNT_SW_FRP_ADDR_UNICAST            =   'h00;
    localparam  MGNT_SW_FRP_ADDR_GROUPCAST          =   'h01;
    localparam  MGNT_SW_FRP_ADDR_BROADCAST          =   'h02;
    localparam  MGNT_SW_FRP_ADDR_FT_SRC_LEARN       =   'h03;
    localparam  MGNT_SW_FRP_ADDR_FT_SRC_EVICT       =   'h04;
    localparam  MGNT_SW_FRP_ADDR_FT_DST_MISS        =   'h05;
    localparam  MGNT_SW_FRP_ADDR_ERR_BP             =   'h06;
    localparam  MGNT_SW_FRP_ADDR_ERR_MAC_INVD       =   'h07;
    localparam  MGNT_SW_FRP_FUNC_FT_FWD_DISABLE     =   'h08;
    localparam  MGNT_SW_FRP_FUNC_FT_LRN_DISABLE     =   'h09;
    localparam  MGNT_SW_FRP_FUNC_FT_AGING_ITVL      =   'h0A;
    localparam  MGNT_SW_FRP_FUNC_FT_RSVD_MULTICAST  =   'h0B;
    // localparam  MGNT_SW_FRP_FUNC_FT_FLUSH           =   'h0E;
    localparam  MGNT_SW_FRP_FUNC_CLR                =   'h0F;
    // frame_process reg addr, tte mode
    localparam  MGNT_SW_FRP_TTE_ADDR_PKT            =   'h00;
    localparam  MGNT_SW_FRP_TTE_ADDR_DST_MISS       =   'h01;
    localparam  MGNT_SW_FRP_TTE_ADDR_ERR_MAC_INVD   =   'h02;
    localparam  MGNT_SW_FRP_TTE_FUNC_FT_FWD_DISABLE =   'h03;
    localparam  MGNT_SW_FRP_TTE_FUNC_CLR            =   'h0F;    
    // switch_core reg addr, shared
    localparam  MGNT_SW_SWC_ADDR_PKT                =   'h10;
    localparam  MGNT_SW_SWC_ADDR_ERR_NO_ROUTE       =   'h11;
    localparam  MGNT_SW_SWC_ADDR_ERR_FQ_EMPTY       =   'h12;
    localparam  MGNT_SW_SWC_ADDR_ERR_QC_FULL        =   'h13;
    localparam  MGNT_SW_SWC_ADDR_ERR_BP             =   'h14;
    localparam  MGNT_SW_SWC_FUNC_CLR                =   'h1F;

    localparam  MGNT_REG_FRP_DEPTH                  =   (SW_CTRL_TYPE == "TTE") ? 4 : 12;
    localparam  MGNT_REG_SWC_DEPTH                  =   5;

    integer i;

    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_frp [MGNT_REG_FRP_DEPTH-1:0];
    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_swc [MGNT_REG_SWC_DEPTH+15:16];

    reg     [ 7:0]  mgnt_frp_rx_state, mgnt_frp_rx_state_next;
    reg     [ 1:0]  mgnt_buf_frp_rx_valid;
    reg     [15:0]  mgnt_buf_frp_rx_data;
    reg     [ 7:0]  mgnt_frp_tx_state, mgnt_frp_tx_state_next;
    reg     [ 1:0]  mgnt_buf_frp_tx_resp;
    reg     [ 1:0]  mgnt_buf_frp_tx_addr;
    reg     [15:0]  mgnt_buf_frp_tx_data;
    reg     [ 7:0]  mgnt_swc_state, mgnt_swc_state_next;
    reg     [ 1:0]  mgnt_buf_swc_valid;
    reg     [15:0]  mgnt_buf_swc_data;

    reg     [ 5:0]  mgnt_state, mgnt_state_next;
    reg             mgnt_rx_wr;
    reg     [ 7:0]  mgnt_rx_addr;
    reg             mgnt_rx_rmt;
    reg     [MGNT_REG_WIDTH_L2-1:0]     mgnt_rx_cnt, mgnt_tx_cnt;
    reg     [   MGNT_REG_WIDTH-1:0]     mgnt_rx_buf, mgnt_tx_buf;

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_buf_frp_rx_valid   <=  'b0;
            mgnt_buf_frp_tx_resp    <=  'b0;
            mgnt_buf_swc_valid      <=  'b0;
            fp_stat_resp            <=  'b0;
            fp_conf_valid           <=  'b0;
            swc_mgnt_resp           <=  'b0;
        end
        else begin
            mgnt_buf_frp_rx_valid   <=  {mgnt_buf_frp_rx_valid, fp_stat_valid};
            mgnt_buf_frp_tx_resp    <=  {mgnt_buf_frp_tx_resp, fp_conf_resp};
            mgnt_buf_swc_valid      <=  {mgnt_buf_swc_valid, swc_mgnt_valid};
            fp_stat_resp            <=  (mgnt_frp_rx_state[2]);
            fp_conf_valid           <=  (!mgnt_frp_tx_state[0]);
            swc_mgnt_resp           <=  (mgnt_swc_state[2]);
        end
    end

    always @(posedge clk_if) begin
        if (mgnt_buf_frp_rx_valid == 2'h3) begin
            mgnt_buf_frp_rx_data    <=  fp_stat_data;
        end
        if (mgnt_buf_swc_valid == 2'h3) begin
            mgnt_buf_swc_data       <=  swc_mgnt_data;
        end
        if (mgnt_frp_tx_state[1]) begin
            mgnt_buf_frp_tx_addr    <=  mgnt_rx_addr[1:0];
            mgnt_buf_frp_tx_data    <=  mgnt_rx_buf;
        end
    end

    assign  fp_conf_type    =   mgnt_buf_frp_tx_addr;
    assign  fp_conf_data    =   mgnt_buf_frp_tx_data;

    always @(*) begin
        case(mgnt_frp_rx_state)
            1 : mgnt_frp_rx_state_next  =   (mgnt_buf_frp_rx_valid[1])      ? 2 : 1;
            2 : mgnt_frp_rx_state_next  =   4;
            4 : mgnt_frp_rx_state_next  =   (!mgnt_buf_frp_rx_valid[1])     ? 1 : 4;
            default : mgnt_frp_rx_state_next    =   mgnt_frp_rx_state;
        endcase
        case(mgnt_frp_tx_state)
            1 : mgnt_frp_tx_state_next  =   (mgnt_state[4] && mgnt_rx_rmt)  ? 2 : 1;
            2 : mgnt_frp_tx_state_next  =   4;
            4 : mgnt_frp_tx_state_next  =   (mgnt_buf_frp_tx_resp == 2'h3)  ? 1 : 4;
            default : mgnt_frp_tx_state_next    =   mgnt_frp_tx_state;
        endcase
        case(mgnt_swc_state)
            1 : mgnt_swc_state_next     =   (mgnt_buf_swc_valid[1])         ? 2 : 1;
            2 : mgnt_swc_state_next     =   4;
            4 : mgnt_swc_state_next     =   (!mgnt_buf_swc_valid[1])        ? 1 : 4;
            default : mgnt_swc_state_next    =   mgnt_swc_state;
        endcase
    end

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_frp_rx_state   <=  1;
            mgnt_frp_tx_state   <=  1;
            mgnt_swc_state      <=  1;
        end
        else begin
            mgnt_frp_rx_state   <=  mgnt_frp_rx_state_next;
            mgnt_frp_tx_state   <=  mgnt_frp_tx_state_next;
            mgnt_swc_state      <=  mgnt_swc_state_next;
        end
    end

    always @(*) begin
        case (mgnt_state)
            // start transaction
            01: mgnt_state_next =   sys_req_valid && sys_req_wr                 ? 08 :
                                    sys_req_valid && !sys_req_wr                ? 02 : 01;
            // read from reg stack
            02: mgnt_state_next =   04;
            // tx loop
            04: mgnt_state_next =   (mgnt_tx_cnt == {MGNT_REG_WIDTH_L2{1'b1}})  ? 32 : 04;
            // rx loop
            08: mgnt_state_next =   (mgnt_rx_cnt == {MGNT_REG_WIDTH_L2{1'b1}})  ? 16 : 08;
            // wait for endpt resp
            16: mgnt_state_next =   (mgnt_frp_tx_state_next[0])                 ? 32 : 16;
            // wait for handshake
            32: mgnt_state_next =   (!sys_req_valid)                            ? 01 : 32;
            // unexpected state trap
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
        if (!rst_if) begin
            mgnt_rx_cnt <=  'b0;
            mgnt_tx_cnt <=  'b0;
        end
        else begin
            if (mgnt_state[0] && sys_req_valid) begin
                mgnt_rx_wr      <=  sys_req_wr;
                mgnt_rx_addr    <=  sys_req_addr;
            end
            if (mgnt_state[0]) begin
                mgnt_tx_cnt <=  'b0;
            end
            else if (mgnt_state[1]) begin
                mgnt_tx_buf <=  sys_req_addr[4] ? mgnt_reg_swc[sys_req_addr] : mgnt_reg_frp[sys_req_addr];  
            end
            else if (mgnt_state[2]) begin
                mgnt_tx_cnt <=  mgnt_tx_cnt + 1'b1;
                mgnt_tx_buf <=  mgnt_tx_buf << 8;
            end
            if (mgnt_state[0]) begin
                mgnt_rx_cnt <=  'b0;
            end
            else if (mgnt_state[3] && sys_req_data_valid) begin
                mgnt_rx_cnt <=  mgnt_rx_cnt + 1'b1;
                mgnt_rx_buf <=  {mgnt_rx_buf, sys_req_data};
            end
        end
    end

    assign  sys_resp_data   =   mgnt_tx_buf[(MGNT_REG_WIDTH-1)-:8];

    always @(posedge clk_if) begin
        if (!rst_if) begin
            sys_req_ack         <=  'b0;
            sys_resp_data_valid <=  'b0;
        end
        else begin
            if (mgnt_state[1]) begin
                sys_resp_data_valid <=  'b1;
            end
            else if (mgnt_state[2] && mgnt_tx_cnt == {MGNT_REG_WIDTH_L2{1'b1}}) begin
                sys_resp_data_valid <=  'b0;
            end
            if (mgnt_state_next[5]) begin
                sys_req_ack         <=  'b1;
            end
            else if (mgnt_state_next[0]) begin
                sys_req_ack         <=  'b0;
            end
        end
    end

    generate 
        if (SW_CTRL_TYPE == "BE") begin
            always @(posedge clk_if) begin
                // if (!rst_if || (mgnt_state[4] && sys_req_addr == 'h0F)) begin
                if (!rst_if) begin
                    for (i = 0; i < MGNT_REG_FRP_DEPTH; i = i + 1) begin
                        mgnt_reg_frp[i] <=  'b0;
                    end
                end
                else begin
                    if (mgnt_frp_rx_state == 2) begin
                        if (mgnt_buf_frp_rx_data[0]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_UNICAST]          <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_UNICAST] + 1'b1;
                        end
                        if (mgnt_buf_frp_rx_data[1]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_GROUPCAST]        <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_GROUPCAST] + 1'b1;
                        end
                        if (mgnt_buf_frp_rx_data[2]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_BROADCAST]        <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_BROADCAST] + 1'b1;
                        end
                        if (!mgnt_buf_frp_rx_data[3]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_DST_MISS]      <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_DST_MISS] + 1'b1;
                        end
                        if (!mgnt_buf_frp_rx_data[4]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_ERR_MAC_INVD]     <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_ERR_MAC_INVD] + 1'b1;
                        end
                        if (mgnt_buf_frp_rx_data[5]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_SRC_LEARN]     <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_SRC_LEARN] + 1'b1;
                        end
                        if (mgnt_buf_frp_rx_data[6]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_SRC_EVICT]     <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_FT_SRC_EVICT] + 1'b1;
                        end
                        if (mgnt_buf_frp_rx_data[7]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_ADDR_ERR_BP]           <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_ERR_BP] + 1'b1;
                        end
                    end
                end
                if (mgnt_state_next[4] && mgnt_rx_addr == MGNT_SW_FRP_FUNC_FT_FWD_DISABLE) begin
                    mgnt_reg_frp[MGNT_SW_FRP_FUNC_FT_FWD_DISABLE]           <=  mgnt_rx_buf;
                    mgnt_rx_rmt                                             <=  1'b1;
                end
                else if (mgnt_state_next[4] && mgnt_rx_addr == MGNT_SW_FRP_FUNC_FT_LRN_DISABLE) begin
                    mgnt_reg_frp[MGNT_SW_FRP_FUNC_FT_LRN_DISABLE]           <=  mgnt_rx_buf;
                    mgnt_rx_rmt                                             <=  1'b1;
                end
                else if (mgnt_state_next[4] && mgnt_rx_addr == MGNT_SW_FRP_FUNC_FT_AGING_ITVL) begin
                    mgnt_reg_frp[MGNT_SW_FRP_FUNC_FT_AGING_ITVL]            <=  mgnt_rx_buf;
                    mgnt_rx_rmt                                             <=  1'b1;
                end
                else if (mgnt_state_next[4] && mgnt_rx_addr == MGNT_SW_FRP_FUNC_FT_RSVD_MULTICAST) begin
                    mgnt_reg_frp[MGNT_SW_FRP_FUNC_FT_RSVD_MULTICAST]        <=  mgnt_rx_buf;
                    mgnt_rx_rmt                                             <=  1'b1;
                end
                else if (mgnt_state_next[4]) begin
                    mgnt_rx_rmt                                             <=  1'b0;
                end
            end
        end
        else if (SW_CTRL_TYPE == "TTE") begin
            always @(posedge clk_if) begin
                // if (!rst_if || (mgnt_state[4] && sys_req_addr == 'h0F)) begin
                if (!rst_if) begin
                    for (i = 0; i < MGNT_REG_FRP_DEPTH; i = i + 1) begin
                        mgnt_reg_frp[i] <=  'b0;
                    end
                end
                else begin
                    if (mgnt_frp_rx_state == 2) begin
                        if (mgnt_buf_frp_rx_data[0]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_TTE_ADDR_PKT]          <=  mgnt_reg_frp[MGNT_SW_FRP_TTE_ADDR_PKT] + 1'b1;
                        end
                        if (!mgnt_buf_frp_rx_data[3]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_TTE_ADDR_DST_MISS]     <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_GROUPCAST] + 1'b1;
                        end
                        if (!mgnt_buf_frp_rx_data[4]) begin
                            mgnt_reg_frp[MGNT_SW_FRP_TTE_ADDR_ERR_MAC_INVD] <=  mgnt_reg_frp[MGNT_SW_FRP_ADDR_BROADCAST] + 1'b1;
                        end
                    end
                end
                if (mgnt_state_next[4] && mgnt_rx_addr == MGNT_SW_FRP_TTE_FUNC_FT_FWD_DISABLE) begin
                    mgnt_reg_frp[MGNT_SW_FRP_TTE_FUNC_FT_FWD_DISABLE]       <=  mgnt_rx_buf;
                    mgnt_rx_rmt                                             <=  1'b1;
                end
                else if (mgnt_state_next[4]) begin
                    mgnt_rx_rmt                                             <=  1'b0;
                end
            end
        end
    endgenerate


    always @(posedge clk_if) begin
        // if (!rst_if || (mgnt_state[4] && sys_req_addr == 'h1F)) begin
        if (!rst_if) begin
            for (i = 16; i < 21; i = i + 1) begin
                mgnt_reg_swc[i] <=  'b0;
            end
        end
        else if (mgnt_swc_state == 2) begin
            if (mgnt_buf_swc_data[2:0] == 'b0) begin
                mgnt_reg_swc[MGNT_SW_SWC_ADDR_PKT]              <=  mgnt_reg_swc[MGNT_SW_SWC_ADDR_PKT] + 1'b1;
            end
            if (mgnt_buf_swc_data[0]) begin
                mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_NO_ROUTE]     <=  mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_NO_ROUTE] + 1'b1;
            end
            if (mgnt_buf_swc_data[1]) begin
                mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_FQ_EMPTY]     <=  mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_FQ_EMPTY] + 1'b1;
            end
            if (mgnt_buf_swc_data[2]) begin
                mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_QC_FULL]      <=  mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_QC_FULL] + 1'b1;
            end
            if (mgnt_buf_swc_data[3]) begin
                mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_BP]           <=  mgnt_reg_swc[MGNT_SW_SWC_ADDR_ERR_BP] + 1'b1;
            end
        end
    end

endmodule