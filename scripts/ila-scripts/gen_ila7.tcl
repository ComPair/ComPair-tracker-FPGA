update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_7
endgroup
set_property -dict [list CONFIG.C_NUM_OF_PROBES {12} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_7]
connect_bd_net [get_bd_pins ila_7/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins ila_7/probe0] [get_bd_pins vata_460p3_axi_inter_7/vata_s0]
connect_bd_net [get_bd_pins ila_7/probe1] [get_bd_pins vata_460p3_axi_inter_7/vata_s1]
connect_bd_net [get_bd_pins ila_7/probe2] [get_bd_pins vata_460p3_axi_inter_7/vata_s2]
connect_bd_net [get_bd_pins ila_7/probe3] [get_bd_pins vata_460p3_axi_inter_7/vata_s_latch]
connect_bd_net [get_bd_pins ila_7/probe4] [get_bd_pins vata_460p3_axi_inter_7/vata_i1]
connect_bd_net [get_bd_pins ila_7/probe5] [get_bd_pins vata_460p3_axi_inter_7/vata_i3]
connect_bd_net [get_bd_pins ila_7/probe6] [get_bd_pins vata_460p3_axi_inter_7/vata_i4]
connect_bd_net [get_bd_ports DIG_ASIC_7_OUT_5_IN] [get_bd_pins ila_7/probe7]
connect_bd_net [get_bd_ports DIG_ASIC_7_OUT_6_V_IN] [get_bd_pins ila_7/probe8]
connect_bd_net [get_bd_ports TRIG_HIT_IN] [get_bd_pins ila_7/probe9]
connect_bd_net [get_bd_pins ila_7/probe10] [get_bd_pins sync_vata_distn_0/vata_hits]
connect_bd_net [get_bd_pins ila_7/probe11] [get_bd_pins sync_vata_distn_0/force_trigger]
