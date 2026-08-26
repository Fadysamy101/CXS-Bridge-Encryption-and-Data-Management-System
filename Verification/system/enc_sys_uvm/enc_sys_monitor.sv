package enc_sys_monitor_pkg;
    import uvm_pkg::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_monitor extends uvm_monitor;
        `uvm_component_utils(enc_sys_monitor)

        enc_sys_seq_item item;
        virtual enc_sys_inter enc_sys_test_vif;
        uvm_analysis_port #(enc_sys_seq_item) mon_ap;

        function new(string name = "enc_sys_monitor", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap", this);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                item = enc_sys_seq_item::type_id::create("item");
                @(negedge enc_sys_test_vif.clk_cxs);
                mon_ap.write(item);
            end
        endtask
    endclass
endpackage
