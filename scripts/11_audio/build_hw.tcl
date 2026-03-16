# build_hw.tcl — Build Zynq PS + I2S audio hardware design
# Block design: PS7 + Clocking Wizard (12.288 MHz MCLK) + AXI IIC + I2S tone gen
#
# Run: vivado -mode batch -source scripts/11_audio/build_hw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../.."]
set out_dir "$proj_root/output/11_audio"
set proj_dir "$out_dir/vivado_proj"
set proj_name "audio_hw"

puts "============================================"
puts " Building: 11_audio (Zynq PS + I2S Audio)"
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
# Add RTL source (i2s_tone_gen) first
# ============================================
puts "\n>>> Adding I2S tone generator RTL..."
add_files -norecurse "$proj_root/src/11_audio/i2s_tone_gen.v"
update_compile_order -fileset sources_1

# ============================================
# Create Block Design
# ============================================
puts "\n>>> Creating Block Design..."
create_bd_design "system"

# --- Zynq PS7 ---
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Apply Digilent's official ZYBO preset (configures DDR, clocks, MIO, UART)
source "$proj_root/scripts/zybo_preset.tcl"
set_property -dict [apply_preset IPINST] [get_bd_cells ps7]

# Enable M_AXI_GP0, FCLK_CLK0 at 100 MHz
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells ps7]

# --- Clocking Wizard: 100 MHz -> 12.288 MHz MCLK ---
puts "\n>>> Adding Clocking Wizard (12.288 MHz MCLK)..."
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0

set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {12.288} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {9.750} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {79.375} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.CLKOUT1_JITTER {290.000} \
    CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
] [get_bd_cells clk_wiz_0]

# --- AXI IIC for SSM2603 codec configuration ---
puts "\n>>> Adding AXI IIC IP..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0

# --- I2S tone generator (RTL module) ---
puts "\n>>> Adding I2S tone generator to block design..."
create_bd_cell -type module -reference i2s_tone_gen i2s_tone_gen_0

# ============================================
# Connection Automation — PS7 + AXI
# ============================================
puts "\n>>> Running connection automation..."

# PS7: DDR, FIXED_IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" Master_Disable 0} [get_bd_cells ps7]

# AXI IIC: connect to PS7 M_AXI_GP0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_iic_0/S_AXI]

# ============================================
# Manual Connections
# ============================================
puts "\n>>> Wiring clocks and tone generator..."

# Clocking wizard input: FCLK_CLK0 (100 MHz)
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]

# I2S tone generator: mclk from clocking wizard
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins i2s_tone_gen_0/mclk]

# I2S tone generator: reset_n from processor system reset (find auto-created name)
set rst_cell [get_bd_cells -filter {VLNV =~ *:proc_sys_reset:*}]
connect_bd_net [get_bd_pins $rst_cell/peripheral_aresetn] [get_bd_pins i2s_tone_gen_0/reset_n]

# ============================================
# Make External Ports
# ============================================
puts "\n>>> Making audio ports external..."

# Create all external ports explicitly with correct names
create_bd_port -dir O ac_bclk
create_bd_port -dir O ac_pblrc
create_bd_port -dir O ac_pbdat
create_bd_port -dir O ac_muten
create_bd_port -dir O ac_mclk
create_bd_port -dir I ac_recdat
create_bd_port -dir I ac_reclrc

# Connect tone gen outputs to external ports
connect_bd_net [get_bd_pins i2s_tone_gen_0/ac_bclk] [get_bd_ports ac_bclk]
connect_bd_net [get_bd_pins i2s_tone_gen_0/ac_pblrc] [get_bd_ports ac_pblrc]
connect_bd_net [get_bd_pins i2s_tone_gen_0/ac_pbdat] [get_bd_ports ac_pbdat]
connect_bd_net [get_bd_pins i2s_tone_gen_0/ac_muten] [get_bd_ports ac_muten]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_ports ac_mclk]

# IIC — make the IIC interface external (creates iic_rtl_* ports)
make_bd_intf_pins_external [get_bd_intf_pins axi_iic_0/IIC]

# Validate and save
puts "\n>>> Validating block design..."
validate_bd_design
save_bd_design

# ============================================
# Add Constraints
# ============================================
puts "\n>>> Adding XDC constraints..."
add_files -fileset constrs_1 "$proj_root/constrs/11_audio/zybo_audio.xdc"

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
puts " XSA: output/11_audio/system.xsa"
puts " BIT: output/11_audio/system.bit"
puts "============================================"

close_project
