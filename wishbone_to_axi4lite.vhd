----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 05/20/2017 07:01:58 PM
-- Design Name:
-- Module Name: wisbone_to_axi - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.log2;

entity wishbone_to_axi4lite is
generic(

    data_length : natural :=32;
    wb_adr_high : natural := 31;
    axi_hi_adrs_bits : std_logic_vector (7 downto 0) :=(others=>'0')
);
port(
        -- Wishbone Slave interface
        clk_i: in std_logic;
        rst_i: in std_logic;

        wbs_cyc_i: in std_logic;
        wbs_stb_i: in std_logic;
        wbs_we_i: in std_logic;
        wbs_sel_i: in std_logic_vector((data_length/8)-1 downto 0);
        wbs_ack_o: out std_logic;
        wbs_adr_i: in std_logic_vector(wb_adr_high downto 2);
        wbs_dat_i: in std_logic_vector(data_length-1 downto 0);
        wbs_dat_o: out std_logic_vector(data_length-1 downto 0);
        wbs_cti_i: in std_logic_vector(2 downto 0);

        -- AXI Master

         M_AXI_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
         M_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         M_AXI_AWVALID : OUT STD_LOGIC;
         M_AXI_AWREADY : IN STD_LOGIC;
         M_AXI_WDATA : OUT STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
         M_AXI_WSTRB : OUT STD_LOGIC_VECTOR((data_length/8)-1 DOWNTO 0);
         M_AXI_WVALID : OUT STD_LOGIC;
         M_AXI_WREADY : IN STD_LOGIC;
         M_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
         M_AXI_BVALID : IN STD_LOGIC;
         M_AXI_BREADY : OUT STD_LOGIC;
         M_AXI_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
         M_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
         M_AXI_ARVALID : OUT STD_LOGIC;
         M_AXI_ARREADY : IN STD_LOGIC;
         M_AXI_RDATA : IN STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
         M_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
         M_AXI_RVALID : IN STD_LOGIC;
         M_AXI_RREADY : OUT STD_LOGIC


);
end wishbone_to_axi4lite;


architecture Behavioral of wishbone_to_axi4lite is

  component wishbone_to_axi4
  generic (
    data_length      : natural := 32;
    id_length        : natural := 4;
    burst_length     : natural := 8;
    wb_adr_high      : natural := 31;
    axi_hi_adrs_bits : std_logic_vector;
    axi_lite_mode    : boolean := false
  );
  port (
    clk_i         : in  std_logic;
    rst_i         : in  std_logic;
    wbs_cyc_i     : in  std_logic;
    wbs_stb_i     : in  std_logic;
    wbs_we_i      : in  std_logic;
    wbs_sel_i     : in  std_logic_vector((data_length/8)-1 downto 0);
    wbs_ack_o     : out std_logic;
    wbs_adr_i     : in  std_logic_vector(wb_adr_high downto log2.log2(data_length/8));
    wbs_dat_i     : in  std_logic_vector(data_length-1 downto 0);
    wbs_dat_o     : out std_logic_vector(data_length-1 downto 0);
    wbs_cti_i     : in  std_logic_vector(2 downto 0);
    M_AXI_AWADDR  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_AWPROT  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_AWVALID : OUT STD_LOGIC;
    M_AXI_AWREADY : IN  STD_LOGIC;
    M_AXI_WDATA   : OUT STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_WSTRB   : OUT STD_LOGIC_VECTOR((data_length/8)-1 DOWNTO 0);
    M_AXI_WVALID  : OUT STD_LOGIC;
    M_AXI_WREADY  : IN  STD_LOGIC;
    M_AXI_BRESP   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_BVALID  : IN  STD_LOGIC;
    M_AXI_BREADY  : OUT STD_LOGIC;
    M_AXI_ARADDR  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_ARPROT  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARVALID : OUT STD_LOGIC;
    M_AXI_ARREADY : IN  STD_LOGIC;
    M_AXI_RDATA   : IN  STD_LOGIC_VECTOR(data_length-1 DOWNTO 0);
    M_AXI_RRESP   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_RVALID  : IN  STD_LOGIC;
    M_AXI_RREADY  : OUT STD_LOGIC;
    M_AXI_ARID    : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_ARLEN   : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_ARSIZE  : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_ARLOCK  : out STD_LOGIC;
    M_AXI_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_RID     : in  STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_RLAST   : in  STD_LOGIC;
    M_AXI_AWID    : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
    M_AXI_AWLEN   : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_AWSIZE  : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_AWLOCK  : out STD_LOGIC;
    M_AXI_WLAST   : out STD_LOGIC;
    M_AXI_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component wishbone_to_axi4;

begin

  wishbone_to_axi4_i : wishbone_to_axi4
  generic map (
    data_length      => data_length,

    burst_length     => 1,
    wb_adr_high      => wb_adr_high,
    axi_hi_adrs_bits => axi_hi_adrs_bits,
    axi_lite_mode    => true
  )
  port map (
    clk_i         => clk_i,
    rst_i         => rst_i,
    wbs_cyc_i     => wbs_cyc_i,
    wbs_stb_i     => wbs_stb_i,
    wbs_we_i      => wbs_we_i,
    wbs_sel_i     => wbs_sel_i,
    wbs_ack_o     => wbs_ack_o,
    wbs_adr_i     => wbs_adr_i,
    wbs_dat_i     => wbs_dat_i,
    wbs_dat_o     => wbs_dat_o,
    wbs_cti_i     => wbs_cti_i,
    M_AXI_AWADDR  => M_AXI_AWADDR,
    M_AXI_AWPROT  => M_AXI_AWPROT,
    M_AXI_AWVALID => M_AXI_AWVALID,
    M_AXI_AWREADY => M_AXI_AWREADY,
    M_AXI_WDATA   => M_AXI_WDATA,
    M_AXI_WSTRB   => M_AXI_WSTRB,
    M_AXI_WVALID  => M_AXI_WVALID,
    M_AXI_WREADY  => M_AXI_WREADY,
    M_AXI_BRESP   => M_AXI_BRESP,
    M_AXI_BVALID  => M_AXI_BVALID,
    M_AXI_BREADY  => M_AXI_BREADY,
    M_AXI_ARADDR  => M_AXI_ARADDR,
    M_AXI_ARPROT  => M_AXI_ARPROT,
    M_AXI_ARVALID => M_AXI_ARVALID,
    M_AXI_ARREADY => M_AXI_ARREADY,
    M_AXI_RDATA   => M_AXI_RDATA,
    M_AXI_RRESP   => M_AXI_RRESP,
    M_AXI_RVALID  => M_AXI_RVALID,
    M_AXI_RREADY  => M_AXI_RREADY,

    M_AXI_ARID    => open,
    M_AXI_ARLEN   => open,
    M_AXI_ARSIZE  => open,
    M_AXI_ARBURST => open,
    M_AXI_ARLOCK  => open,
    M_AXI_ARCACHE => open,
    M_AXI_RID     => (others=>'0'),
    M_AXI_RLAST   => '0',
    M_AXI_AWID    => open,
    M_AXI_AWLEN   => open,
    M_AXI_AWSIZE  => open,
    M_AXI_AWBURST => open,
    M_AXI_AWLOCK  => open,
    M_AXI_WLAST   => open,
    M_AXI_AWCACHE => open
  );


end Behavioral;
