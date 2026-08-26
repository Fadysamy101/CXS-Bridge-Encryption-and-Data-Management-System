package enc_sys_seq_item_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Directed stimulus only - no rand, every field is set by the sequence.
    typedef enum {
        OP_RESET,    // pulse both resets
        OP_FLIT,     // drive one FLIT on the CXS receive interface
        OP_IDLE,     // do nothing for "cycles" CXS clocks
        OP_TX_CRD    // set cxs_tx_crdgnt to "tx_crdgnt"
    } enc_sys_op_e;

    class enc_sys_seq_item extends uvm_sequence_item;
        `uvm_object_utils(enc_sys_seq_item)

        enc_sys_op_e  op;

        logic [255:0] data;
        logic [13:0]  cntl;
        int unsigned  cycles;
        logic         tx_crdgnt;

        // Copied to the interface by the driver so they show up on the wave
        int unsigned  test_num;
        logic [127:0] test_name;

        function new(string name = "enc_sys_seq_item");
            super.new(name);
            op        = OP_IDLE;
            data      = '0;
            cntl      = '0;
            cycles    = 1;
            tx_crdgnt = 1'b0;
            test_num  = 0;
            test_name = "INIT";
        endfunction
    endclass
endpackage
