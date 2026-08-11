
module atu #(
    parameter int ADDR_WIDTH  = 16
)(
    input  logic                              config_signal,   // 1 = configuration phase
    input  logic                              addr_mode,       // Register File [16]
    input  logic [ADDR_WIDTH-1:0]             addr_in,
    input  logic [ADDR_WIDTH-1:0]             config_addr,
    output logic [ADDR_WIDTH-1:0]             addr_out
);


    localparam logic MODE_RANGE  = 1'b0;
    localparam logic MODE_REGION = 1'b1;

    logic [ADDR_WIDTH-1:0]   base_addr_reg;

    always_comb begin
        if (config_signal) begin
            addr_out = addr_in;
            if(addr_in ==0)
                base_addr_reg = config_addr;
        end
        else begin
            case (addr_mode)
                MODE_RANGE:  addr_out = base_addr_reg+addr_in;
               // MODE_REGION: addr_out = base_addr + addr_in;
                default:     addr_out = '0;
            endcase
        end
    end

    

endmodule
