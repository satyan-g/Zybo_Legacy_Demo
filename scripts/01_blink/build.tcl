# build.tcl — Build blink LED design for Zybo Z7-10
# Run: vivado -mode batch -source scripts/01_blink/build.tcl

# Get project root (two levels up from this script)
set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]

puts "============================================"
puts " Building: 01_blink (LED Blink)"
puts " Project root: $proj_root"
puts "============================================"

# Create output directory
file mkdir "$proj_root/output/01_blink"

# Target FPGA part — Zybo Z7-10
set part xc7z010clg400-1

# Read sources
read_verilog "$proj_root/src/01_blink/blink.v"
read_xdc "$proj_root/constrs/01_blink/zybo_blink.xdc"

# Synthesize
puts "\n>>> Running Synthesis..."
synth_design -top blink -part $part
report_utilization -file "$proj_root/output/01_blink/utilization.rpt"

# Optimize, place, and route
puts "\n>>> Running Optimization..."
opt_design

puts "\n>>> Running Placement..."
place_design

puts "\n>>> Running Routing..."
route_design

# Reports
report_timing_summary -file "$proj_root/output/01_blink/timing.rpt"
report_drc -file "$proj_root/output/01_blink/drc.rpt"

# Check timing
if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "ERROR: Timing violations detected! Check timing.rpt"
} else {
    puts "Timing OK"
}

# Generate bitstream
puts "\n>>> Generating Bitstream..."
write_bitstream -force "$proj_root/output/01_blink/blink.bit"

puts "\n============================================"
puts " Build complete!"
puts " Bitstream: output/01_blink/blink.bit"
puts " Reports:   output/01_blink/*.rpt"
puts "============================================"
