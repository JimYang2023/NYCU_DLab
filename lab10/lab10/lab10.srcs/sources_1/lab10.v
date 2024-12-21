`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish_clock;
reg  [31:0] fish_clock1;
reg  [31:0] fish_clock2;
reg  [31:0] fish_clock3;
reg  [31:0] fish_clock4;
reg  [31:0] fish_clock5;
reg  [31:0] fish_clock6;
reg  [31:0] fish_clock7;
reg  [31:0] fish_clock_y;
reg  [31:0] fish_clock_y1;
reg  [31:0] fish_clock_y2;
reg  [31:0] fish_clock_y3;
wire [9:0]  pos;
wire [9:0]  pos1;
wire [9:0]  pos2;
wire [9:0]  pos3;
wire [9:0]  pos4;
wire [9:0]  pos5;
wire [9:0]  pos6;
wire [9:0]  pos7;
wire [9:0]  pos_y;
wire [9:0]  pos_y1;
wire [9:0]  pos_y2;
wire [9:0]  pos_y3;
wire        fish_region;
wire        fish_region1;
wire        fish_region2;
wire        fish_region3;
wire        fish_region4;
wire        fish_region5;
wire        fish_region6;
wire        fish_region7;
wire        fish_region8;
wire        fish_region9;
wire        fish_region10;
wire        fish_region11;
wire        fish_region12;
wire        fish_region13;
wire        fish_region14;
wire        fish_region15;
reg check , check1 , check2 , check3 , check4 , check5 , check6 , check7;
reg check_y ,check_y1 , check_y2 , check_y3;

localparam y_cnt_max = 5;
reg [31:0] y_cnt;


//speed control
reg [2:0] speed;
reg color;
reg [1:0]type;
wire [3:0] db_btn;
reg [3:0] pre_btn;
debounce db0(.clk(clk),.btn_input(usr_btn[0]),.btn_output(db_btn[0]));
debounce db1(.clk(clk),.btn_input(usr_btn[1]),.btn_output(db_btn[1]));
debounce db2(.clk(clk),.btn_input(usr_btn[2]),.btn_output(db_btn[2]));
debounce db3(.clk(clk),.btn_input(usr_btn[3]),.btn_output(db_btn[3]));
assign usr_led[0] = (speed >= 3'b001);
assign usr_led[1] = (speed >= 3'b010);
assign usr_led[2] = (speed >= 3'b011);
assign usr_led[3] = (speed == 3'b100);

always @(posedge clk)begin
    if(~reset_n)color <= 0;
    else if(pre_btn[2]==0 && db_btn[2]==1 && usr_sw[0])color <= ~color;
    else color <= color;
end

always @(posedge clk)begin
    if(~reset_n) type <= 0;
    else if(pre_btn[2]==0 && db_btn[2]==1 && ~usr_sw[0]) type <= (type==2)?0:type+1;
    else type <= type;
end

// declare SRAM control signals
wire [16:0] sram_addr;
wire [16:0] sram_addr1;
wire [16:0] sram_addr2;
wire [16:0] sram_addr3;
wire [16:0] sram_addr4;
wire [16:0] sram_addr5;
wire [16:0] sram_addr6;
wire [16:0] sram_addr7;
wire [11:0] data_in;
wire [11:0] data_out;
wire [11:0] data_out1;
wire [11:0] data_out2;
wire [11:0] data_out3;
wire [11:0] data_out4;
wire [11:0] data_out5;
wire [11:0] data_out6;
wire [11:0] data_out7;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;
reg  [17:0] pixel_addr1;
reg  [17:0] pixel_addr2;
reg  [17:0] pixel_addr3;
reg  [17:0] pixel_addr4;
reg  [17:0] pixel_addr5;
reg  [17:0] pixel_addr6;
reg  [17:0] pixel_addr7;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS    = 32; // Vertical location of the fish in the sea image.
localparam FISH_VPOS1   = 96; // Vertical location of the fish in the sea image.
localparam FISH_VPOS2   = 160; // Vertical location of the fish in the sea image.
localparam FISH_VPOS3   = 120; // Vertical location of the fish in the sea image.
localparam FISH_VPOS4   = 76;
localparam FISH_VPOS5   = 120;
localparam FISH_VPOS6   = 32;
localparam FISH_VPOS7   = 135;
localparam FISH_VPOS8   = 35;
localparam FISH_VPOS9   = 165;
localparam FISH_VPOS10   = 112;
localparam FISH_VPOS11   = 35;
localparam FISH_VPOS12   = 155;
localparam FISH_VPOS13   = 180;
localparam FISH_VPOS14   = 80;
localparam FISH_VPOS15   = 160;
localparam FISH_W      = 32; // Width of the fish.
localparam FISH_H      = 16; // Height of the fish.
localparam FISH_H1     = 22;
localparam FISH_H2     = 36;

reg [17:0] fish_addr[0:7];   // Address array for up to 8 fish images.
reg [17:0] fish_addr1[0:7];
reg [17:0] fish_addr2[0:7];
reg [17:0] fish_addr3[0:7];
reg [17:0] fish_addr4[0:7];
reg [17:0] fish_addr5[0:7];

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] = VBUF_W*VBUF_H + 18'd0;         /* Addr for fish image #1 */
  fish_addr[1] = VBUF_W*VBUF_H + FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] = VBUF_W*VBUF_H + FISH_W*FISH_H*2; /* Addr for fish image #3 */
  fish_addr[3] = VBUF_W*VBUF_H + FISH_W*FISH_H*3; /* Addr for fish image #4 */
  fish_addr[4] = VBUF_W*VBUF_H + FISH_W*FISH_H*4; /* Addr for fish image #4 */
  fish_addr[5] = VBUF_W*VBUF_H + FISH_W*FISH_H*5; /* Addr for fish image #4 */
  fish_addr[6] = VBUF_W*VBUF_H + FISH_W*FISH_H*6; /* Addr for fish image #4 */
  fish_addr[7] = VBUF_W*VBUF_H + FISH_W*FISH_H*7; /* Addr for fish image #4 */
end

initial begin
  fish_addr4[0] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + 18'd0; /* Addr for fish image #1 */
  fish_addr4[1] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*1; /* Addr for fish image #2 */
  fish_addr4[2] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*2; /* Addr for fish image #3 */
  fish_addr4[3] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*3; /* Addr for fish image #4 */
  fish_addr4[4] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*4; /* Addr for fish image #4 */
  fish_addr4[5] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*5; /* Addr for fish image #4 */
  fish_addr4[6] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*6; /* Addr for fish image #4 */
  fish_addr4[7] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*7; /* Addr for fish image #4 */
end


initial begin
  fish_addr5[0] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + 18'd0; /* Addr for fish image #1 */
  fish_addr5[1] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*1; /* Addr for fish image #2 */
  fish_addr5[2] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*2; /* Addr for fish image #3 */
  fish_addr5[3] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*3; /* Addr for fish image #4 */
  fish_addr5[4] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*4; /* Addr for fish image #4 */
  fish_addr5[5] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*5; /* Addr for fish image #4 */
  fish_addr5[6] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*6; /* Addr for fish image #4 */
  fish_addr5[7] = VBUF_W*VBUF_H + FISH_W*FISH_H*8 + FISH_W*FISH_H1*8 + FISH_W*FISH_H2*7; /* Addr for fish image #4 */
end

initial begin
  fish_addr1[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr1[1] = FISH_W*FISH_H1; /* Addr for fish image #2 */
  fish_addr1[2] = FISH_W*FISH_H1*2; /* Addr for fish image #3 */
  fish_addr1[3] = FISH_W*FISH_H1*3; /* Addr for fish image #4 */
  fish_addr1[4] = FISH_W*FISH_H1*4; /* Addr for fish image #4 */
  fish_addr1[5] = FISH_W*FISH_H1*5; /* Addr for fish image #4 */
  fish_addr1[6] = FISH_W*FISH_H1*6; /* Addr for fish image #4 */
  fish_addr1[7] = FISH_W*FISH_H1*7; /* Addr for fish image #4 */
end

initial begin
  fish_addr2[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr2[1] = FISH_W*FISH_H2; /* Addr for fish image #2 */
  fish_addr2[2] = FISH_W*FISH_H2*2; /* Addr for fish image #3 */
  fish_addr2[3] = FISH_W*FISH_H2*3; /* Addr for fish image #4 */
  fish_addr2[4] = FISH_W*FISH_H2*4; /* Addr for fish image #4 */
  fish_addr2[5] = FISH_W*FISH_H2*5; /* Addr for fish image #4 */
  fish_addr2[6] = FISH_W*FISH_H2*6; /* Addr for fish image #4 */
  fish_addr2[7] = FISH_W*FISH_H2*7; /* Addr for fish image #4 */
end

initial begin
  fish_addr3[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr3[1] = FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr3[2] = FISH_W*FISH_H*2; /* Addr for fish image #3 */
  fish_addr3[3] = FISH_W*FISH_H*3; /* Addr for fish image #4 */
  fish_addr3[4] = FISH_W*FISH_H*4; /* Addr for fish image #4 */
  fish_addr3[5] = FISH_W*FISH_H*5; /* Addr for fish image #4 */
  fish_addr3[6] = FISH_W*FISH_H*6; /* Addr for fish image #4 */
  fish_addr3[7] = FISH_W*FISH_H*7; /* Addr for fish image #4 */
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H+FISH_W*FISH_H*8+FISH_W*FISH_H1*8+FISH_W*FISH_H2*8) , .FILE("images.mem"))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .addr1(sram_addr1),.data_i(data_in), .data_o(data_out), .data_o1(data_out1));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H1*8),.FILE("fish2.mem"))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr2), .addr1(sram_addr3),.data_i(data_in), .data_o(data_out2), .data_o1(data_out3));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*16),.FILE("fish1.mem"))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr4), .addr1(sram_addr5),.data_i(data_in), .data_o(data_out4), .data_o1(data_out5));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H2*8),.FILE("fish3.mem"))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr6), .addr1(sram_addr7),.data_i(data_in), .data_o(data_out6), .data_o1(data_out7));


assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr1 = pixel_addr1;
assign sram_addr2 = pixel_addr2;
assign sram_addr3 = pixel_addr3;
assign sram_addr4 = pixel_addr4;
assign sram_addr5 = pixel_addr5;
assign sram_addr6 = pixel_addr6;
assign sram_addr7 = pixel_addr7;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; 
assign pos1 = fish_clock1[31:20];
assign pos2 = fish_clock2[31:20];
assign pos3 = fish_clock3[31:20]; 
assign pos4 = fish_clock4[31:20]; 
assign pos5 = fish_clock5[31:20];  
assign pos6 = fish_clock6[31:20];  
assign pos7 = fish_clock7[31:20];
assign pos_y = fish_clock_y[31:20];
assign pos_y1 = fish_clock_y1[31:20];
assign pos_y2 = fish_clock_y2[31:20];
assign pos_y3 = fish_clock_y3[31:20];

always @(posedge clk) begin
  if (~reset_n )begin
    fish_clock <= FISH_W;
    check <= 1;
  end else begin
    if(fish_clock[31:21] > VBUF_W) check <= 0;
    else if(fish_clock[31:21]==FISH_W) check <= 1;
    else check <= check;
    fish_clock <= (check)? fish_clock + 1 + speed: fish_clock - 1 - speed;
  end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock1 <= 0;
        check1 <= 1;
    end else begin
        if(fish_clock1[31:21] > VBUF_W) check1 <= 0;
        else if(fish_clock1[31:21]<=FISH_W) check1 <= 1;
        else check1 <= check1;
        fish_clock1 <= (check1)? fish_clock1 + 2 + speed: fish_clock1 - 2 - speed;  
    end
end 

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock2 <= 54;
        check2 <= 0;
    end else begin
        if(fish_clock2[31:21] > VBUF_W) check2 <= 0;
        else if(fish_clock2[31:21]<=FISH_W) check2 <= 1;
        else check2 <= check2;
        fish_clock2 <= (check2)? fish_clock2 + 2 + speed: fish_clock2 - 2 - speed;
    end
end 

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock3 <= 60;
        check3 <= 1;
    end else begin
        if(fish_clock3[31:21] > VBUF_W) check3 <= 0;
        else if(fish_clock3[31:21]<=FISH_W) check3 <= 1;
        else check3 <= check3;
        fish_clock3 <= (check3)? fish_clock3 + 3 + speed: fish_clock3 - 3 - speed;
    end
end 

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock4 <= 120;
        check4 <= 0;
    end else begin
        if(pre_btn[1]==0 && db_btn[1]==1) check4 <= ~check4;
        else if(fish_clock4[31:21] > VBUF_W) check4 <= 0;
        else if(fish_clock4[31:21]<=FISH_W) check4 <= 1;
        else check4 <= check4;
        fish_clock4 <= (check4)? fish_clock4 + 2 + speed: fish_clock4 - 2 - speed;
    end
end 

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock5 <= 63;
        check5 <= 1;
    end else begin
        if(pre_btn[1]==0 && db_btn[1]==1)check5 <= ~check5;
        else if(fish_clock5[31:21] > VBUF_W) check5 <= 0;
        else if(fish_clock5[31:21]<=FISH_W) check5 <= 1;
        else check5 <= check5;
        fish_clock5 <= (check5)? fish_clock5 + 1 + speed: fish_clock5 - 1 - speed;
    end
end 

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock6 <= 63;
        check6 <= 1;
    end else begin
        if(pre_btn[1]==0 && db_btn[1]==1)check6 <= ~check6;
        else if(fish_clock6[31:21] > VBUF_W) check6 <= 0;
        else if(fish_clock6[31:21]<=FISH_W) check6 <= 1;
        else check6 <= check6;
        fish_clock6 <= (check6)? fish_clock6 + (y_cnt == y_cnt_max) + speed: fish_clock6 - (y_cnt == y_cnt_max) - speed;
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock7 <= 23;
        check7 <= 1;
    end else begin
        if(pre_btn[1]==0 && db_btn[1]==1)check7 <= ~check7;
        else if(fish_clock7[31:21] > VBUF_W) check7 <= 0;
        else if(fish_clock7[31:21]<=FISH_W) check7 <= 1;
        else check7 <= check7;
        fish_clock7 <= (check7)? fish_clock7 + 4 + speed: fish_clock7 - 4 - speed;
    end
end

//fish move y cnt
always @(posedge clk)begin
    if(~reset_n)begin
        y_cnt <= 0;
    end else begin
        y_cnt <= (y_cnt == y_cnt_max)?0:y_cnt+1;
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock_y[20:0] <= 0;
        fish_clock_y[31:21] <= FISH_VPOS;   
        check_y <= 1;
    end else begin
        if(fish_clock_y[31:21] >= VBUF_H - 115-FISH_H) check_y <= 0;
        else if(fish_clock_y[31:21]<=0) check_y <= 1;
        else check_y <= check_y;
        fish_clock_y <= (check_y)?(fish_clock_y + 1 + speed):(fish_clock_y - 1 - speed);
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock_y1[20:0] <= 0;
        fish_clock_y1[31:21] <= FISH_VPOS1;
        check_y1 <= 0;
    end else begin
        if(fish_clock_y1[31:21] >= VBUF_H - 110 -FISH_H1) check_y1 <= 0;
        else if(fish_clock_y1[31:21]<=0) check_y1 <= 1;
        else check_y1 <= check_y1;
        fish_clock_y1 <= (check_y1)?(fish_clock_y1 + (y_cnt == y_cnt_max)):(fish_clock_y1 - (y_cnt == y_cnt_max));
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock_y2[20:0] <= 0;
        fish_clock_y2[31:21] <= FISH_VPOS2;
        check_y2 <= 1;
    end else begin
        if(fish_clock_y2[31:21] >= VBUF_H - 110 - FISH_H2) check_y2 <= 0;
        else if(fish_clock_y2[31:21]<=0) check_y2 <= 1;
        else check_y2 <= check_y2;
        fish_clock_y2 <= (check_y2)?(fish_clock_y2 + 2):(fish_clock_y2 - 2);
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        fish_clock_y3[20:0] <= 0;
        fish_clock_y3[31:21] <= FISH_VPOS3;
        check_y3 <= 1;
    end else begin
        if(fish_clock_y3[31:21] > VBUF_H - 115-FISH_H) check_y3 <= 0;
        else if(fish_clock_y3[31:21]<=0) check_y3 <= 1;
        else check_y3 <= check_y3;
        fish_clock_y3 <= (check_y3)?(fish_clock_y3 + 2 + speed):(fish_clock_y3 - 2 - speed);
    end
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.

assign fish_region = pixel_y >= (pos_y<<1) && pixel_y < (pos_y+((type==1)?FISH_H1:(type==2)?FISH_H2:FISH_H))<<1 &&
           (pixel_x + 63) >= pos && pixel_x < pos + 1;
           
assign fish_region1 = pixel_y >= (pos_y1<<1) && pixel_y < (pos_y1+FISH_H1)<<1 &&
           (pixel_x + 63) >= pos1 && pixel_x < pos1 + 1;

assign fish_region2 = pixel_y >= (pos_y2<<1) && pixel_y < (pos_y2+FISH_H2)<<1 &&
           (pixel_x + 63) >= pos2 && pixel_x < pos2 + 1;

assign fish_region3 = pixel_y >= (pos_y3<<1) && pixel_y < (pos_y3+FISH_H)<<1 &&
           (pixel_x + 63) >= pos3 && pixel_x < pos3 + 1;

assign fish_region4 = pixel_y >= (FISH_VPOS4<<1) && pixel_y < (FISH_VPOS4+FISH_H1)<<1 && 
            (pixel_x + 63) >= pos4 && pixel_x < pos4 + 1;
                       
assign fish_region5 = (pixel_y >= (FISH_VPOS5<<1) && pixel_y < (FISH_VPOS5+FISH_H1)<<1 && 
            (pixel_x + 63) >= pos5 && pixel_x < pos5 + 1 );

assign fish_region6 = (pixel_y >= (FISH_VPOS6<<1) && pixel_y < (FISH_VPOS6+FISH_H1)<<1 && 
            (pixel_x + 63) >= pos4 && pixel_x < pos4 + 1 );

assign fish_region7 = (pixel_y >= (FISH_VPOS7<<1) && pixel_y < (FISH_VPOS7+FISH_H2)<<1 && 
            (pixel_x + 63) >= pos5 && pixel_x < pos5 + 1 );

assign fish_region8 = (pixel_y >= (FISH_VPOS8<<1) && pixel_y < (FISH_VPOS8+FISH_H2)<<1 && 
            (pixel_x + 63) >= pos5 && pixel_x < pos5 + 1 );

assign fish_region9 = (pixel_y >= (FISH_VPOS9<<1) && pixel_y < (FISH_VPOS9+FISH_H2)<<1 && 
            (pixel_x + 63) >= pos4 && pixel_x < pos4 + 1 );

assign fish_region10 = (pixel_y >= (FISH_VPOS10<<1) && pixel_y < (FISH_VPOS10+FISH_H)<<1 && 
            (pixel_x + 63) >= pos6 && pixel_x < pos6 + 1 );

assign fish_region11 = (pixel_y >= (FISH_VPOS11<<1) && pixel_y < (FISH_VPOS11+FISH_H)<<1 && 
            (pixel_x + 63) >= pos6 && pixel_x < pos6 + 1 );

assign fish_region12 = (pixel_y >= (FISH_VPOS12<<1) && pixel_y < (FISH_VPOS12+FISH_H)<<1 && 
            (pixel_x + 63) >= pos6 && pixel_x < pos6 + 1 );

assign fish_region13 = (pixel_y >= (FISH_VPOS13<<1) && pixel_y < (FISH_VPOS13+FISH_H)<<1 && 
            (pixel_x + 63) >= pos6 && pixel_x < pos6 + 1 );

assign fish_region14 = (pixel_y >= (FISH_VPOS14<<1) && pixel_y < (FISH_VPOS14+FISH_H2)<<1 && 
            (pixel_x + 63) >= pos7 && pixel_x < pos7 + 1 );

assign fish_region15 = (pixel_y >= (FISH_VPOS15<<1) && pixel_y < (FISH_VPOS15+FISH_H1)<<1 && 
            (pixel_x + 63) >= pos7 && pixel_x < pos7 + 1 );


always @(posedge clk)begin
    if(~reset_n)begin
        pixel_addr <=0;
        pixel_addr1<=0;
        pixel_addr2<=0;
        pixel_addr3<=0;
        pixel_addr4<=0;
        pixel_addr5<=0;
        pixel_addr6<=0;
        pixel_addr7<=0;
    end else begin
        if(check)
            if(type==2)
            pixel_addr <= (fish_addr5[fish_clock[25:23]]) +
                          ((pixel_y>>1)-pos_y)*FISH_W +
                          ((-pixel_x + pos)>>1);
            else 
            pixel_addr <= ((type==1)?fish_addr4[fish_clock[25:23]]:fish_addr[fish_clock[25:23]]) +
                          ((pixel_y>>1)-pos_y)*FISH_W +
                          ((pixel_x +(FISH_W*2-1)-pos)>>1);
        else
            if(type==2)
            pixel_addr <= (fish_addr5[fish_clock[25:23]])+
                      ((pixel_y>>1)-pos_y)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos)>>1);
            else
            pixel_addr <= ((type)?fish_addr4[fish_clock[25:23]]:fish_addr[fish_clock[25:23]])+
                      ((pixel_y>>1)-pos_y)*FISH_W +
                      ((-pixel_x + pos)>>1);
        
        if(check1)
            pixel_addr2 <= fish_addr1[fish_clock[25:23]] +
                      ((pixel_y>>1)-pos_y1)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos1)>>1);
        else 
            pixel_addr2 <= fish_addr1[fish_clock[25:23]]+
                      ((pixel_y>>1)-pos_y1)*FISH_W +
                      ((-pixel_x + pos1)>>1);
        
        if(check2)
            pixel_addr6 <= fish_addr2[fish_clock[25:23]]+
                      ((pixel_y>>1)-pos_y2)*FISH_W +
                      ((-pixel_x + pos2)>>1);
        else 
            pixel_addr6 <= fish_addr2[fish_clock[25:23]] +
                      ((pixel_y>>1)-pos_y2)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos2)>>1);
        if(check3) 
            pixel_addr4 <= fish_addr3[fish_clock[25:23]] +
                      ((pixel_y>>1)-pos_y3)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos3)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else
            pixel_addr4 <= fish_addr3[fish_clock[25:23]]+
                      ((pixel_y>>1)-pos_y3)*FISH_W +
                      ((-pixel_x + pos3)>>1) +((color)?FISH_W*FISH_H*8:0);
                      
        if(fish_region4)
        if(check4) 
            pixel_addr3 <= fish_addr1[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS4)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos4)>>1);
        else
            pixel_addr3 <= fish_addr1[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS4)*FISH_W +
                      ((-pixel_x + pos4)>>1);
        else if(fish_region5)
        if(check5) 
            pixel_addr3 <= fish_addr1[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS5)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos5)>>1);
        else
            pixel_addr3 <= fish_addr1[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS5)*FISH_W +
                      ((-pixel_x + pos5)>>1);
        else if(fish_region6)
        if(check4) 
            pixel_addr3 <= fish_addr1[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS6)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos4)>>1);
        else
            pixel_addr3 <= fish_addr1[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS6)*FISH_W +
                      ((-pixel_x + pos4)>>1);
        else if(fish_region15)
        if(check7) 
            pixel_addr3 <= fish_addr1[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS15)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos7)>>1);
        else
            pixel_addr3 <= fish_addr1[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS15)*FISH_W +
                      ((-pixel_x + pos7)>>1);     
        
        
        if(fish_region7)
        if(~check5) 
            pixel_addr7 <= fish_addr2[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS7)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos5)>>1);
        else 
            pixel_addr7 <= fish_addr2[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS7)*FISH_W +
                      ((-pixel_x + pos5)>>1);     
        else if(fish_region8) 
        if(~check5) 
            pixel_addr7 <= fish_addr2[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS8)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos5)>>1);
        else
            pixel_addr7 <= fish_addr2[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS8)*FISH_W +
                      ((-pixel_x + pos5)>>1);     
        else if(fish_region9)
        if(~check4) 
            pixel_addr7 <= fish_addr2[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS9)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos4)>>1);
        else
            pixel_addr7 <= fish_addr2[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS9)*FISH_W +
                      ((-pixel_x + pos4)>>1);
        else if(fish_region14)
        if(~check7) 
            pixel_addr7 <= fish_addr2[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS14)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos7)>>1);
        else
            pixel_addr7 <= fish_addr2[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS14)*FISH_W +
                      ((-pixel_x + pos7)>>1);     
        
        
        //-----------------------------------------------------
        if(fish_region10)
        if(check6) 
            pixel_addr5 <= fish_addr3[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS10)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos6)>>1)+ ((color)?FISH_W*FISH_H*8:0);
        else
            pixel_addr5 <= fish_addr3[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS10)*FISH_W +
                      ((-pixel_x + pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else if(fish_region11)
        if(check6) 
            pixel_addr5 <= fish_addr3[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS11)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else
            pixel_addr5 <= fish_addr3[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS11)*FISH_W +
                      ((-pixel_x + pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else if(fish_region12)
        if(check6) 
            pixel_addr5 <= fish_addr3[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS12)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else
            pixel_addr5 <= fish_addr3[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS12)*FISH_W +
                      ((-pixel_x + pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else if(fish_region13)
        if(check6) 
            pixel_addr5 <= fish_addr3[fish_clock[25:23]] +
                      ((pixel_y>>1)-FISH_VPOS13)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        else
            pixel_addr5 <= fish_addr3[fish_clock[25:23]]+
                      ((pixel_y>>1)-FISH_VPOS13)*FISH_W +
                      ((-pixel_x + pos6)>>1) + ((color)?FISH_W*FISH_H*8:0);
        
                      
        pixel_addr1 <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    end
end 

// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else
    rgb_next = (fish_region2 & data_out6!=12'h0f0)?data_out6:
               (fish_region1 & data_out2!=12'h0f0)?data_out2:
               (fish_region3 & data_out4!=12'h0f0)?data_out4:
               (fish_region  & data_out !=12'h0f0)?data_out:
               ((fish_region7||fish_region8||fish_region9||fish_region14) & data_out7!=12'h0f0)?data_out7:
               ((fish_region4||fish_region5||fish_region6||fish_region15) & data_out3!=12'h0f0)?data_out3:
               ((fish_region10||fish_region11||fish_region12||fish_region13) & data_out5!=12'h0f0)?data_out5:data_out1; // RGB value at (pixel_x, pixel_y)
end


//speed control
always @(posedge clk)begin
    if(~reset_n)begin
        pre_btn <= 0;
    end else begin
        pre_btn <= db_btn;    
    end
end

always @(posedge clk)begin
    if(~reset_n)begin
        speed <= 0;
    end else begin
        if(pre_btn[0] == 0 && db_btn[0] == 1)
            speed <= (speed == 3'b100)?0:speed + 1;
    end
end


// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
