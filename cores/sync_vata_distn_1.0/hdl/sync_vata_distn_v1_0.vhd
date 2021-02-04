library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_vata_distn_v1_0 is
    generic (
        -- Users to add parameters here
        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 5
    );
    port (
        -- Users to add ports here
        global_counter     : out std_logic_vector(63 downto 0);
        global_counter_rst : out std_logic;
        force_trigger      : out std_logic;

        FEE_sideA_hit      : out std_logic;
        FEE_sideB_hit      : out std_logic;
        FEE_ready          : out std_logic;
        FEE_busy           : out std_logic;

        vata_hit_busy00    : in std_logic_vector(1 downto 0);
        vata_hit_busy01    : in std_logic_vector(1 downto 0);
        vata_hit_busy02    : in std_logic_vector(1 downto 0);
        vata_hit_busy03    : in std_logic_vector(1 downto 0);
        vata_hit_busy04    : in std_logic_vector(1 downto 0);
        vata_hit_busy05    : in std_logic_vector(1 downto 0);
        vata_hit_busy06    : in std_logic_vector(1 downto 0);
        vata_hit_busy07    : in std_logic_vector(1 downto 0);
        vata_hit_busy08    : in std_logic_vector(1 downto 0);
        vata_hit_busy09    : in std_logic_vector(1 downto 0);
        vata_hit_busy10    : in std_logic_vector(1 downto 0);
        vata_hit_busy11    : in std_logic_vector(1 downto 0);
        -- Concatenate hit signals to send back to individual vata's:
        -- Each bit is combined with (and NOT FEE_BUSY)
        vata_hits          : out std_logic_vector(11 downto 0);
        -- Debugging port; same as above port but ignoring the FEE_busy 
        vata_hits_noblock  : out std_logic_vector(11 downto 0);
        -- User ports ends
        -- Do not modify the ports beyond this line


        -- Ports of Axi Slave Bus Interface S00_AXI
        s00_axi_aclk    : in std_logic;
        s00_axi_aresetn : in std_logic;
        s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot  : in std_logic_vector(2 downto 0);
        s00_axi_awvalid : in std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid  : in std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in std_logic;
        s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot  : in std_logic_vector(2 downto 0);
        s00_axi_arvalid : in std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in std_logic
    );
end sync_vata_distn_v1_0;

architecture arch_imp of sync_vata_distn_v1_0 is

    -- component declaration
    component sync_vata_distn_v1_0_S00_AXI is
        generic
            ( C_S_AXI_DATA_WIDTH  : integer   := 32
            ; C_S_AXI_ADDR_WIDTH  : integer   := 5
            );
        port
            ( counter         : in std_logic_vector(63 downto 0)
            ; counter_rst     : out std_logic
            ; force_trigger   : out std_logic
            ; disable_hits    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
            ; global_hit_ena  : out std_logic
              -- The other ports:
            ; S_AXI_ACLK      : in std_logic
            ; S_AXI_ARESETN   : in std_logic
            ; S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)
            ; S_AXI_AWPROT    : in std_logic_vector(2 downto 0)
            ; S_AXI_AWVALID   : in std_logic
            ; S_AXI_AWREADY   : out std_logic
            ; S_AXI_WDATA     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
            ; S_AXI_WSTRB     : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0)
            ; S_AXI_WVALID    : in std_logic
            ; S_AXI_WREADY    : out std_logic
            ; S_AXI_BRESP     : out std_logic_vector(1 downto 0)
            ; S_AXI_BVALID    : out std_logic
            ; S_AXI_BREADY    : in std_logic
            ; S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)
            ; S_AXI_ARPROT    : in std_logic_vector(2 downto 0)
            ; S_AXI_ARVALID   : in std_logic
            ; S_AXI_ARREADY   : out std_logic
            ; S_AXI_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
            ; S_AXI_RRESP     : out std_logic_vector(1 downto 0)
            ; S_AXI_RVALID    : out std_logic
            ; S_AXI_RREADY    : in std_logic
            );
    end component sync_vata_distn_v1_0_S00_AXI;

    component sync_vata_fsm is
        port
            ( clk           : in std_logic
            ; rst_n         : in std_logic
            ; counter_rst   : in std_logic
            ; counter       : out std_logic_vector(63 downto 0)
            );
    end component sync_vata_fsm;

    component stay_high_n_cycles is
        generic
            ( N_CYCLES_WIDTH : integer := 4
            ; N_CYCLES       : integer := 5
            );
        port
            ( clk      : in std_logic
            ; rst_n    : in std_logic
            ; data_in  : in std_logic
            ; data_out : out std_logic
            );
    end component stay_high_n_cycles;

    signal counter_rst     : std_logic;
    signal counter_buf     : std_logic_vector(63 downto 0);
    signal counter_rst_buf : std_logic;

    signal FEE_busy_buf   : std_logic;
    signal disable_hits   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal global_hit_ena : std_logic;

    signal vata_hit00 : std_logic;
    signal vata_hit01 : std_logic;
    signal vata_hit02 : std_logic;
    signal vata_hit03 : std_logic;
    signal vata_hit04 : std_logic;
    signal vata_hit05 : std_logic;
    signal vata_hit06 : std_logic;
    signal vata_hit07 : std_logic;
    signal vata_hit08 : std_logic;
    signal vata_hit09 : std_logic;
    signal vata_hit10 : std_logic;
    signal vata_hit11 : std_logic;
    signal vata_busy00 : std_logic;
    signal vata_busy01 : std_logic;
    signal vata_busy02 : std_logic;
    signal vata_busy03 : std_logic;
    signal vata_busy04 : std_logic;
    signal vata_busy05 : std_logic;
    signal vata_busy06 : std_logic;
    signal vata_busy07 : std_logic;
    signal vata_busy08 : std_logic;
    signal vata_busy09 : std_logic;
    signal vata_busy10 : std_logic;
    signal vata_busy11 : std_logic;

begin

    -- Instantiation of Axi Bus Interface S00_AXI
    sync_vata_distn_v1_0_S00_AXI_inst : sync_vata_distn_v1_0_S00_AXI
        generic map
            ( C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH
            , C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
            )
        port map 
            ( counter        => counter_buf
            , counter_rst    => global_counter_rst  
            , force_trigger  => force_trigger
            , disable_hits   => disable_hits
            , global_hit_ena => global_hit_ena
            , S_AXI_ACLK     => s00_axi_aclk
            , S_AXI_ARESETN  => s00_axi_aresetn
            , S_AXI_AWADDR   => s00_axi_awaddr
            , S_AXI_AWPROT   => s00_axi_awprot
            , S_AXI_AWVALID  => s00_axi_awvalid
            , S_AXI_AWREADY  => s00_axi_awready
            , S_AXI_WDATA    => s00_axi_wdata
            , S_AXI_WSTRB    => s00_axi_wstrb
            , S_AXI_WVALID   => s00_axi_wvalid
            , S_AXI_WREADY   => s00_axi_wready
            , S_AXI_BRESP    => s00_axi_bresp
            , S_AXI_BVALID   => s00_axi_bvalid
            , S_AXI_BREADY   => s00_axi_bready
            , S_AXI_ARADDR   => s00_axi_araddr
            , S_AXI_ARPROT   => s00_axi_arprot
            , S_AXI_ARVALID  => s00_axi_arvalid
            , S_AXI_ARREADY  => s00_axi_arready
            , S_AXI_RDATA    => s00_axi_rdata
            , S_AXI_RRESP    => s00_axi_rresp
            , S_AXI_RVALID   => s00_axi_rvalid
            , S_AXI_RREADY   => s00_axi_rready
            );
    
    sync_vata_fsm_inst : sync_vata_fsm
        port map
            ( clk           => s00_axi_aclk
            , rst_n         => s00_axi_aresetn
            , counter_rst   => counter_rst_buf
            , counter       => counter_buf
            );

    -- Components for generating signals to TM:
    -- 
    -- stay_high_n_cycles components:
    --    create 50ns long pulse for FEE_hit's from or'ing the vata_hit's
    fee_hit_sideA_stay_high_inst : stay_high_n_cycles
        generic map
            ( N_CYCLES_WIDTH => 4
            , N_CYCLES       => 5
            ) 
        port map
            ( clk      => s00_axi_aclk
            , rst_n    => s00_axi_aresetn
            , data_in  => vata_hit00
                       or vata_hit01
                       or vata_hit02
                       or vata_hit03
                       or vata_hit04
                       or vata_hit05
            , data_out => FEE_sideA_hit
            );
    fee_hit_sideB_stay_high_inst : stay_high_n_cycles
        generic map
            ( N_CYCLES_WIDTH => 4
            , N_CYCLES       => 5
            ) 
        port map
           ( clk      => s00_axi_aclk
           , rst_n    => s00_axi_aresetn
           , data_in  => vata_hit06
                      or vata_hit07
                      or vata_hit08
                      or vata_hit09
                      or vata_hit10
                      or vata_hit11
           , data_out => FEE_sideB_hit
           );

    --    create 50ns long pulse for FEE_ready based of `not FEE_busy`
    fee_ready_stay_high_inst : stay_high_n_cycles
        generic map
            ( N_CYCLES_WIDTH => 4
            , N_CYCLES       => 5
            ) 
        port map
            ( clk      => s00_axi_aclk
            , rst_n    => s00_axi_aresetn
            , data_in  => not FEE_busy_buf
            , data_out => FEE_ready
            );

    -- XXX Does FEE_busy need to use the `global_hit_ena`?
    FEE_busy_buf <= vata_busy00
                 or vata_busy01
                 or vata_busy02
                 or vata_busy03
                 or vata_busy04
                 or vata_busy05
                 or vata_busy06
                 or vata_busy07
                 or vata_busy08
                 or vata_busy09
                 or vata_busy10
                 or vata_busy11;
    FEE_busy <= FEE_busy_buf;

    global_counter     <= counter_buf;
    global_counter_rst <= counter_rst_buf;

    vata_hit00 <= vata_hit_busy00(1) and (not disable_hits(0)) and global_hit_ena;
    vata_hit01 <= vata_hit_busy01(1) and (not disable_hits(1)) and global_hit_ena;
    vata_hit02 <= vata_hit_busy02(1) and (not disable_hits(2)) and global_hit_ena;
    vata_hit03 <= vata_hit_busy03(1) and (not disable_hits(3)) and global_hit_ena;
    vata_hit04 <= vata_hit_busy04(1) and (not disable_hits(4)) and global_hit_ena;
    vata_hit05 <= vata_hit_busy05(1) and (not disable_hits(5)) and global_hit_ena;
    vata_hit06 <= vata_hit_busy06(1) and (not disable_hits(6)) and global_hit_ena;
    vata_hit07 <= vata_hit_busy07(1) and (not disable_hits(7)) and global_hit_ena;
    vata_hit08 <= vata_hit_busy08(1) and (not disable_hits(8)) and global_hit_ena;
    vata_hit09 <= vata_hit_busy09(1) and (not disable_hits(9)) and global_hit_ena;
    vata_hit10 <= vata_hit_busy10(1) and (not disable_hits(10)) and global_hit_ena;
    vata_hit11 <= vata_hit_busy11(1) and (not disable_hits(11)) and global_hit_ena;

    vata_busy00 <= vata_hit_busy00(0) and not disable_hits(0);
    vata_busy01 <= vata_hit_busy01(0) and not disable_hits(1);
    vata_busy02 <= vata_hit_busy02(0) and not disable_hits(2);
    vata_busy03 <= vata_hit_busy03(0) and not disable_hits(3);
    vata_busy04 <= vata_hit_busy04(0) and not disable_hits(4);
    vata_busy05 <= vata_hit_busy05(0) and not disable_hits(5);
    vata_busy06 <= vata_hit_busy06(0) and not disable_hits(6);
    vata_busy07 <= vata_hit_busy07(0) and not disable_hits(7);
    vata_busy08 <= vata_hit_busy08(0) and not disable_hits(8);
    vata_busy09 <= vata_hit_busy09(0) and not disable_hits(9);
    vata_busy10 <= vata_hit_busy10(0) and not disable_hits(10);
    vata_busy11 <= vata_hit_busy11(0) and not disable_hits(11);

    vata_hits(0)  <= vata_hit00 and not FEE_busy_buf;
    vata_hits(1)  <= vata_hit01 and not FEE_busy_buf;
    vata_hits(2)  <= vata_hit02 and not FEE_busy_buf;
    vata_hits(3)  <= vata_hit03 and not FEE_busy_buf;
    vata_hits(4)  <= vata_hit04 and not FEE_busy_buf;
    vata_hits(5)  <= vata_hit05 and not FEE_busy_buf;
    vata_hits(6)  <= vata_hit06 and not FEE_busy_buf;
    vata_hits(7)  <= vata_hit07 and not FEE_busy_buf;
    vata_hits(8)  <= vata_hit08 and not FEE_busy_buf;
    vata_hits(9)  <= vata_hit09 and not FEE_busy_buf;
    vata_hits(10) <= vata_hit10 and not FEE_busy_buf;
    vata_hits(11) <= vata_hit11 and not FEE_busy_buf;

    -- Debugging --
    vata_hits_noblock(0)  <= vata_hit_busy00(1);
    vata_hits_noblock(1)  <= vata_hit_busy01(1);
    vata_hits_noblock(2)  <= vata_hit_busy02(1);
    vata_hits_noblock(3)  <= vata_hit_busy03(1);
    vata_hits_noblock(4)  <= vata_hit_busy04(1);
    vata_hits_noblock(5)  <= vata_hit_busy05(1);
    vata_hits_noblock(6)  <= vata_hit_busy06(1);
    vata_hits_noblock(7)  <= vata_hit_busy07(1);
    vata_hits_noblock(8)  <= vata_hit_busy08(1);
    vata_hits_noblock(9)  <= vata_hit_busy09(1);
    vata_hits_noblock(10) <= vata_hit_busy10(1);
    vata_hits_noblock(11) <= vata_hit_busy11(1);
    -- User logic ends

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
