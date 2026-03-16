# build_sw.py — Build bare-metal SD boot demo for Zynq using Vitis 2024.2
# Run: vitis -s scripts/13_sd_boot/build_sw.py
#
# Builds the user app. FSBL is generated separately via platform with boot BSP.

import vitis
import os
import shutil

script_dir = os.path.dirname(os.path.abspath(__file__))
proj_root = os.path.normpath(os.path.join(script_dir, "../.."))
out_dir = os.path.join(proj_root, "output/13_sd_boot")
xsa_file = os.path.join(out_dir, "system.xsa")
sw_dir = os.path.join(out_dir, "vitis_workspace")
app_src = os.path.join(proj_root, "sw/13_sd_boot/sd_boot_demo.c")

APP_NAME = "sd_boot_demo"

print("=" * 48)
print(" Building: 13_sd_boot Software")
print(f" XSA: {xsa_file}")
print("=" * 48)

if not os.path.exists(xsa_file):
    print(f"ERROR: XSA not found at {xsa_file}")
    exit(1)

client = vitis.create_client()
client.set_workspace(sw_dir)

# Create platform — try with boot BSP first (generates FSBL automatically)
print("\n>>> Creating platform from XSA (with boot BSP for FSBL)...")
try:
    platform = client.create_platform_component(
        name="zybo_platform",
        hw_design=xsa_file,
        os="standalone",
        cpu="ps7_cortexa9_0",
        no_boot_bsp=False
    )
except Exception as e:
    print(f"  Boot BSP failed: {e}")
    print("  Retrying without boot BSP...")
    platform = client.create_platform_component(
        name="zybo_platform",
        hw_design=xsa_file,
        os="standalone",
        cpu="ps7_cortexa9_0",
        no_boot_bsp=True
    )

print("\n>>> Building platform...")
platform = client.get_component(name="zybo_platform")
platform.build()

xpfm_path = os.path.join(sw_dir, "zybo_platform/export/zybo_platform/zybo_platform.xpfm")

# Look for auto-generated FSBL ELF
print("\n>>> Looking for auto-generated FSBL...")
found_fsbl = False
for root, dirs, files in os.walk(sw_dir):
    for f in files:
        if "fsbl" in f.lower() and f.endswith(".elf"):
            found = os.path.join(root, f)
            shutil.copy2(found, os.path.join(out_dir, "fsbl.elf"))
            print(f"Found FSBL ELF: {found}")
            found_fsbl = True
            break
    if found_fsbl:
        break

if not found_fsbl:
    print("  No auto-generated FSBL found. JTAG deploy will still work.")
    print("  BOOT.BIN generation will need FSBL built separately.")

# Create user application
print(f"\n>>> Creating {APP_NAME} application...")
app = client.create_app_component(
    name=APP_NAME,
    platform=xpfm_path,
    domain="standalone_ps7_cortexa9_0"
)

app_src_dir = os.path.join(sw_dir, f"{APP_NAME}/src")
os.makedirs(app_src_dir, exist_ok=True)

for f in os.listdir(app_src_dir):
    if f.endswith(".c") or f.endswith(".h"):
        os.remove(os.path.join(app_src_dir, f))

shutil.copy2(app_src, os.path.join(app_src_dir, "sd_boot_demo.c"))

print("\n>>> Building application...")
app = client.get_component(name=APP_NAME)
app.build()

print("\n>>> Locating app ELF...")
found_elf = False
for root, dirs, files in os.walk(sw_dir):
    for f in files:
        if f == f"{APP_NAME}.elf":
            found = os.path.join(root, f)
            shutil.copy2(found, os.path.join(out_dir, f"{APP_NAME}.elf"))
            print(f"Found app ELF: {found}")
            found_elf = True
            break
    if found_elf:
        break

if found_elf:
    print("\n" + "=" * 48)
    print(" Software build complete!")
    print(f" App:  output/13_sd_boot/{APP_NAME}.elf")
    if found_fsbl:
        print(f" FSBL: output/13_sd_boot/fsbl.elf")
    print("=" * 48)
else:
    print(f"ERROR: {APP_NAME}.elf not found in workspace")
    exit(1)
