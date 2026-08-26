module rptr_handler #(
  parameter PTR_WIDTH = 3
)(
  input                      i_rptr_handler_r_clk,
  input                      i_rptr_handler_r_rst_n,
  input                      i_rptr_handler_r_en,
  input      [PTR_WIDTH:0]   i_rptr_handler_g_wptr_sync,
  output reg [PTR_WIDTH:0]   o_rptr_handler_b_rptr,
  output reg [PTR_WIDTH:0]   o_rptr_handler_g_rptr,
  output reg                 o_rptr_handler_empty
);

  reg [PTR_WIDTH:0] b_rptr_next;
  reg [PTR_WIDTH:0] g_rptr_next;
  wire              rempty;

  assign b_rptr_next = o_rptr_handler_b_rptr + (i_rptr_handler_r_en & !o_rptr_handler_empty);
  assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;
  assign rempty      = (i_rptr_handler_g_wptr_sync == g_rptr_next);

  always @(posedge i_rptr_handler_r_clk or negedge i_rptr_handler_r_rst_n) begin: rptr_proc
    if (!i_rptr_handler_r_rst_n) begin
      o_rptr_handler_b_rptr <= 0;
      o_rptr_handler_g_rptr <= 0;
    end
    else begin
      o_rptr_handler_b_rptr <= b_rptr_next;
      o_rptr_handler_g_rptr <= g_rptr_next;
    end
  end

  always @(posedge i_rptr_handler_r_clk or negedge i_rptr_handler_r_rst_n) begin: empty_proc
    if (!i_rptr_handler_r_rst_n) o_rptr_handler_empty <= 1;
    else                         o_rptr_handler_empty <= rempty;
  end

endmodule
