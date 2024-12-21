`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);
    
    //PWM
    parameter [31:0] duty_5 = 32'd50000;
    parameter [31:0] duty_25 =32'd250000;
    parameter [31:0] duty_50 = 32'd500000;
    parameter [31:0] duty_75 = 32'd750000;
    parameter [31:0] duty_100 = 32'd1000000;
    reg signal;  // PWM signal
    reg [2:0] duty_state;
    reg [31:0] pwm_counter;
    
    //debounce module
    wire [3:0] db_btn;
    debounce d1(.btn_in(usr_btn[0]), .clk(clk) , .reset_n(reset_n) , .btn_out(db_btn[0]));
    debounce d2(.btn_in(usr_btn[1]), .clk(clk) , .reset_n(reset_n) , .btn_out(db_btn[1]));
    debounce d3(.btn_in(usr_btn[2]), .clk(clk) , .reset_n(reset_n) , .btn_out(db_btn[2]));
    debounce d4(.btn_in(usr_btn[3]), .clk(clk) , .reset_n(reset_n) , .btn_out(db_btn[3]));
        
    //gray code control
    reg [3:0] binary_code;
    wire [3:0] gray_code;
    // gray code
    /*
        0000 -> 0001 -> 0011 -> 0010 -> 
        0110 -> 0111 -> 0101 -> 0100 -> 
        1100 -> 1101 -> 1111 -> 1110 -> 
        1010 -> 1011 -> 1001 -> 1000
        
        the method of binary changing to gray code : g[i] = b[i] ^ b[i+1] 
    */
    function [3:0] binary_to_gray;
        input [3:0] cur;
        begin
            binary_to_gray[3] = cur[3];
            binary_to_gray[2] = cur[2]^cur[3];
            binary_to_gray[1] = cur[1]^cur[2];
            binary_to_gray[0] = cur[0]^cur[1]; 
        end
    endfunction
    
    //
    assign usr_led = gray_code & {4{signal}};
    assign gray_code = binary_to_gray(binary_code);
    
    //LED Control
    always @(posedge clk or negedge reset_n)begin
        if(~reset_n)begin
            binary_code <= 4'b0000;
            duty_state <= 3'b000;
            pwm_counter <= 32'd0;
            signal <= 1'b0;
        end
        else begin
            if(db_btn[0] & binary_code != 4'b0000)begin
                binary_code <= binary_code - 4'b0001;
            end
            else if(db_btn[1] & binary_code != 4'b1111)begin
                binary_code <= binary_code + 4'b0001;
            end        
            
            //duty control
            if(db_btn[3] & duty_state != 3'b000)begin
                duty_state <= duty_state - 1;
            end 
            else if(db_btn[2] & duty_state != 3'b100)begin
                duty_state <= duty_state + 1;
            end           
            //PWM
            if(pwm_counter == 32'd1000000)begin
                pwm_counter <= 0;
            end
            else begin
                pwm_counter <= pwm_counter + 1'd1;        
            end
            case(duty_state)
                3'b000:signal <= (pwm_counter >= duty_5 )? 0:1;
                3'b001:signal <= (pwm_counter >= duty_25 )? 0:1;
                3'b010:signal <= (pwm_counter >= duty_50 )? 0:1;
                3'b011:signal <= (pwm_counter >= duty_75 )? 0:1;
                3'b100:signal <= (pwm_counter >= duty_100 )? 0:1;
                default: signal <= (pwm_counter >= duty_50 )? 0:1;
            endcase
        end
    end 
endmodule

module debounce(input btn_in, input clk, input reset_n, output btn_out);
    reg [1:0]out;
    reg [31:0] count;
    assign btn_out = (out == 2'b01) ? out[0] : 0;
    always @(posedge clk or negedge reset_n)begin
        if(~reset_n)begin
            out <= 2'b00;
            count <= 32'd0;
        end    
        else begin
            if( out[0] == btn_in)begin
                count <= 32'd0;
                out <= out << 1;                
            end
            else begin
                count <= count + 32'd1;
                if(count == 32'd500000)begin  //wait 0.005 second and store input
                    out[0] <= (out<<1) + btn_in;
                    count <= 32'd0;
                end
            end 
        end
    end
endmodule

