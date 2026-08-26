package enc_sys_driver_pkg;
    import uvm_pkg::*;
    import enc_sys_configuration::*;
    import enc_sys_seq_item_pkg::*;
    `include "uvm_macros.svh"

    class enc_sys_driver extends uvm_driver #(enc_sys_seq_item);
        `uvm_component_utils(enc_sys_driver)

        enc_sys_seq_item item;
        virtual enc_sys_inter enc_sys_test_vif;

        function new(string name = "enc_sys_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                seq_item_port.get_next_item(item);

                // Keep the wave markers up to date with the running test
                enc_sys_test_vif.test_num  = item.test_num;
                enc_sys_test_vif.test_name = item.test_name;

                case (item.op)
                    OP_RESET:  do_reset(item);
                    OP_FLIT:   send_flit(item);
                    OP_TX_CRD: set_tx_credit(item);
                    default:   do_idle(item);
                endcase

                seq_item_port.item_done();
            end
        endtask

        // Both domains held in reset together, then released.
        task do_reset(enc_sys_seq_item it);
            enc_sys_test_vif.rst_n_cxs     <= 1'b0;
            enc_sys_test_vif.rst_n_sys     <= 1'b0;
            enc_sys_test_vif.cxs_rx_valid  <= 1'b0;
            enc_sys_test_vif.cxs_rx_data   <= '0;
            enc_sys_test_vif.cxs_rx_cntl   <= '0;
            enc_sys_test_vif.cxs_tx_crdgnt <= 1'b0;

            repeat (it.cycles) @(posedge enc_sys_test_vif.clk_cxs);

            enc_sys_test_vif.rst_n_cxs <= 1'b1;
            enc_sys_test_vif.rst_n_sys <= 1'b1;

            repeat (2) @(posedge enc_sys_test_vif.clk_cxs);
        endtask

        // One FLIT, sent only once the bridge has granted a receive credit.
        task send_flit(enc_sys_seq_item it);
            while (enc_sys_test_vif.cxs_rx_crdgnt !== 1'b1)
                @(posedge enc_sys_test_vif.clk_cxs);

            @(posedge enc_sys_test_vif.clk_cxs);
            enc_sys_test_vif.cxs_rx_valid <= 1'b1;
            enc_sys_test_vif.cxs_rx_data  <= it.data;
            enc_sys_test_vif.cxs_rx_cntl  <= it.cntl;

            @(posedge enc_sys_test_vif.clk_cxs);
            enc_sys_test_vif.cxs_rx_valid <= 1'b0;
            enc_sys_test_vif.cxs_rx_data  <= '0;
            enc_sys_test_vif.cxs_rx_cntl  <= '0;
        endtask

        task set_tx_credit(enc_sys_seq_item it);
            enc_sys_test_vif.cxs_tx_crdgnt <= it.tx_crdgnt;
            repeat (it.cycles) @(posedge enc_sys_test_vif.clk_cxs);
        endtask

        task do_idle(enc_sys_seq_item it);
            repeat (it.cycles) @(posedge enc_sys_test_vif.clk_cxs);
        endtask

    endclass
endpackage
