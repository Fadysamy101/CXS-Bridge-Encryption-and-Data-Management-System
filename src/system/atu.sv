
module atu #(
    parameter int ADDR_WIDTH  = 16,
    parameter int DEV_MAX     = 8,      // device entries this instance can match
    parameter int REGION_SIZE = 256,    // CDM words per device
    parameter int DATA_BASE   = 256     // 0x0100, first non-configuration word
)(
    input  logic                              config_signal,   // 1 = configuration phase
    input  logic                              addr_mode,       // Register File [16]
    input  logic [ADDR_WIDTH-1:0]             addr_in,

    // Device configuration entries, sourced from the CDM (0x0001 - 0x00FF).
    input  logic [7:0]                        dev_count,
    input  logic [(DEV_MAX*ADDR_WIDTH)-1:0]   dev_start_flat,
    input  logic [(DEV_MAX*ADDR_WIDTH)-1:0]   dev_end_flat,

    output logic [ADDR_WIDTH-1:0]             addr_out,
    output logic                              addr_error       // no valid mapping
);

    localparam logic MODE_RANGE  = 1'b0;
    localparam logic MODE_REGION = 1'b1;

    localparam int OFFSET_W = $clog2(REGION_SIZE);

    logic [ADDR_WIDTH-1:0] dev_start [DEV_MAX];
    logic [ADDR_WIDTH-1:0] dev_end   [DEV_MAX];

    

endmodule
