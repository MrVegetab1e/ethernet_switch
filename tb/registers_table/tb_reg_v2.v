//~ `New testbench
`timescale  1ns / 1ps

module tb_register_v2;

// register_v2 Parameters
parameter PERIOD           = 10   ;
parameter MGNT_REG_WIDTH   = 32   ;
parameter TABLE_CTRL_ADDR  = 7'h02;
parameter TABLE_HASH_ADDR  = 7'h03;
parameter TABLE_ST0_ADDR   = 7'h30;
parameter TABLE_ST1_ADDR   = 7'h31;
parameter TABLE_ST2_ADDR   = 7'h32;
parameter TABLE_ST3_ADDR   = 7'h33;
parameter TABLE_ST4_ADDR   = 7'h34;
parameter TABLE_ST5_ADDR   = 7'h35;
parameter TABLE_ST6_ADDR   = 7'h36;
parameter TABLE_ST7_ADDR   = 7'h37;

// register_v2 Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 0 ;
reg   spi_wr                               = 0 ;
reg   [ 6:0]  spi_op                       = 0 ;
reg   [15:0]  spi_din                      = 0 ;
reg   sys_resp_valid                       = 0 ;
reg   [ 7:0]  sys_resp_data                = 0 ;

// register_v2 Outputs
wire  [15:0]  spi_dout                     ;
wire  [ 5:0]  sys_req_valid                ;
wire  sys_req_wr                           ;
wire  [ 7:0]  sys_req_addr                 ;
wire  ft_clear                             ;
wire  ft_update                            ;
wire  [127:0]  flow                        ;
wire  [11:0]  hash                         ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
end

register_v2 #(
    .MGNT_REG_WIDTH  ( MGNT_REG_WIDTH  ),
    .TABLE_CTRL_ADDR ( TABLE_CTRL_ADDR ),
    .TABLE_HASH_ADDR ( TABLE_HASH_ADDR ),
    .TABLE_ST0_ADDR  ( TABLE_ST0_ADDR  ),
    .TABLE_ST1_ADDR  ( TABLE_ST1_ADDR  ),
    .TABLE_ST2_ADDR  ( TABLE_ST2_ADDR  ),
    .TABLE_ST3_ADDR  ( TABLE_ST3_ADDR  ),
    .TABLE_ST4_ADDR  ( TABLE_ST4_ADDR  ),
    .TABLE_ST5_ADDR  ( TABLE_ST5_ADDR  ),
    .TABLE_ST6_ADDR  ( TABLE_ST6_ADDR  ),
    .TABLE_ST7_ADDR  ( TABLE_ST7_ADDR  ))
 u_register_v2 (
    .clk                     ( clk                     ),
    .rst                     ( rst                     ),
    .spi_wr                  ( spi_wr                  ),
    .spi_op                  ( spi_op          [ 6:0]  ),
    .spi_din                 ( spi_din         [15:0]  ),
    .sys_resp_valid          ( sys_resp_valid          ),
    .sys_resp_data           ( sys_resp_data   [ 7:0]  ),

    .spi_dout                ( spi_dout        [15:0]  ),
    .sys_req_valid           ( sys_req_valid   [ 5:0]  ),
    .sys_req_wr              ( sys_req_wr              ),
    .sys_req_addr            ( sys_req_addr    [ 7:0]  ),
    .ft_clear                ( ft_clear                ),
    .ft_update               ( ft_update               ),
    .flow                    ( flow            [127:0] ),
    .hash                    ( hash            [11:0]  )
);

mac_ctrl #(
    .MGNT_REG_WIDTH ( MGNT_REG_WIDTH ))
 u_mac_ctrl_1 (
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

    $finish;
end

endmodule