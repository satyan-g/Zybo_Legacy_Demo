# build.tcl — Build switches & buttons demo
# Run: ./scripts/run_vivado.sh scripts/04_switches_buttons/build.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }

puts "============================================"
puts " Building: 04_switches_buttons"
puts "============================================"

file mkdir $out_dir

set part xc7z010clg400-1

read_verilog "$script_dir/switches_buttons.v"
read_xdc "$script_dir/zybo_sw_btn.xdc"

puts "\n>>> Synthesis..."
synth_design -top switches_buttons -part $part
report_utilization -file "$out_dir/utilization.rpt"

puts "\n>>> Opt + Place + Route..."
opt_design
place_design
route_design

report_timing_summary -file "$out_dir/timing.rpt"

if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "WARNING: Timing violations!"
} else {
    puts "Timing OK"
}

puts "\n>>> Bitstream..."
write_bitstream -force "$out_dir/switches_buttons.bit"

puts "\n============================================"
puts " Build complete!"
puts " Bitstream: output/04_switches_buttons/switches_buttons.bit"
puts "============================================"
