# Zybo Legacy Demo — Zynq FPGA Learning Project

## Project Overview
Learning/demo project for the Zybo Zynq-7000 board (Digilent). Covers board
fundamentals: PL GPIO, PS UART, AXI peripherals, interrupts, DMA, and more.
Serves as reference for the main LPU project (`../LPU/`).

## Environment
- **Dev machine**: Mac (local) → SSH into Linux server
- **Session management**: tmux on Linux server (persistent sessions)
- **GUI fallback**: xpra for Vivado GUI inspection when needed
- **Toolchain**: Xilinx Vivado + Vitis (WebPACK edition)
- **Board**: Digilent Zybo (Original, Rev B) — NOT Z7 variant
- **Serial console**: picocom or minicom at 115200 baud, 8N1

## Workflow — Claude-Driven, TCL-First

### Golden Rule
Everything that can be scripted MUST be scripted. No manual GUI clicks for
repeatable work. The GUI (via xpra) is only for visual inspection/debugging.

### How We Work
1. User describes what they want to build or learn
2. Claude generates: HDL source, constraints (.xdc), TCL build scripts, C code
3. User runs scripts in tmux, pastes output back if issues arise
4. Claude debugs from logs/output text

### File Organization
```
LPU/
├── CLAUDE.md              # This file — project rules for Claude
├── docs/                  # Learning docs, process guides, architecture notes
│   ├── overview.md        # Project overview and learning roadmap
│   ├── environment.md     # Environment setup guide
│   ├── workflow.md        # Day-to-day workflow reference
│   └── troubleshooting.md # Common issues and fixes
├── scripts/               # TCL build/utility scripts
│   └── README.md          # Script usage guide
├── src/                   # HDL source files (Verilog/VHDL)
│   └── README.md          # Source file conventions
├── constrs/               # Constraint files (.xdc)
│   └── README.md          # Constraint file conventions
├── sw/                    # Software (bare-metal C, drivers)
│   └── README.md          # Software conventions
├── ip/                    # Custom AXI IP cores
├── sim/                   # Simulation testbenches
├── output/                # Generated artifacts (bitstreams, logs) — gitignored
└── .gitignore
```

## Conventions

### Naming
- Verilog files: `snake_case.v`
- Constraint files: `<board>_<function>.xdc` (e.g., `zybo_leds.xdc`)
- TCL scripts: `snake_case.tcl`
- C source: `snake_case.c`

### TCL Scripts
- Every script must be runnable standalone: `vivado -mode batch -source scripts/build.tcl`
- Scripts should print clear status messages so terminal output is self-explanatory
- Use non-project mode for builds (no Vivado project directory bloat)
- Board-specific settings (part number, board files path) are set in `scripts/settings.tcl`

### Version Control
- NEVER commit Vivado project directories or generated files
- Commit only: source HDL, constraints, TCL scripts, C source, docs
- The `output/` directory is gitignored

### Build Artifacts
- Bitstreams, HW exports (.xsa), logs go in `output/`
- `output/` is created automatically by build scripts if it doesn't exist

## Guardrails

### Before Synthesis
- [ ] All pin assignments in .xdc match the board schematic
- [ ] Clock constraints are defined
- [ ] TCL script targets the correct FPGA part

### Before Programming the Board
- [ ] Confirm board is connected (`lsusb | grep -i digilent`)
- [ ] Confirm correct bitstream (check build log timestamp)
- [ ] Back up any existing flash contents if reflashing

### Board-Specific Findings
See **docs/myhardware.md** (bottom section) for critical Vitis 2024.2 / Original Zybo findings:
- XPAR_*_DEVICE_ID → XPAR_*_BASEADDR (all drivers)
- Use XPAR_FABRIC_*_INTR for interrupt IDs (NOT XPAR_*_INTERRUPTS which is DT-encoded)
- proc_sys_reset auto-naming, M_AXI_GP0_ACLK wiring, XADC bank conflicts, etc.

### Common Mistakes to Avoid
- **CRITICAL: This is the ORIGINAL Zybo, NOT the Z7-10/Z7-20** — pin assignments differ!
  - System clock is **L16** (Z7 uses K17)
  - Board part is `digilentinc.com:zybo:part0:2.0` (NOT `zybo-z7-10`)
  - Board files dir is `zybo/B.3`
  - UART1 on MIO 48..49 must be explicitly enabled in PS block designs
- Don't use Vivado project mode for PL-only builds — use non-project TCL flow
- Don't hardcode absolute paths in scripts — use relative paths from project root
- Don't skip timing constraints — even for simple designs
- Don't forget to `reset_run` before re-running synthesis if changing sources
- Always use wrapper scripts (`./scripts/run_vivado.sh`, etc.) — never inline `source`

## Board Quick Reference (Original Zybo)
- **FPGA Part**: xc7z010clg400-1
- **Board files**: `zybo/B.3` (NOT `zybo-z7-10`)
- **System Clock**: 125 MHz on pin **L16** (Z7-10 uses K17 — DIFFERENT)
- **LEDs**: 4 user LEDs (M14, M15, G14, D18) — active high
- **Switches**: 4 slide switches (G15, P15, W13, T16)
- **Buttons**: 4 push buttons (R18, P16, V16, Y16)
- **UART**: via USB-JTAG, 115200/8N1
- **DDR**: 512 MB DDR3

## Status

### Tested on hardware
- [x] Environment setup verified (Vivado 2024.2, board files, xpra, picocom)
- [x] 01_blink — PL LED blink
- [x] 02_hello — PS UART hello world
- [x] 03_breathing_led — PWM LED breathing
- [x] 04_switches_buttons — PL GPIO inputs
- [x] 05_axi_gpio — AXI GPIO peripheral
- [x] 06_interrupts — Interrupt handling
- [x] 07_timer — Timer peripheral
- [x] 08_custom_ip — Custom AXI IP core
- [x] 09_dma — DMA transfers
- [x] 10_xadc — Analog-to-digital converter
- [x] 13_sd_boot — SD card boot (JTAG verified; SD boot untested)

- [x] 12_ethernet — Ethernet lwIP echo server (DHCP + TCP echo on port 7)

### On hold
- [ ] 11_audio — Audio codec (SSM2603) — needs headphone testing
- [ ] 14_qspi_boot — QSPI flash boot — JTAG works; QSPI flash programming untested
