package directed_seq_pkg;
    import uvm_pkg::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    // SYS_STATE field of the TLP header = packet type (spec 6.2.1)
    localparam logic [1:0] SYS_IDLE     = 2'b00;
    localparam logic [1:0] SYS_CONFIG   = 2'b01;
    localparam logic [1:0] SYS_LINKUP   = 2'b10;
    localparam logic [1:0] SYS_TRANSFER = 2'b11;

    // BASE_ADDR is the full 16 bits of header [31:16]
    localparam logic [15:0] BASE_ADDR = 16'h0100;

    localparam logic [3:0] ENC_EVEN    = 4'h0;
    localparam logic [3:0] ENC_INVALID = 4'h5;
    localparam logic       PAR_EVEN    = 1'b0;

    // ADDR_MODE, header bit [3]. Range mode is the only mode the ATU implements.
    localparam logic       ADDR_RANGE  = 1'b0;


    // -----------------------------------------------------------------------
    // Base sequence: TLP / FLIT construction helpers and item shorthands.
    // -----------------------------------------------------------------------
    class enc_sys_base_seq extends uvm_sequence #(enc_sys_seq_item);
        `uvm_object_utils(enc_sys_base_seq)

        int unsigned  tnum;
        logic [127:0] tname;

        function new(string name = "enc_sys_base_seq");
            super.new(name);
            tnum  = 0;
            tname = "NONE";
        endfunction

        // Header word: BASE_ADDR [31:16], DEV_COUNT [15:8], ENC_MODE [7:4],
        // ADDR_MODE [3], PARITY_MODE [2], SYS_STATE [1:0]
        function logic [31:0] hdr(logic [15:0] base_addr, logic [7:0] devs,
                                  logic [3:0] enc, logic par,
                                  logic [1:0] sys_state);
            return {base_addr, devs, enc, ADDR_RANGE, par, sys_state};
        endfunction

        // Transfer payload word: ADDR [31:16], DATA [15:0]
        function logic [31:0] payload(logic [15:0] addr, logic [15:0] data);
            return {addr, data};
        endfunction

        // Device configuration entry: END_ADDR [31:16], START_ADDR [15:0]
        function logic [31:0] dev_entry(logic [15:0] start_addr, logic [15:0] end_addr);
            return {end_addr, start_addr};
        endfunction

        // Control field for the packet held in FLIT slot "slot", occupying the
        // 32-bit words start_ptr*4 .. end_ptr, as decoded by packet_formatter.
        function logic [13:0] make_cntl(int slot, int start_ptr, int end_ptr);
            logic [13:0] c;
            c = '0;
            c[0 + slot]        = 1'b1;           // START[slot]
            c[2 + slot]        = start_ptr[0];   // START_PTR[slot]
            c[4 + slot]        = 1'b1;           // END[slot]
            c[8 + 3*slot +: 3] = end_ptr[2:0];   // END_PTR[slot]
            return c;
        endfunction

        task send_reset(int unsigned cyc = 5);
            enc_sys_seq_item it;
            it = enc_sys_seq_item::type_id::create("it");
            start_item(it);
            it.op = OP_RESET; it.cycles = cyc;
            it.test_num = tnum; it.test_name = tname;
            finish_item(it);
        endtask

        task send_flit(logic [255:0] d, logic [13:0] c);
            enc_sys_seq_item it;
            it = enc_sys_seq_item::type_id::create("it");
            start_item(it);
            it.op = OP_FLIT; it.data = d; it.cntl = c;
            it.test_num = tnum; it.test_name = tname;
            finish_item(it);
        endtask

        task send_idle(int unsigned cyc);
            enc_sys_seq_item it;
            it = enc_sys_seq_item::type_id::create("it");
            start_item(it);
            it.op = OP_IDLE; it.cycles = cyc;
            it.test_num = tnum; it.test_name = tname;
            finish_item(it);
        endtask

        task tx_credit(logic v, int unsigned cyc = 1);
            enc_sys_seq_item it;
            it = enc_sys_seq_item::type_id::create("it");
            start_item(it);
            it.op = OP_TX_CRD; it.tx_crdgnt = v; it.cycles = cyc;
            it.test_num = tnum; it.test_name = tname;
            finish_item(it);
        endtask
    endclass


    // -----------------------------------------------------------------------
    // Test 1 - Configuration, Link-Up and Transfer, one TLP per FLIT.
    // -----------------------------------------------------------------------
    class cfg_link_xfer_seq extends enc_sys_base_seq;
        `uvm_object_utils(cfg_link_xfer_seq)

        function new(string name = "cfg_link_xfer_seq");
            super.new(name);
            tnum = 1; tname = "CFG_LINK_XFER";
        endfunction

        task body();
            logic [255:0] flit;

            send_reset(5);

            // Configuration TLP: header at CDM 0x0000, device entries at 0x0001+
            flit          = '0;
            flit[31:0]    = hdr(BASE_ADDR, 8'd2, ENC_EVEN, PAR_EVEN, SYS_CONFIG);
            flit[63:32]   = dev_entry(16'h0100, 16'h010F);
            flit[95:64]   = dev_entry(16'h0110, 16'h011F);
            flit[127:96]  = dev_entry(16'h0120, 16'h012F);
            send_flit(flit, make_cntl(0, 0, 3));
            send_idle(25);

            // Link-Up TLP: header carries no write, its payload words do
            flit          = '0;
            flit[31:0]    = hdr(BASE_ADDR, 8'd2, ENC_EVEN, PAR_EVEN, SYS_LINKUP);
            flit[63:32]   = payload(16'h0010, 16'h1111);
            flit[95:64]   = payload(16'h0011, 16'h2222);
            flit[127:96]  = payload(16'h0012, 16'h3333);
            send_flit(flit, make_cntl(0, 0, 3));
            send_idle(25);

            // Transfer TLP: payloads land encrypted + parity at BASE_ADDR + ADDR
            flit          = '0;
            flit[31:0]    = hdr(BASE_ADDR, 8'd2, ENC_EVEN, PAR_EVEN, SYS_TRANSFER);
            flit[63:32]   = payload(16'h0002, 16'hA5A5);
            flit[95:64]   = payload(16'h0003, 16'h5A5A);
            flit[127:96]  = payload(16'h0004, 16'hFFFF);
            send_flit(flit, make_cntl(0, 0, 3));
            send_idle(30);
        endtask
    endclass


    // -----------------------------------------------------------------------
    // Test 2 - Two Transfer TLPs packed into a single FLIT (words 0-3, 4-7).
    // Runs straight after test 1, which leaves the FSM in the data phase.
    // -----------------------------------------------------------------------
    class two_tlp_seq extends enc_sys_base_seq;
        `uvm_object_utils(two_tlp_seq)

        function new(string name = "two_tlp_seq");
            super.new(name);
            tnum = 2; tname = "TWO_TLP_ONE_FLIT";
        endfunction

        task body();
            logic [255:0] flit;

            flit          = '0;
            // First TLP, words 0-3
            flit[31:0]    = hdr(BASE_ADDR, 8'd2, ENC_EVEN, PAR_EVEN, SYS_TRANSFER);
            flit[63:32]   = payload(16'h0005, 16'hDEAD);
            flit[95:64]   = payload(16'h0006, 16'hBEEF);
            flit[127:96]  = payload(16'h0007, 16'hCAFE);
            // Second TLP, words 4-7
            flit[159:128] = hdr(BASE_ADDR, 8'd2, ENC_EVEN, PAR_EVEN, SYS_TRANSFER);
            flit[191:160] = payload(16'h0008, 16'h1234);
            flit[223:192] = payload(16'h0009, 16'h5678);
            flit[255:224] = payload(16'h000A, 16'h9ABC);

            send_flit(flit, make_cntl(0, 0, 3) | make_cntl(1, 1, 7));
            send_idle(40);
        endtask
    endclass


    // -----------------------------------------------------------------------
    // Test 3 - Invalid ENC_MODE in the configuration header. The error crosses
    // to the CXS domain, the packet encoder builds a response FLIT and the TX
    // interface sends it, because credit is available.
    // -----------------------------------------------------------------------
    class err_tx_flit_seq extends enc_sys_base_seq;
        `uvm_object_utils(err_tx_flit_seq)

        function new(string name = "err_tx_flit_seq");
            super.new(name);
            tnum = 3; tname = "ERR_TX_FLIT";
        endfunction

        task body();
            logic [255:0] flit;

            send_reset(5);
            tx_credit(1'b1, 2);        // transmit credit available up front

            // Only word 0 is set; the remaining words are zero so the FSM drops
            // them in Idle instead of reading them as headers.
            flit       = '0;
            flit[31:0] = hdr(BASE_ADDR, 8'd2, ENC_INVALID, PAR_EVEN, SYS_CONFIG);
            send_flit(flit, make_cntl(0, 0, 3));
            send_idle(60);
        endtask
    endclass


    // -----------------------------------------------------------------------
    // Test 4 - Same error with no transmit credit. The response FLIT is held in
    // the TX interface with flit_ready low until a credit is granted.
    // -----------------------------------------------------------------------
    class tx_credit_stall_seq extends enc_sys_base_seq;
        `uvm_object_utils(tx_credit_stall_seq)

        function new(string name = "tx_credit_stall_seq");
            super.new(name);
            tnum = 4; tname = "TX_CREDIT_STALL";
        endfunction

        task body();
            logic [255:0] flit;

            send_reset(5);
            tx_credit(1'b0, 2);        // no credit: nothing may leave

            flit       = '0;
            flit[31:0] = hdr(BASE_ADDR, 8'd2, ENC_INVALID, PAR_EVEN, SYS_CONFIG);
            send_flit(flit, make_cntl(0, 0, 3));
            send_idle(40);             // response FLIT parked in tx_interface

            tx_credit(1'b1, 1);        // one credit releases it
            tx_credit(1'b0, 20);
        endtask
    endclass

endpackage
