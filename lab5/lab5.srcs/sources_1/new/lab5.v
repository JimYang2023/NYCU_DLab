`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,      // button 
  input [3:0] usr_sw,       // switches
  output [3:0] usr_led,     // led
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

assign usr_led = 4'b0000; // turn off led

reg [127:0] row_A = "                "; // Initialize the text of the first row. 
reg [127:0] row_B = "                "; // Initialize the text of the second row.

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

//debounce
wire [3:0] db_sw;
debounce db1(.clk(clk),.reset_n(reset_n),.sw_in(usr_sw[0]),.sw_out(db_sw[0]));
debounce db2(.clk(clk),.reset_n(reset_n),.sw_in(usr_sw[1]),.sw_out(db_sw[1]));
debounce db3(.clk(clk),.reset_n(reset_n),.sw_in(usr_sw[2]),.sw_out(db_sw[2]));
debounce db4(.clk(clk),.reset_n(reset_n),.sw_in(usr_sw[3]),.sw_out(db_sw[3]));

//game setting 
reg check_game_end;
reg error_game;
reg [3:0] pre_sw;

//counter
wire [3:0] cur_num_1;
wire [3:0] cur_num_2;
wire [3:0] cur_num_3;
wire [3:0] next_num_1;
wire [3:0] next_num_2;
wire [3:0] next_num_3;

counter_1 cnt1(.clk(clk),.signal(~db_sw[0] & db_sw[3] & check_game_end),.reset_n(reset_n),.count_out(cur_num_1),.next_out(next_num_1));
counter_2 cnt2(.clk(clk),.signal(~db_sw[0] & db_sw[2] & check_game_end),.reset_n(reset_n),.count_out(cur_num_2),.next_out(next_num_2));
counter_3 cnt3(.clk(clk),.signal(~db_sw[0] & db_sw[1] & check_game_end),.reset_n(reset_n),.count_out(cur_num_3),.next_out(next_num_3));
//assign usr_led = cur_num_2;

always @(posedge clk or negedge reset_n)begin
    if(~reset_n)begin
        check_game_end <= 1'b1;
        error_game <= 1'b0; 
        pre_sw <= 4'b1111;       
    end else begin
        if(check_game_end)begin
            row_A <= {"     |",8'b00110000 + next_num_1,"|",8'b00110000 + next_num_2,"|",8'b00110000 + next_num_3,"|    "};
            row_B <= {"     |",8'b00110000 + cur_num_1,"|",8'b00110000 + cur_num_2,"|",8'b00110000 + cur_num_3,"|    "}; 
            if(db_sw == 4'b0000)begin
                check_game_end <= ~check_game_end;
            end else if(db_sw[0] == 1 & (db_sw[1] & db_sw[2] & db_sw[3]) == 0 )begin
                error_game <= 1'b1;
                check_game_end <= ~check_game_end;
            end else if((pre_sw[0] == 0 & db_sw[0] == 1)|(pre_sw[1] == 0 & db_sw[1] == 1)|(pre_sw[2] == 0 & db_sw[2] == 1)|(pre_sw[3] == 0 & db_sw[3] == 1))begin
                error_game <= 1'b1;
                check_game_end <= ~check_game_end;
            end
            pre_sw <= db_sw;
        end
        else begin
            if(error_game)begin
                row_A <= "      ERROR     ";
                row_B <= "  game stopped  ";
            end else begin
                if(cur_num_1 == cur_num_2 & cur_num_2 == cur_num_3)begin
                    row_A <= "    Jackpots!   "; 
                end else if(cur_num_1 == cur_num_2 | cur_num_2 == cur_num_3 || cur_num_1 == cur_num_3)begin
                    row_A <= "   Free Game!   ";
                end else begin
                    row_A <= "     Loser!     ";
                end            
                row_B <= "    Game over   ";            
            end
        end
    end
end

endmodule

//debounce
module debounce(input clk,input reset_n,input sw_in,output sw_out);
    reg [31:0] count ;
    reg out;
    assign sw_out = out;
    always @(posedge clk or negedge reset_n)begin
        if(~reset_n)begin
           count <= 32'd0;
           out <= 1'b1; 
        end
        else begin
            if(sw_out == sw_in)begin
                count <= 32'd0;
            end 
            else begin
                count <= count + 32'd1;
                if(count == 32'd500_000)begin
                    out <= sw_in;
                    count <= 32'd0; 
                end       
            end
        end
    end
endmodule

//1,2,3,4,5,6,7,8,9
module counter_1(
    input clk,
    input signal,
    input reset_n,
    output [3:0] count_out,
    output [3:0] next_out
);
reg [3:0] out;
reg [31:0] cnt;
assign count_out = out;
assign next_out = (out == 4'b1001)?4'b0001:out+4'b0001;
always @(posedge clk or negedge reset_n)begin
    if(~reset_n)begin
        out <= 4'b0001;
        cnt <= 32'd0;
    end
    else begin
        if(signal)begin
            cnt <= cnt + 32'd1; 
            if(cnt == 32'd100_000_000)begin
                out <= (out == 4'b1001)?4'b0001:out+4'b0001; 
                cnt <= 32'd0;
            end
        end
    end
end
endmodule

//9,8,7,6,5,4,3,2,1
module counter_2(
    input clk,
    input signal,
    input reset_n,
    output [3:0] count_out,
    output [3:0] next_out
);
reg [3:0] out;
reg [31:0]cnt ;
assign count_out = out;
assign next_out = (out == 4'b0001)?4'b1001:out-4'b0001;
always @(posedge clk or negedge reset_n)begin
    if(~reset_n)begin
        out <= 4'b1001;
        cnt <= 32'd0;   
    end
    else begin
        if(signal)begin
            cnt <= cnt + 1'b1;
            if(cnt == 32'd200_000_000)begin
                cnt <= 32'd0;
                out <= (out == 4'b0001)?4'b1001:out-4'b0001; 
            end        
        end
    end
end
endmodule

//1,3,5,7,9,2,4,6,8
module counter_3(
    input clk,
    input signal,
    input reset_n,
    output [3:0] count_out,
    output [3:0] next_out
);
reg [3:0] out;
reg [31:0] cnt;
assign count_out = out;
assign next_out = ( out == 4'b1001)? 4'b0010: ( out == 4'b1000 )? 4'b0001: out + 4'b0010;
always @(posedge clk or negedge reset_n)begin
    if(~reset_n)begin
        out <= 4'b0001;
        cnt <= 32'd0;
    end
    else begin
        if(signal)begin
            cnt <= cnt + 32'd1;
            if(cnt == 32'd100_000_000)begin
                cnt <= 32'd0;
                out <= ( out == 4'b1001)? 4'b0010: ( out == 4'b1000 )? 4'b0001: out + 4'b0010;
            end        
        end
    end
end
endmodule

