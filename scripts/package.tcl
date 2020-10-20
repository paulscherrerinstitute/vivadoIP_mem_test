##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

###############################################################
# Include PSI packaging commands
###############################################################
source ../../../TCL/PsiIpPackage/PsiIpPackage.tcl
namespace import -force psi::ip_package::latest::*

###############################################################
# General Information
###############################################################
set IP_NAME mem_test
set IP_VERSION 1.3
set IP_REVISION "auto"
set IP_LIBRARY DBPM3
set IP_DESCIRPTION "AXI Memory Tester"

init $IP_NAME $IP_VERSION $IP_REVISION $IP_LIBRARY
set_description $IP_DESCIRPTION
set_logo_relative "../doc/psi_logo_150.gif"
set_datasheet_relative "../doc/$IP_NAME.pdf"

###############################################################
# Add Source Files
###############################################################

#Relative Source Files
add_sources_relative { \
	../hdl/mem_test_pkg.vhd \
	../hdl/mem_test.vhd \
	../hdl/mem_test_wrapper.vhd \
}

#PSI Common
add_lib_relative \
	"../../../VHDL/psi_common/hdl"	\
	{ \
		psi_common_array_pkg.vhd \
		psi_common_math_pkg.vhd \
		psi_common_logic_pkg.vhd \
		psi_common_sdp_ram.vhd \
		psi_common_sync_fifo.vhd \
		psi_common_pl_stage.vhd \
		psi_common_axi_master_simple.vhd \
		psi_common_axi_slave_ipif.vhd \
	}	

###############################################################
# Driver Files
###############################################################	

add_drivers_relative ../drivers/mem_test { \
	src/mem_test.c \
	src/mem_test.h \
}
	

###############################################################
# GUI Parameters
###############################################################

#User Parameters
gui_add_page "AXI-M"

gui_create_parameter "C_M00_AXI_DATA_WIDTH" "AXI-M data width"
gui_parameter_set_range 16 256
gui_add_parameter

gui_create_parameter "C_M00_AXI_ADDR_WIDTH" "AXI-M addr width"
gui_parameter_set_range 16 64
gui_add_parameter

gui_create_parameter "C_M00_AXI_MAX_BURST_SIZE" "AXI-M Msx. Burst Size"
gui_parameter_set_range 1 256
gui_add_parameter

gui_create_parameter "C_M00_AXI_MAX_OPEN_TRANS" "AXI-M Max. Outstanding Transactions"
gui_parameter_set_range 0 8
gui_add_parameter


###############################################################
# Optional Ports
###############################################################

###############################################################
# Package Core
###############################################################
set TargetDir ".."
#						Edit  	Synth	Part
package_ip 	$TargetDir 	false 	true	xczu9eg-ffvb1156-2-e




