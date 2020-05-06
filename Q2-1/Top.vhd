----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:   09:28:37 05/24/2018 
-- Design Name: 
-- Module Name:   Top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top is
	Port (
			Clk : in  STD_LOGIC;
			HSync : out  STD_LOGIC;
			VSync : out  STD_LOGIC;

			R : out  STD_LOGIC;
			G : out  STD_LOGIC;
			B : out  STD_LOGIC;
			rx : in STD_LOGIC;
			tx : out STD_LOGIC;
			DIP : in STD_LOGIC;
			PB : in STD_LOGIC;
			SRAM_WEn : out  STD_LOGIC;
			SRAM_OEn : out  STD_LOGIC;
			SRAM_CEn : out  STD_LOGIC;
			SRAM_Addr : out STD_LOGIC_VECTOR(18 downto 0);
			SRAM_Data : inout STD_LOGIC_VECTOR(7 downto 0)
	);
end Top;

Architecture Behavioral of Top is
	COMPONENT SyncGen
		PORT (  
			Clk 		: in  STD_LOGIC;
			HSync 	: out STD_LOGIC;
			Vsync 	: out STD_LOGIC;
			xCounter : out STD_LOGIC_VECTOR(9 downto 0);
			yCounter : out STD_LOGIC_VECTOR(9 downto 0);
			VideoOn 	: out STD_LOGIC
			);
		End COMPONENT;

	COMPONENT Mul
		PORT (
			clk : IN STD_LOGIC;
			a : IN STD_LOGIC_VECTOR(9 downto 0);
			b : IN STD_LOGIC_VECTOR(9 downto 0);
			p : OUT STD_LOGIC_VECTOR(19 downto 0)
			);
		END COMPONENT;
	
	COMPONENT uart_transceiver
		PORT(
			sys_rst : IN STD_LOGIC;
			sys_clk : IN STD_LOGIC;
			uart_rx : IN STD_LOGIC;
			divisor : IN STD_LOGIC_VECTOR(15 downto 0);
			tx_data : IN STD_LOGIC_VECTOR(7 downto 0);
			tx_wr	  : IN STD_LOGIC;          
			uart_tx : OUT STD_LOGIC;
			rx_data : OUT STD_LOGIC_VECTOR(7 downto 0);
			rx_done : OUT STD_LOGIC;
			tx_done : OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT FIFO256_8
		PORT (
			 clk 	 : IN STD_LOGIC;
			 rst 	 : IN STD_LOGIC;
			 din 	 : IN STD_LOGIC_VECTOR(7 downto 0);
			 wr_en : IN STD_LOGIC;
			 rd_en : IN STD_LOGIC;
			 dout	 : OUT STD_LOGIC_VECTOR(7 downto 0);
			 full  : OUT STD_LOGIC;
			 empty : OUT STD_LOGIC
		);
	END COMPONENT;
	
	signal xCounter : STD_LOGIC_VECTOR(9 downto 0) := (others=>'0');
	signal yCounter : STD_LOGIC_VECTOR(9 downto 0) := (others=>'0');
	signal VideoOn  : STD_LOGIC;
	
	signal p 		: STD_LOGIC_VECTOR(19 downto 0);
	signal mul_out : STD_LOGIC_VECTOR (19 downto 0);
	
	signal rx_data : STD_LOGIC_VECTOR(7 downto 0);
	signal rx_done : STD_LOGIC;
	signal tx_done : STD_LOGIC;
	signal dout : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
	signal sram_data_sig : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
	signal read_addr 		: STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
	signal write_addr 	: STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
	signal sram_we_sig	: STD_LOGIC;
	
	signal fifo_rst 	: STD_LOGIC;
	signal fifo_din 	: STD_LOGIC_VECTOR(7 downto 0);
	signal fifo_wr_en : STD_LOGIC;
	signal fifo_rd_en : STD_LOGIC;
	signal fifo_dout 	: STD_LOGIC_VECTOR(7 downto 0);
	signal fifo_full 	: STD_LOGIC;
	signal fifo_empty : STD_LOGIC;
	signal fifo_dout_sig : STD_LOGIC_VECTOR(7 downto 0);	
	
	type states is (idle, s0, s1, s4);
	signal state : states := idle;

begin
	
	R <= SRAM_Data(0) when (VideoOn='1') else '0';
	G <= SRAM_Data(1) when (VideoOn='1') else '0';
	B <= SRAM_Data(2) when (VideoOn='1') else '0';

	SyncGen_U0: SyncGen 
		Port Map ( 
			Clk      => Clk     ,
			HSync    => HSync   ,
			Vsync    => Vsync   ,
			xCounter => xCounter,
			yCounter => yCounter,
			VideoOn  => VideoOn 
		);
				 
	Multiplier_U0: Mul
		PORT MAP (
			clk => clk,
			a 	 => ycounter,
			b 	 => "1010000000",
			p 	 => p
		);
	
	mul_out	 <= p + xcounter;
	read_addr <= mul_out(18 downto 0);
					
	uart_transceiver_U0 :uart_transceiver
		port map (
			sys_rst => '0',
			sys_clk => clk,
			uart_rx => rx,
			uart_tx => tx,
			divisor => x"0006",
			rx_data => rx_data,
			rx_done => rx_done,
			tx_data => rx_data,
			tx_wr   => rx_done,
			tx_done => tx_done
		);
	
	FIFO256_8_U0 : FIFO256_8
		PORT MAP (
			clk 	=> clk,
			rst 	=> '0',
			din 	=> rx_data,
			wr_en => rx_done,
			rd_en => fifo_rd_en,
			dout 	=> fifo_dout,
			full 	=> fifo_full,
			empty => fifo_empty
		);
			
	SRAM_CEn	 <= '0';
	SRAM_Addr <= read_addr when (videoon = '1') else write_addr;
	SRAM_Data <= sram_data_sig when (VideoOn='0') else (others => 'Z');
	SRAM_OEn  <= not VideoOn;
	SRAM_WEn  <= sram_we_sig or VideoOn;
	
	sram_data_sig(2 downto 0) <= dout(2 downto 0) when (PB = '0')
							else dout(5 downto 3);
--	process(xcounter, ycounter)
--	begin
--		if (xcounter =0 and ycounter = 0) then
--			read_addr <= (others => '0');
--		else
--			read_addr <= read_addr + 1;
--		end if;
--	end process;
	
	process(clk)
	begin
		if(clk='1' and clk'event) then
			case state is
				when idle =>
					dout <= "00100001";
					write_addr <= (others => '0');
					state <= s0;
					
				when s0 =>
					if (videoOn = '0') then
						sram_we_sig <= '0';
						state <= s1;
					end if;

				when s1 =>
					sram_we_sig <= '1';
					write_addr <= write_addr + 1;
					if (write_addr = "1000000000000000000") then
						state <= s4;
					end if;
					state <= s0;
					
--				when s2 =>
--					fifo_dout_sig <= fifo_dout;
--					sram_we_sig <= '0';
--					sram_data_sig <= fifo_dout_sig;
--					state <= s3;
--					
--				when s3 =>
--					sram_we_sig <= '1';
--					state <= s4;
				
				when s4 => NULL;
--					write_addr <= write_addr + 1;
--					state <= idle;
			end case; 
		end if;
	end process;

end Behavioral;

