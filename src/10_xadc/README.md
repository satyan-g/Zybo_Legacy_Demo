# 10 — XADC On-Chip Sensors

Reads the Zynq's built-in 12-bit ADC (XADC) to report die temperature,
VCCINT (core voltage), and VCCAUX (aux voltage). The raw ADC codes are
converted to engineering units using the formulas in UG480. LEDs display
a 4-bit bar graph proportional to die temperature.

**Teaches:** XADC Wizard IP, XSysMon driver, ADC code-to-value conversion,
UG480 register map.

## Build and Run
```
./scripts/build_hw.sh 10_xadc
./scripts/build_sw.sh 10_xadc
./scripts/deploy.sh 10_xadc
```

## What to Expect
- Serial console prints temperature (°C), VCCINT (V), VCCAUX (V) every second.
- More LEDs light as die temperature rises.
- Typical idle values: ~40–50 °C, VCCINT ~1.0 V, VCCAUX ~1.8 V.

## Source
- `src/10_xadc/sw/xadc_demo.c`
