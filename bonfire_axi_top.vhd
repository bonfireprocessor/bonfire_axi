----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/04/2017 06:46:08 PM
-- Design Name:
-- Module Name: bonfire_axi_top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.log2;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bonfire_axi_top is
generic(
      DBUS_RMW: boolean:=false;
      DIVIDER_EN: boolean:=true;

      MUL_ARCH: string:="spartandsp";
      START_ADDR: std_logic_vector(31 downto 0):=X"C0000000";

      REG_RAM_STYLE : string := "block";
      CACHE_SIZE_WORDS : natural := 2048;
      CACHE_LINE_SIZE_WORDS : natural := 8;
      BRAM_PORT_ADR_SIZE : natural := 13; -- 8K Words= 32KByte
      BRAM_ADR_BASE : std_logic_vector(7 downto 0) := X"C0";
      ENABLE_TIMER : boolean := true;
      TIMER_XLEN : natural := 32;

      -- Data Cache

      USE_DCACHE : boolean := true;
      DCACHE_LINE_SIZE : natural :=8; -- Line size in MASTER_DATA_WIDTH  words
      DCACHE_SIZE : natural :=2048; -- Cache Size in MASTER_DATA_WIDTH Bit words
      DCACHE_MASTER_WIDTH: natural := 32;

      -- Axi parameters
      data_length : natural :=32;
      id_length : natural := 4
   );
Port (
    clk_i: in std_logic;
    rst_i: in std_logic;

    --irq_i: in std_logic_vector(7 downto 0);

    ext_irq_i  : in std_logic;
    lirq6_i : in std_logic;
    lirq5_i : in std_logic;
    lirq4_i : in std_logic;
    lirq3_i : in std_logic;
    lirq2_i : in std_logic;
    lirq1_i : in std_logic;
    lirq0_i : in std_logic;



    -- Interface to  dual port Block RAM
    -- Port A R/W, Byte Level Access, for Data

    bram_dba_i : in std_logic_vector(31 downto 0);
    bram_dba_o : out std_logic_vector(31 downto 0);
    bram_adra_o : out std_logic_vector(BRAM_PORT_ADR_SIZE-1 downto 0);
    bram_ena_o :  out  STD_LOGIC;
    bram_wrena_o :out  STD_LOGIC_VECTOR (3 downto 0);

    -- Port B Read Only, Word level access, for Code
    bram_dbb_i : in std_logic_vector(31 downto 0);
    bram_adrb_o : out std_logic_vector(BRAM_PORT_ADR_SIZE-1 downto 0);
    bram_enb_o :  out  STD_LOGIC;



    -- Wishbone data bus (only used for data access...)
    -- Adress range 0x40000000-0x7FFFFFFF
    wb_dbus_cyc_o: out std_logic;
    wb_dbus_stb_o: out std_logic;
    wb_dbus_we_o: out std_logic;
    wb_dbus_sel_o: out std_logic_vector(3 downto 0);
    wb_dbus_ack_i: in std_logic;
    wb_dbus_adr_o: out std_logic_vector(31 downto 2);
    wb_dbus_dat_o: out std_logic_vector(31 downto 0);
    wb_dbus_dat_i: in std_logic_vector(31 downto 0);

      -- AXI Instruction Cache Master

    M_AXI_IC_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_IC_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_IC_AWVALID : OUT STD_LOGIC;
    M_AXI_IC_AWREADY : IN STD_LOGIC;
    M_AXI_IC_WDATA : OUT STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_IC_WSTRB : OUT STD_LOGIC_VECTOR((data_length/8)-1 DOWNTO 0);
    M_AXI_IC_WVALID : OUT STD_LOGIC;
    M_AXI_IC_WREADY : IN STD_LOGIC;
    M_AXI_IC_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_IC_BVALID : IN STD_LOGIC;
    M_AXI_IC_BREADY : OUT STD_LOGIC;
    M_AXI_IC_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_IC_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_IC_ARVALID : OUT STD_LOGIC;
    M_AXI_IC_ARREADY : IN STD_LOGIC;
    M_AXI_IC_RDATA : IN STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_IC_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_IC_RVALID : IN STD_LOGIC;
    M_AXI_IC_RREADY : OUT STD_LOGIC;

    M_AXI_IC_ARID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_IC_ARLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_IC_ARSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_IC_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_IC_ARLOCK : out STD_LOGIC;
    M_AXI_IC_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_IC_RID : in STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_IC_RLAST : in STD_LOGIC;

    M_AXI_IC_AWID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_IC_AWLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_IC_AWSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_IC_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_IC_AWLOCK : out STD_LOGIC;
    M_AXI_IC_WLAST : out STD_LOGIC;
    M_AXI_IC_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );



    -- AXI DC Master, Address Range: 0x00000000-0x3FFFFFFF

    M_AXI_DC_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DC_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DC_AWVALID : OUT STD_LOGIC;
    M_AXI_DC_AWREADY : IN STD_LOGIC;
    M_AXI_DC_WDATA : OUT STD_LOGIC_VECTOR(DCACHE_MASTER_WIDTH-1 DOWNTO 0);
    M_AXI_DC_WSTRB : OUT STD_LOGIC_VECTOR((DCACHE_MASTER_WIDTH/8)-1 DOWNTO 0);
    M_AXI_DC_WVALID : OUT STD_LOGIC;
    M_AXI_DC_WREADY : IN STD_LOGIC;
    M_AXI_DC_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DC_BVALID : IN STD_LOGIC;
    M_AXI_DC_BREADY : OUT STD_LOGIC;
    M_AXI_DC_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DC_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DC_ARVALID : OUT STD_LOGIC;
    M_AXI_DC_ARREADY : IN STD_LOGIC;
    M_AXI_DC_RDATA : IN STD_LOGIC_VECTOR(DCACHE_MASTER_WIDTH-1 DOWNTO 0);
    M_AXI_DC_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DC_RVALID : IN STD_LOGIC;
    M_AXI_DC_RREADY : OUT STD_LOGIC;

    M_AXI_DC_ARID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_DC_ARLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_DC_ARSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_DC_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_DC_ARLOCK : out STD_LOGIC;
    M_AXI_DC_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_DC_RID : in STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_DC_RLAST : in STD_LOGIC;

    M_AXI_DC_AWID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_DC_AWLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_DC_AWSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_DC_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_DC_AWLOCK : out STD_LOGIC;
    M_AXI_DC_WLAST : out STD_LOGIC;
    M_AXI_DC_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );



    -- AXI4 Lite Data Interface
    M_AXI_DP_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DP_AWVALID : OUT STD_LOGIC;
    M_AXI_DP_AWREADY : IN STD_LOGIC;
    M_AXI_DP_WDATA : OUT STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_DP_WSTRB : OUT STD_LOGIC_VECTOR((data_length/8)-1 DOWNTO 0);
    M_AXI_DP_WVALID : OUT STD_LOGIC;
    M_AXI_DP_WREADY : IN STD_LOGIC;
    M_AXI_DP_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DP_BVALID : IN STD_LOGIC;
    M_AXI_DP_BREADY : OUT STD_LOGIC;
    M_AXI_DP_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DP_ARVALID : OUT STD_LOGIC;
    M_AXI_DP_ARREADY : IN STD_LOGIC;
    M_AXI_DP_RDATA : IN STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_DP_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DP_RVALID : IN STD_LOGIC;
    M_AXI_DP_RREADY : OUT STD_LOGIC




 );
end bonfire_axi_top;

architecture Behavioral of bonfire_axi_top is

ATTRIBUTE X_INTERFACE_INFO : STRING;
ATTRIBUTE X_INTERFACE_INFO of  clk_i : SIGNAL is "xilinx.com:signal:clock:1.0 clk_i CLK";
--ATTRIBUTE X_INTERFACE_INFO of  rst_i : SIGNAL is "xilinx.com:signal:reset:1.0 rst_i RESET";



  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_WDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_WSTRB: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_WVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC WVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_WREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_BRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_BVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_BREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARLEN: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARLEN";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARSIZE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARSIZE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARBURST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARBURST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARLOCK: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARLOCK";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_ARCACHE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC ARCACHE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_RLAST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC RLAST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWLEN: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWLEN";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWSIZE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWSIZE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWBURST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWBURST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWLOCK: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWLOCK";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_WLAST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC WLAST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_IC_AWCACHE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_IC AWCACHE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_WDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_WSTRB: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_WVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC WVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_WREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_BRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_BVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_BREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARLEN: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARLEN";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARSIZE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARSIZE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARBURST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARBURST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARLOCK: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARLOCK";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_ARCACHE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC ARCACHE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_RLAST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC RLAST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWLEN: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWLEN";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWSIZE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWSIZE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWBURST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWBURST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWLOCK: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWLOCK";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_WLAST: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC WLAST";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DC_AWCACHE: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DC AWCACHE";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_AWADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP AWADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_AWPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP AWPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_AWVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_AWREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_WDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_WSTRB: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_WVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP WVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_WREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_BRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_BVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_BREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_ARADDR: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP ARADDR";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_ARPROT: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_ARVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP ARVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_ARREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_RDATA: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_RRESP: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_RVALID: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF M_AXI_DP_RREADY: SIGNAL IS "xilinx.com:interface:aximm:1.0 M_AXI_DP RREADY";


  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER of clk_i : SIGNAL is "ASSOCIATED_BUSIF M_AXI_IC:M_AXI_DC:M_AXI_DP:WB_DB:BRAM_A:BRAM_B";
  --ATTRIBUTE X_INTERFACE_PARAMETER of rst_i : SIGNAL is "ASSOCIATED_BUSIF M_AXI_IC:M_AXI_DC:M_AXI_DP:WB_DB:BRAM_A:BRAM_B";

  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_cyc_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_cyc_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_stb_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_stb_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_we_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0  WB_DB wb_dbus_we_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_sel_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_sel_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_ack_i: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_ack_i";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_adr_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_adr_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_dat_o: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_dat_o";
  ATTRIBUTE X_INTERFACE_INFO OF wb_dbus_dat_i: SIGNAL IS "bonfire.eu:wb:Wishbone_master:1.0 WB_DB wb_dbus_dat_i";

  attribute X_INTERFACE_MODE : string;
  

  ATTRIBUTE X_INTERFACE_INFO OF bram_ena_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_A EN";
  ATTRIBUTE X_INTERFACE_INFO OF bram_dba_i: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_A DOUT";
  ATTRIBUTE X_INTERFACE_INFO OF bram_dba_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_A DIN";
  ATTRIBUTE X_INTERFACE_INFO OF bram_wrena_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_A WE";
  ATTRIBUTE X_INTERFACE_INFO OF bram_adra_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_A ADDR";
  attribute X_INTERFACE_MODE of bram_ena_o: signal is "MASTER";


  ATTRIBUTE X_INTERFACE_INFO OF bram_enb_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_B EN";
  ATTRIBUTE X_INTERFACE_INFO OF bram_dbb_i: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_B DOUT";
  ATTRIBUTE X_INTERFACE_INFO OF bram_adrb_o: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_B ADDR";
  attribute X_INTERFACE_MODE of bram_enb_o: signal is "MASTER";  



-- Instruction Bus Master
signal ibus_cyc_o:  std_logic;
signal ibus_stb_o:  std_logic;
signal ibus_cti_o:  std_logic_vector(2 downto 0);
signal ibus_bte_o:  std_logic_vector(1 downto 0);
signal ibus_ack_i:  std_logic;
signal ibus_adr_o:  std_logic_vector(29 downto 0);
signal ibus_dat_i:  std_logic_vector(31 downto 0);


attribute mark_debug : string;



-- Data Bus Master
signal  dbus_cyc_o :  std_logic; attribute mark_debug of dbus_cyc_o  : signal is "true";
signal  dbus_stb_o :  std_logic;  attribute mark_debug of dbus_stb_o  : signal is "true";
signal  dbus_we_o :  std_logic; attribute mark_debug of dbus_we_o  : signal is "true";
signal  dbus_sel_o :  std_logic_vector(3 downto 0);
signal  dbus_adr_o :  std_logic_vector(31 downto 2);
signal  dbus_dat_o :  std_logic_vector(31 downto 0);
signal  dbus_ack_i :  std_logic; attribute mark_debug of dbus_ack_i  : signal is "true";
signal  dbus_dat_i :  std_logic_vector(31 downto 0);

--Wishbone to AXI BUS, M_AXI_DC Port
signal axi_dc_cyc,axi_dc_stb,axi_dc_we,axi_dc_ack : std_logic;
signal axi_dc_sel :  std_logic_vector(DCACHE_MASTER_WIDTH/8-1 downto 0);
signal axi_dc_dat_rd,axi_dc_dat_wr : std_logic_vector(DCACHE_MASTER_WIDTH-1 downto 0);
signal axi_dc_adr : std_logic_vector(29 downto log2.log2(DCACHE_MASTER_WIDTH/8));
signal axi_dc_cti : std_logic_vector(2 downto 0);

--Wishbone to AXI BUS, M_AXI_DP Port
signal axi_dp_cyc,axi_dp_stb,axi_dp_we,axi_dp_ack : std_logic;
signal axi_dp_sel :  std_logic_vector(3 downto 0);
signal axi_dp_dat_rd,axi_dp_dat_wr : std_logic_vector(31 downto 0);
signal axi_dp_adr : std_logic_vector(29 downto 2);
signal axi_dp_cti : std_logic_vector(2 downto 0);


-- Data Cache Master - Connection between Data Bus Arbiter and Data Cache Slave
signal dcm_cyc,dcm_stb,dcm_we,dcm_ack : std_logic;
signal dcm_sel :  std_logic_vector(3 downto 0);
signal dcm_dat_rd,dcm_dat_wr : std_logic_vector(31 downto 0);
signal dcm_adr : std_logic_vector(29 downto 2);
signal dcm_cti : std_logic_vector(2 downto 0);

 attribute mark_debug of axi_dc_cyc  : signal is "true";


signal wb_dbus_adr_o_temp : std_logic_vector(29 downto 2);

signal irq : std_logic_vector(7 downto 0);


begin

wb_dbus_adr_o <= "00" & wb_dbus_adr_o_temp;


 irq(0)<=  ext_irq_i;
 irq(1) <=  lirq0_i;
 irq(2) <=  lirq1_i;
 irq(3) <=  lirq2_i;
 irq(4) <=  lirq3_i;
 irq(5) <=  lirq4_i;
 irq(6) <=  lirq5_i;
 irq(7) <=  lirq6_i;

cpu_top: entity work.bonfire_cpu_top
       generic map (
         MUL_ARCH => MUL_ARCH,
         REG_RAM_STYLE => REG_RAM_STYLE,
         START_ADDR => START_ADDR(31 downto 2),
         CACHE_LINE_SIZE_WORDS =>CACHE_LINE_SIZE_WORDS,
         CACHE_SIZE_WORDS=>CACHE_SIZE_WORDS,
         BRAM_PORT_ADR_SIZE=>BRAM_PORT_ADR_SIZE,
         BRAM_ADR_BASE=>BRAM_ADR_BASE,
         ENABLE_TIMER=>ENABLE_TIMER
       )

       PORT MAP(
        clk_i => clk_i,
        rst_i => rst_i,

        bram_dba_i => bram_dba_i,
        bram_dba_o => bram_dba_o,
        bram_adra_o => bram_adra_o,
        bram_ena_o =>  bram_ena_o,
        bram_wrena_o => bram_wrena_o,
        bram_dbb_i =>  bram_dbb_i,
        bram_adrb_o => bram_adrb_o,
        bram_enb_o =>  bram_enb_o,

        wb_ibus_cyc_o => ibus_cyc_o ,
        wb_ibus_stb_o => ibus_stb_o,
        wb_ibus_cti_o => ibus_cti_o,
        wb_ibus_bte_o => ibus_bte_o,
        wb_ibus_ack_i => ibus_ack_i,
        wb_ibus_adr_o => ibus_adr_o,
        wb_ibus_dat_i => ibus_dat_i,

        wb_dbus_cyc_o => dbus_cyc_o,
        wb_dbus_stb_o => dbus_stb_o,
        wb_dbus_we_o =>  dbus_we_o,
        wb_dbus_sel_o => dbus_sel_o,
        wb_dbus_ack_i => dbus_ack_i,
        wb_dbus_adr_o => dbus_adr_o,
        wb_dbus_dat_o => dbus_dat_o,
        wb_dbus_dat_i => dbus_dat_i,

        irq_i => irq
      );


inst_arbiter:  entity work.wb_db_connect PORT MAP(
           clk_i => clk_i,
           rst_i => rst_i,

           s0_cyc_i => dbus_cyc_o,
           s0_stb_i => dbus_stb_o,
           s0_we_i =>  dbus_we_o,
           s0_sel_i => dbus_sel_o,
           s0_cti_i => "000",
           s0_bte_i => "00",
           s0_ack_o => dbus_ack_i,
           s0_adr_i => dbus_adr_o,
           s0_dat_i => dbus_dat_o,
           s0_dat_o => dbus_dat_i,


       -- Interface to Data cache Address Range: 0x00000000-0x3FFFFFFF
           m0_cyc_o => dcm_cyc,
           m0_stb_o => dcm_stb,
           m0_we_o =>  dcm_we,
           m0_sel_o => dcm_sel,
           m0_cti_o => dcm_cti,
           m0_bte_o => open,
           m0_ack_i => dcm_ack,
           m0_adr_o => dcm_adr,
           m0_dat_o => dcm_dat_wr,
           m0_dat_i => dcm_dat_rd,

        -- Interace to external wishbone port Address range 0x40000000-0x7FFFFFFF
           m1_cyc_o => wb_dbus_cyc_o,
           m1_stb_o => wb_dbus_stb_o,
           m1_we_o =>  wb_dbus_we_o,
           m1_sel_o => wb_dbus_sel_o,
           m1_cti_o => open,
           m1_bte_o => open,
           m1_ack_i => wb_dbus_ack_i,
           m1_adr_o => wb_dbus_adr_o_temp,
           m1_dat_o => wb_dbus_dat_o,
           m1_dat_i => wb_dbus_dat_i,

        -- Interface to AXI4 Lite Data Port Address range 0x80000000-0xB0000000
           m2_cyc_o => axi_dp_cyc,
           m2_stb_o => axi_dp_stb,
           m2_we_o =>  axi_dp_we,
           m2_sel_o => axi_dp_sel,
           m2_cti_o => open,
           m2_bte_o => open,
           m2_ack_i => axi_dp_ack,
           m2_adr_o => axi_dp_adr,
           m2_dat_o => axi_dp_dat_wr,
           m2_dat_i => axi_dp_dat_rd
       );



axi_bridge_ic: entity work.wishbone_to_axi4
    generic map (
      BURST_LENGTH => CACHE_LINE_SIZE_WORDS

     )
     port map (
       clk_i => clk_i,
       rst_i => rst_i,
       wbs_cyc_i => ibus_cyc_o,
       wbs_stb_i => ibus_stb_o,
       wbs_we_i =>  '0',
       wbs_sel_i => "1111",
       wbs_ack_o => ibus_ack_i,
       wbs_adr_i => ibus_adr_o,
       wbs_dat_i => (others=>'0'),
       wbs_dat_o => ibus_dat_i,
       wbs_cti_i => ibus_cti_o,

       M_AXI_AWADDR => M_AXI_IC_AWADDR,
       M_AXI_AWPROT => M_AXI_IC_AWPROT,
       M_AXI_AWVALID => M_AXI_IC_AWVALID,
       M_AXI_AWREADY => M_AXI_IC_AWREADY,
       M_AXI_WDATA => M_AXI_IC_WDATA,
       M_AXI_WSTRB => M_AXI_IC_WSTRB,
       M_AXI_WVALID => M_AXI_IC_WVALID,
       M_AXI_WREADY => M_AXI_IC_WREADY,
       M_AXI_BRESP => M_AXI_IC_BRESP,
       M_AXI_BREADY => M_AXI_IC_BREADY,
       M_AXI_BVALID => M_AXI_IC_BVALID,
       M_AXI_ARADDR => M_AXI_IC_ARADDR,
       M_AXI_ARPROT => M_AXI_IC_ARPROT,
       M_AXI_ARVALID => M_AXI_IC_ARVALID,
       M_AXI_ARREADY => M_AXI_IC_ARREADY,
       M_AXI_RDATA => M_AXI_IC_RDATA,
       M_AXI_RRESP => M_AXI_IC_RRESP,
       M_AXI_RVALID => M_AXI_IC_RVALID,
       M_AXI_RREADY => M_AXI_IC_RREADY,

       M_AXI_ARID => M_AXI_IC_ARID,
       M_AXI_ARLEN => M_AXI_IC_ARLEN,
       M_AXI_ARSIZE => M_AXI_IC_ARSIZE,
       M_AXI_ARBURST => M_AXI_IC_ARBURST,
       M_AXI_ARLOCK => M_AXI_IC_ARLOCK,
       M_AXI_ARCACHE => M_AXI_IC_ARCACHE,
       M_AXI_RID => M_AXI_IC_RID,
       M_AXI_RLAST => M_AXI_IC_RLAST,

       M_AXI_AWID => M_AXI_IC_AWID,
       M_AXI_AWLEN => M_AXI_IC_AWLEN,
       M_AXI_AWSIZE => M_AXI_IC_AWSIZE,
       M_AXI_AWBURST => M_AXI_IC_AWBURST,
        M_AXI_AWCACHE => M_AXI_IC_AWCACHE,
       M_AXI_AWLOCK => M_AXI_IC_AWLOCK,
       M_AXI_WLAST => M_AXI_IC_WLAST

 );


 dcache: if USE_DCACHE  generate

 inst_dcache: entity work.bonfire_dcache

 generic  map (
       MASTER_DATA_WIDTH => DCACHE_MASTER_WIDTH,
       LINE_SIZE => DCACHE_LINE_SIZE,
       CACHE_SIZE => DCACHE_SIZE,
       ADDRESS_BITS => dcm_adr'length,
       DEVICE_FAMILY => "ARTIX7"
     )
     port map (clk_i     => clk_i,
               rst_i     => rst_i,
               wbs_cyc_i => dcm_cyc,
               wbs_stb_i => dcm_stb,
               wbs_we_i  => dcm_we,
               wbs_sel_i => dcm_sel,
               wbs_ack_o => dcm_ack,
               wbs_adr_i => dcm_adr,
               wbs_dat_o => dcm_dat_rd,
               wbs_dat_i => dcm_dat_wr,

               wbm_cyc_o => axi_dc_cyc,
               wbm_stb_o => axi_dc_stb,
               wbm_we_o  => axi_dc_we,
               wbm_cti_o => axi_dc_cti,
               wbm_bte_o => open,
               wbm_sel_o => axi_dc_sel,
               wbm_ack_i => axi_dc_ack,
               wbm_adr_o => axi_dc_adr,
               wbm_dat_i => axi_dc_dat_rd,
               wbm_dat_o => axi_dc_dat_wr);

 end generate;


 axi_bridge_dc: entity work.wishbone_to_axi4
     generic map (
       wb_adr_high => 29,
       burst_length=>DCACHE_LINE_SIZE,
       data_length=>DCACHE_MASTER_WIDTH
     )
     port map (

       clk_i => clk_i,
       rst_i => rst_i,
       wbs_cyc_i => axi_dc_cyc,
       wbs_stb_i => axi_dc_stb ,
       wbs_we_i =>  axi_dc_we,
       wbs_sel_i => axi_dc_sel,
       wbs_ack_o => axi_dc_ack,
       wbs_adr_i => axi_dc_adr,
       wbs_dat_i => axi_dc_dat_wr,
       wbs_dat_o => axi_dc_dat_rd,
       wbs_cti_i => axi_dc_cti,

       M_AXI_AWADDR => M_AXI_DC_AWADDR,
       M_AXI_AWPROT => M_AXI_DC_AWPROT,
       M_AXI_AWVALID => M_AXI_DC_AWVALID,
       M_AXI_AWREADY => M_AXI_DC_AWREADY,
       M_AXI_WDATA => M_AXI_DC_WDATA,
       M_AXI_WSTRB => M_AXI_DC_WSTRB,
       M_AXI_WVALID => M_AXI_DC_WVALID,
       M_AXI_WREADY => M_AXI_DC_WREADY,
       M_AXI_BRESP => M_AXI_DC_BRESP,
       M_AXI_BREADY => M_AXI_DC_BREADY,
       M_AXI_BVALID => M_AXI_DC_BVALID,
       M_AXI_ARADDR => M_AXI_DC_ARADDR,
       M_AXI_ARPROT => M_AXI_DC_ARPROT,
       M_AXI_ARVALID => M_AXI_DC_ARVALID,
       M_AXI_ARREADY => M_AXI_DC_ARREADY,
       M_AXI_RDATA => M_AXI_DC_RDATA,
       M_AXI_RRESP => M_AXI_DC_RRESP,
       M_AXI_RVALID => M_AXI_DC_RVALID,
       M_AXI_RREADY => M_AXI_DC_RREADY,

       M_AXI_ARID => M_AXI_DC_ARID,
       M_AXI_ARLEN => M_AXI_DC_ARLEN,
       M_AXI_ARSIZE => M_AXI_DC_ARSIZE,
       M_AXI_ARBURST => M_AXI_DC_ARBURST,
       M_AXI_ARLOCK => M_AXI_DC_ARLOCK,
       M_AXI_ARCACHE => M_AXI_DC_ARCACHE,
       M_AXI_RID => M_AXI_DC_RID,
       M_AXI_RLAST => M_AXI_DC_RLAST,

       M_AXI_AWID => M_AXI_DC_AWID,
       M_AXI_AWLEN => M_AXI_DC_AWLEN,
       M_AXI_AWSIZE => M_AXI_DC_AWSIZE,
       M_AXI_AWBURST => M_AXI_DC_AWBURST,
       M_AXI_AWLOCK => M_AXI_DC_AWLOCK,
       M_AXI_AWCACHE => M_AXI_DC_AWCACHE,
       M_AXI_WLAST => M_AXI_DC_WLAST
 );


 axi_bridge_dp: entity work.wishbone_to_axi4lite
    generic map (
       wb_adr_high => 29,
       axi_hi_adrs_bits => "00000010"
     )
     port map (
       clk_i => clk_i,
       rst_i => rst_i,
       wbs_cyc_i => axi_dp_cyc,
       wbs_stb_i => axi_dp_stb ,
       wbs_we_i =>  axi_dp_we,
       wbs_sel_i => axi_dp_sel,
       wbs_ack_o => axi_dp_ack,
       wbs_adr_i => axi_dp_adr,
       wbs_dat_i => axi_dp_dat_wr,
       wbs_dat_o => axi_dp_dat_rd,
       wbs_cti_i => axi_dp_cti,

       M_AXI_AWADDR => M_AXI_DP_AWADDR,
       M_AXI_AWPROT => M_AXI_DP_AWPROT,
       M_AXI_AWVALID => M_AXI_DP_AWVALID,
       M_AXI_AWREADY => M_AXI_DP_AWREADY,
       M_AXI_WDATA => M_AXI_DP_WDATA,
       M_AXI_WSTRB => M_AXI_DP_WSTRB,
       M_AXI_WVALID => M_AXI_DP_WVALID,
       M_AXI_WREADY => M_AXI_DP_WREADY,
       M_AXI_BRESP => M_AXI_DP_BRESP,
       M_AXI_BREADY => M_AXI_DP_BREADY,
       M_AXI_BVALID => M_AXI_DP_BVALID,
       M_AXI_ARADDR => M_AXI_DP_ARADDR,
       M_AXI_ARPROT => M_AXI_DP_ARPROT,
       M_AXI_ARVALID => M_AXI_DP_ARVALID,
       M_AXI_ARREADY => M_AXI_DP_ARREADY,
       M_AXI_RDATA => M_AXI_DP_RDATA,
       M_AXI_RRESP => M_AXI_DP_RRESP,
       M_AXI_RVALID => M_AXI_DP_RVALID,
       M_AXI_RREADY => M_AXI_DP_RREADY
 );








end Behavioral;
