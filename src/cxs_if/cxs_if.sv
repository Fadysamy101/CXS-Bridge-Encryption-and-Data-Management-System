module cxs_if #(
  parameter int CXS_DATA_WIDTH  = 256,
  parameter int CXS_CNTL_WIDTH  = 14,
  parameter int FLIT_WIDTH      = CXS_DATA_WIDTH + CXS_CNTL_WIDTH,
  parameter int FLIT_FIFO_DEPTH = 8,
  parameter int WORD_WIDTH      = 32
)(
  input  logic                      i_cxs_if_clk,
  input  logic                      i_cxs_if_rst_n,

  input  logic                      i_cxs_if_cxs_rx_valid,
  input  logic [CXS_DATA_WIDTH-1:0] i_cxs_if_cxs_rx_data,
  input  logic [CXS_CNTL_WIDTH-1:0] i_cxs_if_cxs_rx_cntl,
  output logic                      o_cxs_if_cxs_rx_crdgnt,

  input  logic                      i_cxs_if_cxs_tx_crdgnt,
  output logic                      o_cxs_if_cxs_tx_valid,
  output logic [CXS_DATA_WIDTH-1:0] o_cxs_if_cxs_tx_data,
  output logic [CXS_CNTL_WIDTH-1:0] o_cxs_if_cxs_tx_cntl,

  input  logic                      i_cxs_if_async_fifo_full,
  output logic                      o_cxs_if_async_fifo_w_en,
  output logic [WORD_WIDTH-1:0]     o_cxs_if_async_fifo_w_data,

  input  logic                      i_cxs_if_error_valid_sync,
  input  logic [1:0]                i_cxs_if_error_in
);

  logic                      flit_fifo_wr;
  logic [FLIT_WIDTH-1:0]     flit_fifo_wdata;
  logic                      flit_fifo_rd;
  logic [FLIT_WIDTH-1:0]     flit_fifo_rdata;
  logic                      flit_fifo_full;
  logic                      flit_fifo_empty;

  logic [$clog2(FLIT_FIFO_DEPTH):0] credit_counter;

  logic                      packet_valid;
  logic [CXS_DATA_WIDTH-1:0] packet_data;
  logic [CXS_CNTL_WIDTH-1:0] packet_ctrl;

  // Packet encoder -> TX interface
  logic                      flit_valid;
  logic [CXS_DATA_WIDTH-1:0] flit_tx;
  logic [CXS_CNTL_WIDTH-1:0] flit_cntrl;
  logic                      flit_ready;

  rx_interface
  #(
    // Parameter Declaration
     .CXS_DATA_WIDTH (CXS_DATA_WIDTH)  // CXS Data Width
    ,.CXS_CNTL_WIDTH (CXS_CNTL_WIDTH)  // CXS Control Width
    ,.FLIT_WIDTH     (FLIT_WIDTH)      // FLIT Width
  )
  u_rx_interface
  (
    // Ports Declaration
     .i_rx_interface_cxs_rx_valid    (i_cxs_if_cxs_rx_valid) // I: CXS RX Valid
    ,.i_rx_interface_cxs_rx_data     (i_cxs_if_cxs_rx_data)  // I: CXS RX Data
    ,.i_rx_interface_cxs_rx_cntl     (i_cxs_if_cxs_rx_cntl)  // I: CXS RX Control
    ,.i_rx_interface_flit_fifo_full  (flit_fifo_full)        // I: FLIT FIFO Full
    ,.o_rx_interface_flit_fifo_wr    (flit_fifo_wr)          // O: FLIT FIFO Write
    ,.o_rx_interface_flit_fifo_wdata (flit_fifo_wdata)       // O: FLIT FIFO Write Data
  );

  flit_fifo
  #(
    // Parameter Declaration
     .DEPTH      (FLIT_FIFO_DEPTH)     // FLIT FIFO Depth
    ,.DATA_WIDTH (FLIT_WIDTH)          // FLIT Width
  )
  u_flit_fifo
  (
    // Ports Declaration
     .i_flit_fifo_rst_n (i_cxs_if_rst_n)   // I: CXS Async Reset
    ,.i_flit_fifo_clk   (i_cxs_if_clk)     // I: CXS Clock
    ,.i_flit_fifo_wr    (flit_fifo_wr)     // I: FLIT FIFO Write
    ,.i_flit_fifo_wdata (flit_fifo_wdata)  // I: FLIT FIFO Write Data
    ,.i_flit_fifo_rd    (flit_fifo_rd)     // I: FLIT FIFO Read
    ,.o_flit_fifo_rdata (flit_fifo_rdata)  // O: FLIT FIFO Read Data
    ,.o_flit_fifo_full  (flit_fifo_full)   // O: FLIT FIFO Full
    ,.o_flit_fifo_empty (flit_fifo_empty)  // O: FLIT FIFO Empty
  );

  credit_manager
  #(
    // Parameter Declaration
     .DEPTH (FLIT_FIFO_DEPTH)           // FLIT FIFO Depth
  )
  u_credit_manager
  (
    // Ports Declaration
     .i_credit_manager_rst_n           (i_cxs_if_rst_n)         // I: CXS Async Reset
    ,.i_credit_manager_clk             (i_cxs_if_clk)           // I: CXS Clock
    ,.i_credit_manager_flit_fifo_full  (flit_fifo_full)         // I: FLIT FIFO Full
    ,.i_credit_manager_flit_fifo_empty (flit_fifo_empty)        // I: FLIT FIFO Empty
    ,.i_credit_manager_flit_fifo_wr    (flit_fifo_wr)           // I: FLIT FIFO Write
    ,.i_credit_manager_flit_fifo_rd    (flit_fifo_rd)           // I: FLIT FIFO Read
    ,.o_credit_manager_cxs_rx_crdgnt   (o_cxs_if_cxs_rx_crdgnt) // O: CXS RX Credit Grant
  );

  packet_formatter
  #(
    // Parameter Declaration
     .CXS_DATA_WIDTH (CXS_DATA_WIDTH)  // CXS Data Width
    ,.CXS_CNTL_WIDTH (CXS_CNTL_WIDTH)  // CXS Control Width
    ,.FLIT_WIDTH     (FLIT_WIDTH)      // FLIT Width
    ,.WORD_WIDTH     (WORD_WIDTH)      // TLP Word Width
  )
  u_packet_formatter
  (
    // Ports Declaration
     .i_packet_formatter_rst_n             (i_cxs_if_rst_n)             // I: CXS Async Reset
    ,.i_packet_formatter_clk               (i_cxs_if_clk)               // I: CXS Clock
    ,.i_packet_formatter_flit_fifo_empty   (flit_fifo_empty)            // I: FLIT FIFO Empty
    ,.o_packet_formatter_flit_fifo_rd      (flit_fifo_rd)               // O: FLIT FIFO Read
    ,.i_packet_formatter_flit_fifo_rdata   (flit_fifo_rdata)            // I: FLIT FIFO Read Data
    ,.i_packet_formatter_async_fifo_full   (i_cxs_if_async_fifo_full)   // I: Async FIFO Full
    ,.o_packet_formatter_async_fifo_w_en   (o_cxs_if_async_fifo_w_en)   // O: Async FIFO Write Enable
    ,.o_packet_formatter_async_fifo_w_data (o_cxs_if_async_fifo_w_data) // O: Async FIFO Write Data
  );

  packet_encoder
  #(
    // Parameter Declaration
     .CXS_DATA_WIDTH (CXS_DATA_WIDTH)  // CXS Data Width
    ,.CXS_CNTL_WIDTH (CXS_CNTL_WIDTH)  // CXS Control Width
  )
  u_packet_encoder
  (
    // Ports Declaration
     .i_packet_encoder_clk              (i_cxs_if_clk)              // I: CXS Clock
    ,.i_packet_encoder_rst_n            (i_cxs_if_rst_n)            // I: CXS Async Reset
    ,.i_packet_encoder_error_valid_sync (i_cxs_if_error_valid_sync) // I: Synchronized Error Pulse
    ,.i_packet_encoder_error_in         (i_cxs_if_error_in)         // I: Error Code
    ,.o_packet_encoder_flit_tx          (flit_tx)                   // O: Response FLIT Data
    ,.o_packet_encoder_flit_cntrl       (flit_cntrl)                // O: Response FLIT Control
    ,.o_packet_encoder_flit_valid       (flit_valid)                // O: Response FLIT Valid
  );

  tx_interface
  #(
    // Parameter Declaration
     .CXS_DATA_WIDTH (CXS_DATA_WIDTH)  // CXS Data Width
    ,.CXS_CNTL_WIDTH (CXS_CNTL_WIDTH)  // CXS Control Width
    ,.FLIT_WIDTH     (FLIT_WIDTH)      // FLIT Width
    ,.MAX_CREDITS    (FLIT_FIFO_DEPTH) // Max Outstanding TX Credits
  )
  u_tx_interface
  (
    // Ports Declaration
     .i_tx_interface_clk           (i_cxs_if_clk)            // I: CXS Clock
    ,.i_tx_interface_rst_n         (i_cxs_if_rst_n)          // I: CXS Async Reset
    ,.i_tx_interface_cxs_tx_crdgnt (i_cxs_if_cxs_tx_crdgnt)  // I: CXS TX Credit Grant
    ,.i_tx_interface_flit_valid    (flit_valid)              // I: FLIT Valid
    ,.i_tx_interface_flit_data_in  ({flit_cntrl, flit_tx})   // I: FLIT Data
    ,.o_tx_interface_flit_ready    (flit_ready)              // O: FLIT Ready
    ,.o_tx_interface_cxs_tx_valid  (o_cxs_if_cxs_tx_valid)   // O: CXS TX Valid
    ,.o_tx_interface_cxs_tx_data   (o_cxs_if_cxs_tx_data)    // O: CXS TX Data
    ,.o_tx_interface_cxs_tx_cntl   (o_cxs_if_cxs_tx_cntl)    // O: CXS TX Control
  );

endmodule
