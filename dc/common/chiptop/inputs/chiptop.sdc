set PERIOD  3.3
set INPUT_DELAY  1
set OUTPUT_DELAY  1
set CLOCK_LATENCY 0.2
set MIN_IO_DELAY 1.0
set MAX_TRANSITION 0.5

## CLOCK BASICS
create_clock -name "clock" -period $PERIOD [get_ports clock]
set_clock_latency $CLOCK_LATENCY [get_clocks clock]
set_clock_uncertainty 0.1 [get_clocks clock]
set_clock_transition 0.5 [get_clocks clock]

## GROUPING
group_path  -name CLOCK\
            -to clock\
            -weight 1

group_path  -name INPUTS\
            -through [all_inputs]\
            -weight 1

group_path  -name OUTPUTS\
            -to [all_outputs]\
            -weight 1

## IN/OUT
set INPUTPORTS [remove_from_collection [all_inputs] [get_ports clock]]
set OUTPUTPORTS [all_outputs]
  
set_input_delay -clock "clock" -max $INPUT_DELAY $INPUTPORTS 
set_output_delay -clock "clock" -max $OUTPUT_DELAY $OUTPUTPORTS
set_input_delay -clock "clock" -min $MIN_IO_DELAY $INPUTPORTS 
set_output_delay -clock "clock" -min $MIN_IO_DELAY $OUTPUTPORTS

#set REFLIB [get_object_name [index_collection [get_libs *wc] 0]]
set REFLIB saed14rvt_ss0p72v125c
set BUFFER "SAEDRVT14_BUF_16"
set BUF_IN_PIN "A"
set BUF_OUT_PIN "X"

set_load [expr 2 * [load_of $REFLIB/$BUFFER/$BUF_IN_PIN]] [all_outputs]

set_driving_cell -library $REFLIB \
                 -lib_cell $BUFFER \
                 -pin $BUF_OUT_PIN [all_inputs]

remove_driving_cell [get_ports clock]


## DRC
set_max_transition $MAX_TRANSITION [current_design]
set_max_capacitance 100 [current_design]
set_max_fanout 200 [current_design]


set_voltage 0.72 -obj {VDDL}
set_voltage 0.72 -obj {VDD}
set_voltage 0.000 -obj {VSS}
set_voltage 0.72 -obj {TOP.primary.power}
set_voltage 0.000 -obj {TOP.primary.ground}
set_voltage 0.000 -obj {GPRS.primary.ground}
set_voltage 0.72 -obj {GPRS.primary.power}

