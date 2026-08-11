vlog Verification/unit/async_fifo/async_fifo_tb.sv
vsim -voptargs="+acc" work.async_fifo_tb
add wave -r sim:/async_fifo_tb/*
add wave -r sim:/async_fifo_tb/dut/*
run -all