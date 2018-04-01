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
type t_axi_state is (axi_idle,axi_write,axi_read);

--registered signals
signal axi_state : t_axi_state := axi_idle;
signal wr_valid : std_logic:='0';

--combinatorial signals
signal wr_avalid : std_logic;
signal rd_avalid : std_logic;
signal wbs_ack : std_logic;

signal aw_taken,ar_taken : std_logic;

signal axi_adr_temp : std_logic_vector (31 downto 0);


begin

  
  M_AXI_AWPROT<="000";
  M_AXI_ARPROT<="000";
  
  M_AXI_BREADY<='1';


 
  wr_avalid <= wbs_stb_i and wbs_we_i;
  M_AXI_AWVALID <= wr_avalid when axi_state=axi_idle else '0';
  aw_taken <=   wr_avalid and M_AXI_AWREADY; -- When both are 1 then the slave has taken the adddress
  
  M_AXI_WVALID  <= wr_valid;
  
  rd_avalid <= wbs_stb_i and not wbs_we_i;
  M_AXI_ARVALID <= rd_avalid when axi_state=axi_idle else '0';
  ar_taken <= rd_avalid and M_AXI_ARREADY; -- When both are 1 then the slave has taken the adddress
  
  M_AXI_RREADY  <= M_AXI_RVALID;
  
  M_AXI_WSTRB<=wbs_sel_i;
  M_AXI_WDATA <= wbs_dat_i;
  
  
  -- Address length and range adaption
  
  axi_adr_temp(wb_adr_high downto 0) <=  wbs_adr_i & "00";
  -- Fill up AXI address bits wich are "above" the highest wishbone address bits
  adr_fill: if wb_adr_high<31 generate 
    axi_adr_temp(axi_adr_temp'high downto wbs_adr_i'high+1) <= axi_hi_adrs_bits(axi_adr_temp'high-wbs_adr_i'high-1 downto 0);
  end generate;  
    
  M_AXI_AWADDR <= axi_adr_temp;
  M_AXI_ARADDR <= axi_adr_temp;   
  
  wbs_dat_o<=M_AXI_RDATA;
  
  
  -- Ack wisbone cycle when AXI cycle is finished
  wbs_ack <= '1' when ((axi_state=axi_write) and M_AXI_WREADY='1') or
                      ((axi_state=axi_read) and M_AXI_RVALID='1')
             else '0';
             
                      
  wbs_ack_o <= wbs_ack;
  
  process(clk_i) begin
  
    if rising_edge(clk_i) then
      if rst_i='1' then
        axi_state<=axi_idle;
        wr_valid<='0';
      else
        case axi_state is
        
          when axi_idle =>
             if ar_taken = '1' then
               axi_state<=axi_read;
             elsif aw_taken= '1' then
               axi_state<=axi_write;
               wr_valid<='1';
             end if;
             
          when axi_read|axi_write =>
            if wbs_ack='1' then
              axi_state<=axi_idle;
              wr_valid<='0';
            end if;
            
        end case;
      end if;
    end if;
  end process;
  

end Behavioral;