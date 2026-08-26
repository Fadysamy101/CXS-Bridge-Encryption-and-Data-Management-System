
module system_wrapper #(
    parameter int ADDR_WIDTH = 16,
    parameter int DATA_WIDTH = 16,
    parameter int DEV_MAX    = 8
)(
    input  logic                        clk_sys,
    input  logic                        rst_n,

    // Asynchronous FIFO read port (CDC boundary, spec 10.2)
    input  logic                        fifo_empty,
    output logic                        fifo_en,
    input  logic [(2*DATA_WIDTH)-1:0]   fifo_data_in,

    // Error indication towards the CXS domain
    output logic                        error_valid,
    output logic [1:0]                  error
);

    localparam int ENC_DATA_WIDTH = DATA_WIDTH * 2;        // encryption expands x2
    localparam int CDM_WORD_WIDTH = ENC_DATA_WIDTH + 1;    // + parity bit

    // Control unit outputs
    logic                        direct_cdm_write;
    logic                        cu_w_en;
    logic [ADDR_WIDTH-1:0]       cu_addr_out;
    logic [DATA_WIDTH-1:0]       cu_data_out;
    logic [ENC_DATA_WIDTH-1:0]   cu_cfg_data_out;

    // Processing path and CDM
    logic [ADDR_WIDTH-1:0]       atu_addr_out;
    logic [ENC_DATA_WIDTH-1:0]   enc_data;
    logic [CDM_WORD_WIDTH-1:0]   par_data;
    logic [CDM_WORD_WIDTH-1:0]   cdm_wdata;
    logic [CDM_WORD_WIDTH-1:0]   cdm_rdata;

    // Configuration taps published by the CDM
    logic [7:0]                  dev_count;
    logic                        addr_mode;
    logic [3:0]                  enc_mode;
    logic                        parity_mode;

    control_unit #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_control_unit (
        .clk_sys          (clk_sys),
        .rst_n            (rst_n),

        .fifo_empty       (fifo_empty),
        .fifo_en          (fifo_en),
        .fifo_data_in     (fifo_data_in),

        .direct_cdm_write (direct_cdm_write),
        .w_en             (cu_w_en),
        .addr_out         (cu_addr_out),
        .data_out         (cu_data_out),
        .cfg_data_out     (cu_cfg_data_out),

        .dev_count        (dev_count),

        .error_valid      (error_valid),
        .error            (error)
    );

    // During configuration the ATU passes the address through and latches the
    // base address carried in the upper half of the configuration header.
    atu #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_atu (
        .clk(clk_sys),
        .rst_n(rst_n),
        .config_signal (direct_cdm_write),
        .addr_mode     (addr_mode),
        .addr_in       (cu_addr_out),
        .config_addr   (cu_cfg_data_out[ENC_DATA_WIDTH-1:DATA_WIDTH]),
        .addr_out      (atu_addr_out)
    );

    encryption_unit #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_encryption_unit (
        .ENC_MODE (enc_mode),
        .Data_in  (cu_data_out),
        .Data_out (enc_data)
    );

    parity_unit #(
        .ENC_DATA_WIDTH (ENC_DATA_WIDTH)
    ) u_parity_unit (
        .PARITY_MODE (parity_mode),
        .Data_in     (enc_data),
        .Data_out    (par_data)
    );

    // Write source selection (spec 10.2): configuration data bypasses the
    // encryption path, payload data is written encrypted with its parity bit.
    assign cdm_wdata = direct_cdm_write ? {1'b0, cu_cfg_data_out} : par_data;

    cdm #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .DEV_MAX    (DEV_MAX)
    ) u_cdm (
        .clk_sys     (clk_sys),
        .rst_n       (rst_n),

        .r_en        (1'b0),            // no read port user yet
        .r_addr      ({ADDR_WIDTH{1'b0}}),
        .rdata       (cdm_rdata),

        .w_en        (cu_w_en),
        .w_addr      (atu_addr_out),
        .wdata       (cdm_wdata),

        .dev_count   (dev_count),
        .addr_mode   (addr_mode),
        .enc_mode    (enc_mode),
        .parity_mode (parity_mode)
    );

endmodule
