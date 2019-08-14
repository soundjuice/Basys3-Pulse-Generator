----------------------------------------------------------------------------------
-- Company: 
-- Engineers: Ahmad Frazier, Cheik Sylla
-- 
-- Create Date: 06/17/2019 04:20:02 PM
-- Design Name: 
-- Module Name: Pulse_Generator - Behavioral
-- Project Name: Pulse Generator Summer 2019 Project
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: 
--  Pulse Generator program that outputs a square wave signal on PMOD port JA1:J1. 
--  Both Frequency and Duty Cycle are configured by the user on a scale of 
--  1kHz - 99kHz and 1% - 99%.
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

entity Pulse_Generator is
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
end Pulse_Generator;

architecture Behavioral of Pulse_Generator is

--===================================================================================
    --------------------------- [COMPONENT PORT SIGNALS] ----------------------------
    --===================== Button_Debounce =====================
    -- Output port signals (out)
    signal Increase_Value  : std_logic;
    signal Program_Reset   : std_logic;
    signal Start_Generator : std_logic;
    signal Stop_Generator  : std_logic;
    signal Decrease_Value  : std_logic;
    
    ------------------------------- [STATE MACHINES] --------------------------------
    -- Pulse Generator
    type PG_States is (Initialization, Program, Increase, Decrease, Finish_Display, 
                       Run, Reset);
    signal PG_Next_State    : PG_States;
    signal PG_Current_State : PG_States := Initialization;
    
    -- Segment Display
    type Seg_States is (Clear_Digits, Digit_0, Digit_1, Digit_2, Digit_3);
    signal Seg_Next_State    : Seg_States;
    signal Seg_Current_State : Seg_States := Clear_Digits;
    
    ---------------------------------- [TYPE DEFS] ----------------------------------
    type Scroll_Type is array (12 downto 0) of std_logic_vector(6 downto 0);
    type Seg_Type    is array (3 downto 0)  of std_logic_vector(6 downto 0);
    type Pipe_Type   is array (5 downto 0)  of int;
    
    ---------------------------------- [CONSTANTS] ----------------------------------
    -- [segment]
    constant ALL_CLEAR_7SEG : Seg_Type := (CLEAR_7SEG,CLEAR_7SEG,CLEAR_7SEG,CLEAR_7SEG);
    constant RESET_7SEG     : Seg_Type := (DASH_7SEG,DASH_7SEG,DASH_7SEG,DASH_7SEG);
    constant PROG_7SEG      : Seg_Type := (P_7SEG,r_7SEG,o_7SEG,G_7SEG);   
    constant RUN_7SEG       : Seg_Type := (r_7SEG,u_LOW_7SEG, n_7SEG, CLEAR_7SEG);
    
    constant SCROLL_7SEG : Scroll_Type := (DASH_7SEG,DASH_7SEG,DASH_7SEG,DASH_7SEG,
                                          P_7SEG,U_7SEG,L_7SEG,S_7SEG,E_7SEG,
                                          DASH_7SEG,DASH_7SEG,DASH_7SEG,DASH_7SEG);
       
    ----------------------------------- [SIGNALS] -----------------------------------
    -- [Freq DC Calculation]
    signal Full_Count_Signal : int range 1010 to 100000;
    signal High_Count_Signal : int;
    signal High_Count_Multi  : int;
    signal Pipe_Multi : Pipe_Type;
    signal Pipe_Div   : Pipe_Type;
    
    -- [seg]
    signal Tens_Place_FR         : std_logic_vector(6 downto 0); 
    signal Tens_Place_DC         : std_logic_vector(6 downto 0);
    signal Ones_Place_FR         : std_logic_vector(6 downto 0);
    signal Ones_Place_DC         : std_logic_vector(6 downto 0);
    signal Ones_FR_Signal        : int range 0 to 9;
    signal Ones_DC_Signal        : int range 0 to 9;
    signal Tens_FR_Signal        : int range 0 to 9;
    signal Tens_DC_Signal        : int range 0 to 9;
    signal Freq_7Seg             : Seg_Type;
    signal Duty_7Seg             : Seg_Type;                         
    signal Segment_Signal        : Seg_Type;
    signal Segment_Scroll_Signal : Seg_Type;
    signal Scroll_Complete       : boolean := FALSE;
        
    -- [dp]
    signal Decimal_Point_Signal : std_logic;
    
    -- [LEDs] 
    signal Led_Signal : std_logic_vector(15 downto 0);    
    
    -- [Flick]
    signal Program_Flick : std_logic_vector(1 downto 0);
    signal Run_Flick     : std_logic_vector(2 downto 0);   
    
    -- [Finish Display]
    signal Finish_Display_Timer : std_logic;
    signal Increase_Again       : boolean := FALSE;
    signal Decrease_Again       : boolean := FALSE;
--===================================================================================

begin
    --------------------------- [COMPONENT INSTANTIATION] ---------------------------
    BD : Button_Debounce port map(clk_i          => clk,
                                  system_reset_i => system_reset_sw,  
                                  btnC_i         => btnC,    
                                  btnU_i         => btnU,
                                  btnL_i         => btnL,
                                  btnR_i         => btnR,
                                  btnD_i         => btnD,
                                  btnC_deb_o     => Stop_Generator,
                                  btnU_deb_o     => Increase_Value,
                                  btnL_deb_o     => Program_Reset,
                                  btnR_deb_o     => Start_Generator,
                                  btnD_deb_o     => Decrease_Value); 
                                                                                                                                             
--========================== PULSE GENERATOR STATE MACHINE ==========================
-- Main state machine that controls which part of the program the user is in, either
-- Initialization, Program, Increase_Value, Decrease_Value, Finish_Display, Run, or
-- Reset.
--
-- Program Flow:
--                                      ------------[Increase Again]-----------
--                                      |    -----------------------------    |        
--                                      |    |     -[Decrease Again]-    |    |
--                                     _v____|_   _v______       ___|____v____|__
--                                    |        | |        |     |                |
--    _______                         |Increase| |Decrease|---->| Finish Display |           
--   |       |                        |________| |________|     |________________|
--   | Reset |                             ^         ^                   |
--   |_______|                             |         |                   |   
--       |                     [Increase Value]   [Decrease Value]       |                                       
--  _____v________                        _|_________|__                 |
-- |              |                      |              |                |
-- |Initialization|--[Scroll Complete]-> |    Program   |<---[Display Timer Complete]
-- |______________|                      |______________|    
--                                         |          ^
--                            [Start Generator]       |
--                                         |     [Stop Generator] 
--                                      ___v_____     |
--                                     |         |    |
--                                     |   Run   |-----
--                                     |_________|       
--
--===================================================================================
------ [Register] ------------------------------------------------------------PROCESS
    PG_Register : process(clk, Program_Reset, system_reset_sw)
    begin
        if (system_reset_sw = ACTIVE) then
            PG_Current_State <= Reset;
        elsif (rising_edge(clk)) then
            if (Program_Reset = ACTIVE) then
                PG_Current_State <= Reset;
            else
                PG_Current_State <= PG_Next_State;
            end if;
        end if;
    end process;
------ [Transition] ----------------------------------------------------------PROCESS    
    PG_Transition : process(PG_Current_State, Start_Generator, Increase_Value,
                            Decrease_Value, Stop_Generator, Finish_Display_Timer,
                            Increase_Again, Decrease_Again, Scroll_Complete)
    begin
        case PG_Current_State is
            when Initialization =>
                if (Scroll_Complete = TRUE) then
                    PG_Next_State <= Program;
                else
                    PG_Next_State <= Initialization;
                end if;
            when Program =>
                if (Start_Generator = ACTIVE) then
                    PG_Next_State <= Run;
                elsif (Increase_Value = ACTIVE) then
                    PG_Next_State <= Increase;
                elsif (Decrease_Value = ACTIVE) then
                    PG_Next_State <= Decrease;
                else
                    PG_Next_State <= Program;
                end if;
            when Increase =>
                PG_Next_State <= Finish_Display;
            when Decrease =>
                PG_Next_State <= Finish_Display;
            when Finish_Display =>
                if (Finish_Display_Timer = COMPLETE) then
                    PG_Next_State <= Program; 
                elsif (Increase_Again = TRUE) then
                    PG_Next_State <= Increase; 
                elsif (Decrease_Again = TRUE) then
                    PG_Next_State <= Decrease; 
                else
                    PG_Next_State <= Finish_Display; 
                end if;
            when Run =>
                if (Stop_Generator = ACTIVE) then
                    PG_Next_State <= Program;
                else
                    PG_Next_State <= Run;
                end if;
            when Reset =>
                PG_Next_State <= Initialization;
        end case;            
    end process;
--===================================================================================
    
------ [Freq/DC Calculation] -------------------------------------------------PROCESS
-- Process that determines the Frequency and Duty Cycle of the Pulse Generator, and 
-- produces count signals that is used to approximate the frequency and duty cycle 
-- of desired specification.
--
-- When Pulse Generator is in Reset or Initialization state, the frequency is set to
-- 1 (representing 1kHz) and duty_cycle is set to 50 (representing 50%).
--
-- If in Increase/Decrease state, depending on config_mode_sw the corresponding data
-- value is Increased/Decreased by 1.
--
-- Next, predefined full count values are selected based on the chosen frequency where
-- the error is no more than 0.05% (error across all frequencies < 40Hz)  
--
-- Equation : 100MHz/(Chosen Frequency[kHz]) = Full Count
--          : Full Count * Duty Cycle[%] = High Cycle Count
--
-- Frequency and duty_cycle variables are converted into single digits in the tens 
-- and ones place.     
--          
-- Notes: More advanced pipelining will be implemented to the multiplier and divider.
-------------------------------------------------------------------------------------                        
    Freq_DC_Calculation : process(system_reset_sw, clk, PG_Current_State, 
                                  config_mode_sw)
        variable full_count : int range 1010 to 100000; 
        variable high_count : int;  
        variable frequency  : int range 1 to 99;
        variable duty_cycle : int range 1 to 99;  
                                                              
    begin
        if (system_reset_sw = ACTIVE) then
            frequency  := 1;
            duty_cycle := 50;
        elsif (rising_edge(clk)) then
            if (Program_Reset = ACTIVE) then
                frequency  := 1;
                duty_cycle := 50;
            else
                case PG_Current_State is
                    when Initialization | Reset =>
                        frequency  := 1;
                        duty_cycle := 50;
                    when Increase =>
                        if (config_mode_sw = PROG_FREQ and frequency < 99) then
                            frequency := frequency + 1; 
                        elsif (config_mode_sw = PROG_DUTY and duty_cycle < 99) then
                            duty_cycle := duty_cycle + 1; 
                        end if;
                    when Decrease =>
                        if (config_mode_sw = PROG_FREQ and frequency > 1) then
                            frequency := frequency - 1; 
                        elsif (config_mode_sw = PROG_DUTY and duty_cycle > 1) then
                            duty_cycle := duty_cycle - 1; 
                        end if;
                    when others =>
                        frequency  := frequency;
                        duty_cycle := duty_cycle;
                end case;

                -- Rounded precalculated full_count values (100MHz/Chosen Frequency)
                case frequency is 
                    when 99 => full_count := 1010;
                    when 98 => full_count := 1020;
                    when 97 => full_count := 1031;
                    when 96 => full_count := 1042;
                    when 95 => full_count := 1053;
                    when 94 => full_count := 1064;
                    when 93 => full_count := 1075;
                    when 92 => full_count := 1087;
                    when 91 => full_count := 1099;
                    when 90 => full_count := 1111;
                    when 89 => full_count := 1124;
                    when 88 => full_count := 1136;
                    when 87 => full_count := 1149;
                    when 86 => full_count := 1163;
                    when 85 => full_count := 1176;
                    when 84 => full_count := 1190;
                    when 83 => full_count := 1205;
                    when 82 => full_count := 1220;
                    when 81 => full_count := 1235;
                    when 80 => full_count := 1250;
                    when 79 => full_count := 1266;
                    when 78 => full_count := 1282;
                    when 77 => full_count := 1299;
                    when 76 => full_count := 1316;
                    when 75 => full_count := 1333;
                    when 74 => full_count := 1351;
                    when 73 => full_count := 1370;
                    when 72 => full_count := 1389;
                    when 71 => full_count := 1408;
                    when 70 => full_count := 1429;
                    when 69 => full_count := 1449;
                    when 68 => full_count := 1471;
                    when 67 => full_count := 1493;
                    when 66 => full_count := 1515;
                    when 65 => full_count := 1538;
                    when 64 => full_count := 1563;
                    when 63 => full_count := 1587;
                    when 62 => full_count := 1613;
                    when 61 => full_count := 1639;
                    when 60 => full_count := 1667;
                    when 59 => full_count := 1695;
                    when 58 => full_count := 1724;
                    when 57 => full_count := 1754;
                    when 56 => full_count := 1786;
                    when 55 => full_count := 1818;
                    when 54 => full_count := 1852;
                    when 53 => full_count := 1887;
                    when 52 => full_count := 1923;
                    when 51 => full_count := 1961;
                    when 50 => full_count := 2000;
                    when 49 => full_count := 2041;
                    when 48 => full_count := 2083;
                    when 47 => full_count := 2128;
                    when 46 => full_count := 2174;
                    when 45 => full_count := 2222;
                    when 44 => full_count := 2273;
                    when 43 => full_count := 2326;
                    when 42 => full_count := 2381;
                    when 41 => full_count := 2439;
                    when 40 => full_count := 2500;
                    when 39 => full_count := 2564;
                    when 38 => full_count := 2632;
                    when 37 => full_count := 2703;
                    when 36 => full_count := 2778;
                    when 35 => full_count := 2857;
                    when 34 => full_count := 2941;
                    when 33 => full_count := 3030;
                    when 32 => full_count := 3125;
                    when 31 => full_count := 3226;
                    when 30 => full_count := 3333;
                    when 29 => full_count := 3448;
                    when 28 => full_count := 3571;
                    when 27 => full_count := 3704;
                    when 26 => full_count := 3846;
                    when 25 => full_count := 4000;
                    when 24 => full_count := 4167;
                    when 23 => full_count := 4348;
                    when 22 => full_count := 4545;
                    when 21 => full_count := 4762;
                    when 20 => full_count := 5000;
                    when 19 => full_count := 5263;
                    when 18 => full_count := 5556;
                    when 17 => full_count := 5882;
                    when 16 => full_count := 6250;
                    when 15 => full_count := 6667;
                    when 14 => full_count := 7143;
                    when 13 => full_count := 7692;
                    when 12 => full_count := 8333;
                    when 11 => full_count := 9091;
                    when 10 => full_count := 10000;
                    when 9  => full_count := 11111;
                    when 8  => full_count := 12500;
                    when 7  => full_count := 14286;
                    when 6  => full_count := 16667;
                    when 5  => full_count := 20000;
                    when 4  => full_count := 25000;
                    when 3  => full_count := 33333;
                    when 2  => full_count := 50000;
                    when 1  => full_count := 100000;
                end case;
                
                Full_Count_Signal <= full_count;   

                -- Pipelining
                High_Count_Multi  <= Full_Count_Signal * duty_cycle;
                Pipe_Multi(0)     <= High_Count_Multi;
                Pipe_Multi(1)     <= Pipe_Multi(0);
                Pipe_Multi(2)     <= Pipe_Multi(1);
                Pipe_Multi(3)     <= Pipe_Multi(2);
                Pipe_Multi(4)     <= Pipe_Multi(3);
                Pipe_Multi(5)     <= Pipe_Multi(4);
                Pipe_Div(0)       <= Pipe_Multi(5) / 100;
                Pipe_Div(1)       <= Pipe_Div(0);
                Pipe_Div(2)       <= Pipe_Div(1);
                Pipe_Div(3)       <= Pipe_Div(2);
                Pipe_Div(4)       <= Pipe_Div(3);
                Pipe_Div(5)       <= Pipe_Div(4);
                High_Count_Signal <= Pipe_Div(5);
            end if;
              
            Ones_FR_Signal <= frequency mod 10;
            Tens_FR_Signal <= (frequency - Ones_FR_Signal) / 10;
            Ones_DC_Signal <= duty_cycle mod 10; 
            Tens_DC_Signal <= (duty_cycle - Ones_DC_Signal) / 10; 
        end if;        
     end process;

------ [Freq/DC to Segment] -------------------------------SELECTED SIGNAL ASSIGNMENT
-- From Freq/DC Calculation process, frequency and duty_cycle values are converted
-- into single digits in the tens and ones place.
--
-- The single digit values are translated into 7 segment values which are then used
-- to update Freq_7Seg and Duty_7Seg Signals for the 7 segment display.
-------------------------------------------------------------------------------------  
    with Ones_FR_Signal select
        Ones_Place_FR <= ZERO_7SEG   when 0,    
                         ONE_7SEG    when 1,
                         TWO_7SEG    when 2,
                         THREE_7SEG  when 3,
                         FOUR_7SEG   when 4,
                         FIVE_7SEG   when 5,
                         SIX_7SEG    when 6,
                         SEVEN_7SEG  when 7,
                         EIGHT_7SEG  when 8,
                         NINE_7SEG   when others;
    with Tens_FR_Signal select
        Tens_Place_FR <= ZERO_7SEG   when 0,    
                         ONE_7SEG    when 1,
                         TWO_7SEG    when 2,
                         THREE_7SEG  when 3,
                         FOUR_7SEG   when 4,
                         FIVE_7SEG   when 5,
                         SIX_7SEG    when 6,
                         SEVEN_7SEG  when 7,
                         EIGHT_7SEG  when 8,
                         NINE_7SEG   when others;
    with Ones_DC_Signal select
        Ones_Place_DC <= ZERO_7SEG   when 0,    
                         ONE_7SEG    when 1,
                         TWO_7SEG    when 2,
                         THREE_7SEG  when 3,
                         FOUR_7SEG   when 4,
                         FIVE_7SEG   when 5,
                         SIX_7SEG    when 6,
                         SEVEN_7SEG  when 7,
                         EIGHT_7SEG  when 8,
                         NINE_7SEG   when others;
    with Tens_DC_Signal select
        Tens_Place_DC <= ZERO_7SEG   when 0,    
                         ONE_7SEG    when 1,
                         TWO_7SEG    when 2,
                         THREE_7SEG  when 3,
                         FOUR_7SEG   when 4,
                         FIVE_7SEG   when 5,
                         SIX_7SEG    when 6,
                         SEVEN_7SEG  when 7,
                         EIGHT_7SEG  when 8,
                         NINE_7SEG   when others; 

    Freq_7Seg <= (F_7SEG,r_7SEG,Tens_Place_FR,Ones_Place_FR); 
    Duty_7Seg <= (d_7SEG,c_7SEG,Tens_Place_DC,Ones_Place_DC);    

------ [PMOD Output] ---------------------------------------------------------PROCESS
-- PMOD output that delivers the Pulse Generator signal.
--
-- After calculation of the full cycle count and high cycle count, when the
-- Pulse Generator state enters RUN, a counter is initiated.
--
-- If the counter is less than the high cycle count, the PMOD output is set to '1'.
--
-- If the counter is equal to or greater than the high cycle count and less than 
-- the full cycle count, the PMOD output is set to '0';
--
-- Finally, if the counter equals the full cycle count, the PMOD output is set back
-- to '1' and the counter is set back to 0.
--
-- The counter is set to 0 because it is incremented in the next iteration and will
-- be checked on the value of 1 instead of 0, confirming that there has been a state
-- change in the previous iteration.
-------------------------------------------------------------------------------------     
    PMOD_Output : process(system_reset_sw, clk, PG_Current_State, High_Count_Signal,
                          Full_Count_Signal)
        variable output_counter : int range 0 to 100000 := 0;
    begin         
        if (system_reset_sw = ACTIVE) then
            JA1_J1 <= '0';
            output_counter := 0;      
        elsif (rising_edge(clk)) then  
            if (Program_Reset = ACTIVE) then
                JA1_J1 <= '0';
                output_counter := 0;
            else 
                case PG_Current_State is
                    when Run =>
                        output_counter := output_counter + 1;
                        if (output_counter < High_Count_Signal) then
                            JA1_J1 <= '1';
                        elsif (output_counter >= High_Count_Signal and 
                               output_counter < Full_Count_Signal) then
                            JA1_J1 <= '0';
                        elsif (output_counter = Full_Count_Signal) then
                            JA1_J1 <= '1';
                            output_counter := 0;
                        end if; 
                    when others =>
                        JA1_J1 <= '0';
                        output_counter := 0;
                end case;
            end if;
        end if;                
    end process;   

--======================== 7 SEGMENT DISPLAY STATE MACHINE ==========================
-- State machine for the 7 segment display where every 1 ms the current state enters 
-- the next state.
--
-- Each state represents the position of the 7 segment display where 
-- from left to right 
-- Digit_0 = 4th digit place
-- Digit_1 = 3rd digit place
-- Digit_2 = 2nd digit place
-- Digit_3 = 1st digit place
--
-- When state Digit_2 is active and Freq_7Seg or Duty_7Seg is displayed, a decimal
-- point signal is activated to divide the letters and numbers.
--
-- State Clear_Digits is used to disconnect the 7 segment display completely upon 
-- reset.
--===================================================================================
------ [Register] ------------------------------------------------------------PROCESS
    Seg_Register : process(system_reset_sw, clk)   
        variable segment_counter : int range 1 to PERIOD_COUNT_1mS := 1;
    begin  
        if (system_reset_sw = ACTIVE) then
            Seg_Current_State <= Clear_Digits;
        elsif (rising_edge(clk)) then
            if (segment_counter = PERIOD_COUNT_1mS) then
                Seg_Current_State <= Seg_Next_State;
                segment_counter := 1;
            else
                segment_counter := segment_counter + 1;
            end if;
        end if;
    end process;        
------ [Transition] ----------------------------------------------------------PROCESS    
    Seg_Transistion : process(Decimal_Point_Signal, Segment_Signal, Seg_Current_State)
    begin
        case Seg_Current_State is
            when Clear_Digits =>
                seg            <= CLEAR_7SEG;
                an             <= AN_DIGIT_CLEAR;
                dp             <= DECIMAL_OFF;
                Seg_Next_State <= Digit_0;    
            when Digit_0 =>
                seg            <= Segment_Signal(0);
                an             <= AN_DIGIT_0;
                dp             <= DECIMAL_OFF;
                Seg_Next_State <= Digit_1;
            when Digit_1 =>
                seg            <= Segment_Signal(1);
                an             <= AN_DIGIT_1;
                dp             <= DECIMAL_OFF;
                Seg_Next_State <= Digit_2;
            when Digit_2 =>
                seg            <= Segment_Signal(2);
                an             <= AN_DIGIT_2;
                dp             <= Decimal_Point_Signal;
                Seg_Next_State <= Digit_3;
            when Digit_3 =>
                seg            <= Segment_Signal(3);
                an             <= AN_DIGIT_3;
                dp             <= DECIMAL_OFF;
                Seg_Next_State <= Digit_0;
        end case;
    end process;  
--===================================================================================
    
------ [Segment Process] -----------------------------------------------------PROCESS
-- A process that sends the value of the [4] 7 segment display digits and decimal 
-- point to the 7 segment display state machine.
--
-- When Pulse Generator state is
-- Initialization : 
--    "----PULSE----" will be scrolled across 7 segment display
--
-- Program : 
--    Display will flick between "Prog" | Freq_7Seg ("Fr.##") or
--    "Prog" | Duty_7Seg ("dc.##") depending on config_mode_sw.
--
-- Increase | Decrease | Finish_Display : 
--    Display Freq_7Seg ("Fr.##") or Duty_7Seg ("dc.##") depending on config_mode_sw.
--
-- Run : 
--    Display will flick between "run" | Freq_7Seg ("Fr.##") | Duty_7Seg ("dc.##").
--
-- Reset :
--    display "----"
-------------------------------------------------------------------------------------
    Segment_Process : process(system_reset_sw, clk, PG_Current_State, config_mode_sw,
                              Program_Flick, Run_Flick)
    begin
        if (system_reset_sw = ACTIVE) then
            Decimal_Point_Signal <= DECIMAL_OFF; 
            Segment_Signal(3 downto 0) <= ALL_CLEAR_7SEG;  
        elsif (rising_edge(clk)) then
            if (Program_Reset = ACTIVE) then
                Decimal_Point_Signal <= DECIMAL_OFF; 
                Segment_Signal(3 downto 0) <= RESET_7SEG; 
            else
                case PG_Current_State is
                    when Initialization =>
                        Decimal_Point_Signal <= DECIMAL_OFF;
                        Segment_Signal(3 downto 0) <= Segment_Scroll_Signal;
                    when Program =>
                        if (Program_Flick = PROG_FLICK_DATA) then   
                            Decimal_Point_Signal <= DECIMAL_ON; 
                            if (config_mode_sw = PROG_FREQ) then
                                Segment_Signal(3 downto 0) <= Freq_7Seg;
                            elsif (config_mode_sw = PROG_DUTY) then
                                Segment_Signal(3 downto 0) <= Duty_7Seg;
                            end if;
                        else 
                            Decimal_Point_Signal <= DECIMAL_OFF;
                            Segment_Signal(3 downto 0) <= PROG_7SEG;
                        end if;
                    when Increase | Decrease | Finish_Display =>
                        Decimal_Point_Signal <= DECIMAL_ON;
                        if (config_mode_sw = PROG_FREQ) then
                            Segment_Signal(3 downto 0) <= Freq_7Seg;
                        elsif (config_mode_sw = PROG_DUTY) then
                            Segment_Signal(3 downto 0) <= Duty_7Seg;
                        end if;
                    when Run =>
                        if (Run_Flick = RUN_FLICK_FREQ) then
                            Decimal_Point_Signal <= DECIMAL_ON;
                            Segment_Signal(3 downto 0) <= Freq_7Seg;
                        elsif (Run_Flick = RUN_FLICK_DUTY) then
                            Decimal_Point_Signal <= DECIMAL_ON;
                            Segment_Signal(3 downto 0) <= Duty_7Seg;
                        else 
                            Decimal_Point_Signal <= DECIMAL_OFF;
                            Segment_Signal(3 downto 0) <= RUN_7SEG;
                        end if;
                    when Reset =>
                        Decimal_Point_Signal <= DECIMAL_OFF;
                        Segment_Signal(3 downto 0) <= RESET_7SEG;
                end case;
            end if;
        end if; 
    end process;

                      
    
------ [Flick Display Clock] -------------------------------------------------PROCESS
-- Flick display for 7 segment when Pulse Generator is in Program or Run state.
--
-- In Program state, Program_Flick will alternate segment display between displaying 
-- "Prog" | "dc.##" or "Prog" | "Fr.##" every 1 second.
--
-- In Run state, Run_Flick will alternate segment display between displaying 
-- "run" | "Fr.##" | "dc.##" every 1 second.
------------------------------------------------------------------------------------- 
    Flick_Display_Clock : process(system_reset_sw, clk, PG_Current_State, Run_Flick)
        variable flick_counter : int range 1 to PERIOD_COUNT_1S := 1;                               
    begin
        if (system_reset_sw = ACTIVE) then
            Program_Flick <= PROG_FLICK_RESET;
            Run_Flick     <= RUN_FLICK_RESET;
            flick_counter := 1;
        elsif (rising_edge(clk)) then
            if (flick_counter = PERIOD_COUNT_1S) then
                flick_counter := 1; -- reset counter
                if (Program_Reset = ACTIVE) then
                    Program_Flick <= PROG_FLICK_RESET;
                    Run_Flick     <= RUN_FLICK_RESET;
                else
                    case PG_Current_State is 
                        when Program =>
                            Run_Flick <= RUN_FLICK_RUN; -- Display "run" initially in Run state
                            case Program_Flick is 
                                when PROG_FLICK_PROG =>
                                    Program_Flick <= PROG_FLICK_DATA;
                                when PROG_FLICK_DATA =>
                                    Program_Flick <= PROG_FLICK_PROG;
                                when others =>
                                    Program_Flick <= PROG_FLICK_PROG;
                            end case;
                        when Run =>  
                            Program_Flick <= PROG_FLICK_PROG; -- Display "ProG" initially in Program state
                            case Run_Flick is 
                                when RUN_FLICK_RUN =>
                                    Run_Flick <= RUN_FLICK_FREQ;
                                when RUN_FLICK_FREQ =>
                                    Run_Flick <= RUN_FLICK_DUTY;
                                when RUN_FLICK_DUTY =>
                                    Run_Flick <= RUN_FLICK_RUN;
                                when others =>
                                    Run_Flick <= RUN_FLICK_RUN;
                            end case;
                        when others =>
                            Program_Flick <= PROG_FLICK_RESET;
                            Run_Flick     <= RUN_FLICK_RESET;
                    end case;
                end if;
            else
                flick_counter := flick_counter + 1;
            end if;
        end if;        
    end process;

------ [Scroll Display Clock] ------------------------------------------------PROCESS
-- Process that handles the scrolling of "----PULSE----" on the 7 segment display
-- during Pulse Generator Initialization state.
--
-- On Initialization, the defined display constant is shifted into a segment signal
-- that gets updated every 500ms and once the constant is fully shifted, a segment
-- clear constant is shifted into the segment signal in order to clear the 
-- 7 segment display.
------------------------------------------------------------------------------------- 
    Scroll_Display_Clock : process(system_reset_sw, clk, PG_Current_State)
        variable scroll_counter : int range 1 to PERIOD_COUNT_500mS := 1;
        variable index_1 : int range 0 to 13;
        variable index_2 : int range 0 to 4;
    begin
        if (system_reset_sw = ACTIVE) then
            Segment_Scroll_Signal <= ALL_CLEAR_7SEG;
            Scroll_Complete <= FALSE;
            scroll_counter := 1;
            index_1 := 13;
            index_2 := 4;
        elsif (rising_edge(clk)) then
            if (scroll_counter = PERIOD_COUNT_500mS) then
                scroll_counter := 1;
                if (Program_Reset = ACTIVE) then
                    Segment_Scroll_Signal <= ALL_CLEAR_7SEG;
                    Scroll_Complete <= FALSE;
                    index_1 := 13;
                    index_2 := 4;
                else
                    case PG_Current_State is
                        when Initialization =>
                            if (index_1 = 0) then
                                if (index_2 = 0) then
                                    Scroll_Complete <= TRUE;
                                else
                                    index_2 := index_2 - 1;
                                    Segment_Scroll_Signal(3 downto 0) <= 
                                        Segment_Scroll_Signal(2 downto 0) & ALL_CLEAR_7SEG(index_2); 
                                    Scroll_Complete <= FALSE;
                                end if;
                            else
                                index_1 := index_1 - 1;
                                Segment_Scroll_Signal(3 downto 0) <= 
                                    Segment_Scroll_Signal(2 downto 0) & SCROLL_7SEG(index_1);
                                Scroll_Complete <= FALSE;
                            end if;    
                        when others =>
                            Segment_Scroll_Signal <= ALL_CLEAR_7SEG;
                            Scroll_Complete <= FALSE;
                            index_1 := 13;
                            index_2 := 4;
                    end case;
                end if;
            else
                scroll_counter := scroll_counter + 1;
            end if;
        end if;
    end process;

------ [Finish Display Timer Process] ----------------------------------------PROCESS
-- A 500ms counter that is initiated upon entering the Pulse Generator 
-- Finish_Display state where after an increase/decrease in data is performed, the 
-- counter counts to 500ms and sends the Pulse Generator state back to Program.
--
-- This counter holds the changed data value display for 500ms to enhance readability.
--
-- If a button press is detected in the Finish_Display state, the counter is reset.
------------------------------------------------------------------------------------- 
    Finish_Display_Timer_Process : process(system_reset_sw, clk, Increase_Again,
                                           Decrease_Again, Program_Reset)
        variable display_counter : int range 1 to PERIOD_COUNT_500mS := 1;
    begin
        if (system_reset_sw = ACTIVE) then
            Finish_Display_Timer <= INCOMPLETE;
            display_counter := 1;
        elsif (rising_edge(clk)) then
            if (Program_Reset = ACTIVE) then
                Finish_Display_Timer <= INCOMPLETE;
                display_counter := 1;
            else
                case PG_Current_State is
                    when Finish_Display =>
                        if (display_counter = PERIOD_COUNT_500mS) then
                            Finish_Display_Timer <= COMPLETE;
                            display_counter := 1;
                        elsif (Increase_Again = TRUE or Decrease_Again = TRUE) then
                            display_counter := 1;
                        else
                            display_counter := display_counter + 1;
                        end if;
                    when others =>
                        Finish_Display_Timer <= INCOMPLETE;
                        display_counter := 1;
                end case;
            end if;
        end if;
    end process;

------ [Finish Display Button Detect] ----------------------------------------PROCESS
-- When the Pulse Generator state is in Finish_Display, and the Finish_Display_Timer
-- is still counting, a rising edge on the up button (Increase_Value) or 
-- down button (Decrease_Value) will send the Pulse Generator state to Increase or
-- Decrease in order to increase/decrease the data value once and reset the timer.
--
-- When Pulse Generator state is in Increase or Decrease, the [Inc/Dec]_Again signals 
-- are set FALSE in order to be able to detect another button press in Finish_Display
-- state. 
--
-- This is done because on the rising edge of a button press, if the state is in any
-- other state besides Finish_Display, it would have to detect another button rising 
-- edge in order to set the [Inc/Dec]_Again signal FALSE.
------------------------------------------------------------------------------------- 
    Finish_Display_Button_Detect_Inc : process(system_reset_sw, Increase_Value, 
                                               PG_Current_State,Program_Reset)
    begin
        if (system_reset_sw = ACTIVE or PG_Current_State = Increase) then
            Increase_Again <= FALSE;
        elsif (rising_edge(Increase_Value)) then
            case PG_Current_State is
                when Finish_Display =>
                    Increase_Again <= TRUE;
                when others =>
                    Increase_Again <= FALSE;
            end case;
        end if;
    end process;

    Finish_Display_Button_Detect_Dec : process(system_reset_sw, Decrease_Value,
                                               PG_Current_State, Program_Reset)
    begin                                            
        if (system_reset_sw = ACTIVE or PG_Current_State = Decrease) then
            Decrease_Again <= FALSE;
        elsif (rising_edge(Decrease_Value)) then
            case PG_Current_State is
                when Finish_Display =>
                    Decrease_Again <= TRUE;
                when others =>
                    Decrease_Again <= FALSE;
            end case;
        end if;
    end process;                                           

------ [LED Process] ---------------------------------------------------------PROCESS
-- When Pulse Generator state is in Run, the leds are activated from left to right
-- through shifting on a 50ms clock cycle and once all leds are activated, they are
-- deactivated from left to right and repeat untill the state is other than Run.
-------------------------------------------------------------------------------------
    LED_Process : process(Led_Signal, system_reset_sw, clk, PG_Current_State, 
                          Program_Reset)
        variable led_counter : int range 1 to PERIOD_COUNT_50mS := 1;
        variable led_start   : std_logic;
    begin
        if (system_reset_sw = ACTIVE) then
            Led_Signal <= CLEAR_LED;
            led_counter := 1;
            led_start := ACTIVE;
        elsif (rising_edge(clk)) then
            if (led_counter = PERIOD_COUNT_50mS) then
                led_counter := 1;
                if (Program_Reset = ACTIVE) then
                    Led_Signal <= CLEAR_LED;
                    led_start := ACTIVE;
                else
                    case PG_Current_State is 
                        when Run =>
                            if (led_start = ACTIVE) then 
                                if (Led_Signal = FULL_LED) then
                                    led_start := not ACTIVE;
                                else
                                    Led_Signal <= Led_Signal(14 downto 0) & '1';
                                end if;
                            elsif (led_start /= ACTIVE) then
                                if (Led_Signal = CLEAR_LED) then
                                    led_start := ACTIVE;
                                else
                                    Led_Signal <= Led_Signal(14 downto 0) & '0';
                                end if;
                            end if;
                        when others =>
                            Led_Signal <= CLEAR_LED;
                            led_start := ACTIVE;
                    end case;
                end if;
            else
                led_counter := led_counter + 1;
            end if;        
        end if;            
        led <= Led_Signal;
    end process;
    
end Behavioral;
