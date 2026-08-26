
module parity_unit #(
    parameter int ENC_DATA_WIDTH = 32
)(
    input  logic                        PARITY_MODE,   // Register File [2]
    input  logic [ENC_DATA_WIDTH-1:0]   Data_in,
    output logic [ENC_DATA_WIDTH:0]     Data_out
);

   
    localparam logic PAR_EVEN = 1'b0;
    localparam logic PAR_ODD  = 1'b1;


    logic parity_bit;

    // Even parity : the appended bit makes the total number of 1s even.
    // Odd parity  : it makes the total number of 1s odd.
    always_comb begin
        case (PARITY_MODE)
            PAR_EVEN: parity_bit =  (^Data_in);
            PAR_ODD : parity_bit = ~(^Data_in);
            default : parity_bit = 1'b0;  
        endcase
    end

    assign Data_out = {parity_bit, Data_in};

endmodule
