## This should add on the VATA driver to the zynq.bd block diagram.
## For the most part, I have no idea what the options being fed to the commands mean;
## these were all scraped from the Vivado's journal file produced from adding to 
## the block diagram by hand.

open_bd_design {/home/lucas/fpga/xilinx/repos/ComPair-tracker-FPGA/work/zynq/zynq.srcs/sources_1/bd/zynq_bd/zynq_bd.bd}

## Create the AXI smart connect
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]

## Create interface to P2
startgroup
create_bd_cell -type ip -vlnv user.org:user:vata_460p3_interface:1.0 vata_460p3_interface_P2
endgroup

## Connect P2's AXI
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins vata_460p3_interface_P2/S_AXI_BRAM]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins vata_460p3_interface_P2/s_axi_vata]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/vata_460p3_interface_P2/S_AXI_BRAM} intc_ip {/smartconnect_0} master_apm {0}}  [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins vata_460p3_interface_P2/s00_axi_aclk_vata]

## Connect to external VATA ports
connect_bd_net [get_bd_ports P2_i1_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i1]
connect_bd_net [get_bd_ports P2_i3_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i3]
connect_bd_net [get_bd_ports P2_i4_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i4]
connect_bd_net [get_bd_ports P2_s0_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s0]
connect_bd_net [get_bd_ports P2_s1_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s1]
connect_bd_net [get_bd_ports P2_s2_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s2]
connect_bd_net [get_bd_ports P2_s_latch_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s_latch]
connect_bd_net [get_bd_ports P2_o5_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_o5]

regenerate_bd_layout
save_bd_design

