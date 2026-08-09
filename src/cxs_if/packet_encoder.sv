
module packet_encoder #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14
)(
    input  logic                      clk_cxs,           
    input  logic                      rst_n_cxs,         

    input  logic                      error_valid_sync,  
    input  logic [1:0]                error_in,          

    output logic [CXS_DATA_WIDTH-1:0] flit_tx,           
    output logic [CXS_CNTL_WIDTH-1:0] flit_cntrl,        
    output logic                      flit_valid         
);

    
    localparam logic [7:0] RESP_OPCODE_ERROR = 8'hE0;

    // CXS control field bit positions (see header note).
    localparam int CNTL_START_BIT = 0;
    localparam int CNTL_END_BIT   = 1;

    logic error_valid_sync_d;

    // One response packet per assertion of error_valid_sync: a level that stays
    // high must not keep re-issuing FLITs.
    wire error_event = error_valid_sync && !error_valid_sync_d;

    logic [31:0] resp_word;
    always_comb begin
        resp_word          = '0;
        resp_word[15:8]    = RESP_OPCODE_ERROR;
        resp_word[1:0]     = error_in;
    end

    logic [CXS_CNTL_WIDTH-1:0] resp_cntl;
    always_comb begin
        resp_cntl                 = '0;
        resp_cntl[CNTL_START_BIT] = 1'b1;   
        resp_cntl[CNTL_END_BIT]   = 1'b1;   // ... and end in the same FLIT
    end

    always_ff @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            error_valid_sync_d <= 1'b0;
            flit_tx            <= '0;
            flit_cntrl         <= '0;
            flit_valid         <= 1'b0;
        end
        else begin
            error_valid_sync_d <= error_valid_sync;
            flit_valid         <= error_event;

            if (error_event) begin
                flit_tx    <= {{(CXS_DATA_WIDTH-32){1'b0}}, resp_word};
                flit_cntrl <= resp_cntl;
            end
        end
    end

endmodule
