## Zybo (Original) — Breathing LED constraints

## 125 MHz system clock (Original Zybo = L16)
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk -period 8.00 -waveform {0 4} [get_ports clk]

## LEDs (active high)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
