`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/05/14 19:37:44
// Design Name:
// Module Name: mac_t_gmii_tte_tb_v2
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mac_t_gmii_tte_tb_v2;
    // Inputs
    reg rstn;
    reg clk;
    reg tx_clk;
    reg gtx_clk;
    reg [1:0] speed;  //ethernet speed 00:10M 01:100M 10:1000M
    reg status_fifo_rd;
    reg [31:0] counter_ns;
    // Outputs
    wire interface_clk;
    wire gtx_dv;
    wire [7:0] gtx_d;
    wire [15:0] status_fifo_dout;
    wire status_fifo_empty;
    wire [63:0] counter_ns_tx_delay;
    wire [63:0] counter_ns_gtx_delay;

    always #2.5 clk = ~clk;
    always #20 tx_clk = ~tx_clk;
    always #4 gtx_clk = ~gtx_clk;
    // Instantiate the Unit Under Test (UUT)
    reg  [ 7:0] data_fifo_din;
    reg         data_fifo_wr;
    wire        data_fifo_rd;
    wire [ 7:0] data_fifo_dout;
    wire [11:0] data_fifo_depth;

    reg  [15:0] ptr_fifo_din;
    reg         ptr_fifo_wr;
    wire        ptr_fifo_rd;
    wire [15:0] ptr_fifo_dout;
    wire        ptr_fifo_full;
    wire        ptr_fifo_empty;

    reg  [ 7:0] tdata_fifo_din;
    reg         tdata_fifo_wr;
    wire        tdata_fifo_rd;
    wire [ 7:0] tdata_fifo_dout;
    wire [11:0] tdata_fifo_depth;

    reg  [15:0] tptr_fifo_din;
    reg         tptr_fifo_wr;
    wire        tptr_fifo_rd;
    wire [15:0] tptr_fifo_dout;
    wire        tptr_fifo_full;
    wire        tptr_fifo_empty;

    wire [63:0] delay_fifo_din;
    wire        delay_fifo_wr;
    reg         delay_fifo_full;

    reg  [ 7:0] frame_1588_sync   [127:0];
    reg  [ 7:0] frame_1588_follow [127:0];
    reg  [ 7:0] frame_1588_req    [127:0];
    reg  [ 7:0] frame_1588_resp   [127:0];

    mac_t_gmii_tte_v5 u_mac_t_gmii (
        .rstn_sys(rstn),
        .rstn_mac(rstn),
        .sys_clk(clk),
        .tx_clk(tx_clk),
        .gtx_clk(gtx_clk),
        .interface_clk(interface_clk),
        .gtx_dv(gtx_dv),
        .gtx_d(gtx_d),
        .speed(speed),
        .data_fifo_rd(data_fifo_rd),
        .data_fifo_din(data_fifo_dout),
        .ptr_fifo_rd(ptr_fifo_rd),
        .ptr_fifo_din(ptr_fifo_dout),
        .ptr_fifo_empty(ptr_fifo_empty),
        .tdata_fifo_rd(tdata_fifo_rd),
        .tdata_fifo_din(tdata_fifo_dout),
        .tptr_fifo_rd(tptr_fifo_rd),
        .tptr_fifo_din(tptr_fifo_dout),
        .tptr_fifo_empty(tptr_fifo_empty),
        // .status_fifo_rd(status_fifo_rd),
        // .status_fifo_dout(status_fifo_dout),
        // .status_fifo_empty(status_fifo_empty),
        .counter_ns(counter_ns),
        // .counter_ns_tx_delay(counter_ns_tx_delay),
        // .counter_ns_gtx_delay(counter_ns_gtx_delay),
        .delay_fifo_din(delay_fifo_din),
        .delay_fifo_wr(delay_fifo_wr),
        .delay_fifo_full(delay_fifo_full)
    );

    reg reg_dv = 0;
    integer i = 0;

    always @(posedge interface_clk) begin
        if (!rstn) begin
            reg_dv  <=  0;
            i       <=  1;
        end
        else begin
            reg_dv  <=  gtx_dv;
            if (reg_dv && !gtx_dv) begin
                i   <=  1;
            end
            else if (!gtx_dv) begin
                i   <=  i + 1'b1;
            end
            else if (!reg_dv && gtx_dv) begin
                $display("f2f interval: %d", i);
            end
        end
    end

    initial begin
        // Initialize Inputs
        rstn = 0;
        clk = 0;
        tx_clk = 0;
        gtx_clk = 0;

        data_fifo_din = 0;
        data_fifo_wr = 0;
        ptr_fifo_din = 0;
        ptr_fifo_wr = 0;
        tdata_fifo_din = 0;
        tdata_fifo_wr = 0;
        tptr_fifo_din = 0;
        tptr_fifo_wr = 0;
        status_fifo_rd = 0;
        delay_fifo_full = 0;
        speed[1:0] = 2'b01;  //ethernet speed 00:10M 01:100M 10:1000M

        $readmemh("C:/Users/PC/Desktop/ethernet/ethernet_switch/tb/mac/gmii/1588_sync_udpv4_2.txt",
                  frame_1588_sync);
        $readmemh("C:/Users/PC/Desktop/ethernet/ethernet_switch/tb/mac/gmii/1588_follow_up_udpv4_2.txt",
                  frame_1588_follow);
        $readmemh("C:/Users/PC/Desktop/ethernet/ethernet_switch/tb/mac/gmii/1588_delay_req_udpv4_2.txt",
                  frame_1588_req);

        // Wait 100 ns for global reset to finish
        #100;
        rstn = 1;
        // Add stimulus here
        #1000;
        // send_frame(1514);
        // send_frame(100);
        send_frame(60);
        // send_1588_sync(60);
        // send_1588_follow(60);
        // send_1588_req(60);
        send_1588_sync(86);
        send_1588_follow(86);
        send_1588_req(86);
        send_frame(60);
        send_frame(1514);
        send_frame(100);
        // send_tteframe(300);
        // send_tteframe(58);
        #1000;
        $finish;

    end

    reg [31:0] counter;
    initial begin
        counter_ns = 0;
        counter = 0;
    end

    always @(posedge clk) begin
        counter <= #2 counter + 1;
    end


    always @(*) begin
        counter_ns = (counter << 2) + counter;  // counter_ns=counter*5
    end

    task send_frame;
        input [10:0] len;
        integer i;
        begin
            $display("start to send frame");
            repeat (1) @(posedge clk);
            #2;
            while (ptr_fifo_full | (data_fifo_depth > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                data_fifo_wr  = 1;
                data_fifo_din = ($random) % 256;
                repeat (1) @(posedge clk);
                #2;
            end
            data_fifo_wr = 0;
            ptr_fifo_din = {4'h1, 1'b0, len[10:0]};
            ptr_fifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            ptr_fifo_wr = 0;
            $display("end to send frame");
        end
    endtask

    task send_tteframe;
        input [10:0] len;
        integer i;
        begin
            $display("start to send tteframe");
            repeat (1) @(posedge clk);
            #2;
            while (tptr_fifo_full | (tdata_fifo_depth > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                tdata_fifo_wr  = 1;
                tdata_fifo_din = ($random) % 256;
                repeat (1) @(posedge clk);
                #2;
            end
            tdata_fifo_wr = 0;
            tptr_fifo_din = {4'h2, 1'b0, len[10:0]};
            tptr_fifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            tptr_fifo_wr = 0;
            $display("end to send tteframe");
        end
    endtask

    task send_1588_sync;
        input [10:0] len;
        integer i;
        begin
            $display("start to send 1588 sync frame");
            repeat (1) @(posedge clk);
            #2;
            while (ptr_fifo_full | (data_fifo_depth > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                data_fifo_wr  = 1;
                // tdata_fifo_din = ($random) % 256;
                data_fifo_din = frame_1588_sync[i];
                repeat (1) @(posedge clk);
                #2;
            end
            data_fifo_wr = 0;
            ptr_fifo_din = {4'h4, 1'b0, len[10:0]};
            ptr_fifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            ptr_fifo_wr = 0;
            $display("end to send 1588 sync frame");
        end
    endtask

    task send_1588_follow;
        input [10:0] len;
        integer i;
        begin
            $display("start to send 1588 follow frame");
            repeat (1) @(posedge clk);
            #2;
            while (ptr_fifo_full | (data_fifo_depth > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                data_fifo_wr  = 1;
                // tdata_fifo_din = ($random) % 256;
                data_fifo_din = frame_1588_follow[i];
                repeat (1) @(posedge clk);
                #2;
            end
            data_fifo_wr = 0;
            ptr_fifo_din = {4'h8, 1'b0, len[10:0]};
            ptr_fifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            ptr_fifo_wr = 0;
            $display("end to send 1588 follow frame");
        end
    endtask

    task send_1588_req;
        input [10:0] len;
        integer i;
        begin
            $display("start to send 1588 req frame");
            repeat (1) @(posedge clk);
            #2;
            while (ptr_fifo_full | (data_fifo_depth > 2578)) repeat (1) @(posedge clk);
            #2;
            for (i = 0; i < len; i = i + 1) begin
                data_fifo_wr  = 1;
                // tdata_fifo_din = ($random) % 256;
                data_fifo_din = frame_1588_req[i];
                repeat (1) @(posedge clk);
                #2;
            end
            data_fifo_wr = 0;
            ptr_fifo_din = {4'h0, 1'b0, len[10:0]};
            ptr_fifo_wr  = 1;
            repeat (1) @(posedge clk);
            #2;
            ptr_fifo_wr = 0;
            $display("end to send 1588 req frame");
        end
    endtask

    afifo_reg_w8_d4k u_data_fifo (
        .rst          (!rstn),           // input rst
        .wr_clk       (clk),             // input clk
        .rd_clk       (interface_clk),   // input clk
        .din          (data_fifo_din),   // input [7 : 0] din
        .wr_en        (data_fifo_wr),    // input wr_en
        .rd_en        (data_fifo_rd),    // input rd_en
        .dout         (data_fifo_dout),  // output [7 : 0] dout
        .full         (),                // output full
        .empty        (),                // output empty
        .wr_data_count(data_fifo_depth)  // output [11 : 0] data_count
    );

    afifo_w16_d32 u_ptr_fifo (
        .rst   (!rstn),          // input rst
        .wr_clk(clk),            // input clk
        .rd_clk(interface_clk),  // input clk
        .din   (ptr_fifo_din),   // input [15 : 0] din
        .wr_en (ptr_fifo_wr),    // input wr_en
        .rd_en (ptr_fifo_rd),    // input rd_en
        .dout  (ptr_fifo_dout),  // output [15 : 0] dout
        .full  (ptr_fifo_full),  // output full
        .empty (ptr_fifo_empty)  // output empty
    );

    afifo_reg_w8_d4k u_tte_fifo (
        .rst          (!rstn),            // input rst
        .wr_clk       (clk),              // input clk
        .rd_clk       (interface_clk),    // input clk
        .din          (tdata_fifo_din),   // input [7 : 0] din
        .wr_en        (tdata_fifo_wr),    // input wr_en
        .rd_en        (tdata_fifo_rd),    // input rd_en
        .dout         (tdata_fifo_dout),  // output [7 : 0] dout
        .full         (),                 // output full
        .empty        (),                 // output empty
        .wr_data_count(tdata_fifo_depth)  // output [11 : 0] data_count
    );

    afifo_w16_d32 u_tteptr_fifo (
        .rst   (!rstn),           // input rst
        .wr_clk(clk),             // input clk
        .rd_clk(interface_clk),   // input clk
        .din   (tptr_fifo_din),   // input [15 : 0] din
        .wr_en (tptr_fifo_wr),    // input wr_en
        .rd_en (tptr_fifo_rd),    // input rd_en
        .dout  (tptr_fifo_dout),  // output [15 : 0] dout
        .full  (tptr_fifo_full),  // output full
        .empty (tptr_fifo_empty)  // output empty
    );
endmodule
