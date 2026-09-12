vlog -f Verification/system/enc_sys_uvm/src_files.list

vsim -voptargs=+acc work.enc_sys_top -classdebug -uvmcontrol=all

set TB  sim:/enc_sys_top
set VIF sim:/enc_sys_top/enc_sys_test_vif
set DUT sim:/enc_sys_top/dut

# ==============================================================================
# 0. Active Test Tracker
# ==============================================================================
add wave -divider "CURRENT TESTCASE"
add wave -radix unsigned -color Yellow      $VIF/test_num
add wave -radix ascii    -color Yellow      $VIF/test_name
add wave -radix hexadecimal                 $DUT/i_top_cxs_clk
add wave -radix hexadecimal                 $DUT/i_top_cxs_rst_n
add wave -radix hexadecimal                 $DUT/i_top_sys_clk
add wave -radix hexadecimal                 $DUT/i_top_sys_rst_n

# ==============================================================================
# 1. SCENARIO 1: Config, Link-Up & Transfer TLPs (CFG_LINK_XFER)
# ==============================================================================
add wave -divider "TC1: CFG, LINK-UP & TRANSFER"
add wave -group "TC1: CFG_LINK_XFER" -color "Cyan"        -radix hexadecimal $DUT/i_top_cxs_rx_valid
add wave -group "TC1: CFG_LINK_XFER" -color "Cyan"        -radix hexadecimal $DUT/i_top_cxs_rx_data
add wave -group "TC1: CFG_LINK_XFER" -color "Cyan"        -radix hexadecimal $DUT/i_top_cxs_rx_cntl
add wave -group "TC1: CFG_LINK_XFER" -color "Cyan"        -radix hexadecimal $DUT/o_top_cxs_rx_crdgnt
add wave -group "TC1: CFG_LINK_XFER" -color "Orange"      -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_en
add wave -group "TC1: CFG_LINK_XFER" -color "Orange"      -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_data
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix ascii       $DUT/u_system_wrapper/u_control_unit/state
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_direct_cdm_write
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_w_en
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_addr_out
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_data_out
add wave -group "TC1: CFG_LINK_XFER" -color "Green"       -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_cfg_data_out
add wave -group "TC1: CFG_LINK_XFER" -color "Magenta"     -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_w_en
add wave -group "TC1: CFG_LINK_XFER" -color "Magenta"     -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_w_addr
add wave -group "TC1: CFG_LINK_XFER" -color "Magenta"     -radix hexadecimal $DUT/u_system_wrapper/u_cdm/i_cdm_wdata
add wave -group "TC1: CFG_LINK_XFER" -color "Magenta"     -radix unsigned    $DUT/u_system_wrapper/u_cdm/o_cdm_dev_count
add wave -group "TC1: CFG_LINK_XFER" -color "Magenta"     -radix hexadecimal $DUT/u_system_wrapper/u_cdm/o_cdm_enc_mode

# ==============================================================================
# 2. SCENARIO 2: Two Transfer TLPs in a Single FLIT (TWO_TLP_ONE_FLIT)
# ==============================================================================
add wave -divider "TC2: TWO TLPs IN SINGLE FLIT"
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Cyan"     -radix hexadecimal $DUT/i_top_cxs_rx_valid
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Cyan"     -radix hexadecimal $DUT/i_top_cxs_rx_data
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Cyan"     -radix binary      $DUT/i_top_cxs_rx_cntl
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix binary      $DUT/u_cxs_if/u_packet_formatter/start
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix binary      $DUT/u_cxs_if/u_packet_formatter/end_
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix unsigned    $DUT/u_cxs_if/u_packet_formatter/word_count
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix binary      $DUT/u_cxs_if/u_packet_formatter/word_valid
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_en
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Orange"   -radix hexadecimal $DUT/u_cxs_if/u_packet_formatter/o_packet_formatter_async_fifo_w_data
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Green"    -radix ascii       $DUT/u_system_wrapper/u_control_unit/state
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Green"    -radix unsigned    $DUT/u_system_wrapper/u_control_unit/tlp_word_counter
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Green"    -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_fifo_en
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Green"    -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_w_en
add wave -group "TC2: TWO_TLP_ONE_FLIT" -color "Green"    -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_data_out

# ==============================================================================
# 3. SCENARIO 3: Error Detection & Response FLIT Transmission (ERR_TX_FLIT)
# ==============================================================================
add wave -divider "TC3: ERROR & RESPONSE FLIT"
add wave -group "TC3: ERR_TX_FLIT" -color "Red"         -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/i_control_unit_fifo_data_in
add wave -group "TC3: ERR_TX_FLIT" -color "Red"         -radix ascii       $DUT/u_system_wrapper/u_control_unit/state
add wave -group "TC3: ERR_TX_FLIT" -color "Red"         -radix hexadecimal $DUT/u_system_wrapper/u_control_unit/o_control_unit_error_valid
add wave -group "TC3: ERR_TX_FLIT" -color "Red"         -radix binary      $DUT/u_system_wrapper/u_control_unit/o_control_unit_error
add wave -group "TC3: ERR_TX_FLIT" -color "Yellow"      -radix binary      $DUT/err_toggle
add wave -group "TC3: ERR_TX_FLIT" -color "Yellow"      -radix binary      $DUT/err_toggle_sync
add wave -group "TC3: ERR_TX_FLIT" -color "Yellow"      -radix binary      $DUT/err_pulse_cxs
add wave -group "TC3: ERR_TX_FLIT" -color "Orange"      -radix binary      $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_error_valid_sync
add wave -group "TC3: ERR_TX_FLIT" -color "Orange"      -radix binary      $DUT/u_cxs_if/u_packet_encoder/i_packet_encoder_error_in
add wave -group "TC3: ERR_TX_FLIT" -color "Orange"      -radix binary      $DUT/u_cxs_if/u_packet_encoder/o_packet_encoder_flit_valid
add wave -group "TC3: ERR_TX_FLIT" -color "Orange"      -radix hexadecimal $DUT/u_cxs_if/u_packet_encoder/o_packet_encoder_flit_tx
add wave -group "TC3: ERR_TX_FLIT" -color "Magenta"     -radix binary      $DUT/o_top_cxs_tx_valid
add wave -group "TC3: ERR_TX_FLIT" -color "Magenta"     -radix hexadecimal $DUT/o_top_cxs_tx_data
add wave -group "TC3: ERR_TX_FLIT" -color "Magenta"     -radix hexadecimal $DUT/o_top_cxs_tx_cntl

# ==============================================================================
# 4. SCENARIO 4: TX Credit Flow Control Stall & Resume (TX_CREDIT_STALL)
# ==============================================================================
add wave -divider "TC4: TX CREDIT STALL & RESUME"
add wave -group "TC4: TX_CREDIT_STALL" -color "Yellow"  -radix unsigned    $DUT/u_cxs_if/u_tx_interface/credit_counter
add wave -group "TC4: TX_CREDIT_STALL" -color "Yellow"  -radix binary      $DUT/u_cxs_if/u_tx_interface/has_credit
add wave -group "TC4: TX_CREDIT_STALL" -color "Orange"  -radix binary      $DUT/u_cxs_if/u_tx_interface/i_tx_interface_flit_valid
add wave -group "TC4: TX_CREDIT_STALL" -color "Orange"  -radix binary      $DUT/u_cxs_if/u_tx_interface/o_tx_interface_flit_ready
add wave -group "TC4: TX_CREDIT_STALL" -color "Orange"  -radix binary      $DUT/u_cxs_if/u_tx_interface/flit_pending
add wave -group "TC4: TX_CREDIT_STALL" -color "Cyan"    -radix binary      $DUT/i_top_cxs_tx_crdgnt
add wave -group "TC4: TX_CREDIT_STALL" -color "Magenta" -radix binary      $DUT/o_top_cxs_tx_valid
add wave -group "TC4: TX_CREDIT_STALL" -color "Magenta" -radix hexadecimal $DUT/o_top_cxs_tx_data
add wave -group "TC4: TX_CREDIT_STALL" -color "Magenta" -radix hexadecimal $DUT/o_top_cxs_tx_cntl

# Run the simulation
run -all
