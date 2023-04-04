//~ `New testbench
`timescale  1ns / 1ps

module tb_rst_ctrl;

// rst_ctrl Parameters
parameter real PERIOD_SRC = 5;
parameter real PERIOD_SYS = 4;


// rst_ctrl Inputs
reg   src_clk                              = 0 ;
reg   sys_clk                              = 0 ;
reg   arstn                                = 1 ;
reg   pll_locked                           = 0 ;

// rst_ctrl Outputs
wire  rstn_pll                             ;
wire  rstn_sys                             ;
wire  rstn_mac                             ;


initial
begin
    forever #(PERIOD_SRC/2)  src_clk=~src_clk;
end

initial
begin
    forever #(PERIOD_SYS/2)  sys_clk=~sys_clk;
end

initial
begin
    #41 arstn  =  0;
    #52 arstn  =  1;
end

rst_ctrl  u_rst_ctrl (
    .src_clk                 ( src_clk      ),
    .sys_clk                 ( sys_clk      ),
    .arstn                   ( arstn        ),
    .pll_locked              ( pll_locked   ),

    .rstn_pll                ( rstn_pll     ),
    .rstn_sys                ( rstn_sys     ),
    .rstn_mac                ( rstn_mac     )
);

initial
begin
    #(45+PERIOD_SRC*20)
    pll_locked = 1;
    #(PERIOD_SRC*300)
    $finish;
end

endmodule