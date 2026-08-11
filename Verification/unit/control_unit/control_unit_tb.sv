`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// control_unit_tb - directed unit test for src/system/control_unit.sv
//
// The async FIFO the control unit reads from is read-through: fifo_data_in is
// valid whenever fifo_empty is low, and fifo_en pops that word. The control
// unit peeks without popping in Idle and at header boundaries, so every task
// below holds a word on the bus until it actually sees fifo_en.
//
// Stimulus is driven after posedge, outputs are checked at negedge where the
// combinational outputs have settled.
// ---------------------------------------------------------------------------
module control_unit_tb;

localparam int ADDR_WIDTH = 16;
localparam int DATA_WIDTH = 16;
localparam int WORD_WIDTH = 2 * DATA_WIDTH;

localparam int TIMEOUT_CYCLES = 20;   // guards every wait loop

// Packet type = header SYS_STATE field
localparam logic [1:0] PKT_IDLE     = 2'b00;
localparam logic [1:0] PKT_CONFIG   = 2'b01;
localparam logic [1:0] PKT_LINKUP   = 2'b10;
localparam logic [1:0] PKT_TRANSFER = 2'b11;

// Error codes
localparam logic [1:0] ERR_INVALID_HEADER_PKT = 2'b00;
localparam logic [1:0] ERR_INVALID_ENC        = 2'b01;
localparam logic [1:0] ERR_INVALID_STATE      = 2'b10;

logic                    clk;
logic                    rst_n;

logic                    fifo_empty;
logic                    fifo_en;
logic [WORD_WIDTH-1:0]   fifo_data_in;

logic                    direct_cdm_write;
logic                    w_en;
logic [ADDR_WIDTH-1:0]   addr_out;
logic [DATA_WIDTH-1:0]   data_out;
logic [WORD_WIDTH-1:0]   cfg_data_out;

logic [7:0]              dev_count;

logic                    error_valid;
logic [1:0]              error;

string                   test_name;   // named in every assertion message

control_unit #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
) dut (
    .clk_sys          (clk),
    .rst_n            (rst_n),

    .fifo_empty       (fifo_empty),
    .fifo_en          (fifo_en),
    .fifo_data_in     (fifo_data_in),

    .direct_cdm_write (direct_cdm_write),
    .w_en             (w_en),
    .addr_out         (addr_out),
    .data_out         (data_out),
    .cfg_data_out     (cfg_data_out),

    .dev_count        (dev_count),

    .error_valid      (error_valid),
    .error            (error)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Build a header word: RSV [31:17], ADDR_MODE [16], DEV_COUNT [15:8],
// ENC_MODE [7:4], PARITY_MODE [3:2], SYS_STATE [1:0]
function automatic logic [WORD_WIDTH-1:0] hdr(
    input logic [7:0] devs,
    input logic [3:0] enc,
    input logic [1:0] par,
    input logic [1:0] sys_state
);
    hdr = {15'b0, 1'b0, devs, enc, par, sys_state};
endfunction

// Build a Transfer payload word: ADDR [31:16], DATA [15:0]
function automatic logic [WORD_WIDTH-1:0] payload(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
);
    payload = {addr, data};
endfunction

// Present a word and wait until the DUT pops it. Leaves the simulation at the
// negedge of the popping cycle, so the caller can still see the outputs.
task automatic present_until_pop(input logic [WORD_WIDTH-1:0] word);
    int guard;
    begin
        fifo_data_in = word;
        fifo_empty   = 1'b0;

        guard = 0;
        forever begin
            @(negedge clk);
            if (fifo_en) break;
            guard++;
            if (guard > TIMEOUT_CYCLES)
                $fatal(1, "[%s] DUT never popped word 0x%08h", test_name, word);
        end
    end
endtask

// Release the bus after the popping posedge.
task automatic release_word();
    begin
        @(posedge clk);
        fifo_empty   = 1'b1;
        fifo_data_in = '0;
    end
endtask

// Send a word, no expectation on the write interface.
task automatic send_word(input logic [WORD_WIDTH-1:0] word);
    begin
        present_until_pop(word);
        release_word();
    end
endtask

// Send a word that must not produce a CDM write.
task automatic send_word_nowrite(input logic [WORD_WIDTH-1:0] word);
    begin
        present_until_pop(word);
        assert (w_en === 1'b0)
            else $error("[%s] word 0x%08h: expected no write, got w_en=1 addr=0x%04h",
                        test_name, word, addr_out);
        release_word();
    end
endtask

// Send a word that must produce a configuration (direct) write.
task automatic send_word_cfg_write(
    input logic [WORD_WIDTH-1:0] word,
    input logic [ADDR_WIDTH-1:0] exp_addr
);
    begin
        present_until_pop(word);
        assert (w_en === 1'b1)
            else $error("[%s] word 0x%08h: expected w_en=1", test_name, word);
        assert (direct_cdm_write === 1'b1)
            else $error("[%s] word 0x%08h: expected direct_cdm_write=1", test_name, word);
        assert (addr_out === exp_addr)
            else $error("[%s] word 0x%08h: addr_out=0x%04h expected 0x%04h",
                        test_name, word, addr_out, exp_addr);
        assert (cfg_data_out === word)
            else $error("[%s] word 0x%08h: cfg_data_out=0x%08h expected 0x%08h",
                        test_name, word, cfg_data_out, word);
        release_word();
    end
endtask

// Send a Transfer payload word that must produce an encrypted-path write.
task automatic send_word_data_write(
    input logic [ADDR_WIDTH-1:0] exp_addr,
    input logic [DATA_WIDTH-1:0] exp_data
);
    logic [WORD_WIDTH-1:0] word;
    begin
        word = payload(exp_addr, exp_data);
        present_until_pop(word);
        assert (w_en === 1'b1)
            else $error("[%s] payload 0x%08h: expected w_en=1", test_name, word);
        assert (direct_cdm_write === 1'b0)
            else $error("[%s] payload 0x%08h: expected direct_cdm_write=0", test_name, word);
        assert (addr_out === exp_addr)
            else $error("[%s] payload 0x%08h: addr_out=0x%04h expected 0x%04h",
                        test_name, word, addr_out, exp_addr);
        assert (data_out === exp_data)
            else $error("[%s] payload 0x%08h: data_out=0x%04h expected 0x%04h",
                        test_name, word, data_out, exp_data);
        release_word();
    end
endtask

// After the offending word is consumed the FSM spends one cycle in Error.
task automatic expect_error(input logic [1:0] exp_code);
    int guard;
    begin
        guard = 0;
        forever begin
            @(negedge clk);
            if (error_valid) break;
            guard++;
            if (guard > TIMEOUT_CYCLES)
                $fatal(1, "[%s] expected error_valid, none seen", test_name);
        end
        assert (error === exp_code)
            else $error("[%s] error=%b expected %b", test_name, error, exp_code);
        @(posedge clk);
    end
endtask

// Put the DUT back in Idle so a test can start from a known state.
task automatic reset_dut();
    begin
        fifo_empty   = 1'b1;
        fifo_data_in = '0;
        rst_n        = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    end
endtask

// Starve the DUT for n cycles.
task automatic idle_gap(input int n);
    begin
        fifo_empty   = 1'b1;
        fifo_data_in = '0;
        repeat (n) @(posedge clk);
    end
endtask

// Config phase: header + DEV_COUNT entries + padding to fill the 4-word frame.
// Entries land at 0x0001 upwards; padding words are written too and are
// overwritten later by data (they sit at or past the base address).
task automatic run_config_phase(input logic [7:0] devs, input logic [3:0] enc);
    logic [WORD_WIDTH-1:0] w;
    int idx;
    begin
        dev_count = devs;
        send_word_cfg_write(hdr(devs, enc, 2'b01, PKT_CONFIG), 16'h0000);
        for (idx = 0; idx < 3; idx++) begin
            w = {16'h0010 + 16'(idx), 16'h0050 + 16'(idx)};   // END_ADDR, START_ADDR
            send_word_cfg_write(w, 16'h0001 + 16'(idx));
        end
    end
endtask


// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
initial begin
    logic [WORD_WIDTH-1:0] w;
    int i;

    rst_n        = 1'b0;
    fifo_empty   = 1'b1;
    fifo_data_in = '0;
    dev_count    = 8'd0;
    test_name    = "INIT";

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // =======================================================================
    // TEST 1 - reset state
    // =======================================================================
    test_name = "T1 reset";
    @(negedge clk);
    assert (fifo_en === 1'b0)
        else $error("[%s] fifo_en asserted with an empty FIFO", test_name);
    assert (w_en === 1'b0)
        else $error("[%s] w_en asserted out of reset", test_name);
    assert (error_valid === 1'b0)
        else $error("[%s] error_valid asserted out of reset", test_name);
    @(posedge clk);

    // =======================================================================
    // TEST 2 - Idle drops anything that is not a Config header
    // =======================================================================
    test_name = "T2 idle drop";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_IDLE));

    // =======================================================================
    // TEST 3 - Configuration TLP, DEV_COUNT = 2
    // header -> 0x0000, entries -> 0x0001/0x0002, padding word -> 0x0003
    // =======================================================================
    test_name = "T3 config tlp";
    run_config_phase(8'd2, 4'h0);

    // =======================================================================
    // TEST 4 - Config -> Link-up. The header carries no write, the payload
    // words of the Link-up packet are written like any other data.
    // =======================================================================
    test_name = "T4 link-up";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP));
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0600 + 16'(i), 16'h1000 + 16'(i));

    // =======================================================================
    // TEST 5 - Transfer TLP: header consumed, 3 payloads written
    // =======================================================================
    test_name = "T5 transfer tlp";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));
    send_word_data_write(16'h0100, 16'hA001);
    send_word_data_write(16'h0101, 16'hA002);
    send_word_data_write(16'h0102, 16'hA003);

    // =======================================================================
    // TEST 6 - back-to-back Transfer TLP, frame alignment must hold
    // =======================================================================
    test_name = "T6 transfer tlp 2";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));
    send_word_data_write(16'h0200, 16'hB001);
    send_word_data_write(16'h0201, 16'hB002);
    send_word_data_write(16'h0202, 16'hB003);

    // =======================================================================
    // TEST 7 - Link-up packet arriving during the data phase
    // =======================================================================
    test_name = "T7 link-up in data";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP));
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0700 + 16'(i), 16'h2000 + 16'(i));

    // =======================================================================
    // TEST 8 - Config header during the data phase is an invalid transition
    // =======================================================================
    test_name = "T8 config in data";
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));   // enter data phase
    send_word_data_write(16'h0300, 16'hC001);
    send_word_data_write(16'h0301, 16'hC002);
    send_word_data_write(16'h0302, 16'hC003);
    send_word(hdr(8'd2, 4'h0, 2'b01, PKT_CONFIG));             // header boundary
    expect_error(ERR_INVALID_STATE);
    idle_gap(2);

    // =======================================================================
    // TEST 9 - unsupported ENC_MODE in the first configuration header
    // =======================================================================
    test_name = "T9 invalid enc";
    dev_count = 8'd2;
    send_word(hdr(8'd2, 4'h5, 2'b01, PKT_CONFIG));
    expect_error(ERR_INVALID_ENC);
    idle_gap(2);

    // =======================================================================
    // TEST 10 - addresses finished but the next header is not Link-up
    // =======================================================================
    test_name = "T10 bad hdr after config";
    run_config_phase(8'd2, 4'h0);
    send_word(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));   // should have been Link-up
    expect_error(ERR_INVALID_STATE);
    idle_gap(2);

    // =======================================================================
    // TEST 11 - non-Config header while entries are still outstanding
    // DEV_COUNT = 6 needs a second Configuration TLP; send Link-up instead.
    // =======================================================================
    test_name = "T11 early hdr";
    dev_count = 8'd6;
    send_word_cfg_write(hdr(8'd6, 4'h0, 2'b01, PKT_CONFIG), 16'h0000);
    for (i = 0; i < 3; i++)
        send_word_cfg_write({16'h0020 + 16'(i), 16'h0060 + 16'(i)}, 16'h0001 + 16'(i));
    send_word(hdr(8'd6, 4'h0, 2'b01, PKT_LINKUP));    // only 3 of 6 entries written
    expect_error(ERR_INVALID_STATE);
    idle_gap(2);

    // =======================================================================
    // TEST 12 - recovery: the FSM is back in Idle and configures again
    // =======================================================================
    test_name = "T12 recovery";
    run_config_phase(8'd2, 4'h1);
    send_word_nowrite(hdr(8'd2, 4'h1, 2'b01, PKT_LINKUP));
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0800 + 16'(i), 16'h3000 + 16'(i));
    send_word_nowrite(hdr(8'd2, 4'h1, 2'b01, PKT_TRANSFER));
    send_word_data_write(16'h0400, 16'hD001);
    send_word_data_write(16'h0401, 16'hD002);
    send_word_data_write(16'h0402, 16'hD003);

    // =======================================================================
    // TEST 13 - same sequence with the FIFO randomly starved between words.
    // The word-position counter must survive the gaps.
    // T12 leaves the FSM in the data phase, so start from a clean reset.
    // =======================================================================
    test_name = "T13 random stalls";
    reset_dut();

    // a full config phase, one word at a time with random gaps
    dev_count = 8'd2;
    idle_gap($urandom_range(0, 3));
    send_word_cfg_write(hdr(8'd2, 4'h0, 2'b01, PKT_CONFIG), 16'h0000);
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_cfg_write({16'h0030 + 16'(i), 16'h0070 + 16'(i)}, 16'h0001 + 16'(i));
    end

    idle_gap($urandom_range(0, 3));
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP));
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_data_write(16'h0900 + 16'(i), 16'h4000 + 16'(i));
    end

    idle_gap($urandom_range(0, 3));
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_data_write(16'h0500 + 16'(i), 16'hE000 + 16'(i));
    end

    repeat (4) @(posedge clk);
    $display("control_unit_tb: all directed tests completed");
    $finish;
end

endmodule
