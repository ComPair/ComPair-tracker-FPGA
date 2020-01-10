library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_cal_dac is
    generic (
        CLK_RATIO : integer; -- spi clock freq is clk in freq / 2 / CLK_RATIO
        COUNTER_WIDTH : integer
        ); 
    port ( 
        clk : in std_logic;
        rst_n : in std_logic;
        data_in : in std_logic_vector(11 downto 0);
        trigger_send_data : in std_logic;
        spi_sclk : out std_logic;
        spi_mosi : out std_logic;
        spi_syncn : out std_logic
        );
end spi_cal_dac;

architecture arch_imp of spi_cal_dac is
    constant STATE_WIDTH : integer := 8;
    constant IDLE   : std_logic_vector(STATE_WIDTH-1 downto 0) := x"00";
    constant RCLK0  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"01";
    constant LCLK0  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"02";
    constant RCLK1  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"03";
    constant LCLK1  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"04";
    constant RCLK2  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"05";
    constant LCLK2  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"06";
    constant RCLK3  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"07";
    constant LCLK3  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"08";
    constant RCLK4  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"09";
    constant LCLK4  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0A";
    constant RCLK5  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0B";
    constant LCLK5  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0C";
    constant RCLK6  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0D";
    constant LCLK6  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0E";
    constant RCLK7  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"0F";
    constant LCLK7  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"10";
    constant RCLK8  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"11";
    constant LCLK8  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"12";
    constant RCLK9  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"13";
    constant LCLK9  : std_logic_vector(STATE_WIDTH-1 downto 0) := x"14";
    constant RCLK10 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"15";
    constant LCLK10 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"16";
    constant RCLK11 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"17";
    constant LCLK11 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"18";
    constant RCLK12 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"19";
    constant LCLK12 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1A";
    constant RCLK13 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1B";
    constant LCLK13 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1C";
    constant RCLK14 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1D";
    constant LCLK14 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1E";
    constant RCLK15 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"1F";
    constant LCLK15 : std_logic_vector(STATE_WIDTH-1 downto 0) := x"20";
    
    constant COUNTER_MAX : unsigned(COUNTER_WIDTH-1 downto 0) := to_unsigned(CLK_RATIO-1, COUNTER_WIDTH);
    signal counter       : unsigned(COUNTER_WIDTH-1 downto 0) := (others => '0');
    signal counter_clr   : std_logic := '0';

    signal current_state : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');
    signal next_state    : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');

    signal trigger_rising_edge : std_logic := '0';
    signal last_trigger_send   : std_logic := '0';
    
begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            last_trigger_send   <= '0';
            trigger_rising_edge <= '0';
        elsif rising_edge(clk) then
            if trigger_send_data = '1' and last_trigger_send = '0' then
                trigger_rising_edge <= '1';
            else
                trigger_rising_edge <= '0';
            end if;
            last_trigger_send <= trigger_send_data;
        end if;
    end process;

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state; 
        end if;
    end process;

    process (rst_n, current_state, trigger_rising_edge, counter)
    begin
        if rst_n = '0' then
            next_state <= IDLE;
        else
            counter_clr <= '0';
            case (current_state) is
                when IDLE =>
                    if trigger_rising_edge = '1' then
                        counter_clr <= '1';
                        next_state <= RCLK0;
                    else
                        next_state <= IDLE;
                    end if;
                when RCLK0 =>
                    if counter = COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK0;
                    else
                        next_state <= RCLK0;
                    end if;
                when LCLK0 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK1;
                    else
                        next_state <= LCLK0;
                    end if;
                when RCLK1 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK1;
                    else
                        next_state <= RCLK1;
                    end if;
                when LCLK1 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK2;
                    else
                        next_state <= LCLK1;
                    end if;
                when RCLK2 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK2;
                    else
                        next_state <= RCLK2;
                    end if;
                when LCLK2 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK3;
                    else
                        next_state <= LCLK2;
                    end if;
                when RCLK3 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK3;
                    else
                        next_state <= RCLK3;
                    end if;
                when LCLK3 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK4;
                    else
                        next_state <= LCLK3;
                    end if;
                when RCLK4 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK4;
                    else
                        next_state <= RCLK4;
                    end if;
                when LCLK4 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK5;
                    else
                        next_state <= LCLK4;
                    end if;
                when RCLK5 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK5;
                    else
                        next_state <= RCLK5;
                    end if;
                when LCLK5 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK6;
                    else
                        next_state <= LCLK5;
                    end if;
                when RCLK6 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK6;
                    else
                        next_state <= RCLK6;
                    end if;
                when LCLK6 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK7;
                    else
                        next_state <= LCLK6;
                    end if;
                when RCLK7 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK7;
                    else
                        next_state <= RCLK7;
                    end if;
                when LCLK7 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK8;
                    else
                        next_state <= LCLK7;
                    end if;
                when RCLK8 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK8;
                    else
                        next_state <= RCLK8;
                    end if;
                when LCLK8 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK9;
                    else
                        next_state <= LCLK8;
                    end if;
                when RCLK9 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK9;
                    else
                        next_state <= RCLK9;
                    end if;
                when LCLK9 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK10;
                    else
                        next_state <= LCLK9;
                    end if;
                when RCLK10 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK10;
                    else
                        next_state <= RCLK10;
                    end if;
                when LCLK10 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK11;
                    else
                        next_state <= LCLK10;
                    end if;
                when RCLK11 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK11;
                    else
                        next_state <= RCLK11;
                    end if;
                when LCLK11 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK12;
                    else
                        next_state <= LCLK11;
                    end if;
                when RCLK12 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK12;
                    else
                        next_state <= RCLK12;
                    end if;
                when LCLK12 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK13;
                    else
                        next_state <= LCLK12;
                    end if;
                when RCLK13 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK13;
                    else
                        next_state <= RCLK13;
                    end if;
                when LCLK13 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK14;
                    else
                        next_state <= LCLK13;
                    end if;
                when RCLK14 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK14;
                    else
                        next_state <= RCLK14;
                    end if;
                when LCLK14 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= RCLK15;
                    else
                        next_state <= LCLK14;
                    end if;
                when RCLK15 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= LCLK15;
                    else
                        next_state <= RCLK15;
                    end if;
                when LCLK15 =>
                    if counter >= COUNTER_MAX then
                        counter_clr <= '1';
                        next_state <= IDLE;
                    else
                        next_state <= LCLK15;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        spi_syncn <= '0';
        spi_mosi  <= '0';
        case (current_state) is
            when IDLE =>
                spi_sclk  <= '0';
                spi_syncn <= '1';
            when RCLK0 => 
                spi_sclk <= '1';
            when LCLK0 => 
                spi_sclk <= '0';
            when RCLK1 =>
                spi_sclk <= '1';
            when LCLK1 =>
                spi_sclk <= '0';
            when RCLK2 =>
                spi_sclk <= '1';
            when LCLK2 =>
                spi_sclk <= '0';
            when RCLK3 =>
                spi_sclk <= '1';
            when LCLK3 =>
                spi_sclk <= '0';
            when RCLK4 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(11);
            when LCLK4 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(11);
            when RCLK5 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(10);
            when LCLK5 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(10);
            when RCLK6 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(9);
            when LCLK6 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(9);
            when RCLK7 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(8);
            when LCLK7 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(8);
            when RCLK8 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(7);
            when LCLK8 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(7);
            when RCLK9 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(6);
            when LCLK9 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(6);
            when RCLK10 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(5);
            when LCLK10 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(5);
            when RCLK11 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(4);
            when LCLK11 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(4);
            when RCLK12 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(3);
            when LCLK12 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(3);
            when RCLK13 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(2);
            when LCLK13 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(2);
            when RCLK14 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(1);
            when LCLK14 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(1);
            when RCLK15 =>
                spi_sclk <= '1';
                spi_mosi <= data_in(0);
            when LCLK15 =>
                spi_sclk <= '0';
                spi_mosi <= data_in(0);
                spi_syncn <= '1';
            when others =>
                spi_sclk <= '0';
                spi_mosi <= '0';
                spi_syncn <= '1';
        end case;
    end process;

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if counter_clr = '1' then
                counter <= (others => '0');
            else
                counter <= counter + to_unsigned(1, counter'length);
            end if;
        else
            counter <= counter;
        end if;
    end process;

end arch_imp;

-- vim: set ts=4 sw=4 sts=4 et:
