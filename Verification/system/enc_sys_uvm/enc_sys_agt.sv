package enc_sys_agt_pkg;
    import uvm_pkg::*;
    import enc_sys_driver_pkg::*;
    import enc_sys_sequencer_pkg::*;
    import enc_sys_monitor_pkg::*;
    import enc_sys_configuration::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_agt extends uvm_agent;
        `uvm_component_utils(enc_sys_agt)

        enc_sys_driver driver;
        enc_sys_monitor monitor;
        enc_sys_confg cfg;
        enc_sys_sqr_class sqr;
        uvm_analysis_port #(enc_sys_seq_item) agt_ap;

        function new(string name = "enc_sys_agt", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            monitor = enc_sys_monitor::type_id::create("mon", this);
            if (!uvm_config_db #(enc_sys_confg)::get(this, "", "CFG", cfg))
                `uvm_fatal("build_phase", "No config object found")
            if (cfg.is_active == UVM_ACTIVE) begin
                driver = enc_sys_driver::type_id::create("driver", this);
                sqr = enc_sys_sqr_class::type_id::create("sqr", this);
            end
            agt_ap = new("agt_ap", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            monitor.enc_sys_test_vif = cfg.enc_sys_test_vif;
            if (cfg.is_active == UVM_ACTIVE) begin
                driver.enc_sys_test_vif = cfg.enc_sys_test_vif;
                driver.seq_item_port.connect(sqr.seq_item_export);
            end
            monitor.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage
