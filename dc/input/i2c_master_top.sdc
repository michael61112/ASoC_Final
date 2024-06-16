################################################################################
#
# Design name:  i2c_master_top_7_finished
#
# Created by icc2 write_sdc on Thu Jan  4 19:48:34 2024
#
################################################################################

set sdc_version 2.1
set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA

################################################################################
#
# Units
# time_unit               : 1e-09
# resistance_unit         : 1000000
# capacitive_load_unit    : 1e-15
# voltage_unit            : 1
# current_unit            : 1e-06
# power_unit              : 1e-12
################################################################################


# Mode: func
# Corner: fast
# Scenario: func_fast

# /remote/testcases/TC102/042022/4196128/LIB_AJ/ICC2/FlowTraining_BE/TEST_AJ/University_LAB/lab_formal_release/common/i2c_master_top.sdc, \
#   line 8
create_clock -name wb_clk_i -period 2 -waveform {0 1} [get_ports {wb_clk_i}]
# Warning: Libcell power domain derates are skipped!

set_clock_uncertainty -setup 0.3 [get_clocks {wb_clk_i}]
set_clock_transition 0.2 [get_clocks {wb_clk_i}]
