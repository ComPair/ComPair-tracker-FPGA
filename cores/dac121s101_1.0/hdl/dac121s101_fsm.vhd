library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity dac121s101_fsm is
  generic (
    REGISTER_DATA_WIDTH : integer := 16;
    SELECT_MASK_WIDTH : integer := 4);
    Port ( 
      clk                      : in  std_logic;
      rst_n                    : in  std_logic;
      delay_register           : in std_logic_vector(REGISTER_DATA_WIDTH-1 downto 0);
      input_word               : in  std_logic_vector(15 downto 0);
      write_trig               : in  std_logic;
      select_mask              : in  std_logic_vector(SELECT_MASK_WIDTH-1 downto 0);
      fsm_done                 : out std_logic;
      out_sync                 : out std_logic_vector(SELECT_MASK_WIDTH-1 downto 0);
      out_mosi                 : out std_logic;
      out_sclk                 : out std_logic);
end dac121s101_fsm;


architecture behave of dac121s101_fsm is

  constant state_bitwidth : integer := 16;
  signal current_state    : std_logic_vector(state_bitwidth-1 downto 0);
  signal next_state       : std_logic_vector(state_bitwidth-1 downto 0);


---------------------
-- State Enumeration
---------------------

  constant IDLE                 : std_logic_vector(state_bitwidth-1 downto 0) := x"0000";
  constant SCLK_ONLY_a    : std_logic_vector(state_bitwidth-1 downto 0) := x"0001";
  constant SCLK_ONLY_b    : std_logic_vector(state_bitwidth-1 downto 0) := x"0002";
  constant SCLK_ONLY_c    : std_logic_vector(state_bitwidth-1 downto 0) := x"0003";
  constant SCLK_ONLY_d    : std_logic_vector(state_bitwidth-1 downto 0) := x"0004";
  constant SYNC_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0005";
  constant SYNC_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0006";
  constant DB15_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0010";
  constant DB15_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0011";
  constant DB14_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0012";
  constant DB14_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0013";
  constant DB13_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0014";
  constant DB13_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0015";
  constant DB12_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0016";
  constant DB12_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0017";
  constant DB11_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0018";
  constant DB11_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0019";
  constant DB10_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"001A";
  constant DB10_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"001B";
  constant DB9_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"001C";
  constant DB9_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"001D";
  constant DB8_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"001E";
  constant DB8_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"001F";
  constant DB7_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"0020";
  constant DB7_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"0021";
  constant DB6_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"0022";
  constant DB6_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"0023";
  constant DB5_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"0024";
  constant DB5_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"0025";
  constant DB4_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"0026";
  constant DB4_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"0027";
  constant DB3_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"0028";
  constant DB3_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"0029";
  constant DB2_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"002A";
  constant DB2_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"002B";
  constant DB1_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"002C";
  constant DB1_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"002D";
  constant DB0_set   : std_logic_vector(state_bitwidth-1 downto 0) := x"002E";
  constant DB0_clk   : std_logic_vector(state_bitwidth-1 downto 0) := x"002F"; 
  constant SYNC_END_set  : std_logic_vector(state_bitwidth-1 downto 0) := x"0030";
  constant SYNC_END_clk  : std_logic_vector(state_bitwidth-1 downto 0) := x"0031";
  
  
-- counter_stay = keeps us in a state until its time to move on. Only references current states wait time
  signal counter_stay_enable : std_logic;
  signal counter_stay_clr    : std_logic;
  signal counter_stay_value  : std_logic_vector(REGISTER_DATA_WIDTH-1 downto 0);
  signal select_mask_inverted : std_logic_vector(SELECT_MASK_WIDTH-1 downto 0);
  
begin


gen: for i in 0 to SELECT_MASK_WIDTH-1 generate
    select_mask_inverted(i) <= not select_mask(I);
end generate;

  process (rst_n, clk)
  begin
    if rst_n = '0' then
      current_state     <= IDLE;
    elsif rising_edge (clk) then
      current_state     <= next_state;
    end if;
  end process;

  
  process (rst_n, write_trig, current_state, counter_stay_value, delay_register)
  begin
  counter_stay_enable         <= '1';
  counter_stay_clr            <= '0';
  if rst_n = '0' then
      counter_stay_enable         <= '0';
      counter_stay_clr            <= '1';
      next_state <= IDLE;
  else
  case (current_state) is
    when IDLE =>
      if (write_trig = '1' ) then
        next_state <= SCLK_ONLY_a;
        counter_stay_enable <= '0';
        counter_stay_clr    <= '1';
      else
        next_state <= IDLE;
        counter_stay_enable <= '0';
        counter_stay_clr    <= '1';
      end if;

    when SCLK_ONLY_a =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SCLK_ONLY_b;
      else
        next_state                  <= SCLK_ONLY_a;
      end if;  

    when SCLK_ONLY_b =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SCLK_ONLY_c;
      else
        next_state                  <= SCLK_ONLY_b;
      end if;

    when SCLK_ONLY_c =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SCLK_ONLY_d;
      else
        next_state                  <= SCLK_ONLY_c;
      end if;  

    when SCLK_ONLY_d =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SYNC_set;
        else
        next_state                  <= SCLK_ONLY_d;
      end if;

    when SYNC_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SYNC_clk;
      else
        next_state                  <= SYNC_set;
      end if;

    when SYNC_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB15_set;
      else
        next_state                  <= SYNC_clk;
      end if;

    when DB15_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB15_clk;
      else
        next_state                  <= DB15_set;
      end if;

    when DB15_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB14_set;
      else
        next_state                  <= DB15_clk;
      end if;

    when DB14_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB14_clk;
      else
        next_state                  <= DB14_set;
      end if;

    when DB14_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB13_set;
      else
        next_state                  <= DB14_clk;
      end if;

    when DB13_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB13_clk;
      else
        next_state                  <= DB13_set;
      end if;

    when DB13_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB12_set;
      else
        next_state                  <= DB13_clk;
      end if;

    when DB12_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB12_clk;
      else
        next_state                  <= DB12_set;
      end if;

    when DB12_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB11_set;
      else
        next_state                  <= DB12_clk;
      end if;

    when DB11_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB11_clk;
      else
        next_state                  <= DB11_set;
      end if;

    when DB11_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB10_set;
      else
        next_state                  <= DB11_clk;
      end if;

    when DB10_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB10_clk;
      else
        next_state                  <= DB10_set;
      end if;

    when DB10_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB9_set;
      else
        next_state                  <= DB10_clk;
      end if;

    when DB9_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB9_clk;
      else
        next_state                  <= DB9_set;
      end if;

    when DB9_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB8_set;
      else
        next_state                  <= DB9_clk;
      end if;

    when DB8_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB8_clk;
      else
        next_state                  <= DB8_set;
      end if;

    when DB8_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB7_set;
      else
        next_state                  <= DB8_clk;
      end if;

    when DB7_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB7_clk;
      else
        next_state                  <= DB7_set;
      end if;

    when DB7_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB6_set;
      else
        next_state                  <= DB7_clk;
      end if;

    when DB6_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB6_clk;
      else
        next_state                  <= DB6_set;
      end if;

    when DB6_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB5_set;
      else
        next_state                  <= DB6_clk;
      end if;

    when DB5_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB5_clk;
      else
        next_state                  <= DB5_set;
      end if;

    when DB5_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB4_set;
      else
        next_state                  <= DB5_clk;
      end if;

    when DB4_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB4_clk;
      else
        next_state                  <= DB4_set;
      end if;

    when DB4_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB3_set;
      else
        next_state                  <= DB4_clk;
      end if;

    when DB3_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB3_clk;
      else
        next_state                  <= DB3_set;
      end if;

    when DB3_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB2_set;
      else
        next_state                  <= DB3_clk;
      end if;

    when DB2_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB2_clk;
      else
        next_state                  <= DB2_set;
      end if;

    when DB2_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB1_set;
      else
        next_state                  <= DB2_clk;
      end if;

    when DB1_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB1_clk;
      else
        next_state                  <= DB1_set;
      end if;

    when DB1_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB0_set;
      else
        next_state                  <= DB1_clk;
      end if;

    when DB0_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= DB0_clk;
      else
        next_state                  <= DB0_set;
      end if;

    when DB0_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SYNC_END_set;
      else
        next_state                  <= DB0_clk;
      end if;


      
    when SYNC_END_set =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= SYNC_END_clk;
      else
        next_state                  <= SYNC_END_set;
      end if;

    when SYNC_END_clk =>
      if (counter_stay_value >= delay_register) then
        counter_stay_clr            <= '1';
        next_state                  <= IDLE;
      else
        next_state                  <= SYNC_END_clk;
      end if;
    when others =>
      next_state <= IDLE;
    end case;
  end if;
end process;

output_logic : process(current_state, input_word, select_mask)
begin
  case (current_state) is
    when IDLE         => out_sclk <= '0';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '1';
    when SCLK_ONLY_a  => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= '0';             fsm_done <= '0';
    when SCLK_ONLY_b  => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= '0';             fsm_done <= '0';
    when SCLK_ONLY_c  => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= '0';             fsm_done <= '0';
    when SCLK_ONLY_d  => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= '0';             fsm_done <= '0';
    when SYNC_set     => out_sclk <= '1';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '0';
    when SYNC_clk     => out_sclk <= '0';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '0';
    when DB15_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(15);  fsm_done <= '0';
    when DB15_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(15);  fsm_done <= '0';
    when DB14_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(14);  fsm_done <= '0';
    when DB14_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(14);  fsm_done <= '0';
    when DB13_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(13);  fsm_done <= '0';
    when DB13_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(13);  fsm_done <= '0';
    when DB12_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(12);  fsm_done <= '0';
    when DB12_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(12);  fsm_done <= '0';
    when DB11_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(11);  fsm_done <= '0';
    when DB11_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(11);  fsm_done <= '0';
    when DB10_set     => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(10);  fsm_done <= '0';
    when DB10_clk     => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(10);  fsm_done <= '0';
    when DB9_set      => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(9);   fsm_done <= '0';
    when DB9_clk      => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(9);   fsm_done <= '0';
    when DB8_set      => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(8);   fsm_done <= '0';
    when DB8_clk      => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(8);   fsm_done <= '0';
    when DB7_set      => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(7);   fsm_done <= '0';
    when DB7_clk      => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(7);   fsm_done <= '0';
    when DB6_set      => out_sclk <= '1';  out_sync <= (others => '0');       out_mosi <= input_word(6);   fsm_done <= '0';
    when DB6_clk      => out_sclk <= '0';  out_sync <= (others => '0');       out_mosi <= input_word(6);   fsm_done <= '0';
    when DB5_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(5);   fsm_done <= '0';
    when DB5_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(5);   fsm_done <= '0';
    when DB4_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(4);   fsm_done <= '0';
    when DB4_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(4);   fsm_done <= '0';
    when DB3_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(3);   fsm_done <= '0';
    when DB3_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(3);   fsm_done <= '0';
    when DB2_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(2);   fsm_done <= '0';
    when DB2_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(2);   fsm_done <= '0';
    when DB1_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(1);   fsm_done <= '0';
    when DB1_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(1);   fsm_done <= '0';
    when DB0_set      => out_sclk <= '1';  out_sync <= select_mask_inverted;  out_mosi <= input_word(0);   fsm_done <= '0';
    when DB0_clk      => out_sclk <= '0';  out_sync <= select_mask_inverted;  out_mosi <= input_word(0);   fsm_done <= '0';
    when SYNC_END_set => out_sclk <= '1';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '0';
    when SYNC_END_clk => out_sclk <= '1';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '0';
    when others       => out_sclk <= '1';  out_sync <= (others => '1');       out_mosi <= '0';             fsm_done <= '0';
  end case;
end process;

counter_stay : process (rst_n, clk)
  begin
    if (rst_n = '0') then
      counter_stay_value <= (others => '0');
    elsif rising_edge (clk) then
      if (counter_stay_clr = '1') then
        counter_stay_value <= (others => '0');
      elsif (counter_stay_enable = '1') then
        counter_stay_value <= counter_stay_value + '1';
      end if;
    end if;
  end process;
end behave;