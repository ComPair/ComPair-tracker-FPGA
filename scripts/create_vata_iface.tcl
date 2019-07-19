set VATA_IFACE_REPO_DIR [file normalize "$CORES_BASE/vata_460p3_interface"]

update_compile_order -fileset sources_1
create_bd_design "vata_460p3_interface"
update_compile_order -fileset sources_1
add_files -norecurse $HDL_SRC_DIR/vata_460p3_axi_interface_v1_0_S00_AXI.vhd
add_files -norecurse $HDL_SRC_DIR/vata_460p3_axi_interface_v1_0.vhd

update_compile_order -fileset sources_1

create_bd_cell -type module -reference vata_460p3_axi_interface_v1_0 vata_460p3_axi_iface

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen
endgroup

set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_addr] [get_bd_pins blk_mem_gen/addra]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_clk] [get_bd_pins blk_mem_gen/clka]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_wea] [get_bd_pins blk_mem_gen/wea]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_en] [get_bd_pins blk_mem_gen/ena]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_dwrite] [get_bd_pins blk_mem_gen/dina]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_dread] [get_bd_pins blk_mem_gen/douta]
connect_bd_net [get_bd_pins vata_460p3_axi_iface/bram_rst] [get_bd_pins blk_mem_gen/rsta]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl
endgroup
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]

startgroup
make_bd_pins_external  [get_bd_cells axi_bram_ctrl]
make_bd_intf_pins_external  [get_bd_cells axi_bram_ctrl]
endgroup
set_property name S_AXI_BRAM [get_bd_intf_ports S_AXI_0]
set_property name s_axi_bram_aclk [get_bd_ports s_axi_aclk_0]
set_property name s_axi_aresetn_bram [get_bd_ports s_axi_aresetn_0]
set_property name s_axi_aclk_bram [get_bd_ports s_axi_bram_aclk]

startgroup
make_bd_pins_external  [get_bd_cells vata_460p3_axi_iface]
make_bd_intf_pins_external  [get_bd_cells vata_460p3_axi_iface]
endgroup
set_property name s_axi_vata [get_bd_intf_ports s00_axi_0]
set_property name vata_o5 [get_bd_ports vata_o5_0]
set_property name rst [get_bd_ports rst_0]
set_property name s00_axi_aclk_vata [get_bd_ports s00_axi_aclk_0]
set_property name s00_axi_aresetn_vata [get_bd_ports s00_axi_aresetn_0]
set_property name vata_s0 [get_bd_ports vata_s0_0]
set_property name vata_s1 [get_bd_ports vata_s1_0]
set_property name vata_s2 [get_bd_ports vata_s2_0]
set_property name vata_s_latch [get_bd_ports vata_s_latch_0]
set_property name vata_i1 [get_bd_ports vata_i1_0]
set_property name vata_i3 [get_bd_ports vata_i3_0]
set_property name vata_i4 [get_bd_ports vata_i4_0]

assign_bd_address [get_bd_addr_segs {axi_bram_ctrl/S_AXI/Mem0 }]
assign_bd_address [get_bd_addr_segs {vata_460p3_axi_iface/s00_axi/reg0 }]
set_property range 8K [get_bd_addr_segs {S_AXI_BRAM/SEG_axi_bram_ctrl_Mem0}]

ipx::package_project -root_dir $VATA_IFACE_REPO_DIR -vendor user.org -library user -taxonomy /UserIP -module vata_460p3_interface -import_files
set_property core_revision 2 [ipx::find_open_core user.org:user:vata_460p3_interface:1.0]
ipx::create_xgui_files [ipx::find_open_core user.org:user:vata_460p3_interface:1.0]
ipx::update_checksums [ipx::find_open_core user.org:user:vata_460p3_interface:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vata_460p3_interface:1.0]

set_property ip_repo_paths $VATA_IFACE_REPO_DIR [current_fileset]
update_ip_catalog

##open_bd_design {/home/lucas/fpga/xilinx/repos/ComPair-tracker-FPGA/work/zynq/zynq.srcs/sources_1/bd/zynq_bd/zynq_bd.bd}
##startgroup
##create_bd_cell -type ip -vlnv user.org:user:vata_460p3_interface:1.0 vata_460p3_interface_P2
##endgroup
##startgroup
##create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
##endgroup
##set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
##connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins vata_460p3_interface_P2/S_AXI_BRAM]
##connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins vata_460p3_interface_P2/s_axi_vata]
##apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/vata_460p3_interface_P2/S_AXI_BRAM} intc_ip {/smartconnect_0} master_apm {0}}  [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
##apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins vata_460p3_interface_P2/s00_axi_aclk_vata]
##connect_bd_net [get_bd_ports P2_i1_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i1]
##connect_bd_net [get_bd_ports P2_i3_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i3]
##connect_bd_net [get_bd_ports P2_i4_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_i4]
##connect_bd_net [get_bd_ports P2_s0_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s0]
##connect_bd_net [get_bd_ports P2_s1_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s1]
##connect_bd_net [get_bd_ports P2_s2_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s2]
##connect_bd_net [get_bd_ports P2_s_latch_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_s_latch]
##connect_bd_net [get_bd_ports P2_o5_GALAO] [get_bd_pins vata_460p3_interface_P2/vata_o5]
##
##regenerate_bd_layout
##save_bd_design
##
