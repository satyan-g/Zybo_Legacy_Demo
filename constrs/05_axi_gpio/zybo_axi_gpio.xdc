## Original Zybo — AXI GPIO pin constraints
## LEDs, switches, and buttons directly on AXI GPIO IP ports

## LEDs (active high) — connected to AXI GPIO ch1
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {gpio_leds_tri_o[3]}]

## Switches — connected to AXI GPIO ch2 bits [3:0]
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[0]}]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[1]}]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[2]}]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[3]}]

## Buttons — connected to AXI GPIO ch2 bits [7:4]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[4]}]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[5]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[6]}]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports {gpio_sw_btn_tri_i[7]}]
