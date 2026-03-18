# run.tcl — Program Zybo with breathing LED bitstream via XSCT
# Run: xsct src/03_breathing_led/run.tcl

set script_dir [file dirname [info script]]
set base_dir [lindex $argv 0]
if {$base_dir eq ""} { puts "ERROR: base_dir argument required. Run via deploy.sh"; exit 1 }
set bitfile "$base_dir/hw/breathing_led.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    puts "Build first: ./scripts/build_hw.sh 03_breathing_led"
    exit 1
}

puts "============================================"
puts " Programming Zybo (Original) — 03_breathing_led"
puts " Bitstream: $bitfile"
puts "============================================"

connect
targets -set -filter {name =~ "xc7z*"}
fpga -file $bitfile
disconnect

puts "\n>>> Done! LEDs should be breathing."
puts ">>> Switches: \[1:0\]=speed, \[3:2\]=mode"
