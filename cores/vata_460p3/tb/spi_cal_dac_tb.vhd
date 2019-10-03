library ieee;
use ieee.std_logic_1164.all;

entity spi_cal_dac_tb is
end spi_cal_dac_tb;

architecture TB_ARCH of spi_cal_dac_tb is
      -- Component declaration of the tested unit
    component spi_cal_dac 
        generic (
            CLK_RATIO : integer := 2;
            COUNTER_WIDTH : integer := 2);
        port (
            clk               : in std_logic;
            rst_n             : in std_logic;
            data_in           : in std_logic_vector(11 downto 0);
            trigger_send_data : in std_logic;
            spi_sclk          : out std_logic;
            spi_mosi          : out std_logic;
            spi_syncn         : out std_logic);
    end component spi_cal_dac;

    constant CLK_RATIO     : integer := 2;
    constant COUNTER_WIDTH : integer := 2;
    constant Tpd : time := 10.0 ns; -- 100 MHz

    constant data_in : std_logic_vector(11 downto 0) := "101010000101";

    signal clk               : std_logic;
    signal rst_n             : std_logic := '1';
    signal trigger_send_data : std_logic := '0';
    signal spi_sclk          : std_logic;
    signal spi_mosi          : std_logic;
    signal spi_syncn         : std_logic;

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
        trigger_send_data <= '0';
        wait for 10 * Tpd;
        trigger_send_data <= '1';
        wait for 1 * Tpd;
        trigger_send_data <= '0';
        wait;
    end process;

    UUT : spi_cal_dac 
        generic map (
            CLK_RATIO     => CLK_RATIO,
            COUNTER_WIDTH => COUNTER_WIDTH)
        port map (
            clk               => clk,
            rst_n             => rst_n,
            data_in           => data_in,
            trigger_send_data => trigger_send_data,
            spi_sclk          => spi_sclk,
            spi_mosi          => spi_mosi,
            spi_syncn         => spi_syncn);
                        
end TB_ARCH;

-- vim: set ts=4 sw=4 sts=4 et:
