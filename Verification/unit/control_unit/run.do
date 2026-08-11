vlog src/system/control_unit.sv
vlog Verification/unit/control_unit/control_unit_tb.sv

vsim -voptargs="+acc" work.control_unit_tb

add wave -r sim:/control_unit_tb/*
add wave -r sim:/control_unit_tb/dut/*

run -all
