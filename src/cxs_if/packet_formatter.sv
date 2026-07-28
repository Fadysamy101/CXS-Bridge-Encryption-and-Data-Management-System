//TODO incomplete packet formatter implementation
module packet_formatter (
    input                    clk_cxs,
    input                    rst_n_cxs,

    // async_fifo (downstream storage fifo) write-side status/handshake
    input                    async_fifo_full,
    output reg               async_fifo_w_en,
    output reg      [31:0]   async_fifo_w_data,

    // flit_fifo read-side handshake
    input                    flit_fifo_empty,
    output reg               flit_rd_en,        // R_en into flit_fifo
    input      [269:0]       flit_data          // R_data from flit_fifo
);

    reg [269:0] shift_reg;
    reg [2:0]   word_cnt;
    reg         sending;
    
always @(posedge clk_cxs or negedge rst_n_cxs) begin
    if (!rst_n_cxs) begin
        shift_reg   <= '0;
        word_cnt    <= 3'd0;
        sending     <= 1'b0;

        flit_rd_en  <= 1'b0;
        async_fifo_w_en   <= 1'b0;
        async_fifo_w_data <= 32'd0;

    end else begin
        flit_rd_en <= 1'b0;
        async_fifo_w_en  <= 1'b0;

        // Load a new flit
        if (!sending && !flit_fifo_empty && !async_fifo_full) begin
            flit_rd_en <= 1'b1;
            shift_reg  <= flit_data;
            word_cnt   <= 3'd0;
            sending    <= 1'b1;
        end

        // Send one 32-bit word each cycle
        else if (sending && !async_fifo_full) begin
            async_fifo_w_en   <= 1'b1;
            async_fifo_w_data <= shift_reg[31:0];

            shift_reg <= shift_reg >> 32;
            word_cnt  <= word_cnt + 1'b1;

            if (word_cnt == 3'd7)
                sending <= 1'b0;
        end
    end
end

endmodule
