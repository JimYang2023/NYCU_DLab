`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/16 17:50:28
// Design Name: 
// Module Name: mmult
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


module mmult(
  input  clk,                 // Clock signal.
  input  reset_n,             // Reset signal (negative logic).
  input  enable,              // Activation signal for matrix                              //   multiplication (tells the circuit                              //   that A and B are ready for use).
  input  [0:9*8-1] A_mat,     // A matrix.
  input  [0:9*8-1] B_mat,     // B matrix.

  output valid,               // Signals that the output is valid to read.
  output reg [0:9*18-1] C_mat // The result of A x B.
);
    reg [0:7] A[0:2][0:2];
    reg [0:7] B[0:2][0:2];
    reg [0:17] C[0:2][0:2];
    
    reg [1:0] counter;
    reg fin;
    wire check;
    assign valid = fin;
    assign check = |(counter ^ 2'b11);
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            {A[0][0],A[0][1],A[0][2],A[1][0],A[1][1],A[1][2],A[2][0],A[2][1],A[2][2]} <= A_mat;
            {B[0][0],B[0][1],B[0][2],B[1][0],B[1][1],B[1][2],B[2][0],B[2][1],B[2][2]} <= B_mat;
            {C[0][0],C[0][1],C[0][2],C[1][0],C[1][1],C[1][2],C[2][0],C[2][1],C[2][2]} <= 0;
            counter <= 0;
            fin <= 0;
            C_mat <= 0;
        end
        else if(enable)begin
            if( check )begin
                C[0][counter] <= (C[0][counter]+( (A[0][0] * B[0][counter])+(A[0][1] * B[1][counter]) +(A[0][2] * B[2][counter])) );
                C[1][counter] <= (C[1][counter]+( (A[1][0] * B[0][counter])+(A[1][1] * B[1][counter]) +(A[1][2] * B[2][counter])) ); 
                C[2][counter] <= (C[2][counter]+( (A[2][0] * B[0][counter])+(A[2][1] * B[1][counter]) +(A[2][2] * B[2][counter])) );
                counter <= (counter + 1);
            end
            else begin       
                //$display ("\nMatrix C is input to C_mat\n");
                C_mat <= {C[0][0],C[0][1],C[0][2],C[1][0],C[1][1],C[1][2],C[2][0],C[2][1],C[2][2]};         
                fin <= 1'b1;
            end            
        end
    end    
endmodule
