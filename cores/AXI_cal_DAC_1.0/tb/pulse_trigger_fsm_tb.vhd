library ieee;
use ieee.std_logic_1164.all;

entity pulse_trigger_fsm_tb is
end pulse_trigger_fsm_tb ;

architecture TB_ARCH of pulse_trigger_fsm_tb is
      -- Component declaration of the tested unit
    component pulse_trigger_fsm 
        generic (
            C_S_AXI_DATA_WIDTH : integer := 32
        );
        port (
            clk                   : in std_logic;
            rst_n                 : in std_logic;
            run_pulses            : in std_logic;
            cal_pulse_ena         : in std_logic;
            vata_trigger_ena      : in std_logic;
            cal_pulse_width       : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            trigger_delay         : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            n_pulses_in           : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            pulse_wait            : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            cal_pulse_trigger_out : out std_logic := '0';
            vata_trigger_out      : out std_logic := '0'
        );
    end component pulse_trigger_fsm;

    constant C_S_AXI_DATA_WIDTH : integer := 32;

    constant Tpd : time := 10.0 ns; -- 100 MHz

    constant cal_pulse_width : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"0000000A"; -- width is 10
    constant trigger_delay   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"00000005"; -- delay is 5
    constant n_pulses_in     : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"00000003"; -- 3 pulses
    constant pulse_wait      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"00000004"; -- wait is 4

    signal clk               : std_logic;
    signal rst_n             : std_logic := '1';
    signal run_pulses        : std_logic := '0';
    signal cal_pulse_trigger_out : std_logic;
    signal vata_trigger_out      : std_logic;

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

    run_pulse_proc : process
    begin
        run_pulses <= '0';
        wait for 10 * Tpd;
        run_pulses <= '1';
        wait for 1 * Tpd;
        run_pulses <= '0';
        wait;
    end process;

    UUT : pulse_trigger_fsm
        generic map (
            C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH
        )
        port map (
            clk                   => clk,
            rst_n                 => rst_n,
            run_pulses            => run_pulses,
            cal_pulse_ena         => '1',
            vata_trigger_ena      => '1',
            cal_pulse_width       => cal_pulse_width,
            trigger_delay         => trigger_delay,
            n_pulses_in           => n_pulses_in,
            pulse_wait            => pulse_wait,
            cal_pulse_trigger_out => cal_pulse_trigger_out,
            vata_trigger_out      => vata_trigger_out
        );
                        
end TB_ARCH;

-- vim: set ts=4 sw=4 sts=4 et:
