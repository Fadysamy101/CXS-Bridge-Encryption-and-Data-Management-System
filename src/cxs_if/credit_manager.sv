
module credit_manager(
    input                    clk_cxs,
    input                    rst_n_cxs,

    // flit_fifo status (monitored side)
    input                    flit_fifo_empty,
    input                    flit_fifo_rd,
    input                    flit_fifo_full,
    input                    flit_fifo_wr,

    // credit grant issued back to rx_interface / CXS link
    output reg               cxs_rx_crdgnt
);

    reg [15:0] credit_counter;


    always @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            credit_counter <= 15;
            cxs_rx_crdgnt          <= 1'b0;

        end else begin
            if(!flit_fifo_empty) begin
               cxs_rx_crdgnt <= 1;
            end
            else
               cxs_rx_crdgnt <= 0;

            if(flit_fifo_rd && !flit_fifo_empty)
            credit_counter <= credit_counter +1;

            if (flit_fifo_wr && !flit_fifo_full)
            credit_counter <= credit_counter -1;
        end
    end

endmodule
