# Basys 3 Pulse Generator
## Description
Pulse Generator program that outputs a square wave signal between 0v and 3.3v on PMOD port JA1:J1 of Basys3 FPGA Board. Both Frequency and Duty Cycle are configured by the user on a scale of 1kHz - 99kHz and 1% - 99%. 

<b>Basys 3 Layout</b>
	
![Basys-3-Layout](https://github.com/soundjuice/Basys3-Pulse-Generator/blob/master/docs/images/Basys-3-Pulse-Generator-Layout.png)

| PMOD Ports | PMOD JA Labels |
|--|--|
|![PMOD-Ports](https://github.com/soundjuice/Basys3-Pulse-Generator/blob/master/docs/images/Pmod-Port.png)|![PMOD-Port-Labels](https://github.com/soundjuice/Basys3-Pulse-Generator/blob/master/docs/images/Pmod-Port-Labels.png)|

<center>

>
> **PMOD Ports supply a max current of 2A / typical current between 100mA to 1.5A on a 3.3v supply with a zener diode regulator for each port.**
> **The VCC and Ground pins can deliver up to 1A of current**.
> Pmod data signals are not matched pairs, and they are routed using best-available tracks without impedance control or delay matching. 
> &mdash; <cite class="title">Basys 3™ FPGA Board Reference Manual.</cite> <cite class="author">Digilent, Inc.</cite>

_Connect PMOD output JA1:J1 to an input and use either GND port on JA as common ground._

</center>

 |Peripherals|Description|
 |:-:|-|
 |Up Button|Increase Frequency or Duty Cycle value|
 |Down Button|Decrease Frequency or Duty Cycle value|
 |Left Button|Program Reset|
 |Center Button|Stop Pulse Generator|
 |Right Button|Start Pulse Generator|
 |Switch 0|[Up] Program Frequency <br> [Down] Program Duty Cycle|
 |Switch 15|System Reset|
 |LEDs|Notify running program
 |7 Segment Display|[Initialization] "----PULSE----" <br> [Program] "Prog" \| "Fr.01" \| "dc.50" <br> [Run] "run" \| "Fr.01" \| "dc.50" <br> [Reset] "----"
 |PMOD JA [JA1:J1]|Pulse Output
 
## Requirements
- [Basys3](https://store.digilentinc.com/basys-3-artix-7-fpga-trainer-board-recommended-for-introductory-users/) 
- MicroUSB Cable
- [Vivado HLx 2019.1: WebPACK and Editions](https://www.xilinx.com/support/download.html?_ga=2.82180886.1698710582.1561930953-2036611854.1558574743) - (any version after 2018.3)
	* [Installing Vivado and Digilent Board Files](https://reference.digilentinc.com/vivado/installing-vivado/start)
## Setup
1. Open Vivado and **Create Project** (creates a new project)
	- select RTL Project (Register-transfer level)
2. In _Add Sources_ window, click **Add Files** and select all .vhd files within the sources folder. 
	- Be sure to select _"Copy sources into project"_ to prevent overwriting of original files.
3. In _Add Constraints_ window, click **Add Files** and select the .xdc constraint file within the constraints folder.
	- Be sure to select _"Copy sources into project"_ to prevent overwriting of original files.
4. In _Default Part_ window, select **Boards** and search for Basys3 in the search bar.
5. Once on the _PROJECT MANAGER_ page, execute these commands in the following order:
 
 |Commands|Image
 |:-:|:-:|
 |1. **Run Synthesis** <br> 2. **Run Implementation** <br> 3. **Generate Bitstream** <br> 4. **Open Target** (after connecting to Basys 3 board via microUSB) <br> 5. **Program Device** (select board and click **Program** on pop-up)|![Vivado-Flow-Navigator](https://github.com/soundjuice/Basys3-Pulse-Generator/blob/master/docs/images/Vivado-Flow-Navigator.PNG)|

**BEFORE OPERATION - Connect PMOD output JA1:J1 to an input and use either GND port on JA as common ground.** 
## Resources
* [Basys 3 Resources](https://reference.digilentinc.com/reference/programmable-logic/basys-3/start)
