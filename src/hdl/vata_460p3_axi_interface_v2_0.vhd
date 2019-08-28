library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_axi_interface_v2_0 is
	generic (
		-- Users to add parameters here
		-- User parameters ends
		-- Do not modify the parameters beyond this line
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 7
	);
	port (
		-- Users to add ports here
        trigger_in        : in std_logic;
        vata_s0           : out std_logic;
        vata_s1           : out std_logic;
        vata_s2           : out std_logic;
        vata_s_latch      : out std_logic;
        vata_i1           : out std_logic;
        vata_i3           : out std_logic;
        vata_i4           : out std_logic;
        vata_o5           : in std_logic;
        vata_o6           : in std_logic;
        bram_dread        : in std_logic_vector(31 downto 0);
        bram_addr         : out std_logic_vector(31 downto 0);
        bram_dwrite       : out std_logic_vector(31 downto 0);
        bram_en           : out std_logic;
        bram_wea          : out std_logic_vector (3 downto 0) := (others => '0'); 
        bram_clk          : out std_logic;
        bram_rst          : out std_logic;
        vss_shutdown_n    : out std_logic;
        -- Temporary debug ports
        set_config_out    : out std_logic;
        get_config_out    : out std_logic;
        cp_data_done_out  : out std_logic;
        reg_indx_out      : out std_logic_vector(9 downto 0);
        state_counter_out : out std_logic_vector(15 downto 0);
        state_out         : out std_logic_vector(7 downto 0); 
        reg_from_vata_out : out std_logic_vector(7 downto 0);
		-- User ports ends

		-- Do not modify the ports beyond this line
		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	  : in std_logic;
		s00_axi_aresetn	  : in std_logic;
		s00_axi_awaddr	  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	  : in std_logic_vector(2 downto 0);
		s00_axi_awvalid	  : in std_logic;
		s00_axi_awready	  : out std_logic;
		s00_axi_wdata	  : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	  : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	  : in std_logic;
		s00_axi_wready	  : out std_logic;
		s00_axi_bresp	  : out std_logic_vector(1 downto 0);
		s00_axi_bvalid	  : out std_logic;
		s00_axi_bready	  : in std_logic;
		s00_axi_araddr	  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	  : in std_logic_vector(2 downto 0);
		s00_axi_arvalid	  : in std_logic;
		s00_axi_arready	  : out std_logic;
		s00_axi_rdata	  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	  : out std_logic_vector(1 downto 0);
		s00_axi_rvalid	  : out std_logic;
		s00_axi_rready	  : in std_logic
	);
end vata_460p3_axi_interface_v2_0;

architecture arch_imp of vata_460p3_axi_interface_v2_0 is

	-- component declaration
	component vata_460p3_axi_interface_v1_0_S00_AXI is
		generic (
            C_S_AXI_DATA_WIDTH	: integer	:= 32;
            C_S_AXI_ADDR_WIDTH	: integer	:= 7
		);
		port (
            CONFIG_REG_FROM_PS : out std_logic_vector(519 downto 0);
            HOLD_TIME          : out std_logic_vector(15 downto 0);
            S_AXI_ACLK	       : in std_logic;
            S_AXI_ARESETN	   : in std_logic;
            S_AXI_AWADDR	   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT	   : in std_logic_vector(2 downto 0);
            S_AXI_AWVALID	   : in std_logic;
            S_AXI_AWREADY	   : out std_logic;
            S_AXI_WDATA	       : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB	       : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID	   : in std_logic;
            S_AXI_WREADY	   : out std_logic;
            S_AXI_BRESP	       : out std_logic_vector(1 downto 0);
            S_AXI_BVALID	   : out std_logic;
            S_AXI_BREADY	   : in std_logic;
            S_AXI_ARADDR	   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT	   : in std_logic_vector(2 downto 0);
            S_AXI_ARVALID	   : in std_logic;
            S_AXI_ARREADY	   : out std_logic;
            S_AXI_RDATA	       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP	       : out std_logic_vector(1 downto 0);
            S_AXI_RVALID	   : out std_logic;
            S_AXI_RREADY	   : in std_logic
		);
	end component vata_460p3_axi_interface_v1_0_S00_AXI;

    component vata_460p3_axi_iface_fsm
        port (
            clk_100MHz         : in std_logic; -- 10 ns
            rst_n              : in std_logic;
            trigger_in         : in std_logic;
            get_config         : in std_logic;
            set_config         : in std_logic;
            cp_data_done       : in std_logic;
            hold_time          : in std_logic_vector(15 downto 0);
            vata_s0            : out std_logic;
            vata_s1            : out std_logic;
            vata_s2            : out std_logic;
            vata_s_latch       : out std_logic;
            vata_i1            : out std_logic;
            vata_i3            : out std_logic;
            vata_i4            : out std_logic;
            vata_o5            : in std_logic;
            vata_o6            : in std_logic;
            bram_addr          : out std_logic_vector(31 downto 0);
            bram_dwrite        : out std_logic_vector(31 downto 0);
            bram_wea           : out std_logic_vector (3 downto 0) := (others => '0');
            cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
            reg_indx_out       : out std_logic_vector(9 downto 0);
            state_counter_out  : out std_logic_vector(15 downto 0);
            reg_from_vata_out  : out std_logic_vector(7 downto 0);
            state_out          : out std_logic_vector(7 downto 0));
        end component;

    signal cfg_reg_from_ps : std_logic_vector(519 downto 0);

    signal axi_wready_buf  : std_logic;
    signal last_axi_wready : std_logic := '0';
    signal set_config      : std_logic := '0';
    signal get_config      : std_logic := '0';
    signal cp_data_done    : std_logic := '0';
    signal hold_time       : std_logic_vector(15 downto 0);

    constant S00_AXI_AWADDR_0VAL : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

begin
            
-- Instantiation of Axi Bus Interface S00_AXI
    vata_460p3_axi_interface_v1_0_S00_AXI_inst : vata_460p3_axi_interface_v1_0_S00_AXI
        generic map (
            C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
        )
        port map (
            CONFIG_REG_FROM_PS => cfg_reg_from_ps,
            HOLD_TIME          => hold_time,
            S_AXI_ACLK	       => s00_axi_aclk,
            S_AXI_ARESETN	   => s00_axi_aresetn,
            S_AXI_AWADDR	   => s00_axi_awaddr,
            S_AXI_AWPROT	   => s00_axi_awprot,
            S_AXI_AWVALID	   => s00_axi_awvalid,
            S_AXI_AWREADY	   => s00_axi_awready,
            S_AXI_WDATA	       => s00_axi_wdata,
            S_AXI_WSTRB	       => s00_axi_wstrb,
            S_AXI_WVALID	   => s00_axi_wvalid,
            S_AXI_WREADY	   => axi_wready_buf,
            S_AXI_BRESP	       => s00_axi_bresp,
            S_AXI_BVALID	   => s00_axi_bvalid,
            S_AXI_BREADY	   => s00_axi_bready,
            S_AXI_ARADDR	   => s00_axi_araddr,
            S_AXI_ARPROT	   => s00_axi_arprot,
            S_AXI_ARVALID	   => s00_axi_arvalid,
            S_AXI_ARREADY	   => s00_axi_arready,
            S_AXI_RDATA	       => s00_axi_rdata,
            S_AXI_RRESP	       => s00_axi_rresp,
            S_AXI_RVALID	   => s00_axi_rvalid,
            S_AXI_RREADY	   => s00_axi_rready
        );
	-- Add user logic here

    vata_fsm : vata_460p3_iface_fsm
        port map (
            clk_100MHz        => s00_axi_aclk,
            rst_n             => s00_axi_aresetn,
            trigger_in        => trigger_in,
            set_config        => set_config,
            get_config        => get_config,
            cp_data_done      => cp_data_done,
            hold_time         => hold_time,
            vata_s0           => vata_s0,
            vata_s1           => vata_s1,
            vata_s2           => vata_s2,
            vata_s_latch      => vata_s_latch,
            vata_i1_out       => vata_i1,
            vata_i3_out       => vata_i3,
            vata_i4_out       => vata_i4,
            vata_o5           => vata_o5,
            vata_o6           => vata_o6,
            bram_addr         => bram_addr,
            bram_dwrite       => bram_dwrite,
            bram_wea          => bram_wea,
            cfg_reg_from_ps   => cfg_reg_from_ps,
            reg_indx_out      => reg_indx_out,
            reg_from_vata_out => reg_from_vata_out,
            state_counter_out => state_counter_out,
            state_out         => state_out
        );

    -- Upon writing to 0th addr, trigger set or get config
    -- If writing 0, trigger set config.
    -- If writing 1, trigger get config.
    -- If writing 2, trigger cp_data_done.
    trigger_proc: process (s00_axi_aresetn, s00_axi_aclk)
    begin
        if s00_axi_aresetn = '0' then
            set_config      <= '0';
            get_config      <= '0';
            cp_data_done    <= '0';
            last_axi_wready <= '0';
        elsif rising_edge(s00_axi_aclk) then
            if axi_wready_buf = '1' and last_axi_wready = '0' and 
                    s00_axi_awaddr = S00_AXI_AWADDR_0VAL then
                -- We are writing to the 0th address! Do something!
                if s00_axi_wdata = std_logic_vector(to_unsigned(0, s00_axi_wdata'length)) then
                    set_config   <= '1';
                    get_config   <= '0';
                    cp_data_done <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(1, s00_axi_wdata'length)) then
                    set_config   <= '0';
                    get_config   <= '1';
                    cp_data_done <= '0';
                else
                    -- Just assume anything else is that we're done copying data.
                    set_config   <= '0';
                    get_config   <= '0';
                    cp_data_done <= '1';
                end if;
            else
                set_config   <= '0';
                get_config   <= '0';
                cp_data_done <= '0';
            end if;
            last_axi_wready <= axi_wready_buf;
        end if;
    end process trigger_proc;

    set_config_out   <= set_config;
    get_config_out   <= get_config;
    cp_data_done_out <= cp_data_done;

    s00_axi_wready   <= axi_wready_buf;

    bram_clk         <= s00_axi_aclk;
    bram_en          <= '1';
    bram_rst         <= not s00_axi_aresetn;

    vss_shutdown_n   <= '1';

	-- User logic ends

end arch_imp;


