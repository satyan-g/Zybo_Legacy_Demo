## Original Zybo — Ethernet demo LED constraints
## Ethernet itself is on PS MIO pins (no PL constraints needed)
## LEDs used for link status / activity indication via AXI GPIO

## LEDs (active high) — connected to AXI GPIO
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[3]}]
