
source ../../common/common.tcl

set link_library          "$Std_cell_lib $Ram_lib"
set target_library        "$Std_cell_lib $Ram_lib"
set dc_allow_rtl_pg	  true

source $analyze_script
elaborate ${DESIGN_NAME} -architecture verilog -library WORK

current_design ${DESIGN_NAME}

link

source $Constraints_file

set_fix_multiple_port_nets -outputs -feedthroughs 
source $Warning_file
#set dont_use
source ../scripts/set_dont_use.tcl
set_dont_use [get_lib_cells */*FDN*]

check_design
link

compile -exact_map -map_effort high -area_effort medium -power_effort none -incremental_mapping
#compile -exact_map -map_effort high -area_effort none -power_effort none

## reporting and output
report_timing > ../../reports/timing_${DESIGN_NAME}_timing_reports.log
report_qor > ../../reports/timing_${DESIGN_NAME}_qor_reports.log
report_area -hierarchy  > ../../reports/timing_${DESIGN_NAME}_area_reports.log
report_power -hierarchy > ../../reports/timing_${DESIGN_NAME}_power_reports.log

change_names -rules verilog
write_file -format verilog -hierarchy -pg -output ../../input/${DESIGN_NAME}.v

quit
