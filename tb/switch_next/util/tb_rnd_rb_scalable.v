module tb_rnd_rb_scal;

// rnd_rb_scal Parameters
parameter PERIOD       = 10              ;
parameter RR_WIDTH     = 4               ;
parameter RR_WIDTH_L2  = $clog2(RR_WIDTH);

integer i, j;

// rnd_rb_scal Inputs
reg                      clk                     ;
reg   [   RR_WIDTH-1:0]  rr_vec_in         = 'b0 ;
reg   [RR_WIDTH_L2-1:0]  rr_priority       = 'b1 ;

// rnd_rb_scal Outputs
wire  [   RR_WIDTH-1:0]  rr_vec_out        ;
wire  [RR_WIDTH_L2-1:0]  rr_bin_out        ;

initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

rnd_rb_scal #(
    .RR_WIDTH    ( RR_WIDTH    ),
    .RR_WIDTH_L2 ( RR_WIDTH_L2 ))
 u_rnd_rb_scal (
    .rr_vec_in               ( rr_vec_in    [   RR_WIDTH-1:0] ),
    .rr_priority             ( rr_priority  [RR_WIDTH_L2-1:0] ),

    .rr_vec_out              ( rr_vec_out   [   RR_WIDTH-1:0] ),
    .rr_bin_out              ( rr_bin_out   [RR_WIDTH_L2-1:0] )
);

initial
begin
    // repeat(2)@(posedge clk)
    for (j = 0; j < RR_WIDTH; j = j + 1) begin
        for (i = 0; i < 2**RR_WIDTH; i = i + 1) begin
            #10    
            rr_vec_in = rr_vec_in + 1'b1;
        end
        rr_priority = rr_priority + 1'b1;
    end
    #10 
    $finish;
end

endmodule