`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/13 11:20:18
// Design Name: 
// Module Name: hash_multicast
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Provide a configuable designated route for certain lldp-layer multicast packets incl. RSTP
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
//
// Additional Comments:
// Direct attach to sys mgnt bus
// ftm = flow table multicast
//////////////////////////////////////////////////////////////////////////////////

module hash_multicast #(
    parameter   MGNT_REG_WIDTH      =   32,
    localparam  MGNT_REG_WIDTH_L2   =   $clog2(MGNT_REG_WIDTH/8)
) (
    input               clk_if,
    input               rst_if,
    input               clk_sys,
    input               rst_sys,

    // frame_process side interface
    input               ftm_req_valid,
    input       [15:0]  ftm_req_mac,
    // input       [15:0]  ftm_req_portmap,
    output reg          ftm_resp_ack,
    output reg          ftm_resp_nak,
    output reg  [15:0]  ftm_resp_result,

    // sys mgnt side interface
    input               sys_req_valid,
    input               sys_req_wr,
    input       [ 7:0]  sys_req_addr,
    output reg          sys_req_ack,
    // sys mgnt side interface, tx channel
    input       [ 7:0]  sys_req_data,
    input               sys_req_data_valid,
    // sys mgnt side interface, rx channel
    output      [ 7:0]  sys_resp_data,
    output reg          sys_resp_data_valid

);

    localparam  MGNT_FTM_ADDR_BRIDGE    =   8'h00;
    localparam  MGNT_FTM_ADDR_MACCTL    =   8'h01;
    localparam  MGNT_FTM_ADDR_ACCCTL    =   8'h02;
    localparam  MGNT_FTM_ADDR_DEFRT0    =   8'h03;
    localparam  MGNT_FTM_ADDR_DEFRT1    =   8'h04;

    localparam  MAC_ADDR_MC_BRDGEGP =   16'h0000;
    localparam  MAC_ADDR_MC_MACCTRL =   16'h0001;
    localparam  MAC_ADDR_MC_ACCCTRL =   16'h0003;

    reg     [15:0]  mgnt_reg_ftm_sys    [4:0];
    reg     [15:0]  mgnt_reg_ftm_if     [4:0];

    (*MARK_DEBUG = "true"*) reg     [ 2:0]  ftm_state, ftm_state_next;

    // reg     [15:0]  ftm_port_bridge_group;
    // reg     [15:0]  ftm_port_mac_ctrl;
    // reg     [15:0]  ftm_port_access_ctrl;
    // reg     [15:0]  ftm_port_def_0;
    // reg     [15:0]  ftm_port_def_1;

    reg     [ 5:0]  mgnt_state, mgnt_state_next;
    reg             mgnt_rx_wr;
    reg     [ 7:0]  mgnt_rx_addr;
    reg     [MGNT_REG_WIDTH_L2-1:0]     mgnt_rx_cnt, mgnt_tx_cnt;
    reg     [   MGNT_REG_WIDTH-1:0]     mgnt_rx_buf, mgnt_tx_buf;

    always @(*) begin
        case(ftm_state)
            01 : ftm_state_next =   (ftm_req_valid)     ? 02 : 01;
            02 : ftm_state_next =                              04;
            04 : ftm_state_next =   (!ftm_req_valid)    ? 01 : 04;
            default: ftm_state_next = ftm_state;
        endcase
    end

    always @(posedge clk_sys) begin
        if (!rst_sys) begin
            ftm_state   <=  1;
        end
        else begin
            ftm_state   <=  ftm_state_next;
        end
    end

    always @(posedge clk_sys) begin
        if (!rst_sys) begin
            ftm_resp_ack    <=  'b0;
            ftm_resp_nak    <=  'b0;
            ftm_resp_result <=  'b0;
        end
        else begin
            if (ftm_state[0]) begin
                ftm_resp_ack    <=  'b0;
                ftm_resp_nak    <=  'b0;
            end
            if (ftm_state[1]) begin
                casex(ftm_req_mac)
                    MAC_ADDR_MC_BRDGEGP: begin
                        ftm_resp_ack    <=  'b1;
                        ftm_resp_result <=  mgnt_reg_ftm_sys[MGNT_FTM_ADDR_BRIDGE];
                    end
                    MAC_ADDR_MC_MACCTRL: begin
                        ftm_resp_ack    <=  'b1;
                        ftm_resp_result <=  mgnt_reg_ftm_sys[MGNT_FTM_ADDR_MACCTL];
                    end
                    MAC_ADDR_MC_ACCCTRL: begin
                        ftm_resp_ack    <=  'b1;
                        ftm_resp_result <=  mgnt_reg_ftm_sys[MGNT_FTM_ADDR_ACCCTL];
                    end
                    16'h000X: begin
                        ftm_resp_ack    <=  'b1;
                        ftm_resp_result <=  mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT0];
                    end
                    16'h001X: begin
                        ftm_resp_ack    <=  'b1;
                        ftm_resp_result <=  mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT1];
                    end
                    default: begin
                        ftm_resp_nak    <=  'b1;
                        // ftm_resp_result <=  ~ftm_req_portmap;
                    end
                endcase
            end
        end
    end

    always @(posedge clk_sys) begin
        if (!rst_sys) begin
            mgnt_reg_ftm_sys[MGNT_FTM_ADDR_BRIDGE]  <=  16'h8;
            mgnt_reg_ftm_sys[MGNT_FTM_ADDR_MACCTL]  <=  16'h0;
            mgnt_reg_ftm_sys[MGNT_FTM_ADDR_ACCCTL]  <=  16'h8;
            mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT0]  <=  16'h8;
            mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT1]  <=  16'hF;
        end
        else begin
            if (ftm_state_next[1] && (mgnt_state[0] || mgnt_state[1] || mgnt_state[2])) begin
                mgnt_reg_ftm_sys[MGNT_FTM_ADDR_BRIDGE]  <=  mgnt_reg_ftm_if[MGNT_FTM_ADDR_BRIDGE];
                mgnt_reg_ftm_sys[MGNT_FTM_ADDR_MACCTL]  <=  mgnt_reg_ftm_if[MGNT_FTM_ADDR_MACCTL];
                mgnt_reg_ftm_sys[MGNT_FTM_ADDR_ACCCTL]  <=  mgnt_reg_ftm_if[MGNT_FTM_ADDR_ACCCTL];
                mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT0]  <=  mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT0];
                mgnt_reg_ftm_sys[MGNT_FTM_ADDR_DEFRT1]  <=  mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT1];
            end
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
            16: mgnt_state_next =                                                 32;
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
                mgnt_tx_buf <=  mgnt_reg_ftm_if[sys_req_addr];  
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

    always @(posedge clk_if) begin
        if (!rst_if) begin
            mgnt_reg_ftm_if[MGNT_FTM_ADDR_BRIDGE]   <=  16'h8;
            mgnt_reg_ftm_if[MGNT_FTM_ADDR_MACCTL]   <=  16'h0;
            mgnt_reg_ftm_if[MGNT_FTM_ADDR_ACCCTL]   <=  16'h8;
            mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT0]   <=  16'h8;
            mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT1]   <=  16'hF;
        end
        else begin
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FTM_ADDR_BRIDGE) begin
                mgnt_reg_ftm_if[MGNT_FTM_ADDR_BRIDGE]   <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_rx_addr == MGNT_FTM_ADDR_MACCTL) begin
                mgnt_reg_ftm_if[MGNT_FTM_ADDR_MACCTL]   <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_rx_addr == MGNT_FTM_ADDR_ACCCTL) begin
                mgnt_reg_ftm_if[MGNT_FTM_ADDR_ACCCTL]   <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_rx_addr == MGNT_FTM_ADDR_DEFRT0) begin
                mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT0]   <=  mgnt_rx_buf;
            end
            else if (mgnt_state[4] && mgnt_rx_addr == MGNT_FTM_ADDR_DEFRT1) begin
                mgnt_reg_ftm_if[MGNT_FTM_ADDR_DEFRT1]   <=  mgnt_rx_buf;
            end
        end
    end

endmodule