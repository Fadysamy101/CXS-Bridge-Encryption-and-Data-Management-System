`timescale 1ns/1ps

module encryption_unit_tb;

    localparam int DATA_WIDTH = 16;

    logic [3:0]                  enc_mode;
    logic [DATA_WIDTH-1:0]       data_in;
    logic [(DATA_WIDTH*2)-1:0]   data_out;

    int passed = 0;
    int failed = 0;

    encryption_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_encryption_unit_enc_mode (enc_mode),
        .i_encryption_unit_data_in  (data_in),
        .o_encryption_unit_data_out (data_out)
    );

    task automatic test_case(
        input string name,
        input logic [3:0] mode,
        input logic [DATA_WIDTH-1:0] input_val,
        input logic [(DATA_WIDTH*2)-1:0] expected_out
    );
        enc_mode = mode;
        data_in  = input_val;

        #1;

        if (data_out === expected_out) begin
            $display("PASS: %s | in=%h mode=%h out=%h",
                     name, input_val, mode, data_out);
            passed++;
        end
        else begin
            $display("FAIL: %s", name);
            $display("      Input    = %h", input_val);
            $display("      ENC_MODE = %h", mode);
            $display("      Expected = %h", expected_out);
            $display("      Got      = %h", data_out);
            failed++;
        end
    endtask

    initial begin

        $display("===== Encryption Unit Testbench =====");

        test_case("Balanced 00FF - EVEN",
                  4'h0, 16'h00FF, 32'h5555_AAAA);

        test_case("Balanced 00FF - ODD",
                  4'h1, 16'h00FF, 32'h5555_AAAA);

        test_case("Single 1 LSB - EVEN",
                  4'h0, 16'h0001, 32'h0000_0001);

        test_case("Single 1 LSB - ODD",
                  4'h1, 16'h0001, 32'hAAAA_AAAB);

        test_case("All zeros",
                  4'h0, 16'h0000, 32'h5555_5555);

        test_case("All ones",
                  4'h0, 16'hFFFF, 32'hAAAA_AAAA);

        test_case("Two ones - EVEN",
                  4'h0, 16'h0003, 32'h5555_555A);

        test_case("Two ones - ODD",
                  4'h1, 16'h0003, 32'h5555_555A);

        test_case("Alternating 5555 - EVEN",
                  4'h0, 16'h5555, 32'h6666_6666);

        test_case("Single 1 LSB - ODD",
                  4'h1, 16'h0001, 32'hAAAA_AAAB);

        test_case("Single 1 MSB - EVEN",
                  4'h0, 16'h8000, 32'h4000_0000);

        test_case("Three ones - ODD",
                  4'h1, 16'h0007, 32'hAAAA_AABF);

        $display("\n===== Test Summary =====");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);

        if (failed == 0)
            $display("*** ALL TESTS PASSED ***");
        else
            $display("*** SOME TESTS FAILED ***");

        $finish;
    end

endmodule