//~ `New testbench
`timescale  1ns / 1ps

module tb_prio_enc;

// prio_enc Parameters
parameter PERIOD       = 10              ;
parameter PE_WIDTH     = 16              ;
parameter PE_WIDTH_L2  = $clog2(PE_WIDTH);

integer i;

// prio_enc Inputs
reg                   clk                  = 0 ;
reg   [PE_WIDTH-1:0]  pe_vec_in            = 0 ;

// prio_enc Outputs
wire                     pe_found             ;
wire  [   PE_WIDTH-1:0]  pe_vec_out           ;
wire  [PE_WIDTH_L2-1:0]  pe_bin_out           ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

prio_enc #(
    .PE_WIDTH    ( PE_WIDTH    ))
 u_prio_enc (
    .pe_vec_in               ( pe_vec_in   [   PE_WIDTH-1:0] ),

    .pe_found                ( pe_found                      ),
    .pe_vec_out              ( pe_vec_out  [   PE_WIDTH-1:0] ),
    .pe_bin_out              ( pe_bin_out  [PE_WIDTH_L2-1:0] )
);

initial
begin

    for (i = 0; i < 2**PE_WIDTH; i = i + 1) begin
        // repeat(1) @(posedge clk)
        #10
        pe_vec_in = pe_vec_in + 1'b1;
    end
    // repeat(1) @(posedge clk)
    #10
    $finish;
end

endmodule