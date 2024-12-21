`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 14:05:42
// Design Name: 
// Module Name: SHA_256
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


module SHA_256(
    input clk,
    input reset_n,
    input start_signal,
    input [511:0] message,
    output [255:0] ans,
    output count_done
);
//for cycle constant
integer i;

localparam [7:0] w_cnt_max = 64;
localparam [7:0] h_cnt_max = 64;

localparam [2:0] SHA_MAIN_INIT  = 3'b000,
                 SHA_MAIN_CREATE_W = 3'b001, 
                 SHA_MAIN_COUNT = 3'b010, 
                 SHA_MAIN_DONE  = 3'b011;

localparam [31:0] h0 = 32'h6a09e667, h1 = 32'hbb67ae85, h2 = 32'h3c6ef372, h3 = 32'ha54ff53a,
                  h4 = 32'h510e527f, h5 = 32'h9b05688c, h6 = 32'h1f83d9ab, h7 = 32'h5be0cd19;


reg [2:0] SHA_P , SHA_P_next;
reg [31:0] W[0:63];
reg [31:0] a,b,c,d,e,f,g,h;
reg [255:0] r_ans;
reg [31:0] t1,t2;
reg  count_control;
reg [7:0] h_cnt;
reg [7:0] w_cnt;
wire [31:0] k [0:63];


//assign
assign crate_w_done = (w_cnt == w_cnt_max);
assign ans = r_ans;
assign count_done = ( SHA_P ==S_MAIN_DONE || (SHA_P_next == SHA_MAIN_INIT && ~start_signal ));

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

//function
function [31:0]s0;
    input [31:0]x;
begin
    s0 = {x[6:0],x[31:7]}^{x[17:0],x[31:18]}^{3'h0,x[31:3]};
end
endfunction

function [31:0]s1;
    input [31:0]x;
begin
    s1 = {x[16:0],x[31:17]} ^ {x[18:0],x[31:19]} ^ {10'h0,x[31:10]};
end
endfunction

function [31:0]maj;
    input [31:0] a,b,c;
begin
    maj = (a&b)^(a&c)^(b&c);
end
endfunction

function [31:0]ch;
    input [31:0] a,b,c;
begin
    ch = (a&b)^((~a)&c);
end
endfunction

function [31:0]S0;
    input [31:0]x;
begin
    S0 = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
end
endfunction

function [31:0]S1;
    input [31:0]x;
begin
    S1 = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
end
endfunction

always @(posedge clk)begin
    if(~reset_n) SHA_P <= SHA_MAIN_INIT;
    else SHA_P <= SHA_P_next;
end 

always @(posedge clk)begin
    case(SHA_P)
    SHA_MAIN_INIT: SHA_P_next =( (start_signal)?SHA_MAIN_CREATE_W:SHA_MAIN_INIT);
    SHA_MAIN_CREATE_W: SHA_P_next =( (w_cnt == w_cnt_max)?SHA_MAIN_COUNT:SHA_MAIN_CREATE_W);
    SHA_MAIN_COUNT: SHA_P_next =( (h_cnt == h_cnt_max)?SHA_MAIN_DONE:SHA_MAIN_COUNT);
    SHA_MAIN_DONE: SHA_P_next = SHA_MAIN_INIT;
    default: SHA_P_next = SHA_MAIN_INIT;
    endcase
end 


//W
always @(posedge clk)begin
    if(~reset_n || SHA_P==SHA_MAIN_INIT)begin
        w_cnt <= 16;
    end else if(SHA_P==SHA_MAIN_CREATE_W)begin        
        w_cnt <= (w_cnt == w_cnt_max)? w_cnt : w_cnt + 1;
    end
end 

always @(posedge clk)begin 
    if(~reset_n)begin
        for(i=0;i<64;i=i+1)begin
            W[i] <= 0;        
        end
    end else if(SHA_P_next == SHA_MAIN_CREATE_W && SHA_P == SHA_MAIN_INIT) begin
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
    end else if(SHA_P==SHA_MAIN_CREATE_W && w_cnt < w_cnt_max)begin
        W[w_cnt] <= W[w_cnt-16] + W[w_cnt-7]+ s0(W[w_cnt-15])+ s1(W[w_cnt-2]);
    end
end

//H
always @(posedge clk)begin
    if(~reset_n || SHA_P==SHA_MAIN_INIT)begin
        h_cnt <= 0;
        count_control <= 0;
    end else if(SHA_P==SHA_MAIN_COUNT)begin
        h_cnt <= (h_cnt == h_cnt_max)? h_cnt : h_cnt + count_control;
        count_control <= ~count_control;
    end
end 

always @(posedge clk)begin
    if(~reset_n || (SHA_P==SHA_MAIN_INIT && SHA_P_next == SHA_MAIN_CREATE_W ) )begin
        t1 <= 0;    
        t2 <= 0;
        a <= h0;    
        b <= h1;    
        c <= h2; 
        d <= h3; 
        e <= h4;    
        f <= h5;    
        g <= h6; 
        h <= h7;
    end else if(SHA_P==SHA_MAIN_COUNT) begin
        if(count_control)begin
            a <= t1 + t2;    
            b <= a;    
            c <= b; 
            d <= c; 
            e <= d + t1;    
            f <= e;    
            g <= f; 
            h <= g;
        end else begin
            t1 <= h+S1(e)+ch(e,f,g)+k[h_cnt]+W[h_cnt];
            t2 <= S0(a) + maj(a,b,c);
        end
    end
end 


always @(posedge clk)begin
    if(~reset_n)begin
        r_ans <= 256'b0;
    end else if(SHA_P_next == SHA_MAIN_DONE) begin
        r_ans <= {h0+a,h1+b,h2+c,h3+d,h4+e,h5+f,h6+g,h7+h};
    end
end

endmodule