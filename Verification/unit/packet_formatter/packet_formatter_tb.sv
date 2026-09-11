`timescale 1ns/1ps

// ===========================================================================
// packet_formatter_tb - Self-checking directed unit test for packet_formatter
// ===========================================================================
module packet_formatter_tb;

localparam int CXS_DATA_WIDTH       = 256;
localparam int CXS_CNTL_WIDTH       = 14;
localparam int WORD_WIDTH           = 32;
localparam int CXSMAXPKTPERFLIT     = 2;
localparam int FLIT_WIDTH           = CXS_DATA_WIDTH + CXS_CNTL_WIDTH;
localparam int WORDS_PER_FLIT       = CXS_DATA_WIDTH / WORD_WIDTH;

logic                     clk;
logic                     rst_n;

logic                     flit_fifo_empty;
logic [FLIT_WIDTH-1:0]    flit_fifo_rdata;
logic                     async_fifo_full;

logic                     flit_fifo_rd;
logic                     async_fifo_w_en;
logic [WORD_WIDTH-1:0]    async_fifo_w_data;

// Verification Tracking
int pass_count = 0;
int fail_count = 0;

// DUT Instantiation
packet_formatter #(
    .CXS_DATA_WIDTH      (CXS_DATA_WIDTH),
    .CXS_CNTL_WIDTH      (CXS_CNTL_WIDTH),
    .WORD_WIDTH          (WORD_WIDTH),
    .CXSMAXPKTPERFLIT    (CXSMAXPKTPERFLIT),
    .FLIT_WIDTH          (FLIT_WIDTH)
) dut (
    .i_packet_formatter_rst_n              (rst_n),
    .i_packet_formatter_clk                (clk),

    .i_packet_formatter_flit_fifo_empty    (flit_fifo_empty),
    .i_packet_formatter_flit_fifo_rdata    (flit_fifo_rdata),
    .i_packet_formatter_async_fifo_full    (async_fifo_full),

    .o_packet_formatter_flit_fifo_rd       (flit_fifo_rd),
    .o_packet_formatter_async_fifo_w_en    (async_fifo_w_en),
    .o_packet_formatter_async_fifo_w_data  (async_fifo_w_data)
);

// Clock Generation (100 MHz, 10 ns period)
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// ---------------------------------------------------------------------------
// Logging & Checking Helpers
// ---------------------------------------------------------------------------
task automatic print_tc_banner(string name);
    begin
        $display("");
        $display("# ------------------ %s ------------------", name);
    end
endtask

task automatic check(string desc, logic condition, string details = "");
    begin
        if (condition) begin
            $display("# [%0t] PASS: %s", $time, desc);
            pass_count++;
        end else begin
            $display("# [%0t] FAIL: %s %s", $time, desc, details);
            fail_count++;
        end
    end
endtask

task automatic print_summary();
    begin
        $display("");
        $display("# ===================================================");
        $display("#         PACKET FORMATTER TESTBENCH SUMMARY");
        $display("# ===================================================");
        $display("# PASS        = %0d", pass_count);
        $display("# FAIL        = %0d", fail_count);
        if (fail_count == 0)
            $display("# RESULT      = ALL TESTS PASSED");
        else
            $display("# RESULT      = TESTS FAILED");
        $display("# ===================================================");
    end
endtask

// Task to drive a FLIT and verify word-by-word streaming
task automatic send_and_verify_flit(
    input string                         tc_name,
    input logic [CXS_CNTL_WIDTH-1:0]     ctrl,
    input logic [CXS_DATA_WIDTH-1:0]     data,
    input logic [WORDS_PER_FLIT-1:0]     expected_valid_mask, // 1 = word emitted, 0 = word dropped
    input logic [WORD_WIDTH-1:0]         expected_words [WORDS_PER_FLIT]
);
    int w_idx;
    logic rd_seen;
    begin
        // Present FLIT to FIFO interface
        flit_fifo_empty = 1'b0;
        flit_fifo_rdata = {ctrl, data};
        rd_seen         = 1'b0;

        // Wait for DUT to assert read acknowledge
        @(posedge clk);
        while (!flit_fifo_rd) begin
            @(posedge clk);
        end
        rd_seen = 1'b1;
        check({tc_name, " FLIT FIFO read asserted"}, rd_seen);

        // Keep rdata stable during capture cycle
        @(posedge clk);
        flit_fifo_empty = 1'b1;
        flit_fifo_rdata = '0;

        // DUT transitions to S_STREAM and evaluates words 0 through WORDS_PER_FLIT-1
        for (w_idx = 0; w_idx < WORDS_PER_FLIT; w_idx++) begin
            @(negedge clk); // Sample after combinational logic settles
            if (expected_valid_mask[w_idx]) begin
                check($sformatf("%s word %0d valid asserted", tc_name, w_idx),
                      async_fifo_w_en === 1'b1);
                check($sformatf("%s word %0d data matched (DATA=%08h)", tc_name, w_idx, async_fifo_w_data),
                      async_fifo_w_data === expected_words[w_idx],
                      $sformatf("[Exp: %08h, Got: %08h]", expected_words[w_idx], async_fifo_w_data));
            end else begin
                check($sformatf("%s word %0d dropped correctly (w_en=0)", tc_name, w_idx),
                      async_fifo_w_en === 1'b0);
            end
            @(posedge clk);
        end

        // Ensure DUT returns to IDLE
        @(negedge clk);
        check({tc_name, " all words processed, w_en deasserted"}, async_fifo_w_en === 1'b0);
        @(posedge clk);
    end
endtask

// ---------------------------------------------------------------------------
// Test Sequence
// ---------------------------------------------------------------------------
initial begin
    logic [WORD_WIDTH-1:0] words_test1 [WORDS_PER_FLIT];
    logic [WORD_WIDTH-1:0] words_test2 [WORDS_PER_FLIT];
    logic [WORD_WIDTH-1:0] words_test3 [WORDS_PER_FLIT];
    logic [WORD_WIDTH-1:0] words_test4 [WORDS_PER_FLIT];
    logic [WORD_WIDTH-1:0] words_test5 [WORDS_PER_FLIT];
    int k;

    rst_n           = 1'b0;
    flit_fifo_empty = 1'b1;
    flit_fifo_rdata = '0;
    async_fifo_full = 1'b0;

    // =======================================================================
    // TC1 : RESET
    // =======================================================================
    print_tc_banner("TC1 : RESET");
    repeat (2) @(posedge clk);
    @(negedge clk);
    check("TC1 flit_fifo_rd after reset = 0", flit_fifo_rd === 1'b0);
    check("TC1 async_fifo_w_en after reset = 0", async_fifo_w_en === 1'b0);
    check("TC1 async_fifo_w_data reset to zero", async_fifo_w_data === '0);
    @(posedge clk);

    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // =======================================================================
    // TC2 : SINGLE PACKET (Words 0, 1, 2)
    // START0=1, START0PTR=0, END0=1, END0PTR=2 -> Words 0..2 streamed, 3..7 dropped
    // CXSCNTL: [13:11]=000, [10:8]=010, [7:6]=00, [5:4]=01, [3]=0, [2]=0, [1:0]=01
    // =======================================================================
    print_tc_banner("TC2 : SINGLE PACKET (WORDS 0..2)");
    words_test1[0] = 32'h1111_1111;
    words_test1[1] = 32'h2222_2222;
    words_test1[2] = 32'h3333_3333;
    words_test1[3] = 32'h4444_4444;
    words_test1[4] = 32'h5555_5555;
    words_test1[5] = 32'h6666_6666;
    words_test1[6] = 32'h7777_7777;
    words_test1[7] = 32'hAAAA_AAAA;

    send_and_verify_flit(
        "TC2",
        14'b000_010_00_01_0_0_01,
        {words_test1[7], words_test1[6], words_test1[5], words_test1[4],
         words_test1[3], words_test1[2], words_test1[1], words_test1[0]},
        8'b0000_0111, // only words 0, 1, 2 enabled
        words_test1
    );

    repeat (2) @(posedge clk);

    // =======================================================================
    // TC3 : SINGLE PACKET OFFSET (Words 4, 5, 6, 7)
    // START0=1, START0PTR=1 (start at word 4), END0=1, END0PTR=7
    // Words 0..3 dropped, Words 4..7 streamed
    // CXSCNTL = 000_111_00_01_0_1_01
    // =======================================================================
    print_tc_banner("TC3 : SINGLE PACKET OFFSET (WORDS 4..7)");
    words_test2[0] = 32'h4444_4444;
    words_test2[1] = 32'h5555_5555;
    words_test2[2] = 32'h6666_6666;
    words_test2[3] = 32'h7777_7777;
    words_test2[4] = 32'h8888_8888;
    words_test2[5] = 32'h9999_9999;
    words_test2[6] = 32'hAAAA_AAAA;
    words_test2[7] = 32'hBBBB_BBBB;

    send_and_verify_flit(
        "TC3",
        14'b000_111_00_01_0_1_01,
        {words_test2[7], words_test2[6], words_test2[5], words_test2[4],
         words_test2[3], words_test2[2], words_test2[1], words_test2[0]},
        8'b1111_0000, // only words 4, 5, 6, 7 enabled
        words_test2
    );

    repeat (2) @(posedge clk);

    // =======================================================================
    // TC4 : TWO PACKETS IN ONE FLIT
    // Pkt 0: Words 0..1 (START0=1, START0PTR=0, END0=1, END0PTR=1)
    // Pkt 1: Words 4..6 (START1=1, START1PTR=1, END1=1, END1PTR=6)
    // CXSCNTL: END1PTR=110, END0PTR=001, END=11, START1PTR=1, START0PTR=0, START=11
    // =======================================================================
    print_tc_banner("TC4 : TWO PACKETS IN ONE FLIT");
    words_test3[0] = 32'hDEAD_0000;
    words_test3[1] = 32'hDEAD_0001;
    words_test3[2] = 32'h0000_0000; // drop
    words_test3[3] = 32'h0000_0000; // drop
    words_test3[4] = 32'hBEEF_0004;
    words_test3[5] = 32'hBEEF_0005;
    words_test3[6] = 32'hBEEF_0006;
    words_test3[7] = 32'h0000_0000; // drop

    send_and_verify_flit(
        "TC4",
        14'b110_001_00_11_1_0_11,
        {words_test3[7], words_test3[6], words_test3[5], words_test3[4],
         words_test3[3], words_test3[2], words_test3[1], words_test3[0]},
        8'b0111_0011, // words 0,1 and 4,5,6 enabled
        words_test3
    );

    repeat (2) @(posedge clk);

    // =======================================================================
    // TC5 : FULL FLIT STREAMING (Words 0..7)
    // START0=1, START0PTR=0, END0=1, END0PTR=7 -> all 8 words valid
    // CXSCNTL = 000_111_00_01_0_0_01
    // =======================================================================
    print_tc_banner("TC5 : FULL FLIT STREAMING (WORDS 0..7)");
    for (k = 0; k < 8; k++) words_test4[k] = 32'hC000_0000 + k;

    send_and_verify_flit(
        "TC5",
        14'b000_111_00_01_0_0_01,
        {words_test4[7], words_test4[6], words_test4[5], words_test4[4],
         words_test4[3], words_test4[2], words_test4[1], words_test4[0]},
        8'b1111_1111, // all words enabled
        words_test4
    );

    repeat (2) @(posedge clk);

    // =======================================================================
    // TC6 : ASYNC FIFO BACKPRESSURE (STALL TEST)
    // DUT captures FLIT, streams words 0..1, then stalls when async_fifo_full=1.
    // Word counter must freeze. When FIFO releases, stream completes accurately.
    // =======================================================================
    print_tc_banner("TC6 : ASYNC FIFO BACKPRESSURE (STALL)");
    for (k = 0; k < 8; k++) words_test5[k] = 32'hF000_0000 + k;

    flit_fifo_empty = 1'b0;
    flit_fifo_rdata = {14'b000_010_00_01_0_0_01, // words 0..2 valid
                       words_test5[7], words_test5[6], words_test5[5], words_test5[4],
                       words_test5[3], words_test5[2], words_test5[1], words_test5[0]};

    @(posedge clk);
    wait (flit_fifo_rd);
    @(posedge clk);
    flit_fifo_empty = 1'b1;

    // Word 0 is streaming
    @(negedge clk);
    check("TC6 word 0 valid before stall", async_fifo_w_en === 1'b1);
    check("TC6 word 0 data correct", async_fifo_w_data === words_test5[0]);
    @(posedge clk);

    // Assert backpressure (FIFO full)
    async_fifo_full = 1'b1;
    @(negedge clk);
    check("TC6 word 1 held during backpressure", async_fifo_w_data === words_test5[1]);
    @(posedge clk);

    // Keep FIFO full for 4 clock cycles - DUT must pause and not advance
    repeat (4) begin
        @(negedge clk);
        check("TC6 backpressure active - word remains steady", async_fifo_w_data === words_test5[1]);
        @(posedge clk);
    end

    // Release backpressure
    async_fifo_full = 1'b0;
    @(negedge clk);
    check("TC6 backpressure released - word 1 valid", async_fifo_w_en === 1'b1);
    check("TC6 word 1 data correct", async_fifo_w_data === words_test5[1]);
    @(posedge clk);

    @(negedge clk);
    check("TC6 word 2 valid after resume", async_fifo_w_en === 1'b1);
    check("TC6 word 2 data correct", async_fifo_w_data === words_test5[2]);
    @(posedge clk);

    repeat (6) @(posedge clk);

    // =======================================================================
    // FINAL SUMMARY
    // =======================================================================
    print_summary();

    $finish;
end

endmodule
