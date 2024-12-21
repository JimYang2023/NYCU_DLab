`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab9(
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

integer i;

assign usr_led = 4'b0000; // turn off led

reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.

localparam [2:0] S_MAIN_INIT = 3'b000,
                 S_MAIN_WAIT  = 3'b001,
                 S_MAIN_SHOW = 3'b010,
                 S_MAIN_CHECK= 3'b011,
                 S_MAIN_COUNT = 3'b100;
reg [2:0] P , P_next;


//---------------------------------------------
//SHA_256
reg [3:0] password[0:8]; 
//reg [255:0] passwd_hash = 256'hf120bb5698d520c5691b6d603a00bfd662d13bf177a04571f9d10c0745dfa2a5; //000000000
//reg [255:0] passwd_hash = 256'h7e09d41e8e1979275e2bf8aa6a2f0fab4637d096fede31226bbbd5e2774072f5;  //000000001
//reg [255:0] passwd_hash = 256'h66d4cf43c9131bcc7e572303efa765204073f9ed4396581a153ba103766c7414; //001000000
reg [255:0] passwd_hash = 256'he59bbea6227c578f97fc467bc62dc3407d4885693d74e6e970f6cab44158fef4; //1000000000
//reg [255:0] passwd_hash = 256'hf6adf7a153fe960a525aa206fbcb527278f6adf1ab148947a066f97ef054cf67; //345123222
//reg [255:0] passwd_hash = 256'he7acadece807f3ede9fef4c9a3ecdb3f430797c41c3fa66aec1a65c421a3a835; //999999998
//reg [255:0] passwd_hash = 256'hbb421fa35db885ce507b0ef5c3f23cb09c62eb378fae3641c165bdf4c0272949; //999999999

localparam [7:0] w_cnt_max = 66;
localparam [31:0] h0 = 32'h6a09e667, h1 = 32'hbb67ae85, h2 = 32'h3c6ef372, h3 = 32'ha54ff53a,
                  h4 = 32'h510e527f, h5 = 32'h9b05688c, h6 = 32'h1f83d9ab, h7 = 32'h5be0cd19;

reg [511:0] message;
reg [255:0] r_ans;
reg [31:0] W[0:63];
reg [31:0] a,b,c,d,e,f,g,h;
reg [7:0] w_cnt;
wire [31:0] k [0:63];

//
// W Counter with Buffering
reg w_cnt_control;
reg [31:0]t1,t2;
reg [31:0] W_stage1, W_stage2;
//


//---------------------------------------------

//wait
localparam wait_cnt_max = 2;
reg [31:0] wait_cnt ;

//timer
reg [55:0] timer;

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

//---------------------------------------------------------------------
assign k[ 0] = 32'h428a2f98;
assign k[ 1] = 32'h71374491;
assign k[ 2] = 32'hb5c0fbcf;
assign k[ 3] = 32'he9b5dba5;
assign k[ 4] = 32'h3956c25b;
assign k[ 5] = 32'h59f111f1;
assign k[ 6] = 32'h923f82a4;
assign k[ 7] = 32'hab1c5ed5;
assign k[ 8] = 32'hd807aa98;
assign k[ 9] = 32'h12835b01;
assign k[10] = 32'h243185be;
assign k[11] = 32'h550c7dc3;
assign k[12] = 32'h72be5d74;
assign k[13] = 32'h80deb1fe;
assign k[14] = 32'h9bdc06a7;
assign k[15] = 32'hc19bf174;
assign k[16] = 32'he49b69c1;
assign k[17] = 32'hefbe4786;
assign k[18] = 32'h0fc19dc6;
assign k[19] = 32'h240ca1cc;
assign k[20] = 32'h2de92c6f;
assign k[21] = 32'h4a7484aa;
assign k[22] = 32'h5cb0a9dc;
assign k[23] = 32'h76f988da;
assign k[24] = 32'h983e5152;
assign k[25] = 32'ha831c66d;
assign k[26] = 32'hb00327c8;
assign k[27] = 32'hbf597fc7;
assign k[28] = 32'hc6e00bf3;
assign k[29] = 32'hd5a79147;
assign k[30] = 32'h06ca6351;
assign k[31] = 32'h14292967;
assign k[32] = 32'h27b70a85;
assign k[33] = 32'h2e1b2138;
assign k[34] = 32'h4d2c6dfc;
assign k[35] = 32'h53380d13;
assign k[36] = 32'h650a7354;
assign k[37] = 32'h766a0abb;
assign k[38] = 32'h81c2c92e;
assign k[39] = 32'h92722c85;
assign k[40] = 32'ha2bfe8a1;
assign k[41] = 32'ha81a664b;
assign k[42] = 32'hc24b8b70;
assign k[43] = 32'hc76c51a3;
assign k[44] = 32'hd192e819;
assign k[45] = 32'hd6990624;
assign k[46] = 32'hf40e3585;
assign k[47] = 32'h106aa070;
assign k[48] = 32'h19a4c116;
assign k[49] = 32'h1e376c08;
assign k[50] = 32'h2748774c;
assign k[51] = 32'h34b0bcb5;
assign k[52] = 32'h391c0cb3;
assign k[53] = 32'h4ed8aa4a;
assign k[54] = 32'h5b9cca4f;
assign k[55] = 32'h682e6ff3;
assign k[56] = 32'h748f82ee;
assign k[57] = 32'h78a5636f;
assign k[58] = 32'h84c87814;
assign k[59] = 32'h8cc70208;
assign k[60] = 32'h90befffa;
assign k[61] = 32'ha4506ceb;
assign k[62] = 32'hbef9a3f7;
assign k[63] = 32'hc67178f2;

function [31:0]s0;
    input [31:0]x;
begin
    s0 = {x[6:0],x[31:7]}^{x[17:0],x[31:18]}^{3'h0,x[31:3]};
end
endfunction

function [31:0]s1;
    input [31:0]x;
    s1 = {x[16:0],x[31:17]} ^ {x[18:0],x[31:19]} ^ {10'h0,x[31:10]};
endfunction

function [31:0]maj;
    input [31:0] a,b,c;
    maj = (a&b)^(a&c)^(b&c);
endfunction

function [31:0]ch;
    input [31:0] a,b,c;
    ch = (a&b)^((~a)&c);
endfunction

function [31:0]S0;
    input [31:0]x;
    S0 = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
endfunction

function [31:0]S1;
    input [31:0]x;
    S1 = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
endfunction
//---------------------------------------------------------------------

//staet control
always @(posedge clk)begin
    if(~reset_n) P <= S_MAIN_INIT;    
    else P <= P_next;
end

always @(*)begin
    case(P)
        S_MAIN_INIT: P_next <= (usr_btn[3])?S_MAIN_WAIT:S_MAIN_INIT ;
        S_MAIN_WAIT: P_next <= (wait_cnt==wait_cnt_max)?S_MAIN_COUNT:S_MAIN_WAIT;  
        S_MAIN_COUNT: P_next <= (w_cnt == w_cnt_max)?S_MAIN_CHECK:S_MAIN_COUNT;
        S_MAIN_CHECK: P_next <= (r_ans==passwd_hash)?S_MAIN_SHOW:S_MAIN_WAIT;
        S_MAIN_SHOW: P_next <= S_MAIN_SHOW;
    endcase
end

//timer control
always @(posedge clk or negedge reset_n) begin
    if(~reset_n || P==S_MAIN_INIT) timer <= 0;
    else timer <= (P==S_MAIN_SHOW)? timer: timer+1 ;
end
    
always @(posedge clk) begin
  if (~reset_n || P==S_MAIN_INIT) begin
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
  end else begin
    row_A <= {"Pwd:",password[0]+"0",password[1]+"0",password[2]+"0",password[3]+"0",password[4]+"0",
                     password[5]+"0",password[6]+"0",password[7]+"0",password[8]+"0","   "};
    row_B <= {"T:",((timer[55:52]>9)?"7":"0")+timer[55:52],((timer[51:48]>9)?"7":"0")+timer[51:48],
                   ((timer[47:44]>9)?"7":"0")+timer[47:44],((timer[43:40]>9)?"7":"0")+timer[43:40],
                   ((timer[39:36]>9)?"7":"0")+timer[39:36],((timer[35:32]>9)?"7":"0")+timer[35:32],
                   ((timer[31:28]>9)?"7":"0")+timer[31:28],((timer[27:24]>9)?"7":"0")+timer[27:24],
                   ((timer[23:20]>9)?"7":"0")+timer[23:20],((timer[19:16]>9)?"7":"0")+timer[19:16],
                   ((timer[15:12]>9)?"7":"0")+timer[15:12],((timer[11: 8]>9)?"7":"0")+timer[11: 8],
                   ((timer[ 7: 4]>9)?"7":"0")+timer[ 7: 4],((timer[ 3: 0]>9)?"7":"0")+timer[ 3: 0]};
  end
end

//message control
always @(posedge clk) begin
    if (~reset_n) begin
        message = 512'b0;
    end else if (P == S_MAIN_WAIT) begin
        message <= {
            password[0] + 8'h30, password[1] + 8'h30, password[2] + 8'h30,
            password[3] + 8'h30, password[4] + 8'h30, password[5] + 8'h30,
            password[6] + 8'h30, password[7] + 8'h30, password[8] + 8'h30,
            1'b1, 375'b0, 64'd72
        };
    end
end

//
localparam [31:0] number_max = 32'd1000000000;
reg [31:0] number_cnt;
always @(posedge clk)begin
    if(~reset_n)begin
        for(i=0;i<9;i=i+1)begin
            password[i] <= 0;
        end
        number_cnt <= 0;
    end else if(P==S_MAIN_CHECK && P_next == S_MAIN_WAIT && number_cnt < number_max) begin
        number_cnt <= (number_cnt == number_max)? number_cnt:number_cnt + 1;
        if(password[8] == 9)begin password[8] <= 0;
            if(password[7]==9)begin password[7] <= 0;
                if(password[6]==9)begin password[6] <= 0;
                    if(password[5]==9)begin password[5] <=0;
                        if(password[4]==9)begin password[4] <= 0;
                            if(password[3]==9)begin password[3] <= 0;
                                if(password[2]==9)begin password[2] <= 0;
                                    if(password[1]==9)begin password[1] <= 0;
                                        if(password[0]==9)begin
                                           password[0] <= 0;
                                        end else password[0] <= password[0]+1;
                                    end else password[1] <= password[1]+1;
                                end else password[2] <= password[2]+1;
                            end else password[3] <= password[3]+1;
                        end else password[4] <= password[4]+1;
                    end else password[5] <= password[5]+1;
                end else password[6] <= password[6]+1;
            end else password[7] <= password[7]+1;
        end else password[8] <= password[8]+1;
    end
end

// Wait Counter
always @(posedge clk) begin
    if (~reset_n || P != S_MAIN_WAIT) begin
        wait_cnt <= 0;
    end else begin
        wait_cnt <= (wait_cnt == wait_cnt_max) ? wait_cnt : wait_cnt + 1;
    end
end


always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_WAIT) begin
        w_cnt <= 1;
        w_cnt_control <= 0;
    end else if (P == S_MAIN_COUNT) begin        
        w_cnt <= (w_cnt == w_cnt_max) ? w_cnt : w_cnt + w_cnt_control;
        w_cnt_control <= ~w_cnt_control;
    end
end

always @(posedge clk) begin 
    if (~reset_n) begin
        for (i = 0; i < 64; i = i + 1) W[i] <= 0;
    end else if (P_next == S_MAIN_COUNT && P == S_MAIN_WAIT) begin
        // Load initial message into W[0:15]
        W[ 0] <= message[511:480];
        W[ 1] <= message[479:448];
        W[ 2] <= message[447:416];
        W[ 3] <= message[415:384];
        W[ 4] <= message[383:352];
        W[ 5] <= message[351:320];
        W[ 6] <= message[319:288];
        W[ 7] <= message[287:256];
        W[ 8] <= message[255:224];
        W[ 9] <= message[223:192];
        W[10] <= message[191:160];
        W[11] <= message[159:128];
        W[12] <= message[127: 96];
        W[13] <= message[ 95: 64];
        W[14] <= message[ 63: 32];
        W[15] <= message[ 31:  0];
        W_stage1 <= 0;
        W_stage2 <= 0;
    end else if (P == S_MAIN_COUNT && w_cnt < w_cnt_max - 2 && w_cnt >= 16) begin
        if (~w_cnt_control) begin
            W_stage1 <= W[w_cnt - 16] + W[w_cnt - 7];
            W_stage2 <= s0(W[w_cnt - 15]) + s1(W[w_cnt - 2]);
        end else begin
            W[w_cnt] <= W_stage1 + W_stage2;
        end
    end
end

// Registers t1 and t2 with Correct Handling
always @(posedge clk) begin
    if (~reset_n || (P == S_MAIN_WAIT && P_next == S_MAIN_COUNT)) begin
        t1 <= 0;
        t2 <= 0;
    end else if (P == S_MAIN_COUNT && w_cnt > 0 && w_cnt < w_cnt_max-1) begin
        if (~w_cnt_control) begin
            t1 <= h + S1(e) + ch(e, f, g) + k[w_cnt- 1] + W[w_cnt - 1];
            t2 <= S0(a) + maj(a, b, c);
        end
    end
end

// Update Registers a, b, c, d, e, f, g, h
always @(posedge clk) begin
    if (~reset_n || (P == S_MAIN_WAIT && P_next == S_MAIN_COUNT)) begin
        a <= h0;
        b <= h1;
        c <= h2;
        d <= h3;
        e <= h4;
        f <= h5;
        g <= h6;
        h <= h7;
    end else if (P == S_MAIN_COUNT && w_cnt > 1 && w_cnt < w_cnt_max) begin
        h <= g;
        g <= f;
        f <= e;
        e <= d + t1;
        d <= c;
        c <= b;
        b <= a;
        a <= t1 + t2;
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        r_ans <= 256'b0;
    end else if(P_next == S_MAIN_CHECK) begin
        r_ans <= {h0+a,h1+b,h2+c,h3+d,h4+e,h5+f,h6+g,h7+h};
    end
end

endmodule