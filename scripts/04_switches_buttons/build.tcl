# build.tcl — Build switches & buttons demo
# Run: ./scripts/run_vivado.sh scripts/04_switches_buttons/build.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]

puts "============================================"
puts " Building: 04_switches_buttons"
puts "============================================"

file mkdir "$proj_root/output/04_switches_buttons"

set part xc7z010clg400-1

read_verilog "$proj_root/src/04_switches_buttons/switches_buttons.v"
read_xdc "$proj_root/constrs/04_switches_buttons/zybo_sw_btn.xdc"

puts "\n>>> Synthesis..."
synth_design -top switches_buttons -part $part
report_utilization -file "$proj_root/output/04_switches_buttons/utilization.rpt"

puts "\n>>> Opt + Place + Route..."
opt_design
place_design
route_design

report_timing_summary -file "$proj_root/output/04_switches_buttons/timing.rpt"

if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "WARNING: Timing violations!"
} else {
    puts "Timing OK"
}

puts "\n>>> Bitstream..."
write_bitstream -force "$proj_root/output/04_switches_buttons/switches_buttons.bit"

puts "\n============================================"
puts " Build complete!"
puts " Bitstream: output/04_switches_buttons/switches_buttons.bit"
puts "============================================"
