-- event_id_s2p
-- This will set the event-id on event_id_out
-- Simply does serial to parallel conversion by
-- shifting data into register as it comes in, 
-- does not keep track of number of bits.
-- Clears the `event_id_out` on rising edge of event_id_clr
library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity event_id_s2p is
    generic (
        EVENT_ID_WIDTH : integer := 32);
    port (
        clk            : in std_logic;
        rst_n          : in std_logic;
    	event_id_data  : in std_logic;
    	event_id_latch : in std_logic;
        event_id_clr   : in std_logic;
        event_id_out   : out std_logic_vector(EVENT_ID_WIDTH-1 downto 0));
end event_id_s2p;

architecture arch_imp of event_id_s2p is
    signal data: std_logic_vector(EVENT_ID_WIDTH-1 downto 0) := (others => '0');
    signal trigger_event_id_clr : std_logic := '0';
    signal last_event_id_clr : std_logic := '0';
    signal last_event_id_latch : std_logic := '0';
begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            trigger_event_id_clr <= '0';
            last_event_id_clr <= '0';
        elsif rising_edge(clk) then
            if last_event_id_clr = '0' and event_id_clr = '1' then
                trigger_event_id_clr <= '1';
            else
                trigger_event_id_clr <= '0';
            end if;
            last_event_id_clr <= event_id_clr;
        end if;
    end process;
            

    process (rst_n, clk)
    begin
        if rst_n = '0' or trigger_event_id_clr = '1' then
            data <= (others => '0');
        elsif rising_edge(clk) then
            if last_event_id_latch = '0' and event_id_latch = '1' then
                data(EVENT_ID_WIDTH-1 downto 1) <= data(EVENT_ID_WIDTH-2 downto 0);
                data(0) <= event_id_data;
            else
                data <= data;
            end if;
            last_event_id_latch <= event_id_latch;
        end if;
    end process;

    event_id_out <= data;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
