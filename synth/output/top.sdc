###################################################################

# Created by write_sdc on Sat Sep 12 01:02:18 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
create_clock [get_ports i_top_cxs_clk]  -name CLK_CXS  -period 27.027  -waveform {0 13.5135}
create_clock [get_ports i_top_sys_clk]  -name CLK_SYS  -period 40  -waveform {0 20}
set_clock_groups  -asynchronous -name CLK_CXS_1  -group [get_clocks CLK_CXS]   \
-group [get_clocks CLK_SYS]
