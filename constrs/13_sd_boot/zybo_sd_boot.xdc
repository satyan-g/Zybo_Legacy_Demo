# zybo_sd_boot.xdc — LED pin constraints for 13_sd_boot
# Original Zybo Rev B (NOT Z7)

# LEDs — active high
set_property PACKAGE_PIN M14 [get_ports {leds_tri_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[0]}]

set_property PACKAGE_PIN M15 [get_ports {leds_tri_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[1]}]

set_property PACKAGE_PIN G14 [get_ports {leds_tri_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[2]}]

set_property PACKAGE_PIN D18 [get_ports {leds_tri_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_tri_o[3]}]
