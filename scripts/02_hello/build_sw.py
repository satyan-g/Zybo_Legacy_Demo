# build_sw.py — Build bare-metal Hello World for Zynq using Vitis 2024.2
# Run: ./scripts/vitis_reset_workspace.sh 02_hello

import vitis
import os
import shutil

script_dir = os.path.dirname(os.path.abspath(__file__))
proj_root = os.path.normpath(os.path.join(script_dir, "../.."))
out_dir = os.path.join(proj_root, "output/02_hello")
xsa_file = os.path.join(out_dir, "system.xsa")
sw_dir = os.path.join(out_dir, "vitis_workspace")
app_src = os.path.join(proj_root, "sw/02_hello/hello.c")

print("=" * 44)
print(" Building: 02_hello Software")
print(f" XSA: {xsa_file}")
print("=" * 44)

if not os.path.exists(xsa_file):
    print(f"ERROR: XSA not found at {xsa_file}")
    exit(1)

# Create Vitis client
client = vitis.create_client()
client.set_workspace(sw_dir)

# Create platform from XSA
print("\n>>> Creating platform from XSA...")
platform = client.create_platform_component(
    name="zybo_platform",
    hw_design=xsa_file,
    os="standalone",
    cpu="ps7_cortexa9_0",
    no_boot_bsp=True
)

# Build platform
print("\n>>> Building platform...")
platform = client.get_component(name="zybo_platform")
platform.build()

# Create application
print("\n>>> Creating Hello World application...")
app = client.create_app_component(
    name="hello",
    platform=os.path.join(sw_dir, "zybo_platform/export/zybo_platform/zybo_platform.xpfm"),
    domain="standalone_ps7_cortexa9_0"
)

# Replace the default source with our hello.c
app_src_dir = os.path.join(sw_dir, "hello/src")
os.makedirs(app_src_dir, exist_ok=True)

# Remove default sources if any
for f in os.listdir(app_src_dir):
    if f.endswith(".c") or f.endswith(".h"):
        os.remove(os.path.join(app_src_dir, f))

# Copy our source
shutil.copy2(app_src, os.path.join(app_src_dir, "hello.c"))

# Build application
print("\n>>> Building application...")
app = client.get_component(name="hello")
app.build()

# Find and copy ELF to output
print("\n>>> Locating ELF...")
found_elf = False
for root, dirs, files in os.walk(sw_dir):
    for f in files:
        if f == "hello.elf":
            found = os.path.join(root, f)
            shutil.copy2(found, os.path.join(out_dir, "hello.elf"))
            print(f"Found ELF: {found}")
            found_elf = True
            break
    if found_elf:
        break

if found_elf:
    print("\n" + "=" * 44)
    print(" Software build complete!")
    print(" ELF: output/02_hello/hello.elf")
    print("=" * 44)
else:
    print("ERROR: hello.elf not found in workspace")
    exit(1)
