
##########  VARIABLES TO MODIFY ############################################################################# Main_PATH
set starrc_bin_path        	"/global/apps/starrc_2022.12-SP5/bin"
set primetime_bin_path    	"/global/apps/pt_2022.12-SP5/bin"
set REDHAWK_PGA_ICV_DIR		"/global/apps/icv_2022.12-SP5/"

###########################################################
set ROOT_DIR        "[pwd]/../.."
#set DESIGN_REF_PATH "/path/to/SAED14_EDK"
set DESIGN_REF_PATH "/RAID2/COURSE/asoc/asoc020/lab-snps-flow/SAED14_EDK_LAB"
#"${ROOT_DIR}/../SAED14_EDK_LAB"

set VERILOG_DIR     "${ROOT_DIR}/common/project/rtl/verilog"
###########################################################

set DESIGN_NAME     "USER_PRJ1"

set Constraints_file      "${ROOT_DIR}/common/${DESIGN_NAME}.sdc"
set analyze_script        "${ROOT_DIR}/common/${DESIGN_NAME}_analyze.tcl"
set Warning_file          "${ROOT_DIR}/common/warnings_to_ignore.tcl"
############### outputs 
set Svf_file              "${ROOT_DIR}/input/${DESIGN_NAME}.svf"
set ARC_TOP               "${ROOT_DIR}/results/${DESIGN_NAME}"
set Core_compile          "${ROOT_DIR}/input/${DESIGN_NAME}.v"  
set Top_design_pt         "${ROOT_DIR}/input/${DESIGN_NAME}_pt.v"
###########################################################

set pns_vlayer M6
set pns_hlayer M7
set route_min_layer M1
set route_max_layer M9

#################################################################################REF_PATH
set DESIGN_REF_LIB_PATH  "${DESIGN_REF_PATH}/lib"
set DESIGN_REF_TECH_PATH "${DESIGN_REF_PATH}/tech"
#################################################################################LIB_PATH
set DESIGN_REF_MW_PATH   "${DESIGN_REF_TECH_PATH}/milkyway"
set DESIGN_REF_RC_PATH   "${DESIGN_REF_TECH_PATH}/star_rc"
#################################################################################TECH_PATH
set DESIGN_REF_NLDM_PATH "${DESIGN_REF_LIB_PATH}/stdcell_rvt/db_nldm"
set DESIGN_REF_RAM_PATH  "${DESIGN_REF_LIB_PATH}/sram/logic_synth/single"
#######################################################################################Liberty
#set Std_cell_lib         "/remote/exchange/synopsys/SAED14_EDK/lib/stdcell_rvt/db_nldm/saed14rvt_tt0p8v25c.db"
set Std_cell_lib         "${DESIGN_REF_LIB_PATH}/stdcell_rvt/db_nldm/saed14rvt_tt0p8v25c.db"
set Ram_lib              "${DESIGN_REF_LIB_PATH}/sram/logic_synth/single/saed14sram_tt0p8v25c.db"
#######################################################################################
set REFERENCE_LIB "${DESIGN_REF_LIB_PATH}/stdcell_rvt/ndm/saed14rvt_frame_only.ndm"
set Std_cell_gds	"${DESIGN_REF_LIB_PATH}/stdcell_rvt/gds/saed14rvt.gds"
set Ram_gds              "${DESIGN_REF_LIB_PATH}/sram/gds/single.gds"
set Std_cell_lef	"${DESIGN_REF_LIB_PATH}/stdcell_rvt/lef/saed14nm_rvt_1p9m.lef"
set Ram_lef              "${DESIGN_REF_LIB_PATH}/sram/lef/saed14_sram_1rw.lef"

set search_path "$DESIGN_REF_RC_PATH $DESIGN_REF_NLDM_PATH $DESIGN_REF_RAM_PATH"

set Tech_file             "${DESIGN_REF_MW_PATH}/saed14nm_1p9m_mw.tf"
#set Tech_file             "${DESIGN_REF_MW_PATH}/tfs/saed14nm_1p9m_mw_v2.tf"
#set Tech_file 		  "${ROOT_DIR}/results/1205_v2_tech_AJ.tf"

set Map_file              "${DESIGN_REF_RC_PATH}/saed14nm_tf_itf_tluplus.map"
set Antenna_file          "${DESIGN_REF_MW_PATH}/saed32nm_ant_1p9m.tcl"
set Alf_file              "${DESIGN_REF_MW_PATH}/saed32nm_em_1p9m.alf"
set Gds_map_file          "${DESIGN_REF_MW_PATH}/saed14nm_1p9m_gdsout_mw.map"
set Tlup_max_file         "${DESIGN_REF_RC_PATH}/max/saed14nm_1p9m_Cmax.tluplus"
set Tlup_min_file         "${DESIGN_REF_RC_PATH}/min/saed14nm_1p9m_Cmin.tluplus"
set Nxtgrd_max_file       "${DESIGN_REF_RC_PATH}/max/saed14nm_1p9m_Cmax.nxtgrd"
set Nxtgrd_min_file       "${DESIGN_REF_RC_PATH}/min/saed14nm_1p9m_Cmin.nxtgrd"

set icv_drc_runset	  "${DESIGN_REF_TECH_PATH}/icv_drc/saed14nm_1p9m_drc_rules.rs"
#set icv_drc_runset "${DESIGN_REF_MW_PATH}/saed14nm_1p9m_mw.tf"
set icv_mfill_runset      "${DESIGN_REF_TECH_PATH}/icv_drc/saed14nm_1p9m_mfill_rules.rs"
###########################################################
set STARRC_CORNER_GRD_FILE "${ROOT_DIR}/lab_starRC/script/StarRC.smc"
set STARRC_SELECTED_CORNERS "fast slow"
set METAL_FILL_SELECT_LAYER "M2 M6"

##########################################################
#PT setting for single mode (Note : not for multi mode)
##########################################################
set PT_SELECTED_SCENARIO "fast slow"
set PT_REPORTS_DIR "reports"
set PT_RESULTS_DIR "results"
set PT_SESSION_DIR "pt_session"
set PT_link_path "* $Std_cell_lib $Ram_lib"
set PT_NETLIST_FILES "${ROOT_DIR}/results/${DESIGN_NAME}.out.wo_filler.v"
set PT_PARASITIC_FILES	 "${ROOT_DIR}/results/${DESIGN_NAME}.star.wo_filler.spef.fast" 
set PT_PARASITIC_PATHS	 "fsic_top"
#use gloden sdc (FROM FE)
set PT_CONSTRAINT_FILES "${ROOT_DIR}/input/${DESIGN_NAME}.sdc" 

##########################################################
#FM setting 
##########################################################
#set FM_IMPLEMENTED_DESIGN "${ROOT_DIR}/results/${DESIGN_NAME}.fm.v.gz"
set FM_IMPLEMENTED_DESIGN "${ROOT_DIR}/results/${DESIGN_NAME}.pt.v.gz"

