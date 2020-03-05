library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vata_460p3_axi_interface_v3_0 is
    generic (
        -- Users to add parameters here

        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 8
    );
    port (
        -- Users to add ports here
        trigger_ack             : in std_logic;
        fast_or_trigger         : in std_logic;
        local_fast_or_trigger   : in std_logic;
        --force_trigger           : in std_logic;
        disable_fast_or_trigger : in std_logic;
        FEE_hit                 : out std_logic;
        FEE_ready               : out std_logic;
        FEE_busy                : out std_logic;
        FEE_spare               : out std_logic;
        event_id_latch          : in std_logic;
        event_id_data           : in std_logic;
        vata_s0                 : out std_logic;
        vata_s1                 : out std_logic;
        vata_s2                 : out std_logic;
        vata_s_latch            : out std_logic;
        vata_i1                 : out std_logic;
        vata_i3                 : out std_logic;
        vata_i4                 : out std_logic;
        vata_o5                 : in std_logic;
        vata_o6                 : in std_logic;
        -- data stream here:
        data_tvalid             : out std_logic;
        data_tlast              : out std_logic;
        data_tready             : in std_logic;
        data_tdata              : out std_logic_vector(31 downto 0);
        --
        vss_shutdown_n          : out std_logic;
 
        cald                    : out std_logic;
        caldb                   : out std_logic;
        -- Temporary debug ports
        state_out         : out std_logic_vector(7 downto 0);
        event_id_out      : out std_logic_vector(31 downto 0);
        trigger_acq_out   : out std_logic;
        abort_daq         : out std_logic;
        trigger_ack_timeout_counter : out std_logic_vector(31 downto 0);
        trigger_ack_timeout_state : out std_logic_vector(3 downto 0);
        trigger_ack_timeout_out   : out std_logic_vector(31 downto 0);
        FEE_hit0_out : out std_logic;

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
end vata_460p3_axi_interface_v3_0;

architecture arch_imp of vata_460p3_axi_interface_v3_0 is

    -- component declaration
    component vata_460p3_axi_interface_v3_0_S00_AXI is
        generic (
        C_S_AXI_DATA_WIDTH  : integer   := 32;
        C_S_AXI_ADDR_WIDTH  : integer   := 8
        );
        port (
        -- User defined ports
        CONFIG_REG_FROM_PS  : out std_logic_vector(519 downto 0);
        CONFIG_REG_FROM_PL  : in std_logic_vector(519 downto 0);
        HOLD_TIME           : out std_logic_vector(15 downto 0);
        POWER_CYCLE_TIMER   : out std_logic_vector(31 downto 0);
        TRIGGER_ACK_TIMEOUT : out std_logic_vector(31 downto 0);
        --TRIGGER_ENA_MASK    : out std_logic_vector(3 downto 0);
        FAST_OR_TRIGGER_ENA : out std_logic;
        ACK_TRIGGER_ENA     : out std_logic;
        LOCAL_FAST_OR_TRIGGER_ENA : out std_logic;
        RUNNING_COUNTER     : in std_logic_vector(63 downto 0);
        LIVE_COUNTER        : in std_logic_vector(63 downto 0);
        EVENT_COUNTER       : in std_logic_vector(31 downto 0);
        --
        S_AXI_ACLK  : in std_logic;
        S_AXI_ARESETN   : in std_logic;
        S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
        S_AXI_AWVALID   : in std_logic;
        S_AXI_AWREADY   : out std_logic;
        S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID    : in std_logic;
        S_AXI_WREADY    : out std_logic;
        S_AXI_BRESP : out std_logic_vector(1 downto 0);
        S_AXI_BVALID    : out std_logic;
        S_AXI_BREADY    : in std_logic;
        S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
        S_AXI_ARVALID   : in std_logic;
        S_AXI_ARREADY   : out std_logic;
        S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP : out std_logic_vector(1 downto 0);
        S_AXI_RVALID    : out std_logic;
        S_AXI_RREADY    : in std_logic
        );
    end component vata_460p3_axi_interface_v3_0_S00_AXI;

    component vata_460p3_iface_fsm
        port (
            clk_100MHz              : in std_logic; -- 10 ns
            rst_n                   : in std_logic;
            fast_or_trigger         : in std_logic;
            fast_or_trigger_ena     : in std_logic;
            trigger_ack             : in std_logic;
            ack_trigger_ena         : in std_logic;
            local_fast_or_trigger   : in std_logic;
            local_fast_or_trigger_ena : in std_logic;
            force_trigger           : in std_logic;
            disable_fast_or_trigger : in std_logic;
            trigger_ack_timeout     : in std_logic_vector(31 downto 0);
            FEE_hit                 : out std_logic;
            FEE_ready               : out std_logic;
            FEE_busy                : out std_logic;
            FEE_spare               : out std_logic;
            event_id_latch          : in std_logic;
            event_id_data           : in std_logic;
            get_config              : in std_logic;
            set_config              : in std_logic;
            int_cal_trigger         : in std_logic;
            hold_time               : in std_logic_vector(15 downto 0);
            vata_s0                 : out std_logic;
            vata_s1                 : out std_logic;
            vata_s2                 : out std_logic;
            vata_s_latch            : out std_logic;
            vata_i1                 : out std_logic;
            vata_i3                 : out std_logic;
            vata_i4                 : out std_logic;
            vata_o5                 : in std_logic;
            vata_o6                 : in std_logic;
            cfg_reg_from_ps         : in std_logic_vector(519 downto 0);
            cfg_reg_from_pl         : out std_logic_vector(519 downto 0);
            data_tvalid             : out std_logic;
            data_tlast              : out std_logic;
            data_tready             : in std_logic;
            data_tdata              : out std_logic_vector(31 downto 0);
            cald                    : out std_logic;
            caldb                   : out std_logic;
            counter_rst             : in std_logic;
            running_counter         : out std_logic_vector(63 downto 0);
            live_counter            : out std_logic_vector(63 downto 0);
            event_counter_rst       : in std_logic;
            event_counter           : out std_logic_vector(31 downto 0);
            -- DEBUG --
            event_id_out_debug      : out std_logic_vector(31 downto 0);
            abort_daq_debug         : out std_logic;
            trigger_acq_out         : out std_logic;
            trigger_ack_timeout_counter : out std_logic_vector(31 downto 0);
            trigger_ack_timeout_state   : out std_logic_vector(3 downto 0);
            FEE_hit0_out       : out std_logic;
            state_out          : out std_logic_vector(7 downto 0));
        end component;

    component control_register_triggers is
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
    end component;

    component power_cycler is
        port (
            clk                 : in std_logic;
            rst_n               : in std_logic;
            trigger_power_cycle : in std_logic;
            power_cycle_timer   : in std_logic_vector(31 downto 0);
            vss_shutdown_n      : out std_logic);
    end component;

    constant S00_AXI_AWADDR_0VAL : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant N_CTRL_TRIGGERS     : integer := 16;

    signal cfg_reg_from_ps       : std_logic_vector(519 downto 0);
    signal cfg_reg_from_pl       : std_logic_vector(519 downto 0);
    signal axi_wready_buf        : std_logic;
    signal ctrl_triggers         : std_logic_vector(N_CTRL_TRIGGERS-1 downto 0);
    signal set_config            : std_logic := '0';
    signal get_config            : std_logic := '0';
    signal int_cal_trigger       : std_logic := '0';
    signal hold_time             : std_logic_vector(15 downto 0);
    signal trigger_power_cycle   : std_logic := '0';
    signal power_cycle_timer     : std_logic_vector(31 downto 0);
    signal trigger_ack_timeout   : std_logic_vector(31 downto 0);
    signal trigger_ena_mask      : std_logic_vector(3 downto 0);
    signal counter_rst           : std_logic := '0';
    signal running_counter       : std_logic_vector(63 downto 0);
    signal live_counter          : std_logic_vector(63 downto 0);
    signal event_counter_rst     : std_logic := '0';
    signal event_counter         : std_logic_vector(31 downto 0);
    signal fast_or_trigger_ena   : std_logic := '0';
    signal ack_trigger_ena       : std_logic := '0';
    signal force_trigger         : std_logic := '0';
    signal local_fast_or_trigger_ena : std_logic := '0';
begin

-- Instantiation of Axi Bus Interface S00_AXI
vata_460p3_axi_interface_v3_0_S00_AXI_inst : vata_460p3_axi_interface_v3_0_S00_AXI
    generic map (
        C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
    )
    port map (
        CONFIG_REG_FROM_PS  => cfg_reg_from_ps,
        CONFIG_REG_FROM_PL  => cfg_reg_from_pl,
        HOLD_TIME           => hold_time,
        POWER_CYCLE_TIMER   => power_cycle_timer,
        TRIGGER_ACK_TIMEOUT => trigger_ack_timeout,
        --TRIGGER_ENA_MASK    => trigger_ena_mask,
        FAST_OR_TRIGGER_ENA => fast_or_trigger_ena,
        ACK_TRIGGER_ENA     => ack_trigger_ena,
        LOCAL_FAST_OR_TRIGGER_ENA => local_fast_or_trigger_ena,
        RUNNING_COUNTER     => running_counter,
        LIVE_COUNTER        => live_counter,
        EVENT_COUNTER       => event_counter,
        S_AXI_ACLK      => s00_axi_aclk,
        S_AXI_ARESETN   => s00_axi_aresetn,
        S_AXI_AWADDR    => s00_axi_awaddr,
        S_AXI_AWPROT    => s00_axi_awprot,
        S_AXI_AWVALID   => s00_axi_awvalid,
        S_AXI_AWREADY   => s00_axi_awready,
        S_AXI_WDATA     => s00_axi_wdata,
        S_AXI_WSTRB     => s00_axi_wstrb,
        S_AXI_WVALID    => s00_axi_wvalid,
        --S_AXI_WREADY    => s00_axi_wready,
        S_AXI_WREADY    => axi_wready_buf,
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


    vata_fsm : vata_460p3_iface_fsm
        port map (
            clk_100MHz          => s00_axi_aclk,
            rst_n               => s00_axi_aresetn,
            fast_or_trigger     => fast_or_trigger,
            fast_or_trigger_ena => fast_or_trigger_ena,
            trigger_ack         => trigger_ack,
            ack_trigger_ena     => ack_trigger_ena,
            local_fast_or_trigger => local_fast_or_trigger,
            local_fast_or_trigger_ena => local_fast_or_trigger_ena,
            force_trigger       => force_trigger,
            disable_fast_or_trigger => disable_fast_or_trigger,
            trigger_ack_timeout => trigger_ack_timeout,
            FEE_hit           => FEE_hit,
            FEE_ready         => FEE_ready,
            FEE_busy          => FEE_busy,
            FEE_spare         => FEE_spare,
            event_id_latch    => event_id_latch,
            event_id_data     => event_id_data,
            get_config        => get_config,
            set_config        => set_config,
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
            int_cal_trigger   => int_cal_trigger,
            cfg_reg_from_ps   => cfg_reg_from_ps,
            cfg_reg_from_pl   => cfg_reg_from_pl,
            data_tvalid       => data_tvalid,
            data_tlast        => data_tlast,
            data_tready       => data_tready,
            data_tdata        => data_tdata,
            cald              => cald,
            caldb             => caldb,
            counter_rst       => counter_rst,
            running_counter   => running_counter,
            event_counter_rst => event_counter_rst,
            event_counter     => event_counter,
            live_counter      => live_counter,
            event_id_out_debug => event_id_out,
            abort_daq_debug   => abort_daq,
            trigger_acq_out   => trigger_acq_out,
            trigger_ack_timeout_counter => trigger_ack_timeout_counter,
            trigger_ack_timeout_state => trigger_ack_timeout_state,
            FEE_hit0_out      => FEE_hit0_out,
            --FEE_ready0_out    => FEE_ready0_out,
            state_out         => state_out
        );

    control_register_triggers_inst : control_register_triggers
        generic map (
            AXI_DATA_WIDTH     => C_S00_AXI_DATA_WIDTH,
            AXI_ADDR_WIDTH     => C_S00_AXI_ADDR_WIDTH,
            N_TRIGGERS         => N_CTRL_TRIGGERS,
            AXI_AWADDR_CONTROL => 0)
        port map (
            axi_aclk => s00_axi_aclk,
            axi_aresetn => s00_axi_aresetn,
            axi_awaddr => s00_axi_awaddr,
            axi_wdata => s00_axi_wdata,
            axi_wready => axi_wready_buf,
            triggers => ctrl_triggers);

    power_cycler_inst : power_cycler
        port map (
            clk                 => s00_axi_aclk,
            rst_n               => s00_axi_aresetn,
            trigger_power_cycle => trigger_power_cycle,
            power_cycle_timer   => power_cycle_timer,
            vss_shutdown_n      => vss_shutdown_n);

    s00_axi_wready   <= axi_wready_buf;

    -- Trigger mapping:
    set_config          <= ctrl_triggers(0);
    get_config          <= ctrl_triggers(1);
    int_cal_trigger     <= ctrl_triggers(2);
    trigger_power_cycle <= ctrl_triggers(3);
    counter_rst         <= ctrl_triggers(4);
    event_counter_rst   <= ctrl_triggers(5);
    force_trigger       <= ctrl_triggers(6);

    -- Debug
    trigger_ack_timeout_out <= trigger_ack_timeout;

    -- User logic ends

end arch_imp;
-- vim: set ts=4 sw=4 sts=4 et:
