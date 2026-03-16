## Zybo (Original, Rev B) — Audio codec (SSM2603) pin constraints
## Reference: Zybo schematic Rev B

## Audio codec — I2S interface
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports ac_bclk]
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports ac_mclk]
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports ac_muten]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports ac_pbdat]
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports ac_pblrc]
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports ac_recdat]
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports ac_reclrc]

## Audio codec — I2C bus (AXI IIC external interface)
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports IIC_0_scl_io]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports IIC_0_sda_io]
