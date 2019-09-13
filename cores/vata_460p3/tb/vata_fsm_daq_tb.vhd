-- Simulation should run for ~355us
library ieee;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;

entity vata_fsm_daq_tb is
end vata_fsm_daq_tb;

architecture TB_ARCH of vata_fsm_daq_tb is
    -- Component declaration of the tested unit
    component vata_460p3_iface_fsm
        port (
            clk_100MHz         : in std_logic; -- 100 ns
            rst_n              : in std_logic;
            trigger_in         : in std_logic;
            trigger_out        : out std_logic;
            get_config         : in std_logic;
            set_config         : in std_logic;
            cp_data_done       : in std_logic;
            hold_time          : in std_logic_vector(15 downto 0);
            vata_s0            : out std_logic;
            vata_s1            : out std_logic;
            vata_s2            : out std_logic;
            vata_s_latch       : out std_logic;
            vata_i1            : out std_logic;
            vata_i3            : out std_logic;
            vata_i4            : out std_logic;
            vata_o5            : in std_logic;
            vata_o6            : in std_logic;
            bram_addr          : out std_logic_vector(31 downto 0);
            bram_dwrite        : out std_logic_vector(31 downto 0);
            bram_wea           : out std_logic_vector (3 downto 0);
            cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
            state_counter_out  : out std_logic_vector(15 downto 0);
            reg_indx_out       : out std_logic_vector(9 downto 0);
            reg_from_vata_out  : out std_logic_vector(378 downto 0);
            state_out          : out std_logic_vector(7 downto 0));
    end component;

    constant Tpd : time := 10.0 ns; -- 100 MHz
    constant hold_time : std_logic_vector(15 downto 0) := x"000A"; -- 10 clock cycle hold
    constant RO_WAIT_FOR_CP_DATA_DONE : std_logic_vector(7 downto 0) := x"40";

    signal clk               : std_logic;
    signal rst_n             : std_logic := '1';
    signal trigger_in        : std_logic := '0';
    signal trigger_out       : std_logic;
    signal cp_data_done      : std_logic := '0';
    signal vata_s0           : std_logic;
    signal vata_s1           : std_logic;
    signal vata_s2           : std_logic;
    signal vata_s_latch      : std_logic;
    signal vata_i1           : std_logic;
    signal vata_i3           : std_logic;
    signal vata_i4           : std_logic;
    signal vata_o5           : std_logic := '0';
    signal vata_o6           : std_logic := '0';
    signal bram_addr         : std_logic_vector(31 downto 0);
    signal bram_dwrite       : std_logic_vector(31 downto 0);
    signal bram_wea          : std_logic_vector(3 downto 0) := (others => '0');

    signal state_counter_out : std_logic_vector(15 downto 0);
    signal state_out         : std_logic_vector(7 downto 0);
    signal reg_indx_out      : std_logic_vector(9 downto 0);
    signal reg_from_vata_out : std_logic_vector(378 downto 0);

    signal last_vata_i1      : std_logic := '0';
    signal vata_out_count    : integer range 0 to 1023;
    signal vata_out_state    : std_logic_vector(7 downto 0) := x"00";

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

    trigger_proc : process
    begin
        trigger_in <= '0';
        wait for 5 * Tpd; -- wait for resets to finish
        trigger_in <= '1';
        wait for 100 ns;
        trigger_in <= '0';
        wait;
    end process;

    vata_out_proc : process (clk)
    begin
        if rising_edge(clk) then
            case (vata_out_state) is
                when x"00" =>
                    if vata_i3 = '1' then
                        vata_out_count <= 0;
                        vata_out_state <= x"01";
                    else
                        vata_out_state <= x"00";
                    end if;
                when x"01" =>
                    if last_vata_i1 = '0' and vata_i1 = '1' then
                        if vata_out_count = 1023 then
                            vata_o5 <= '1';
                            vata_out_count <= 0;
                            vata_out_state <= x"02";
                        else
                            vata_out_count <= vata_out_count + 1;
                            vata_out_state <= x"01";
                        end if;
                    else
                        vata_out_state <= x"01";
                    end if;
                when x"02" =>
                    if vata_s_latch = '1' then
                        vata_o5 <= '0';
                        vata_out_count <= 0;
                        vata_out_state <= x"03";
                    else
                        vata_o5 <= '1';
                        vata_out_state <= x"02";
                    end if;
                when x"03" =>
                    if last_vata_i1 = '0' and vata_i1 = '1' then
                        if vata_out_count = 378 then
                            vata_o5 <= '1';
                            vata_out_count <= 379;
                            vata_out_state <= x"0A";
                        else
                            vata_out_count <= vata_out_count + 1;
                            vata_out_state <= x"03";
                        end if;
                    else
                        vata_out_state <= x"03";
                    end if;
                when x"0A" =>
                    if state_out = x"32" or state_out = x"33" then
                        vata_o5 <= '0';
                        vata_out_state <= x"04";
                    else
                        vata_o5 <= '1';
                        vata_out_count <= 379;
                        vata_out_state <= x"0A";
                    end if;
                when x"04" =>
                    if bram_wea = x"F" then
                        vata_o5 <= '0';
                        vata_out_state <= x"05";
                    else
                        vata_o5 <= '1';
                        vata_out_state <= x"04";
                    end if;
                when x"05" =>
                    -- Waiting for read out to bram to finish...
                    if state_out = RO_WAIT_FOR_CP_DATA_DONE then
                        vata_out_state <= x"06";
                    else
                        vata_out_state <= x"05";
                    end if;
                when x"06" =>
                    cp_data_done <= '1';
                    vata_out_state <= x"07";
                when x"07" =>
                    cp_data_done <= '0';
                    vata_out_state <= x"00";
                when others =>
                    vata_out_state <= x"00";
            end case;
        end if;
    end process;

    last_i1_proc : process (clk)
    begin
        if rising_edge(clk) then
            last_vata_i1 <= vata_i1;
        end if;
    end process;

    vata_o6_proc : process (vata_out_state, vata_out_count)
    begin
        if vata_out_state = x"03" or vata_out_state = x"0A" then
            if vata_out_count = 1 or vata_out_count = 3 or vata_out_count = 5 or vata_out_count = 7 or
                    vata_out_count = 379 or vata_out_count = 377 or vata_out_count = 375 then
                vata_o6 <= '1';
            else
                vata_o6 <= '0';
            end if;
        else
            vata_o6 <= '0';
        end if;
    end process;

    UUT : vata_460p3_iface_fsm
        port map (
            clk_100MHz        => clk,
            rst_n             => rst_n,
            trigger_in        => trigger_in,
            trigger_out       => trigger_out,
            set_config        => '0',
            get_config        => '0',
            cp_data_done      => cp_data_done,
            hold_time         => hold_time,
            vata_s0           => vata_s0,
            vata_s1           => vata_s1,
            vata_s2           => vata_s2,
            vata_s_latch      => vata_s_latch,
            vata_i1           => vata_i1,
            vata_i3           => vata_i3,
            vata_i4           => vata_i4,
            vata_o5           => vata_o5,
            vata_o6           => vata_o6,
            bram_addr         => bram_addr,
            bram_dwrite       => bram_dwrite,
            bram_wea          => bram_wea,
            cfg_reg_from_ps   => (others => '0'),
            state_counter_out => state_counter_out,
            reg_indx_out      => reg_indx_out,
            reg_from_vata_out => reg_from_vata_out,
            state_out         => state_out);

end TB_ARCH;

-- vim: set ts=4 sw=4 sts=4 et:
