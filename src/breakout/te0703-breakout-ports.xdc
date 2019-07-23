# P1 split between CPLD and FPGA, don't use.

set_property PACKAGE_PIN U4   [get_ports P2_DIG_VSS_SHDN]
set_property PACKAGE_PIN T4   [get_ports P2_TELEM1_CSn]
set_property PACKAGE_PIN V8   [get_ports P2_TELEM1_MOSI]
set_property PACKAGE_PIN AB9  [get_ports P2_TELEM1_MISO]
set_property PACKAGE_PIN AB10 [get_ports P2_TELEM1_SCLK]
set_property PACKAGE_PIN W10  [get_ports P2_DIG_CAL_DAC_SYNCn]
set_property PACKAGE_PIN AA8  [get_ports P2_DIG_CAL_DAC_SCLK]
set_property PACKAGE_PIN AA9  [get_ports P2_DIG_CAL_DAC_MOSI]
set_property PACKAGE_PIN AB11 [get_ports P2_DIG_CAL_PULSE_TRIGGER]
set_property PACKAGE_PIN AA11 [get_ports P2_i3_GALAO]
set_property PACKAGE_PIN AB12 [get_ports P2_i4_GALAO]
set_property PACKAGE_PIN AA12 [get_ports P2_caldb_GALAO]
set_property PACKAGE_PIN AB16 [get_ports P2_cald_GALAO]
set_property PACKAGE_PIN AA16 [get_ports P2_o5_GALAO]
set_property PACKAGE_PIN AB17 [get_ports P2_s2_GALAO]
set_property PACKAGE_PIN AA17 [get_ports P2_i1_GALAO]
set_property PACKAGE_PIN AA18 [get_ports P2_s1_GALAO]
set_property PACKAGE_PIN Y18  [get_ports P2_s0_GALAO]
set_property PACKAGE_PIN AB21 [get_ports P2_s_latch_GALAO]
set_property PACKAGE_PIN AA21 [get_ports P2_ASIC_TRIGGER_OUT]

set_property IOSTANDARD LVCMOS33 [get_ports P2_i1_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_i3_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_i4_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_o5_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_s0_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_s1_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_s2_GALAO]
set_property IOSTANDARD LVCMOS33 [get_ports P2_s_latch_GALAO]

#set_property PACKAGE_PIN Y10  [get_ports P3-DIG-VSS-SHDN]
#set_property PACKAGE_PIN V7   [get_ports P3-TELEM1-CSn]
#set_property PACKAGE_PIN W7   [get_ports P3-TELEM1-MOSI]
#set_property PACKAGE_PIN R6   [get_ports P3-TELEM1-MISO]
#set_property PACKAGE_PIN T6   [get_ports P3-TELEM1-SCLK]
#set_property PACKAGE_PIN Y4   [get_ports P3-DIG-CAL-DAC-SYNCn]
#set_property PACKAGE_PIN AA4  [get_ports P3-DIG-CAL-DAC-SCLK]
#set_property PACKAGE_PIN V4   [get_ports P3-DIG-CAL-DAC-MOSI]
#set_property PACKAGE_PIN AB1  [get_ports P3-DIG-CAL-PULSE-TRIGGER]
#set_property PACKAGE_PIN V5   [get_ports P3-i3-GALAO]
#set_property PACKAGE_PIN AB2  [get_ports P3-i4-GALAO]
#set_property PACKAGE_PIN U5   [get_ports P3-caldb-GALAO]
#set_property PACKAGE_PIN AB4  [get_ports P3-cald-GALAO]
#set_property PACKAGE_PIN U6   [get_ports P3-o5-GALAO]
#set_property PACKAGE_PIN AB5  [get_ports P3-s2-GALAO]
#set_property PACKAGE_PIN W5   [get_ports P3-i1-GALAO]
#set_property PACKAGE_PIN AB6  [get_ports P3-s1-GALAO]
#set_property PACKAGE_PIN W6   [get_ports P3-s0-GALAO]
#set_property PACKAGE_PIN AB7  [get_ports P3-s-latch-GALAO]
#set_property PACKAGE_PIN W8   [get_ports P3-ASIC-TRIGGER-OUT]

#set_property PACKAGE_PIN P21  [get_ports P4-DIG-VSS-SHDN]
#set_property PACKAGE_PIN K15  [get_ports P4-TELEM1-CSn]
#set_property PACKAGE_PIN T19  [get_ports P4-TELEM1-MOSI]
#set_property PACKAGE_PIN P20  [get_ports P4-TELEM1-MISO]
#set_property PACKAGE_PIN J15  [get_ports P4-TELEM1-SCLK]
#set_property PACKAGE_PIN R19  [get_ports P4-DIG-CAL-DAC-SYNCn]
#set_property PACKAGE_PIN N17  [get_ports P4-DIG-CAL-DAC-SCLK]
#set_property PACKAGE_PIN J18  [get_ports P4-DIG-CAL-DAC-MOSI]
#set_property PACKAGE_PIN J16  [get_ports P4-DIG-CAL-PULSE-TRIGGER]
#set_property PACKAGE_PIN N18  [get_ports P4-i3-GALAO]
#set_property PACKAGE_PIN K18  [get_ports P4-i4-GALAO]
#set_property PACKAGE_PIN J17  [get_ports P4-caldb-GALAO]
#set_property PACKAGE_PIN L18  [get_ports P4-cald-GALAO]
#set_property PACKAGE_PIN L17  [get_ports P4-o5-GALAO]
#set_property PACKAGE_PIN J21  [get_ports P4-s2-GALAO]
#set_property PACKAGE_PIN L19  [get_ports P4-i1-GALAO]
#set_property PACKAGE_PIN M17  [get_ports P4-s1-GALAO]
#set_property PACKAGE_PIN J22  [get_ports P4-s0-GALAO]
#set_property PACKAGE_PIN C22  [get_ports P4-s-latch-GALAO]
#set_property PACKAGE_PIN A19  [get_ports P4-ASIC-TRIGGER-OUT]

#set_property PACKAGE_PIN G22  [get_ports P5-DIG-VSS-SHDN]
#set_property PACKAGE_PIN D22  [get_ports P5-TELEM1-CSn]
#set_property PACKAGE_PIN A18  [get_ports P5-TELEM1-MOSI]
#set_property PACKAGE_PIN A17  [get_ports P5-TELEM1-MISO]
#set_property PACKAGE_PIN H22  [get_ports P5-TELEM1-SCLK]
#set_property PACKAGE_PIN B22  [get_ports P5-DIG-CAL-DAC-SYNCn]
#set_property PACKAGE_PIN A16  [get_ports P5-DIG-CAL-DAC-SCLK]
#set_property PACKAGE_PIN A22  [get_ports P5-DIG-CAL-DAC-MOSI]
#set_property PACKAGE_PIN B21  [get_ports P5-DIG-CAL-PULSE-TRIGGER]
#set_property PACKAGE_PIN B15  [get_ports P5-i3-GALAO]
#set_property PACKAGE_PIN G21  [get_ports P5-i4-GALAO]
#set_property PACKAGE_PIN C15  [get_ports P5-caldb-GALAO]
#set_property PACKAGE_PIN D21  [get_ports P5-cald-GALAO]
#set_property PACKAGE_PIN E21  [get_ports P5-o5-GALAO]
#set_property PACKAGE_PIN B16  [get_ports P5-s2-GALAO]
#set_property PACKAGE_PIN B20  [get_ports P5-i1-GALAO]
#set_property PACKAGE_PIN B19  [get_ports P5-s1-GALAO]
#set_property PACKAGE_PIN C18  [get_ports P5-s0-GALAO]
#set_property PACKAGE_PIN C20  [get_ports P5-s-latch-GALAO]
#set_property PACKAGE_PIN D20  [get_ports P5-ASIC-TRIGGER-OUT]

#set_property PACKAGE_PIN C17  [get_ports P6-DIG-VSS-SHDN]
#set_property PACKAGE_PIN C19  [get_ports P6-TELEM1-CSn]
#set_property PACKAGE_PIN F22  [get_ports P6-TELEM1-MOSI]
#set_property PACKAGE_PIN D18  [get_ports P6-TELEM1-MISO]
#set_property PACKAGE_PIN F21  [get_ports P6-TELEM1-SCLK]
#set_property PACKAGE_PIN H20  [get_ports P6-DIG-CAL-DAC-SYNCn]
#set_property PACKAGE_PIN E18  [get_ports P6-DIG-CAL-DAC-SCLK]
#set_property PACKAGE_PIN H19  [get_ports P6-DIG-CAL-DAC-MOSI]
#set_property PACKAGE_PIN F18  [get_ports P6-DIG-CAL-PULSE-TRIGGER]
#set_property PACKAGE_PIN F17  [get_ports P6-i3-GALAO]
#set_property PACKAGE_PIN G17  [get_ports P6-i4-GALAO]
#set_property PACKAGE_PIN E16  [get_ports P6-caldb-GALAO]
#set_property PACKAGE_PIN F16  [get_ports P6-cald-GALAO]
#set_property PACKAGE_PIN E15  [get_ports P6-o5-GALAO]
#set_property PACKAGE_PIN D15  [get_ports P6-s2-GALAO]
#set_property PACKAGE_PIN G19  [get_ports P6-i1-GALAO]
#set_property PACKAGE_PIN F19  [get_ports P6-s1-GALAO]
#set_property PACKAGE_PIN G15  [get_ports P6-s0-GALAO]
#set_property PACKAGE_PIN G16  [get_ports P6-s-latch-GALAO]
#set_property PACKAGE_PIN E19  [get_ports P6-ASIC-TRIGGER-OUT]
