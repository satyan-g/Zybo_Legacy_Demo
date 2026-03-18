# build_sw.tcl — Build bare-metal Hello World for Zynq
# Run: xsct scripts/02_hello/build_sw.tcl

set script_dir [file dirname [info script]]
set proj_root [file normalize "$script_dir/../../.."]
set out_dir "$proj_root/output/02_hello"
set xsa_file "$out_dir/system.xsa"
set sw_dir "$out_dir/sw_workspace"
set app_src "$proj_root/sw/02_hello/hello.c"

puts "============================================"
puts " Building: 02_hello Software"
puts " XSA: $xsa_file"
puts "============================================"

if {![file exists $xsa_file]} {
    puts "ERROR: XSA not found at $xsa_file"
    puts "Run the hardware build first."
    exit 1
}

# Clean previous workspace
if {[file exists $sw_dir]} {
    file delete -force $sw_dir
}
file mkdir $sw_dir

# Set workspace
setws $sw_dir

# Create platform from XSA
puts "\n>>> Creating platform from XSA..."
platform create -name "zybo_platform" -hw $xsa_file -proc ps7_cortexa9_0 -os standalone

# Build the platform (generates BSP)
puts "\n>>> Building platform (BSP)..."
platform generate

# Create application
puts "\n>>> Creating Hello World application..."
app create -name "hello" -platform "zybo_platform" -template "Empty Application(C)"

# Copy our source file into the app
file copy -force $app_src "$sw_dir/hello/src/hello.c"

# Build the application
puts "\n>>> Building application..."
app build -name "hello"

# Copy ELF to output
set elf_src "$sw_dir/hello/Debug/hello.elf"
if {[file exists $elf_src]} {
    file copy -force $elf_src "$out_dir/hello.elf"
    puts "\n============================================"
    puts " Software build complete!"
    puts " ELF: output/02_hello/hello.elf"
    puts "============================================"
} else {
    puts "ERROR: ELF not found at $elf_src"
    puts "Check build output for errors."
    exit 1
}
