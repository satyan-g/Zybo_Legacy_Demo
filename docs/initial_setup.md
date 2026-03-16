# Initial Setup — Digilent Zybo Z7-10 (XC7Z010)

## Board Specs
- **FPGA Part**: xc7z010clg400-1
- **ARM Cores**: Dual Cortex-A9 @ 650 MHz
- **DDR3**: 512 MB
- **USB-JTAG**: Programming + UART serial console
- **User I/O**: 4 LEDs, 4 switches, 4 buttons

---

## Step 1: Install Vivado on Linux Server

Download Vivado ML Edition (free, covers Zynq-7010) from:
https://www.xilinx.com/support/download.html

```bash
# Run the installer (adjust filename to your download)
chmod +x Xilinx_Unified_*.bin
./Xilinx_Unified_*.bin

# During install:
#   - Choose "Vivado" (not Vitis yet — add it later if needed)
#   - Select "Vivado ML Standard" (free tier)
#   - Under device support, check ONLY "Zynq-7000" to save disk space
#   - Default install path: /tools/Xilinx/Vivado/2024.1 (adjust to version)
```

After install, source the environment:
```bash
# Add to ~/.bashrc
echo 'source /tools/Xilinx/Vivado/2024.1/settings64.sh' >> ~/.bashrc
source ~/.bashrc

# Verify
vivado -version
```

---

## Step 2: Install Digilent Board Files

```bash
git clone https://github.com/Digilent/vivado-boards.git /tmp/vivado-boards

# Find your Vivado install path
VIVADO_DIR=$(dirname $(dirname $(which vivado)))

# Copy board files
cp -r /tmp/vivado-boards/new/board_files/* \
  $VIVADO_DIR/data/boards/board_files/

# Verify zybo board files exist
ls $VIVADO_DIR/data/boards/board_files/ | grep zybo
# Expected output: zybo-z7-10  (and possibly zybo-z7-20)

rm -rf /tmp/vivado-boards
```

---

## Step 3: Install Cable Drivers (for JTAG programming)

```bash
cd $VIVADO_DIR/data/xicom/cable_drivers/lin64/install_script/install_drivers
sudo ./install_drivers

# Add your user to the dialout group (for serial port access)
sudo usermod -aG dialout $USER

# Log out and back in for group change to take effect
```

---

## Step 4: Install Serial Console Tool

```bash
# picocom (recommended — lightweight)
sudo apt install picocom        # Debian/Ubuntu
sudo dnf install picocom        # Fedora/RHEL

# or minicom
sudo apt install minicom
```

---

## Step 5: Install xpra (GUI Fallback)

```bash
sudo apt install xpra           # Debian/Ubuntu
sudo dnf install xpra           # Fedora/RHEL

# Verify
xpra --version

# On your Mac: install xpra client
# Download from https://github.com/Xpra-org/xpra/releases
# or: brew install --cask xpra
```

### Quick xpra usage
```bash
# On server — start a detachable Vivado GUI session
xpra start :100 --start="vivado"

# On Mac — connect
xpra attach ssh://user@server/100

# Disconnect anytime (Vivado keeps running on server)
# Reconnect later with the same attach command

# Stop session when done
xpra stop :100
```

---

## Step 6: tmux Session Layout

```bash
# Install tmux if not present
sudo apt install tmux           # Debian/Ubuntu

# Create project session
tmux new-session -s zynq -c ~/Projects/Cognito/LPU

# Suggested pane layout:
#   Ctrl-b %    → split vertical
#   Ctrl-b "    → split horizontal
#
# ┌──────────────────┬───────────────────┐
# │ editor (nvim)    │ build output      │
# ├──────────────────┼───────────────────┤
# │ shell (git, ls)  │ serial console    │
# └──────────────────┴───────────────────┘
```

---

## Step 7: Connect the Zybo Board

Plug the Zybo into the Linux server via micro-USB (J12 PROG/UART port).

```bash
# Verify USB connection
lsusb | grep -i digilent
# Expected: "Digilent" device listed

# Find serial port
ls /dev/ttyUSB*
# Typically /dev/ttyUSB0 or /dev/ttyUSB1

# Open serial console (115200 baud, 8N1)
picocom -b 115200 /dev/ttyUSB0
# Exit picocom: Ctrl-a Ctrl-x
```

---

## Step 8: Verify Everything Works

Run these commands and confirm each succeeds:

```bash
# 1. Vivado version
vivado -version
# Should print version info

# 2. Board files present
ls $(dirname $(dirname $(which vivado)))/data/boards/board_files/ | grep zybo
# Should list zybo-z7-10

# 3. xpra available
xpra --version

# 4. Board connected
lsusb | grep -i digilent

# 5. Serial port accessible
ls /dev/ttyUSB*

# 6. Test Vivado can target the right part (quick TCL check)
vivado -mode batch -nojournal -nolog -tclargs <<'EOF'
puts "Vivado [version -short]"
puts "Target part: xc7z010clg400-1"
puts "Environment OK"
exit
EOF
```

---

## Step 9: Clone and Set Up the Project

```bash
cd ~/Projects/Cognito/LPU

# Create project directories
mkdir -p src constrs scripts sw ip sim output

# Verify structure
find . -type d | sort
# Should show:
# .
# ./constrs
# ./docs
# ./ip
# ./output
# ./scripts
# ./sim
# ./src
# ./sw
```

---

## What's Next

Once all checks pass, you're ready to build your first design.
Ask Claude: "Create a blink LED design for the Zybo Z7-10"

Claude will generate:
1. `src/blink.v` — Verilog source
2. `constrs/zybo_leds.xdc` — pin constraints
3. `scripts/build.tcl` — full build script
4. Commands to program the board

---

## Troubleshooting

### "No Digilent device found" in lsusb
- Check USB cable (must be data cable, not charge-only)
- Try a different USB port
- Check `dmesg | tail` for USB errors
- Reinstall cable drivers (Step 3)

### Permission denied on /dev/ttyUSB*
- Ensure you're in the `dialout` group: `groups $USER`
- Log out and back in after `usermod`
- Temporary fix: `sudo chmod 666 /dev/ttyUSB0`

### Vivado command not found
- Source the settings: `source /tools/Xilinx/Vivado/2024.1/settings64.sh`
- Check it's in your `~/.bashrc`

### xpra attach fails from Mac
- Ensure SSH key auth works: `ssh user@server` should not prompt for password
- Check xpra is running on server: `xpra list`
- Try with explicit display: `xpra attach ssh://user@server/100`
