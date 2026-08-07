// ---------------------------------------------------------------------------
// parity_unit - CXS Bridge Architecture Spec, Section 8
//
// Combinational parity generator sitting between the Encryption Module and the
// CDM. The generated bit is appended above the encrypted word, so Data_out is
// one bit wider than Data_in.
// ---------------------------------------------------------------------------
module parity_unit #(
    parameter int ENC_DATA_WIDTH = 32
)(
    input  logic [1:0]                  PARITY_MODE,   // Register File [3:2]
    input  logic [ENC_DATA_WIDTH-1:0]   Data_in,
    output logic [ENC_DATA_WIDTH:0]     Data_out
);

    localparam logic [1:0] PAR_DISABLED = 2'b00;
    localparam logic [1:0] PAR_EVEN     = 2'b01;
    localparam logic [1:0] PAR_ODD      = 2'b10;
    localparam logic [1:0] PAR_RESERVED = 2'b11;

    logic parity_bit;

    // Even parity : the appended bit makes the total number of 1s even.
    // Odd parity  : it makes the total number of 1s odd.
    always_comb begin
        case (PARITY_MODE)
            PAR_EVEN: parity_bit =  (^Data_in);
            PAR_ODD : parity_bit = ~(^Data_in);
            default : parity_bit = 1'b0;   // PAR_DISABLED and PAR_RESERVED
        endcase
    end

    assign Data_out = {parity_bit, Data_in};

endmodule
