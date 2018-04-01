----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 06/28/2017 04:40:39 PM
-- Design Name:
-- Module Name: bonfire_dcache - Behavioral
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

use work.log2;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bonfire_dcache is
generic(
  MASTER_DATA_WIDTH : natural := 128; -- 16 Bytes....
  LINE_SIZE : natural :=4; -- Line size in MASTER_DATA_WIDTH  words
  CACHE_SIZE : natural :=2048; -- Cache Size in MASTER_DATA_WIDTH Bit words
  ADDRESS_BITS : natural := 30  -- Number of bits of chacheable address range
);
Port (
   clk_i: in std_logic;
   rst_i: in std_logic;
   
   -- Slave Interface (from CPU to Cache) -- fixed 32 Bit
   
   wbs_cyc_i : in std_logic ;
   wbs_stb_i : in std_logic ;
   wbs_we_i : in std_logic ;
   wbs_sel_i : in std_logic_vector (3 downto 0);
   wbs_ack_o : out std_logic ;
   wbs_adr_i : in std_logic_vector (ADDRESS_BITS+1 downto 2);
   
   wbs_dat_o : out std_logic_vector (31 downto 0);
   wbs_dat_i : in std_logic_vector (31 downto 0);
   
   -- Master Interface (from Cache to memory)
   wbm_cyc_o: out std_logic;
   wbm_stb_o: out std_logic;
   wbm_we_o : out std_logic;
   wbm_cti_o: out std_logic_vector(2 downto 0);
   wbm_bte_o: out std_logic_vector(1 downto 0);
   wbm_sel_o : out std_logic_vector(MASTER_DATA_WIDTH/8-1 downto 0);
   wbm_ack_i: in std_logic;
   wbm_adr_o: out std_logic_vector(ADDRESS_BITS+1 downto log2.log2(MASTER_DATA_WIDTH/8));
   wbm_dat_i: in std_logic_vector(MASTER_DATA_WIDTH-1 downto 0);
   wbm_dat_o: out std_logic_vector(MASTER_DATA_WIDTH-1 downto 0)
   

 );
end bonfire_dcache;

architecture Behavioral of bonfire_dcache is

constant  WORD_SELECT_BITS : natural := log2.log2(MASTER_DATA_WIDTH/32);
constant CL_BITS : natural :=log2.log2(LINE_SIZE); -- Bits for adressing a word in a cache line
constant CACHE_ADR_BITS : natural := log2.log2(CACHE_SIZE); -- total adress bits for cache
constant LINE_SELECT_ADR_BITS : natural := CACHE_ADR_BITS-CL_BITS; -- adr bits for selecting a cache line
constant TAG_RAM_SIZE : natural := log2.power2(LINE_SELECT_ADR_BITS); -- the Tag RAM size is defined by the size of line select address
constant TAG_RAM_BITS: natural := ADDRESS_BITS-LINE_SELECT_ADR_BITS-CL_BITS-WORD_SELECT_BITS;


constant LINE_MAX : std_logic_vector(CL_BITS-1 downto 0) := (others=>'1');

constant  MASTER_WIDTH_BYTES : natural := MASTER_DATA_WIDTH / 8 ; -- Number of Bytes for a memory bus word


-- Slave interface calculations
constant MUX_SIZE : natural  :=MASTER_DATA_WIDTH / 32; -- Multiplex factor from memory bus to CPU bus
constant CL_BITS_SLAVE : natural := log2.log2(LINE_SIZE*MUX_SIZE);

-- Cache address range in master address
constant CACHEADR_LOW : natural := wbm_adr_o'low;
constant CACHEADR_HI : natural  := CACHEADR_LOW+CACHE_ADR_BITS-1;


subtype t_tag_value is unsigned(TAG_RAM_BITS-1 downto 0);
subtype t_dirty_bits is std_logic_vector(MASTER_WIDTH_BYTES-1 downto 0);

type t_tag_data is record
   valid : std_logic;
   dirty : std_logic;
   address : t_tag_value;
end record;

constant tag_rec_len:natural:= 1+t_tag_value'length+1;

subtype t_tag_bits is std_logic_vector(tag_rec_len-1 downto 0);

constant init_dirty_bits : t_dirty_bits := (others=>'0');
constant init_tag_data : t_tag_data := ('0','0',to_unsigned(0,t_tag_value'length));

type t_tag_ram is array (0 to TAG_RAM_SIZE-1) of t_tag_bits;
type t_cache_ram is array (0 to CACHE_SIZE-1) of std_logic_vector(MASTER_DATA_WIDTH-1 downto 0);

signal tag_value : t_tag_value;
signal tag_index : unsigned(LINE_SELECT_ADR_BITS-1 downto 0); -- Offset into TAG RAM

signal tag_ram : t_tag_ram := (others =>(others=> '0')) ;
attribute ram_style: string; -- for Xilinx
attribute ram_style of tag_ram: signal is "block";


shared variable cache_ram : t_cache_ram;
attribute ram_style of cache_ram: variable is "block";

signal tag_we : std_logic:='0'; -- Tag RAM Write Enable - updates Tag RAM


signal slave_adr : std_logic_vector (wbs_adr_i'range);
signal wbs_enable : std_logic;

signal tag_buffer : t_tag_data; -- last buffered tag value
signal buffer_index : unsigned(LINE_SELECT_ADR_BITS-1 downto 0); -- index of last buffered tag value

signal tag_out,tag_in : t_tag_bits; -- input and output of tag RAM


signal hit,miss : std_logic;

signal slave_rd_ack : std_logic :='0';

signal slave_write_enable : std_logic; -- combinatorial, slave write cycle enabled

signal write_back_enable : std_logic; -- combinatorial, actual tag line must be written back

-- Bus master signals

signal master_offset_counter : unsigned(CL_BITS-1 downto 0) :=to_unsigned(0,CL_BITS);
signal master_address : std_logic_vector(wbm_adr_o'range);
signal cache_offset_counter : unsigned(CL_BITS-1 downto 0);


signal wbm_enable : std_logic:='0';
signal cache_ram_out : std_logic_vector(wbm_dat_o'range);

type t_wbm_state is (wb_idle,wb_burst_read,wb_burst_write,wb_finish,wb_retire);

signal wbm_state : t_wbm_state:=wb_idle;


-- Cache RAM Interface
signal cache_AdrBus : std_logic_vector(CACHE_ADR_BITS-1 downto 0);
signal cache_DBOut,cache_DBIn : std_logic_vector (MASTER_DATA_WIDTH-1 downto 0);
signal cache_wren : std_logic_vector (MASTER_WIDTH_BYTES-1 downto 0);
signal cache_ena : std_logic;


 function is_sel(adr: std_logic_vector (slave_adr'range);mux:natural) return boolean is
   variable res: boolean;
   begin
     if MUX_SIZE=1 then
       return true;
     else
       res:= mux=unsigned(adr(log2.log2(MUX_SIZE)-1+adr'low downto adr'low));
       return res;
     end if;
   
   end function;
   
   function to_tag_bits(t:t_tag_data) return t_tag_bits is
   variable r: t_tag_bits;
   begin
     r(r'high):=t.valid;
     r(r'high-1):=t.dirty;
     r(r'high-2 downto 0):=std_logic_vector(t.address);
     return r;  
   end function;
   
   function to_tag_data(t:t_tag_bits) return t_tag_data is
   variable r:t_tag_data;
   begin
     r.valid:=t(t'high);
     r.dirty:=t(t'high-1);
     r.address:=unsigned(t(t'high-2 downto 0));
     return r;
   end function;


begin


  cache_AdrBus<= std_logic_vector(buffer_index) &
                 std_logic_vector (cache_offset_counter) when write_back_enable='1'  else
                 
                std_logic_vector(tag_index) & std_logic_vector(master_offset_counter); 
              --   else slave_adr(CACHEADR_HI  downto CACHEADR_LOW);




  slave_adr <= wbs_adr_i; -- currently only an alias...
  
  tag_value <= unsigned(slave_adr(slave_adr'high downto slave_adr'high-TAG_RAM_BITS+1));

  tag_index <= unsigned (slave_adr(tag_index'length+CL_BITS_SLAVE+slave_adr'low-1 downto CL_BITS_SLAVE+slave_adr'low));
  
  wbs_enable <= wbs_cyc_i and wbs_stb_i;
  
  slave_write_enable <= wbs_enable and wbs_we_i and hit;
  
  write_back_enable <= '1' when miss='1' and tag_buffer.valid='1' and tag_buffer.dirty='1'
                       else '0';
  
  
  wbs_ack_o <= slave_rd_ack or slave_write_enable;
  
 
          
  
  
  check_hitmiss : process(tag_value,tag_buffer,buffer_index,tag_index,wbs_enable)
    variable index_match,tag_match : boolean;
   
    begin
      index_match:= buffer_index = tag_index;
      tag_match:=tag_buffer.valid='1' and tag_buffer.address=tag_value;
      
  
      if  index_match and tag_match and wbs_enable='1' then
        hit<='1';
      else
        hit<='0';
      end if;
  
      -- A miss only occurs when the tag buffer contains data for the right index but
      -- the tag itself does not match
      if wbs_enable='1' and index_match and not tag_match then
        miss<='1';
      else
        miss<='0';
      end if;
    end process;
    
    
    
  -- mapping between tag bitstring and record, needed because of synthesis limiations
  tag_buffer <= to_tag_data(tag_out);
  tag_in <= to_tag_bits( (not write_back_enable,slave_write_enable,tag_value));   
    
  proc_tag_ram:process(clk_i)
    
      variable rd,wd : t_tag_data;
      begin
        if rising_edge(clk_i) then
          if rst_i='1' then
             tag_out<=  to_tag_bits(init_tag_data);
          else
             if tag_we='1' or slave_write_enable='1'  then
               tag_ram(to_integer(tag_index))<=tag_in;
               tag_out <= tag_in; -- write first RAM...
             else
               tag_out <=tag_ram(to_integer(tag_index));   
             end if;
          end if; 
          buffer_index<=tag_index;  
        end if;
    
      end process;
      
  
      
  cache_dbmux: for i in 0 to MUX_SIZE-1 generate
  begin
     -- For writing the Slave bus can just be demutiplexed n times
     -- Write Enable is done on byte lane level
     cache_DBIn((i+1)*32-1 downto i*32)<=wbs_dat_i;  
  end generate;
  
  
  proc_cache_wren:process(wbs_sel_i,slave_adr,wbs_we_i) begin
  
   for i in 0 to MUX_SIZE-1 loop
     if is_sel(slave_adr,i) and wbs_we_i='1' then
       cache_wren((i+1)*4-1 downto i*4) <= wbs_sel_i;
     else
       cache_wren((i+1)*4-1 downto i*4) <= "0000";
     end if;     
    end loop;
  
  end process;
  
  
  proc_cache_rdmux:process(cache_DBOut,slave_adr) begin
 -- Databus Multiplexer, select the 32 Bit word from the cache ram word.
    for i in 0 to MUX_SIZE-1 loop
      if is_sel(slave_adr,i) then
        wbs_dat_o <= cache_DBOut((i+1)*32-1 downto i*32);
      end if;
    end loop; 
  end process;
   
 
  proc_slave_rd_ack: process(clk_i) begin
  
     if rising_edge(clk_i) then  
       if slave_rd_ack='1' then
          slave_rd_ack <= '0';
       elsif hit='1' and wbs_enable='1' and wbs_we_i='0' then
         slave_rd_ack<='1';
       end if;
     end if;       
  
  end process;     
      
      
   proc_cache_ram_slave: process(clk_i)
   --variable cache_rd : std_logic_vector(MASTER_DATA_WIDTH-1 downto 0);
   variable master_cache_address : std_logic_vector(wbm_adr_o'range);
   
   begin
      
      if rising_edge(clk_i) then
      
        -- in case of hit read cache and ack slave wishbone bus
        if hit='1' and wbs_enable='1' then 
            -- -- write cycle
           for b in cache_wren'range loop -- byte selector
              if cache_wren(b)='1' then
                cache_ram(to_integer(unsigned(slave_adr(CACHEADR_HI  downto CACHEADR_LOW))))((b+1)*8-1 downto b*8):=cache_DBIn((b+1)*8-1 downto b*8);
              end if;
           end loop;
           --  read cycle
           cache_DBOut <= cache_ram(to_integer(unsigned(slave_adr(CACHEADR_HI  downto CACHEADR_LOW))));
        end if;       
      end if;
    end process;
    
    
   cache_ram_master: process(clk_i) begin
   
     if rising_edge (clk_i) then
       
         if (wbm_ack_i='1' and wbm_enable='1') or 
            (write_back_enable='1' and wbm_state=wb_idle) then -- RAM Enable
            
            if  wbm_ack_i='1' and write_back_enable='0' then  -- RAM WE
              cache_ram(to_integer(unsigned(cache_AdrBus))):=wbm_dat_i;
            end if;
              
            cache_ram_out <= cache_ram(to_integer(unsigned(cache_AdrBus)));
         end if;
         
   
     
     end if;
   end process;
  
      
-- Master State engine
      
   wbm_cyc_o <=  wbm_enable;
   wbm_stb_o <=  wbm_enable;
   master_address <=  std_logic_vector(tag_buffer.address) &
                      std_logic_vector(buffer_index) &
                      std_logic_vector (master_offset_counter) when write_back_enable='1'
                      else slave_adr(master_address'high downto master_address'low+master_offset_counter'length) & std_logic_vector(master_offset_counter);
   wbm_adr_o <= master_address;
      
   wbm_dat_o <= cache_ram_out;    
      
   master_rw: process(clk_i) -- Master cycle state engine
   variable n : unsigned(master_offset_counter'range);
   begin
     if rising_edge(clk_i) then
       if rst_i='1' then
            wbm_enable<='0';
            wbm_state<=wb_idle;
            master_offset_counter<=to_unsigned(0,master_offset_counter'length);
            cache_offset_counter<=to_unsigned(0,cache_offset_counter'length);
            tag_we<='0';
        else
          case wbm_state is
            when wb_idle =>
              if miss='1' and hit='0' then
                wbm_enable<='1';
               
                wbm_sel_o <= (others=>'1');
               
               
                if write_back_enable='1'  then
                   cache_offset_counter<=master_offset_counter+1;
                   wbm_we_o<='1';
              --     wbm_dat_o <= cache_ram_out;
                   wbm_cti_o<="010"; -- for the moment write without burst...
                   wbm_state<=wb_burst_write;-- When some dirty bits start with a write back burst
                else
                   wbm_we_o<='0';
                   wbm_cti_o<="010";
                   wbm_state<=wb_burst_read;
                end if;
               end if;
            
             when  wb_burst_read|wb_burst_write =>
               n:=master_offset_counter+1;
               if  wbm_ack_i='1' then
              --    wbm_dat_o <= cache_ram_out;
                  if std_logic_vector(n)=LINE_MAX then
                     wbm_cti_o<="111";
                     wbm_state<=wb_finish;
                    
                   end if;
                   master_offset_counter<=n;
                   cache_offset_counter<=n+1; -- used for address look ahead in write back mode
                end if;
                 
             when wb_finish=>
               if  wbm_ack_i='1' then
                  tag_we<='1';
                  wbm_enable<='0';
                  wbm_we_o<='0';
                  master_offset_counter<=to_unsigned(0,master_offset_counter'length);
                  cache_offset_counter<=to_unsigned(0,cache_offset_counter'length);
                  --if write_back_enable='1' then
                    --wbm_state<=wb_idle;
                  --else
                    wbm_state<=wb_retire;
                  --end if;
                end if;
             when wb_retire=>
               tag_we<='0';
               wbm_state <= wb_idle;
          end case;
        
        end if;
      end if;
   
   
   
   end process;


end Behavioral;