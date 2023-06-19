`timescale 1ns / 1ps
module interface_mux_v2 #(
    parameter   IFMUX_MODE      =   "LLDP",
    localparam  IFMUX_PTR_WIDTH =   (IFMUX_MODE == "LLDP") ? 20 : 16
) (
    input           clk_sys,
    input           rstn_sys,
    // mac 0 if
    output                          rx_data_fifo_rd0,
    input   [ 7:0]                  rx_data_fifo_dout0,
    output                          rx_ptr_fifo_rd0,
    input   [IFMUX_PTR_WIDTH-1:0]   rx_ptr_fifo_dout0,
    input                           rx_ptr_fifo_empty0,
    // mac 1 if
    output                          rx_data_fifo_rd1,
    input   [ 7:0]                  rx_data_fifo_dout1,
    output                          rx_ptr_fifo_rd1,
    input   [IFMUX_PTR_WIDTH-1:0]   rx_ptr_fifo_dout1,
    input                           rx_ptr_fifo_empty1,
    // mac 2 if
    output                          rx_data_fifo_rd2,
    input   [ 7:0]                  rx_data_fifo_dout2,
    output                          rx_ptr_fifo_rd2,
    input   [IFMUX_PTR_WIDTH-1:0]   rx_ptr_fifo_dout2,
    input                           rx_ptr_fifo_empty2,
    // mac 3 if
    output                          rx_data_fifo_rd3,
    input   [ 7:0]                  rx_data_fifo_dout3,
    output                          rx_ptr_fifo_rd3,
    input   [IFMUX_PTR_WIDTH-1:0]   rx_ptr_fifo_dout3,
    input                           rx_ptr_fifo_empty3,
    // backend if
    input                           sfifo_rd,
    output  [ 7:0]                  sfifo_dout,
    input                           ptr_sfifo_rd,
    output  [IFMUX_PTR_WIDTH-1:0]   ptr_sfifo_dout,
    output                          ptr_sfifo_empty
);

    reg     [ 5:0]  ifmux_state, ifmux_state_next;

    reg             bp;
    reg             error;
    reg     [12:0]  cnt;
    reg     [ 1:0]  cnt_1;
    reg     [12:0]  cnt_tgt;

    // dest data fifo ctrl
    reg     [ 1:0]  sfifo_wr;
    reg             sfifo_en;
    reg     [ 7:0]  sfifo_din;
    // wire    [13:0]  sfifo_cnt;
    wire    [11:0]  sfifo_cnt;
    // dest ptr fifo ctrl
    reg                             ptr_sfifo_wr;
    reg     [IFMUX_PTR_WIDTH-1:0]   ptr_sfifo_din;
    wire                            ptr_sfifo_full;
    // src data fifo sel
    (*EXTRACT_ENABLE = "no"*) reg     [ 3:0]  rx_data_fifo_rd;
    wire    [ 7:0]  rx_data_fifo_dout;
    // src ptr fifo sel
    reg     [ 3:0]                  rx_ptr_fifo_rd;
    wire    [IFMUX_PTR_WIDTH-1:0]   rx_ptr_fifo_dout;


    reg     [ 1:0]  ifmux_rndrb;
    reg     [ 3:0]  ifmux_sel;
    reg     [ 1:0]  ifmux_sel_bin;
    wire    [ 3:0]  ifmux_rr_vec_out;
    wire    [ 1:0]  ifmux_rr_bin_out;
    wire    [ 3:0]  rx_rdy;
    assign          rx_rdy  =   {!rx_ptr_fifo_empty3, !rx_ptr_fifo_empty2, !rx_ptr_fifo_empty1, !rx_ptr_fifo_empty0};

    rnd_rb_ppe #(
        .RR_WIDTH       (4)
    ) u_rndrb (
        .rr_vec_in      (rx_rdy),
        .rr_priority    (ifmux_rndrb),
        .rr_vec_out     (ifmux_rr_vec_out),
        .rr_bin_out     (ifmux_rr_bin_out)
    );

    always @(*) begin
        case(ifmux_state)
            01: ifmux_state_next =   (rx_rdy != 'b0 && !bp) ? 2 : 1;
            02: ifmux_state_next =   4;
            04: ifmux_state_next =   8;
            08: ifmux_state_next =   16;
            16: ifmux_state_next =   (cnt == cnt_tgt) ? 32 : 16;
            32: ifmux_state_next =   (cnt_1 == 2'b11) ? 1 : 32;
            default: ifmux_state_next = ifmux_state;
        endcase
    end

    always @(posedge clk_sys or negedge rstn_sys) begin
        if (!rstn_sys) begin
            ifmux_state <=  1;
        end
        else begin
            ifmux_state <=  ifmux_state_next;
        end
    end

    always @(posedge clk_sys or negedge rstn_sys) begin
        if (!rstn_sys) begin
            ifmux_rndrb     <=  'b0;
            ifmux_sel       <=  'b0;
            ifmux_sel_bin   <=  'b0;
        end
        else begin
            // if (ifmux_state_next == 2) begin
            if (ifmux_state_next[1]) begin
                ifmux_rndrb     <=  ifmux_rr_bin_out + 1'b1;
                ifmux_sel       <=  ifmux_rr_vec_out;
                ifmux_sel_bin   <=  ifmux_rr_bin_out;
            end
        end
    end

    always @(posedge clk_sys or negedge rstn_sys) begin
        if (!rstn_sys) begin
            // cnt             <=  'b1;
            // cnt_1           <=  'b0;
            // cnt_tgt         <=  'b0;
            // error           <=  'b0;
            sfifo_en        <=  'b0;
            sfifo_wr        <=  'b0;
            ptr_sfifo_wr    <=  'b0;
            rx_ptr_fifo_rd  <=  'b0;
            rx_data_fifo_rd <=  'b0;
        end
        else begin
            // cnt block ctrl
            // if (rx_data_fifo_rd != 0) begin
            if (!ifmux_state[0]) begin
                cnt     <=  cnt + 1'b1;
            end
            else begin
                cnt     <=  'h1;
            end
            // if (ifmux_state == 32) begin
            if (ifmux_state[5]) begin
                cnt_1   <=  cnt_1 + 1'b1;
            end
            else begin
                cnt_1   <=  'b0;
            end
            // rx data read
            // if (ifmux_state_next == 2) begin
            if (ifmux_state_next[1]) begin
                rx_data_fifo_rd <=  ifmux_rr_vec_out;
            end
            // else if (ifmux_state_next == 1) begin
            // else if (ifmux_state_next[0]) begin
            else if (ifmux_state[5] && cnt_1 == 2'b11) begin
                rx_data_fifo_rd <=  'b0;
            end
            // rx ptr read
            // if (ifmux_state_next == 2) begin
            if (ifmux_state_next[1]) begin
                rx_ptr_fifo_rd  <=  ifmux_rr_vec_out;
            end
            // else if (ifmux_state_next == 4) begin
            else if (ifmux_state[1]) begin
                rx_ptr_fifo_rd  <=  'b0;
            end
            // sfifo valid
            // if (ifmux_state_next == 2) begin
            if (ifmux_state[1]) begin
                sfifo_en        <=  'b1;
            end
            // else if (ifmux_state_next == 32) begin
            else if (ifmux_state[5]) begin
                sfifo_en        <=  'b0;
            end 
            // other ctrl signal
            // if (ifmux_state == 4) begin
            if (ifmux_state[2]) begin
                cnt_tgt         <=  rx_ptr_fifo_dout[12:0];
                error           <=  rx_ptr_fifo_dout[15] || rx_ptr_fifo_dout[14] || rx_ptr_fifo_dout[13];
            end
            // if (ifmux_state != 1) begin
            if (!ifmux_state[0]) begin
                // sfifo_wr        <=  !error;
                // sfifo_wr        <=  {sfifo_wr[0], !error && sfifo_en};
                sfifo_wr        <=  {!error && sfifo_wr[0], sfifo_en};
                // sfifo_din       <=  rx_data_fifo_dout;
                sfifo_din       <=  rx_data_fifo_dout;
            end
            // if (ifmux_state == 8) begin
            if (ifmux_state[3]) begin
                ptr_sfifo_wr    <=  !error;
                if (IFMUX_MODE == "LLDP") begin
                    ptr_sfifo_din   <=  {rx_ptr_fifo_dout[19:16], ifmux_sel, 1'b0, cnt_tgt[10:0]};
                end
                else begin
                    ptr_sfifo_din   <=  {ifmux_sel, 1'b0, cnt_tgt[10:0]};
                end
            end
            else begin
                ptr_sfifo_wr    <=  'b0;
            end
        end
    end

    always @(posedge clk_sys or negedge rstn_sys) begin
        if (!rstn_sys) begin
            bp  <=  'b1;
        end
        else begin
            // if (sfifo_cnt[13:8] >= 'h3A || ptr_sfifo_full) begin
            if (sfifo_cnt[11:8] >= 'h0A || ptr_sfifo_full) begin
                bp  <=  'b1;
            end
            else begin
                bp  <=  'b0;
            end
        end
    end

    assign  rx_data_fifo_rd0    =   rx_data_fifo_rd[0];
    assign  rx_data_fifo_rd1    =   rx_data_fifo_rd[1];
    assign  rx_data_fifo_rd2    =   rx_data_fifo_rd[2];
    assign  rx_data_fifo_rd3    =   rx_data_fifo_rd[3];
    assign  rx_ptr_fifo_rd0     =   rx_ptr_fifo_rd[0];
    assign  rx_ptr_fifo_rd1     =   rx_ptr_fifo_rd[1];
    assign  rx_ptr_fifo_rd2     =   rx_ptr_fifo_rd[2];
    assign  rx_ptr_fifo_rd3     =   rx_ptr_fifo_rd[3];
    assign  rx_ptr_fifo_dout    =   (ifmux_sel[0])  ?   rx_ptr_fifo_dout0   :
                                    (ifmux_sel[1])  ?   rx_ptr_fifo_dout1   :
                                    (ifmux_sel[2])  ?   rx_ptr_fifo_dout2   :
                                    rx_ptr_fifo_dout3;    
    assign  rx_data_fifo_dout   =   (ifmux_sel[0])  ?   rx_data_fifo_dout0  :
                                    (ifmux_sel[1])  ?   rx_data_fifo_dout1  :
                                    (ifmux_sel[2])  ?   rx_data_fifo_dout2  :
                                    rx_data_fifo_dout3; 

    (*MARK_DEBUG="true"*) wire  dbg_data_of;
    (*MARK_DEBUG="true"*) wire  dbg_data_uf;
    (*MARK_DEBUG="true"*) wire  dbg_ptr_of;
    (*MARK_DEBUG="true"*) wire  dbg_ptr_uf;

    sfifo_reg_w8_d4k    u_sfifo(
        .clk(clk_sys),
        .rst(!rstn_sys),
        .din(sfifo_din),
        .wr_en(sfifo_wr[1]),
        .rd_en(sfifo_rd),
        .dout(sfifo_dout),
        .full(), 							
        .empty(), 					
        .data_count(sfifo_cnt),
        .underflow(dbg_data_uf),
        .overflow(dbg_data_of)	
        );
    if (IFMUX_MODE == "LLDP") begin
        sfifo_w20_d32   u_ptr_sfifo(
            .clk(clk_sys),
            .rst(!rstn_sys),
            .din(ptr_sfifo_din),
            .wr_en(ptr_sfifo_wr),
            .rd_en(ptr_sfifo_rd),
            .dout(ptr_sfifo_dout),
            .empty(ptr_sfifo_empty),
            .full(ptr_sfifo_full),
            .data_count(),
            .underflow(dbg_ptr_uf),
            .overflow(dbg_ptr_of)	
            );
    end 
    else begin
        sfifo_w16_d32   u_ptr_sfifo(
            .clk(clk_sys),
            .rst(!rstn_sys),
            .din(ptr_sfifo_din),
            .wr_en(ptr_sfifo_wr),
            .rd_en(ptr_sfifo_rd),
            .dout(ptr_sfifo_dout),
            .empty(ptr_sfifo_empty),
            .full(ptr_sfifo_full),
            .data_count(),
            .underflow(dbg_ptr_uf),
            .overflow(dbg_ptr_of)	
            );
    end

endmodule
