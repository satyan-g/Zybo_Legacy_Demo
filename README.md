# Zybo Legacy Demo — Zynq FPGA Learning Projects

14 progressive bare-metal projects for the **Digilent Zybo (Original, Rev B)** — a Zynq-7000 FPGA/ARM SoC board. Covers PL GPIO, PS UART, AXI peripherals, interrupts, DMA, XADC, audio, ethernet, and boot modes.

Everything is TCL-scripted. No GUI clicks.

## Board

| Field | Value |
|-------|-------|
| Board | Digilent Zybo (Original, Rev B) — **NOT Z7** |
| FPGA | xc7z010clg400-1 (Zynq-7010) |
| Clock | 125 MHz on pin L16 |
| DDR | 512 MB DDR3 |
| Toolchain | Vivado + Vitis 2024.2 |

## Projects

| # | Project | What it demonstrates | Status |
|---|---------|---------------------|--------|
| 01 | blink | PL LED blink (Verilog only) | Verified |
| 02 | hello | PS UART hello world | Verified |
| 03 | breathing_led | PWM LED breathing | Verified |
| 04 | switches_buttons | PL GPIO inputs | Verified |
| 05 | axi_gpio | PS reads switches/buttons, drives LEDs via AXI GPIO IP | Verified |
| 06 | interrupts | Button press interrupts toggle LEDs | Verified |
| 07 | timer | AXI Timer interrupt-driven LED patterns | Verified |
| 08 | custom_ip | Custom AXI4-Lite slave (Verilog) with registers | Verified |
| 09 | dma | AXI DMA loopback (PS DDR ↔ PL) | Verified |
| 10 | xadc | On-chip temperature/voltage sensor readout | Verified |
| 11 | audio | SSM2603 codec I2S tone generator | On hold |
| 12 | ethernet | lwIP TCP echo server (DHCP + port 7) | Verified |
| 13 | sd_boot | SD card boot image (FSBL + bitstream + app) | Verified (JTAG) |
| 14 | qspi_boot | QSPI flash boot image | On hold |

## Quick Start

```bash
# 1. Build hardware (Vivado synthesis + implementation + bitstream)
./scripts/build_hw.sh 05_axi_gpio

# 2. Build software (Vitis bare-metal app)
./scripts/build_sw.sh 05_axi_gpio

# 3. Open serial console
picocom -b 115200 /dev/ttyUSB1

# 4. Deploy to board
./scripts/deploy.sh 05_axi_gpio
```

For PL-only projects (01, 03, 04) that don't use the ARM core:
```bash
./scripts/build_hw.sh 01_blink
./scripts/run_vivado.sh src/01_blink/program.tcl
```

## File Structure

```
├── src/
│   └── <NN_project>/
│       ├── hw/            # Verilog sources, constraints (.xdc), build.tcl
│       ├── sw/            # Bare-metal C app, build.py
│       ├── run.tcl        # XSCT deploy script (PS projects)
│       └── README.md      # Project-specific notes
├── src/common/
│   └── zybo_master.xdc    # Master pin constraint reference
├── scripts/               # Shell wrapper scripts
│   ├── build_hw.sh        # Build hardware:  ./scripts/build_hw.sh <project>
│   ├── build_sw.sh        # Build software:  ./scripts/build_sw.sh <project>
│   ├── deploy.sh          # Program + run:   ./scripts/deploy.sh <project>
│   ├── env.sh             # Xilinx tool paths
│   └── zybo_preset.tcl    # Zynq PS configuration preset
├── docs/                  # Hardware docs and build gotchas
│   └── myhardware.md      # Critical Vitis 2024.2 findings
├── output/                # Build artifacts (gitignored)
└── CLAUDE.md              # AI assistant instructions
```

## Key Findings (Vitis 2024.2 + Original Zybo)

Documented in [`docs/myhardware.md`](docs/myhardware.md). The highlights:

- **`XPAR_*_DEVICE_ID` is gone** — all drivers now use `XPAR_*_BASEADDR`
- **Fabric interrupt IDs need `+32`** — `XPAR_FABRIC_*_INTR` gives the raw SPI number, XScuGic needs the GIC ID (SPI + 32)
- **DMA dual-master address paths** — verify both masters have address segments after `assign_bd_address`
- **XADC pins in Bank 35** — don't constrain analog pins in XDC (conflicts with digital I/O standards)
- **lwIP is now `lwip220`** — not `lwip213`, and `NO_SYS_NO_TIMERS` must be disabled

## Documentation Links

- [Zybo Reference Manual](https://digilent.com/reference/programmable-logic/zybo/reference-manual)
- [Zybo Schematic](https://digilent.com/reference/programmable-logic/zybo/start)
- [Zynq-7000 Technical Reference Manual (UG585)](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM)
- [Vivado Design Suite User Guide](https://docs.amd.com/r/en-US/ug892-vivado-design-flows-overview)

## License

Source code in this repository is MIT licensed. Xilinx/AMD IP cores and tools are subject to their respective licenses.
