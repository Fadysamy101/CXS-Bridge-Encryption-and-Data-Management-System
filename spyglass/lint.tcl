open_project lint
set_option mthresh 16384
set_option top top
set_option enableSV yes
set_option language_mode verilog

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

current_methodology $SPYGLASS_HOME/GuideWare2.0/block/rtl_handoff

current_goal lint/lint_rtl -top top

run_goal

save_project
