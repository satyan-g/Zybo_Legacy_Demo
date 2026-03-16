# 08 — Custom AXI4-Lite Slave IP

Tests a hand-written AXI4-Lite slave with four registers: LED output,
switch input, scratch read/write, and a free-running counter.

## Hardware Setup
- Custom AXI4-Lite slave IP (`custom_axi_slave.v`) in the PL.
- Connected to Zynq PS via AXI interconnect.
- LEDs and switches directly wired to the custom IP ports.

## Build and Run
```
./scripts/build_hw.sh 08_custom_ip
./scripts/build_sw.sh 08_custom_ip
./scripts/deploy.sh 08_custom_ip
```

## What to Expect
- Serial console reports register read/write tests (pass/fail for each).
- LEDs are driven by writing to the LED register.
- Counter register increments every clock cycle.

## Source
- `sw/08_custom_ip/custom_ip_demo.c`
- `src/08_custom_ip/custom_axi_slave.v`
