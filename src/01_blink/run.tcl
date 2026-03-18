# run.tcl — Program Zybo with blink bitstream via XSCT
# Run: xsct src/01_blink/run.tcl

set script_dir [file dirname [info script]]
set base_dir [lindex $argv 0]
if {$base_dir eq ""} { puts "ERROR: base_dir argument required. Run via deploy.sh"; exit 1 }
set bitfile "$base_dir/hw/blink.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    puts "Build first: ./scripts/build_hw.sh 01_blink"
    exit 1
}

puts "============================================"
puts " Programming Zybo (Original) — 01_blink"
puts " Bitstream: $bitfile"
puts "============================================"

connect
targets -set -filter {name =~ "xc7z*"}
fpga -file $bitfile
disconnect

puts "\n>>> Done! LEDs should be blinking."
