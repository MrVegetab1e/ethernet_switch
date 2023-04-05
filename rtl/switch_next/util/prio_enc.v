// binary-tree scalable priority encoder
module prio_enc #(
    parameter   PE_WIDTH    =   4,
    parameter   PE_WIDTH_L2 =   $clog2(PE_WIDTH)
) (
    input   [   PE_WIDTH-1:0]   pe_vec_in,
    output  [   PE_WIDTH-1:0]   pe_vec_out,
    output  [PE_WIDTH_L2-1:0]   pe_bin_out,
    output                      pe_found
);

    genvar level, l;

    wire    [2**PE_WIDTH_L2-2:0]   nodes;
    wire    [2**PE_WIDTH_L2-2:0]   gnt_nodes;
    wire    [   PE_WIDTH_L2-1:0]   bin_nodes   [2**PE_WIDTH_L2-2:0];

    generate
        // create binary tree level
        for (level = 0; level < PE_WIDTH_L2; level = level + 1) begin : gen_levels
            // create nodes on same level
            for (genvar l = 0; l < 2**level; l = l + 1) begin : gen_level
                // index calcs
                // current node
                localparam Idx0 = 2**level-1+l;
                // child node
                localparam Idx1 = 2**(level+1)-1+l*2;
                if (level == PE_WIDTH_L2 - 1) begin
                    if (l*2 < PE_WIDTH) begin
                        assign nodes[Idx0] = pe_vec_in[l*2] || pe_vec_in[l*2+1];
                        // assign bin_nodes[Idx0] = pe_vec_in[l*2+1];
                        // assign pe_vec_out[l*2] = gnt_nodes[Idx0] && pe_vec_in[l*2] && !pe_vec_in[l*2+1];
                        // assign pe_vec_out[l*2+1] = gnt_nodes[Idx0] && pe_vec_in[l*2+1];
                        assign bin_nodes[Idx0] = ~pe_vec_in[l*2];
                        assign pe_vec_out[l*2] = gnt_nodes[Idx0] && pe_vec_in[l*2];
                        assign pe_vec_out[l*2+1] = gnt_nodes[Idx0] && !pe_vec_in[l*2] && pe_vec_in[l*2+1];
                    end
                    else if (l*2 == PE_WIDTH) begin
                        assign nodes[Idx0] = pe_vec_in[l*2];
                        assign bin_nodes[Idx0] = 'b0;
                        assign pe_vec_out[l*2] = gnt_nodes[Idx0] && pe_vec_in[l*2];
                    end
                    else begin
                        assign nodes[Idx0] = 'b0;
                        assign bin_nodes[Idx0] = 'b0;
                    end
                end
                else begin
                    assign nodes[Idx0] = nodes[Idx1] || nodes[Idx1+1];
                    // assign bin_nodes[Idx0] = nodes[Idx1+1] ? 
                    //     {1'b1, bin_nodes[Idx1+1][PE_WIDTH_L2-level-2:0]} : 
                    //     {1'b0, bin_nodes[Idx1+0][PE_WIDTH_L2-level-2:0]};
                    // assign gnt_nodes[Idx1] = gnt_nodes[Idx0] && nodes[Idx1] && !nodes[Idx1+1];
                    // assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] && nodes[Idx1+1];
                    assign bin_nodes[Idx0] = nodes[Idx1] ? 
                        {1'b0, bin_nodes[Idx1+0][PE_WIDTH_L2-level-2:0]} : 
                        {1'b1, bin_nodes[Idx1+1][PE_WIDTH_L2-level-2:0]};
                    assign gnt_nodes[Idx1] = gnt_nodes[Idx0] && nodes[Idx1];
                    assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] && !nodes[Idx1] && nodes[Idx1+1];
                end
            end
        end
    endgenerate  

    assign  gnt_nodes[0]    =   1;
    assign  pe_bin_out      =   bin_nodes[0];
    assign  pe_found        =   nodes[0];

    // always @(*) begin
    //     casex(pe_vec_in)
    //         16'b0000000000000000:   pe_vec_out  =  16'b0;
    //         16'b0000000000000001:   pe_vec_out  =  16'h1;
    //         16'b000000000000001x:   pe_vec_out  =  16'h2;
    //         16'b00000000000001xx:   pe_vec_out  =  16'h4;
    //         16'b0000000000001xxx:   pe_vec_out  =  16'h8;
    //         16'b000000000001xxxx:   pe_vec_out  =  16'h10;
    //         16'b00000000001xxxxx:   pe_vec_out  =  16'h20;
    //         16'b0000000001xxxxxx:   pe_vec_out  =  16'h40;
    //         16'b000000001xxxxxxx:   pe_vec_out  =  16'h80;
    //         16'b00000001xxxxxxxx:   pe_vec_out  =  16'h100;
    //         16'b0000001xxxxxxxxx:   pe_vec_out  =  16'h200;
    //         16'b000001xxxxxxxxxx:   pe_vec_out  =  16'h400;
    //         16'b00001xxxxxxxxxxx:   pe_vec_out  =  16'h800;
    //         16'b0001xxxxxxxxxxxx:   pe_vec_out  =  16'h1000;
    //         16'b001xxxxxxxxxxxxx:   pe_vec_out  =  16'h2000;
    //         16'b01xxxxxxxxxxxxxx:   pe_vec_out  =  16'h4000;
    //         16'b1xxxxxxxxxxxxxxx:   pe_vec_out  =  16'h8000;
    //     endcase
    // end

    // assign  pe_found        =   !(pe_vec_in == 'b0);


endmodule