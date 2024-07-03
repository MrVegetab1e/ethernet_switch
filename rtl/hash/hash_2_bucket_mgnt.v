`timescale 1ns / 1ps
//====================================================================
//entry structure:
//[15:0]:portmap
//[63:16]:mac
//[73:64]:age counter
//[79]:item valid
//=====================================================================
module hash_2_bucket_mgnt #(
    parameter   MGNT_REG_WIDTH      =   32,
    localparam  MGNT_REG_WIDTH_L2   =   $clog2(MGNT_REG_WIDTH/8)
) (
    input               clk,
    input               rstn,
    //port se signals.
    input               se_source,
    input       [47:0]  se_mac,
    input       [15:0]  se_portmap,
    input       [9:0]   se_hash,        
    input               se_req,
    output  reg         se_ack,
    output  reg         se_nak,
    output  reg [15:0]  se_result,

    input           clk_if,
    input           rst_if,
    // sys mgnt side interface, cmd channel
    input               sys_req_valid,
    input               sys_req_wr,
    input       [ 7:0]  sys_req_addr,
    output  reg         sys_req_ack,
    // sys mgnt side interface, tx channel
    input       [ 7:0]  sys_req_data,
    input               sys_req_data_valid,
    // sys mgnt side interface, rx channel
    output      [ 7:0]  sys_resp_data,
    output  reg         sys_resp_data_valid
);
parameter   LIVE_TH=10'd150;
// parameter LIVE_TH=7'd100;

integer i;

//======================================
//              main state.
//======================================
reg     [3:0]   state;
// reg     [2:0]   hit0;
// reg     [2:0]   hit1;
reg             hit0, hit1;
reg             hit0_0, hit0_1;
reg             hit1_0, hit1_1;
//======================================
//              one cycle for state1.
//======================================
reg             count;

wire            item_valid0;
wire            item_valid1;
wire    [9:0]   live_time0;
wire    [9:0]   live_time1;
wire            not_outlive_0;
wire            not_outlive_1;

reg             ram_en_tag_0;
reg             ram_en_data_0;
reg             ram_wr_tag_0;
reg             ram_wr_data_0;
(*EXTRACT_ENABLE = "no"*) reg     [ 9:0]  ram_addr_0;
(*EXTRACT_ENABLE = "no"*) reg     [15:0]  ram_din_tag_0;
(*EXTRACT_ENABLE = "no"*) reg     [63:0]  ram_din_data_0;
wire    [15:0]  ram_dout_tag_0;
// reg     [15:0]  ram_dout_tag_0_reg;
wire    [63:0]  ram_dout_data_0;
// reg     [63:0]  ram_dout_data_0_reg;
reg             ram_en_tag_1;
reg             ram_en_data_1;
reg             ram_wr_tag_1;
reg             ram_wr_data_1;
(*EXTRACT_ENABLE = "no"*) reg     [ 9:0]  ram_addr_1;
(*EXTRACT_ENABLE = "no"*) reg     [15:0]  ram_din_tag_1;
(*EXTRACT_ENABLE = "no"*) reg     [63:0]  ram_din_data_1;
wire    [15:0]  ram_dout_tag_1;
// reg     [15:0]  ram_dout_tag_1_reg;
wire    [63:0]  ram_dout_data_1;
// reg     [63:0]  ram_dout_data_1_reg;

reg     [ 9:0]  ram_mgnt_addr_0;
reg             ram_mgnt_wr_0;
reg             ram_mgnt_en_0;
reg     [15:0]  ram_mgnt_din_tag_0;
reg     [63:0]  ram_mgnt_din_data_0;
wire    [15:0]  ram_mgnt_dout_tag_0;
wire    [63:0]  ram_mgnt_dout_data_0;
reg     [ 9:0]  ram_mgnt_addr_1;
reg             ram_mgnt_wr_1;
reg             ram_mgnt_en_1;
reg     [15:0]  ram_mgnt_din_tag_1;
reg     [63:0]  ram_mgnt_din_data_1;
wire    [15:0]  ram_mgnt_dout_tag_1;
wire    [63:0]  ram_mgnt_dout_data_1;

reg     [9:0]   aging_addr;
// reg     [47:0]  hit_mac;
reg     [47:0]  hit_mac_0;
reg     [47:0]  hit_mac_1;
always @(posedge clk or negedge rstn)
    if(!rstn)begin
        state<=#2 0;
        ram_en_tag_0<=#2 0;
        ram_en_data_0<=#2 0;
        ram_wr_tag_0<=#2 0;
        ram_wr_data_0<=#2 0;
        // ram_addr_0<=#2 0;
        // ram_din_0<=#2 0;
        ram_en_tag_1<=#2 0;
        ram_en_data_1<=#2 0;
        ram_wr_tag_1<=#2 0;
        ram_wr_data_1<=#2 0;
        // ram_addr_1<=#2 0; 
        // ram_din_1<=#2 0;    
        se_ack<=#2 0;
        se_nak<=#2 0;
        se_result<=#2 0;
        // hit_mac<=#2 0;
        // hit_mac_0<=#2 0;
        // hit_mac_1<=#2 0;
        count<=#2 0;
        hit0<=#2 0;
        hit1<=#2 0;
        end
    else begin
        // ram_dout_0_reg<=#2 ram_dout_0;  
        // ram_dout_1_reg<=#2 ram_dout_1;  
        // ram_en_tag_0<=#2 0;
        // ram_en_data_0<=#2 0;
        ram_wr_tag_0<=#2 0;
        ram_wr_data_0<=#2 0;
        // ram_en_tag_1<=#2 0;
        // ram_en_data_1<=#2 0;
        ram_wr_tag_1<=#2 0;
        ram_wr_data_1<=#2 0;
        se_ack<=#2 0;
        se_nak<=#2 0;
        case(state)
        0:begin
            if(se_req) begin
                ram_addr_0<=#2 se_hash;
                ram_addr_1<=#2 se_hash;
                // hit_mac   <=#2 se_mac;
                hit_mac_0 <=#2 se_mac;
                hit_mac_1 <=#2 se_mac;
                ram_en_tag_0<=#2 1;
                ram_en_data_0<=#2 1;
                ram_en_tag_1<=#2 1;
                ram_en_data_1<=#2 1;
                count     <=#2 0;
                state   <=#2 1;
                end
            else begin
                ram_en_tag_0<=#2 0;
                ram_en_data_0<=#2 0;
                ram_en_tag_1<=#2 0;
                ram_en_data_1<=#2 0;    
                end
            end
        //===============================================
        //check if there is an entry can match current 
        //source mac address. 
        //(1)if macthed, refresh live time.
        //(2)if not macthed, add new entry.
        //===============================================
        1:begin
            count <=#2 1;
            if (count) begin
                state<=#2 2;
                ram_en_tag_0<=#2 0;
                ram_en_data_0<=#2 0;
                ram_en_tag_1<=#2 0;
                ram_en_data_1<=#2 0;
                end
            end
        2:begin
            if(se_source) state<=#2 3;
            else state<=#2 6;
            // hit0<=#2 {ram_dout_tag_0[15], hit0_0, hit0_1};
            // hit1<=#2 {ram_dout_tag_1[15], hit1_0, hit1_1};
            hit0<=#2 (ram_dout_tag_0[15] && hit0_0 && hit0_1);
            hit1<=#2 (ram_dout_tag_1[15] && hit1_0 && hit1_1);
            end
        3:begin
            //=====================================================
            //if no entry is matched(still valid), should add new 
            //entry.
            //=====================================================
            if({hit1,hit0}==2'b00) state<=#2 4;
            // if({&(hit1), &(hit0)}==2'b0) state<=#2 4;
            //=====================================================
            //if an entry is existed and old entry should be refreshed.
            //=====================================================
            else state<=#2 5;
            end
        4:begin
            state<=#2 7;
            case({item_valid1,item_valid0})
            2'b11: se_nak<=#2 1;
            2'b00,2'b10: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_0<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_tag_0<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_din_data_0<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_en_tag_0<=#2 1;
                ram_en_data_0<=#2 1;
                ram_wr_tag_0<=#2 1;
                ram_wr_data_0<=#2 1;
                end
            2'b01:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_1<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_tag_1<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_din_data_1<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_en_tag_1<=#2 1;
                ram_en_data_1<=#2 1;
                ram_wr_tag_1<=#2 1;
                ram_wr_data_1<=#2 1;
                end
            endcase
            end
        5:begin
            state<=#2 7;
            case({hit1,hit0})
            // case({&(hit1), &(hit0)})
            2'b01: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_0<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_data_0<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_en_data_0<=#2 1;
                ram_wr_data_0<=#2 1;
                ram_din_tag_0<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_en_tag_0<=#2 1;
                ram_wr_tag_0<=#2 1;
                end
            2'b10:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_1<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_data_1<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_en_data_1<=#2 1;
                ram_wr_data_1<=#2 1;
                ram_din_tag_1<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_en_tag_1<=#2 1;
                ram_wr_tag_1<=#2 1;
                end
            endcase
            end
        6:begin
            state<=#2 7;
            case({hit1,hit0})
            // case({&(hit1), &(hit0)})
            2'b00: begin
                se_ack<=#2 0;
                se_nak<=#2 1;
                se_result<=#2 ~se_portmap;
                end
            2'b01: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_0[63:48];
                end
            2'b10:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_1[63:48];             
                end
        //=============================
        //code for 2'b11
        //=============================
            2'b11:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_0[63:48];            
                end
            endcase
            end
        7:begin
            state<=#2 0;
            hit0<=#2 0;
            hit1<=#2 0;
            end
        endcase
        end

always @(*)begin
    // hit0=(hit_mac==ram_dout_0_reg[63:16])& ram_dout_0_reg[79];          
    // hit1=(hit_mac==ram_dout_1_reg[63:16])& ram_dout_1_reg[79];          
    hit0_0=(hit_mac_0[0+:24]==ram_dout_data_0[0+:24]);
    hit0_1=(hit_mac_0[24+:24]==ram_dout_data_0[24+:24]);
    hit1_0=(hit_mac_1[0+:24]==ram_dout_data_1[0+:24]);
    hit1_1=(hit_mac_1[24+:24]==ram_dout_data_1[24+:24]);
    end
assign item_valid0=ram_dout_tag_0[15];
assign item_valid1=ram_dout_tag_1[15];
assign live_time0=ram_dout_tag_0[ 9:0];
assign live_time1=ram_dout_tag_1[ 9:0];
assign not_outlive_0=(live_time0!=0)?1:0;
assign not_outlive_1=(live_time1!=0)?1:0;

// flow table cfg reg
//     [ 0]   : aging enable
//     [ 1]   : link down port flushing enable (unimplemented)
// flow table cmd reg
//     [15]   : flush 
//     [14]   : write
//     [13]   : read
//   parameter for read
//     * WRITE TO WRITE ENTRY BUFFER BEFORE USE * 
//     [ 9: 0]: index
//     [10]   : way sel
//   parameter for write
//     [ 9: 0]: index
//     [10]   : way sel
//   parameter for flush
//     [12:11]: flush mode
//       -- 00: flush all
//       -- 01: flush selected way
//       -- 1*: flush selected port
//     [10: 0]: flush sel
//       -- flush way mode:
//       -- [10]: way sel
//       -- flush port mode:
//       -- [7:0]: port sel(one-hot)


    localparam  MGNT_REG_FP_BE_DEPTH        =   3;

    localparam  MGNT_FT_BE_ADDR_CFG         =   'h00;
    localparam  MGNT_FT_BE_ADDR_CMD         =   'h01;
    localparam  MGNT_FT_BE_ADDR_STS         =   'h02;
    localparam  MGNT_FT_BE_FUNC_CMD         =   'h0F;
    localparam  MGNT_FT_BE_ADDR_ENT_0_WR    =   'h10;
    localparam  MGNT_FT_BE_ADDR_ENT_1_WR    =   'h11;
    localparam  MGNT_FT_BE_ADDR_ENT_2_WR    =   'h12;
    localparam  MGNT_FT_BE_ADDR_ENT_3_WR    =   'h13;
    localparam  MGNT_FT_BE_ADDR_ENT_4_WR    =   'h14;
    localparam  MGNT_FT_BE_ADDR_ENT_0_RD    =   'h20;
    localparam  MGNT_FT_BE_ADDR_ENT_1_RD    =   'h21;
    localparam  MGNT_FT_BE_ADDR_ENT_2_RD    =   'h22;
    localparam  MGNT_FT_BE_ADDR_ENT_3_RD    =   'h23;
    localparam  MGNT_FT_BE_ADDR_ENT_4_RD    =   'h24;

    reg     [MGNT_REG_WIDTH-1:0]    mgnt_reg_fp_be [MGNT_REG_FP_BE_DEPTH-1:0];
    reg     [79:0]  mgnt_reg_ft_be_entry_wr;
    reg     [79:0]  mgnt_reg_ft_be_entry_rd;

    reg     [ 5:0]  mgnt_state, mgnt_state_next;
    reg             mgnt_rx_wr;
    reg     [ 7:0]  mgnt_rx_addr;
    reg     [MGNT_REG_WIDTH_L2-1:0]     mgnt_rx_cnt, mgnt_tx_cnt;
    reg     [   MGNT_REG_WIDTH-1:0]     mgnt_rx_buf, mgnt_tx_buf;

    reg     [15:0]  conf_state, conf_state_next;
    reg     [15:0]  conf_cmd_buf;
    reg             conf_cmd_req;
    reg     [ 9:0]  conf_scan_cnt_wr;
    reg     [ 9:0]  conf_scan_cnt_rd;
    wire            conf_scan_flush_hit_0;
    wire            conf_scan_flush_hit_1;
    wire            conf_scan_aging_hit_0;
    wire            conf_scan_aging_hit_1;
    reg     [15:0]  conf_aging_cnt_l;
    reg     [11:0]  conf_aging_cnt_h;
    reg             conf_aging_req;

    assign  conf_scan_flush_hit_0 = ram_mgnt_dout_tag_0[15] && !ram_mgnt_dout_tag_0[14] && (|(ram_mgnt_dout_data_0[55:48] & mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CMD][7:0]));
    assign  conf_scan_flush_hit_1 = ram_mgnt_dout_tag_1[15] && !ram_mgnt_dout_tag_1[14] && (|(ram_mgnt_dout_data_1[55:48] & mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CMD][7:0]));

    assign  conf_scan_aging_hit_0 = ram_mgnt_dout_tag_0[15] && !ram_mgnt_dout_tag_0[14] && (ram_mgnt_dout_tag_0[9:0] == 'b0);
    assign  conf_scan_aging_hit_1 = ram_mgnt_dout_tag_1[15] && !ram_mgnt_dout_tag_1[14] && (ram_mgnt_dout_tag_1[9:0] == 'b0);

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
            // write to reg stack
            16: mgnt_state_next =                                                      32;
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
                mgnt_tx_buf <=  (sys_req_addr[5]) ? mgnt_reg_ft_be_entry_rd[16*sys_req_addr[3:0]+:16] :
                                (sys_req_addr[4]) ? mgnt_reg_ft_be_entry_wr[16*sys_req_addr[3:0]+:16] :
                                mgnt_reg_fp_be[sys_req_addr[1:0]];  
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
            for (i = 0; i < 2; i = i + 1) begin
                mgnt_reg_fp_be[i]   <=  'b0;
            end
        end
        else begin
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_CFG) begin
                mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CFG]     <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_CMD) begin
                mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CMD]     <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_ENT_0_WR) begin
                mgnt_reg_ft_be_entry_wr[15:0]           <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_ENT_1_WR) begin
                mgnt_reg_ft_be_entry_wr[31:16]          <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_ENT_2_WR) begin
                mgnt_reg_ft_be_entry_wr[47:32]          <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_ENT_3_WR) begin
                mgnt_reg_ft_be_entry_wr[63:48]          <=  mgnt_rx_buf;
            end
            if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_ADDR_ENT_4_WR) begin
                mgnt_reg_ft_be_entry_wr[79:64]          <=  mgnt_rx_buf;
            end
        end
    end

    always @(*) begin
        case(conf_state)
            'h0001: conf_state_next <=  (conf_cmd_buf[15]) ? 'h0002 : // flush destinated entry
                                        (conf_cmd_buf[14]) ? 'h0004 : // write destinated entry
                                        (conf_cmd_buf[13]) ? 'h0008 : // read destinated entry
                                        'h2000;
            'h0002: conf_state_next <=  (conf_cmd_buf[12]) ? 'h0200 : 'h0100;
            'h0004: conf_state_next <=  'h2000;
            'h0008: conf_state_next <=  'h0020;
            'h0010: conf_state_next <=  'h0200;
            'h0020: conf_state_next <=  'h0040; // read cycle 1
            'h0040: conf_state_next <=  'h0080; // read cycle 2
            'h0080: conf_state_next <=  'h2000; // read cycle 3
            'h0100: conf_state_next <=  (ram_mgnt_addr_0 == 10'h3FF) ? 'h2000 : 'h0100;
            'h0200: conf_state_next <=  'h0400;
            'h0400: conf_state_next <=  'h0800;
            'h0800: conf_state_next <=  'h1000;
            'h1000: conf_state_next <=  (conf_scan_cnt_wr == 10'h3FF) ? 'h2000 : 'h0800;
            'h2000: conf_state_next <=  conf_cmd_req    ? 'h0001 :
                                        conf_aging_req  ? 'h0010 :
                                        'h2000;
            default: conf_state_next <= 'h2000;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            conf_state  <=  'h2000;
        end
        else begin
            conf_state  <=  conf_state_next;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            conf_aging_cnt_l    <=  'b0;
            conf_aging_cnt_h    <=  'b0;
        end
        else begin
            if (mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CFG][0]) begin
                if (conf_aging_cnt_l < 16'hC34F) begin
                    conf_aging_cnt_l    <=  conf_aging_cnt_l + 1'b1;
                end
                else begin
                    conf_aging_cnt_l    <=  'b0;
                    if (conf_aging_cnt_h < 12'h9C3) begin
                        conf_aging_cnt_h    <=  conf_aging_cnt_h + 1'b1;
                    end
                    else begin
                        conf_aging_cnt_h    <=  'b0;
                    end
                end
            end
            else begin
                conf_aging_cnt_l    <=  'b0;
                conf_aging_cnt_h    <=  'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            conf_aging_req  <=  'b0;
            conf_cmd_req    <=  'b0;
        end
        else begin
            if (conf_state[4]) begin
                conf_aging_req  <=  'b0;
            end
            else if (conf_aging_cnt_h == 12'h9C3 && conf_aging_cnt_l == 16'hC34F) begin
                conf_aging_req  <=  'b1;
            end
            if (conf_state[0]) begin
                conf_cmd_req    <=  'b0;
            end
            else if (mgnt_state[4] && mgnt_rx_addr == MGNT_FT_BE_FUNC_CMD) begin
                conf_cmd_req    <=  'b1;
                conf_cmd_buf    <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_CMD];
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            ram_mgnt_addr_0 <=  'b0;
            ram_mgnt_wr_0   <=  'b0;
            ram_mgnt_en_0   <=  'b0;
            ram_mgnt_addr_1 <=  'b0;
            ram_mgnt_wr_1   <=  'b0;
            ram_mgnt_en_1   <=  'b0;
        end
        else begin
            if (conf_state[0] || conf_state[13]) begin
                ram_mgnt_wr_0   <=  'b0;
                ram_mgnt_en_0   <=  'b0;
                ram_mgnt_wr_1   <=  'b0;
                ram_mgnt_en_1   <=  'b0;
            end
            if (conf_state[1]) begin
                conf_scan_cnt_rd    <=  'b0;
                conf_scan_cnt_wr    <=  'b0;
                if (!conf_cmd_buf[12]) begin
                    ram_mgnt_wr_0       <=  conf_cmd_buf[11] ? 
                                            ~conf_cmd_buf[10] : 1'b1;
                    ram_mgnt_en_0       <=  conf_cmd_buf[11] ? 
                                            ~conf_cmd_buf[10] : 1'b1;
                    ram_mgnt_addr_0     <=  'b0;
                    ram_mgnt_din_tag_0  <=  'b0;
                    ram_mgnt_wr_1       <=  conf_cmd_buf[11] ? 
                                            conf_cmd_buf[10] : 1'b1;
                    ram_mgnt_en_1       <=  conf_cmd_buf[11] ? 
                                            conf_cmd_buf[10] : 1'b1;
                    ram_mgnt_addr_1     <=  'b0;
                    ram_mgnt_din_tag_1  <=  'b0;  
                end
                else begin
                    ram_mgnt_en_0       <=  'b1;
                    ram_mgnt_addr_0     <=  'b0;
                    ram_mgnt_din_tag_0  <=  'b0;
                    ram_mgnt_din_data_0 <=  'b0;
                    ram_mgnt_en_1       <=  'b1;
                    ram_mgnt_addr_1     <=  'b0;
                    ram_mgnt_din_tag_0  <=  'b0;
                    ram_mgnt_din_data_0 <=  'b0;
                end
            end
            if (conf_state[2]) begin
                ram_mgnt_wr_0       <=  ~conf_cmd_buf[10];
                ram_mgnt_en_0       <=  ~conf_cmd_buf[10];
                ram_mgnt_addr_0     <=  conf_cmd_buf[9:0];
                ram_mgnt_din_tag_0  <=  mgnt_reg_ft_be_entry_wr[79:64];
                ram_mgnt_din_data_0 <=  mgnt_reg_ft_be_entry_wr[63: 0];
                ram_mgnt_wr_1       <=  conf_cmd_buf[10];
                ram_mgnt_en_1       <=  conf_cmd_buf[10];
                ram_mgnt_addr_1     <=  conf_cmd_buf[9:0];
                ram_mgnt_din_tag_1  <=  mgnt_reg_ft_be_entry_wr[79:64];
                ram_mgnt_din_data_1 <=  mgnt_reg_ft_be_entry_wr[63: 0];     
            end
            if (conf_state[3]) begin
                ram_mgnt_en_0       <=  ~conf_cmd_buf[10];
                ram_mgnt_addr_0     <=  conf_cmd_buf[9:0];
                ram_mgnt_en_1       <=  conf_cmd_buf[10];
                ram_mgnt_addr_1     <=  conf_cmd_buf[9:0];   
            end
            if (conf_state[4]) begin
                conf_scan_cnt_rd    <=  'b0;
                conf_scan_cnt_wr    <=  'b0;
                ram_mgnt_addr_0     <=  'b0;
                ram_mgnt_en_0       <=  'b1;
                ram_mgnt_addr_1     <=  'b0;
                ram_mgnt_en_1       <=  'b1;
            end
            if (conf_state[6]) begin
                ram_mgnt_en_0       <=  'b0;
                ram_mgnt_en_1       <=  'b0;
            end
            if (conf_state[7]) begin
                mgnt_reg_ft_be_entry_rd <=  conf_cmd_buf[10] ? 
                                            {ram_mgnt_dout_tag_1, ram_mgnt_dout_data_1} :
                                            {ram_mgnt_dout_tag_0, ram_mgnt_dout_data_0};
            end
            if (conf_state[8]) begin
                ram_mgnt_addr_0     <=  ram_mgnt_addr_0 + 1'b1;
                ram_mgnt_addr_1     <=  ram_mgnt_addr_1 + 1'b1;
            end
            if (conf_state[9]) begin
                conf_scan_cnt_rd    <=  conf_scan_cnt_rd + 1'b1;
            end
            if (conf_state[10]) begin
                ram_mgnt_addr_0     <=  conf_scan_cnt_rd;
                ram_mgnt_addr_1     <=  conf_scan_cnt_rd;
            end
            if (conf_state[11]) begin
                conf_scan_cnt_rd    <=  conf_scan_cnt_rd + 1'b1;
                // ram_mgnt_en_0       <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] ? ram_mgnt_dout_tag_0[15] && !ram_mgnt_dout_tag_0[14]:
                //                         conf_scan_flush_hit_0;
                ram_mgnt_wr_0       <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] ? ram_mgnt_dout_tag_0[15] && !ram_mgnt_dout_tag_0[14]:
                                        conf_scan_flush_hit_0;
                ram_mgnt_addr_0     <=  conf_scan_cnt_wr;
                ram_mgnt_din_tag_0  <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] && !conf_scan_aging_hit_0 ? {ram_mgnt_dout_tag_0[15:10], ram_mgnt_dout_tag_0[9:0] - 1'b1} :
                                        16'b0;
                ram_mgnt_din_data_0 <=  ram_mgnt_dout_data_0;
                // ram_mgnt_en_1       <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] ? ram_mgnt_dout_tag_1[15] && !ram_mgnt_dout_tag_1[14]: 
                //                         conf_scan_flush_hit_1;
                ram_mgnt_wr_1       <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] ? ram_mgnt_dout_tag_1[15] && !ram_mgnt_dout_tag_1[14]: 
                                        conf_scan_flush_hit_1;
                ram_mgnt_addr_1     <=  conf_scan_cnt_wr;
                ram_mgnt_din_tag_1  <=  mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1] && !conf_scan_aging_hit_1 ? {ram_mgnt_dout_tag_1[15:10], ram_mgnt_dout_tag_1[9:0] - 1'b1} :
                                        16'b0;
                ram_mgnt_din_data_1 <=  ram_mgnt_dout_data_1;
            end
            if (conf_state[12]) begin
                conf_scan_cnt_wr    <=  conf_scan_cnt_wr + 1'b1;
                // ram_mgnt_en_0       <=  'b1;
                ram_mgnt_wr_0       <=  'b0;
                ram_mgnt_addr_0     <=  conf_scan_cnt_rd;
                // ram_mgnt_en_1       <=  'b1;
                ram_mgnt_wr_1       <=  'b0;
                ram_mgnt_addr_1     <=  conf_scan_cnt_rd;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mgnt_reg_fp_be[2]   <=  'b0;
        end
        else begin
            mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][0]    <=  !conf_state[13];
            if (conf_state[13]) begin
                mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1]    <=  1'b0;
            end
            else if (conf_state[4])begin
                mgnt_reg_fp_be[MGNT_FT_BE_ADDR_STS][1]    <=  1'b1;
            end
        end
    end

dpsram_reg_w16_d1k u_sram_tag_0 (
  .clka(clk),
  .ena(ram_en_tag_0),
  .wea(ram_wr_tag_0),
  .addra(ram_addr_0),
  .dina(ram_din_tag_0),
  .douta(ram_dout_tag_0),
  .clkb(clk),
  .enb(ram_mgnt_en_0),
  .web(ram_mgnt_wr_0),
  .addrb(ram_mgnt_addr_0),
  .dinb(ram_mgnt_din_tag_0),
  .doutb(ram_mgnt_dout_tag_0)
);
dpsram_reg_w64_d1k u_sram_data_0 (
  .clka(clk),
  .ena(ram_en_data_0),
  .wea(ram_wr_data_0),
  .addra(ram_addr_0),
  .dina(ram_din_data_0),
  .douta(ram_dout_data_0),
  .clkb(clk),
  .enb(ram_mgnt_en_0),
  .web(ram_mgnt_wr_0),
  .addrb(ram_mgnt_addr_0),
  .dinb(ram_mgnt_din_data_0),
  .doutb(ram_mgnt_dout_data_0)
);
dpsram_reg_w16_d1k u_sram_tag_1 (
  .clka(clk),
  .ena(ram_en_tag_1),
  .wea(ram_wr_tag_1),
  .addra(ram_addr_1),
  .dina(ram_din_tag_1),
  .douta(ram_dout_tag_1),
  .clkb(clk),
  .enb(ram_mgnt_en_1),
  .web(ram_mgnt_wr_1),
  .addrb(ram_mgnt_addr_1),
  .dinb(ram_mgnt_din_tag_1),
  .doutb(ram_mgnt_dout_tag_1)
);
dpsram_reg_w64_d1k u_sram_data_1 (
  .clka(clk),
  .ena(ram_en_data_1),
  .wea(ram_wr_data_1),
  .addra(ram_addr_1),
  .dina(ram_din_data_1),
  .douta(ram_dout_data_1),
  .clkb(clk),
  .enb(ram_mgnt_en_1),
  .web(ram_mgnt_wr_1),
  .addrb(ram_mgnt_addr_1),
  .dinb(ram_mgnt_din_data_1),
  .doutb(ram_mgnt_dout_data_1)
);
// sram_w80_d1k u_sram_0 (
//   .clka(clk),           // input clka
//   .wea(ram_wr_0),       // input [0 : 0] wea
//   .addra(ram_addr_0),   // input [9 : 0] addra
//   .dina(ram_din_0),     // input [79 : 0] dina
//   .douta(ram_dout_0)    // output [79 : 0] douta
// );
// sram_w80_d1k u_sram_1 (
//   .clka(clk),           // input clka
//   .wea(ram_wr_1),       // input [0 : 0] wea
//   .addra(ram_addr_1),   // input [9 : 0] addra
//   .dina(ram_din_1),     // input [79 : 0] dina
//   .douta(ram_dout_1)    // output [79 : 0] douta
// );

endmodule
