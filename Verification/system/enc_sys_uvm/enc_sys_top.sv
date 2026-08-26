import enc_sys_test_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"


module enc_sys_top;

    bit clk_cxs;   // CXS link domain, 100 MHz
    bit clk_sys;   // system domain, 125 MHz - deliberately unrelated

    initial begin
        clk_cxs = 1'b0;
        forever #5 clk_cxs = ~clk_cxs;
    end

    initial begin
        clk_sys = 1'b0;
        forever #4 clk_sys = ~clk_sys;
    end

    enc_sys_inter enc_sys_test_vif(clk_cxs, clk_sys);

    top dut (
        .clk_cxs       (clk_cxs),
        .rst_n_cxs     (enc_sys_test_vif.rst_n_cxs),
        .clk_sys       (clk_sys),
        .rst_n_sys     (enc_sys_test_vif.rst_n_sys),

        .cxs_rx_valid  (enc_sys_test_vif.cxs_rx_valid),
        .cxs_rx_data   (enc_sys_test_vif.cxs_rx_data),
        .cxs_rx_cntl   (enc_sys_test_vif.cxs_rx_cntl),
        .cxs_rx_crdgnt (enc_sys_test_vif.cxs_rx_crdgnt),

        .cxs_tx_crdgnt (enc_sys_test_vif.cxs_tx_crdgnt),
        .cxs_tx_valid  (enc_sys_test_vif.cxs_tx_valid),
        .cxs_tx_data   (enc_sys_test_vif.cxs_tx_data),
        .cxs_tx_cntl   (enc_sys_test_vif.cxs_tx_cntl)
    );

    initial begin
        uvm_config_db #(virtual enc_sys_inter)::set(null, "*", "enc_sys_test_vif", enc_sys_test_vif);
        run_test("enc_sys_test");
    end

endmodule
