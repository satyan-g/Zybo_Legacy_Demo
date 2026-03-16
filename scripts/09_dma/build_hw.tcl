# build_hw.tcl — Build Zynq PS + AXI DMA loopback hardware design
# DMA transfers data from DDR through direct loopback back to DDR
#
# Run: vivado -mode batch -source scripts/09_dma/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/09_dma"
set proj_dir "$out_dir/vivado_proj"
set proj_name "dma_hw"

puts "============================================"
puts " Building: 09_dma (PS + AXI DMA Loopback)"
puts " Project root: $proj_root"
puts "============================================"

file mkdir $out_dir

if {[file exists $proj_dir]} {
    file delete -force $proj_dir
}

set part xc7z010clg400-1

create_project $proj_name $proj_dir -part $part
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]

# ============================================
# Create Block Design
# ============================================
puts "\n>>> Creating Block Design..."
create_bd_design "system"

# 1. Zynq PS
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7
source "$proj_root/scripts/zybo_preset.tcl"
set_property -dict [apply_preset IPINST] [get_bd_cells ps7]

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells ps7]

# 2. AXI DMA — Simple mode
puts "\n>>> Adding AXI DMA IP..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list \
    CONFIG.c_include_sg {0} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {23} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
] [get_bd_cells axi_dma_0]

# 3. PS automation (DDR, FIXED_IO)
puts "\n>>> Running PS automation..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

# 4. Connect DMA control port (S_AXI_LITE) to PS GP0
puts "\n>>> Connecting DMA control via GP0..."
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

# 5. Connect BOTH DMA memory masters to HP0 in one automation call
#    by running automation for each master sequentially, reusing the interconnect
puts "\n>>> Connecting DMA MM2S memory port to HP0..."
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/axi_dma_0/M_AXI_MM2S" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins ps7/S_AXI_HP0]

puts "\n>>> Connecting DMA S2MM memory port to HP0..."
# Run automation for all remaining unconnected interfaces
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Slave "/ps7/S_AXI_HP0" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]

# 6. Direct stream loopback: MM2S → S2MM
puts "\n>>> Connecting DMA streams directly (loopback)..."
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] \
                    [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

# 7. Assign all addresses and verify
puts "\n>>> Assigning addresses..."
assign_bd_address

# Debug: print all address segments
puts "\n>>> Address segments:"
foreach seg [get_bd_addr_segs] {
    puts "  $seg"
}

# Ensure both DMA masters can reach DDR via HP0
# If any segments are excluded, include them
foreach space {/axi_dma_0/Data_MM2S /axi_dma_0/Data_S2MM} {
    set segs [get_bd_addr_segs -of_objects [get_bd_addr_spaces $space]]
    puts "  Address space $space -> $segs"
    if {$segs eq ""} {
        puts "  WARNING: No segments for $space — creating manually"
        create_bd_addr_seg -range 0x20000000 -offset 0x00000000 \
            [get_bd_addr_spaces $space] \
            [get_bd_addr_segs ps7/S_AXI_HP0/HP0_DDR_LOWOCM] \
            SEG_ps7_HP0_DDR_LOWOCM_${space}
    }
}

# 8. Validate
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Generate, synth, impl, bitstream, export
# ============================================
puts "\n>>> Generating block design output products..."
generate_target all [get_files system.bd]

make_wrapper -files [get_files system.bd] -top
add_files -norecurse $proj_dir/${proj_name}.gen/sources_1/bd/system/hdl/system_wrapper.v

puts "\n>>> Running Synthesis..."
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 6
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    exit 1
}

puts "\n>>> Running Implementation..."
launch_runs impl_1 -jobs 6
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed"
    exit 1
}

puts "\n>>> Generating Bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1

puts "\n>>> Exporting Hardware..."
write_hw_platform -fixed -include_bit -force "$out_dir/system.xsa"
file copy -force "$proj_dir/${proj_name}.runs/impl_1/system_wrapper.bit" "$out_dir/system.bit"

puts "\n============================================"
puts " Hardware build complete!"
puts " XSA: output/09_dma/system.xsa"
puts " BIT: output/09_dma/system.bit"
puts "============================================"

close_project
