`timescale 1ns/1ps

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
        message = {"000000000",1'b1,375'b0,64'd72}; // Message + Padding
        //message = 512'b0;

        #15 start_signal = 1;
            
        #20 start_signal = 0; // Deassert start

        // Wait for processing to complete
        wait(count_done == 1);

        $display("message: %h",message);
        // Display the output hash
        $display("Computed Hash: %h", ans);

        // Compare with the expected result
        if (ans == 256'hf120bb5698d520c5691b6d603a00bfd662d13bf177a04571f9d10c0745dfa2a5) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed!");
            $display("Expected: %h", 256'hf120bb5698d520c5691b6d603a00bfd662d13bf177a04571f9d10c0745dfa2a5);
        end
        //--------------------------------
        message = 512'b0; // Message + Padding
        
        #100 start_signal = 1;
            
        #105 start_signal = 0; // Deassert start

        // Wait for processing to complete
        wait(count_done == 1);

        $display("message: %h",message);
        // Display the output hash
        $display("Computed Hash: %h", ans);

        // Compare with the expected result
        if (ans == 256'hda5698be17b9b46962335799779fbeca8ce5d491c0d26243bafef9ea1837a9d8) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed!");
            $display("Expected: %h", 256'hda5698be17b9b46962335799779fbeca8ce5d491c0d26243bafef9ea1837a9d8);
        end
        
        // End simulation
        $finish;
    end
endmodule
