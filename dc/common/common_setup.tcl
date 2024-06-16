
##########  VARIABLES TO MODIFY                     #############################################################################Main_PATH
#set ROOT_DIR        	"/SCRATCH/IC_Synthesis_Optimisation/lab_files/lab"
##############################################################
set ROOT_DIR 		"[pwd]/../../"
set DESIGN_PATH         "${ROOT_DIR}/common/chiptop/"

## Point to the new 14nm SAED libs
## if unavailable download from https://www.synopsys.com/COMMUNITY/UNIVERSITYPROGRAM/Pages/14nm-generic-library.aspx
#set DESIGN_REF_PATH		  "/SCRATCH/development/SAED14_EDK"
set DESIGN_REF_PATH		  "/RAID2/COURSE/asoc/asoc020/lab-snps-flow/SAED14_EDK_LAB"
#"${ROOT_DIR}/../SAED14_EDK_LAB"

set DESIGN_REF_TECH_PATH          "${DESIGN_REF_PATH}/tech"

# Library Setup Variables

set ADDITIONAL_SEARCH_PATH      " \
        ${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm \
        ${DESIGN_REF_PATH}/lib/stdcell_hvt/db_nldm \
        ${DESIGN_REF_PATH}/lib/stdcell_lvt/db_nldm \
	${DESIGN_REF_PATH}/lib/sram/logic_synth/single \
	${DESIGN_REF_PATH}/lib/io_std/db_nldm "

#multi_voltage
set LINK_LIBRARY_FILES    "* \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ss0p72v125c.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ss0p6v125c.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_dlvl_ss0p72v125c_i0p72v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_dlvl_ss0p6v125c_i0p6v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ulvl_ss0p72v125c_i0p72v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ulvl_ss0p6v125c_i0p6v.db \
${DESIGN_REF_PATH}/lib/sram/logic_synth/single/saed14sram_ss0p72v125c.db \
${DESIGN_REF_PATH}/lib/sram/logic_synth/single/saed14sram_tt0p8v25c.db"

#multi_voltage
set TARGET_LIBRARY_FILES   "\
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ss0p72v125c.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ss0p6v125c.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_dlvl_ss0p72v125c_i0p72v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_dlvl_ss0p6v125c_i0p6v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ulvl_ss0p72v125c_i0p72v.db \
${DESIGN_REF_PATH}/lib/stdcell_rvt/db_nldm/saed14rvt_ulvl_ss0p6v125c_i0p6v.db \
${DESIGN_REF_PATH}/lib/sram/logic_synth/single/saed14sram_ss0p72v125c.db \
${DESIGN_REF_PATH}/lib/sram/logic_synth/single/saed14sram_tt0p8v25c.db"


