
module parity_unit #(
  parameter int ENC_DATA_WIDTH = 32
)(
  input  logic                      i_parity_unit_parity_mode,  // Register File [2]
  input  logic [ENC_DATA_WIDTH-1:0] i_parity_unit_data_in,
  output logic [ENC_DATA_WIDTH:0]   o_parity_unit_data_out
);

  localparam logic PAR_EVEN = 1'b0;
  localparam logic PAR_ODD  = 1'b1;

  logic parity_bit;

  // Even parity : the appended bit makes the total number of 1s even.
  // Odd parity  : it makes the total number of 1s odd.
  always_comb begin: parity_bit_proc
    case (i_parity_unit_parity_mode)
      PAR_EVEN: parity_bit =  (^i_parity_unit_data_in);
      PAR_ODD : parity_bit = ~(^i_parity_unit_data_in);
      default : parity_bit = 1'b0;
    endcase
  end

  assign o_parity_unit_data_out = {parity_bit, i_parity_unit_data_in};

endmodule
