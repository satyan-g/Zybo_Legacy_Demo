# program.tcl — Program Zybo Z7-10 with blink bitstream
# Run: vivado -mode batch -source scripts/01_blink/program.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set bitfile "$proj_root/output/01_blink/blink.bit"

if {![file exists $bitfile]} {
    puts "ERROR: Bitstream not found at $bitfile"
    puts "Run the build first: vivado -mode batch -source scripts/01_blink/build.tcl"
    exit 1
}

puts "============================================"
puts " Programming Zybo Z7-10"
puts " Bitstream: $bitfile"
puts "============================================"

# Connect to board
open_hw_manager
connect_hw_server
open_hw_target

# Get the FPGA device (skip arm_dap, find the xc7z* device)
set device [get_hw_devices xc7z*]
if {$device eq ""} {
    puts "ERROR: No Zynq FPGA device found. Available devices:"
    foreach d [get_hw_devices] { puts "  $d" }
    exit 1
}
current_hw_device $device
set_property PROGRAM.FILE $bitfile $device

# Program
puts "\n>>> Programming FPGA..."
program_hw_devices $device

puts "\n============================================"
puts " Programming complete!"
puts " LEDs should be blinking now."
puts "============================================"

close_hw_target
disconnect_hw_server
close_hw_manager
