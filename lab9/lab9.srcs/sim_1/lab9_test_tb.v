`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/16 11:14:06
// Design Name: 
// Module Name: lab9_test_tb
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


`timescale 1ns / 1ps

module tb_lab9();

    // Inputs
    reg clk;
    reg reset_n;
    reg [3:0] usr_btn;
    reg [3:0] usr_sw;

    // Outputs
    wire [3:0] usr_led;
    wire LCD_RS;
    wire LCD_RW;
    wire LCD_E;
    wire [3:0] LCD_D;

    // Instantiate the Unit Under Test (UUT)
    lab9 uut (
        .clk(clk),
        .reset_n(reset_n),
        .usr_btn(usr_btn),
        .usr_sw(usr_sw),
        .usr_led(usr_led),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_E(LCD_E),
        .LCD_D(LCD_D)
    );

    // Clock generation (50 MHz)
    always #10 clk = ~clk; // 20ns period

    // Testbench logic
    initial begin
        // Initialize inputs
        clk = 0;
        reset_n = 1;
        usr_btn = 4'b0000;
        usr_sw = 4'b0000;

        // Apply reset
        #10;
        reset_n = 0;
        #15;
        reset_n = 1;
        // Wait a bit, then simulate pressing BTN3 to start the process
        #20;
        usr_btn = 4'b1111;
        // Wait for processing
        wait(uut.P == uut.S_MAIN_COUNT); // Wait until the state machine enters COUNT state
        #1000; // Simulate some delay during counting

        // Monitor transition to CHECK state
        wait(uut.P == uut.S_MAIN_CHECK);
        #1000;

        // Monitor result
        if (usr_led[2]) begin
            $display("Password match detected. Transitioned to SHOW state.");
        end else begin
            $display("Password mismatch or incorrect behavior.");
        end

        // Finish simulation
        #1000;
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time: %0t | State: %b | usr_led: %b | row_A: %s | row_B: %s",
                 $time, uut.P, usr_led, uut.row_A, uut.row_B);
    end

endmodule

