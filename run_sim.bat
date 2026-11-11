@echo off
rem Compile and run all testbenches (Icarus Verilog). Run from the project root.
if not exist sim mkdir sim
set RTL=rtl\adder32.v rtl\barrel_shifter32.v rtl\alu32.v

iverilog -g2005 -Wall -o sim\adder_tb.vvp rtl\adder32.v tb\tb_adder32.v || exit /b 1
vvp sim\adder_tb.vvp > sim\adder_sim.log & type sim\adder_sim.log

iverilog -g2005 -Wall -o sim\shifter_tb.vvp rtl\barrel_shifter32.v tb\tb_barrel_shifter32.v || exit /b 1
vvp sim\shifter_tb.vvp > sim\shifter_sim.log & type sim\shifter_sim.log

iverilog -g2005 -Wall -o sim\alu_tb.vvp %RTL% tb\tb_alu32.v || exit /b 1
vvp sim\alu_tb.vvp > sim\alu_sim.log & type sim\alu_sim.log
echo Waveform: gtkwave sim\alu32.vcd
