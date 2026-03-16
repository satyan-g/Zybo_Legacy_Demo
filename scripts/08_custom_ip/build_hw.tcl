# build_hw.tcl — Build Zynq PS + custom AXI4-Lite slave hardware design
# Custom RTL module integrated as a block design module reference
#
# Run: vivado -mode batch -source scripts/08_custom_ip/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/08_custom_ip"
set proj_dir "$out_dir/vivado_proj"
set proj_name "custom_ip_hw"

puts "============================================"
puts " Building: 08_custom_ip (PS + Custom AXI Slave)"
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
# Add custom RTL source to the project
# ============================================
puts "\n>>> Adding custom AXI slave RTL..."
add_files -norecurse "$proj_root/src/08_custom_ip/custom_axi_slave.v"
update_compile_order -fileset sources_1

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

# PS7 needs M_AXI_GP0 enabled, ensure FCLK_CLK0 is on
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells ps7]

# ============================================
# Add custom AXI slave as module reference
# ============================================
puts "\n>>> Adding custom AXI slave to block design..."
create_bd_cell -type module -reference custom_axi_slave custom_ip_0

# ============================================
# PS7 automation — creates FIXED_IO and DDR external ports
# ============================================
puts "\n>>> Running PS7 connection automation..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

# ============================================
# Add AXI Interconnect (1 master, 1 slave)
# ============================================
puts "\n>>> Adding AXI Interconnect..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property CONFIG.NUM_MI {1} [get_bd_cells axi_interconnect_0]

# ============================================
# Connect clocks and resets
# ============================================
puts "\n>>> Connecting clocks and resets..."

# PS7 FCLK_CLK0 is our system clock
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins ps7/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins custom_ip_0/S_AXI_ACLK]

# Add a proc_sys_reset for clean reset generation
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_100M
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins rst_ps7_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_pins rst_ps7_100M/ext_reset_in]

# Connect resets
connect_bd_net [get_bd_pins rst_ps7_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_100M/peripheral_aresetn] [get_bd_pins custom_ip_0/S_AXI_ARESETN]

# ============================================
# Connect AXI interfaces
# ============================================
puts "\n>>> Connecting AXI interfaces..."

# PS7 M_AXI_GP0 -> Interconnect S00_AXI
connect_bd_intf_net [get_bd_intf_pins ps7/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# Interconnect M00_AXI -> Custom IP S_AXI
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins custom_ip_0/S_AXI]

# ============================================
# Assign address: 0x43C00000, 64K range
# ============================================
puts "\n>>> Assigning address space..."
assign_bd_address
set_property offset 0x43C00000 [get_bd_addr_segs {ps7/Data/SEG_custom_ip_0_reg0}]
set_property range 64K [get_bd_addr_segs {ps7/Data/SEG_custom_ip_0_reg0}]

# ============================================
# Make LED and switch ports external
# ============================================
puts "\n>>> Making LED and switch ports external..."
make_bd_pins_external [get_bd_pins custom_ip_0/leds]
make_bd_pins_external [get_bd_pins custom_ip_0/switches]

# Rename external ports to clean names
set_property name leds [get_bd_ports leds_0]
set_property name switches [get_bd_ports switches_0]

# Validate and save
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add Constraints
# ============================================
puts "\n>>> Adding XDC constraints..."
add_files -fileset constrs_1 "$proj_root/constrs/08_custom_ip/zybo_custom_ip.xdc"

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
puts " XSA: output/08_custom_ip/system.xsa"
puts " BIT: output/08_custom_ip/system.bit"
puts "============================================"

close_project
