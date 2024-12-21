`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  input uart_rx,
  output uart_tx
);

//main state
localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_ADDR = 3'b001, 
                 S_MAIN_READ = 3'b010, S_MAIN_POOL = 3'b011, 
                 S_MAIN_MUL  = 3'b100, S_MAIN_SHOW = 3'b101, 
                 S_MAIN_WAIT = 3'b111;
                 
// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [2:0]  P, P_next;
reg  [11:0] user_addr;
reg  [7:0]  user_data;
reg  [7:0]  user_data1;

reg  [127:0] row_A = "                ", 
             row_B = "                ";

// declare SRAM control signals
wire [10:0] sram_addr , sram_addr1;
wire [7:0]  data_in;
wire [7:0]  data_out , data_out1;
wire        sram_we, sram_en;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte; 
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_receiving;
wire is_transmitting;
wire recv_error;
wire init_end, addr_end, read_data_end, pool_end, mul_end, sent_end; 

//UART
localparam  start = 33;
localparam  msg_len = 201;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1, S_UART_SEND = 2, S_UART_INCR = 3; 
reg [0:8*msg_len-1] msg = {"\015\012The matrix operation result is:\015\012[00000,00000,00000,00000,00000]\015\012[00000,00000,00000,00000,00000]\015\012[00000,00000,00000,00000,00000]\015\012[00000,00000,00000,00000,00000]\015\012[00000,00000,00000,00000,00000]\015\012",8'h0};
reg [1:0] Q , Q_next;
reg [$clog2(msg_len):0] send_counter;
wire print_enable;
wire print_done;
reg [7:0] data[0:msg_len-1];

//matrix A , B and pooled A , B 
reg [7:0] matA[0:6][0:6];
reg [7:0] matB[0:6][0:6];
reg [7:0] matA_p [0:4][0:4];
reg [7:0] matB_p [0:4][0:4];

//led
assign usr_led = 4'h00;

//max
wire [7:0] nums[0:8];
wire [7:0] max_num;
reg  [7:0] nums_r[0:8];
assign nums[0]=nums_r[0];
assign nums[1]=nums_r[1];
assign nums[2]=nums_r[2];
assign nums[3]=nums_r[3];
assign nums[4]=nums_r[4];
assign nums[5]=nums_r[5];
assign nums[6]=nums_r[6];
assign nums[7]=nums_r[7];
assign nums[8]=nums_r[8];




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
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

//max module
max pool_max(.clk(clk),.num1(nums[0]),.num2(nums[1]),.num3(nums[2]),
                       .num4(nums[3]),.num5(nums[4]),.num6(nums[5]),
                       .num7(nums[6]),.num8(nums[7]),.num9(nums[8]),.out(max_num));

// Enable one cycle of btn_pressed per each button hit
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

//sram
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),.addr(sram_addr), .data_i(data_in), .data_o(data_out));
sram ram1(.clk(clk), .we(sram_we), .en(sram_en),.addr(sram_addr1), .data_i(data_in), .data_o(data_out1));          

assign sram_we = usr_btn[3];
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign sram_addr1 = user_addr[11:0]+49;
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
        if(init_end)P_next = S_MAIN_ADDR;
        else P_next = S_MAIN_INIT;
    S_MAIN_ADDR: // send an address to the SRAM 
        if(addr_end)P_next = S_MAIN_READ;
        else P_next = S_MAIN_ADDR;
    S_MAIN_READ: // fetch the sample from the SRAM
        if(read_data_end)P_next = S_MAIN_POOL;
        else P_next = S_MAIN_ADDR;
    S_MAIN_POOL:
        if(pool_end) P_next = S_MAIN_MUL;
        else P_next = S_MAIN_POOL;
    S_MAIN_MUL:
        if(mul_end) P_next = S_MAIN_WAIT;
        else P_next = S_MAIN_MUL;
    S_MAIN_WAIT: // wait for a button click
        if (| btn_pressed == 1) P_next = S_MAIN_SHOW;
        else P_next = S_MAIN_WAIT;
    S_MAIN_SHOW:
        if(sent_end)P_next = S_MAIN_INIT;
        else P_next = S_MAIN_SHOW;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we)begin
     user_data <= data_out;
     user_data1 <= data_out1;
  end
end

// End of the main controller
// -----------------------------------------------------------------------
//INIT
localparam [16:0] INIT_DELAY = 100_000;
reg [16:0] init_cnt; 
always @(posedge clk)begin
    if(~reset_n || ~(P==S_MAIN_INIT))begin
        init_cnt <= 0;
    end else begin  
        if(init_cnt < INIT_DELAY) init_cnt <= init_cnt + 1;
        else init_cnt <= init_cnt;
    end
end 
assign init_end = (init_cnt == INIT_DELAY);

//ADDR
localparam [3:0]ADDR_DELAY = 10;
reg [3:0] addr_cnt; 
always @(posedge clk)begin
    if(~reset_n || P!=S_MAIN_ADDR)begin
        addr_cnt <= 0;
    end else begin  
        if(addr_cnt < ADDR_DELAY)addr_cnt <= addr_cnt + 1;
        else begin
            addr_cnt <= 0;
        end
    end
end 
assign addr_end = (addr_cnt == ADDR_DELAY);

//READ DATA
localparam [3:0] read_cnt_max = 4'b0110;
reg [3:0] row_cnt , col_cnt;
reg [5:0] read_cnt;

assign read_data_end = (read_cnt == 49); 

always @(posedge clk)begin
    if(~reset_n || P==S_MAIN_INIT)begin
        read_cnt <= 0;
        row_cnt <= 4'b0;
        col_cnt <= 4'b0;
        user_addr <= 12'h000;
    end else begin
        if(P == S_MAIN_READ && ~read_data_end )begin
            matA[row_cnt][col_cnt] <= user_data;
            matB[row_cnt][col_cnt] <= user_data1;
            //A counter control
            if(row_cnt == read_cnt_max)begin
                col_cnt <= col_cnt + 4'b0001;
                row_cnt <= 4'b0000;
            end else begin
                row_cnt <= row_cnt + 4'b0001;
            end
            read_cnt <= read_cnt + 1;
            user_addr <= (user_addr < 1024)? user_addr + 1 : user_addr;
        end
    end
end 

// ------------------------------------------------------------------------
//POOL
localparam [2:0] pool_cnt_max = 4; 
localparam [3:0] pool_wait_cnt_max = 10 , pool_state_wait_delay = 10;
localparam [1:0] pool_init_state = 0 , pool_state = 1 , pool_wait_state = 2;
reg [5:0] pool_cnt;
reg [2:0] pool_cnt1 , pool_cnt2;
reg [1:0] pool_s , pool_s_next; 
reg [3:0] pool_wait_cnt , pool_state_wait_cnt;
wire pool_wait_end , pool_state_end;
assign pool_end = (pool_cnt == 51);
assign pool_wait_end = (pool_wait_cnt == pool_wait_cnt_max);
assign pool_state_end = pool_state_wait_cnt == pool_state_wait_delay;

//pool state control
always @(posedge clk)begin
    if(~reset_n)begin
        pool_s <= pool_init_state;
    end else begin
        pool_s <= (P==S_MAIN_POOL)?pool_s_next:pool_init_state;
    end
end 

always @(posedge clk)begin
    if(~reset_n || pool_s == pool_init_state || (pool_s == pool_wait_state && pool_s_next == pool_state))begin
        pool_wait_cnt <= 0;
    end else begin
        if(pool_s == pool_wait_state && pool_wait_cnt < pool_wait_cnt_max)begin
            pool_wait_cnt <= pool_wait_cnt + 1;
        end
    end
end 

always @(posedge clk)begin
    case(pool_s)
        pool_init_state:
            pool_s_next <= pool_wait_state;
        pool_wait_state:
            if(pool_wait_end) pool_s_next <= pool_state;
            else pool_s_next <= pool_wait_state;
        pool_state:
            if(pool_state_end)pool_s_next <= pool_wait_state;
            else pool_s_next <= pool_state;
        default:
            pool_s_next <= pool_init_state;
    endcase 
end 

always @(posedge clk)begin
    if(~reset_n || pool_s == pool_init_state)begin
        pool_cnt <= 0;  
        pool_cnt1 <= 0; 
        pool_cnt2 <= 0;        
    end else begin
        if(pool_s == pool_state && pool_s_next == pool_wait_state)begin
            if(pool_cnt == 25)begin
                pool_cnt1 <= 0;
                pool_cnt2 <= 0;
            end else if(pool_cnt2 == pool_cnt_max)begin
                pool_cnt2 <= 0;            
                pool_cnt1 <= pool_cnt1 + 1;
            end else begin            
                pool_cnt2 <= pool_cnt2 + 1;
            end
            pool_cnt <= pool_cnt + 1;
        end 
    end
end 

//nums 
always @(posedge clk)begin
    if(~reset_n || pool_s == pool_init_state)begin
        nums_r[0] <= 0; nums_r[1] <= 0; nums_r[2] <= 0;
        nums_r[3] <= 0; nums_r[4] <= 0; nums_r[5] <= 0;
        nums_r[6] <= 0; nums_r[7] <= 0; nums_r[8] <= 0;
    end else begin
        if(pool_s == pool_state)begin
            if(pool_cnt < 25)begin
                //matA_p[pool_cnt1][pool_cnt2]<=matA[pool_cnt1][pool_cnt2];
                matA_p[pool_cnt1][pool_cnt2] <= max_num;
            end else begin
                //matB_p[pool_cnt_max-pool_cnt1][pool_cnt_max-pool_cnt2]<=matB[pool_cnt1][pool_cnt2];
                matB_p[pool_cnt2][pool_cnt1] <= max_num;
            end        
        end else if(pool_s == pool_wait_state)begin
            if(pool_cnt < 25)begin
                nums_r[0] <= matA[pool_cnt1  ][pool_cnt2  ];
                nums_r[1] <= matA[pool_cnt1+1][pool_cnt2  ];
                nums_r[2] <= matA[pool_cnt1+2][pool_cnt2  ];
                nums_r[3] <= matA[pool_cnt1  ][pool_cnt2+1];
                nums_r[4] <= matA[pool_cnt1+1][pool_cnt2+1];
                nums_r[5] <= matA[pool_cnt1+2][pool_cnt2+1];
                nums_r[6] <= matA[pool_cnt1  ][pool_cnt2+2];
                nums_r[7] <= matA[pool_cnt1+1][pool_cnt2+2];
                nums_r[8] <= matA[pool_cnt1+2][pool_cnt2+2];
            end else begin
                nums_r[0] <= matB[pool_cnt1  ][pool_cnt2  ];
                nums_r[1] <= matB[pool_cnt1+1][pool_cnt2  ];
                nums_r[2] <= matB[pool_cnt1+2][pool_cnt2  ];
                nums_r[3] <= matB[pool_cnt1  ][pool_cnt2+1];
                nums_r[4] <= matB[pool_cnt1+1][pool_cnt2+1];
                nums_r[5] <= matB[pool_cnt1+2][pool_cnt2+1];
                nums_r[6] <= matB[pool_cnt1  ][pool_cnt2+2];
                nums_r[7] <= matB[pool_cnt1+1][pool_cnt2+2];
                nums_r[8] <= matB[pool_cnt1+2][pool_cnt2+2];    
            end
        end
    end    
end 

always @(posedge clk)begin
    if(~reset_n || ( ~(pool_s == pool_state) && pool_s_next == pool_state) )begin
        pool_state_wait_cnt <= 0;
    end else begin
        if(pool_s == pool_state)begin
            pool_state_wait_cnt <= (pool_state_wait_cnt == pool_state_wait_delay)?pool_state_wait_cnt:pool_state_wait_cnt+1;
        end 
    end
end 

// ------------------------------------------------------------------------
//matrix multiplication
localparam [1:0] mul_init=0 , mul_wait = 1 ,mul_push = 2;
localparam [5:0] mul_wait_delay = 63;
reg [5:0] mul_wait_cnt;
reg [1:0] mul_s , mul_s_next;
reg [2:0] mul_cnt1;
reg [19:0] ans_mat[0:4][0:4];
wire mul_wait_end;

(*use_dsp="yes"*)reg [19:0] mul_stage[0:24];
reg [19:0] mul_stage1[0:4];

assign mul_wait_end = (mul_wait_cnt == mul_wait_delay);
assign mul_end = (mul_cnt1 == 5);

always @(posedge clk)begin
    if(~reset_n || ~(P==S_MAIN_MUL)) mul_s <= mul_init;
    else mul_s <= mul_s_next;
end

always @(posedge clk)begin
    case(mul_s)
    mul_init: 
        if(mul_wait_end)mul_s_next <= mul_wait;
        else mul_s_next <= mul_init;
    mul_wait: 
        if(mul_wait_end) mul_s_next <= mul_push;
        else mul_s_next <= mul_wait;
    mul_push: 
        if(mul_wait_end) mul_s_next <= mul_wait;
        else mul_s_next <= mul_push;
    endcase
end

//wait
always @(posedge clk)begin
    if(~reset_n || ~(P==S_MAIN_MUL) || ~(mul_s==mul_s_next) )begin
        mul_wait_cnt <= 0;
    end else begin
        mul_wait_cnt <= (mul_wait_cnt == mul_wait_delay)?mul_wait_cnt:mul_wait_cnt +1;
    end
end 

//mul cnt control
always @(posedge clk)begin
    if(~reset_n || P == S_MAIN_INIT)begin
        mul_cnt1 <= 3'b000;
    end else begin
        if(mul_s == mul_push && mul_s_next == mul_wait)begin         
            mul_cnt1 <= mul_cnt1 + 3'b001;
        end        
    end
end

always @(posedge clk)begin
    if(P == S_MAIN_MUL && mul_s == mul_push)begin
        mul_stage[ 0] <= matA_p[mul_cnt1][0] * matB_p[0][0];
        mul_stage[ 1] <= matA_p[mul_cnt1][1] * matB_p[1][0];
        mul_stage[ 2] <= matA_p[mul_cnt1][2] * matB_p[2][0];
        mul_stage[ 3] <= matA_p[mul_cnt1][3] * matB_p[3][0];
        mul_stage[ 4] <= matA_p[mul_cnt1][4] * matB_p[4][0];
        mul_stage[ 5] <= matA_p[mul_cnt1][0] * matB_p[0][1];
        mul_stage[ 6] <= matA_p[mul_cnt1][1] * matB_p[1][1];
        mul_stage[ 7] <= matA_p[mul_cnt1][2] * matB_p[2][1];
        mul_stage[ 8] <= matA_p[mul_cnt1][3] * matB_p[3][1];
        mul_stage[ 9] <= matA_p[mul_cnt1][4] * matB_p[4][1];       
        mul_stage[10] <= matA_p[mul_cnt1][0] * matB_p[0][2];
        mul_stage[11] <= matA_p[mul_cnt1][1] * matB_p[1][2];
        mul_stage[12] <= matA_p[mul_cnt1][2] * matB_p[2][2];
        mul_stage[13] <= matA_p[mul_cnt1][3] * matB_p[3][2];
        mul_stage[14] <= matA_p[mul_cnt1][4] * matB_p[4][2];        
        mul_stage[15] <= matA_p[mul_cnt1][0] * matB_p[0][3];
        mul_stage[16] <= matA_p[mul_cnt1][1] * matB_p[1][3];
        mul_stage[17] <= matA_p[mul_cnt1][2] * matB_p[2][3];
        mul_stage[18] <= matA_p[mul_cnt1][3] * matB_p[3][3];
        mul_stage[19] <= matA_p[mul_cnt1][4] * matB_p[4][3];
        mul_stage[20] <= matA_p[mul_cnt1][0] * matB_p[0][4];
        mul_stage[21] <= matA_p[mul_cnt1][1] * matB_p[1][4];
        mul_stage[22] <= matA_p[mul_cnt1][2] * matB_p[2][4];
        mul_stage[23] <= matA_p[mul_cnt1][3] * matB_p[3][4];
        mul_stage[24] <= matA_p[mul_cnt1][4] * matB_p[4][4];
        mul_stage1[0] <= mul_stage[ 0] + mul_stage[ 1] + mul_stage[ 2] + mul_stage[ 3] + mul_stage[ 4];
        mul_stage1[1] <= mul_stage[ 5] + mul_stage[ 6] + mul_stage[ 7] + mul_stage[ 8] + mul_stage[ 9];
        mul_stage1[2] <= mul_stage[10] + mul_stage[11] + mul_stage[12] + mul_stage[13] + mul_stage[14];
        mul_stage1[3] <= mul_stage[15] + mul_stage[16] + mul_stage[17] + mul_stage[18] + mul_stage[19];
        mul_stage1[4] <= mul_stage[20] + mul_stage[21] + mul_stage[22] + mul_stage[23] + mul_stage[24];
        ans_mat[mul_cnt1][0] <= mul_stage1[0];
        ans_mat[mul_cnt1][1] <= mul_stage1[1];
        ans_mat[mul_cnt1][2] <= mul_stage1[2];
        ans_mat[mul_cnt1][3] <= mul_stage1[3];
        ans_mat[mul_cnt1][4] <= mul_stage1[4];
    end
end 
// ------------------------------------------------------------------------

always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

integer idx , row , col;
always @(posedge clk)begin
    if(~reset_n || P == S_MAIN_INIT)begin
        row <= 3'b000;
        for(idx = 0;idx < msg_len ; idx = idx + 1) data[idx] = msg[idx*8 +: 8];
    end else begin
        for(row = 0;row <5 ; row = row +1)begin
            for(col = 0;col <5;col = col + 1)begin
                
                data[start+start*row+3+6*col] <= ((ans_mat[row][col][19:16] > 9)? "7" : "0") + ans_mat[row][col][19:16];
                data[start+start*row+4+6*col] <= ((ans_mat[row][col][15:12] > 9)? "7" : "0") + ans_mat[row][col][15:12];
                data[start+start*row+5+6*col] <= ((ans_mat[row][col][11: 8] > 9)? "7" : "0") + ans_mat[row][col][11: 8];
                data[start+start*row+6+6*col] <= ((ans_mat[row][col][ 7: 4] > 9)? "7" : "0") + ans_mat[row][col][ 7: 4];
                data[start+start*row+7+6*col] <= ((ans_mat[row][col][ 3: 0] > 9)? "7" : "0") + ans_mat[row][col][ 3: 0];
                
                /*
                data[start+start*row+3+6*col] <= ((matA_p[row][col][ 7: 4] > 9)? "7" : "0") + matA_p[row][col][ 7: 4];
                data[start+start*row+4+6*col] <= ((matA_p[row][col][ 3: 0] > 9)? "7" : "0") + matA_p[row][col][ 3: 0];
                data[start+start*row+6+6*col] <= ((matB_p[row][col][ 7: 4] > 9)? "7" : "0") + matB_p[row][col][ 7: 4];
                data[start+start*row+7+6*col] <= ((matB_p[row][col][ 3: 0] > 9)? "7" : "0") + matB_p[row][col][ 3: 0];
                */
                /*
                data[start+start*row+3+6*col] <= ((matA[row][col][ 7: 4] > 9)? "7" : "0") + matA[row][col][ 7: 4];
                data[start+start*row+4+6*col] <= ((matA[row][col][ 3: 0] > 9)? "7" : "0") + matA[row][col][ 3: 0];
                data[start+start*row+6+6*col] <= ((matB[row][col][ 7: 4] > 9)? "7" : "0") + matB[row][col][ 7: 4];
                data[start+start*row+7+6*col] <= ((matB[row][col][ 3: 0] > 9)? "7" : "0") + matB[row][col][ 3: 0];
                */                
            end
        end
    end
end 

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

assign print_done = (tx_byte == 8'h0);
assign print_enable = (~(P==S_MAIN_SHOW) && P_next == S_MAIN_SHOW);
assign tx_byte  = data[send_counter];
assign transmit = (Q_next == S_UART_WAIT || print_enable);

always @(posedge clk)begin
    if(~reset_n)begin
        send_counter <= 0;
    end else begin
        case(Q)
        S_UART_IDLE: send_counter <= 0;
        default:send_counter <= send_counter + (Q_next == S_UART_INCR);
        endcase
    end
end 

assign sent_end = (print_done);
endmodule

module max(input clk,
           input [7:0] num1,input [7:0] num2,input [7:0] num3,
           input [7:0] num4,input [7:0] num5,input [7:0] num6,
           input [7:0] num7,input [7:0] num8,input [7:0] num9,
           output[7:0] out);
    reg [7:0] cmp1,cmp2,cmp3,cmp4,cmp5,cmp6,cmp7,max_num;
    always @(posedge clk)begin
        cmp1 <= (num1>num2)?num1:num2;
        cmp2 <= (num3>num4)?num3:num4;
        cmp3 <= (num5>num6)?num5:num6;
        cmp4 <= (num7>num8)?num7:num8;
        cmp5 <= (cmp1>cmp2)?cmp1:cmp2;
        cmp6 <= (cmp3>cmp4)?cmp3:cmp4;
        cmp7 <= (cmp5>cmp6)?cmp5:cmp6;
        max_num <= (cmp7>num9)?cmp7:num9;
    end
    assign out = max_num;
endmodule
