#===============================================================================
# Synopsys Design Compiler - Synthesis Script
# Design: top (CXS Bridge Encryption and Data Management System)
# Clocks: CXS = 37 MHz (27.027 ns), System = 25 MHz (40.0 ns)
#===============================================================================

#---------------------------------------------------------------
# 1. Setup: SAED 90nm Technology Library
#---------------------------------------------------------------
set LIB_PATH  "/home/ICer/saed90nm/synopsys/models"
set LIB_NAME  "saed90nm_typ.db"

set search_path     [concat $search_path $LIB_PATH]
set target_library  $LIB_NAME
set link_library    [list * $LIB_NAME]

#---------------------------------------------------------------
# 2. Read RTL source files
#---------------------------------------------------------------
set RTL_DIR "../src"

# Async FIFO
analyze -format sverilog [list \
  $RTL_DIR/async_fifo/synchronizer.sv     \
  $RTL_DIR/async_fifo/fifo_mem.sv         \
  $RTL_DIR/async_fifo/rptr_handler.sv     \
  $RTL_DIR/async_fifo/wptr_handler.sv     \
  $RTL_DIR/async_fifo/asynchronous_fifo.sv \
]

# CXS Interface
analyze -format sverilog [list \
  $RTL_DIR/cxs_if/credit_manager.sv    \
  $RTL_DIR/cxs_if/flit_fifo.sv         \
  $RTL_DIR/cxs_if/rx_interface.sv      \
  $RTL_DIR/cxs_if/tx_interface.sv      \
  $RTL_DIR/cxs_if/packet_formatter.sv  \
  $RTL_DIR/cxs_if/packet_encoder.sv    \
  $RTL_DIR/cxs_if/cxs_if.sv           \
]

# System
analyze -format sverilog [list \
  $RTL_DIR/system/parity_unit.sv        \
  $RTL_DIR/system/encryption_unit.sv    \
  $RTL_DIR/system/atu.sv               \
  $RTL_DIR/system/cdm.sv               \
  $RTL_DIR/system/control_unit.sv      \
  $RTL_DIR/system/system_wrapper.sv    \
]

# Top
analyze -format sverilog $RTL_DIR/top.sv

elaborate top

current_design top
link

#---------------------------------------------------------------
# 3. Clock Constraints
#---------------------------------------------------------------
# CXS clock: 37 MHz => period = 1000/37 = 27.027 ns
create_clock -name CLK_CXS -period 27.027 [get_ports i_top_cxs_clk]

# System clock: 25 MHz => period = 1000/25 = 40.0 ns
create_clock -name CLK_SYS -period 40.0   [get_ports i_top_sys_clk]

# Tell DC the two clocks are asynchronous (no timing between domains)
set_clock_groups -asynchronous \
  -group [get_clocks CLK_CXS] \
  -group [get_clocks CLK_SYS]

#---------------------------------------------------------------
# 4. Compile
#---------------------------------------------------------------
compile

#---------------------------------------------------------------
# 5. Reports
#---------------------------------------------------------------
report_timing  > reports/timing.rpt
report_area    > reports/area.rpt
report_power   > reports/power.rpt

#---------------------------------------------------------------
# 6. Write outputs
#---------------------------------------------------------------
write -format verilog -hierarchy -output output/top_netlist.v
write_sdc output/top.sdc

puts "===== Synthesis complete ====="
