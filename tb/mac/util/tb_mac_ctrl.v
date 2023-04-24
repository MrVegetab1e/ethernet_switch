//~ `New testbench
`timescale  1ns / 1ps

module tb_mac_ctrl;

// mac_ctrl Parameters
parameter PERIOD  = 10;


// mac_ctrl Inputs
reg   clk_if                               = 0 ;
reg   rst_if                               = 1 ;
reg   rx_mgnt_valid                        = 0 ;
reg   [19:0]  rx_mgnt_data                 = 0 ;
reg   tx_mgnt_valid                        = 0 ;
reg   [15:0]  tx_mgnt_data                 = 0 ;
reg   sys_req_valid                        = 0 ;
reg   sys_req_wr                           = 0 ;
reg   [ 7:0]  sys_req_addr                 = 0 ;

// mac_ctrl Outputs
wire  rx_mgnt_resp                         ;
wire  tx_mgnt_resp                         ;
wire  sys_resp_valid                       ;
wire  [ 7:0]  sys_resp_data                ;


initial
begin
    forever #(PERIOD/2)  clk_if=~clk_if;
end

initial
begin
    #(PERIOD*2) rst_if  =  0;
end

mac_ctrl  u_mac_ctrl (
    .clk_if                  ( clk_if                 ),
    .rst_if                  ( rst_if                 ),
    .rx_mgnt_valid           ( rx_mgnt_valid          ),
    .rx_mgnt_data            ( rx_mgnt_data    [19:0] ),
    .tx_mgnt_valid           ( tx_mgnt_valid          ),
    .tx_mgnt_data            ( tx_mgnt_data    [15:0] ),
    .sys_req_valid           ( sys_req_valid          ),
    .sys_req_wr              ( sys_req_wr             ),
    .sys_req_addr            ( sys_req_addr    [ 7:0] ),

    .rx_mgnt_resp            ( rx_mgnt_resp           ),
    .tx_mgnt_resp            ( tx_mgnt_resp           ),
    .sys_resp_valid          ( sys_resp_valid         ),
    .sys_resp_data           ( sys_resp_data   [ 7:0] )
);

initial
begin

    #(PERIOD*10)
    rx_mgnt_valid = 1;
    rx_mgnt_data = {8'b0, 12'd60};
    #(PERIOD*10)
    rx_mgnt_valid = 0;
    #(PERIOD*10)
    tx_mgnt_valid = 1;
    tx_mgnt_data = {4'b0, 12'd60};
    #(PERIOD*10)
    tx_mgnt_valid = 0;

    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_addr = 8'h00;
    #(PERIOD)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_addr = 8'h10;
    #(PERIOD)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 1;
    sys_req_addr = 8'h0F;
    #(PERIOD)
    sys_req_valid = 0;
    sys_req_wr = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_addr = 8'h00;
    #(PERIOD)
    sys_req_valid = 0;

    $finish;
end

endmodule