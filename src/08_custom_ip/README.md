# 08 — Custom AXI4-Lite Slave IP

A hand-written AXI4-Lite slave (`custom_axi_slave.v`) with four 32-bit
registers: LED output (w), switch input (r), scratch (rw), and a
free-running counter (r). The C app exercises every register with
read/write/verify tests to prove the AXI bus is wired correctly.

**Teaches:** AXI4-Lite protocol (write address/data/response, read
address/data channels), custom IP packaging in Vivado, memory-mapped
register design.

## Build and Run
```
./scripts/build_hw.sh 08_custom_ip
./scripts/build_sw.sh 08_custom_ip
./scripts/deploy.sh 08_custom_ip
```

## What to Expect
- Serial console reports PASS/FAIL for each register test.
- LEDs are driven by writing to register 0.
- Counter register increments every AXI clock cycle.

## Source
- `src/08_custom_ip/hw/custom_axi_slave.v`
- `src/08_custom_ip/sw/custom_ip_demo.c`
