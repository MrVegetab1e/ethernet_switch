// scalable round-robin arbiter, programmable priority encoder(PPE) implementation
module rnd_rb_ppe #(
    parameter   RR_WIDTH    =   4,
    parameter   RR_WIDTH_L2 =   $clog2(RR_WIDTH)
) (
    input   [RR_WIDTH   -1:0]   rr_vec_in,     // input arbit vector
    input   [RR_WIDTH_L2-1:0]   rr_priority,
    output  [RR_WIDTH   -1:0]   rr_vec_out,
    output  [RR_WIDTH_L2-1:0]   rr_bin_out
);

    genvar n;

    wire    [RR_WIDTH   -1:0]   rr_vec_lo;
    wire    [RR_WIDTH   -1:0]   rr_vec_hi;

    wire    [RR_WIDTH   -1:0]   pe_vec_lo;
    wire    [RR_WIDTH_L2-1:0]   pe_bin_lo;
    wire    [RR_WIDTH   -1:0]   pe_vec_hi;
    wire    [RR_WIDTH_L2-1:0]   pe_bin_hi;
    wire                        pe_hi_found;

    for (n = 0; n < RR_WIDTH; n = n + 1) begin
        assign  rr_vec_hi[n]    =   (n >= rr_priority) ? rr_vec_in[n] : 1'b0;
    end
    assign  rr_vec_lo   =   rr_vec_in;

    prio_enc #(
        .PE_WIDTH   (RR_WIDTH)
    ) u_prio_enc_h (
        .pe_vec_in  (rr_vec_hi),
        .pe_vec_out (pe_vec_hi),
        .pe_bin_out (pe_bin_hi),
        .pe_found   (pe_hi_found)
    );

    prio_enc #(
        .PE_WIDTH   (RR_WIDTH)
    ) u_prio_enc_l (
        .pe_vec_in  (rr_vec_lo),
        .pe_vec_out (pe_vec_lo),
        .pe_bin_out (pe_bin_lo),
        .pe_found   ()
    );

    assign  rr_vec_out  =   pe_hi_found ? pe_vec_hi : pe_vec_lo;
    assign  rr_bin_out  =   pe_hi_found ? pe_bin_hi : pe_bin_lo;

endmodule