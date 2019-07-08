## This should add on the VATA driver to the base trenz block diagram.
## For the most part, I have no idea what the options being fed to the commands mean;
## these were all scraped from the Vivado GUI's tcl console while building
## the block diagram by hand.

## Create GPIO
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_cfg_setget
endgroup

set_property -dict [list CONFIG.C_GPIO_WIDTH {1} CONFIG.C_GPIO2_WIDTH {1} CONFIG.C_IS_DUAL {1} CONFIG.C_ALL_OUTPUTS_2 {1} ] [get_bd_cells axi_gpio_cfg_setget]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_cfg_setget/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_cfg_setget/S_AXI]

## Create VATA460.3 Driver
create_bd_cell -type module -reference vata460p3_interface vata460p3_interface_0
## Connect CLK
connect_bd_net [get_bd_pins vata460p3_interface_0/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]

## Add BRAM
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]

## Add BRAM controller to port A
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.SINGLE_PORT_BRAM {1} CONFIG.ECC_TYPE {0}] [get_bd_cells axi_bram_ctrl_0]
## Connect controller AXI
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {Auto} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_bram_ctrl_0/S_AXI} intc_ip {/ps7_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
## Connect to controller to port A
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

## Limit BRAM size. Way oversized for what we need
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
## Might as well limit GPIO address space
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_gpio_cfg_setget_Reg}]

## Connect VATA460.3 driver to BRAM
connect_bd_net [get_bd_pins vata460p3_interface_0/addr] [get_bd_pins blk_mem_gen_0/addrb]
connect_bd_net [get_bd_pins vata460p3_interface_0/dwrite] [get_bd_pins blk_mem_gen_0/dinb]
connect_bd_net [get_bd_pins vata460p3_interface_0/dread] [get_bd_pins blk_mem_gen_0/doutb]
connect_bd_net [get_bd_pins vata460p3_interface_0/bram_en] [get_bd_pins blk_mem_gen_0/enb]
connect_bd_net [get_bd_pins vata460p3_interface_0/bram_wea] [get_bd_pins blk_mem_gen_0/web]
connect_bd_net [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins processing_system7_0/FCLK_CLK0]

## Connect GPIO to VATA driver
connect_bd_net [get_bd_pins axi_gpio_cfg_setget/gpio_io_o] [get_bd_pins vata460p3_interface_0/set_config]
connect_bd_net [get_bd_pins axi_gpio_cfg_setget/gpio2_io_o] [get_bd_pins vata460p3_interface_0/get_config]

## Wrap it up
validate_bd_design
save_bd_design
