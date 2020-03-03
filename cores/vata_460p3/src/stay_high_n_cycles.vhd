-- stay_high_n_cycles
-- This module looks for the rising edge of data_in,
-- and upon receiving the rising edge sets data_out
-- high, and keeps it high, for specified number of
-- clock signals.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stay_high_n_cycles is
    generic (
        N_CYCLES_WIDTH : integer := 8;
        N_CYCLES : integer := 5);
    port (
        clk            : in std_logic;
        rst_n          : in std_logic;
        data_in : in std_logic;
    	data_out : out std_logic);
end stay_high_n_cycles;

architecture arch_imp of stay_high_n_cycles is
    constant IDLE : std_logic := '0';
    constant HIGH : std_logic := '1';
    
    signal current_state : std_logic := IDLE;
    signal next_state : std_logic := IDLE;

    constant COUNTER_MAX : unsigned(N_CYCLES_WIDTH-1 downto 0) := to_unsigned(N_CYCLES, N_CYCLES_WIDTH);
    signal counter : unsigned(N_CYCLES_WIDTH-1 downto 0) := (others => '0');
    signal counter_clr : std_logic := '0';
    signal counter_ena : std_logic := '0';

    signal last_data_in : std_logic := '0';
    signal data_in_rising_edge : std_logic := '0';

begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, data_in_rising_edge, counter)
    begin
        counter_clr <= '0';
        if rst_n = '0' then
            counter_clr <= '1';
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if data_in_rising_edge = '1' then
                        counter_clr <= '1';
                        next_state <= HIGH;
                    else
                        next_state <= IDLE;
                    end if;
                when HIGH =>
                    if counter >= COUNTER_MAX then
                        next_state <= IDLE;
                    else
                        next_state <= HIGH;
                    end if;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        case (current_state) is
            when IDLE =>
                counter_ena <= '0';
                data_out <= '0';
            when HIGH =>
                counter_ena <= '1';
                data_out <= '1';
        end case;
    end process;

    process (rst_n, clk)
    begin
        if rising_edge(clk) then
            if counter_clr = '1' then
                counter <= (others => '0');
            elsif counter_ena = '1' then
                counter <= counter + 1;
            else
                counter <= counter;
            end if;
        end if;
    end process;

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            last_data_in <= '0';
            data_in_rising_edge <= '0';
        elsif rising_edge(clk) then
            if last_data_in = '0' and data_in = '1' then
                data_in_rising_edge <= '1';
            else
                data_in_rising_edge <= '0';
            end if;
            last_data_in <= data_in;
        end if;
    end process;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
