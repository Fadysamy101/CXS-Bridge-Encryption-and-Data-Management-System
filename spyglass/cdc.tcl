#===============================================================================
# SpyGlass CDC Analysis TCL Script
# Design: top (CXS Bridge Encryption and Data Management System)
#===============================================================================

new_project cdc_prj -force

set_option mthresh 16384
set_option top top
set_option enableSV yes
set_option language_mode verilog

# 1. Read RTL source files
read_file -type verilog ../top.sv

read_file -type verilog ../async_fifo/asynchronous_fifo.sv
read_file -type verilog ../async_fifo/fifo_mem.sv
read_file -type verilog ../async_fifo/rptr_handler.sv
read_file -type verilog ../async_fifo/synchronizer.sv
read_file -type verilog ../async_fifo/wptr_handler.sv

read_file -type verilog ../cxs_if/credit_manager.sv
read_file -type verilog ../cxs_if/cxs_if.sv
read_file -type verilog ../cxs_if/flit_fifo.sv
read_file -type verilog ../cxs_if/packet_encoder.sv
read_file -type verilog ../cxs_if/packet_formatter.sv
read_file -type verilog ../cxs_if/rx_interface.sv
read_file -type verilog ../cxs_if/tx_interface.sv

read_file -type verilog ../system/atu.sv
read_file -type verilog ../system/cdm.sv
read_file -type verilog ../system/control_unit.sv
read_file -type verilog ../system/encryption_unit.sv
read_file -type verilog ../system/parity_unit.sv
read_file -type verilog ../system/system_wrapper.sv

# 2. Read SGDC constraint file
read_file -type sgdc cdc.sgdc

# 3. CDC Goal: Structural CDC Verification
current_goal cdc/cdc_verify_struct -top top
run_goal

save_project
