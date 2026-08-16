`timescale 1ns/1ps

module parity_unit_tb;

    localparam int ENC_DATA_WIDTH = 32;

    logic [1:0]                  parity_mode;
    logic [ENC_DATA_WIDTH-1:0]   data_in;
    logic [ENC_DATA_WIDTH:0]     data_out;

    parity_unit #(
        .ENC_DATA_WIDTH(ENC_DATA_WIDTH)
    ) dut (
        .PARITY_MODE(parity_mode),
        .Data_in(data_in),
        .Data_out(data_out)
    );

    // Helper function to count ones in a value
    function automatic int count_ones(logic [31:0] val);
        int count = 0;
        for (int i = 0; i < 32; i++)
            count += val[i];
        return count;
    endfunction

    // Test counters
    int passed = 0;
    int failed = 0;

    // Self-checking test stimulus
    initial begin
        $display("===== Parity Unit Testbench =====");

        // Test 1: PARITY_MODE = DISABLED (2'b00)
        $display("\nTest 1: Parity Disabled");
        parity_mode = 2'b00;
        data_in = 32'hAAAA_AAAA;  // 16 ones
        #1;
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: data_out = {0, data_in} when disabled");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 2: PARITY_MODE = EVEN (2'b01), data with even number of ones
        $display("\nTest 2: Even Parity (data has even ones)");
        parity_mode = 2'b00;
        data_in = 32'h5555_5555;  // 16 ones (even)
        #1;
        // For even parity, parity_bit = ^data_in. Since data has 16 ones (even), parity_bit should be 0
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: Even parity bit = 0 for even number of ones");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 3: PARITY_MODE = EVEN (2'b01), data with odd number of ones
        $display("\nTest 3: Even Parity (data has odd ones)");
        parity_mode = 2'b00;
        data_in = 32'h5555_555E;  // 17 ones (odd)
        #1;
        // For even parity, parity_bit = ^data_in. Since data has 17 ones (odd), parity_bit should be 1
        if (data_out == {1'b1, data_in}) begin
            $display("  PASS: Even parity bit = 1 for odd number of ones");
            passed++;
        end else begin
            $display("  FAIL: Expected {1, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 4: PARITY_MODE = ODD (2'b10), data with even number of ones
        $display("\nTest 4: Odd Parity (data has even ones)");
        parity_mode = 2'b01;
        data_in = 32'h5555_5555;  // 16 ones (even)
        #1;
        // For odd parity, parity_bit = ~^data_in. Since data has 16 ones (even), ^data_in = 0, so ~0 = 1
        if (data_out == {1'b1, data_in}) begin
            $display("  PASS: Odd parity bit = 1 for even number of ones");
            passed++;
        end else begin
            $display("  FAIL: Expected {1, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 5: PARITY_MODE = ODD (2'b10), data with odd number of ones
        $display("\nTest 5: Odd Parity (data has odd ones)");
        parity_mode = 2'b01;
        data_in = 32'h5555_555E;  // 17 ones (odd)
        #1;
        // For odd parity, parity_bit = ~^data_in. Since data has 17 ones (odd), ^data_in = 1, so ~1 = 0
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: Odd parity bit = 0 for odd number of ones");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 6: PARITY_MODE = RESERVED (2'b11)
        $display("\nTest 6: Parity Reserved (treated as disabled)");
        parity_mode = 2'b11;
        data_in = 32'hFFFF_FFFF;  // All ones
        #1;
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: Reserved mode produces parity_bit = 0");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 7: All zeros
        $display("\nTest 7: All zeros");
        parity_mode = 2'b00;
        data_in = 32'h0000_0000;
        #1;
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: All zeros produces even parity bit = 0");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Test 8: All ones
        $display("\nTest 8: All ones (32 ones = even)");
        parity_mode = 2'b00;
        data_in = 32'hFFFF_FFFF;
        #1;
        if (data_out == {1'b0, data_in}) begin
            $display("  PASS: All ones (even count) produces even parity bit = 0");
            passed++;
        end else begin
            $display("  FAIL: Expected {0, %h}, got %h", data_in, data_out);
            failed++;
        end

        // Summary
        $display("\n===== Test Summary =====");
        $display("Passed: %d", passed);
        $display("Failed: %d", failed);

        if (failed == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
        end

        $finish;
    end

endmodule
