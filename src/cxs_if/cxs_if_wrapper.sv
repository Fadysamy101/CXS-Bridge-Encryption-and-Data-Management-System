`include "flit_fifo.sv"
`include "rx_interface.sv"
`include "packet_formatter.sv"
`include "credit_manager.sv"
`include "packet_encoder.sv"
`include "tx_interface.sv"

// -----------------------------------------------------------------------------
// cxs_if_wrapper : top-level CXS-clock-domain wrapper. Instantiates the
// RX/TX interfaces, flit fifo, credit manager, packet formatter and packet
// encoder. Everything here runs on clk_cxs / rst_n_cxs.
// -----------------------------------------------------------------------------
module cxs_if_wrapper (
    input                    clk_cxs,
    input                    rst_n_cxs,

    // CXS receive bus
    input                    cxs_rx_valid,
    input      [255:0]       cxs_rx_data,
    input      [13:0]        cxs_rx_cntl,
    output                   cxs_rx_crdgnt,

    // CXS transmit bus
    output                   cxs_tx_valid,
    output     [255:0]       cxs_tx_data,
    output     [13:0]        cxs_tx_cntl,

    // downstream (system side) storage fifo handshake, driven by packet_formatter
    input                    async_fifo_full,
    output                    async_fifo_w_en,
    output      [31:0]        async_fifo_w_data,

    // downstream flit source into packet_encoder (e.g. from CDM/system side)
    input                    flit_valid,
    input      [269:0]       flit_data_in,
    output                   flit_ready
);

    // ---------------------------------------------------------------
    // flit_fifo interconnect
    // ---------------------------------------------------------------
    wire               ff_empty, ff_full;
    wire               ff_r_en,  ff_w_en;
    wire [269:0]       ff_r_data, ff_w_data;

    // credit_manager <-> flit_fifo monitoring side
    wire               cm_flit_fifo_full, cm_flit_fifo_wr;

    // packet_formatter outputs
    wire               pf_flit_rd_en;

    // rx_interface outputs
    wire               rx_flit_fifo_en;
    wire [269:0]       rx_flit_fifo_data;

    // packet_encoder <-> tx_interface
    wire               pe_tx_valid;
    wire [269:0]       pe_tx_data;
    wire [13:0]        pe_tx_cntl;
    wire               tx_pkt_ready;
    // ---------------------------------------------------------------
    // rx_interface
    // ---------------------------------------------------------------
    rx_interface rx_interface_inst (

        .cxs_rx_valid    (cxs_rx_valid),
        .cxs_rx_data     (cxs_rx_data),
        .cxs_rx_cntl     (cxs_rx_cntl),
      
        .flit_fifo_full  (ff_full),
        .flit_fifo_en    (rx_flit_fifo_en),
        .flit_fifo_data  (rx_flit_fifo_data)
    );

    // ---------------------------------------------------------------
    // flit_fifo : simple synchronous fifo, write side fed by rx_interface,
    // read side by packet_formatter. Single clock domain (clk_cxs / rst_n_cxs).
    // ---------------------------------------------------------------
    flit_fifo #(
        .DEPTH      (16),
        .DATA_WIDTH (270)
    ) flit_fifo_inst (
        .clk_cxs   (clk_cxs),
        .rst_n_cxs (rst_n_cxs),
        .w_en      (rx_flit_fifo_en),
        .w_data    (rx_flit_fifo_data),
        .r_en      (pf_flit_rd_en),
        .r_data    (ff_r_data),
        .full      (ff_full),
        .empty     (ff_empty)
    );

    // ---------------------------------------------------------------
    // credit_manager
    // ---------------------------------------------------------------
    credit_manager credit_manager_inst (
        .clk_cxs         (clk_cxs),
        .rst_n_cxs       (rst_n_cxs),
        .flit_fifo_empty (ff_empty),
        .flit_fifo_full  (ff_full),
        .flit_fifo_rd    (pf_flit_rd_en),
        .flit_fifo_wr    (rx_flit_fifo_en),
        .cxs_rx_crdgnt   (cxs_rx_crdgnt)
    );

    // ---------------------------------------------------------------
    // packet_formatter
    // ---------------------------------------------------------------
    packet_formatter packet_formatter_inst (
        .clk_cxs          (clk_cxs),
        .rst_n_cxs        (rst_n_cxs),
        .async_fifo_full  (async_fifo_full),
        .async_fifo_w_data(async_fifo_w_data),
        .async_fifo_w_en(async_fifo_w_en),
        .flit_fifo_empty  (ff_empty),
        .flit_rd_en       (pf_flit_rd_en),
        .flit_data        (ff_r_data)
    );


    // // ---------------------------------------------------------------
    // // packet_encoder
    // // ---------------------------------------------------------------
    // packet_encoder packet_encoder_inst (
    //     .clk_cxs      (clk_cxs),
    //     .rst_n_cxs    (rst_n_cxs),
    //     .flit_valid   (flit_valid),
    //     .flit_data    (flit_data_in),
    //     .flit_ready   (flit_ready),
    //     .tx_pkt_valid (pe_tx_valid),
    //     .tx_pkt_data  (pe_tx_data),
    //     .tx_pkt_cntl  (pe_tx_cntl),
    //     .tx_pkt_ready (tx_pkt_ready)
    // );

    // // ---------------------------------------------------------------
    // // tx_interface
    // // ---------------------------------------------------------------
    // tx_interface tx_interface_inst (
    //     .clk_cxs      (clk_cxs),
    //     .rst_n_cxs    (rst_n_cxs),
    //     .tx_pkt_valid (pe_tx_valid),
    //     .tx_pkt_data  (pe_tx_data),
    //     .tx_pkt_cntl  (pe_tx_cntl),
    //     .tx_pkt_ready (tx_pkt_ready),
    //     .CXSTXVALID   (cxs_tx_valid),
    //     .CXSTXDATA    (cxs_tx_data),
    //     .CXSTXCNTL    (cxs_tx_cntl)
    // );

endmodule