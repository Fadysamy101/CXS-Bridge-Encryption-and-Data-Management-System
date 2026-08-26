package enc_sys_env_pkg;
    import uvm_pkg::*;
    import enc_sys_agt_pkg::*;
    import enc_sys_coverage_pkg::*;
    import enc_sys_scoreboard_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_env extends uvm_env;
        `uvm_component_utils(enc_sys_env)

        enc_sys_agt agt;
        enc_sys_scoreboard sb;
        enc_sys_cover cov;

        function new(string name = "enc_sys_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agt = enc_sys_agt::type_id::create("agt", this);
            sb = enc_sys_scoreboard::type_id::create("sb", this);
            cov = enc_sys_cover::type_id::create("cov", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agt.agt_ap.connect(sb.sb_export);
            agt.agt_ap.connect(cov.cov_export);
        endfunction
    endclass
endpackage
