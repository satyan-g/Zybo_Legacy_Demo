# build_boot.tcl — Create BOOT.BIN for SD card boot
# Generates BIF file and runs bootgen to produce BOOT.BIN
# Usage: xsct scripts/13_sd_boot/build_boot.tcl
#   -OR- vivado -mode batch -source scripts/13_sd_boot/build_boot.tcl
#   -OR- tclsh scripts/13_sd_boot/build_boot.tcl (if bootgen is on PATH)

set script_dir [file dirname [info script]]
set proj_root  [file normalize "$script_dir/../.."]
set out_dir    "$proj_root/output/13_sd_boot"

# Verify required files exist
set fsbl_elf   "$out_dir/fsbl.elf"
set bit_file   "$out_dir/system.bit"
set app_elf    "$out_dir/sd_boot_demo.elf"

foreach f [list $fsbl_elf $bit_file $app_elf] {
    if {![file exists $f]} {
        puts "ERROR: Required file not found: $f"
        puts "       Run build_hw.tcl and build_sw.tcl first."
        exit 1
    }
}

# -----------------------------------------------------------------------------
# Create BIF (Boot Image Format) file
# -----------------------------------------------------------------------------
set bif_path "$out_dir/sd_boot.bif"
puts "INFO: Creating BIF file at $bif_path"

set bif_fd [open $bif_path w]
puts $bif_fd "the_ROM_image:"
puts $bif_fd "\{"
puts $bif_fd "    \[bootloader\] $fsbl_elf"
puts $bif_fd "    $bit_file"
puts $bif_fd "    $app_elf"
puts $bif_fd "\}"
close $bif_fd

puts "INFO: BIF file created."

# -----------------------------------------------------------------------------
# Run bootgen to create BOOT.BIN
# -----------------------------------------------------------------------------
set boot_bin "$out_dir/BOOT.BIN"

# Remove old BOOT.BIN if it exists
if {[file exists $boot_bin]} {
    file delete -force $boot_bin
}

puts "INFO: Running bootgen to create BOOT.BIN..."
set bootgen_cmd "bootgen -image $bif_path -arch zynq -o $boot_bin -w"
puts "INFO: Command: $bootgen_cmd"

if {[catch {exec {*}$bootgen_cmd} result]} {
    puts "ERROR: bootgen failed:"
    puts $result
    exit 1
}

# Verify BOOT.BIN was created
if {![file exists $boot_bin]} {
    puts "ERROR: BOOT.BIN was not created!"
    exit 1
}

set bin_size [file size $boot_bin]
puts "INFO: BOOT.BIN created successfully!"
puts "INFO: Size: $bin_size bytes ([expr {$bin_size / 1024}] KB)"
puts "INFO: Output: $boot_bin"
puts ""
puts "=========================================="
puts " SD Card Boot Instructions"
puts "=========================================="
puts "1. Format an SD card as FAT32"
puts "2. Copy BOOT.BIN to the root of the SD card:"
puts "     cp $boot_bin /media/<sdcard>/"
puts "3. Insert SD card into the Zybo"
puts "4. Set JP5 jumper to SD position"
puts "5. Power on the board"
puts "6. LEDs should show a chaser pattern"
puts "7. Connect serial (115200/8N1) to see UART messages"
puts "=========================================="
