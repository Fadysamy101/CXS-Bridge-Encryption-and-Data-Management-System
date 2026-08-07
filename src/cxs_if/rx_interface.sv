
module rx_interface #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14,
    parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH  
)(
    
    input  logic                      cxs_rx_valid,     
    input  logic [CXS_DATA_WIDTH-1:0] cxs_rx_data,      
    input  logic [CXS_CNTL_WIDTH-1:0] cxs_rx_cntl,      

    
    input  logic                      flit_fifo_full,   
    output logic                      flit_fifo_wr,     
    output logic [FLIT_WIDTH-1:0]     flit_fifo_wdata   
);

    
    
    assign flit_fifo_wr    = cxs_rx_valid && !flit_fifo_full;

    
    assign flit_fifo_wdata = {cxs_rx_cntl, cxs_rx_data};

endmodule
