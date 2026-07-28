// -----------------------------------------------------------------------------
// tx_interface : CXS transmit-side interface. Drives CXS TX bus from packets
// supplied by packet_encoder.
// Clock domain: CLK_CXS (clk_cxs / rst_n_cxs).
// -----------------------------------------------------------------------------
module tx_interface (
    input                    clk_cxs,
    input                    rst_n_cxs,

    // from packet_encoder
    input                    tx_pkt_valid,
    input      [255:0]       tx_pkt_data,
    input      [13:0]        tx_pkt_cntl,
    output reg               tx_pkt_ready,

    // CXS transmit bus
    output reg               CXSTXVALID,
    output reg [255:0]       CXSTXDATA,
    output reg [13:0]        CXSTXCNTL
);

    // TODO: flow control / READY handshake with link partner

    always @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            tx_pkt_ready <= 1'b0;
            CXSTXVALID   <= 1'b0;
            CXSTXDATA    <= '0;
            CXSTXCNTL    <= '0;
        end else begin
            // placeholder pass-through
            tx_pkt_ready <= 1'b1;
            CXSTXVALID   <= tx_pkt_valid;
            CXSTXDATA    <= tx_pkt_data;
            CXSTXCNTL    <= tx_pkt_cntl;
        end
    end

endmodule
