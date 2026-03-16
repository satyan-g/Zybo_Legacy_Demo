# LPU Project Roadmap

## Phase 1: Fundamentals (PL only)
- [x] 01_blink — LED blink
- [x] 03_breathing_led — DDS + PWM + sine LUT

## Phase 2: PS Basics
- [x] 02_hello — UART Hello World from ARM core

## Phase 3: Board Feature Exploration
- [ ] 04_switches_buttons — PL: switches→LEDs, button debouncing, edge detection
- [ ] 05_axi_gpio — PS reads switches / writes LEDs via AXI GPIO IP (first AXI bus use)
- [ ] 06_interrupts — Button press triggers ARM IRQ, handler prints to UART
- [ ] 07_timer — PS timer, measure elapsed time, toggle LED at precise interval
- [ ] 08_custom_ip — Create a custom AXI peripheral (register-mapped HW accelerator)
- [ ] 09_dma — AXI DMA: move data blocks between DDR and PL at high speed
- [ ] 10_xadc — Read analog voltage from XADC Pmod header, print to UART
- [ ] 11_audio — I2S audio codec: play a tone through headphone jack
- [ ] 12_ethernet — Bare-metal lwIP echo server
- [ ] 13_sd_boot — Boot from SD card (FSBL + bitstream + app)
- [ ] 14_qspi_boot — Boot from QSPI flash (persistent, survives power cycle)

## Planned — ML on FPGA

### Project 1: Binarized MLP — MNIST digit classifier
**Easiest — Start here**
- Model size: ~15 KB
- Fits in BRAM? Fully on-chip
- Est. throughput: >1M images/sec
- A 3-layer fully connected binary neural network (weights = ±1) trained on MNIST.
  Entire model fits in ~15 KB of BRAM — no DDR needed at all. FINN has a pre-built
  reference design for this. Sub-microsecond latency, demo live drawing digits on
  screen feeding into the board via UART/USB.
- Toolchain: FINN finn-examples repo → Zybo board file → Vivado synthesis → done

### Project 2: Binarized CNN — CIFAR-10 image classifier
**Beginner-friendly**
- Model size: ~180 KB
- Fits in BRAM? Just fits (240 KB available)
- Est. throughput: ~20K images/sec
- A binarized CNN (CNV-W1A1) classifying 32×32 colour images into 10 classes —
  airplanes, cars, birds etc. Canonical FINN demo. Original FINN paper demonstrated
  21,906 classifications/sec with 283 µs latency on CIFAR-10 at 80.1% accuracy.
- Toolchain: Brevitas (PyTorch) → FINN compiler → Vivado → Zybo

### Project 3: Ternary MLP — keyword spotting
**Intermediate**
- Model size: ~60 KB ternary
- Fits in BRAM? Yes
- Demo factor: Very visual
- A small ternary-weight MLP that classifies MFCC audio features — detecting spoken
  keywords like "yes", "no", "stop", "go" from a microphone. Weights are {-1, 0, +1}
  — the same representation as BitNet 1.58. Connects to BitNet interest. Live demo
  with mic audio via USB, classifications on terminal.
- Toolchain: Brevitas → hls4ml → Vivado HLS → Zybo + USB mic
