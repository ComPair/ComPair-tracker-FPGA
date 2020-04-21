-- event_id_p2s
-- This will set the event-id on event_id_out,
-- Simply does parallel to serial conversion and
-- includes the output `event_id_latch` signal
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity event_id_p2s is
    generic ( EVENT_ID_WIDTH     : integer := 32 -- Max is 64
            ; EVENT_ID_CLK_RATIO : integer := 10 -- Ratio between clk and event_id_latch. Max is 15
            );
    port ( clk            : in std_logic
         ; rst_n          : in std_logic
         ; event_id_in    : in std_logic_vector(EVENT_ID_WIDTH-1 downto 0)
         ; event_id_go    : in std_logic -- On rising edge, latch event_id_in, and then start sending out event_id_out
         ; event_id_out   : out std_logic
         ; event_id_latch : out std_logic
         ; inc_event_id   : out std_logic
         -- Debug --
         ; clk_count_out  : out std_logic_vector(3 downto 0)
         ; id_bit_count_out : out std_logic_vector(5 downto 0)
         );
end event_id_p2s;

architecture arch_imp of event_id_p2s is
    constant CLK_COUNT_WIDTH : integer := 4;
    constant ID_BIT_COUNT_WIDTH : integer := 6;

    constant CLK_MAX    : unsigned(CLK_COUNT_WIDTH-1 downto 0) := to_unsigned(EVENT_ID_CLK_RATIO-1, CLK_COUNT_WIDTH);
    constant ID_BIT_MAX : unsigned(ID_BIT_COUNT_WIDTH-1 downto 0) := to_unsigned(EVENT_ID_WIDTH-1, ID_BIT_COUNT_WIDTH);
    --constant CLK_MAX    : integer := EVENT_ID_CLK_RATIO - 1;
    --constant ID_BIT_MAX : integer := EVENT_ID_WIDTH - 1;

    constant IDLE     : std_logic_vector(1 downto 0) := "00";
    constant LATCH_HI : std_logic_vector(1 downto 0) := "01";
    constant LATCH_LO : std_logic_vector(1 downto 0) := "10";

    signal current_state : std_logic_vector(1 downto 0) := (others => '0');
    signal next_state    : std_logic_vector(1 downto 0) := (others => '0');

    signal start_id_out     : std_logic := '0';
    signal inc_id_bit_count : std_logic := '0';

    signal id_bit_count : unsigned(5 downto 0) := (others => '0');
    --signal id_bit_count     : integer range 0 to ID_BIT_MAX := 0;

    signal clk_count_clr : std_logic := '0';
    signal clk_count_ena : std_logic := '0';
    signal clk_count : unsigned(3 downto 0) := (others => '0');
    --signal clk_count     : integer range 0 to CLK_MAX := 0;

    signal data: unsigned(EVENT_ID_WIDTH-1 downto 0) := (others => '0');

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
                    if clk_count >= CLK_MAX then
                        clk_count_clr <= '1';
                        next_state    <= LATCH_LO;
                    else
                        next_state <= LATCH_HI;
                    end if;
                when LATCH_LO =>
                    if clk_count >= CLK_MAX then
                        if id_bit_count >= ID_BIT_MAX then
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
                clk_count_ena  <= '0';
            when LATCH_HI =>
                event_id_out   <= data(EVENT_ID_WIDTH-1);
                event_id_latch <= '1';
                clk_count_ena  <= '1';
            when LATCH_LO =>
                event_id_out   <= data(EVENT_ID_WIDTH-1);
                event_id_latch <= '0';
                clk_count_ena  <= '1';
            when others =>
                event_id_out   <= '0';
                event_id_latch <= '0';
                clk_count_ena  <= '0';
        end case;
    end process state_outputs_proc;

    id_bit_count_proc : process (rst_n, clk)
    begin
        if rst_n = '0' then
            id_bit_count <= (others => '0');
        elsif rising_edge(clk) then
            if start_id_out = '1' then
                id_bit_count <= (others => '0');
            elsif inc_id_bit_count = '1' then
                id_bit_count <= id_bit_count + 1;
            else
                id_bit_count <= id_bit_count;
            end if;
        end if;
    end process id_bit_count_proc;

    clk_count_proc : process (rst_n, clk, clk_count_clr)
    begin
        if rst_n = '0' then
            clk_count <= (others => '0');
        elsif rising_edge(clk) then
            if clk_count_clr = '1' then
                clk_count <= (others => '0');
            elsif clk_count_ena = '1' then
                clk_count <= clk_count + 1;
            else
                clk_count <= clk_count;
            end if;
        end if;
    end process clk_count_proc;

    latch_event_id_proc : process (rst_n, clk)
    begin
        if rst_n = '0' then
            data <= (others => '0');
        elsif rising_edge(clk) then
            if start_id_out = '1' then
                data <= unsigned(event_id_in);
            elsif inc_id_bit_count = '1' then
                data <= shift_left(data, 1);
            else
                data <= data;
            end if;
        end if;
    end process latch_event_id_proc;

    -- Debug out
    clk_count_out    <= std_logic_vector(clk_count);
    id_bit_count_out <= std_logic_vector(id_bit_count);

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
