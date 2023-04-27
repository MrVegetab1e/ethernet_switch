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
    output      [15:0]      spi_dout,
    // sys mgnt side interface
    output reg  [ 5:0]      sys_req_valid,
    output reg              sys_req_wr,
    output      [ 7:0]      sys_req_addr,
    input                   sys_resp_valid,
    input       [ 7:0]      sys_resp_data,
    // flow table side interface
    output reg              ft_clear,
    output reg              ft_update,
    output      [119:0]     flow,
    output      [11:0]      hash
);

    localparam  PORT0_ADDR      =   7'h00;
    localparam  PORT1_ADDR      =   7'h01;
    localparam  PORT2_ADDR      =   7'h02;
    localparam  PORT3_ADDR      =   7'h03;
    // localparam  BE_SW_ADDR      =   7'h40;
    // localparam  TTE_SW_ADDR     =   7'h41;
    parameter   TABLE_CTRL_ADDR =   7'h02;
    parameter   TABLE_HASH_ADDR =   7'h03;
    parameter   TABLE_ST0_ADDR  =   7'h30;
    parameter   TABLE_ST1_ADDR  =   7'h31;
    parameter   TABLE_ST2_ADDR  =   7'h32;
    parameter   TABLE_ST3_ADDR  =   7'h33;
    parameter   TABLE_ST4_ADDR  =   7'h34;
    parameter   TABLE_ST5_ADDR  =   7'h35;
    parameter   TABLE_ST6_ADDR  =   7'h36;
    parameter   TABLE_ST7_ADDR  =   7'h37;
    
    // spi reg operation
    reg     [3:0]  reg_state, reg_state_next;
    reg     [15:0]  reg_ptr;
    reg     [MGNT_REG_WIDTH_L2-1:0]     reg_cnt;
    reg     [MGNT_REG_WIDTH-1:0]    reg_data;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_ptr <=  'b0;
        end
        else begin
            if (spi_wr) begin
                reg_ptr <=  spi_din;
            end
        end
    end

    always @(*) begin
        case(reg_state)
            1: begin
                if (spi_wr && spi_op == 'b0) begin
                    reg_state_next  =   2;
                end
                else begin
                    reg_state_next  =   1; 
                end 
            end
            2: begin
                case(reg_ptr[14:8])
                    PORT0_ADDR: reg_state_next = 4;
                    PORT1_ADDR: reg_state_next = 4;
                    PORT2_ADDR: reg_state_next = 4;
                    PORT3_ADDR: reg_state_next = 4;
                    default: reg_state_next = 1;
                endcase
            end
            4: begin
                if (sys_req_wr) begin
                    reg_state_next  =   1;
                end
                else begin
                    if (reg_cnt == {MGNT_REG_WIDTH_L2-1{1'b1}}) begin
                        reg_state_next  =   1;
                    end
                    else begin
                        reg_state_next  =   4;
                    end
                end
            end
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
            reg_cnt     <=  'b1;
            reg_data    <=  'b0;
        end
        else if (sys_resp_valid) begin
            reg_cnt     <=  reg_cnt + 1'b1;
            reg_data    <=  {reg_data, sys_resp_data};
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sys_req_valid   <=  'b0;
            sys_req_wr      <=  'b0;
        end
        else begin
            if (reg_state == 2) begin
                case(reg_ptr[14:8])
                    PORT0_ADDR: begin sys_req_valid <= 'h1; sys_req_wr <= reg_ptr[15]; end
                    PORT1_ADDR: begin sys_req_valid <= 'h2; sys_req_wr <= reg_ptr[15]; end
                    PORT2_ADDR: begin sys_req_valid <= 'h4; sys_req_wr <= reg_ptr[15]; end
                    PORT3_ADDR: begin sys_req_valid <= 'h8; sys_req_wr <= reg_ptr[15]; end
                    default: begin sys_req_valid <= 'b0; sys_req_wr <= 'b0; end
                endcase
            end
            else if (reg_state == 4) begin
                sys_req_valid   <=  'b0;
                sys_req_wr      <=  'b0;
            end
        end
    end

    assign  sys_req_addr    =   reg_ptr[7:0];
    assign  spi_dout        =   reg_data;

    reg     [ 3:0]      ft_state, ft_state_next;
    reg     [127:0]     table_reg;
    reg     [11:0]      table_hash;

    always @(*) begin
        case(ft_state)
            1: ft_state_next    =   (spi_wr && spi_op == 'h2) ? 2 : 1;
            2: begin
                if (reg_ptr == 'h1 || reg_ptr == 'h2) begin
                    ft_state_next   =   4; 
                end
                else begin
                    ft_state_next   =   1;
                end
            end
            4: ft_state_next    =   1;
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
        end
        else begin
            if (ft_state == 2) begin
                if (reg_ptr == 'h1) begin
                    ft_update   <=  'b1;
                end
                if (reg_ptr == 'h2) begin
                    ft_clear    <=  'b1;
                end
            end
            if (ft_state == 4) begin
                ft_update   <=  'b0;
                ft_clear    <=  'b0;
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

endmodule