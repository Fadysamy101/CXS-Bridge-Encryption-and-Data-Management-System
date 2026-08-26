module synchronizer #(
  parameter WIDTH = 16
)(
  input                    i_synchronizer_clk,
  input                    i_synchronizer_rst_n,
  input      [WIDTH:0]     i_synchronizer_d_in,
  output reg [WIDTH:0]     o_synchronizer_d_out
);

  reg [WIDTH:0] d_in_d0;

  always @(posedge i_synchronizer_clk or negedge i_synchronizer_rst_n) begin: sync_proc
    if (!i_synchronizer_rst_n) begin
      d_in_d0              <= 0;
      o_synchronizer_d_out <= 0;
    end
    else begin
      d_in_d0              <= i_synchronizer_d_in;
      o_synchronizer_d_out <= d_in_d0;
    end
  end

endmodule
