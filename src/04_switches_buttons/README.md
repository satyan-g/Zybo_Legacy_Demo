# 04 — Switches and Buttons (PL Only)

Two modes selected by SW[3]:
- **SW[3]=0**: Switches directly drive LEDs (SW[0]→LED[0], etc.)
- **SW[3]=1**: Button mode — BTN0/1/2 toggle their LED, BTN3 rotates the pattern left

Buttons are debounced (3-sample shift register at ~8 ms tick) with rising-edge detection.
Teaches: debouncing, edge detection, registered vs combinational outputs.

## Hardware Setup
- PL only: 125 MHz clock on pin L16.
- Switches: G15/P15/W13/T16, Buttons: R18/P16/V16/Y16, LEDs: M14/M15/G14/D18.
- No block design or PS configuration required.

## Build and Run
```
./scripts/build_hw.sh 04_switches_buttons
./scripts/deploy.sh 04_switches_buttons
```

## What to Expect
- SW[3]=0: flip a switch, its LED follows immediately.
- SW[3]=1: press BTN0/1/2 to toggle LEDs; press BTN3 to rotate the lit pattern.
- No serial output (no PS).

## Source
- `src/04_switches_buttons/hw/switches_buttons.v`
