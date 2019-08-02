# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set AXI-M [ipgui::add_page $IPINST -name "AXI-M"]
  ipgui::add_param $IPINST -name "C_M00_AXI_DATA_WIDTH" -parent ${AXI-M}
  ipgui::add_param $IPINST -name "C_M00_AXI_ADDR_WIDTH" -parent ${AXI-M}
  ipgui::add_param $IPINST -name "C_M00_AXI_MAX_BURST_SIZE" -parent ${AXI-M}
  ipgui::add_param $IPINST -name "C_M00_AXI_MAX_OPEN_TRANS" -parent ${AXI-M}


}

proc update_PARAM_VALUE.C_M00_AXI_ADDR_WIDTH { PARAM_VALUE.C_M00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_M00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXI_ADDR_WIDTH { PARAM_VALUE.C_M00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_M00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXI_DATA_WIDTH { PARAM_VALUE.C_M00_AXI_DATA_WIDTH } {
	# Procedure called to update C_M00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXI_DATA_WIDTH { PARAM_VALUE.C_M00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_M00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE { PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE } {
	# Procedure called to update C_M00_AXI_MAX_BURST_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE { PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE } {
	# Procedure called to validate C_M00_AXI_MAX_BURST_SIZE
	return true
}

proc update_PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS { PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS } {
	# Procedure called to update C_M00_AXI_MAX_OPEN_TRANS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS { PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS } {
	# Procedure called to validate C_M00_AXI_MAX_OPEN_TRANS
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to update C_S00_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to validate C_S00_AXI_ID_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH PARAM_VALUE.C_M00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH PARAM_VALUE.C_M00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE { MODELPARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE}] ${MODELPARAM_VALUE.C_M00_AXI_MAX_BURST_SIZE}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS { MODELPARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS}] ${MODELPARAM_VALUE.C_M00_AXI_MAX_OPEN_TRANS}
}

