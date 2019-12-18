-- trigger_ack_timeout_fsm
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger_ack_timeout_fsm is
    port (
        clk_100MHz          : in std_logic;
        rst_n               : in std_logic;
        trigger_ena         : in std_logic;
        trigger_ack         : in std_logic;
        trigger_ack_timeout : in std_logic_vector(31 downto 0);
        abort_daq           : out std_logic;
        -- Debug ports:
        counter_out         : out std_logic_vector(31 downto 0);
        state_out           : out std_logic_vector(3 downto 0));
end trigger_ack_timeout_fsm;

architecture arch_imp of trigger_ack_timeout_fsm is
    --constant COUNTER_MAX : unsigned(31 downto 0) := to_unsigned(TIMEOUT, COUNTER_WIDTH);
    
    constant IDLE          : std_logic_vector(3 downto 0) := x"0";
    constant INC_COUNTER   : std_logic_vector(3 downto 0) := x"1";
    constant ACQ_OK        : std_logic_vector(3 downto 0) := x"2";
    constant ACQ_ABORT     : std_logic_vector(3 downto 0) := x"3";
    constant ACK_ZEROS     : std_logic_vector(31 downto 0) := (others => '0');

    signal current_state : std_logic_vector(3 downto 0) := x"0";
    signal next_state : std_logic_vector(3 downto 0) := x"0";
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal counter_clr : std_logic;
    signal counter_ena : std_logic;

begin

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_100MHz) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, trigger_ena, trigger_ack)
    begin
        counter_clr <= '0';
        if rst_n = '0' then
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if trigger_ena = '1' and trigger_ack_timeout /= ACK_ZEROS then
                        counter_clr <= '1';
                        next_state <= INC_COUNTER;
                    else
                        next_state <= IDLE;
                    end if;
                when INC_COUNTER =>
                    if counter >= unsigned(trigger_ack_timeout) then
                        next_state <= ACQ_ABORT;
                    elsif trigger_ack = '1' then
                        next_state <= ACQ_OK;
                    else
                        next_state <= INC_COUNTER;
                    end if;
                when ACQ_ABORT =>
                    next_state <= IDLE;
                when ACQ_OK =>
                    next_state <= IDLE;
                when others =>
                    -- Error!
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        case (current_state) is
            when ACQ_ABORT =>
                abort_daq <= '1';
                counter_ena <= '0';
            when INC_COUNTER =>
                abort_daq <= '0';
                counter_ena <= '1';
            when others =>
                abort_daq <= '0';
                counter_ena <= '0';
        end case;
    end process;

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk_100MHz) then
            if counter_clr = '1' then
                counter <= (others => '0');
            elsif counter_ena = '1' then
                counter <= counter + to_unsigned(1, counter'length);
            else
                counter <= counter;
            end if;
        end if;
    end process;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
