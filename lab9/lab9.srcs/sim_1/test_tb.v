`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/14 21:38:27
// Design Name: 
// Module Name: test_tb
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

module tb_SHA_256();

    // Testbench Signals
    reg clk;
    reg reset_n;
    reg start_signal;
    reg [511:0] message;
    wire [255:0] ans;
    wire count_done;

    // Instantiate the SHA-256 module
    SHA_256 uut (
        .clk(clk),
        .reset_n(reset_n),
        .start_signal(start_signal),
        .message(message),
        .ans(ans),
        .count_done(count_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test process
    initial begin
        // Initialize signals
        reset_n = 0;
        start_signal = 0;
        message = 512'b0;

        // Reset the system
        #10 reset_n = 1;

        // Test Case: Input message "abc" (in padded form)
        // ASCII for "abc": 0x616263
        // Padding for "abc": 0x616263800000000000...00000000018 (512 bits)
        // The expected SHA-256 hash: 
        // "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"
        message = {384'b0, 32'h61626380, 448'b0, 64'd24}; // Message + Padding
        start_signal = 1;

        #10 start_signal = 0; // Deassert start

        // Wait for processing to complete
        wait(count_done == 1);

        // Display the output hash
        $display("Computed Hash: %h", ans);

        // Compare with the expected result
        if (ans == 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed!");
            $display("Expected: %h", 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad);
        end

        // End simulation
        $finish;
    end
endmodule

