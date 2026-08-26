// ---------------------------------------------------------------------------
// top - CXS Bridge Encryption and Data Management System
//
// Joins the two clock-domain wrappers (spec section 9):
//   cxs_if         - CLK_CXS : link interface, FLIT FIFO, credit management,
//                              packet formatting.
//   system_wrapper - CLK_SYS : control unit, ATU, encryption, parity, CDM.
//
// Everything that straddles the boundary lives here: the asynchronous FIFO on
// the data path (spec 10.2) and the two-stage synchronizer carrying the error
// indication back to the CXS domain (spec 10.3).
// ---------------------------------------------------------------------------
module top #(
    parameter int CXS_DATA_WIDTH   = 256,
    parameter int CXS_CNTL_WIDTH   = 14,
    parameter int FLIT_WIDTH       = CXS_DATA_WIDTH + CXS_CNTL_WIDTH,
    parameter int FLIT_FIFO_DEPTH  = 16,
    parameter int WORD_WIDTH       = 32,   // TLP word carried across the CDC
    parameter int ASYNC_FIFO_DEPTH = 8,
    parameter int ADDR_WIDTH       = 16,
    parameter int DATA_WIDTH       = 16,
    parameter int DEV_MAX          = 8
)(
    // CXS clock domain
    input  logic                      clk_cxs,
    input  logic                      rst_n_cxs,

    // System clock domain
    input  logic                      clk_sys,
    input  logic                      rst_n_sys,

    // CXS link - receive
    input  logic                      cxs_rx_valid,
    input  logic [CXS_DATA_WIDTH-1:0] cxs_rx_data,
    input  logic [CXS_CNTL_WIDTH-1:0] cxs_rx_cntl,
    output logic                      cxs_rx_crdgnt,

    // CXS link - transmit
    input logic                       cxs_tx_crdgnt,
    output logic                      cxs_tx_valid,
    output logic [CXS_DATA_WIDTH-1:0] cxs_tx_data,
    output logic [CXS_CNTL_WIDTH-1:0] cxs_tx_cntl
);

    // CXS domain -> async FIFO
    logic                  async_fifo_w_en;
    logic [WORD_WIDTH-1:0] async_fifo_w_data;
    logic                  async_fifo_full;

    // async FIFO -> system domain
    logic                  fifo_empty;
    logic                  fifo_en;
    logic [WORD_WIDTH-1:0] fifo_data_in;

    // Error path
    logic                      sys_error_valid;   // CLK_SYS, one-cycle pulse
    logic [1:0]                sys_error;         // CLK_SYS, held stable
    logic                      err_toggle;        // CLK_SYS
    logic                      err_toggle_sync;   // CLK_CXS, after 2FF
    logic                      err_toggle_sync_d;
    logic                      err_pulse_cxs;

    // =======================================================================
    // CXS clock domain
    // =======================================================================
    cxs_if #(
        .CXS_DATA_WIDTH  (CXS_DATA_WIDTH),
        .CXS_CNTL_WIDTH  (CXS_CNTL_WIDTH),
        .FLIT_WIDTH      (FLIT_WIDTH),
        .FLIT_FIFO_DEPTH (FLIT_FIFO_DEPTH),
        .WORD_WIDTH      (WORD_WIDTH)
    ) u_cxs_if (
        .clk_cxs           (clk_cxs),
        .rst_n_cxs         (rst_n_cxs),

        .cxs_rx_valid      (cxs_rx_valid),
        .cxs_rx_data       (cxs_rx_data),
        .cxs_rx_cntl       (cxs_rx_cntl),
        .cxs_rx_crdgnt     (cxs_rx_crdgnt),

        .cxs_tx_crdgnt     (cxs_tx_crdgnt),
        .cxs_tx_valid      (cxs_tx_valid),
        .cxs_tx_data       (cxs_tx_data),
        .cxs_tx_cntl       (cxs_tx_cntl),

        .async_fifo_full   (async_fifo_full),
        .async_fifo_w_en   (async_fifo_w_en),
        .async_fifo_w_data (async_fifo_w_data),

        // Error indication, synchronized into the CXS domain, encoded into a
        // response FLIT by the packet encoder
        .error_valid_sync  (err_pulse_cxs),
        .error_in          (sys_error)
    );

   

    // =======================================================================
    // Clock domain crossing
    // =======================================================================
    asynchronous_fifo #(
        .DEPTH      (ASYNC_FIFO_DEPTH),
        .DATA_WIDTH (WORD_WIDTH)
    ) u_async_fifo (
        .wclk     (clk_cxs),
        .wrst_n   (rst_n_cxs),
        .rclk     (clk_sys),
        .rrst_n   (rst_n_sys),
        .w_en     (async_fifo_w_en),
        .r_en     (fifo_en),
        .data_in  (async_fifo_w_data),
        .data_out (fifo_data_in),
        .full     (async_fifo_full),
        .empty    (fifo_empty)
    );

    // The system reports an error as a single CLK_SYS cycle pulse, which a
    // slower CLK_CXS could miss, so it crosses as a toggle and is turned back
    // into a pulse on the far side. sys_error is held stable by the control
    // unit until the next error, so the encoder samples it safely.
    always_ff @(posedge clk_sys or negedge rst_n_sys) begin
        if (!rst_n_sys) err_toggle <= 1'b0;
        else            err_toggle <= err_toggle ^ sys_error_valid;
    end

    // WIDTH=0 gives a [0:0] bus - see the [WIDTH:0] convention in 2ff.sv
    synchronizer #(
        .WIDTH (0)
    ) u_err_sync (
        .clk   (clk_cxs),
        .rst_n (rst_n_cxs),
        .d_in  (err_toggle),
        .d_out (err_toggle_sync)
    );

    always_ff @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) err_toggle_sync_d <= 1'b0;
        else            err_toggle_sync_d <= err_toggle_sync;
    end

    assign err_pulse_cxs = err_toggle_sync ^ err_toggle_sync_d;

    // =======================================================================
    // System clock domain
    // =======================================================================
    system_wrapper #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .DEV_MAX    (DEV_MAX)
    ) u_system_wrapper (
        .clk_sys      (clk_sys),
        .rst_n        (rst_n_sys),

        .fifo_empty   (fifo_empty),
        .fifo_en      (fifo_en),
        .fifo_data_in (fifo_data_in),

        .error_valid  (sys_error_valid),
        .error        (sys_error)
    );

endmodule
