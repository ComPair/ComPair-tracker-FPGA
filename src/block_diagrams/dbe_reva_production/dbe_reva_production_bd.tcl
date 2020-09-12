
################################################################
# This is a generated script based on design: dbe_reva_production_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source dbe_reva_production_bd_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-2
   set_property BOARD_PART trenz.biz:te0720_2i:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name dbe_reva_production_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
nasa.gov:user:AXI_cal_pulse:1.1\
xilinx.com:ip:util_vector_logic:2.0\
trenz.biz:user:SC0720:1.0\
xilinx.com:ip:axi_fifo_mm_s:4.2\
nasa.gov:user:dac121s101:1.0\
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:proc_sys_reset:5.0\
user.org:user:sync_vata_distn:1.0\
nasa.gov:user:vata_460p3_axi_interface:3.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

  # Create ports
  set DIG_ASIC_10_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_10_I1 ]
  set DIG_ASIC_10_I3 [ create_bd_port -dir O DIG_ASIC_10_I3 ]
  set DIG_ASIC_10_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_10_I4 ]
  set DIG_ASIC_10_OUT_5 [ create_bd_port -dir I DIG_ASIC_10_OUT_5 ]
  set DIG_ASIC_10_OUT_6 [ create_bd_port -dir I DIG_ASIC_10_OUT_6 ]
  set DIG_ASIC_10_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_10_S0 ]
  set DIG_ASIC_10_S1 [ create_bd_port -dir O DIG_ASIC_10_S1 ]
  set DIG_ASIC_10_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_10_S2 ]
  set DIG_ASIC_10_S_LATCH [ create_bd_port -dir O DIG_ASIC_10_S_LATCH ]
  set DIG_ASIC_11_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_11_CALD ]
  set DIG_ASIC_11_CALDB [ create_bd_port -dir O DIG_ASIC_11_CALDB ]
  set DIG_ASIC_11_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_11_I1 ]
  set DIG_ASIC_11_I3 [ create_bd_port -dir O DIG_ASIC_11_I3 ]
  set DIG_ASIC_11_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_11_I4 ]
  set DIG_ASIC_11_OUT_5 [ create_bd_port -dir I DIG_ASIC_11_OUT_5 ]
  set DIG_ASIC_11_OUT_6 [ create_bd_port -dir I DIG_ASIC_11_OUT_6 ]
  set DIG_ASIC_11_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_11_S0 ]
  set DIG_ASIC_11_S1 [ create_bd_port -dir O DIG_ASIC_11_S1 ]
  set DIG_ASIC_11_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_11_S2 ]
  set DIG_ASIC_11_S_LATCH [ create_bd_port -dir O DIG_ASIC_11_S_LATCH ]
  set DIG_ASIC_12_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_12_I1 ]
  set DIG_ASIC_12_I3 [ create_bd_port -dir O DIG_ASIC_12_I3 ]
  set DIG_ASIC_12_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_12_I4 ]
  set DIG_ASIC_12_OUT_5 [ create_bd_port -dir I DIG_ASIC_12_OUT_5 ]
  set DIG_ASIC_12_OUT_6 [ create_bd_port -dir I DIG_ASIC_12_OUT_6 ]
  set DIG_ASIC_12_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_12_S0 ]
  set DIG_ASIC_12_S1 [ create_bd_port -dir O DIG_ASIC_12_S1 ]
  set DIG_ASIC_12_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_12_S2 ]
  set DIG_ASIC_12_S_LATCH [ create_bd_port -dir O DIG_ASIC_12_S_LATCH ]
  set DIG_ASIC_1_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_1_CALD ]
  set DIG_ASIC_1_CALDB [ create_bd_port -dir O DIG_ASIC_1_CALDB ]
  set DIG_ASIC_1_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_1_I1 ]
  set DIG_ASIC_1_I3 [ create_bd_port -dir O DIG_ASIC_1_I3 ]
  set DIG_ASIC_1_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_1_I4 ]
  set DIG_ASIC_1_OUT_5 [ create_bd_port -dir I DIG_ASIC_1_OUT_5 ]
  set DIG_ASIC_1_OUT_6 [ create_bd_port -dir I DIG_ASIC_1_OUT_6 ]
  set DIG_ASIC_1_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_1_S0 ]
  set DIG_ASIC_1_S1 [ create_bd_port -dir O DIG_ASIC_1_S1 ]
  set DIG_ASIC_1_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_1_S2 ]
  set DIG_ASIC_1_S_LATCH [ create_bd_port -dir O DIG_ASIC_1_S_LATCH ]
  set DIG_ASIC_2_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_2_I1 ]
  set DIG_ASIC_2_I3 [ create_bd_port -dir O DIG_ASIC_2_I3 ]
  set DIG_ASIC_2_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_2_I4 ]
  set DIG_ASIC_2_OUT_5 [ create_bd_port -dir I DIG_ASIC_2_OUT_5 ]
  set DIG_ASIC_2_OUT_6 [ create_bd_port -dir I DIG_ASIC_2_OUT_6 ]
  set DIG_ASIC_2_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_2_S0 ]
  set DIG_ASIC_2_S1 [ create_bd_port -dir O DIG_ASIC_2_S1 ]
  set DIG_ASIC_2_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_2_S2 ]
  set DIG_ASIC_2_S_LATCH [ create_bd_port -dir O DIG_ASIC_2_S_LATCH ]
  set DIG_ASIC_3_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_3_CALD ]
  set DIG_ASIC_3_CALDB [ create_bd_port -dir O DIG_ASIC_3_CALDB ]
  set DIG_ASIC_3_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_3_I1 ]
  set DIG_ASIC_3_I3 [ create_bd_port -dir O DIG_ASIC_3_I3 ]
  set DIG_ASIC_3_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_3_I4 ]
  set DIG_ASIC_3_OUT_5 [ create_bd_port -dir I DIG_ASIC_3_OUT_5 ]
  set DIG_ASIC_3_OUT_6 [ create_bd_port -dir I DIG_ASIC_3_OUT_6 ]
  set DIG_ASIC_3_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_3_S0 ]
  set DIG_ASIC_3_S1 [ create_bd_port -dir O DIG_ASIC_3_S1 ]
  set DIG_ASIC_3_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_3_S2 ]
  set DIG_ASIC_3_S_LATCH [ create_bd_port -dir O DIG_ASIC_3_S_LATCH ]
  set DIG_ASIC_4_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_4_I1 ]
  set DIG_ASIC_4_I3 [ create_bd_port -dir O DIG_ASIC_4_I3 ]
  set DIG_ASIC_4_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_4_I4 ]
  set DIG_ASIC_4_OUT_5 [ create_bd_port -dir I DIG_ASIC_4_OUT_5 ]
  set DIG_ASIC_4_OUT_6 [ create_bd_port -dir I DIG_ASIC_4_OUT_6 ]
  set DIG_ASIC_4_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_4_S0 ]
  set DIG_ASIC_4_S1 [ create_bd_port -dir O DIG_ASIC_4_S1 ]
  set DIG_ASIC_4_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_4_S2 ]
  set DIG_ASIC_4_S_LATCH [ create_bd_port -dir O DIG_ASIC_4_S_LATCH ]
  set DIG_ASIC_5_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_5_CALD ]
  set DIG_ASIC_5_CALDB [ create_bd_port -dir O DIG_ASIC_5_CALDB ]
  set DIG_ASIC_5_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_5_I1 ]
  set DIG_ASIC_5_I3 [ create_bd_port -dir O DIG_ASIC_5_I3 ]
  set DIG_ASIC_5_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_5_I4 ]
  set DIG_ASIC_5_OUT_5 [ create_bd_port -dir I DIG_ASIC_5_OUT_5 ]
  set DIG_ASIC_5_OUT_6 [ create_bd_port -dir I DIG_ASIC_5_OUT_6 ]
  set DIG_ASIC_5_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_5_S0 ]
  set DIG_ASIC_5_S1 [ create_bd_port -dir O DIG_ASIC_5_S1 ]
  set DIG_ASIC_5_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_5_S2 ]
  set DIG_ASIC_5_S_LATCH [ create_bd_port -dir O DIG_ASIC_5_S_LATCH ]
  set DIG_ASIC_6_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_6_I1 ]
  set DIG_ASIC_6_I3 [ create_bd_port -dir O DIG_ASIC_6_I3 ]
  set DIG_ASIC_6_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_6_I4 ]
  set DIG_ASIC_6_OUT_5 [ create_bd_port -dir I DIG_ASIC_6_OUT_5 ]
  set DIG_ASIC_6_OUT_6 [ create_bd_port -dir I DIG_ASIC_6_OUT_6 ]
  set DIG_ASIC_6_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_6_S0 ]
  set DIG_ASIC_6_S1 [ create_bd_port -dir O DIG_ASIC_6_S1 ]
  set DIG_ASIC_6_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_6_S2 ]
  set DIG_ASIC_6_S_LATCH [ create_bd_port -dir O DIG_ASIC_6_S_LATCH ]
  set DIG_ASIC_7_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_7_CALD ]
  set DIG_ASIC_7_CALDB [ create_bd_port -dir O DIG_ASIC_7_CALDB ]
  set DIG_ASIC_7_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_7_I1 ]
  set DIG_ASIC_7_I3 [ create_bd_port -dir O DIG_ASIC_7_I3 ]
  set DIG_ASIC_7_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_7_I4 ]
  set DIG_ASIC_7_OUT_5 [ create_bd_port -dir I DIG_ASIC_7_OUT_5 ]
  set DIG_ASIC_7_OUT_6 [ create_bd_port -dir I DIG_ASIC_7_OUT_6 ]
  set DIG_ASIC_7_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_7_S0 ]
  set DIG_ASIC_7_S1 [ create_bd_port -dir O DIG_ASIC_7_S1 ]
  set DIG_ASIC_7_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_7_S2 ]
  set DIG_ASIC_7_S_LATCH [ create_bd_port -dir O DIG_ASIC_7_S_LATCH ]
  set DIG_ASIC_8_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_8_I1 ]
  set DIG_ASIC_8_I3 [ create_bd_port -dir O DIG_ASIC_8_I3 ]
  set DIG_ASIC_8_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_8_I4 ]
  set DIG_ASIC_8_OUT_5 [ create_bd_port -dir I DIG_ASIC_8_OUT_5 ]
  set DIG_ASIC_8_OUT_6 [ create_bd_port -dir I DIG_ASIC_8_OUT_6 ]
  set DIG_ASIC_8_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_8_S0 ]
  set DIG_ASIC_8_S1 [ create_bd_port -dir O DIG_ASIC_8_S1 ]
  set DIG_ASIC_8_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_8_S2 ]
  set DIG_ASIC_8_S_LATCH [ create_bd_port -dir O DIG_ASIC_8_S_LATCH ]
  set DIG_ASIC_9_CALD [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_9_CALD ]
  set DIG_ASIC_9_CALDB [ create_bd_port -dir O DIG_ASIC_9_CALDB ]
  set DIG_ASIC_9_I1 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_9_I1 ]
  set DIG_ASIC_9_I3 [ create_bd_port -dir O DIG_ASIC_9_I3 ]
  set DIG_ASIC_9_I4 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_9_I4 ]
  set DIG_ASIC_9_OUT_5 [ create_bd_port -dir I DIG_ASIC_9_OUT_5 ]
  set DIG_ASIC_9_OUT_6 [ create_bd_port -dir I DIG_ASIC_9_OUT_6 ]
  set DIG_ASIC_9_S0 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_9_S0 ]
  set DIG_ASIC_9_S1 [ create_bd_port -dir O DIG_ASIC_9_S1 ]
  set DIG_ASIC_9_S2 [ create_bd_port -dir O -from 0 -to 0 DIG_ASIC_9_S2 ]
  set DIG_ASIC_9_S_LATCH [ create_bd_port -dir O DIG_ASIC_9_S_LATCH ]
  set DIG_A_CAL_DAC_SYNCn_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_CAL_DAC_SYNCn_P ]
  set DIG_A_CAL_PULSE_TRIGGER_P [ create_bd_port -dir O DIG_A_CAL_PULSE_TRIGGER_P ]
  set DIG_A_TELEM1_CSn_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_TELEM1_CSn_P ]
  set DIG_A_TELEM1_SCLK_P [ create_bd_port -dir O DIG_A_TELEM1_SCLK_P ]
  set DIG_A_TELEM2_CSn_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_TELEM2_CSn_P ]
  set DIG_A_TELEMX_MISO_P [ create_bd_port -dir I DIG_A_TELEMX_MISO_P ]
  set DIG_A_TELEMX_MOSI_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_TELEMX_MOSI_P ]
  set DIG_A_VTH_CAL_DAC_MOSI_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_VTH_CAL_DAC_MOSI_P ]
  set DIG_A_VTH_CAL_DAC_SCLK_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_VTH_CAL_DAC_SCLK_P ]
  set DIG_A_VTH_DAC_SYNCn_P [ create_bd_port -dir O -from 0 -to 0 DIG_A_VTH_DAC_SYNCn_P ]
  set DIG_B_CAL_DAC_SYNCn_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_CAL_DAC_SYNCn_P ]
  set DIG_B_CAL_PULSE_TRIGGER_P [ create_bd_port -dir O DIG_B_CAL_PULSE_TRIGGER_P ]
  set DIG_B_TELEM1_CSn_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_TELEM1_CSn_P ]
  set DIG_B_TELEM2_CSn_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_TELEM2_CSn_P ]
  set DIG_B_TELEMX_MISO_P [ create_bd_port -dir I DIG_B_TELEMX_MISO_P ]
  set DIG_B_TELEMX_MOSI_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_TELEMX_MOSI_P ]
  set DIG_B_TELEMX_SCLK_P [ create_bd_port -dir O DIG_B_TELEMX_SCLK_P ]
  set DIG_B_VTH_CAL_DAC_MOSI_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_VTH_CAL_DAC_MOSI_P ]
  set DIG_B_VTH_CAL_DAC_SCLK_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_VTH_CAL_DAC_SCLK_P ]
  set DIG_B_VTH_DAC_SYNCn_P [ create_bd_port -dir O -from 0 -to 0 DIG_B_VTH_DAC_SYNCn_P ]
  set EXTCLK [ create_bd_port -dir I EXTCLK ]
  set Event_ID_Latch_P [ create_bd_port -dir I Event_ID_Latch_P ]
  set Event_ID_P [ create_bd_port -dir I Event_ID_P ]
  set PL_pin_K16 [ create_bd_port -dir I PL_pin_K16 ]
  set PL_pin_K19 [ create_bd_port -dir I PL_pin_K19 ]
  set PL_pin_K20 [ create_bd_port -dir O PL_pin_K20 ]
  set PL_pin_L16 [ create_bd_port -dir O PL_pin_L16 ]
  set PL_pin_M15 [ create_bd_port -dir I PL_pin_M15 ]
  set PL_pin_N15 [ create_bd_port -dir I PL_pin_N15 ]
  set PL_pin_N22 [ create_bd_port -dir O PL_pin_N22 ]
  set PL_pin_P16 [ create_bd_port -dir I PL_pin_P16 ]
  set PL_pin_P22 [ create_bd_port -dir I PL_pin_P22 ]
  set PPS [ create_bd_port -dir I PPS ]
  set Si_BUSY_P [ create_bd_port -dir O -from 0 -to 0 Si_BUSY_P ]
  set Si_HIT_P [ create_bd_port -dir O -from 0 -to 0 Si_HIT_P ]
  set Si_RDY_P [ create_bd_port -dir O Si_RDY_P ]
  set Si_SPARE_P [ create_bd_port -dir O Si_SPARE_P ]
  set Trig_Ack_P [ create_bd_port -dir I Trig_Ack_P ]
  set Trig_ENA_P [ create_bd_port -dir I Trig_ENA_P ]
  set eth_phy_led0_yellow [ create_bd_port -dir O -from 0 -to 0 eth_phy_led0_yellow ]
  set eth_phy_led1_green [ create_bd_port -dir O -from 0 -to 0 eth_phy_led1_green ]

  # Create instance: AXI_cal_pulse_0, and set properties
  set AXI_cal_pulse_0 [ create_bd_cell -type ip -vlnv nasa.gov:user:AXI_cal_pulse:1.1 AXI_cal_pulse_0 ]

  # Create instance: INV_CALD_ASIC1, and set properties
  set INV_CALD_ASIC1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC1

  # Create instance: INV_CALD_ASIC3, and set properties
  set INV_CALD_ASIC3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC3

  # Create instance: INV_CALD_ASIC5, and set properties
  set INV_CALD_ASIC5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC5

  # Create instance: INV_CALD_ASIC7, and set properties
  set INV_CALD_ASIC7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC7 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC7

  # Create instance: INV_CALD_ASIC9, and set properties
  set INV_CALD_ASIC9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC9 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC9

  # Create instance: INV_CALD_ASIC10, and set properties
  set INV_CALD_ASIC10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_CALD_ASIC10 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_CALD_ASIC10

  # Create instance: INV_I1_ASIC1, and set properties
  set INV_I1_ASIC1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC1

  # Create instance: INV_I1_ASIC2, and set properties
  set INV_I1_ASIC2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC2

  # Create instance: INV_I1_ASIC3, and set properties
  set INV_I1_ASIC3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC3

  # Create instance: INV_I1_ASIC4, and set properties
  set INV_I1_ASIC4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC4 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC4

  # Create instance: INV_I1_ASIC5, and set properties
  set INV_I1_ASIC5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC5

  # Create instance: INV_I1_ASIC6, and set properties
  set INV_I1_ASIC6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC6 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC6

  # Create instance: INV_I1_ASIC7, and set properties
  set INV_I1_ASIC7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC7 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC7

  # Create instance: INV_I1_ASIC8, and set properties
  set INV_I1_ASIC8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC8 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC8

  # Create instance: INV_I1_ASIC9, and set properties
  set INV_I1_ASIC9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC9 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC9

  # Create instance: INV_I1_ASIC10, and set properties
  set INV_I1_ASIC10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC10 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC10

  # Create instance: INV_I1_ASIC11, and set properties
  set INV_I1_ASIC11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC11 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC11

  # Create instance: INV_I1_ASIC12, and set properties
  set INV_I1_ASIC12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I1_ASIC12 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I1_ASIC12

  # Create instance: INV_I4_ASIC1, and set properties
  set INV_I4_ASIC1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC1

  # Create instance: INV_I4_ASIC2, and set properties
  set INV_I4_ASIC2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC2

  # Create instance: INV_I4_ASIC3, and set properties
  set INV_I4_ASIC3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC3

  # Create instance: INV_I4_ASIC4, and set properties
  set INV_I4_ASIC4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC4 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC4

  # Create instance: INV_I4_ASIC5, and set properties
  set INV_I4_ASIC5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC5

  # Create instance: INV_I4_ASIC6, and set properties
  set INV_I4_ASIC6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC6 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC6

  # Create instance: INV_I4_ASIC7, and set properties
  set INV_I4_ASIC7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC7 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC7

  # Create instance: INV_I4_ASIC8, and set properties
  set INV_I4_ASIC8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC8 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC8

  # Create instance: INV_I4_ASIC9, and set properties
  set INV_I4_ASIC9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC9 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC9

  # Create instance: INV_I4_ASIC10, and set properties
  set INV_I4_ASIC10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC10 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC10

  # Create instance: INV_I4_ASIC11, and set properties
  set INV_I4_ASIC11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC11 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC11

  # Create instance: INV_I4_ASIC12, and set properties
  set INV_I4_ASIC12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_I4_ASIC12 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_I4_ASIC12

  # Create instance: INV_S0_ASIC1, and set properties
  set INV_S0_ASIC1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC1

  # Create instance: INV_S0_ASIC2, and set properties
  set INV_S0_ASIC2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC2

  # Create instance: INV_S0_ASIC3, and set properties
  set INV_S0_ASIC3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC3

  # Create instance: INV_S0_ASIC4, and set properties
  set INV_S0_ASIC4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC4 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC4

  # Create instance: INV_S0_ASIC5, and set properties
  set INV_S0_ASIC5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC5

  # Create instance: INV_S0_ASIC6, and set properties
  set INV_S0_ASIC6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC6 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC6

  # Create instance: INV_S0_ASIC7, and set properties
  set INV_S0_ASIC7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC7 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC7

  # Create instance: INV_S0_ASIC8, and set properties
  set INV_S0_ASIC8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC8 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC8

  # Create instance: INV_S0_ASIC9, and set properties
  set INV_S0_ASIC9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC9 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC9

  # Create instance: INV_S0_ASIC10, and set properties
  set INV_S0_ASIC10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC10 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC10

  # Create instance: INV_S0_ASIC11, and set properties
  set INV_S0_ASIC11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC11 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC11

  # Create instance: INV_S0_ASIC12, and set properties
  set INV_S0_ASIC12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S0_ASIC12 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S0_ASIC12

  # Create instance: INV_S2_ASIC1, and set properties
  set INV_S2_ASIC1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC1

  # Create instance: INV_S2_ASIC2, and set properties
  set INV_S2_ASIC2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC2

  # Create instance: INV_S2_ASIC3, and set properties
  set INV_S2_ASIC3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC3

  # Create instance: INV_S2_ASIC4, and set properties
  set INV_S2_ASIC4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC4 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC4

  # Create instance: INV_S2_ASIC5, and set properties
  set INV_S2_ASIC5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC5

  # Create instance: INV_S2_ASIC6, and set properties
  set INV_S2_ASIC6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC6 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC6

  # Create instance: INV_S2_ASIC7, and set properties
  set INV_S2_ASIC7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC7 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC7

  # Create instance: INV_S2_ASIC8, and set properties
  set INV_S2_ASIC8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC8 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC8

  # Create instance: INV_S2_ASIC9, and set properties
  set INV_S2_ASIC9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC9 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC9

  # Create instance: INV_S2_ASIC10, and set properties
  set INV_S2_ASIC10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC10 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC10

  # Create instance: INV_S2_ASIC11, and set properties
  set INV_S2_ASIC11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC11 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC11

  # Create instance: INV_S2_ASIC12, and set properties
  set INV_S2_ASIC12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_S2_ASIC12 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_S2_ASIC12

  # Create instance: INV_SI_BUSY, and set properties
  set INV_SI_BUSY [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_SI_BUSY ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_SI_BUSY

  # Create instance: INV_SI_HIT, and set properties
  set INV_SI_HIT [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_SI_HIT ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_SI_HIT

  # Create instance: INV_VTH_CAL_DAC_MOSI, and set properties
  set INV_VTH_CAL_DAC_MOSI [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_VTH_CAL_DAC_MOSI ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_VTH_CAL_DAC_MOSI

  # Create instance: INV_VTH_CAL_DAC_SCLK, and set properties
  set INV_VTH_CAL_DAC_SCLK [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 INV_VTH_CAL_DAC_SCLK ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $INV_VTH_CAL_DAC_SCLK

  # Create instance: SC0720_0, and set properties
  set SC0720_0 [ create_bd_cell -type ip -vlnv trenz.biz:user:SC0720:1.0 SC0720_0 ]

  # Create instance: axi_fifo_mm_s_data0, and set properties
  set axi_fifo_mm_s_data0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data0 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data0

  # Create instance: axi_fifo_mm_s_data1, and set properties
  set axi_fifo_mm_s_data1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data1 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data1

  # Create instance: axi_fifo_mm_s_data2, and set properties
  set axi_fifo_mm_s_data2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data2 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data2

  # Create instance: axi_fifo_mm_s_data3, and set properties
  set axi_fifo_mm_s_data3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data3 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data3

  # Create instance: axi_fifo_mm_s_data4, and set properties
  set axi_fifo_mm_s_data4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data4 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data4

  # Create instance: axi_fifo_mm_s_data5, and set properties
  set axi_fifo_mm_s_data5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data5 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data5

  # Create instance: axi_fifo_mm_s_data6, and set properties
  set axi_fifo_mm_s_data6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data6 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data6

  # Create instance: axi_fifo_mm_s_data7, and set properties
  set axi_fifo_mm_s_data7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data7 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data7

  # Create instance: axi_fifo_mm_s_data8, and set properties
  set axi_fifo_mm_s_data8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data8 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data8

  # Create instance: axi_fifo_mm_s_data9, and set properties
  set axi_fifo_mm_s_data9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data9 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data9

  # Create instance: axi_fifo_mm_s_data10, and set properties
  set axi_fifo_mm_s_data10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data10 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data10

  # Create instance: axi_fifo_mm_s_data11, and set properties
  set axi_fifo_mm_s_data11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_fifo_mm_s:4.2 axi_fifo_mm_s_data11 ]
  set_property -dict [ list \
   CONFIG.C_RX_FIFO_DEPTH {1024} \
   CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
   CONFIG.C_RX_FIFO_PF_THRESHOLD {507} \
   CONFIG.C_USE_TX_CTRL {0} \
   CONFIG.C_USE_TX_DATA {0} \
 ] $axi_fifo_mm_s_data11

  # Create instance: dac121s101_0, and set properties
  set dac121s101_0 [ create_bd_cell -type ip -vlnv nasa.gov:user:dac121s101:1.0 dac121s101_0 ]

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
   CONFIG.PCW_ACT_CAN0_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN1_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {1.000000} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_I2C_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {166.666672} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
   CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
   CONFIG.PCW_CAN0_BASEADDR {0xE0008000} \
   CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN0_HIGHADDR {0xE0008FFF} \
   CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN0_PERIPHERAL_FREQMHZ {-1} \
   CONFIG.PCW_CAN1_BASEADDR {0xE0009000} \
   CONFIG.PCW_CAN1_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN1_HIGHADDR {0xE0009FFF} \
   CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN1_PERIPHERAL_FREQMHZ {-1} \
   CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
   CONFIG.PCW_CLK0_FREQ {100000000} \
   CONFIG.PCW_CLK1_FREQ {1000000} \
   CONFIG.PCW_CLK2_FREQ {10000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CORE0_FIQ_INTR {0} \
   CONFIG.PCW_CORE0_IRQ_INTR {0} \
   CONFIG.PCW_CORE1_FIQ_INTR {0} \
   CONFIG.PCW_CORE1_IRQ_INTR {0} \
   CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {767} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
   CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} \
   CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
   CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
   CONFIG.PCW_DDR_HPRLPR_QUEUE_PARTITION {HPR(0)/LPR(32)} \
   CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
   CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_PORT0_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT1_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT2_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT3_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_RAM_BASEADDR {0x00100000} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
   CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DM_WIDTH {4} \
   CONFIG.PCW_DQS_WIDTH {4} \
   CONFIG.PCW_DQ_WIDTH {32} \
   CONFIG.PCW_ENET0_BASEADDR {0xE000B000} \
   CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
   CONFIG.PCW_ENET0_HIGHADDR {0xE000BFFF} \
   CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {0} \
   CONFIG.PCW_ENET1_BASEADDR {0xE000C000} \
   CONFIG.PCW_ENET1_GRP_MDIO_ENABLE {0} \
   CONFIG.PCW_ENET1_HIGHADDR {0xE000CFFF} \
   CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
   CONFIG.PCW_EN_4K_TIMER {0} \
   CONFIG.PCW_EN_CAN0 {0} \
   CONFIG.PCW_EN_CAN1 {0} \
   CONFIG.PCW_EN_CLK0_PORT {1} \
   CONFIG.PCW_EN_CLK1_PORT {1} \
   CONFIG.PCW_EN_CLK2_PORT {0} \
   CONFIG.PCW_EN_CLK3_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG0_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG1_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG2_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG3_PORT {0} \
   CONFIG.PCW_EN_DDR {1} \
   CONFIG.PCW_EN_EMIO_CAN0 {0} \
   CONFIG.PCW_EN_EMIO_CAN1 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_ENET0 {0} \
   CONFIG.PCW_EN_EMIO_ENET1 {0} \
   CONFIG.PCW_EN_EMIO_GPIO {0} \
   CONFIG.PCW_EN_EMIO_I2C0 {0} \
   CONFIG.PCW_EN_EMIO_I2C1 {1} \
   CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
   CONFIG.PCW_EN_EMIO_PJTAG {0} \
   CONFIG.PCW_EN_EMIO_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_SPI0 {1} \
   CONFIG.PCW_EN_EMIO_SPI1 {1} \
   CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
   CONFIG.PCW_EN_EMIO_TRACE {0} \
   CONFIG.PCW_EN_EMIO_TTC0 {1} \
   CONFIG.PCW_EN_EMIO_TTC1 {1} \
   CONFIG.PCW_EN_EMIO_UART0 {0} \
   CONFIG.PCW_EN_EMIO_UART1 {0} \
   CONFIG.PCW_EN_EMIO_WDT {1} \
   CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
   CONFIG.PCW_EN_ENET0 {1} \
   CONFIG.PCW_EN_ENET1 {0} \
   CONFIG.PCW_EN_GPIO {1} \
   CONFIG.PCW_EN_I2C0 {1} \
   CONFIG.PCW_EN_I2C1 {1} \
   CONFIG.PCW_EN_MODEM_UART0 {0} \
   CONFIG.PCW_EN_MODEM_UART1 {0} \
   CONFIG.PCW_EN_PJTAG {0} \
   CONFIG.PCW_EN_PTP_ENET0 {0} \
   CONFIG.PCW_EN_PTP_ENET1 {0} \
   CONFIG.PCW_EN_QSPI {1} \
   CONFIG.PCW_EN_RST0_PORT {1} \
   CONFIG.PCW_EN_RST1_PORT {0} \
   CONFIG.PCW_EN_RST2_PORT {0} \
   CONFIG.PCW_EN_RST3_PORT {0} \
   CONFIG.PCW_EN_SDIO0 {1} \
   CONFIG.PCW_EN_SDIO1 {1} \
   CONFIG.PCW_EN_SMC {0} \
   CONFIG.PCW_EN_SPI0 {1} \
   CONFIG.PCW_EN_SPI1 {1} \
   CONFIG.PCW_EN_TRACE {0} \
   CONFIG.PCW_EN_TTC0 {1} \
   CONFIG.PCW_EN_TTC1 {1} \
   CONFIG.PCW_EN_UART0 {1} \
   CONFIG.PCW_EN_UART1 {1} \
   CONFIG.PCW_EN_USB0 {1} \
   CONFIG.PCW_EN_USB1 {0} \
   CONFIG.PCW_EN_WDT {1} \
   CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
   CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {40} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {25} \
   CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK1_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK2_BUF {FALSE} \
   CONFIG.PCW_FCLK_CLK3_BUF {FALSE} \
   CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {1} \
   CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_FTM_CTI_IN0 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN1 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN2 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN3 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT0 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT1 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT2 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT3 {<Select>} \
   CONFIG.PCW_GP0_EN_MODIFIABLE_TXN {1} \
   CONFIG.PCW_GP0_NUM_READ_THREADS {4} \
   CONFIG.PCW_GP0_NUM_WRITE_THREADS {4} \
   CONFIG.PCW_GP1_EN_MODIFIABLE_TXN {1} \
   CONFIG.PCW_GP1_NUM_READ_THREADS {4} \
   CONFIG.PCW_GP1_NUM_WRITE_THREADS {4} \
   CONFIG.PCW_GPIO_BASEADDR {0xE000A000} \
   CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {64} \
   CONFIG.PCW_GPIO_HIGHADDR {0xE000AFFF} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
   CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
   CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C0_BASEADDR {0xE0004000} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C0_HIGHADDR {0xE0004FFF} \
   CONFIG.PCW_I2C0_I2C0_IO {MIO 10 .. 11} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_ENABLE {0} \
   CONFIG.PCW_I2C1_BASEADDR {0xE0005000} \
   CONFIG.PCW_I2C1_GRP_INT_ENABLE {1} \
   CONFIG.PCW_I2C1_GRP_INT_IO {EMIO} \
   CONFIG.PCW_I2C1_HIGHADDR {0xE0005FFF} \
   CONFIG.PCW_I2C1_I2C1_IO {EMIO} \
   CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_I2C_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
   CONFIG.PCW_IMPORT_BOARD_PRESET {None} \
   CONFIG.PCW_INCLUDE_ACP_TRANS_CHECK {0} \
   CONFIG.PCW_INCLUDE_TRACE_BUFFER {0} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
   CONFIG.PCW_MIO_0_DIRECTION {inout} \
   CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_0_PULLUP {disabled} \
   CONFIG.PCW_MIO_0_SLEW {slow} \
   CONFIG.PCW_MIO_10_DIRECTION {inout} \
   CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_10_PULLUP {enabled} \
   CONFIG.PCW_MIO_10_SLEW {slow} \
   CONFIG.PCW_MIO_11_DIRECTION {inout} \
   CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_11_PULLUP {enabled} \
   CONFIG.PCW_MIO_11_SLEW {slow} \
   CONFIG.PCW_MIO_12_DIRECTION {out} \
   CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_12_PULLUP {enabled} \
   CONFIG.PCW_MIO_12_SLEW {slow} \
   CONFIG.PCW_MIO_13_DIRECTION {in} \
   CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_13_PULLUP {enabled} \
   CONFIG.PCW_MIO_13_SLEW {slow} \
   CONFIG.PCW_MIO_14_DIRECTION {in} \
   CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_14_PULLUP {enabled} \
   CONFIG.PCW_MIO_14_SLEW {slow} \
   CONFIG.PCW_MIO_15_DIRECTION {out} \
   CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_15_PULLUP {enabled} \
   CONFIG.PCW_MIO_15_SLEW {slow} \
   CONFIG.PCW_MIO_16_DIRECTION {out} \
   CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_16_PULLUP {enabled} \
   CONFIG.PCW_MIO_16_SLEW {slow} \
   CONFIG.PCW_MIO_17_DIRECTION {out} \
   CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_17_PULLUP {enabled} \
   CONFIG.PCW_MIO_17_SLEW {slow} \
   CONFIG.PCW_MIO_18_DIRECTION {out} \
   CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_18_PULLUP {enabled} \
   CONFIG.PCW_MIO_18_SLEW {slow} \
   CONFIG.PCW_MIO_19_DIRECTION {out} \
   CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_19_PULLUP {enabled} \
   CONFIG.PCW_MIO_19_SLEW {slow} \
   CONFIG.PCW_MIO_1_DIRECTION {out} \
   CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_1_PULLUP {enabled} \
   CONFIG.PCW_MIO_1_SLEW {slow} \
   CONFIG.PCW_MIO_20_DIRECTION {out} \
   CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_20_PULLUP {enabled} \
   CONFIG.PCW_MIO_20_SLEW {slow} \
   CONFIG.PCW_MIO_21_DIRECTION {out} \
   CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_21_PULLUP {enabled} \
   CONFIG.PCW_MIO_21_SLEW {slow} \
   CONFIG.PCW_MIO_22_DIRECTION {in} \
   CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_22_PULLUP {enabled} \
   CONFIG.PCW_MIO_22_SLEW {slow} \
   CONFIG.PCW_MIO_23_DIRECTION {in} \
   CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_23_PULLUP {enabled} \
   CONFIG.PCW_MIO_23_SLEW {slow} \
   CONFIG.PCW_MIO_24_DIRECTION {in} \
   CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_24_PULLUP {enabled} \
   CONFIG.PCW_MIO_24_SLEW {slow} \
   CONFIG.PCW_MIO_25_DIRECTION {in} \
   CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_25_PULLUP {enabled} \
   CONFIG.PCW_MIO_25_SLEW {slow} \
   CONFIG.PCW_MIO_26_DIRECTION {in} \
   CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_26_PULLUP {enabled} \
   CONFIG.PCW_MIO_26_SLEW {slow} \
   CONFIG.PCW_MIO_27_DIRECTION {in} \
   CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_27_PULLUP {enabled} \
   CONFIG.PCW_MIO_27_SLEW {slow} \
   CONFIG.PCW_MIO_28_DIRECTION {inout} \
   CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_28_PULLUP {enabled} \
   CONFIG.PCW_MIO_28_SLEW {slow} \
   CONFIG.PCW_MIO_29_DIRECTION {in} \
   CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_29_PULLUP {enabled} \
   CONFIG.PCW_MIO_29_SLEW {slow} \
   CONFIG.PCW_MIO_2_DIRECTION {inout} \
   CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_2_PULLUP {disabled} \
   CONFIG.PCW_MIO_2_SLEW {slow} \
   CONFIG.PCW_MIO_30_DIRECTION {out} \
   CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_30_PULLUP {enabled} \
   CONFIG.PCW_MIO_30_SLEW {slow} \
   CONFIG.PCW_MIO_31_DIRECTION {in} \
   CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_31_PULLUP {enabled} \
   CONFIG.PCW_MIO_31_SLEW {slow} \
   CONFIG.PCW_MIO_32_DIRECTION {inout} \
   CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_32_PULLUP {enabled} \
   CONFIG.PCW_MIO_32_SLEW {slow} \
   CONFIG.PCW_MIO_33_DIRECTION {inout} \
   CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_33_PULLUP {enabled} \
   CONFIG.PCW_MIO_33_SLEW {slow} \
   CONFIG.PCW_MIO_34_DIRECTION {inout} \
   CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_34_PULLUP {enabled} \
   CONFIG.PCW_MIO_34_SLEW {slow} \
   CONFIG.PCW_MIO_35_DIRECTION {inout} \
   CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_35_PULLUP {enabled} \
   CONFIG.PCW_MIO_35_SLEW {slow} \
   CONFIG.PCW_MIO_36_DIRECTION {in} \
   CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_36_PULLUP {enabled} \
   CONFIG.PCW_MIO_36_SLEW {slow} \
   CONFIG.PCW_MIO_37_DIRECTION {inout} \
   CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_37_PULLUP {enabled} \
   CONFIG.PCW_MIO_37_SLEW {slow} \
   CONFIG.PCW_MIO_38_DIRECTION {inout} \
   CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_38_PULLUP {enabled} \
   CONFIG.PCW_MIO_38_SLEW {slow} \
   CONFIG.PCW_MIO_39_DIRECTION {inout} \
   CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_39_PULLUP {enabled} \
   CONFIG.PCW_MIO_39_SLEW {slow} \
   CONFIG.PCW_MIO_3_DIRECTION {inout} \
   CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_3_PULLUP {disabled} \
   CONFIG.PCW_MIO_3_SLEW {slow} \
   CONFIG.PCW_MIO_40_DIRECTION {inout} \
   CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_40_PULLUP {disabled} \
   CONFIG.PCW_MIO_40_SLEW {slow} \
   CONFIG.PCW_MIO_41_DIRECTION {inout} \
   CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_41_PULLUP {disabled} \
   CONFIG.PCW_MIO_41_SLEW {slow} \
   CONFIG.PCW_MIO_42_DIRECTION {inout} \
   CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_42_PULLUP {disabled} \
   CONFIG.PCW_MIO_42_SLEW {slow} \
   CONFIG.PCW_MIO_43_DIRECTION {inout} \
   CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_43_PULLUP {disabled} \
   CONFIG.PCW_MIO_43_SLEW {slow} \
   CONFIG.PCW_MIO_44_DIRECTION {inout} \
   CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_44_PULLUP {disabled} \
   CONFIG.PCW_MIO_44_SLEW {slow} \
   CONFIG.PCW_MIO_45_DIRECTION {inout} \
   CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_45_PULLUP {disabled} \
   CONFIG.PCW_MIO_45_SLEW {slow} \
   CONFIG.PCW_MIO_46_DIRECTION {inout} \
   CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_46_PULLUP {enabled} \
   CONFIG.PCW_MIO_46_SLEW {slow} \
   CONFIG.PCW_MIO_47_DIRECTION {inout} \
   CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_47_PULLUP {enabled} \
   CONFIG.PCW_MIO_47_SLEW {slow} \
   CONFIG.PCW_MIO_48_DIRECTION {inout} \
   CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_48_PULLUP {enabled} \
   CONFIG.PCW_MIO_48_SLEW {slow} \
   CONFIG.PCW_MIO_49_DIRECTION {inout} \
   CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_49_PULLUP {enabled} \
   CONFIG.PCW_MIO_49_SLEW {slow} \
   CONFIG.PCW_MIO_4_DIRECTION {inout} \
   CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_4_PULLUP {disabled} \
   CONFIG.PCW_MIO_4_SLEW {slow} \
   CONFIG.PCW_MIO_50_DIRECTION {inout} \
   CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_50_PULLUP {enabled} \
   CONFIG.PCW_MIO_50_SLEW {slow} \
   CONFIG.PCW_MIO_51_DIRECTION {inout} \
   CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_51_PULLUP {enabled} \
   CONFIG.PCW_MIO_51_SLEW {slow} \
   CONFIG.PCW_MIO_52_DIRECTION {out} \
   CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_52_PULLUP {enabled} \
   CONFIG.PCW_MIO_52_SLEW {slow} \
   CONFIG.PCW_MIO_53_DIRECTION {inout} \
   CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_53_PULLUP {enabled} \
   CONFIG.PCW_MIO_53_SLEW {slow} \
   CONFIG.PCW_MIO_5_DIRECTION {inout} \
   CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_5_PULLUP {disabled} \
   CONFIG.PCW_MIO_5_SLEW {slow} \
   CONFIG.PCW_MIO_6_DIRECTION {out} \
   CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_6_PULLUP {disabled} \
   CONFIG.PCW_MIO_6_SLEW {slow} \
   CONFIG.PCW_MIO_7_DIRECTION {out} \
   CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_7_PULLUP {disabled} \
   CONFIG.PCW_MIO_7_SLEW {slow} \
   CONFIG.PCW_MIO_8_DIRECTION {out} \
   CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_8_PULLUP {disabled} \
   CONFIG.PCW_MIO_8_SLEW {slow} \
   CONFIG.PCW_MIO_9_DIRECTION {inout} \
   CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_9_PULLUP {disabled} \
   CONFIG.PCW_MIO_9_SLEW {slow} \
   CONFIG.PCW_MIO_PRIMITIVE {54} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#Quad SPI Flash#GPIO#I2C 0#I2C 0#UART 1#UART 1#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#Enet 0#Enet 0} \
   CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#gpio[7]#qspi_fbclk#gpio[9]#scl#sda#tx#rx#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#data[0]#cmd#clk#data[1]#data[2]#data[3]#mdc#mdio} \
   CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
   CONFIG.PCW_M_AXI_GP0_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP0_SUPPORT_NARROW_BURST {0} \
   CONFIG.PCW_M_AXI_GP0_THREAD_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP1_ENABLE_STATIC_REMAP {0} \
   CONFIG.PCW_M_AXI_GP1_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP1_SUPPORT_NARROW_BURST {0} \
   CONFIG.PCW_M_AXI_GP1_THREAD_ID_WIDTH {12} \
   CONFIG.PCW_NAND_CYCLES_T_AR {1} \
   CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
   CONFIG.PCW_NAND_CYCLES_T_RC {11} \
   CONFIG.PCW_NAND_CYCLES_T_REA {1} \
   CONFIG.PCW_NAND_CYCLES_T_RR {1} \
   CONFIG.PCW_NAND_CYCLES_T_WC {11} \
   CONFIG.PCW_NAND_CYCLES_T_WP {1} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_CS0_T_PC {1} \
   CONFIG.PCW_NOR_CS0_T_RC {11} \
   CONFIG.PCW_NOR_CS0_T_TR {1} \
   CONFIG.PCW_NOR_CS0_T_WC {11} \
   CONFIG.PCW_NOR_CS0_T_WP {1} \
   CONFIG.PCW_NOR_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_CS1_T_PC {1} \
   CONFIG.PCW_NOR_CS1_T_RC {11} \
   CONFIG.PCW_NOR_CS1_T_TR {1} \
   CONFIG.PCW_NOR_CS1_T_WC {11} \
   CONFIG.PCW_NOR_CS1_T_WP {1} \
   CONFIG.PCW_NOR_CS1_WE_TIME {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
   CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
   CONFIG.PCW_P2F_CAN0_INTR {0} \
   CONFIG.PCW_P2F_CAN1_INTR {0} \
   CONFIG.PCW_P2F_CTI_INTR {0} \
   CONFIG.PCW_P2F_DMAC0_INTR {0} \
   CONFIG.PCW_P2F_DMAC1_INTR {0} \
   CONFIG.PCW_P2F_DMAC2_INTR {0} \
   CONFIG.PCW_P2F_DMAC3_INTR {0} \
   CONFIG.PCW_P2F_DMAC4_INTR {0} \
   CONFIG.PCW_P2F_DMAC5_INTR {0} \
   CONFIG.PCW_P2F_DMAC6_INTR {0} \
   CONFIG.PCW_P2F_DMAC7_INTR {0} \
   CONFIG.PCW_P2F_DMAC_ABORT_INTR {0} \
   CONFIG.PCW_P2F_ENET0_INTR {0} \
   CONFIG.PCW_P2F_ENET1_INTR {0} \
   CONFIG.PCW_P2F_GPIO_INTR {0} \
   CONFIG.PCW_P2F_I2C0_INTR {0} \
   CONFIG.PCW_P2F_I2C1_INTR {0} \
   CONFIG.PCW_P2F_QSPI_INTR {0} \
   CONFIG.PCW_P2F_SDIO0_INTR {0} \
   CONFIG.PCW_P2F_SDIO1_INTR {0} \
   CONFIG.PCW_P2F_SMC_INTR {0} \
   CONFIG.PCW_P2F_SPI0_INTR {0} \
   CONFIG.PCW_P2F_SPI1_INTR {0} \
   CONFIG.PCW_P2F_UART0_INTR {0} \
   CONFIG.PCW_P2F_UART1_INTR {0} \
   CONFIG.PCW_P2F_USB0_INTR {0} \
   CONFIG.PCW_P2F_USB1_INTR {0} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.063} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.062} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.065} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.083} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {-0.007} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {-0.010} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.006} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.048} \
   CONFIG.PCW_PACKAGE_NAME {clg484} \
   CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_PERIPHERAL_BOARD_PRESET {part0} \
   CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
   CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
   CONFIG.PCW_PS7_SI_REV {PRODUCTION} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
   CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
   CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD1_SD1_IO {MIO 46 .. 51} \
   CONFIG.PCW_SDIO0_BASEADDR {0xE0100000} \
   CONFIG.PCW_SDIO0_HIGHADDR {0xE0100FFF} \
   CONFIG.PCW_SDIO1_BASEADDR {0xE0101000} \
   CONFIG.PCW_SDIO1_HIGHADDR {0xE0101FFF} \
   CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
   CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
   CONFIG.PCW_SMC_CYCLE_T0 {NA} \
   CONFIG.PCW_SMC_CYCLE_T1 {NA} \
   CONFIG.PCW_SMC_CYCLE_T2 {NA} \
   CONFIG.PCW_SMC_CYCLE_T3 {NA} \
   CONFIG.PCW_SMC_CYCLE_T4 {NA} \
   CONFIG.PCW_SMC_CYCLE_T5 {NA} \
   CONFIG.PCW_SMC_CYCLE_T6 {NA} \
   CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SMC_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
   CONFIG.PCW_SPI0_BASEADDR {0xE0006000} \
   CONFIG.PCW_SPI0_GRP_SS0_ENABLE {1} \
   CONFIG.PCW_SPI0_GRP_SS0_IO {EMIO} \
   CONFIG.PCW_SPI0_GRP_SS1_ENABLE {1} \
   CONFIG.PCW_SPI0_GRP_SS1_IO {EMIO} \
   CONFIG.PCW_SPI0_GRP_SS2_ENABLE {1} \
   CONFIG.PCW_SPI0_GRP_SS2_IO {EMIO} \
   CONFIG.PCW_SPI0_HIGHADDR {0xE0006FFF} \
   CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SPI0_SPI0_IO {EMIO} \
   CONFIG.PCW_SPI1_BASEADDR {0xE0007000} \
   CONFIG.PCW_SPI1_GRP_SS0_ENABLE {1} \
   CONFIG.PCW_SPI1_GRP_SS0_IO {EMIO} \
   CONFIG.PCW_SPI1_GRP_SS1_ENABLE {1} \
   CONFIG.PCW_SPI1_GRP_SS1_IO {EMIO} \
   CONFIG.PCW_SPI1_GRP_SS2_ENABLE {1} \
   CONFIG.PCW_SPI1_GRP_SS2_IO {EMIO} \
   CONFIG.PCW_SPI1_HIGHADDR {0xE0007FFF} \
   CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SPI1_SPI1_IO {EMIO} \
   CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {6} \
   CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
   CONFIG.PCW_SPI_PERIPHERAL_VALID {1} \
   CONFIG.PCW_S_AXI_ACP_ARUSER_VAL {31} \
   CONFIG.PCW_S_AXI_ACP_AWUSER_VAL {31} \
   CONFIG.PCW_S_AXI_ACP_ID_WIDTH {3} \
   CONFIG.PCW_S_AXI_GP0_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_GP1_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP0_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP1_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP2_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP3_ID_WIDTH {6} \
   CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TPIU_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_TRACE_BUFFER_CLOCK_DELAY {12} \
   CONFIG.PCW_TRACE_BUFFER_FIFO_SIZE {128} \
   CONFIG.PCW_TRACE_GRP_16BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_2BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_32BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_4BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_8BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
   CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TRACE_PIPELINE_WIDTH {8} \
   CONFIG.PCW_TTC0_BASEADDR {0xE0104000} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_HIGHADDR {0xE0104fff} \
   CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
   CONFIG.PCW_TTC1_BASEADDR {0xE0105000} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_HIGHADDR {0xE0105fff} \
   CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_TTC1_TTC1_IO {EMIO} \
   CONFIG.PCW_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_UART0_BASEADDR {0xE0000000} \
   CONFIG.PCW_UART0_BAUD_RATE {115200} \
   CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART0_HIGHADDR {0xE0000FFF} \
   CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
   CONFIG.PCW_UART1_BASEADDR {0xE0001000} \
   CONFIG.PCW_UART1_BAUD_RATE {115200} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_HIGHADDR {0xE0001FFF} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART1_UART1_IO {MIO 12 .. 13} \
   CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
   CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
   CONFIG.PCW_UIPARAM_DDR_AL {0} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BL {8} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {32 Bit} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {68.4725} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {71.086} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {66.794} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {108.7385} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {64.1705} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {63.686} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {68.46} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {105.4895} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
   CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
   CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
   CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333333} \
   CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
   CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {48.91} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {7} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {7} \
   CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
   CONFIG.PCW_UIPARAM_GENERATE_SUMMARY {NA} \
   CONFIG.PCW_USB0_BASEADDR {0xE0102000} \
   CONFIG.PCW_USB0_HIGHADDR {0xE0102fff} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {0} \
   CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
   CONFIG.PCW_USB1_BASEADDR {0xE0103000} \
   CONFIG.PCW_USB1_HIGHADDR {0xE0103fff} \
   CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
   CONFIG.PCW_USE_AXI_FABRIC_IDLE {0} \
   CONFIG.PCW_USE_AXI_NONSECURE {0} \
   CONFIG.PCW_USE_CORESIGHT {0} \
   CONFIG.PCW_USE_CROSS_TRIGGER {0} \
   CONFIG.PCW_USE_CR_FABRIC {1} \
   CONFIG.PCW_USE_DDR_BYPASS {0} \
   CONFIG.PCW_USE_DEBUG {0} \
   CONFIG.PCW_USE_DEFAULT_ACP_USER_VAL {0} \
   CONFIG.PCW_USE_DMA0 {0} \
   CONFIG.PCW_USE_DMA1 {0} \
   CONFIG.PCW_USE_DMA2 {0} \
   CONFIG.PCW_USE_DMA3 {0} \
   CONFIG.PCW_USE_EXPANDED_IOP {0} \
   CONFIG.PCW_USE_EXPANDED_PS_SLCR_REGISTERS {0} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
   CONFIG.PCW_USE_HIGH_OCM {0} \
   CONFIG.PCW_USE_M_AXI_GP0 {1} \
   CONFIG.PCW_USE_M_AXI_GP1 {1} \
   CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
   CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
   CONFIG.PCW_USE_S_AXI_ACP {0} \
   CONFIG.PCW_USE_S_AXI_GP0 {0} \
   CONFIG.PCW_USE_S_AXI_GP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP0 {0} \
   CONFIG.PCW_USE_S_AXI_HP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP2 {0} \
   CONFIG.PCW_USE_S_AXI_HP3 {0} \
   CONFIG.PCW_USE_TRACE {0} \
   CONFIG.PCW_USE_TRACE_DATA_EDGE_DETECTOR {0} \
   CONFIG.PCW_VALUE_SILVERSION {3} \
   CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_WDT_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_WDT_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_WDT_WDT_IO {EMIO} \
 ] $processing_system7_0

  # Create instance: ps7_0_axi_periph, and set properties
  set ps7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {26} \
 ] $ps7_0_axi_periph

  # Create instance: ps7_0_axi_periph_1, and set properties
  set ps7_0_axi_periph_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
 ] $ps7_0_axi_periph_1

  # Create instance: rst_ps7_0_100M, and set properties
  set rst_ps7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M ]

  # Create instance: rst_ps7_0_5M, and set properties
  set rst_ps7_0_5M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_5M ]

  # Create instance: sync_vata_distn_0, and set properties
  set sync_vata_distn_0 [ create_bd_cell -type ip -vlnv user.org:user:sync_vata_distn:1.0 sync_vata_distn_0 ]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {xor} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_xorgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_2

  # Create instance: util_vector_logic_3, and set properties
  set util_vector_logic_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_3 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {xor} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_xorgate.png} \
 ] $util_vector_logic_3

  # Create instance: util_vector_logic_4, and set properties
  set util_vector_logic_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_4 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_4

  # Create instance: util_vector_logic_5, and set properties
  set util_vector_logic_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_5 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_5

  # Create instance: util_vector_logic_6, and set properties
  set util_vector_logic_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_6 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $util_vector_logic_6

  # Create instance: vata_460p3_axi_inter_0, and set properties
  set vata_460p3_axi_inter_0 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_0 ]

  # Create instance: vata_460p3_axi_inter_1, and set properties
  set vata_460p3_axi_inter_1 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_1 ]

  # Create instance: vata_460p3_axi_inter_2, and set properties
  set vata_460p3_axi_inter_2 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_2 ]

  # Create instance: vata_460p3_axi_inter_3, and set properties
  set vata_460p3_axi_inter_3 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_3 ]

  # Create instance: vata_460p3_axi_inter_4, and set properties
  set vata_460p3_axi_inter_4 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_4 ]

  # Create instance: vata_460p3_axi_inter_5, and set properties
  set vata_460p3_axi_inter_5 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_5 ]

  # Create instance: vata_460p3_axi_inter_6, and set properties
  set vata_460p3_axi_inter_6 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_6 ]

  # Create instance: vata_460p3_axi_inter_7, and set properties
  set vata_460p3_axi_inter_7 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_7 ]

  # Create instance: vata_460p3_axi_inter_8, and set properties
  set vata_460p3_axi_inter_8 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_8 ]

  # Create instance: vata_460p3_axi_inter_9, and set properties
  set vata_460p3_axi_inter_9 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_9 ]

  # Create instance: vata_460p3_axi_inter_10, and set properties
  set vata_460p3_axi_inter_10 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_10 ]

  # Create instance: vata_460p3_axi_inter_11, and set properties
  set vata_460p3_axi_inter_11 [ create_bd_cell -type ip -vlnv nasa.gov:user:vata_460p3_axi_interface:3.0 vata_460p3_axi_inter_11 ]

  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_OUT {0} \
 ] $vio_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {3} \
 ] $xlconcat_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_4

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_5

  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_6

  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_7 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {4} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_7

  # Create interface connections
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_IIC_1 [get_bd_intf_pins SC0720_0/EMIO_I2C1] [get_bd_intf_pins processing_system7_0/IIC_1]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP1 [get_bd_intf_pins processing_system7_0/M_AXI_GP1] [get_bd_intf_pins ps7_0_axi_periph_1/S00_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_1_M02_AXI [get_bd_intf_pins dac121s101_0/S00_AXI] [get_bd_intf_pins ps7_0_axi_periph_1/M02_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI [get_bd_intf_pins AXI_cal_pulse_0/S00_AXI] [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M01_AXI [get_bd_intf_pins ps7_0_axi_periph/M01_AXI] [get_bd_intf_pins vata_460p3_axi_inter_0/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M02_AXI [get_bd_intf_pins axi_fifo_mm_s_data0/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M03_AXI [get_bd_intf_pins ps7_0_axi_periph/M03_AXI] [get_bd_intf_pins vata_460p3_axi_inter_1/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M04_AXI [get_bd_intf_pins axi_fifo_mm_s_data1/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M05_AXI [get_bd_intf_pins ps7_0_axi_periph/M05_AXI] [get_bd_intf_pins vata_460p3_axi_inter_2/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M06_AXI [get_bd_intf_pins axi_fifo_mm_s_data2/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M07_AXI [get_bd_intf_pins ps7_0_axi_periph/M07_AXI] [get_bd_intf_pins vata_460p3_axi_inter_3/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M08_AXI [get_bd_intf_pins axi_fifo_mm_s_data3/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M09_AXI [get_bd_intf_pins ps7_0_axi_periph/M09_AXI] [get_bd_intf_pins vata_460p3_axi_inter_4/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M10_AXI [get_bd_intf_pins axi_fifo_mm_s_data4/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M11_AXI [get_bd_intf_pins ps7_0_axi_periph/M11_AXI] [get_bd_intf_pins vata_460p3_axi_inter_5/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M12_AXI [get_bd_intf_pins axi_fifo_mm_s_data5/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M13_AXI [get_bd_intf_pins ps7_0_axi_periph/M13_AXI] [get_bd_intf_pins vata_460p3_axi_inter_6/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M14_AXI [get_bd_intf_pins axi_fifo_mm_s_data6/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M14_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M15_AXI [get_bd_intf_pins ps7_0_axi_periph/M15_AXI] [get_bd_intf_pins vata_460p3_axi_inter_7/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M16_AXI [get_bd_intf_pins axi_fifo_mm_s_data7/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M16_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M17_AXI [get_bd_intf_pins ps7_0_axi_periph/M17_AXI] [get_bd_intf_pins vata_460p3_axi_inter_8/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M18_AXI [get_bd_intf_pins axi_fifo_mm_s_data8/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M18_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M19_AXI [get_bd_intf_pins ps7_0_axi_periph/M19_AXI] [get_bd_intf_pins vata_460p3_axi_inter_9/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M20_AXI [get_bd_intf_pins axi_fifo_mm_s_data9/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M20_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M21_AXI [get_bd_intf_pins axi_fifo_mm_s_data10/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M21_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M22_AXI [get_bd_intf_pins ps7_0_axi_periph/M22_AXI] [get_bd_intf_pins vata_460p3_axi_inter_10/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M23_AXI [get_bd_intf_pins ps7_0_axi_periph/M23_AXI] [get_bd_intf_pins vata_460p3_axi_inter_11/s00_axi]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M24_AXI [get_bd_intf_pins axi_fifo_mm_s_data11/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M24_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M25_AXI [get_bd_intf_pins ps7_0_axi_periph/M25_AXI] [get_bd_intf_pins sync_vata_distn_0/S00_AXI]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_0_data_stream [get_bd_intf_pins axi_fifo_mm_s_data0/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_0/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_10_data_stream [get_bd_intf_pins axi_fifo_mm_s_data10/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_10/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_11_data_stream [get_bd_intf_pins axi_fifo_mm_s_data11/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_11/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_1_data_stream [get_bd_intf_pins axi_fifo_mm_s_data1/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_1/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_2_data_stream [get_bd_intf_pins axi_fifo_mm_s_data2/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_2/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_3_data_stream [get_bd_intf_pins axi_fifo_mm_s_data3/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_3/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_4_data_stream [get_bd_intf_pins axi_fifo_mm_s_data4/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_4/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_5_data_stream [get_bd_intf_pins axi_fifo_mm_s_data5/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_5/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_6_data_stream [get_bd_intf_pins axi_fifo_mm_s_data6/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_6/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_7_data_stream [get_bd_intf_pins axi_fifo_mm_s_data7/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_7/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_8_data_stream [get_bd_intf_pins axi_fifo_mm_s_data8/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_8/data_stream]
  connect_bd_intf_net -intf_net vata_460p3_axi_inter_9_data_stream [get_bd_intf_pins axi_fifo_mm_s_data9/AXI_STR_RXD] [get_bd_intf_pins vata_460p3_axi_inter_9/data_stream]

  # Create port connections
  connect_bd_net -net AXI_cal_pulse_0_cal_pulse_trigger_out [get_bd_ports DIG_A_CAL_PULSE_TRIGGER_P] [get_bd_pins AXI_cal_pulse_0/cal_pulse_trigger_out] [get_bd_pins vata_460p3_axi_inter_0/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_1/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_10/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_11/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_2/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_3/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_4/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_5/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_6/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_7/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_8/cal_pulse_trigger] [get_bd_pins vata_460p3_axi_inter_9/cal_pulse_trigger]
  connect_bd_net -net DIG_ASIC_10_OUT_5_1 [get_bd_ports DIG_ASIC_10_OUT_5] [get_bd_pins vata_460p3_axi_inter_9/vata_o5]
  connect_bd_net -net DIG_ASIC_10_OUT_6_1 [get_bd_ports DIG_ASIC_10_OUT_6] [get_bd_pins vata_460p3_axi_inter_9/vata_o6]
  connect_bd_net -net DIG_ASIC_11_OUT_5_1 [get_bd_ports DIG_ASIC_11_OUT_5] [get_bd_pins vata_460p3_axi_inter_10/vata_o5]
  connect_bd_net -net DIG_ASIC_11_OUT_6_1 [get_bd_ports DIG_ASIC_11_OUT_6] [get_bd_pins vata_460p3_axi_inter_10/vata_o6]
  connect_bd_net -net DIG_ASIC_12_OUT_5_1 [get_bd_ports DIG_ASIC_12_OUT_5] [get_bd_pins vata_460p3_axi_inter_11/vata_o5]
  connect_bd_net -net DIG_ASIC_12_OUT_6_1 [get_bd_ports DIG_ASIC_12_OUT_6] [get_bd_pins vata_460p3_axi_inter_11/vata_o6]
  connect_bd_net -net DIG_ASIC_1_OUT_5_1 [get_bd_ports DIG_ASIC_1_OUT_5] [get_bd_pins vata_460p3_axi_inter_0/vata_o5]
  connect_bd_net -net DIG_ASIC_1_OUT_6_1 [get_bd_ports DIG_ASIC_1_OUT_6] [get_bd_pins vata_460p3_axi_inter_0/vata_o6]
  connect_bd_net -net DIG_ASIC_2_OUT_5_1 [get_bd_ports DIG_ASIC_2_OUT_5] [get_bd_pins vata_460p3_axi_inter_1/vata_o5]
  connect_bd_net -net DIG_ASIC_2_OUT_6_1 [get_bd_ports DIG_ASIC_2_OUT_6] [get_bd_pins vata_460p3_axi_inter_1/vata_o6]
  connect_bd_net -net DIG_ASIC_3_OUT_5_1 [get_bd_ports DIG_ASIC_3_OUT_5] [get_bd_pins vata_460p3_axi_inter_2/vata_o5]
  connect_bd_net -net DIG_ASIC_3_OUT_6_1 [get_bd_ports DIG_ASIC_3_OUT_6] [get_bd_pins vata_460p3_axi_inter_2/vata_o6]
  connect_bd_net -net DIG_ASIC_4_OUT_5_1 [get_bd_ports DIG_ASIC_4_OUT_5] [get_bd_pins vata_460p3_axi_inter_3/vata_o5]
  connect_bd_net -net DIG_ASIC_4_OUT_6_1 [get_bd_ports DIG_ASIC_4_OUT_6] [get_bd_pins vata_460p3_axi_inter_3/vata_o6]
  connect_bd_net -net DIG_ASIC_5_OUT_5_1 [get_bd_ports DIG_ASIC_5_OUT_5] [get_bd_pins vata_460p3_axi_inter_4/vata_o5]
  connect_bd_net -net DIG_ASIC_5_OUT_6_1 [get_bd_ports DIG_ASIC_5_OUT_6] [get_bd_pins vata_460p3_axi_inter_4/vata_o6]
  connect_bd_net -net DIG_ASIC_6_OUT_5_1 [get_bd_ports DIG_ASIC_6_OUT_5] [get_bd_pins vata_460p3_axi_inter_5/vata_o5]
  connect_bd_net -net DIG_ASIC_6_OUT_6_1 [get_bd_ports DIG_ASIC_6_OUT_6] [get_bd_pins vata_460p3_axi_inter_5/vata_o6]
  connect_bd_net -net DIG_ASIC_7_OUT_5_1 [get_bd_ports DIG_ASIC_7_OUT_5] [get_bd_pins vata_460p3_axi_inter_6/vata_o5]
  connect_bd_net -net DIG_ASIC_7_OUT_6_1 [get_bd_ports DIG_ASIC_7_OUT_6] [get_bd_pins vata_460p3_axi_inter_6/vata_o6]
  connect_bd_net -net DIG_ASIC_8_OUT_5_1 [get_bd_ports DIG_ASIC_8_OUT_5] [get_bd_pins vata_460p3_axi_inter_7/vata_o5]
  connect_bd_net -net DIG_ASIC_8_OUT_6_1 [get_bd_ports DIG_ASIC_8_OUT_6] [get_bd_pins vata_460p3_axi_inter_7/vata_o6]
  connect_bd_net -net DIG_ASIC_9_OUT_5_1 [get_bd_ports DIG_ASIC_9_OUT_5] [get_bd_pins vata_460p3_axi_inter_8/vata_o5]
  connect_bd_net -net DIG_ASIC_9_OUT_6_1 [get_bd_ports DIG_ASIC_9_OUT_6] [get_bd_pins vata_460p3_axi_inter_8/vata_o6]
  connect_bd_net -net DIG_A_TELEMX_MISO_P_1 [get_bd_ports DIG_A_TELEMX_MISO_P] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net DIG_B_TELEMX_MISO_P_1 [get_bd_ports DIG_B_TELEMX_MISO_P] [get_bd_pins util_vector_logic_3/Op1]
  connect_bd_net -net Event_ID_Latch_P_1 [get_bd_ports Event_ID_Latch_P] [get_bd_pins vata_460p3_axi_inter_0/event_id_latch] [get_bd_pins vata_460p3_axi_inter_1/event_id_latch] [get_bd_pins vata_460p3_axi_inter_10/event_id_latch] [get_bd_pins vata_460p3_axi_inter_11/event_id_latch] [get_bd_pins vata_460p3_axi_inter_2/event_id_latch] [get_bd_pins vata_460p3_axi_inter_3/event_id_latch] [get_bd_pins vata_460p3_axi_inter_4/event_id_latch] [get_bd_pins vata_460p3_axi_inter_5/event_id_latch] [get_bd_pins vata_460p3_axi_inter_6/event_id_latch] [get_bd_pins vata_460p3_axi_inter_7/event_id_latch] [get_bd_pins vata_460p3_axi_inter_8/event_id_latch] [get_bd_pins vata_460p3_axi_inter_9/event_id_latch]
  connect_bd_net -net Event_ID_P_1 [get_bd_ports Event_ID_P] [get_bd_pins vata_460p3_axi_inter_0/event_id_data] [get_bd_pins vata_460p3_axi_inter_1/event_id_data] [get_bd_pins vata_460p3_axi_inter_10/event_id_data] [get_bd_pins vata_460p3_axi_inter_11/event_id_data] [get_bd_pins vata_460p3_axi_inter_2/event_id_data] [get_bd_pins vata_460p3_axi_inter_3/event_id_data] [get_bd_pins vata_460p3_axi_inter_4/event_id_data] [get_bd_pins vata_460p3_axi_inter_5/event_id_data] [get_bd_pins vata_460p3_axi_inter_6/event_id_data] [get_bd_pins vata_460p3_axi_inter_7/event_id_data] [get_bd_pins vata_460p3_axi_inter_8/event_id_data] [get_bd_pins vata_460p3_axi_inter_9/event_id_data]
  connect_bd_net -net INV_CALD_ASIC10_Res [get_bd_ports DIG_ASIC_11_CALD] [get_bd_pins INV_CALD_ASIC10/Res]
  connect_bd_net -net INV_CALD_ASIC1_Res [get_bd_ports DIG_ASIC_1_CALD] [get_bd_pins INV_CALD_ASIC1/Res]
  connect_bd_net -net INV_CALD_ASIC3_Res [get_bd_ports DIG_ASIC_3_CALD] [get_bd_pins INV_CALD_ASIC3/Res]
  connect_bd_net -net INV_CALD_ASIC5_Res [get_bd_ports DIG_ASIC_5_CALD] [get_bd_pins INV_CALD_ASIC5/Res]
  connect_bd_net -net INV_CALD_ASIC7_Res [get_bd_ports DIG_ASIC_7_CALD] [get_bd_pins INV_CALD_ASIC7/Res]
  connect_bd_net -net INV_CALD_ASIC8_Res [get_bd_ports DIG_ASIC_9_CALD] [get_bd_pins INV_CALD_ASIC9/Res]
  connect_bd_net -net INV_I1_ASIC10_Res [get_bd_ports DIG_ASIC_10_I1] [get_bd_pins INV_I1_ASIC10/Res]
  connect_bd_net -net INV_I1_ASIC11_Res [get_bd_ports DIG_ASIC_11_I1] [get_bd_pins INV_I1_ASIC11/Res]
  connect_bd_net -net INV_I1_ASIC12_Res [get_bd_ports DIG_ASIC_12_I1] [get_bd_pins INV_I1_ASIC12/Res]
  connect_bd_net -net INV_I1_ASIC1_Res [get_bd_ports DIG_ASIC_1_I1] [get_bd_pins INV_I1_ASIC1/Res]
  connect_bd_net -net INV_I1_ASIC2_Res [get_bd_ports DIG_ASIC_2_I1] [get_bd_pins INV_I1_ASIC2/Res]
  connect_bd_net -net INV_I1_ASIC3_Res [get_bd_ports DIG_ASIC_3_I1] [get_bd_pins INV_I1_ASIC3/Res]
  connect_bd_net -net INV_I1_ASIC4_Res [get_bd_ports DIG_ASIC_4_I1] [get_bd_pins INV_I1_ASIC4/Res]
  connect_bd_net -net INV_I1_ASIC5_Res [get_bd_ports DIG_ASIC_5_I1] [get_bd_pins INV_I1_ASIC5/Res]
  connect_bd_net -net INV_I1_ASIC6_Res [get_bd_ports DIG_ASIC_6_I1] [get_bd_pins INV_I1_ASIC6/Res]
  connect_bd_net -net INV_I1_ASIC7_Res [get_bd_ports DIG_ASIC_7_I1] [get_bd_pins INV_I1_ASIC7/Res]
  connect_bd_net -net INV_I1_ASIC8_Res [get_bd_ports DIG_ASIC_8_I1] [get_bd_pins INV_I1_ASIC8/Res]
  connect_bd_net -net INV_I1_ASIC9_Res [get_bd_ports DIG_ASIC_9_I1] [get_bd_pins INV_I1_ASIC9/Res]
  connect_bd_net -net INV_I4_ASIC10_Res [get_bd_ports DIG_ASIC_10_I4] [get_bd_pins INV_I4_ASIC10/Res]
  connect_bd_net -net INV_I4_ASIC11_Res [get_bd_ports DIG_ASIC_11_I4] [get_bd_pins INV_I4_ASIC11/Res]
  connect_bd_net -net INV_I4_ASIC12_Res [get_bd_ports DIG_ASIC_12_I4] [get_bd_pins INV_I4_ASIC12/Res]
  connect_bd_net -net INV_I4_ASIC1_Res [get_bd_ports DIG_ASIC_1_I4] [get_bd_pins INV_I4_ASIC1/Res]
  connect_bd_net -net INV_I4_ASIC2_Res [get_bd_ports DIG_ASIC_2_I4] [get_bd_pins INV_I4_ASIC2/Res]
  connect_bd_net -net INV_I4_ASIC3_Res [get_bd_ports DIG_ASIC_3_I4] [get_bd_pins INV_I4_ASIC3/Res]
  connect_bd_net -net INV_I4_ASIC4_Res [get_bd_ports DIG_ASIC_4_I4] [get_bd_pins INV_I4_ASIC4/Res]
  connect_bd_net -net INV_I4_ASIC5_Res [get_bd_ports DIG_ASIC_5_I4] [get_bd_pins INV_I4_ASIC5/Res]
  connect_bd_net -net INV_I4_ASIC6_Res [get_bd_ports DIG_ASIC_6_I4] [get_bd_pins INV_I4_ASIC6/Res]
  connect_bd_net -net INV_I4_ASIC7_Res [get_bd_ports DIG_ASIC_7_I4] [get_bd_pins INV_I4_ASIC7/Res]
  connect_bd_net -net INV_I4_ASIC8_Res [get_bd_ports DIG_ASIC_8_I4] [get_bd_pins INV_I4_ASIC8/Res]
  connect_bd_net -net INV_I4_ASIC9_Res [get_bd_ports DIG_ASIC_9_I4] [get_bd_pins INV_I4_ASIC9/Res]
  connect_bd_net -net INV_S0_ASIC10_Res [get_bd_ports DIG_ASIC_10_S0] [get_bd_pins INV_S0_ASIC10/Res]
  connect_bd_net -net INV_S0_ASIC11_Res [get_bd_ports DIG_ASIC_11_S0] [get_bd_pins INV_S0_ASIC11/Res]
  connect_bd_net -net INV_S0_ASIC12_Res [get_bd_ports DIG_ASIC_12_S0] [get_bd_pins INV_S0_ASIC12/Res]
  connect_bd_net -net INV_S0_ASIC1_Res [get_bd_ports DIG_ASIC_1_S0] [get_bd_pins INV_S0_ASIC1/Res]
  connect_bd_net -net INV_S0_ASIC2_Res [get_bd_ports DIG_ASIC_2_S0] [get_bd_pins INV_S0_ASIC2/Res]
  connect_bd_net -net INV_S0_ASIC3_Res [get_bd_ports DIG_ASIC_3_S0] [get_bd_pins INV_S0_ASIC3/Res]
  connect_bd_net -net INV_S0_ASIC4_Res [get_bd_ports DIG_ASIC_4_S0] [get_bd_pins INV_S0_ASIC4/Res]
  connect_bd_net -net INV_S0_ASIC5_Res [get_bd_ports DIG_ASIC_5_S0] [get_bd_pins INV_S0_ASIC5/Res]
  connect_bd_net -net INV_S0_ASIC6_Res [get_bd_ports DIG_ASIC_6_S0] [get_bd_pins INV_S0_ASIC6/Res]
  connect_bd_net -net INV_S0_ASIC7_Res [get_bd_ports DIG_ASIC_7_S0] [get_bd_pins INV_S0_ASIC7/Res]
  connect_bd_net -net INV_S0_ASIC8_Res [get_bd_ports DIG_ASIC_8_S0] [get_bd_pins INV_S0_ASIC8/Res]
  connect_bd_net -net INV_S0_ASIC9_Res [get_bd_ports DIG_ASIC_9_S0] [get_bd_pins INV_S0_ASIC9/Res]
  connect_bd_net -net INV_S2_ASIC10_Res [get_bd_ports DIG_ASIC_10_S2] [get_bd_pins INV_S2_ASIC10/Res]
  connect_bd_net -net INV_S2_ASIC11_Res [get_bd_ports DIG_ASIC_11_S2] [get_bd_pins INV_S2_ASIC11/Res]
  connect_bd_net -net INV_S2_ASIC12_Res [get_bd_ports DIG_ASIC_12_S2] [get_bd_pins INV_S2_ASIC12/Res]
  connect_bd_net -net INV_S2_ASIC1_Res [get_bd_ports DIG_ASIC_1_S2] [get_bd_pins INV_S2_ASIC1/Res]
  connect_bd_net -net INV_S2_ASIC2_Res [get_bd_ports DIG_ASIC_2_S2] [get_bd_pins INV_S2_ASIC2/Res]
  connect_bd_net -net INV_S2_ASIC3_Res [get_bd_ports DIG_ASIC_3_S2] [get_bd_pins INV_S2_ASIC3/Res]
  connect_bd_net -net INV_S2_ASIC4_Res [get_bd_ports DIG_ASIC_4_S2] [get_bd_pins INV_S2_ASIC4/Res]
  connect_bd_net -net INV_S2_ASIC5_Res [get_bd_ports DIG_ASIC_5_S2] [get_bd_pins INV_S2_ASIC5/Res]
  connect_bd_net -net INV_S2_ASIC6_Res [get_bd_ports DIG_ASIC_6_S2] [get_bd_pins INV_S2_ASIC6/Res]
  connect_bd_net -net INV_S2_ASIC7_Res [get_bd_ports DIG_ASIC_7_S2] [get_bd_pins INV_S2_ASIC7/Res]
  connect_bd_net -net INV_S2_ASIC8_Res [get_bd_ports DIG_ASIC_8_S2] [get_bd_pins INV_S2_ASIC8/Res]
  connect_bd_net -net INV_S2_ASIC9_Res [get_bd_ports DIG_ASIC_9_S2] [get_bd_pins INV_S2_ASIC9/Res]
  connect_bd_net -net INV_SI_BUSY_Res [get_bd_ports Si_BUSY_P] [get_bd_pins INV_SI_BUSY/Res]
  connect_bd_net -net INV_SI_HIT_Res [get_bd_ports Si_HIT_P] [get_bd_pins INV_SI_HIT/Res]
  connect_bd_net -net PHY_LEDs [get_bd_pins vio_0/probe_in0] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net PL_pin_K16_1 [get_bd_ports PL_pin_K16] [get_bd_pins SC0720_0/PL_pin_K16]
  connect_bd_net -net PL_pin_K19_1 [get_bd_ports PL_pin_K19] [get_bd_pins SC0720_0/PL_pin_K19]
  connect_bd_net -net PL_pin_M15_1 [get_bd_ports PL_pin_M15] [get_bd_pins SC0720_0/PL_pin_M15]
  connect_bd_net -net PL_pin_N15_1 [get_bd_ports PL_pin_N15] [get_bd_pins SC0720_0/PL_pin_N15]
  connect_bd_net -net PL_pin_P16_1 [get_bd_ports PL_pin_P16] [get_bd_pins SC0720_0/PL_pin_P16]
  connect_bd_net -net PL_pin_P22_1 [get_bd_ports PL_pin_P22] [get_bd_pins SC0720_0/PL_pin_P22]
  connect_bd_net -net SC0720_0_PHY_LED0 [get_bd_pins SC0720_0/PHY_LED0] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net SC0720_0_PHY_LED1 [get_bd_ports eth_phy_led1_green] [get_bd_pins SC0720_0/PHY_LED1] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net SC0720_0_PHY_LED2 [get_bd_pins SC0720_0/PHY_LED2] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net SC0720_0_PL_pin_K20 [get_bd_ports PL_pin_K20] [get_bd_pins SC0720_0/PL_pin_K20]
  connect_bd_net -net SC0720_0_PL_pin_L16 [get_bd_ports PL_pin_L16] [get_bd_pins SC0720_0/PL_pin_L16]
  connect_bd_net -net SC0720_0_PL_pin_N22 [get_bd_ports PL_pin_N22] [get_bd_pins SC0720_0/PL_pin_N22]
  connect_bd_net -net Trig_Ack_P_1 [get_bd_ports Trig_Ack_P] [get_bd_pins vata_460p3_axi_inter_0/trigger_ack] [get_bd_pins vata_460p3_axi_inter_1/trigger_ack] [get_bd_pins vata_460p3_axi_inter_10/trigger_ack] [get_bd_pins vata_460p3_axi_inter_11/trigger_ack] [get_bd_pins vata_460p3_axi_inter_2/trigger_ack] [get_bd_pins vata_460p3_axi_inter_3/trigger_ack] [get_bd_pins vata_460p3_axi_inter_4/trigger_ack] [get_bd_pins vata_460p3_axi_inter_5/trigger_ack] [get_bd_pins vata_460p3_axi_inter_6/trigger_ack] [get_bd_pins vata_460p3_axi_inter_7/trigger_ack] [get_bd_pins vata_460p3_axi_inter_8/trigger_ack] [get_bd_pins vata_460p3_axi_inter_9/trigger_ack]
  connect_bd_net -net Trig_ENA_P_1 [get_bd_ports Trig_ENA_P] [get_bd_pins vata_460p3_axi_inter_0/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_1/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_10/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_11/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_2/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_3/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_4/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_5/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_6/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_7/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_8/fast_or_trigger] [get_bd_pins vata_460p3_axi_inter_9/fast_or_trigger]
  connect_bd_net -net dac121s101_0_spi_mosi [get_bd_pins INV_VTH_CAL_DAC_MOSI/Op1] [get_bd_pins dac121s101_0/spi_mosi]
  connect_bd_net -net dac121s101_0_spi_sclk [get_bd_pins INV_VTH_CAL_DAC_SCLK/Op1] [get_bd_pins dac121s101_0/spi_sclk]
  connect_bd_net -net dac121s101_0_spi_sync [get_bd_pins dac121s101_0/spi_sync] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din] [get_bd_pins xlslice_6/Din] [get_bd_pins xlslice_7/Din]
  connect_bd_net -net local_invert_0_dout [get_bd_ports DIG_A_VTH_CAL_DAC_MOSI_P] [get_bd_ports DIG_B_VTH_CAL_DAC_MOSI_P] [get_bd_pins INV_VTH_CAL_DAC_MOSI/Res]
  connect_bd_net -net local_invert_1_dout [get_bd_ports DIG_A_VTH_CAL_DAC_SCLK_P] [get_bd_ports DIG_B_VTH_CAL_DAC_SCLK_P] [get_bd_pins INV_VTH_CAL_DAC_SCLK/Res]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins AXI_cal_pulse_0/s00_axi_aclk] [get_bd_pins axi_fifo_mm_s_data0/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data1/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data10/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data11/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data2/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data3/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data4/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data5/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data6/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data7/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data8/s_axi_aclk] [get_bd_pins axi_fifo_mm_s_data9/s_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins ps7_0_axi_periph/ACLK] [get_bd_pins ps7_0_axi_periph/M00_ACLK] [get_bd_pins ps7_0_axi_periph/M01_ACLK] [get_bd_pins ps7_0_axi_periph/M02_ACLK] [get_bd_pins ps7_0_axi_periph/M03_ACLK] [get_bd_pins ps7_0_axi_periph/M04_ACLK] [get_bd_pins ps7_0_axi_periph/M05_ACLK] [get_bd_pins ps7_0_axi_periph/M06_ACLK] [get_bd_pins ps7_0_axi_periph/M07_ACLK] [get_bd_pins ps7_0_axi_periph/M08_ACLK] [get_bd_pins ps7_0_axi_periph/M09_ACLK] [get_bd_pins ps7_0_axi_periph/M10_ACLK] [get_bd_pins ps7_0_axi_periph/M11_ACLK] [get_bd_pins ps7_0_axi_periph/M12_ACLK] [get_bd_pins ps7_0_axi_periph/M13_ACLK] [get_bd_pins ps7_0_axi_periph/M14_ACLK] [get_bd_pins ps7_0_axi_periph/M15_ACLK] [get_bd_pins ps7_0_axi_periph/M16_ACLK] [get_bd_pins ps7_0_axi_periph/M17_ACLK] [get_bd_pins ps7_0_axi_periph/M18_ACLK] [get_bd_pins ps7_0_axi_periph/M19_ACLK] [get_bd_pins ps7_0_axi_periph/M20_ACLK] [get_bd_pins ps7_0_axi_periph/M21_ACLK] [get_bd_pins ps7_0_axi_periph/M22_ACLK] [get_bd_pins ps7_0_axi_periph/M23_ACLK] [get_bd_pins ps7_0_axi_periph/M24_ACLK] [get_bd_pins ps7_0_axi_periph/M25_ACLK] [get_bd_pins ps7_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk] [get_bd_pins sync_vata_distn_0/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_0/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_1/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_10/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_11/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_2/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_3/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_4/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_5/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_6/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_7/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_8/s00_axi_aclk] [get_bd_pins vata_460p3_axi_inter_9/s00_axi_aclk] [get_bd_pins vio_0/clk]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins dac121s101_0/s00_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK] [get_bd_pins ps7_0_axi_periph_1/ACLK] [get_bd_pins ps7_0_axi_periph_1/M00_ACLK] [get_bd_pins ps7_0_axi_periph_1/M01_ACLK] [get_bd_pins ps7_0_axi_periph_1/M02_ACLK] [get_bd_pins ps7_0_axi_periph_1/S00_ACLK] [get_bd_pins rst_ps7_0_5M/slowest_sync_clk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in] [get_bd_pins rst_ps7_0_5M/ext_reset_in]
  connect_bd_net -net processing_system7_0_SPI0_MOSI_O [get_bd_pins processing_system7_0/SPI0_MOSI_O] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net processing_system7_0_SPI0_SCLK_O [get_bd_ports DIG_A_TELEM1_SCLK_P] [get_bd_pins processing_system7_0/SPI0_SCLK_O]
  connect_bd_net -net processing_system7_0_SPI0_SS2_O [get_bd_pins processing_system7_0/SPI0_SS2_O] [get_bd_pins util_vector_logic_6/Op1]
  connect_bd_net -net processing_system7_0_SPI0_SS_O [get_bd_ports DIG_A_TELEM1_CSn_P] [get_bd_pins processing_system7_0/SPI0_SS_O]
  connect_bd_net -net processing_system7_0_SPI1_MOSI_O [get_bd_pins processing_system7_0/SPI1_MOSI_O] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net processing_system7_0_SPI1_SCLK_O [get_bd_ports DIG_B_TELEMX_SCLK_P] [get_bd_pins processing_system7_0/SPI1_SCLK_O]
  connect_bd_net -net processing_system7_0_SPI1_SS1_O [get_bd_pins processing_system7_0/SPI1_SS1_O] [get_bd_pins util_vector_logic_3/Op2] [get_bd_pins util_vector_logic_4/Op1]
  connect_bd_net -net processing_system7_0_SPI1_SS2_O [get_bd_pins processing_system7_0/SPI1_SS2_O] [get_bd_pins util_vector_logic_6/Op2]
  connect_bd_net -net processing_system7_0_SPI1_SS_O [get_bd_ports DIG_B_TELEM1_CSn_P] [get_bd_pins processing_system7_0/SPI1_SS_O]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_pins AXI_cal_pulse_0/s00_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data0/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data1/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data10/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data11/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data2/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data3/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data4/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data5/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data6/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data7/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data8/s_axi_aresetn] [get_bd_pins axi_fifo_mm_s_data9/s_axi_aresetn] [get_bd_pins ps7_0_axi_periph/ARESETN] [get_bd_pins ps7_0_axi_periph/M00_ARESETN] [get_bd_pins ps7_0_axi_periph/M01_ARESETN] [get_bd_pins ps7_0_axi_periph/M02_ARESETN] [get_bd_pins ps7_0_axi_periph/M03_ARESETN] [get_bd_pins ps7_0_axi_periph/M04_ARESETN] [get_bd_pins ps7_0_axi_periph/M05_ARESETN] [get_bd_pins ps7_0_axi_periph/M06_ARESETN] [get_bd_pins ps7_0_axi_periph/M07_ARESETN] [get_bd_pins ps7_0_axi_periph/M08_ARESETN] [get_bd_pins ps7_0_axi_periph/M09_ARESETN] [get_bd_pins ps7_0_axi_periph/M10_ARESETN] [get_bd_pins ps7_0_axi_periph/M11_ARESETN] [get_bd_pins ps7_0_axi_periph/M12_ARESETN] [get_bd_pins ps7_0_axi_periph/M13_ARESETN] [get_bd_pins ps7_0_axi_periph/M14_ARESETN] [get_bd_pins ps7_0_axi_periph/M15_ARESETN] [get_bd_pins ps7_0_axi_periph/M16_ARESETN] [get_bd_pins ps7_0_axi_periph/M17_ARESETN] [get_bd_pins ps7_0_axi_periph/M18_ARESETN] [get_bd_pins ps7_0_axi_periph/M19_ARESETN] [get_bd_pins ps7_0_axi_periph/M20_ARESETN] [get_bd_pins ps7_0_axi_periph/M21_ARESETN] [get_bd_pins ps7_0_axi_periph/M22_ARESETN] [get_bd_pins ps7_0_axi_periph/M23_ARESETN] [get_bd_pins ps7_0_axi_periph/M24_ARESETN] [get_bd_pins ps7_0_axi_periph/M25_ARESETN] [get_bd_pins ps7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins sync_vata_distn_0/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_0/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_1/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_10/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_11/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_2/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_3/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_4/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_5/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_6/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_7/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_8/s00_axi_aresetn] [get_bd_pins vata_460p3_axi_inter_9/s00_axi_aresetn]
  connect_bd_net -net rst_ps7_0_5M_peripheral_aresetn [get_bd_pins dac121s101_0/s00_axi_aresetn] [get_bd_pins ps7_0_axi_periph_1/ARESETN] [get_bd_pins ps7_0_axi_periph_1/M00_ARESETN] [get_bd_pins ps7_0_axi_periph_1/M01_ARESETN] [get_bd_pins ps7_0_axi_periph_1/M02_ARESETN] [get_bd_pins ps7_0_axi_periph_1/S00_ARESETN] [get_bd_pins rst_ps7_0_5M/peripheral_aresetn]
  connect_bd_net -net sync_vata_distn_0_FEE_busy [get_bd_pins INV_SI_BUSY/Op1] [get_bd_pins sync_vata_distn_0/FEE_busy]
  connect_bd_net -net sync_vata_distn_0_FEE_sideA_hit [get_bd_pins INV_SI_HIT/Op1] [get_bd_pins sync_vata_distn_0/FEE_sideA_hit]
  connect_bd_net -net sync_vata_distn_0_FEE_sideB_hit [get_bd_ports Si_SPARE_P] [get_bd_pins sync_vata_distn_0/FEE_sideB_hit]
  connect_bd_net -net sync_vata_distn_0_force_trigger [get_bd_pins sync_vata_distn_0/force_trigger] [get_bd_pins vata_460p3_axi_inter_0/force_trigger] [get_bd_pins vata_460p3_axi_inter_1/force_trigger] [get_bd_pins vata_460p3_axi_inter_10/force_trigger] [get_bd_pins vata_460p3_axi_inter_11/force_trigger] [get_bd_pins vata_460p3_axi_inter_2/force_trigger] [get_bd_pins vata_460p3_axi_inter_3/force_trigger] [get_bd_pins vata_460p3_axi_inter_4/force_trigger] [get_bd_pins vata_460p3_axi_inter_5/force_trigger] [get_bd_pins vata_460p3_axi_inter_6/force_trigger] [get_bd_pins vata_460p3_axi_inter_7/force_trigger] [get_bd_pins vata_460p3_axi_inter_8/force_trigger] [get_bd_pins vata_460p3_axi_inter_9/force_trigger]
  connect_bd_net -net sync_vata_distn_0_global_counter [get_bd_pins sync_vata_distn_0/global_counter] [get_bd_pins vata_460p3_axi_inter_0/global_counter] [get_bd_pins vata_460p3_axi_inter_1/global_counter] [get_bd_pins vata_460p3_axi_inter_10/global_counter] [get_bd_pins vata_460p3_axi_inter_11/global_counter] [get_bd_pins vata_460p3_axi_inter_2/global_counter] [get_bd_pins vata_460p3_axi_inter_3/global_counter] [get_bd_pins vata_460p3_axi_inter_4/global_counter] [get_bd_pins vata_460p3_axi_inter_5/global_counter] [get_bd_pins vata_460p3_axi_inter_6/global_counter] [get_bd_pins vata_460p3_axi_inter_7/global_counter] [get_bd_pins vata_460p3_axi_inter_8/global_counter] [get_bd_pins vata_460p3_axi_inter_9/global_counter]
  connect_bd_net -net sync_vata_distn_0_global_counter_rst [get_bd_pins sync_vata_distn_0/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_0/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_1/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_10/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_11/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_2/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_3/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_4/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_5/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_6/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_7/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_8/global_counter_rst] [get_bd_pins vata_460p3_axi_inter_9/global_counter_rst]
  connect_bd_net -net sync_vata_distn_0_vata_hits [get_bd_pins sync_vata_distn_0/vata_hits] [get_bd_pins vata_460p3_axi_inter_0/vata_hits] [get_bd_pins vata_460p3_axi_inter_1/vata_hits] [get_bd_pins vata_460p3_axi_inter_10/vata_hits] [get_bd_pins vata_460p3_axi_inter_11/vata_hits] [get_bd_pins vata_460p3_axi_inter_2/vata_hits] [get_bd_pins vata_460p3_axi_inter_3/vata_hits] [get_bd_pins vata_460p3_axi_inter_4/vata_hits] [get_bd_pins vata_460p3_axi_inter_5/vata_hits] [get_bd_pins vata_460p3_axi_inter_6/vata_hits] [get_bd_pins vata_460p3_axi_inter_7/vata_hits] [get_bd_pins vata_460p3_axi_inter_8/vata_hits] [get_bd_pins vata_460p3_axi_inter_9/vata_hits]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins processing_system7_0/SPI0_MISO_I] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_ports DIG_A_TELEMX_MOSI_P] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_ports DIG_B_TELEMX_MOSI_P] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net util_vector_logic_3_Res [get_bd_pins processing_system7_0/SPI1_MISO_I] [get_bd_pins util_vector_logic_3/Res]
  connect_bd_net -net util_vector_logic_4_Res [get_bd_ports DIG_B_TELEM2_CSn_P] [get_bd_pins util_vector_logic_4/Res]
  connect_bd_net -net util_vector_logic_5_Res [get_bd_ports DIG_A_TELEM2_CSn_P] [get_bd_pins util_vector_logic_5/Res]
  connect_bd_net -net util_vector_logic_6_Res [get_bd_ports eth_phy_led0_yellow] [get_bd_pins util_vector_logic_6/Res]
  connect_bd_net -net vata_460p3_axi_inter_0_FEE_ready [get_bd_ports Si_RDY_P] [get_bd_pins sync_vata_distn_0/FEE_ready]
  connect_bd_net -net vata_460p3_axi_inter_0_cald [get_bd_pins INV_CALD_ASIC1/Op1] [get_bd_pins vata_460p3_axi_inter_0/cald]
  connect_bd_net -net vata_460p3_axi_inter_0_caldb [get_bd_ports DIG_ASIC_1_CALDB] [get_bd_pins vata_460p3_axi_inter_0/caldb]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy00] [get_bd_pins vata_460p3_axi_inter_0/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_i1 [get_bd_pins INV_I1_ASIC1/Op1] [get_bd_pins vata_460p3_axi_inter_0/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_i3 [get_bd_ports DIG_ASIC_1_I3] [get_bd_pins vata_460p3_axi_inter_0/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_i4 [get_bd_pins INV_I4_ASIC1/Op1] [get_bd_pins vata_460p3_axi_inter_0/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_s0 [get_bd_pins INV_S0_ASIC1/Op1] [get_bd_pins vata_460p3_axi_inter_0/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_s1 [get_bd_ports DIG_ASIC_1_S1] [get_bd_pins vata_460p3_axi_inter_0/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_s2 [get_bd_pins INV_S2_ASIC1/Op1] [get_bd_pins vata_460p3_axi_inter_0/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_0_vata_s_latch [get_bd_ports DIG_ASIC_1_S_LATCH] [get_bd_pins vata_460p3_axi_inter_0/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_10_cald [get_bd_pins INV_CALD_ASIC10/Op1] [get_bd_pins vata_460p3_axi_inter_10/cald]
  connect_bd_net -net vata_460p3_axi_inter_10_caldb [get_bd_ports DIG_ASIC_11_CALDB] [get_bd_pins vata_460p3_axi_inter_10/caldb]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy10] [get_bd_pins vata_460p3_axi_inter_10/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_i1 [get_bd_pins INV_I1_ASIC11/Op1] [get_bd_pins vata_460p3_axi_inter_10/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_i3 [get_bd_ports DIG_ASIC_11_I3] [get_bd_pins vata_460p3_axi_inter_10/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_i4 [get_bd_pins INV_I4_ASIC11/Op1] [get_bd_pins vata_460p3_axi_inter_10/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_s0 [get_bd_pins INV_S0_ASIC11/Op1] [get_bd_pins vata_460p3_axi_inter_10/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_s1 [get_bd_ports DIG_ASIC_11_S1] [get_bd_pins vata_460p3_axi_inter_10/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_s2 [get_bd_pins INV_S2_ASIC11/Op1] [get_bd_pins vata_460p3_axi_inter_10/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_10_vata_s_latch [get_bd_ports DIG_ASIC_11_S_LATCH] [get_bd_pins vata_460p3_axi_inter_10/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy11] [get_bd_pins vata_460p3_axi_inter_11/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_i1 [get_bd_pins INV_I1_ASIC12/Op1] [get_bd_pins vata_460p3_axi_inter_11/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_i3 [get_bd_ports DIG_ASIC_12_I3] [get_bd_pins vata_460p3_axi_inter_11/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_i4 [get_bd_pins INV_I4_ASIC12/Op1] [get_bd_pins vata_460p3_axi_inter_11/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_s0 [get_bd_pins INV_S0_ASIC12/Op1] [get_bd_pins vata_460p3_axi_inter_11/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_s1 [get_bd_ports DIG_ASIC_12_S1] [get_bd_pins vata_460p3_axi_inter_11/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_s2 [get_bd_pins INV_S2_ASIC12/Op1] [get_bd_pins vata_460p3_axi_inter_11/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_11_vata_s_latch [get_bd_ports DIG_ASIC_12_S_LATCH] [get_bd_pins vata_460p3_axi_inter_11/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy01] [get_bd_pins vata_460p3_axi_inter_1/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_i1 [get_bd_pins INV_I1_ASIC2/Op1] [get_bd_pins vata_460p3_axi_inter_1/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_i3 [get_bd_ports DIG_ASIC_2_I3] [get_bd_pins vata_460p3_axi_inter_1/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_i4 [get_bd_pins INV_I4_ASIC2/Op1] [get_bd_pins vata_460p3_axi_inter_1/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_s0 [get_bd_pins INV_S0_ASIC2/Op1] [get_bd_pins vata_460p3_axi_inter_1/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_s1 [get_bd_ports DIG_ASIC_2_S1] [get_bd_pins vata_460p3_axi_inter_1/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_s2 [get_bd_pins INV_S2_ASIC2/Op1] [get_bd_pins vata_460p3_axi_inter_1/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_1_vata_s_latch [get_bd_ports DIG_ASIC_2_S_LATCH] [get_bd_pins vata_460p3_axi_inter_1/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_2_cald [get_bd_pins INV_CALD_ASIC3/Op1] [get_bd_pins vata_460p3_axi_inter_2/cald]
  connect_bd_net -net vata_460p3_axi_inter_2_caldb [get_bd_ports DIG_ASIC_3_CALDB] [get_bd_pins vata_460p3_axi_inter_2/caldb]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy02] [get_bd_pins vata_460p3_axi_inter_2/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_i1 [get_bd_pins INV_I1_ASIC3/Op1] [get_bd_pins vata_460p3_axi_inter_2/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_i3 [get_bd_ports DIG_ASIC_3_I3] [get_bd_pins vata_460p3_axi_inter_2/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_i4 [get_bd_pins INV_I4_ASIC3/Op1] [get_bd_pins vata_460p3_axi_inter_2/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_s0 [get_bd_pins INV_S0_ASIC3/Op1] [get_bd_pins vata_460p3_axi_inter_2/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_s1 [get_bd_ports DIG_ASIC_3_S1] [get_bd_pins vata_460p3_axi_inter_2/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_s2 [get_bd_pins INV_S2_ASIC3/Op1] [get_bd_pins vata_460p3_axi_inter_2/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_2_vata_s_latch [get_bd_ports DIG_ASIC_3_S_LATCH] [get_bd_pins vata_460p3_axi_inter_2/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy03] [get_bd_pins vata_460p3_axi_inter_3/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_i1 [get_bd_pins INV_I1_ASIC4/Op1] [get_bd_pins vata_460p3_axi_inter_3/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_i3 [get_bd_ports DIG_ASIC_4_I3] [get_bd_pins vata_460p3_axi_inter_3/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_i4 [get_bd_pins INV_I4_ASIC4/Op1] [get_bd_pins vata_460p3_axi_inter_3/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_s0 [get_bd_pins INV_S0_ASIC4/Op1] [get_bd_pins vata_460p3_axi_inter_3/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_s1 [get_bd_ports DIG_ASIC_4_S1] [get_bd_pins vata_460p3_axi_inter_3/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_s2 [get_bd_pins INV_S2_ASIC4/Op1] [get_bd_pins vata_460p3_axi_inter_3/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_3_vata_s_latch [get_bd_ports DIG_ASIC_4_S_LATCH] [get_bd_pins vata_460p3_axi_inter_3/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_4_cald [get_bd_pins INV_CALD_ASIC5/Op1] [get_bd_pins vata_460p3_axi_inter_4/cald]
  connect_bd_net -net vata_460p3_axi_inter_4_caldb [get_bd_ports DIG_ASIC_5_CALDB] [get_bd_pins vata_460p3_axi_inter_4/caldb]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy04] [get_bd_pins vata_460p3_axi_inter_4/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_i1 [get_bd_pins INV_I1_ASIC5/Op1] [get_bd_pins vata_460p3_axi_inter_4/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_i3 [get_bd_ports DIG_ASIC_5_I3] [get_bd_pins vata_460p3_axi_inter_4/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_i4 [get_bd_pins INV_I4_ASIC5/Op1] [get_bd_pins vata_460p3_axi_inter_4/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_s0 [get_bd_pins INV_S0_ASIC5/Op1] [get_bd_pins vata_460p3_axi_inter_4/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_s1 [get_bd_ports DIG_ASIC_5_S1] [get_bd_pins vata_460p3_axi_inter_4/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_s2 [get_bd_pins INV_S2_ASIC5/Op1] [get_bd_pins vata_460p3_axi_inter_4/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_4_vata_s_latch [get_bd_ports DIG_ASIC_5_S_LATCH] [get_bd_pins vata_460p3_axi_inter_4/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy05] [get_bd_pins vata_460p3_axi_inter_5/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_i1 [get_bd_pins INV_I1_ASIC6/Op1] [get_bd_pins vata_460p3_axi_inter_5/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_i3 [get_bd_ports DIG_ASIC_6_I3] [get_bd_pins vata_460p3_axi_inter_5/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_i4 [get_bd_pins INV_I4_ASIC6/Op1] [get_bd_pins vata_460p3_axi_inter_5/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_s0 [get_bd_pins INV_S0_ASIC6/Op1] [get_bd_pins vata_460p3_axi_inter_5/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_s1 [get_bd_ports DIG_ASIC_6_S1] [get_bd_pins vata_460p3_axi_inter_5/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_s2 [get_bd_pins INV_S2_ASIC6/Op1] [get_bd_pins vata_460p3_axi_inter_5/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_5_vata_s_latch [get_bd_ports DIG_ASIC_6_S_LATCH] [get_bd_pins vata_460p3_axi_inter_5/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_6_cald [get_bd_pins INV_CALD_ASIC7/Op1] [get_bd_pins vata_460p3_axi_inter_6/cald]
  connect_bd_net -net vata_460p3_axi_inter_6_caldb [get_bd_ports DIG_ASIC_7_CALDB] [get_bd_pins vata_460p3_axi_inter_6/caldb]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy06] [get_bd_pins vata_460p3_axi_inter_6/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_i1 [get_bd_pins INV_I1_ASIC7/Op1] [get_bd_pins vata_460p3_axi_inter_6/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_i3 [get_bd_ports DIG_ASIC_7_I3] [get_bd_pins vata_460p3_axi_inter_6/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_i4 [get_bd_pins INV_I4_ASIC7/Op1] [get_bd_pins vata_460p3_axi_inter_6/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_s0 [get_bd_pins INV_S0_ASIC7/Op1] [get_bd_pins vata_460p3_axi_inter_6/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_s1 [get_bd_ports DIG_ASIC_7_S1] [get_bd_pins vata_460p3_axi_inter_6/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_s2 [get_bd_pins INV_S2_ASIC7/Op1] [get_bd_pins vata_460p3_axi_inter_6/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_6_vata_s_latch [get_bd_ports DIG_ASIC_7_S_LATCH] [get_bd_pins vata_460p3_axi_inter_6/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy07] [get_bd_pins vata_460p3_axi_inter_7/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_i1 [get_bd_pins INV_I1_ASIC8/Op1] [get_bd_pins vata_460p3_axi_inter_7/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_i3 [get_bd_ports DIG_ASIC_8_I3] [get_bd_pins vata_460p3_axi_inter_7/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_i4 [get_bd_pins INV_I4_ASIC8/Op1] [get_bd_pins vata_460p3_axi_inter_7/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_s0 [get_bd_pins INV_S0_ASIC8/Op1] [get_bd_pins vata_460p3_axi_inter_7/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_s1 [get_bd_ports DIG_ASIC_8_S1] [get_bd_pins vata_460p3_axi_inter_7/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_s2 [get_bd_pins INV_S2_ASIC8/Op1] [get_bd_pins vata_460p3_axi_inter_7/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_7_vata_s_latch [get_bd_ports DIG_ASIC_8_S_LATCH] [get_bd_pins vata_460p3_axi_inter_7/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_8_cald [get_bd_pins INV_CALD_ASIC9/Op1] [get_bd_pins vata_460p3_axi_inter_8/cald]
  connect_bd_net -net vata_460p3_axi_inter_8_caldb [get_bd_ports DIG_ASIC_9_CALDB] [get_bd_pins vata_460p3_axi_inter_8/caldb]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy08] [get_bd_pins vata_460p3_axi_inter_8/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_i1 [get_bd_pins INV_I1_ASIC9/Op1] [get_bd_pins vata_460p3_axi_inter_8/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_i3 [get_bd_ports DIG_ASIC_9_I3] [get_bd_pins vata_460p3_axi_inter_8/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_i4 [get_bd_pins INV_I4_ASIC9/Op1] [get_bd_pins vata_460p3_axi_inter_8/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_s0 [get_bd_pins INV_S0_ASIC9/Op1] [get_bd_pins vata_460p3_axi_inter_8/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_s1 [get_bd_ports DIG_ASIC_9_S1] [get_bd_pins vata_460p3_axi_inter_8/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_s2 [get_bd_pins INV_S2_ASIC9/Op1] [get_bd_pins vata_460p3_axi_inter_8/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_8_vata_s_latch [get_bd_ports DIG_ASIC_9_S_LATCH] [get_bd_pins vata_460p3_axi_inter_8/vata_s_latch]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_hit_busy [get_bd_pins sync_vata_distn_0/vata_hit_busy09] [get_bd_pins vata_460p3_axi_inter_9/vata_hit_busy]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_i1 [get_bd_pins INV_I1_ASIC10/Op1] [get_bd_pins vata_460p3_axi_inter_9/vata_i1]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_i3 [get_bd_ports DIG_ASIC_10_I3] [get_bd_pins vata_460p3_axi_inter_9/vata_i3]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_i4 [get_bd_pins INV_I4_ASIC10/Op1] [get_bd_pins vata_460p3_axi_inter_9/vata_i4]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_s0 [get_bd_pins INV_S0_ASIC10/Op1] [get_bd_pins vata_460p3_axi_inter_9/vata_s0]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_s1 [get_bd_ports DIG_ASIC_10_S1] [get_bd_pins vata_460p3_axi_inter_9/vata_s1]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_s2 [get_bd_pins INV_S2_ASIC10/Op1] [get_bd_pins vata_460p3_axi_inter_9/vata_s2]
  connect_bd_net -net vata_460p3_axi_inter_9_vata_s_latch [get_bd_ports DIG_ASIC_10_S_LATCH] [get_bd_pins vata_460p3_axi_inter_9/vata_s_latch]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins processing_system7_0/SPI0_MOSI_I] [get_bd_pins processing_system7_0/SPI0_SS_I] [get_bd_pins processing_system7_0/SPI1_MOSI_I] [get_bd_pins processing_system7_0/SPI1_SS_I] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins processing_system7_0/SPI0_SS1_O] [get_bd_pins util_vector_logic_0/Op2] [get_bd_pins util_vector_logic_5/Op1]
  connect_bd_net -net xlslice_4_Dout [get_bd_ports DIG_A_CAL_DAC_SYNCn_P] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net xlslice_5_Dout [get_bd_ports DIG_A_VTH_DAC_SYNCn_P] [get_bd_pins xlslice_5/Dout]
  connect_bd_net -net xlslice_6_Dout [get_bd_ports DIG_B_CAL_DAC_SYNCn_P] [get_bd_pins xlslice_6/Dout]
  connect_bd_net -net xlslice_7_Dout [get_bd_ports DIG_B_VTH_DAC_SYNCn_P] [get_bd_pins xlslice_7/Dout]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x43C20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs AXI_cal_pulse_0/S00_AXI/S00_AXI_reg] SEG_AXI_cal_pulse_0_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data0/S_AXI/Mem0] SEG_axi_fifo_mm_s_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D50000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data10/S_AXI/Mem0] SEG_axi_fifo_mm_s_data10_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D80000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data11/S_AXI/Mem0] SEG_axi_fifo_mm_s_data11_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C40000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data1/S_AXI/Mem0] SEG_axi_fifo_mm_s_data1_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C60000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data2/S_AXI/Mem0] SEG_axi_fifo_mm_s_data2_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C80000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data3/S_AXI/Mem0] SEG_axi_fifo_mm_s_data3_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CA0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data4/S_AXI/Mem0] SEG_axi_fifo_mm_s_data4_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CC0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data5/S_AXI/Mem0] SEG_axi_fifo_mm_s_data5_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CE0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data6/S_AXI/Mem0] SEG_axi_fifo_mm_s_data6_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data7/S_AXI/Mem0] SEG_axi_fifo_mm_s_data7_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data8/S_AXI/Mem0] SEG_axi_fifo_mm_s_data8_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D40000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_fifo_mm_s_data9/S_AXI/Mem0] SEG_axi_fifo_mm_s_data9_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x83C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs dac121s101_0/S00_AXI/S00_AXI_reg] SEG_dac121s101_0_S00_AXI_REG
  create_bd_addr_seg -range 0x00010000 -offset 0x43D90000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs sync_vata_distn_0/S00_AXI/S00_AXI_reg] SEG_sync_vata_distn_0_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_0/s00_axi/reg0] SEG_vata_460p3_axi_inter_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D60000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_10/s00_axi/reg0] SEG_vata_460p3_axi_inter_10_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D70000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_11/s00_axi/reg0] SEG_vata_460p3_axi_inter_11_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C30000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_1/s00_axi/reg0] SEG_vata_460p3_axi_inter_1_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C50000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_2/s00_axi/reg0] SEG_vata_460p3_axi_inter_2_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C70000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_3/s00_axi/reg0] SEG_vata_460p3_axi_inter_3_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43C90000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_4/s00_axi/reg0] SEG_vata_460p3_axi_inter_4_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CB0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_5/s00_axi/reg0] SEG_vata_460p3_axi_inter_5_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CD0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_6/s00_axi/reg0] SEG_vata_460p3_axi_inter_6_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43CF0000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_7/s00_axi/reg0] SEG_vata_460p3_axi_inter_7_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_8/s00_axi/reg0] SEG_vata_460p3_axi_inter_8_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x43D30000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs vata_460p3_axi_inter_9/s00_axi/reg0] SEG_vata_460p3_axi_inter_9_reg0


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


