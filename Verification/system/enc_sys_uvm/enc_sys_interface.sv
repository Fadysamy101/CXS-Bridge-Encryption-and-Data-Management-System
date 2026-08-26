interface enc_sys_inter(input logic clk_cxs, input logic clk_sys);

    // Resets, one per clock domain
    logic         rst_n_cxs;
    logic         rst_n_sys;

    // CXS link - receive
    logic         cxs_rx_valid;
    logic [255:0] cxs_rx_data;
    logic [13:0]  cxs_rx_cntl;
    logic         cxs_rx_crdgnt;

    // CXS link - transmit
    logic         cxs_tx_crdgnt;
    logic         cxs_tx_valid;
    logic [255:0] cxs_tx_data;
    logic [13:0]  cxs_tx_cntl;

    // Waveform markers: which directed test is running right now.
    // test_name is packed ASCII, view it with "add wave -radix ascii".
    int unsigned  test_num;
    logic [127:0] test_name;

endinterface
