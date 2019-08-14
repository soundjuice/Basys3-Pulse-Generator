----------------------------------------------------------------------------------
-- Company: 
-- Engineers: Ahmad Frazier, Cheik Sylla
-- 
-- Create Date: 06/17/2019 04:35:49 PM
-- Design Name: 
-- Module Name: PG_Package - Behavioral
-- Project Name: Pulse Generator Summer 2019 Project
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: 
--  Package module that provides type, component, and constant defines.
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

package PG_Package is
    --------------------------------- [COMPONENTS] ----------------------------------
    --===================================================================
    component Pulse_Generator
        Port (clk             : in  std_logic;
              config_mode_sw  : in  std_logic; 
              system_reset_sw : in  std_logic;
              btnC            : in  std_logic;
              btnU            : in  std_logic;
              btnL            : in  std_logic;
              btnR            : in  std_logic;
              btnD            : in  std_logic;
              led             : out std_logic_vector(15 downto 0);
              seg             : out std_logic_vector(6 downto 0);
              dp              : out std_logic;
              an              : out std_logic_vector(3 downto 0);
              JA1_J1          : out std_logic);
     end component;
    --===================================================================
    component Button_Debounce
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
    end component; 
    --===================================================================
  
    ---------------------------------- [SUBTYPES] -----------------------------------
    subtype int is integer range 0 to 100000000; 
  
    ---------------------------------- [CONSTANTS] ----------------------------------
    constant ACTIVE    : std_logic := '1';
    constant PROG_FREQ : std_logic := '1';
    constant PROG_DUTY : std_logic := '0';
    
    constant PERIOD_COUNT_1S    : int := 100000000;
    constant PERIOD_COUNT_500mS : int := 50000000;
    constant PERIOD_COUNT_50mS  : int := 5000000;
    constant PERIOD_COUNT_1mS   : int := 100000;
    constant PERIOD_COUNT_500uS : int := 50000;
    
    -- [segment]
    constant ZERO_7SEG  : std_logic_vector(6 downto 0) := "1000000";
    constant ONE_7SEG   : std_logic_vector(6 downto 0) := "1111001";
    constant TWO_7SEG   : std_logic_vector(6 downto 0) := "0100100";
    constant THREE_7SEG : std_logic_vector(6 downto 0) := "0110000";
    constant FOUR_7SEG  : std_logic_vector(6 downto 0) := "0011001";
    constant FIVE_7SEG  : std_logic_vector(6 downto 0) := "0010010";
    constant SIX_7SEG   : std_logic_vector(6 downto 0) := "0000010";
    constant SEVEN_7SEG : std_logic_vector(6 downto 0) := "1111000";
    constant EIGHT_7SEG : std_logic_vector(6 downto 0) := "0000000";
    constant NINE_7SEG  : std_logic_vector(6 downto 0) := "0010000";
    constant CLEAR_7SEG : std_logic_vector(6 downto 0) := "1111111";
    constant DASH_7SEG  : std_logic_vector(6 downto 0) := "0111111";
    constant P_7SEG     : std_logic_vector(6 downto 0) := "0001100";
    constant U_7SEG     : std_logic_vector(6 downto 0) := "1000001";
    constant L_7SEG     : std_logic_vector(6 downto 0) := "1000111";
    constant S_7SEG     : std_logic_vector(6 downto 0) := "0010010";
    constant E_7SEG     : std_logic_vector(6 downto 0) := "0000110";
    constant r_7SEG     : std_logic_vector(6 downto 0) := "0101111";
    constant o_7SEG     : std_logic_vector(6 downto 0) := "0100011";
    constant G_7SEG     : std_logic_vector(6 downto 0) := "1000010";
    constant F_7SEG     : std_logic_vector(6 downto 0) := "0001110";
    constant d_7SEG     : std_logic_vector(6 downto 0) := "0100001";
    constant c_7SEG     : std_logic_vector(6 downto 0) := "0100111";
    constant u_LOW_7SEG : std_logic_vector(6 downto 0) := "1100011";
    constant n_7SEG     : std_logic_vector(6 downto 0) := "0101011";

    -- [an]
    constant AN_DIGIT_CLEAR : std_logic_vector(3 downto 0) := "1111";
    constant AN_DIGIT_0     : std_logic_vector(3 downto 0) := "1110";
    constant AN_DIGIT_1     : std_logic_vector(3 downto 0) := "1101";
    constant AN_DIGIT_2     : std_logic_vector(3 downto 0) := "1011";
    constant AN_DIGIT_3     : std_logic_vector(3 downto 0) := "0111";
    
    -- [dp]         
    constant DECIMAL_ON  : std_logic := '0';
    constant DECIMAL_OFF : std_logic := '1';
    
    -- [LEDs]
    constant CLEAR_LED : std_logic_vector(15 downto 0) := (others => '0');  
    constant FULL_LED  : std_logic_vector(15 downto 0) := (others => '1'); 
    
    -- [Flick]             
    constant PROG_FLICK_RESET : std_logic_vector(1 downto 0) := "00";             
    constant PROG_FLICK_PROG  : std_logic_vector(1 downto 0) := "01";  
    constant PROG_FLICK_DATA  : std_logic_vector(1 downto 0) := "10";  
    constant RUN_FLICK_RESET  : std_logic_vector(2 downto 0) := "000";
    constant RUN_FLICK_RUN    : std_logic_vector(2 downto 0) := "001";
    constant RUN_FLICK_FREQ   : std_logic_vector(2 downto 0) := "010";
    constant RUN_FLICK_DUTY   : std_logic_vector(2 downto 0) := "100";
     
    -- [Finish Display]     
    constant MAX_COUNT_1S : int := 100000000;
    constant INCOMPLETE   : std_logic := '0';
    constant COMPLETE     : std_logic := '1';
    
end package;
