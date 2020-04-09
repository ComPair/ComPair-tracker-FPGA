-- rising_edge_vector
-- Given input std_logic_vector, return a vector
-- with '1' for each bit that just had rising edge.
library ieee;
use ieee.std_logic_1164.all;

entity rising_edge_vector is
    generic ( VECTOR_WIDTH : integer := 12 );
    port ( clk             : in std_logic
         ; rst_n           : in std_logic
    	 ; vector_in       : in std_logic_vector(VECTOR_WIDTH-1 downto 0)
    	 ; rising_edge_out : out std_logic_vector(VECTOR_WIDTH-1 downto 0)
         );
end rising_edge_vector;

architecture arch_imp of rising_edge_vector is

    signal last_vector : std_logic_vector(VECTOR_WIDTH-1 downto 0) := (others => '0');

begin

    process (rst_n, clk)
    begin
        if rst_n = '0' then
            last_vector <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to VECTOR_WIDTH-1 loop
                if last_vector(i) = '0' and vector_in(i) = '1' then
                    rising_edge_out(i) <= '1';
                else
                    rising_edge_out(i) <= '0';
                end if;
            end loop;
            last_vector <= vector_in;
        end if;
    end process;

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
