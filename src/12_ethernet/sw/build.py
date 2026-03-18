# build_sw.py — Build bare-metal lwIP ethernet demo for Zynq using Vitis 2024.2
# Run: vitis -s scripts/12_ethernet/build_sw.py
#
# SPECIAL: This project requires lwip220 library in the BSP.
# We use platform.get_domain().set_lib() to add it before building.

import vitis
import os
import shutil

script_dir = os.path.dirname(os.path.abspath(__file__))
proj_root = os.path.normpath(os.path.join(script_dir, "../../.."))
_base = os.environ.get('BUILD_OUT_DIR')
if not _base:
    raise RuntimeError("BUILD_OUT_DIR not set — run via scripts/build_sw.sh")
hw_dir = os.path.join(_base, "hw")
out_dir = os.path.join(_base, "sw")
xsa_file = os.path.join(hw_dir, "system.xsa")
sw_dir = os.path.join(out_dir, "vitis_workspace")
app_src = os.path.join(proj_root, "src/12_ethernet/sw/ethernet_demo.c")

APP_NAME = "ethernet_demo"

print("=" * 48)
print(" Building: 12_ethernet Software (lwIP Echo)")
print(f" XSA: {xsa_file}")
print("=" * 48)

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

# Add lwip220 library to BSP via domain.set_lib()
print("\n>>> Adding lwip220 library to BSP...")
platform = client.get_component(name="zybo_platform")
domain = platform.get_domain(name="standalone_ps7_cortexa9_0")

# List available libraries for reference
print("  Available libs:", domain.get_applicable_libs())

# Add lwip220
domain.set_lib(lib_name="lwip220")
print("  Added lwip220")

# Verify
print("  Configured libs:", domain.get_libs())

# List available lwIP params for reference, then configure
print("\n>>> Available lwIP params:")
try:
    params = domain.list_params(option="lib", lib_name="lwip220")
    print(f"  {params}")
except Exception as e:
    print(f"  Could not list params: {e}")

# Try to enable DHCP — skip if param names don't match
print("\n>>> Configuring lwIP settings...")
for param, value in [("lwip220_api_mode", "RAW_API"), ("lwip220_dhcp", "true"), ("lwip220_no_sys_no_timers", "false")]:
    try:
        domain.set_config(option="lib", param=param, value=value, lib_name="lwip220")
        print(f"  Set {param} = {value}")
    except Exception as e:
        print(f"  Skipping {param}: {e}")

# Build platform (generates BSP with lwIP)
print("\n>>> Building platform (BSP + lwIP)...")
platform.build()

# Create application
print(f"\n>>> Creating {APP_NAME} application...")
app = client.create_app_component(
    name=APP_NAME,
    platform=os.path.join(sw_dir, "zybo_platform/export/zybo_platform/zybo_platform.xpfm"),
    domain="standalone_ps7_cortexa9_0"
)

# Replace source
app_src_dir = os.path.join(sw_dir, f"{APP_NAME}/src")
os.makedirs(app_src_dir, exist_ok=True)

for f in os.listdir(app_src_dir):
    if f.endswith(".c") or f.endswith(".h"):
        os.remove(os.path.join(app_src_dir, f))

shutil.copy2(app_src, os.path.join(app_src_dir, "ethernet_demo.c"))

# Build application
print("\n>>> Building application...")
app = client.get_component(name=APP_NAME)
app.build()

# Find and copy ELF
print("\n>>> Locating ELF...")
found_elf = False
for root, dirs, files in os.walk(sw_dir):
    for f in files:
        if f == f"{APP_NAME}.elf":
            found = os.path.join(root, f)
            shutil.copy2(found, os.path.join(out_dir, f"{APP_NAME}.elf"))
            print(f"Found ELF: {found}")
            found_elf = True
            break
    if found_elf:
        break

if found_elf:
    print("\n" + "=" * 48)
    print(" Software build complete!")
    print(f" ELF: output/12_ethernet/{APP_NAME}.elf")
    print("=" * 48)
else:
    print(f"ERROR: {APP_NAME}.elf not found in workspace")
    exit(1)
