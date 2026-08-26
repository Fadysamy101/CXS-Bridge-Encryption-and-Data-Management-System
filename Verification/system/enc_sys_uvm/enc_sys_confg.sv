package enc_sys_configuration;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_confg extends uvm_object;
        `uvm_object_utils(enc_sys_confg)

        virtual enc_sys_inter enc_sys_test_vif;
        uvm_active_passive_enum is_active;

        function new(string name = "enc_sys_confg");
            super.new(name);
        endfunction
    endclass
endpackage
