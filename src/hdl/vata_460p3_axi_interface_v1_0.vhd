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

    signal trigger_set_config : std_logic := '0';
    signal trigger_get_config : std_logic := '0';

    constant CFG_BRAM_HIGH_ADDR : unsigned (31 downto 0) := to_unsigned(64, 32);
    constant CFG_REG_LEN       : unsigned(9 downto 0) := to_unsigned(520, 10);
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
		S_AXI_WREADY	=> s00_axi_wready,
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


	-- User logic ends

end arch_imp;

--    signal driver_state       : std_logic_vector (7 downto 0) := x"00";
--    signal mode               : std_logic_vector (2 downto 0) := "111";
--    signal trigger_set_config : std_logic := '0';
--    signal trigger_get_config : std_logic := '0';
--    signal last_set_config    : std_logic := '1';
--    signal last_get_config    : std_logic := '1';
--    signal config_reg         : unsigned (519 downto 0) := (others => '0');
--    signal reg_count          : unsigned (9 downto 0) := (others => '0');
--    signal uaddr              : unsigned (31 downto 0) := (others => '0');
--
--    -- It takes 17 32-bit entries in ram to contain 520 bits
--    -- so final BRAM address is 4 * 16 = 64:
--    constant HIGH_ADDR : unsigned (31 downto 0) := to_unsigned(64, 32);
--    constant REG_LEN   : unsigned(9 downto 0) := to_unsigned(520, 10);
--begin
--
--    p_trigger : process (clk) is
--    begin
--        if rising_edge(clk) then
--            if set_config = '1' and last_set_config = '0' then
--                trigger_set_config <= '1';
--                trigger_get_config <= '0';
--            elsif get_config = '1' and last_get_config = '0' then
--                trigger_get_config <= '1';
--                trigger_set_config <= '0';
--            else
--                trigger_set_config <= '0';
--                trigger_get_config <= '0';
--            end if;
--            last_set_config <= set_config;
--            last_get_config <= get_config;
--        end if;
--    end process p_trigger;
--
--    p_main : process (clk) is
--    begin
--        if rising_edge(clk) then
--            case driver_state is
--                when x"00" =>
--                    -- Look for triggers to set or get ASIC configuration register
--                    if trigger_set_config = '1' then
--                        -- Setting taking precedence over getting
--                        -- Start reading in bram values to the config reg...
--                        -- Note that read latency is 1...
--                        uaddr <= (others => '0');
--                        i1 <= '0';
--                        i3 <= '0';
--                        i4 <= '0';
--                        driver_state <= x"01";
--                    elsif trigger_get_config = '1' then
--                        -- Start get config...
--                        mode <= "001";
--                        driver_state <= x"10";
--                    end if;
--                -- Start of "set config" states
--                when x"01" =>
--                    -- Delay for read.
--                    uaddr <= to_unsigned(4, uaddr'length);
--                    driver_state <= x"02";
--                when x"02" =>
--                    config_reg <= shift_right(config_reg, 32);
--                    config_reg(519 downto 488) <= unsigned(dread);
--                    if uaddr = HIGH_ADDR then
--                        -- End of successive bram addressing.
--                        -- Get current dread and next one.
--                        uaddr <= (others => '0');
--                        driver_state <= x"03";
--                    else
--                        uaddr <= uaddr + to_unsigned(4, uaddr'length);
--                        driver_state <= x"02";
--                    end if;
--                when x"03" =>
--                    -- Get final 8 bits.
--                    config_reg <= shift_right(config_reg, 8);
--                    config_reg(519 downto 512) <= unsigned(dread(7 downto 0));
--                    driver_state <= x"04";
--                when x"04" =>
--                    -- config_reg is now full.
--                    -- Set ASIC mode to set config register.
--                    mode <= "000";
--                    driver_state <= x"05";
--                when x"05" =>
--                    s_latch <= '1';
--                    i4 <= '1';
--                    reg_count <= (others => '0');
--                    driver_state <= x"06"; -- Start sending data to ASIC
--                when x"06" =>
--                    -- Send data into ASIC shift register
--                    s_latch <= '0';
--                    i1 <= '1';
--                    i3 <= config_reg(519);
--                    config_reg <= shift_left(config_reg, 1);
--                    reg_count <= reg_count + to_unsigned(1, reg_count'length);
--                    driver_state <= x"07";
--                when x"07" =>
--                    i1 <= '0';
--                    if reg_count = REG_LEN then
--                        -- Done sending data to ASIC
--                        i3 <= '0';
--                        i4 <= '0';
--                        -- Unsure what to do here... do we change the mode to "111"???
--                        -- Yes for now, as that is a meaningless ASIC mode at this point.
--                        mode <= "111";
--                        driver_state <= x"08";
--                    else
--                        -- Go send another bit.
--                        driver_state <= x"06";
--                    end if;
--                when x"08" =>
--                    -- Lock in ASIC mode to "111"
--                    s_latch <= '1';
--                    driver_state <= x"09";
--                when x"09" =>
--                    -- End of set_config.
--                    s_latch <= '0';
--                    driver_state <= x"00";
--                -- Start of "get config" states.
--                when x"10" =>
--                    s_latch <= '1';
--                    reg_count <= (others => '0');
--                    driver_state <= x"20";
--                when x"20" =>
--                    if reg_count = REG_LEN then
--                        -- Done reading in  Change to mode "111" then start writing to BRAM
--                        mode <= "111";
--                        driver_state <= x"40";
--                    else
--                        s_latch <= '0';
--                        i1 <= '1';
--                        config_reg <= shift_left(config_reg, 1);
--                        driver_state <= x"30";
--                    end if;
--                when x"30" =>
--                    i1 <= '0';
--                    config_reg(0) <= o5;
--                    reg_count <= reg_count + to_unsigned(1, reg_count'length);
--                    driver_state <= x"20";
--                when x"40" =>
--                    -- Start sending data into BRAM
--                    s_latch <= '1';
--                    bram_wea <= (others => '1');
--                    uaddr <= (others => '0');
--                    dwrite <= std_logic_vector(config_reg(31 downto 0));
--                    config_reg <= shift_right(config_reg, 32);
--                    driver_state <= x"50";
--                when x"50" =>
--                    if uaddr = HIGH_ADDR then
--                        -- All done.
--                        bram_wea <= (others => '0');
--                        driver_state <= x"00";
--                    else
--                        s_latch <= '0';
--                        uaddr <= uaddr + to_unsigned(4, uaddr'length);
--                        dwrite <= std_logic_vector(config_reg(31 downto 0));
--                        config_reg <= shift_right(config_reg, 32);
--                        driver_state <= x"50";
--                    end if;
--                when others =>
--                    -- Should not be here!
--                    -- Reset driver state???
--                    driver_state <= x"00";
--            end case;
--        end if;
--    end process p_main;
--
--    addr <= std_logic_vector(uaddr);
--    bram_en <= '1';
--
--    s0 <= mode(0);
--    s1 <= mode(1);
--    s2 <= mode(2);
--
--    driver_state_out <= driver_state;
--
--end Behavioral;
