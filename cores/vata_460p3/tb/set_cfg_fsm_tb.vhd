library ieee;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity set_cfg_fsm_tb is
end set_cfg_fsm_tb;

architecture TB_ARCH of set_cfg_fsm_tb is
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
            bram_wea           : out std_logic_vector (3 downto 0) := (others => '0');
            cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
            state_counter_out  : out std_logic_vector(15 downto 0);
            reg_indx_out       : out std_logic_vector(9 downto 0);
            reg_from_vata_out  : out std_logic_vector(378 downto 0);
            state_out          : out std_logic_vector(7 downto 0));
    end component;

    constant Tpd : time := 10.0 ns; -- 100 MHz

    signal cfg_reg : std_logic_vector(519 downto 0) := (
                            519 => '1',
                            517 => '1',
                            515 => '1',
                            513 => '1',
                            0 => '1',
                            2 => '1',
                            4 => '1',
                            others => '0');
    
    signal clk : std_logic;
    signal rst_n : std_logic;
    signal get_config : std_logic := '0';
    signal set_config : std_logic := '0';
    signal vata_s0 : std_logic;
    signal vata_s1 : std_logic;
    signal vata_s2 : std_logic;
    signal vata_s_latch : std_logic;
    signal vata_i1 : std_logic;
    signal vata_i3 : std_logic;
    signal vata_i4 : std_logic;

    signal vata_o5 : std_logic;
    signal vata_o6 : std_logic;
    signal bram_addr   : std_logic_vector(31 downto 0);
    signal bram_dwrite : std_logic_vector(31 downto 0);
    signal bram_wea    : std_logic_vector (3 downto 0) := (others => '0');

    signal reg_indx_out : std_logic_vector(9 downto 0);
    signal state_counter_out : std_logic_vector(15 downto 0);
    signal state_out : std_logic_vector(7 downto 0);

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
        set_config <= '0';
        get_config <= '0';
        wait for 5 * Tpd;
        set_config <= '1';
        wait for Tpd;
        set_config <= '0';
        wait;
    end process;

    UUT : vata_460p3_iface_fsm
        port map (
            clk_100MHz        => clk,
            rst_n             => rst_n,
            trigger_in        => '0',
            trigger_out       => open,
            set_config        => set_config,
            get_config        => get_config,
            cp_data_done      => '0',
            hold_time         => x"0000",
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
            cfg_reg_from_ps   => cfg_reg,
            reg_indx_out      => reg_indx_out,
            reg_from_vata_out => open,
            state_counter_out => state_counter_out,
            state_out         => state_out);
            
end TB_ARCH;
