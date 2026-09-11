`timescale 1ns/1ps

// ===========================================================================
// control_unit_tb - Self-checking directed unit test for control_unit
// ===========================================================================
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

string                   current_tc_name;

// Verification Tracking
int pass_count = 0;
int fail_count = 0;

// DUT Instantiation
control_unit #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
) dut (
    .i_control_unit_clk              (clk),
    .i_control_unit_rst_n            (rst_n),

    .i_control_unit_fifo_empty       (fifo_empty),
    .o_control_unit_fifo_en          (fifo_en),
    .i_control_unit_fifo_data_in     (fifo_data_in),

    .o_control_unit_direct_cdm_write (direct_cdm_write),
    .o_control_unit_w_en             (w_en),
    .o_control_unit_addr_out         (addr_out),
    .o_control_unit_data_out         (data_out),
    .o_control_unit_cfg_data_out     (cfg_data_out),

    .i_control_unit_dev_count        (dev_count),

    .o_control_unit_error_valid      (error_valid),
    .o_control_unit_error            (error)
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
        current_tc_name = name;
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
        $display("#           CONTROL UNIT TESTBENCH SUMMARY");
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

// Build a header word: BASE_ADDR [31:16], DEV_COUNT [15:8], ENC_MODE [7:4],
// ADDR_MODE [3], PARITY_MODE [2], SYS_STATE [1:0]
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
            if (guard > TIMEOUT_CYCLES) begin
                check($sformatf("[%s] DUT popped word 0x%08h", current_tc_name, word), 1'b0, "TIMEOUT");
                break;
            end
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
task automatic send_word_nowrite(input logic [WORD_WIDTH-1:0] word, input string desc = "");
    begin
        present_until_pop(word);
        check($sformatf("%s %s (w_en=0)", current_tc_name, (desc != "") ? desc : "drop word"),
              w_en === 1'b0,
              $sformatf("Got w_en=%b, addr=0x%04h", w_en, addr_out));
        release_word();
    end
endtask

// Send a word that must produce a configuration (direct) write.
task automatic send_word_cfg_write(
    input logic [WORD_WIDTH-1:0] word,
    input logic [ADDR_WIDTH-1:0] exp_addr,
    input string                 desc = ""
);
    begin
        present_until_pop(word);
        check($sformatf("%s %s w_en asserted", current_tc_name, desc), w_en === 1'b1);
        check($sformatf("%s %s direct_cdm_write asserted", current_tc_name, desc), direct_cdm_write === 1'b1);
        check($sformatf("%s %s addr_out matched (0x%04h)", current_tc_name, desc, exp_addr),
              addr_out === exp_addr,
              $sformatf("[Exp: 0x%04h, Got: 0x%04h]", exp_addr, addr_out));
        check($sformatf("%s %s cfg_data_out matched (0x%08h)", current_tc_name, desc, word),
              cfg_data_out === word,
              $sformatf("[Exp: 0x%08h, Got: 0x%08h]", word, cfg_data_out));
        release_word();
    end
endtask

// Send a Transfer payload word that must produce an encrypted-path write.
task automatic send_word_data_write(
    input logic [ADDR_WIDTH-1:0] exp_addr,
    input logic [DATA_WIDTH-1:0] exp_data,
    input string                 desc = ""
);
    logic [WORD_WIDTH-1:0] word;
    begin
        word = payload(exp_addr, exp_data);
        present_until_pop(word);
        check($sformatf("%s %s w_en asserted", current_tc_name, desc), w_en === 1'b1);
        check($sformatf("%s %s direct_cdm_write=0 (payload path)", current_tc_name, desc), direct_cdm_write === 1'b0);
        check($sformatf("%s %s addr_out matched (0x%04h)", current_tc_name, desc, exp_addr),
              addr_out === exp_addr,
              $sformatf("[Exp: 0x%04h, Got: 0x%04h]", exp_addr, addr_out));
        check($sformatf("%s %s data_out matched (0x%04h)", current_tc_name, desc, exp_data),
              data_out === exp_data,
              $sformatf("[Exp: 0x%04h, Got: 0x%04h]", exp_data, data_out));
        release_word();
    end
endtask

// Expect error pulse and code
task automatic expect_error(input logic [1:0] exp_code, input string desc = "");
    int guard;
    logic seen;
    begin
        guard = 0;
        seen  = 1'b0;
        forever begin
            @(negedge clk);
            if (error_valid) begin
                seen = 1'b1;
                break;
            end
            guard++;
            if (guard > TIMEOUT_CYCLES) break;
        end
        check($sformatf("%s %s error_valid asserted", current_tc_name, desc), seen === 1'b1);
        check($sformatf("%s %s error code matched (%0b)", current_tc_name, desc, exp_code),
              error === exp_code,
              $sformatf("[Exp: %0b, Got: %0b]", exp_code, error));
        @(posedge clk);
    end
endtask

task automatic reset_dut();
    begin
        fifo_empty   = 1'b1;
        fifo_data_in = '0;
        rst_n        = 1'b0;
        repeat (2) @(posedge clk);
        rst_n        = 1'b1;
        repeat (2) @(posedge clk);
    end
endtask

task automatic idle_gap(input int n);
    begin
        fifo_empty   = 1'b1;
        fifo_data_in = '0;
        repeat (n) @(posedge clk);
    end
endtask

task automatic run_config_phase(input logic [7:0] devs, input logic [3:0] enc);
    logic [WORD_WIDTH-1:0] w;
    int idx;
    begin
        dev_count = devs;
        send_word_cfg_write(hdr(devs, enc, 2'b01, PKT_CONFIG), 16'h0000, "Header Config Write");
        for (idx = 0; idx < 3; idx++) begin
            w = {16'h0010 + 16'(idx), 16'h0050 + 16'(idx)};
            send_word_cfg_write(w, 16'h0001 + 16'(idx), $sformatf("Entry %0d Config Write", idx));
        end
    end
endtask

// ---------------------------------------------------------------------------
// Main Test Sequencer
// ---------------------------------------------------------------------------
initial begin
    int i;

    rst_n        = 1'b0;
    fifo_empty   = 1'b1;
    fifo_data_in = '0;
    dev_count    = 8'd0;

    // =======================================================================
    // TC1 : RESET STATE
    // =======================================================================
    print_tc_banner("TC1 : RESET STATE");
    repeat (2) @(posedge clk);
    @(negedge clk);
    check("TC1 fifo_en deasserted out of reset", fifo_en === 1'b0);
    check("TC1 w_en deasserted out of reset", w_en === 1'b0);
    check("TC1 error_valid deasserted out of reset", error_valid === 1'b0);
    @(posedge clk);

    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // =======================================================================
    // TC2 : IDLE DROP (Transfer/Idle packets ignored before Config)
    // =======================================================================
    print_tc_banner("TC2 : IDLE DROP NON-CONFIG PACKETS");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER), "dropped unexpected transfer");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_IDLE), "dropped idle packet");

    // =======================================================================
    // TC3 : CONFIGURATION TLP (DEV_COUNT = 2)
    // =======================================================================
    print_tc_banner("TC3 : CONFIGURATION TLP");
    run_config_phase(8'd2, 4'h0);

    // =======================================================================
    // TC4 : LINK-UP PACKET TRANSITION
    // =======================================================================
    print_tc_banner("TC4 : LINK-UP PACKET");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP), "Link-up Header (no write)");
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0600 + 16'(i), 16'h1000 + 16'(i), $sformatf("Link-up payload %0d", i));

    // =======================================================================
    // TC5 : TRANSFER TLP (Single Packet)
    // =======================================================================
    print_tc_banner("TC5 : TRANSFER TLP");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER), "Transfer Header (no write)");
    send_word_data_write(16'h0100, 16'hA001, "word 0");
    send_word_data_write(16'h0101, 16'hA002, "word 1");
    send_word_data_write(16'h0102, 16'hA003, "word 2");

    // =======================================================================
    // TC6 : BACK-TO-BACK TRANSFER TLPs
    // =======================================================================
    print_tc_banner("TC6 : BACK-TO-BACK TRANSFER TLPs");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER), "Transfer 2 Header");
    send_word_data_write(16'h0200, 16'hB001, "word 0");
    send_word_data_write(16'h0201, 16'hB002, "word 1");
    send_word_data_write(16'h0202, 16'hB003, "word 2");

    // =======================================================================
    // TC7 : LINK-UP ARRIVING DURING DATA PHASE
    // =======================================================================
    print_tc_banner("TC7 : LINK-UP IN DATA PHASE");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP), "Link-up in data Header");
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0700 + 16'(i), 16'h2000 + 16'(i), $sformatf("payload %0d", i));

    // =======================================================================
    // TC8 : ERROR INJECTION - CONFIG IN DATA PHASE
    // =======================================================================
    print_tc_banner("TC8 : INVALID TRANSITION (CONFIG IN DATA)");
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER), "Transfer Header");
    send_word_data_write(16'h0300, 16'hC001, "word 0");
    send_word_data_write(16'h0301, 16'hC002, "word 1");
    send_word_data_write(16'h0302, 16'hC003, "word 2");
    send_word(hdr(8'd2, 4'h0, 2'b01, PKT_CONFIG));
    expect_error(ERR_INVALID_STATE, "State error on Config in Data");
    idle_gap(2);

    // =======================================================================
    // TC9 : ERROR INJECTION - UNSUPPORTED ENC MODE
    // =======================================================================
    print_tc_banner("TC9 : UNSUPPORTED ENCRYPTION MODE");
    dev_count = 8'd2;
    send_word(hdr(8'd2, 4'h5, 2'b01, PKT_CONFIG));
    expect_error(ERR_INVALID_ENC, "Encryption Mode error");
    idle_gap(2);

    // =======================================================================
    // TC10 : ERROR INJECTION - BAD HEADER AFTER CONFIG
    // =======================================================================
    print_tc_banner("TC10 : BAD HEADER AFTER CONFIG");
    run_config_phase(8'd2, 4'h0);
    send_word(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER));
    expect_error(ERR_INVALID_STATE, "State error on Transfer after Config");
    idle_gap(2);

    // =======================================================================
    // TC11 : ERROR INJECTION - EARLY HEADER BEFORE DEV_COUNT COMPLETE
    // =======================================================================
    print_tc_banner("TC11 : PREMATURE HEADER (INCOMPLETE DEV_COUNT)");
    dev_count = 8'd6;
    send_word_cfg_write(hdr(8'd6, 4'h0, 2'b01, PKT_CONFIG), 16'h0000, "Config 1 Header");
    for (i = 0; i < 3; i++)
        send_word_cfg_write({16'h0020 + 16'(i), 16'h0060 + 16'(i)}, 16'h0001 + 16'(i), $sformatf("Entry %0d", i));
    send_word(hdr(8'd6, 4'h0, 2'b01, PKT_LINKUP));
    expect_error(ERR_INVALID_STATE, "State error on incomplete config entries");
    idle_gap(2);

    // =======================================================================
    // TC12 : ERROR RECOVERY
    // =======================================================================
    print_tc_banner("TC12 : FSM ERROR RECOVERY");
    run_config_phase(8'd2, 4'h1);
    send_word_nowrite(hdr(8'd2, 4'h1, 2'b01, PKT_LINKUP), "Link-up Header");
    for (i = 0; i < 3; i++)
        send_word_data_write(16'h0800 + 16'(i), 16'h3000 + 16'(i), $sformatf("Link-up data %0d", i));
    send_word_nowrite(hdr(8'd2, 4'h1, 2'b01, PKT_TRANSFER), "Transfer Header");
    send_word_data_write(16'h0400, 16'hD001, "word 0");
    send_word_data_write(16'h0401, 16'hD002, "word 1");
    send_word_data_write(16'h0402, 16'hD003, "word 2");

    // =======================================================================
    // TC13 : RANDOM FIFO STALLS (SURVIVING GAPS)
    // =======================================================================
    print_tc_banner("TC13 : RANDOM FIFO STARVATION & STALLS");
    reset_dut();

    dev_count = 8'd2;
    idle_gap($urandom_range(0, 3));
    send_word_cfg_write(hdr(8'd2, 4'h0, 2'b01, PKT_CONFIG), 16'h0000, "Config Header");
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_cfg_write({16'h0030 + 16'(i), 16'h0070 + 16'(i)}, 16'h0001 + 16'(i), $sformatf("Config entry %0d", i));
    end

    idle_gap($urandom_range(0, 3));
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_LINKUP), "Link-up Header");
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_data_write(16'h0900 + 16'(i), 16'h4000 + 16'(i), $sformatf("Link-up word %0d", i));
    end

    idle_gap($urandom_range(0, 3));
    send_word_nowrite(hdr(8'd2, 4'h0, 2'b01, PKT_TRANSFER), "Transfer Header");
    for (i = 0; i < 3; i++) begin
        idle_gap($urandom_range(0, 3));
        send_word_data_write(16'h0500 + 16'(i), 16'hE000 + 16'(i), $sformatf("Transfer word %0d", i));
    end

    repeat (4) @(posedge clk);

    // =======================================================================
    // FINAL SUMMARY
    // =======================================================================
    print_summary();

    $finish;
end

endmodule
