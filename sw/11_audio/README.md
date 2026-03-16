# 11 — Audio Codec (SSM2603)

Configures the Zybo's SSM2603 audio codec over I2C and plays a 750 Hz sine
tone through the headphone jack using a PL-based I2S transmitter.

## Hardware Setup
- SSM2603 configured via PS I2C (IIC0).
- PL I2S tone generator (`i2s_tone_gen.v`) drives BCLK, LRCLK, and data to the codec.
- AXI GPIO or custom IP for tone enable/control.

## Build and Run
```
./scripts/build_hw.sh 11_audio
./scripts/build_sw.sh 11_audio
./scripts/deploy.sh 11_audio
```

## What to Expect
- Plug headphones into the HP jack.
- A steady 750 Hz sine tone plays after initialization.
- Serial console prints codec register configuration status.

## Source
- `sw/11_audio/audio_demo.c`
- `src/11_audio/i2s_tone_gen.v`
