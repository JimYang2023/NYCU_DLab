`timescale 1ns / 1ps


module alu(
    // DO NOT modify the interface!
    // input signal
    input [7:0] accum,
    input [7:0] data,
    input [2:0] opcode,
    input reset,
    
    // result
    output [7:0] alu_out,
    
    // PSW
    output zero,
    output overflow,
    output parity,
    output sign
    );
    
    parameter num_max = 8'b01111111;
    parameter num_min = 8'b10000000;
    reg [7:0]out;
    reg test_overflow;
    assign alu_out = (overflow)?(accum[7]? num_min : num_max ):out;
    assign zero = ~|(alu_out);
    assign parity = (alu_out[7]^alu_out[6]^alu_out[5]^alu_out[4]^alu_out[3]^alu_out[2]^alu_out[1]^alu_out[0]);
    assign sign = alu_out[7];
    assign overflow = test_overflow;
    
    //change the sign of 8-bit number 
    function [7:0] flip_sign;
        input [7:0] num;
        begin
            flip_sign = (num ^ {8{1'b1}}) + 1 ;
        end
    endfunction
    function [3:0] flip_sign_4bits;
        input [3:0] num;
        begin
            flip_sign_4bits =((num[3])?((num ^ {4{1'b1}})+1):num);
        end
    endfunction
    
    
    always @(*)begin
        if(reset)begin
            out <= 0;
            test_overflow <= 0;
        end
        else begin
            case(opcode)
                3'bxxx:out <= 0;
                3'b000:out <= accum;
                3'b001:begin    
                    out <= accum + data;
                    // overflow
                    //case1 : pos_num + pos_num = neg_num -> upperflow
                    //case2 : neg_num + neg_num = pos_num -> underflow
                    if(accum[7] == data[7] & accum[7] != out[7])begin
                        test_overflow <= 1;
                    end
                    else begin
                        test_overflow <= 0;
                    end
                end
                3'b010:begin    
                    out <= accum - data;
                    //overflow 
                    //case1 : pos_num - neg_num = neg_num -> upperflow
                    //case2 : neg_num - pos_num = pos_num -> underflow
                    if(accum[7] != data[7] & accum[7] != out[7])begin
                        test_overflow <= 1;
                    end
                    else begin
                        test_overflow <= 0;
                    end 
                end     
                3'b011:out <= accum >>> data;
                3'b100:out <= accum ^ data;     
                3'b101:out <= (accum[7])?flip_sign(accum):accum ;
                3'b110:begin
                    if(accum[3]==0 && data[3]==0)begin
                        out <= accum[3]*data[3];
                    end      
                    else if(accum[3]==1 && data[3]==0)begin
                        out <= flip_sign(flip_sign_4bits(accum[3:0])*data[3:0]);
                    end
                    else if(accum[3]==0 && data[3]==1)begin
                        out <= flip_sign(accum[3:0] * flip_sign_4bits(data[3:0]));
                    end
                    else begin
                        out <= flip_sign_4bits(accum[3:0])*flip_sign_4bits(data[3:0]);
                    end
                end
                3'b111:out <= flip_sign(accum);
            endcase
            // overflow 
            if(~(opcode == 3'b001 | opcode == 3'b010))begin 
                test_overflow <= 0;
            end
        end           
    end
endmodule
