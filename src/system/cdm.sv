
module cdm #(
  parameter int ADDR_WIDTH = 16,
  parameter int DATA_WIDTH = 16,
  parameter int DEV_MAX    = 8
)(
  input  logic                    i_cdm_clk,
  input  logic                    i_cdm_rst_n,

  input  logic                    i_cdm_r_en,
  input  logic [ADDR_WIDTH-1:0]   i_cdm_r_addr,
  output logic [(DATA_WIDTH*2):0] o_cdm_rdata,     // (DATA_WIDTH*2)+1 bits

  input  logic                    i_cdm_w_en,
  input  logic [ADDR_WIDTH-1:0]   i_cdm_w_addr,
  input  logic [(DATA_WIDTH*2):0] i_cdm_wdata,

  // Configuration parameters published to the rest of the system
  output logic [7:0]              o_cdm_dev_count,
  output logic                    o_cdm_addr_mode,
  output logic [3:0]              o_cdm_enc_mode,
  output logic                    o_cdm_parity_mode
);

  localparam int WORD_WIDTH = (DATA_WIDTH*2) + 1;
  localparam int MEM_DEPTH  = 1 << ADDR_WIDTH;

  // CDM map (spec 10.1)
  localparam logic [ADDR_WIDTH-1:0] CFG_ADDR = ADDR_WIDTH'('h0000);
  localparam logic [ADDR_WIDTH-1:0] DEV_BASE = ADDR_WIDTH'('h0001);

  logic [WORD_WIDTH-1:0] mem [MEM_DEPTH];

  // Reset clears the configuration region only; the data region behaves like
  // an ordinary memory and keeps whatever was written to it.
  always_ff @(posedge i_cdm_clk or negedge i_cdm_rst_n) begin: mem_write_proc
    if (!i_cdm_rst_n) begin
      mem[CFG_ADDR] <= '0;
      for (int i = 0; i < DEV_MAX; i++)
        mem[DEV_BASE + ADDR_WIDTH'(i)] <= '0;
    end
    else if (i_cdm_w_en) begin
      mem[i_cdm_w_addr] <= i_cdm_wdata;
    end
  end

  always_ff @(posedge i_cdm_clk or negedge i_cdm_rst_n) begin: mem_read_proc
    if (!i_cdm_rst_n)
      o_cdm_rdata <= '0;
    else if (i_cdm_r_en)
      o_cdm_rdata <= mem[i_cdm_r_addr];
  end

  // Global configuration register taps (spec 6.2.1)
  assign o_cdm_dev_count   = mem[CFG_ADDR][15:8];
  assign o_cdm_enc_mode    = mem[CFG_ADDR][7:4];
  assign o_cdm_addr_mode   = mem[CFG_ADDR][3];
  assign o_cdm_parity_mode = mem[CFG_ADDR][2];

endmodule
