library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_iface_fsm is
        port (
                clk_100MHz              : in std_logic; -- 10 ns
                rst_n                   : in std_logic;
                force_fsm_idle          : in std_logic;
                fast_or_trigger         : in std_logic;
                fast_or_trigger_ena     : in std_logic;
                trigger_ack             : in std_logic;
                ack_trigger_ena         : in std_logic;
                vata_hits               : in std_logic_vector(11 downto 0);
                local_vata_trigger_ena  : in std_logic_vector(11 downto 0);
                force_trigger           : in std_logic;
                force_trigger_ena       : in std_logic;
                cal_pulse_trigger       : in std_logic;
                disable_fast_or_trigger : in std_logic; 
                trigger_ack_timeout     : in std_logic_vector(31 downto 0);
                vata_hit                : out std_logic;
                vata_busy               : out std_logic;
                event_id_latch          : in std_logic;
                event_id_data           : in std_logic;
                get_config              : in std_logic;
                set_config              : in std_logic;
                int_cal_trigger         : in std_logic;
                hold_time               : in std_logic_vector(15 downto 0); -- in clock cycles
                vata_s0                 : out std_logic;
                vata_s1                 : out std_logic;
                vata_s2                 : out std_logic;
                vata_s_latch            : out std_logic;
                vata_i1                 : out std_logic;
                vata_i3                 : out std_logic;
                vata_i4                 : out std_logic;
                vata_o5                 : in std_logic;
                vata_o6                 : in std_logic;
                cfg_reg_from_ps         : in std_logic_vector(519 downto 0);
                cfg_reg_from_pl         : out std_logic_vector(519 downto 0);
                data_tvalid             : out std_logic;
                data_tlast              : out std_logic;
                data_tready             : in std_logic;
                data_tdata              : out std_logic_vector(31 downto 0);
                cald                    : out std_logic;
                caldb                   : out std_logic;
                counter_rst             : in std_logic;
                running_counter         : in std_logic_vector(63 downto 0);
                live_counter            : out std_logic_vector(63 downto 0);
                event_counter_rst       : in std_logic;
                event_counter           : out std_logic_vector(31 downto 0);
                -- DEBUG --
                event_id_out_debug      : out std_logic_vector(31 downto 0);
                abort_daq_debug         : out std_logic;
                trigger_acq_out         : out std_logic;
                trigger_ack_timeout_counter : out std_logic_vector(31 downto 0);
                trigger_ack_timeout_state   : out std_logic_vector(3 downto 0);
                vata_hits_rising_edge_out   : out std_logic_vector(1 downto 0);
                state_out             : out std_logic_vector(7 downto 0));
    end vata_460p3_iface_fsm;

architecture arch_imp of vata_460p3_iface_fsm is

    component trigger_ack_timeout_fsm is
        port (
            clk_100MHz          : in std_logic;
            rst_n               : in std_logic;
            trigger_ena         : in std_logic;
            trigger_ack         : in std_logic;
            trigger_ack_timeout : in std_logic_vector(31 downto 0);
            abort_daq           : out std_logic;
            counter_out         : out std_logic_vector(31 downto 0);
            state_out           : out std_logic_vector(3 downto 0));
    end component trigger_ack_timeout_fsm;

    component event_id_s2p is
        generic (
            EVENT_ID_WIDTH : integer := 32);
        port (
            clk            : in std_logic;
            rst_n          : in std_logic;
            event_id_data  : in std_logic;
            event_id_latch : in std_logic;
            event_id_clr   : in std_logic;
            event_id_out   : out std_logic_vector(EVENT_ID_WIDTH-1 downto 0));
    end component event_id_s2p;
    
    component int_cal_toggle is
        port (
            clk             : in std_logic;
            rst_n           : in std_logic;
            int_cal_trigger : in std_logic;
            cald            : out std_logic;
            caldb           : out std_logic);
    end component int_cal_toggle;

    component rising_edge_vector is
        generic ( VECTOR_WIDTH : integer := 12 );
        port ( clk : in std_logic
             ; rst_n : in std_logic
             ; vector_in : in std_logic_vector(VECTOR_WIDTH-1 downto 0)
             ; rising_edge_out : out std_logic_vector(VECTOR_WIDTH-1 downto 0)
             );
    end component rising_edge_vector;
    
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
    constant GC_XFER_DATA             : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"11";
    constant GC_SET_MODE_M3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"12";
    constant GC_LATCH_MODE_M3         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"13";
    constant ACQ_DELAY                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"14";
    constant ACQ_HOLD                 : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"15";
    constant ACQ_LOWER_I1             : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"16";
    constant ACQ_SET_MODE_M4          : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"17";
    constant CONV_LATCH_M4            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"18";
    constant CONV_RAISE_I3            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"19";
    constant CONV_LOWER_I4            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1A";
    constant CONV_CLK_HI              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1B";
    constant CONV_CLK_LO              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1C";
    constant CONV_SET_MODE_M5         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1D";
    constant RO_LATCH_MODE_M5         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1E";
    constant RO_CLK_HI                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"1F";
    constant RO_READ_O6               : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"20";
    constant RO_CLK_LO                : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"21";
    constant RO_SHIFT_DATA            : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"22";
    constant RO_WFIFO_00              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"23";
    constant RO_WFIFO_01              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"24";
    constant RO_WFIFO_02              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"25";
    constant RO_WFIFO_03              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"26";
    constant RO_WFIFO_04              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"27";
    constant RO_WFIFO_05              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"28";
    constant RO_WFIFO_06              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"29";
    constant RO_WFIFO_07              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2A";
    constant RO_WFIFO_08              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2B";
    constant RO_WFIFO_09              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2C";
    constant RO_WFIFO_10              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2D";
    constant RO_WFIFO_11              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2E";
    constant RO_WFIFO_12              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"2F";
    constant RO_WFIFO_13              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"30";
    constant RO_WFIFO_14              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"31";
    constant RO_WFIFO_15              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"32";
    constant RO_WFIFO_16              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"33";
    constant RO_WFIFO_17              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"34";
    constant RO_WFIFO_18              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"35";
    constant RO_SET_MODE_M3           : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"36";
    constant RO_LATCH_MODE_M3         : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"37";
    constant ABORT_WFIFO              : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"38";
    constant ABORT_SET_MODE_M3        : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"39";
    constant ABORT_LATCH_MODE_M3      : std_logic_vector(STATE_BITWIDTH-1 downto 0) := x"3A";

    constant EVENT_ID_WIDTH : integer := 32;

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

    signal cfg_bit   : std_logic;
    signal cfg_reg0  : std_logic;
    signal cfg_reg1  : std_logic;

    signal reg_from_vata     : unsigned(519 downto 0);
    signal read_o5           : std_logic := '0';
    signal read_o6           : std_logic := '0';
    signal shift_reg_left_1  : std_logic := '0';
    signal shift_reg_right_1 : std_logic := '0';
    signal reg_clr           : std_logic := '0';

    signal event_id_clr  : std_logic := '0';
    signal event_id_out  : std_logic_vector(EVENT_ID_WIDTH-1 downto 0);
    signal abort_daq     : std_logic := '0';
    signal abort_daq_buf : std_logic;

    signal trigger_acq            : std_logic := '0';

    signal ulive_counter    : unsigned(63 downto 0) := (others => '0');
    signal uevent_counter   : unsigned(31 downto 0) := (others => '0');
    signal inc_event_counter : std_logic := '0';

    signal vata_hits_rising_edge : std_logic_vector(11 downto 0) := (others => '0');

    -- Saved info to store in asic packet:
    signal set_pkt_data : std_logic;
    signal pkt_running_counter : std_logic_vector(63 downto 0) := (others => '0');
    signal pkt_live_counter    : std_logic_vector(63 downto 0) := (others => '0');
    signal pkt_event_counter   : std_logic_vector(31 downto 0) := (others => '0');
    signal pkt_event_triggers  : std_logic_vector(15 downto 0) := (others => '0');

begin

    event_id_s2p_inst : event_id_s2p
        generic map (
            EVENT_ID_WIDTH => EVENT_ID_WIDTH
        ) port map (
            clk            => clk_100MHz,
            rst_n          => rst_n,
            event_id_data  => event_id_data,
            event_id_latch => event_id_latch,
            event_id_clr   => event_id_clr,
            event_id_out   => event_id_out
            --event_id_out   => open
    );
    -- For debugging purposes:
    --event_id_out <= x"A1B2C3D4";

    -- Manage the timeout for when we look for the trigger-ack signal
    trigger_ack_timeout_fsm_inst : trigger_ack_timeout_fsm
        port map (
            clk_100MHz          => clk_100MHz,
            rst_n               => rst_n,
            -------------------------------------------------------------------------------------
            -- Use `trigger_ena => fast_or_trigger` for only handling timeout with fast-or-triggers
            -- (this makes the most sense for actual setup)
            --trigger_ena         => fast_or_trigger,
            -------------------------------------------------------------------------------------
            -- Use `trigger_ena => trigger_acq` for testing with any triggers
            -- (this makes sense for debugging):
            trigger_ena         => trigger_acq,
            -------------------------------------------------------------------------------------
            trigger_ack         => trigger_ack,
            trigger_ack_timeout => trigger_ack_timeout,
            abort_daq           => abort_daq_buf,
            counter_out         => trigger_ack_timeout_counter,
            state_out           => trigger_ack_timeout_state
    );
    ---------------------
    -- ENABLE ABORT DAQ:
    abort_daq <= abort_daq_buf;
    -- DISABLE ABORT DAQ:
    -- abort_daq <= '0';
    ---------------------
    abort_daq_debug <= abort_daq_buf;

    int_cal_toggle_inst : int_cal_toggle
        port map (
            clk             => clk_100MHz,
            rst_n           => rst_n,
            int_cal_trigger => int_cal_trigger,
            cald            => cald,
            caldb           => caldb);

    rising_edge_vector_inst : rising_edge_vector
        generic map ( VECTOR_WIDTH => 12 )
        port map ( clk             => clk_100MHz
                 , rst_n           => rst_n
                 , vector_in       => vata_hits
                 , rising_edge_out => vata_hits_rising_edge
                 );

    process (rst_n, clk_100MHz)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk_100MHz) then
            current_state <= next_state;
        end if;
    end process;

    process (rst_n, current_state, trigger_acq, set_config, get_config, state_counter, force_fsm_idle)
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
        inc_event_counter <= '0';
        set_pkt_data      <= '0';
        if rst_n = '0' then
            state_counter_clr <= '1';
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if trigger_acq = '1' then
                        state_counter_clr <= '1';
                        set_pkt_data      <= '1'; -- save packet-header data at this point
                        next_state        <= ACQ_DELAY;
                    elsif set_config = '1' then
                        state_counter_clr <= '1';
                        next_state <= SC_SET_MODE_M1;
                    elsif get_config = '1' then
                        next_state <= GC_SET_MODE_M2;
                    else
                        next_state <= IDLE;
                    end if;
                when SC_SET_MODE_M1 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        rst_reg_indx_519 <= '1';
                        next_state <= SC_LATCH_MODE_M1;
                    else
                        next_state <= SC_SET_MODE_M1;
                    end if;
                when SC_LATCH_MODE_M1 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= SC_LOWER_LATCH_M1;
                    else
                        next_state <= SC_LATCH_MODE_M1;
                    end if;
                when SC_LOWER_LATCH_M1 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= SC_SET_DATA_I3;
                    else
                        next_state <= SC_LOWER_LATCH_M1;
                    end if;
                when SC_SET_DATA_I3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= SC_CLOCK_DATA;
                    else
                        next_state <= SC_SET_DATA_I3;
                    end if;
                when SC_CLOCK_DATA =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(999, state_counter'length) then -- 10us - 1clk
                        state_counter_clr <= '1';
                        next_state <= SC_LOWER_CLOCK;
                    else
                        next_state <= SC_CLOCK_DATA;
                    end if;
                when SC_LOWER_CLOCK =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
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
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= SC_LATCH_MODE_M3;
                    else
                        next_state <= SC_SET_MODE_M3;
                    end if;
                when SC_LATCH_MODE_M3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        next_state <= IDLE;
                    else
                        next_state <= SC_LATCH_MODE_M3;
                    end if;
                when GC_SET_MODE_M2 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        rst_reg_indx_519 <= '1';
                        reg_clr <= '1';
                        next_state <= GC_LATCH_MODE_M2;
                    else
                        next_state <= GC_SET_MODE_M2;
                    end if;
                when GC_LATCH_MODE_M2 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= GC_LOWER_LATCH_M2;
                    else
                        next_state <= GC_LATCH_MODE_M2;
                    end if;
                when GC_LOWER_LATCH_M2 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        read_o5 <= '1';
                        next_state <= GC_SET_DATA_I3;
                    else
                        next_state <= GC_LOWER_LATCH_M2;
                    end if;
                when GC_SET_DATA_I3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        next_state <= GC_CLOCK_DATA;
                    else
                        next_state <= GC_SET_DATA_I3;
                    end if;
                when GC_CLOCK_DATA =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif reg_indx > 0 and state_counter >= to_unsigned(29, state_counter'length) then -- 300 ns
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
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        state_counter_clr <= '1';
                        read_o5 <= '1';
                        next_state <= GC_READ_O5;
                    end if;
                when GC_READ_O5 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(969, state_counter'length) then -- (10us - 300 ns)
                        state_counter_clr <= '1';
                        next_state <= GC_LOWER_CLOCK;
                    else
                        next_state <= GC_READ_O5;
                    end if;
                when GC_LOWER_CLOCK =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(499, state_counter'length) then -- 5us
                        state_counter_clr <= '1';
                        if reg_indx = 0 then
                            next_state <= GC_XFER_DATA;
                        else
                            dec_reg_indx <= '1';
                            next_state <= GC_SET_DATA_I3;
                        end if;
                    else
                        next_state <= GC_LOWER_CLOCK;
                    end if;
                when GC_XFER_DATA =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= GC_SET_MODE_M3;
                    end if;
                when GC_SET_MODE_M3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= GC_LATCH_MODE_M3;
                    else
                        next_state <= GC_SET_MODE_M3;
                    end if;
                when GC_LATCH_MODE_M3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        next_state <= IDLE;
                    else
                        next_state <= GC_LATCH_MODE_M3;
                    end if;
                when ACQ_DELAY =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= unsigned(hold_time) then
                        state_counter_clr <= '1';
                        next_state <= ACQ_HOLD;
                    else
                        next_state <= ACQ_DELAY;
                    end if;
                when ACQ_HOLD =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(34, state_counter'length) then -- 350ns
                        state_counter_clr <= '1';
                        next_state <= ACQ_LOWER_I1;
                    else
                        next_state <= ACQ_HOLD;
                    end if;
                when ACQ_LOWER_I1 =>
                    -- XXX NOTE: THERE IS A DELAY BETWEEN LOWERING HOLD AND STARTING CONVERSION!!!!
                    -- XXX UNSURE IF THIS SHOULD BE AS SHORT AS POSSIBLE???
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(1, state_counter'length) then -- 20ns
                        state_counter_clr <= '1';
                        next_state <= ACQ_SET_MODE_M4;
                    else
                        next_state <= ACQ_LOWER_I1;
                    end if;
                when ACQ_SET_MODE_M4 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    else
                        state_counter_clr <= '1';
                        next_state <= CONV_LATCH_M4;
                    end if;
                when CONV_LATCH_M4 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    else
                        state_counter_clr <= '1';
                        next_state <= CONV_RAISE_I3;
                    end if;
                when CONV_RAISE_I3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= CONV_LOWER_I4;
                    else
                        next_state <= CONV_RAISE_I3;
                    end if;
                when CONV_LOWER_I4 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(14, state_counter'length) then -- 150ns
                        state_counter_clr <= '1';
                        next_state <= CONV_CLK_HI;
                    else
                        next_state <= CONV_LOWER_I4;
                    end if;
                when CONV_CLK_HI =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
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
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        next_state <= CONV_CLK_HI;
                    else
                        next_state <= CONV_CLK_LO;
                    end if;
                when CONV_SET_MODE_M5 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(4, state_counter'length) then -- 50ns
                        state_counter_clr <= '1';
                        next_state <= RO_LATCH_MODE_M5;
                    else
                        next_state <= CONV_SET_MODE_M5;
                    end if;
                when RO_LATCH_MODE_M5 =>
                    -- XXX UNSURE HOW LONG THIS DELAY IS IN THE TIMING DIAGRAM!!!!!
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(39, state_counter'length) then -- 400ns
                        state_counter_clr <= '1';
                        rst_reg_indx_0 <= '1';
                        next_state <= RO_CLK_HI;
                    else
                        next_state <= RO_LATCH_MODE_M5;
                    end if;
                when RO_CLK_HI =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(24, state_counter'length) then -- 250ns
                        state_counter_clr <= '1';
                        --shift_reg_right_1 <= '1';
                        next_state <= RO_READ_O6;
                    else
                        next_state <= RO_CLK_HI;
                    end if;
                when RO_READ_O6 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(7, state_counter'length) then -- 80ns
                        state_counter_clr <= '1';
                        read_o6 <= '1';
                        inc_reg_indx <= '1';
                        next_state <= RO_CLK_LO;
                    else
                        next_state <= RO_READ_O6;
                    end if;
                when RO_CLK_LO =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(32, state_counter'length) then -- 330ns
                        state_counter_clr <= '1';
                        if vata_o5 = '1' then
                            if reg_indx = 379 then
                                next_state <= RO_WFIFO_00;
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
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif abort_daq = '1' then
                        state_counter_clr <= '1';
                        next_state <= RO_SET_MODE_M3;
                    else
                        inc_reg_indx <= '1';
                        if reg_indx >= 379 then
                            next_state <= RO_WFIFO_00;
                        else
                            shift_reg_right_1 <= '1';
                            next_state <= RO_SHIFT_DATA;
                        end if;
                    end if;
                when RO_WFIFO_00 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_01;
                    end if;
                when RO_WFIFO_01 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_02;
                    end if;
                when RO_WFIFO_02 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_03;
                    end if;
                when RO_WFIFO_03 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_04;
                    end if;
                when RO_WFIFO_04 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_05;
                    end if;
                when RO_WFIFO_05 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_06;
                    end if;
                when RO_WFIFO_06 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_07;
                    end if;
                when RO_WFIFO_07 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_08;
                    end if;
                when RO_WFIFO_08 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_09;
                    end if;
                when RO_WFIFO_09 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_10;
                    end if;
                when RO_WFIFO_10 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_11;
                    end if;
                when RO_WFIFO_11 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_12;
                    end if;
                when RO_WFIFO_12 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_13;
                    end if;
                when RO_WFIFO_13 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_14;
                    end if;
                when RO_WFIFO_14 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_15;
                    end if;
                when RO_WFIFO_15 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_16;
                    end if;
                when RO_WFIFO_16 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_17;
                    end if;
                when RO_WFIFO_17 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        next_state <= RO_WFIFO_18;
                    end if;
                when RO_WFIFO_18 =>
                    state_counter_clr <= '1';
                    if force_fsm_idle = '1' then
                        next_state <= ABORT_SET_MODE_M3;
                    else
                        inc_event_counter <= '1';
                        next_state <= RO_SET_MODE_M3;
                    end if;
                when RO_SET_MODE_M3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then --100ns
                        state_counter_clr <= '1';
                        next_state <= RO_LATCH_MODE_M3;
                    else
                        next_state <= RO_SET_MODE_M3;
                    end if;
                when RO_LATCH_MODE_M3 =>
                    if force_fsm_idle = '1' then
                        state_counter_clr <= '1';
                        next_state <= ABORT_SET_MODE_M3;
                    elsif state_counter >= to_unsigned(9, state_counter'length) then --100ns
                        state_counter_clr <= '1';
                        next_state <= IDLE;
                    else
                        next_state <= RO_LATCH_MODE_M3;
                    end if;
                when ABORT_WFIFO =>
                    state_counter_clr <= '1';
                    next_state <= ABORT_SET_MODE_M3;
                when ABORT_SET_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        state_counter_clr <= '1';
                        next_state <= ABORT_LATCH_MODE_M3;
                    else
                        next_state <= ABORT_SET_MODE_M3;
                    end if;
                when ABORT_LATCH_MODE_M3 =>
                    if state_counter >= to_unsigned(9, state_counter'length) then -- 100ns
                        next_state <= IDLE;
                    else
                        next_state <= ABORT_LATCH_MODE_M3;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process (current_state)
    begin
        vata_i1 <= '0'; vata_i3 <= '0'; vata_i4 <= '0'; vata_s_latch <= '0';
        data_tvalid <= '0'; data_tlast <= '0'; data_tdata <= (others => '0');
        event_id_clr <= '0';
        vata_hit <= '0'; vata_busy <= '1';
        case (current_state) is
            when IDLE =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "010"; vata_s_latch <= '0';
                vata_busy <= '0';
                vata_hit <= not vata_o6;
            ---- Set config states---------------------------------------------------------------------------
            when SC_SET_MODE_M1 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "000"; vata_s_latch <= '0';
            when SC_LATCH_MODE_M1 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "000"; vata_s_latch <= '1';
            when SC_LOWER_LATCH_M1 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "000"; vata_s_latch <= '0';
            when SC_SET_DATA_I3 =>
                vata_i1 <= '0'; vata_i3 <= cfg_bit ;                 vata_mode <= "000";
                if reg_indx = 519 then
                    vata_i4 <= '0';
                else
                    vata_i4 <= '1';
                end if;
            when SC_CLOCK_DATA =>
                vata_i1 <= '1'; vata_i3 <= cfg_bit ; vata_i4 <= '1'; vata_mode <= "000";
            when SC_LOWER_CLOCK =>
                vata_i1 <= '0'; vata_i3 <= cfg_bit ; vata_i4 <= '1'; vata_mode <= "000";
            when SC_SET_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '0';
            when SC_LATCH_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '1';
            ----Get config states----------------------------------------------------------------------------
            --- Unsure if vata_i4 should be low???
            when GC_SET_MODE_M2 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_LATCH_MODE_M2 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '1';
            when GC_LOWER_LATCH_M2 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_SET_DATA_I3 =>
                vata_i1 <= '0'; vata_i3 <= cfg_reg0; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_CLOCK_DATA =>
                vata_i1 <= '1'; vata_i3 <= cfg_reg0; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_SHIFT_CFG_REG =>
                vata_i1 <= '1'; vata_i3 <= cfg_reg1; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_READ_O5 =>
                vata_i1 <= '1'; vata_i3 <= cfg_reg1; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
            when GC_LOWER_CLOCK =>
                vata_i1 <= '0';                      vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
                if reg_indx = 0 then
                    vata_i3 <= cfg_reg0;
                else
                    vata_i3 <= cfg_reg1;
                end if;
            when GC_XFER_DATA =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "001"; vata_s_latch <= '0';
                cfg_reg_from_pl <= std_logic_vector(reg_from_vata);
            when GC_SET_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '0';
            when GC_LATCH_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '1';
            ----Acquisition modes----------------------------------------------------------------------------
            when ACQ_DELAY =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "010"; vata_s_latch <= '0';
            when ACQ_HOLD =>
                vata_i1 <= '1'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "010"; vata_s_latch <= '0';
            when ACQ_LOWER_I1 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "010"; vata_s_latch <= '0';
            when ACQ_SET_MODE_M4 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "011"; vata_s_latch <= '0';
            ----Data conversion modes------------------------------------------------------------------------
            when CONV_LATCH_M4 =>
                -- i3 goes hi here in timing diagram
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '1'; vata_mode <= "011"; vata_s_latch <= '1';
            when CONV_RAISE_I3 =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '1'; vata_mode <= "011"; vata_s_latch <= '1';
            when CONV_LOWER_I4 =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "011"; vata_s_latch <= '0';
            when CONV_CLK_HI =>
                vata_i1 <= '1'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "011"; vata_s_latch <= '0';
            when CONV_CLK_LO =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "011"; vata_s_latch <= '0';
            when CONV_SET_MODE_M5 =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            ----Data readout states--------------------------------------------------------------------------
            when RO_LATCH_MODE_M5 =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '1';
            when RO_CLK_HI =>
                vata_i1 <= '1'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            when RO_READ_O6 =>
                vata_i1 <= '1'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            when RO_CLK_LO =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            when RO_SHIFT_DATA =>
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            ----Write header data----------------------------------------------------------------------------
            when RO_WFIFO_00 =>
                -- Write event ID
                data_tvalid <= '1';
                data_tdata  <= event_id_out; -- Write event id at head of data packet
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_01 =>
                -- Write event number
                -- We just wrote the event id, so now clear it:
                event_id_clr <= '1';
                data_tvalid  <= '1';
                data_tdata   <= pkt_event_counter;
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_02 =>
                -- Event trigger info
                data_tvalid <= '1';
                data_tdata(15 downto 0)  <= pkt_event_triggers;
                data_tdata(31 downto 16) <= (others => '0'); -- Room for more data here.
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_03 =>
                -- LSB's of the global counter
                data_tvalid <= '1';
                data_tdata  <= pkt_running_counter(31 downto 0);  -- lowest 32 bits the pkt_running_counter
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_04 =>
                -- MSB's of the global counter
                data_tvalid <= '1';
                data_tdata  <= pkt_running_counter(63 downto 32); -- highest 32 bits of pkt_running_counter
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_05 =>
                -- LSB's of the live-time counter
                data_tvalid <= '1';
                data_tdata  <= pkt_live_counter(31 downto 0);  -- lowest 32 bits the pkt_live_counter
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_06 =>
                -- MSB's of the live-time counter
                data_tvalid <= '1';
                data_tdata  <= pkt_live_counter(63 downto 32); -- highest 32 bits of pkt_live_counter
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            ----Write asic data------------------------------------------------------------------------------
            when RO_WFIFO_07 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(31 downto 0));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_08 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(63 downto 32));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_09 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(95 downto 64));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_10 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(127 downto 96));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_11 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(159 downto 128));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_12 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(191 downto 160));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_13 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(223 downto 192));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_14 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(255 downto 224));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_15 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(287 downto 256));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_16 =>
                data_tvalid <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(319 downto 288));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_17 =>
                data_tvalid  <= '1';
                data_tdata  <= std_logic_vector(reg_from_vata(351 downto 320));
                vata_i1 <= '0'; vata_i3 <= '1'; vata_i4 <= '0'; vata_mode <= "100";
            when RO_WFIFO_18 =>
                data_tvalid               <= '1';
                data_tdata(26 downto 0)   <= std_logic_vector(reg_from_vata(378 downto 352));
                data_tdata(31 downto 27)  <= (others => '0');
                data_tlast                <= '1';
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            when RO_SET_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '0';
            when RO_LATCH_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '1';
            when ABORT_WFIFO =>
                data_tvalid <= '1';
                data_tdata  <= (others => '1'); -- Aborted data packet. Write last word, as max val.
                data_tlast  <= '1';
                vata_i1 <= '0'; vata_i3 <= '1'     ; vata_i4 <= '0'; vata_mode <= "100"; vata_s_latch <= '0';
            when ABORT_SET_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '0';
            when ABORT_LATCH_MODE_M3 =>
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= "010"; vata_s_latch <= '1';
            when others =>
                -- Should never get here!
                vata_i1 <= '0'; vata_i3 <= '0'     ; vata_i4 <= '0'; vata_mode <= vata_mode; vata_s_latch <= '0';
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

    -- reg_indx counter. Make sure that we read/write the correct number
    -- of bits for the configuration register
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

    -- Process to read data in from the vata, into the `reg_from_vata` register.
    -- Data either comes in from vata_o5 or vata_o6, depending on if we are
    -- performing configuration readout or data readout.
    -- The configuration register comes in msb first, lsb last,
    -- so we write the data from o5 to bit 0, and shift left.
    -- Data comes in lsb first, msb last, so we read data into the
    -- highest bit (378 for data), and shift right.
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
                reg_from_vata(378) <= not vata_o6;
                reg_from_vata(519 downto 379) <= reg_from_vata(519 downto 379);
                reg_from_vata(377 downto 0) <= reg_from_vata(377 downto 0);
            elsif reg_clr = '1' then
                reg_from_vata <= (others => '0');
            else
                reg_from_vata <= reg_from_vata;
            end if;
        end if;
    end process;

    -- Live-time counter:
    process (rst_n, counter_rst, clk_100MHz)
    begin
        if rst_n = '0' or counter_rst = '1' then
            ulive_counter <= (others => '0');
        elsif rising_edge(clk_100MHz) then
            if current_state = IDLE then
                ulive_counter <= ulive_counter + to_unsigned(1, ulive_counter'length);
            else
                ulive_counter <= ulive_counter;
            end if;
        end if;
    end process;

    -- Event counter:
    process (rst_n, event_counter_rst, inc_event_counter)
    begin
        if rst_n = '0' or event_counter_rst = '1' then
            uevent_counter <= (others => '0');
        elsif rising_edge(inc_event_counter) then -- we are finished with data readout for an event
            uevent_counter <= uevent_counter + to_unsigned(1, uevent_counter'length);
        else
            uevent_counter <= uevent_counter;
        end if;
    end process;

    -- Latch data that goes into the packet on `set_pkt_data` rising edge.
    process (rst_n, set_pkt_data)
    begin
        if rst_n = '0' then
            pkt_running_counter <= (others => '0');
            pkt_live_counter    <= (others => '0');
            pkt_event_counter   <= (others => '0');
            pkt_event_triggers  <= (others => '0');
        elsif rising_edge(set_pkt_data) then
            pkt_running_counter <= running_counter;
            pkt_live_counter    <= std_logic_vector(ulive_counter);
            pkt_event_counter   <= std_logic_vector(uevent_counter);
            pkt_event_triggers(11 downto 0) <= vata_hits_rising_edge;
            pkt_event_triggers(12)          <= fast_or_trigger;
            pkt_event_triggers(13)          <= trigger_ack;
            pkt_event_triggers(14)          <= force_trigger;
            pkt_event_triggers(15)          <= cal_pulse_trigger;
        else
            pkt_running_counter <= pkt_running_counter;
            pkt_live_counter    <= pkt_live_counter;
            pkt_event_counter   <= pkt_event_counter;
            pkt_event_triggers  <= pkt_event_triggers;
        end if;
    end process;

    vata_s0 <= vata_mode(0);
    vata_s1 <= vata_mode(1);
    vata_s2 <= vata_mode(2);

    cfg_bit  <= cfg_reg_from_ps(reg_indx);
    cfg_reg0 <= reg_from_vata(0);
    cfg_reg1 <= reg_from_vata(1);

    live_counter    <= std_logic_vector(ulive_counter);
    event_counter   <= std_logic_vector(uevent_counter);
    
    -- Trigger acquisition:
    trigger_acq <= (force_trigger and force_trigger_ena)
                or (fast_or_trigger and fast_or_trigger_ena)
                or (trigger_ack and ack_trigger_ena)
                or (vata_hits_rising_edge(0) and local_vata_trigger_ena(0))
                or (vata_hits_rising_edge(1) and local_vata_trigger_ena(1))
                or (vata_hits_rising_edge(2) and local_vata_trigger_ena(2))
                or (vata_hits_rising_edge(3) and local_vata_trigger_ena(3))
                or (vata_hits_rising_edge(4) and local_vata_trigger_ena(4))
                or (vata_hits_rising_edge(5) and local_vata_trigger_ena(5))
                or (vata_hits_rising_edge(6) and local_vata_trigger_ena(6))
                or (vata_hits_rising_edge(7) and local_vata_trigger_ena(7))
                or (vata_hits_rising_edge(8) and local_vata_trigger_ena(8))
                or (vata_hits_rising_edge(9) and local_vata_trigger_ena(9))
                or (vata_hits_rising_edge(10) and local_vata_trigger_ena(10))
                or (vata_hits_rising_edge(11) and local_vata_trigger_ena(11));

    -- DEBUG --

    vata_hits_rising_edge_out <= vata_hits_rising_edge(1 downto 0);

    state_out          <= current_state;
    event_id_out_debug <= event_id_out;
    trigger_acq_out    <= trigger_acq;


end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
