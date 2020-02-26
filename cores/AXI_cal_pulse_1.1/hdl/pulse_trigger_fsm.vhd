-- pulse_trigger_fsm
-- =================
--  Simple FSM for controlling calibration pulse output and vata trigger outputs.
--
--  Notes on inputs:
--      * n_pulses_in:
--            Number of pulses to send out. If n_pulses_in is 0, repeatedly emit pulses.
--      * run_pulses: 
--            On rising edge, start sending pulses. If n_pulses_in is 0, then pulses will be
--            sent as long as run_pulses is high.
--      * cal_pulse_ena:
--            calibrating pulses emitted if this is high.
--      * vata_trigger_ena:
--            triggers sent for vata's if this is high
--      * cal_pulse_width:
--            cal_pulse_out will be high for `cal_pulse_width` number of clock cycles for each pulse.
--      * trigger_delay:
--            vata_trigger_out will go high `trigger_delay` clock cycles after cal_pluse_trigger_out goes high.
--            If trigger_delay > cal_pulse_width, vata triggers will never occur.
--      * pulse_wait:
--            After finishing a cal pulse, wait `pulse_wait` number of cycles before the next calibration pulse.
--            A calibration pulse will be sent out every `cal_pulse_width` + `pulse_wait` clock cycles.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_trigger_fsm is
    generic (
        C_S_AXI_DATA_WIDTH : integer := 32
       );
    port (
        clk                   : in std_logic;
        rst_n                 : in std_logic := '0';
        run_pulses            : in std_logic;
        cal_pulse_ena         : in std_logic;
        vata_trigger_ena      : in std_logic;
        cal_pulse_width       : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- Pulse width 
        trigger_delay         : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- VATA trigger out delay
        n_pulses_in           : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- Number of pulses to perform
        pulse_wait            : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- How long to wait between pulses
    	cal_pulse_trigger_out : out std_logic := '0';
    	vata_trigger_out      : out std_logic := '0'
    	);
end pulse_trigger_fsm;

architecture arch_imp of pulse_trigger_fsm is
    constant STATE_WIDTH        : integer := 3;
    constant IDLE               : std_logic_vector(STATE_WIDTH-1 downto 0) := o"0";
    constant CAL_PULSE_HOLD     : std_logic_vector(STATE_WIDTH-1 downto 0) := o"1";
    constant CAL_PULSE_WAIT     : std_logic_vector(STATE_WIDTH-1 downto 0) := o"2";
    constant INF_CAL_PULSE_HOLD : std_logic_vector(STATE_WIDTH-1 downto 0) := o"3";
    constant INF_CAL_PULSE_WAIT : std_logic_vector(STATE_WIDTH-1 downto 0) := o"4";

    constant N_PULSE_ZERO : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal current_state         : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');
    signal next_state            : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');    
        
    -- Number of clock cycles to hold pulse high:
    -- Read in from `cal_pulse_width` input.
    signal cal_pulse_nhold       : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal cal_pulse_nwait       : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);

    -- Number of clock cycles to wait before sending out VATA trigger.
    -- Read in from `trigger_delay` input.
    signal vata_trig_delay_nhold : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
        
    signal last_run_pulses      : std_logic := '0'; -- Track the last trigger state. 
    signal start_cal_pulses     : std_logic := '0'; -- Flag for starting the cal pulse hold counter
        
    signal counter_clr           : std_logic := '0';
    signal vata_trig_counter_clr : std_logic := '0'; -- Redundant w/above?
    
    signal counter_ena           : std_logic := '0'; -- Enable main pulse counter.
    signal vata_trig_delay_counter_ena : std_logic := '0'; -- Enable VATA trigger delay counter.
        
    signal counter                 : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal vata_trig_delay_counter : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal n_pulses : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);    -- Number of pulses to perform
    signal pulse_count : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal inc_pulse_count : std_logic := '0';
    signal pulse_count_clr : std_logic := '0';

begin
        
    --Updates the state machine.
    p_STATE_UPDATE : process (rst_n, clk)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    --Handle state machine transfers.
    p_STATE_XFER : process (rst_n, current_state, start_cal_pulses, counter, cal_pulse_nhold, cal_pulse_nwait, n_pulses, run_pulses)
    begin
        counter_clr     <= '0';
        pulse_count_clr <= '0';
        inc_pulse_count <= '0';
        if rst_n = '0' then
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if start_cal_pulses = '1' then
                        counter_clr <= '1';
                        if n_pulses = N_PULSE_ZERO then
                            next_state <= INF_CAL_PULSE_HOLD;
                        else
                            pulse_count_clr <= '1';
                            next_state <= CAL_PULSE_HOLD;
                        end if;
                    else
                        next_state <= IDLE;
                    end if;
                when CAL_PULSE_HOLD =>
                    -- If the counter has grown larger than the width of nhold, go to idle.
                    -- Else, stay in hold.
                    if counter >= cal_pulse_nhold-1 then
                        if pulse_count >= n_pulses-1 then
                            next_state <= IDLE;
                        else
                            counter_clr <= '1';
                            inc_pulse_count <= '1';
                            next_state <= CAL_PULSE_WAIT;
                        end if;
                    else
                        next_state <= CAL_PULSE_HOLD;
                    end if;
                when CAL_PULSE_WAIT =>
                    if counter >= cal_pulse_nwait-1 then
                        counter_clr <= '1';
                        next_state <= CAL_PULSE_HOLD;
                    else
                        next_state <= CAL_PULSE_WAIT;
                    end if;
                when INF_CAL_PULSE_HOLD =>
                    -- Same as `CAL_PULSE_HOLD` but different rut.
                    if counter >= cal_pulse_nhold-1 then
                        counter_clr <= '1';
                        next_state <= INF_CAL_PULSE_WAIT;
                    else
                        next_state <= INF_CAL_PULSE_HOLD;
                    end if;
                when INF_CAL_PULSE_WAIT =>
                    if run_pulses = '0' then
                        next_state <= IDLE;
                    elsif counter >= cal_pulse_nwait-1 then
                        counter_clr <= '1';
                        next_state <= INF_CAL_PULSE_HOLD;
                    else
                        next_state <= INF_CAL_PULSE_WAIT;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process p_STATE_XFER;

    p_OUTPUTS : process (current_state, cal_pulse_ena, vata_trigger_ena, vata_trig_delay_counter, vata_trig_delay_nhold )
    begin
        counter_ena <= '0';
        vata_trig_delay_counter_ena <= '0';
        cal_pulse_trigger_out <= '0';
        vata_trigger_out <= '0';
        if current_state = CAL_PULSE_HOLD or current_state = INF_CAL_PULSE_HOLD then
            counter_ena <= '1';
            vata_trig_delay_counter_ena <= '1';
            if cal_pulse_ena = '1' then
                cal_pulse_trigger_out <= '1';
            else
                cal_pulse_trigger_out <= '0';
            end if;
            if vata_trigger_ena = '1' and vata_trig_delay_counter > vata_trig_delay_nhold-1 then
                vata_trig_delay_counter_ena <= '0'; --Doesn't really matter, but stops the counter. 
                vata_trigger_out <= '1';
            else
                vata_trigger_out <= '0';
            end if;
        elsif current_state = CAL_PULSE_WAIT or current_state = INF_CAL_PULSE_WAIT then
            counter_ena <= '1';
        end if;
    end process p_OUTPUTS;

    p_INITIATE : process (rst_n, clk)
    begin
        if rst_n = '0' then
            last_run_pulses <= '0';
        elsif rising_edge(clk) then
            if last_run_pulses = '0' and run_pulses = '1' then
                start_cal_pulses <= '1';
            else
                start_cal_pulses <= '0';
            end if;
            last_run_pulses <= run_pulses;
        end if;
    end process p_INITIATE;

    p_COUNTER : process (rst_n, clk)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if counter_clr = '1' then
                counter <= (others => '0');
            elsif counter_ena = '1' then
                counter <= counter + 1;
            else
                counter <= counter;
            end if;
        end if;
    end process p_COUNTER;
    
    --Identical to above, but for the delay counter that waits before sending out the VATA trigger.
    p_VATA_TRIG_COUNTER : process (rst_n, clk)
    begin
         if rst_n = '0' then
            vata_trig_delay_counter <= (others => '0');
        elsif rising_edge(clk) then
            if counter_clr = '1' then
                vata_trig_delay_counter <= (others => '0');
            elsif vata_trig_delay_counter_ena = '1' then
                vata_trig_delay_counter <= vata_trig_delay_counter + 1;
            else
                vata_trig_delay_counter <= vata_trig_delay_counter;
            end if;
        end if;       
    end process p_VATA_TRIG_COUNTER; 

    p_PULSE_COUNTER : process (rst_n, clk)
    begin
        if rst_n = '0' then
            pulse_count <= (others => '0');
        elsif rising_edge(clk) then
            if pulse_count_clr = '1' then
                pulse_count <= (others => '0');
            elsif inc_pulse_count = '1' then
                pulse_count <= pulse_count + 1;
            else
                pulse_count <= pulse_count;
            end if;
        end if;
    end process p_PULSE_COUNTER;

    n_pulses              <= unsigned(n_pulses_in);
    cal_pulse_nhold       <= unsigned(cal_pulse_width);
    cal_pulse_nwait       <= unsigned(pulse_wait);
    vata_trig_delay_nhold <= unsigned(trigger_delay);
    
end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
