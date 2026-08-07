
module flit_fifo #(
    parameter int DEPTH      = 16,   
    parameter int DATA_WIDTH = 270   
)(
    input  logic                  rst_n,             
    input  logic                  clk,               

    input  logic                  flit_fifo_wr,      
    input  logic [DATA_WIDTH-1:0] flit_fifo_wdata,   

    input  logic                  flit_fifo_rd,      
    output logic [DATA_WIDTH-1:0] flit_fifo_rdata,   

    output logic                  flit_fifo_full,    
    output logic                  flit_fifo_empty    
);

    localparam int PTR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [DEPTH];

    
    logic [PTR_WIDTH:0] wptr, rptr;

    
    wire do_wr = flit_fifo_wr && !flit_fifo_full;
    wire do_rd = flit_fifo_rd && !flit_fifo_empty;

    
    
    
    always_ff @(posedge clk) begin
        if (do_wr)
            mem[wptr[PTR_WIDTH-1:0]] <= flit_fifo_wdata;
    end

    
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= '0;
            rptr <= '0;
        end
        else begin
            if (do_wr) wptr <= wptr + 1'b1;
            if (do_rd) rptr <= rptr + 1'b1;
        end
    end

    
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flit_fifo_rdata <= '0;
        else if (do_rd)
            flit_fifo_rdata <= mem[rptr[PTR_WIDTH-1:0]];
    end

    // ---------------------------------------------------------------------
    // Status flags
    // Empty : both pointers identical (no wrap).
    // Full  : same location but pointers wrapped a different number of times.
    // ---------------------------------------------------------------------
    assign flit_fifo_empty = (wptr == rptr);
    assign flit_fifo_full  = (wptr[PTR_WIDTH]     != rptr[PTR_WIDTH]) &&
                             (wptr[PTR_WIDTH-1:0] == rptr[PTR_WIDTH-1:0]);

endmodule
