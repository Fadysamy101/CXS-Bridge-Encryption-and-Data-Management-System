package enc_sys_scoreboard_pkg;
    import uvm_pkg::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(enc_sys_scoreboard)

        uvm_analysis_export #(enc_sys_seq_item) sb_export;
        uvm_tlm_analysis_fifo #(enc_sys_seq_item) sb_fifo;
        enc_sys_seq_item item;
        static int correct_count = 0;
        static int wrong_count = 0;

        function new(string name = "enc_sys_scoreboard", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export", this);
            sb_fifo = new("sb_fifo", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_fifo.analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                sb_fifo.get(item);
                // check results
            end
        endtask
    endclass
endpackage
