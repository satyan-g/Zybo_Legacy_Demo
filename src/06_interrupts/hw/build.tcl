# build_hw.tcl — Build Zynq PS + AXI GPIO interrupt demo hardware
# AXI GPIO dual-channel: ch1=LEDs (output), ch2=buttons (input, interrupts enabled)
# GPIO interrupt routed to PS via IRQ_F2P
#
# Run: vivado -mode batch -source scripts/06_interrupts/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }
set proj_dir "$out_dir/vivado_proj"

puts "============================================"
puts " Building: 06_interrupts (AXI GPIO + IRQ)"
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
create_project interrupt_hw $proj_dir -part $part
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

# Enable M_AXI_GP0 (needed for AXI GPIO) and fabric interrupts
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
] [get_bd_cells ps7]

# Make external connections for DDR and FIXED_IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

# ============================================
# Add AXI GPIO (dual channel, interrupts)
# ============================================
puts "\n>>> Adding AXI GPIO IP..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0

# Configure: dual channel, ch1=4-bit output (LEDs), ch2=4-bit input (buttons), interrupts on
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_IS_DUAL {1} \
    CONFIG.C_GPIO2_WIDTH {4} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_INTERRUPT_PRESENT {1} \
] [get_bd_cells axi_gpio_0]

# Use apply_bd_automation for AXI interconnect wiring
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" Clk "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# ============================================
# Connect interrupt: GPIO ip2intc_irpt → PS IRQ_F2P
# ============================================
puts "\n>>> Connecting interrupt..."
connect_bd_net [get_bd_pins axi_gpio_0/ip2intc_irpt] [get_bd_pins ps7/IRQ_F2P]

# ============================================
# Make GPIO ports external
# ============================================
puts "\n>>> Making GPIO ports external..."
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_leds [get_bd_intf_ports GPIO_0]

make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO2]
set_property name gpio_btns [get_bd_intf_ports GPIO2_0]

# Validate and save
validate_bd_design
save_bd_design

# ============================================
# Add constraints
# ============================================
puts "\n>>> Adding constraint file..."
add_files -fileset constrs_1 "$proj_root/src/06_interrupts/hw/zybo_interrupts.xdc"

# ============================================
# Generate output products and HDL wrapper
# ============================================
puts "\n>>> Generating block design output products..."
generate_target all [get_files system.bd]

# Create HDL wrapper
make_wrapper -files [get_files system.bd] -top
add_files -norecurse $proj_dir/interrupt_hw.gen/sources_1/bd/system/hdl/system_wrapper.v

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
file copy -force "$proj_dir/interrupt_hw.runs/impl_1/system_wrapper.bit" "$out_dir/system.bit"

puts "\n============================================"
puts " Hardware build complete!"
puts " XSA: output/06_interrupts/system.xsa"
puts " BIT: output/06_interrupts/system.bit"
puts "============================================"

close_project
