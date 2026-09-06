vlog -f Verification/system/enc_sys_uvm/src_files.list

vsim -voptargs=+acc work.enc_sys_top -classdebug -uvmcontrol=all

set TB  sim:/enc_sys_top
set VIF sim:/enc_sys_top/enc_sys_test_vif
set DUT sim:/enc_sys_top/dut

# Waves are grouped per design block: each group holds that block's
# own input and output ports, in declaration order.

# Which directed test is running right now
add wave -group TEST -radix unsigned $VIF/test_num
add wave -group TEST -radix ascii    $VIF/test_name

# top - 8 inputs, 4 outputs
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_clk
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_rst_n
add wave -group TOP -radix hexadecimal $DUT/i_top_sys_clk
add wave -group TOP -radix hexadecimal $DUT/i_top_sys_rst_n
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_rx_valid
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_rx_data
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_rx_cntl
add wave -group TOP -radix hexadecimal $DUT/o_top_cxs_rx_crdgnt
add wave -group TOP -radix hexadecimal $DUT/i_top_cxs_tx_crdgnt
add wave -group TOP -radix hexadecimal $DUT/o_top_cxs_tx_valid
add wave -group TOP -radix hexadecimal $DUT/o_top_cxs_tx_data
add wave -group TOP -radix hexadecimal $DUT/o_top_cxs_tx_cntl

# rx_interface - 4 inputs, 2 outputs
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/i_rx_interface_cxs_rx_valid
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/i_rx_interface_cxs_rx_data
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/i_rx_interface_cxs_rx_cntl
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/i_rx_interface_flit_fifo_full
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/o_rx_interface_flit_fifo_wr
add wave -group RX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_rx_interface/o_rx_interface_flit_fifo_wdata

# flit_fifo - 5 inputs, 3 outputs
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/i_flit_fifo_rst_n
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/i_flit_fifo_clk
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/i_flit_fifo_wr
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/i_flit_fifo_wdata
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/i_flit_fifo_rd
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/o_flit_fifo_rdata
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/o_flit_fifo_full
add wave -group FLIT_FIFO -radix hexadecimal $DUT/u_cxs_if/u_flit_fifo/o_flit_fifo_empty

# credit_manager - 6 inputs, 1 outputs
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_rst_n
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_clk
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_flit_fifo_wr
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_flit_fifo_rd
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_flit_fifo_empty
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/i_credit_manager_flit_fifo_full
add wave -group CREDIT_MANAGER -radix hexadecimal $DUT/u_cxs_if/u_credit_manager/o_credit_manager_cxs_rx_crdgnt

# packet_formatter - 5 inputs, 3 outputs
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/i_packet_formatter_rst_n
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/i_packet_formatter_clk
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/i_packet_formatter_flit_fifo_empty
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/i_packet_formatter_flit_fifo_rdata
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/i_packet_formatter_async_fifo_full
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_flit_fifo_rd
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_en
add wave -group PACKET_FORMATTER -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_data

# asynchronous_fifo - 7 inputs, 3 outputs
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_w_clk
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_w_rst_n
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_r_clk
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_r_rst_n
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_w_en
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_r_en
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/i_asynchronous_fifo_data_in
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/o_asynchronous_fifo_data_out
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/o_asynchronous_fifo_full
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/o_asynchronous_fifo_empty

# control_unit - 5 inputs, 8 outputs
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/i_control_unit_clk
add wave -group CONTROL_UNIT  hexadecimal $DUT/u_system_wrapper/u_control_unit/state
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/i_control_unit_rst_n
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/i_control_unit_fifo_empty
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_fifo_en
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/i_control_unit_fifo_data_in
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_direct_cdm_write
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_w_en
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_addr_out
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_data_out
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_cfg_data_out
add wave -group CONTROL_UNIT -radix unsigned    $DUT/u_system_wrapper/u_control_unit/i_control_unit_dev_count
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_error_valid
add wave -group CONTROL_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_error

# atu - 6 inputs, 1 outputs
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_clk
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_rst_n
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_config_signal
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_addr_mode
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_addr_in
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/i_atu_config_addr
add wave -group ATU -radix hexadecimal $DUT/u_system_wrapper/u_atu/o_atu_addr_out

# encryption_unit - 2 inputs, 1 outputs
add wave -group ENCRYPTION_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_encryption_unit/i_encryption_unit_enc_mode
add wave -group ENCRYPTION_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_encryption_unit/i_encryption_unit_data_in
add wave -group ENCRYPTION_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_encryption_unit/o_encryption_unit_data_out

# parity_unit - 2 inputs, 1 outputs
add wave -group PARITY_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_parity_unit/i_parity_unit_parity_mode
add wave -group PARITY_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_parity_unit/i_parity_unit_data_in
add wave -group PARITY_UNIT -radix hexadecimal $DUT/u_system_wrapper/u_parity_unit/o_parity_unit_data_out

# cdm - 7 inputs, 5 outputs
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_clk
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_rst_n
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_r_en
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_r_addr
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/o_cdm_rdata
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_w_en
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_w_addr
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_wdata
add wave -group CDM -radix unsigned    $DUT/u_system_wrapper/u_cdm/o_cdm_dev_count
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/o_cdm_addr_mode
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/o_cdm_enc_mode
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/o_cdm_parity_mode

# packet_encoder - 4 inputs, 3 outputs
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_clk
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_rst_n
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_error_valid_sync
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_error_in
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/o_packet_encoder_flit_tx
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/o_packet_encoder_flit_cntrl
add wave -group PACKET_ENCODER -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/o_packet_encoder_flit_valid

# tx_interface - 5 inputs, 4 outputs
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/i_tx_interface_clk
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/i_tx_interface_rst_n
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/i_tx_interface_cxs_tx_crdgnt
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/i_tx_interface_flit_valid
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/i_tx_interface_flit_data_in
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/o_tx_interface_flit_ready
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/o_tx_interface_cxs_tx_valid
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/o_tx_interface_cxs_tx_data
add wave -group TX_INTERFACE -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/o_tx_interface_cxs_tx_cntl

run -all
