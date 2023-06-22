`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/13 11:20:18
// Design Name: 
// Module Name: register_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Reworked register controller
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 1.00 - Basic function(mac rx link) implemented
// Revision 2.00 - Full capabilities incl. tx link
// Additional Comments:
// Distributed design for mac state registers
//                                                                                
//////////////////////////////////////////////////////////////////////////////////


module register_v2 #(
    parameter   MGNT_REG_WIDTH      =   32,
    localparam  MGNT_REG_WIDTH_L2   =   $clog2(MGNT_REG_WIDTH/8)
) (
    input                   clk,
    input                   rst,
    // spi side interface
    input                   spi_wr,
    input       [ 6:0]      spi_op,
    input       [15:0]      spi_din,
    output                  spi_ack,
    output reg  [15:0]      spi_dout,
    // sys mgnt side interface, cmd channel
    output reg  [ 7:0]      sys_req_valid,
    output reg              sys_req_wr,
    output      [ 7:0]      sys_req_addr,
    input                   sys_req_ack,
    // sys mgnt side interface, tx channel
    output      [ 7:0]      sys_req_data,
    output reg              sys_req_data_valid,
    // sys mgnt side interface, rx channel
    input       [ 7:0]      sys_resp_data,
    input                   sys_resp_data_valid,
    // flow table side interface
    output reg              ft_clear,
    output reg              ft_update,
    input                   ft_ack,
    output      [119:0]     flow,
    output      [11:0]      hash
);

    localparam  PORT0_ADDR      =   7'h00;
    localparam  PORT1_ADDR      =   7'h01;
    localparam  PORT2_ADDR      =   7'h02;
    localparam  PORT3_ADDR      =   7'h03;
    localparam  BE_SW_ADDR      =   7'h40;
    localparam  BE_SW_FTM_ADDR  =   7'h41;
    localparam  TTE_SW_ADDR     =   7'h50;
    localparam  SPI_LOCAL_ADDR  =   7'h7F;

    // Write this register will immediately start a direct read or indirect write between reg hub and remote device;
    // Read have no effect and will be ignored
    localparam  DEV_PTR_ADDR    =   7'h00;
    // Write this register to assert the value of indirect write;
    localparam  DEV_DATA_ADDR   =   7'h01;
    // Write this register to start a indirect write to flow table;
    localparam  TABLE_CTRL_ADDR =   7'h02;
    localparam  TABLE_HASH_ADDR =   7'h03;
    localparam  TABLE_ST0_ADDR  =   7'h30;
    localparam  TABLE_ST1_ADDR  =   7'h31;
    localparam  TABLE_ST2_ADDR  =   7'h32;
    localparam  TABLE_ST3_ADDR  =   7'h33;
    localparam  TABLE_ST4_ADDR  =   7'h34;
    localparam  TABLE_ST5_ADDR  =   7'h35;
    localparam  TABLE_ST6_ADDR  =   7'h36;
    localparam  TABLE_ST7_ADDR  =   7'h37;

    // Feature Flag:
    // bit 15-6: reserved for future
    // bit 5: vlan functionality
    // bit 4: rstp functionality (static route for certain ctrl frames, tail tagging)
    // bit 3: lldp functionality (online modification for lldp packet)
    // bit 2: ptp functionality (2-step only, using a fifo to track backward latency)
    // bit 1: tte functionality (support for dedicated route and flow table)
    // bit 0: MDIO remote ctrl (read status from phy and reconfigure)

    localparam  SW_ID_ADDR      =   8'h80;
    localparam  SW_FTR_ADDR     =   8'h81;
    localparam  SW_REV_ADDR_0   =   8'h82;
    localparam  SW_REV_ADDR_1   =   8'h83;
    parameter   SW_ID_VAL       =   16'h1234;
    parameter   SW_FTR_VAL      =   16'h001E;
    
    // spi reg operation
    reg     [ 7:0]  reg_state, reg_state_next;
    reg     [15:0]  reg_dev_ptr;
    reg     [15:0]  reg_dev_data;
    reg     [MGNT_REG_WIDTH_L2-1:0]     reg_cnt_rx;
    reg     [MGNT_REG_WIDTH_L2-1:0]     reg_cnt_tx;
    reg     [MGNT_REG_WIDTH-1:0]        reg_data_rx;
    reg     [MGNT_REG_WIDTH-1:0]        reg_data_tx;

    reg     [ 3:0]      ft_state, ft_state_next;
    reg     [ 1:0]      ft_bsy;
    reg     [127:0]     table_reg;
    reg     [11:0]      table_hash;

    wire    [31:0]      usr_data;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_dev_ptr <=  'b0;
        end
        else begin
            if (spi_wr) begin
                reg_dev_ptr <=  spi_din;
            end
        end
    end

    always @(*) begin
        case(reg_state)
            01: begin
                if (spi_wr && spi_op == DEV_PTR_ADDR) begin
                    reg_state_next  =   2;
                end
                else if (spi_wr && spi_op == DEV_DATA_ADDR) begin
                    reg_state_next  =   64;
                end
                else begin
                    reg_state_next  =   1; 
                end 
            end
            02: begin
                case(reg_dev_ptr[14:8])
                    PORT0_ADDR      : reg_state_next = 4;
                    PORT1_ADDR      : reg_state_next = 4;
                    PORT2_ADDR      : reg_state_next = 4;
                    PORT3_ADDR      : reg_state_next = 4;
                    BE_SW_ADDR      : reg_state_next = 4;
                    BE_SW_FTM_ADDR  : reg_state_next = 4;
                    TTE_SW_ADDR     : reg_state_next = 4;
                    SPI_LOCAL_ADDR  : reg_state_next = 32;
                    default: reg_state_next = 1;
                endcase
            end
            04: reg_state_next = 8;
            08: begin   // remote addr, create remote request
                if (sys_req_wr) begin
                    if (reg_cnt_tx == {MGNT_REG_WIDTH_L2{1'b1}}) begin
                        reg_state_next  =   16;
                    end
                    else begin
                        reg_state_next  =   8;
                    end
                end
                else begin
                    if (reg_cnt_rx == {MGNT_REG_WIDTH_L2{1'b1}}) begin
                        reg_state_next  =   16;
                    end
                    else begin
                        reg_state_next  =   8;
                    end
                end
            end
            16: begin   // wait for ack sgnl
                reg_state_next  =   sys_req_ack ? 128 : 16;
            end
            32: begin   // local addr
                reg_state_next  =   128;
            end
            64: begin   // update write buffer
                reg_state_next  =   128;
            end
            128: begin   // update retn val
                reg_state_next  =   1;
            end
            default: reg_state_next =   reg_state;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_state   <=  1;
        end
        else begin
            reg_state   <=  reg_state_next;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_cnt_rx  <=  'b0;
            reg_data_rx <=  'b0;
        end
        else begin
            if (reg_state[2]) begin
                reg_cnt_rx  <=  'b0;
            end
            else if (reg_state[3] && sys_resp_data_valid) begin
                reg_cnt_rx  <=  reg_cnt_rx + 1'b1;
                reg_data_rx <=  {reg_data_rx, sys_resp_data};
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_cnt_tx          <=  'b0;
            reg_data_tx         <=  'b0;
            sys_req_data_valid  <=  'b0;
        end
        else if (sys_req_wr) begin
            if (reg_state[2]) begin
                reg_cnt_tx          <=  'b0;
                reg_data_tx         <=  reg_dev_data;
                sys_req_data_valid  <=  'b1;
            end
            else if (reg_state[3]) begin
                reg_cnt_tx  <=  reg_cnt_tx + 1'b1;
                reg_data_tx <=  reg_data_tx << 8;
                if (reg_cnt_tx == {MGNT_REG_WIDTH_L2{1'b1}})
                    sys_req_data_valid  <=  'b0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_dev_data    <=  'b0;
        end
        else if (reg_state[6]) begin
            reg_dev_data    <=  reg_dev_ptr[15:0];
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            spi_dout        <=  'b0;
        end
        else if (reg_state[7]) begin
            if (spi_op == DEV_PTR_ADDR) begin
                if (reg_dev_ptr[14:8] == SPI_LOCAL_ADDR) begin
                    if (reg_dev_ptr[7:0] == {1'b0, DEV_DATA_ADDR}) begin
                        spi_dout    <=  reg_dev_data;
                    end
                    if (reg_dev_ptr[7:0] == {1'b0, TABLE_CTRL_ADDR}) begin
                        spi_dout    <=  {14'b0, ft_bsy};
                    end
                    if (reg_dev_ptr[7:0] == {1'b0, TABLE_HASH_ADDR}) begin
                        spi_dout    <=  table_hash;
                    end
                    if (reg_dev_ptr[7:3] == 5'h06) begin
                        spi_dout    <=  table_reg[16*reg_dev_ptr[2:0]+:16];
                    end
                    if (reg_dev_ptr[7:0] == SW_ID_ADDR) begin
                        spi_dout    <=  SW_ID_VAL;
                    end
                    if (reg_dev_ptr[7:0] == SW_FTR_ADDR) begin
                        spi_dout    <=  SW_FTR_VAL;
                    end
                    if (reg_dev_ptr[7:0] == SW_REV_ADDR_0) begin
                        spi_dout    <=  usr_data[15:0];
                    end
                    if (reg_dev_ptr[7:0] == SW_REV_ADDR_1)begin
                        spi_dout    <=  usr_data[31:16];
                    end
                end
                else begin
                    spi_dout    <=  reg_data_rx;
                end
            end
            if (spi_op == DEV_DATA_ADDR) begin
                spi_dout    <=  reg_dev_data;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sys_req_valid   <=  'b0;
            sys_req_wr      <=  'b0;
        end
        else begin
            if (reg_state[1]) begin
                case(reg_dev_ptr[14:8])
                    PORT0_ADDR      : begin sys_req_valid <= 'h01; sys_req_wr <= reg_dev_ptr[15]; end
                    PORT1_ADDR      : begin sys_req_valid <= 'h02; sys_req_wr <= reg_dev_ptr[15]; end
                    PORT2_ADDR      : begin sys_req_valid <= 'h04; sys_req_wr <= reg_dev_ptr[15]; end
                    PORT3_ADDR      : begin sys_req_valid <= 'h08; sys_req_wr <= reg_dev_ptr[15]; end
                    BE_SW_ADDR      : begin sys_req_valid <= 'h10; sys_req_wr <= reg_dev_ptr[15]; end
                    BE_SW_FTM_ADDR  : begin sys_req_valid <= 'h20; sys_req_wr <= reg_dev_ptr[15]; end
                    TTE_SW_ADDR     : begin sys_req_valid <= 'h40; sys_req_wr <= reg_dev_ptr[15]; end
                    default: begin sys_req_valid <= 'b0; sys_req_wr <= 'b0; end
                endcase
            end
            else if (reg_state[4] && sys_req_ack) begin
                sys_req_valid   <=  'b0;
                sys_req_wr      <=  'b0;
            end
        end
    end

    assign  sys_req_addr        =   reg_dev_ptr[7:0];
    assign  sys_req_data        =   reg_data_tx[(MGNT_REG_WIDTH-1)-:8];
    // assign  sys_req_data_valid  =   reg_state[3] && sys_req_wr;
    // assign  spi_dout        =   reg_data_rx;

    always @(*) begin
        case(ft_state)
            1: ft_state_next    =   (spi_wr && spi_op == 'h2) ? 2 : 1;
            2: begin
                if (reg_dev_ptr == 'h1 || reg_dev_ptr == 'h2) begin
                    ft_state_next   =   4; 
                end
                else begin
                    ft_state_next   =   1;
                end
            end
            4: ft_state_next    =   1;
            default: ft_state_next  =   ft_state;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ft_state    <=  1;
        end
        else begin
            ft_state    <=  ft_state_next;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ft_update   <=  'b0;
            ft_clear    <=  'b0;
            ft_bsy      <=  'b0;
        end
        else begin
            if (ft_state == 2) begin
                if (reg_dev_ptr == 'h1) begin
                    ft_update   <=  'b1;
                end
                if (reg_dev_ptr == 'h2) begin
                    ft_clear    <=  'b1;
                end
            end
            else if (ft_state == 4) begin
                ft_update   <=  'b0;
                ft_clear    <=  'b0;
            end
            if (ft_update || ft_clear) begin
                ft_bsy  <=  {ft_clear, ft_update};
            end
            else if (!ft_ack) begin
                ft_bsy  <=  'b0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            table_hash  <=  'b0;
            table_reg   <=  'b0;
        end
        else if (spi_wr) begin
            if (spi_op == TABLE_HASH_ADDR) begin
                table_hash  <=  spi_din[11:0];
            end
            if (spi_op == TABLE_ST0_ADDR) begin
                table_reg[  0+:16]    <=  spi_din;
            end
            if (spi_op == TABLE_ST1_ADDR) begin
                table_reg[ 16+:16]    <=  spi_din;
            end
            if (spi_op == TABLE_ST2_ADDR) begin
                table_reg[ 32+:16]      <=  spi_din;
            end
            if (spi_op == TABLE_ST3_ADDR) begin
                table_reg[ 48+:16]      <=  spi_din;
            end
            if (spi_op == TABLE_ST4_ADDR) begin
                table_reg[ 64+:16]      <=  spi_din;
            end
            if (spi_op == TABLE_ST5_ADDR) begin
                table_reg[ 80+:16]      <=  spi_din;
            end
            if (spi_op == TABLE_ST6_ADDR) begin
                table_reg[ 96+:16]      <=  spi_din;
            end
            if (spi_op == TABLE_ST7_ADDR) begin
                table_reg[112+:16]      <=  spi_din;
            end
        end
    end

    assign  flow    =   table_reg[119:0];
    assign  hash    =   table_hash;
    assign  spi_ack =   spi_wr;

   USR_ACCESSE2 USR_ACCESSE2_inst (
      .CFGCLK(),            // 1-bit output: Configuration Clock output
      .DATA(usr_data),      // 32-bit output: Configuration Data output
      .DATAVALID()          // 1-bit output: Active high data valid output
   );

endmodule