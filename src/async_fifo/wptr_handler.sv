module wptr_handler #(
  parameter PTR_WIDTH = 3
)(
  input                      i_wptr_handler_w_clk,
  input                      i_wptr_handler_w_rst_n,
  input                      i_wptr_handler_w_en,
  input      [PTR_WIDTH:0]   i_wptr_handler_g_rptr_sync,
  output reg [PTR_WIDTH:0]   o_wptr_handler_b_wptr,
  output reg [PTR_WIDTH:0]   o_wptr_handler_g_wptr,
  output reg                 o_wptr_handler_full
);

  reg [PTR_WIDTH:0] b_wptr_next;
  reg [PTR_WIDTH:0] g_wptr_next;

  reg               wrap_around;
  wire              wfull;

  assign b_wptr_next = o_wptr_handler_b_wptr + (i_wptr_handler_w_en & !o_wptr_handler_full);
  assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;

  always @(posedge i_wptr_handler_w_clk or negedge i_wptr_handler_w_rst_n) begin: wptr_proc
    if (!i_wptr_handler_w_rst_n) begin
      o_wptr_handler_b_wptr <= 0;            // set default value
      o_wptr_handler_g_wptr <= 0;
    end
    else begin
      o_wptr_handler_b_wptr <= b_wptr_next;  // incr binary write pointer
      o_wptr_handler_g_wptr <= g_wptr_next;  // incr gray write pointer
    end
  end

  always @(posedge i_wptr_handler_w_clk or negedge i_wptr_handler_w_rst_n) begin: full_proc
    if (!i_wptr_handler_w_rst_n) o_wptr_handler_full <= 0;
    else                         o_wptr_handler_full <= wfull;
  end

  assign wfull = (g_wptr_next == {~i_wptr_handler_g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1],
                                   i_wptr_handler_g_rptr_sync[PTR_WIDTH-2:0]});

endmodule
