library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_axi_interface_v2_0 is
    generic (
        -- Users to add parameters here
        -- User parameters ends
        -- Do not modify the parameters beyond this line
        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 7
    );
    port (
        -- Users to add ports here
        trigger_ack           : in std_logic;
        trigger_ena           : in std_logic;
        trigger_ena_ena       : in std_logic;
        trigger_ena_force     : in std_logic;
        FEE_hit               : out std_logic;
        FEE_ready             : out std_logic;
        FEE_busy              : out std_logic;
        FEE_spare             : out std_logic;
        event_id_latch        : in std_logic;
        event_id_data         : in std_logic;
        cal_pulse_trigger_out : out std_logic;
        vata_s0               : out std_logic;
        vata_s1               : out std_logic;
        vata_s2               : out std_logic;
        vata_s_latch          : out std_logic;
        vata_i1               : out std_logic;
        vata_i3               : out std_logic;
        vata_i4               : out std_logic;
        vata_o5               : in std_logic;
        vata_o6               : in std_logic;
        bram_dread            : in std_logic_vector(31 downto 0);
        bram_addr             : out std_logic_vector(31 downto 0);
        bram_dwrite           : out std_logic_vector(31 downto 0);
        bram_en               : out std_logic;
        bram_wea              : out std_logic_vector (3 downto 0) := (others => '0'); 
        bram_clk              : out std_logic;
        bram_rst              : out std_logic;
        vss_shutdown_n        : out std_logic;
        cal_dac_spi_sclk      : out std_logic;
        cal_dac_spi_mosi      : out std_logic;
        cal_dac_spi_syncn     : out std_logic;
        data_to_fifo          : out std_logic_vector(511 downto 0);
        data_from_fifo        : in std_logic_vector(511 downto 0);
        fifo_full             : in std_logic;
        fifo_empty            : in std_logic;
        fifo_wea              : out std_logic;
        fifo_rd_en            : out std_logic;
        tvalid                : out std_logic;
        tlast                 : out std_logic;
        tready                : in std_logic;
        tdata                 : out std_logic_vector(31 downto 0);
        cald                  : out std_logic;
        caldb                 : out std_logic;
        -- Temporary debug ports
        set_config_out    : out std_logic;
        get_config_out    : out std_logic;
        set_cal_dac_out   : out std_logic;
        cal_pulse_trigger_in_out  : out std_logic;
        cp_data_done_out  : out std_logic;
        reg_indx_out      : out std_logic_vector(9 downto 0);
        state_counter_out : out std_logic_vector(15 downto 0);
        state_out         : out std_logic_vector(7 downto 0); 
        --reg_from_vata_out : out std_logic_vector(378 downto 0);
        event_id_out      : out std_logic_vector(31 downto 0);
        trigger_acq_out       : out std_logic;
        abort_daq         : out std_logic;
        -- User ports ends

        -- Do not modify the ports beyond this line
        -- Ports of Axi Slave Bus Interface S00_AXI
        s00_axi_aclk      : in std_logic;
        s00_axi_aresetn   : in std_logic;
        s00_axi_awaddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot    : in std_logic_vector(2 downto 0);
        s00_axi_awvalid   : in std_logic;
        s00_axi_awready   : out std_logic;
        s00_axi_wdata     : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb     : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid    : in std_logic;
        s00_axi_wready    : out std_logic;
        s00_axi_bresp     : out std_logic_vector(1 downto 0);
        s00_axi_bvalid    : out std_logic;
        s00_axi_bready    : in std_logic;
        s00_axi_araddr    : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot    : in std_logic_vector(2 downto 0);
        s00_axi_arvalid   : in std_logic;
        s00_axi_arready   : out std_logic;
        s00_axi_rdata     : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp     : out std_logic_vector(1 downto 0);
        s00_axi_rvalid    : out std_logic;
        s00_axi_rready    : in std_logic
    );
end vata_460p3_axi_interface_v2_0;

architecture arch_imp of vata_460p3_axi_interface_v2_0 is

    -- component declaration
    component vata_460p3_axi_interface_v1_0_S00_AXI is
        generic (
            C_S_AXI_DATA_WIDTH  : integer   := 32;
            C_S_AXI_ADDR_WIDTH  : integer   := 7
        );
        port (
            CONFIG_REG_FROM_PS : out std_logic_vector(519 downto 0);
            HOLD_TIME          : out std_logic_vector(15 downto 0);
            CAL_DAC            : out std_logic_vector(11 downto 0);
            POWER_CYCLE_TIMER  : out std_logic_vector(31 downto 0);
            S_AXI_ACLK         : in std_logic;
            S_AXI_ARESETN      : in std_logic;
            S_AXI_AWADDR       : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT       : in std_logic_vector(2 downto 0);
            S_AXI_AWVALID      : in std_logic;
            S_AXI_AWREADY      : out std_logic;
            S_AXI_WDATA        : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB        : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID       : in std_logic;
            S_AXI_WREADY       : out std_logic;
            S_AXI_BRESP        : out std_logic_vector(1 downto 0);
            S_AXI_BVALID       : out std_logic;
            S_AXI_BREADY       : in std_logic;
            S_AXI_ARADDR       : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT       : in std_logic_vector(2 downto 0);
            S_AXI_ARVALID      : in std_logic;
            S_AXI_ARREADY      : out std_logic;
            S_AXI_RDATA        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP        : out std_logic_vector(1 downto 0);
            S_AXI_RVALID       : out std_logic;
            S_AXI_RREADY       : in std_logic
        );
    end component vata_460p3_axi_interface_v1_0_S00_AXI;

    component vata_460p3_iface_fsm
        port (
            clk_100MHz         : in std_logic; -- 10 ns
            rst_n              : in std_logic;
            trigger_ack        : in std_logic;
            trigger_ena        : in std_logic;
            trigger_ena_ena    : in std_logic;
            trigger_ena_force  : in std_logic;
            FEE_hit            : out std_logic;
            FEE_ready          : out std_logic;
            FEE_busy           : out std_logic;
            FEE_spare          : out std_logic;
            event_id_latch     : in std_logic;
            event_id_data      : in std_logic;
            get_config         : in std_logic;
            set_config         : in std_logic;
            cal_pulse_trigger_in : in std_logic;
            int_cal_trigger    : in std_logic;
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
            cal_pulse_trigger_out : out std_logic;
            bram_addr          : out std_logic_vector(31 downto 0);
            bram_dwrite        : out std_logic_vector(31 downto 0);
            bram_wea           : out std_logic_vector (3 downto 0) := (others => '0');
            cfg_reg_from_ps    : in std_logic_vector(519 downto 0);
            fifo_full          : in std_logic;
            fifo_empty         : in std_logic;
            data_to_fifo       : out std_logic_vector(511 downto 0);
            data_from_fifo     : in std_logic_vector(511 downto 0);
            fifo_wea           : out std_logic;
            fifo_rd_en         : out std_logic;
            tvalid             : out std_logic;
            tlast              : out std_logic;
            tready             : in std_logic;
            tdata              : out std_logic_vector(31 downto 0);
            cald               : out std_logic;
            caldb              : out std_logic;
            -- DEBUG --
            state_counter_out  : out std_logic_vector(15 downto 0);
            reg_indx_out       : out std_logic_vector(9 downto 0);
            --reg_from_vata_out  : out std_logic_vector(378 downto 0);
            event_id_out_debug : out std_logic_vector(31 downto 0);
            abort_daq_debug    : out std_logic;
            trigger_acq_out       : out std_logic;
            state_out          : out std_logic_vector(7 downto 0));
        end component;

    component spi_cal_dac is
        generic ( 
            CLK_RATIO : integer := 2;
            COUNTER_WIDTH : integer := 2);
        port (
            clk               : in std_logic;
            rst_n             : in std_logic;
            data_in           : in std_logic_vector(11 downto 0);
            trigger_send_data : in std_logic;
            spi_sclk          : out std_logic;
            spi_mosi          : out std_logic;
            spi_syncn         : out std_logic);
    end component;

    component power_cycler is
        port (
            clk                 : in std_logic;
            rst_n               : in std_logic;
            trigger_power_cycle : in std_logic;
            power_cycle_timer   : in std_logic_vector(31 downto 0);
            vss_shutdown_n      : out std_logic);
    end component;

    signal cfg_reg_from_ps : std_logic_vector(519 downto 0);

    signal axi_wready_buf        : std_logic;
    signal last_axi_wready       : std_logic := '0';
    signal set_config            : std_logic := '0';
    signal get_config            : std_logic := '0';
    signal set_cal_dac           : std_logic := '0';
    signal int_cal_trigger       : std_logic := '0';
    signal cal_pulse_trigger     : std_logic := '0';
    signal cp_data_done          : std_logic := '0';
    signal hold_time             : std_logic_vector(15 downto 0);
    signal cal_dac               : std_logic_vector(11 downto 0);
    signal trigger_power_cycle   : std_logic := '0';
    signal power_cycle_timer     : std_logic_vector(31 downto 0);
    constant S00_AXI_AWADDR_0VAL : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

begin
            
-- Instantiation of Axi Bus Interface S00_AXI
    vata_460p3_axi_interface_v1_0_S00_AXI_inst : vata_460p3_axi_interface_v1_0_S00_AXI
        generic map (
            C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
        )
        port map (
            CONFIG_REG_FROM_PS => cfg_reg_from_ps,
            HOLD_TIME          => hold_time,
            CAL_DAC            => cal_dac,
            POWER_CYCLE_TIMER  => power_cycle_timer,
            S_AXI_ACLK         => s00_axi_aclk,
            S_AXI_ARESETN      => s00_axi_aresetn,
            S_AXI_AWADDR       => s00_axi_awaddr,
            S_AXI_AWPROT       => s00_axi_awprot,
            S_AXI_AWVALID      => s00_axi_awvalid,
            S_AXI_AWREADY      => s00_axi_awready,
            S_AXI_WDATA        => s00_axi_wdata,
            S_AXI_WSTRB        => s00_axi_wstrb,
            S_AXI_WVALID       => s00_axi_wvalid,
            S_AXI_WREADY       => axi_wready_buf,
            S_AXI_BRESP        => s00_axi_bresp,
            S_AXI_BVALID       => s00_axi_bvalid,
            S_AXI_BREADY       => s00_axi_bready,
            S_AXI_ARADDR       => s00_axi_araddr,
            S_AXI_ARPROT       => s00_axi_arprot,
            S_AXI_ARVALID      => s00_axi_arvalid,
            S_AXI_ARREADY      => s00_axi_arready,
            S_AXI_RDATA        => s00_axi_rdata,
            S_AXI_RRESP        => s00_axi_rresp,
            S_AXI_RVALID       => s00_axi_rvalid,
            S_AXI_RREADY       => s00_axi_rready
        );
    -- Add user logic here

    vata_fsm : vata_460p3_iface_fsm
        port map (
            clk_100MHz        => s00_axi_aclk,
            rst_n             => s00_axi_aresetn,
            trigger_ack       => trigger_ack,
            trigger_ena       => trigger_ena,
            trigger_ena_ena   => trigger_ena_ena,
            trigger_ena_force => trigger_ena_force,
            FEE_hit           => FEE_hit,
            FEE_ready         => FEE_ready,
            FEE_busy          => FEE_busy,
            FEE_spare         => FEE_spare,
            event_id_latch    => event_id_latch,
            event_id_data     => event_id_data,
            get_config        => get_config,
            set_config        => set_config,
            cal_pulse_trigger_in => cal_pulse_trigger,
            cp_data_done      => cp_data_done,
            hold_time         => hold_time,
            vata_s0           => vata_s0,
            vata_s1           => vata_s1,
            vata_s2           => vata_s2,
            vata_s_latch      => vata_s_latch,
            vata_i1           => vata_i1,
            vata_i3           => vata_i3,
            vata_i4           => vata_i4,
            vata_o5           => vata_o5,
            vata_o6           => vata_o6,
            cal_pulse_trigger_out => cal_pulse_trigger_out,
            int_cal_trigger   => int_cal_trigger,
            bram_addr         => bram_addr,
            bram_dwrite       => bram_dwrite,
            bram_wea          => bram_wea,
            cfg_reg_from_ps   => cfg_reg_from_ps,
            fifo_full         => fifo_full,
            fifo_empty        => fifo_empty,
            data_to_fifo      => data_to_fifo,
            data_from_fifo    => data_from_fifo,
            fifo_wea          => fifo_wea,
            fifo_rd_en        => fifo_rd_en,
            tvalid            => tvalid,
            tlast             => tlast,
            tready            => tready,
            tdata             => tdata,
            cald              => cald,
            caldb             => caldb,
            reg_indx_out      => reg_indx_out,
            --reg_from_vata_out => reg_from_vata_out,
            state_counter_out => state_counter_out,
            event_id_out_debug => event_id_out,
            abort_daq_debug   => abort_daq,
            trigger_acq_out   => trigger_acq_out,
            state_out         => state_out
        );

        spi_cal_dac_inst : spi_cal_dac 
            generic map ( 
                -- Set SPI clock to 25 MHz
                CLK_RATIO     => 2,
                COUNTER_WIDTH => 2)
            port map (
                clk               => s00_axi_aclk,
                rst_n             => s00_axi_aresetn,
                data_in           => cal_dac,
                trigger_send_data => set_cal_dac,
                spi_sclk          => cal_dac_spi_sclk,
                spi_mosi          => cal_dac_spi_mosi,
                spi_syncn         => cal_dac_spi_syncn);

        power_cycler_inst : power_cycler
            port map (
                clk                 => s00_axi_aclk,
                rst_n               => s00_axi_aresetn,
                trigger_power_cycle => trigger_power_cycle,
                power_cycle_timer   => power_cycle_timer,
                vss_shutdown_n      => vss_shutdown_n);

    -- Below is the process that interprets writes to the 0th axi register
    -- to determine whether to send some initiating signal.
    -- Upon writing to 0th addr, trigger the following actions:
    -- If writing 0, trigger set config.
    -- If writing 1, trigger get config.
    -- If writing 2, trigger external calibration pulse.
    -- If writing 3, trigger cp_data_done.
    write_reg0_proc : process (s00_axi_aresetn, s00_axi_aclk)
    begin
        if s00_axi_aresetn = '0' then
            set_config          <= '0';
            get_config          <= '0';
            set_cal_dac         <= '0';
            int_cal_trigger     <= '0';
            cal_pulse_trigger   <= '0';
            trigger_power_cycle <= '0';
            cp_data_done        <= '0';
            last_axi_wready     <= '0';
        elsif rising_edge(s00_axi_aclk) then
            if axi_wready_buf = '1' and last_axi_wready = '0' and 
                    s00_axi_awaddr = S00_AXI_AWADDR_0VAL then
                -- We are writing to the 0th address! Do something!
                if s00_axi_wdata = std_logic_vector(to_unsigned(0, s00_axi_wdata'length)) then
                    -- Trigger set config
                    set_config          <= '1';
                    get_config          <= '0';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(1, s00_axi_wdata'length)) then
                    -- Trigger get config
                    set_config          <= '0';
                    get_config          <= '1';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(2, s00_axi_wdata'length)) then
                    -- Set the calibration dac value
                    set_config          <= '0';
                    get_config          <= '0';
                    set_cal_dac         <= '1';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(3, s00_axi_wdata'length)) then
                    -- Trigger the external calibration pulse
                    set_config          <= '0';
                    get_config          <= '0';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '1';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(4, s00_axi_wdata'length)) then
                    -- Toggle internal cald lines.
                    set_config          <= '0';
                    get_config          <= '0';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '1';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '0';
                elsif s00_axi_wdata = std_logic_vector(to_unsigned(5, s00_axi_wdata'length)) then
                    -- Power cycle with vss_shutdown
                    set_config          <= '0';
                    get_config          <= '0';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '1';
                    cp_data_done        <= '0';
                else
                    -- Just assume anything else is that we're done copying data.
                    set_config          <= '0';
                    get_config          <= '0';
                    set_cal_dac         <= '0';
                    cal_pulse_trigger   <= '0';
                    int_cal_trigger     <= '0';
                    trigger_power_cycle <= '0';
                    cp_data_done        <= '1';
                end if;
            else
                set_config          <= '0';
                get_config          <= '0';
                set_cal_dac         <= '0';
                cal_pulse_trigger   <= '0';
                int_cal_trigger     <= '0';
                trigger_power_cycle <= '0';
                cp_data_done        <= '0';
            end if;
            last_axi_wready <= axi_wready_buf;
        end if;
    end process write_reg0_proc;

    
    s00_axi_wready   <= axi_wready_buf;
    bram_clk         <= s00_axi_aclk;
    bram_en          <= '1';
    bram_rst         <= not s00_axi_aresetn;

    --vss_shutdown_n   <= '1';

    -- Debugging
    cal_pulse_trigger_in_out <= cal_pulse_trigger;
    set_config_out   <= set_config;
    get_config_out   <= get_config;
    set_cal_dac_out  <= set_cal_dac;
    cp_data_done_out <= cp_data_done;

    -- User logic ends

end arch_imp;

-- vim: set ts=4 sw=4 sts=4 et:
