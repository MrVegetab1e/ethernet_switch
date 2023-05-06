//~ `New testbench
`timescale  1ns / 1ps

module tb_frame_process_v3;   

    // frame_process_v2 Parameters
    parameter PERIOD  = 10;
    parameter LIVE_TH  = 10'd150;


    // frame_process_v2 Inputs    
    reg   clk                                  = 0 ;
    reg   rstn                                 = 0 ;

    reg   [ 3:0]  link                         = 4'hF ;
    reg   [ 3:0]  o_cell_bp                    = 4'h0 ;

    // frame_process_v2 Outputs
    wire  sfifo_rd                             ;
    wire  [ 7:0]  sfifo_dout                   ;
    wire  ptr_sfifo_rd                         ;
    wire  [15:0]  ptr_sfifo_dout               ;
    wire  ptr_sfifo_empty                      ;

    wire  se_req                               ;
    wire  se_source                            ;
    wire  [ 9:0]  se_hash                      ;
    wire  [15:0]  source_portmap               ;
    wire  [47:0]  se_mac                       ;
    wire  se_ack                               ;
    wire  se_nak                               ;
    wire  [15:0]  se_result                    ;
    wire  aging_ack                            ;

    wire  [127:0]  i_cell_data_fifo_dout       ;
    wire  i_cell_data_fifo_wr                  ;
    wire  [ 15:0]  i_cell_ptr_fifo_dout        ;
    wire  i_cell_ptr_fifo_wr                   ;
    wire  i_cell_bp                            ;

    wire  [3:0]  o_cell_fifo_wr                ;
    wire  [127:0]  o_cell_fifo_din             ;
    wire  o_cell_first                         ;
    wire  o_cell_last                          ;


    initial
    begin
        forever #(PERIOD/2)  clk=~clk;
    end

    initial
    begin
        #(PERIOD*2) rstn  =  1;
    end

    frame_process_v3  u_frame_process_v3 (
        .clk                     ( clk                             ),
        .rstn                    ( rstn                            ),
        .sfifo_dout              ( sfifo_dout             [ 7:0]   ),
        .ptr_sfifo_dout          ( ptr_sfifo_dout         [15:0]   ),
        .ptr_sfifo_empty         ( ptr_sfifo_empty                 ),
        .se_ack                  ( se_ack                          ),
        .se_nak                  ( se_nak                          ),
        .se_result               ( se_result              [15:0]   ),
        .link                    ( link                   [ 3:0]   ),
        .i_cell_bp               ( i_cell_bp                       ),

        .sfifo_rd                ( sfifo_rd                        ),
        .ptr_sfifo_rd            ( ptr_sfifo_rd                    ),
        .se_mac                  ( se_mac                 [47:0]   ),
        .source_portmap          ( source_portmap         [15:0]   ),
        .se_hash                 ( se_hash                [ 9:0]   ),
        .se_source               ( se_source                       ),
        .se_req                  ( se_req                          ),
        .i_cell_data_fifo_dout   ( i_cell_data_fifo_dout  [127:0] ),
        .i_cell_data_fifo_wr     ( i_cell_data_fifo_wr             ),
        .i_cell_ptr_fifo_dout    ( i_cell_ptr_fifo_dout   [ 15:0]  ),
        .i_cell_ptr_fifo_wr      ( i_cell_ptr_fifo_wr              )
    );

    hash_2_bucket #(
        .LIVE_TH ( LIVE_TH ))
    u_hash_2_bucket (
        .clk                     ( clk                ),
        .rstn                    ( rstn               ),
        .se_source               ( se_source          ),
        .se_mac                  ( se_mac      [47:0] ),
        .se_portmap              ( source_portmap     ),
        .se_hash                 ( se_hash     [9:0]  ),
        .se_req                  ( se_req             ),
        .aging_req               ( 1'b0               ),

        .se_ack                  ( se_ack             ),
        .se_nak                  ( se_nak             ),
        .se_result               ( se_result   [15:0] ),
        .aging_ack               ( aging_ack          )
    );

    switch_core_v2  u_switch_core_v2 (
        .clk                     ( clk                           ),
        .rstn                    ( rstn                          ),
        .i_cell_data_fifo_din    ( i_cell_data_fifo_dout [127:0] ),
        .i_cell_data_fifo_wr     ( i_cell_data_fifo_wr           ),
        .i_cell_ptr_fifo_din     ( i_cell_ptr_fifo_dout  [15:0]  ),
        .i_cell_ptr_fifo_wr      ( i_cell_ptr_fifo_wr            ),
        .o_cell_bp               ( o_cell_bp             [3:0]   ),

        .i_cell_bp               ( i_cell_bp                     ),
        .o_cell_fifo_wr          ( o_cell_fifo_wr        [3:0]   ),
        .o_cell_fifo_din         ( o_cell_fifo_din       [127:0] ),
        .o_cell_first            ( o_cell_first                  ),
        .o_cell_last             ( o_cell_last                   )
    );

    reg  [ 7:0] sfifo_din       =   0;
    reg         sfifo_wr        =   0;
    wire [11:0] sfifo_cnt;
    reg  [15:0] ptr_sfifo_din   =   0;
    reg         ptr_sfifo_wr    =   0;
    wire        ptr_sfifo_full;


    sfifo_reg_w8_d4k    u_sfifo(
        .clk(clk),
        .rst(!rstn),
        .din(sfifo_din),
        .wr_en(sfifo_wr),
        .rd_en(sfifo_rd),
        .dout(sfifo_dout),
        .full(), 							
        .empty(), 					
        .data_count(sfifo_cnt),
        .underflow(),
        .overflow()	
        );
    sfifo_w16_d32   u_ptr_sfifo(
        .clk(clk),
        .rst(!rstn),
        .din(ptr_sfifo_din),
        .wr_en(ptr_sfifo_wr),
        .rd_en(ptr_sfifo_rd),
        .dout(ptr_sfifo_dout),
        .empty(ptr_sfifo_empty),
        .full(ptr_sfifo_full),
        .data_count(),
        .underflow(),
        .overflow()	
        );    

    initial
    begin
        send_frame(62);
        send_frame(63);
        send_frame(62);
        send_frame(63);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        send_frame(1514);
        $finish;
    end

    task send_frame;
        input [10:0] len;
        integer i;
        begin
            $display("start to send frame");
            repeat (1) @(posedge clk);
            #2;
            while (ptr_sfifo_full | (sfifo_cnt > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                sfifo_wr  = 1;
                sfifo_din = ($random) % 256;
                repeat (1) @(posedge clk);
                #2;
            end
            sfifo_wr = 0;
            ptr_sfifo_din = {1'b0, (4'b1 << ($random % 4)), len[10:0]};
            ptr_sfifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            ptr_sfifo_wr = 0;
            $display("end to send frame");
        end
    endtask

endmodule