# run.tcl — Program FPGA and run Hello World on Zynq ARM core
# Run: ./scripts/run_xsct.sh scripts/02_hello/run.tcl
#
# Sequence (matches Vitis IDE launch.json):
#   1. System reset
#   2. Program bitstream
#   3. PS init (DDR, clocks, UART)
#   4. Processor reset (clears stale core state)
#   5. Download ELF
#   6. Run
#
# Open serial console BEFORE running: ./scripts/console.sh

set script_dir [file dirname [info script]]
set base_dir [lindex $argv 0]
if {$base_dir eq ""} { puts "ERROR: base_dir argument required. Run via deploy.sh"; exit 1 }
set hw_dir "$base_dir/hw"
set sw_dir "$base_dir/sw"
set bit_file "$hw_dir/system.bit"
set elf_file "$sw_dir/hello.elf"
set ps7_init_tcl "$sw_dir/vitis_workspace/hello/_ide/psinit/ps7_init.tcl"

puts "============================================"
puts " Running: 02_hello on Zybo"
puts "============================================"

if {![file exists $elf_file]} {
    puts "ERROR: ELF not found at $elf_file"
    exit 1
}
if {![file exists $ps7_init_tcl]} {
    set ps7_init_tcl "$sw_dir/vitis_workspace/zybo_platform/hw/sdt/ps7_init.tcl"
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
if {[file exists $bit_file]} {
    puts "\n>>> Programming FPGA..."
    targets -set -filter {name =~ "xc7z*"}
    fpga -file $bit_file
    after 500
}

# 4. PS init
puts "\n>>> Initializing PS (DDR, clocks, UART)..."
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
puts " Hello World is running!"
puts " Check your serial console (picocom)"
puts "============================================"

after 3000
disconnect
