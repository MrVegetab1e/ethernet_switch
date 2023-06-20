//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Athlon
// 
// Create Date: 2023/04/20
// Design Name: New MDIO ctrl interface
// Module Name: smi_new
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - On Progress
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module smi_new #(
    parameter   REF_CLK     =   125,
    parameter   MDC_CLK     =   500
) (
    input           clk,
    input           rstn,
    // mdio interface
    output reg      mdc,
    inout           mdio,
    // mgnt interface
    input           req_valid,  // req valid
    input           req_wr,     // req direction
    input   [ 9:0]  req_addr,   // [9:5]:phy addr, [4:0]:reg addr
    input   [15:0]  req_data,   // ignored when read
    output          resp_valid, // resp valid
    output  [15:0]  resp_data   // ignored when write
);

    localparam  MDC_DIV =   REF_CLK * 500 / MDC_CLK;
    localparam  ST      =   2'b01 ;     //mdio start code
    localparam  W_OP    =   2'b01 ;     //mdio write op code
    localparam  R_OP    =   2'b10 ;     //mdio read op code
    localparam  W_TA    =   2'b10 ;     //mdio write turn around code

    (* MARK_DEBUG="true" *) reg [ 7:0]  mdio_state, mdio_state_next;
    reg [ 3:0]  mdio_reg;
    reg         mdio_en;
    reg         mdio_out;
    reg [15:0]  mdc_cnt;
    reg [ 1:0]  mdc_reg;
    reg [ 5:0]  mdio_cnt;
    (* MARK_DEBUG="true" *) reg [15:0]  mdio_rd_buf;

    assign  mdio    =   mdio_en ? mdio_out : 1'bz;

    always @(posedge clk) begin
        if (!rstn) begin
            mdc_cnt     <=  'b0;
        end
        else begin
            if (mdc_cnt != MDC_DIV - 1'b1) begin
                mdc_cnt     <=  mdc_cnt + 1'b1;
            end
            else begin
                mdc_cnt     <=  'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mdc         <=  1'b1;
            mdc_reg     <=  2'b11;
        end
        else begin 
            if (mdc_cnt == MDC_DIV - 1'b1) begin
                mdc         <=  !mdc;
                mdc_reg     <=  {mdc_reg, !mdc};
            end
            else begin
                mdc_reg     <=  {mdc_reg, mdc};
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mdio_cnt    <=  'b0;
        end
        else begin
            if (mdio_state[0] && req_valid) begin
                mdio_cnt    <=  'b0;
            end
            else if (!mdio_state[0]) begin
                if (mdc_reg == 2'b10) begin     // inc @ negedge
                    mdio_cnt    <=  mdio_cnt + 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        mdio_reg    <=  {mdio_reg, mdio};
        if (mdio_state[3]) begin
            if (mdc_reg == 2'b01) begin
                mdio_rd_buf <=  {mdio_rd_buf, mdio_reg[3]};
            end
        end 
    end

    always @(*) begin
        case (mdio_state)
            01 : mdio_state_next =  req_valid ? 2 : 1;
            02 : mdio_state_next =  (mdio_cnt == 6'd15) ? 
                                    (req_wr ? 4 : 8) : 2;
            04 : mdio_state_next =  (mdio_cnt == 6'd33) ? 16 : 4;
            08 : mdio_state_next =  (mdio_cnt == 6'd33) ? 16 : 8;
            16 : mdio_state_next =  1;
            default : mdio_state_next = mdio_state;
        endcase
    end

    always @(posedge clk) begin
        if (!rstn) begin
            mdio_state  <=  1;
        end
        else begin
            mdio_state  <=  mdio_state_next;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            mdio_en     <=  1'b0;
            mdio_out    <=  1'b1;
        end
        else begin
            if (mdio_state[1]) begin
                mdio_en     <=  1'b1;
                case(mdio_cnt)
                    6'd1    : mdio_out <= ST[1] ;
                    6'd2    : mdio_out <= ST[0] ;
                    6'd3    : mdio_out <= req_wr ? W_OP[1] : R_OP[1];
                    6'd4    : mdio_out <= req_wr ? W_OP[0] : R_OP[0];
                    6'd5    : mdio_out <= req_addr[9] ;
                    6'd6    : mdio_out <= req_addr[8] ;
                    6'd7    : mdio_out <= req_addr[7] ;
                    6'd8    : mdio_out <= req_addr[6] ;
                    6'd9    : mdio_out <= req_addr[5] ;
                    6'd10   : mdio_out <= req_addr[4] ;
                    6'd11   : mdio_out <= req_addr[3] ;
                    6'd12   : mdio_out <= req_addr[2] ;
                    6'd13   : mdio_out <= req_addr[1] ;
                    6'd14   : mdio_out <= req_addr[0] ;
                    default : mdio_out <= 1'b1 ;
                endcase
            end
            else if (mdio_state[2]) begin
                mdio_en     <=  1'b1;
                case(mdio_cnt)
                    6'd15   : mdio_out <= W_TA[1] ;
                    6'd16   : mdio_out <= W_TA[0] ;
                    6'd17   : mdio_out <= req_data[15] ;
                    6'd18   : mdio_out <= req_data[14] ;
                    6'd19   : mdio_out <= req_data[13] ;
                    6'd20   : mdio_out <= req_data[12] ;
                    6'd21   : mdio_out <= req_data[11] ;
                    6'd22   : mdio_out <= req_data[10] ;
                    6'd23   : mdio_out <= req_data[9] ;
                    6'd24   : mdio_out <= req_data[8] ;
                    6'd25   : mdio_out <= req_data[7] ;
                    6'd26   : mdio_out <= req_data[6] ;
                    6'd27   : mdio_out <= req_data[5] ;
                    6'd28   : mdio_out <= req_data[4] ;
                    6'd29   : mdio_out <= req_data[3] ;
                    6'd30   : mdio_out <= req_data[2] ;
                    6'd31   : mdio_out <= req_data[1] ;
                    6'd32   : mdio_out <= req_data[0] ;
                    default : mdio_out <= 1'b1 ;
                endcase
            end
            else begin
                mdio_en     <=  1'b0;
                mdio_out    <=  1'b1;
            end
        end
    end

    assign  resp_valid  =   mdio_state[4];
    assign  resp_data   =   mdio_rd_buf;

endmodule