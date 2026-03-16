# build_hw.tcl — Build Zynq PS + AXI GPIO hardware for lwIP Ethernet echo server
# Ethernet is on PS MIO (GEM0), AXI GPIO drives LEDs for status indication
#
# Run: vivado -mode batch -source scripts/12_ethernet/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/12_ethernet"
set proj_dir "$out_dir/vivado_proj"
set proj_name "ethernet_hw"

puts "============================================"
puts " Building: 12_ethernet (PS GEM + AXI GPIO)"
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

# ------------------------------------------
# 1. Zynq Processing System
# ------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Apply Digilent's official ZYBO preset (configures DDR, clocks, MIO, UART, ENET0)
source "$proj_root/scripts/zybo_preset.tcl"
set_property -dict [apply_preset IPINST] [get_bd_cells ps7]

# Ensure ENET0 is enabled (already in preset on MIO 16..27, MDIO on MIO 52..53)
# Enable M_AXI_GP0 for AXI GPIO access
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
    CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
    CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
] [get_bd_cells ps7]

# ------------------------------------------
# 2. AXI GPIO for LEDs (link/activity status)
# ------------------------------------------
puts "\n>>> Adding AXI GPIO for LEDs..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0

set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
] [get_bd_cells axi_gpio_0]

# ------------------------------------------
# 3. Connections — PS external pins
# ------------------------------------------
puts "\n>>> Running PS automation (DDR, FIXED_IO)..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

# ------------------------------------------
# 4. AXI lite connection: PS M_AXI_GP0 → GPIO S_AXI
# ------------------------------------------
puts "\n>>> Connecting AXI GPIO to PS GP0..."
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

# ------------------------------------------
# 5. Make GPIO external (LEDs)
# ------------------------------------------
puts "\n>>> Making GPIO pins external..."
make_bd_intf_pins_external [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_leds [get_bd_intf_ports GPIO_0]

# ------------------------------------------
# 6. Validate and save
# ------------------------------------------
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add constraints
# ============================================
puts "\n>>> Adding constraint files..."
add_files -fileset constrs_1 "$proj_root/constrs/12_ethernet/zybo_ethernet.xdc"

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
puts " XSA: output/12_ethernet/system.xsa"
puts " BIT: output/12_ethernet/system.bit"
puts "============================================"

close_project
