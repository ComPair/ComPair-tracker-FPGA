----------------------------------------------------------------------------------
-- Stupid simple module to fake the asic 05 line
-- Useful if there is no AFE, and you want to test
-- the DBE, since conversion/readout requires something to happen
-- on the asic 05 line
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fake_asic is
    Port ( clk : in std_logic;
           vata_state : in std_logic_vector (7 downto 0);
           vata_o5    : out std_logic);
end fake_asic;

architecture Behavioral of fake_asic is
    -- Copied from vata_460p3_iface_fsm:
    constant CONV_LATCH_M4    : std_logic_vector(7 downto 0) := x"18";
    constant CONV_RAISE_I3    : std_logic_vector(7 downto 0) := x"19";
    constant CONV_LOWER_I4    : std_logic_vector(7 downto 0) := x"1A";
    constant CONV_CLK_HI      : std_logic_vector(7 downto 0) := x"1B";
    constant CONV_CLK_LO      : std_logic_vector(7 downto 0) := x"1C";
    constant CONV_SET_MODE_M5 : std_logic_vector(7 downto 0) := x"1D";
    constant RO_LATCH_MODE_M5 : std_logic_vector(7 downto 0) := x"1E";
    constant RO_CLK_HI        : std_logic_vector(7 downto 0) := x"1F";
    constant RO_READ_O6       : std_logic_vector(7 downto 0) := x"20";
    constant RO_CLK_LO        : std_logic_vector(7 downto 0) := x"21";
    constant RO_SHIFT_DATA    : std_logic_vector(7 downto 0) := x"22";

    -- Local states:
    constant LOCAL_IDLE     : std_logic_vector(1 downto 0) := "00";
    constant LOCAL_CONV_END : std_logic_vector(1 downto 0) := "01";
    constant LOCAL_RO_WAIT  : std_logic_vector(1 downto 0) := "10";
    constant LOCAL_RO_END   : std_logic_vector(1 downto 0) := "11";

    signal current_state : std_logic_vector(1 downto 0) := LOCAL_IDLE;
    signal next_state : std_logic_vector(1 downto 0) := LOCAL_IDLE;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process (vata_state)
    begin
        case (current_state) is
            when LOCAL_IDLE =>
                if vata_state = CONV_CLK_HI then
                    next_state <= LOCAL_CONV_END;
                else
                    next_state <= LOCAL_IDLE;
                end if;
            when LOCAL_CONV_END =>
                if vata_state = RO_CLK_HI then
                    next_state <= LOCAL_RO_WAIT;
                else
                    next_state <= LOCAL_CONV_END;
                end if;
            when LOCAL_RO_WAIT =>
                if vata_state = RO_CLK_LO then
                    next_state <= LOCAL_RO_END;
                else
                    next_state <= LOCAL_RO_WAIT;
                end if;
            when LOCAL_RO_END =>
                if vata_state = RO_SHIFT_DATA then
                    next_state <= LOCAL_IDLE;
                else
                    next_state <= LOCAL_RO_END;
                end if;
            when others =>
                next_state <= LOCAL_IDLE;
        end case;
    end process;

    with current_state select
        vata_o5 <= '1' when LOCAL_CONV_END,
                   '1' when LOCAL_RO_END,
                   '0' when others;
        
end Behavioral;
-- vim: set ts=4 sw=4 sts=4 et:
