library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_axi_interface_v1_0 is
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
        vata_s0      : out std_logic;
        vata_s1      : out std_logic;
        vata_s2      : out std_logic;
        vata_s_latch : out std_logic;
        vata_i1      : out std_logic;
        vata_i3      : out std_logic;
        vata_i4      : out std_logic;
        vata_o5      : in std_logic;
        rst          : in std_logic;
        bram_dread   : in std_logic_vector(31 downto 0);
        bram_addr    : out std_logic_vector(31 downto 0);
        bram_dwrite  : out std_logic_vector(31 downto 0);
        bram_en      : out std_logic;
        bram_wea     : out std_logic_vector (3 downto 0) := (others => '0'); 
        bram_clk     : out std_logic;
        bram_rst     : out std_logic;
        trigger_set_config_out : out std_logic;
        trigger_get_config_out : out std_logic;
		-- User ports ends

		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end vata_460p3_axi_interface_v1_0;

architecture arch_imp of vata_460p3_axi_interface_v1_0 is

	-- component declaration
	component vata_460p3_axi_interface_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 7
		);
		port (
        CONFIG_REG_FROM_PS : out std_logic_vector(519 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component vata_460p3_axi_interface_v1_0_S00_AXI;

    type state_type is (idle,
                        set_config_s1,
                        set_config_s2,
                        set_config_s3,
                        set_config_s4,
                        set_config_s5,
                        get_config_s1,
                        get_config_s2,
                        get_config_s3,
                        get_config_s4,
                        get_config_s5);

    signal state : state_type := idle;

    signal vata_mode : std_logic_vector(2 downto 0);

    signal bram_uaddr : unsigned(31 downto 0) := (others => '0');
    signal cfg_reg_from_ps : std_logic_vector(519 downto 0);
    signal cfg_reg_from_vata : unsigned(519 downto 0);
    signal cfg_reg_count : unsigned (9 downto 0) := (others => '0');
    signal cfg_reg_indx : integer range -1 to 519 := 0;

    signal axi_wready_buf : std_logic;
    signal last_axi_wready : std_logic := '0';
    signal trigger_set_config : std_logic := '0';
    signal trigger_get_config : std_logic := '0';


    constant CFG_BRAM_HIGH_ADDR : unsigned (31 downto 0) := to_unsigned(64, 32);
    constant CFG_REG_LEN       : unsigned(9 downto 0) := to_unsigned(520, 10);
    constant S00_AXI_AWADDR_0VAL : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant S00_AXI_AWADDR_4VAL : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0) := (2 => '1',
                                                                                         others => '0');
begin
            
-- Instantiation of Axi Bus Interface S00_AXI
vata_460p3_axi_interface_v1_0_S00_AXI_inst : vata_460p3_axi_interface_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        CONFIG_REG_FROM_PS => cfg_reg_from_ps,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		--S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_WREADY	=> axi_wready_buf, --s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

    -- Upon writing to 0th addr, trigger set or get config
    -- If writing 0, trigger get.
    -- If writing 1, trigger set.
    trigger_proc: process (s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            if axi_wready_buf = '1' and last_axi_wready = '0' and 
                    s00_axi_awaddr = S00_AXI_AWADDR_0VAL then
                if s00_axi_wdata(0) = '0' then
                    trigger_set_config <= '1';
                    trigger_get_config <= '0';
                else
                    trigger_set_config <= '0';
                    trigger_get_config <= '1';
                end if;
            else
                trigger_set_config <= '0';
                trigger_get_config <= '0';
            end if;
            last_axi_wready <= axi_wready_buf;
        end if;
    end process trigger_proc;

    -- clk : s00_axi_aclk
    main_proc: process (s00_axi_aclk)
    begin
        if rising_edge(s00_axi_aclk) then
            case state is
                when idle =>
                    -- Look for triggers to set or get ASIC configuration register
                    if trigger_set_config = '1' then
                        vata_i1 <= '0';
                        vata_i3 <= '0';
                        vata_i4 <= '0';
                        vata_mode <= "000";
                        state <= set_config_s1;
                    elsif trigger_get_config = '1' then
                        -- Start get config...
                        vata_mode <= "001";
                        state <= get_config_s1;
                    end if;
                -- Start of "set config" states
                when set_config_s1 =>
                    vata_s_latch <= '1';
                    vata_i4 <= '1';
                    cfg_reg_indx <= 519;
                    state <= set_config_s2;
                when set_config_s2 =>
                    -- Send data into ASIC shift register
                    vata_s_latch <= '0';
                    vata_i1 <= '1';
                    vata_i3 <= cfg_reg_from_ps(cfg_reg_indx);
                    cfg_reg_indx <= cfg_reg_indx - 1;
                    state <= set_config_s3;
                when set_config_s3 =>
                    vata_i1 <= '0';
                    if cfg_reg_indx = -1 then
                        -- Done sending data to ASIC
                        vata_i3 <= '0';
                        vata_i4 <= '0';
                        -- Unsure what to do here... do we change the mode to "111"???
                        -- Yes for now, as that it is a meaningless ASIC mode at this point...
                        vata_mode <= "111";
                        state <= set_config_s4;
                    else
                        -- Go send another bit.
                        state <= set_config_s2;
                    end if;
                when set_config_s4 =>
                    -- Lock in ASIC mode to "111"
                    vata_s_latch <= '1';
                    state <= set_config_s5;
                when set_config_s5 =>
                    -- End of set_config.
                    vata_s_latch <= '0';
                    state <= idle;
                when get_config_s1 =>
                    vata_s_latch <= '1';
                    cfg_reg_count <= (others => '0');
                    state <= get_config_s2;
                when get_config_s2 =>
                    if cfg_reg_count = CFG_REG_LEN then
                        -- Done reading in  Change to mode "111" then start writing to BRAM
                        vata_mode <= "111";
                        state <= get_config_s4;
                    else
                        vata_s_latch <= '0';
                        vata_i1 <= '1';
                        cfg_reg_from_vata <= shift_left(cfg_reg_from_vata, 1);
                        state <= get_config_s3;
                    end if;
                when get_config_s3 =>
                    vata_i1 <= '0';
                    cfg_reg_from_vata(0) <= vata_o5;
                    cfg_reg_count <= cfg_reg_count + to_unsigned(1, cfg_reg_count'length);
                    state <= get_config_s2;
                when get_config_s4 =>
                    -- Start sending data into BRAM
                    vata_s_latch <= '1';
                    bram_wea <= (others => '1');
                    bram_uaddr <= (others => '0');
                    bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                    cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
                    state <= get_config_s5;
                when get_config_s5 =>
                    if bram_uaddr = CFG_BRAM_HIGH_ADDR then
                        -- All done.
                        bram_wea <= (others => '0');
                        state <= idle;
                    else
                        vata_s_latch <= '0';
                        bram_uaddr <= bram_uaddr + to_unsigned(4, bram_uaddr'length);
                        bram_dwrite <= std_logic_vector(cfg_reg_from_vata(31 downto 0));
                        cfg_reg_from_vata <= shift_right(cfg_reg_from_vata, 32);
                        state <= get_config_s5;
                    end if;
                when others =>
                    -- Should not be here!
                    -- Reset driver state???
                    state <= idle;
            end case;
        end if;
  

    end process main_proc;

    bram_addr <= std_logic_vector(bram_uaddr);
    bram_clk <= s00_axi_aclk;
    bram_rst <= rst;

    vata_s0 <= vata_mode(0);
    vata_s1 <= vata_mode(1);
    vata_s2 <= vata_mode(2);

    trigger_set_config_out <= trigger_set_config;
    trigger_get_config_out <= trigger_get_config;

    s00_axi_wready <= axi_wready_buf;
	-- User logic ends

end arch_imp;


