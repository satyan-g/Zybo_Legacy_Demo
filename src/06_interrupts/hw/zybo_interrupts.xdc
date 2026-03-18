## Original Zybo — Interrupt demo pin constraints
## LEDs on AXI GPIO ch1 (output), buttons on AXI GPIO ch2 (input with interrupts)

## LEDs (active high) — connected to AXI GPIO ch1
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[3]}]

## Buttons (active high) — connected to AXI GPIO ch2
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {gpio_btns_tri_i[0]}]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports {gpio_btns_tri_i[1]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {gpio_btns_tri_i[2]}]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports {gpio_btns_tri_i[3]}]
