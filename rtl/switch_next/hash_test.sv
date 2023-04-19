// scalable hash table for multiport destination lookup
module hash_test #(
    parameter   HASH_WIDTH      =   4,
    parameter   HASH_WIDTH_L2   =   $clog2(HASH_WIDTH)
) (
    input                       clk,
    input                       rst,
    input   [47:0]              input_mac   [HASH_WIDTH-1:0],
    input                       input_dir   [HASH_WIDTH-1:0],
    input   [HASH_WIDTH_L2-1:0] input_src   [HASH_WIDTH-1:0],
    output  [   HASH_WIDTH-1:0] output_dst  [HASH_WIDTH-1:0]

);

endmodule