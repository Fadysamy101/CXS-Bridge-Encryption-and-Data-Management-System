// ---------------------------------------------------------------------------
// encryption_unit - CXS Bridge Architecture Spec, Section 7
//
// Configurable bit-expansion "encryption" of the payload word extracted from a
// Data TLP. Each input bit expands to two output bits, so the data output is
// twice the width of the data input. The expansion pair is selected by the
// encryption mode, except when the input word is balanced, which overrides the
// mode (see below).
// ---------------------------------------------------------------------------
module encryption_unit #(
  parameter int DATA_WIDTH = 16
)(
  input  logic [3:0]                i_encryption_unit_enc_mode,  // Register File [7:4]
  input  logic [DATA_WIDTH-1:0]     i_encryption_unit_data_in,
  output logic [(DATA_WIDTH*2)-1:0] o_encryption_unit_data_out
);

  localparam logic [3:0] MODE_EVEN = 4'b0000;   // 0 -> 00, 1 -> 01
  localparam logic [3:0] MODE_ODD  = 4'b0001;   // 0 -> 10, 1 -> 11

  localparam int CNT_WIDTH = $clog2(DATA_WIDTH + 1);

  logic [CNT_WIDTH-1:0]      ones_cnt, zeros_cnt;
  logic                      balanced;
  logic [(DATA_WIDTH*2)-1:0] expanded;

  always_comb begin: ones_cnt_proc
    ones_cnt = '0;
    for (int i = 0; i < DATA_WIDTH; i++)
      ones_cnt += CNT_WIDTH'(i_encryption_unit_data_in[i]);
  end

  assign zeros_cnt = CNT_WIDTH'(DATA_WIDTH) - ones_cnt;

  assign balanced  = (ones_cnt == zeros_cnt) || (!ones_cnt[0] && !zeros_cnt[0]);

  always_comb begin: expand_proc
    for (int i = 0; i < DATA_WIDTH; i++) begin
      if (balanced)
        expanded[i*2 +: 2] = i_encryption_unit_data_in[i] ? 2'b10 : 2'b01;
      else if (i_encryption_unit_enc_mode == MODE_ODD)
        expanded[i*2 +: 2] = i_encryption_unit_data_in[i] ? 2'b11 : 2'b10;
      else // MODE_EVEN and every unassigned encoding
        expanded[i*2 +: 2] = i_encryption_unit_data_in[i] ? 2'b01 : 2'b00;
    end
  end

  assign o_encryption_unit_data_out = expanded;

endmodule
