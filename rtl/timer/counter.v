`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/19 14:44:12
// Design Name: 
// Module Name: counter
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


module counter
(
input               clk,
input               rst_n,
output      [31:0]  counter_ns
);

parameter DELAY = 2;


//reg [28:0]  counter;
reg [15:0] counter_lo;
reg [13:0] counter_hi;

always @(posedge clk or negedge rst_n)    
begin
      if (~rst_n)begin                           
            //  counter <=#DELAY 0;
            counter_lo  <=#DELAY 0;
            counter_hi  <=#DELAY 0;
      end                    
      else begin                 
            // counter <=#DELAY counter+1;  
            counter_lo  <=#DELAY counter_lo+1;
            if(&(counter_lo))
            counter_hi  <=#DELAY counter_hi+1;
      end
end

// assign  counter_ns = (counter<<2)+counter; // counter_ns=counter*5
// assign  counter_ns = (counter << 2);
assign counter_ns = {counter_hi, counter_lo, 2'b0};

endmodule
