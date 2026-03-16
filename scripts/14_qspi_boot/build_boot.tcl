# build_boot.tcl — Create BOOT.BIN for QSPI flash boot
# Run: vivado -mode batch -source scripts/14_qspi_boot/build_boot.tcl
#   or: xsct scripts/14_qspi_boot/build_boot.tcl
#
# This script writes a BIF file and invokes bootgen to produce BOOT.BIN
# containing: FSBL + bitstream + application ELF

set script_dir [file dirname [info script]]
set proj_root  [file normalize "$script_dir/../.."]
set out_dir    "$proj_root/output/14_qspi_boot"

set fsbl_elf   "$out_dir/fsbl.elf"
set bit_file   "$out_dir/system.bit"
set app_elf    "$out_dir/qspi_boot_demo.elf"
set bif_file   "$out_dir/qspi_boot.bif"
set boot_bin   "$out_dir/BOOT.BIN"

puts "============================================"
puts " Creating BOOT.BIN for QSPI flash boot"
puts "============================================"

# Verify all inputs exist
foreach {label path} [list "FSBL ELF" $fsbl_elf "Bitstream" $bit_file "App ELF" $app_elf] {
    if {![file exists $path]} {
        puts "ERROR: $label not found at $path"
        puts "Run build_hw.tcl and build_sw.tcl first."
        exit 1
    }
}

# -----------------------------------------------------------------------------
# Write BIF file
# -----------------------------------------------------------------------------
puts "\n>>> Writing BIF file: $bif_file"
set bif_fd [open $bif_file w]
puts $bif_fd "//arch = zynq; split = false; format = BIN"
puts $bif_fd "the_ROM_image:"
puts $bif_fd "\{"
puts $bif_fd "  \[bootloader\]$fsbl_elf"
puts $bif_fd "  $bit_file"
puts $bif_fd "  $app_elf"
puts $bif_fd "\}"
close $bif_fd

puts "INFO: BIF written."

# -----------------------------------------------------------------------------
# Run bootgen
# -----------------------------------------------------------------------------
puts "\n>>> Running bootgen..."

# Remove old BOOT.BIN if present
if {[file exists $boot_bin]} {
    file delete -force $boot_bin
}

set bootgen_cmd "bootgen -image $bif_file -arch zynq -o $boot_bin -w on"
puts "CMD: $bootgen_cmd"

if {[catch {exec bootgen -image $bif_file -arch zynq -o $boot_bin -w on} result]} {
    puts "bootgen output: $result"
    # bootgen sometimes prints to stderr even on success; check if file was created
    if {![file exists $boot_bin]} {
        puts "ERROR: bootgen failed — BOOT.BIN not created"
        exit 1
    }
} else {
    puts "bootgen output: $result"
}

if {[file exists $boot_bin]} {
    set boot_size [file size $boot_bin]
    puts "\n============================================"
    puts " BOOT.BIN created successfully!"
    puts " File: output/14_qspi_boot/BOOT.BIN"
    puts " Size: $boot_size bytes ([expr {$boot_size / 1024}] KB)"
    puts "============================================"
    puts "INFO: Next step: run flash.tcl to program QSPI flash"
} else {
    puts "ERROR: BOOT.BIN was not created"
    exit 1
}
