
module system_wrapper #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 16,
  parameter int DEV_MAX    = 8
)(
  input  logic                      i_system_wrapper_clk,
  input  logic                      i_system_wrapper_rst_n,

  // Asynchronous FIFO read port (CDC boundary, spec 10.2)
  input  logic                      i_system_wrapper_fifo_empty,
  output logic                      o_system_wrapper_fifo_en,
  input  logic [(2*DATA_WIDTH)-1:0] i_system_wrapper_fifo_data_in,

  // Error indication towards the CXS domain
  output logic                      o_system_wrapper_error_valid,
  output logic [1:0]                o_system_wrapper_error
);

  localparam int ENC_DATA_WIDTH = DATA_WIDTH * 2;        // encryption expands x2
  localparam int CDM_WORD_WIDTH = ENC_DATA_WIDTH + 1;    // + parity bit

  // Control unit outputs
  logic                      direct_cdm_write;
  logic                      cu_w_en;
  logic [ADDR_WIDTH-1:0]     cu_addr_out;
  logic [DATA_WIDTH-1:0]     cu_data_out;
  logic [ENC_DATA_WIDTH-1:0] cu_cfg_data_out;

  // Processing path and CDM
  logic [ADDR_WIDTH-1:0]     atu_addr_out;
  logic [ENC_DATA_WIDTH-1:0] enc_data;
  logic [CDM_WORD_WIDTH-1:0] par_data;
  logic [CDM_WORD_WIDTH-1:0] cdm_wdata;
  logic [CDM_WORD_WIDTH-1:0] cdm_rdata;

  // Configuration taps published by the CDM
  logic [7:0]                dev_count;
  logic                      addr_mode;
  logic [3:0]                enc_mode;
  logic                      parity_mode;

  control_unit
  #(
    // Parameter Declaration
     .ADDR_WIDTH (ADDR_WIDTH)  // CDM / ATU Address Width
    ,.DATA_WIDTH (DATA_WIDTH)  // Payload Data Width
  )
  u_control_unit
  (
    // Ports Declaration
     .i_control_unit_clk              (i_system_wrapper_clk)          // I: System Clock
    ,.i_control_unit_rst_n            (i_system_wrapper_rst_n)        // I: System Async Reset
    ,.i_control_unit_fifo_empty       (i_system_wrapper_fifo_empty)   // I: Async FIFO Empty
    ,.o_control_unit_fifo_en          (o_system_wrapper_fifo_en)      // O: Async FIFO Read Enable
    ,.i_control_unit_fifo_data_in     (i_system_wrapper_fifo_data_in) // I: Async FIFO Read Data
    ,.o_control_unit_direct_cdm_write (direct_cdm_write)              // O: Encryption-Bypass CDM Write
    ,.o_control_unit_w_en             (cu_w_en)                       // O: CDM Write Enable
    ,.o_control_unit_addr_out         (cu_addr_out)                   // O: CDM Write Address
    ,.o_control_unit_data_out         (cu_data_out)                   // O: Payload Data
    ,.o_control_unit_cfg_data_out     (cu_cfg_data_out)               // O: Configuration Word
    ,.i_control_unit_dev_count        (dev_count)                     // I: Configured Device Count
    ,.o_control_unit_error_valid      (o_system_wrapper_error_valid)  // O: Error Pulse
    ,.o_control_unit_error            (o_system_wrapper_error)        // O: Error Code
  );

  // During configuration the ATU passes the address through and latches the
  // base address carried in the upper half of the configuration header.
  atu
  #(
    // Parameter Declaration
     .ADDR_WIDTH (ADDR_WIDTH)  // Address Width
  )
  u_atu
  (
    // Ports Declaration
     .i_atu_clk           (i_system_wrapper_clk)                       // I: System Clock
    ,.i_atu_rst_n         (i_system_wrapper_rst_n)                     // I: System Async Reset
    ,.i_atu_config_signal (direct_cdm_write)                           // I: Configuration Phase Active
    ,.i_atu_addr_mode     (addr_mode)                                  // I: Address Translation Mode
    ,.i_atu_addr_in       (cu_addr_out)                                // I: Untranslated Address
    ,.i_atu_config_addr   (cu_cfg_data_out[ENC_DATA_WIDTH-1:DATA_WIDTH]) // I: Base Address
    ,.o_atu_addr_out      (atu_addr_out)                               // O: Translated Address
  );

  encryption_unit
  #(
    // Parameter Declaration
     .DATA_WIDTH (DATA_WIDTH)  // Payload Data Width
  )
  u_encryption_unit
  (
    // Ports Declaration
     .i_encryption_unit_enc_mode (enc_mode)     // I: Encryption Mode
    ,.i_encryption_unit_data_in  (cu_data_out)  // I: Plain Payload Data
    ,.o_encryption_unit_data_out (enc_data)     // O: Expanded Payload Data
  );

  parity_unit
  #(
    // Parameter Declaration
     .ENC_DATA_WIDTH (ENC_DATA_WIDTH)  // Encrypted Data Width
  )
  u_parity_unit
  (
    // Ports Declaration
     .i_parity_unit_parity_mode (parity_mode)  // I: Parity Mode
    ,.i_parity_unit_data_in     (enc_data)     // I: Encrypted Data
    ,.o_parity_unit_data_out    (par_data)     // O: Data With Parity Bit
  );

  // Write source selection (spec 10.2): configuration data bypasses the
  // encryption path, payload data is written encrypted with its parity bit.
  assign cdm_wdata = direct_cdm_write ? {1'b0, cu_cfg_data_out} : par_data;

  cdm
  #(
    // Parameter Declaration
     .ADDR_WIDTH (ADDR_WIDTH)  // CDM Address Width
    ,.DATA_WIDTH (DATA_WIDTH)  // Payload Data Width
    ,.DEV_MAX    (DEV_MAX)     // Max Configurable Devices
  )
  u_cdm
  (
    // Ports Declaration
     .i_cdm_clk         (i_system_wrapper_clk)   // I: System Clock
    ,.i_cdm_rst_n       (i_system_wrapper_rst_n) // I: System Async Reset
    ,.i_cdm_r_en        (1'b0)                   // I: Read Enable - no read port user yet
    ,.i_cdm_r_addr      ({ADDR_WIDTH{1'b0}})     // I: Read Address
    ,.o_cdm_rdata       (cdm_rdata)              // O: Read Data
    ,.i_cdm_w_en        (cu_w_en)                // I: Write Enable
    ,.i_cdm_w_addr      (atu_addr_out)           // I: Write Address
    ,.i_cdm_wdata       (cdm_wdata)              // I: Write Data
    ,.o_cdm_dev_count   (dev_count)              // O: Configured Device Count
    ,.o_cdm_addr_mode   (addr_mode)              // O: Address Translation Mode
    ,.o_cdm_enc_mode    (enc_mode)               // O: Encryption Mode
    ,.o_cdm_parity_mode (parity_mode)            // O: Parity Mode
  );

endmodule
