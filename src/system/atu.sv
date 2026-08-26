module atu #(
  parameter int ADDR_WIDTH = 16
)(
  input  logic                  i_atu_clk,
  input  logic                  i_atu_rst_n,

  input  logic                  i_atu_config_signal,
  input  logic                  i_atu_addr_mode,

  input  logic [ADDR_WIDTH-1:0] i_atu_addr_in,
  input  logic [ADDR_WIDTH-1:0] i_atu_config_addr,

  output logic [ADDR_WIDTH-1:0] o_atu_addr_out
);

  localparam logic MODE_RANGE  = 1'b0;
  localparam logic MODE_REGION = 1'b1;

  logic [ADDR_WIDTH-1:0] base_addr_reg;

  // Capture BASE_ADDR during configuration
  always_ff @(posedge i_atu_clk or negedge i_atu_rst_n) begin: base_addr_proc
    if (!i_atu_rst_n)
      base_addr_reg <= '0;
    else if (i_atu_addr_in == 0 && i_atu_config_signal )
      base_addr_reg <= i_atu_config_addr;
  end

  // Address translation
  always_comb begin: addr_translate_proc
    if (i_atu_config_signal) begin
      o_atu_addr_out = i_atu_addr_in;
    end
    else begin
      case (i_atu_addr_mode)
        MODE_RANGE:
          o_atu_addr_out = base_addr_reg + i_atu_addr_in;

        MODE_REGION:
          o_atu_addr_out = base_addr_reg + i_atu_addr_in;

        default:
          o_atu_addr_out = i_atu_addr_in;
      endcase
    end
  end

endmodule
