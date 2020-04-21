-- gen_event_id_go
-- Generate the `event_id_go` signal from `FEE_busy` and `FEE_ready`
library ieee;
use ieee.std_logic_1164.all;

entity gen_event_id_go is
    port ( clk         : in std_logic
         ; rst_n       : in std_logic
         ; FEE_busy    : in std_logic
         ; FEE_ready   : in std_logic
         ; event_id_go : out std_logic
         );
end gen_event_id_go;

architecture arch_imp of gen_event_id_go is
    constant IDLE           : std_logic_vector(0 downto 0) := "0";
    constant WAIT_FOR_READY : std_logic_vector(0 downto 0) := "1";

    signal state         : std_logic_vector(0 downto 0) := "0";
    signal last_FEE_busy : std_logic := '0';
begin

    process (clk, rst_n)
    begin
        event_id_go <= '0';
        if rst_n = '0' then
            last_FEE_busy <= '0';
            state <= IDLE;
        elsif rising_edge(clk) then
            case (state) is
                when IDLE =>
                    if last_FEE_busy = '0' and FEE_busy = '1' then
                        event_id_go <= '1';
                        state       <= WAIT_FOR_READY;
                    else
                        state <= IDLE;
                    end if;
                    last_FEE_busy <= FEE_busy;
                when WAIT_FOR_READY =>
                    if FEE_ready = '1' then
                        state <= IDLE;
                    else
                        state <= WAIT_FOR_READY;
                    end if;
                    last_FEE_busy <= '0';
                when others =>
                    state <= IDLE;
                    last_FEE_busy <= '0';
            end case;
        end if;
    end process;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
