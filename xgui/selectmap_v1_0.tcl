# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_APB_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_APB_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Apb Addr Width} ${C_APB_ADDR_WIDTH}
  set C_APB_DATA_WIDTH [ipgui::add_param $IPINST -name "C_APB_DATA_WIDTH" -parent ${Page_0}]
  set_property tooltip {Apb Data Width} ${C_APB_DATA_WIDTH}
  ipgui::add_param $IPINST -name "DATA_TBYTES" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.C_APB_ADDR_WIDTH { PARAM_VALUE.C_APB_ADDR_WIDTH } {
	# Procedure called to update C_APB_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_APB_ADDR_WIDTH { PARAM_VALUE.C_APB_ADDR_WIDTH } {
	# Procedure called to validate C_APB_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_APB_DATA_WIDTH { PARAM_VALUE.C_APB_DATA_WIDTH } {
	# Procedure called to update C_APB_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_APB_DATA_WIDTH { PARAM_VALUE.C_APB_DATA_WIDTH } {
	# Procedure called to validate C_APB_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_TBYTES { PARAM_VALUE.DATA_TBYTES } {
	# Procedure called to update DATA_TBYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_TBYTES { PARAM_VALUE.DATA_TBYTES } {
	# Procedure called to validate DATA_TBYTES
	return true
}


proc update_MODELPARAM_VALUE.C_APB_DATA_WIDTH { MODELPARAM_VALUE.C_APB_DATA_WIDTH PARAM_VALUE.C_APB_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_APB_DATA_WIDTH}] ${MODELPARAM_VALUE.C_APB_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_APB_ADDR_WIDTH { MODELPARAM_VALUE.C_APB_ADDR_WIDTH PARAM_VALUE.C_APB_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_APB_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_APB_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_TBYTES { MODELPARAM_VALUE.DATA_TBYTES PARAM_VALUE.DATA_TBYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_TBYTES}] ${MODELPARAM_VALUE.DATA_TBYTES}
}

