module fifo_mem #(
  parameter DEPTH      = 8,
  parameter DATA_WIDTH = 8,
  parameter PTR_WIDTH  = 3
)(
  input                       i_fifo_mem_w_clk,
  input                       i_fifo_mem_w_en,
  input                       i_fifo_mem_r_clk,
  input                       i_fifo_mem_r_en,
  input      [PTR_WIDTH:0]    i_fifo_mem_b_wptr,
  input      [PTR_WIDTH:0]    i_fifo_mem_b_rptr,
  input      [DATA_WIDTH-1:0] i_fifo_mem_data_in,
  input                       i_fifo_mem_full,
  input                       i_fifo_mem_empty,
  output reg [DATA_WIDTH-1:0] o_fifo_mem_data_out
);

  reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];

  always @(posedge i_fifo_mem_w_clk) begin: fifo_write_proc
    if (i_fifo_mem_w_en & !i_fifo_mem_full) begin
      fifo[i_fifo_mem_b_wptr[PTR_WIDTH-1:0]] <= i_fifo_mem_data_in;
    end
  end

  // always @(posedge i_fifo_mem_r_clk) begin: fifo_read_proc
  //   if (i_fifo_mem_r_en & !i_fifo_mem_empty) begin
  //     o_fifo_mem_data_out <= fifo[i_fifo_mem_b_rptr[PTR_WIDTH-1:0]];
  //   end
  // end
  // 
  assign o_fifo_mem_data_out = fifo[i_fifo_mem_b_rptr[PTR_WIDTH-1:0]];

endmodule
