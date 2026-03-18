# build_hw.tcl — Vivado TCL script for 14_qspi_boot
# Builds PS + AXI GPIO block design, synthesizes, implements, exports XSA
# Usage: vivado -mode batch -source scripts/14_qspi_boot/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir    [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }
set proj_name  "qspi_boot"
set proj_dir   "$out_dir/${proj_name}_project"
set part       "xc7z010clg400-1"
set board      "digilentinc.com:zybo:part0:2.0"

# Create output directory
file mkdir $out_dir

# Remove previous project if it exists
if {[file exists $proj_dir]} {
    puts "INFO: Removing previous project directory..."
    file delete -force $proj_dir
}

# -----------------------------------------------------------------------------
# Create managed project
# -----------------------------------------------------------------------------
puts "INFO: Creating project..."
create_project $proj_name $proj_dir -part $part
set_property board_part $board [current_project]

# Add constraints
add_files -fileset constrs_1 "$proj_root/src/14_qspi_boot/hw/zybo_qspi_boot.xdc"

# -----------------------------------------------------------------------------
# Create block design
# -----------------------------------------------------------------------------
puts "INFO: Creating block design..."
create_bd_design "system"

# Add PS7
set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} $ps7

# Enable M_AXI_GP0 (QSPI is already enabled by board preset)
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
] $ps7

# Add AXI GPIO for LEDs
set gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0]
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
] $gpio

# Make GPIO external
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name leds [get_bd_intf_ports GPIO_0]

# Run connection automation for AXI
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# Validate and save
regenerate_bd_layout
validate_bd_design
save_bd_design

# Create HDL wrapper
set wrapper [make_wrapper -files [get_files system.bd] -top]
add_files -norecurse $wrapper
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

# -----------------------------------------------------------------------------
# Synthesize, implement, generate bitstream
# -----------------------------------------------------------------------------
puts "INFO: Launching synthesis..."
launch_runs synth_1 -jobs 6
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "INFO: Synthesis complete."

puts "INFO: Launching implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
    puts "ERROR: Implementation/bitstream failed!"
    exit 1
}
puts "INFO: Bitstream generation complete."

# -----------------------------------------------------------------------------
# Export hardware (XSA) with bitstream
# -----------------------------------------------------------------------------
puts "INFO: Exporting XSA..."
write_hw_platform -fixed -include_bit -force "$out_dir/system.xsa"
puts "INFO: XSA exported to $out_dir/system.xsa"

# Also copy bitstream to output
file copy -force "$proj_dir/${proj_name}.runs/impl_1/system_wrapper.bit" "$out_dir/system.bit"
puts "INFO: Bitstream copied to $out_dir/system.bit"

puts "INFO: Hardware build complete!"
puts "INFO: Next step: run build_sw.tcl with XSCT"
