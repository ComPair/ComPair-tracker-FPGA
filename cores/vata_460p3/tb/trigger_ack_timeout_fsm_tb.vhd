library ieee;
use ieee.std_logic_1164.all;

entity trigger_ack_timeout_fsm_tb is
end trigger_ack_timeout_fsm_tb;

architecture TB_ARCH of trigger_ack_timeout_fsm_tb is
    -- Component declaration of the tested unit
    component trigger_ack_timeout_fsm
        generic (
            COUNTER_WIDTH : integer := 16;
            TIMEOUT       : integer := 1000); -- in multiples of clock period.
        port (
            clk_100MHz   : in std_logic;
            rst_n        : in std_logic;
            trigger_ena  : in std_logic;
            trigger_ack  : in std_logic;
            abort_daq    : out std_logic);
    end component trigger_ack_timeout_fsm;

    constant COUNTER_WIDTH : integer := 16;
    constant TIMEOUT: integer := 10;
    constant Tpd : time := 10.0 ns; -- 100 MHz

    signal rst_n : std_logic := '1';
    signal trigger_ena : std_logic := '0';
    signal trigger_ack : std_logic := '0';
    signal event_id_data : std_logic;
    signal event_id_latch : std_logic := '0';
    signal event_id_out : std_logic_vector(EVENT_ID_WIDTH-1 downto 0);

begin

    clk_proc : process
    begin
        clk <= '0';
        wait for Tpd / 2;
        clk <= '1';
        wait for Tpd / 2;
    end process;

    rst_proc : process
    begin
        rst_n <= '1';
        wait for 2 * Tpd;
        rst_n <= '0';
        wait for 1 * Tpd;
        rst_n <= '1';
        wait;
    end process;

    test_proc : process
    begin
        trigger_ena <= '0';
        trigger_ack <= '0';
        wait for 10 * Tpd;

        -- Try and trigger abort_daq
        trigger_ena <= '1';
        wait for 1 * Tpd;
        trigger_ena <= '0';
        wait for 10 * Tpd; -- should trigger abort_daq

        -- Normal operation
        trigger_ena <= '1';
        wait for 1 * Tpd;
        trigger_ena <= '0';
        wait for 5 * Tpd;
        trigger_ack <= '1'
        wait for 1 * Tpd;
        trigger_ack <= '0'
        wait for 10 * Tpd;

        -- Try and trigger abort_daq
        trigger_ena <= '1';
        wait for 1 * Tpd;
        trigger_ena <= '0';
        wait for 10 * Tpd; -- should trigger abort_daq
        wait;
    end process;

    UUT : event_id_s2p
        generic map (
            EVENT_ID_WIDTH => EVENT_ID_WIDTH)
        port map (
            clk => clk,
            rst_n => rst_n,
            trigger_ack => trigger_ack,
            event_id_data => event_id_data,
            event_id_latch => event_id_latch,
            event_id_out => event_id_out);

    UUT : trigger_ack_timeout_fsm
        generic map (
            COUNTER_WIDTH => COUNTER_WIDTH
            TIMEOUT       => TIMEOUT)
        port map (
            clk_100MHz  => clk,
            rst_n       => rst_n,
            trigger_ena => trigger_ena,
            trigger_ack => trigger_ack,
            abort_daq   => abort_daq);
                        
end TB_ARCH;

-- vim: set ts=4 sw=4 sts=4 et:
