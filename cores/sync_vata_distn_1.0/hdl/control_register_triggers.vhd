----------------------------------------------------------------------------------
-- Create Date: 12/23/2019 02:53:21 PM
-- Person whose fault this is: Lucas Parker <lpp@lanl.gov>
-- Module Name: control_register_triggers - Behavioral
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_register_triggers is
    generic (
        AXI_DATA_WIDTH     : integer := 32;
        AXI_ADDR_WIDTH     : integer := 8;
        N_TRIGGERS         : integer := 16;
        AXI_AWADDR_CONTROL : integer := 0);
    port (
        axi_aclk    : in std_logic;
        axi_aresetn : in std_logic;
        axi_awaddr  : in std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
        axi_wdata   : in std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        axi_wready  : in std_logic;
        triggers    : out std_logic_vector(N_TRIGGERS-1 downto 0));
end control_register_triggers;

architecture Behavioral of control_register_triggers is
    constant control_reg   : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0)
                           := std_logic_vector(to_unsigned(AXI_AWADDR_CONTROL, AXI_ADDR_WIDTH));
    signal last_axi_wready : std_logic := '0';

begin

    process (axi_aresetn, axi_aclk)
    begin
        if axi_aresetn = '0' then
            triggers <= (others => '0');
            last_axi_wready <= '0';
        elsif rising_edge(axi_aclk) then
            if axi_wready = '1' and last_axi_wready = '0' and axi_awaddr = control_reg then
                triggers <= (others => '0');
                if unsigned(axi_wdata) < N_TRIGGERS then
                    triggers(to_integer(unsigned(axi_wdata))) <= '1';
                end if;
            else
                triggers <= (others => '0');
            end if;
            last_axi_wready <= axi_wready;
        end if;
    end process;
                

end Behavioral;
-- vim: set ts=4 sw=4 sts=4 et:
