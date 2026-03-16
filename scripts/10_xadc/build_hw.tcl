# build_hw.tcl — Build Zynq PS + XADC Wizard + AXI GPIO hardware design
# Creates a block design with PS7, XADC Wizard (temp/voltage + aux channels), AXI GPIO (LEDs)
#
# Run: vivado -mode batch -source scripts/10_xadc/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/10_xadc"
set proj_dir "$out_dir/vivado_proj"
set proj_name "xadc_hw"

puts "============================================"
puts " Building: 10_xadc (PS + XADC + GPIO LEDs)"
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

# Enable M_AXI_GP0 and FCLK_CLK0 at 100MHz
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells ps7]

# ============================================
# Add XADC Wizard IP
# ============================================
puts "\n>>> Adding XADC Wizard IP..."
create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc_wiz_0

# Configure XADC:
#   - AXI4Lite interface
#   - Channel sequencer mode
#   - Enable on-chip sensors: temperature, VCCINT, VCCAUX
#   - Enable auxiliary channels: VAUX6, VAUX7, VAUX14, VAUX15 (Pmod JA)
#   - Continuous sequencer mode
set_property -dict [list \
    CONFIG.INTERFACE_SELECTION {Enable_AXI} \
    CONFIG.DCLK_FREQUENCY {100} \
    CONFIG.ADC_CONVERSION_RATE {1000} \
    CONFIG.XADC_STARUP_SELECTION {channel_sequencer} \
    CONFIG.CHANNEL_ENABLE_TEMPERATURE {true} \
    CONFIG.CHANNEL_ENABLE_VCCINT {true} \
    CONFIG.CHANNEL_ENABLE_VCCAUX {true} \
    CONFIG.CHANNEL_ENABLE_VP_VN {false} \
    CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6 {false} \
    CONFIG.CHANNEL_ENABLE_VAUXP7_VAUXN7 {false} \
    CONFIG.CHANNEL_ENABLE_VAUXP14_VAUXN14 {false} \
    CONFIG.CHANNEL_ENABLE_VAUXP15_VAUXN15 {false} \
    CONFIG.SEQUENCER_MODE {Continuous} \
    CONFIG.ENABLE_EXTERNAL_MUX {false} \
    CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
    CONFIG.ENABLE_RESET {false} \
] [get_bd_cells xadc_wiz_0]

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
# Run connection automation
# ============================================
puts "\n>>> Running connection automation..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins xadc_wiz_0/s_axi_lite]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "/ps7_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# Make GPIO port external with meaningful name
puts "\n>>> Making GPIO LED port external..."
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_leds [get_bd_intf_ports GPIO_0]

# XADC uses internal sensors only (temp, VCCINT, VCCAUX) — no external analog pins
# This avoids Bank 35 I/O standard conflicts with LEDs

# Validate and save
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add Constraints
# ============================================
puts "\n>>> Adding XDC constraints..."
add_files -fileset constrs_1 "$proj_root/constrs/10_xadc/zybo_xadc.xdc"

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
puts " XSA: output/10_xadc/system.xsa"
puts " BIT: output/10_xadc/system.bit"
puts "============================================"

close_project
