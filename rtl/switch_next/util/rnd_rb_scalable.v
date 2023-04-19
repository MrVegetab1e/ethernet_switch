// scalable round-robin arbiter, binary tree implementation
module rnd_rb_scal #(
    parameter   RR_WIDTH    =   8,
    parameter   RR_WIDTH_L2 =   $clog2(RR_WIDTH)
) (
    input   [RR_WIDTH   -1:0]   rr_vec_in,     // input arbit vector
    input   [RR_WIDTH_L2-1:0]   rr_priority,
    output  [RR_WIDTH   -1:0]   rr_vec_out,
    output  [RR_WIDTH_L2-1:0]   rr_bin_out
);

    wire    [2**RR_WIDTH-2:0]   index_nodes [RR_WIDTH_L2:0];
    wire    [2**RR_WIDTH-2:0]   gnt_nodes;
    wire    [2**RR_WIDTH-2:0]   req_nodes;

    assign  gnt_nodes[0]    = 1;

    for (genvar level = 0; level < RR_WIDTH_L2; level = level + 1) begin : gen_levels
      for (genvar l = 0; l < 2**level; l = l + 1) begin : gen_level
        // local select signal
        wire sel;
        // index calcs
        localparam Idx0 = 2**level-1+l;// current node
        localparam Idx1 = 2**(level+1)-1+l*2;
        //////////////////////////////////////////////////////////////
        // uppermost level where data is fed in from the inputs
        if (level == RR_WIDTH_L2-1) begin : gen_first_level
          // if two successive indices are still in the vector...
          if (l * 2 < RR_WIDTH-1) begin : gen_reduce
            assign req_nodes[Idx0]      = rr_vec_in[l*2] | rr_vec_in[l*2+1];

            // arbitration: round robin
            assign sel =  ~rr_vec_in[l*2] | rr_vec_in[l*2+1] & rr_priority[RR_WIDTH_L2-1-level];

            assign index_nodes[Idx0]    = sel;
            assign rr_vec_out[l*2]      = gnt_nodes[Idx0] & rr_vec_in[l*2]   & ~sel;
            assign rr_vec_out[l*2+1]    = gnt_nodes[Idx0] & rr_vec_in[l*2+1] & sel;
          end
          // if only the first index is still in the vector...
          if (l * 2 == RR_WIDTH-1) begin : gen_first
            assign req_nodes[Idx0]      = rr_vec_in[l*2];
            assign index_nodes[Idx0]    = 'b0;// always zero in this case
            assign rr_vec_out[l*2]      = gnt_nodes[Idx0] & rr_vec_in[l*2];
          end
          // if index is out of range, fill up with zeros (will get pruned)
          if (l * 2 > RR_WIDTH-1) begin : gen_out_of_range
            assign req_nodes[Idx0]      = 'b0;
            assign index_nodes[Idx0]    = 'b0;
          end
        //////////////////////////////////////////////////////////////
        // general case for other levels within the tree
        end else begin : gen_other_levels
          assign req_nodes[Idx0]   = req_nodes[Idx1] | req_nodes[Idx1+1];

          // arbitration: round robin
          assign sel =  ~req_nodes[Idx1] | req_nodes[Idx1+1] & rr_priority[RR_WIDTH_L2-1-level];

          assign index_nodes[Idx0] = (sel) ?
            {1'b1, index_nodes[Idx1+1][RR_WIDTH_L2-level-2:0]} :
            {1'b0, index_nodes[Idx1][RR_WIDTH_L2-level-2:0]};

          assign gnt_nodes[Idx1]   = gnt_nodes[Idx0] & ~sel;
          assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] & sel;
        end
        //////////////////////////////////////////////////////////////
      end
    end

    assign      rr_bin_out  =   index_nodes[0];

endmodule