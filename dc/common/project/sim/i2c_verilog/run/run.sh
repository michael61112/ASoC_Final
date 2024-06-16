#!/bin/bash

i2c=../../..
bench=$i2c/bench
wave_dir=$i2c/sim/rtl_sim/i2c_verilog/waves

vcs								\
	+incdir+$bench/verilog					\
	+incdir+$i2c/rtl/verilog				\
								\
	$i2c/rtl/verilog/i2c_master_bit_ctrl.v			\
	$i2c/rtl/verilog/i2c_master_byte_ctrl.v			\
	$i2c/rtl/verilog/i2c_master_top.v			\
								\
	$bench/verilog/i2c_slave_model.v			\
	$bench/verilog/wb_master_model.v			\
	$bench/verilog/tst_bench_top.v				\
								\
	-R
	




