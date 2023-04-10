// crossbar architecture test
module xbar_test #(
    parameter   XBAR_INPUT      =   4,
    parameter   XBAR_INPUT_L2   =   $clog2(XBAR_INPUT),
    parameter   XBAR_WIDTH      =   8
) (
    input   [XBAR_WIDTH   -1:0] xbar_input  [XBAR_INPUT-1:0],
    input   [XBAR_INPUT_L2-1:0] xbar_arbit  [XBAR_INPUT-1:0],
    output  [XBAR_WIDTH   -1:0] xbar_output [XBAR_INPUT-1:0]
);

    integer i;
    genvar n;

    generate
        for (n = 0; n < XBAR_INPUT; n = n + 1) begin : xbar_instance
            assign  xbar_output[n]  =   xbar_input[xbar_arbit[n]];
        end
    endgenerate

endmodule