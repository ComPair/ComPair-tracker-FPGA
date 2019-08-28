library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_iface_fsm is
        port (
                clk_100MHz         : in std_logic; -- 10 ns
                rst_n              : in std_logic;
                trigger_in         : in std_logic;
                trigger_out        : out std_logic;
                get_config         : in std_logic;
                set_config         : in std_logic;
                cp_data_done       : in std_logic;
                hold_time          : in std_logic_vector(15 downto 0); -- in clock cycles
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
                -- DEBUG --
                state_counter_out  : out std_logic_vector(15 downto 0);
                reg_indx_out       : out std_logic_vector(9 downto 0);
                reg_from_vata_out  : out std_logic_vector(378 downto 0);
                state_out          : out std_logic_vector(7 downto 0));
    end vata_460p3_iface_fsm;

architecture arch_imp of vata_460p3_iface_fsm is

    constant STATE_BITWIDTH : integer := 8;
    constant IDLE                     : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"00";
    constant SC_SET_MODE_M1           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"01";
    constant SC_LATCH_MODE_M1         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"02";
    constant SC_LOWER_LATCH_M1        : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"03";
    constant SC_SET_DATA_I3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"04";
    constant SC_CLOCK_DATA            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"05";
    constant SC_LOWER_CLOCK           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"06";
    constant SC_SET_MODE_M3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"07";
    constant SC_LATCH_MODE_M3         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"08";
    constant GC_SET_MODE_M2           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"09";
    constant GC_LATCH_MODE_M2         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0A";
    constant GC_LOWER_LATCH_M2        : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0B";
    constant GC_SET_DATA_I3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0C";
    constant GC_CLOCK_DATA            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0D";
    constant GC_SHIFT_CFG_REG         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0E";
    constant GC_READ_O5               : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"0F";
    constant GC_LOWER_CLOCK           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"10";
    constant GC_WBRAM_00              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"11";
    constant GC_WBRAM_01              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"12";
    constant GC_WBRAM_02              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"13";
    constant GC_WBRAM_03              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"14";
    constant GC_WBRAM_04              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"15";
    constant GC_WBRAM_05              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"16";
    constant GC_WBRAM_06              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"17";
    constant GC_WBRAM_07              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"18";
    constant GC_WBRAM_08              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"19";
    constant GC_WBRAM_09              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1A";
    constant GC_WBRAM_10              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1B";
    constant GC_WBRAM_11              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1C";
    constant GC_WBRAM_12              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1D";
    constant GC_WBRAM_13              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1E";
    constant GC_WBRAM_14              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1F";
    constant GC_WBRAM_15              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"20";
    constant GC_WBRAM_16              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"21";
    constant GC_SET_MODE_M3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"22";
    constant GC_LATCH_MODE_M3         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"23";
    constant ACQ_CLR_BRAM_00          : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"24";
    constant ACQ_DELAY                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"25";
    constant ACQ_HOLD                 : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"26";
    constant ACQ_LOWER_I1             : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"27";
    constant ACQ_SET_MODE_M4          : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"28";
    constant CONV_LATCH_M4            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"29";
    constant CONV_LOWER_I4            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2A";
    constant CONV_CLK_HI              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2B";
    constant CONV_CLK_LO              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2C";
    constant CONV_SET_MODE_M5         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2D";
    constant RO_LATCH_MODE_M5         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2E";
    constant RO_CLK_HI                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2F";
    constant RO_READ_O6               : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"30";
    constant RO_CLK_LO                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"31";
    constant RO_SHIFT_DATA            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"32";
    constant RO_WBRAM_12              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"33";
    constant RO_WBRAM_11              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"34";
    constant RO_WBRAM_10              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"35";
    constant RO_WBRAM_09              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"36";
    constant RO_WBRAM_08              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"37";
    constant RO_WBRAM_07              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"38";
    constant RO_WBRAM_06              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"39";
    constant RO_WBRAM_05              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3A";
    constant RO_WBRAM_04              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3B";
    constant RO_WBRAM_03              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3C";
    constant RO_WBRAM_02              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3D";
    constant RO_WBRAM_01              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3E";
    constant RO_WBRAM_00              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3F";
    constant RO_WAIT_FOR_CP_DATA_DONE : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"40";
    constant RO_CLR_BRAM_00           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"41";
    constant RO_SET_MODE_M3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"42";
    constant RO_LATCH_MODE_M3         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"43";

    signal current_state     : std_logic_vector(STATE_BITWIDTH-1 downto 0) := IDLE;
    signal next_state        : std_logic_vector(STATE_BITWIDTH-1 downto 0) := IDLE;
    signal state_counter     : unsigned(15 downto 0) := (others => '0');
    signal state_counter_clr : std_logic := '0';

    signal vata_mode : std_logic_vector(2 downto 0);

    signal reg_indx          : integer range 0 to 519 := 0;
    signal dec_reg_indx      : std_logic;
    signal inc_reg_indx      : std_logic;
    signal rst_reg_indx_519  : std_logic;
    signal rst_reg_indx_0    : std_logic;

    signal reg_from_vata     : unsigned(519 downto 0);
    signal read_o5           : std_logic := '0';
    signal read_o6           : std_logic := '0';
    signal shift_reg_left_1  : std_logic := '0';
    signal shift_reg_right_1 : std_logic := '0';
    signal reg_clr           : std_logic := '0';

    signal trigger_acq       : std_logic;
    signal bram_uaddr        : unsigned(31 downto 0);

begin

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_100MHz) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, trigger_acq, set_config, get_config, cp_data_done, state_counter)
    begin
        state_counter_clr <= '0';
        dec_reg_indx      <= '0';
        inc_reg_indx      <= '0';
        rst_reg_indx_519  <= '0';
        rst_reg_indx_0    <= '0';
        shift_reg_left_1  <= '0';
        shift_reg_right_1 <= '0';
        reg_clr           <= '0';
        read_o5           <= '0';
        read_o6           <= '0';
        if rst_n = '0' then
            state_counter_clr <= '1';
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if trigger_acq = '1' then
                        state_counter_clr <= '1';
                        next_state <= ACQ_CLR_BRAM_00;
                    elsif set_config = '1' then
                        state_counter_clr <= '1';
                        next_state <= SC_SET_MODE_M1;
                    elsif get_config = '1' then
                        next_state <= GC_SET_MODE_M2;
                    else
                        next_state <= IDLE;
                    end if;
                when SC_SET_MODE_M1 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        rst_reg_indx_519 <= '1';
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
                        if reg_indx = 0 then
                            next_state <= SC_SET_MODE_M3;
                        else
                            dec_reg_indx <= '1';
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
                        rst_reg_indx_519 <= '1';
                        reg_clr <= '1';
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
                    if reg_indx > 0 and state_counter >= to_unsigned(29, state_counter'length) then -- 300 ns
                        state_counter_clr <= '1';
                        shift_reg_left_1 <= '1';
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
                        if reg_indx = 0 then
                            next_state <= GC_WBRAM_00;
                        else
                            dec_reg_indx <= '1';
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
                when ACQ_CLR_BRAM_00 =>
                    state_counter_clr <= '1';
                    next_state <= ACQ_DELAY;
                when ACQ_DELAY =>
                    if state_counter >= unsigned(hold_time) then -- to_unsigned(1, state_counter'length) then
                        state_counter_clr <= '1';
                        next_state <= ACQ_HOLD;
                    else
                        next_state <= ACQ_DELAY;
                    end if;
                when ACQ_HOLD =>
                    if state_counter >= to_unsigned(34, state_counter'length) then -- 350ns
                        state_counter_clr <= '1';
                        next_state <= ACQ_LOWER_I1;
                    else
                        next_state <= ACQ_HOLD;
                    end if;
                when ACQ_LOWER_I1 =>
                    if state_counter >= to_unsigned(14, state_counter'length) then -- 150ns
                        state_counter_clr <= '1';
                        next_state <= ACQ_SET_MODE_M4;
                    else
                        next_state <= ACQ_LOWER_I1;
                    end if;
                when ACQ_SET_MODE_M4 =>
                    if state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        next_state <= CONV_LATCH_M4;
                    else
                        next_state <= ACQ_SET_MODE_M4;
                    end if;
                when CONV_LATCH_M4 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= CONV_LOWER_I4;
                    else
                        next_state <= CONV_LATCH_M4;
                    end if;
                when CONV_LOWER_I4 =>
                    if state_counter >= to_unsigned(14, state_counter'length) then -- 150ns
                        state_counter_clr <= '1';
                        next_state <= CONV_CLK_HI;
                    else
                        next_state <= CONV_LOWER_I4;
                    end if;
                when CONV_CLK_HI =>
                    if state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        if vata_o5 = '1' then
                            next_state <= CONV_SET_MODE_M5;
                        else
                            next_state <= CONV_CLK_LO;
                        end if;
                    else
                        next_state <= CONV_CLK_HI;
                    end if;
                when CONV_CLK_LO =>
                    if state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        next_state <= CONV_CLK_HI;
                    else
                        next_state <= CONV_CLK_LO;
                    end if;
                when CONV_SET_MODE_M5 =>
                    if state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        next_state <= RO_LATCH_MODE_M5;
                    else
                        next_state <= CONV_SET_MODE_M5;
                    end if;
                when RO_LATCH_MODE_M5 =>
                    -- XXX UNSURE HOW LONG THIS DELAY IS IN THE TIMING DIAGRAM!!!!!
                    if state_counter >= to_unsigned(39, state_counter'length) then -- 400ns
                        state_counter_clr <= '1';
                        rst_reg_indx_0 <= '1';
                        next_state <= RO_CLK_HI;
                    else
                        next_state <= RO_LATCH_MODE_M5;
                    end if;
                when RO_CLK_HI =>
                    if state_counter >= to_unsigned(24, state_counter'length) then -- 250ns
                        state_counter_clr <= '1';
                        --shift_reg_right_1 <= '1';
                        next_state <= RO_READ_O6;
                    else
                        next_state <= RO_CLK_HI;
                    end if;
                when RO_READ_O6 =>
                    if state_counter >= to_unsigned(7, state_counter'length) then -- 80ns
                        state_counter_clr <= '1';
                        read_o6 <= '1';
                        inc_reg_indx <= '1';
                        next_state <= RO_CLK_LO;
                    else
                        next_state <= RO_READ_O6;
                    end if;
                when RO_CLK_LO =>
                    if state_counter >= to_unsigned(32, state_counter'length) then -- 330ns
                        state_counter_clr <= '1';
                        if vata_o5 = '1' then
                            if reg_indx = 379 then
                                next_state <= RO_WBRAM_12;
                            else
                                inc_reg_indx <= '1';
                                shift_reg_right_1 <= '1';
                                next_state <= RO_SHIFT_DATA;
                            end if;
                        else
                            shift_reg_right_1 <= '1';
                            next_state <= RO_CLK_HI;
                        end if;
                    else
                        next_state <= RO_CLK_LO;
                    end if;
                when RO_SHIFT_DATA =>
                    inc_reg_indx <= '1';
                    if reg_indx >= 379 then
                        next_state <= RO_WBRAM_12;
                    else
                        shift_reg_right_1 <= '1';
                        next_state <= RO_SHIFT_DATA;
                    end if;
                when RO_WBRAM_12 => next_state <= RO_WBRAM_11;
                when RO_WBRAM_11 => next_state <= RO_WBRAM_10;
                when RO_WBRAM_10 => next_state <= RO_WBRAM_09;
                when RO_WBRAM_09 => next_state <= RO_WBRAM_08;
                when RO_WBRAM_08 => next_state <= RO_WBRAM_07;
                when RO_WBRAM_07 => next_state <= RO_WBRAM_06;
                when RO_WBRAM_06 => next_state <= RO_WBRAM_05;
                when RO_WBRAM_05 => next_state <= RO_WBRAM_04;
                when RO_WBRAM_04 => next_state <= RO_WBRAM_03;
                when RO_WBRAM_03 => next_state <= RO_WBRAM_02;
                when RO_WBRAM_02 => next_state <= RO_WBRAM_01;
                when RO_WBRAM_01 => next_state <= RO_WBRAM_00;
                when RO_WBRAM_00 =>
                    state_counter_clr <= '1';
                    next_state <= RO_WAIT_FOR_CP_DATA_DONE;
                when RO_WAIT_FOR_CP_DATA_DONE =>
                    -- XXX INCLUDE TIMEOUT HERE!!! XXX --
                    if cp_data_done = '1' then
                        next_state <= RO_CLR_BRAM_00;
                    else
                        next_state <= RO_WAIT_FOR_CP_DATA_DONE;
                    end if;
                when RO_CLR_BRAM_00 =>
                    state_counter_clr <= '1';
                    next_state <= RO_SET_MODE_M3;
                when RO_SET_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then --100ns
                        state_counter_clr <= '1';
                        next_state <= RO_LATCH_MODE_M3;
                    else
                        next_state <= RO_SET_MODE_M3;
                    end if;
                when RO_LATCH_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then --100ns
                        state_counter_clr <= '1';
                        next_state <= IDLE;
                    else
                        next_state <= RO_LATCH_MODE_M3;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0'; vata_s_latch <= '0';
        bram_wea <= (others => '0'); bram_uaddr <= (others => '0'); bram_dwrite <= (others => '0');
        trigger_out <= '0';
        case (current_state) is
            when IDLE =>
                vata_mode <= "010"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
                trigger_out <= vata_o6;
            ---- Set config states ----
            when SC_SET_MODE_M1 =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when SC_LATCH_MODE_M1 =>
                vata_mode <= "000"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when SC_LOWER_LATCH_M1 =>
                vata_mode <= "000"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when SC_SET_DATA_I3 =>
                vata_mode <= "000";
                vata_i1   <= '0';
                vata_i3   <= cfg_reg_from_ps(reg_indx);
                if reg_indx = 519 then
                    vata_i4 <= '0';
                else
                    vata_i4 <= '1';
                end if;
            when SC_CLOCK_DATA =>
                vata_mode <= "000";
                vata_i3 <= cfg_reg_from_ps(reg_indx);
                vata_i1 <= '1'; vata_i4 <= '1';
            when SC_LOWER_CLOCK =>
                vata_mode <= "000";
                vata_i3 <= cfg_reg_from_ps(reg_indx);
                vata_i1 <= '0'; vata_i4 <= '1';
            when SC_SET_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when SC_LATCH_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            ----Get config states----
            --- Unsure if vata_i4 should be low???
            when GC_SET_MODE_M2 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_LATCH_MODE_M2 =>
                vata_mode <= "001"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_LOWER_LATCH_M2 =>
                vata_mode <= "001"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0';
            when GC_SET_DATA_I3 =>
                vata_mode <= "001";
                vata_i1 <= '0'; vata_i4 <= '0';
                vata_i3 <= reg_from_vata(0);
            when GC_CLOCK_DATA =>
                vata_mode <= "001";
                vata_i3 <= reg_from_vata(0);
                vata_i1 <= '1'; vata_i4 <= '0';
            when GC_SHIFT_CFG_REG =>
                vata_mode <= "001";
                vata_i3 <= reg_from_vata(1);
                vata_i1 <= '1'; vata_i4 <= '0';
            when GC_READ_O5 =>
                vata_mode <= "001";
                vata_i3 <= reg_from_vata(1);
                vata_i1 <= '1'; vata_i4 <= '0';
            when GC_LOWER_CLOCK =>
                vata_mode <= "001";
                if reg_indx = 0 then
                    vata_i3 <= reg_from_vata(0);
                else
                    vata_i3 <= reg_from_vata(1);
                end if;
                vata_i1 <= '0'; vata_i4 <= '0';
            when GC_WBRAM_00 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= (others => '0');
                bram_dwrite <= std_logic_vector(reg_from_vata(31 downto 0));
            when GC_WBRAM_01 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(4, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(63 downto 32));
            when GC_WBRAM_02 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(8, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(95 downto 64));
            when GC_WBRAM_03 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(12, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(127 downto 96));
            when GC_WBRAM_04 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(16, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(159 downto 128));
            when GC_WBRAM_05 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(20, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(191 downto 160));
            when GC_WBRAM_06 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(24, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(223 downto 192));
            when GC_WBRAM_07 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(28, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(255 downto 224));
            when GC_WBRAM_08 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(32, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(287 downto 256));
            when GC_WBRAM_09 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(36, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(319 downto 288));
            when GC_WBRAM_10 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(40, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(351 downto 320));
            when GC_WBRAM_11 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(44, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(383 downto 352));
            when GC_WBRAM_12 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(48, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(415 downto 384));
            when GC_WBRAM_13 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(52, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(447 downto 416));
            when GC_WBRAM_14 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(56, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(479 downto 448));
            when GC_WBRAM_15 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(60, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(511 downto 480));
            when GC_WBRAM_16 =>
                vata_mode   <= "001";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(64, bram_uaddr'length);
                bram_dwrite(7 downto 0) <= std_logic_vector(reg_from_vata(519 downto 512));
                bram_dwrite(31 downto 8) <= (others => '0');
            when GC_SET_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '0';
            when GC_LATCH_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '1';
            ----Acquisition modes-----------------------
            when ACQ_CLR_BRAM_00 =>
                vata_mode   <= "010";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(0, bram_uaddr'length);
                bram_dwrite <= (others => '0');
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
            when ACQ_DELAY =>
                vata_mode <= "010"; 
                bram_wea  <= (others => '0'); -- just in case?
                vata_i1   <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
            when ACQ_HOLD =>
                vata_mode <= "010";
                vata_i1   <= '1'; vata_i3 <= '0'; vata_i4 <= '1';
            when ACQ_LOWER_I1 =>
                vata_mode <= "010";
                vata_i1   <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
            when ACQ_SET_MODE_M4 =>
                vata_mode <= "011";
                vata_i1   <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
            ----Data conversion modes-------------------
            when CONV_LATCH_M4 =>
                vata_mode <= "011"; vata_s_latch <= '1';
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '1'; -- i3 goes hi here in timing diagram
            when CONV_LOWER_I4 =>
                vata_mode <= "011"; vata_s_latch <= '0';
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when CONV_CLK_HI =>
                vata_mode <= "011";
                vata_i1   <= '1'; vata_i3 <= '1'; vata_i4 <= '0';
            when CONV_CLK_LO =>
                vata_mode <= "011";
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when CONV_SET_MODE_M5 =>
                vata_mode <= "100";
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            ----Data readout states--------------------
            when RO_LATCH_MODE_M5 =>
                vata_mode <= "100"; vata_s_latch <= '1';
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_CLK_HI =>
                vata_mode <= "100";
                vata_i1   <= '1'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_READ_O6 =>
                vata_mode <= "100";
                vata_i1   <= '1'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_CLK_LO =>
                vata_mode <= "100";
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_SHIFT_DATA =>
                vata_mode <= "100";
                vata_i1   <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_12 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(48, bram_uaddr'length);
                bram_dwrite(26 downto 0) <= std_logic_vector(reg_from_vata(378 downto 352));
                bram_dwrite(31 downto 27) <= (others => '0');
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_11 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(44, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(351 downto 320));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_10 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(40, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(319 downto 288));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_09 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(36, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(287 downto 256));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_08 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(32, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(255 downto 224));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_07 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(28, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(223 downto 192));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_06 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(24, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(191 downto 160));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_05 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(20, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(159 downto 128));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_04 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(16, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(127 downto 96));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_03 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(12, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(95 downto 64));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_02 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(8, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(63 downto 32));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_01 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(4, bram_uaddr'length);
                bram_dwrite <= std_logic_vector(reg_from_vata(31 downto 0));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WBRAM_00 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(0, bram_uaddr'length);
                bram_dwrite <= (others => '1'); -- Signify we finished writing data to ram
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_WAIT_FOR_CP_DATA_DONE =>
                vata_mode <= "100";
                bram_wea  <= (others => '0');
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_CLR_BRAM_00 =>
                vata_mode   <= "100";
                bram_wea    <= (others => '1');
                bram_uaddr  <= to_unsigned(0, bram_uaddr'length);
                bram_dwrite <= (others => '0');
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_SET_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '0';
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0';
            when RO_LATCH_MODE_M3 =>
                vata_mode <= "010"; vata_s_latch <= '1';
                vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '1';
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
            reg_indx <= 0;
        elsif rising_edge(clk_100MHz) then
            if rst_reg_indx_0 = '1' then
                reg_indx <= 0;
            elsif rst_reg_indx_519 = '1' then
                reg_indx <= 519;
            elsif inc_reg_indx = '1' then
                reg_indx <= reg_indx + 1;
            elsif dec_reg_indx = '1' then
                reg_indx <= reg_indx - 1;
            else
                reg_indx <= reg_indx;
            end if;
        end if;
    end process;

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            reg_from_vata <= (others => '0');
        elsif rising_edge(clk_100MHz) then
            if shift_reg_left_1 = '1' then
                reg_from_vata <= shift_left(reg_from_vata, 1);
            elsif shift_reg_right_1 = '1' then
                reg_from_vata <= shift_right(reg_from_vata, 1);
            elsif read_o5 = '1' then
                reg_from_vata(0) <= vata_o5;
                reg_from_vata(519 downto 1) <= reg_from_vata(519 downto 1);
            elsif read_o6 = '1' then
                reg_from_vata(378) <= vata_o6;
                reg_from_vata(519 downto 379) <= reg_from_vata(519 downto 379);
                reg_from_vata(377 downto 0) <= reg_from_vata(377 downto 0);
            elsif reg_clr = '1' then
                reg_from_vata <= (others => '0');
            else
                reg_from_vata <= reg_from_vata;
            end if;
        end if;
    end process;

    vata_s0 <= vata_mode(0);
    vata_s1 <= vata_mode(1);
    vata_s2 <= vata_mode(2);

    bram_addr   <= std_logic_vector(bram_uaddr);
    trigger_acq <= trigger_in or vata_o6;

    -- DEBUG --
    state_counter_out <= std_logic_vector(state_counter);
    state_out         <= current_state;

    reg_indx_out      <= std_logic_vector(to_unsigned(reg_indx, reg_indx_out'length));
    reg_from_vata_out <= std_logic_vector(reg_from_vata(378 downto 0));

end arch_imp;
