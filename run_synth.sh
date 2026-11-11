#!/bin/sh
# Synthesis flow. Install with:  pip install yowasp-yosys   (or use OSS CAD Suite)
YOSYS=${YOSYS:-yosys}
mkdir -p synth/reports synth/out
$YOSYS -q -s synth/synth_generic.ys && cat synth/reports/generic_stat.txt
$YOSYS -q -s synth/synth_ecp5.ys    && cat synth/reports/ecp5_stat.txt
