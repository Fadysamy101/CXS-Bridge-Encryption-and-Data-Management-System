




















module packet_formatter #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14,
    parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH, 
    parameter int WORD_WIDTH     = 32
)(
    input  logic                      rst_n,             
    input  logic                      clk,               

    
    input  logic                      flit_fifo_empty,   
    output logic                      flit_fifo_rd,      
    input  logic [FLIT_WIDTH-1:0]     flit_fifo_rdata,   



    
    input  logic                      async_fifo_full,   
    output logic                      async_fifo_w_en,   
    output logic [WORD_WIDTH-1:0]     async_fifo_w_data  
);

    localparam int WORDS_PER_FLIT = CXS_DATA_WIDTH / WORD_WIDTH;   
    localparam int WCNT_WIDTH     = $clog2(WORDS_PER_FLIT);

    typedef enum logic [1:0] {
        S_IDLE,     
        S_CAPTURE,  
        S_STREAM    
    } state_e;

    state_e                  state;
    logic [WCNT_WIDTH-1:0]   word_cnt;

    
    wire word_accepted = async_fifo_w_en && !async_fifo_full;
    wire last_word     = (word_cnt == WCNT_WIDTH'(WORDS_PER_FLIT-1));
;

    // ---------------------------------------------------------------------
    // FSM and payload capture
    // ---------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
   
    end

endmodule
