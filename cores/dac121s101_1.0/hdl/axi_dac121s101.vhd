library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_dac121s101 is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line


    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH  : integer  := 32;
    C_S00_AXI_ADDR_WIDTH  : integer  := 4
  );
  port (
    -- Users to add ports here
      spi_sync     : out std_logic;
      spi_mosi     : out std_logic;
      spi_sclk     : out std_logic;
    -- User ports ends
    -- Do not modify the ports beyond this line


    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk  : in std_logic;
    s00_axi_aresetn  : in std_logic;
    s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot  : in std_logic_vector(2 downto 0);
    s00_axi_awvalid  : in std_logic;
    s00_axi_awready  : out std_logic;
    s00_axi_wdata  : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb  : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid  : in std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp  : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in std_logic;
    s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid  : in std_logic;
    s00_axi_arready  : out std_logic;
    s00_axi_rdata  : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp  : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in std_logic
  );
end axi_dac121s101;

architecture arch_imp of axi_dac121s101 is
 
  signal slave_reg0  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal slave_reg1  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal slave_reg2  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 
  signal slave_reg3  :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0); 

  signal fsm_done : std_logic;
  -- component declaration
  component dac121s101_fsm is
    generic (
    REGISTER_DATA_WIDTH : integer := 16);
    port(
      clk                      : in  std_logic;
      rst_n                    : in  std_logic;
      delay_register           : in std_logic_vector(REGISTER_DATA_WIDTH-1 downto 0);
      input_word               : in  std_logic_vector(15 downto 0);
      write_trig               : in  std_logic;
      fsm_done                 : out std_logic;
      out_sync                 : out std_logic;
      out_mosi                 : out std_logic;
      out_sclk                 : out std_logic);
  end component dac121s101_fsm;

  component axi_dac121s101_S00_AXI is
    generic (
    C_S_AXI_DATA_WIDTH  : integer  := 32;
    C_S_AXI_ADDR_WIDTH  : integer  := 4
    );
    port (
    slave_reg0 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    slave_reg1 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    slave_reg2 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    slave_reg3 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_ACLK  : in std_logic;
    S_AXI_ARESETN  : in std_logic;
    S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    S_AXI_AWVALID  : in std_logic;
    S_AXI_AWREADY  : out std_logic;
    S_AXI_WDATA  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB  : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP  : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in std_logic;
    S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
    S_AXI_ARVALID  : in std_logic;
    S_AXI_ARREADY  : out std_logic;
    S_AXI_RDATA  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP  : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in std_logic
    );
  end component axi_dac121s101_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
axi_dac121s101_S00_AXI_inst : axi_dac121s101_S00_AXI
  generic map (
    C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
  )
  port map (
    slave_reg0     => slave_reg0,
    slave_reg1     => slave_reg1,
    slave_reg2     => slave_reg2,
    slave_reg3     => slave_reg3,
    S_AXI_ACLK     => s00_axi_aclk,
    S_AXI_ARESETN  => s00_axi_aresetn,
    S_AXI_AWADDR   => s00_axi_awaddr,
    S_AXI_AWPROT   => s00_axi_awprot,
    S_AXI_AWVALID  => s00_axi_awvalid,
    S_AXI_AWREADY  => s00_axi_awready,
    S_AXI_WDATA    => s00_axi_wdata,
    S_AXI_WSTRB    => s00_axi_wstrb,
    S_AXI_WVALID   => s00_axi_wvalid,
    S_AXI_WREADY   => s00_axi_wready,
    S_AXI_BRESP    => s00_axi_bresp,
    S_AXI_BVALID   => s00_axi_bvalid,
    S_AXI_BREADY   => s00_axi_bready,
    S_AXI_ARADDR   => s00_axi_araddr,
    S_AXI_ARPROT   => s00_axi_arprot,
    S_AXI_ARVALID  => s00_axi_arvalid,
    S_AXI_ARREADY  => s00_axi_arready,
    S_AXI_RDATA    => s00_axi_rdata,
    S_AXI_RRESP    => s00_axi_rresp,
    S_AXI_RVALID   => s00_axi_rvalid,
    S_AXI_RREADY   => s00_axi_rready
  );

  -- Add user logic here
    comp_dac121s101_fsm : dac121s101_fsm
    port map (
      clk => s00_axi_aclk,
      rst_n => s00_axi_aresetn,
      delay_register => slave_reg1(15 downto 0),
      input_word => slave_reg0(15 downto 0),
      write_trig => slave_reg3(0),
      fsm_done => fsm_done,
      out_sync => spi_sync,
      out_mosi => spi_mosi,
      out_sclk => spi_sclk
   );
   
  -- User logic ends

end arch_imp;
