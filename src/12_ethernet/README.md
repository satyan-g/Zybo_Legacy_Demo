# 12 — lwIP Ethernet Echo Server

Runs a TCP echo server on port 7 using the lwIP 2.2.0 stack over the Zynq
PS GEM (Gigabit Ethernet MAC). Requests a DHCP lease on startup; falls back
to a static IP if DHCP times out. Any data sent to port 7 is echoed back
verbatim — useful for testing network connectivity and latency.

**Teaches:** lwIP220 initialization, GEM driver, DHCP client, TCP pcb setup,
sys_now() with ARM global timer, raw API callback model.

## Build and Run
```
./scripts/build_hw.sh 12_ethernet
./scripts/build_sw.sh 12_ethernet
./scripts/deploy.sh 12_ethernet
```

## What to Expect
- Serial console prints the assigned IP address.
- Test: `telnet <ip> 7` — type anything and it echoes back.
- Or: `echo "hello" | nc <ip> 7`

## Source
- `src/12_ethernet/sw/ethernet_demo.c`
