package enc_sys_test_pkg;
    import uvm_pkg::*;
    import enc_sys_env_pkg::*;
    import enc_sys_configuration::*;
    import reset_seq_pkg::*;
    import directed_seq_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_test extends uvm_test;
        `uvm_component_utils(enc_sys_test)

        enc_sys_confg conf_enc_sys;
        enc_sys_env env_enc_sys;

        cfg_link_xfer_seq   seq_cfg_link_xfer;
        two_tlp_seq         seq_two_tlp;
        err_tx_flit_seq     seq_err_tx;
        tx_credit_stall_seq seq_tx_stall;

        function new(string name = "enc_sys_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env_enc_sys = enc_sys_env::type_id::create("env", this);
            conf_enc_sys = enc_sys_confg::type_id::create("conf_enc_sys", this);

            if (!uvm_config_db #(virtual enc_sys_inter)::get(this, "", "enc_sys_test_vif", conf_enc_sys.enc_sys_test_vif))
                `uvm_fatal("build_phase", "No interface found")

            conf_enc_sys.is_active = UVM_ACTIVE;
            uvm_config_db #(enc_sys_confg)::set(this, "*", "CFG", conf_enc_sys);

            seq_cfg_link_xfer = cfg_link_xfer_seq::type_id::create("seq_cfg_link_xfer");
            seq_two_tlp       = two_tlp_seq::type_id::create("seq_two_tlp");
            seq_err_tx        = err_tx_flit_seq::type_id::create("seq_err_tx");
            seq_tx_stall      = tx_credit_stall_seq::type_id::create("seq_tx_stall");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this);

            banner(1, "CFG_LINK_XFER    - Config, Link-Up and Transfer TLPs");
            seq_cfg_link_xfer.start(env_enc_sys.agt.sqr);

            banner(2, "TWO_TLP_ONE_FLIT - two Transfer TLPs in a single FLIT");
            seq_two_tlp.start(env_enc_sys.agt.sqr);

            banner(3, "ERR_TX_FLIT      - bad ENC_MODE, response FLIT sent");
            seq_err_tx.start(env_enc_sys.agt.sqr);

            banner(4, "TX_CREDIT_STALL  - response FLIT held until credit");
            seq_tx_stall.start(env_enc_sys.agt.sqr);

            $display("\n=== all directed tests completed at %0t ===\n", $time);
            phase.drop_objection(this);
        endtask

        function void banner(int n, string txt);
            $display("\n=========================================================");
            $display("  TEST %0d : %s", n, txt);
            $display("=========================================================\n");
        endfunction

    endclass
endpackage
