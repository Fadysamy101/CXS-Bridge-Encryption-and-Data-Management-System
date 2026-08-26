module atu #(
    parameter int ADDR_WIDTH = 16
)(
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic                     config_signal,
    input  logic                     addr_mode,

    input  logic [ADDR_WIDTH-1:0]    addr_in,
    input  logic [ADDR_WIDTH-1:0]    config_addr,

    output logic [ADDR_WIDTH-1:0]    addr_out
);

    localparam logic MODE_RANGE  = 1'b0;
    localparam logic MODE_REGION = 1'b1;

    logic [ADDR_WIDTH-1:0] base_addr_reg;

    // Capture BASE_ADDR during configuration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            base_addr_reg <= '0;
        else if (config_signal)
            base_addr_reg <= config_addr;
    end

    // Address translation
    always_comb begin
        if (config_signal) begin
            addr_out = addr_in;
        end
        else begin
            case (addr_mode)
                MODE_RANGE:
                    addr_out = base_addr_reg + addr_in;

                MODE_REGION:
                    addr_out = base_addr_reg + addr_in;

                default:
                    addr_out = addr_in;
            endcase
        end
    end

endmodule