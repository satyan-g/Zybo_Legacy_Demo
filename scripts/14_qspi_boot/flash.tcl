# flash.tcl — Program QSPI flash on Zybo with BOOT.BIN
# Run: vivado -mode batch -source scripts/14_qspi_boot/flash.tcl
#
# Programs the on-board QSPI flash so the board boots autonomously.
# After flashing, set the JP5 boot jumper to QSPI and power cycle.

set script_dir [file dirname [info script]]
set proj_root  [file normalize "$script_dir/../.."]
set out_dir    "$proj_root/output/14_qspi_boot"

set boot_bin   "$out_dir/BOOT.BIN"
set fsbl_elf   "$out_dir/fsbl.elf"

puts "============================================"
puts " Programming QSPI Flash — 14_qspi_boot"
puts "============================================"

# Verify inputs
if {![file exists $boot_bin]} {
    puts "ERROR: BOOT.BIN not found at $boot_bin"
    puts "Run build_boot.tcl first."
    exit 1
}
if {![file exists $fsbl_elf]} {
    puts "ERROR: FSBL ELF not found at $fsbl_elf"
    puts "Run build_sw.tcl first."
    exit 1
}

set boot_size [file size $boot_bin]
puts "INFO: BOOT.BIN size = $boot_size bytes ([expr {$boot_size / 1024}] KB)"

# Open hardware manager and connect
puts "\n>>> Connecting to hardware..."
open_hw_manager
connect_hw_server
open_hw_target

# Program QSPI flash using program_flash
# The Zybo has a single QSPI flash (Spansion S25FL128S, 16 MB)
# Flash type: qspi-x1-single
puts "\n>>> Programming QSPI flash (this may take a few minutes)..."
puts "INFO: Using program_flash with blank_check and verify"

program_flash -f $boot_bin \
    -flash_type qspi-x1-single \
    -fsbl $fsbl_elf \
    -blank_check \
    -verify

puts "\n============================================"
puts " QSPI Flash programmed successfully!"
puts "============================================"
puts ""
puts " To boot from QSPI:"
puts "   1. Set JP5 boot jumper to QSPI"
puts "   2. Power cycle the board (unplug/replug USB)"
puts "   3. Open serial console: ./scripts/console.sh"
puts "   4. Board should boot and show LED binary counter"
puts ""
puts " To go back to JTAG mode:"
puts "   1. Set JP5 boot jumper to JTAG"
puts "   2. Power cycle the board"
puts "============================================"

# Cleanup
close_hw_target
disconnect_hw_server
close_hw_manager
