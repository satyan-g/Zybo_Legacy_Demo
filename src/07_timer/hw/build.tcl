# build_hw.tcl — Build Zynq PS + AXI Timer + AXI GPIO hardware design
# Creates a block design with PS7, AXI Timer (interrupt-driven), and AXI GPIO (LEDs)
#
# Run: vivado -mode batch -source scripts/07_timer/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir [lindex $argv 0]
if {$out_dir eq ""} { puts "ERROR: out_dir argument required. Run via build_hw.sh"; exit 1 }
set proj_dir "$out_dir/vivado_proj"
set proj_name "timer_hw"

puts "============================================"
puts " Building: 07_timer (PS + AXI Timer + GPIO)"
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

# Enable M_AXI_GP0, FCLK_CLK0 at 100MHz, and fabric interrupts
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
] [get_bd_cells ps7]

# ============================================
# Add AXI Timer IP
# ============================================
puts "\n>>> Adding AXI Timer IP..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0

# ============================================
# Add AXI GPIO IP — single channel, 4-bit output (LEDs)
# ============================================
puts "\n>>> Adding AXI GPIO IP (4-bit LEDs)..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0

set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_IS_DUAL {0} \
] [get_bd_cells axi_gpio_0]

# ============================================
# Add Concat block for interrupts → IRQ_F2P
# ============================================
puts "\n>>> Adding xlconcat for interrupts..."
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0

set_property -dict [list \
    CONFIG.NUM_PORTS {1} \
] [get_bd_cells xlconcat_0]

# Connect timer interrupt to concat input
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins xlconcat_0/In0]

# Connect concat output to PS IRQ_F2P
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins ps7/IRQ_F2P]

# ============================================
# Run connection automation
# ============================================
puts "\n>>> Running connection automation..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_timer_0/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "/ps7_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# Make GPIO port external with meaningful name
puts "\n>>> Making GPIO LED port external..."
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_leds [get_bd_intf_ports GPIO_0]

# Validate and save
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add Constraints
# ============================================
puts "\n>>> Adding XDC constraints..."
add_files -fileset constrs_1 "$proj_root/src/07_timer/hw/zybo_timer.xdc"

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
puts " XSA: output/07_timer/system.xsa"
puts " BIT: output/07_timer/system.bit"
puts "============================================"

close_project
