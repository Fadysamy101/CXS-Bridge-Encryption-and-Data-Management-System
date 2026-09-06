import enc_sys_test_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
`timescale 1ns/1ps


module enc_sys_top;

    bit clk_cxs;   // CXS link domain, 100 MHz
    bit clk_sys;   // system domain, 125 MHz - deliberately unrelated

    initial begin
        clk_cxs = 0;
        forever #13.514 clk_cxs = ~clk_cxs;
    end

    initial begin
        clk_sys = 0;
        forever #20 clk_sys = ~clk_sys;
    end

    enc_sys_inter enc_sys_test_vif(clk_cxs, clk_sys);

    top dut (
        .i_top_cxs_clk       (clk_cxs),
        .i_top_cxs_rst_n     (enc_sys_test_vif.rst_n_cxs),
        .i_top_sys_clk       (clk_sys),
        .i_top_sys_rst_n     (enc_sys_test_vif.rst_n_sys),

        .i_top_cxs_rx_valid  (enc_sys_test_vif.cxs_rx_valid),
        .i_top_cxs_rx_data   (enc_sys_test_vif.cxs_rx_data),
        .i_top_cxs_rx_cntl   (enc_sys_test_vif.cxs_rx_cntl),
        .o_top_cxs_rx_crdgnt (enc_sys_test_vif.cxs_rx_crdgnt),

        .i_top_cxs_tx_crdgnt (enc_sys_test_vif.cxs_tx_crdgnt),
        .o_top_cxs_tx_valid  (enc_sys_test_vif.cxs_tx_valid),
        .o_top_cxs_tx_data   (enc_sys_test_vif.cxs_tx_data),
        .o_top_cxs_tx_cntl   (enc_sys_test_vif.cxs_tx_cntl)
    );

    initial begin
        uvm_config_db #(virtual enc_sys_inter)::set(null, "*", "enc_sys_test_vif", enc_sys_test_vif);
        run_test("enc_sys_test");
    end

endmodule
