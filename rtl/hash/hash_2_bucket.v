`timescale 1ns / 1ps
//====================================================================
//entry structure:
//[15:0]:portmap
//[63:16]:mac
//[73:64]:age counter
//[79]:item valid
//=====================================================================
module hash_2_bucket(
input               clk,
input               rstn,
//port se signals.
input               se_source,
input       [47:0]  se_mac,
input       [15:0]  se_portmap,
input       [9:0]   se_hash,        
input               se_req,
output  reg         se_ack,
output  reg         se_nak,
output  reg [15:0]  se_result,
input               aging_req,  
output  reg         aging_ack   
);
parameter   LIVE_TH=10'd150;
// parameter LIVE_TH=7'd100;

//======================================
//              main state.
//======================================
reg     [3:0]   state;
reg             clear_op;
// reg     [2:0]   hit0;
// reg     [2:0]   hit1;
reg             hit0, hit1;
reg             hit0_0, hit0_1;
reg             hit1_0, hit1_1;
//======================================
//              one cycle for state1.
//======================================
reg             count;

wire            item_valid0;
wire            item_valid1;
wire    [9:0]   live_time0;
wire    [9:0]   live_time1;
wire            not_outlive_0;
wire            not_outlive_1;

reg             ram_wr_data_0;
reg             ram_wr_tag_0;
reg     [ 9:0]  ram_addr_0;
reg     [15:0]  ram_din_tag_0;
reg     [63:0]  ram_din_data_0;
wire    [15:0]  ram_dout_tag_0;
// reg     [15:0]  ram_dout_tag_0_reg;
wire    [63:0]  ram_dout_data_0;
// reg     [63:0]  ram_dout_data_0_reg;
reg             ram_wr_data_1;
reg             ram_wr_tag_1;
reg     [ 9:0]  ram_addr_1;
reg     [15:0]  ram_din_tag_1;
reg     [63:0]  ram_din_data_1;
wire    [15:0]  ram_dout_tag_1;
// reg     [15:0]  ram_dout_tag_1_reg;
wire    [63:0]  ram_dout_data_1;
// reg     [63:0]  ram_dout_data_1_reg;

reg     [9:0]   aging_addr;
// reg     [47:0]  hit_mac;
reg     [47:0]  hit_mac_0;
reg     [47:0]  hit_mac_1;
always @(posedge clk or negedge rstn)
    if(!rstn)begin
        state<=#2 0;
		clear_op<=#2 1;
        ram_wr_tag_0<=#2 0;
        ram_wr_data_0<=#2 0;
        // ram_addr_0<=#2 0; 
        // ram_din_0<=#2 0;    
        ram_wr_tag_1<=#2 0;
        ram_wr_data_1<=#2 0;
        // ram_addr_1<=#2 0; 
        // ram_din_1<=#2 0;    
        se_ack<=#2 0;
        se_nak<=#2 0;
        se_result<=#2 0;
        aging_ack<=#2 0;
        aging_addr<=#2 0;
        // hit_mac<=#2 0;
        // hit_mac_0<=#2 0;
        // hit_mac_1<=#2 0;
        count<=#2 0;
        hit0<=#2 0;
        hit1<=#2 0;
        end
    else begin
        // ram_dout_0_reg<=#2 ram_dout_0;  
        // ram_dout_1_reg<=#2 ram_dout_1;  
        ram_wr_tag_0<=#2 0;
        ram_wr_data_0<=#2 0;
        ram_wr_tag_1<=#2 0;
        ram_wr_data_1<=#2 0;
        se_ack<=#2 0;
        se_nak<=#2 0;
        aging_ack<=#2 0;
        case(state)
        0:begin
            if(clear_op) begin
                ram_addr_0<=#2 0;
                ram_addr_1<=#2 0;
                ram_wr_tag_0<=#2 1;
                ram_wr_tag_1<=#2 1;
                ram_din_tag_0<=#2 0;
                ram_din_tag_1<=#2 0;
                state<=#2 15;
                end
            else if(se_req) begin
                ram_addr_0<=#2 se_hash;
                ram_addr_1<=#2 se_hash;
                // hit_mac   <=#2 se_mac;
                hit_mac_0 <=#2 se_mac;
                hit_mac_1 <=#2 se_mac;
                count     <=#2 0;
                state   <=#2 1;
                end
            else if(aging_req) begin
                if(aging_addr<10'h3ff) aging_addr<=#2 aging_addr+1;
                else begin
                    aging_addr<=#2 0;
                    aging_ack<=#2 1;
                    end
                ram_addr_0<=#2 aging_addr;
                ram_addr_1<=#2 aging_addr;
                state<=#2 8;
                end
            end
        //===============================================
        //check if there is an entry can match current 
        //source mac address. 
        //(1)if macthed, refresh live time.
        //(2)if not macthed, add new entry.
        //===============================================
        1:begin
            count <=#2 1;
            if(count) state<=#2 2;
            end
        2:begin
            if(se_source) state<=#2 3;
            else state<=#2 6;
            // hit0<=#2 {ram_dout_tag_0[15], hit0_0, hit0_1};
            // hit1<=#2 {ram_dout_tag_1[15], hit1_0, hit1_1};
            hit0<=#2 (ram_dout_tag_0[15] && hit0_0 && hit0_1);
            hit1<=#2 (ram_dout_tag_1[15] && hit1_0 && hit1_1);
            end
        3:begin
            //=====================================================
            //if no entry is matched(still valid), should add new 
            //entry.
            //=====================================================
            if({hit1,hit0}==2'b00) state<=#2 4;
            // if({&(hit1), &(hit0)}==2'b0) state<=#2 4;
            //=====================================================
            //if an entry is existed and old entry should be refreshed.
            //=====================================================
            else state<=#2 5;
            end
        4:begin
            state<=#2 14;
            case({item_valid1,item_valid0})
            2'b11: se_nak<=#2 1;
            2'b00,2'b10: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_0<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_tag_0<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_din_data_0<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_wr_tag_0<=#2 1;
                ram_wr_data_0<=#2 1;
                end
            2'b01:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_1<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_tag_1<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_din_data_1<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_wr_tag_1<=#2 1;
                ram_wr_data_1<=#2 1;
                end
            endcase
            end
        5:begin
            state<=#2 14;
            case({hit1,hit0})
            // case({&(hit1), &(hit0)})
            2'b01: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_0<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_data_0<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_wr_data_0<=#2 1;
                ram_din_tag_0<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_wr_tag_0<=#2 1;
                end
            2'b10:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                // ram_din_1<=#2 { 1'b1,5'b0,
                //                 LIVE_TH,
                //                 se_mac[47:0],
                //                 se_portmap[15:0]};
                ram_din_data_1<=#2 {se_portmap[15:0], se_mac[47:0]};
                ram_wr_data_1<=#2 1;
                ram_din_tag_1<=#2 {1'b1, 5'b0, LIVE_TH};
                ram_wr_tag_1<=#2 1;
                end
            endcase
            end
        6:begin
            state<=#2 14;
            case({hit1,hit0})
            // case({&(hit1), &(hit0)})
            2'b00: begin
                se_ack<=#2 0;
                se_nak<=#2 1;
                se_result<=#2 ~se_portmap;
                end
            2'b01: begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_0[63:48];
                end
            2'b10:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_1[63:48];             
                end
        //=============================
        //code for 2'b11
        //=============================
            2'b11:begin
                se_nak<=#2 0;
                se_ack<=#2 1;
                se_result<=#2 ram_dout_data_0[63:48];            
                end
            endcase
            end
        //=============================
        //normal aging op.
        //=============================
        8:state<=#2 9;
        9:state<=#2 10;
        10:begin
            state<=#2 14;
            ram_din_tag_0<=#2 {item_valid0 && not_outlive_0, 5'b0, live_time0-1'b1};
            ram_wr_tag_0<=#2 1;
            ram_din_tag_1<=#2 {item_valid1 && not_outlive_1, 5'b0, live_time1-1'b1};
            ram_wr_tag_1<=#2 1;
            // if(not_outlive_0)begin
            //     // ram_din_0[79]<=#2 1'b1;
            //     // ram_din_0[78:74]<=#2 5'b0;
            //     // ram_din_0[73:64]<=#2 live_time0-10'd1;
            //     // ram_din_0[63:0]<=#2  ram_dout_0_reg[63:0];
            //     // ram_wr_0<=#2 1;
            //     ram_din_tag_0<=#2 {1'b1, 5'b0, live_time0-1'b1};
            //     ram_wr_tag_0<=#2 1;
            //     end
            // else begin
            //     // ram_din_0[79:0]<=#2 80'b0;
            //     // ram_wr_0<=#2 1;
            //     ram_din_tag_0<=#2 'b0;
            //     ram_wr_tag_0<=#2 1;
            //     end
            // if(not_outlive_1)begin
            //     // ram_din_1[79]<=#2 1'b1;
            //     // ram_din_1[78:74]<=#2 5'b0;
            //     // ram_din_1[73:64]<=#2 live_time1-10'd1;
            //     // ram_din_1[63:0]<=#2  ram_dout_1_reg[63:0];
            //     // ram_wr_1<=#2 1;
            //     ram_din_tag_1<=#2 {1'b1, 5'b0, live_time1-1'b1};
            //     ram_wr_tag_1<=#2 1;
            //     end
            // else begin
            //     // ram_din_1[79:0]<=#2 80'b0;
            //     // ram_wr_1<=#2 1;
            //     ram_din_tag_1<=#2 'b0;
            //     ram_wr_tag_1<=#2 1;
            //     end
            end 
        14:begin
            state<=#2 0;
            hit0<=#2 0;
            hit1<=#2 0;
            end
        15:begin
            if(ram_addr_0<10'h3ff) begin
				ram_addr_0<=#2 ram_addr_0+1;
                ram_wr_tag_0<=#2 1;
				end
            else ram_addr_0<=#2 0;
            if(ram_addr_1<10'h3ff) begin
				ram_addr_1<=#2 ram_addr_1+1;
                ram_wr_tag_1<=#2 1;
				end
            else begin
                ram_addr_1<=#2 0;
                ram_wr_tag_0<=#2 0;
                ram_wr_tag_1<=#2 0;
                clear_op<=#2 0;
                state<=#2 0;
                end
            end
        endcase
        end

always @(*)begin
    // hit0=(hit_mac==ram_dout_0_reg[63:16])& ram_dout_0_reg[79];          
    // hit1=(hit_mac==ram_dout_1_reg[63:16])& ram_dout_1_reg[79];          
    hit0_0=(hit_mac_0[0+:24]==ram_dout_data_0[0+:24]);
    hit0_1=(hit_mac_0[24+:24]==ram_dout_data_0[24+:24]);
    hit1_0=(hit_mac_1[0+:24]==ram_dout_data_1[0+:24]);
    hit1_1=(hit_mac_1[24+:24]==ram_dout_data_1[24+:24]);
    end
assign item_valid0=ram_dout_tag_0[15];
assign item_valid1=ram_dout_tag_1[15];
assign live_time0=ram_dout_tag_0[ 9:0];
assign live_time1=ram_dout_tag_1[ 9:0];
assign not_outlive_0=(live_time0!=0)?1:0;
assign not_outlive_1=(live_time1!=0)?1:0;

sram_w16_d1k u_sram_tag_0 (
  .clka(clk),
  .wea(ram_wr_tag_0),
  .addra(ram_addr_0),
  .dina(ram_din_tag_0),
  .douta(ram_dout_tag_0)
);
sram_w64_d1k u_sram_data_0 (
  .clka(clk),
  .wea(ram_wr_data_0),
  .addra(ram_addr_0),
  .dina(ram_din_data_0),
  .douta(ram_dout_data_0)
);
sram_w16_d1k u_sram_tag_1 (
  .clka(clk),
  .wea(ram_wr_tag_1),
  .addra(ram_addr_1),
  .dina(ram_din_tag_1),
  .douta(ram_dout_tag_1)
);
sram_w64_d1k u_sram_data_1 (
  .clka(clk),
  .wea(ram_wr_data_1),
  .addra(ram_addr_1),
  .dina(ram_din_data_1),
  .douta(ram_dout_data_1)
);
// sram_w80_d1k u_sram_0 (
//   .clka(clk),           // input clka
//   .wea(ram_wr_0),       // input [0 : 0] wea
//   .addra(ram_addr_0),   // input [9 : 0] addra
//   .dina(ram_din_0),     // input [79 : 0] dina
//   .douta(ram_dout_0)    // output [79 : 0] douta
// );
// sram_w80_d1k u_sram_1 (
//   .clka(clk),           // input clka
//   .wea(ram_wr_1),       // input [0 : 0] wea
//   .addra(ram_addr_1),   // input [9 : 0] addra
//   .dina(ram_din_1),     // input [79 : 0] dina
//   .douta(ram_dout_1)    // output [79 : 0] douta
// );

endmodule
