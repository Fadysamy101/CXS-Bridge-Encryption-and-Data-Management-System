
module tx_interface #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14,
    parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH  
)(
    input  logic                      clk_cxs,
    input  logic                      rst_n_cxs,

    
    input  logic                      flit_valid,     
    input  logic [FLIT_WIDTH-1:0]     flit_data_in,   
    output logic                      flit_ready,     

    
    output logic                      cxs_tx_valid,
    output logic [CXS_DATA_WIDTH-1:0] cxs_tx_data,
    output logic [CXS_CNTL_WIDTH-1:0] cxs_tx_cntl
);

    assign flit_ready = rst_n_cxs;

    always_ff @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            cxs_tx_valid <= 1'b0;
            cxs_tx_data  <= '0;
            cxs_tx_cntl  <= '0;
        end
        else begin
            cxs_tx_valid <= flit_valid;
            if (flit_valid) begin
                cxs_tx_data <= flit_data_in[CXS_DATA_WIDTH-1:0];
                cxs_tx_cntl <= flit_data_in[FLIT_WIDTH-1:CXS_DATA_WIDTH];
            end
        end
    end

endmodule
