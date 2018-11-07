----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2017 12:41:23 PM
-- Design Name: 
-- Module Name: wishbone_to_axi4 - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.log2;

entity wishbone_to_axi4 is
generic(
   
    data_length : natural :=32;
    id_length : natural := 4;
    burst_length : natural :=8;
    wb_adr_high : natural := 31
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
        wbs_adr_i: in std_logic_vector(wb_adr_high downto log2.log2(data_length/8));
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
         M_AXI_RREADY : OUT STD_LOGIC;
         
         -- Extended AXI Master Signals
          M_AXI_ARID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
          M_AXI_ARLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
          M_AXI_ARSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
          M_AXI_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
          M_AXI_ARLOCK : out STD_LOGIC;
          M_AXI_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
          M_AXI_RID : in STD_LOGIC_VECTOR ( id_length-1 downto 0 );
          M_AXI_RLAST : in STD_LOGIC;
          
          M_AXI_AWID : out STD_LOGIC_VECTOR ( id_length-1 downto 0 );
          M_AXI_AWLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
          M_AXI_AWSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
          M_AXI_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
          M_AXI_AWLOCK : out STD_LOGIC;
          M_AXI_WLAST : out STD_LOGIC;
          M_AXI_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 )
          
        
        
);
end wishbone_to_axi4;

architecture Behavioral of wishbone_to_axi4 is

constant burst_size : natural := data_length / 8;

constant lower_adr_bits : std_logic_vector(log2.log2(data_length/8)-1 downto 0) := (others=>'0');

type t_axi_state is (axi_idle,axi_write,axi_read);

subtype t_axlen is std_logic_vector(2 downto 0);

--registered signals
signal axi_state : t_axi_state := axi_idle;
signal wr_taken_reg : std_logic :='0';
signal aw_taken_reg : std_logic :='0';
signal in_burst : std_logic :='0';

--combinatorial signals
signal wr_avalid : std_logic;
signal rd_avalid : std_logic;
signal wbs_ack : std_logic;

signal aw_taken,ar_taken, wr_taken : std_logic;
signal wr_valid : std_logic;
signal wr_handshake_complete : std_logic;



signal axi_adr_temp : std_logic_vector (M_AXI_AWADDR'range);

function get_AXSIZE(buswidth:natural) return t_axlen is
variable res:t_axlen;
begin
  case buswidth/8 is
    when  1 => res:="000";
    when  2 => res:="001";
    when  4 => res:="010";
    when  8 => res:="011";
    when 16 => res:="100";
    when 32 => res:="101";
    when 64 => res:="110";
    when 128 => res:="111";
    when others=>
      report "Invalid value for AXI buswidth"
      severity error;
      res:=(others=>'U');
  end case;
  return res;

end function;


begin
  M_AXI_ARID <= (others=>'0');
  M_AXI_AWID   <= (others=>'0');
  
  M_AXI_AWPROT<="000";
  M_AXI_ARPROT<="000";
  
  M_AXI_BREADY<='1';
  
  M_AXI_ARLOCK <='0';
  M_AXI_AWLOCK <='0';
  M_AXI_AWSIZE<=get_AXSIZE(data_length); 
  M_AXI_ARSIZE<=get_AXSIZE(data_length); 
   
  M_AXI_ARCACHE<="1111";
  M_AXI_AWCACHE<="1111";  
  M_AXI_AWBURST<="01";
  M_AXI_ARBURST<="01";

 
  wr_avalid <= wbs_stb_i and wbs_we_i;
  M_AXI_AWVALID <= wr_avalid when aw_taken_reg='0' else '0';
  aw_taken <=   wr_avalid and M_AXI_AWREADY; -- When both are 1 then the slave has taken the adddress
  
  wr_valid <= wr_avalid when wr_taken_reg='0'  else '0'; 
  wr_taken <= wr_valid and M_AXI_WREADY; -- When both are 1 then the slave has taken the write channel

  wr_handshake_complete <= (wr_taken or wr_taken_reg) and (aw_taken or aw_taken_reg);

  M_AXI_WVALID  <= wr_valid;
  M_AXI_WLAST <= '1' when  axi_state=axi_write and (wbs_cti_i="000" or wbs_cti_i="111") else '0'; 
  
  rd_avalid <= wbs_stb_i and not wbs_we_i;
  M_AXI_ARVALID <= rd_avalid when axi_state=axi_idle else '0';
  ar_taken <= rd_avalid and M_AXI_ARREADY; -- When both are 1 then the slave has taken the adddress
  
  M_AXI_RREADY  <= M_AXI_RVALID;
  
  M_AXI_WSTRB<=wbs_sel_i;
  M_AXI_WDATA <= wbs_dat_i;
  
  -- Address length adaption
  axi_adr_temp(wbs_adr_i'high downto 0) <=  wbs_adr_i & lower_adr_bits;
  axi_adr_temp(axi_adr_temp'high downto wbs_adr_i'high+1) <= (others=>'0');
  
  M_AXI_AWADDR <= axi_adr_temp;
  M_AXI_ARADDR <= axi_adr_temp;
  
  wbs_dat_o<=M_AXI_RDATA;
  
  
  -- Ack wisbone cycle when AXI cycle is finished
  wbs_ack <= '1' when ((axi_state=axi_write) and M_AXI_WREADY='1') or
                      ((axi_state=axi_read) and M_AXI_RVALID='1')
             else '0';
             
                      
  wbs_ack_o <= wbs_ack;
  
  process(wbs_cti_i,wbs_stb_i,wbs_we_i)
  begin
    M_AXI_AWLEN<=X"00";
    M_AXI_ARLEN<=X"00";
    
    if wbs_stb_i='1' and wbs_cti_i="010" then
      if wbs_we_i='1' then
        M_AXI_AWLEN<=std_logic_vector(to_unsigned(burst_length-1,M_AXI_AWLEN'length));
      else
        M_AXI_ARLEN<=std_logic_vector(to_unsigned(burst_length-1,M_AXI_AWLEN'length));
      end if;
    end if;
  
  
  end process;
  
  process(clk_i) 
  begin
 
  
    if rising_edge(clk_i) then
      wr_taken_reg <= '0';
      if rst_i='1' then
        axi_state<=axi_idle;
        aw_taken_reg <= '0';
        in_burst<='0';
      else
        case axi_state is
        
          when axi_idle =>
             if wr_taken='1' then
               wr_taken_reg <='1';
             end if;
             if aw_taken='1' then
               aw_taken_reg <= '1';
             end if;
 
             if ar_taken = '1' then
               axi_state<=axi_read;
             elsif wr_handshake_complete = '1' then
               axi_state<=axi_write;  
             end if;
             
             if ar_taken='1' or wr_handshake_complete='1' then
               if wbs_cti_i="010" then
                 in_burst<='1';
               else
                 in_burst<='0';
                end if;
             end if;
             
          when axi_read=>
            if wbs_ack='1' then
              if in_burst='0' or (in_burst='1' and M_AXI_RLAST='1') then
                axi_state<=axi_idle;
                wr_taken_reg <= '0';
                aw_taken_reg <= '0';
                in_burst <= '0';
              end if;
            end if;    
                    
          when axi_write =>
            if wbs_ack='1' then
              if in_burst='0' or (in_burst='1' and wbs_cti_i="111") then 
                axi_state<=axi_idle;
                wr_taken_reg <= '0';
                aw_taken_reg <= '0';
                in_burst <= '0';
              end if;
            end if;
            
        end case;
      end if;
    end if;
  end process;
  

end Behavioral;
