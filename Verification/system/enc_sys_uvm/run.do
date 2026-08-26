vlog -f Verification/system/enc_sys_uvm/src_files.list

vsim -voptargs=+acc work.enc_sys_top -classdebug -uvmcontrol=all

set TB  sim:/enc_sys_top
set VIF sim:/enc_sys_top/enc_sys_test_vif
set DUT sim:/enc_sys_top/dut

# Which directed test is running right now
add wave -group TEST -radix unsigned $VIF/test_num
add wave -group TEST -radix ascii    $VIF/test_name

# CXS link, both directions
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_rx_valid
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_rx_cntl
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_rx_data
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_rx_crdgnt
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_tx_crdgnt
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_tx_valid
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_tx_cntl
add wave -group CXS_LINK -radix hexadecimal $VIF/cxs_tx_data

# CXS interface wrapper
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_fifo_wr
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_fifo_rd
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_fifo_full
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_fifo_empty
add wave -group CXS_IF -radix unsigned    $DUT/u_cxs_if/u_credit_manager/credit_counter
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/async_fifo_w_en
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/async_fifo_w_data
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_valid
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_ready
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_cntrl
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/flit_tx
add wave -group CXS_IF -radix unsigned    $DUT/u_cxs_if/u_tx_interface/credit_counter
add wave -group CXS_IF -radix hexadecimal $DUT/u_cxs_if/u_tx_interface/flit_pending

# Clock domain crossing
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/w_en
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/full
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/data_in
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/r_en
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/empty
add wave -group ASYNC_FIFO -radix hexadecimal $DUT/u_async_fifo/data_out

add wave -group CDC -radix hexadecimal $DUT/err_toggle
add wave -group CDC -radix hexadecimal $DUT/err_toggle_sync
add wave -group CDC -radix hexadecimal $DUT/err_pulse_cxs

# System wrapper
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/state
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/fifo_en
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/fifo_data_in
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/direct_cdm_write
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/cu_w_en
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/cu_addr_out
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/cu_data_out
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/cu_cfg_data_out
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/atu_addr_out
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/enc_data
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/par_data
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/error_valid
add wave -group SYSTEM -radix hexadecimal $DUT/u_system_wrapper/error

# Central Data Memory
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/w_en
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/w_addr
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/wdata
add wave -group CDM -radix unsigned    $DUT/u_system_wrapper/u_cdm/dev_count
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/addr_mode
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/enc_mode
add wave -group CDM -radix hexadecimal $DUT/u_system_wrapper/u_cdm/parity_mode

run -all
