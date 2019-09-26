library ieee;
use ieee.std_logic_1164.all;

entity event_id_s2p_tb is
end event_id_s2p_tb;

architecture TB_ARCH of event_id_s2p_tb is
      -- Component declaration of the tested unit
    component event_id_s2p
        generic (
            EVENT_ID_WIDTH : integer := 32);
        port (
            clk            : in std_logic;
            rst_n          : in std_logic;
            trigger_ack    : in std_logic;
            event_id_data  : in std_logic;
            event_id_latch : in std_logic;
            event_id_out   : out std_logic_vector(EVENT_ID_WIDTH-1 downto 0));
    end event_id_s2p;

    constant EVENT_ID_WIDTH : integer := 32;
    constant Tpd : time := 10.0 ns; -- 100 MHz

    constant event_id_in : std_logic_vector(EVENT_ID_WIDTH-1 downto 0) := x"12345678";

    signal rst_n : std_logic := '1';
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

    data_in_proc : process
    begin
        event_id_data  <= '0';
        event_id_latch <= '0';
        trigger_ack    <= '0';
        wait for 10 * Tpd;
        trigger_ack <= '1';
        wait for 5 * Tpd;
        trigger_ack <= '0';
        wait for 5 * Tpd;
        for i in 31 downto 0 loop
            event_id_latch <= '1';
            event_id_data <= event_id_in(i);
            wait for 10 * Tpd;
            event_id_latch <= '0';
            wait for 10 * Tpd;
        end loop;
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
                        
end TB_ARCH;

-- vim: set ts=4 sw=4 sts=4 et:
