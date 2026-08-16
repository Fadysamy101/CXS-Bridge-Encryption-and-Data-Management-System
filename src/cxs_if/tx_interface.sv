
module tx_interface #(
    parameter int CXS_DATA_WIDTH = 256,
    parameter int CXS_CNTL_WIDTH = 14,
    parameter int FLIT_WIDTH     = CXS_DATA_WIDTH + CXS_CNTL_WIDTH,
    parameter int MAX_CREDITS    = 16
)(
    input  logic                      clk_cxs,
    input  logic                      rst_n_cxs,

    // Credit granted by the link partner: one grant allows one transmitted FLIT
    input  logic                      cxs_tx_crdgnt,

    input  logic                      flit_valid,
    input  logic [FLIT_WIDTH-1:0]     flit_data_in,
    output logic                      flit_ready,

    output logic                      cxs_tx_valid,
    output logic [CXS_DATA_WIDTH-1:0] cxs_tx_data,
    output logic [CXS_CNTL_WIDTH-1:0] cxs_tx_cntl
);

    localparam int CNT_WIDTH = $clog2(MAX_CREDITS) + 1;

    logic [CNT_WIDTH-1:0]  credit_counter;
    logic [FLIT_WIDTH-1:0] flit_hold;
    logic                  flit_pending;

    wire has_credit = (|credit_counter);
    wire capture    = flit_valid && flit_ready;
    wire send       = flit_pending && has_credit;

    // A single FLIT is held until enough credit is granted to send it
    assign flit_ready = !flit_pending;

    always_ff @(posedge clk_cxs or negedge rst_n_cxs) begin
        if (!rst_n_cxs) begin
            credit_counter <= '0;
            flit_hold      <= '0;
            flit_pending   <= 1'b0;
            cxs_tx_valid   <= 1'b0;
            cxs_tx_data    <= '0;
            cxs_tx_cntl    <= '0;
        end
        else begin
            // A grant arriving in the same cycle as a transmission leaves the
            // number of available credits unchanged.
            if (cxs_tx_crdgnt && !send && (credit_counter != CNT_WIDTH'(MAX_CREDITS)))
                credit_counter <= credit_counter + 1'b1;
            else if (send && !cxs_tx_crdgnt)
                credit_counter <= credit_counter - 1'b1;

            if (capture) begin
                flit_hold    <= flit_data_in;
                flit_pending <= 1'b1;
            end
            else if (send) begin
                flit_pending <= 1'b0;
            end

            cxs_tx_valid <= send;
            if (send) begin
                cxs_tx_data <= flit_hold[CXS_DATA_WIDTH-1:0];
                cxs_tx_cntl <= flit_hold[FLIT_WIDTH-1:CXS_DATA_WIDTH];
            end
        end
    end

endmodule
