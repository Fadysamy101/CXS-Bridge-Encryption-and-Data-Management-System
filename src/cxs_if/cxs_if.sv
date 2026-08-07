

module cxs_if #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14,
    parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH, 
    parameter int FLIT_FIFO_DEPTH = 16,
    parameter int WORD_WIDTH      = 32
)(
    input  logic                      clk_cxs,            
    input  logic                      rst_n_cxs,          

    
    input  logic                      cxs_rx_valid,       
    input  logic [CXS_DATA_WIDTH-1:0] cxs_rx_data,        
    input  logic [CXS_CNTL_WIDTH-1:0] cxs_rx_cntl,        
    output logic                      cxs_rx_crdgnt,      

    
    output logic                      cxs_tx_valid,       
    output logic [CXS_DATA_WIDTH-1:0] cxs_tx_data,        
    output logic [CXS_CNTL_WIDTH-1:0] cxs_tx_cntl,        

    
    input  logic                      async_fifo_full,    
    output logic                      async_fifo_w_en,    
    output logic [WORD_WIDTH-1:0]     async_fifo_w_data,  

    
    input  logic                      flit_valid,         
    input  logic [FLIT_WIDTH-1:0]     flit_data_in,       
    output logic                      flit_ready          
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

    
    
    
    rx_interface #(
        .CXS_DATA_WIDTH (CXS_DATA_WIDTH),
        .CXS_CNTL_WIDTH (CXS_CNTL_WIDTH),
        .FLIT_WIDTH     (FLIT_WIDTH)
    ) u_rx_interface (
        .cxs_rx_valid    (cxs_rx_valid),
        .cxs_rx_data     (cxs_rx_data),
        .cxs_rx_cntl     (cxs_rx_cntl),
        .flit_fifo_full  (flit_fifo_full),
        .flit_fifo_wr    (flit_fifo_wr),
        .flit_fifo_wdata (flit_fifo_wdata)
    );

    
    
    
    flit_fifo #(
        .DEPTH      (FLIT_FIFO_DEPTH),
        .DATA_WIDTH (FLIT_WIDTH)
    ) u_flit_fifo (
        .rst_n           (rst_n_cxs),
        .clk             (clk_cxs),
        .flit_fifo_wr    (flit_fifo_wr),
        .flit_fifo_wdata (flit_fifo_wdata),
        .flit_fifo_rd    (flit_fifo_rd),
        .flit_fifo_rdata (flit_fifo_rdata),
        .flit_fifo_full  (flit_fifo_full),
        .flit_fifo_empty (flit_fifo_empty)
    );

    
    
    
    credit_manager #(
        .DEPTH (FLIT_FIFO_DEPTH)
    ) u_credit_manager (
        .rst_n          (rst_n_cxs),
        .clk            (clk_cxs),
        .flit_fifo_wr   (flit_fifo_wr),
        .flit_fifo_rd   (flit_fifo_rd),
        .credit_counter (credit_counter),
        .cxs_rx_crdgnt  (cxs_rx_crdgnt)
    );

    
    
    
    packet_formatter #(
        .CXS_DATA_WIDTH (CXS_DATA_WIDTH),
        .CXS_CNTL_WIDTH (CXS_CNTL_WIDTH),
        .FLIT_WIDTH     (FLIT_WIDTH),
        .WORD_WIDTH     (WORD_WIDTH)
    ) u_packet_formatter (
        .rst_n             (rst_n_cxs),
        .clk               (clk_cxs),
        .flit_fifo_empty   (flit_fifo_empty),
        .flit_fifo_rd      (flit_fifo_rd),
        .flit_fifo_rdata   (flit_fifo_rdata),
        .packet_valid      (packet_valid),
        .packet_data       (packet_data),
        .packet_ctrl       (packet_ctrl),
        .async_fifo_full   (async_fifo_full),
        .async_fifo_w_en   (async_fifo_w_en),
        .async_fifo_w_data (async_fifo_w_data)
    );

    
    
    
    tx_interface #(
        .CXS_DATA_WIDTH (CXS_DATA_WIDTH),
        .CXS_CNTL_WIDTH (CXS_CNTL_WIDTH),
        .FLIT_WIDTH     (FLIT_WIDTH)
    ) u_tx_interface (
        .clk_cxs      (clk_cxs),
        .rst_n_cxs    (rst_n_cxs),
        .flit_valid   (flit_valid),
        .flit_data_in (flit_data_in),
        .flit_ready   (flit_ready),
        .cxs_tx_valid (cxs_tx_valid),
        .cxs_tx_data  (cxs_tx_data),
        .cxs_tx_cntl  (cxs_tx_cntl)
    );

endmodule
