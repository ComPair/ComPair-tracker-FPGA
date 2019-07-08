library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vata460p3_interface is
    Port ( clk        : in std_logic;
           set_config : in std_logic;
           get_config : in std_logic;
           s0         : out std_logic;
           s1         : out std_logic;
           s2         : out std_logic;
           s_latch    : out std_logic := '0';
           i1         : out std_logic;
           i3         : out std_logic;
           i4         : out std_logic;
           o5         : in std_logic;
           dread      : in std_logic_vector (31 downto 0);
           addr       : out std_logic_vector (31 downto 0);
           dwrite     : out std_logic_vector (31 downto 0);
           bram_en    : out std_logic;
           bram_wea   : out std_logic_vector (3 downto 0) := (others => '0');
           -- driver_state_out is temporary, for debugging
           driver_state_out : out std_logic_vector (7 downto 0)); 
end vata460p3_interface;

architecture Behavioral of vata460p3_interface is
    signal driver_state       : std_logic_vector (7 downto 0) := x"00";
    signal mode               : std_logic_vector (2 downto 0) := "111";
    signal trigger_set_config : std_logic := '0';
    signal trigger_get_config : std_logic := '0';
    signal last_set_config    : std_logic := '1';
    signal last_get_config    : std_logic := '1';
    signal config_reg         : unsigned (519 downto 0) := (others => '0');
    signal reg_count          : unsigned (9 downto 0) := (others => '0');
    signal uaddr              : unsigned (31 downto 0) := (others => '0');

    -- It takes 17 32-bit entries in ram to contain 520 bits
    -- so final BRAM address is 4 * 16 = 64:
    constant HIGH_ADDR : unsigned (31 downto 0) := to_unsigned(64, 32);
    constant REG_LEN   : unsigned(9 downto 0) := to_unsigned(520, 10);
begin

    p_trigger : process (clk) is
    begin
        if rising_edge(clk) then
            if set_config = '1' and last_set_config = '0' then
                trigger_set_config <= '1';
                trigger_get_config <= '0';
            elsif get_config = '1' and last_get_config = '0' then
                trigger_get_config <= '1';
                trigger_set_config <= '0';
            else
                trigger_set_config <= '0';
                trigger_get_config <= '0';
            end if;
            last_set_config <= set_config;
            last_get_config <= get_config;
        end if;
    end process p_trigger;

    p_main : process (clk) is
    begin
        if rising_edge(clk) then
            case driver_state is
                when x"00" =>
                    -- Look for triggers to set or get ASIC configuration register
                    if trigger_set_config = '1' then
                        -- Setting taking precedence over getting
                        -- Start reading in bram values to the config reg...
                        -- Note that read latency is 1...
                        uaddr <= (others => '0');
                        i1 <= '0';
                        i3 <= '0';
                        i4 <= '0';
                        driver_state <= x"01";
                    elsif trigger_get_config = '1' then
                        -- Start get config...
                        mode <= "001";
                        driver_state <= x"10";
                    end if;
                -- Start of "set config" states
                when x"01" =>
                    -- Delay for read.
                    uaddr <= to_unsigned(4, uaddr'length);
                    driver_state <= x"02";
                when x"02" =>
                    config_reg <= shift_right(config_reg, 32);
                    config_reg(519 downto 488) <= unsigned(dread);
                    if uaddr = HIGH_ADDR then
                        -- End of successive bram addressing.
                        -- Get current dread and next one.
                        uaddr <= (others => '0');
                        driver_state <= x"03";
                    else
                        uaddr <= uaddr + to_unsigned(4, uaddr'length);
                        driver_state <= x"02";
                    end if;
                when x"03" =>
                    -- Get final 8 bits.
                    config_reg <= shift_right(config_reg, 8);
                    config_reg(519 downto 512) <= unsigned(dread(7 downto 0));
                    driver_state <= x"04";
                when x"04" =>
                    -- config_reg is now full.
                    -- Set ASIC mode to set config register.
                    mode <= "000";
                    driver_state <= x"05";
                when x"05" =>
                    s_latch <= '1';
                    i4 <= '1';
                    reg_count <= (others => '0');
                    driver_state <= x"06"; -- Start sending data to ASIC
                when x"06" =>
                    -- Send data into ASIC shift register
                    s_latch <= '0';
                    i1 <= '1';
                    i3 <= config_reg(519);
                    config_reg <= shift_left(config_reg, 1);
                    reg_count <= reg_count + to_unsigned(1, reg_count'length);
                    driver_state <= x"07";
                when x"07" =>
                    i1 <= '0';
                    if reg_count = REG_LEN then
                        -- Done sending data to ASIC
                        i3 <= '0';
                        i4 <= '0';
                        -- Unsure what to do here... do we change the mode to "111"???
                        -- Yes for now, as that is a meaningless ASIC mode at this point.
                        mode <= "111";
                        driver_state <= x"08";
                    else
                        -- Go send another bit.
                        driver_state <= x"06";
                    end if;
                when x"08" =>
                    -- Lock in ASIC mode to "111"
                    s_latch <= '1';
                    driver_state <= x"09";
                when x"09" =>
                    -- End of set_config.
                    s_latch <= '0';
                    driver_state <= x"00";
                -- Start of "get config" states.
                when x"10" =>
                    s_latch <= '1';
                    reg_count <= (others => '0');
                    driver_state <= x"20";
                when x"20" =>
                    if reg_count = REG_LEN then
                        -- Done reading in  Change to mode "111" then start writing to BRAM
                        mode <= "111";
                        driver_state <= x"40";
                    else
                        s_latch <= '0';
                        i1 <= '1';
                        config_reg <= shift_left(config_reg, 1);
                        driver_state <= x"30";
                    end if;
                when x"30" =>
                    i1 <= '0';
                    config_reg(0) <= o5;
                    reg_count <= reg_count + to_unsigned(1, reg_count'length);
                    driver_state <= x"20";
                when x"40" =>
                    -- Start sending data into BRAM
                    s_latch <= '1';
                    bram_wea <= (others => '1');
                    uaddr <= (others => '0');
                    dwrite <= std_logic_vector(config_reg(31 downto 0));
                    config_reg <= shift_right(config_reg, 32);
                    driver_state <= x"50";
                when x"50" =>
                    if uaddr = HIGH_ADDR then
                        -- All done.
                        bram_wea <= (others => '0');
                        driver_state <= x"00";
                    else
                        s_latch <= '0';
                        uaddr <= uaddr + to_unsigned(4, uaddr'length);
                        dwrite <= std_logic_vector(config_reg(31 downto 0));
                        config_reg <= shift_right(config_reg, 32);
                        driver_state <= x"50";
                    end if;
                when others =>
                    -- Should not be here!
                    -- Reset driver state???
                    driver_state <= x"00";
            end case;
        end if;
    end process p_main;

    addr <= std_logic_vector(uaddr);
    bram_en <= '1';

    s0 <= mode(0);
    s1 <= mode(1);
    s2 <= mode(2);

    driver_state_out <= driver_state;

end Behavioral;
