# build_hw.tcl — Build Zynq PS + AXI GPIO hardware design
# Creates a block design with PS7 + AXI GPIO (dual channel: LEDs out, SW+BTN in)
#
# Run: vivado -mode batch -source scripts/05_axi_gpio/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }
set proj_dir "$out_dir/vivado_proj"
set proj_name "axi_gpio_hw"

puts "============================================"
puts " Building: 05_axi_gpio (PS + AXI GPIO)"
puts " Project root: $proj_root"
puts "============================================"

file mkdir $out_dir

# Clean previous project
if {[file exists $proj_dir]} {
    file delete -force $proj_dir
}

# Target part — Original Zybo
set part xc7z010clg400-1

# Create a managed project (needed for block design + launch_runs)
create_project $proj_name $proj_dir -part $part
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]

# ============================================
# Create Block Design
# ============================================
puts "\n>>> Creating Block Design..."
create_bd_design "system"

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Apply Digilent's official ZYBO preset (configures DDR, clocks, MIO, UART)
source "$proj_root/scripts/zybo_preset.tcl"
set_property -dict [apply_preset IPINST] [get_bd_cells ps7]

# PS7 needs M_AXI_GP0 enabled (default), ensure FCLK_CLK0 is on
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells ps7]

# Add AXI GPIO IP — dual channel
# Channel 1: 4-bit output (LEDs)
# Channel 2: 8-bit input (switches + buttons)
puts "\n>>> Adding AXI GPIO IP (dual channel)..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0

set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_IS_DUAL {1} \
    CONFIG.C_GPIO2_WIDTH {8} \
    CONFIG.C_ALL_INPUTS_2 {1} \
] [get_bd_cells axi_gpio_0]

# Run connection automation — wires up AXI interconnect, clocks, resets
puts "\n>>> Running connection automation..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# Make GPIO ports external with meaningful names
puts "\n>>> Making GPIO ports external..."
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_leds [get_bd_intf_ports GPIO_0]

make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO2]
set_property name gpio_sw_btn [get_bd_intf_ports GPIO2_0]

# Validate and save
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add Constraints
# ============================================
puts "\n>>> Adding XDC constraints..."
add_files -fileset constrs_1 "$proj_root/src/05_axi_gpio/hw/zybo_axi_gpio.xdc"

# ============================================
# Generate output products and HDL wrapper
# ============================================
puts "\n>>> Generating block design output products..."
generate_target all [get_files system.bd]

# Create HDL wrapper
make_wrapper -files [get_files system.bd] -top
add_files -norecurse $proj_dir/${proj_name}.gen/sources_1/bd/system/hdl/system_wrapper.v

# ============================================
# Synthesis
# ============================================
puts "\n>>> Running Synthesis..."
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 6
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    exit 1
}
puts "Synthesis complete."

# ============================================
# Implementation
# ============================================
puts "\n>>> Running Implementation..."
launch_runs impl_1 -jobs 6
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed"
    exit 1
}
puts "Implementation complete."

# ============================================
# Bitstream
# ============================================
puts "\n>>> Generating Bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1
puts "Bitstream generated."

# ============================================
# Export Hardware (.xsa)
# ============================================
puts "\n>>> Exporting Hardware..."
write_hw_platform -fixed -include_bit -force "$out_dir/system.xsa"

# Also copy bitstream to output
file copy -force "$proj_dir/${proj_name}.runs/impl_1/system_wrapper.bit" "$out_dir/system.bit"

puts "\n============================================"
puts " Hardware build complete!"
puts " XSA: output/05_axi_gpio/system.xsa"
puts " BIT: output/05_axi_gpio/system.bit"
puts "============================================"

close_project
