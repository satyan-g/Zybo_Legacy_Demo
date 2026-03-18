# build.tcl — Build blink LED design for Zybo Z7-10
# Run: vivado -mode batch -source scripts/01_blink/build.tcl

# Get project root (two levels up from this script)
set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }

puts "============================================"
puts " Building: 01_blink (LED Blink)"
puts " Project root: $proj_root"
puts "============================================"

# Create output directory
file mkdir $out_dir

# Target FPGA part — Zybo Z7-10
set part xc7z010clg400-1

# Read sources
read_verilog "$script_dir/blink.v"
read_xdc "$script_dir/zybo_blink.xdc"

# Synthesize
puts "\n>>> Running Synthesis..."
synth_design -top blink -part $part
report_utilization -file "$out_dir/utilization.rpt"

# Optimize, place, and route
puts "\n>>> Running Optimization..."
opt_design

puts "\n>>> Running Placement..."
place_design

puts "\n>>> Running Routing..."
route_design

# Reports
report_timing_summary -file "$out_dir/timing.rpt"
report_drc -file "$out_dir/drc.rpt"

# Check timing
if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "ERROR: Timing violations detected! Check timing.rpt"
} else {
    puts "Timing OK"
}

# Generate bitstream
puts "\n>>> Generating Bitstream..."
write_bitstream -force "$out_dir/blink.bit"

puts "\n============================================"
puts " Build complete!"
puts " Bitstream: output/01_blink/blink.bit"
puts " Reports:   output/01_blink/*.rpt"
puts "============================================"
