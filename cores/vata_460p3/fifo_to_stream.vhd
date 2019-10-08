----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/04/2019 10:29:48 AM
-- Design Name: 
-- Module Name: fifo_to_stream - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Transfer data from a native FIFO to an AXI4-lite stream fifo.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_to_stream is
    port ( clk        : in STD_LOGIC;
           rst_n      : in STD_LOGIC;
           fifo_empty : in STD_LOGIC;
           data_in    : in STD_LOGIC_VECTOR (511 downto 0);
           rd_en      : out STD_LOGIC;
           tvalid     : out std_logic;
           tlast      : out std_logic;
           tready     : in std_logic;
           tdata      : out std_logic_vector(31 downto 0);
           count_out  : out std_logic_vector(4 downto 0);
           state_out  : out std_logic_vector(3 downto 0));
end fifo_to_stream;

architecture Behavioral of fifo_to_stream is

    constant IDLE : std_logic_vector(3 downto 0) := x"0";
    constant RD_FIFO_WAIT : std_logic_vector(3 downto 0) := x"1";
    constant RD_FIFO : std_logic_vector(3 downto 0) := x"2";
    constant TX_DATA : std_logic_vector(3 downto 0) := x"3";
    
    constant NSEND: unsigned(4 downto 0) := to_unsigned(17, 5);
    constant NSEND_MINUS_ONE : unsigned(4 downto 0) := to_unsigned(16, 5);
     
    signal current_state : std_logic_vector(3 downto 0) := IDLE;
    signal next_state : std_logic_vector(3 downto 0) := IDLE;

    signal data_reg : unsigned(511 downto 0);
    signal count : unsigned(4 downto 0) := (others => '0');

begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process (current_state, fifo_empty, count)
    begin
        rd_en <= '0';
        case (current_state) is
            when IDLE =>
                if fifo_empty = '0' then
                    rd_en <= '1';
                    next_state <= RD_FIFO_WAIT;
                else
                    next_state <= IDLE;
                end if;
            when RD_FIFO_WAIT =>
                next_state <= RD_FIFO;
            when RD_FIFO =>
                next_state <= TX_DATA;
            when TX_DATA =>
                if count = NSEND then
                    next_state <= IDLE;
                else
                    next_state <= TX_DATA;
                end if;
            when others =>
                next_state <= IDLE;
        end case;
    end process;
    
    process (clk)
    begin
        if rising_edge(clk) then
            tvalid <= '0';
            tlast <= '0';
            tdata <= (others => '0');
            case (current_state) is
                when RD_FIFO =>
                    count <= (others => '0');
                    data_reg <= unsigned(data_in);
                when TX_DATA =>
                    if tready = '1' and count < NSEND then
                        if count = NSEND_MINUS_ONE then
                            tdata <= (others => '1');
                            tlast <= '1';
                        else
                            tdata <= std_logic_vector(data_reg(31 downto 0));
                            data_reg <= shift_right(data_reg, 32);
                            tlast <= '0';
                        end if;
                        tvalid <= '1';
                        count <= count + to_unsigned(1, count'length);
                    end if;
                when others =>
                    count <= (others => '0');
                    data_reg <= (others => '0');
            end case;
        end if;
    end process;
                         
    state_out <= current_state;
    count_out <= std_logic_vector(count);

end Behavioral;

-- vim: set ts=4 sw=4 sts=4 et:
