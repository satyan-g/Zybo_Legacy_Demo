# 12 — lwIP Ethernet Echo Server

Runs a TCP echo server on port 7 using the lwIP stack. Obtains an IP address
via DHCP (falls back to a static IP if DHCP times out).

## Hardware Setup
- Zynq PS GEM (Gigabit Ethernet MAC) enabled.
- Ethernet PHY connected via MDIO/MII on the Zybo.
- Connect an Ethernet cable to the board.

## Build and Run
```
./scripts/build_hw.sh 12_ethernet
./scripts/build_sw.sh 12_ethernet
./scripts/deploy.sh 12_ethernet
```

## What to Expect
- Serial console prints the assigned IP address.
- Test with: `telnet <ip> 7` — anything you type is echoed back.
- LEDs indicate network status (link, activity).

## Source
- `sw/12_ethernet/ethernet_demo.c`
