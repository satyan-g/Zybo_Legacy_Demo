# run.tcl — Program FPGA and run AXI GPIO demo on Zynq ARM core
# Run: xsct scripts/05_axi_gpio/run.tcl
#
# Open serial console BEFORE running: ./scripts/console.sh

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/05_axi_gpio"
set bit_file "$out_dir/system.bit"
set elf_file "$out_dir/axi_gpio_demo.elf"

# Try multiple paths for ps7_init.tcl
set ps7_init_tcl "$out_dir/vitis_workspace/axi_gpio_demo/_ide/psinit/ps7_init.tcl"
if {![file exists $ps7_init_tcl]} {
    set ps7_init_tcl "$out_dir/vitis_workspace/zybo_platform/hw/sdt/ps7_init.tcl"
}

puts "============================================"
puts " Running: 05_axi_gpio on Zybo"
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
    puts "Tried: $out_dir/vitis_workspace/axi_gpio_demo/_ide/psinit/ps7_init.tcl"
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
puts " AXI GPIO demo is running!"
puts " Check your serial console (picocom)"
puts " Toggle switches / press buttons to see"
puts " LED patterns change."
puts "============================================"

after 3000
disconnect
