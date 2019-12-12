-- Module to power cycle on the vss_shutdown_n line.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity power_cycler is
    port (
        clk                 : in std_logic;
        rst_n               : in std_logic;
        trigger_power_cycle : in std_logic;
        power_cycle_timer   : in std_logic_vector(31 downto 0);
        vss_shutdown_n      : out std_logic);
end power_cycler;

architecture arch_imp of power_cycler is
    signal counter : unsigned(31 downto 0) := (others => '0');
begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            -- clear the counter.
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if trigger_power_cycle = '1' then
                counter <= unsigned(power_cycle_timer);
            elsif counter = to_unsigned(0, counter'length) then
                counter <= counter;
            else
                counter <= counter - to_unsigned(1, counter'length);
            end if;
        end if;
    end process;

    with counter select
        vss_shutdown_n <= '1' when to_unsigned(0, counter'length),
                          '0' when others;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
