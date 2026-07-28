module rx_interface (

    input                    cxs_rx_valid,
    input      [255:0]       cxs_rx_data,
    input      [13:0]        cxs_rx_cntl,

    input                    flit_fifo_full,
    output reg               flit_fifo_en,      // W_en into flit_fifo
    output reg [269:0]       flit_fifo_data     // W_data into flit_fifo
);

    always @(*) begin
       
        flit_fifo_en   = cxs_rx_valid && !flit_fifo_full;
        flit_fifo_data = {cxs_rx_cntl, cxs_rx_data};
    end

endmodule
