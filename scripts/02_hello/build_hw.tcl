# build_hw.tcl — Build Zynq PS hardware design for Hello World
# Creates a minimal Zynq block design with UART, builds bitstream, exports XSA
#
# Run: vivado -mode batch -source scripts/02_hello/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/02_hello"
set proj_dir "$out_dir/vivado_proj"

puts "============================================"
puts " Building: 02_hello (Zynq PS Hello World)"
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
create_project hello_hw $proj_dir -part $part
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]

# ============================================
# Create Block Design
# ============================================
puts "\n>>> Creating Block Design..."
create_bd_design "system"

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Apply Digilent's official ZYBO preset (configures DDR, clocks, MIO, UART properly)
source "$proj_root/scripts/zybo_preset.tcl"
set_property -dict [apply_preset IPINST] [get_bd_cells ps7]

# Disable GP0 AXI port (not needed for PS-only design)
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {0} \
] [get_bd_cells ps7]

# Make external connections for DDR and FIXED_IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 1} [get_bd_cells ps7]

# Validate and save
validate_bd_design
save_bd_design

# ============================================
# Generate output products and HDL wrapper
# ============================================
puts "\n>>> Generating block design output products..."
generate_target all [get_files system.bd]

# Create HDL wrapper
make_wrapper -files [get_files system.bd] -top
add_files -norecurse $proj_dir/hello_hw.gen/sources_1/bd/system/hdl/system_wrapper.v

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
file copy -force "$proj_dir/hello_hw.runs/impl_1/system_wrapper.bit" "$out_dir/system.bit"

puts "\n============================================"
puts " Hardware build complete!"
puts " XSA: output/02_hello/system.xsa"
puts " BIT: output/02_hello/system.bit"
puts "============================================"

close_project
