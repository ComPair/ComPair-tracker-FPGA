library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_iface_fsm is
        port (
                clk_100MHz         : in std_logic; -- 10 ns
                rst_n              : in std_logic;
                trigger_get_config : in std_logic;
                trigger_set_config : in std_logic;
                vata_s0            : out std_logic;
                vata_s1            : out std_logic;
                vata_s2            : out std_logic;
                vata_s_latch       : out std_logic;
                vata_i1_out        : out std_logic;
                vata_i3_out        : out std_logic;
                vata_i4_out        : out std_logic;
                vata_o5            : in std_logic;
                vata_o6            : in std_logic;
                bram_addr          : out std_logic_vector(31 downto 0);
                bram_dwrite        : out std_logic_vector(31 downto 0);
                bram_wea           : out std_logic_vector (3 downto 0) := (others => '0');
                cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
                -- DEBUG --
                state_counter_out  : out std_logic_vector(15 downto 0);
                cfg_reg_indx_out   : out std_logic_vector(9 downto 0);
                cfg_reg_from_vata_out  : out std_logic_vector(7 downto 0);
                state_out          : out std_logic_vector(7 downto 0));
    end vata_460p3_iface_fsm;

architecture arch_imp of vata_460p3_iface_fsm is

    constant STATE_BITWIDTH : integer := 8;
    constant IDLE              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"00";
    constant SC_SET_MODE_M1    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"01";
    constant SC_LATCH_MODE_M1  : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"02";
    constant SC_LOWER_LATCH_M1 : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"03";
    constant SC_SET_DATA_I3    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"04";
    constant SC_CLOCK_DATA     : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"05";
    constant SC_LOWER_CLOCK    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"06";
    constant SC_SET_MODE_M3    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"07";
    constant SC_LATCH_MODE_M3  : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"08";
    constant GC_SET_MODE_M2    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"09";
    constant GC_LATCH_MODE_M2  : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0A";
    constant GC_LOWER_LATCH_M2 : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0B";
    constant GC_SET_DATA_I3    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0C";
    constant GC_CLOCK_DATA     : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0D";
    constant GC_SHIFT_CFG_REG  : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0E";
    constant GC_READ_O5        : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0F";
    constant GC_LOWER_CLOCK    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"10";
    constant GC_WBRAM_00       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"11";
    constant GC_WBRAM_01       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"12";
    constant GC_WBRAM_02       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"13";
    constant GC_WBRAM_03       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"14";
    constant GC_WBRAM_04       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"15";
    constant GC_WBRAM_05       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"16";
    constant GC_WBRAM_06       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"17";
    constant GC_WBRAM_07       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"18";
    constant GC_WBRAM_08       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"19";
    constant GC_WBRAM_09       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1A";
    constant GC_WBRAM_10       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1B";
    constant GC_WBRAM_11       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1C";
    constant GC_WBRAM_12       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1D";
    constant GC_WBRAM_13       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1E";
    constant GC_WBRAM_14       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1F";
    constant GC_WBRAM_15       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"20";
    constant GC_WBRAM_16       : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"21";
    constant GC_SET_MODE_M3    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"22";
    constant GC_LATCH_MODE_M3  : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"23";

    signal current_state : std_logic_vector(STATE_BITWIDTH-1 downto 0) := IDLE;
    signal next_state    : std_logic_vector(STATE_BITWIDTH-1 downto 0) := IDLE;
    signal state_counter : unsigned(15 downto 0) := (others => '0');
    signal state_counter_clr : std_logic := '0';

    signal vata_mode : std_logic_vector(2 downto 0);
    signal vata_i1 : std_logic;
    signal vata_i3 : std_logic;
    signal vata_i4 : std_logic;

    signal cfg_reg_indx : integer range 0 to 519 := 0;
    signal dec_cfg_reg_indx : std_logic;
    signal rst_cfg_reg_indx : std_logic;

    signal cfg_reg_from_vata : unsigned(519 downto 0);
    signal read_o5 : std_logic := '0';
    signal shift_cfg_reg : std_logic := '0';
    signal cfg_reg_clr : std_logic := '0';

    signal bram_uaddr : unsigned(31 downto 0);

begin

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_100MHz) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, trigger_set_config, trigger_get_config, state_counter)
    begin
        state_counter_clr <= '0';
        dec_cfg_reg_indx  <= '0';
        rst_cfg_reg_indx  <= '0';
        shift_cfg_reg     <= '0';
        cfg_reg_clr       <= '0';
        read_o5           <= '0';
        if rst_n = '0' then
            state_counter_clr <= '1';
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if trigger_set_config = '1' then
                        state_counter_clr <= '1';
                        next_state <= SC_SET_MODE_M1;
                    elsif trigger_get_config = '1' then
                        next_state <= GC_SET_MODE_M2;
                    else
                        next_state <= IDLE;
                    end if;
                when SC_SET_MODE_M1 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        rst_cfg_reg_indx <= '1';
                        next_state <= SC_LATCH_MODE_M1;
                    else
                        next_state <= SC_SET_MODE_M1;
                    end if;
                when SC_LATCH_MODE_M1 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= SC_LOWER_LATCH_M1;
                    else
                        next_state <= SC_LATCH_MODE_M1;
                    end if;
                when SC_LOWER_LATCH_M1 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= SC_SET_DATA_I3;
                    else
                        next_state <= SC_LOWER_LATCH_M1;
                    end if;
                when SC_SET_DATA_I3 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= SC_CLOCK_DATA;
                    else
                        next_state <= SC_SET_DATA_I3;
                    end if;
                when SC_CLOCK_DATA =>
                    if state_counter >= to_unsigned(999, state_counter'length) then -- 10us - 1clk
                        state_counter_clr <= '1';
                        next_state <= SC_LOWER_CLOCK;
                    else
                        next_state <= SC_CLOCK_DATA;
                    end if;
                when SC_LOWER_CLOCK =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        if cfg_reg_indx = 0 then
                            next_state <= SC_SET_MODE_M3;
                        else
                            dec_cfg_reg_indx <= '1';
                            next_state <= SC_SET_DATA_I3;
                        end if;
                    else
                        next_state <= SC_LOWER_CLOCK;
                    end if;
                when SC_SET_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= SC_LATCH_MODE_M3;
                    else
                        next_state <= SC_SET_MODE_M3;
                    end if;
                when SC_LATCH_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        next_state <= IDLE;
                    else
                        next_state <= SC_LATCH_MODE_M3;
                    end if;
                when GC_SET_MODE_M2 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        rst_cfg_reg_indx <= '1';
                        cfg_reg_clr <= '1';
                        next_state <= GC_LATCH_MODE_M2;
                    else
                        next_state <= GC_SET_MODE_M2;
                    end if;
                when GC_LATCH_MODE_M2 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= GC_LOWER_LATCH_M2;
                    else
                        next_state <= GC_LATCH_MODE_M2;
                    end if;
                when GC_LOWER_LATCH_M2 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        read_o5 <= '1';
                        next_state <= GC_SET_DATA_I3;
                    else
                        next_state <= GC_LOWER_LATCH_M2;
                    end if;
                when GC_SET_DATA_I3 =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= GC_CLOCK_DATA;
                    else
                        next_state <= GC_SET_DATA_I3;
                    end if;
                when GC_CLOCK_DATA =>
                    if cfg_reg_indx > 0 and state_counter >= to_unsigned(29, state_counter'length) then -- 300 ns
                        state_counter_clr <= '1';
                        shift_cfg_reg <= '1';
                        next_state <= GC_SHIFT_CFG_REG;
                    elsif state_counter >= to_unsigned(999, state_counter'length) then -- 10us
                        state_counter_clr <= '1';
                        next_state <= GC_LOWER_CLOCK;
                    else
                        next_state <= GC_CLOCK_DATA;
                    end if;
                when GC_SHIFT_CFG_REG =>
                    state_counter_clr <= '1';
                    read_o5 <= '1';
                    next_state <= GC_READ_O5;
                when GC_READ_O5 =>
                    if state_counter >= to_unsigned(969, state_counter'length) then -- (10us - 300 ns)
                        state_counter_clr <= '1';
                        next_state <= GC_LOWER_CLOCK;
                    else
                        next_state <= GC_READ_O5;
                    end if;
                when GC_LOWER_CLOCK =>
                    if state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        if cfg_reg_indx = 0 then
                            next_state <= GC_WBRAM_00;
                        else
                            dec_cfg_reg_indx <= '1';
                            next_state <= GC_SET_DATA_I3;
                        end if;
                    else
                        next_state <= GC_LOWER_CLOCK;
                    end if;
                when GC_WBRAM_00 => next_state <= GC_WBRAM_01;
                when GC_WBRAM_01 => next_state <= GC_WBRAM_02;
                when GC_WBRAM_02 => next_state <= GC_WBRAM_03;
                when GC_WBRAM_03 => next_state <= GC_WBRAM_04;
                when GC_WBRAM_04 => next_state <= GC_WBRAM_05;
                when GC_WBRAM_05 => next_state <= GC_WBRAM_06;
                when GC_WBRAM_06 => next_state <= GC_WBRAM_07;
                when GC_WBRAM_07 => next_state <= GC_WBRAM_08;
                when GC_WBRAM_08 => next_state <= GC_WBRAM_09;
                when GC_WBRAM_09 => next_state <= GC_WBRAM_10;
                when GC_WBRAM_10 => next_state <= GC_WBRAM_11;
                when GC_WBRAM_11 => next_state <= GC_WBRAM_12;
                when GC_WBRAM_12 => next_state <= GC_WBRAM_13;
                when GC_WBRAM_13 => next_state <= GC_WBRAM_14;
                when GC_WBRAM_14 => next_state <= GC_WBRAM_15;
                when GC_WBRAM_15 => next_state <= GC_WBRAM_16;
                when GC_WBRAM_16 => next_state <= GC_SET_MODE_M3;
                when GC_SET_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= GC_LATCH_MODE_M3;
                    else
                        next_state <= GC_SET_MODE_M3;
                    end if;
                when GC_LATCH_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        next_state <= IDLE;
                    else
                        next_state <= GC_LATCH_MODE_M3;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        case (current_state) is
            when IDLE =>
                vata_mode <= vata_mode; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            ---- Set config states ----
            when SC_SET_MODE_M1 =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_LATCH_MODE_M1 =>
                vata_mode <= "000"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_LOWER_LATCH_M1 =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_SET_DATA_I3 =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i1 <= '0';
                vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                if cfg_reg_indx = 519 then
                    vata_i4 <= '0';
                else
                    vata_i4 <= '1';
                end if;
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_CLOCK_DATA =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                vata_i1 <= '1'; vata_i4 <= '1';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_LOWER_CLOCK =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                vata_i1 <= '0'; vata_i4 <= '1';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_SET_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when SC_LATCH_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            ----Get config states----
            --- Unsure if vata_i4 should be low???
            when GC_SET_MODE_M2 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_LATCH_MODE_M2 =>
                vata_mode <= "001"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_LOWER_LATCH_M2 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_SET_DATA_I3 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i4 <= '0';
                vata_i3 <= cfg_reg_from_vata(0);
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_CLOCK_DATA =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i3 <= cfg_reg_from_vata(0);
                vata_i1 <= '1'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_SHIFT_CFG_REG =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i3 <= cfg_reg_from_vata(1); -- ??? --
                vata_i1 <= '1'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_READ_O5 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i3 <= cfg_reg_from_vata(1);
                vata_i1 <= '1'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_LOWER_CLOCK =>
                vata_mode <= "001"; vata_s_latch <= '0';
                if cfg_reg_indx = 0 then
                    vata_i3 <= cfg_reg_from_vata(0);
                else
                    vata_i3 <= cfg_reg_from_vata(1);
                end if;
                vata_i1 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
            when GC_WBRAM_00 =>
                bram_wea <= (others => '1');
                bram_uaddr <= (others => '0');
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_01 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(4, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(63 downto 32));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_02 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(8, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(95 downto 64));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_03 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(12, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(127 downto 96));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_04 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(16, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(159 downto 128));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_05 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(20, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(191 downto 160));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_06 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(24, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(223 downto 192));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_07 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(28, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(255 downto 224));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_08 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(32, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(287 downto 256));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_09 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(36, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(319 downto 288));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_10 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(40, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(351 downto 320));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_11 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(44, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(383 downto 352));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_12 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(48, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(415 downto 384));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_13 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(52, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(447 downto 416));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_14 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(56, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(479 downto 448));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_15 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(60, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(cfg_reg_from_vata(511 downto 480));
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_16 =>
                bram_wea <= (others => '1');
                bram_uaddr  <= to_unsigned(64, bram_uaddr'length);
                bram_dwrite(7 downto 0) <= std_logic_vector(cfg_reg_from_vata(519 downto 512));
                bram_dwrite(31 downto 8) <= (others => '0');
                vata_mode <= "001"; vata_s_latch <= '0'; vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_SET_MODE_M3 =>
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
                vata_mode <= "010"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_LATCH_MODE_M3 =>
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
                vata_mode <= "010"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when others =>
                vata_mode <= vata_mode; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
                bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
        end case;
    end process;

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            state_counter <= (others => '0');
        elsif rising_edge(clk_100MHz) then
            if state_counter_clr = '1' then
                state_counter <= (others => '0');
            else
                state_counter <= state_counter + to_unsigned(1, state_counter'length);
            end if;
        end if;
    end process;

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            cfg_reg_indx <= 0;
        elsif rising_edge(clk_100MHz) then
            if rst_cfg_reg_indx = '1' then
                cfg_reg_indx <= 519;
            elsif dec_cfg_reg_indx = '1' then
                cfg_reg_indx <= cfg_reg_indx - 1;
            else
                cfg_reg_indx <= cfg_reg_indx;
            end if;
        end if;
    end process;

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            cfg_reg_from_vata <= (others => '0');
        elsif rising_edge(clk_100MHz) then
            if shift_cfg_reg = '1' then
                cfg_reg_from_vata <= shift_left(cfg_reg_from_vata, 1);
            elsif read_o5 = '1' then
                cfg_reg_from_vata(0) <= vata_o5;
                cfg_reg_from_vata(519 downto 1) <= cfg_reg_from_vata(519 downto 1);
            elsif cfg_reg_clr = '1' then
                cfg_reg_from_vata <= (others => '0');
            else
                cfg_reg_from_vata <= cfg_reg_from_vata;
            end if;
        end if;
    end process;

    vata_s0 <= vata_mode(0);
    vata_s1 <= vata_mode(1);
    vata_s2 <= vata_mode(2);
    vata_i1_out <= vata_i1;
    vata_i3_out <= vata_i3;
    vata_i4_out <= vata_i4;

    bram_addr <= std_logic_vector(bram_uaddr);

    -- DEBUG --
    state_counter_out <= std_logic_vector(state_counter);
    state_out <= current_state;

    cfg_reg_indx_out <= std_logic_vector(to_unsigned(cfg_reg_indx, cfg_reg_indx_out'length));
    cfg_reg_from_vata_out <= std_logic_vector(cfg_reg_from_vata(7 downto 0));

end arch_imp;
