# run.tcl — Program Zybo with switches_buttons bitstream via XSCT
# Run: xsct src/04_switches_buttons/run.tcl

set script_dir [file dirname [info script]]
set base_dir [lindex $argv 0]
if {$base_dir eq ""} { puts "ERROR: base_dir argument required. Run via deploy.sh"; exit 1 }
set bitfile "$base_dir/hw/switches_buttons.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    puts "Build first: ./scripts/build_hw.sh 04_switches_buttons"
    exit 1
}

puts "============================================"
puts " Programming Zybo (Original) — 04_switches_buttons"
puts " Bitstream: $bitfile"
puts "============================================"

connect
targets -set -filter {name =~ "xc7z*"}
fpga -file $bitfile
disconnect

puts "\n>>> Done!"
puts ">>> SW\[3\]=0: switches control LEDs directly"
puts ">>> SW\[3\]=1: buttons toggle/rotate LEDs"
