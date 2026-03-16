# build.tcl — Build breathing LED design for Original Zybo
# Run: ./scripts/run_vivado.sh scripts/03_breathing_led/build.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]

puts "============================================"
puts " Building: 03_breathing_led"
puts " Project root: $proj_root"
puts "============================================"

file mkdir "$proj_root/output/03_breathing_led"

set part xc7z010clg400-1

# Read sources
read_verilog "$proj_root/src/03_breathing_led/breathing_led.v"
read_xdc "$proj_root/constrs/03_breathing_led/zybo_breathing.xdc"

# Synthesize
puts "\n>>> Running Synthesis..."
synth_design -top breathing_led -part $part
report_utilization -file "$proj_root/output/03_breathing_led/utilization.rpt"

# Check DSP usage
puts "\n>>> DSP Usage:"
report_utilization -hierarchical -hierarchical_depth 1 -return_string

# Optimize, place, route
puts "\n>>> Running Optimization..."
opt_design

puts "\n>>> Running Placement..."
place_design

puts "\n>>> Running Routing..."
route_design

# Reports
report_timing_summary -file "$proj_root/output/03_breathing_led/timing.rpt"

# Check timing
if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "WARNING: Timing violations detected! Check timing.rpt"
} else {
    puts "Timing OK"
}

# Generate bitstream
puts "\n>>> Generating Bitstream..."
write_bitstream -force "$proj_root/output/03_breathing_led/breathing_led.bit"

puts "\n============================================"
puts " Build complete!"
puts " Bitstream: output/03_breathing_led/breathing_led.bit"
puts "============================================"
