package enc_sys_sequencer_pkg;
    import uvm_pkg::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_sqr_class extends uvm_sequencer #(enc_sys_seq_item);
        `uvm_component_utils(enc_sys_sqr_class)

        function new(string name = "enc_sys_sqr_class", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
endpackage
