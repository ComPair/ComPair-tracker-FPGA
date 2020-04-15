-- event_id_p2s
-- This will set the event-id on event_id_out,
-- Simply does parallel to serial conversion and
-- includes the output `event_id_latch` signal
library ieee;
use ieee.std_logic_1164.all;

entity event_id_p2s is
    generic ( EVENT_ID_WIDTH     : integer := 32
            ; EVENT_ID_CLK_RATIO : integer := 10 -- Ratio between clk and event_id_latch
            );
    port ( clk            : in std_logic
         ; rst_n          : in std_logic
         ; event_id_in    : in std_logic_vector(EVENT_ID_WIDTH-1 downto 0)
         ; event_id_go    : in std_logic -- On rising edge, latch event_id_in, and then start sending out event_id_out
         ; event_id_out   : out std_logic
         ; event_id_latch : out std_logic
         ; inc_event_id   : out std_logic
         );
end event_id_p2s;

architecture arch_imp of event_id_p2s is
    constant CLK_MAX    : integer := EVENT_ID_CLK_RATIO - 1;
    constant ID_BIT_MAX : integer := EVENT_ID_WIDTH - 1;

    constant IDLE     : std_logic_vector(1 downto 0) := "00";
    constant LATCH_HI : std_logic_vector(1 downto 0) := "01";
    constant LATCH_LO : std_logic_vector(1 downto 0) := "10";

    signal current_state : std_logic_vector(1 downto 0) := (others => '0');
    signal next_state    : std_logic_vector(1 downto 0) := (others => '0');

    signal start_id_out     : std_logic := '0';
    signal inc_id_bit_count : std_logic := '0';
    signal id_bit_count     : integer range 0 to ID_BIT_MAX := 0;

    signal clk_count_clr : std_logic := '0';
    signal clk_count     : integer range 0 to CLK_MAX := 0;

    signal data: std_logic_vector(EVENT_ID_WIDTH-1 downto 0) := (others => '0');

begin

    state_update_proc : process (rst_n, clk)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process state_update_proc;

    state_xfer_proc : process (rst_n, current_state, clk_count, id_bit_count, event_id_go)
    begin
        start_id_out     <= '0';
        inc_id_bit_count <= '0';
        clk_count_clr    <= '0';
        inc_event_id     <= '0';
        if rst_n = '0' then
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if event_id_go = '1' then
                        start_id_out  <= '1';
                        clk_count_clr <= '1';
                        next_state    <= LATCH_HI;
                    else
                        next_state <= IDLE;
                    end if;
                when LATCH_HI =>
                    if clk_count = CLK_MAX then
                        clk_count_clr <= '1';
                        next_state    <= LATCH_LO;
                    else
                        next_state <= LATCH_HI;
                    end if;
                when LATCH_LO =>
                    if clk_count = CLK_MAX then
                        if id_bit_count = ID_BIT_MAX then
                            inc_event_id <= '1';
                            next_state   <= IDLE;
                        else
                            clk_count_clr    <= '1';
                            inc_id_bit_count <= '1';
                            next_state       <= LATCH_HI;
                        end if;
                    else
                        next_state <= LATCH_LO;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process state_xfer_proc;

    state_outputs_proc : process (current_state) 
    begin
        case (current_state) is
            when IDLE =>
                event_id_out   <= '0';
                event_id_latch <= '0';
            when LATCH_HI =>
                event_id_out   <= data(id_bit_count);
                event_id_latch <= '1';
            when LATCH_LO =>
                event_id_out   <= data(id_bit_count);
                event_id_latch <= '0';
            when others =>
                event_id_out   <= '0';
                event_id_latch <= '0';
        end case;
    end process state_outputs_proc;

    id_bit_count_proc : process (rst_n, start_id_out, inc_id_bit_count)
    begin
        if rst_n = '0' or start_id_out = '1' then
            id_bit_count <= 0;
        elsif inc_id_bit_count = '1' then
            id_bit_count <= id_bit_count + 1;
        else
            id_bit_count <= id_bit_count;
        end if;
    end process id_bit_count_proc;

    clk_count_proc : process (rst_n, clk, clk_count_clr)
    begin
        if rst_n = '0' then
            clk_count <= 0;
        elsif rising_edge(clk) then
            if clk_count_clr = '1' then
                clk_count <= 0;
            else
                clk_count <= clk_count + 1;
            end if;
        end if;
    end process clk_count_proc;

    latch_event_id_proc : process (rst_n, start_id_out)
    begin
        if rst_n = '0' then
            data <= (others => '0');
        elsif start_id_out = '1' then
            data <= event_id_in;
        else
            data <= data;
        end if;
    end process latch_event_id_proc;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
