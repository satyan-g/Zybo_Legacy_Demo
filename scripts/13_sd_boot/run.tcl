# run.tcl — Program FPGA and run SD boot demo via JTAG (for testing)
# Run: xsct scripts/13_sd_boot/run.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/13_sd_boot"
set bit_file "$out_dir/system.bit"
set elf_file "$out_dir/sd_boot_demo.elf"

# Try multiple ps7_init.tcl fallback paths
set ps7_init_tcl "$out_dir/vitis_workspace/sd_boot_demo/_ide/psinit/ps7_init.tcl"
if {![file exists $ps7_init_tcl]} {
    set ps7_init_tcl "$out_dir/vitis_workspace/zybo_platform/hw/sdt/ps7_init.tcl"
}

puts "============================================"
puts " Running: 13_sd_boot on Zybo (via JTAG)"
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
puts "\n>>> Initializing PS..."
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
puts " SD boot demo running (via JTAG)!"
puts " LEDs: Knight Rider chaser pattern"
puts " Serial: boot mode + cycle count"
puts "============================================"

after 3000
disconnect
