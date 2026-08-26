package reset_seq_pkg;
    import uvm_pkg::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class reset_seq extends uvm_sequence #(enc_sys_seq_item);
        `uvm_object_utils(reset_seq)

        enc_sys_seq_item item;

        function new(string name = "reset_seq");
            super.new(name);
        endfunction

        task body();
            item = enc_sys_seq_item::type_id::create("item");
            start_item(item);
            item.op        = OP_RESET;
            item.cycles    = 5;
            item.test_name = "RESET";
            finish_item(item);
        endtask
    endclass
endpackage
