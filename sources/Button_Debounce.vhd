----------------------------------------------------------------------------------
-- Company: 
-- Engineers: Ahmad Frazier, Cheik Sylla
-- 
-- Create Date: 06/17/2019 04:56:43 PM
-- Design Name: 
-- Module Name: Button_Debounce - Behavioral
-- Project Name: Pulse Generator Summer 2019 Project
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: 
--  Button debounce module that samples raw button presses and filters out 
--  inactive states caused by debouncing. 
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
library work;
use work.PG_Package.all;

entity Button_Debounce is
    Port (clk_i          : in  std_logic;
          system_reset_i : in  std_logic;
          btnC_i         : in  std_logic;
          btnU_i         : in  std_logic;
          btnL_i         : in  std_logic;
          btnR_i         : in  std_logic;
          btnD_i         : in  std_logic;
          btnC_deb_o     : out std_logic;
          btnU_deb_o     : out std_logic;
          btnL_deb_o     : out std_logic;
          btnR_deb_o     : out std_logic;
          btnD_deb_o     : out std_logic);
end Button_Debounce;

architecture Behavioral of Button_Debounce is

--===================================================================================
    ---------------------------------- [CONSTANTS] ----------------------------------
    constant FULL_ACTIVE : std_logic_vector(20 downto 0) := (others => '1');
    
    ----------------------------------- [SIGNALS] -----------------------------------
    signal btnC_memory : std_logic_vector(20 downto 0) := (others => '0');     
    signal btnU_memory : std_logic_vector(20 downto 0) := (others => '0');     
    signal btnL_memory : std_logic_vector(20 downto 0) := (others => '0');     
    signal btnR_memory : std_logic_vector(20 downto 0) := (others => '0');     
    signal btnD_memory : std_logic_vector(20 downto 0) := (others => '0');                                      
--===================================================================================

begin

------ [Button State Sample] -------------------------------------------------PROCESS
-- On clock edge, each button press is sampled into a 21 bit register through
-- bit shifting.
--
-- The buttons are sampled every 500us.
--
-- The 21 bit register will cover a sampling period of 10.5ms (500us * 21 = 10.5ms) to
-- detect debouncing.
--
-- The debounce buttons are active when all 21 bits of the register are active else 
-- if there exists a single non active bit ('0'), it is not active. 
-------------------------------------------------------------------------------------
    Button_State_Sample : process(clk_i, system_reset_i)
        variable Button_Counter : int range 1 to PERIOD_COUNT_500uS := 1;
    begin
        if (system_reset_i = ACTIVE) then
            Button_Counter := 1;
            btnC_memory <= (others => '0');
            btnU_memory <= (others => '0');
            btnL_memory <= (others => '0');
            btnR_memory <= (others => '0');
            btnD_memory <= (others => '0');

        elsif (rising_edge(clk_i)) then
            if (Button_Counter = PERIOD_COUNT_500uS) then
                Button_Counter := 1;
                btnC_memory <= btnC_memory(19 downto 0) & btnC_i;
                btnU_memory <= btnU_memory(19 downto 0) & btnU_i;
                btnL_memory <= btnL_memory(19 downto 0) & btnL_i;
                btnR_memory <= btnR_memory(19 downto 0) & btnR_i;
                btnD_memory <= btnD_memory(19 downto 0) & btnD_i;
                
                case btnC_memory is
                    when FULL_ACTIVE =>
                        btnC_deb_o <= ACTIVE;
                    when others =>
                        btnC_deb_o <= not ACTIVE;
                end case;
                
                case btnU_memory is
                    when FULL_ACTIVE =>
                        btnU_deb_o <= ACTIVE;
                    when others =>
                        btnU_deb_o <= not ACTIVE;
                end case;
                
                case btnL_memory is
                    when FULL_ACTIVE =>
                        btnL_deb_o <= ACTIVE;
                    when others =>
                        btnL_deb_o <= not ACTIVE;
                end case;
                
                case btnR_memory is
                    when FULL_ACTIVE =>
                        btnR_deb_o <= ACTIVE;
                    when others =>
                        btnR_deb_o <= not ACTIVE;
                end case;
                
                case btnD_memory is
                    when FULL_ACTIVE =>
                        btnD_deb_o <= ACTIVE;
                    when others =>
                        btnD_deb_o <= not ACTIVE;
                end case;
                
            else
                Button_Counter := Button_Counter + 1;
            end if;
        end if; 
    end process;  
         
end Behavioral;
