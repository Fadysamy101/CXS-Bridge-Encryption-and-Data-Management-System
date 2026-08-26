module asynchronous_fifo #(
  parameter DEPTH      = 8,
  parameter DATA_WIDTH = 8
)(
  input                       i_asynchronous_fifo_w_clk,
  input                       i_asynchronous_fifo_w_rst_n,
  input                       i_asynchronous_fifo_r_clk,
  input                       i_asynchronous_fifo_r_rst_n,
  input                       i_asynchronous_fifo_w_en,
  input                       i_asynchronous_fifo_r_en,
  input      [DATA_WIDTH-1:0] i_asynchronous_fifo_data_in,
  output reg [DATA_WIDTH-1:0] o_asynchronous_fifo_data_out,
  output reg                  o_asynchronous_fifo_full,
  output reg                  o_asynchronous_fifo_empty
);

  parameter PTR_WIDTH = $clog2(DEPTH);

  reg [PTR_WIDTH:0] g_wptr_sync;
  reg [PTR_WIDTH:0] g_rptr_sync;
  reg [PTR_WIDTH:0] b_wptr;
  reg [PTR_WIDTH:0] b_rptr;
  reg [PTR_WIDTH:0] g_wptr;
  reg [PTR_WIDTH:0] g_rptr;

  wire [PTR_WIDTH-1:0] waddr;
  wire [PTR_WIDTH-1:0] raddr;

  // Write pointer into the read clock domain
  synchronizer
  #(
    // Parameter Declaration
     .WIDTH (PTR_WIDTH)                          // Gray Pointer Width
  )
  u_sync_wptr
  (
    // Ports Declaration
     .i_synchronizer_clk   (i_asynchronous_fifo_r_clk)   // I: Read Clock
    ,.i_synchronizer_rst_n (i_asynchronous_fifo_r_rst_n) // I: Read Async Reset
    ,.i_synchronizer_d_in  (g_wptr)                      // I: Gray Write Pointer
    ,.o_synchronizer_d_out (g_wptr_sync)                 // O: Synchronized Gray Write Pointer
  );

  // Read pointer into the write clock domain
  synchronizer
  #(
    // Parameter Declaration
     .WIDTH (PTR_WIDTH)                          // Gray Pointer Width
  )
  u_sync_rptr
  (
    // Ports Declaration
     .i_synchronizer_clk   (i_asynchronous_fifo_w_clk)   // I: Write Clock
    ,.i_synchronizer_rst_n (i_asynchronous_fifo_w_rst_n) // I: Write Async Reset
    ,.i_synchronizer_d_in  (g_rptr)                      // I: Gray Read Pointer
    ,.o_synchronizer_d_out (g_rptr_sync)                 // O: Synchronized Gray Read Pointer
  );

  wptr_handler
  #(
    // Parameter Declaration
     .PTR_WIDTH (PTR_WIDTH)                      // Pointer Width
  )
  u_wptr_handler
  (
    // Ports Declaration
     .i_wptr_handler_w_clk       (i_asynchronous_fifo_w_clk)   // I: Write Clock
    ,.i_wptr_handler_w_rst_n     (i_asynchronous_fifo_w_rst_n) // I: Write Async Reset
    ,.i_wptr_handler_w_en        (i_asynchronous_fifo_w_en)    // I: Write Enable
    ,.i_wptr_handler_g_rptr_sync (g_rptr_sync)                 // I: Synchronized Gray Read Pointer
    ,.o_wptr_handler_b_wptr      (b_wptr)                      // O: Binary Write Pointer
    ,.o_wptr_handler_g_wptr      (g_wptr)                      // O: Gray Write Pointer
    ,.o_wptr_handler_full        (o_asynchronous_fifo_full)    // O: FIFO Full
  );

  rptr_handler
  #(
    // Parameter Declaration
     .PTR_WIDTH (PTR_WIDTH)                      // Pointer Width
  )
  u_rptr_handler
  (
    // Ports Declaration
     .i_rptr_handler_r_clk       (i_asynchronous_fifo_r_clk)   // I: Read Clock
    ,.i_rptr_handler_r_rst_n     (i_asynchronous_fifo_r_rst_n) // I: Read Async Reset
    ,.i_rptr_handler_r_en        (i_asynchronous_fifo_r_en)    // I: Read Enable
    ,.i_rptr_handler_g_wptr_sync (g_wptr_sync)                 // I: Synchronized Gray Write Pointer
    ,.o_rptr_handler_b_rptr      (b_rptr)                      // O: Binary Read Pointer
    ,.o_rptr_handler_g_rptr      (g_rptr)                      // O: Gray Read Pointer
    ,.o_rptr_handler_empty       (o_asynchronous_fifo_empty)   // O: FIFO Empty
  );

  fifo_mem
  #(
    // Parameter Declaration
     .DEPTH      (DEPTH)                         // FIFO Depth
    ,.DATA_WIDTH (DATA_WIDTH)                    // Data Width
    ,.PTR_WIDTH  (PTR_WIDTH)                     // Pointer Width
  )
  u_fifo_mem
  (
    // Ports Declaration
     .i_fifo_mem_w_clk    (i_asynchronous_fifo_w_clk)    // I: Write Clock
    ,.i_fifo_mem_w_en     (i_asynchronous_fifo_w_en)     // I: Write Enable
    ,.i_fifo_mem_r_clk    (i_asynchronous_fifo_r_clk)    // I: Read Clock
    ,.i_fifo_mem_r_en     (i_asynchronous_fifo_r_en)     // I: Read Enable
    ,.i_fifo_mem_b_wptr   (b_wptr)                       // I: Binary Write Pointer
    ,.i_fifo_mem_b_rptr   (b_rptr)                       // I: Binary Read Pointer
    ,.i_fifo_mem_data_in  (i_asynchronous_fifo_data_in)  // I: Write Data
    ,.i_fifo_mem_full     (o_asynchronous_fifo_full)     // I: FIFO Full
    ,.i_fifo_mem_empty    (o_asynchronous_fifo_empty)    // I: FIFO Empty
    ,.o_fifo_mem_data_out (o_asynchronous_fifo_data_out) // O: Read Data
  );

endmodule
