
module flit_fifo #(
    parameter DEPTH      = 16,
    parameter DATA_WIDTH = 270
)(
    input                        clk_cxs,
    input                        rst_n_cxs,

    input                        w_en,
    input      [DATA_WIDTH-1:0]  w_data,
    input                        r_en,
    output reg [DATA_WIDTH-1:0]  r_data,

    output reg                   full,
    output reg                   empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH:0]    wptr, rptr;   

    wire [PTR_WIDTH:0] wptr_next = wptr + (w_en && !full);
    wire [PTR_WIDTH:0] rptr_next = rptr + (r_en && !empty);

    always @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            wptr  <= '0;
            rptr  <= '0;
            full  <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (w_en && !full)
                mem[wptr[PTR_WIDTH-1:0]] <= w_data;

            if (r_en && !empty)
                r_data <= mem[rptr[PTR_WIDTH-1:0]];

            wptr <= wptr_next;
            rptr <= rptr_next;

          
            full  <= (wptr_next[PTR_WIDTH]     != rptr_next[PTR_WIDTH]) &&
                     (wptr_next[PTR_WIDTH-1:0] == rptr_next[PTR_WIDTH-1:0]);
            empty <= (wptr_next == rptr_next);
        end
    end

endmodule
