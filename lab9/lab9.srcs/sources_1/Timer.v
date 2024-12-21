`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 14:29:44
// Design Name: 
// Module Name: Timer
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

module timer(
    input clk,
    input reset_n,
    input signal,
    output [55:0]result);
    
reg [55:0]time_cnt;
assign result = time_cnt;

always @(posedge clk)begin
    if(~reset_n)begin
        time_cnt <= 55'b0;
    end else if(signal) begin
        time_cnt <= time_cnt + 1;
    end
end 
endmodule