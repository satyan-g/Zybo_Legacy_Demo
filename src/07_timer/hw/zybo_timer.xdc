## Original Zybo — AXI Timer demo LED pin constraints
## LEDs only (active high) — connected to AXI GPIO output

set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[3]}]
