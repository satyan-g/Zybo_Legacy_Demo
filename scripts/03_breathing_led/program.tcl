# program.tcl — Program Zybo with breathing LED bitstream
# Run: ./scripts/run_vivado.sh scripts/03_breathing_led/program.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set bitfile "$proj_root/output/03_breathing_led/breathing_led.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    exit 1
}

puts ">>> Programming FPGA with breathing_led..."

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

puts ">>> Done! LEDs should be breathing."
puts ">>> Switches: [1:0]=speed, [3:2]=mode"

close_hw_target
disconnect_hw_server
close_hw_manager
