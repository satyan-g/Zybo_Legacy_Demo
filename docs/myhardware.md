# My Hardware

## Development Server

| Component | Details |
|-----------|---------|
| **CPU** | AMD Ryzen 5 3600 6-Core (12 threads) |
| **RAM** | 94 GB |
| **Disk** | 938 GB NVMe, ~424 GB free |
| **GPU** | NVIDIA GeForce RTX 2060 |
| **OS** | Ubuntu 24.04.4 LTS (kernel 6.8.0-101-generic) |

## FPGA Board — Digilent Zybo (Original, NOT Z7)

| Field | Value |
|-------|-------|
| **Board** | Digilent Zybo (Original, Rev B) |
| **FPGA Part** | xc7z010clg400-1 |
| **SoC** | Xilinx Zynq-7010 (dual ARM Cortex-A9 + FPGA) |
| **DDR3** | 512 MB |
| **System Clock** | 125 MHz on pin **L16** (Z7-10 uses K17 — different!) |
| **Board Files Dir** | `zybo/B.3` (not `zybo-z7-10`) |
| **Power** | USB powered (JP5 jumper set to USB) |

## USB Connection

| Field | Value |
|-------|-------|
| **USB Chip** | FTDI FT2232 Dual UART/FIFO |
| **USB Vendor:Product** | 0403:6010 |
| **Manufacturer** | Digilent |
| **Product** | Digilent Adept USB Device |
| **Serial** | 210279655246 |
| **Bus Power** | 500 mA max |

## Serial Ports

| Port | Function | Baud | Settings |
|------|----------|------|----------|
| `/dev/ttyUSB0` | JTAG (programming) | — | Used by Vivado hw_server |
| `/dev/ttyUSB1` | UART (serial console) | 115200 | 8N1, no flow control |

## Software / Toolchain

| Tool | Version | Path |
|------|---------|------|
| **Vivado** | 2024.2 | `$HOME/Xilinx/Vivado/2024.2/Vivado/2024.2` |
| **Settings** | — | `source $HOME/Xilinx/Vivado/2024.2/Vivado/2024.2/settings64.sh` |
| **Board Files** | Digilent | `$HOME/Xilinx/Vivado/2024.2/Vivado/2024.2/data/boards/board_files/zybo/B.3` |
| **Cable Drivers** | Installed | udev rules in `/etc/udev/rules.d/52-xilinx-*.rules` |
| **WiFi** | Intel AC 9260 (5 GHz, weak signal -72 dBm) | `wlp5s0` — consider ethernet |

## Quick Access

```bash
# Source Vivado (already in ~/.bashrc)
source $HOME/Xilinx/Vivado/2024.2/Vivado/2024.2/settings64.sh

# Serial console
picocom -b 115200 /dev/ttyUSB1

# Check board connected
lsusb | grep 0403:6010

# Check serial ports
ls /dev/ttyUSB*

# Run environment diagnostics
bash scripts/vivado_check.sh
```

---

## Vivado/Vitis 2024.2 Build Gotchas

Critical findings discovered during hardware testing. These are specific to the
Original Zybo Rev B + Vivado/Vitis 2024.2 and prevent repeat mistakes.

### Vitis 2024.2 SDT BSP — XPAR Changes

Vitis 2024.2 uses a System Device Tree (SDT) based BSP. The `xparameters.h`
defines have changed significantly from the legacy XPS/HSI-based BSP:

**Device IDs → Base Addresses**
- **Old**: `XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_DEVICE_ID)`
- **New**: `XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_BASEADDR)`
- All `_DEVICE_ID` defines are gone. Drivers now take `BASEADDR` (a `UINTPTR`).
- Applies to: XGpio, XTmrCtr, XAxiDma, XSysMon, XIic, XScuGic, etc.

**GIC (Interrupt Controller)**
- **Old**: `XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID)`
- **New**: `XScuGic_LookupConfig(XPAR_XSCUGIC_0_BASEADDR)` (= 0xF8F01000)

**Fabric Interrupt IDs — CRITICAL**
The BSP generates three defines per interrupt, and NONE give the correct GIC ID directly:
- `XPAR_AXI_GPIO_0_INTERRUPTS` = `0x401D` — Device Tree encoded. **HANGS the processor.**
- `XPAR_FABRIC_AXI_GPIO_0_INTR` = `29` — Raw SPI number. **Too low for XScuGic.**
- Actual GIC ID needed = **61** (SPI 29 + 32)

**Formula: GIC_ID = XPAR_FABRIC_*_INTR + 32**
(ARM GIC architecture: first 32 IDs are SGI/PPI, SPI interrupts start at ID 32)

**Recommended pattern in C code:**
```c
#define GPIO_INTERRUPT_ID (XPAR_FABRIC_AXI_GPIO_0_INTR + 32)
```

This applies to ALL fabric (PL→PS) interrupts: GPIO, Timer, DMA, etc.

### Vivado Block Design — Auto-Generated Names

**proc_sys_reset naming**
When using `apply_bd_automation` for AXI connections, Vivado auto-creates a
`proc_sys_reset` cell. The name is NOT always `rst_ps7_0_100M`:
- **Fix**: Use a filter to find it:
  ```tcl
  set rst_cell [get_bd_cells -filter {VLNV =~ *:proc_sys_reset:*}]
  connect_bd_net [get_bd_pins $rst_cell/peripheral_aresetn] ...
  ```

**DMA dual-master HP0 address assignment**
When connecting both M_AXI_MM2S and M_AXI_S2MM to S_AXI_HP0, the second
`apply_bd_automation` must use `Slave "/ps7/S_AXI_HP0"` (not `Master`):
```tcl
# First master creates interconnect
apply_bd_automation ... {Master "/axi_dma_0/M_AXI_MM2S" intc_ip "New AXI Interconnect" ...} [get_bd_intf_pins ps7/S_AXI_HP0]
# Second master — note Slave config to reuse the same HP0
apply_bd_automation ... {Slave "/ps7/S_AXI_HP0" intc_ip "Auto" ...} [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
```
After `assign_bd_address`, verify BOTH address spaces have segments — if not, the S2MM
channel silently fails (MM2S works but S2MM times out).

**M_AXI_GP0_ACLK must be explicitly connected**
When manually wiring AXI (not using `apply_bd_automation`), you MUST connect:
```tcl
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins ps7/M_AXI_GP0_ACLK]
```

**External port naming**
`make_bd_pins_external` appends `_0` to the port name. Use `create_bd_port` instead:
```tcl
create_bd_port -dir O ac_bclk
connect_bd_net [get_bd_pins module/ac_bclk] [get_bd_ports ac_bclk]
```

### XADC Analog Pins — Bank 35 I/O Conflict

Pmod JA XADC analog inputs (VAUX6/7/14/15) are in Bank 35 with LEDs (LVCMOS33).
Do NOT constrain XADC analog pins in XDC — the XADC Wizard handles them internally.

### Vitis Python API (2024.2)

- Workspace path is `vitis_workspace/` (not `sw_workspace/` like XSCT)
- `domain.add_lib()` / `domain.set_lib()` do NOT exist — can't add BSP libraries via API
- `no_boot_bsp=False` auto-generates FSBL with `xilffs`/`xilrsa`
- `no_boot_bsp=True` skips FSBL (use for non-boot projects)

### Audio Codec (SSM2603) — I2C Port Names

AXI IIC external interface ports are named `IIC_0_scl_io` / `IIC_0_sda_io` (not `iic_rtl_*`).
