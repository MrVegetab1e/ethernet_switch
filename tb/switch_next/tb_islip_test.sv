//~ `New testbench
`timescale  1ns / 1ps

module tb_islip_test;

// islip_test Parameters       
parameter PERIOD          = 10;
parameter ARB_STATE_IDLE  = 1; 
parameter ARB_STATE_GRNT  = 2; 
parameter ARB_STATE_ACPT  = 4; 
parameter ARB_STATE_WAIT  = 8; 

// islip_test Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 0 ;
reg   arb_valid_in                         = 0 ;
reg   [ 3:0]  rx_req_vect [4]              = {0, 0, 0, 0} ;
reg   [ 3:0]  tx_rdy_vect                  = 0 ;
reg   arb_ready_out                        = 0 ;

// islip_test Outputs
wire  arb_ready_in                         ;
wire  arb_valid_out                        ;
wire  [ 3:0]  arb_vect [3:0]               ;

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
end

islip_test u_islip_test (
    .clk                 ( clk                      ),
    .rst                 ( rst                      ),
    .arb_valid_in        ( arb_valid_in             ),
    .rx_req_vect         ( rx_req_vect              ),
    .tx_rdy_vect         ( tx_rdy_vect              ),
    .arb_ready_out       ( arb_ready_out            ),
    .arb_ready_in        ( arb_ready_in             ),
    .arb_valid_out       ( arb_valid_out            ),
    .arb_vect            ( arb_vect                 )
);

initial
begin
    #(PERIOD*10)
    rst = 1'b0;
    #(PERIOD*10)
    arb_valid_in = 1;
    arb_ready_out = 1;
    rx_req_vect = {4'h0, 4'h1, 4'hC, 4'h0};
    #(PERIOD*3)
    rx_req_vect = {4'h7, 4'h2, 4'h8, 4'h2};
    #(PERIOD*4)
    rx_req_vect = {4'h3, 4'h0, 4'h5, 4'hA};
    #(PERIOD*4)
    rx_req_vect = {4'h6, 4'h1, 4'h0, 4'h0};   
    #(PERIOD*6)
    $finish;
end

endmodule