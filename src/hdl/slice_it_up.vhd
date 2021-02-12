library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slice_it_up is
    port (
        gpio1_1 : in std_logic_vector(31 downto 0);
        gpio1_2 : in std_logic_vector(31 downto 0);
        gpio2_1 : in std_logic_vector(31 downto 0);
        gpio2_2 : in std_logic_vector(31 downto 0);
        gpio3_1 : in std_logic_vector(31 downto 0);
        DIG_ASIC_1_S0 : out std_logic;
        DIG_ASIC_1_S1 : out std_logic;
        DIG_ASIC_1_S2 : out std_logic;
        DIG_ASIC_1_S_LATCH : out std_logic;
        DIG_ASIC_1_I1 : out std_logic;
        DIG_ASIC_1_I3 : out std_logic;
        DIG_ASIC_1_I4 : out std_logic;
        DIG_ASIC_2_S0 : out std_logic;
        DIG_ASIC_2_S1 : out std_logic;
        DIG_ASIC_2_S2 : out std_logic;
        DIG_ASIC_2_S_LATCH : out std_logic;
        DIG_ASIC_2_I1 : out std_logic;
        DIG_ASIC_2_I3 : out std_logic;
        DIG_ASIC_2_I4 : out std_logic;
        DIG_ASIC_1_CALD : out std_logic;
        DIG_ASIC_1_CALDB : out std_logic;
        DIG_ASIC_1_OUT_5 : out std_logic;
        DIG_ASIC_1_OUT_6 : out std_logic;
        DIG_ASIC_2_OUT_5 : out std_logic;
        DIG_ASIC_2_OUT_6 : out std_logic;
        DIG_ASIC_3_S0 : out std_logic;
        DIG_ASIC_3_S1 : out std_logic;
        DIG_ASIC_3_S2 : out std_logic;
        DIG_ASIC_3_S_LATCH : out std_logic;
        DIG_ASIC_3_I1 : out std_logic;
        DIG_ASIC_3_I3 : out std_logic;
        DIG_ASIC_3_I4 : out std_logic;
        DIG_ASIC_4_S0 : out std_logic;
        DIG_ASIC_4_S1 : out std_logic;
        DIG_ASIC_4_S2 : out std_logic;
        DIG_ASIC_4_S_LATCH : out std_logic;
        DIG_ASIC_4_I1 : out std_logic;
        DIG_ASIC_4_I3 : out std_logic;
        DIG_ASIC_4_I4 : out std_logic;
        DIG_ASIC_3_CALD : out std_logic;
        DIG_ASIC_3_CALDB : out std_logic;
        DIG_ASIC_3_OUT_5 : out std_logic;
        DIG_ASIC_3_OUT_6 : out std_logic;
        DIG_ASIC_4_OUT_5 : out std_logic;
        DIG_ASIC_4_OUT_6 : out std_logic;
        DIG_ASIC_5_S0 : out std_logic;
        DIG_ASIC_5_S1 : out std_logic;
        DIG_ASIC_5_S2 : out std_logic;
        DIG_ASIC_5_S_LATCH : out std_logic;
        DIG_ASIC_5_I1 : out std_logic;
        DIG_ASIC_5_I3 : out std_logic;
        DIG_ASIC_5_I4 : out std_logic;
        DIG_ASIC_6_S0 : out std_logic;
        DIG_ASIC_6_S1 : out std_logic;
        DIG_ASIC_6_S2 : out std_logic;
        DIG_ASIC_6_S_LATCH : out std_logic;
        DIG_ASIC_6_I1 : out std_logic;
        DIG_ASIC_6_I3 : out std_logic;
        DIG_ASIC_6_I4 : out std_logic;
        DIG_ASIC_5_CALD : out std_logic;
        DIG_ASIC_5_CALDB : out std_logic;
        DIG_ASIC_5_OUT_5 : out std_logic;
        DIG_ASIC_5_OUT_6 : out std_logic;
        DIG_ASIC_6_OUT_5 : out std_logic;
        DIG_ASIC_6_OUT_6 : out std_logic;
        DIG_ASIC_7_S0 : out std_logic;
        DIG_ASIC_7_S1 : out std_logic;
        DIG_ASIC_7_S2 : out std_logic;
        DIG_ASIC_7_S_LATCH : out std_logic;
        DIG_ASIC_7_I1 : out std_logic;
        DIG_ASIC_7_I3 : out std_logic;
        DIG_ASIC_7_I4 : out std_logic;
        DIG_ASIC_8_S0 : out std_logic;
        DIG_ASIC_8_S1 : out std_logic;
        DIG_ASIC_8_S2 : out std_logic;
        DIG_ASIC_8_S_LATCH : out std_logic;
        DIG_ASIC_8_I1 : out std_logic;
        DIG_ASIC_8_I3 : out std_logic;
        DIG_ASIC_8_I4 : out std_logic;
        DIG_ASIC_7_CALD : out std_logic;
        DIG_ASIC_7_CALDB : out std_logic;
        DIG_ASIC_7_OUT_5 : out std_logic;
        DIG_ASIC_7_OUT_6 : out std_logic;
        DIG_ASIC_8_OUT_5 : out std_logic;
        DIG_ASIC_8_OUT_6 : out std_logic;
        DIG_A_VTH_CAL_DAC_MOSI_P : out std_logic;
        DIG_A_CAL_DAC_SYNCn_P : out std_logic;
        DIG_A_VTH_CAL_DAC_SCLK_P : out std_logic;
        DIG_A_CAL_PULSE_TRIGGER_P : out std_logic;
        DIG_A_VTH_DAC_SYNCn_P : out std_logic;
        DIG_A_TELEMX_MISO_P : out std_logic;
        PPS : out std_logic;
        DIG_A_TELEMX_MOSI_P : out std_logic;
        EXTCLK : out std_logic;
        DIG_A_TELEM1_SCLK_P : out std_logic;
        DIG_A_TELEM1_CSn_P : out std_logic;
        DIG_A_TELEM2_CSn_P : out std_logic;
        DIG_B_TELEMX_MISO_P : out std_logic;
        DIG_B_TELEMX_MOSI_P : out std_logic;
        DIG_B_TELEMX_SCLK_P : out std_logic;
        DIG_B_TELEM1_CSn_P : out std_logic;
        DIG_B_TELEM2_CSn_P : out std_logic;
        DIG_B_CAL_PULSE_TRIGGER_P : out std_logic;
        DIG_B_VTH_CAL_DAC_MOSI_P : out std_logic;
        DIG_B_VTH_CAL_DAC_SCLK_P : out std_logic;
        DIG_B_CAL_DAC_SYNCn_P : out std_logic;
        DIG_B_VTH_DAC_SYNCn_P : out std_logic;
        DIG_ASIC_9_S0 : out std_logic;
        DIG_ASIC_9_S1 : out std_logic;
        DIG_ASIC_9_S2 : out std_logic;
        DIG_ASIC_9_S_LATCH : out std_logic;
        DIG_ASIC_9_I1 : out std_logic;
        DIG_ASIC_9_I3 : out std_logic;
        DIG_ASIC_9_I4 : out std_logic;
        DIG_ASIC_10_S0 : out std_logic;
        DIG_ASIC_10_S1 : out std_logic;
        DIG_ASIC_10_S2 : out std_logic;
        DIG_ASIC_10_S_LATCH : out std_logic;
        DIG_ASIC_10_I1 : out std_logic;
        DIG_ASIC_10_I3 : out std_logic;
        DIG_ASIC_10_I4 : out std_logic;
        DIG_ASIC_9_CALD : out std_logic;
        DIG_ASIC_9_CALDB : out std_logic;
        DIG_ASIC_9_OUT_5 : out std_logic;
        DIG_ASIC_9_OUT_6 : out std_logic;
        DIG_ASIC_10_OUT_5 : out std_logic;
        DIG_ASIC_10_OUT_6 : out std_logic;
        DIG_ASIC_11_S0 : out std_logic;
        DIG_ASIC_11_S1 : out std_logic;
        DIG_ASIC_11_S2 : out std_logic;
        DIG_ASIC_11_S_LATCH : out std_logic;
        DIG_ASIC_11_I1 : out std_logic;
        DIG_ASIC_11_I3 : out std_logic;
        DIG_ASIC_11_I4 : out std_logic;
        DIG_ASIC_12_S0 : out std_logic;
        DIG_ASIC_12_S1 : out std_logic;
        DIG_ASIC_12_S2 : out std_logic;
        DIG_ASIC_12_S_LATCH : out std_logic;
        Trig_Ack_P : out std_logic;
        Event_ID_Latch_P : out std_logic;
        Event_ID_P : out std_logic;
        Trig_ENA_P : out std_logic;
        DIG_ASIC_12_I1 : out std_logic;
        DIG_ASIC_12_I3 : out std_logic;
        DIG_ASIC_12_I4 : out std_logic;
        DIG_ASIC_11_CALD : out std_logic;
        DIG_ASIC_11_CALDB : out std_logic;
        DIG_ASIC_11_OUT_5 : out std_logic;
        DIG_ASIC_11_OUT_6 : out std_logic;
        DIG_ASIC_12_OUT_5 : out std_logic;
        DIG_ASIC_12_OUT_6 : out std_logic;
        Si_HIT_P : out std_logic;
        Si_RDY_P : out std_logic;
        Si_BUSY_P : out std_logic;
        Si_SPARE_P : out std_logic
    );
end slice_it_up;

architecture Behavioral of slice_it_up is

begin
    DIG_ASIC_1_S0 <= gpio1_1(0);
    DIG_ASIC_1_S1 <= gpio1_1(1);
    DIG_ASIC_1_S2 <= gpio1_1(2);
    DIG_ASIC_1_S_LATCH <= gpio1_1(3);
    DIG_ASIC_1_I1 <= gpio1_1(4);
    DIG_ASIC_1_I3 <= gpio1_1(5);
    DIG_ASIC_1_I4 <= gpio1_1(6);
    DIG_ASIC_2_S0 <= gpio1_1(7);
    DIG_ASIC_2_S1 <= gpio1_1(8);
    DIG_ASIC_2_S2 <= gpio1_1(9);
    DIG_ASIC_2_S_LATCH <= gpio1_1(10);
    DIG_ASIC_2_I1 <= gpio1_1(11);
    DIG_ASIC_2_I3 <= gpio1_1(12);
    DIG_ASIC_2_I4 <= gpio1_1(13);
    DIG_ASIC_1_CALD <= gpio1_1(14);
    DIG_ASIC_1_CALDB <= gpio1_1(15);
    DIG_ASIC_1_OUT_5 <= gpio1_1(16);
    DIG_ASIC_1_OUT_6 <= gpio1_1(17);
    DIG_ASIC_2_OUT_5 <= gpio1_1(18);
    DIG_ASIC_2_OUT_6 <= gpio1_1(19);
    DIG_ASIC_3_S0 <= gpio1_1(20);
    DIG_ASIC_3_S1 <= gpio1_1(21);
    DIG_ASIC_3_S2 <= gpio1_1(22);
    DIG_ASIC_3_S_LATCH <= gpio1_1(23);
    DIG_ASIC_3_I1 <= gpio1_1(24);
    DIG_ASIC_3_I3 <= gpio1_1(25);
    DIG_ASIC_3_I4 <= gpio1_1(26);
    DIG_ASIC_4_S0 <= gpio1_1(27);
    DIG_ASIC_4_S1 <= gpio1_1(28);
    DIG_ASIC_4_S2 <= gpio1_1(29);
    DIG_ASIC_4_S_LATCH <= gpio1_1(30);
    DIG_ASIC_4_I1 <= gpio1_1(31);
    DIG_ASIC_4_I3 <= gpio1_2(0);
    DIG_ASIC_4_I4 <= gpio1_2(1);
    DIG_ASIC_3_CALD <= gpio1_2(2);
    DIG_ASIC_3_CALDB <= gpio1_2(3);
    DIG_ASIC_3_OUT_5 <= gpio1_2(4);
    DIG_ASIC_3_OUT_6 <= gpio1_2(5);
    DIG_ASIC_4_OUT_5 <= gpio1_2(6);
    DIG_ASIC_4_OUT_6 <= gpio1_2(7);
    DIG_ASIC_5_S0 <= gpio1_2(8);
    DIG_ASIC_5_S1 <= gpio1_2(9);
    DIG_ASIC_5_S2 <= gpio1_2(10);
    DIG_ASIC_5_S_LATCH <= gpio1_2(11);
    DIG_ASIC_5_I1 <= gpio1_2(12);
    DIG_ASIC_5_I3 <= gpio1_2(13);
    DIG_ASIC_5_I4 <= gpio1_2(14);
    DIG_ASIC_6_S0 <= gpio1_2(15);
    DIG_ASIC_6_S1 <= gpio1_2(16);
    DIG_ASIC_6_S2 <= gpio1_2(17);
    DIG_ASIC_6_S_LATCH <= gpio1_2(18);
    DIG_ASIC_6_I1 <= gpio1_2(19);
    DIG_ASIC_6_I3 <= gpio1_2(20);
    DIG_ASIC_6_I4 <= gpio1_2(21);
    DIG_ASIC_5_CALD <= gpio1_2(22);
    DIG_ASIC_5_CALDB <= gpio1_2(23);
    DIG_ASIC_5_OUT_5 <= gpio1_2(24);
    DIG_ASIC_5_OUT_6 <= gpio1_2(25);
    DIG_ASIC_6_OUT_5 <= gpio1_2(26);
    DIG_ASIC_6_OUT_6 <= gpio1_2(27);
    DIG_ASIC_7_S0 <= gpio1_2(28);
    DIG_ASIC_7_S1 <= gpio1_2(29);
    DIG_ASIC_7_S2 <= gpio1_2(30);
    DIG_ASIC_7_S_LATCH <= gpio1_2(31);
    DIG_ASIC_7_I1 <= gpio2_1(0);
    DIG_ASIC_7_I3 <= gpio2_1(1);
    DIG_ASIC_7_I4 <= gpio2_1(2);
    DIG_ASIC_8_S0 <= gpio2_1(3);
    DIG_ASIC_8_S1 <= gpio2_1(4);
    DIG_ASIC_8_S2 <= gpio2_1(5);
    DIG_ASIC_8_S_LATCH <= gpio2_1(6);
    DIG_ASIC_8_I1 <= gpio2_1(7);
    DIG_ASIC_8_I3 <= gpio2_1(8);
    DIG_ASIC_8_I4 <= gpio2_1(9);
    DIG_ASIC_7_CALD <= gpio2_1(10);
    DIG_ASIC_7_CALDB <= gpio2_1(11);
    DIG_ASIC_7_OUT_5 <= gpio2_1(12);
    DIG_ASIC_7_OUT_6 <= gpio2_1(13);
    DIG_ASIC_8_OUT_5 <= gpio2_1(14);
    DIG_ASIC_8_OUT_6 <= gpio2_1(15);
    DIG_A_VTH_CAL_DAC_MOSI_P <= gpio2_1(16);
    DIG_A_CAL_DAC_SYNCn_P <= gpio2_1(17);
    DIG_A_VTH_CAL_DAC_SCLK_P <= gpio2_1(18);
    DIG_A_CAL_PULSE_TRIGGER_P <= gpio2_1(19);
    DIG_A_VTH_DAC_SYNCn_P <= gpio2_1(20);
    DIG_A_TELEMX_MISO_P <= gpio2_1(21);
    PPS <= gpio2_1(22);
    DIG_A_TELEMX_MOSI_P <= gpio2_1(23);
    EXTCLK <= gpio2_1(24);
    DIG_A_TELEM1_SCLK_P <= gpio2_1(25);
    DIG_A_TELEM1_CSn_P <= gpio2_1(26);
    DIG_A_TELEM2_CSn_P <= gpio2_1(27);
    DIG_B_TELEMX_MISO_P <= gpio2_1(28);
    DIG_B_TELEMX_MOSI_P <= gpio2_1(29);
    DIG_B_TELEMX_SCLK_P <= gpio2_1(30);
    DIG_B_TELEM1_CSn_P <= gpio2_1(31);
    DIG_B_TELEM2_CSn_P <= gpio2_2(0);
    DIG_B_CAL_PULSE_TRIGGER_P <= gpio2_2(1);
    DIG_B_VTH_CAL_DAC_MOSI_P <= gpio2_2(2);
    DIG_B_VTH_CAL_DAC_SCLK_P <= gpio2_2(3);
    DIG_B_CAL_DAC_SYNCn_P <= gpio2_2(4);
    DIG_B_VTH_DAC_SYNCn_P <= gpio2_2(5);
    DIG_ASIC_9_S0 <= gpio2_2(6);
    DIG_ASIC_9_S1 <= gpio2_2(7);
    DIG_ASIC_9_S2 <= gpio2_2(8);
    DIG_ASIC_9_S_LATCH <= gpio2_2(9);
    DIG_ASIC_9_I1 <= gpio2_2(10);
    DIG_ASIC_9_I3 <= gpio2_2(11);
    DIG_ASIC_9_I4 <= gpio2_2(12);
    DIG_ASIC_10_S0 <= gpio2_2(13);
    DIG_ASIC_10_S1 <= gpio2_2(14);
    DIG_ASIC_10_S2 <= gpio2_2(15);
    DIG_ASIC_10_S_LATCH <= gpio2_2(16);
    DIG_ASIC_10_I1 <= gpio2_2(17);
    DIG_ASIC_10_I3 <= gpio2_2(18);
    DIG_ASIC_10_I4 <= gpio2_2(19);
    DIG_ASIC_9_CALD <= gpio2_2(20);
    DIG_ASIC_9_CALDB <= gpio2_2(21);
    DIG_ASIC_9_OUT_5 <= gpio2_2(22);
    DIG_ASIC_9_OUT_6 <= gpio2_2(23);
    DIG_ASIC_10_OUT_5 <= gpio2_2(24);
    DIG_ASIC_10_OUT_6 <= gpio2_2(25);
    DIG_ASIC_11_S0 <= gpio2_2(26);
    DIG_ASIC_11_S1 <= gpio2_2(27);
    DIG_ASIC_11_S2 <= gpio2_2(28);
    DIG_ASIC_11_S_LATCH <= gpio2_2(29);
    DIG_ASIC_11_I1 <= gpio2_2(30);
    DIG_ASIC_11_I3 <= gpio2_2(31);
    DIG_ASIC_11_I4 <= gpio3_1(0);
    DIG_ASIC_12_S0 <= gpio3_1(1);
    DIG_ASIC_12_S1 <= gpio3_1(2);
    DIG_ASIC_12_S2 <= gpio3_1(3);
    DIG_ASIC_12_S_LATCH <= gpio3_1(4);
    Trig_Ack_P <= gpio3_1(5);
    Event_ID_Latch_P <= gpio3_1(6);
    Event_ID_P <= gpio3_1(7);
    Trig_ENA_P <= gpio3_1(8);
    DIG_ASIC_12_I1 <= gpio3_1(9);
    DIG_ASIC_12_I3 <= gpio3_1(10);
    DIG_ASIC_12_I4 <= gpio3_1(11);
    DIG_ASIC_11_CALD <= gpio3_1(12);
    DIG_ASIC_11_CALDB <= gpio3_1(13);
    DIG_ASIC_11_OUT_5 <= gpio3_1(14);
    DIG_ASIC_11_OUT_6 <= gpio3_1(15);
    DIG_ASIC_12_OUT_5 <= gpio3_1(16);
    DIG_ASIC_12_OUT_6 <= gpio3_1(17);
    Si_HIT_P <= gpio3_1(18);
    Si_RDY_P <= gpio3_1(19);
    Si_BUSY_P <= gpio3_1(20);
    Si_SPARE_P <= gpio3_1(21);
end Behavioral;
-- set vim: st=4 sw=4 sts=4 et: