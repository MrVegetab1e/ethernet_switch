//~ `New testbench
`timescale  1ns / 1ps

module tb_switch_ctrl;

// switch_ctrl Parameters        
parameter PERIOD          = 4  ;
parameter SW_CTRL_TYPE    = "BE";
parameter MGNT_REG_WIDTH  = 16  ;

// switch_ctrl Inputs
reg   clk_if                               = 0 ;
reg   rst_if                               = 0 ;
reg   fp_stat_valid                        = 0 ;
reg   [ 7:0]  fp_stat_data                 = 0 ;
reg   fp_conf_resp                         = 0 ;
reg   swc_mgnt_valid                       = 0 ;
reg   [ 3:0]  swc_mgnt_data                = 0 ;
reg   aging_ack                            = 0 ;
reg   sys_req_valid                        = 0 ;
reg   sys_req_wr                           = 0 ;
reg   [ 7:0]  sys_req_addr                 = 0 ;
reg   [ 7:0]  sys_req_data                 = 0 ;
reg   sys_req_data_valid                   = 0 ;

// switch_ctrl Outputs
wire  fp_stat_resp                         ;
wire  fp_conf_valid                        ;
wire  [ 1:0]  fp_conf_type                 ;
wire  [15:0]  fp_conf_data                 ;
wire  swc_mgnt_resp                        ;
wire  aging_req                            ;
wire  sys_req_ack                          ;
wire  [ 7:0]  sys_resp_data                ;
wire  sys_resp_data_valid                  ;


initial
begin
    forever #(PERIOD/2)  clk_if=~clk_if;
end

initial
begin
    #(PERIOD*2) rst_if  =  1;
end

switch_ctrl #(
    .SW_CTRL_TYPE   ( SW_CTRL_TYPE   ),
    .MGNT_REG_WIDTH ( MGNT_REG_WIDTH ))
 u_switch_ctrl (
    .clk_if                  ( clk_if                      ),
    .rst_if                  ( rst_if                      ),
    .fp_stat_valid           ( fp_stat_valid               ),
    .fp_stat_data            ( fp_stat_data         [ 7:0] ),
    .fp_conf_resp            ( fp_conf_resp                ),
    .swc_mgnt_valid          ( swc_mgnt_valid              ),
    .swc_mgnt_data           ( swc_mgnt_data        [ 3:0] ),
    .aging_ack               ( aging_ack                   ),
    .sys_req_valid           ( sys_req_valid               ),
    .sys_req_wr              ( sys_req_wr                  ),
    .sys_req_addr            ( sys_req_addr         [ 7:0] ),
    .sys_req_data            ( sys_req_data         [ 7:0] ),
    .sys_req_data_valid      ( sys_req_data_valid          ),

    .fp_stat_resp            ( fp_stat_resp                ),
    .fp_conf_valid           ( fp_conf_valid               ),
    .fp_conf_type            ( fp_conf_type         [ 1:0] ),
    .fp_conf_data            ( fp_conf_data         [15:0] ),
    .swc_mgnt_resp           ( swc_mgnt_resp               ),
    .aging_req               ( aging_req                   ),
    .sys_req_ack             ( sys_req_ack                 ),
    .sys_resp_data           ( sys_resp_data        [ 7:0] ),
    .sys_resp_data_valid     ( sys_resp_data_valid         )
);

initial
begin

    #(PERIOD*10)
    fp_stat_valid = 1;
    fp_stat_data = 8'h99;
    #(PERIOD*10)
    fp_stat_valid = 0;
    #(PERIOD*10)
    fp_stat_valid = 1;
    fp_stat_data = 8'h09;
    #(PERIOD*10)
    fp_stat_valid = 0;
    #(PERIOD*10)
    fp_stat_valid = 1;
    fp_stat_data = 8'h14;
    #(PERIOD*10)
    fp_stat_valid = 0;
    #(PERIOD*10)
    swc_mgnt_valid = 1;
    swc_mgnt_data = 4'h7;
    #(PERIOD*10)
    swc_mgnt_valid = 0;

    // stat reg
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h00;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h02;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h07;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h10;
    #(PERIOD*10)
    sys_req_valid = 0;

    // clear
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 1;
    sys_req_addr = 8'h0F;
    #(PERIOD)
    sys_req_data = 8'h00;
    sys_req_data_valid = 1;
    #(PERIOD)
    sys_req_data = 8'h00;
    sys_req_data_valid = 1;
    #(PERIOD)
    sys_req_data = 8'h00;
    sys_req_data_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h00;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h02;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h07;
    #(PERIOD*10)
    sys_req_valid = 0;

    // conf deploy
    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 1;
    sys_req_addr = 8'h08;
    #(PERIOD)
    sys_req_data = 8'h12;
    sys_req_data_valid = 1;
    #(PERIOD)
    sys_req_data = 8'h34;
    sys_req_data_valid = 1;
    #(PERIOD)
    sys_req_data = 8'h00;
    sys_req_data_valid = 0;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)
    fp_conf_resp = 1;
    #(PERIOD*10)
    fp_conf_resp = 0;

    #(PERIOD*10)
    sys_req_valid = 1;
    sys_req_wr = 0;
    sys_req_addr = 8'h8;
    #(PERIOD*10)
    sys_req_valid = 0;
    #(PERIOD*10)

    $finish;
end

endmodule