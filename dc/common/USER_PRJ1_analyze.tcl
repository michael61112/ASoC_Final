
analyze -library WORK -format sverilog " \

$VERILOG_DIR/user_prj1.v \
$VERILOG_DIR/global_buffer.v \
$VERILOG_DIR/systolic_array.v \
$VERILOG_DIR/TPU_fsm.v \
$VERILOG_DIR/block.v \
$VERILOG_DIR/TPU.v "
