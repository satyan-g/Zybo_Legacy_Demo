# program.tcl — Program Zybo with switches_buttons bitstream
# Run: ./scripts/run_vivado.sh scripts/04_switches_buttons/program.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set bitfile "$proj_root/output/04_switches_buttons/switches_buttons.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    exit 1
}

puts ">>> Programming FPGA with switches_buttons..."

open_hw_manager
connect_hw_server
open_hw_target

set device [get_hw_devices xc7z*]
if {$device eq ""} {
    puts "ERROR: No Zynq device found"
    exit 1
}
current_hw_device $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device

puts ">>> Done!"
puts ">>> SW[3]=0: switches control LEDs directly"
puts ">>> SW[3]=1: buttons toggle/rotate LEDs"

close_hw_target
disconnect_hw_server
close_hw_manager
