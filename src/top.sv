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
  parameter int ADDR_WIDTH       = 8, 
  parameter int DATA_WIDTH       = 16,
  parameter int DEV_MAX          = 8
)(
  // CXS clock domain
  input  logic                      i_top_cxs_clk,
  input  logic                      i_top_cxs_rst_n,

  // System clock domain
  input  logic                      i_top_sys_clk,
  input  logic                      i_top_sys_rst_n,

  // CXS link - receive
  input  logic                      i_top_cxs_rx_valid,
  input  logic [CXS_DATA_WIDTH-1:0] i_top_cxs_rx_data,
  input  logic [CXS_CNTL_WIDTH-1:0] i_top_cxs_rx_cntl,
  output logic                      o_top_cxs_rx_crdgnt,

  // CXS link - transmit
  input  logic                      i_top_cxs_tx_crdgnt,
  output logic                      o_top_cxs_tx_valid,
  output logic [CXS_DATA_WIDTH-1:0] o_top_cxs_tx_data,
  output logic [CXS_CNTL_WIDTH-1:0] o_top_cxs_tx_cntl
);

  // CXS domain -> async FIFO (write side)
  logic                  async_fifo_w_en;
  logic [WORD_WIDTH-1:0] async_fifo_data_in;
  logic                  async_fifo_full;

  // async FIFO -> system domain (read side)
  logic                  async_fifo_r_en;
  logic [WORD_WIDTH-1:0] async_fifo_data_out;
  logic                  async_fifo_empty;

  // Error path
  logic                  sys_error_valid;     // CLK_SYS, one-cycle pulse
  logic [1:0]            sys_error;           // CLK_SYS, held stable
  logic                  err_toggle;          // CLK_SYS
  logic                  err_toggle_sync;     // CLK_CXS, after 2FF
  logic                  err_toggle_sync_d0;
  logic                  err_pulse_cxs;

  // =========================================================================
  // CXS clock domain
  // =========================================================================
  cxs_if
  #(
    // Parameter Declaration
     .CXS_DATA_WIDTH  (CXS_DATA_WIDTH)   // CXS Data Width
    ,.CXS_CNTL_WIDTH  (CXS_CNTL_WIDTH)   // CXS Control Width
    ,.FLIT_WIDTH      (FLIT_WIDTH)       // FLIT Width
    ,.FLIT_FIFO_DEPTH (FLIT_FIFO_DEPTH)  // FLIT FIFO Depth
    ,.WORD_WIDTH      (WORD_WIDTH)       // TLP Word Width
  )
  u_cxs_if
  (
    // Ports Declaration
     .i_cxs_if_clk               (i_top_cxs_clk)        // I: CXS Clock
    ,.i_cxs_if_rst_n             (i_top_cxs_rst_n)      // I: CXS Async Reset
    ,.i_cxs_if_cxs_rx_valid      (i_top_cxs_rx_valid)   // I: CXS RX Valid
    ,.i_cxs_if_cxs_rx_data       (i_top_cxs_rx_data)    // I: CXS RX Data
    ,.i_cxs_if_cxs_rx_cntl       (i_top_cxs_rx_cntl)    // I: CXS RX Control
    ,.o_cxs_if_cxs_rx_crdgnt     (o_top_cxs_rx_crdgnt)  // O: CXS RX Credit Grant
    ,.i_cxs_if_cxs_tx_crdgnt     (i_top_cxs_tx_crdgnt)  // I: CXS TX Credit Grant
    ,.o_cxs_if_cxs_tx_valid      (o_top_cxs_tx_valid)   // O: CXS TX Valid
    ,.o_cxs_if_cxs_tx_data       (o_top_cxs_tx_data)    // O: CXS TX Data
    ,.o_cxs_if_cxs_tx_cntl       (o_top_cxs_tx_cntl)    // O: CXS TX Control
    ,.i_cxs_if_async_fifo_full   (async_fifo_full)      // I: Async FIFO Full
    ,.o_cxs_if_async_fifo_w_en   (async_fifo_w_en)      // O: Async FIFO Write Enable
    ,.o_cxs_if_async_fifo_w_data (async_fifo_data_in)   // O: Async FIFO Write Data
    // Error indication, synchronized into the CXS domain, encoded into a
    // response FLIT by the packet encoder
    ,.i_cxs_if_error_valid_sync  (err_pulse_cxs)  // I: Synchronized Error Pulse
    ,.i_cxs_if_error_in          (sys_error)      // I: Error Code
  );

  // =========================================================================
  // Clock domain crossing
  // =========================================================================
  asynchronous_fifo
  #(
    // Parameter Declaration
     .DEPTH      (ASYNC_FIFO_DEPTH)  // Async FIFO Depth
    ,.DATA_WIDTH (WORD_WIDTH)        // TLP Word Width
  )
  u_async_fifo
  (
    // Ports Declaration
     .i_asynchronous_fifo_w_clk    (i_top_cxs_clk)        // I: Write Clock - CXS Domain
    ,.i_asynchronous_fifo_w_rst_n  (i_top_cxs_rst_n)      // I: Write Async Reset
    ,.i_asynchronous_fifo_r_clk    (i_top_sys_clk)        // I: Read Clock - System Domain
    ,.i_asynchronous_fifo_r_rst_n  (i_top_sys_rst_n)      // I: Read Async Reset
    ,.i_asynchronous_fifo_w_en     (async_fifo_w_en)      // I: Write Enable
    ,.i_asynchronous_fifo_r_en     (async_fifo_r_en)      // I: Read Enable
    ,.i_asynchronous_fifo_data_in  (async_fifo_data_in)   // I: Write Data
    ,.o_asynchronous_fifo_data_out (async_fifo_data_out)  // O: Read Data
    ,.o_asynchronous_fifo_full     (async_fifo_full)      // O: FIFO Full
    ,.o_asynchronous_fifo_empty    (async_fifo_empty)     // O: FIFO Empty
  );

  // The system reports an error as a single CLK_SYS cycle pulse, which a
  // slower CLK_CXS could miss, so it crosses as a toggle and is turned back
  // into a pulse on the far side. sys_error is held stable by the control
  // unit until the next error, so the encoder samples it safely.
  always_ff @(posedge i_top_sys_clk or negedge i_top_sys_rst_n) begin: err_toggle_proc
    if (!i_top_sys_rst_n) err_toggle <= 1'b0;
    else                  err_toggle <= err_toggle ^ sys_error_valid;
  end

  // WIDTH=0 gives a [0:0] bus - see the [WIDTH:0] convention in synchronizer.sv
  synchronizer
  #(
    // Parameter Declaration
     .WIDTH (0)  // Single-Bit Synchronizer
  )
  u_err_sync
  (
    // Ports Declaration
     .i_synchronizer_clk   (i_top_cxs_clk)    // I: CXS Clock
    ,.i_synchronizer_rst_n (i_top_cxs_rst_n)  // I: CXS Async Reset
    ,.i_synchronizer_d_in  (err_toggle)       // I: Error Toggle - System Domain
    ,.o_synchronizer_d_out (err_toggle_sync)  // O: Error Toggle - CXS Domain
  );

  always_ff @(posedge i_top_cxs_clk or negedge i_top_cxs_rst_n) begin: err_toggle_sync_proc
    if (!i_top_cxs_rst_n) err_toggle_sync_d0 <= 1'b0;
    else                  err_toggle_sync_d0 <= err_toggle_sync;
  end

  assign err_pulse_cxs = err_toggle_sync ^ err_toggle_sync_d0;

  // =========================================================================
  // System clock domain
  // =========================================================================
  system_wrapper
  #(
    // Parameter Declaration
     .ADDR_WIDTH (ADDR_WIDTH)  // CDM / ATU Address Width
    ,.DATA_WIDTH (DATA_WIDTH)  // Payload Data Width
    ,.DEV_MAX    (DEV_MAX)     // Max Configurable Devices
  )
  u_system_wrapper
  (
    // Ports Declaration
     .i_system_wrapper_clk          (i_top_sys_clk)        // I: System Clock
    ,.i_system_wrapper_rst_n        (i_top_sys_rst_n)      // I: System Async Reset
    ,.i_system_wrapper_fifo_empty   (async_fifo_empty)     // I: Async FIFO Empty
    ,.o_system_wrapper_fifo_en      (async_fifo_r_en)      // O: Async FIFO Read Enable
    ,.i_system_wrapper_fifo_data_in (async_fifo_data_out)  // I: Async FIFO Read Data
    ,.o_system_wrapper_error_valid  (sys_error_valid)      // O: Error Pulse
    ,.o_system_wrapper_error        (sys_error)            // O: Error Code
  );

endmodule
