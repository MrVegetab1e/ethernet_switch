//~ `New testbench
`timescale  1ns / 1ps

module tb_rnd_rb_ppe;

// rnd_rb_ppe Parameters
parameter PERIOD       = 10              ;
parameter RR_WIDTH     = 8               ;
parameter RR_WIDTH_L2  = $clog2(RR_WIDTH);

integer i, j;

// rnd_rb_ppe Inputs
reg                      clk               = 0 ;
reg   [RR_WIDTH   -1:0]  rr_vec_in         = 0 ;
reg   [RR_WIDTH_L2-1:0]  rr_priority       = 0 ;

// rnd_rb_ppe Outputs
wire  [RR_WIDTH   -1:0]  rr_vec_out        ;
wire  [RR_WIDTH_L2-1:0]  rr_bin_out        ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

rnd_rb_ppe #(
    .RR_WIDTH    ( RR_WIDTH    ),
    .RR_WIDTH_L2 ( RR_WIDTH_L2 ))
 u_rnd_rb_ppe (
    .rr_vec_in               ( rr_vec_in    [RR_WIDTH   -1:0] ),
    .rr_priority             ( rr_priority  [RR_WIDTH_L2-1:0] ),

    .rr_vec_out              ( rr_vec_out   [RR_WIDTH   -1:0] ),
    .rr_bin_out              ( rr_bin_out   [RR_WIDTH_L2-1:0] )
);

initial
begin
    for (i = 0; i < RR_WIDTH; i = i + 1) begin
        for (j = 0; j < 2**RR_WIDTH; j = j + 1) begin
            #10
            rr_vec_in = rr_vec_in + 1'b1;
        end
        rr_priority = rr_priority + 1'b1;
    end
    #10
    $finish;
end

endmodule