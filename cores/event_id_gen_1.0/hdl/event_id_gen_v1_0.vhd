library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity event_id_gen_v1_0 is
    generic (
        -- Users to add parameters here
        EVENT_ID_CLK_RATIO : integer := 10; -- Ratio between clk and event_id_latch
        -- User parameters ends

        -- Do not modify the parameters beyond this line

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 4
    );
    port (
        -- Users to add ports here
        FEE_busy       : in std_logic;
        FEE_ready      : in std_logic;
        event_id_data  : out std_logic;
        event_id_latch : out std_logic;

        -- Debug ports --
        event_id_go_out   : out std_logic;
        inc_event_id_out  : out std_logic;
        event_id_full_out : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        clk_count_out     : out std_logic_vector(3 downto 0);
        id_bit_count_out  : out std_logic_vector(5 downto 0);

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
end event_id_gen_v1_0;

architecture arch_imp of event_id_gen_v1_0 is

    -- component declaration
    component event_id_gen_v1_0_S00_AXI is
        generic (
        C_S_AXI_DATA_WIDTH  : integer   := 32;
        C_S_AXI_ADDR_WIDTH  : integer   := 4
        );
        port (
        NEW_EVENT_ID     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CURRENT_EVENT_ID : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        UPDATE_EVENT_ID  : out std_logic;
        S_AXI_ACLK      : in std_logic;
        S_AXI_ARESETN   : in std_logic;
        S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
        S_AXI_AWVALID   : in std_logic;
        S_AXI_AWREADY   : out std_logic;
        S_AXI_WDATA     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB     : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID    : in std_logic;
        S_AXI_WREADY    : out std_logic;
        S_AXI_BRESP     : out std_logic_vector(1 downto 0);
        S_AXI_BVALID    : out std_logic;
        S_AXI_BREADY    : in std_logic;
        S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
        S_AXI_ARVALID   : in std_logic;
        S_AXI_ARREADY   : out std_logic;
        S_AXI_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP     : out std_logic_vector(1 downto 0);
        S_AXI_RVALID    : out std_logic;
        S_AXI_RREADY    : in std_logic
        );
    end component event_id_gen_v1_0_S00_AXI;

    component event_id_p2s is
        generic ( EVENT_ID_WIDTH     : integer := 32
                ; EVENT_ID_CLK_RATIO : integer := 10 -- Ratio between clk and event_id_latch
                );
        port ( clk            : in std_logic
             ; rst_n          : in std_logic
             ; event_id_in    : in std_logic_vector(EVENT_ID_WIDTH-1 downto 0)
             ; event_id_go    : in std_logic
             ; event_id_out   : out std_logic
             ; event_id_latch : out std_logic
             ; inc_event_id   : out std_logic
             -- Debug --
             ; clk_count_out  : out std_logic_vector(3 downto 0)
             ; id_bit_count_out : out std_logic_vector(5 downto 0)
             );
    end component event_id_p2s;

    component gen_event_id_go is
        port ( clk         : in std_logic
             ; rst_n       : in std_logic
             ; FEE_busy    : in std_logic
             ; FEE_ready   : in std_logic
             ; event_id_go : out std_logic
             );
    end component gen_event_id_go;

    signal event_id        : unsigned (C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal new_event_id    : std_logic_vector (C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal inc_event_id    : std_logic := '0';
    signal update_event_id : std_logic := '0';
    signal event_id_go     : std_logic := '0';


begin

    -- Instantiation of Axi Bus Interface S00_AXI
    event_id_gen_v1_0_S00_AXI_inst : event_id_gen_v1_0_S00_AXI
    generic map (
        C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
    )
    port map (
        NEW_EVENT_ID     => new_event_id,
        CURRENT_EVENT_ID => std_logic_vector(event_id),
        UPDATE_EVENT_ID  => update_event_id,
        S_AXI_ACLK      => s00_axi_aclk,
        S_AXI_ARESETN   => s00_axi_aresetn,
        S_AXI_AWADDR    => s00_axi_awaddr,
        S_AXI_AWPROT    => s00_axi_awprot,
        S_AXI_AWVALID   => s00_axi_awvalid,
        S_AXI_AWREADY   => s00_axi_awready,
        S_AXI_WDATA     => s00_axi_wdata,
        S_AXI_WSTRB     => s00_axi_wstrb,
        S_AXI_WVALID    => s00_axi_wvalid,
        S_AXI_WREADY    => s00_axi_wready,
        S_AXI_BRESP     => s00_axi_bresp,
        S_AXI_BVALID    => s00_axi_bvalid,
        S_AXI_BREADY    => s00_axi_bready,
        S_AXI_ARADDR    => s00_axi_araddr,
        S_AXI_ARPROT    => s00_axi_arprot,
        S_AXI_ARVALID   => s00_axi_arvalid,
        S_AXI_ARREADY   => s00_axi_arready,
        S_AXI_RDATA     => s00_axi_rdata,
        S_AXI_RRESP     => s00_axi_rresp,
        S_AXI_RVALID    => s00_axi_rvalid,
        S_AXI_RREADY    => s00_axi_rready
    );

    -- Add user logic here

    event_id_p2s_inst : event_id_p2s
    generic map ( EVENT_ID_WIDTH     => C_S00_AXI_DATA_WIDTH
                , EVENT_ID_CLK_RATIO => EVENT_ID_CLK_RATIO
                )
    port map ( clk            => s00_axi_aclk
             , rst_n          => s00_axi_aresetn
             , event_id_in    => std_logic_vector(event_id)
             , event_id_go    => event_id_go
             , event_id_out   => event_id_data
             , event_id_latch => event_id_latch
             , inc_event_id   => inc_event_id
             -- Debug --
             , clk_count_out    => clk_count_out
             , id_bit_count_out => id_bit_count_out
             );

    gen_event_id_go_inst : gen_event_id_go
    port map ( clk         => s00_axi_aclk
             , rst_n       => s00_axi_aresetn
             , FEE_busy    => FEE_busy
             , FEE_ready   => FEE_ready
             , event_id_go => event_id_go
             );

    process (s00_axi_aclk, s00_axi_aresetn)
    begin
        if s00_axi_aresetn = '0' then
            event_id <= (others => '0');
        else
            if rising_edge(s00_axi_aclk) then
                if update_event_id = '1' then
                    event_id <= unsigned(new_event_id);
                elsif inc_event_id = '1' then
                    event_id <= event_id + to_unsigned(1, event_id'length);
                else
                    event_id <= event_id;
                end if;
            end if;
        end if;
    end process;
    
    -- Debug ports --
    event_id_go_out   <= event_id_go;
    inc_event_id_out  <= inc_event_id;
    event_id_full_out <= std_logic_vector(event_id);

    -- User logic ends

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
