vlog Verification/unit/packet_formatter/packet_formatter_tb.sv

vsim -voptargs="+acc" work.packet_formatter_tb

add wave -r sim:/packet_formatter_tb/*
add wave -r sim:/packet_formatter_tb/dut/*

run -all