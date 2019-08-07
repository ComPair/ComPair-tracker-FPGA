startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
endgroup
set_property -dict [list CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells axi_gpio_0]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
endgroup
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_ports P2_s0_GALAO] [get_bd_pins xlslice_0/Dout]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
endgroup
set_property -dict [list CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DIN_FROM {1} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_1]
connect_bd_net [get_bd_ports P2_s1_GALAO] [get_bd_pins xlslice_1/Dout]
connect_bd_net [get_bd_pins xlslice_1/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2
endgroup
set_property -dict [list CONFIG.DIN_TO {2} CONFIG.DIN_FROM {2} CONFIG.DIN_FROM {2} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_2]
connect_bd_net [get_bd_ports P2_s2_GALAO] [get_bd_pins xlslice_2/Dout]
connect_bd_net [get_bd_pins xlslice_2/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3
endgroup
set_property -dict [list CONFIG.DIN_TO {3} CONFIG.DIN_FROM {3} CONFIG.DIN_FROM {3} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_3]
connect_bd_net [get_bd_ports P2_s_latch_GALAO] [get_bd_pins xlslice_3/Dout]
connect_bd_net [get_bd_pins xlslice_3/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4
endgroup
set_property -dict [list CONFIG.DIN_TO {4} CONFIG.DIN_FROM {4} CONFIG.DIN_FROM {4} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_4]
connect_bd_net [get_bd_ports P2_i1_GALAO] [get_bd_pins xlslice_4/Dout]
connect_bd_net [get_bd_pins xlslice_4/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5
endgroup
set_property -dict [list CONFIG.DIN_TO {5} CONFIG.DIN_FROM {5} CONFIG.DIN_FROM {5} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_5]
connect_bd_net [get_bd_ports P2_i3_GALAO] [get_bd_pins xlslice_5/Dout]
connect_bd_net [get_bd_pins xlslice_5/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6
endgroup
set_property -dict [list CONFIG.DIN_TO {6} CONFIG.DIN_FROM {6} CONFIG.DIN_FROM {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_6]
connect_bd_net [get_bd_ports P2_i4_GALAO] [get_bd_pins xlslice_6/Dout]
connect_bd_net [get_bd_pins xlslice_6/Din] [get_bd_pins axi_gpio_0/gpio_io_o]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_0/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
endgroup

set_property -dict [list CONFIG.C_NUM_OF_PROBES {8} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_0]
connect_bd_net [get_bd_pins ila_0/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins ila_0/probe0] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins ila_0/probe1] [get_bd_pins xlslice_0/Dout]
connect_bd_net [get_bd_pins ila_0/probe2] [get_bd_pins xlslice_1/Dout]
connect_bd_net [get_bd_pins ila_0/probe3] [get_bd_pins xlslice_2/Dout]
connect_bd_net [get_bd_pins ila_0/probe4] [get_bd_pins xlslice_3/Dout]
connect_bd_net [get_bd_pins ila_0/probe5] [get_bd_pins xlslice_4/Dout]
connect_bd_net [get_bd_pins ila_0/probe6] [get_bd_pins xlslice_5/Dout]
connect_bd_net [get_bd_pins ila_0/probe7] [get_bd_pins xlslice_6/Dout]

save_bd_design
