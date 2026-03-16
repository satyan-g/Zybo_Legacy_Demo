# run.tcl — Program FPGA and run lwIP echo server on Zynq ARM core
# Run: xsct scripts/12_ethernet/run.tcl
#
# Open serial console BEFORE running: ./scripts/console.sh
# Then test: telnet <board-ip> 7   OR   nc <board-ip> 7

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/12_ethernet"
set bit_file "$out_dir/system.bit"
set elf_file "$out_dir/ethernet_demo.elf"

# Try multiple paths for ps7_init.tcl
set ps7_init_tcl "$out_dir/vitis_workspace/ethernet_demo/_ide/psinit/ps7_init.tcl"
if {![file exists $ps7_init_tcl]} {
    set ps7_init_tcl "$out_dir/vitis_workspace/zybo_platform/hw/sdt/ps7_init.tcl"
}

puts "============================================"
puts " Running: 12_ethernet on Zybo"
puts "============================================"

if {![file exists $bit_file]} {
    puts "ERROR: Bitstream not found at $bit_file"
    exit 1
}
if {![file exists $elf_file]} {
    puts "ERROR: ELF not found at $elf_file"
    exit 1
}
if {![file exists $ps7_init_tcl]} {
    puts "ERROR: ps7_init.tcl not found"
    puts "Tried: $out_dir/vitis_workspace/ethernet_demo/_ide/psinit/ps7_init.tcl"
    puts "  and: $out_dir/vitis_workspace/zybo_platform/hw/sdt/ps7_init.tcl"
    exit 1
}

# 1. Connect
puts "\n>>> Connecting to board..."
connect

# 2. System reset
puts "\n>>> Resetting system..."
targets -set -filter {name =~ "APU*"}
rst -system
after 1000

# 3. Program bitstream
puts "\n>>> Programming FPGA..."
targets -set -filter {name =~ "xc7z*"}
fpga -file $bit_file
after 500

# 4. PS init
puts "\n>>> Initializing PS (DDR, clocks, UART, Ethernet)..."
targets -set -filter {name =~ "ARM*#0"}
source $ps7_init_tcl
ps7_init
ps7_post_config
after 500

# 5. Processor reset
puts "\n>>> Resetting processor core..."
rst -processor
after 500

# 6. Download ELF
puts "\n>>> Loading ELF..."
dow $elf_file

# 7. Run
puts "\n>>> Starting execution..."
con

puts "\n============================================"
puts " lwIP Echo Server is running!"
puts " Check your serial console (picocom)"
puts " for the assigned IP address."
puts ""
puts " Test with:  telnet <board-ip> 7"
puts "         or: nc <board-ip> 7"
puts "============================================"

after 3000
disconnect
