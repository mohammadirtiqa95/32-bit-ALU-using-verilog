#!/bin/sh
# Compile and run all testbenches (Icarus Verilog). Run from the project root.
set -e
mkdir -p sim
RTL="rtl/adder32.v rtl/barrel_shifter32.v rtl/alu32.v"

iverilog -g2005 -Wall -o sim/adder_tb.vvp  rtl/adder32.v tb/tb_adder32.v
vvp sim/adder_tb.vvp | tee sim/adder_sim.log

iverilog -g2005 -Wall -o sim/shifter_tb.vvp rtl/barrel_shifter32.v tb/tb_barrel_shifter32.v
vvp sim/shifter_tb.vvp | tee sim/shifter_sim.log

iverilog -g2005 -Wall -o sim/alu_tb.vvp $RTL tb/tb_alu32.v
vvp sim/alu_tb.vvp | tee sim/alu_sim.log
echo "Waveform: gtkwave sim/alu32.vcd"
