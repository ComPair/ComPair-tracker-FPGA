----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/19/2020 04:15:34 PM
-- Design Name: 
-- Module Name: conditional_invert - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity conditional_invert is
    Port ( din : in STD_LOGIC;
           inv_ena : in STD_LOGIC;
           dout : out STD_LOGIC);
end local_invert;

architecture Behavioral of conditional_invert is

begin

dout <= not din when inv_ena = '1' else din;


end Behavioral;
