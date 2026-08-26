
module rx_interface #(
  parameter int CXS_DATA_WIDTH = 256,
  parameter int CXS_CNTL_WIDTH = 14,
  parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH
)(
  input  logic                      i_rx_interface_cxs_rx_valid,
  input  logic [CXS_DATA_WIDTH-1:0] i_rx_interface_cxs_rx_data,
  input  logic [CXS_CNTL_WIDTH-1:0] i_rx_interface_cxs_rx_cntl,

  input  logic                      i_rx_interface_flit_fifo_full,
  output logic                      o_rx_interface_flit_fifo_wr,
  output logic [FLIT_WIDTH-1:0]     o_rx_interface_flit_fifo_wdata
);

  assign o_rx_interface_flit_fifo_wr    = i_rx_interface_cxs_rx_valid &&
                                          !i_rx_interface_flit_fifo_full;

  assign o_rx_interface_flit_fifo_wdata = {i_rx_interface_cxs_rx_cntl,
                                           i_rx_interface_cxs_rx_data};

endmodule
