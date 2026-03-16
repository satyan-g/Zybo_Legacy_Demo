## Original Zybo — XADC demo constraints
## LEDs for visual temperature indicator
## XADC analog pins are dedicated — no constraints needed (handled by XADC Wizard IP)

## LEDs (active high) — connected to AXI GPIO output
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[3]}]
