-- # combine_fee_outs
--     This module combines the FEE outputs from each VATA
--     to provide a single FEE_hit, FEE_busy, FEE_ready.
library ieee;
use ieee.std_logic_1164.all;

entity combine_fee_outs is
    port (
        clk           : in std_logic;
        rst_n         : in std_logic;
        FEE_hit0      : in std_logic;
        FEE_busy0     : in std_logic;
        FEE_hit1      : in std_logic;
        FEE_busy1     : in std_logic;
        FEE_hit_out   : out std_logic;
        FEE_busy_out  : out std_logic;
        FEE_ready_out : out std_logic);
end combine_fee_outs;

architecture arch_imp of combine_fee_outs is

    component stay_high_5_cycles is
        generic (
            N_CYCLES_WIDTH : integer := 8;
            N_CYCLES       : integer := 5);
        port (
            clk      : in std_logic;
            rst_n    : in std_logic;
            data_in  : in std_logic;
            data_out : out std_logic);
    end component stay_high_5_cycles;
        
    signal FEE_busy_or : std_logic := '0';

begin
    FEE_hit_out <= FEE_hit0 or FEE_hit1;

    FEE_busy_or <= FEE_busy0 or FEE_busy1;
    FEE_busy_out <= FEE_busy_or;
    
    gen_fee_ready_out : stay_high_5_cycles
        generic map (
            N_CYCLES_WIDTH => 3,
            N_CYCLES       => 5
        ) port map (
            clk            => clk,
            rst_n          => rst_n,
            data_in        => (not FEE_busy0) and (not FEE_busy1),
            data_out       => FEE_ready_out
        );

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:

