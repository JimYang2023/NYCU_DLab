`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  // tri-state LED
  output [3:0] rgb_led_r,
  output [3:0] rgb_led_g,
  output [3:0] rgb_led_b
);

localparam [3:0] S_MAIN_INIT = 4'b0000, S_MAIN_IDLE = 4'b0001,
                 S_MAIN_WAIT = 4'b0010, S_MAIN_READ = 4'b0011,
                 S_MAIN_DONE = 4'b0100, S_MAIN_SHOW = 4'b0101,
                 S_MAIN_READ_RAM = 4'b0110,S_MAIN_READ_WAIT = 4'b0111,
                 S_MAIN_COUNT = 4'b1000;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [3:0] P, P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

//read start , end , wait 
localparam [31:0]read_wait_delay = 5;
localparam [3:0] dcl_start_len = 9 , dcl_end_len = 7;
wire read_start_end , read_end , read_wait_end;
reg [7:0] dcl_start[0:8];
reg [7:0] dcl_end[0:6];
reg [3:0] dcl_start_cnt , dcl_end_cnt;
integer read_wait_cnt;

//PWM
localparam [31:0] duty_5 = 32'd50000 , duty_100 = 32'd1000000;
wire pwm_signal;
reg [31:0] pwm_counter;

//color counter 


//read con
localparam [31:0]con_cnt_max = 65;
reg [7:0] words[0:con_cnt_max];
reg [31:0] con_cnt;
integer i;
assign read_wait_end =(read_wait_cnt==read_wait_delay);

//S_MAIN_COUNT
localparam [31:0]count_delay = 200_000_000;
reg [3:0] color_counter[0:5];
reg [31:0] count_wait_cnt , count_cnt;
wire count_end;
assign count_end = (count_cnt == con_cnt - 5);

//rgb led control
reg [3:0] r_control , g_control , b_control;

assign pwm_signal = (pwm_counter < duty_5);
assign read_start_end = (dcl_start_cnt == dcl_start_len);
assign read_end = (dcl_end_cnt == dcl_end_len);
assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller

//rgb led control
assign rgb_led_r = r_control & {4{pwm_signal}};
assign rgb_led_g = g_control & {4{pwm_signal}};
assign rgb_led_b = b_control & {4{pwm_signal}};
assign usr_led = 4'h00;


clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
    done_flag <= 0;
  end
  else begin
    P <= P_next;
    if (P == S_MAIN_DONE)
      done_flag <= 1;
    else if (P == S_MAIN_SHOW && P_next == S_MAIN_IDLE)
      done_flag <= 0;
    else
      done_flag <= done_flag;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512) P_next = S_MAIN_DONE;
      else P_next = S_MAIN_READ;
    S_MAIN_DONE: // read byte 0 of the superblock from sram[]
      P_next = S_MAIN_READ_WAIT;
    S_MAIN_READ_WAIT:
        if(read_wait_end)P_next = S_MAIN_READ_RAM;
        else P_next = S_MAIN_READ_WAIT;
    S_MAIN_READ_RAM:
        if(read_end)P_next = S_MAIN_COUNT;
        else if(sd_counter == 512) P_next = S_MAIN_WAIT;
        else P_next = S_MAIN_READ_WAIT;
    S_MAIN_COUNT:
        if(count_end)P_next = S_MAIN_SHOW;
        else P_next  = S_MAIN_COUNT;
    S_MAIN_SHOW:
      P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_WAIT);
  rd_addr = blk_addr;
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if(P==S_MAIN_READ && P_next == S_MAIN_DONE) blk_addr <= blk_addr + 1; // In lab 6, change this line to scan all blocks
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n || (P == S_MAIN_READ && P_next == S_MAIN_DONE) || (P==S_MAIN_READ_RAM && P_next == S_MAIN_WAIT))
    sd_counter <= 0;
  else if ((P == S_MAIN_READ && sd_valid) || (P==S_MAIN_READ_WAIT && P_next==S_MAIN_READ_RAM ))
    sd_counter <= (sd_counter == 512)?sd_counter:sd_counter + 1;
end

// FSM ouput logic: Retrieves the content of sram[] for display
always @(posedge clk) begin
  if (~reset_n) data_byte <= 8'b0;
  else if (sram_en && P==S_MAIN_READ_WAIT) data_byte <= data_out;
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end else if (P == S_MAIN_READ || P==S_MAIN_DONE || P == S_MAIN_READ_RAM || P==S_MAIN_READ_WAIT) begin
    row_A <= "searching for   ";
    row_B <= "title           ";
  end else if(P==S_MAIN_COUNT)begin  
    row_A <= "caculating...   ";
    row_B <= "                ";
  end else if(P==S_MAIN_SHOW)begin
    //row_A <= {words[0],words[1],words[2],words[3],words[4],words[5],words[6],words[7],words[8],words[9],words[10],words[11],words[12],words[13],words[14],words[15]};
    row_A <= "RGBPYX          ";
    row_B <= {color_counter[0]+"0",color_counter[1]+"0",color_counter[2]+"0",color_counter[3]+"0",color_counter[4]+"0",color_counter[5]+"0","          "};
  end else if(P==S_MAIN_INIT)begin
    row_A <= "P==S_MAIN_INIT  ";
    row_B <= "                ";
  end else if(P==S_MAIN_WAIT)begin
    row_A <= "P==S_MAIN_WAIT  ";
    row_B <= "                ";  
  end 
end

//read dcl 
always @(posedge clk)begin
    if(~reset_n || P==S_MAIN_INIT )begin
        dcl_start_cnt <= 0;
        dcl_end_cnt <= 0;
        dcl_start[0] <= "D"; //DCL_START
        dcl_start[1] <= "C";
        dcl_start[2] <= "L";
        dcl_start[3] <= "_";
        dcl_start[4] <= "S";
        dcl_start[5] <= "T";
        dcl_start[6] <= "A";
        dcl_start[7] <= "R";
        dcl_start[8] <= "T";
        dcl_end[0] <= "D";   //DCL_END
        dcl_end[1] <= "C";
        dcl_end[2] <= "L";
        dcl_end[3] <= "_";
        dcl_end[4] <= "E";
        dcl_end[5] <= "N";
        dcl_end[6] <= "D";
    end else begin
        if(P==S_MAIN_READ_RAM)begin
            if(dcl_start_cnt < dcl_start_len)begin
                if(data_byte == dcl_start[dcl_start_cnt])begin
                    dcl_start_cnt <= (dcl_start_cnt == dcl_start_len)?dcl_start_cnt:dcl_start_cnt+1;
                end else begin
                    dcl_start_cnt <= (dcl_start_cnt==dcl_start_len)?dcl_start_cnt:0;
                end
            end else begin
                if(data_byte == dcl_end[dcl_end_cnt])begin
                    dcl_end_cnt <= (dcl_end_cnt == dcl_end_len)?dcl_end_cnt:dcl_end_cnt+1;
                end else begin
                    dcl_end_cnt <= (dcl_end_cnt == dcl_end_len)?dcl_end_cnt:0;
                end 
            end
        end    
    end
end
//

//read con
always @(posedge clk)begin
    if(~reset_n || P==S_MAIN_INIT)begin
        con_cnt <= 0;
        for(i=0;i<54;i=i+1)begin
            words[i] <= "0";
        end
    end else begin
        if(P==S_MAIN_READ_RAM && read_start_end && ~read_end)begin     
            words[con_cnt] <= data_byte;
            con_cnt <= (con_cnt == con_cnt_max)?con_cnt:con_cnt+1;
        end        
    end
end 

//COUNT
//cnt control
always @(posedge clk)begin
    if(~reset_n)begin
        count_wait_cnt <= 0;
        count_cnt <= 0;
    end else begin
        if(P==S_MAIN_COUNT)begin
            if(count_wait_cnt < count_delay)begin
                count_wait_cnt <= count_wait_cnt +1;
            end else begin
                count_cnt <= count_cnt +1;
                count_wait_cnt <= 0;
            end 
        end        
    end
end  

always @(posedge clk)begin
    if(~reset_n)begin
        color_counter[0] <= 4'b0000;
        color_counter[1] <= 4'b0000;
        color_counter[2] <= 4'b0000;
        color_counter[3] <= 4'b0000;
        color_counter[4] <= 4'b0000;
        color_counter[5] <= 4'b0000;
    end else begin
        if(P==S_MAIN_COUNT && count_cnt < con_cnt - 7)begin
            case(words[count_cnt])
                "R":color_counter[0] <= color_counter[0]+1;
                "r":color_counter[0] <= color_counter[0]+1;
                "G":color_counter[1] <= color_counter[1]+1;
                "g":color_counter[1] <= color_counter[1]+1;
                "B":color_counter[2] <= color_counter[2]+1;
                "b":color_counter[2] <= color_counter[2]+1;
                "P":color_counter[3] <= color_counter[3]+1;
                "p":color_counter[3] <= color_counter[3]+1;
                "Y":color_counter[4] <= color_counter[4]+1;
                "y":color_counter[4] <= color_counter[4]+1;
                default: color_counter[5] <= color_counter[5]+1;        
            endcase
        end     
    end
end

//read wait
always @(posedge clk)begin
    if(~reset_n)begin
        read_wait_cnt <= 0;
    end else begin
        read_wait_cnt <= (read_wait_cnt == read_wait_delay)?read_wait_cnt:read_wait_cnt +1;
    end
end 

//PWM
always @(posedge clk)begin
    if(~reset_n)begin
        pwm_counter <= 0;
    end else begin
        pwm_counter <= (pwm_counter == duty_100)?0:pwm_counter + 1;
    end
end

//rgb led control
always @(posedge clk)begin
    if(~reset_n || P!=S_MAIN_COUNT)begin
        r_control <= 4'b0000;
        g_control <= 4'b0000;
        b_control <= 4'b0000;    
    end else if(count_wait_cnt == count_delay) begin
       for(i=0;i<4;i=i+1)begin
           if(words[count_cnt+i]=="R" || words[count_cnt+i]=="r") begin
           r_control[3-i] <= 1;       g_control[3-i] <= 0;       b_control[3-i] <= 0;
           end  else if(words[count_cnt+i]=="G" || words[count_cnt+i]=="g")begin
           r_control[3-i] <= 0;       g_control[3-i] <= 1;       b_control[3-i] <= 0;
           end else if(words[count_cnt+i]=="B" || words[count_cnt+i]=="b")begin
           r_control[3-i] <= 0;       g_control[3-i] <= 0;       b_control[3-i] <= 1;
           end else if(words[count_cnt+i]=="P" || words[count_cnt+i]=="p")begin
           r_control[3-i] <= 1;       g_control[3-i] <= 0;       b_control[3-i] <= 1;
           end else if(words[count_cnt+i]=="Y" || words[count_cnt+i]=="y")begin
           r_control[3-i] <= 1;       g_control[3-i] <= 1;       b_control[3-i] <= 0;
           end else begin
           r_control[3-i] <= 0;       g_control[3-i] <= 0;       b_control[3-i] <= 0;
           end
       end
    end 
end 

endmodule
