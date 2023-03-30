`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2022/05/11 16:43:39
// Design Name: Scalable interface MUX
// Module Name: interface_mux_scalable
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// - Scalable MUX between frontend MAC rx modules and backend switch modules
// - Round-robin arbitration with programmable priority levels
// - System Verilog implementation
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module interface_mux_scalable #(
    parameter   MUX_INPUT_WIDTH     = 4,
    parameter   MUX_OUTPUT_WIDTH    = 1
) (
    // common interfaces
    input           clk,
    input           rstn,
    // MAC rx side interfaces
    input           rx_data_fifo_rd     [ 3:0]  ,
    input   [ 7:0]  rx_data_fifo_dout   [ 3:0]  ,
    output          rx_ptr_fifo_rd      [ 3:0]  ,
    input   [15:0]  rx_ptr_fifo_dout    [ 3:0]  ,
    input           rx_ptr_fifo_empty   [ 3:0]  ,
    // switch side interfaces
    input           sw_data_fifo_rd     [ 0:0]  ,
    output  [ 7:0]  sw_data_fifo_dout   [ 0:0]  ,
    input           sw_ptr_fifo_rd      [ 0:0]  ,
    output  [ 7:0]  sw_ptr_fifo_dout    [ 0:0]  ,
    output          sw_ptr_fifo_empty   [ 0:0]
);





endmodule