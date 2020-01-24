-- int_cal_toggle
-- Toggles the cald, caldb lines on rising edge of int_cal_trigger
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_cal_toggle is
    port (
        clk             : in std_logic;
        rst_n           : in std_logic;
        int_cal_trigger : in std_logic;
    	cald            : out std_logic;
        caldb           : out std_logic);
end int_cal_toggle;

architecture arch_imp of int_cal_toggle is
    signal last_trigger : std_logic := '0';
    signal cald_buf     : std_logic := '0';
begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            cald_buf     <= '0';
            last_trigger <= '0';
        elsif rising_edge(clk) then
            if last_trigger = '0' and int_cal_trigger = '1' then
                cald_buf <= not cald_buf;
            end if;
            last_trigger <= int_cal_trigger;
        end if;
    end process;

    cald  <= cald_buf;
    caldb <= not cald_buf;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
