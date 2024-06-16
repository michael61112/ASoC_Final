#ICC2_EXEC = /global/apps/icc2_2019.12/bin/icc2_shell
#ICC2_EXEC = /global/apps/icc2_2022.12/bin/icc2_shell
#DC_EXEC = /global/apps/syn_2022.12/bin/dc_shell
DC_EXEC = dc_shell
LOGS_DIR = ./LOG

console:
	$(DC_EXEC)
setup:	
	cp ~/final_project/rtl/user/user_subsys/user_prj/user_prj1/rtl/* ../../common/project/rtl/verilog/
	test -d $(LOGS_DIR) || mkdir $(LOGS_DIR)	
	date > setup
compile_for_timing: setup 
	$(DC_EXEC) -f ./../scripts/compile_for_timing.tcl | tee -i $(LOGS_DIR)/compile_for_timing.log
	date > 	compile_for_timing
all: setup compile_for_timing
	date > 	all
clean:
	ls | grep -v "Makefile" | xargs rm -r
	rm -rf  ../../results/*
	rm -rf  ../../reports/*
	rm -rf  ../../input/fsic_top_pt.v
	rm -rf  ../../input/fsic_top.v
