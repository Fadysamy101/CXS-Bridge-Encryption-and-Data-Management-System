
module credit_manager #(
  parameter int DEPTH = 16
)(
  input  logic i_credit_manager_rst_n,
  input  logic i_credit_manager_clk,

  input  logic i_credit_manager_flit_fifo_wr,
  input  logic i_credit_manager_flit_fifo_rd,
  input  logic i_credit_manager_flit_fifo_empty,
  input  logic i_credit_manager_flit_fifo_full,

  output logic o_credit_manager_cxs_rx_crdgnt
);

  localparam int CNT_WIDTH = $clog2(DEPTH) + 1;

  logic [$clog2(DEPTH):0] credit_counter;

  // as long there is at least one credit, grant credits.
  wire grant = (|credit_counter);

  always_ff @(posedge i_credit_manager_clk or negedge i_credit_manager_rst_n) begin: credit_counter_proc
    if (!i_credit_manager_rst_n) begin
      credit_counter                 <= CNT_WIDTH'(DEPTH);
      o_credit_manager_cxs_rx_crdgnt <= 1'b0;
    end
    else begin
      // counter operation. A simultaneous read and write
      // leaves the occupancy - and therefore the counter - unchanged.
      if (i_credit_manager_flit_fifo_rd && !i_credit_manager_flit_fifo_empty && !i_credit_manager_flit_fifo_wr) begin
        credit_counter <= credit_counter + 1'b1;
      end

      else if (i_credit_manager_flit_fifo_wr && !i_credit_manager_flit_fifo_full && !i_credit_manager_flit_fifo_rd) begin
        credit_counter <= credit_counter - 1'b1;
      end

      o_credit_manager_cxs_rx_crdgnt <= grant;
    end
  end

endmodule
