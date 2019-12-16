-- cal_pulse
-- Simply asserts the cal_pulse_trigger_out for given CAL_PULSE_NHOLD
-- duration upon receiving rising edge on trigger_cal_pulse input.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cal_pulse is
    generic (
        C_S_AXI_DATA_WIDTH : integer := 32;
        vata_trigger_pulse_width : integer := 5

        --CAL_PULSE_NHOLD : integer := 200; -- 2us with 100MHz clock
        --COUNTER_WIDTH   : integer := 9
       );
    port (
        clk                   : in std_logic;
        rst_n                 : in std_logic := '0';
        --cal_pulse_trigger_in  : in std_logic;
    	cal_pulse_trigger_out : out std_logic := '0';
    	vata_trigger_out      : out std_logic := '0';
    	
    	reg0 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- start
    	reg1 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- Pulse width
    	reg2 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- number of counts 
    	reg3 : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)  -- VATA trigger out delay
    	
    	);
end cal_pulse;

architecture arch_imp of cal_pulse is
    constant STATE_WIDTH   : integer := 1; -- very simple, on or off.
    constant IDLE          : std_logic_vector(STATE_WIDTH-1 downto 0) := "0";
    constant HOLD          : std_logic_vector(STATE_WIDTH-1 downto 0) := "1";
    --constant COUNTER_LIMIT : unsigned(COUNTER_WIDTH-1 downto 0) := to_unsigned(CAL_PULSE_NHOLD-1, COUNTER_WIDTH);    
    
    signal cal_pulse_nhold       : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
    
    signal vata_trig_delay : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vata_trig_out_counter : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vata_trig_counter_clr : std_logic := '0';
    signal vata_trig_counter_ena : std_logic := '0';
    
    
    signal cal_pulse_trigger_in : std_logic := '0';
    
    signal last_trigger         : std_logic := '0';
    signal start_cal_pulse_hold : std_logic := '0';
    signal counter_clr          : std_logic := '0';
    signal counter_ena          : std_logic := '0';
    signal counter              : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal current_state        : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');
    signal next_state           : std_logic_vector(STATE_WIDTH-1 downto 0) := (others => '0');
begin
    
    p_PARSE_REG: process (clk)
    begin
        if rising_edge(clk) then
            cal_pulse_trigger_in <= reg0(0);        
            cal_pulse_nhold <= unsigned(reg1);
            vata_trig_delay <= unsigned(reg3);
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

    p_STATE_XFER : process (rst_n, current_state, start_cal_pulse_hold)
    begin
        counter_clr <= '0';
        if rst_n = '0' then
            next_state <= IDLE;
        else
            case (current_state) is
                when IDLE =>
                    if start_cal_pulse_hold = '1' then
                        counter_clr <= '1';
                        next_state <= HOLD;
                    else
                        next_state <= IDLE;
                    end if;
                when HOLD =>
                    if counter >= cal_pulse_nhold-1 then
                        next_state <= IDLE;
                    else
                        next_state <= HOLD;
                    end if;
            end case;
        end if;
    end process p_STATE_XFER;

    p_OUTPUTS : process (current_state)
    begin
        case (current_state) is
            when IDLE =>
                counter_ena <= '0';
                cal_pulse_trigger_out <= '0';
            when HOLD =>
                counter_ena <= '1';
                cal_pulse_trigger_out <= '1';
        end case;
    end process p_OUTPUTS;

    p_TRIGGER : process (rst_n, clk)
    begin
        if rst_n = '0' then
            last_trigger <= '0';
        elsif rising_edge(clk) then
            if last_trigger = '0' and cal_pulse_trigger_in = '1' then
                start_cal_pulse_hold <= '1';
            else
                start_cal_pulse_hold <= '0';
            end if;
            last_trigger <= cal_pulse_trigger_in;
        end if;
    end process p_TRIGGER;

    p_COUNTER : process (rst_n, clk)
    begin
        if rst_n = '0' then
            counter <= (others => '0');
        elsif rising_edge(clk) then
            if counter_clr = '1' then
                counter <= (others => '0');
            elsif counter_ena = '1' then
                counter <= counter + to_unsigned(1, counter'length);
            else
                counter <= counter;
            end if;
        end if;
    end process p_COUNTER;
    
    --Identical to above, but for a different counter.
    p_VATA_trig_out_counter : process (rst_n, clk)
    begin
         if rst_n = '0' then
            vata_trig_out_counter <= (others => '0');
        elsif rising_edge(clk) then
            if vata_trig_counter_clr = '1' then
                vata_trig_out_counter <= (others => '0');
            elsif vata_trig_counter_ena = '1' then
                vata_trig_out_counter <= vata_trig_out_counter + 1;
            else
                vata_trig_out_counter <= vata_trig_out_counter;
            end if;
        end if;       
    end process p_VATA_trig_out_counter; 
    
    
    trigger_VATA : process (vata_trig_out_counter)
    begin
        --variable pulse_width_ctr: integer range 0 to vata_trigger_pulse_width;
        variable pulse_width_ctr : integer range 0 to 10;
        
        if vata_trig_out_counter >= vata_trig_delay then
            vata_trig_counter_ena <= '0';
            vata_trigger_out
        end if;
        
    end process trigger_VATA;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
