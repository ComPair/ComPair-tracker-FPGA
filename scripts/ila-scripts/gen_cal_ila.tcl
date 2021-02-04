update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_cal_O6_check
endgroup
set_property -dict [list CONFIG.C_NUM_OF_PROBES {13} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_cal_O6_check]
connect_bd_net [get_bd_pins ila_cal_O6_check/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe0] [get_bd_pins DIG_ASIC_0_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe1] [get_bd_pins DIG_ASIC_1_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe2] [get_bd_pins DIG_ASIC_2_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe3] [get_bd_pins DIG_ASIC_3_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe4] [get_bd_pins DIG_ASIC_4_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe5] [get_bd_pins DIG_ASIC_5_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe6] [get_bd_pins DIG_ASIC_6_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe7] [get_bd_pins DIG_ASIC_7_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe8] [get_bd_pins DIG_ASIC_8_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe9] [get_bd_pins DIG_ASIC_9_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe10] [get_bd_pins DIG_ASIC_10_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe11] [get_bd_pins DIG_ASIC_11_OUT_6_V_IN]
connect_bd_net [get_bd_pins ila_cal_O6_check/probe12] [get_bd_pins axi_cal_pulse_0/cal_pulse_trigger_out]