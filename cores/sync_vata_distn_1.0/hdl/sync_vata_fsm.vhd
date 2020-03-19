library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_vata_fsm is
    port ( clk           : in std_logic
         ; rst_n         : in std_logic
         ; counter_rst : in std_logic
         ; counter       : out std_logic_vector(63 downto 0)
         );
end sync_vata_fsm;

architecture arch_imp of sync_vata_fsm is
    signal ucounter : unsigned(63 downto 0) := (others => '0');
begin

    process (clk, rst_n, counter_rst)
    begin
        if rst_n = '0' or counter_rst = '1' then
            ucounter <= (others => '0');
        else
            if rising_edge(clk) then
                ucounter <= ucounter + 1;
            end if;
        end if;
    end process;

    counter <= std_logic_vector(ucounter);

end arch_imp;

-- vim: set ts=4 sw=4 sts=4 et:
