library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_axi_interface_fsm is
	port (
        clk_100MHz         : in std_logic; -- 100 ns
        rst_n              : in std_logic;
        trigger_get_config : in std_logic;
        trigger_set_config : in std_logic;
        vata_s0            : out std_logic;
        vata_s1            : out std_logic;
        vata_s2            : out std_logic;
        vata_s_latch       : out std_logic;
        vata_i1_out            : out std_logic;
        vata_i3_out            : out std_logic;
        vata_i4_out            : out std_logic;
        vata_o5            : in std_logic;
        vata_o6            : in std_logic;
        bram_addr          : out std_logic_vector(31 downto 0);
        bram_dwrite        : out std_logic_vector(31 downto 0);
        bram_wea           : out std_logic_vector (3 downto 0) := (others => '0'); 
        cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
        -- DEBUG --
        state_counter_out  : out std_logic_vector(15 downto 0);
        --cfg_reg_indx_out        : out std_logic_vector(9 downto 0);
        state_out          : out std_logic_vector(7 downto 0));
end vata_460p3_axi_interface_fsm;

architecture arch_imp of vata_460p3_axi_interface_fsm is

    type state_type is (IDLE,
                        SET_CONFIG_INIT_SET_MODE, SET_CONFIG_INIT_LATCH_MODE,
                        SET_CONFIG_S2_START, SET_CONFIG_S2,
                        SET_CONFIG_S3_START, SET_CONFIG_S3,
                        SET_CONFIG_S4_START, SET_CONFIG_S4,
                        SET_CONFIG_S5_START, SET_CONFIG_S5,
                        SET_CONFIG_S6_START, SET_CONFIG_S6,
                        SET_CONFIG_S7_START, SET_CONFIG_S7,
                        SET_CONFIG_S8_START, SET_CONFIG_S8,
                        SET_CONFIG_S9_START, SET_CONFIG_S9,
                        GET_CONFIG_INIT_SET_MODE, GET_CONFIG_INIT_LATCH_MODE,
                        GET_CONFIG_S2_START, GET_CONFIG_S2,
                        GET_CONFIG_S3_START, GET_CONFIG_S3,
                        GET_CONFIG_WBRAM_0, GET_CONFIG_WBRAM_1, GET_CONFIG_WBRAM_2, GET_CONFIG_WBRAM_3,
                        GET_CONFIG_WBRAM_4, GET_CONFIG_WBRAM_5, GET_CONFIG_WBRAM_6, GET_CONFIG_WBRAM_7,
                        GET_CONFIG_WBRAM_8, GET_CONFIG_WBRAM_9, GET_CONFIG_WBRAM_10, GET_CONFIG_WBRAM_11,
                        GET_CONFIG_WBRAM_12, GET_CONFIG_WBRAM_13, GET_CONFIG_WBRAM_14, GET_CONFIG_WBRAM_15,
                        GET_CONFIG_WBRAM_16,
                        GET_CONFIG_FINISH_SET_MODE_START, GET_CONFIG_FINISH_SET_MODE,
                        GET_CONFIG_FINISH_LATCH_MODE_START, GET_CONFIG_FINISH_LATCH_MODE,
                        GET_CONFIG_DONE
                    );

    signal current_state            : state_type := IDLE;
    signal next_state               : state_type;
    signal state_counter            : unsigned(15 downto 0) := (others => '0');
    signal start_state_counter : std_logic := '0';
    signal last_start_state_counter : std_logic := '0';

    signal vata_mode : std_logic_vector(2 downto 0);
    signal vata_i1 : std_logic;
    signal vata_i3 : std_logic;
    signal vata_i4 : std_logic;

    signal bram_uaddr : unsigned(31 downto 0) := (others => '0');

    signal cfg_reg_from_vata : unsigned(519 downto 0);
    signal cfg_reg_count     : unsigned (9 downto 0) := (others => '0');
    signal cfg_reg_indx      : integer range -1 to 519 := 0;

    constant CFG_REG_LEN     : unsigned(9 downto 0) := to_unsigned(520, 10);

begin

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_100MHz) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, trigger_set_config, trigger_get_config, state_counter, cfg_reg_indx)
    begin
        if rst_n = '0' then
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if trigger_set_config = '1' then
                        next_state <= SET_CONFIG_INIT_SET_MODE;
                    elsif trigger_get_config = '1' then
                        next_state <= GET_CONFIG_INIT_SET_MODE;
                    end if;
                when SET_CONFIG_INIT_SET_MODE =>
                    next_state <= SET_CONFIG_INIT_LATCH_MODE;
                when SET_CONFIG_INIT_LATCH_MODE =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S2_START;
                    else
                        next_state <= SET_CONFIG_INIT_LATCH_MODE;
                    end if;
                when SET_CONFIG_S2_START =>
                    next_state <= SET_CONFIG_S2;
                when SET_CONFIG_S2 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S3_START;
                    else
                        next_state <= SET_CONFIG_S2;
                    end if;
                when SET_CONFIG_S3_START =>
                    next_state <= SET_CONFIG_S3;
                when SET_CONFIG_S3 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        if cfg_reg_indx = -1 then
                            next_state <= SET_CONFIG_S7_START;
                        else
                            next_state <= SET_CONFIG_S4_START;
                        end if;
                    else
                        next_state <= SET_CONFIG_S3;
                    end if;
                when SET_CONFIG_S4_START =>
                    next_state <= SET_CONFIG_S4;
                when SET_CONFIG_S4 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S5_START;
                    else
                        next_state <= SET_CONFIG_S4;
                    end if;
                when SET_CONFIG_S5_START =>
                    next_state <= SET_CONFIG_S5;
                when SET_CONFIG_S5 =>
                   if state_counter >= to_unsigned(999, state_counter'length) then -- 10us
                        next_state <= SET_CONFIG_S3_START;
                   else
                        next_state <= SET_CONFIG_S5;
                   end if;
                when SET_CONFIG_S6_START =>
                    next_state <= SET_CONFIG_S6;
                when SET_CONFIG_S6 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S7_START;
                    else
                        next_state <= SET_CONFIG_S6;
                    end if;
                when SET_CONFIG_S7_START =>
                    next_state <= SET_CONFIG_S7;
                when SET_CONFIG_S7 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S8_START;
                    else
                        next_state <= SET_CONFIG_S9;
                    end if;
                when SET_CONFIG_S8_START =>
                    next_state <= SET_CONFIG_S8;
                when SET_CONFIG_S8 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= SET_CONFIG_S9;
                    else
                        next_state <= SET_CONFIG_S8;
                    end if;
                when SET_CONFIG_S9 =>
                    next_state <= IDLE;
                when GET_CONFIG_INIT_SET_MODE =>
                    next_state <= GET_CONFIG_INIT_LATCH_MODE;
                when GET_CONFIG_INIT_LATCH_MODE =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= GET_CONFIG_S2_START;
                    else
                        next_state <= GET_CONFIG_INIT_LATCH_MODE;
                    end if;
                when GET_CONFIG_S2_START =>
                    next_state <= GET_CONFIG_S2;
                when GET_CONFIG_S2 =>
                    if state_counter >= to_unsigned(999, state_counter'length) then -- 10us
                        if cfg_reg_count >= CFG_REG_LEN then
                            next_state <= GET_CONFIG_WBRAM_0;
                        else
                            next_state <= GET_CONFIG_S3_START;
                        end if;
                    else
                        next_state <= GET_CONFIG_S2;
                    end if;
                when GET_CONFIG_S3_START =>
                    next_state <= GET_CONFIG_S3;
                when GET_CONFIG_S3 =>
                    if state_counter >= to_unsigned(999, state_counter'length) then -- 10us
                        next_state <= GET_CONFIG_S2_START;
                    else
                        next_state <= GET_CONFIG_S3;
                    end if;
                when GET_CONFIG_WBRAM_0 =>
                    next_state <= GET_CONFIG_WBRAM_1;
                when GET_CONFIG_WBRAM_1 =>
                    next_state <= GET_CONFIG_WBRAM_2;
                when GET_CONFIG_WBRAM_2 =>
                    next_state <= GET_CONFIG_WBRAM_3;
                when GET_CONFIG_WBRAM_3 =>
                    next_state <= GET_CONFIG_WBRAM_4;
                when GET_CONFIG_WBRAM_4 =>
                    next_state <= GET_CONFIG_WBRAM_5;
                when GET_CONFIG_WBRAM_5 =>
                    next_state <= GET_CONFIG_WBRAM_6;
                when GET_CONFIG_WBRAM_6 =>
                    next_state <= GET_CONFIG_WBRAM_7;
                when GET_CONFIG_WBRAM_7 =>
                    next_state <= GET_CONFIG_WBRAM_8;
                when GET_CONFIG_WBRAM_8 =>
                    next_state <= GET_CONFIG_WBRAM_9;
                when GET_CONFIG_WBRAM_9 =>
                    next_state <= GET_CONFIG_WBRAM_10;
                when GET_CONFIG_WBRAM_10 =>
                    next_state <= GET_CONFIG_WBRAM_11;
                when GET_CONFIG_WBRAM_11 =>
                    next_state <= GET_CONFIG_WBRAM_12;
                when GET_CONFIG_WBRAM_12 =>
                    next_state <= GET_CONFIG_WBRAM_13;
                when GET_CONFIG_WBRAM_13 =>
                    next_state <= GET_CONFIG_WBRAM_14;
                when GET_CONFIG_WBRAM_14 =>
                    next_state <= GET_CONFIG_WBRAM_15;
                when GET_CONFIG_WBRAM_15 =>
                    next_state <= GET_CONFIG_WBRAM_16;
                when GET_CONFIG_WBRAM_16 =>
                    next_state <= GET_CONFIG_FINISH_SET_MODE_START;
                when GET_CONFIG_FINISH_SET_MODE_START =>
                    next_state <= GET_CONFIG_FINISH_SET_MODE;
                when GET_CONFIG_FINISH_SET_MODE =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= GET_CONFIG_FINISH_LATCH_MODE_START;
                    else
                        next_state <= GET_CONFIG_FINISH_SET_MODE;
                    end if;
                when GET_CONFIG_FINISH_LATCH_MODE_START =>
                    next_state <= GET_CONFIG_FINISH_LATCH_MODE;
                when GET_CONFIG_FINISH_LATCH_MODE =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        next_state <= GET_CONFIG_DONE;
                    else
                        next_state <= GET_CONFIG_FINISH_LATCH_MODE;
                    end if;
                when GET_CONFIG_DONE =>
                    next_state <= IDLE;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        case (current_state) is
            when IDLE =>
                vata_i1 <= '0';
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '0';
            when SET_CONFIG_INIT_SET_MODE =>
                -- Set mode lines, prepare to latch
                vata_i1 <= '0';
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '1';
                vata_mode <= "000";
            when SET_CONFIG_INIT_LATCH_MODE =>
                -- Latch the mode in.
                vata_s_latch <= '1';
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '0';
            when SET_CONFIG_S2_START =>
                -- Initialize cfg reg index
                vata_s_latch <= '0';
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                cfg_reg_indx <= 519;
                start_state_counter <= '1';
            when SET_CONFIG_S2 =>
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '1';
            when SET_CONFIG_S3_START =>
                -- Lower i1 clock
                vata_i1 <= '0';
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '1';
            when SET_CONFIG_S3 =>
                vata_i1 <= '0';
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '0';
            when SET_CONFIG_S4_START =>
                -- Set data on i3
                vata_i1 <= vata_i1;
                vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                vata_i4 <= vata_i4;
                start_state_counter <= '1';
            when SET_CONFIG_S4 =>
                vata_i1 <= vata_i1;
                vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                vata_i4 <= vata_i4;
                start_state_counter <= '0';
            when SET_CONFIG_S5_START =>
                -- Raise i1 clock
                vata_i1 <= '1';
                vata_i3 <= vata_i3;
                vata_i4 <= '1';
                cfg_reg_indx <= cfg_reg_indx - 1;
                start_state_counter <= '1';
            when SET_CONFIG_S5 =>
                vata_i1 <= '1';
                vata_i3 <= vata_i3;
                vata_i4 <= '1';
                start_state_counter <= '0';
            when SET_CONFIG_S6_START =>
                -- Done shifting in data
                vata_i1 <= vata_i1;
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '1';
            when SET_CONFIG_S6 =>
                vata_i1 <= vata_i1;
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '0';
            when SET_CONFIG_S7_START =>
                -- Set mode to data acquisition
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                vata_mode <= "010";
                start_state_counter <= '1';
            when SET_CONFIG_S7 =>
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                vata_mode <= "010";
                start_state_counter <= '0';
            when SET_CONFIG_S8_START =>
                -- Latch in daq mode
                vata_s_latch <= '1';
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '1';
            when SET_CONFIG_S8 =>
                vata_s_latch <= '1';
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
                start_state_counter <= '0';
            when SET_CONFIG_S9 =>
                -- Done setting config.
                vata_s_latch <= '0';
                vata_i1 <= vata_i1;
                vata_i3 <= vata_i3;
                vata_i4 <= vata_i4;
            when GET_CONFIG_INIT_SET_MODE =>
                -- Set mode lines, prepare to latch
                vata_i1 <= '0';
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '1';
                vata_mode <= "001";
            when GET_CONFIG_INIT_LATCH_MODE =>
                -- Latch the mode in.
                start_state_counter <= '0';
                vata_s_latch <= '1';
                cfg_reg_count <= (others => '0');
            when GET_CONFIG_S2_START =>
                start_state_counter <= '1';
                vata_s_latch <= '0';
                vata_i1 <= '0';
                cfg_reg_from_vata(0) <= vata_o5;
                cfg_reg_count <= cfg_reg_count + to_unsigned(1, cfg_reg_count'length);
            when GET_CONFIG_S2 =>
                start_state_counter <= '0';
            when GET_CONFIG_S3_START =>
                start_state_counter <= '1';
                vata_i1 <= '1';
                cfg_reg_from_vata <= shift_left(cfg_reg_from_vata, 1);
            when GET_CONFIG_S3 =>
                start_state_counter <= '0';
            when GET_CONFIG_WBRAM_0 =>
                -- Change to start writing BRAM...
                -- We could probably do away with the shift right and index directly???
                bram_wea <= (others => '1');
                bram_uaddr <= (others => '0');
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_1 =>
                bram_uaddr  <= to_unsigned(4, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_2 =>
                bram_uaddr  <= to_unsigned(8, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_3 =>
                bram_uaddr  <= to_unsigned(12, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_4 =>
                bram_uaddr  <= to_unsigned(16, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_5 =>
                bram_uaddr  <= to_unsigned(20, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_6 =>
                bram_uaddr  <= to_unsigned(24, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_7 =>
                bram_uaddr  <= to_unsigned(28, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_8 =>
                bram_uaddr  <= to_unsigned(32, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_9 =>
                bram_uaddr  <= to_unsigned(36, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_10 =>
                bram_uaddr  <= to_unsigned(40, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_11 =>
                bram_uaddr  <= to_unsigned(44, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_12 =>
                bram_uaddr  <= to_unsigned(48, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_13 =>
                bram_uaddr  <= to_unsigned(52, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_14 =>
                bram_uaddr  <= to_unsigned(56, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_15 =>
                bram_uaddr  <= to_unsigned(60, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_WBRAM_16 =>
                bram_uaddr  <= to_unsigned(64, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
            when GET_CONFIG_FINISH_SET_MODE_START =>
                start_state_counter <= '1';
                bram_wea <= (others => '0');
                vata_mode <= "010";
            when GET_CONFIG_FINISH_SET_MODE =>
                start_state_counter <= '0';
            when GET_CONFIG_FINISH_LATCH_MODE_START =>
                start_state_counter <= '1';
                vata_s_latch <= '1';
            when GET_CONFIG_FINISH_LATCH_MODE =>
                start_state_counter <= '0';
            when GET_CONFIG_DONE =>
                vata_s_latch <= '0';
            when others =>
                vata_i1 <= '0';
                vata_i3 <= '0';
                vata_i4 <= '0';
                start_state_counter <= '0';
        end case;
    end process;

    process (clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if last_start_state_counter = '0' and start_state_counter = '1' then
                state_counter <= (others => '0');
            else
                state_counter <= state_counter + to_unsigned(1, state_counter'length);
            end if;
            last_start_state_counter <= start_state_counter;
        end if;
    end process;

    bram_addr <= std_logic_vector(bram_uaddr);

    vata_s0 <= vata_mode(0);
    vata_s1 <= vata_mode(1);
    vata_s2 <= vata_mode(2);
    vata_i1_out <= vata_i1;
    vata_i3_out <= vata_i3;
    vata_i4_out <= vata_i4;

    state_out <=
       x"00" when current_state = IDLE else
       x"01" when current_state = SET_CONFIG_INIT_SET_MODE else
       x"02" when current_state = SET_CONFIG_INIT_LATCH_MODE else
       x"03" when current_state = SET_CONFIG_S2_START else
       x"04" when current_state = SET_CONFIG_S2 else
       x"05" when current_state = SET_CONFIG_S3_START else
       x"06" when current_state = SET_CONFIG_S3 else
       x"07" when current_state = SET_CONFIG_S4_START else
       x"08" when current_state = SET_CONFIG_S4 else
       x"09" when current_state = SET_CONFIG_S5_START else
       x"0A" when current_state = SET_CONFIG_S5 else
       x"0B" when current_state = SET_CONFIG_S6_START else
       x"0C" when current_state = SET_CONFIG_S6 else
       x"0D" when current_state = SET_CONFIG_S7_START else
       x"0E" when current_state = SET_CONFIG_S7 else
       x"0F" when current_state = SET_CONFIG_S8_START else
       x"10" when current_state = SET_CONFIG_S8 else
       x"11" when current_state = SET_CONFIG_S9_START else
       x"12" when current_state = SET_CONFIG_S9 else
       x"13" when current_state = GET_CONFIG_INIT_SET_MODE else
       x"14" when current_state = GET_CONFIG_INIT_LATCH_MODE else
       x"15" when current_state = GET_CONFIG_S2_START else
       x"16" when current_state = GET_CONFIG_S2 else
       x"17" when current_state = GET_CONFIG_S3_START else
       x"18" when current_state = GET_CONFIG_S3 else
       x"19" when current_state = GET_CONFIG_WBRAM_0 else
       x"1A" when current_state = GET_CONFIG_WBRAM_1 else
       x"1B" when current_state = GET_CONFIG_WBRAM_2 else
       x"1C" when current_state = GET_CONFIG_WBRAM_3 else
       x"1D" when current_state = GET_CONFIG_WBRAM_4 else
       x"1E" when current_state = GET_CONFIG_WBRAM_5 else
       x"1F" when current_state = GET_CONFIG_WBRAM_6 else
       x"21" when current_state = GET_CONFIG_WBRAM_7 else
       x"22" when current_state = GET_CONFIG_WBRAM_8 else
       x"23" when current_state = GET_CONFIG_WBRAM_9 else
       x"24" when current_state = GET_CONFIG_WBRAM_10 else
       x"25" when current_state = GET_CONFIG_WBRAM_11 else
       x"26" when current_state = GET_CONFIG_WBRAM_12 else
       x"27" when current_state = GET_CONFIG_WBRAM_13 else
       x"28" when current_state = GET_CONFIG_WBRAM_14 else
       x"29" when current_state = GET_CONFIG_WBRAM_15 else
       x"2A" when current_state = GET_CONFIG_WBRAM_16 else
       x"2B" when current_state = GET_CONFIG_FINISH_SET_MODE_START else
       x"2C" when current_state = GET_CONFIG_FINISH_SET_MODE else
       x"2D" when current_state = GET_CONFIG_FINISH_LATCH_MODE_START else
       x"2E" when current_state = GET_CONFIG_FINISH_LATCH_MODE else
       x"2F" when current_state = GET_CONFIG_DONE else
       x"FF";

    state_counter_out <= std_logic_vector(state_counter);
    --cfg_reg_indx_out <= std_logic_vector(to_signed(cfg_reg_indx, cfg_reg_indx'length));

end arch_imp;



